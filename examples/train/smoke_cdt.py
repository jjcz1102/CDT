import argparse
import time

import torch
import torch.nn.functional as F

from osrl.algorithms.cdt import CDT


def parse_args():
    parser = argparse.ArgumentParser(description="Fast CDT GPU smoke test.")
    parser.add_argument("--device", type=str, default="cuda:0")
    parser.add_argument("--batch-size", type=int, default=32)
    parser.add_argument("--seq-len", type=int, default=8)
    parser.add_argument("--state-dim", type=int, default=32)
    parser.add_argument("--action-dim", type=int, default=4)
    parser.add_argument("--embedding-dim", type=int, default=64)
    parser.add_argument("--num-layers", type=int, default=1)
    parser.add_argument("--num-heads", type=int, default=1)
    parser.add_argument("--steps", type=int, default=5)
    return parser.parse_args()


def main():
    args = parse_args()
    if not torch.cuda.is_available() and args.device.startswith("cuda"):
        raise RuntimeError("CUDA device requested but torch.cuda.is_available() is False.")

    device = torch.device(args.device)
    torch.manual_seed(0)

    model = CDT(
        state_dim=args.state_dim,
        action_dim=args.action_dim,
        max_action=1.0,
        seq_len=args.seq_len,
        episode_len=100,
        embedding_dim=args.embedding_dim,
        num_layers=args.num_layers,
        num_heads=args.num_heads,
        use_rew=True,
        use_cost=True,
        stochastic=False,
    ).to(device)
    optim = torch.optim.AdamW(model.parameters(), lr=1e-4, weight_decay=1e-4)

    print(f"device={device}")
    print(f"params={sum(p.numel() for p in model.parameters())}")

    start = time.time()
    for i in range(args.steps):
        states = torch.randn(args.batch_size, args.seq_len, args.state_dim, device=device)
        actions = torch.tanh(
            torch.randn(args.batch_size, args.seq_len, args.action_dim, device=device))
        returns = torch.randn(args.batch_size, args.seq_len, device=device)
        costs_return = torch.rand(args.batch_size, args.seq_len, device=device)
        time_steps = torch.arange(args.seq_len, device=device).long().unsqueeze(0).repeat(
            args.batch_size, 1)
        mask = torch.ones(args.batch_size, args.seq_len, device=device)
        episode_cost = torch.rand(args.batch_size, device=device)

        action_preds, cost_preds, state_preds = model(
            states=states,
            actions=actions,
            returns_to_go=returns,
            costs_to_go=costs_return,
            time_steps=time_steps,
            padding_mask=~mask.bool(),
            episode_cost=episode_cost,
        )

        cost_targets = torch.randint(0, 2, (args.batch_size * args.seq_len,), device=device)
        action_loss = F.mse_loss(action_preds, actions)
        cost_loss = F.nll_loss(cost_preds.reshape(-1, 2), cost_targets)
        state_loss = F.mse_loss(state_preds[:, :-1], states[:, 1:])
        loss = action_loss + 0.02 * cost_loss + 0.1 * state_loss

        optim.zero_grad(set_to_none=True)
        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), 0.25)
        optim.step()

        if device.type == "cuda":
            torch.cuda.synchronize(device)
        print(f"step={i + 1}/{args.steps} loss={loss.item():.6f}")

    elapsed = time.time() - start
    print(f"smoke test passed in {elapsed:.2f}s")


if __name__ == "__main__":
    main()

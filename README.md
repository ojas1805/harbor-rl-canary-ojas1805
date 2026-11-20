# Harbor RL Canary — Payment Reconciliation

**Author:** Ojas Singh  
**Agent:** terminus-2  
**Model:** Groq — `openai/gpt-oss-120b`  
**Task:** `reconcile-bug`

## 1. Project Overview

This project evaluates an AI coding agent's ability to identify and repair bugs in a Python-based CSV payment reconciliation application.

The task contains three bugs of increasing difficulty:

1. CLI argument handling.
2. Transaction status and amount calculation.
3. Duplicate transaction handling using chronological timestamp comparison across timezone offsets.

The verifier uses dense rewards to provide partial credit for independently solving each bug.

## 2. Task Structure

- `tasks/reconcile-bug/` — Original Baseline task.
- `tasks/reconcile-bug-ablation/` — Modified Ablation task.
- `jobs_summary/baseline/` — Baseline results and trajectories.
- `jobs_summary/ablation/` — Ablation results and trajectories.
- `README.md` — Experiment documentation.

## 3. Dense Reward Design

| Component | Weight |
|---|---:|
| Correct CLI argument (`--input`) | 0.20 |
| Correct transaction status handling | 0.30 |
| Duplicate IDs and timezone comparison | 0.50 |
| **Total** | **1.00** |

The verifier generates randomized transaction amounts to reduce the effectiveness of hardcoded outputs.

## 4. Calibration and Anti-Cheat

| Test | Expected reward | Observed reward |
|---|---:|---:|
| NOP | 0.000 | 0.000 |
| Oracle with `solve.sh` | 1.000 | 1.000 |
| Oracle with `hack.sh` | 0.000 | 0.000 |

Both the original task and the Ablation task passed these calibration checks.

## 5. Baseline vs Ablation

**Model:** `openai/gpt-oss-120b`  
**Agent:** `terminus-2`

| Metric | Baseline | Ablation |
|---|---:|---:|
| Requested trials | 3 | 3 |
| Valid scored trials | 2 | 2 |
| Rate-limit errors | 1 | 1 |
| Mean reward | 1.000 | 1.000 |
| Pass@2 | 1.000 | 1.000 |
| Input tokens | 14,286 | 20,886 |
| Output tokens | 8,092 | 9,452 |
| Cost (USD) | 0.0069981 | 0.0086889 |

The third trial in each experiment encountered a Groq TPM rate limit. These trials did not produce valid rewards and are excluded from the scored-trial means.

**Important:** Each experiment currently has two valid trials, not three.

## 6. Ablation Design

The Ablation experiment strengthened the duplicate transaction test.

The modified test places the chronologically newer transaction first in the CSV and the older transaction second.

The timestamps use different UTC offsets:

- Newer: `2026-11-20T05:00:00+00:00`
- Older: `2026-11-20T10:00:00+05:30`

The newer transaction has status `FAILED`, while the older transaction has status `VALID`.

A correct implementation must compare actual chronological instants rather than simply retaining the last row in the CSV.

## 7. Trajectory Analysis

The successful Baseline trajectories show that the agent:

- Inspected the reconciliation application.
- Created its own CSV test data.
- Identified the CLI argument issue.
- Implemented status handling.
- Used timezone-aware timestamp parsing.
- Deduplicated transactions by ID.
- Used Decimal arithmetic for financial calculations.

The successful Ablation trajectories show that the agent recognized the importance of UTC offset-aware timestamp comparison and implemented chronological deduplication.

Both valid trials in each experiment achieved a reward of 1.000.

## 8. Reward and Advantage Analysis

For both experiments, the valid observed reward vector was:

`[1.0, 1.0]`

Binary rewards:

`[1, 1]`

Dense rewards:

`[1.0, 1.0]`

Using mean-centered advantages:

`A_i = R_i - mean(R)`

The resulting advantages are:

`[0.0, 0.0]`

The model achieved identical rewards across all valid trials, so there is no within-experiment reward variation.

The Ablation did not reduce the observed success rate. This suggests that the modified task was still solvable by the selected model.

## 9. Limitations

- Both experiments encountered one Groq rate-limit error.
- Only two valid scored trials were obtained per experiment.
- The Ablation modification did not produce a measurable reduction in model performance.
- More challenging duplicate-handling cases may be needed to distinguish model performance.

## 10. Demonstration

**Loom video:** [Add Loom recording link here]

The demonstration should cover:

1. Task structure and three bugs.
2. Dense reward design.
3. NOP and Oracle calibration.
4. Anti-cheat verification.
5. Baseline and Ablation experiment results.
6. Trajectory analysis and reward calculations.
7. Limitations and conclusions.
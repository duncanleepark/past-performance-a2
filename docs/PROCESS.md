# Development and Validation Record

## Milestone 1: Cash-only run

**Initial plan.** Read `data/handout.csv`, run the `cash` strategy through the engine with `--cash 100.00`, and write `equity.csv`. The executable should print a summary and write one row per date. Planned test: run it from the command line and compare the file to the expected output below.

```
date,value
2024-01-02,100.00
2024-01-03,100.00
2024-01-04,100.00
```

**Actual result.** [Test performed and result. Fill in once done.]

## Milestone 2: Portfolio accounting and buy-and-hold

**Initial plan.** Add order processing (reject zero or negative quantities, unknown securities, negative cash, and negative holdings, leaving the portfolio unchanged) and the `buy-and-hold` strategy, run through the same engine as `cash`. Planned test: before coding, work out cash, holdings, and value for each date by hand. Then run `buy-and-hold` on `data/handout.csv` with `--hold ALFA` and `--hold BETA` and compare. Also try a rejected order followed by a valid one.

**Actual result.** [Test performed and result.]

## Milestone 3: Momentum behind the shared strategy signature

**Initial plan.** Define the common strategy module type (abstract `state`, an update function whose input is one day's prices only) and seal `Cash`, `Buy_and_hold`, and `Momentum` with it. The engine must contain no strategy-specific branches. Planned test: predict the target and orders on `handout.csv` by hand (below), then compare against the actual dated states.

**Actual result.** [Test performed and result.]

## Milestone 4: Command-line path, errors, and final summary

**Initial plan.** Wire up `BatOptParse` (`--cash`, `--hold`), print the full summary (strategy, period, initial and final cash, nonzero holdings, final value, total return), and handle errors with a message and a nonzero exit status: missing file, wrong number of positional arguments, unknown strategy, bad cash string, missing or unknown `--hold`. Planned test: run all three strategies on `data/small-spy-5days.csv` with $10,000.00 and check each full stdout against hand-computed output, plus one run for each error case.

**Actual result.** [Test performed and result.]

## Cash on the supplied tiny market file

With $100.00 on `data/handout.csv`, the cash strategy never orders, so the state on every date is cash $100.00, no holdings, value $100.00.

| Date | Cash | Holdings | Value |
|---|---|---|---|
| 2024-01-02 | 100.00 | none | 100.00 |
| 2024-01-03 | 100.00 | none | 100.00 |
| 2024-01-04 | 100.00 | none | 100.00 |

OUnit group: [name of the group, e.g. `cash_handout`]. It checks cash, holdings, and value on every date.

## Buy-and-hold predictions

**`data/handout.csv`, $100.00.** On 2024-01-02, ALFA costs $10.00, so 10 shares fit with $0.00 left over. BETA costs $25.00, so 4 shares fit with $0.00 left over. No later orders.

| Date | ALFA hold: cash / shares / value | BETA hold: cash / shares / value |
|---|---|---|
| 2024-01-02 | 0.00 / 10 / 100.00 | 0.00 / 4 / 100.00 |
| 2024-01-03 | 0.00 / 10 / 120.00 | 0.00 / 4 / 80.00 |
| 2024-01-04 | 0.00 / 10 / 110.00 | 0.00 / 4 / 84.00 |

**My own file.** [Show the CSV. Use new security names, multiple dates, leftover cash after the first purchase, and a held price that changes later. State the initial cash and held security, then give the dated table of predictions and explain what the file exercises. Name the OUnit group.]

## Stateful-strategy predictions

I used the default one-day momentum rule. [Change this if you replace it with an original rule, and describe that rule precisely.]

**`data/handout.csv`, $100.00.**

- 2024-01-02: first date, so remember the prices, target is none, no orders. Cash 100.00, value 100.00.
- 2024-01-03: ALFA is +2.00 and BETA is -5.00, so ALFA is selected and differs from the previous target (none). Nothing to sell; buy 8 ALFA at 12.00 (96.00). Cash 4.00, value 4.00 + 96.00 = 100.00.
- 2024-01-04: ALFA is -1.00 and BETA is +1.00, so BETA is selected and differs from ALFA. Sell 8 ALFA at 11.00 (cash 92.00), then buy 4 BETA at 21.00 (84.00). Cash 8.00, value 8.00 + 84.00 = 92.00.

| Date | Cash | Holdings | Value |
|---|---|---|---|
| 2024-01-02 | 100.00 | none | 100.00 |
| 2024-01-03 | 4.00 | ALFA 8 | 100.00 |
| 2024-01-04 | 8.00 | BETA 4 | 92.00 |

**My own file.** [Show the CSV and design it to hit these cases: a tie (first column wins), a day with no positive increase (keep the previous target, no orders), the same target selected twice (no orders), a switch where sale proceeds fund the new purchase, and an unaffordable target (no buy, but it is still remembered). Give the predicted dated states.]

OUnit group: [name of the group(s)].

## Command-line report check

[Hand-compute final cash, holdings, value, and total return for `cash`, `buy-and-hold`, and `momentum` with $10,000.00 on `data/small-spy-5days.csv`, and paste the expected summaries here. Name the Cram group that checks each run's complete stdout.]

## Consequential revisions

[Record any revisions to the plan above and how you tested the result. If none were needed, say so briefly.]
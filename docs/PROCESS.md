# Development and Validation Record

## Milestone 1: Cash-only backtest

**Initial plan.** Load a market, run cash with $100.00, write equity values,
print a summary, and check every handout date plus missing-file behavior.

**Actual result.** `Market.load` uses `Csv.load` and stores prices in cents.
The `cash strategy on handout` OUnit group checks all dates. CLI smoke tests
confirmed equity and summary output, and a missing file exits with status 1.

## Milestone 2: Buy-and-hold backtest

**Initial plan.** Buy as many whole shares as possible of `--hold` on day one,
retain leftover cash, then hold. Check dated states on supplied and new data.

**Actual result.** The `buy-and-hold strategy` group checks handout and
ORBI/NOVA dates. CLI checks valid/unknown symbols; accounting tests check
trade acceptance and rejection.

## Milestone 3: Stateful momentum backtest

**Initial plan.** Run strategies through one engine. Momentum sees only the
current row, remembers prices and target, and is checked on each fixture date.

**Actual result.** The shared interface hides strategy state and supplies
only current prices. `momentum strategy` tests handout and fixture dates,
ties, retention, switches, and unaffordable targets. Rejections do not stop
later orders.

## Milestone 4: Command-line reports

**Initial plan.** Accept required arguments, run a strategy, write the R6
equity CSV, and compare complete summaries on the SPY file.

**Actual result.** The CLI validates arguments, cash, and buy-and-hold's
`--hold`, writes equity, and prints the summary. `test/cli.t` checks all three
summaries on `data/small-spy-5days.csv`.

## Cash on the supplied tiny market file

With $100.00, cash makes no orders: all three handout dates have $100.00
cash/value and no holdings. The `cash strategy on handout` group checks them.

## Buy-and-hold predictions

The `buy-and-hold strategy` group checks ALFA on the handout and ORBI on
`data/r7-buy-hold.csv`. Ten ALFA shares bought for $100.00 yield values
$100.00, $120.00, $110.00. The new two-security, three-date fixture starts
with $25.00: 3 ORBI at $7.00 leave $4.00; later ORBI prices change.

| Date | Cash | Holdings | Value |
|---|---:|---|---:|
| 2025-01-02 | $4.00 | ORBI 3 | $25.00 |
| 2025-01-03 | $4.00 | ORBI 3 | $31.00 |
| 2025-01-06 | $4.00 | ORBI 3 | $28.00 |

## Stateful-strategy predictions

Momentum selects the largest positive one-day increase, breaks ties by
header order, retains its target when no price rises, and sells before buying
on target change. It stores prior prices and target privately.

On the handout with $100.00, daily cash/holdings/value are $100.00/none/$100.00,
$4.00/8 ALFA/$100.00, then $8.00/4 BETA/$92.00. Seven-date
`data/r7-momentum.csv` exercises ties, retention, switching, and an
unaffordable switch. `momentum strategy` checks every date with $120.00; it
ends with $134.50 cash/value and no holdings.

## Command-line report check

`test/cli.t` checks complete output for all strategies on the SPY file with
$10,000.00. Cash ends at $10,000.00 (0.00%); buy-and-hold buys 95 SPY, leaves
$62.05, and ends at $10,333.45 (3.33%); momentum buys 94 SPY on September 16,
leaves $3.10, and ends at $10,166.38 (1.66%). Build and all OUnit/Cram tests
pass with `dune build && dune runtest --force`.

## Consequential revisions

**Original initial plan (retained).** Implement parsing, accounting, engine,
and CLI as end-to-end milestones, building internals bottom-up. The engine
records rejections so tests can verify later orders still run.

As I continued to work on it, I made the strategy boundary stricter. The engine
supplies only the current price row, so momentum retains its own preceding
prices and target rather than obtaining another market row. That made the
stateful rule easier to predict and test on a small fixture. I also clarified
the order rule after considering a rejected trade: one rejected order leaves
the portfolio unchanged but does not prevent later proposed orders from being
processed. Most consequentially, I kept all money as integer cents across parsing,
trading, and output so that rounding and formatting would not drift apart.
The Cram tests then checks the complete formatted report (not just the final
portfolio numbers.)

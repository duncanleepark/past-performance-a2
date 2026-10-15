# Development and Validation Record

## Milestone 1: Cash-only backtest

**Initial plan.** The executable will load a tiny market CSV, run the cash
strategy with $100.00, write one dated equity value per input row, and print a
summary showing unchanged cash, no holdings, and no return. I will check all
three dates of `data/handout.csv` and a missing market-file error.

**Actual result.** `Market.load` uses `Csv.load`, preserves header order, and
stores prices as integer cents. The OUnit group `cash strategy on handout`
checks cash, holdings, and value for every handout date; all remain $100.00.
A command-line run produced the dated equity CSV and summary, and a missing
file reported an error with status 1.

## Milestone 2: Buy-and-hold backtest

**Initial plan.** The executable will buy as many whole shares as possible on
the first date for a selected `--hold` symbol, retain leftover cash, value the
holding at later prices, and then make no more trades. I will predict every
dated state for the supplied file and a new multi-date, multi-security file.

**Actual result.** The OUnit group `buy-and-hold strategy` checks every date
on `data/handout.csv` while holding ALFA and every date on the new ORBI/NOVA
fixture. Command-line runs validate `--hold`, reject an unknown symbol, and
write the expected equity CSV. `Portfolio.apply` also rejects invalid orders
without changing the portfolio, which is checked by the accounting tests.

## Milestone 3: Stateful momentum backtest

**Initial plan.** The executable will run cash, buy-and-hold, and a stateful
strategy through one engine. Momentum will see only the current price row,
remember prior prices and its target, then make predictable decisions on a
small multi-date fixture. I will test every dated cash, holding, and value.

**Actual result.** `Engine.Strategy` gives each strategy an abstract state and
only the current date's prices. `Momentum` retains its prior prices and target;
the OUnit group `momentum strategy` checks every date on the handout and the
new momentum fixture, including a tie, target retention, a switch, and an
unaffordable new target. The engine processes proposed orders in sequence and
continues after a rejection.

## Milestone 4: Command-line reports

**Initial plan.** Connect all strategies to the required command-line shape,
write the R6 equity CSV, print the complete final summary, and use Cram to
check each strategy's complete standard output on the five-day SPY file.

**Actual result.** The executable accepts `MARKET.csv STRATEGY EQUITY.csv
--cash DOLLARS [--hold SYMBOL]`, validates invalid arguments and cash values,
and prints the R6 summary after successfully writing the equity CSV. The Cram
group in `test/cli.t` checks the complete output for cash, buy-and-hold, and
momentum on `data/small-spy-5days.csv`.

## Cash on the supplied tiny market file

With $100.00 on `data/handout.csv`, cash makes no orders. Cash, holdings, and
portfolio value are respectively $100.00, none, and $100.00 on January 2, 3,
and 4. OUnit group: `cash strategy on handout`.

## Buy-and-hold predictions

The `buy-and-hold strategy` OUnit group checks ALFA on `data/handout.csv` and
ORBI on `data/r7-buy-hold.csv`. With $100.00, ALFA buys 10 shares for $100.00,
so the dated values are $100.00, $120.00, and $110.00. The new fixture has
ORBI and NOVA over three dates; $25.00 buys 3 ORBI at $7.00, leaving $4.00.
Its dated states are:

| Date | Cash | Holdings | Value |
|---|---:|---|---:|
| 2025-01-02 | $4.00 | ORBI 3 | $25.00 |
| 2025-01-03 | $4.00 | ORBI 3 | $31.00 |
| 2025-01-06 | $4.00 | ORBI 3 | $28.00 |

The changing ORBI price checks valuation, while NOVA confirms that only the
selected holding is purchased.

## Stateful-strategy predictions

I used the default one-day momentum rule: after the first date, select the
security with the greatest strictly positive price increase, breaking ties by
header order; retain the target if no price rises. On a target change, sell all
holdings before buying as many shares as possible of the new target. Private
state retains the preceding price row and target.

On the handout with $100.00, the states are cash/no holdings/value of
$100.00 on January 2, $4.00/8 ALFA/$100.00 on January 3, and $8.00/4
BETA/$92.00 on January 4. `data/r7-momentum.csv` has two securities and seven
dates. With $120.00 it exercises a header-order tie, no-rise retention,
unchanged-target retention, a switch to BETA, and an unaffordable switch back
to ALFA. The `momentum strategy` OUnit group checks cash, holdings, and value
on all seven dates; it finishes with $134.50 cash, no holdings, and $134.50
value because ALFA remains the remembered target.

## Command-line report check

The Cram group runs all strategies with $10,000.00 on
`data/small-spy-5days.csv`. Cash finishes at $10,000.00, no holdings, and
0.00%. Buy-and-hold buys 95 SPY, leaves $62.05, and finishes at $10,333.45
(3.33%). Momentum buys 94 SPY on September 16, leaves $3.10, and finishes at
$10,166.38 (1.66%). Each complete standard-output summary is checked.

Validation command: `dune build && dune runtest --force`; all OUnit groups and
the Cram report test pass.

## Consequential revisions

**Original initial plan (retained).** Start with market parsing, then portfolio
accounting, then a generic engine and command-line integration.

I revised that component-level sequence into the end-to-end slices above,
while still implementing the internals bottom-up. This made each milestone
observable through a strategy run and its resulting dated portfolio states. I
also added recorded rejected orders to the engine so that a rejection could be
tested without preventing later proposed orders.

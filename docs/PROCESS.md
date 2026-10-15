# Development and Validation Record

## Milestone 1: Read and represent market data

**Initial plan.** Read a market CSV with the `csv` package, preserve dates and
securities in file order, and convert prices to integer cents. Check the tiny
handout file and verify a missing path gives a useful error.

**Actual result.** `Market.load` uses `Csv.load`; `Market.daily_prices` pairs
each date's prices with security names in header order. The OUnit case
`market daily prices pair securities and cents` checks all three rows of
`data/handout.csv`. The missing-file behavior was checked from the command
line and returned an error with status 1. `dune build` and the then-current
test suite passed. The CLI still only prints parsed market data; it does not
yet run a strategy.

## Milestone 2: Account for orders

**Initial plan.** Store cash and whole-share holdings in cents/shares. Accept
valid buys and sells; reject invalid orders without changing the portfolio.
Check each rejection and verify that valuation uses the supplied prices.

**Actual result.** `Portfolio.apply` implements the order rules and returns a
new portfolio or a rejection. The OUnit tests cover buys, sells, zero and
negative quantities, unknown securities, insufficient cash, insufficient
shares, and valuation at a changed price. These accounting tests passed as
part of the 11-test suite. Holdings are exposed as a sorted list.

## Milestone 3: Run a strategy through the engine

**Initial plan.** Define one strategy interface that receives only the
current date and its prices, then returns its updated private state and
orders. The engine should process orders in sequence and record the
post-order portfolio value for each date.

**Actual result.** `Engine.Strategy` and `Engine.Make` provide a shared
interface and loop. Each call receives only the current date's prices and
the portfolio before that date's orders. The engine applies orders in order
and records post-order values. OUnit tests check dated values, rejection
handling, and momentum transitions. `dune build` and all 13 tests passed.
The CLI is not yet wired to the engine.

## Milestone 4: Strategies, reports, and command line

**Initial plan.** Implement cash, buy-and-hold, and one-day momentum strategies,
then connect them to the CLI. Print the R6 summary and handle invalid
arguments, strategy names, cash amounts, and hold selections. Add Cram tests
for complete output and error cases.

**Actual result.** Cash, buy-and-hold, and momentum strategy modules exist.
The CLI still only prints parsed market data; the final R6 report, argument
handling, and Cram tests are not implemented yet.

## Cash on the supplied tiny market file

For the planned cash strategy with $100.00 on `data/handout.csv`, there are no
orders: cash and value remain $100.00 on every date, with no holdings.

| Date | Cash | Holdings | Value |
|---|---:|---|---:|
| 2024-01-02 | $100.00 | none | $100.00 |
| 2024-01-03 | $100.00 | none | $100.00 |
| 2024-01-04 | $100.00 | none | $100.00 |

Planned OUnit group: `cash_handout`. It does not exist yet.

## Buy-and-hold predictions

These are hand calculations for the planned behavior: buy as many whole
shares as possible on the first date, then hold. They are not strategy test
results yet.

On `data/handout.csv`, start with $100.00. Holding ALFA buys 10 shares for
$100.00; holding BETA buys 4 shares for $100.00.

| Date | ALFA: cash / shares / value | BETA: cash / shares / value |
|---|---|---|
| 2024-01-02 | $0.00 / 10 / $100.00 | $0.00 / 4 / $100.00 |
| 2024-01-03 | $0.00 / 10 / $120.00 | $0.00 / 4 / $80.00 |
| 2024-01-04 | $0.00 / 10 / $110.00 | $0.00 / 4 / $84.00 |

Planned additional fixture, `buy_hold_example.csv`, with $25.00 and ORBI
selected; it exercises multiple securities, leftover cash, and a changing
held price:

```csv
date,ORBI,NOVA
2025-01-02,7.00,12.00
2025-01-03,9.00,10.00
2025-01-06,8.00,13.00
```

The first-date purchase is 3 ORBI shares for $21.00, leaving $4.00. Predicted
daily values are $25.00, $31.00, and $28.00, with cash $4.00 and 3 ORBI shares
throughout. Planned OUnit group: `buy_hold_handout` and
`buy_hold_example`; neither exists yet.

## Stateful-strategy predictions

The implemented rule is one-day momentum: after the first date, select the
security with the greatest positive absolute price increase; ties go to the
first security in header order. If none increased, keep the prior target.
On a target change, sell the old holding before buying as many shares as
possible of the new target. `Momentum` retains the previous prices and target
in private state.

On `data/handout.csv` with $100.00, the predicted states are: 2024-01-02,
$100.00 cash and no holdings; 2024-01-03, $4.00 cash and 8 ALFA shares
(value $100.00); 2024-01-04, $8.00 cash and 4 BETA shares (value $92.00).

The OUnit test `momentum tie, retention, and target switch` exercises the
specified transitions using direct dated price rows and a $120.00 portfolio:
first-day no-trade, first-in-header tie-breaking, no-increase retention,
unchanged-target no-trade, sell-before-buy switching, and an unaffordable
new target that is remembered. `momentum runs through engine on handout
market` also verifies the strategy through the engine.

The following fixture is a planning example; the tests use direct price rows
instead of loading this CSV:

```csv
date,ALFA,BETA
2025-01-02,10.00,10.00
2025-01-03,12.00,12.00
2025-01-06,11.00,11.00
2025-01-07,13.00,12.00
2025-01-08,13.00,14.00
2025-01-09,200.00,14.50
```

The intended behaviors for this planning example are covered with direct
price rows in the OUnit tests.

## Command-line report check

These are hand-calculated predictions for the planned strategies on
`data/small-spy-5days.csv` with $10,000.00, not program output. Cash should end
at $10,000.00, with no holdings, value $10,000.00, and 0.0000% return.
Buy-and-hold should buy 95 SPY shares on the first date, leaving $62.05 cash;
final value should be $10,333.45 and return 3.3345%. Under the momentum rule,
the first positive increase is on September 16: buy 94 shares at $106.35,
leaving $3.10. The only security remains the target, so no later trade is
predicted; final value should be $10,166.38 and return 1.6638%.

Planned Cram groups: `report_cash_spy`, `report_buy_hold_spy`, and
`report_momentum_spy`, each comparing complete standard output. They are not
implemented, and the predicted summaries must be checked against the final
R6 format.

## Consequential revisions

The initial milestones planned end-to-end CLI behavior early. Work instead
proceeded bottom-up: market representation, portfolio accounting, strategies,
then a generic engine. This made components independently testable, but
reporting and command-line integration remain outstanding. The engine records
rejected orders in each daily result for testability; a rejection leaves the
portfolio unchanged and does not stop later orders.

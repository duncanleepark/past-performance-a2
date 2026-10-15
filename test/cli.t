  $ dune exec a2 -- ../data/small-spy-5days.csv cash /tmp/a2-r7-cash.csv --cash 10000.00
  Strategy: cash
  Period: 2008-09-15 to 2008-09-19
  Initial cash: $10000.00
  Final cash: $10000.00
  Final holdings: none
  Final portfolio value: $10000.00
  Total return: 0.00%
  $ dune exec a2 -- ../data/small-spy-5days.csv buy-and-hold /tmp/a2-r7-buy-hold.csv --cash 10000.00 --hold SPY
  Strategy: buy-and-hold
  Period: 2008-09-15 to 2008-09-19
  Initial cash: $10000.00
  Final cash: $62.05
  Final holdings:
    SPY: 95 shares
  Final portfolio value: $10333.45
  Total return: 3.33%
  $ dune exec a2 -- ../data/small-spy-5days.csv momentum /tmp/a2-r7-momentum.csv --cash 10000.00
  Strategy: momentum
  Period: 2008-09-15 to 2008-09-19
  Initial cash: $10000.00
  Final cash: $3.10
  Final holdings:
    SPY: 94 shares
  Final portfolio value: $10166.38
  Total return: 1.66%

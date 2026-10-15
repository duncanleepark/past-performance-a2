open OUnit2
open Backtester

let load_market path =
  match Market.load path with
  | Ok market -> market
  | Error message -> assert_failure ("could not load " ^ path ^ ": " ^ message)

let initial_cash = 10_000

module Run_cash = Engine.Make (Cash)
module Run_momentum = Engine.Make (Momentum)

let run_buy_and_hold ~cash symbol market =
  let module Strategy = Buy_and_hold.Make (struct
    let symbol = symbol
  end) in
  let module Simulation = Engine.Make (Strategy) in
  Simulation.run ~initial_cash:cash market

let string_of_day (date, cash, holdings, value) =
  Printf.sprintf "%s cash=%d holdings=[%s] value=%d" date cash
    (String.concat "; "
       (List.map (fun (symbol, shares) -> Printf.sprintf "%s=%d" symbol shares) holdings))
    value

let string_of_days days = String.concat "\n" (List.map string_of_day days)

let check_days label (result : Engine.result) expected =
  let actual =
    List.map
      (fun (day : Engine.daily_result) ->
        (day.date, day.cash, day.holdings, day.value))
      result.daily_results
  in
  assert_equal ~msg:label ~printer:string_of_days expected actual

let handout_days = [ "2024-01-02"; "2024-01-03"; "2024-01-04" ]

let cash_tests =
  "cash strategy on handout" >::: [
    "cash, holdings, and value remain unchanged each date" >:: (fun _ ->
        let market = load_market "../data/handout.csv" in
        let result = Run_cash.run ~initial_cash market in
        check_days "cash handout" result
          [
            (List.nth handout_days 0, 10_000, [], 10_000);
            (List.nth handout_days 1, 10_000, [], 10_000);
            (List.nth handout_days 2, 10_000, [], 10_000);
          ])
  ]

let buy_and_hold_tests =
  "buy-and-hold strategy" >::: [
    "handout ALFA purchase and all daily valuations" >:: (fun _ ->
        let market = load_market "../data/handout.csv" in
        let result = run_buy_and_hold ~cash:initial_cash "ALFA" market in
        check_days "buy-and-hold handout ALFA" result
          [
            ("2024-01-02", 0, [ ("ALFA", 10) ], 10_000);
            ("2024-01-03", 0, [ ("ALFA", 10) ], 12_000);
            ("2024-01-04", 0, [ ("ALFA", 10) ], 11_000);
          ]);
    "own fixture leaves cash and tracks changing held price" >:: (fun _ ->
        let market = load_market "../data/r7-buy-hold.csv" in
        let result = run_buy_and_hold ~cash:2_500 "ORBI" market in
        check_days "buy-and-hold r7 fixture" result
          [
            ("2025-01-02", 400, [ ("ORBI", 3) ], 2_500);
            ("2025-01-03", 400, [ ("ORBI", 3) ], 3_100);
            ("2025-01-06", 400, [ ("ORBI", 3) ], 2_800);
          ])
  ]

let momentum_tests =
  "momentum strategy" >::: [
    "handout selection and daily values" >:: (fun _ ->
        let market = load_market "../data/handout.csv" in
        let result = Run_momentum.run ~initial_cash market in
        check_days "momentum handout" result
          [
            ("2024-01-02", 10_000, [], 10_000);
            ("2024-01-03", 400, [ ("ALFA", 8) ], 10_000);
            ("2024-01-04", 800, [ ("BETA", 4) ], 9_200);
          ]);
    "own fixture exercises tie, retention, switch, and unaffordable target"
    >:: (fun _ ->
          let market = load_market "../data/r7-momentum.csv" in
          let result = Run_momentum.run ~initial_cash:12_000 market in
          check_days "momentum r7 fixture" result
            [
              ("2025-01-02", 12_000, [], 12_000);
              ("2025-01-03", 0, [ ("ALFA", 10) ], 12_000);
              ("2025-01-06", 0, [ ("ALFA", 10) ], 11_000);
              ("2025-01-07", 0, [ ("ALFA", 10) ], 13_000);
              ("2025-01-08", 400, [ ("BETA", 9) ], 13_000);
              ("2025-01-09", 13_450, [], 13_450);
              ("2025-01-10", 13_450, [], 13_450);
            ])
  ]

let tests =
  "R7 strategy evidence" >::: [ cash_tests; buy_and_hold_tests; momentum_tests ]

let () = run_test_tt_main tests

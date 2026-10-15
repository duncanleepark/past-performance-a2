open OUnit2
open Backtester

let prices = [ ("ALFA", 1_000); ("BETA", 2_500) ]

let order security direction quantity : Order.t =
  { security; direction; quantity }

let assert_rejected expected portfolio trade =
  match Portfolio.apply portfolio ~prices trade with
  | Error actual ->
      assert_equal expected actual;
      assert_equal 10_000 (Portfolio.cash portfolio);
      assert_equal [] (Portfolio.holdings portfolio)
  | Ok _ -> assert_failure "expected the order to be rejected"

module Buy_once = struct
  type state = unit

  let initial_state () = ()

  let next state ~date:_ ~prices:_ ~portfolio =
    let orders =
      if Portfolio.shares portfolio "ALFA" = 0 then
        [ order "ALFA" Order.Buy 1 ]
      else []
    in
    (state, orders)
end

module Buy_once_engine = Engine.Make (Buy_once)

module Rejection_then_buy = struct
  type state = bool

  let initial_state () = false

  let next has_run ~date:_ ~prices:_ ~portfolio:_ =
    if has_run then (true, [])
    else
      ( true,
        [
          order "BETA" Order.Buy 5;
          order "ALFA" Order.Buy 1;
        ] )
end

module Rejection_then_buy_engine = Engine.Make (Rejection_then_buy)
module Momentum_engine = Engine.Make (Momentum)
module Cash_engine = Engine.Make (Cash)

module Hold_alfa = Buy_and_hold.Make (struct
  let symbol = "ALFA"
end)

module Hold_alfa_engine = Engine.Make (Hold_alfa)

let apply_orders portfolio prices orders =
  List.fold_left
    (fun portfolio trade ->
      match Portfolio.apply portfolio ~prices trade with
      | Ok updated -> updated
      | Error _ -> assert_failure "momentum produced a rejected order")
    portfolio orders

let momentum_step state portfolio prices =
  let next_state, orders =
    Momentum.next state ~date:"test-date" ~prices ~portfolio
  in
  (next_state, apply_orders portfolio prices orders, orders)

let tests =
  "test suite" >::: [
    "buy updates cash and holdings" >:: (fun _ ->
        let initial = Portfolio.create ~cash:10_000 in
        match Portfolio.apply initial ~prices (order "ALFA" Order.Buy 3) with
        | Error _ -> assert_failure "valid buy was rejected"
        | Ok bought ->
            assert_equal 7_000 (Portfolio.cash bought);
            assert_equal 3 (Portfolio.shares bought "ALFA");
            assert_equal [ ("ALFA", 3) ] (Portfolio.holdings bought);
            assert_equal 10_000 (Portfolio.value bought ~prices));
    "sell updates cash and removes empty holding" >:: (fun _ ->
        let initial = Portfolio.create ~cash:10_000 in
        let bought =
          match Portfolio.apply initial ~prices (order "ALFA" Order.Buy 3) with
          | Ok portfolio -> portfolio
          | Error _ -> assert_failure "valid buy was rejected"
        in
        match Portfolio.apply bought ~prices (order "ALFA" Order.Sell 3) with
        | Error _ -> assert_failure "valid sell was rejected"
        | Ok sold ->
            assert_equal 10_000 (Portfolio.cash sold);
            assert_equal 0 (Portfolio.shares sold "ALFA");
            assert_equal [] (Portfolio.holdings sold));
    "zero quantity is rejected without changing portfolio" >:: (fun _ ->
        assert_rejected Portfolio.Non_positive_quantity
          (Portfolio.create ~cash:10_000)
          (order "ALFA" Order.Buy 0));
    "negative quantity is rejected without changing portfolio" >:: (fun _ ->
        assert_rejected Portfolio.Non_positive_quantity
          (Portfolio.create ~cash:10_000)
          (order "ALFA" Order.Sell (-1)));
    "unknown security is rejected without changing portfolio" >:: (fun _ ->
        assert_rejected Portfolio.Unknown_security
          (Portfolio.create ~cash:10_000)
          (order "GAMMA" Order.Buy 1));
    "unaffordable buy is rejected without changing portfolio" >:: (fun _ ->
        assert_rejected Portfolio.Insufficient_cash
          (Portfolio.create ~cash:10_000)
          (order "BETA" Order.Buy 5));
    "oversell is rejected without changing portfolio" >:: (fun _ ->
        assert_rejected Portfolio.Insufficient_shares
          (Portfolio.create ~cash:10_000)
          (order "ALFA" Order.Sell 1));
    "value uses supplied current prices" >:: (fun _ ->
        let portfolio = Portfolio.create ~cash:1_000 in
        let bought =
          match Portfolio.apply portfolio ~prices (order "ALFA" Order.Buy 1) with
          | Ok portfolio -> portfolio
          | Error _ -> assert_failure "valid buy was rejected"
        in
        assert_equal 1_100
          (Portfolio.value bought ~prices:[ ("ALFA", 1_100) ]));
    "market daily prices pair securities and cents" >:: (fun _ ->
        match Market.load "../data/handout.csv" with
        | Error msg -> assert_failure ("could not load handout market: " ^ msg)
        | Ok market ->
            assert_equal
              [
                ("2024-01-02", [ ("ALFA", 1_000); ("BETA", 2_500) ]);
                ("2024-01-03", [ ("ALFA", 1_200); ("BETA", 2_000) ]);
                ("2024-01-04", [ ("ALFA", 1_100); ("BETA", 2_100) ]);
              ]
              (Market.daily_prices market));
    "engine records post-order values for each date" >:: (fun _ ->
        match Market.load "../data/handout.csv" with
        | Error msg -> assert_failure ("could not load handout market: " ^ msg)
        | Ok market ->
            let result =
              Buy_once_engine.run ~initial_cash:10_000 market
            in
            assert_equal
              [ ("2024-01-02", 9_000, [ ("ALFA", 1) ], 10_000);
                ("2024-01-03", 9_000, [ ("ALFA", 1) ], 10_200);
                ("2024-01-04", 9_000, [ ("ALFA", 1) ], 10_100) ]
              (List.map
                 (fun (day : Engine.daily_result) ->
                   (day.date, day.cash, day.holdings, day.value))
                 result.daily_results);
            assert_equal 9_000 result.final_cash;
            assert_equal [ ("ALFA", 1) ] result.final_holdings;
            assert_equal 10_100 result.final_value;
            assert_equal 1.0 result.total_return);
    "engine continues after rejected order" >:: (fun _ ->
        match Market.load "../data/handout.csv" with
        | Error msg -> assert_failure ("could not load handout market: " ^ msg)
        | Ok market ->
            let result =
              Rejection_then_buy_engine.run ~initial_cash:10_000 market
            in
            match result.daily_results with
            | first_day :: _ ->
                assert_equal 1 (List.length first_day.rejections);
                assert_equal
                  [ ("ALFA", 1) ]
                  first_day.holdings;
                assert_equal 9_000 first_day.cash;
                assert_equal 10_000 first_day.value
            | [] -> assert_failure "engine returned no daily results")
    ;
    "cash strategy makes no trades" >:: (fun _ ->
        match Market.load "../data/handout.csv" with
        | Error msg -> assert_failure ("could not load handout market: " ^ msg)
        | Ok market ->
            let result = Cash_engine.run ~initial_cash:10_000 market in
            assert_equal 10_000 result.final_cash;
            assert_equal [] result.final_holdings;
            assert_equal 10_000 result.final_value;
            assert_equal [ 10_000; 10_000; 10_000 ]
              (List.map
                 (fun (day : Engine.daily_result) -> day.value)
                 result.daily_results));
    "buy and hold buys whole shares once" >:: (fun _ ->
        match Market.load "../data/handout.csv" with
        | Error msg -> assert_failure ("could not load handout market: " ^ msg)
        | Ok market ->
            let result = Hold_alfa_engine.run ~initial_cash:10_000 market in
            assert_equal 0 result.final_cash;
            assert_equal [ ("ALFA", 10) ] result.final_holdings;
            assert_equal 11_000 result.final_value;
            assert_equal [ 10_000; 12_000; 11_000 ]
              (List.map
                 (fun (day : Engine.daily_result) -> day.value)
                 result.daily_results));
    "momentum tie, retention, and target switch" >:: (fun _ ->
        let state = Momentum.initial_state () in
        let portfolio = Portfolio.create ~cash:12_000 in
        let state, portfolio, orders =
          momentum_step state portfolio [ ("ALFA", 1_000); ("BETA", 1_000) ]
        in
        assert_equal [] orders;
        assert_equal 12_000 (Portfolio.cash portfolio);
        let state, portfolio, orders =
          momentum_step state portfolio [ ("ALFA", 1_200); ("BETA", 1_200) ]
        in
        assert_equal [ order "ALFA" Order.Buy 10 ] orders;
        assert_equal 0 (Portfolio.cash portfolio);
        assert_equal 10 (Portfolio.shares portfolio "ALFA");
        let state, portfolio, orders =
          momentum_step state portfolio [ ("ALFA", 1_100); ("BETA", 1_100) ]
        in
        assert_equal [] orders;
        assert_equal 10 (Portfolio.shares portfolio "ALFA");
        let state, portfolio, orders =
          momentum_step state portfolio [ ("ALFA", 1_300); ("BETA", 1_200) ]
        in
        assert_equal [] orders;
        assert_equal 10 (Portfolio.shares portfolio "ALFA");
        let state, portfolio, orders =
          momentum_step state portfolio [ ("ALFA", 1_300); ("BETA", 1_400) ]
        in
        assert_equal
          [ order "ALFA" Order.Sell 10; order "BETA" Order.Buy 9 ]
          orders;
        assert_equal 400 (Portfolio.cash portfolio);
        assert_equal [ ("BETA", 9) ] (Portfolio.holdings portfolio);
        assert_equal 9 (Portfolio.shares portfolio "BETA");
        let state, portfolio, orders =
          momentum_step state portfolio [ ("ALFA", 20_000); ("BETA", 1_450) ]
        in
        assert_equal [ order "BETA" Order.Sell 9 ] orders;
        assert_equal 13_450 (Portfolio.cash portfolio);
        assert_equal [] (Portfolio.holdings portfolio);
        let _state, portfolio, orders =
          momentum_step state portfolio [ ("ALFA", 20_100); ("BETA", 1_460) ]
        in
        assert_equal [] orders;
        assert_equal 13_450 (Portfolio.cash portfolio));
    "momentum runs through engine on handout market" >:: (fun _ ->
        match Market.load "../data/handout.csv" with
        | Error msg -> assert_failure ("could not load handout market: " ^ msg)
        | Ok market ->
            let result =
              Momentum_engine.run ~initial_cash:10_000 market
            in
            assert_equal 800 result.final_cash;
            assert_equal [ ("BETA", 4) ] result.final_holdings;
            assert_equal 9_200 result.final_value;
            assert_equal 9_200
              (List.hd (List.rev result.daily_results)).value)
  ]

let _ = run_test_tt_main tests

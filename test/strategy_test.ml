open OUnit2
open Backtester

(* The contents of data/handout.csv. Written to a temporary file so this test
   needs no dune dependency on the data/ folder. For the final R7 tests, load
   the real file instead. *)
let handout_csv =
  "date,ALFA,BETA\n\
   2024-01-02,10.00,25.00\n\
   2024-01-03,12.00,20.00\n\
   2024-01-04,11.00,21.00\n"

let market_of_csv contents =
  let path = Filename.temp_file "market" ".csv" in
  let oc = open_out path in
  output_string oc contents;
  close_out oc;
  let loaded = Market.load path in
  Sys.remove path;
  match loaded with Ok m -> m | Error msg -> failwith msg

let handout = market_of_csv handout_csv
let initial_cash = 10000

module Run_cash = Engine.Make (Cash)
module Run_momentum = Engine.Make (Momentum)

let run_buy_and_hold symbol market =
  let module S = Buy_and_hold.Make (struct
    let symbol = symbol
  end) in
  let module E = Engine.Make (S) in
  E.run ~initial_cash market

let string_of_day (date, cash, holdings, value) =
  Printf.sprintf "%s cash=%d holdings=[%s] value=%d" date cash
    (String.concat "; "
       (List.map (fun (s, n) -> Printf.sprintf "%s=%d" s n) holdings))
    value

let string_of_days days = String.concat "\n" (List.map string_of_day days)

(* Compares date, cash, holdings and value on every date. *)
let check_days label (result : Engine.result) expected =
  let actual =
    List.map
      (fun (d : Engine.daily_result) ->
        (d.Engine.date, d.Engine.cash, d.Engine.holdings, d.Engine.value))
      result.Engine.daily_results
  in
  assert_equal ~msg:label ~printer:string_of_days expected actual

let d1 = "2024-01-02"
let d2 = "2024-01-03"
let d3 = "2024-01-04"

let tests =
  "strategies on handout.csv with $100.00"
  >::: [
         ( "cash: nothing ever changes" >:: fun _ ->
           check_days "cash"
             (Run_cash.run ~initial_cash handout)
             [
               (d1, 10000, [], 10000);
               (d2, 10000, [], 10000);
               (d3, 10000, [], 10000);
             ] );
         ( "buy-and-hold ALFA: 10 shares at 10.00, no cash left" >:: fun _ ->
           check_days "hold ALFA"
             (run_buy_and_hold "ALFA" handout)
             [
               (d1, 0, [ ("ALFA", 10) ], 10000);
               (d2, 0, [ ("ALFA", 10) ], 12000);
               (d3, 0, [ ("ALFA", 10) ], 11000);
             ] );
         ( "buy-and-hold BETA: 4 shares at 25.00, no cash left" >:: fun _ ->
           check_days "hold BETA"
             (run_buy_and_hold "BETA" handout)
             [
               (d1, 0, [ ("BETA", 4) ], 10000);
               (d2, 0, [ ("BETA", 4) ], 8000);
               (d3, 0, [ ("BETA", 4) ], 8400);
             ] );
         ( "momentum: ALFA on 01-03, then switch to BETA on 01-04" >:: fun _ ->
           (* 01-02: first date, no orders.
              01-03: ALFA +2.00 beats BETA -5.00; buy 8 ALFA at 12.00
                     (96.00), cash 4.00.
              01-04: BETA +1.00 beats ALFA -1.00; sell 8 ALFA at 11.00
                     (cash 92.00), buy 4 BETA at 21.00 (84.00), cash 8.00. *)
           let result = Run_momentum.run ~initial_cash handout in
           check_days "momentum" result
             [
               (d1, 10000, [], 10000);
               (d2, 400, [ ("ALFA", 8) ], 10000);
               (d3, 800, [ ("BETA", 4) ], 9200);
             ];
           assert_equal ~printer:string_of_int 9200 result.Engine.final_value;
           assert_equal ~printer:string_of_float
             ~cmp:(fun a b -> Float.abs (a -. b) < 1e-9)
             (-8.0) result.Engine.total_return );
       ]

let () = run_test_tt_main tests
open OUnit2
open Backtester

let string_of_opt = function
  | None -> "None"
  | Some n -> "Some " ^ string_of_int n

let accepts (input, cents) =
  "parses " ^ input >:: fun _ ->
  assert_equal ~printer:string_of_opt (Some cents) (Money.of_string input)

let rejects input =
  "rejects '" ^ input ^ "'" >:: fun _ ->
  assert_equal ~printer:string_of_opt None (Money.of_string input)

let formats (cents, text) =
  "formats " ^ string_of_int cents >:: fun _ ->
  assert_equal ~printer:(fun s -> s) text (Money.to_string cents)

let tests =
  "money"
  >::: List.concat
         [
           List.map accepts
             [
               ("10.00", 1000);
               ("0.05", 5);
               ("10000.01", 1000001);
               ("0.00", 0);
               ("05.00", 500);
             ];
           List.map rejects
             [
               "";
               "10";
               "10.5";
               "10.505";
               ".50";
               "10.";
               "-5.00";
               "abc";
               " 10.00";
               "10.0a";
               "1.2.3";
               "1,000.00";
             ];
           List.map formats
             [
               (0, "0.00"); (5, "0.05"); (1000, "10.00"); (1000001, "10000.01");
             ];
         ]

let () = run_test_tt_main tests

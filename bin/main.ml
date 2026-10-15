open Backtester

let usage =
  "usage: a2 MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]"

let parse_options args =
  let rec loop cash hold = function
    | [] -> Ok (cash, hold)
    | "--cash" :: amount :: rest ->
        if Option.is_some cash then Error "--cash may only be specified once"
        else loop (Some amount) hold rest
    | "--hold" :: symbol :: rest ->
        if Option.is_some hold then Error "--hold may only be specified once"
        else loop cash (Some symbol) rest
    | [ option ] when option = "--cash" || option = "--hold" ->
        Error (option ^ " requires a value")
    | option :: _ -> Error ("unrecognized argument: " ^ option)
  in
  loop None None args

let run_strategy (module Strategy : Engine.Strategy) ~initial_cash market =
  let module Simulation = Engine.Make (Strategy) in
  Simulation.run ~initial_cash market

let fail message =
  prerr_endline ("error: " ^ message);
  prerr_endline usage;
  exit 1

let run argv =
  match argv with
  | _program :: market_path :: strategy_name :: equity_path :: options ->
      let cash_arg, hold_arg =
        match parse_options options with
        | Ok options -> options
        | Error message -> fail message
      in
      let initial_cash =
        match cash_arg with
        | None -> fail "missing required --cash DOLLARS"
        | Some amount ->
            (match Money.of_string amount with
             | Some cents when cents > 0 -> cents
             | _ -> fail "cash must be a positive amount with exactly two decimal places")
      in
      let market =
        match Market.load market_path with
        | Ok market -> market
        | Error message -> fail message
      in
      let strategy =
        match strategy_name with
        | "cash" ->
            run_strategy (module Cash) ~initial_cash market
        | "momentum" ->
            run_strategy (module Momentum) ~initial_cash market
        | "buy-and-hold" ->
            let symbol =
              match hold_arg with
              | None -> fail "buy-and-hold requires --hold SYMBOL"
              | Some symbol -> symbol
            in
            if not (List.mem symbol (Market.securities market)) then
              fail ("unknown security for --hold: " ^ symbol);
            let module Buy_and_hold_strategy =
              Buy_and_hold.Make (struct
                let symbol = symbol
              end)
            in
            run_strategy
              (module Buy_and_hold_strategy)
              ~initial_cash market
        | name -> fail ("unknown strategy: " ^ name)
      in
      (match Report.write equity_path strategy with
       | Error message -> fail message
       | Ok () -> print_string (Report.render ~strategy:strategy_name strategy))
  | _ -> fail "expected exactly three positional arguments"

let () = run (Array.to_list Sys.argv)

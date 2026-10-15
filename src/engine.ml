module type Strategy = sig
  type state

  val initial_state : unit -> state

  val next :
    state ->
    date:string ->
    prices:Market.prices ->
    portfolio:Portfolio.t ->
    state * Order.t list
end

type daily_result = {
  date : string;
  cash : int;
  holdings : (string * int) list;
  value : int;
  rejections : (Order.t * Portfolio.rejection) list;
}

type result = {
  initial_cash : int;
  final_cash : int;
  final_holdings : (string * int) list;
  final_value : int;
  total_return : float;
  daily_results : daily_result list;
}

module Make (S : Strategy) = struct
  let run ~initial_cash market =
    let initial_portfolio = Portfolio.create ~cash:initial_cash in
    let initial_strategy_state = S.initial_state () in
    let portfolio, _, reversed_daily_results =
      List.fold_left
        (fun (portfolio, strategy_state, results) (date, prices) ->
          let next_strategy_state, orders =
            S.next strategy_state ~date ~prices ~portfolio
          in
          let portfolio, rejections =
            List.fold_left
              (fun (portfolio, rejections) order ->
                match Portfolio.apply portfolio ~prices order with
                | Ok updated -> (updated, rejections)
                | Error reason -> (portfolio, (order, reason) :: rejections))
              (portfolio, []) orders
          in
          let daily_result =
            {
              date;
              cash = Portfolio.cash portfolio;
              holdings = Portfolio.holdings portfolio;
              value = Portfolio.value portfolio ~prices;
              rejections = List.rev rejections;
            }
          in
          (portfolio, next_strategy_state, daily_result :: results))
        (initial_portfolio, initial_strategy_state, [])
        (Market.daily_prices market)
    in
    let final_value =
      match reversed_daily_results with
      | [] -> Portfolio.cash portfolio
      | last_day :: _ -> last_day.value
    in
    let total_return =
      (float_of_int final_value -. float_of_int initial_cash)
      /. float_of_int initial_cash
      *. 100.0
    in
    {
      initial_cash;
      final_cash = Portfolio.cash portfolio;
      final_holdings = Portfolio.holdings portfolio;
      final_value;
      total_return;
      daily_results = List.rev reversed_daily_results;
    }
end
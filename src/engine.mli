(** A strategy owns its private state. On each date, [next] receives only that
    date's prices and the portfolio as it stands before that date's orders, and
    returns the updated state and the orders to process. *)
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

(** Run a strategy across the market, processing dates and orders in order. *)
module Make (S : Strategy) : sig
  val run : initial_cash:int -> Market.t -> result
  (** [run ~initial_cash market] runs the strategy from an all-cash portfolio.
      Total return is a percentage, e.g. [6.0] represents a 6% return. *)
end

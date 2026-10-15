(** Buy-and-hold strategy: on the first date, buy as many whole shares as
    possible of one security, then never trade again. The security is chosen
    when the strategy is instantiated. *)

module Make (C : sig
  val symbol : string
end) : Engine.Strategy

module Make (C : sig
  val symbol : string
end) =
struct
  (* Whether the first date has already been handled. *)
  type state = bool

  let initial_state () = false

  let next already_acted ~date:_ ~prices ~portfolio =
    if already_acted then (true, [])
    else
      match List.assoc_opt C.symbol prices with
      | None -> (true, [])
      | Some price ->
          let quantity = Portfolio.cash portfolio / price in
          if quantity > 0 then
            ( true,
              [ { Order.security = C.symbol; direction = Order.Buy; quantity } ]
            )
          else (true, [])
end
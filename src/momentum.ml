(* [previous] is the preceding date's prices, [target] the security selected so
   far (None until a positive increase has been seen). *)
type state = {
  previous : Market.prices option;
  target : string option;
}

let initial_state () = { previous = None; target = None }

(* The security with the largest strictly positive increase since [previous].
   [prices] is in file order and a later security replaces the current best only
   if its increase is strictly larger, so ties go to the earliest. *)
let best_riser ~previous ~prices =
  List.fold_left
    (fun best (security, price) ->
      match List.assoc_opt security previous with
      | None -> best
      | Some old_price -> (
          let increase = price - old_price in
          if increase <= 0 then best
          else
            match best with
            | Some (_, best_increase) when best_increase >= increase -> best
            | _ -> Some (security, increase)))
    None prices
  |> Option.map fst

let sell_everything portfolio =
  List.map
    (fun (security, quantity) ->
      { Order.security; direction = Order.Sell; quantity })
    (Portfolio.holdings portfolio)

let next state ~date:_ ~prices ~portfolio =
  let remember target = { previous = Some prices; target } in
  match state.previous with
  | None -> (remember None, [])
  | Some previous -> (
      match best_riser ~previous ~prices with
      | None -> (remember state.target, [])
      | Some choice when state.target = Some choice ->
          (remember state.target, [])
      | Some choice ->
          (* Selling everything at today's prices yields exactly the portfolio's
             value, so that is the budget for the new purchase. *)
          let budget = Portfolio.value portfolio ~prices in
          let price = List.assoc choice prices in
          let quantity = budget / price in
          let buys =
            if quantity > 0 then
              [ { Order.security = choice; direction = Order.Buy; quantity } ]
            else []
          in
          (remember (Some choice), sell_everything portfolio @ buys))

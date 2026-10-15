module String_map = Map.Make (String)

type t = {
  cash : int;
  holdings: int String_map.t;
}

type rejection =
  | Non_positive_quantity
  | Unknown_security
  | Insufficient_shares
  | Insufficient_cash

let create ~cash =
  { cash; holdings = String_map.empty }

let cash p = p.cash
let holdings p = String_map.bindings p.holdings

let shares p security =
  match String_map.find_opt security p.holdings with
  | Some quantity -> quantity
  | None -> 0

let buy p security price quantity =
  let amount = quantity * price in
  if amount > p.cash then Error Insufficient_cash
  else
    let new_cash = p.cash - amount in
    let new_holdings =
      let current_quantity = shares p security in
      String_map.add security (current_quantity + quantity) p.holdings
    in
    Ok { cash = new_cash; holdings = new_holdings }

let sell p security price quantity =
  let held = shares p security in
  if quantity > held then Error Insufficient_shares
  else
    let remaining = held - quantity in
    let holdings =
      if remaining = 0 then String_map.remove security p.holdings
      else String_map.add security remaining p.holdings
    in
    Ok { cash = p.cash + (quantity * price); holdings }

let apply p ~prices { Order.security; direction; quantity } =
  if quantity <= 0 then Error Non_positive_quantity
  else
    match List.assoc_opt security prices with
    | None -> Error Unknown_security
    | Some price ->
        (match direction with
         | Order.Buy -> buy p security price quantity
         | Order.Sell -> sell p security price quantity)

let value p ~prices =
  String_map.fold
    (fun security quantity acc ->
      match List.assoc_opt security prices with
      | None -> acc
      | Some price -> acc + (quantity * price))
    p.holdings p.cash
let dollars cents = "$" ^ Money.to_string cents

let shares_phrase n =
  if n = 1 then "1 share" else Printf.sprintf "%d shares" n

(* Dates of the first and last rows. A valid market file has at least one
   row, so the empty case does not occur in practice. *)
let period (result : Engine.result) =
  match result.Engine.daily_results with
  | [] -> ("n/a", "n/a")
  | first :: _ as days ->
      let last = List.hd (List.rev days) in
      (first.Engine.date, last.Engine.date)

let holdings_lines = function
  | [] -> [ "Final holdings: none" ]
  | holdings ->
      "Final holdings:"
      :: List.map
           (fun (security, quantity) ->
             Printf.sprintf "  %s: %s" security (shares_phrase quantity))
           holdings

let render ~strategy (result : Engine.result) =
  let first_date, last_date = period result in
  let lines =
    [
      "Strategy: " ^ strategy;
      Printf.sprintf "Period: %s to %s" first_date last_date;
      "Initial cash: " ^ dollars result.Engine.initial_cash;
      "Final cash: " ^ dollars result.Engine.final_cash;
    ]
    @ holdings_lines result.Engine.final_holdings
    @ [
        "Final portfolio value: " ^ dollars result.Engine.final_value;
        Printf.sprintf "Total return: %.2f%%" result.Engine.total_return;
      ]
  in
  String.concat "\n" lines ^ "\n"

let equity_csv (result : Engine.result) =
  let rows =
    List.map
      (fun (day : Engine.daily_result) ->
        Printf.sprintf "%s,%s\n" day.Engine.date (Money.to_string day.Engine.value))
      result.Engine.daily_results
  in
  String.concat "" ("date,value\n" :: rows)

let write path result =
  let contents = equity_csv result in
  try
    let oc = open_out path in
    (try output_string oc contents
     with e ->
       close_out_noerr oc;
       raise e);
    close_out oc;
    Ok ()
  with Sys_error msg -> Error msg
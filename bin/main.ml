let () =
  match Array.to_list Sys.argv with
  | [_; path] ->
      (match Backtester.Market.load path with
       | Error msg -> prerr_endline ("error: " ^ msg); exit 1
       | Ok m ->
           Printf.printf "securities: %s\n"
             (String.concat ", " (Backtester.Market.securities m));
           List.iter
             (fun (d, ps) ->
               Printf.printf "%s: %s\n" d
                 (String.concat " " (List.map string_of_int ps)))
             (Backtester.Market.days m))
  | _ ->
      prerr_endline "usage: a2 <market-file>";
      exit 1
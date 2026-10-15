let is_digit c = c >= '0' && c <= '9'

let all_digits s =
  let rec go i = i >= String.length s || (is_digit s.[i] && go (i + 1)) in
  go 0

let of_string s =
  match String.split_on_char '.' s with
  | [ dollars; cents ]
    when dollars <> ""
         && String.length cents = 2
         && all_digits dollars && all_digits cents ->
      int_of_string_opt (dollars ^ cents)
  | _ -> None

let to_string cents = Printf.sprintf "%d.%02d" (cents / 100) (cents mod 100)

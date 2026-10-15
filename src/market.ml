type t = {
  securities : string list;
  days : (string * int list) list;
}

type prices = (string * int) list

let cents_of_string s =
  int_of_string (String.concat "" (String.split_on_char '.' s))

let parse_row = function
  | date :: prices -> (date, List.map cents_of_string prices)
  | [] -> failwith "Invalid row format"

let of_csv = function
  | (_date :: securities) :: rows ->
      let securities = List.map String.trim securities in
      let days = List.map parse_row rows in
      { securities; days }
  | _ -> failwith "Invalid CSV format"

let load path =
  try Ok (of_csv (Csv.load path)) with Sys_error msg -> Error msg

let securities m = m.securities
let days m = m.days

let daily_prices m =
  List.map
    (fun (date, values) -> (date, List.combine m.securities values))
    m.days

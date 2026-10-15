(** A parsed market file. The representation is hidden. *)
type t

(** Security names paired with their closing prices in cents. *)
type prices = (string * int) list

(** Security names in the order of the header. *)
val securities : t -> string list

(** One entry per data row, in file (date) order. Each entry is the date as
    [YYYY-MM-DD] text and that date's closing prices in cents. The prices
    appear in the same order as [securities]. *)
val days : t -> (string * int list) list

(** One entry per data row, with each price paired to its security name.
    Securities appear in header order. *)
val daily_prices : t -> (string * prices) list

(** [load path] reads and parses the market file at [path]. Returns
    [Error msg] if the file cannot be opened; [msg] is suitable to show the
    user. The contents of a file that does open are assumed to be valid. *)
val load : string -> (t, string) result

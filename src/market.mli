type t
(** A parsed market file. The representation is hidden. *)

type prices = (string * int) list
(** Security names paired with their closing prices in cents. *)

val securities : t -> string list
(** Security names in the order of the header. *)

val days : t -> (string * int list) list
(** One entry per data row, in file (date) order. Each entry is the date as
    [YYYY-MM-DD] text and that date's closing prices in cents. The prices appear
    in the same order as [securities]. *)

val daily_prices : t -> (string * prices) list
(** One entry per data row, with each price paired to its security name.
    Securities appear in header order. *)

val load : string -> (t, string) result
(** [load path] reads and parses the market file at [path]. Returns [Error msg]
    if the file cannot be opened; [msg] is suitable to show the user. The
    contents of a file that does open are assumed to be valid. *)

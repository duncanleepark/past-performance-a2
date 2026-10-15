(** Presents an [Engine.result]: the human-readable final summary and the
    [date,value] equity CSV. Everything here is formatting; no trade or value
    is recomputed. *)

val render : strategy:string -> Engine.result -> string
(** [render ~strategy result] is the complete final summary, every line
    (including the last) ending in a newline: strategy name, first and last
    dates, initial cash, final cash, final holdings (omitting zero holdings,
    or ["Final holdings: none"] when there are none), final portfolio value,
    and total return. The caller prints the string as is. *)

val equity_csv : Engine.result -> string
(** The text of the equity file: the header [date,value], then one line per
    date with the portfolio value after that date's orders, formatted as
    [DIGITS.DD] with no dollar sign. Every line ends in a newline. *)

val write : string -> Engine.result -> (unit, string) result
(** [write path result] saves [equity_csv result] to [path]. [Error msg] if
    the file cannot be created or written; [msg] is suitable to show the
    user. *)
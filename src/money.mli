(** Dollar amounts as integer cents: the one place that parses and formats them.
    Used for market prices, the [--cash] option, and report output. *)

val of_string : string -> int option
(** [of_string s] parses text of the form [DIGITS.DD] (one or more digits, a
    dot, exactly two digits) into cents, so ["10000.01"] is [Some 1000001].
    Anything else, including signs, spaces, a missing or misplaced dot, or the
    wrong number of decimal digits, is [None]. Zero is accepted; callers that
    need a positive amount check that themselves. *)

val to_string : int -> string
(** [to_string cents] formats a nonnegative number of cents as [DIGITS.DD] with
    no dollar sign or separators, so [1000001] is ["10000.01"]. *)

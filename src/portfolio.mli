(** A cash balance plus whole-share holdings. Portfolios are immutable:
    [apply] returns a new portfolio. *)

(** A portfolio. The representation is hidden. Holdings of zero shares are
    never stored. *)
type t

type rejection =
    | Non_positive_quantity
    | Unknown_security
    | Insufficient_shares
    | Insufficient_cash

(** [create ~cash] holds [cash] cents and no shares. *)
val create : cash:int -> t

(** Cash on hand in cents. *)
val cash : t -> int

(** [shares p security] is the number of shares held; 0 if none. *)
val shares : t -> string -> int

(** Securities held with a positive share count, sorted by security name. *)
val holdings : t -> (string * int) list

(** [apply p ~prices order] executes [order] at the given per-share prices
    (security name, cents) and returns the new portfolio. If the order breaks
    a rule it returns [Error reason]; the caller keeps using [p], which is
    unchanged. *)
val apply : t -> prices:(string * int) list -> Order.t -> (t, rejection) result

(** Cash plus each holding valued at its price in [prices], in cents. *)
val value : t -> prices:(string * int) list -> int
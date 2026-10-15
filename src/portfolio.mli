(** A cash balance plus whole-share holdings. Portfolios are immutable: [apply]
    returns a new portfolio. *)

type t
(** A portfolio. The representation is hidden. Holdings of zero shares are never
    stored. *)

type rejection =
  | Non_positive_quantity
  | Unknown_security
  | Insufficient_shares
  | Insufficient_cash

val create : cash:int -> t
(** [create ~cash] holds [cash] cents and no shares. *)

val cash : t -> int
(** Cash on hand in cents. *)

val shares : t -> string -> int
(** [shares p security] is the number of shares held; 0 if none. *)

val holdings : t -> (string * int) list
(** Securities held with a positive share count, sorted by security name. *)

val apply : t -> prices:(string * int) list -> Order.t -> (t, rejection) result
(** [apply p ~prices order] executes [order] at the given per-share prices
    (security name, cents) and returns the new portfolio. If the order breaks a
    rule it returns [Error reason]; the caller keeps using [p], which is
    unchanged. *)

val value : t -> prices:(string * int) list -> int
(** Cash plus each holding valued at its price in [prices], in cents. *)

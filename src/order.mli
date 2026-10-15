type direction = Buy | Sell

(** An order: buy or sell [quantity] whole shares of [security]. *)
type t = {
  security : string;
  direction : direction;
  quantity : int;
}


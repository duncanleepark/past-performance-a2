type direction =
  | Buy
  | Sell

type t = {
  security : string;
  direction : direction;
  quantity : int;
}
(** An order: buy or sell [quantity] whole shares of [security]. *)

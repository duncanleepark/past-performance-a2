type direction = Buy | Sell
type t = {
  security : string;
  direction : direction;
  quantity : int;
}
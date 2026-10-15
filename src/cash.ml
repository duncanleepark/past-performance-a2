type state = unit

let initial_state () = ()
let next () ~date:_ ~prices:_ ~portfolio:_ = ((), [])

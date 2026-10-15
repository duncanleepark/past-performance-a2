(** One-day momentum strategy.

    Each date after the first, pick the security with the largest strictly
    positive one-day price increase (ties go to the security that appears first
    in the market file). If it differs from the previously selected security,
    sell everything and put all cash into the new one. If no increase is
    positive, or the pick is unchanged, do nothing. *)

include Engine.Strategy

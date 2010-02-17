(*  Title:      HOLCF/IOA/ABP/Action.thy
    Author:     Olaf M�ller
*)

header {* The set of all actions of the system *}

theory Action
imports Main
begin

datatype action = New  | Loc nat | Free nat

lemma [cong]: "!!x. x = y ==> action_case a b c x = action_case a b c y"
  by simp

end

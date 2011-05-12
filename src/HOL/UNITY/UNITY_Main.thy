(*  Title:      HOL/UNITY/UNITY_Main.thy
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   2003  University of Cambridge
*)

header{*Comprehensive UNITY Theory*}

theory UNITY_Main
imports Detects PPROD Follows ProgressSets
uses "UNITY_tactics.ML"
begin

method_setup safety = {*
    Scan.succeed (SIMPLE_METHOD' o constrains_tac) *}
    "for proving safety properties"

method_setup ensures_tac = {*
  Args.goal_spec -- Scan.lift Args.name_source >>
  (fn (quant, s) => fn ctxt => SIMPLE_METHOD'' quant (ensures_tac ctxt s))
*} "for proving progress properties"

end

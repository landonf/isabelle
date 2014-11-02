(*  Title:      HOL/UNITY/UNITY_Main.thy
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   2003  University of Cambridge
*)

section{*Comprehensive UNITY Theory*}

theory UNITY_Main
imports Detects PPROD Follows ProgressSets
begin

ML_file "UNITY_tactics.ML"

method_setup safety = {*
    Scan.succeed (SIMPLE_METHOD' o constrains_tac) *}
    "for proving safety properties"

method_setup ensures_tac = {*
  Args.goal_spec -- Scan.lift Args.name_inner_syntax >>
  (fn (quant, s) => fn ctxt => SIMPLE_METHOD'' quant (ensures_tac ctxt s))
*} "for proving progress properties"

setup {*
  map_theory_simpset (fn ctxt => ctxt
    addsimps (make_o_equivs ctxt @{thm fst_o_funPair} @ make_o_equivs ctxt @{thm snd_o_funPair})
    addsimps (make_o_equivs ctxt @{thm fst_o_lift_map} @ make_o_equivs ctxt @{thm snd_o_lift_map}))
*}

end

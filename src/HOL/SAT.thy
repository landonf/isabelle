(*  Title:      HOL/SAT.thy
    Author:     Alwen Tiu, Tjark Weber
    Copyright   2005

Basic setup for the 'sat' and 'satx' tactic.
*)

header {* Reconstructing external resolution proofs for propositional logic *}

theory SAT
imports Refute
uses
  "Tools/sat_funcs.ML"
begin

text {* \medskip Late package setup: default values for refute, see
  also theory @{theory Refute}. *}

refute_params
 ["itself"=1,
  minsize=1,
  maxsize=8,
  maxvars=10000,
  maxtime=60,
  satsolver="auto",
  no_assms="false"]

ML {* structure sat = SATFunc(cnf) *}

method_setup sat = {* Scan.succeed (SIMPLE_METHOD' o sat.sat_tac) *}
  "SAT solver"

method_setup satx = {* Scan.succeed (SIMPLE_METHOD' o sat.satx_tac) *}
  "SAT solver (with definitional CNF)"

end

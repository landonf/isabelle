
(* Author: Ondrej Kuncar, TU Muenchen *)

section \<open>Pervasive test of code generator\<close>

theory Generate_Efficient_Datastructures
imports
  Candidates
  "~~/src/HOL/Library/DAList_Multiset"
  "~~/src/HOL/Library/RBT_Mapping"
  "~~/src/HOL/Library/RBT_Set"
begin

text \<open>
  The following code equations have to be deleted because they use 
  lists to implement sets in the code generetor. 
\<close>

declare [[code drop:
  Sup_pred_inst.Sup_pred
  Inf_pred_inst.Inf_pred
  pred_of_set
  Wellfounded.acc
  Cardinality.card'
  Cardinality.finite'
  Cardinality.subset'
  Cardinality.eq_set
  Gcd_fin
  Lcm_fin
  "Gcd :: nat set \<Rightarrow> nat"
  "Lcm :: nat set \<Rightarrow> nat"
  "Gcd :: int set \<Rightarrow> int"
  "Lcm :: int set \<Rightarrow> int"
  "Gcd :: _ poly set \<Rightarrow> _"
  "Lcm :: _ poly set \<Rightarrow> _"
  Euclidean_Algorithm.Gcd
  Euclidean_Algorithm.Lcm
  permutations_of_set
  permutations_of_multiset
]]

(*
  If the code generation ends with an exception with the following message:
  '"List.set" is not a constructor, on left hand side of equation: ...',
  the code equation in question has to be either deleted (like many others in this file) 
  or implemented for RBT trees.
*)

export_code _ checking SML OCaml? Haskell? Scala

end

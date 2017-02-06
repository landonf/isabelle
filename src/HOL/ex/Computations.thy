(*  Title:      HOL/ex/Computations.thy
    Author:     Florian Haftmann, TU Muenchen
*)

section \<open>Simple example for computations generated by the code generator\<close>

theory Computations
  imports "../Nat" "../Fun_Def" "../Num" "../Code_Numeral"
begin

fun even :: "nat \<Rightarrow> bool"
  where "even 0 \<longleftrightarrow> True"
      | "even (Suc 0) \<longleftrightarrow> False"
      | "even (Suc (Suc n)) \<longleftrightarrow> even n"
  
fun fib :: "nat \<Rightarrow> nat"
  where "fib 0 = 0"
      | "fib (Suc 0) = Suc 0"
      | "fib (Suc (Suc n)) = fib (Suc n) + fib n"

declare [[ML_source_trace]]

ML \<open>
local 

fun int_of_nat @{code "0 :: nat"} = 0
  | int_of_nat (@{code Suc} n) = int_of_nat n + 1;

in

val comp_nat = @{computation "0 :: nat" Suc
  "plus :: nat \<Rightarrow>_" "times :: nat \<Rightarrow> _" fib :: nat}
  (fn post => post o HOLogic.mk_nat o int_of_nat o the);

val comp_numeral = @{computation "0 :: nat" "1 :: nat" "2 :: nat" "3 :: nat" :: nat}
  (fn post => post o HOLogic.mk_nat o int_of_nat o the);

val comp_bool = @{computation True False HOL.conj HOL.disj HOL.implies
  HOL.iff even "less_eq :: nat \<Rightarrow> _" "less :: nat \<Rightarrow> _" "HOL.eq :: nat \<Rightarrow> _" :: bool}
  (K the);

val comp_check = @{computation_check Trueprop};

end
\<close>

declare [[ML_source_trace = false]]
  
ML_val \<open>
  comp_nat @{context} @{term "fib (Suc (Suc (Suc 0)) * Suc (Suc (Suc 0))) + Suc 0"}
  |> Syntax.string_of_term @{context}
  |> writeln
\<close>
  
ML_val \<open>
  comp_bool @{context} @{term "fib (Suc (Suc (Suc 0)) * Suc (Suc (Suc 0))) + Suc 0 < fib (Suc (Suc 0))"}
\<close>

ML_val \<open>
  comp_check @{context} @{cprop "fib (Suc (Suc (Suc 0)) * Suc (Suc (Suc 0))) + Suc 0 > fib (Suc (Suc 0))"}
\<close>
  
ML_val \<open>
  comp_numeral @{context} @{term "Suc 42 + 7"}
  |> Syntax.string_of_term @{context}
  |> writeln
\<close>

end

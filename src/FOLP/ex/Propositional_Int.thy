(*  Title:      FOLP/ex/Propositional_Int.thy
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1991  University of Cambridge
*)

section \<open>First-Order Logic: propositional examples\<close>

theory Propositional_Int
imports IFOLP
begin


text "commutative laws of & and | "
schematic_lemma "?p : P & Q  -->  Q & P"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

schematic_lemma "?p : P | Q  -->  Q | P"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)


text "associative laws of & and | "
schematic_lemma "?p : (P & Q) & R  -->  P & (Q & R)"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

schematic_lemma "?p : (P | Q) | R  -->  P | (Q | R)"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)


text "distributive laws of & and | "
schematic_lemma "?p : (P & Q) | R  --> (P | R) & (Q | R)"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

schematic_lemma "?p : (P | R) & (Q | R)  --> (P & Q) | R"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

schematic_lemma "?p : (P | Q) & R  --> (P & R) | (Q & R)"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)


schematic_lemma "?p : (P & R) | (Q & R)  --> (P | Q) & R"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)


text "Laws involving implication"

schematic_lemma "?p : (P-->R) & (Q-->R) <-> (P|Q --> R)"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

schematic_lemma "?p : (P & Q --> R) <-> (P--> (Q-->R))"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

schematic_lemma "?p : ((P-->R)-->R) --> ((Q-->R)-->R) --> (P&Q-->R) --> R"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

schematic_lemma "?p : ~(P-->R) --> ~(Q-->R) --> ~(P&Q-->R)"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

schematic_lemma "?p : (P --> Q & R) <-> (P-->Q)  &  (P-->R)"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)


text "Propositions-as-types"

(*The combinator K*)
schematic_lemma "?p : P --> (Q --> P)"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

(*The combinator S*)
schematic_lemma "?p : (P-->Q-->R)  --> (P-->Q) --> (P-->R)"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)


(*Converse is classical*)
schematic_lemma "?p : (P-->Q) | (P-->R)  -->  (P --> Q | R)"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

schematic_lemma "?p : (P-->Q)  -->  (~Q --> ~P)"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)


text "Schwichtenberg's examples (via T. Nipkow)"

schematic_lemma stab_imp: "?p : (((Q-->R)-->R)-->Q) --> (((P-->Q)-->R)-->R)-->P-->Q"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

schematic_lemma stab_to_peirce: "?p : (((P --> R) --> R) --> P) --> (((Q --> R) --> R) --> Q)  
              --> ((P --> Q) --> P) --> P"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

schematic_lemma peirce_imp1: "?p : (((Q --> R) --> Q) --> Q)  
               --> (((P --> Q) --> R) --> P --> Q) --> P --> Q"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)
  
schematic_lemma peirce_imp2: "?p : (((P --> R) --> P) --> P) --> ((P --> Q --> R) --> P) --> P"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

schematic_lemma mints: "?p : ((((P --> Q) --> P) --> P) --> Q) --> Q"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

schematic_lemma mints_solovev: "?p : (P --> (Q --> R) --> Q) --> ((P --> Q) --> R) --> R"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

schematic_lemma tatsuta: "?p : (((P7 --> P1) --> P10) --> P4 --> P5)  
          --> (((P8 --> P2) --> P9) --> P3 --> P10)  
          --> (P1 --> P8) --> P6 --> P7  
          --> (((P3 --> P2) --> P9) --> P4)  
          --> (P1 --> P3) --> (((P6 --> P1) --> P2) --> P9) --> P5"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

schematic_lemma tatsuta1: "?p : (((P8 --> P2) --> P9) --> P3 --> P10)  
     --> (((P3 --> P2) --> P9) --> P4)  
     --> (((P6 --> P1) --> P2) --> P9)  
     --> (((P7 --> P1) --> P10) --> P4 --> P5)  
     --> (P1 --> P3) --> (P1 --> P8) --> P6 --> P7 --> P5"
  by (tactic \<open>IntPr.fast_tac @{context} 1\<close>)

end

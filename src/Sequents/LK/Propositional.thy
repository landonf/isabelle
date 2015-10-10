(*  Title:      Sequents/LK/Propositional.thy
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1992  University of Cambridge
*)

section \<open>Classical sequent calculus: examples with propositional connectives\<close>

theory Propositional
imports "../LK"
begin

text "absorptive laws of \<and> and \<or>"

lemma "|- P \<and> P \<longleftrightarrow> P"
  by fast_prop

lemma "|- P \<or> P \<longleftrightarrow> P"
  by fast_prop


text "commutative laws of \<and> and \<or>"

lemma "|- P \<and> Q \<longleftrightarrow> Q \<and> P"
  by fast_prop

lemma "|- P \<or> Q \<longleftrightarrow> Q \<or> P"
  by fast_prop


text "associative laws of \<and> and \<or>"

lemma "|- (P \<and> Q) \<and> R \<longleftrightarrow> P \<and> (Q \<and> R)"
  by fast_prop

lemma "|- (P \<or> Q) \<or> R \<longleftrightarrow> P \<or> (Q \<or> R)"
  by fast_prop


text "distributive laws of \<and> and \<or>"

lemma "|- (P \<and> Q) \<or> R \<longleftrightarrow> (P \<or> R) \<and> (Q \<or> R)"
  by fast_prop

lemma "|- (P \<or> Q) \<and> R \<longleftrightarrow> (P \<and> R) \<or> (Q \<and> R)"
  by fast_prop


text "Laws involving implication"

lemma "|- (P \<or> Q \<longrightarrow> R) \<longleftrightarrow> (P \<longrightarrow> R) \<and> (Q \<longrightarrow> R)"
  by fast_prop

lemma "|- (P \<and> Q \<longrightarrow> R) \<longleftrightarrow> (P \<longrightarrow> (Q \<longrightarrow> R))"
  by fast_prop

lemma "|- (P \<longrightarrow> Q \<and> R) \<longleftrightarrow> (P \<longrightarrow> Q) \<and> (P \<longrightarrow> R)"
  by fast_prop


text "Classical theorems"

lemma "|- P \<or> Q \<longrightarrow> P \<or> \<not> P \<and> Q"
  by fast_prop

lemma "|- (P \<longrightarrow> Q) \<and> (\<not> P \<longrightarrow> R) \<longrightarrow> (P \<and> Q \<or> R)"
  by fast_prop

lemma "|- P \<and> Q \<or> \<not> P \<and> R \<longleftrightarrow> (P \<longrightarrow> Q) \<and> (\<not> P \<longrightarrow> R)"
  by fast_prop

lemma "|- (P \<longrightarrow> Q) \<or> (P \<longrightarrow> R) \<longleftrightarrow> (P \<longrightarrow> Q \<or> R)"
  by fast_prop


(*If and only if*)

lemma "|- (P \<longleftrightarrow> Q) \<longleftrightarrow> (Q \<longleftrightarrow> P)"
  by fast_prop

lemma "|- \<not> (P \<longleftrightarrow> \<not> P)"
  by fast_prop


(*Sample problems from 
  F. J. Pelletier, 
  Seventy-Five Problems for Testing Automatic Theorem Provers,
  J. Automated Reasoning 2 (1986), 191-216.
  Errata, JAR 4 (1988), 236-236.
*)

(*1*)
lemma "|- (P \<longrightarrow> Q) \<longleftrightarrow> (\<not> Q \<longrightarrow> \<not> P)"
  by fast_prop

(*2*)
lemma "|- \<not> \<not> P \<longleftrightarrow> P"
  by fast_prop

(*3*)
lemma "|- \<not> (P \<longrightarrow> Q) \<longrightarrow> (Q \<longrightarrow> P)"
  by fast_prop

(*4*)
lemma "|- (\<not> P \<longrightarrow> Q) \<longleftrightarrow> (\<not> Q \<longrightarrow> P)"
  by fast_prop

(*5*)
lemma "|- ((P \<or> Q) \<longrightarrow> (P \<or> R)) \<longrightarrow> (P \<or> (Q \<longrightarrow> R))"
  by fast_prop

(*6*)
lemma "|- P \<or> \<not> P"
  by fast_prop

(*7*)
lemma "|- P \<or> \<not> \<not> \<not> P"
  by fast_prop

(*8.  Peirce's law*)
lemma "|- ((P \<longrightarrow> Q) \<longrightarrow> P) \<longrightarrow> P"
  by fast_prop

(*9*)
lemma "|- ((P \<or> Q) \<and> (\<not> P \<or> Q) \<and> (P \<or> \<not> Q)) \<longrightarrow> \<not> (\<not> P \<or> \<not> Q)"
  by fast_prop

(*10*)
lemma "Q \<longrightarrow> R, R \<longrightarrow> P \<and> Q, P \<longrightarrow> (Q \<or> R) |- P \<longleftrightarrow> Q"
  by fast_prop

(*11.  Proved in each direction (incorrectly, says Pelletier!!)  *)
lemma "|- P \<longleftrightarrow> P"
  by fast_prop

(*12.  "Dijkstra's law"*)
lemma "|- ((P \<longleftrightarrow> Q) \<longleftrightarrow> R) \<longleftrightarrow> (P \<longleftrightarrow> (Q \<longleftrightarrow> R))"
  by fast_prop

(*13.  Distributive law*)
lemma "|- P \<or> (Q \<and> R) \<longleftrightarrow> (P \<or> Q) \<and> (P \<or> R)"
  by fast_prop

(*14*)
lemma "|- (P \<longleftrightarrow> Q) \<longleftrightarrow> ((Q \<or> \<not> P) \<and> (\<not> Q \<or> P))"
  by fast_prop

(*15*)
lemma "|- (P \<longrightarrow> Q) \<longleftrightarrow> (\<not> P \<or> Q)"
  by fast_prop

(*16*)
lemma "|- (P \<longrightarrow> Q) \<or> (Q \<longrightarrow> P)"
  by fast_prop

(*17*)
lemma "|- ((P \<and> (Q \<longrightarrow> R)) \<longrightarrow> S) \<longleftrightarrow> ((\<not> P \<or> Q \<or> S) \<and> (\<not> P \<or> \<not> R \<or> S))"
  by fast_prop

end

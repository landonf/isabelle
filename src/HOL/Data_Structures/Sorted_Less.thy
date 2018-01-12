(* Author: Tobias Nipkow *)

section \<open>Lists Sorted wrt $<$\<close>

theory Sorted_Less
imports Less_False
begin

hide_const sorted

text \<open>Is a list sorted without duplicates, i.e., wrt @{text"<"}?
Could go into theory List under a name like @{term sorted_less}.\<close>

abbreviation sorted :: "'a::linorder list \<Rightarrow> bool" where
"sorted \<equiv> sorted_wrt (<)"

lemma sorted_cons: "sorted (x#xs) \<Longrightarrow> sorted xs"
by(simp add: sorted_wrt_Cons)

lemma sorted_cons': "ASSUMPTION (sorted (x#xs)) \<Longrightarrow> sorted xs"
by(rule ASSUMPTION_D [THEN sorted_cons])

lemma sorted_snoc: "sorted (xs @ [y]) \<Longrightarrow> sorted xs"
by(simp add: sorted_wrt_append)

lemma sorted_snoc': "ASSUMPTION (sorted (xs @ [y])) \<Longrightarrow> sorted xs"
by(rule ASSUMPTION_D [THEN sorted_snoc])

lemma sorted_mid_iff:
  "sorted(xs @ y # ys) = (sorted(xs @ [y]) \<and> sorted(y # ys))"
by(fastforce simp add: sorted_wrt_Cons sorted_wrt_append)

lemma sorted_mid_iff2:
  "sorted(x # xs @ y # ys) =
  (sorted(x # xs) \<and> x < y \<and> sorted(xs @ [y]) \<and> sorted(y # ys))"
by(fastforce simp add: sorted_wrt_Cons sorted_wrt_append)

lemma sorted_mid_iff': "NO_MATCH [] ys \<Longrightarrow>
  sorted(xs @ y # ys) = (sorted(xs @ [y]) \<and> sorted(y # ys))"
by(rule sorted_mid_iff)

lemmas sorted_lems = sorted_mid_iff' sorted_mid_iff2 sorted_cons' sorted_snoc'

text\<open>Splay trees need two additional @{const sorted} lemmas:\<close>

lemma sorted_snoc_le:
  "ASSUMPTION(sorted(xs @ [x])) \<Longrightarrow> x \<le> y \<Longrightarrow> sorted (xs @ [y])"
by (auto simp add: sorted_wrt_append ASSUMPTION_def)

lemma sorted_Cons_le:
  "ASSUMPTION(sorted(x # xs)) \<Longrightarrow> y \<le> x \<Longrightarrow> sorted (y # xs)"
by (auto simp add: sorted_wrt_Cons ASSUMPTION_def)

end

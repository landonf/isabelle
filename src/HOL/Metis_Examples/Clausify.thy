(*  Title:      HOL/Metis_Examples/Clausifier.thy
    Author:     Jasmin Blanchette, TU Muenchen

Testing Metis's clausifier.
*)

theory Clausifier
imports Complex_Main
begin


text {* Definitional CNF for goal *}

(* FIXME: shouldn't need this *)
declare [[unify_search_bound = 100]]
declare [[unify_trace_bound = 100]]

axiomatization p :: "nat \<Rightarrow> nat \<Rightarrow> bool" where
pax: "\<exists>b. \<forall>a. ((p b a \<and> p 0 0 \<and> p 1 a) \<or> (p 0 1 \<and> p 1 0 \<and> p a b))"

declare [[metis_new_skolemizer = false]]

lemma "\<exists>b. \<forall>a. \<exists>x. (p b a \<or> x) \<and> (p 0 0 \<or> x) \<and> (p 1 a \<or> x) \<and>
                   (p 0 1 \<or> \<not> x) \<and> (p 1 0 \<or> \<not> x) \<and> (p a b \<or> \<not> x)"
by (metis pax)

lemma "\<exists>b. \<forall>a. \<exists>x. (p b a \<or> x) \<and> (p 0 0 \<or> x) \<and> (p 1 a \<or> x) \<and>
                   (p 0 1 \<or> \<not> x) \<and> (p 1 0 \<or> \<not> x) \<and> (p a b \<or> \<not> x)"
by (metisFT pax)

declare [[metis_new_skolemizer]]

lemma "\<exists>b. \<forall>a. \<exists>x. (p b a \<or> x) \<and> (p 0 0 \<or> x) \<and> (p 1 a \<or> x) \<and>
                   (p 0 1 \<or> \<not> x) \<and> (p 1 0 \<or> \<not> x) \<and> (p a b \<or> \<not> x)"
by (metis pax)

lemma "\<exists>b. \<forall>a. \<exists>x. (p b a \<or> x) \<and> (p 0 0 \<or> x) \<and> (p 1 a \<or> x) \<and>
                   (p 0 1 \<or> \<not> x) \<and> (p 1 0 \<or> \<not> x) \<and> (p a b \<or> \<not> x)"
by (metisFT pax)


text {* New Skolemizer *}

declare [[metis_new_skolemizer]]

lemma
  fixes x :: real
  assumes fn_le: "!!n. f n \<le> x" and 1: "f----> lim f"
  shows "lim f \<le> x"
by (metis 1 LIMSEQ_le_const2 fn_le)

definition
  bounded :: "'a::metric_space set \<Rightarrow> bool" where
  "bounded S \<longleftrightarrow> (\<exists>x eee. \<forall>y\<in>S. dist x y \<le> eee)"

lemma "bounded T \<Longrightarrow> S \<subseteq> T ==> bounded S"
by (metis bounded_def subset_eq)

lemma
  assumes a: "Quotient R Abs Rep"
  shows "symp R"
using a unfolding Quotient_def using sympI
by metisFT

lemma
  "(\<exists>x \<in> set xs. P x) \<longleftrightarrow>
   (\<exists>ys x zs. xs = ys@x#zs \<and> P x \<and> (\<forall>z \<in> set zs. \<not> P z))"
by (metis split_list_last_prop [where P = P] in_set_conv_decomp)

end

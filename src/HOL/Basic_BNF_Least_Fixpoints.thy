(*  Title:      HOL/Basic_BNF_Least_Fixpoints.thy
    Author:     Jasmin Blanchette, TU Muenchen
    Copyright   2014

Registration of basic types as BNF least fixpoints (datatypes).
*)

theory Basic_BNF_Least_Fixpoints
imports BNF_Least_Fixpoint
begin

definition xtor :: "'a \<Rightarrow> 'a" where
  "xtor x = x"

lemma xtor_map: "f (xtor x) = xtor (f x)"
  unfolding xtor_def by (rule refl)

lemma xtor_set: "f (xtor x) = f x"
  unfolding xtor_def by (rule refl)

lemma xtor_rel: "R (xtor x) (xtor y) = R x y"
  unfolding xtor_def by (rule refl)

lemma xtor_induct: "(\<And>x. P (xtor x)) \<Longrightarrow> P z"
  unfolding xtor_def by assumption

lemma xtor_xtor: "xtor (xtor x) = x"
  unfolding xtor_def by (rule refl)

lemmas xtor_inject = xtor_rel[of "op ="]

lemma xtor_rel_induct: "(\<And>x y. vimage2p id_bnf id_bnf R x y \<Longrightarrow> IR (xtor x) (xtor y)) \<Longrightarrow> R \<le> IR"
  unfolding xtor_def vimage2p_def id_bnf_def by default

lemma Inl_def_alt: "Inl \<equiv> (\<lambda>a. xtor (id_bnf (Inl a)))"
  unfolding xtor_def id_bnf_def by (rule reflexive)

lemma Inr_def_alt: "Inr \<equiv> (\<lambda>a. xtor (id_bnf (Inr a)))"
  unfolding xtor_def id_bnf_def by (rule reflexive)

lemma Pair_def_alt: "Pair \<equiv> (\<lambda>a b. xtor (id_bnf (a, b)))"
  unfolding xtor_def id_bnf_def by (rule reflexive)

definition ctor_rec :: "'a \<Rightarrow> 'a" where
  "ctor_rec x = x"

lemma ctor_rec: "g = id \<Longrightarrow> ctor_rec f (xtor x) = f ((id_bnf \<circ> g \<circ> id_bnf) x)"
  unfolding ctor_rec_def id_bnf_def xtor_def comp_def id_def by hypsubst (rule refl)

lemma ctor_rec_def_alt: "f = ctor_rec (f \<circ> id_bnf)"
  unfolding ctor_rec_def id_bnf_def comp_def by (rule refl)

lemma ctor_rec_o_map: "ctor_rec f \<circ> g = ctor_rec (f \<circ> (id_bnf \<circ> g \<circ> id_bnf))"
  unfolding ctor_rec_def id_bnf_def comp_def by (rule refl)

ML_file "Tools/BNF/bnf_lfp_basic_sugar.ML"

thm sum.rec_o_map
thm sum.size_o_map

thm prod.rec_o_map
thm prod.size_o_map

hide_const (open) xtor ctor_rec

hide_fact (open)
  xtor_def xtor_map xtor_set xtor_rel xtor_induct xtor_xtor xtor_inject ctor_rec_def ctor_rec
  ctor_rec_def_alt ctor_rec_o_map xtor_rel_induct Inl_def_alt Inr_def_alt Pair_def_alt

end

(*  Title:      HOL/Transfer.thy
    Author:     Brian Huffman, TU Muenchen
    Author:     Ondrej Kuncar, TU Muenchen
*)

header {* Generic theorem transfer using relations *}

theory Transfer
imports Hilbert_Choice Basic_BNFs
begin

subsection {* Relator for function space *}

locale lifting_syntax
begin
  notation fun_rel (infixr "===>" 55)
  notation map_fun (infixr "--->" 55)
end

context
begin
interpretation lifting_syntax .

lemma fun_relD2:
  assumes "fun_rel A B f g" and "A x x"
  shows "B (f x) (g x)"
  using assms by (rule fun_relD)

lemma fun_relE:
  assumes "fun_rel A B f g" and "A x y"
  obtains "B (f x) (g y)"
  using assms by (simp add: fun_rel_def)

lemmas fun_rel_eq = fun.rel_eq

lemma fun_rel_eq_rel:
shows "fun_rel (op =) R = (\<lambda>f g. \<forall>x. R (f x) (g x))"
  by (simp add: fun_rel_def)


subsection {* Transfer method *}

text {* Explicit tag for relation membership allows for
  backward proof methods. *}

definition Rel :: "('a \<Rightarrow> 'b \<Rightarrow> bool) \<Rightarrow> 'a \<Rightarrow> 'b \<Rightarrow> bool"
  where "Rel r \<equiv> r"

text {* Handling of equality relations *}

definition is_equality :: "('a \<Rightarrow> 'a \<Rightarrow> bool) \<Rightarrow> bool"
  where "is_equality R \<longleftrightarrow> R = (op =)"

lemma is_equality_eq: "is_equality (op =)"
  unfolding is_equality_def by simp

text {* Reverse implication for monotonicity rules *}

definition rev_implies where
  "rev_implies x y \<longleftrightarrow> (y \<longrightarrow> x)"

text {* Handling of meta-logic connectives *}

definition transfer_forall where
  "transfer_forall \<equiv> All"

definition transfer_implies where
  "transfer_implies \<equiv> op \<longrightarrow>"

definition transfer_bforall :: "('a \<Rightarrow> bool) \<Rightarrow> ('a \<Rightarrow> bool) \<Rightarrow> bool"
  where "transfer_bforall \<equiv> (\<lambda>P Q. \<forall>x. P x \<longrightarrow> Q x)"

lemma transfer_forall_eq: "(\<And>x. P x) \<equiv> Trueprop (transfer_forall (\<lambda>x. P x))"
  unfolding atomize_all transfer_forall_def ..

lemma transfer_implies_eq: "(A \<Longrightarrow> B) \<equiv> Trueprop (transfer_implies A B)"
  unfolding atomize_imp transfer_implies_def ..

lemma transfer_bforall_unfold:
  "Trueprop (transfer_bforall P (\<lambda>x. Q x)) \<equiv> (\<And>x. P x \<Longrightarrow> Q x)"
  unfolding transfer_bforall_def atomize_imp atomize_all ..

lemma transfer_start: "\<lbrakk>P; Rel (op =) P Q\<rbrakk> \<Longrightarrow> Q"
  unfolding Rel_def by simp

lemma transfer_start': "\<lbrakk>P; Rel (op \<longrightarrow>) P Q\<rbrakk> \<Longrightarrow> Q"
  unfolding Rel_def by simp

lemma transfer_prover_start: "\<lbrakk>x = x'; Rel R x' y\<rbrakk> \<Longrightarrow> Rel R x y"
  by simp

lemma untransfer_start: "\<lbrakk>Q; Rel (op =) P Q\<rbrakk> \<Longrightarrow> P"
  unfolding Rel_def by simp

lemma Rel_eq_refl: "Rel (op =) x x"
  unfolding Rel_def ..

lemma Rel_app:
  assumes "Rel (A ===> B) f g" and "Rel A x y"
  shows "Rel B (f x) (g y)"
  using assms unfolding Rel_def fun_rel_def by fast

lemma Rel_abs:
  assumes "\<And>x y. Rel A x y \<Longrightarrow> Rel B (f x) (g y)"
  shows "Rel (A ===> B) (\<lambda>x. f x) (\<lambda>y. g y)"
  using assms unfolding Rel_def fun_rel_def by fast

end

ML_file "Tools/transfer.ML"
setup Transfer.setup

declare refl [transfer_rule]

declare fun_rel_eq [relator_eq]

hide_const (open) Rel

context
begin
interpretation lifting_syntax .

text {* Handling of domains *}

lemma Domaimp_refl[transfer_domain_rule]:
  "Domainp T = Domainp T" ..

subsection {* Predicates on relations, i.e. ``class constraints'' *}

definition right_total :: "('a \<Rightarrow> 'b \<Rightarrow> bool) \<Rightarrow> bool"
  where "right_total R \<longleftrightarrow> (\<forall>y. \<exists>x. R x y)"

definition right_unique :: "('a \<Rightarrow> 'b \<Rightarrow> bool) \<Rightarrow> bool"
  where "right_unique R \<longleftrightarrow> (\<forall>x y z. R x y \<longrightarrow> R x z \<longrightarrow> y = z)"

definition bi_total :: "('a \<Rightarrow> 'b \<Rightarrow> bool) \<Rightarrow> bool"
  where "bi_total R \<longleftrightarrow> (\<forall>x. \<exists>y. R x y) \<and> (\<forall>y. \<exists>x. R x y)"

definition bi_unique :: "('a \<Rightarrow> 'b \<Rightarrow> bool) \<Rightarrow> bool"
  where "bi_unique R \<longleftrightarrow>
    (\<forall>x y z. R x y \<longrightarrow> R x z \<longrightarrow> y = z) \<and>
    (\<forall>x y z. R x z \<longrightarrow> R y z \<longrightarrow> x = y)"

lemma bi_uniqueDr: "\<lbrakk> bi_unique A; A x y; A x z \<rbrakk> \<Longrightarrow> y = z"
by(simp add: bi_unique_def)

lemma bi_uniqueDl: "\<lbrakk> bi_unique A; A x y; A z y \<rbrakk> \<Longrightarrow> x = z"
by(simp add: bi_unique_def)

lemma right_uniqueI: "(\<And>x y z. \<lbrakk> A x y; A x z \<rbrakk> \<Longrightarrow> y = z) \<Longrightarrow> right_unique A"
unfolding right_unique_def by blast

lemma right_uniqueD: "\<lbrakk> right_unique A; A x y; A x z \<rbrakk> \<Longrightarrow> y = z"
unfolding right_unique_def by blast

lemma right_total_alt_def:
  "right_total R \<longleftrightarrow> ((R ===> op \<longrightarrow>) ===> op \<longrightarrow>) All All"
  unfolding right_total_def fun_rel_def
  apply (rule iffI, fast)
  apply (rule allI)
  apply (drule_tac x="\<lambda>x. True" in spec)
  apply (drule_tac x="\<lambda>y. \<exists>x. R x y" in spec)
  apply fast
  done

lemma right_unique_alt_def:
  "right_unique R \<longleftrightarrow> (R ===> R ===> op \<longrightarrow>) (op =) (op =)"
  unfolding right_unique_def fun_rel_def by auto

lemma bi_total_alt_def:
  "bi_total R \<longleftrightarrow> ((R ===> op =) ===> op =) All All"
  unfolding bi_total_def fun_rel_def
  apply (rule iffI, fast)
  apply safe
  apply (drule_tac x="\<lambda>x. \<exists>y. R x y" in spec)
  apply (drule_tac x="\<lambda>y. True" in spec)
  apply fast
  apply (drule_tac x="\<lambda>x. True" in spec)
  apply (drule_tac x="\<lambda>y. \<exists>x. R x y" in spec)
  apply fast
  done

lemma bi_unique_alt_def:
  "bi_unique R \<longleftrightarrow> (R ===> R ===> op =) (op =) (op =)"
  unfolding bi_unique_def fun_rel_def by auto

lemma bi_unique_conversep [simp]: "bi_unique R\<inverse>\<inverse> = bi_unique R"
by(auto simp add: bi_unique_def)

lemma bi_total_conversep [simp]: "bi_total R\<inverse>\<inverse> = bi_total R"
by(auto simp add: bi_total_def)

text {* Properties are preserved by relation composition. *}

lemma OO_def: "R OO S = (\<lambda>x z. \<exists>y. R x y \<and> S y z)"
  by auto

lemma bi_total_OO: "\<lbrakk>bi_total A; bi_total B\<rbrakk> \<Longrightarrow> bi_total (A OO B)"
  unfolding bi_total_def OO_def by metis

lemma bi_unique_OO: "\<lbrakk>bi_unique A; bi_unique B\<rbrakk> \<Longrightarrow> bi_unique (A OO B)"
  unfolding bi_unique_def OO_def by metis

lemma right_total_OO:
  "\<lbrakk>right_total A; right_total B\<rbrakk> \<Longrightarrow> right_total (A OO B)"
  unfolding right_total_def OO_def by metis

lemma right_unique_OO:
  "\<lbrakk>right_unique A; right_unique B\<rbrakk> \<Longrightarrow> right_unique (A OO B)"
  unfolding right_unique_def OO_def by metis


subsection {* Properties of relators *}

lemma right_total_eq [transfer_rule]: "right_total (op =)"
  unfolding right_total_def by simp

lemma right_unique_eq [transfer_rule]: "right_unique (op =)"
  unfolding right_unique_def by simp

lemma bi_total_eq [transfer_rule]: "bi_total (op =)"
  unfolding bi_total_def by simp

lemma bi_unique_eq [transfer_rule]: "bi_unique (op =)"
  unfolding bi_unique_def by simp

lemma right_total_fun [transfer_rule]:
  "\<lbrakk>right_unique A; right_total B\<rbrakk> \<Longrightarrow> right_total (A ===> B)"
  unfolding right_total_def fun_rel_def
  apply (rule allI, rename_tac g)
  apply (rule_tac x="\<lambda>x. SOME z. B z (g (THE y. A x y))" in exI)
  apply clarify
  apply (subgoal_tac "(THE y. A x y) = y", simp)
  apply (rule someI_ex)
  apply (simp)
  apply (rule the_equality)
  apply assumption
  apply (simp add: right_unique_def)
  done

lemma right_unique_fun [transfer_rule]:
  "\<lbrakk>right_total A; right_unique B\<rbrakk> \<Longrightarrow> right_unique (A ===> B)"
  unfolding right_total_def right_unique_def fun_rel_def
  by (clarify, rule ext, fast)

lemma bi_total_fun [transfer_rule]:
  "\<lbrakk>bi_unique A; bi_total B\<rbrakk> \<Longrightarrow> bi_total (A ===> B)"
  unfolding bi_total_def fun_rel_def
  apply safe
  apply (rename_tac f)
  apply (rule_tac x="\<lambda>y. SOME z. B (f (THE x. A x y)) z" in exI)
  apply clarify
  apply (subgoal_tac "(THE x. A x y) = x", simp)
  apply (rule someI_ex)
  apply (simp)
  apply (rule the_equality)
  apply assumption
  apply (simp add: bi_unique_def)
  apply (rename_tac g)
  apply (rule_tac x="\<lambda>x. SOME z. B z (g (THE y. A x y))" in exI)
  apply clarify
  apply (subgoal_tac "(THE y. A x y) = y", simp)
  apply (rule someI_ex)
  apply (simp)
  apply (rule the_equality)
  apply assumption
  apply (simp add: bi_unique_def)
  done

lemma bi_unique_fun [transfer_rule]:
  "\<lbrakk>bi_total A; bi_unique B\<rbrakk> \<Longrightarrow> bi_unique (A ===> B)"
  unfolding bi_total_def bi_unique_def fun_rel_def fun_eq_iff
  by (safe, metis, fast)


subsection {* Transfer rules *}

lemma Domainp_iff: "Domainp T x \<longleftrightarrow> (\<exists>y. T x y)"
  by auto

lemma Domainp_forall_transfer [transfer_rule]:
  assumes "right_total A"
  shows "((A ===> op =) ===> op =)
    (transfer_bforall (Domainp A)) transfer_forall"
  using assms unfolding right_total_def
  unfolding transfer_forall_def transfer_bforall_def fun_rel_def Domainp_iff
  by metis

text {* Transfer rules using implication instead of equality on booleans. *}

lemma transfer_forall_transfer [transfer_rule]:
  "bi_total A \<Longrightarrow> ((A ===> op =) ===> op =) transfer_forall transfer_forall"
  "right_total A \<Longrightarrow> ((A ===> op =) ===> implies) transfer_forall transfer_forall"
  "right_total A \<Longrightarrow> ((A ===> implies) ===> implies) transfer_forall transfer_forall"
  "bi_total A \<Longrightarrow> ((A ===> op =) ===> rev_implies) transfer_forall transfer_forall"
  "bi_total A \<Longrightarrow> ((A ===> rev_implies) ===> rev_implies) transfer_forall transfer_forall"
  unfolding transfer_forall_def rev_implies_def fun_rel_def right_total_def bi_total_def
  by metis+

lemma transfer_implies_transfer [transfer_rule]:
  "(op =        ===> op =        ===> op =       ) transfer_implies transfer_implies"
  "(rev_implies ===> implies     ===> implies    ) transfer_implies transfer_implies"
  "(rev_implies ===> op =        ===> implies    ) transfer_implies transfer_implies"
  "(op =        ===> implies     ===> implies    ) transfer_implies transfer_implies"
  "(op =        ===> op =        ===> implies    ) transfer_implies transfer_implies"
  "(implies     ===> rev_implies ===> rev_implies) transfer_implies transfer_implies"
  "(implies     ===> op =        ===> rev_implies) transfer_implies transfer_implies"
  "(op =        ===> rev_implies ===> rev_implies) transfer_implies transfer_implies"
  "(op =        ===> op =        ===> rev_implies) transfer_implies transfer_implies"
  unfolding transfer_implies_def rev_implies_def fun_rel_def by auto

lemma eq_imp_transfer [transfer_rule]:
  "right_unique A \<Longrightarrow> (A ===> A ===> op \<longrightarrow>) (op =) (op =)"
  unfolding right_unique_alt_def .

lemma eq_transfer [transfer_rule]:
  assumes "bi_unique A"
  shows "(A ===> A ===> op =) (op =) (op =)"
  using assms unfolding bi_unique_def fun_rel_def by auto

lemma right_total_Ex_transfer[transfer_rule]:
  assumes "right_total A"
  shows "((A ===> op=) ===> op=) (Bex (Collect (Domainp A))) Ex"
using assms unfolding right_total_def Bex_def fun_rel_def Domainp_iff[abs_def]
by blast

lemma right_total_All_transfer[transfer_rule]:
  assumes "right_total A"
  shows "((A ===> op =) ===> op =) (Ball (Collect (Domainp A))) All"
using assms unfolding right_total_def Ball_def fun_rel_def Domainp_iff[abs_def]
by blast

lemma All_transfer [transfer_rule]:
  assumes "bi_total A"
  shows "((A ===> op =) ===> op =) All All"
  using assms unfolding bi_total_def fun_rel_def by fast

lemma Ex_transfer [transfer_rule]:
  assumes "bi_total A"
  shows "((A ===> op =) ===> op =) Ex Ex"
  using assms unfolding bi_total_def fun_rel_def by fast

lemma If_transfer [transfer_rule]: "(op = ===> A ===> A ===> A) If If"
  unfolding fun_rel_def by simp

lemma Let_transfer [transfer_rule]: "(A ===> (A ===> B) ===> B) Let Let"
  unfolding fun_rel_def by simp

lemma id_transfer [transfer_rule]: "(A ===> A) id id"
  unfolding fun_rel_def by simp

lemma comp_transfer [transfer_rule]:
  "((B ===> C) ===> (A ===> B) ===> (A ===> C)) (op \<circ>) (op \<circ>)"
  unfolding fun_rel_def by simp

lemma fun_upd_transfer [transfer_rule]:
  assumes [transfer_rule]: "bi_unique A"
  shows "((A ===> B) ===> A ===> B ===> A ===> B) fun_upd fun_upd"
  unfolding fun_upd_def [abs_def] by transfer_prover

lemma case_nat_transfer [transfer_rule]:
  "(A ===> (op = ===> A) ===> op = ===> A) case_nat case_nat"
  unfolding fun_rel_def by (simp split: nat.split)

lemma rec_nat_transfer [transfer_rule]:
  "(A ===> (op = ===> A ===> A) ===> op = ===> A) rec_nat rec_nat"
  unfolding fun_rel_def by (clarsimp, rename_tac n, induct_tac n, simp_all)

lemma funpow_transfer [transfer_rule]:
  "(op = ===> (A ===> A) ===> (A ===> A)) compow compow"
  unfolding funpow_def by transfer_prover

lemma mono_transfer[transfer_rule]:
  assumes [transfer_rule]: "bi_total A"
  assumes [transfer_rule]: "(A ===> A ===> op=) op\<le> op\<le>"
  assumes [transfer_rule]: "(B ===> B ===> op=) op\<le> op\<le>"
  shows "((A ===> B) ===> op=) mono mono"
unfolding mono_def[abs_def] by transfer_prover

lemma right_total_relcompp_transfer[transfer_rule]: 
  assumes [transfer_rule]: "right_total B"
  shows "((A ===> B ===> op=) ===> (B ===> C ===> op=) ===> A ===> C ===> op=) 
    (\<lambda>R S x z. \<exists>y\<in>Collect (Domainp B). R x y \<and> S y z) op OO"
unfolding OO_def[abs_def] by transfer_prover

lemma relcompp_transfer[transfer_rule]: 
  assumes [transfer_rule]: "bi_total B"
  shows "((A ===> B ===> op=) ===> (B ===> C ===> op=) ===> A ===> C ===> op=) op OO op OO"
unfolding OO_def[abs_def] by transfer_prover

lemma right_total_Domainp_transfer[transfer_rule]:
  assumes [transfer_rule]: "right_total B"
  shows "((A ===> B ===> op=) ===> A ===> op=) (\<lambda>T x. \<exists>y\<in>Collect(Domainp B). T x y) Domainp"
apply(subst(2) Domainp_iff[abs_def]) by transfer_prover

lemma Domainp_transfer[transfer_rule]:
  assumes [transfer_rule]: "bi_total B"
  shows "((A ===> B ===> op=) ===> A ===> op=) Domainp Domainp"
unfolding Domainp_iff[abs_def] by transfer_prover

lemma reflp_transfer[transfer_rule]: 
  "bi_total A \<Longrightarrow> ((A ===> A ===> op=) ===> op=) reflp reflp"
  "right_total A \<Longrightarrow> ((A ===> A ===> implies) ===> implies) reflp reflp"
  "right_total A \<Longrightarrow> ((A ===> A ===> op=) ===> implies) reflp reflp"
  "bi_total A \<Longrightarrow> ((A ===> A ===> rev_implies) ===> rev_implies) reflp reflp"
  "bi_total A \<Longrightarrow> ((A ===> A ===> op=) ===> rev_implies) reflp reflp"
using assms unfolding reflp_def[abs_def] rev_implies_def bi_total_def right_total_def fun_rel_def 
by fast+

lemma right_unique_transfer [transfer_rule]:
  assumes [transfer_rule]: "right_total A"
  assumes [transfer_rule]: "right_total B"
  assumes [transfer_rule]: "bi_unique B"
  shows "((A ===> B ===> op=) ===> implies) right_unique right_unique"
using assms unfolding right_unique_def[abs_def] right_total_def bi_unique_def fun_rel_def
by metis

end

end

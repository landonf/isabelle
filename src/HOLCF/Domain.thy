(*  Title:      HOLCF/Domain.thy
    ID:         $Id$
    Author:     Brian Huffman
*)

header {* Domain package *}

theory Domain
imports Ssum Sprod Up One Tr Fixrec
(*
files
  ("domain/library.ML")
  ("domain/syntax.ML")
  ("domain/axioms.ML")
  ("domain/theorems.ML")
  ("domain/extender.ML")
  ("domain/interface.ML")
*)
begin

defaultsort pcpo

subsection {* Continuous isomorphisms *}

text {* A locale for continuous isomorphisms *}

locale iso =
  fixes abs :: "'a \<rightarrow> 'b"
  fixes rep :: "'b \<rightarrow> 'a"
  assumes abs_iso [simp]: "rep\<cdot>(abs\<cdot>x) = x"
  assumes rep_iso [simp]: "abs\<cdot>(rep\<cdot>y) = y"

lemma (in iso) swap: "iso rep abs"
by (rule iso.intro [OF rep_iso abs_iso])

lemma (in iso) abs_less: "(abs\<cdot>x \<sqsubseteq> abs\<cdot>y) = (x \<sqsubseteq> y)"
proof
  assume "abs\<cdot>x \<sqsubseteq> abs\<cdot>y"
  hence "rep\<cdot>(abs\<cdot>x) \<sqsubseteq> rep\<cdot>(abs\<cdot>y)" by (rule monofun_cfun_arg)
  thus "x \<sqsubseteq> y" by simp
next
  assume "x \<sqsubseteq> y"
  thus "abs\<cdot>x \<sqsubseteq> abs\<cdot>y" by (rule monofun_cfun_arg)
qed

lemma (in iso) rep_less: "(rep\<cdot>x \<sqsubseteq> rep\<cdot>y) = (x \<sqsubseteq> y)"
by (rule iso.abs_less [OF swap])

lemma (in iso) abs_eq: "(abs\<cdot>x = abs\<cdot>y) = (x = y)"
by (simp add: po_eq_conv abs_less)

lemma (in iso) rep_eq: "(rep\<cdot>x = rep\<cdot>y) = (x = y)"
by (rule iso.abs_eq [OF swap])

lemma (in iso) abs_strict: "abs\<cdot>\<bottom> = \<bottom>"
proof -
  have "\<bottom> \<sqsubseteq> rep\<cdot>\<bottom>" ..
  hence "abs\<cdot>\<bottom> \<sqsubseteq> abs\<cdot>(rep\<cdot>\<bottom>)" by (rule monofun_cfun_arg)
  hence "abs\<cdot>\<bottom> \<sqsubseteq> \<bottom>" by simp
  thus ?thesis by (rule UU_I)
qed

lemma (in iso) rep_strict: "rep\<cdot>\<bottom> = \<bottom>"
by (rule iso.abs_strict [OF swap])

lemma (in iso) abs_defin': "abs\<cdot>x = \<bottom> \<Longrightarrow> x = \<bottom>"
proof -
  have "x = rep\<cdot>(abs\<cdot>x)" by simp
  also assume "abs\<cdot>x = \<bottom>"
  also note rep_strict
  finally show "x = \<bottom>" .
qed

lemma (in iso) rep_defin': "rep\<cdot>z = \<bottom> \<Longrightarrow> z = \<bottom>"
by (rule iso.abs_defin' [OF swap])

lemma (in iso) abs_defined: "z \<noteq> \<bottom> \<Longrightarrow> abs\<cdot>z \<noteq> \<bottom>"
by (erule contrapos_nn, erule abs_defin')

lemma (in iso) rep_defined: "z \<noteq> \<bottom> \<Longrightarrow> rep\<cdot>z \<noteq> \<bottom>"
by (rule iso.abs_defined [OF iso.swap])

lemma (in iso) abs_defined_iff: "(abs\<cdot>x = \<bottom>) = (x = \<bottom>)"
by (auto elim: abs_defin' intro: abs_strict)

lemma (in iso) rep_defined_iff: "(rep\<cdot>x = \<bottom>) = (x = \<bottom>)"
by (rule iso.abs_defined_iff [OF iso.swap])

lemma (in iso) compact_abs_rev: "compact (abs\<cdot>x) \<Longrightarrow> compact x"
proof (unfold compact_def)
  assume "adm (\<lambda>y. \<not> abs\<cdot>x \<sqsubseteq> y)"
  with cont_Rep_CFun2
  have "adm (\<lambda>y. \<not> abs\<cdot>x \<sqsubseteq> abs\<cdot>y)" by (rule adm_subst)
  thus "adm (\<lambda>y. \<not> x \<sqsubseteq> y)" using abs_less by simp
qed

lemma (in iso) compact_rep_rev: "compact (rep\<cdot>x) \<Longrightarrow> compact x"
by (rule iso.compact_abs_rev [OF iso.swap])

lemma (in iso) compact_abs: "compact x \<Longrightarrow> compact (abs\<cdot>x)"
by (rule compact_rep_rev, simp)

lemma (in iso) compact_rep: "compact x \<Longrightarrow> compact (rep\<cdot>x)"
by (rule iso.compact_abs [OF iso.swap])

lemma (in iso) iso_swap: "(x = abs\<cdot>y) = (rep\<cdot>x = y)"
proof
  assume "x = abs\<cdot>y"
  hence "rep\<cdot>x = rep\<cdot>(abs\<cdot>y)" by simp
  thus "rep\<cdot>x = y" by simp
next
  assume "rep\<cdot>x = y"
  hence "abs\<cdot>(rep\<cdot>x) = abs\<cdot>y" by simp
  thus "x = abs\<cdot>y" by simp
qed

subsection {* Casedist *}

lemma ex_one_defined_iff:
  "(\<exists>x. P x \<and> x \<noteq> \<bottom>) = P ONE"
 apply safe
  apply (rule_tac p=x in oneE)
   apply simp
  apply simp
 apply force
done

lemma ex_up_defined_iff:
  "(\<exists>x. P x \<and> x \<noteq> \<bottom>) = (\<exists>x. P (up\<cdot>x))"
 apply safe
  apply (rule_tac p=x in upE)
   apply simp
  apply fast
 apply (force intro!: up_defined)
done

lemma ex_sprod_defined_iff:
 "(\<exists>y. P y \<and> y \<noteq> \<bottom>) =
  (\<exists>x y. (P (:x, y:) \<and> x \<noteq> \<bottom>) \<and> y \<noteq> \<bottom>)"
 apply safe
  apply (rule_tac p=y in sprodE)
   apply simp
  apply fast
 apply (force intro!: spair_defined)
done

lemma ex_sprod_up_defined_iff:
 "(\<exists>y. P y \<and> y \<noteq> \<bottom>) =
  (\<exists>x y. P (:up\<cdot>x, y:) \<and> y \<noteq> \<bottom>)"
 apply safe
  apply (rule_tac p=y in sprodE)
   apply simp
  apply (rule_tac p=x in upE)
   apply simp
  apply fast
 apply (force intro!: spair_defined)
done

lemma ex_ssum_defined_iff:
 "(\<exists>x. P x \<and> x \<noteq> \<bottom>) =
 ((\<exists>x. P (sinl\<cdot>x) \<and> x \<noteq> \<bottom>) \<or>
  (\<exists>x. P (sinr\<cdot>x) \<and> x \<noteq> \<bottom>))"
 apply (rule iffI)
  apply (erule exE)
  apply (erule conjE)
  apply (rule_tac p=x in ssumE)
    apply simp
   apply (rule disjI1, fast)
  apply (rule disjI2, fast)
 apply (erule disjE)
  apply force
 apply force
done

lemma exh_start: "p = \<bottom> \<or> (\<exists>x. p = x \<and> x \<noteq> \<bottom>)"
by auto

lemmas ex_defined_iffs =
   ex_ssum_defined_iff
   ex_sprod_up_defined_iff
   ex_sprod_defined_iff
   ex_up_defined_iff
   ex_one_defined_iff

text {* Rules for turning exh into casedist *}

lemma exh_casedist0: "\<lbrakk>R; R \<Longrightarrow> P\<rbrakk> \<Longrightarrow> P" (* like make_elim *)
by auto

lemma exh_casedist1: "((P \<or> Q \<Longrightarrow> R) \<Longrightarrow> S) \<equiv> (\<lbrakk>P \<Longrightarrow> R; Q \<Longrightarrow> R\<rbrakk> \<Longrightarrow> S)"
by rule auto

lemma exh_casedist2: "(\<exists>x. P x \<Longrightarrow> Q) \<equiv> (\<And>x. P x \<Longrightarrow> Q)"
by rule (auto simp: norm_hhf_eq)

lemma exh_casedist3: "(P \<and> Q \<Longrightarrow> R) \<equiv> (P \<Longrightarrow> Q \<Longrightarrow> R)"
by rule auto

lemmas exh_casedists = exh_casedist1 exh_casedist2 exh_casedist3


subsection {* Setting up the package *}

ML {*
val iso_intro       = thm "iso.intro";
val iso_abs_iso     = thm "iso.abs_iso";
val iso_rep_iso     = thm "iso.rep_iso";
val iso_abs_strict  = thm "iso.abs_strict";
val iso_rep_strict  = thm "iso.rep_strict";
val iso_abs_defin'  = thm "iso.abs_defin'";
val iso_rep_defin'  = thm "iso.rep_defin'";
val iso_abs_defined = thm "iso.abs_defined";
val iso_rep_defined = thm "iso.rep_defined";
val iso_compact_abs = thm "iso.compact_abs";
val iso_compact_rep = thm "iso.compact_rep";
val iso_iso_swap    = thm "iso.iso_swap";

val exh_start = thm "exh_start";
val ex_defined_iffs = thms "ex_defined_iffs";
val exh_casedist0 = thm "exh_casedist0";
val exh_casedists = thms "exh_casedists";
*}

end

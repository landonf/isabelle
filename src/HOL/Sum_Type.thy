(*  Title:      HOL/Sum_Type.thy
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1992  University of Cambridge
*)

section\<open>The Disjoint Sum of Two Types\<close>

theory Sum_Type
imports Typedef Inductive Fun
begin

subsection \<open>Construction of the sum type and its basic abstract operations\<close>

definition Inl_Rep :: "'a \<Rightarrow> 'a \<Rightarrow> 'b \<Rightarrow> bool \<Rightarrow> bool" where
  "Inl_Rep a x y p \<longleftrightarrow> x = a \<and> p"

definition Inr_Rep :: "'b \<Rightarrow> 'a \<Rightarrow> 'b \<Rightarrow> bool \<Rightarrow> bool" where
  "Inr_Rep b x y p \<longleftrightarrow> y = b \<and> \<not> p"

definition "sum = {f. (\<exists>a. f = Inl_Rep (a::'a)) \<or> (\<exists>b. f = Inr_Rep (b::'b))}"

typedef ('a, 'b) sum (infixr "+" 10) = "sum :: ('a => 'b => bool => bool) set"
  unfolding sum_def by auto

lemma Inl_RepI: "Inl_Rep a \<in> sum"
  by (auto simp add: sum_def)

lemma Inr_RepI: "Inr_Rep b \<in> sum"
  by (auto simp add: sum_def)

lemma inj_on_Abs_sum: "A \<subseteq> sum \<Longrightarrow> inj_on Abs_sum A"
  by (rule inj_on_inverseI, rule Abs_sum_inverse) auto

lemma Inl_Rep_inject: "inj_on Inl_Rep A"
proof (rule inj_onI)
  show "\<And>a c. Inl_Rep a = Inl_Rep c \<Longrightarrow> a = c"
    by (auto simp add: Inl_Rep_def fun_eq_iff)
qed

lemma Inr_Rep_inject: "inj_on Inr_Rep A"
proof (rule inj_onI)
  show "\<And>b d. Inr_Rep b = Inr_Rep d \<Longrightarrow> b = d"
    by (auto simp add: Inr_Rep_def fun_eq_iff)
qed

lemma Inl_Rep_not_Inr_Rep: "Inl_Rep a \<noteq> Inr_Rep b"
  by (auto simp add: Inl_Rep_def Inr_Rep_def fun_eq_iff)

definition Inl :: "'a \<Rightarrow> 'a + 'b" where
  "Inl = Abs_sum \<circ> Inl_Rep"

definition Inr :: "'b \<Rightarrow> 'a + 'b" where
  "Inr = Abs_sum \<circ> Inr_Rep"

lemma inj_Inl [simp]: "inj_on Inl A"
by (auto simp add: Inl_def intro!: comp_inj_on Inl_Rep_inject inj_on_Abs_sum Inl_RepI)

lemma Inl_inject: "Inl x = Inl y \<Longrightarrow> x = y"
using inj_Inl by (rule injD)

lemma inj_Inr [simp]: "inj_on Inr A"
by (auto simp add: Inr_def intro!: comp_inj_on Inr_Rep_inject inj_on_Abs_sum Inr_RepI)

lemma Inr_inject: "Inr x = Inr y \<Longrightarrow> x = y"
using inj_Inr by (rule injD)

lemma Inl_not_Inr: "Inl a \<noteq> Inr b"
proof -
  from Inl_RepI [of a] Inr_RepI [of b] have "{Inl_Rep a, Inr_Rep b} \<subseteq> sum" by auto
  with inj_on_Abs_sum have "inj_on Abs_sum {Inl_Rep a, Inr_Rep b}" .
  with Inl_Rep_not_Inr_Rep [of a b] inj_on_contraD have "Abs_sum (Inl_Rep a) \<noteq> Abs_sum (Inr_Rep b)" by auto
  then show ?thesis by (simp add: Inl_def Inr_def)
qed

lemma Inr_not_Inl: "Inr b \<noteq> Inl a" 
  using Inl_not_Inr by (rule not_sym)

lemma sumE: 
  assumes "\<And>x::'a. s = Inl x \<Longrightarrow> P"
    and "\<And>y::'b. s = Inr y \<Longrightarrow> P"
  shows P
proof (rule Abs_sum_cases [of s])
  fix f 
  assume "s = Abs_sum f" and "f \<in> sum"
  with assms show P by (auto simp add: sum_def Inl_def Inr_def)
qed

free_constructors case_sum for
    isl: Inl projl
  | Inr projr
  by (erule sumE, assumption) (auto dest: Inl_inject Inr_inject simp add: Inl_not_Inr)

text \<open>Avoid name clashes by prefixing the output of \<open>old_rep_datatype\<close> with \<open>old\<close>.\<close>

setup \<open>Sign.mandatory_path "old"\<close>

old_rep_datatype Inl Inr
proof -
  fix P
  fix s :: "'a + 'b"
  assume x: "\<And>x::'a. P (Inl x)" and y: "\<And>y::'b. P (Inr y)"
  then show "P s" by (auto intro: sumE [of s])
qed (auto dest: Inl_inject Inr_inject simp add: Inl_not_Inr)

setup \<open>Sign.parent_path\<close>

text \<open>But erase the prefix for properties that are not generated by \<open>free_constructors\<close>.\<close>

setup \<open>Sign.mandatory_path "sum"\<close>

declare
  old.sum.inject[iff del]
  old.sum.distinct(1)[simp del, induct_simp del]

lemmas induct = old.sum.induct
lemmas inducts = old.sum.inducts
lemmas rec = old.sum.rec
lemmas simps = sum.inject sum.distinct sum.case sum.rec

setup \<open>Sign.parent_path\<close>

primrec map_sum :: "('a \<Rightarrow> 'c) \<Rightarrow> ('b \<Rightarrow> 'd) \<Rightarrow> 'a + 'b \<Rightarrow> 'c + 'd" where
  "map_sum f1 f2 (Inl a) = Inl (f1 a)"
| "map_sum f1 f2 (Inr a) = Inr (f2 a)"

functor map_sum: map_sum proof -
  fix f g h i
  show "map_sum f g \<circ> map_sum h i = map_sum (f \<circ> h) (g \<circ> i)"
  proof
    fix s
    show "(map_sum f g \<circ> map_sum h i) s = map_sum (f \<circ> h) (g \<circ> i) s"
      by (cases s) simp_all
  qed
next
  fix s
  show "map_sum id id = id"
  proof
    fix s
    show "map_sum id id s = id s" 
      by (cases s) simp_all
  qed
qed

lemma split_sum_all: "(\<forall>x. P x) \<longleftrightarrow> (\<forall>x. P (Inl x)) \<and> (\<forall>x. P (Inr x))"
  by (auto intro: sum.induct)

lemma split_sum_ex: "(\<exists>x. P x) \<longleftrightarrow> (\<exists>x. P (Inl x)) \<or> (\<exists>x. P (Inr x))"
using split_sum_all[of "\<lambda>x. \<not>P x"] by blast

subsection \<open>Projections\<close>

lemma case_sum_KK [simp]: "case_sum (\<lambda>x. a) (\<lambda>x. a) = (\<lambda>x. a)"
  by (rule ext) (simp split: sum.split)

lemma surjective_sum: "case_sum (\<lambda>x::'a. f (Inl x)) (\<lambda>y::'b. f (Inr y)) = f"
proof
  fix s :: "'a + 'b"
  show "(case s of Inl (x::'a) \<Rightarrow> f (Inl x) | Inr (y::'b) \<Rightarrow> f (Inr y)) = f s"
    by (cases s) simp_all
qed

lemma case_sum_inject:
  assumes a: "case_sum f1 f2 = case_sum g1 g2"
  assumes r: "f1 = g1 \<Longrightarrow> f2 = g2 \<Longrightarrow> P"
  shows P
proof (rule r)
  show "f1 = g1" proof
    fix x :: 'a
    from a have "case_sum f1 f2 (Inl x) = case_sum g1 g2 (Inl x)" by simp
    then show "f1 x = g1 x" by simp
  qed
  show "f2 = g2" proof
    fix y :: 'b
    from a have "case_sum f1 f2 (Inr y) = case_sum g1 g2 (Inr y)" by simp
    then show "f2 y = g2 y" by simp
  qed
qed

primrec Suml :: "('a \<Rightarrow> 'c) \<Rightarrow> 'a + 'b \<Rightarrow> 'c" where
  "Suml f (Inl x) = f x"

primrec Sumr :: "('b \<Rightarrow> 'c) \<Rightarrow> 'a + 'b \<Rightarrow> 'c" where
  "Sumr f (Inr x) = f x"

lemma Suml_inject:
  assumes "Suml f = Suml g" shows "f = g"
proof
  fix x :: 'a
  let ?s = "Inl x :: 'a + 'b"
  from assms have "Suml f ?s = Suml g ?s" by simp
  then show "f x = g x" by simp
qed

lemma Sumr_inject:
  assumes "Sumr f = Sumr g" shows "f = g"
proof
  fix x :: 'b
  let ?s = "Inr x :: 'a + 'b"
  from assms have "Sumr f ?s = Sumr g ?s" by simp
  then show "f x = g x" by simp
qed


subsection \<open>The Disjoint Sum of Sets\<close>

definition Plus :: "'a set \<Rightarrow> 'b set \<Rightarrow> ('a + 'b) set" (infixr "<+>" 65) where
  "A <+> B = Inl ` A \<union> Inr ` B"

hide_const (open) Plus \<comment>"Valuable identifier"

lemma InlI [intro!]: "a \<in> A \<Longrightarrow> Inl a \<in> A <+> B"
by (simp add: Plus_def)

lemma InrI [intro!]: "b \<in> B \<Longrightarrow> Inr b \<in> A <+> B"
by (simp add: Plus_def)

text \<open>Exhaustion rule for sums, a degenerate form of induction\<close>

lemma PlusE [elim!]: 
  "u \<in> A <+> B \<Longrightarrow> (\<And>x. x \<in> A \<Longrightarrow> u = Inl x \<Longrightarrow> P) \<Longrightarrow> (\<And>y. y \<in> B \<Longrightarrow> u = Inr y \<Longrightarrow> P) \<Longrightarrow> P"
by (auto simp add: Plus_def)

lemma Plus_eq_empty_conv [simp]: "A <+> B = {} \<longleftrightarrow> A = {} \<and> B = {}"
by auto

lemma UNIV_Plus_UNIV [simp]: "UNIV <+> UNIV = UNIV"
proof (rule set_eqI)
  fix u :: "'a + 'b"
  show "u \<in> UNIV <+> UNIV \<longleftrightarrow> u \<in> UNIV" by (cases u) auto
qed

lemma UNIV_sum:
  "UNIV = Inl ` UNIV \<union> Inr ` UNIV"
proof -
  { fix x :: "'a + 'b"
    assume "x \<notin> range Inr"
    then have "x \<in> range Inl"
    by (cases x) simp_all
  } then show ?thesis by auto
qed

hide_const (open) Suml Sumr sum

end

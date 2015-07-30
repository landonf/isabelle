(*  Title:      HOL/Library/Infinite_Set.thy
    Author:     Stephan Merz
*)

section \<open>Infinite Sets and Related Concepts\<close>

theory Infinite_Set
imports Main
begin

subsection "Infinite Sets"

text \<open>
  Some elementary facts about infinite sets, mostly by Stephan Merz.
  Beware! Because "infinite" merely abbreviates a negation, these
  lemmas may not work well with @{text "blast"}.
\<close>

abbreviation infinite :: "'a set \<Rightarrow> bool"
  where "infinite S \<equiv> \<not> finite S"

text \<open>
  Infinite sets are non-empty, and if we remove some elements from an
  infinite set, the result is still infinite.
\<close>

lemma infinite_imp_nonempty: "infinite S \<Longrightarrow> S \<noteq> {}"
  by auto

lemma infinite_remove: "infinite S \<Longrightarrow> infinite (S - {a})"
  by simp

lemma Diff_infinite_finite:
  assumes T: "finite T" and S: "infinite S"
  shows "infinite (S - T)"
  using T
proof induct
  from S
  show "infinite (S - {})" by auto
next
  fix T x
  assume ih: "infinite (S - T)"
  have "S - (insert x T) = (S - T) - {x}"
    by (rule Diff_insert)
  with ih
  show "infinite (S - (insert x T))"
    by (simp add: infinite_remove)
qed

lemma Un_infinite: "infinite S \<Longrightarrow> infinite (S \<union> T)"
  by simp

lemma infinite_Un: "infinite (S \<union> T) \<longleftrightarrow> infinite S \<or> infinite T"
  by simp

lemma infinite_super:
  assumes T: "S \<subseteq> T" and S: "infinite S"
  shows "infinite T"
proof
  assume "finite T"
  with T have "finite S" by (simp add: finite_subset)
  with S show False by simp
qed

lemma infinite_coinduct [consumes 1, case_names infinite]:
  assumes "X A"
  and step: "\<And>A. X A \<Longrightarrow> \<exists>x\<in>A. X (A - {x}) \<or> infinite (A - {x})"
  shows "infinite A"
proof
  assume "finite A"
  then show False using \<open>X A\<close>
    by(induction rule: finite_psubset_induct)(meson Diff_subset card_Diff1_less card_psubset finite_Diff step)
qed    

text \<open>
  As a concrete example, we prove that the set of natural numbers is
  infinite.
\<close>

lemma infinite_nat_iff_unbounded_le: "infinite (S::nat set) \<longleftrightarrow> (\<forall>m. \<exists>n\<ge>m. n \<in> S)"
  using frequently_cofinite[of "\<lambda>x. x \<in> S"]
  by (simp add: cofinite_eq_sequentially frequently_def eventually_sequentially)

lemma infinite_nat_iff_unbounded: "infinite (S::nat set) \<longleftrightarrow> (\<forall>m. \<exists>n>m. n \<in> S)"
  using frequently_cofinite[of "\<lambda>x. x \<in> S"]
  by (simp add: cofinite_eq_sequentially frequently_def eventually_at_top_dense)

lemma finite_nat_iff_bounded: "finite (S::nat set) \<longleftrightarrow> (\<exists>k. S \<subseteq> {..<k})"
  using infinite_nat_iff_unbounded_le[of S] by (simp add: subset_eq) (metis not_le)

lemma finite_nat_iff_bounded_le: "finite (S::nat set) \<longleftrightarrow> (\<exists>k. S \<subseteq> {.. k})"
  using infinite_nat_iff_unbounded[of S] by (simp add: subset_eq) (metis not_le)

lemma finite_nat_bounded: "finite (S::nat set) \<Longrightarrow> \<exists>k. S \<subseteq> {..<k}"
  by (simp add: finite_nat_iff_bounded)

text \<open>
  For a set of natural numbers to be infinite, it is enough to know
  that for any number larger than some @{text k}, there is some larger
  number that is an element of the set.
\<close>

lemma unbounded_k_infinite: "\<forall>m>k. \<exists>n>m. n \<in> S \<Longrightarrow> infinite (S::nat set)"
  by (metis (full_types) infinite_nat_iff_unbounded_le le_imp_less_Suc not_less
            not_less_iff_gr_or_eq sup.bounded_iff)

lemma nat_not_finite: "finite (UNIV::nat set) \<Longrightarrow> R"
  by simp

lemma range_inj_infinite:
  "inj (f::nat \<Rightarrow> 'a) \<Longrightarrow> infinite (range f)"
proof
  assume "finite (range f)" and "inj f"
  then have "finite (UNIV::nat set)"
    by (rule finite_imageD)
  then show False by simp
qed

text \<open>
  For any function with infinite domain and finite range there is some
  element that is the image of infinitely many domain elements.  In
  particular, any infinite sequence of elements from a finite set
  contains some element that occurs infinitely often.
\<close>

lemma inf_img_fin_dom':
  assumes img: "finite (f ` A)" and dom: "infinite A"
  shows "\<exists>y \<in> f ` A. infinite (f -` {y} \<inter> A)"
proof (rule ccontr)
  have "A \<subseteq> (\<Union>y\<in>f ` A. f -` {y} \<inter> A)" by auto
  moreover
  assume "\<not> ?thesis"
  with img have "finite (\<Union>y\<in>f ` A. f -` {y} \<inter> A)" by blast
  ultimately have "finite A" by(rule finite_subset)
  with dom show False by contradiction
qed

lemma inf_img_fin_domE':
  assumes "finite (f ` A)" and "infinite A"
  obtains y where "y \<in> f`A" and "infinite (f -` {y} \<inter> A)"
  using assms by (blast dest: inf_img_fin_dom')

lemma inf_img_fin_dom:
  assumes img: "finite (f`A)" and dom: "infinite A"
  shows "\<exists>y \<in> f`A. infinite (f -` {y})"
using inf_img_fin_dom'[OF assms] by auto

lemma inf_img_fin_domE:
  assumes "finite (f`A)" and "infinite A"
  obtains y where "y \<in> f`A" and "infinite (f -` {y})"
  using assms by (blast dest: inf_img_fin_dom)

subsection "Infinitely Many and Almost All"

text \<open>
  We often need to reason about the existence of infinitely many
  (resp., all but finitely many) objects satisfying some predicate, so
  we introduce corresponding binders and their proof rules.
\<close>

(* The following two lemmas are available as filter-rules, but not in the simp-set *)
lemma not_INFM [simp]: "\<not> (INFM x. P x) \<longleftrightarrow> (MOST x. \<not> P x)" by (fact not_frequently)
lemma not_MOST [simp]: "\<not> (MOST x. P x) \<longleftrightarrow> (INFM x. \<not> P x)" by (fact not_eventually)

lemma INFM_const [simp]: "(INFM x::'a. P) \<longleftrightarrow> P \<and> infinite (UNIV::'a set)"
  by (simp add: frequently_const_iff)

lemma MOST_const [simp]: "(MOST x::'a. P) \<longleftrightarrow> P \<or> finite (UNIV::'a set)"
  by (simp add: eventually_const_iff)

lemma INFM_imp_distrib: "(INFM x. P x \<longrightarrow> Q x) \<longleftrightarrow> ((MOST x. P x) \<longrightarrow> (INFM x. Q x))"
  by (simp only: imp_conv_disj frequently_disj_iff not_eventually)

lemma MOST_imp_iff: "MOST x. P x \<Longrightarrow> (MOST x. P x \<longrightarrow> Q x) \<longleftrightarrow> (MOST x. Q x)"
  by (auto intro: eventually_rev_mp eventually_elim1)

lemma INFM_conjI: "INFM x. P x \<Longrightarrow> MOST x. Q x \<Longrightarrow> INFM x. P x \<and> Q x"
  by (rule frequently_rev_mp[of P]) (auto elim: eventually_elim1)

text \<open>Properties of quantifiers with injective functions.\<close>

lemma INFM_inj: "INFM x. P (f x) \<Longrightarrow> inj f \<Longrightarrow> INFM x. P x"
  using finite_vimageI[of "{x. P x}" f] by (auto simp: frequently_cofinite)

lemma MOST_inj: "MOST x. P x \<Longrightarrow> inj f \<Longrightarrow> MOST x. P (f x)"
  using finite_vimageI[of "{x. \<not> P x}" f] by (auto simp: eventually_cofinite)

text \<open>Properties of quantifiers with singletons.\<close>

lemma not_INFM_eq [simp]:
  "\<not> (INFM x. x = a)"
  "\<not> (INFM x. a = x)"
  unfolding frequently_cofinite by simp_all

lemma MOST_neq [simp]:
  "MOST x. x \<noteq> a"
  "MOST x. a \<noteq> x"
  unfolding eventually_cofinite by simp_all

lemma INFM_neq [simp]:
  "(INFM x::'a. x \<noteq> a) \<longleftrightarrow> infinite (UNIV::'a set)"
  "(INFM x::'a. a \<noteq> x) \<longleftrightarrow> infinite (UNIV::'a set)"
  unfolding frequently_cofinite by simp_all

lemma MOST_eq [simp]:
  "(MOST x::'a. x = a) \<longleftrightarrow> finite (UNIV::'a set)"
  "(MOST x::'a. a = x) \<longleftrightarrow> finite (UNIV::'a set)"
  unfolding eventually_cofinite by simp_all

lemma MOST_eq_imp:
  "MOST x. x = a \<longrightarrow> P x"
  "MOST x. a = x \<longrightarrow> P x"
  unfolding eventually_cofinite by simp_all

text \<open>Properties of quantifiers over the naturals.\<close>

lemma MOST_nat: "(\<forall>\<^sub>\<infinity>n. P (n::nat)) \<longleftrightarrow> (\<exists>m. \<forall>n>m. P n)"
  by (auto simp add: eventually_cofinite finite_nat_iff_bounded_le subset_eq not_le[symmetric])

lemma MOST_nat_le: "(\<forall>\<^sub>\<infinity>n. P (n::nat)) \<longleftrightarrow> (\<exists>m. \<forall>n\<ge>m. P n)"
  by (auto simp add: eventually_cofinite finite_nat_iff_bounded subset_eq not_le[symmetric])

lemma INFM_nat: "(\<exists>\<^sub>\<infinity>n. P (n::nat)) \<longleftrightarrow> (\<forall>m. \<exists>n>m. P n)"
  by (simp add: frequently_cofinite infinite_nat_iff_unbounded)

lemma INFM_nat_le: "(\<exists>\<^sub>\<infinity>n. P (n::nat)) \<longleftrightarrow> (\<forall>m. \<exists>n\<ge>m. P n)"
  by (simp add: frequently_cofinite infinite_nat_iff_unbounded_le)

lemma MOST_INFM: "infinite (UNIV::'a set) \<Longrightarrow> MOST x::'a. P x \<Longrightarrow> INFM x::'a. P x"
  by (simp add: eventually_frequently)

lemma MOST_Suc_iff: "(MOST n. P (Suc n)) \<longleftrightarrow> (MOST n. P n)"
  by (simp add: cofinite_eq_sequentially eventually_sequentially_Suc)

lemma
  shows MOST_SucI: "MOST n. P n \<Longrightarrow> MOST n. P (Suc n)"
    and MOST_SucD: "MOST n. P (Suc n) \<Longrightarrow> MOST n. P n"
  by (simp_all add: MOST_Suc_iff)

lemma MOST_ge_nat: "MOST n::nat. m \<le> n"
  by (simp add: cofinite_eq_sequentially eventually_ge_at_top)

(* legacy names *)
lemma Inf_many_def: "Inf_many P \<longleftrightarrow> infinite {x. P x}" by (fact frequently_cofinite)
lemma Alm_all_def: "Alm_all P \<longleftrightarrow> \<not> (INFM x. \<not> P x)" by simp
lemma INFM_iff_infinite: "(INFM x. P x) \<longleftrightarrow> infinite {x. P x}" by (fact frequently_cofinite)
lemma MOST_iff_cofinite: "(MOST x. P x) \<longleftrightarrow> finite {x. \<not> P x}" by (fact eventually_cofinite)
lemma INFM_EX: "(\<exists>\<^sub>\<infinity>x. P x) \<Longrightarrow> (\<exists>x. P x)" by (fact frequently_ex)
lemma ALL_MOST: "\<forall>x. P x \<Longrightarrow> \<forall>\<^sub>\<infinity>x. P x" by (fact always_eventually)
lemma INFM_mono: "\<exists>\<^sub>\<infinity>x. P x \<Longrightarrow> (\<And>x. P x \<Longrightarrow> Q x) \<Longrightarrow> \<exists>\<^sub>\<infinity>x. Q x" by (fact frequently_elim1)
lemma MOST_mono: "\<forall>\<^sub>\<infinity>x. P x \<Longrightarrow> (\<And>x. P x \<Longrightarrow> Q x) \<Longrightarrow> \<forall>\<^sub>\<infinity>x. Q x" by (fact eventually_elim1)
lemma INFM_disj_distrib: "(\<exists>\<^sub>\<infinity>x. P x \<or> Q x) \<longleftrightarrow> (\<exists>\<^sub>\<infinity>x. P x) \<or> (\<exists>\<^sub>\<infinity>x. Q x)" by (fact frequently_disj_iff)
lemma MOST_rev_mp: "\<forall>\<^sub>\<infinity>x. P x \<Longrightarrow> \<forall>\<^sub>\<infinity>x. P x \<longrightarrow> Q x \<Longrightarrow> \<forall>\<^sub>\<infinity>x. Q x" by (fact eventually_rev_mp)
lemma MOST_conj_distrib: "(\<forall>\<^sub>\<infinity>x. P x \<and> Q x) \<longleftrightarrow> (\<forall>\<^sub>\<infinity>x. P x) \<and> (\<forall>\<^sub>\<infinity>x. Q x)" by (fact eventually_conj_iff)
lemma MOST_conjI: "MOST x. P x \<Longrightarrow> MOST x. Q x \<Longrightarrow> MOST x. P x \<and> Q x" by (fact eventually_conj)
lemma INFM_finite_Bex_distrib: "finite A \<Longrightarrow> (INFM y. \<exists>x\<in>A. P x y) \<longleftrightarrow> (\<exists>x\<in>A. INFM y. P x y)" by (fact frequently_bex_finite_distrib)
lemma MOST_finite_Ball_distrib: "finite A \<Longrightarrow> (MOST y. \<forall>x\<in>A. P x y) \<longleftrightarrow> (\<forall>x\<in>A. MOST y. P x y)" by (fact eventually_ball_finite_distrib)
lemma INFM_E: "INFM x. P x \<Longrightarrow> (\<And>x. P x \<Longrightarrow> thesis) \<Longrightarrow> thesis" by (fact frequentlyE)
lemma MOST_I: "(\<And>x. P x) \<Longrightarrow> MOST x. P x" by (rule eventuallyI)
lemmas MOST_iff_finiteNeg = MOST_iff_cofinite

subsection "Enumeration of an Infinite Set"

text \<open>
  The set's element type must be wellordered (e.g. the natural numbers).
\<close>

text \<open>
  Could be generalized to
    @{term "enumerate' S n = (SOME t. t \<in> s \<and> finite {s\<in>S. s < t} \<and> card {s\<in>S. s < t} = n)"}.
\<close>

primrec (in wellorder) enumerate :: "'a set \<Rightarrow> nat \<Rightarrow> 'a"
where
  enumerate_0: "enumerate S 0 = (LEAST n. n \<in> S)"
| enumerate_Suc: "enumerate S (Suc n) = enumerate (S - {LEAST n. n \<in> S}) n"

lemma enumerate_Suc': "enumerate S (Suc n) = enumerate (S - {enumerate S 0}) n"
  by simp

lemma enumerate_in_set: "infinite S \<Longrightarrow> enumerate S n \<in> S"
  apply (induct n arbitrary: S)
   apply (fastforce intro: LeastI dest!: infinite_imp_nonempty)
  apply simp
  apply (metis DiffE infinite_remove)
  done

declare enumerate_0 [simp del] enumerate_Suc [simp del]

lemma enumerate_step: "infinite S \<Longrightarrow> enumerate S n < enumerate S (Suc n)"
  apply (induct n arbitrary: S)
   apply (rule order_le_neq_trans)
    apply (simp add: enumerate_0 Least_le enumerate_in_set)
   apply (simp only: enumerate_Suc')
   apply (subgoal_tac "enumerate (S - {enumerate S 0}) 0 \<in> S - {enumerate S 0}")
    apply (blast intro: sym)
   apply (simp add: enumerate_in_set del: Diff_iff)
  apply (simp add: enumerate_Suc')
  done

lemma enumerate_mono: "m < n \<Longrightarrow> infinite S \<Longrightarrow> enumerate S m < enumerate S n"
  apply (erule less_Suc_induct)
  apply (auto intro: enumerate_step)
  done


lemma le_enumerate:
  assumes S: "infinite S"
  shows "n \<le> enumerate S n"
  using S 
proof (induct n)
  case 0
  then show ?case by simp
next
  case (Suc n)
  then have "n \<le> enumerate S n" by simp
  also note enumerate_mono[of n "Suc n", OF _ \<open>infinite S\<close>]
  finally show ?case by simp
qed

lemma enumerate_Suc'':
  fixes S :: "'a::wellorder set"
  assumes "infinite S"
  shows "enumerate S (Suc n) = (LEAST s. s \<in> S \<and> enumerate S n < s)"
  using assms
proof (induct n arbitrary: S)
  case 0
  then have "\<forall>s \<in> S. enumerate S 0 \<le> s"
    by (auto simp: enumerate.simps intro: Least_le)
  then show ?case
    unfolding enumerate_Suc' enumerate_0[of "S - {enumerate S 0}"]
    by (intro arg_cong[where f = Least] ext) auto
next
  case (Suc n S)
  show ?case
    using enumerate_mono[OF zero_less_Suc \<open>infinite S\<close>, of n] \<open>infinite S\<close>
    apply (subst (1 2) enumerate_Suc')
    apply (subst Suc)
    using \<open>infinite S\<close>
    apply simp
    apply (intro arg_cong[where f = Least] ext)
    apply (auto simp: enumerate_Suc'[symmetric])
    done
qed

lemma enumerate_Ex:
  assumes S: "infinite (S::nat set)"
  shows "s \<in> S \<Longrightarrow> \<exists>n. enumerate S n = s"
proof (induct s rule: less_induct)
  case (less s)
  show ?case
  proof cases
    let ?y = "Max {s'\<in>S. s' < s}"
    assume "\<exists>y\<in>S. y < s"
    then have y: "\<And>x. ?y < x \<longleftrightarrow> (\<forall>s'\<in>S. s' < s \<longrightarrow> s' < x)"
      by (subst Max_less_iff) auto
    then have y_in: "?y \<in> {s'\<in>S. s' < s}"
      by (intro Max_in) auto
    with less.hyps[of ?y] obtain n where "enumerate S n = ?y"
      by auto
    with S have "enumerate S (Suc n) = s"
      by (auto simp: y less enumerate_Suc'' intro!: Least_equality)
    then show ?case by auto
  next
    assume *: "\<not> (\<exists>y\<in>S. y < s)"
    then have "\<forall>t\<in>S. s \<le> t" by auto
    with \<open>s \<in> S\<close> show ?thesis
      by (auto intro!: exI[of _ 0] Least_equality simp: enumerate_0)
  qed
qed

lemma bij_enumerate:
  fixes S :: "nat set"
  assumes S: "infinite S"
  shows "bij_betw (enumerate S) UNIV S"
proof -
  have "\<And>n m. n \<noteq> m \<Longrightarrow> enumerate S n \<noteq> enumerate S m"
    using enumerate_mono[OF _ \<open>infinite S\<close>] by (auto simp: neq_iff)
  then have "inj (enumerate S)"
    by (auto simp: inj_on_def)
  moreover have "\<forall>s \<in> S. \<exists>i. enumerate S i = s"
    using enumerate_Ex[OF S] by auto
  moreover note \<open>infinite S\<close>
  ultimately show ?thesis
    unfolding bij_betw_def by (auto intro: enumerate_in_set)
qed

subsection "Miscellaneous"

text \<open>
  A few trivial lemmas about sets that contain at most one element.
  These simplify the reasoning about deterministic automata.
\<close>

definition atmost_one :: "'a set \<Rightarrow> bool"
  where "atmost_one S \<longleftrightarrow> (\<forall>x y. x\<in>S \<and> y\<in>S \<longrightarrow> x = y)"

lemma atmost_one_empty: "S = {} \<Longrightarrow> atmost_one S"
  by (simp add: atmost_one_def)

lemma atmost_one_singleton: "S = {x} \<Longrightarrow> atmost_one S"
  by (simp add: atmost_one_def)

lemma atmost_one_unique [elim]: "atmost_one S \<Longrightarrow> x \<in> S \<Longrightarrow> y \<in> S \<Longrightarrow> y = x"
  by (simp add: atmost_one_def)

end


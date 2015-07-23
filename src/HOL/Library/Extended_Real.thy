(*  Title:      HOL/Library/Extended_Real.thy
    Author:     Johannes Hölzl, TU München
    Author:     Robert Himmelmann, TU München
    Author:     Armin Heller, TU München
    Author:     Bogdan Grechuk, University of Edinburgh
*)

section \<open>Extended real number line\<close>

theory Extended_Real
imports Complex_Main Extended_Nat Liminf_Limsup
begin

text \<open>

This should be part of @{theory Extended_Nat} or @{theory Order_Continuity}, but then the
AFP-entry @{text "Jinja_Thread"} fails, as it does overload certain named from @{theory Complex_Main}.

\<close>

lemma continuous_at_left_imp_sup_continuous:
  fixes f :: "'a \<Rightarrow> 'a::{complete_linorder, linorder_topology}"
  assumes "mono f" "\<And>x. continuous (at_left x) f"
  shows "sup_continuous f"
  unfolding sup_continuous_def
proof safe
  fix M :: "nat \<Rightarrow> 'a" assume "incseq M" then show "f (SUP i. M i) = (SUP i. f (M i))"
    using continuous_at_Sup_mono[OF assms, of "range M"] by simp
qed

lemma sup_continuous_at_left:
  fixes f :: "'a \<Rightarrow> 'a::{complete_linorder, linorder_topology, first_countable_topology}"
  assumes f: "sup_continuous f"
  shows "continuous (at_left x) f"
proof cases
  assume "x = bot" then show ?thesis
    by (simp add: trivial_limit_at_left_bot)
next
  assume x: "x \<noteq> bot" 
  show ?thesis
    unfolding continuous_within
  proof (intro tendsto_at_left_sequentially[of bot])
    fix S :: "nat \<Rightarrow> 'a" assume S: "incseq S" and S_x: "S ----> x"
    from S_x have x_eq: "x = (SUP i. S i)"
      by (rule LIMSEQ_unique) (intro LIMSEQ_SUP S)
    show "(\<lambda>n. f (S n)) ----> f x"
      unfolding x_eq sup_continuousD[OF f S]
      using S sup_continuous_mono[OF f] by (intro LIMSEQ_SUP) (auto simp: mono_def)
  qed (insert x, auto simp: bot_less)
qed

lemma sup_continuous_iff_at_left:
  fixes f :: "'a \<Rightarrow> 'a::{complete_linorder, linorder_topology, first_countable_topology}"
  shows "sup_continuous f \<longleftrightarrow> (\<forall>x. continuous (at_left x) f) \<and> mono f"
  using sup_continuous_at_left[of f] continuous_at_left_imp_sup_continuous[of f]
    sup_continuous_mono[of f] by auto
  
lemma continuous_at_right_imp_inf_continuous:
  fixes f :: "'a \<Rightarrow> 'a::{complete_linorder, linorder_topology}"
  assumes "mono f" "\<And>x. continuous (at_right x) f"
  shows "inf_continuous f"
  unfolding inf_continuous_def
proof safe
  fix M :: "nat \<Rightarrow> 'a" assume "decseq M" then show "f (INF i. M i) = (INF i. f (M i))"
    using continuous_at_Inf_mono[OF assms, of "range M"] by simp
qed

lemma inf_continuous_at_right:
  fixes f :: "'a \<Rightarrow> 'a::{complete_linorder, linorder_topology, first_countable_topology}"
  assumes f: "inf_continuous f"
  shows "continuous (at_right x) f"
proof cases
  assume "x = top" then show ?thesis
    by (simp add: trivial_limit_at_right_top)
next
  assume x: "x \<noteq> top" 
  show ?thesis
    unfolding continuous_within
  proof (intro tendsto_at_right_sequentially[of _ top])
    fix S :: "nat \<Rightarrow> 'a" assume S: "decseq S" and S_x: "S ----> x"
    from S_x have x_eq: "x = (INF i. S i)"
      by (rule LIMSEQ_unique) (intro LIMSEQ_INF S)
    show "(\<lambda>n. f (S n)) ----> f x"
      unfolding x_eq inf_continuousD[OF f S]
      using S inf_continuous_mono[OF f] by (intro LIMSEQ_INF) (auto simp: mono_def antimono_def)
  qed (insert x, auto simp: less_top)
qed

lemma inf_continuous_iff_at_right:
  fixes f :: "'a \<Rightarrow> 'a::{complete_linorder, linorder_topology, first_countable_topology}"
  shows "inf_continuous f \<longleftrightarrow> (\<forall>x. continuous (at_right x) f) \<and> mono f"
  using inf_continuous_at_right[of f] continuous_at_right_imp_inf_continuous[of f]
    inf_continuous_mono[of f] by auto

instantiation enat :: linorder_topology
begin

definition open_enat :: "enat set \<Rightarrow> bool" where
  "open_enat = generate_topology (range lessThan \<union> range greaterThan)"

instance
  proof qed (rule open_enat_def)

end

lemma open_enat: "open {enat n}"
proof (cases n)
  case 0
  then have "{enat n} = {..< eSuc 0}"
    by (auto simp: enat_0)
  then show ?thesis
    by simp
next
  case (Suc n')
  then have "{enat n} = {enat n' <..< enat (Suc n)}"
    apply auto
    apply (case_tac x)
    apply auto
    done
  then show ?thesis
    by simp
qed

lemma open_enat_iff:
  fixes A :: "enat set"
  shows "open A \<longleftrightarrow> (\<infinity> \<in> A \<longrightarrow> (\<exists>n::nat. {n <..} \<subseteq> A))"
proof safe
  assume "\<infinity> \<notin> A"
  then have "A = (\<Union>n\<in>{n. enat n \<in> A}. {enat n})"
    apply auto
    apply (case_tac x)
    apply auto
    done
  moreover have "open \<dots>"
    by (auto intro: open_enat)
  ultimately show "open A"
    by simp
next
  fix n assume "{enat n <..} \<subseteq> A"
  then have "A = (\<Union>n\<in>{n. enat n \<in> A}. {enat n}) \<union> {enat n <..}"
    apply auto
    apply (case_tac x)
    apply auto
    done
  moreover have "open \<dots>"
    by (intro open_Un open_UN ballI open_enat open_greaterThan)
  ultimately show "open A"
    by simp
next
  assume "open A" "\<infinity> \<in> A"
  then have "generate_topology (range lessThan \<union> range greaterThan) A" "\<infinity> \<in> A"
    unfolding open_enat_def by auto
  then show "\<exists>n::nat. {n <..} \<subseteq> A"
  proof induction
    case (Int A B)
    then obtain n m where "{enat n<..} \<subseteq> A" "{enat m<..} \<subseteq> B"
      by auto
    then have "{enat (max n m) <..} \<subseteq> A \<inter> B"
      by (auto simp add: subset_eq Ball_def max_def enat_ord_code(1)[symmetric] simp del: enat_ord_code(1))
    then show ?case
      by auto
  next
    case (UN K)
    then obtain k where "k \<in> K" "\<infinity> \<in> k"
      by auto
    with UN.IH[OF this] show ?case
      by auto
  qed auto
qed


text \<open>

For more lemmas about the extended real numbers go to
  @{file "~~/src/HOL/Multivariate_Analysis/Extended_Real_Limits.thy"}

\<close>

subsection \<open>Definition and basic properties\<close>

datatype ereal = ereal real | PInfty | MInfty

instantiation ereal :: uminus
begin

fun uminus_ereal where
  "- (ereal r) = ereal (- r)"
| "- PInfty = MInfty"
| "- MInfty = PInfty"

instance ..

end

instantiation ereal :: infinity
begin

definition "(\<infinity>::ereal) = PInfty"
instance ..

end

declare [[coercion "ereal :: real \<Rightarrow> ereal"]]

lemma ereal_uminus_uminus[simp]:
  fixes a :: ereal
  shows "- (- a) = a"
  by (cases a) simp_all

lemma
  shows PInfty_eq_infinity[simp]: "PInfty = \<infinity>"
    and MInfty_eq_minfinity[simp]: "MInfty = - \<infinity>"
    and MInfty_neq_PInfty[simp]: "\<infinity> \<noteq> - (\<infinity>::ereal)" "- \<infinity> \<noteq> (\<infinity>::ereal)"
    and MInfty_neq_ereal[simp]: "ereal r \<noteq> - \<infinity>" "- \<infinity> \<noteq> ereal r"
    and PInfty_neq_ereal[simp]: "ereal r \<noteq> \<infinity>" "\<infinity> \<noteq> ereal r"
    and PInfty_cases[simp]: "(case \<infinity> of ereal r \<Rightarrow> f r | PInfty \<Rightarrow> y | MInfty \<Rightarrow> z) = y"
    and MInfty_cases[simp]: "(case - \<infinity> of ereal r \<Rightarrow> f r | PInfty \<Rightarrow> y | MInfty \<Rightarrow> z) = z"
  by (simp_all add: infinity_ereal_def)

declare
  PInfty_eq_infinity[code_post]
  MInfty_eq_minfinity[code_post]

lemma [code_unfold]:
  "\<infinity> = PInfty"
  "- PInfty = MInfty"
  by simp_all

lemma inj_ereal[simp]: "inj_on ereal A"
  unfolding inj_on_def by auto

lemma ereal_cases[cases type: ereal]:
  obtains (real) r where "x = ereal r"
    | (PInf) "x = \<infinity>"
    | (MInf) "x = -\<infinity>"
  using assms by (cases x) auto

lemmas ereal2_cases = ereal_cases[case_product ereal_cases]
lemmas ereal3_cases = ereal2_cases[case_product ereal_cases]

lemma ereal_all_split: "\<And>P. (\<forall>x::ereal. P x) \<longleftrightarrow> P \<infinity> \<and> (\<forall>x. P (ereal x)) \<and> P (-\<infinity>)"
  by (metis ereal_cases)

lemma ereal_ex_split: "\<And>P. (\<exists>x::ereal. P x) \<longleftrightarrow> P \<infinity> \<or> (\<exists>x. P (ereal x)) \<or> P (-\<infinity>)"
  by (metis ereal_cases)

lemma ereal_uminus_eq_iff[simp]:
  fixes a b :: ereal
  shows "-a = -b \<longleftrightarrow> a = b"
  by (cases rule: ereal2_cases[of a b]) simp_all

instantiation ereal :: real_of
begin

function real_ereal :: "ereal \<Rightarrow> real" where
  "real_ereal (ereal r) = r"
| "real_ereal \<infinity> = 0"
| "real_ereal (-\<infinity>) = 0"
  by (auto intro: ereal_cases)
termination by standard (rule wf_empty)

instance ..
end

lemma real_of_ereal[simp]:
  "real (- x :: ereal) = - (real x)"
  by (cases x) simp_all

lemma range_ereal[simp]: "range ereal = UNIV - {\<infinity>, -\<infinity>}"
proof safe
  fix x
  assume "x \<notin> range ereal" "x \<noteq> \<infinity>"
  then show "x = -\<infinity>"
    by (cases x) auto
qed auto

lemma ereal_range_uminus[simp]: "range uminus = (UNIV::ereal set)"
proof safe
  fix x :: ereal
  show "x \<in> range uminus"
    by (intro image_eqI[of _ _ "-x"]) auto
qed auto

instantiation ereal :: abs
begin

function abs_ereal where
  "\<bar>ereal r\<bar> = ereal \<bar>r\<bar>"
| "\<bar>-\<infinity>\<bar> = (\<infinity>::ereal)"
| "\<bar>\<infinity>\<bar> = (\<infinity>::ereal)"
by (auto intro: ereal_cases)
termination proof qed (rule wf_empty)

instance ..

end

lemma abs_eq_infinity_cases[elim!]:
  fixes x :: ereal
  assumes "\<bar>x\<bar> = \<infinity>"
  obtains "x = \<infinity>" | "x = -\<infinity>"
  using assms by (cases x) auto

lemma abs_neq_infinity_cases[elim!]:
  fixes x :: ereal
  assumes "\<bar>x\<bar> \<noteq> \<infinity>"
  obtains r where "x = ereal r"
  using assms by (cases x) auto

lemma abs_ereal_uminus[simp]:
  fixes x :: ereal
  shows "\<bar>- x\<bar> = \<bar>x\<bar>"
  by (cases x) auto

lemma ereal_infinity_cases:
  fixes a :: ereal
  shows "a \<noteq> \<infinity> \<Longrightarrow> a \<noteq> -\<infinity> \<Longrightarrow> \<bar>a\<bar> \<noteq> \<infinity>"
  by auto


subsubsection "Addition"

instantiation ereal :: "{one,comm_monoid_add,zero_neq_one}"
begin

definition "0 = ereal 0"
definition "1 = ereal 1"

function plus_ereal where
  "ereal r + ereal p = ereal (r + p)"
| "\<infinity> + a = (\<infinity>::ereal)"
| "a + \<infinity> = (\<infinity>::ereal)"
| "ereal r + -\<infinity> = - \<infinity>"
| "-\<infinity> + ereal p = -(\<infinity>::ereal)"
| "-\<infinity> + -\<infinity> = -(\<infinity>::ereal)"
proof goals
  case prems: (1 P x)
  then obtain a b where "x = (a, b)"
    by (cases x) auto
  with prems show P
   by (cases rule: ereal2_cases[of a b]) auto
qed auto
termination by standard (rule wf_empty)

lemma Infty_neq_0[simp]:
  "(\<infinity>::ereal) \<noteq> 0" "0 \<noteq> (\<infinity>::ereal)"
  "-(\<infinity>::ereal) \<noteq> 0" "0 \<noteq> -(\<infinity>::ereal)"
  by (simp_all add: zero_ereal_def)

lemma ereal_eq_0[simp]:
  "ereal r = 0 \<longleftrightarrow> r = 0"
  "0 = ereal r \<longleftrightarrow> r = 0"
  unfolding zero_ereal_def by simp_all

lemma ereal_eq_1[simp]:
  "ereal r = 1 \<longleftrightarrow> r = 1"
  "1 = ereal r \<longleftrightarrow> r = 1"
  unfolding one_ereal_def by simp_all

instance
proof
  fix a b c :: ereal
  show "0 + a = a"
    by (cases a) (simp_all add: zero_ereal_def)
  show "a + b = b + a"
    by (cases rule: ereal2_cases[of a b]) simp_all
  show "a + b + c = a + (b + c)"
    by (cases rule: ereal3_cases[of a b c]) simp_all
  show "0 \<noteq> (1::ereal)"
    by (simp add: one_ereal_def zero_ereal_def)
qed

end

lemma ereal_0_plus [simp]: "ereal 0 + x = x"
  and plus_ereal_0 [simp]: "x + ereal 0 = x"
by(simp_all add: zero_ereal_def[symmetric])

instance ereal :: numeral ..

lemma real_of_ereal_0[simp]: "real (0::ereal) = 0"
  unfolding zero_ereal_def by simp

lemma abs_ereal_zero[simp]: "\<bar>0\<bar> = (0::ereal)"
  unfolding zero_ereal_def abs_ereal.simps by simp

lemma ereal_uminus_zero[simp]: "- 0 = (0::ereal)"
  by (simp add: zero_ereal_def)

lemma ereal_uminus_zero_iff[simp]:
  fixes a :: ereal
  shows "-a = 0 \<longleftrightarrow> a = 0"
  by (cases a) simp_all

lemma ereal_plus_eq_PInfty[simp]:
  fixes a b :: ereal
  shows "a + b = \<infinity> \<longleftrightarrow> a = \<infinity> \<or> b = \<infinity>"
  by (cases rule: ereal2_cases[of a b]) auto

lemma ereal_plus_eq_MInfty[simp]:
  fixes a b :: ereal
  shows "a + b = -\<infinity> \<longleftrightarrow> (a = -\<infinity> \<or> b = -\<infinity>) \<and> a \<noteq> \<infinity> \<and> b \<noteq> \<infinity>"
  by (cases rule: ereal2_cases[of a b]) auto

lemma ereal_add_cancel_left:
  fixes a b :: ereal
  assumes "a \<noteq> -\<infinity>"
  shows "a + b = a + c \<longleftrightarrow> a = \<infinity> \<or> b = c"
  using assms by (cases rule: ereal3_cases[of a b c]) auto

lemma ereal_add_cancel_right:
  fixes a b :: ereal
  assumes "a \<noteq> -\<infinity>"
  shows "b + a = c + a \<longleftrightarrow> a = \<infinity> \<or> b = c"
  using assms by (cases rule: ereal3_cases[of a b c]) auto

lemma ereal_real: "ereal (real x) = (if \<bar>x\<bar> = \<infinity> then 0 else x)"
  by (cases x) simp_all

lemma real_of_ereal_add:
  fixes a b :: ereal
  shows "real (a + b) =
    (if (\<bar>a\<bar> = \<infinity>) \<and> (\<bar>b\<bar> = \<infinity>) \<or> (\<bar>a\<bar> \<noteq> \<infinity>) \<and> (\<bar>b\<bar> \<noteq> \<infinity>) then real a + real b else 0)"
  by (cases rule: ereal2_cases[of a b]) auto


subsubsection "Linear order on @{typ ereal}"

instantiation ereal :: linorder
begin

function less_ereal
where
  "   ereal x < ereal y     \<longleftrightarrow> x < y"
| "(\<infinity>::ereal) < a           \<longleftrightarrow> False"
| "         a < -(\<infinity>::ereal) \<longleftrightarrow> False"
| "ereal x    < \<infinity>           \<longleftrightarrow> True"
| "        -\<infinity> < ereal r     \<longleftrightarrow> True"
| "        -\<infinity> < (\<infinity>::ereal) \<longleftrightarrow> True"
proof goals
  case prems: (1 P x)
  then obtain a b where "x = (a,b)" by (cases x) auto
  with prems show P by (cases rule: ereal2_cases[of a b]) auto
qed simp_all
termination by (relation "{}") simp

definition "x \<le> (y::ereal) \<longleftrightarrow> x < y \<or> x = y"

lemma ereal_infty_less[simp]:
  fixes x :: ereal
  shows "x < \<infinity> \<longleftrightarrow> (x \<noteq> \<infinity>)"
    "-\<infinity> < x \<longleftrightarrow> (x \<noteq> -\<infinity>)"
  by (cases x, simp_all) (cases x, simp_all)

lemma ereal_infty_less_eq[simp]:
  fixes x :: ereal
  shows "\<infinity> \<le> x \<longleftrightarrow> x = \<infinity>"
    and "x \<le> -\<infinity> \<longleftrightarrow> x = -\<infinity>"
  by (auto simp add: less_eq_ereal_def)

lemma ereal_less[simp]:
  "ereal r < 0 \<longleftrightarrow> (r < 0)"
  "0 < ereal r \<longleftrightarrow> (0 < r)"
  "ereal r < 1 \<longleftrightarrow> (r < 1)"
  "1 < ereal r \<longleftrightarrow> (1 < r)"
  "0 < (\<infinity>::ereal)"
  "-(\<infinity>::ereal) < 0"
  by (simp_all add: zero_ereal_def one_ereal_def)

lemma ereal_less_eq[simp]:
  "x \<le> (\<infinity>::ereal)"
  "-(\<infinity>::ereal) \<le> x"
  "ereal r \<le> ereal p \<longleftrightarrow> r \<le> p"
  "ereal r \<le> 0 \<longleftrightarrow> r \<le> 0"
  "0 \<le> ereal r \<longleftrightarrow> 0 \<le> r"
  "ereal r \<le> 1 \<longleftrightarrow> r \<le> 1"
  "1 \<le> ereal r \<longleftrightarrow> 1 \<le> r"
  by (auto simp add: less_eq_ereal_def zero_ereal_def one_ereal_def)

lemma ereal_infty_less_eq2:
  "a \<le> b \<Longrightarrow> a = \<infinity> \<Longrightarrow> b = (\<infinity>::ereal)"
  "a \<le> b \<Longrightarrow> b = -\<infinity> \<Longrightarrow> a = -(\<infinity>::ereal)"
  by simp_all

instance
proof
  fix x y z :: ereal
  show "x \<le> x"
    by (cases x) simp_all
  show "x < y \<longleftrightarrow> x \<le> y \<and> \<not> y \<le> x"
    by (cases rule: ereal2_cases[of x y]) auto
  show "x \<le> y \<or> y \<le> x "
    by (cases rule: ereal2_cases[of x y]) auto
  {
    assume "x \<le> y" "y \<le> x"
    then show "x = y"
      by (cases rule: ereal2_cases[of x y]) auto
  }
  {
    assume "x \<le> y" "y \<le> z"
    then show "x \<le> z"
      by (cases rule: ereal3_cases[of x y z]) auto
  }
qed

end

lemma ereal_dense2: "x < y \<Longrightarrow> \<exists>z. x < ereal z \<and> ereal z < y"
  using lt_ex gt_ex dense by (cases x y rule: ereal2_cases) auto

instance ereal :: dense_linorder
  by standard (blast dest: ereal_dense2)

instance ereal :: ordered_ab_semigroup_add
proof
  fix a b c :: ereal
  assume "a \<le> b"
  then show "c + a \<le> c + b"
    by (cases rule: ereal3_cases[of a b c]) auto
qed

lemma real_of_ereal_positive_mono:
  fixes x y :: ereal
  shows "0 \<le> x \<Longrightarrow> x \<le> y \<Longrightarrow> y \<noteq> \<infinity> \<Longrightarrow> real x \<le> real y"
  by (cases rule: ereal2_cases[of x y]) auto

lemma ereal_MInfty_lessI[intro, simp]:
  fixes a :: ereal
  shows "a \<noteq> -\<infinity> \<Longrightarrow> -\<infinity> < a"
  by (cases a) auto

lemma ereal_less_PInfty[intro, simp]:
  fixes a :: ereal
  shows "a \<noteq> \<infinity> \<Longrightarrow> a < \<infinity>"
  by (cases a) auto

lemma ereal_less_ereal_Ex:
  fixes a b :: ereal
  shows "x < ereal r \<longleftrightarrow> x = -\<infinity> \<or> (\<exists>p. p < r \<and> x = ereal p)"
  by (cases x) auto

lemma less_PInf_Ex_of_nat: "x \<noteq> \<infinity> \<longleftrightarrow> (\<exists>n::nat. x < ereal (real n))"
proof (cases x)
  case (real r)
  then show ?thesis
    using reals_Archimedean2[of r] by simp
qed simp_all

lemma ereal_add_mono:
  fixes a b c d :: ereal
  assumes "a \<le> b"
    and "c \<le> d"
  shows "a + c \<le> b + d"
  using assms
  apply (cases a)
  apply (cases rule: ereal3_cases[of b c d], auto)
  apply (cases rule: ereal3_cases[of b c d], auto)
  done

lemma ereal_minus_le_minus[simp]:
  fixes a b :: ereal
  shows "- a \<le> - b \<longleftrightarrow> b \<le> a"
  by (cases rule: ereal2_cases[of a b]) auto

lemma ereal_minus_less_minus[simp]:
  fixes a b :: ereal
  shows "- a < - b \<longleftrightarrow> b < a"
  by (cases rule: ereal2_cases[of a b]) auto

lemma ereal_le_real_iff:
  "x \<le> real y \<longleftrightarrow> (\<bar>y\<bar> \<noteq> \<infinity> \<longrightarrow> ereal x \<le> y) \<and> (\<bar>y\<bar> = \<infinity> \<longrightarrow> x \<le> 0)"
  by (cases y) auto

lemma real_le_ereal_iff:
  "real y \<le> x \<longleftrightarrow> (\<bar>y\<bar> \<noteq> \<infinity> \<longrightarrow> y \<le> ereal x) \<and> (\<bar>y\<bar> = \<infinity> \<longrightarrow> 0 \<le> x)"
  by (cases y) auto

lemma ereal_less_real_iff:
  "x < real y \<longleftrightarrow> (\<bar>y\<bar> \<noteq> \<infinity> \<longrightarrow> ereal x < y) \<and> (\<bar>y\<bar> = \<infinity> \<longrightarrow> x < 0)"
  by (cases y) auto

lemma real_less_ereal_iff:
  "real y < x \<longleftrightarrow> (\<bar>y\<bar> \<noteq> \<infinity> \<longrightarrow> y < ereal x) \<and> (\<bar>y\<bar> = \<infinity> \<longrightarrow> 0 < x)"
  by (cases y) auto

lemma real_of_ereal_pos:
  fixes x :: ereal
  shows "0 \<le> x \<Longrightarrow> 0 \<le> real x" by (cases x) auto

lemmas real_of_ereal_ord_simps =
  ereal_le_real_iff real_le_ereal_iff ereal_less_real_iff real_less_ereal_iff

lemma abs_ereal_ge0[simp]: "0 \<le> x \<Longrightarrow> \<bar>x :: ereal\<bar> = x"
  by (cases x) auto

lemma abs_ereal_less0[simp]: "x < 0 \<Longrightarrow> \<bar>x :: ereal\<bar> = -x"
  by (cases x) auto

lemma abs_ereal_pos[simp]: "0 \<le> \<bar>x :: ereal\<bar>"
  by (cases x) auto

lemma real_of_ereal_le_0[simp]: "real (x :: ereal) \<le> 0 \<longleftrightarrow> x \<le> 0 \<or> x = \<infinity>"
  by (cases x) auto

lemma abs_real_of_ereal[simp]: "\<bar>real (x :: ereal)\<bar> = real \<bar>x\<bar>"
  by (cases x) auto

lemma zero_less_real_of_ereal:
  fixes x :: ereal
  shows "0 < real x \<longleftrightarrow> 0 < x \<and> x \<noteq> \<infinity>"
  by (cases x) auto

lemma ereal_0_le_uminus_iff[simp]:
  fixes a :: ereal
  shows "0 \<le> - a \<longleftrightarrow> a \<le> 0"
  by (cases rule: ereal2_cases[of a]) auto

lemma ereal_uminus_le_0_iff[simp]:
  fixes a :: ereal
  shows "- a \<le> 0 \<longleftrightarrow> 0 \<le> a"
  by (cases rule: ereal2_cases[of a]) auto

lemma ereal_add_strict_mono:
  fixes a b c d :: ereal
  assumes "a \<le> b"
    and "0 \<le> a"
    and "a \<noteq> \<infinity>"
    and "c < d"
  shows "a + c < b + d"
  using assms
  by (cases rule: ereal3_cases[case_product ereal_cases, of a b c d]) auto

lemma ereal_less_add:
  fixes a b c :: ereal
  shows "\<bar>a\<bar> \<noteq> \<infinity> \<Longrightarrow> c < b \<Longrightarrow> a + c < a + b"
  by (cases rule: ereal2_cases[of b c]) auto

lemma ereal_add_nonneg_eq_0_iff:
  fixes a b :: ereal
  shows "0 \<le> a \<Longrightarrow> 0 \<le> b \<Longrightarrow> a + b = 0 \<longleftrightarrow> a = 0 \<and> b = 0"
  by (cases a b rule: ereal2_cases) auto

lemma ereal_uminus_eq_reorder: "- a = b \<longleftrightarrow> a = (-b::ereal)"
  by auto

lemma ereal_uminus_less_reorder: "- a < b \<longleftrightarrow> -b < (a::ereal)"
  by (subst (3) ereal_uminus_uminus[symmetric]) (simp only: ereal_minus_less_minus)

lemma ereal_less_uminus_reorder: "a < - b \<longleftrightarrow> b < - (a::ereal)"
  by (subst (3) ereal_uminus_uminus[symmetric]) (simp only: ereal_minus_less_minus)

lemma ereal_uminus_le_reorder: "- a \<le> b \<longleftrightarrow> -b \<le> (a::ereal)"
  by (subst (3) ereal_uminus_uminus[symmetric]) (simp only: ereal_minus_le_minus)

lemmas ereal_uminus_reorder =
  ereal_uminus_eq_reorder ereal_uminus_less_reorder ereal_uminus_le_reorder

lemma ereal_bot:
  fixes x :: ereal
  assumes "\<And>B. x \<le> ereal B"
  shows "x = - \<infinity>"
proof (cases x)
  case (real r)
  with assms[of "r - 1"] show ?thesis
    by auto
next
  case PInf
  with assms[of 0] show ?thesis
    by auto
next
  case MInf
  then show ?thesis
    by simp
qed

lemma ereal_top:
  fixes x :: ereal
  assumes "\<And>B. x \<ge> ereal B"
  shows "x = \<infinity>"
proof (cases x)
  case (real r)
  with assms[of "r + 1"] show ?thesis
    by auto
next
  case MInf
  with assms[of 0] show ?thesis
    by auto
next
  case PInf
  then show ?thesis
    by simp
qed

lemma
  shows ereal_max[simp]: "ereal (max x y) = max (ereal x) (ereal y)"
    and ereal_min[simp]: "ereal (min x y) = min (ereal x) (ereal y)"
  by (simp_all add: min_def max_def)

lemma ereal_max_0: "max 0 (ereal r) = ereal (max 0 r)"
  by (auto simp: zero_ereal_def)

lemma
  fixes f :: "nat \<Rightarrow> ereal"
  shows ereal_incseq_uminus[simp]: "incseq (\<lambda>x. - f x) \<longleftrightarrow> decseq f"
    and ereal_decseq_uminus[simp]: "decseq (\<lambda>x. - f x) \<longleftrightarrow> incseq f"
  unfolding decseq_def incseq_def by auto

lemma incseq_ereal: "incseq f \<Longrightarrow> incseq (\<lambda>x. ereal (f x))"
  unfolding incseq_def by auto

lemma ereal_add_nonneg_nonneg[simp]:
  fixes a b :: ereal
  shows "0 \<le> a \<Longrightarrow> 0 \<le> b \<Longrightarrow> 0 \<le> a + b"
  using add_mono[of 0 a 0 b] by simp

lemma image_eqD: "f ` A = B \<Longrightarrow> \<forall>x\<in>A. f x \<in> B"
  by auto

lemma incseq_setsumI:
  fixes f :: "nat \<Rightarrow> 'a::{comm_monoid_add,ordered_ab_semigroup_add}"
  assumes "\<And>i. 0 \<le> f i"
  shows "incseq (\<lambda>i. setsum f {..< i})"
proof (intro incseq_SucI)
  fix n
  have "setsum f {..< n} + 0 \<le> setsum f {..<n} + f n"
    using assms by (rule add_left_mono)
  then show "setsum f {..< n} \<le> setsum f {..< Suc n}"
    by auto
qed

lemma incseq_setsumI2:
  fixes f :: "'i \<Rightarrow> nat \<Rightarrow> 'a::{comm_monoid_add,ordered_ab_semigroup_add}"
  assumes "\<And>n. n \<in> A \<Longrightarrow> incseq (f n)"
  shows "incseq (\<lambda>i. \<Sum>n\<in>A. f n i)"
  using assms
  unfolding incseq_def by (auto intro: setsum_mono)

lemma setsum_ereal[simp]: "(\<Sum>x\<in>A. ereal (f x)) = ereal (\<Sum>x\<in>A. f x)"
proof (cases "finite A")
  case True
  then show ?thesis by induct auto
next
  case False
  then show ?thesis by simp
qed

lemma setsum_Pinfty:
  fixes f :: "'a \<Rightarrow> ereal"
  shows "(\<Sum>x\<in>P. f x) = \<infinity> \<longleftrightarrow> finite P \<and> (\<exists>i\<in>P. f i = \<infinity>)"
proof safe
  assume *: "setsum f P = \<infinity>"
  show "finite P"
  proof (rule ccontr)
    assume "\<not> finite P"
    with * show False
      by auto
  qed
  show "\<exists>i\<in>P. f i = \<infinity>"
  proof (rule ccontr)
    assume "\<not> ?thesis"
    then have "\<And>i. i \<in> P \<Longrightarrow> f i \<noteq> \<infinity>"
      by auto
    with \<open>finite P\<close> have "setsum f P \<noteq> \<infinity>"
      by induct auto
    with * show False
      by auto
  qed
next
  fix i
  assume "finite P" and "i \<in> P" and "f i = \<infinity>"
  then show "setsum f P = \<infinity>"
  proof induct
    case (insert x A)
    show ?case using insert by (cases "x = i") auto
  qed simp
qed

lemma setsum_Inf:
  fixes f :: "'a \<Rightarrow> ereal"
  shows "\<bar>setsum f A\<bar> = \<infinity> \<longleftrightarrow> finite A \<and> (\<exists>i\<in>A. \<bar>f i\<bar> = \<infinity>)"
proof
  assume *: "\<bar>setsum f A\<bar> = \<infinity>"
  have "finite A"
    by (rule ccontr) (insert *, auto)
  moreover have "\<exists>i\<in>A. \<bar>f i\<bar> = \<infinity>"
  proof (rule ccontr)
    assume "\<not> ?thesis"
    then have "\<forall>i\<in>A. \<exists>r. f i = ereal r"
      by auto
    from bchoice[OF this] obtain r where "\<forall>x\<in>A. f x = ereal (r x)" ..
    with * show False
      by auto
  qed
  ultimately show "finite A \<and> (\<exists>i\<in>A. \<bar>f i\<bar> = \<infinity>)"
    by auto
next
  assume "finite A \<and> (\<exists>i\<in>A. \<bar>f i\<bar> = \<infinity>)"
  then obtain i where "finite A" "i \<in> A" and "\<bar>f i\<bar> = \<infinity>"
    by auto
  then show "\<bar>setsum f A\<bar> = \<infinity>"
  proof induct
    case (insert j A)
    then show ?case
      by (cases rule: ereal3_cases[of "f i" "f j" "setsum f A"]) auto
  qed simp
qed

lemma setsum_real_of_ereal:
  fixes f :: "'i \<Rightarrow> ereal"
  assumes "\<And>x. x \<in> S \<Longrightarrow> \<bar>f x\<bar> \<noteq> \<infinity>"
  shows "(\<Sum>x\<in>S. real (f x)) = real (setsum f S)"
proof -
  have "\<forall>x\<in>S. \<exists>r. f x = ereal r"
  proof
    fix x
    assume "x \<in> S"
    from assms[OF this] show "\<exists>r. f x = ereal r"
      by (cases "f x") auto
  qed
  from bchoice[OF this] obtain r where "\<forall>x\<in>S. f x = ereal (r x)" ..
  then show ?thesis
    by simp
qed

lemma setsum_ereal_0:
  fixes f :: "'a \<Rightarrow> ereal"
  assumes "finite A"
    and "\<And>i. i \<in> A \<Longrightarrow> 0 \<le> f i"
  shows "(\<Sum>x\<in>A. f x) = 0 \<longleftrightarrow> (\<forall>i\<in>A. f i = 0)"
proof
  assume "setsum f A = 0" with assms show "\<forall>i\<in>A. f i = 0"
  proof (induction A)
    case (insert a A)
    then have "f a = 0 \<and> (\<Sum>a\<in>A. f a) = 0"
      by (subst ereal_add_nonneg_eq_0_iff[symmetric]) (simp_all add: setsum_nonneg)
    with insert show ?case
      by simp
  qed simp
qed auto

subsubsection "Multiplication"

instantiation ereal :: "{comm_monoid_mult,sgn}"
begin

function sgn_ereal :: "ereal \<Rightarrow> ereal" where
  "sgn (ereal r) = ereal (sgn r)"
| "sgn (\<infinity>::ereal) = 1"
| "sgn (-\<infinity>::ereal) = -1"
by (auto intro: ereal_cases)
termination by standard (rule wf_empty)

function times_ereal where
  "ereal r * ereal p = ereal (r * p)"
| "ereal r * \<infinity> = (if r = 0 then 0 else if r > 0 then \<infinity> else -\<infinity>)"
| "\<infinity> * ereal r = (if r = 0 then 0 else if r > 0 then \<infinity> else -\<infinity>)"
| "ereal r * -\<infinity> = (if r = 0 then 0 else if r > 0 then -\<infinity> else \<infinity>)"
| "-\<infinity> * ereal r = (if r = 0 then 0 else if r > 0 then -\<infinity> else \<infinity>)"
| "(\<infinity>::ereal) * \<infinity> = \<infinity>"
| "-(\<infinity>::ereal) * \<infinity> = -\<infinity>"
| "(\<infinity>::ereal) * -\<infinity> = -\<infinity>"
| "-(\<infinity>::ereal) * -\<infinity> = \<infinity>"
proof goals
  case prems: (1 P x)
  then obtain a b where "x = (a, b)"
    by (cases x) auto
  with prems show P
    by (cases rule: ereal2_cases[of a b]) auto
qed simp_all
termination by (relation "{}") simp

instance
proof
  fix a b c :: ereal
  show "1 * a = a"
    by (cases a) (simp_all add: one_ereal_def)
  show "a * b = b * a"
    by (cases rule: ereal2_cases[of a b]) simp_all
  show "a * b * c = a * (b * c)"
    by (cases rule: ereal3_cases[of a b c])
       (simp_all add: zero_ereal_def zero_less_mult_iff)
qed

end

lemma one_not_le_zero_ereal[simp]: "\<not> (1 \<le> (0::ereal))"
  by (simp add: one_ereal_def zero_ereal_def)

lemma real_ereal_1[simp]: "real (1::ereal) = 1"
  unfolding one_ereal_def by simp

lemma real_of_ereal_le_1:
  fixes a :: ereal
  shows "a \<le> 1 \<Longrightarrow> real a \<le> 1"
  by (cases a) (auto simp: one_ereal_def)

lemma abs_ereal_one[simp]: "\<bar>1\<bar> = (1::ereal)"
  unfolding one_ereal_def by simp

lemma ereal_mult_zero[simp]:
  fixes a :: ereal
  shows "a * 0 = 0"
  by (cases a) (simp_all add: zero_ereal_def)

lemma ereal_zero_mult[simp]:
  fixes a :: ereal
  shows "0 * a = 0"
  by (cases a) (simp_all add: zero_ereal_def)

lemma ereal_m1_less_0[simp]: "-(1::ereal) < 0"
  by (simp add: zero_ereal_def one_ereal_def)

lemma ereal_times[simp]:
  "1 \<noteq> (\<infinity>::ereal)" "(\<infinity>::ereal) \<noteq> 1"
  "1 \<noteq> -(\<infinity>::ereal)" "-(\<infinity>::ereal) \<noteq> 1"
  by (auto simp add: times_ereal_def one_ereal_def)

lemma ereal_plus_1[simp]:
  "1 + ereal r = ereal (r + 1)"
  "ereal r + 1 = ereal (r + 1)"
  "1 + -(\<infinity>::ereal) = -\<infinity>"
  "-(\<infinity>::ereal) + 1 = -\<infinity>"
  unfolding one_ereal_def by auto

lemma ereal_zero_times[simp]:
  fixes a b :: ereal
  shows "a * b = 0 \<longleftrightarrow> a = 0 \<or> b = 0"
  by (cases rule: ereal2_cases[of a b]) auto

lemma ereal_mult_eq_PInfty[simp]:
  "a * b = (\<infinity>::ereal) \<longleftrightarrow>
    (a = \<infinity> \<and> b > 0) \<or> (a > 0 \<and> b = \<infinity>) \<or> (a = -\<infinity> \<and> b < 0) \<or> (a < 0 \<and> b = -\<infinity>)"
  by (cases rule: ereal2_cases[of a b]) auto

lemma ereal_mult_eq_MInfty[simp]:
  "a * b = -(\<infinity>::ereal) \<longleftrightarrow>
    (a = \<infinity> \<and> b < 0) \<or> (a < 0 \<and> b = \<infinity>) \<or> (a = -\<infinity> \<and> b > 0) \<or> (a > 0 \<and> b = -\<infinity>)"
  by (cases rule: ereal2_cases[of a b]) auto

lemma ereal_abs_mult: "\<bar>x * y :: ereal\<bar> = \<bar>x\<bar> * \<bar>y\<bar>"
  by (cases x y rule: ereal2_cases) (auto simp: abs_mult)

lemma ereal_0_less_1[simp]: "0 < (1::ereal)"
  by (simp_all add: zero_ereal_def one_ereal_def)

lemma ereal_mult_minus_left[simp]:
  fixes a b :: ereal
  shows "-a * b = - (a * b)"
  by (cases rule: ereal2_cases[of a b]) auto

lemma ereal_mult_minus_right[simp]:
  fixes a b :: ereal
  shows "a * -b = - (a * b)"
  by (cases rule: ereal2_cases[of a b]) auto

lemma ereal_mult_infty[simp]:
  "a * (\<infinity>::ereal) = (if a = 0 then 0 else if 0 < a then \<infinity> else - \<infinity>)"
  by (cases a) auto

lemma ereal_infty_mult[simp]:
  "(\<infinity>::ereal) * a = (if a = 0 then 0 else if 0 < a then \<infinity> else - \<infinity>)"
  by (cases a) auto

lemma ereal_mult_strict_right_mono:
  assumes "a < b"
    and "0 < c"
    and "c < (\<infinity>::ereal)"
  shows "a * c < b * c"
  using assms
  by (cases rule: ereal3_cases[of a b c]) (auto simp: zero_le_mult_iff)

lemma ereal_mult_strict_left_mono:
  "a < b \<Longrightarrow> 0 < c \<Longrightarrow> c < (\<infinity>::ereal) \<Longrightarrow> c * a < c * b"
  using ereal_mult_strict_right_mono
  by (simp add: mult.commute[of c])

lemma ereal_mult_right_mono:
  fixes a b c :: ereal
  shows "a \<le> b \<Longrightarrow> 0 \<le> c \<Longrightarrow> a * c \<le> b * c"
  using assms
  apply (cases "c = 0")
  apply simp
  apply (cases rule: ereal3_cases[of a b c])
  apply (auto simp: zero_le_mult_iff)
  done

lemma ereal_mult_left_mono:
  fixes a b c :: ereal
  shows "a \<le> b \<Longrightarrow> 0 \<le> c \<Longrightarrow> c * a \<le> c * b"
  using ereal_mult_right_mono
  by (simp add: mult.commute[of c])

lemma zero_less_one_ereal[simp]: "0 \<le> (1::ereal)"
  by (simp add: one_ereal_def zero_ereal_def)

lemma ereal_0_le_mult[simp]: "0 \<le> a \<Longrightarrow> 0 \<le> b \<Longrightarrow> 0 \<le> a * (b :: ereal)"
  by (cases rule: ereal2_cases[of a b]) auto

lemma ereal_right_distrib:
  fixes r a b :: ereal
  shows "0 \<le> a \<Longrightarrow> 0 \<le> b \<Longrightarrow> r * (a + b) = r * a + r * b"
  by (cases rule: ereal3_cases[of r a b]) (simp_all add: field_simps)

lemma ereal_left_distrib:
  fixes r a b :: ereal
  shows "0 \<le> a \<Longrightarrow> 0 \<le> b \<Longrightarrow> (a + b) * r = a * r + b * r"
  by (cases rule: ereal3_cases[of r a b]) (simp_all add: field_simps)

lemma ereal_mult_le_0_iff:
  fixes a b :: ereal
  shows "a * b \<le> 0 \<longleftrightarrow> (0 \<le> a \<and> b \<le> 0) \<or> (a \<le> 0 \<and> 0 \<le> b)"
  by (cases rule: ereal2_cases[of a b]) (simp_all add: mult_le_0_iff)

lemma ereal_zero_le_0_iff:
  fixes a b :: ereal
  shows "0 \<le> a * b \<longleftrightarrow> (0 \<le> a \<and> 0 \<le> b) \<or> (a \<le> 0 \<and> b \<le> 0)"
  by (cases rule: ereal2_cases[of a b]) (simp_all add: zero_le_mult_iff)

lemma ereal_mult_less_0_iff:
  fixes a b :: ereal
  shows "a * b < 0 \<longleftrightarrow> (0 < a \<and> b < 0) \<or> (a < 0 \<and> 0 < b)"
  by (cases rule: ereal2_cases[of a b]) (simp_all add: mult_less_0_iff)

lemma ereal_zero_less_0_iff:
  fixes a b :: ereal
  shows "0 < a * b \<longleftrightarrow> (0 < a \<and> 0 < b) \<or> (a < 0 \<and> b < 0)"
  by (cases rule: ereal2_cases[of a b]) (simp_all add: zero_less_mult_iff)

lemma ereal_left_mult_cong:
  fixes a b c :: ereal
  shows  "c = d \<Longrightarrow> (d \<noteq> 0 \<Longrightarrow> a = b) \<Longrightarrow> a * c = b * d"
  by (cases "c = 0") simp_all

lemma ereal_right_mult_cong: 
  fixes a b c :: ereal
  shows "c = d \<Longrightarrow> (d \<noteq> 0 \<Longrightarrow> a = b) \<Longrightarrow> c * a = d * b"
  by (cases "c = 0") simp_all

lemma ereal_distrib:
  fixes a b c :: ereal
  assumes "a \<noteq> \<infinity> \<or> b \<noteq> -\<infinity>"
    and "a \<noteq> -\<infinity> \<or> b \<noteq> \<infinity>"
    and "\<bar>c\<bar> \<noteq> \<infinity>"
  shows "(a + b) * c = a * c + b * c"
  using assms
  by (cases rule: ereal3_cases[of a b c]) (simp_all add: field_simps)

lemma numeral_eq_ereal [simp]: "numeral w = ereal (numeral w)"
  apply (induct w rule: num_induct)
  apply (simp only: numeral_One one_ereal_def)
  apply (simp only: numeral_inc ereal_plus_1)
  done

lemma setsum_ereal_right_distrib:
  fixes f :: "'a \<Rightarrow> ereal"
  shows "(\<And>i. i \<in> A \<Longrightarrow> 0 \<le> f i) \<Longrightarrow> r * setsum f A = (\<Sum>n\<in>A. r * f n)"
  by (induct A rule: infinite_finite_induct)  (auto simp: ereal_right_distrib setsum_nonneg)

lemma setsum_ereal_left_distrib:
  "(\<And>i. i \<in> A \<Longrightarrow> 0 \<le> f i) \<Longrightarrow> setsum f A * r = (\<Sum>n\<in>A. f n * r :: ereal)"
  using setsum_ereal_right_distrib[of A f r] by (simp add: mult_ac)

lemma ereal_le_epsilon:
  fixes x y :: ereal
  assumes "\<forall>e. 0 < e \<longrightarrow> x \<le> y + e"
  shows "x \<le> y"
proof -
  {
    assume a: "\<exists>r. y = ereal r"
    then obtain r where r_def: "y = ereal r"
      by auto
    {
      assume "x = -\<infinity>"
      then have ?thesis by auto
    }
    moreover
    {
      assume "x \<noteq> -\<infinity>"
      then obtain p where p_def: "x = ereal p"
      using a assms[rule_format, of 1]
        by (cases x) auto
      {
        fix e
        have "0 < e \<longrightarrow> p \<le> r + e"
          using assms[rule_format, of "ereal e"] p_def r_def by auto
      }
      then have "p \<le> r"
        apply (subst field_le_epsilon)
        apply auto
        done
      then have ?thesis
        using r_def p_def by auto
    }
    ultimately have ?thesis
      by blast
  }
  moreover
  {
    assume "y = -\<infinity> | y = \<infinity>"
    then have ?thesis
      using assms[rule_format, of 1] by (cases x) auto
  }
  ultimately show ?thesis
    by (cases y) auto
qed

lemma ereal_le_epsilon2:
  fixes x y :: ereal
  assumes "\<forall>e. 0 < e \<longrightarrow> x \<le> y + ereal e"
  shows "x \<le> y"
proof -
  {
    fix e :: ereal
    assume "e > 0"
    {
      assume "e = \<infinity>"
      then have "x \<le> y + e"
        by auto
    }
    moreover
    {
      assume "e \<noteq> \<infinity>"
      then obtain r where "e = ereal r"
        using \<open>e > 0\<close> by (cases e) auto
      then have "x \<le> y + e"
        using assms[rule_format, of r] \<open>e>0\<close> by auto
    }
    ultimately have "x \<le> y + e"
      by blast
  }
  then show ?thesis
    using ereal_le_epsilon by auto
qed

lemma ereal_le_real:
  fixes x y :: ereal
  assumes "\<forall>z. x \<le> ereal z \<longrightarrow> y \<le> ereal z"
  shows "y \<le> x"
  by (metis assms ereal_bot ereal_cases ereal_infty_less_eq(2) ereal_less_eq(1) linorder_le_cases)

lemma setprod_ereal_0:
  fixes f :: "'a \<Rightarrow> ereal"
  shows "(\<Prod>i\<in>A. f i) = 0 \<longleftrightarrow> finite A \<and> (\<exists>i\<in>A. f i = 0)"
proof (cases "finite A")
  case True
  then show ?thesis by (induct A) auto
next
  case False
  then show ?thesis by auto
qed

lemma setprod_ereal_pos:
  fixes f :: "'a \<Rightarrow> ereal"
  assumes pos: "\<And>i. i \<in> I \<Longrightarrow> 0 \<le> f i"
  shows "0 \<le> (\<Prod>i\<in>I. f i)"
proof (cases "finite I")
  case True
  from this pos show ?thesis
    by induct auto
next
  case False
  then show ?thesis by simp
qed

lemma setprod_PInf:
  fixes f :: "'a \<Rightarrow> ereal"
  assumes "\<And>i. i \<in> I \<Longrightarrow> 0 \<le> f i"
  shows "(\<Prod>i\<in>I. f i) = \<infinity> \<longleftrightarrow> finite I \<and> (\<exists>i\<in>I. f i = \<infinity>) \<and> (\<forall>i\<in>I. f i \<noteq> 0)"
proof (cases "finite I")
  case True
  from this assms show ?thesis
  proof (induct I)
    case (insert i I)
    then have pos: "0 \<le> f i" "0 \<le> setprod f I"
      by (auto intro!: setprod_ereal_pos)
    from insert have "(\<Prod>j\<in>insert i I. f j) = \<infinity> \<longleftrightarrow> setprod f I * f i = \<infinity>"
      by auto
    also have "\<dots> \<longleftrightarrow> (setprod f I = \<infinity> \<or> f i = \<infinity>) \<and> f i \<noteq> 0 \<and> setprod f I \<noteq> 0"
      using setprod_ereal_pos[of I f] pos
      by (cases rule: ereal2_cases[of "f i" "setprod f I"]) auto
    also have "\<dots> \<longleftrightarrow> finite (insert i I) \<and> (\<exists>j\<in>insert i I. f j = \<infinity>) \<and> (\<forall>j\<in>insert i I. f j \<noteq> 0)"
      using insert by (auto simp: setprod_ereal_0)
    finally show ?case .
  qed simp
next
  case False
  then show ?thesis by simp
qed

lemma setprod_ereal: "(\<Prod>i\<in>A. ereal (f i)) = ereal (setprod f A)"
proof (cases "finite A")
  case True
  then show ?thesis
    by induct (auto simp: one_ereal_def)
next
  case False
  then show ?thesis
    by (simp add: one_ereal_def)
qed


subsubsection \<open>Power\<close>

lemma ereal_power[simp]: "(ereal x) ^ n = ereal (x^n)"
  by (induct n) (auto simp: one_ereal_def)

lemma ereal_power_PInf[simp]: "(\<infinity>::ereal) ^ n = (if n = 0 then 1 else \<infinity>)"
  by (induct n) (auto simp: one_ereal_def)

lemma ereal_power_uminus[simp]:
  fixes x :: ereal
  shows "(- x) ^ n = (if even n then x ^ n else - (x^n))"
  by (induct n) (auto simp: one_ereal_def)

lemma ereal_power_numeral[simp]:
  "(numeral num :: ereal) ^ n = ereal (numeral num ^ n)"
  by (induct n) (auto simp: one_ereal_def)

lemma zero_le_power_ereal[simp]:
  fixes a :: ereal
  assumes "0 \<le> a"
  shows "0 \<le> a ^ n"
  using assms by (induct n) (auto simp: ereal_zero_le_0_iff)


subsubsection \<open>Subtraction\<close>

lemma ereal_minus_minus_image[simp]:
  fixes S :: "ereal set"
  shows "uminus ` uminus ` S = S"
  by (auto simp: image_iff)

lemma ereal_uminus_lessThan[simp]:
  fixes a :: ereal
  shows "uminus ` {..<a} = {-a<..}"
proof -
  {
    fix x
    assume "-a < x"
    then have "- x < - (- a)"
      by (simp del: ereal_uminus_uminus)
    then have "- x < a"
      by simp
  }
  then show ?thesis
    by force
qed

lemma ereal_uminus_greaterThan[simp]: "uminus ` {(a::ereal)<..} = {..<-a}"
  by (metis ereal_uminus_lessThan ereal_uminus_uminus ereal_minus_minus_image)

instantiation ereal :: minus
begin

definition "x - y = x + -(y::ereal)"
instance ..

end

lemma ereal_minus[simp]:
  "ereal r - ereal p = ereal (r - p)"
  "-\<infinity> - ereal r = -\<infinity>"
  "ereal r - \<infinity> = -\<infinity>"
  "(\<infinity>::ereal) - x = \<infinity>"
  "-(\<infinity>::ereal) - \<infinity> = -\<infinity>"
  "x - -y = x + y"
  "x - 0 = x"
  "0 - x = -x"
  by (simp_all add: minus_ereal_def)

lemma ereal_x_minus_x[simp]: "x - x = (if \<bar>x\<bar> = \<infinity> then \<infinity> else 0::ereal)"
  by (cases x) simp_all

lemma ereal_eq_minus_iff:
  fixes x y z :: ereal
  shows "x = z - y \<longleftrightarrow>
    (\<bar>y\<bar> \<noteq> \<infinity> \<longrightarrow> x + y = z) \<and>
    (y = -\<infinity> \<longrightarrow> x = \<infinity>) \<and>
    (y = \<infinity> \<longrightarrow> z = \<infinity> \<longrightarrow> x = \<infinity>) \<and>
    (y = \<infinity> \<longrightarrow> z \<noteq> \<infinity> \<longrightarrow> x = -\<infinity>)"
  by (cases rule: ereal3_cases[of x y z]) auto

lemma ereal_eq_minus:
  fixes x y z :: ereal
  shows "\<bar>y\<bar> \<noteq> \<infinity> \<Longrightarrow> x = z - y \<longleftrightarrow> x + y = z"
  by (auto simp: ereal_eq_minus_iff)

lemma ereal_less_minus_iff:
  fixes x y z :: ereal
  shows "x < z - y \<longleftrightarrow>
    (y = \<infinity> \<longrightarrow> z = \<infinity> \<and> x \<noteq> \<infinity>) \<and>
    (y = -\<infinity> \<longrightarrow> x \<noteq> \<infinity>) \<and>
    (\<bar>y\<bar> \<noteq> \<infinity>\<longrightarrow> x + y < z)"
  by (cases rule: ereal3_cases[of x y z]) auto

lemma ereal_less_minus:
  fixes x y z :: ereal
  shows "\<bar>y\<bar> \<noteq> \<infinity> \<Longrightarrow> x < z - y \<longleftrightarrow> x + y < z"
  by (auto simp: ereal_less_minus_iff)

lemma ereal_le_minus_iff:
  fixes x y z :: ereal
  shows "x \<le> z - y \<longleftrightarrow> (y = \<infinity> \<longrightarrow> z \<noteq> \<infinity> \<longrightarrow> x = -\<infinity>) \<and> (\<bar>y\<bar> \<noteq> \<infinity> \<longrightarrow> x + y \<le> z)"
  by (cases rule: ereal3_cases[of x y z]) auto

lemma ereal_le_minus:
  fixes x y z :: ereal
  shows "\<bar>y\<bar> \<noteq> \<infinity> \<Longrightarrow> x \<le> z - y \<longleftrightarrow> x + y \<le> z"
  by (auto simp: ereal_le_minus_iff)

lemma ereal_minus_less_iff:
  fixes x y z :: ereal
  shows "x - y < z \<longleftrightarrow> y \<noteq> -\<infinity> \<and> (y = \<infinity> \<longrightarrow> x \<noteq> \<infinity> \<and> z \<noteq> -\<infinity>) \<and> (y \<noteq> \<infinity> \<longrightarrow> x < z + y)"
  by (cases rule: ereal3_cases[of x y z]) auto

lemma ereal_minus_less:
  fixes x y z :: ereal
  shows "\<bar>y\<bar> \<noteq> \<infinity> \<Longrightarrow> x - y < z \<longleftrightarrow> x < z + y"
  by (auto simp: ereal_minus_less_iff)

lemma ereal_minus_le_iff:
  fixes x y z :: ereal
  shows "x - y \<le> z \<longleftrightarrow>
    (y = -\<infinity> \<longrightarrow> z = \<infinity>) \<and>
    (y = \<infinity> \<longrightarrow> x = \<infinity> \<longrightarrow> z = \<infinity>) \<and>
    (\<bar>y\<bar> \<noteq> \<infinity> \<longrightarrow> x \<le> z + y)"
  by (cases rule: ereal3_cases[of x y z]) auto

lemma ereal_minus_le:
  fixes x y z :: ereal
  shows "\<bar>y\<bar> \<noteq> \<infinity> \<Longrightarrow> x - y \<le> z \<longleftrightarrow> x \<le> z + y"
  by (auto simp: ereal_minus_le_iff)

lemma ereal_minus_eq_minus_iff:
  fixes a b c :: ereal
  shows "a - b = a - c \<longleftrightarrow>
    b = c \<or> a = \<infinity> \<or> (a = -\<infinity> \<and> b \<noteq> -\<infinity> \<and> c \<noteq> -\<infinity>)"
  by (cases rule: ereal3_cases[of a b c]) auto

lemma ereal_add_le_add_iff:
  fixes a b c :: ereal
  shows "c + a \<le> c + b \<longleftrightarrow>
    a \<le> b \<or> c = \<infinity> \<or> (c = -\<infinity> \<and> a \<noteq> \<infinity> \<and> b \<noteq> \<infinity>)"
  by (cases rule: ereal3_cases[of a b c]) (simp_all add: field_simps)

lemma ereal_add_le_add_iff2:
  fixes a b c :: ereal
  shows "a + c \<le> b + c \<longleftrightarrow> a \<le> b \<or> c = \<infinity> \<or> (c = -\<infinity> \<and> a \<noteq> \<infinity> \<and> b \<noteq> \<infinity>)"
by(cases rule: ereal3_cases[of a b c])(simp_all add: field_simps)

lemma ereal_mult_le_mult_iff:
  fixes a b c :: ereal
  shows "\<bar>c\<bar> \<noteq> \<infinity> \<Longrightarrow> c * a \<le> c * b \<longleftrightarrow> (0 < c \<longrightarrow> a \<le> b) \<and> (c < 0 \<longrightarrow> b \<le> a)"
  by (cases rule: ereal3_cases[of a b c]) (simp_all add: mult_le_cancel_left)

lemma ereal_minus_mono:
  fixes A B C D :: ereal assumes "A \<le> B" "D \<le> C"
  shows "A - C \<le> B - D"
  using assms
  by (cases rule: ereal3_cases[case_product ereal_cases, of A B C D]) simp_all

lemma real_of_ereal_minus:
  fixes a b :: ereal
  shows "real (a - b) = (if \<bar>a\<bar> = \<infinity> \<or> \<bar>b\<bar> = \<infinity> then 0 else real a - real b)"
  by (cases rule: ereal2_cases[of a b]) auto

lemma real_of_ereal_minus': "\<bar>x\<bar> = \<infinity> \<longleftrightarrow> \<bar>y\<bar> = \<infinity> \<Longrightarrow> real x - real y = real (x - y :: ereal)"
by(subst real_of_ereal_minus) auto

lemma ereal_diff_positive:
  fixes a b :: ereal shows "a \<le> b \<Longrightarrow> 0 \<le> b - a"
  by (cases rule: ereal2_cases[of a b]) auto

lemma ereal_between:
  fixes x e :: ereal
  assumes "\<bar>x\<bar> \<noteq> \<infinity>"
    and "0 < e"
  shows "x - e < x"
    and "x < x + e"
  using assms
  apply (cases x, cases e)
  apply auto
  using assms
  apply (cases x, cases e)
  apply auto
  done

lemma ereal_minus_eq_PInfty_iff:
  fixes x y :: ereal
  shows "x - y = \<infinity> \<longleftrightarrow> y = -\<infinity> \<or> x = \<infinity>"
  by (cases x y rule: ereal2_cases) simp_all


subsubsection \<open>Division\<close>

instantiation ereal :: inverse
begin

function inverse_ereal where
  "inverse (ereal r) = (if r = 0 then \<infinity> else ereal (inverse r))"
| "inverse (\<infinity>::ereal) = 0"
| "inverse (-\<infinity>::ereal) = 0"
  by (auto intro: ereal_cases)
termination by (relation "{}") simp

definition "x div y = x * inverse (y :: ereal)"

instance ..

end

lemma real_of_ereal_inverse[simp]:
  fixes a :: ereal
  shows "real (inverse a) = 1 / real a"
  by (cases a) (auto simp: inverse_eq_divide)

lemma ereal_inverse[simp]:
  "inverse (0::ereal) = \<infinity>"
  "inverse (1::ereal) = 1"
  by (simp_all add: one_ereal_def zero_ereal_def)

lemma ereal_divide[simp]:
  "ereal r / ereal p = (if p = 0 then ereal r * \<infinity> else ereal (r / p))"
  unfolding divide_ereal_def by (auto simp: divide_real_def)

lemma ereal_divide_same[simp]:
  fixes x :: ereal
  shows "x / x = (if \<bar>x\<bar> = \<infinity> \<or> x = 0 then 0 else 1)"
  by (cases x) (simp_all add: divide_real_def divide_ereal_def one_ereal_def)

lemma ereal_inv_inv[simp]:
  fixes x :: ereal
  shows "inverse (inverse x) = (if x \<noteq> -\<infinity> then x else \<infinity>)"
  by (cases x) auto

lemma ereal_inverse_minus[simp]:
  fixes x :: ereal
  shows "inverse (- x) = (if x = 0 then \<infinity> else -inverse x)"
  by (cases x) simp_all

lemma ereal_uminus_divide[simp]:
  fixes x y :: ereal
  shows "- x / y = - (x / y)"
  unfolding divide_ereal_def by simp

lemma ereal_divide_Infty[simp]:
  fixes x :: ereal
  shows "x / \<infinity> = 0" "x / -\<infinity> = 0"
  unfolding divide_ereal_def by simp_all

lemma ereal_divide_one[simp]: "x / 1 = (x::ereal)"
  unfolding divide_ereal_def by simp

lemma ereal_divide_ereal[simp]: "\<infinity> / ereal r = (if 0 \<le> r then \<infinity> else -\<infinity>)"
  unfolding divide_ereal_def by simp

lemma ereal_inverse_nonneg_iff: "0 \<le> inverse (x :: ereal) \<longleftrightarrow> 0 \<le> x \<or> x = -\<infinity>"
  by (cases x) auto

lemma zero_le_divide_ereal[simp]:
  fixes a :: ereal
  assumes "0 \<le> a"
    and "0 \<le> b"
  shows "0 \<le> a / b"
  using assms by (cases rule: ereal2_cases[of a b]) (auto simp: zero_le_divide_iff)

lemma ereal_le_divide_pos:
  fixes x y z :: ereal
  shows "x > 0 \<Longrightarrow> x \<noteq> \<infinity> \<Longrightarrow> y \<le> z / x \<longleftrightarrow> x * y \<le> z"
  by (cases rule: ereal3_cases[of x y z]) (auto simp: field_simps)

lemma ereal_divide_le_pos:
  fixes x y z :: ereal
  shows "x > 0 \<Longrightarrow> x \<noteq> \<infinity> \<Longrightarrow> z / x \<le> y \<longleftrightarrow> z \<le> x * y"
  by (cases rule: ereal3_cases[of x y z]) (auto simp: field_simps)

lemma ereal_le_divide_neg:
  fixes x y z :: ereal
  shows "x < 0 \<Longrightarrow> x \<noteq> -\<infinity> \<Longrightarrow> y \<le> z / x \<longleftrightarrow> z \<le> x * y"
  by (cases rule: ereal3_cases[of x y z]) (auto simp: field_simps)

lemma ereal_divide_le_neg:
  fixes x y z :: ereal
  shows "x < 0 \<Longrightarrow> x \<noteq> -\<infinity> \<Longrightarrow> z / x \<le> y \<longleftrightarrow> x * y \<le> z"
  by (cases rule: ereal3_cases[of x y z]) (auto simp: field_simps)

lemma ereal_inverse_antimono_strict:
  fixes x y :: ereal
  shows "0 \<le> x \<Longrightarrow> x < y \<Longrightarrow> inverse y < inverse x"
  by (cases rule: ereal2_cases[of x y]) auto

lemma ereal_inverse_antimono:
  fixes x y :: ereal
  shows "0 \<le> x \<Longrightarrow> x \<le> y \<Longrightarrow> inverse y \<le> inverse x"
  by (cases rule: ereal2_cases[of x y]) auto

lemma inverse_inverse_Pinfty_iff[simp]:
  fixes x :: ereal
  shows "inverse x = \<infinity> \<longleftrightarrow> x = 0"
  by (cases x) auto

lemma ereal_inverse_eq_0:
  fixes x :: ereal
  shows "inverse x = 0 \<longleftrightarrow> x = \<infinity> \<or> x = -\<infinity>"
  by (cases x) auto

lemma ereal_0_gt_inverse:
  fixes x :: ereal
  shows "0 < inverse x \<longleftrightarrow> x \<noteq> \<infinity> \<and> 0 \<le> x"
  by (cases x) auto

lemma ereal_inverse_le_0_iff:
  fixes x :: ereal
  shows "inverse x \<le> 0 \<longleftrightarrow> x < 0 \<or> x = \<infinity>"
  by(cases x) auto

lemma ereal_divide_eq_0_iff: "x / y = 0 \<longleftrightarrow> x = 0 \<or> \<bar>y :: ereal\<bar> = \<infinity>"
by(cases x y rule: ereal2_cases) simp_all

lemma ereal_mult_less_right:
  fixes a b c :: ereal
  assumes "b * a < c * a"
    and "0 < a"
    and "a < \<infinity>"
  shows "b < c"
  using assms
  by (cases rule: ereal3_cases[of a b c])
     (auto split: split_if_asm simp: zero_less_mult_iff zero_le_mult_iff)

lemma ereal_mult_divide: fixes a b :: ereal shows "0 < b \<Longrightarrow> b < \<infinity> \<Longrightarrow> b * (a / b) = a"
  by (cases a b rule: ereal2_cases) auto

lemma ereal_power_divide:
  fixes x y :: ereal
  shows "y \<noteq> 0 \<Longrightarrow> (x / y) ^ n = x^n / y^n"
  by (cases rule: ereal2_cases [of x y])
     (auto simp: one_ereal_def zero_ereal_def power_divide zero_le_power_eq)

lemma ereal_le_mult_one_interval:
  fixes x y :: ereal
  assumes y: "y \<noteq> -\<infinity>"
  assumes z: "\<And>z. 0 < z \<Longrightarrow> z < 1 \<Longrightarrow> z * x \<le> y"
  shows "x \<le> y"
proof (cases x)
  case PInf
  with z[of "1 / 2"] show "x \<le> y"
    by (simp add: one_ereal_def)
next
  case (real r)
  note r = this
  show "x \<le> y"
  proof (cases y)
    case (real p)
    note p = this
    have "r \<le> p"
    proof (rule field_le_mult_one_interval)
      fix z :: real
      assume "0 < z" and "z < 1"
      with z[of "ereal z"] show "z * r \<le> p"
        using p r by (auto simp: zero_le_mult_iff one_ereal_def)
    qed
    then show "x \<le> y"
      using p r by simp
  qed (insert y, simp_all)
qed simp

lemma ereal_divide_right_mono[simp]:
  fixes x y z :: ereal
  assumes "x \<le> y"
    and "0 < z"
  shows "x / z \<le> y / z"
  using assms by (cases x y z rule: ereal3_cases) (auto intro: divide_right_mono)

lemma ereal_divide_left_mono[simp]:
  fixes x y z :: ereal
  assumes "y \<le> x"
    and "0 < z"
    and "0 < x * y"
  shows "z / x \<le> z / y"
  using assms
  by (cases x y z rule: ereal3_cases)
     (auto intro: divide_left_mono simp: field_simps zero_less_mult_iff mult_less_0_iff split: split_if_asm)

lemma ereal_divide_zero_left[simp]:
  fixes a :: ereal
  shows "0 / a = 0"
  by (cases a) (auto simp: zero_ereal_def)

lemma ereal_times_divide_eq_left[simp]:
  fixes a b c :: ereal
  shows "b / c * a = b * a / c"
  by (cases a b c rule: ereal3_cases) (auto simp: field_simps zero_less_mult_iff mult_less_0_iff)

lemma ereal_times_divide_eq: "a * (b / c :: ereal) = a * b / c"
  by (cases a b c rule: ereal3_cases)
     (auto simp: field_simps zero_less_mult_iff)

subsection "Complete lattice"

instantiation ereal :: lattice
begin

definition [simp]: "sup x y = (max x y :: ereal)"
definition [simp]: "inf x y = (min x y :: ereal)"
instance by standard simp_all

end

instantiation ereal :: complete_lattice
begin

definition "bot = (-\<infinity>::ereal)"
definition "top = (\<infinity>::ereal)"

definition "Sup S = (SOME x :: ereal. (\<forall>y\<in>S. y \<le> x) \<and> (\<forall>z. (\<forall>y\<in>S. y \<le> z) \<longrightarrow> x \<le> z))"
definition "Inf S = (SOME x :: ereal. (\<forall>y\<in>S. x \<le> y) \<and> (\<forall>z. (\<forall>y\<in>S. z \<le> y) \<longrightarrow> z \<le> x))"

lemma ereal_complete_Sup:
  fixes S :: "ereal set"
  shows "\<exists>x. (\<forall>y\<in>S. y \<le> x) \<and> (\<forall>z. (\<forall>y\<in>S. y \<le> z) \<longrightarrow> x \<le> z)"
proof (cases "\<exists>x. \<forall>a\<in>S. a \<le> ereal x")
  case True
  then obtain y where y: "\<And>a. a\<in>S \<Longrightarrow> a \<le> ereal y"
    by auto
  then have "\<infinity> \<notin> S"
    by force
  show ?thesis
  proof (cases "S \<noteq> {-\<infinity>} \<and> S \<noteq> {}")
    case True
    with \<open>\<infinity> \<notin> S\<close> obtain x where x: "x \<in> S" "\<bar>x\<bar> \<noteq> \<infinity>"
      by auto
    obtain s where s: "\<forall>x\<in>ereal -` S. x \<le> s" "\<And>z. (\<forall>x\<in>ereal -` S. x \<le> z) \<Longrightarrow> s \<le> z"
    proof (atomize_elim, rule complete_real)
      show "\<exists>x. x \<in> ereal -` S"
        using x by auto
      show "\<exists>z. \<forall>x\<in>ereal -` S. x \<le> z"
        by (auto dest: y intro!: exI[of _ y])
    qed
    show ?thesis
    proof (safe intro!: exI[of _ "ereal s"])
      fix y
      assume "y \<in> S"
      with s \<open>\<infinity> \<notin> S\<close> show "y \<le> ereal s"
        by (cases y) auto
    next
      fix z
      assume "\<forall>y\<in>S. y \<le> z"
      with \<open>S \<noteq> {-\<infinity>} \<and> S \<noteq> {}\<close> show "ereal s \<le> z"
        by (cases z) (auto intro!: s)
    qed
  next
    case False
    then show ?thesis
      by (auto intro!: exI[of _ "-\<infinity>"])
  qed
next
  case False
  then show ?thesis
    by (fastforce intro!: exI[of _ \<infinity>] ereal_top intro: order_trans dest: less_imp_le simp: not_le)
qed

lemma ereal_complete_uminus_eq:
  fixes S :: "ereal set"
  shows "(\<forall>y\<in>uminus`S. y \<le> x) \<and> (\<forall>z. (\<forall>y\<in>uminus`S. y \<le> z) \<longrightarrow> x \<le> z)
     \<longleftrightarrow> (\<forall>y\<in>S. -x \<le> y) \<and> (\<forall>z. (\<forall>y\<in>S. z \<le> y) \<longrightarrow> z \<le> -x)"
  by simp (metis ereal_minus_le_minus ereal_uminus_uminus)

lemma ereal_complete_Inf:
  "\<exists>x. (\<forall>y\<in>S::ereal set. x \<le> y) \<and> (\<forall>z. (\<forall>y\<in>S. z \<le> y) \<longrightarrow> z \<le> x)"
  using ereal_complete_Sup[of "uminus ` S"]
  unfolding ereal_complete_uminus_eq
  by auto

instance
proof
  show "Sup {} = (bot::ereal)"
    apply (auto simp: bot_ereal_def Sup_ereal_def)
    apply (rule some1_equality)
    apply (metis ereal_bot ereal_less_eq(2))
    apply (metis ereal_less_eq(2))
    done
  show "Inf {} = (top::ereal)"
    apply (auto simp: top_ereal_def Inf_ereal_def)
    apply (rule some1_equality)
    apply (metis ereal_top ereal_less_eq(1))
    apply (metis ereal_less_eq(1))
    done
qed (auto intro: someI2_ex ereal_complete_Sup ereal_complete_Inf
  simp: Sup_ereal_def Inf_ereal_def bot_ereal_def top_ereal_def)

end

instance ereal :: complete_linorder ..

instance ereal :: linear_continuum
proof
  show "\<exists>a b::ereal. a \<noteq> b"
    using zero_neq_one by blast
qed

subsubsection "Topological space"

instantiation ereal :: linear_continuum_topology
begin

definition "open_ereal" :: "ereal set \<Rightarrow> bool" where
  open_ereal_generated: "open_ereal = generate_topology (range lessThan \<union> range greaterThan)"

instance
  by standard (simp add: open_ereal_generated)

end

lemma continuous_on_compose': 
  "continuous_on s f \<Longrightarrow> continuous_on t g \<Longrightarrow> f`s \<subseteq> t \<Longrightarrow> continuous_on s (\<lambda>x. g (f x))"
  using continuous_on_compose[of s f g] continuous_on_subset[of t g "f`s"] by auto

lemma continuous_on_ereal[continuous_intros]:
  assumes f: "continuous_on s f" shows "continuous_on s (\<lambda>x. ereal (f x))"
  by (rule continuous_on_compose'[OF f continuous_onI_mono[of ereal UNIV]]) auto

lemma tendsto_ereal[tendsto_intros, simp, intro]: "(f ---> x) F \<Longrightarrow> ((\<lambda>x. ereal (f x)) ---> ereal x) F"
  using isCont_tendsto_compose[of x ereal f F] continuous_on_ereal[of UNIV "\<lambda>x. x"]
  by (simp add: continuous_on_eq_continuous_at)

lemma tendsto_uminus_ereal[tendsto_intros, simp, intro]: "(f ---> x) F \<Longrightarrow> ((\<lambda>x. - f x::ereal) ---> - x) F"
  apply (rule tendsto_compose[where g=uminus])
  apply (auto intro!: order_tendstoI simp: eventually_at_topological)
  apply (rule_tac x="{..< -a}" in exI)
  apply (auto split: ereal.split simp: ereal_less_uminus_reorder) []
  apply (rule_tac x="{- a <..}" in exI)
  apply (auto split: ereal.split simp: ereal_uminus_reorder) []
  done

lemma ereal_Lim_uminus: "(f ---> f0) net \<longleftrightarrow> ((\<lambda>x. - f x::ereal) ---> - f0) net"
  using tendsto_uminus_ereal[of f f0 net] tendsto_uminus_ereal[of "\<lambda>x. - f x" "- f0" net]
  by auto

lemma ereal_divide_less_iff: "0 < (c::ereal) \<Longrightarrow> c < \<infinity> \<Longrightarrow> a / c < b \<longleftrightarrow> a < b * c"
  by (cases a b c rule: ereal3_cases) (auto simp: field_simps)

lemma ereal_less_divide_iff: "0 < (c::ereal) \<Longrightarrow> c < \<infinity> \<Longrightarrow> a < b / c \<longleftrightarrow> a * c < b"
  by (cases a b c rule: ereal3_cases) (auto simp: field_simps)

lemma tendsto_cmult_ereal[tendsto_intros, simp, intro]:
  assumes c: "\<bar>c\<bar> \<noteq> \<infinity>" and f: "(f ---> x) F" shows "((\<lambda>x. c * f x::ereal) ---> c * x) F"
proof -
  { fix c :: ereal assume "0 < c" "c < \<infinity>"
    then have "((\<lambda>x. c * f x::ereal) ---> c * x) F"
      apply (intro tendsto_compose[OF _ f])
      apply (auto intro!: order_tendstoI simp: eventually_at_topological)
      apply (rule_tac x="{a/c <..}" in exI)
      apply (auto split: ereal.split simp: ereal_divide_less_iff mult.commute) []
      apply (rule_tac x="{..< a/c}" in exI)
      apply (auto split: ereal.split simp: ereal_less_divide_iff mult.commute) []
      done }
  note * = this

  have "((0 < c \<and> c < \<infinity>) \<or> (-\<infinity> < c \<and> c < 0) \<or> c = 0)"
    using c by (cases c) auto
  then show ?thesis
  proof (elim disjE conjE)
    assume "- \<infinity> < c" "c < 0"
    then have "0 < - c" "- c < \<infinity>"
      by (auto simp: ereal_uminus_reorder ereal_less_uminus_reorder[of 0])
    then have "((\<lambda>x. (- c) * f x) ---> (- c) * x) F"
      by (rule *)
    from tendsto_uminus_ereal[OF this] show ?thesis 
      by simp
  qed (auto intro!: *)
qed

lemma tendsto_cmult_ereal_not_0[tendsto_intros, simp, intro]:
  assumes "x \<noteq> 0" and f: "(f ---> x) F" shows "((\<lambda>x. c * f x::ereal) ---> c * x) F"
proof cases
  assume "\<bar>c\<bar> = \<infinity>"
  show ?thesis
  proof (rule filterlim_cong[THEN iffD1, OF refl refl _ tendsto_const])
    have "0 < x \<or> x < 0"
      using \<open>x \<noteq> 0\<close> by (auto simp add: neq_iff)
    then show "eventually (\<lambda>x'. c * x = c * f x') F"
    proof
      assume "0 < x" from order_tendstoD(1)[OF f this] show ?thesis
        by eventually_elim (insert \<open>0<x\<close> \<open>\<bar>c\<bar> = \<infinity>\<close>, auto)
    next
      assume "x < 0" from order_tendstoD(2)[OF f this] show ?thesis
        by eventually_elim (insert \<open>x<0\<close> \<open>\<bar>c\<bar> = \<infinity>\<close>, auto)
    qed
  qed
qed (rule tendsto_cmult_ereal[OF _ f])

lemma tendsto_cadd_ereal[tendsto_intros, simp, intro]:
  assumes c: "y \<noteq> - \<infinity>" "x \<noteq> - \<infinity>" and f: "(f ---> x) F" shows "((\<lambda>x. f x + y::ereal) ---> x + y) F"
  apply (intro tendsto_compose[OF _ f])
  apply (auto intro!: order_tendstoI simp: eventually_at_topological)
  apply (rule_tac x="{a - y <..}" in exI)
  apply (auto split: ereal.split simp: ereal_minus_less_iff c) []
  apply (rule_tac x="{..< a - y}" in exI)
  apply (auto split: ereal.split simp: ereal_less_minus_iff c) []
  done

lemma tendsto_add_left_ereal[tendsto_intros, simp, intro]:
  assumes c: "\<bar>y\<bar> \<noteq> \<infinity>" and f: "(f ---> x) F" shows "((\<lambda>x. f x + y::ereal) ---> x + y) F"
  apply (intro tendsto_compose[OF _ f])
  apply (auto intro!: order_tendstoI simp: eventually_at_topological)
  apply (rule_tac x="{a - y <..}" in exI)
  apply (insert c, auto split: ereal.split simp: ereal_minus_less_iff) []
  apply (rule_tac x="{..< a - y}" in exI)
  apply (auto split: ereal.split simp: ereal_less_minus_iff c) []
  done

lemma continuous_at_ereal[continuous_intros]: "continuous F f \<Longrightarrow> continuous F (\<lambda>x. ereal (f x))"
  unfolding continuous_def by auto

lemma ereal_Sup:
  assumes *: "\<bar>SUP a:A. ereal a\<bar> \<noteq> \<infinity>"
  shows "ereal (Sup A) = (SUP a:A. ereal a)"
proof (rule continuous_at_Sup_mono)
  obtain r where r: "ereal r = (SUP a:A. ereal a)" "A \<noteq> {}"
    using * by (force simp: bot_ereal_def)
  then show "bdd_above A" "A \<noteq> {}"
    by (auto intro!: SUP_upper bdd_aboveI[of _ r] simp add: ereal_less_eq(3)[symmetric] simp del: ereal_less_eq)
qed (auto simp: mono_def continuous_at_imp_continuous_at_within continuous_at_ereal)

lemma ereal_SUP: "\<bar>SUP a:A. ereal (f a)\<bar> \<noteq> \<infinity> \<Longrightarrow> ereal (SUP a:A. f a) = (SUP a:A. ereal (f a))"
  using ereal_Sup[of "f`A"] by auto

lemma ereal_Inf:
  assumes *: "\<bar>INF a:A. ereal a\<bar> \<noteq> \<infinity>"
  shows "ereal (Inf A) = (INF a:A. ereal a)"
proof (rule continuous_at_Inf_mono)
  obtain r where r: "ereal r = (INF a:A. ereal a)" "A \<noteq> {}"
    using * by (force simp: top_ereal_def)
  then show "bdd_below A" "A \<noteq> {}"
    by (auto intro!: INF_lower bdd_belowI[of _ r] simp add: ereal_less_eq(3)[symmetric] simp del: ereal_less_eq)
qed (auto simp: mono_def continuous_at_imp_continuous_at_within continuous_at_ereal)

lemma ereal_INF: "\<bar>INF a:A. ereal (f a)\<bar> \<noteq> \<infinity> \<Longrightarrow> ereal (INF a:A. f a) = (INF a:A. ereal (f a))"
  using ereal_Inf[of "f`A"] by auto

lemma ereal_Sup_uminus_image_eq: "Sup (uminus ` S::ereal set) = - Inf S"
  by (auto intro!: SUP_eqI
           simp: Ball_def[symmetric] ereal_uminus_le_reorder le_Inf_iff
           intro!: complete_lattice_class.Inf_lower2)

lemma ereal_SUP_uminus_eq:
  fixes f :: "'a \<Rightarrow> ereal"
  shows "(SUP x:S. uminus (f x)) = - (INF x:S. f x)"
  using ereal_Sup_uminus_image_eq [of "f ` S"] by (simp add: comp_def)

lemma ereal_inj_on_uminus[intro, simp]: "inj_on uminus (A :: ereal set)"
  by (auto intro!: inj_onI)

lemma ereal_Inf_uminus_image_eq: "Inf (uminus ` S::ereal set) = - Sup S"
  using ereal_Sup_uminus_image_eq[of "uminus ` S"] by simp

lemma ereal_INF_uminus_eq:
  fixes f :: "'a \<Rightarrow> ereal"
  shows "(INF x:S. - f x) = - (SUP x:S. f x)"
  using ereal_Inf_uminus_image_eq [of "f ` S"] by (simp add: comp_def)

lemma ereal_SUP_uminus:
  fixes f :: "'a \<Rightarrow> ereal"
  shows "(SUP i : R. - f i) = - (INF i : R. f i)"
  using ereal_Sup_uminus_image_eq[of "f`R"]
  by (simp add: image_image)

lemma ereal_SUP_not_infty:
  fixes f :: "_ \<Rightarrow> ereal"
  shows "A \<noteq> {} \<Longrightarrow> l \<noteq> -\<infinity> \<Longrightarrow> u \<noteq> \<infinity> \<Longrightarrow> \<forall>a\<in>A. l \<le> f a \<and> f a \<le> u \<Longrightarrow> \<bar>SUPREMUM A f\<bar> \<noteq> \<infinity>"
  using SUP_upper2[of _ A l f] SUP_least[of A f u]
  by (cases "SUPREMUM A f") auto

lemma ereal_INF_not_infty:
  fixes f :: "_ \<Rightarrow> ereal"
  shows "A \<noteq> {} \<Longrightarrow> l \<noteq> -\<infinity> \<Longrightarrow> u \<noteq> \<infinity> \<Longrightarrow> \<forall>a\<in>A. l \<le> f a \<and> f a \<le> u \<Longrightarrow> \<bar>INFIMUM A f\<bar> \<noteq> \<infinity>"
  using INF_lower2[of _ A f u] INF_greatest[of A l f]
  by (cases "INFIMUM A f") auto

lemma ereal_image_uminus_shift:
  fixes X Y :: "ereal set"
  shows "uminus ` X = Y \<longleftrightarrow> X = uminus ` Y"
proof
  assume "uminus ` X = Y"
  then have "uminus ` uminus ` X = uminus ` Y"
    by (simp add: inj_image_eq_iff)
  then show "X = uminus ` Y"
    by (simp add: image_image)
qed (simp add: image_image)

lemma Sup_eq_MInfty:
  fixes S :: "ereal set"
  shows "Sup S = -\<infinity> \<longleftrightarrow> S = {} \<or> S = {-\<infinity>}"
  unfolding bot_ereal_def[symmetric] by auto

lemma Inf_eq_PInfty:
  fixes S :: "ereal set"
  shows "Inf S = \<infinity> \<longleftrightarrow> S = {} \<or> S = {\<infinity>}"
  using Sup_eq_MInfty[of "uminus`S"]
  unfolding ereal_Sup_uminus_image_eq ereal_image_uminus_shift by simp

lemma Inf_eq_MInfty:
  fixes S :: "ereal set"
  shows "-\<infinity> \<in> S \<Longrightarrow> Inf S = -\<infinity>"
  unfolding bot_ereal_def[symmetric] by auto

lemma Sup_eq_PInfty:
  fixes S :: "ereal set"
  shows "\<infinity> \<in> S \<Longrightarrow> Sup S = \<infinity>"
  unfolding top_ereal_def[symmetric] by auto

lemma not_MInfty_nonneg[simp]: "0 \<le> (x::ereal) \<Longrightarrow> x \<noteq> - \<infinity>"
  by auto

lemma Sup_ereal_close:
  fixes e :: ereal
  assumes "0 < e"
    and S: "\<bar>Sup S\<bar> \<noteq> \<infinity>" "S \<noteq> {}"
  shows "\<exists>x\<in>S. Sup S - e < x"
  using assms by (cases e) (auto intro!: less_Sup_iff[THEN iffD1])

lemma Inf_ereal_close:
  fixes e :: ereal
  assumes "\<bar>Inf X\<bar> \<noteq> \<infinity>"
    and "0 < e"
  shows "\<exists>x\<in>X. x < Inf X + e"
proof (rule Inf_less_iff[THEN iffD1])
  show "Inf X < Inf X + e"
    using assms by (cases e) auto
qed

lemma SUP_PInfty:
  "(\<And>n::nat. \<exists>i\<in>A. ereal (real n) \<le> f i) \<Longrightarrow> (SUP i:A. f i :: ereal) = \<infinity>"
  unfolding top_ereal_def[symmetric] SUP_eq_top_iff
  by (metis MInfty_neq_PInfty(2) PInfty_neq_ereal(2) less_PInf_Ex_of_nat less_ereal.elims(2) less_le_trans)

lemma SUP_nat_Infty: "(SUP i::nat. ereal (real i)) = \<infinity>"
  by (rule SUP_PInfty) auto

lemma SUP_ereal_add_left:
  assumes "I \<noteq> {}" "c \<noteq> -\<infinity>"
  shows "(SUP i:I. f i + c :: ereal) = (SUP i:I. f i) + c"
proof cases
  assume "(SUP i:I. f i) = - \<infinity>"
  moreover then have "\<And>i. i \<in> I \<Longrightarrow> f i = -\<infinity>"
    unfolding Sup_eq_MInfty Sup_image_eq[symmetric] by auto
  ultimately show ?thesis
    by (cases c) (auto simp: \<open>I \<noteq> {}\<close>)
next
  assume "(SUP i:I. f i) \<noteq> - \<infinity>" then show ?thesis
    unfolding Sup_image_eq[symmetric]
    by (subst continuous_at_Sup_mono[where f="\<lambda>x. x + c"])
       (auto simp: continuous_at_imp_continuous_at_within continuous_at mono_def ereal_add_mono \<open>I \<noteq> {}\<close> \<open>c \<noteq> -\<infinity>\<close>)
qed

lemma SUP_ereal_add_right:
  fixes c :: ereal
  shows "I \<noteq> {} \<Longrightarrow> c \<noteq> -\<infinity> \<Longrightarrow> (SUP i:I. c + f i) = c + (SUP i:I. f i)"
  using SUP_ereal_add_left[of I c f] by (simp add: add.commute)

lemma SUP_ereal_minus_right:
  assumes "I \<noteq> {}" "c \<noteq> -\<infinity>"
  shows "(SUP i:I. c - f i :: ereal) = c - (INF i:I. f i)"
  using SUP_ereal_add_right[OF assms, of "\<lambda>i. - f i"]
  by (simp add: ereal_SUP_uminus minus_ereal_def)

lemma SUP_ereal_minus_left:
  assumes "I \<noteq> {}" "c \<noteq> \<infinity>"
  shows "(SUP i:I. f i - c:: ereal) = (SUP i:I. f i) - c"
  using SUP_ereal_add_left[OF \<open>I \<noteq> {}\<close>, of "-c" f] by (simp add: \<open>c \<noteq> \<infinity>\<close> minus_ereal_def)

lemma INF_ereal_minus_right:
  assumes "I \<noteq> {}" and "\<bar>c\<bar> \<noteq> \<infinity>"
  shows "(INF i:I. c - f i) = c - (SUP i:I. f i::ereal)"
proof -
  { fix b have "(-c) + b = - (c - b)"
      using \<open>\<bar>c\<bar> \<noteq> \<infinity>\<close> by (cases c b rule: ereal2_cases) auto }
  note * = this
  show ?thesis
    using SUP_ereal_add_right[OF \<open>I \<noteq> {}\<close>, of "-c" f] \<open>\<bar>c\<bar> \<noteq> \<infinity>\<close>
    by (auto simp add: * ereal_SUP_uminus_eq)
qed

lemma SUP_ereal_le_addI:
  fixes f :: "'i \<Rightarrow> ereal"
  assumes "\<And>i. f i + y \<le> z" and "y \<noteq> -\<infinity>"
  shows "SUPREMUM UNIV f + y \<le> z"
  unfolding SUP_ereal_add_left[OF UNIV_not_empty \<open>y \<noteq> -\<infinity>\<close>, symmetric]
  by (rule SUP_least assms)+

lemma SUP_combine:
  fixes f :: "'a::semilattice_sup \<Rightarrow> 'a::semilattice_sup \<Rightarrow> 'b::complete_lattice"
  assumes mono: "\<And>a b c d. a \<le> b \<Longrightarrow> c \<le> d \<Longrightarrow> f a c \<le> f b d"
  shows "(SUP i:UNIV. SUP j:UNIV. f i j) = (SUP i. f i i)"
proof (rule antisym)
  show "(SUP i j. f i j) \<le> (SUP i. f i i)"
    by (rule SUP_least SUP_upper2[where i="sup i j" for i j] UNIV_I mono sup_ge1 sup_ge2)+
  show "(SUP i. f i i) \<le> (SUP i j. f i j)"
    by (rule SUP_least SUP_upper2 UNIV_I mono order_refl)+
qed

lemma SUP_ereal_add:
  fixes f g :: "nat \<Rightarrow> ereal"
  assumes inc: "incseq f" "incseq g"
    and pos: "\<And>i. f i \<noteq> -\<infinity>" "\<And>i. g i \<noteq> -\<infinity>"
  shows "(SUP i. f i + g i) = SUPREMUM UNIV f + SUPREMUM UNIV g"
  apply (subst SUP_ereal_add_left[symmetric, OF UNIV_not_empty])
  apply (metis SUP_upper UNIV_I assms(4) ereal_infty_less_eq(2))
  apply (subst (2) add.commute)
  apply (subst SUP_ereal_add_left[symmetric, OF UNIV_not_empty assms(3)])
  apply (subst (2) add.commute)
  apply (rule SUP_combine[symmetric] ereal_add_mono inc[THEN monoD] | assumption)+
  done

lemma INF_ereal_add:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "decseq f" "decseq g"
    and fin: "\<And>i. f i \<noteq> \<infinity>" "\<And>i. g i \<noteq> \<infinity>"
  shows "(INF i. f i + g i) = INFIMUM UNIV f + INFIMUM UNIV g"
proof -
  have INF_less: "(INF i. f i) < \<infinity>" "(INF i. g i) < \<infinity>"
    using assms unfolding INF_less_iff by auto
  { fix a b :: ereal assume "a \<noteq> \<infinity>" "b \<noteq> \<infinity>"
    then have "- ((- a) + (- b)) = a + b"
      by (cases a b rule: ereal2_cases) auto }
  note * = this
  have "(INF i. f i + g i) = (INF i. - ((- f i) + (- g i)))"
    by (simp add: fin *)
  also have "\<dots> = INFIMUM UNIV f + INFIMUM UNIV g"
    unfolding ereal_INF_uminus_eq
    using assms INF_less
    by (subst SUP_ereal_add) (auto simp: ereal_SUP_uminus fin *)
  finally show ?thesis .
qed

lemma SUP_ereal_add_pos:
  fixes f g :: "nat \<Rightarrow> ereal"
  assumes inc: "incseq f" "incseq g"
    and pos: "\<And>i. 0 \<le> f i" "\<And>i. 0 \<le> g i"
  shows "(SUP i. f i + g i) = SUPREMUM UNIV f + SUPREMUM UNIV g"
proof (intro SUP_ereal_add inc)
  fix i
  show "f i \<noteq> -\<infinity>" "g i \<noteq> -\<infinity>"
    using pos[of i] by auto
qed

lemma SUP_ereal_setsum:
  fixes f g :: "'a \<Rightarrow> nat \<Rightarrow> ereal"
  assumes "\<And>n. n \<in> A \<Longrightarrow> incseq (f n)"
    and pos: "\<And>n i. n \<in> A \<Longrightarrow> 0 \<le> f n i"
  shows "(SUP i. \<Sum>n\<in>A. f n i) = (\<Sum>n\<in>A. SUPREMUM UNIV (f n))"
proof (cases "finite A")
  case True
  then show ?thesis using assms
    by induct (auto simp: incseq_setsumI2 setsum_nonneg SUP_ereal_add_pos)
next
  case False
  then show ?thesis by simp
qed

lemma SUP_ereal_mult_left:
  fixes f :: "'a \<Rightarrow> ereal"
  assumes "I \<noteq> {}"
  assumes f: "\<And>i. i \<in> I \<Longrightarrow> 0 \<le> f i" and c: "0 \<le> c"
  shows "(SUP i:I. c * f i) = c * (SUP i:I. f i)"
proof cases
  assume "(SUP i: I. f i) = 0"
  moreover then have "\<And>i. i \<in> I \<Longrightarrow> f i = 0"
    by (metis SUP_upper f antisym)
  ultimately show ?thesis
    by simp
next
  assume "(SUP i:I. f i) \<noteq> 0" then show ?thesis
    unfolding SUP_def
    by (subst continuous_at_Sup_mono[where f="\<lambda>x. c * x"])
       (auto simp: mono_def continuous_at continuous_at_imp_continuous_at_within \<open>I \<noteq> {}\<close>
             intro!: ereal_mult_left_mono c)
qed

lemma countable_approach: 
  fixes x :: ereal
  assumes "x \<noteq> -\<infinity>"
  shows "\<exists>f. incseq f \<and> (\<forall>i::nat. f i < x) \<and> (f ----> x)"
proof (cases x)
  case (real r)
  moreover have "(\<lambda>n. r - inverse (real (Suc n))) ----> r - 0"
    by (intro tendsto_intros LIMSEQ_inverse_real_of_nat)
  ultimately show ?thesis
    by (intro exI[of _ "\<lambda>n. x - inverse (Suc n)"]) (auto simp: incseq_def)
next 
  case PInf with LIMSEQ_SUP[of "\<lambda>n::nat. ereal (real n)"] show ?thesis
    by (intro exI[of _ "\<lambda>n. ereal (real n)"]) (auto simp: incseq_def SUP_nat_Infty)
qed (simp add: assms)

lemma Sup_countable_SUP:
  assumes "A \<noteq> {}"
  shows "\<exists>f::nat \<Rightarrow> ereal. incseq f \<and> range f \<subseteq> A \<and> Sup A = (SUP i. f i)"
proof cases
  assume "Sup A = -\<infinity>"
  with \<open>A \<noteq> {}\<close> have "A = {-\<infinity>}"
    by (auto simp: Sup_eq_MInfty)
  then show ?thesis
    by (auto intro!: exI[of _ "\<lambda>_. -\<infinity>"] simp: bot_ereal_def)
next
  assume "Sup A \<noteq> -\<infinity>"
  then obtain l where "incseq l" and l: "\<And>i::nat. l i < Sup A" and l_Sup: "l ----> Sup A"
    by (auto dest: countable_approach)

  have "\<exists>f. \<forall>n. (f n \<in> A \<and> l n \<le> f n) \<and> (f n \<le> f (Suc n))"
  proof (rule dependent_nat_choice)
    show "\<exists>x. x \<in> A \<and> l 0 \<le> x"
      using l[of 0] by (auto simp: less_Sup_iff)
  next
    fix x n assume "x \<in> A \<and> l n \<le> x"
    moreover from l[of "Suc n"] obtain y where "y \<in> A" "l (Suc n) < y"
      by (auto simp: less_Sup_iff)
    ultimately show "\<exists>y. (y \<in> A \<and> l (Suc n) \<le> y) \<and> x \<le> y"
      by (auto intro!: exI[of _ "max x y"] split: split_max)
  qed
  then guess f .. note f = this
  then have "range f \<subseteq> A" "incseq f"
    by (auto simp: incseq_Suc_iff)
  moreover
  have "(SUP i. f i) = Sup A"
  proof (rule tendsto_unique)
    show "f ----> (SUP i. f i)"
      by (rule LIMSEQ_SUP \<open>incseq f\<close>)+
    show "f ----> Sup A"
      using l f
      by (intro tendsto_sandwich[OF _ _ l_Sup tendsto_const])
         (auto simp: Sup_upper)
  qed simp
  ultimately show ?thesis
    by auto
qed

lemma SUP_countable_SUP:
  "A \<noteq> {} \<Longrightarrow> \<exists>f::nat \<Rightarrow> ereal. range f \<subseteq> g`A \<and> SUPREMUM A g = SUPREMUM UNIV f"
  using Sup_countable_SUP [of "g`A"] by auto

subsection "Relation to @{typ enat}"

definition "ereal_of_enat n = (case n of enat n \<Rightarrow> ereal (real n) | \<infinity> \<Rightarrow> \<infinity>)"

declare [[coercion "ereal_of_enat :: enat \<Rightarrow> ereal"]]
declare [[coercion "(\<lambda>n. ereal (real n)) :: nat \<Rightarrow> ereal"]]

lemma ereal_of_enat_simps[simp]:
  "ereal_of_enat (enat n) = ereal n"
  "ereal_of_enat \<infinity> = \<infinity>"
  by (simp_all add: ereal_of_enat_def)

lemma ereal_of_enat_le_iff[simp]: "ereal_of_enat m \<le> ereal_of_enat n \<longleftrightarrow> m \<le> n"
  by (cases m n rule: enat2_cases) auto

lemma ereal_of_enat_less_iff[simp]: "ereal_of_enat m < ereal_of_enat n \<longleftrightarrow> m < n"
  by (cases m n rule: enat2_cases) auto

lemma numeral_le_ereal_of_enat_iff[simp]: "numeral m \<le> ereal_of_enat n \<longleftrightarrow> numeral m \<le> n"
by (cases n) (auto)

lemma numeral_less_ereal_of_enat_iff[simp]: "numeral m < ereal_of_enat n \<longleftrightarrow> numeral m < n"
  by (cases n) auto

lemma ereal_of_enat_ge_zero_cancel_iff[simp]: "0 \<le> ereal_of_enat n \<longleftrightarrow> 0 \<le> n"
  by (cases n) (auto simp: enat_0[symmetric])

lemma ereal_of_enat_gt_zero_cancel_iff[simp]: "0 < ereal_of_enat n \<longleftrightarrow> 0 < n"
  by (cases n) (auto simp: enat_0[symmetric])

lemma ereal_of_enat_zero[simp]: "ereal_of_enat 0 = 0"
  by (auto simp: enat_0[symmetric])

lemma ereal_of_enat_inf[simp]: "ereal_of_enat n = \<infinity> \<longleftrightarrow> n = \<infinity>"
  by (cases n) auto

lemma ereal_of_enat_add: "ereal_of_enat (m + n) = ereal_of_enat m + ereal_of_enat n"
  by (cases m n rule: enat2_cases) auto

lemma ereal_of_enat_sub:
  assumes "n \<le> m"
  shows "ereal_of_enat (m - n) = ereal_of_enat m - ereal_of_enat n "
  using assms by (cases m n rule: enat2_cases) auto

lemma ereal_of_enat_mult:
  "ereal_of_enat (m * n) = ereal_of_enat m * ereal_of_enat n"
  by (cases m n rule: enat2_cases) auto

lemmas ereal_of_enat_pushin = ereal_of_enat_add ereal_of_enat_sub ereal_of_enat_mult
lemmas ereal_of_enat_pushout = ereal_of_enat_pushin[symmetric]

lemma ereal_of_enat_Sup:
  assumes "A \<noteq> {}" shows "ereal_of_enat (Sup A) = (SUP a : A. ereal_of_enat a)"
proof (intro antisym mono_Sup)
  show "ereal_of_enat (Sup A) \<le> (SUP a : A. ereal_of_enat a)"
  proof cases
    assume "finite A"
    with `A \<noteq> {}` obtain a where "a \<in> A" "ereal_of_enat (Sup A) = ereal_of_enat a"
      using Max_in[of A] by (auto simp: Sup_enat_def simp del: Max_in)
    then show ?thesis
      by (auto intro: SUP_upper)
  next
    assume "\<not> finite A"
    have [simp]: "(SUP a : A. ereal_of_enat a) = top"
      unfolding SUP_eq_top_iff
    proof safe
      fix x :: ereal assume "x < top"
      then obtain n :: nat where "x < n"
        using less_PInf_Ex_of_nat top_ereal_def by auto
      obtain a where "a \<in> A - enat ` {.. n}"
        by (metis `\<not> finite A` all_not_in_conv finite_Diff2 finite_atMost finite_imageI finite.emptyI)
      then have "a \<in> A" "ereal n \<le> ereal_of_enat a"
        by (auto simp: image_iff Ball_def)
           (metis enat_iless enat_ord_simps(1) ereal_of_enat_less_iff ereal_of_enat_simps(1) less_le not_less)
      with `x < n` show "\<exists>i\<in>A. x < ereal_of_enat i"
        by (auto intro!: bexI[of _ a])
    qed
    show ?thesis
      by simp
  qed
qed (simp add: mono_def)

lemma ereal_of_enat_SUP:
  "A \<noteq> {} \<Longrightarrow> ereal_of_enat (SUP a:A. f a) = (SUP a : A. ereal_of_enat (f a))"
  using ereal_of_enat_Sup[of "f`A"] by auto

subsection "Limits on @{typ ereal}"

lemma open_PInfty: "open A \<Longrightarrow> \<infinity> \<in> A \<Longrightarrow> (\<exists>x. {ereal x<..} \<subseteq> A)"
  unfolding open_ereal_generated
proof (induct rule: generate_topology.induct)
  case (Int A B)
  then obtain x z where "\<infinity> \<in> A \<Longrightarrow> {ereal x <..} \<subseteq> A" "\<infinity> \<in> B \<Longrightarrow> {ereal z <..} \<subseteq> B"
    by auto
  with Int show ?case
    by (intro exI[of _ "max x z"]) fastforce
next
  case (Basis S)
  {
    fix x
    have "x \<noteq> \<infinity> \<Longrightarrow> \<exists>t. x \<le> ereal t"
      by (cases x) auto
  }
  moreover note Basis
  ultimately show ?case
    by (auto split: ereal.split)
qed (fastforce simp add: vimage_Union)+

lemma open_MInfty: "open A \<Longrightarrow> -\<infinity> \<in> A \<Longrightarrow> (\<exists>x. {..<ereal x} \<subseteq> A)"
  unfolding open_ereal_generated
proof (induct rule: generate_topology.induct)
  case (Int A B)
  then obtain x z where "-\<infinity> \<in> A \<Longrightarrow> {..< ereal x} \<subseteq> A" "-\<infinity> \<in> B \<Longrightarrow> {..< ereal z} \<subseteq> B"
    by auto
  with Int show ?case
    by (intro exI[of _ "min x z"]) fastforce
next
  case (Basis S)
  {
    fix x
    have "x \<noteq> - \<infinity> \<Longrightarrow> \<exists>t. ereal t \<le> x"
      by (cases x) auto
  }
  moreover note Basis
  ultimately show ?case
    by (auto split: ereal.split)
qed (fastforce simp add: vimage_Union)+

lemma open_ereal_vimage: "open S \<Longrightarrow> open (ereal -` S)"
  by (intro open_vimage continuous_intros)

lemma open_ereal: "open S \<Longrightarrow> open (ereal ` S)"
  unfolding open_generated_order[where 'a=real]
proof (induct rule: generate_topology.induct)
  case (Basis S)
  moreover {
    fix x
    have "ereal ` {..< x} = { -\<infinity> <..< ereal x }"
      apply auto
      apply (case_tac xa)
      apply auto
      done
  }
  moreover {
    fix x
    have "ereal ` {x <..} = { ereal x <..< \<infinity> }"
      apply auto
      apply (case_tac xa)
      apply auto
      done
  }
  ultimately show ?case
     by auto
qed (auto simp add: image_Union image_Int)


lemma eventually_finite:
  fixes x :: ereal
  assumes "\<bar>x\<bar> \<noteq> \<infinity>" "(f ---> x) F"
  shows "eventually (\<lambda>x. \<bar>f x\<bar> \<noteq> \<infinity>) F"
proof -
  have "(f ---> ereal (real x)) F"
    using assms by (cases x) auto
  then have "eventually (\<lambda>x. f x \<in> ereal ` UNIV) F"
    by (rule topological_tendstoD) (auto intro: open_ereal)
  also have "(\<lambda>x. f x \<in> ereal ` UNIV) = (\<lambda>x. \<bar>f x\<bar> \<noteq> \<infinity>)"
    by auto
  finally show ?thesis .
qed


lemma open_ereal_def:
  "open A \<longleftrightarrow> open (ereal -` A) \<and> (\<infinity> \<in> A \<longrightarrow> (\<exists>x. {ereal x <..} \<subseteq> A)) \<and> (-\<infinity> \<in> A \<longrightarrow> (\<exists>x. {..<ereal x} \<subseteq> A))"
  (is "open A \<longleftrightarrow> ?rhs")
proof
  assume "open A"
  then show ?rhs
    using open_PInfty open_MInfty open_ereal_vimage by auto
next
  assume "?rhs"
  then obtain x y where A: "open (ereal -` A)" "\<infinity> \<in> A \<Longrightarrow> {ereal x<..} \<subseteq> A" "-\<infinity> \<in> A \<Longrightarrow> {..< ereal y} \<subseteq> A"
    by auto
  have *: "A = ereal ` (ereal -` A) \<union> (if \<infinity> \<in> A then {ereal x<..} else {}) \<union> (if -\<infinity> \<in> A then {..< ereal y} else {})"
    using A(2,3) by auto
  from open_ereal[OF A(1)] show "open A"
    by (subst *) (auto simp: open_Un)
qed

lemma open_PInfty2:
  assumes "open A"
    and "\<infinity> \<in> A"
  obtains x where "{ereal x<..} \<subseteq> A"
  using open_PInfty[OF assms] by auto

lemma open_MInfty2:
  assumes "open A"
    and "-\<infinity> \<in> A"
  obtains x where "{..<ereal x} \<subseteq> A"
  using open_MInfty[OF assms] by auto

lemma ereal_openE:
  assumes "open A"
  obtains x y where "open (ereal -` A)"
    and "\<infinity> \<in> A \<Longrightarrow> {ereal x<..} \<subseteq> A"
    and "-\<infinity> \<in> A \<Longrightarrow> {..<ereal y} \<subseteq> A"
  using assms open_ereal_def by auto

lemmas open_ereal_lessThan = open_lessThan[where 'a=ereal]
lemmas open_ereal_greaterThan = open_greaterThan[where 'a=ereal]
lemmas ereal_open_greaterThanLessThan = open_greaterThanLessThan[where 'a=ereal]
lemmas closed_ereal_atLeast = closed_atLeast[where 'a=ereal]
lemmas closed_ereal_atMost = closed_atMost[where 'a=ereal]
lemmas closed_ereal_atLeastAtMost = closed_atLeastAtMost[where 'a=ereal]
lemmas closed_ereal_singleton = closed_singleton[where 'a=ereal]

lemma ereal_open_cont_interval:
  fixes S :: "ereal set"
  assumes "open S"
    and "x \<in> S"
    and "\<bar>x\<bar> \<noteq> \<infinity>"
  obtains e where "e > 0" and "{x-e <..< x+e} \<subseteq> S"
proof -
  from \<open>open S\<close>
  have "open (ereal -` S)"
    by (rule ereal_openE)
  then obtain e where "e > 0" and e: "\<And>y. dist y (real x) < e \<Longrightarrow> ereal y \<in> S"
    using assms unfolding open_dist by force
  show thesis
  proof (intro that subsetI)
    show "0 < ereal e"
      using \<open>0 < e\<close> by auto
    fix y
    assume "y \<in> {x - ereal e<..<x + ereal e}"
    with assms obtain t where "y = ereal t" "dist t (real x) < e"
      by (cases y) (auto simp: dist_real_def)
    then show "y \<in> S"
      using e[of t] by auto
  qed
qed

lemma ereal_open_cont_interval2:
  fixes S :: "ereal set"
  assumes "open S"
    and "x \<in> S"
    and x: "\<bar>x\<bar> \<noteq> \<infinity>"
  obtains a b where "a < x" and "x < b" and "{a <..< b} \<subseteq> S"
proof -
  obtain e where "0 < e" "{x - e<..<x + e} \<subseteq> S"
    using assms by (rule ereal_open_cont_interval)
  with that[of "x - e" "x + e"] ereal_between[OF x, of e]
  show thesis
    by auto
qed

subsubsection \<open>Convergent sequences\<close>

lemma lim_real_of_ereal[simp]:
  assumes lim: "(f ---> ereal x) net"
  shows "((\<lambda>x. real (f x)) ---> x) net"
proof (intro topological_tendstoI)
  fix S
  assume "open S" and "x \<in> S"
  then have S: "open S" "ereal x \<in> ereal ` S"
    by (simp_all add: inj_image_mem_iff)
  have "\<forall>x. f x \<in> ereal ` S \<longrightarrow> real (f x) \<in> S"
    by auto
  from this lim[THEN topological_tendstoD, OF open_ereal, OF S]
  show "eventually (\<lambda>x. real (f x) \<in> S) net"
    by (rule eventually_mono)
qed

lemma lim_ereal[simp]: "((\<lambda>n. ereal (f n)) ---> ereal x) net \<longleftrightarrow> (f ---> x) net"
  by (auto dest!: lim_real_of_ereal)

lemma tendsto_PInfty: "(f ---> \<infinity>) F \<longleftrightarrow> (\<forall>r. eventually (\<lambda>x. ereal r < f x) F)"
proof -
  {
    fix l :: ereal
    assume "\<forall>r. eventually (\<lambda>x. ereal r < f x) F"
    from this[THEN spec, of "real l"] have "l \<noteq> \<infinity> \<Longrightarrow> eventually (\<lambda>x. l < f x) F"
      by (cases l) (auto elim: eventually_elim1)
  }
  then show ?thesis
    by (auto simp: order_tendsto_iff)
qed

lemma tendsto_PInfty_eq_at_top:
  "((\<lambda>z. ereal (f z)) ---> \<infinity>) F \<longleftrightarrow> (LIM z F. f z :> at_top)"
  unfolding tendsto_PInfty filterlim_at_top_dense by simp

lemma tendsto_MInfty: "(f ---> -\<infinity>) F \<longleftrightarrow> (\<forall>r. eventually (\<lambda>x. f x < ereal r) F)"
  unfolding tendsto_def
proof safe
  fix S :: "ereal set"
  assume "open S" "-\<infinity> \<in> S"
  from open_MInfty[OF this] obtain B where "{..<ereal B} \<subseteq> S" ..
  moreover
  assume "\<forall>r::real. eventually (\<lambda>z. f z < r) F"
  then have "eventually (\<lambda>z. f z \<in> {..< B}) F"
    by auto
  ultimately show "eventually (\<lambda>z. f z \<in> S) F"
    by (auto elim!: eventually_elim1)
next
  fix x
  assume "\<forall>S. open S \<longrightarrow> -\<infinity> \<in> S \<longrightarrow> eventually (\<lambda>x. f x \<in> S) F"
  from this[rule_format, of "{..< ereal x}"] show "eventually (\<lambda>y. f y < ereal x) F"
    by auto
qed

lemma Lim_PInfty: "f ----> \<infinity> \<longleftrightarrow> (\<forall>B. \<exists>N. \<forall>n\<ge>N. f n \<ge> ereal B)"
  unfolding tendsto_PInfty eventually_sequentially
proof safe
  fix r
  assume "\<forall>r. \<exists>N. \<forall>n\<ge>N. ereal r \<le> f n"
  then obtain N where "\<forall>n\<ge>N. ereal (r + 1) \<le> f n"
    by blast
  moreover have "ereal r < ereal (r + 1)"
    by auto
  ultimately show "\<exists>N. \<forall>n\<ge>N. ereal r < f n"
    by (blast intro: less_le_trans)
qed (blast intro: less_imp_le)

lemma Lim_MInfty: "f ----> -\<infinity> \<longleftrightarrow> (\<forall>B. \<exists>N. \<forall>n\<ge>N. ereal B \<ge> f n)"
  unfolding tendsto_MInfty eventually_sequentially
proof safe
  fix r
  assume "\<forall>r. \<exists>N. \<forall>n\<ge>N. f n \<le> ereal r"
  then obtain N where "\<forall>n\<ge>N. f n \<le> ereal (r - 1)"
    by blast
  moreover have "ereal (r - 1) < ereal r"
    by auto
  ultimately show "\<exists>N. \<forall>n\<ge>N. f n < ereal r"
    by (blast intro: le_less_trans)
qed (blast intro: less_imp_le)

lemma Lim_bounded_PInfty: "f ----> l \<Longrightarrow> (\<And>n. f n \<le> ereal B) \<Longrightarrow> l \<noteq> \<infinity>"
  using LIMSEQ_le_const2[of f l "ereal B"] by auto

lemma Lim_bounded_MInfty: "f ----> l \<Longrightarrow> (\<And>n. ereal B \<le> f n) \<Longrightarrow> l \<noteq> -\<infinity>"
  using LIMSEQ_le_const[of f l "ereal B"] by auto

lemma tendsto_explicit:
  "f ----> f0 \<longleftrightarrow> (\<forall>S. open S \<longrightarrow> f0 \<in> S \<longrightarrow> (\<exists>N. \<forall>n\<ge>N. f n \<in> S))"
  unfolding tendsto_def eventually_sequentially by auto

lemma Lim_bounded_PInfty2: "f ----> l \<Longrightarrow> \<forall>n\<ge>N. f n \<le> ereal B \<Longrightarrow> l \<noteq> \<infinity>"
  using LIMSEQ_le_const2[of f l "ereal B"] by fastforce

lemma Lim_bounded_ereal: "f ----> (l :: 'a::linorder_topology) \<Longrightarrow> \<forall>n\<ge>M. f n \<le> C \<Longrightarrow> l \<le> C"
  by (intro LIMSEQ_le_const2) auto

lemma Lim_bounded2_ereal:
  assumes lim:"f ----> (l :: 'a::linorder_topology)"
    and ge: "\<forall>n\<ge>N. f n \<ge> C"
  shows "l \<ge> C"
  using ge
  by (intro tendsto_le[OF trivial_limit_sequentially lim tendsto_const])
     (auto simp: eventually_sequentially)

lemma real_of_ereal_mult[simp]:
  fixes a b :: ereal
  shows "real (a * b) = real a * real b"
  by (cases rule: ereal2_cases[of a b]) auto

lemma real_of_ereal_eq_0:
  fixes x :: ereal
  shows "real x = 0 \<longleftrightarrow> x = \<infinity> \<or> x = -\<infinity> \<or> x = 0"
  by (cases x) auto

lemma tendsto_ereal_realD:
  fixes f :: "'a \<Rightarrow> ereal"
  assumes "x \<noteq> 0"
    and tendsto: "((\<lambda>x. ereal (real (f x))) ---> x) net"
  shows "(f ---> x) net"
proof (intro topological_tendstoI)
  fix S
  assume S: "open S" "x \<in> S"
  with \<open>x \<noteq> 0\<close> have "open (S - {0})" "x \<in> S - {0}"
    by auto
  from tendsto[THEN topological_tendstoD, OF this]
  show "eventually (\<lambda>x. f x \<in> S) net"
    by (rule eventually_rev_mp) (auto simp: ereal_real)
qed

lemma tendsto_ereal_realI:
  fixes f :: "'a \<Rightarrow> ereal"
  assumes x: "\<bar>x\<bar> \<noteq> \<infinity>" and tendsto: "(f ---> x) net"
  shows "((\<lambda>x. ereal (real (f x))) ---> x) net"
proof (intro topological_tendstoI)
  fix S
  assume "open S" and "x \<in> S"
  with x have "open (S - {\<infinity>, -\<infinity>})" "x \<in> S - {\<infinity>, -\<infinity>}"
    by auto
  from tendsto[THEN topological_tendstoD, OF this]
  show "eventually (\<lambda>x. ereal (real (f x)) \<in> S) net"
    by (elim eventually_elim1) (auto simp: ereal_real)
qed

lemma ereal_mult_cancel_left:
  fixes a b c :: ereal
  shows "a * b = a * c \<longleftrightarrow> (\<bar>a\<bar> = \<infinity> \<and> 0 < b * c) \<or> a = 0 \<or> b = c"
  by (cases rule: ereal3_cases[of a b c]) (simp_all add: zero_less_mult_iff)

lemma tendsto_add_ereal:
  fixes x y :: ereal
  assumes x: "\<bar>x\<bar> \<noteq> \<infinity>" and y: "\<bar>y\<bar> \<noteq> \<infinity>"
  assumes f: "(f ---> x) F" and g: "(g ---> y) F"
  shows "((\<lambda>x. f x + g x) ---> x + y) F"
proof -
  from x obtain r where x': "x = ereal r" by (cases x) auto
  with f have "((\<lambda>i. real (f i)) ---> r) F" by simp
  moreover
  from y obtain p where y': "y = ereal p" by (cases y) auto
  with g have "((\<lambda>i. real (g i)) ---> p) F" by simp
  ultimately have "((\<lambda>i. real (f i) + real (g i)) ---> r + p) F"
    by (rule tendsto_add)
  moreover
  from eventually_finite[OF x f] eventually_finite[OF y g]
  have "eventually (\<lambda>x. f x + g x = ereal (real (f x) + real (g x))) F"
    by eventually_elim auto
  ultimately show ?thesis
    by (simp add: x' y' cong: filterlim_cong)
qed

lemma ereal_inj_affinity:
  fixes m t :: ereal
  assumes "\<bar>m\<bar> \<noteq> \<infinity>"
    and "m \<noteq> 0"
    and "\<bar>t\<bar> \<noteq> \<infinity>"
  shows "inj_on (\<lambda>x. m * x + t) A"
  using assms
  by (cases rule: ereal2_cases[of m t])
     (auto intro!: inj_onI simp: ereal_add_cancel_right ereal_mult_cancel_left)

lemma ereal_PInfty_eq_plus[simp]:
  fixes a b :: ereal
  shows "\<infinity> = a + b \<longleftrightarrow> a = \<infinity> \<or> b = \<infinity>"
  by (cases rule: ereal2_cases[of a b]) auto

lemma ereal_MInfty_eq_plus[simp]:
  fixes a b :: ereal
  shows "-\<infinity> = a + b \<longleftrightarrow> (a = -\<infinity> \<and> b \<noteq> \<infinity>) \<or> (b = -\<infinity> \<and> a \<noteq> \<infinity>)"
  by (cases rule: ereal2_cases[of a b]) auto

lemma ereal_less_divide_pos:
  fixes x y :: ereal
  shows "x > 0 \<Longrightarrow> x \<noteq> \<infinity> \<Longrightarrow> y < z / x \<longleftrightarrow> x * y < z"
  by (cases rule: ereal3_cases[of x y z]) (auto simp: field_simps)

lemma ereal_divide_less_pos:
  fixes x y z :: ereal
  shows "x > 0 \<Longrightarrow> x \<noteq> \<infinity> \<Longrightarrow> y / x < z \<longleftrightarrow> y < x * z"
  by (cases rule: ereal3_cases[of x y z]) (auto simp: field_simps)

lemma ereal_divide_eq:
  fixes a b c :: ereal
  shows "b \<noteq> 0 \<Longrightarrow> \<bar>b\<bar> \<noteq> \<infinity> \<Longrightarrow> a / b = c \<longleftrightarrow> a = b * c"
  by (cases rule: ereal3_cases[of a b c])
     (simp_all add: field_simps)

lemma ereal_inverse_not_MInfty[simp]: "inverse (a::ereal) \<noteq> -\<infinity>"
  by (cases a) auto

lemma ereal_mult_m1[simp]: "x * ereal (-1) = -x"
  by (cases x) auto

lemma ereal_real':
  assumes "\<bar>x\<bar> \<noteq> \<infinity>"
  shows "ereal (real x) = x"
  using assms by auto

lemma real_ereal_id: "real \<circ> ereal = id"
proof -
  {
    fix x
    have "(real o ereal) x = id x"
      by auto
  }
  then show ?thesis
    using ext by blast
qed

lemma open_image_ereal: "open(UNIV-{ \<infinity> , (-\<infinity> :: ereal)})"
  by (metis range_ereal open_ereal open_UNIV)

lemma ereal_le_distrib:
  fixes a b c :: ereal
  shows "c * (a + b) \<le> c * a + c * b"
  by (cases rule: ereal3_cases[of a b c])
     (auto simp add: field_simps not_le mult_le_0_iff mult_less_0_iff)

lemma ereal_pos_distrib:
  fixes a b c :: ereal
  assumes "0 \<le> c"
    and "c \<noteq> \<infinity>"
  shows "c * (a + b) = c * a + c * b"
  using assms
  by (cases rule: ereal3_cases[of a b c])
    (auto simp add: field_simps not_le mult_le_0_iff mult_less_0_iff)

lemma ereal_max_mono: "(a::ereal) \<le> b \<Longrightarrow> c \<le> d \<Longrightarrow> max a c \<le> max b d"
  by (metis sup_ereal_def sup_mono)

lemma ereal_max_least: "(a::ereal) \<le> x \<Longrightarrow> c \<le> x \<Longrightarrow> max a c \<le> x"
  by (metis sup_ereal_def sup_least)

lemma ereal_LimI_finite:
  fixes x :: ereal
  assumes "\<bar>x\<bar> \<noteq> \<infinity>"
    and "\<And>r. 0 < r \<Longrightarrow> \<exists>N. \<forall>n\<ge>N. u n < x + r \<and> x < u n + r"
  shows "u ----> x"
proof (rule topological_tendstoI, unfold eventually_sequentially)
  obtain rx where rx: "x = ereal rx"
    using assms by (cases x) auto
  fix S
  assume "open S" and "x \<in> S"
  then have "open (ereal -` S)"
    unfolding open_ereal_def by auto
  with \<open>x \<in> S\<close> obtain r where "0 < r" and dist: "\<And>y. dist y rx < r \<Longrightarrow> ereal y \<in> S"
    unfolding open_real_def rx by auto
  then obtain n where
    upper: "\<And>N. n \<le> N \<Longrightarrow> u N < x + ereal r" and
    lower: "\<And>N. n \<le> N \<Longrightarrow> x < u N + ereal r"
    using assms(2)[of "ereal r"] by auto
  show "\<exists>N. \<forall>n\<ge>N. u n \<in> S"
  proof (safe intro!: exI[of _ n])
    fix N
    assume "n \<le> N"
    from upper[OF this] lower[OF this] assms \<open>0 < r\<close>
    have "u N \<notin> {\<infinity>,(-\<infinity>)}"
      by auto
    then obtain ra where ra_def: "(u N) = ereal ra"
      by (cases "u N") auto
    then have "rx < ra + r" and "ra < rx + r"
      using rx assms \<open>0 < r\<close> lower[OF \<open>n \<le> N\<close>] upper[OF \<open>n \<le> N\<close>]
      by auto
    then have "dist (real (u N)) rx < r"
      using rx ra_def
      by (auto simp: dist_real_def abs_diff_less_iff field_simps)
    from dist[OF this] show "u N \<in> S"
      using \<open>u N  \<notin> {\<infinity>, -\<infinity>}\<close>
      by (auto simp: ereal_real split: split_if_asm)
  qed
qed

lemma tendsto_obtains_N:
  assumes "f ----> f0"
  assumes "open S"
    and "f0 \<in> S"
  obtains N where "\<forall>n\<ge>N. f n \<in> S"
  using assms using tendsto_def
  using tendsto_explicit[of f f0] assms by auto

lemma ereal_LimI_finite_iff:
  fixes x :: ereal
  assumes "\<bar>x\<bar> \<noteq> \<infinity>"
  shows "u ----> x \<longleftrightarrow> (\<forall>r. 0 < r \<longrightarrow> (\<exists>N. \<forall>n\<ge>N. u n < x + r \<and> x < u n + r))"
  (is "?lhs \<longleftrightarrow> ?rhs")
proof
  assume lim: "u ----> x"
  {
    fix r :: ereal
    assume "r > 0"
    then obtain N where "\<forall>n\<ge>N. u n \<in> {x - r <..< x + r}"
       apply (subst tendsto_obtains_N[of u x "{x - r <..< x + r}"])
       using lim ereal_between[of x r] assms \<open>r > 0\<close>
       apply auto
       done
    then have "\<exists>N. \<forall>n\<ge>N. u n < x + r \<and> x < u n + r"
      using ereal_minus_less[of r x]
      by (cases r) auto
  }
  then show ?rhs
    by auto
next
  assume ?rhs
  then show "u ----> x"
    using ereal_LimI_finite[of x] assms by auto
qed

lemma ereal_Limsup_uminus:
  fixes f :: "'a \<Rightarrow> ereal"
  shows "Limsup net (\<lambda>x. - (f x)) = - Liminf net f"
  unfolding Limsup_def Liminf_def ereal_SUP_uminus ereal_INF_uminus_eq ..

lemma liminf_bounded_iff:
  fixes x :: "nat \<Rightarrow> ereal"
  shows "C \<le> liminf x \<longleftrightarrow> (\<forall>B<C. \<exists>N. \<forall>n\<ge>N. B < x n)"
  (is "?lhs \<longleftrightarrow> ?rhs")
  unfolding le_Liminf_iff eventually_sequentially ..

lemma Liminf_add_le:
  fixes f g :: "_ \<Rightarrow> ereal"
  assumes F: "F \<noteq> bot"
  assumes ev: "eventually (\<lambda>x. 0 \<le> f x) F" "eventually (\<lambda>x. 0 \<le> g x) F"
  shows "Liminf F f + Liminf F g \<le> Liminf F (\<lambda>x. f x + g x)"
  unfolding Liminf_def
proof (subst SUP_ereal_add_left[symmetric])
  let ?F = "{P. eventually P F}"
  let ?INF = "\<lambda>P g. INFIMUM (Collect P) g"
  show "?F \<noteq> {}"
    by (auto intro: eventually_True)
  show "(SUP P:?F. ?INF P g) \<noteq> - \<infinity>"
    unfolding bot_ereal_def[symmetric] SUP_bot_conv INF_eq_bot_iff
    by (auto intro!: exI[of _ 0] ev simp: bot_ereal_def)
  have "(SUP P:?F. ?INF P f + (SUP P:?F. ?INF P g)) \<le> (SUP P:?F. (SUP P':?F. ?INF P f + ?INF P' g))"
  proof (safe intro!: SUP_mono bexI[of _ "\<lambda>x. P x \<and> 0 \<le> f x" for P])
    fix P let ?P' = "\<lambda>x. P x \<and> 0 \<le> f x"
    assume "eventually P F"
    with ev show "eventually ?P' F"
      by eventually_elim auto
    have "?INF P f + (SUP P:?F. ?INF P g) \<le> ?INF ?P' f + (SUP P:?F. ?INF P g)"
      by (intro ereal_add_mono INF_mono) auto
    also have "\<dots> = (SUP P':?F. ?INF ?P' f + ?INF P' g)"
    proof (rule SUP_ereal_add_right[symmetric])
      show "INFIMUM {x. P x \<and> 0 \<le> f x} f \<noteq> - \<infinity>"
        unfolding bot_ereal_def[symmetric] INF_eq_bot_iff
        by (auto intro!: exI[of _ 0] ev simp: bot_ereal_def)
    qed fact
    finally show "?INF P f + (SUP P:?F. ?INF P g) \<le> (SUP P':?F. ?INF ?P' f + ?INF P' g)" .
  qed
  also have "\<dots> \<le> (SUP P:?F. INF x:Collect P. f x + g x)"
  proof (safe intro!: SUP_least)
    fix P Q assume *: "eventually P F" "eventually Q F"
    show "?INF P f + ?INF Q g \<le> (SUP P:?F. INF x:Collect P. f x + g x)"
    proof (rule SUP_upper2)
      show "(\<lambda>x. P x \<and> Q x) \<in> ?F"
        using * by (auto simp: eventually_conj)
      show "?INF P f + ?INF Q g \<le> (INF x:{x. P x \<and> Q x}. f x + g x)"
        by (intro INF_greatest ereal_add_mono) (auto intro: INF_lower)
    qed
  qed
  finally show "(SUP P:?F. ?INF P f + (SUP P:?F. ?INF P g)) \<le> (SUP P:?F. INF x:Collect P. f x + g x)" .
qed

lemma Sup_ereal_mult_right':
  assumes nonempty: "Y \<noteq> {}"
  and x: "x \<ge> 0"
  shows "(SUP i:Y. f i) * ereal x = (SUP i:Y. f i * ereal x)" (is "?lhs = ?rhs")
proof(cases "x = 0")
  case True thus ?thesis by(auto simp add: nonempty zero_ereal_def[symmetric])
next
  case False
  show ?thesis
  proof(rule antisym)
    show "?rhs \<le> ?lhs"
      by(rule SUP_least)(simp add: ereal_mult_right_mono SUP_upper x)
  next
    have "?lhs / ereal x = (SUP i:Y. f i) * (ereal x / ereal x)" by(simp only: ereal_times_divide_eq)
    also have "\<dots> = (SUP i:Y. f i)" using False by simp
    also have "\<dots> \<le> ?rhs / x"
    proof(rule SUP_least)
      fix i
      assume "i \<in> Y"
      have "f i = f i * (ereal x / ereal x)" using False by simp
      also have "\<dots> = f i * x / x" by(simp only: ereal_times_divide_eq)
      also from \<open>i \<in> Y\<close> have "f i * x \<le> ?rhs" by(rule SUP_upper)
      hence "f i * x / x \<le> ?rhs / x" using x False by simp
      finally show "f i \<le> ?rhs / x" .
    qed
    finally have "(?lhs / x) * x \<le> (?rhs / x) * x"
      by(rule ereal_mult_right_mono)(simp add: x)
    also have "\<dots> = ?rhs" using False ereal_divide_eq mult.commute by force
    also have "(?lhs / x) * x = ?lhs" using False ereal_divide_eq mult.commute by force
    finally show "?lhs \<le> ?rhs" .
  qed
qed

lemma sup_continuous_add[order_continuous_intros]:
  fixes f g :: "'a::complete_lattice \<Rightarrow> ereal"
  assumes nn: "\<And>x. 0 \<le> f x" "\<And>x. 0 \<le> g x" and cont: "sup_continuous f" "sup_continuous g"
  shows "sup_continuous (\<lambda>x. f x + g x)"
  unfolding sup_continuous_def
proof safe
  fix M :: "nat \<Rightarrow> 'a" assume "incseq M"
  then show "f (SUP i. M i) + g (SUP i. M i) = (SUP i. f (M i) + g (M i))"
    using SUP_ereal_add_pos[of "\<lambda>i. f (M i)" "\<lambda>i. g (M i)"] nn
      cont[THEN sup_continuous_mono] cont[THEN sup_continuousD]
    by (auto simp: mono_def)
qed

lemma sup_continuous_mult_right[order_continuous_intros]:
  "0 \<le> c \<Longrightarrow> c < \<infinity> \<Longrightarrow> sup_continuous f \<Longrightarrow> sup_continuous (\<lambda>x. f x * c :: ereal)"
  by (cases c) (auto simp: sup_continuous_def fun_eq_iff Sup_ereal_mult_right')

lemma sup_continuous_mult_left[order_continuous_intros]:
  "0 \<le> c \<Longrightarrow> c < \<infinity> \<Longrightarrow> sup_continuous f \<Longrightarrow> sup_continuous (\<lambda>x. c * f x :: ereal)"
  using sup_continuous_mult_right[of c f] by (simp add: mult_ac)

lemma sup_continuous_ereal_of_enat[order_continuous_intros]:
  assumes f: "sup_continuous f" shows "sup_continuous (\<lambda>x. ereal_of_enat (f x))"
  by (rule sup_continuous_compose[OF _ f])
     (auto simp: sup_continuous_def ereal_of_enat_SUP)

subsubsection \<open>Sums\<close>

lemma sums_ereal_positive:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "\<And>i. 0 \<le> f i"
  shows "f sums (SUP n. \<Sum>i<n. f i)"
proof -
  have "incseq (\<lambda>i. \<Sum>j=0..<i. f j)"
    using ereal_add_mono[OF _ assms]
    by (auto intro!: incseq_SucI)
  from LIMSEQ_SUP[OF this]
  show ?thesis unfolding sums_def
    by (simp add: atLeast0LessThan)
qed

lemma summable_ereal_pos:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "\<And>i. 0 \<le> f i"
  shows "summable f"
  using sums_ereal_positive[of f, OF assms]
  unfolding summable_def
  by auto

lemma sums_ereal: "(\<lambda>x. ereal (f x)) sums ereal x \<longleftrightarrow> f sums x"
  unfolding sums_def by simp

lemma suminf_ereal_eq_SUP:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "\<And>i. 0 \<le> f i"
  shows "(\<Sum>x. f x) = (SUP n. \<Sum>i<n. f i)"
  using sums_ereal_positive[of f, OF assms, THEN sums_unique]
  by simp

lemma suminf_bound:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "\<forall>N. (\<Sum>n<N. f n) \<le> x"
    and pos: "\<And>n. 0 \<le> f n"
  shows "suminf f \<le> x"
proof (rule Lim_bounded_ereal)
  have "summable f" using pos[THEN summable_ereal_pos] .
  then show "(\<lambda>N. \<Sum>n<N. f n) ----> suminf f"
    by (auto dest!: summable_sums simp: sums_def atLeast0LessThan)
  show "\<forall>n\<ge>0. setsum f {..<n} \<le> x"
    using assms by auto
qed

lemma suminf_bound_add:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "\<forall>N. (\<Sum>n<N. f n) + y \<le> x"
    and pos: "\<And>n. 0 \<le> f n"
    and "y \<noteq> -\<infinity>"
  shows "suminf f + y \<le> x"
proof (cases y)
  case (real r)
  then have "\<forall>N. (\<Sum>n<N. f n) \<le> x - y"
    using assms by (simp add: ereal_le_minus)
  then have "(\<Sum> n. f n) \<le> x - y"
    using pos by (rule suminf_bound)
  then show "(\<Sum> n. f n) + y \<le> x"
    using assms real by (simp add: ereal_le_minus)
qed (insert assms, auto)

lemma suminf_upper:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "\<And>n. 0 \<le> f n"
  shows "(\<Sum>n<N. f n) \<le> (\<Sum>n. f n)"
  unfolding suminf_ereal_eq_SUP [OF assms]
  by (auto intro: complete_lattice_class.SUP_upper)

lemma suminf_0_le:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "\<And>n. 0 \<le> f n"
  shows "0 \<le> (\<Sum>n. f n)"
  using suminf_upper[of f 0, OF assms]
  by simp

lemma suminf_le_pos:
  fixes f g :: "nat \<Rightarrow> ereal"
  assumes "\<And>N. f N \<le> g N"
    and "\<And>N. 0 \<le> f N"
  shows "suminf f \<le> suminf g"
proof (safe intro!: suminf_bound)
  fix n
  {
    fix N
    have "0 \<le> g N"
      using assms(2,1)[of N] by auto
  }
  have "setsum f {..<n} \<le> setsum g {..<n}"
    using assms by (auto intro: setsum_mono)
  also have "\<dots> \<le> suminf g"
    using \<open>\<And>N. 0 \<le> g N\<close>
    by (rule suminf_upper)
  finally show "setsum f {..<n} \<le> suminf g" .
qed (rule assms(2))

lemma suminf_half_series_ereal: "(\<Sum>n. (1/2 :: ereal) ^ Suc n) = 1"
  using sums_ereal[THEN iffD2, OF power_half_series, THEN sums_unique, symmetric]
  by (simp add: one_ereal_def)

lemma suminf_add_ereal:
  fixes f g :: "nat \<Rightarrow> ereal"
  assumes "\<And>i. 0 \<le> f i"
    and "\<And>i. 0 \<le> g i"
  shows "(\<Sum>i. f i + g i) = suminf f + suminf g"
  apply (subst (1 2 3) suminf_ereal_eq_SUP)
  unfolding setsum.distrib
  apply (intro assms ereal_add_nonneg_nonneg SUP_ereal_add_pos incseq_setsumI setsum_nonneg ballI)+
  done

lemma suminf_cmult_ereal:
  fixes f g :: "nat \<Rightarrow> ereal"
  assumes "\<And>i. 0 \<le> f i"
    and "0 \<le> a"
  shows "(\<Sum>i. a * f i) = a * suminf f"
  by (auto simp: setsum_ereal_right_distrib[symmetric] assms
       ereal_zero_le_0_iff setsum_nonneg suminf_ereal_eq_SUP
       intro!: SUP_ereal_mult_left)

lemma suminf_PInfty:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "\<And>i. 0 \<le> f i"
    and "suminf f \<noteq> \<infinity>"
  shows "f i \<noteq> \<infinity>"
proof -
  from suminf_upper[of f "Suc i", OF assms(1)] assms(2)
  have "(\<Sum>i<Suc i. f i) \<noteq> \<infinity>"
    by auto
  then show ?thesis
    unfolding setsum_Pinfty by simp
qed

lemma suminf_PInfty_fun:
  assumes "\<And>i. 0 \<le> f i"
    and "suminf f \<noteq> \<infinity>"
  shows "\<exists>f'. f = (\<lambda>x. ereal (f' x))"
proof -
  have "\<forall>i. \<exists>r. f i = ereal r"
  proof
    fix i
    show "\<exists>r. f i = ereal r"
      using suminf_PInfty[OF assms] assms(1)[of i]
      by (cases "f i") auto
  qed
  from choice[OF this] show ?thesis
    by auto
qed

lemma summable_ereal:
  assumes "\<And>i. 0 \<le> f i"
    and "(\<Sum>i. ereal (f i)) \<noteq> \<infinity>"
  shows "summable f"
proof -
  have "0 \<le> (\<Sum>i. ereal (f i))"
    using assms by (intro suminf_0_le) auto
  with assms obtain r where r: "(\<Sum>i. ereal (f i)) = ereal r"
    by (cases "\<Sum>i. ereal (f i)") auto
  from summable_ereal_pos[of "\<lambda>x. ereal (f x)"]
  have "summable (\<lambda>x. ereal (f x))"
    using assms by auto
  from summable_sums[OF this]
  have "(\<lambda>x. ereal (f x)) sums (\<Sum>x. ereal (f x))"
    by auto
  then show "summable f"
    unfolding r sums_ereal summable_def ..
qed

lemma suminf_ereal:
  assumes "\<And>i. 0 \<le> f i"
    and "(\<Sum>i. ereal (f i)) \<noteq> \<infinity>"
  shows "(\<Sum>i. ereal (f i)) = ereal (suminf f)"
proof (rule sums_unique[symmetric])
  from summable_ereal[OF assms]
  show "(\<lambda>x. ereal (f x)) sums (ereal (suminf f))"
    unfolding sums_ereal
    using assms
    by (intro summable_sums summable_ereal)
qed

lemma suminf_ereal_minus:
  fixes f g :: "nat \<Rightarrow> ereal"
  assumes ord: "\<And>i. g i \<le> f i" "\<And>i. 0 \<le> g i"
    and fin: "suminf f \<noteq> \<infinity>" "suminf g \<noteq> \<infinity>"
  shows "(\<Sum>i. f i - g i) = suminf f - suminf g"
proof -
  {
    fix i
    have "0 \<le> f i"
      using ord[of i] by auto
  }
  moreover
  from suminf_PInfty_fun[OF \<open>\<And>i. 0 \<le> f i\<close> fin(1)] obtain f' where [simp]: "f = (\<lambda>x. ereal (f' x))" ..
  from suminf_PInfty_fun[OF \<open>\<And>i. 0 \<le> g i\<close> fin(2)] obtain g' where [simp]: "g = (\<lambda>x. ereal (g' x))" ..
  {
    fix i
    have "0 \<le> f i - g i"
      using ord[of i] by (auto simp: ereal_le_minus_iff)
  }
  moreover
  have "suminf (\<lambda>i. f i - g i) \<le> suminf f"
    using assms by (auto intro!: suminf_le_pos simp: field_simps)
  then have "suminf (\<lambda>i. f i - g i) \<noteq> \<infinity>"
    using fin by auto
  ultimately show ?thesis
    using assms \<open>\<And>i. 0 \<le> f i\<close>
    apply simp
    apply (subst (1 2 3) suminf_ereal)
    apply (auto intro!: suminf_diff[symmetric] summable_ereal)
    done
qed

lemma suminf_ereal_PInf [simp]: "(\<Sum>x. \<infinity>::ereal) = \<infinity>"
proof -
  have "(\<Sum>i<Suc 0. \<infinity>) \<le> (\<Sum>x. \<infinity>::ereal)"
    by (rule suminf_upper) auto
  then show ?thesis
    by simp
qed

lemma summable_real_of_ereal:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes f: "\<And>i. 0 \<le> f i"
    and fin: "(\<Sum>i. f i) \<noteq> \<infinity>"
  shows "summable (\<lambda>i. real (f i))"
proof (rule summable_def[THEN iffD2])
  have "0 \<le> (\<Sum>i. f i)"
    using assms by (auto intro: suminf_0_le)
  with fin obtain r where r: "ereal r = (\<Sum>i. f i)"
    by (cases "(\<Sum>i. f i)") auto
  {
    fix i
    have "f i \<noteq> \<infinity>"
      using f by (intro suminf_PInfty[OF _ fin]) auto
    then have "\<bar>f i\<bar> \<noteq> \<infinity>"
      using f[of i] by auto
  }
  note fin = this
  have "(\<lambda>i. ereal (real (f i))) sums (\<Sum>i. ereal (real (f i)))"
    using f
    by (auto intro!: summable_ereal_pos simp: ereal_le_real_iff zero_ereal_def)
  also have "\<dots> = ereal r"
    using fin r by (auto simp: ereal_real)
  finally show "\<exists>r. (\<lambda>i. real (f i)) sums r"
    by (auto simp: sums_ereal)
qed

lemma suminf_SUP_eq:
  fixes f :: "nat \<Rightarrow> nat \<Rightarrow> ereal"
  assumes "\<And>i. incseq (\<lambda>n. f n i)"
    and "\<And>n i. 0 \<le> f n i"
  shows "(\<Sum>i. SUP n. f n i) = (SUP n. \<Sum>i. f n i)"
proof -
  {
    fix n :: nat
    have "(\<Sum>i<n. SUP k. f k i) = (SUP k. \<Sum>i<n. f k i)"
      using assms
      by (auto intro!: SUP_ereal_setsum [symmetric])
  }
  note * = this
  show ?thesis
    using assms
    apply (subst (1 2) suminf_ereal_eq_SUP)
    unfolding *
    apply (auto intro!: SUP_upper2)
    apply (subst SUP_commute)
    apply rule
    done
qed

lemma suminf_setsum_ereal:
  fixes f :: "_ \<Rightarrow> _ \<Rightarrow> ereal"
  assumes nonneg: "\<And>i a. a \<in> A \<Longrightarrow> 0 \<le> f i a"
  shows "(\<Sum>i. \<Sum>a\<in>A. f i a) = (\<Sum>a\<in>A. \<Sum>i. f i a)"
proof (cases "finite A")
  case True
  then show ?thesis
    using nonneg
    by induct (simp_all add: suminf_add_ereal setsum_nonneg)
next
  case False
  then show ?thesis by simp
qed

lemma suminf_ereal_eq_0:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes nneg: "\<And>i. 0 \<le> f i"
  shows "(\<Sum>i. f i) = 0 \<longleftrightarrow> (\<forall>i. f i = 0)"
proof
  assume "(\<Sum>i. f i) = 0"
  {
    fix i
    assume "f i \<noteq> 0"
    with nneg have "0 < f i"
      by (auto simp: less_le)
    also have "f i = (\<Sum>j. if j = i then f i else 0)"
      by (subst suminf_finite[where N="{i}"]) auto
    also have "\<dots> \<le> (\<Sum>i. f i)"
      using nneg
      by (auto intro!: suminf_le_pos)
    finally have False
      using \<open>(\<Sum>i. f i) = 0\<close> by auto
  }
  then show "\<forall>i. f i = 0"
    by auto
qed simp

lemma suminf_ereal_offset_le:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes f: "\<And>i. 0 \<le> f i"
  shows "(\<Sum>i. f (i + k)) \<le> suminf f"
proof -
  have "(\<lambda>n. \<Sum>i<n. f (i + k)) ----> (\<Sum>i. f (i + k))"
    using summable_sums[OF summable_ereal_pos] by (simp add: sums_def atLeast0LessThan f)
  moreover have "(\<lambda>n. \<Sum>i<n. f i) ----> (\<Sum>i. f i)"
    using summable_sums[OF summable_ereal_pos] by (simp add: sums_def atLeast0LessThan f)
  then have "(\<lambda>n. \<Sum>i<n + k. f i) ----> (\<Sum>i. f i)"
    by (rule LIMSEQ_ignore_initial_segment)
  ultimately show ?thesis
  proof (rule LIMSEQ_le, safe intro!: exI[of _ k])
    fix n assume "k \<le> n"
    have "(\<Sum>i<n. f (i + k)) = (\<Sum>i<n. (f \<circ> (\<lambda>i. i + k)) i)"
      by simp
    also have "\<dots> = (\<Sum>i\<in>(\<lambda>i. i + k) ` {..<n}. f i)"
      by (subst setsum.reindex) auto
    also have "\<dots> \<le> setsum f {..<n + k}"
      by (intro setsum_mono3) (auto simp: f)
    finally show "(\<Sum>i<n. f (i + k)) \<le> setsum f {..<n + k}" .
  qed
qed

lemma sums_suminf_ereal: "f sums x \<Longrightarrow> (\<Sum>i. ereal (f i)) = ereal x"
  by (metis sums_ereal sums_unique)

lemma suminf_ereal': "summable f \<Longrightarrow> (\<Sum>i. ereal (f i)) = ereal (\<Sum>i. f i)"
  by (metis sums_ereal sums_unique summable_def)

lemma suminf_ereal_finite: "summable f \<Longrightarrow> (\<Sum>i. ereal (f i)) \<noteq> \<infinity>"
  by (auto simp: sums_ereal[symmetric] summable_def sums_unique[symmetric])

lemma suminf_ereal_finite_neg:
  assumes "summable f"
  shows "(\<Sum>x. ereal (f x)) \<noteq> -\<infinity>"
proof-
  from assms obtain x where "f sums x" by blast
  hence "(\<lambda>x. ereal (f x)) sums ereal x" by (simp add: sums_ereal)
  from sums_unique[OF this] have "(\<Sum>x. ereal (f x)) = ereal x" ..
  thus "(\<Sum>x. ereal (f x)) \<noteq> -\<infinity>" by simp_all
qed


lemma convergent_limsup_cl:
  fixes X :: "nat \<Rightarrow> 'a::{complete_linorder,linorder_topology}"
  shows "convergent X \<Longrightarrow> limsup X = lim X"
  by (auto simp: convergent_def limI lim_imp_Limsup)

lemma lim_increasing_cl:
  assumes "\<And>n m. n \<ge> m \<Longrightarrow> f n \<ge> f m"
  obtains l where "f ----> (l::'a::{complete_linorder,linorder_topology})"
proof
  show "f ----> (SUP n. f n)"
    using assms
    by (intro increasing_tendsto)
       (auto simp: SUP_upper eventually_sequentially less_SUP_iff intro: less_le_trans)
qed

lemma lim_decreasing_cl:
  assumes "\<And>n m. n \<ge> m \<Longrightarrow> f n \<le> f m"
  obtains l where "f ----> (l::'a::{complete_linorder,linorder_topology})"
proof
  show "f ----> (INF n. f n)"
    using assms
    by (intro decreasing_tendsto)
       (auto simp: INF_lower eventually_sequentially INF_less_iff intro: le_less_trans)
qed

lemma compact_complete_linorder:
  fixes X :: "nat \<Rightarrow> 'a::{complete_linorder,linorder_topology}"
  shows "\<exists>l r. subseq r \<and> (X \<circ> r) ----> l"
proof -
  obtain r where "subseq r" and mono: "monoseq (X \<circ> r)"
    using seq_monosub[of X]
    unfolding comp_def
    by auto
  then have "(\<forall>n m. m \<le> n \<longrightarrow> (X \<circ> r) m \<le> (X \<circ> r) n) \<or> (\<forall>n m. m \<le> n \<longrightarrow> (X \<circ> r) n \<le> (X \<circ> r) m)"
    by (auto simp add: monoseq_def)
  then obtain l where "(X \<circ> r) ----> l"
     using lim_increasing_cl[of "X \<circ> r"] lim_decreasing_cl[of "X \<circ> r"]
     by auto
  then show ?thesis
    using \<open>subseq r\<close> by auto
qed

lemma ereal_dense3:
  fixes x y :: ereal
  shows "x < y \<Longrightarrow> \<exists>r::rat. x < real_of_rat r \<and> real_of_rat r < y"
proof (cases x y rule: ereal2_cases, simp_all)
  fix r q :: real
  assume "r < q"
  from Rats_dense_in_real[OF this] show "\<exists>x. r < real_of_rat x \<and> real_of_rat x < q"
    by (fastforce simp: Rats_def)
next
  fix r :: real
  show "\<exists>x. r < real_of_rat x" "\<exists>x. real_of_rat x < r"
    using gt_ex[of r] lt_ex[of r] Rats_dense_in_real
    by (auto simp: Rats_def)
qed

lemma continuous_within_ereal[intro, simp]: "x \<in> A \<Longrightarrow> continuous (at x within A) ereal"
  using continuous_on_eq_continuous_within[of A ereal]
  by (auto intro: continuous_on_ereal continuous_on_id)

lemma ereal_open_uminus:
  fixes S :: "ereal set"
  assumes "open S"
  shows "open (uminus ` S)"
  using \<open>open S\<close>[unfolded open_generated_order]
proof induct
  have "range uminus = (UNIV :: ereal set)"
    by (auto simp: image_iff ereal_uminus_eq_reorder)
  then show "open (range uminus :: ereal set)"
    by simp
qed (auto simp add: image_Union image_Int)

lemma ereal_uminus_complement:
  fixes S :: "ereal set"
  shows "uminus ` (- S) = - uminus ` S"
  by (auto intro!: bij_image_Compl_eq surjI[of _ uminus] simp: bij_betw_def)

lemma ereal_closed_uminus:
  fixes S :: "ereal set"
  assumes "closed S"
  shows "closed (uminus ` S)"
  using assms
  unfolding closed_def ereal_uminus_complement[symmetric]
  by (rule ereal_open_uminus)

lemma ereal_open_affinity_pos:
  fixes S :: "ereal set"
  assumes "open S"
    and m: "m \<noteq> \<infinity>" "0 < m"
    and t: "\<bar>t\<bar> \<noteq> \<infinity>"
  shows "open ((\<lambda>x. m * x + t) ` S)"
proof -
  have "open ((\<lambda>x. inverse m * (x + -t)) -` S)"
    using m t
    apply (intro open_vimage \<open>open S\<close>)
    apply (intro continuous_at_imp_continuous_on ballI tendsto_cmult_ereal continuous_at[THEN iffD2]
                 tendsto_ident_at tendsto_add_left_ereal)
    apply auto
    done
  also have "(\<lambda>x. inverse m * (x + -t)) -` S = (\<lambda>x. (x - t) / m) -` S"
    using m t by (auto simp: divide_ereal_def mult.commute uminus_ereal.simps[symmetric] minus_ereal_def
                       simp del: uminus_ereal.simps)
  also have "(\<lambda>x. (x - t) / m) -` S = (\<lambda>x. m * x + t) ` S"
    using m t
    by (simp add: set_eq_iff image_iff)
       (metis abs_ereal_less0 abs_ereal_uminus ereal_divide_eq ereal_eq_minus ereal_minus(7,8)
              ereal_minus_less_minus ereal_mult_eq_PInfty ereal_uminus_uminus ereal_zero_mult)
  finally show ?thesis .
qed

lemma ereal_open_affinity:
  fixes S :: "ereal set"
  assumes "open S"
    and m: "\<bar>m\<bar> \<noteq> \<infinity>" "m \<noteq> 0"
    and t: "\<bar>t\<bar> \<noteq> \<infinity>"
  shows "open ((\<lambda>x. m * x + t) ` S)"
proof cases
  assume "0 < m"
  then show ?thesis
    using ereal_open_affinity_pos[OF \<open>open S\<close> _ _ t, of m] m
    by auto
next
  assume "\<not> 0 < m" then
  have "0 < -m"
    using \<open>m \<noteq> 0\<close>
    by (cases m) auto
  then have m: "-m \<noteq> \<infinity>" "0 < -m"
    using \<open>\<bar>m\<bar> \<noteq> \<infinity>\<close>
    by (auto simp: ereal_uminus_eq_reorder)
  from ereal_open_affinity_pos[OF ereal_open_uminus[OF \<open>open S\<close>] m t] show ?thesis
    unfolding image_image by simp
qed

lemma open_uminus_iff:
  fixes S :: "ereal set"
  shows "open (uminus ` S) \<longleftrightarrow> open S"
  using ereal_open_uminus[of S] ereal_open_uminus[of "uminus ` S"]
  by auto

lemma ereal_Liminf_uminus:
  fixes f :: "'a \<Rightarrow> ereal"
  shows "Liminf net (\<lambda>x. - (f x)) = - Limsup net f"
  using ereal_Limsup_uminus[of _ "(\<lambda>x. - (f x))"] by auto

lemma Liminf_PInfty:
  fixes f :: "'a \<Rightarrow> ereal"
  assumes "\<not> trivial_limit net"
  shows "(f ---> \<infinity>) net \<longleftrightarrow> Liminf net f = \<infinity>"
  unfolding tendsto_iff_Liminf_eq_Limsup[OF assms]
  using Liminf_le_Limsup[OF assms, of f]
  by auto

lemma Limsup_MInfty:
  fixes f :: "'a \<Rightarrow> ereal"
  assumes "\<not> trivial_limit net"
  shows "(f ---> -\<infinity>) net \<longleftrightarrow> Limsup net f = -\<infinity>"
  unfolding tendsto_iff_Liminf_eq_Limsup[OF assms]
  using Liminf_le_Limsup[OF assms, of f]
  by auto

lemma convergent_ereal:
  fixes X :: "nat \<Rightarrow> 'a :: {complete_linorder,linorder_topology}"
  shows "convergent X \<longleftrightarrow> limsup X = liminf X"
  using tendsto_iff_Liminf_eq_Limsup[of sequentially]
  by (auto simp: convergent_def)

lemma limsup_le_liminf_real:
  fixes X :: "nat \<Rightarrow> real" and L :: real
  assumes 1: "limsup X \<le> L" and 2: "L \<le> liminf X"
  shows "X ----> L"
proof -
  from 1 2 have "limsup X \<le> liminf X" by auto
  hence 3: "limsup X = liminf X"  
    apply (subst eq_iff, rule conjI)
    by (rule Liminf_le_Limsup, auto)
  hence 4: "convergent (\<lambda>n. ereal (X n))"
    by (subst convergent_ereal)
  hence "limsup X = lim (\<lambda>n. ereal(X n))"
    by (rule convergent_limsup_cl)
  also from 1 2 3 have "limsup X = L" by auto
  finally have "lim (\<lambda>n. ereal(X n)) = L" ..
  hence "(\<lambda>n. ereal (X n)) ----> L"
    apply (elim subst)
    by (subst convergent_LIMSEQ_iff [symmetric], rule 4) 
  thus ?thesis by simp
qed

lemma liminf_PInfty:
  fixes X :: "nat \<Rightarrow> ereal"
  shows "X ----> \<infinity> \<longleftrightarrow> liminf X = \<infinity>"
  by (metis Liminf_PInfty trivial_limit_sequentially)

lemma limsup_MInfty:
  fixes X :: "nat \<Rightarrow> ereal"
  shows "X ----> -\<infinity> \<longleftrightarrow> limsup X = -\<infinity>"
  by (metis Limsup_MInfty trivial_limit_sequentially)

lemma ereal_lim_mono:
  fixes X Y :: "nat \<Rightarrow> 'a::linorder_topology"
  assumes "\<And>n. N \<le> n \<Longrightarrow> X n \<le> Y n"
    and "X ----> x"
    and "Y ----> y"
  shows "x \<le> y"
  using assms(1) by (intro LIMSEQ_le[OF assms(2,3)]) auto

lemma incseq_le_ereal:
  fixes X :: "nat \<Rightarrow> 'a::linorder_topology"
  assumes inc: "incseq X"
    and lim: "X ----> L"
  shows "X N \<le> L"
  using inc
  by (intro ereal_lim_mono[of N, OF _ tendsto_const lim]) (simp add: incseq_def)

lemma decseq_ge_ereal:
  assumes dec: "decseq X"
    and lim: "X ----> (L::'a::linorder_topology)"
  shows "X N \<ge> L"
  using dec by (intro ereal_lim_mono[of N, OF _ lim tendsto_const]) (simp add: decseq_def)

lemma bounded_abs:
  fixes a :: real
  assumes "a \<le> x"
    and "x \<le> b"
  shows "abs x \<le> max (abs a) (abs b)"
  by (metis abs_less_iff assms leI le_max_iff_disj
    less_eq_real_def less_le_not_le less_minus_iff minus_minus)

lemma ereal_Sup_lim:
  fixes a :: "'a::{complete_linorder,linorder_topology}"
  assumes "\<And>n. b n \<in> s"
    and "b ----> a"
  shows "a \<le> Sup s"
  by (metis Lim_bounded_ereal assms complete_lattice_class.Sup_upper)

lemma ereal_Inf_lim:
  fixes a :: "'a::{complete_linorder,linorder_topology}"
  assumes "\<And>n. b n \<in> s"
    and "b ----> a"
  shows "Inf s \<le> a"
  by (metis Lim_bounded2_ereal assms complete_lattice_class.Inf_lower)

lemma SUP_Lim_ereal:
  fixes X :: "nat \<Rightarrow> 'a::{complete_linorder,linorder_topology}"
  assumes inc: "incseq X"
    and l: "X ----> l"
  shows "(SUP n. X n) = l"
  using LIMSEQ_SUP[OF inc] tendsto_unique[OF trivial_limit_sequentially l]
  by simp

lemma INF_Lim_ereal:
  fixes X :: "nat \<Rightarrow> 'a::{complete_linorder,linorder_topology}"
  assumes dec: "decseq X"
    and l: "X ----> l"
  shows "(INF n. X n) = l"
  using LIMSEQ_INF[OF dec] tendsto_unique[OF trivial_limit_sequentially l]
  by simp

lemma SUP_eq_LIMSEQ:
  assumes "mono f"
  shows "(SUP n. ereal (f n)) = ereal x \<longleftrightarrow> f ----> x"
proof
  have inc: "incseq (\<lambda>i. ereal (f i))"
    using \<open>mono f\<close> unfolding mono_def incseq_def by auto
  {
    assume "f ----> x"
    then have "(\<lambda>i. ereal (f i)) ----> ereal x"
      by auto
    from SUP_Lim_ereal[OF inc this] show "(SUP n. ereal (f n)) = ereal x" .
  next
    assume "(SUP n. ereal (f n)) = ereal x"
    with LIMSEQ_SUP[OF inc] show "f ----> x" by auto
  }
qed

lemma liminf_ereal_cminus:
  fixes f :: "nat \<Rightarrow> ereal"
  assumes "c \<noteq> -\<infinity>"
  shows "liminf (\<lambda>x. c - f x) = c - limsup f"
proof (cases c)
  case PInf
  then show ?thesis
    by (simp add: Liminf_const)
next
  case (real r)
  then show ?thesis
    unfolding liminf_SUP_INF limsup_INF_SUP
    apply (subst INF_ereal_minus_right)
    apply auto
    apply (subst SUP_ereal_minus_right)
    apply auto
    done
qed (insert \<open>c \<noteq> -\<infinity>\<close>, simp)


subsubsection \<open>Continuity\<close>

lemma continuous_at_of_ereal:
  "\<bar>x0 :: ereal\<bar> \<noteq> \<infinity> \<Longrightarrow> continuous (at x0) real"
  unfolding continuous_at
  by (rule lim_real_of_ereal) (simp add: ereal_real)

lemma nhds_ereal: "nhds (ereal r) = filtermap ereal (nhds r)"
  by (simp add: filtermap_nhds_open_map open_ereal continuous_at_of_ereal)

lemma at_ereal: "at (ereal r) = filtermap ereal (at r)"
  by (simp add: filter_eq_iff eventually_at_filter nhds_ereal eventually_filtermap)

lemma at_left_ereal: "at_left (ereal r) = filtermap ereal (at_left r)"
  by (simp add: filter_eq_iff eventually_at_filter nhds_ereal eventually_filtermap)

lemma at_right_ereal: "at_right (ereal r) = filtermap ereal (at_right r)"
  by (simp add: filter_eq_iff eventually_at_filter nhds_ereal eventually_filtermap)

lemma
  shows at_left_PInf: "at_left \<infinity> = filtermap ereal at_top"
    and at_right_MInf: "at_right (-\<infinity>) = filtermap ereal at_bot"
  unfolding filter_eq_iff eventually_filtermap eventually_at_top_dense eventually_at_bot_dense
    eventually_at_left[OF ereal_less(5)] eventually_at_right[OF ereal_less(6)]
  by (auto simp add: ereal_all_split ereal_ex_split)

lemma ereal_tendsto_simps1:
  "((f \<circ> real) ---> y) (at_left (ereal x)) \<longleftrightarrow> (f ---> y) (at_left x)"
  "((f \<circ> real) ---> y) (at_right (ereal x)) \<longleftrightarrow> (f ---> y) (at_right x)"
  "((f \<circ> real) ---> y) (at_left (\<infinity>::ereal)) \<longleftrightarrow> (f ---> y) at_top"
  "((f \<circ> real) ---> y) (at_right (-\<infinity>::ereal)) \<longleftrightarrow> (f ---> y) at_bot"
  unfolding tendsto_compose_filtermap at_left_ereal at_right_ereal at_left_PInf at_right_MInf
  by (auto simp: filtermap_filtermap filtermap_ident)

lemma ereal_tendsto_simps2:
  "((ereal \<circ> f) ---> ereal a) F \<longleftrightarrow> (f ---> a) F"
  "((ereal \<circ> f) ---> \<infinity>) F \<longleftrightarrow> (LIM x F. f x :> at_top)"
  "((ereal \<circ> f) ---> -\<infinity>) F \<longleftrightarrow> (LIM x F. f x :> at_bot)"
  unfolding tendsto_PInfty filterlim_at_top_dense tendsto_MInfty filterlim_at_bot_dense
  using lim_ereal by (simp_all add: comp_def)

lemmas ereal_tendsto_simps = ereal_tendsto_simps1 ereal_tendsto_simps2

lemma continuous_at_iff_ereal:
  fixes f :: "'a::t2_space \<Rightarrow> real"
  shows "continuous (at x0 within s) f \<longleftrightarrow> continuous (at x0 within s) (ereal \<circ> f)"
  unfolding continuous_within comp_def lim_ereal ..

lemma continuous_on_iff_ereal:
  fixes f :: "'a::t2_space => real"
  assumes "open A"
  shows "continuous_on A f \<longleftrightarrow> continuous_on A (ereal \<circ> f)"
  unfolding continuous_on_def comp_def lim_ereal ..

lemma continuous_on_real: "continuous_on (UNIV - {\<infinity>, -\<infinity>::ereal}) real"
  using continuous_at_of_ereal continuous_on_eq_continuous_at open_image_ereal
  by auto

lemma continuous_on_iff_real:
  fixes f :: "'a::t2_space \<Rightarrow> ereal"
  assumes *: "\<And>x. x \<in> A \<Longrightarrow> \<bar>f x\<bar> \<noteq> \<infinity>"
  shows "continuous_on A f \<longleftrightarrow> continuous_on A (real \<circ> f)"
proof -
  have "f ` A \<subseteq> UNIV - {\<infinity>, -\<infinity>}"
    using assms by force
  then have *: "continuous_on (f ` A) real"
    using continuous_on_real by (simp add: continuous_on_subset)
  have **: "continuous_on ((real \<circ> f) ` A) ereal"
    by (intro continuous_on_ereal continuous_on_id)
  {
    assume "continuous_on A f"
    then have "continuous_on A (real \<circ> f)"
      apply (subst continuous_on_compose)
      using *
      apply auto
      done
  }
  moreover
  {
    assume "continuous_on A (real \<circ> f)"
    then have "continuous_on A (ereal \<circ> (real \<circ> f))"
      apply (subst continuous_on_compose)
      using **
      apply auto
      done
    then have "continuous_on A f"
      apply (subst continuous_on_cong[of _ A _ "ereal \<circ> (real \<circ> f)"])
      using assms ereal_real
      apply auto
      done
  }
  ultimately show ?thesis
    by auto
qed


subsubsection \<open>Tests for code generator\<close>

(* A small list of simple arithmetic expressions *)

value "- \<infinity> :: ereal"
value "\<bar>-\<infinity>\<bar> :: ereal"
value "4 + 5 / 4 - ereal 2 :: ereal"
value "ereal 3 < \<infinity>"
value "real (\<infinity>::ereal) = 0"

end

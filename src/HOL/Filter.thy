(*  Title:      HOL/Filter.thy
    Author:     Brian Huffman
    Author:     Johannes Hölzl
*)

section {* Filters on predicates *}

theory Filter
imports Set_Interval Lifting_Set
begin

subsection {* Filters *}

text {*
  This definition also allows non-proper filters.
*}

locale is_filter =
  fixes F :: "('a \<Rightarrow> bool) \<Rightarrow> bool"
  assumes True: "F (\<lambda>x. True)"
  assumes conj: "F (\<lambda>x. P x) \<Longrightarrow> F (\<lambda>x. Q x) \<Longrightarrow> F (\<lambda>x. P x \<and> Q x)"
  assumes mono: "\<forall>x. P x \<longrightarrow> Q x \<Longrightarrow> F (\<lambda>x. P x) \<Longrightarrow> F (\<lambda>x. Q x)"

typedef 'a filter = "{F :: ('a \<Rightarrow> bool) \<Rightarrow> bool. is_filter F}"
proof
  show "(\<lambda>x. True) \<in> ?filter" by (auto intro: is_filter.intro)
qed

lemma is_filter_Rep_filter: "is_filter (Rep_filter F)"
  using Rep_filter [of F] by simp

lemma Abs_filter_inverse':
  assumes "is_filter F" shows "Rep_filter (Abs_filter F) = F"
  using assms by (simp add: Abs_filter_inverse)


subsubsection {* Eventually *}

definition eventually :: "('a \<Rightarrow> bool) \<Rightarrow> 'a filter \<Rightarrow> bool"
  where "eventually P F \<longleftrightarrow> Rep_filter F P"

lemma eventually_Abs_filter:
  assumes "is_filter F" shows "eventually P (Abs_filter F) = F P"
  unfolding eventually_def using assms by (simp add: Abs_filter_inverse)

lemma filter_eq_iff:
  shows "F = F' \<longleftrightarrow> (\<forall>P. eventually P F = eventually P F')"
  unfolding Rep_filter_inject [symmetric] fun_eq_iff eventually_def ..

lemma eventually_True [simp]: "eventually (\<lambda>x. True) F"
  unfolding eventually_def
  by (rule is_filter.True [OF is_filter_Rep_filter])

lemma always_eventually: "\<forall>x. P x \<Longrightarrow> eventually P F"
proof -
  assume "\<forall>x. P x" hence "P = (\<lambda>x. True)" by (simp add: ext)
  thus "eventually P F" by simp
qed

lemma eventually_mono:
  "(\<forall>x. P x \<longrightarrow> Q x) \<Longrightarrow> eventually P F \<Longrightarrow> eventually Q F"
  unfolding eventually_def
  by (rule is_filter.mono [OF is_filter_Rep_filter])

lemma eventually_conj:
  assumes P: "eventually (\<lambda>x. P x) F"
  assumes Q: "eventually (\<lambda>x. Q x) F"
  shows "eventually (\<lambda>x. P x \<and> Q x) F"
  using assms unfolding eventually_def
  by (rule is_filter.conj [OF is_filter_Rep_filter])

lemma eventually_Ball_finite:
  assumes "finite A" and "\<forall>y\<in>A. eventually (\<lambda>x. P x y) net"
  shows "eventually (\<lambda>x. \<forall>y\<in>A. P x y) net"
using assms by (induct set: finite, simp, simp add: eventually_conj)

lemma eventually_all_finite:
  fixes P :: "'a \<Rightarrow> 'b::finite \<Rightarrow> bool"
  assumes "\<And>y. eventually (\<lambda>x. P x y) net"
  shows "eventually (\<lambda>x. \<forall>y. P x y) net"
using eventually_Ball_finite [of UNIV P] assms by simp

lemma eventually_mp:
  assumes "eventually (\<lambda>x. P x \<longrightarrow> Q x) F"
  assumes "eventually (\<lambda>x. P x) F"
  shows "eventually (\<lambda>x. Q x) F"
proof (rule eventually_mono)
  show "\<forall>x. (P x \<longrightarrow> Q x) \<and> P x \<longrightarrow> Q x" by simp
  show "eventually (\<lambda>x. (P x \<longrightarrow> Q x) \<and> P x) F"
    using assms by (rule eventually_conj)
qed

lemma eventually_rev_mp:
  assumes "eventually (\<lambda>x. P x) F"
  assumes "eventually (\<lambda>x. P x \<longrightarrow> Q x) F"
  shows "eventually (\<lambda>x. Q x) F"
using assms(2) assms(1) by (rule eventually_mp)

lemma eventually_conj_iff:
  "eventually (\<lambda>x. P x \<and> Q x) F \<longleftrightarrow> eventually P F \<and> eventually Q F"
  by (auto intro: eventually_conj elim: eventually_rev_mp)

lemma eventually_elim1:
  assumes "eventually (\<lambda>i. P i) F"
  assumes "\<And>i. P i \<Longrightarrow> Q i"
  shows "eventually (\<lambda>i. Q i) F"
  using assms by (auto elim!: eventually_rev_mp)

lemma eventually_elim2:
  assumes "eventually (\<lambda>i. P i) F"
  assumes "eventually (\<lambda>i. Q i) F"
  assumes "\<And>i. P i \<Longrightarrow> Q i \<Longrightarrow> R i"
  shows "eventually (\<lambda>i. R i) F"
  using assms by (auto elim!: eventually_rev_mp)

lemma not_eventually_impI: "eventually P F \<Longrightarrow> \<not> eventually Q F \<Longrightarrow> \<not> eventually (\<lambda>x. P x \<longrightarrow> Q x) F"
  by (auto intro: eventually_mp)

lemma not_eventuallyD: "\<not> eventually P F \<Longrightarrow> \<exists>x. \<not> P x"
  by (metis always_eventually)

lemma eventually_subst:
  assumes "eventually (\<lambda>n. P n = Q n) F"
  shows "eventually P F = eventually Q F" (is "?L = ?R")
proof -
  from assms have "eventually (\<lambda>x. P x \<longrightarrow> Q x) F"
      and "eventually (\<lambda>x. Q x \<longrightarrow> P x) F"
    by (auto elim: eventually_elim1)
  then show ?thesis by (auto elim: eventually_elim2)
qed

ML {*
  fun eventually_elim_tac ctxt facts = SUBGOAL_CASES (fn (goal, i) =>
    let
      val mp_thms = facts RL @{thms eventually_rev_mp}
      val raw_elim_thm =
        (@{thm allI} RS @{thm always_eventually})
        |> fold (fn thm1 => fn thm2 => thm2 RS thm1) mp_thms
        |> fold (fn _ => fn thm => @{thm impI} RS thm) facts
      val cases_prop = Thm.prop_of (raw_elim_thm RS Goal.init (Thm.cterm_of ctxt goal))
      val cases = Rule_Cases.make_common ctxt cases_prop [(("elim", []), [])]
    in
      CASES cases (rtac raw_elim_thm i)
    end)
*}

method_setup eventually_elim = {*
  Scan.succeed (fn ctxt => METHOD_CASES (HEADGOAL o eventually_elim_tac ctxt))
*} "elimination of eventually quantifiers"


subsubsection {* Finer-than relation *}

text {* @{term "F \<le> F'"} means that filter @{term F} is finer than
filter @{term F'}. *}

instantiation filter :: (type) complete_lattice
begin

definition le_filter_def:
  "F \<le> F' \<longleftrightarrow> (\<forall>P. eventually P F' \<longrightarrow> eventually P F)"

definition
  "(F :: 'a filter) < F' \<longleftrightarrow> F \<le> F' \<and> \<not> F' \<le> F"

definition
  "top = Abs_filter (\<lambda>P. \<forall>x. P x)"

definition
  "bot = Abs_filter (\<lambda>P. True)"

definition
  "sup F F' = Abs_filter (\<lambda>P. eventually P F \<and> eventually P F')"

definition
  "inf F F' = Abs_filter
      (\<lambda>P. \<exists>Q R. eventually Q F \<and> eventually R F' \<and> (\<forall>x. Q x \<and> R x \<longrightarrow> P x))"

definition
  "Sup S = Abs_filter (\<lambda>P. \<forall>F\<in>S. eventually P F)"

definition
  "Inf S = Sup {F::'a filter. \<forall>F'\<in>S. F \<le> F'}"

lemma eventually_top [simp]: "eventually P top \<longleftrightarrow> (\<forall>x. P x)"
  unfolding top_filter_def
  by (rule eventually_Abs_filter, rule is_filter.intro, auto)

lemma eventually_bot [simp]: "eventually P bot"
  unfolding bot_filter_def
  by (subst eventually_Abs_filter, rule is_filter.intro, auto)

lemma eventually_sup:
  "eventually P (sup F F') \<longleftrightarrow> eventually P F \<and> eventually P F'"
  unfolding sup_filter_def
  by (rule eventually_Abs_filter, rule is_filter.intro)
     (auto elim!: eventually_rev_mp)

lemma eventually_inf:
  "eventually P (inf F F') \<longleftrightarrow>
   (\<exists>Q R. eventually Q F \<and> eventually R F' \<and> (\<forall>x. Q x \<and> R x \<longrightarrow> P x))"
  unfolding inf_filter_def
  apply (rule eventually_Abs_filter, rule is_filter.intro)
  apply (fast intro: eventually_True)
  apply clarify
  apply (intro exI conjI)
  apply (erule (1) eventually_conj)
  apply (erule (1) eventually_conj)
  apply simp
  apply auto
  done

lemma eventually_Sup:
  "eventually P (Sup S) \<longleftrightarrow> (\<forall>F\<in>S. eventually P F)"
  unfolding Sup_filter_def
  apply (rule eventually_Abs_filter, rule is_filter.intro)
  apply (auto intro: eventually_conj elim!: eventually_rev_mp)
  done

instance proof
  fix F F' F'' :: "'a filter" and S :: "'a filter set"
  { show "F < F' \<longleftrightarrow> F \<le> F' \<and> \<not> F' \<le> F"
    by (rule less_filter_def) }
  { show "F \<le> F"
    unfolding le_filter_def by simp }
  { assume "F \<le> F'" and "F' \<le> F''" thus "F \<le> F''"
    unfolding le_filter_def by simp }
  { assume "F \<le> F'" and "F' \<le> F" thus "F = F'"
    unfolding le_filter_def filter_eq_iff by fast }
  { show "inf F F' \<le> F" and "inf F F' \<le> F'"
    unfolding le_filter_def eventually_inf by (auto intro: eventually_True) }
  { assume "F \<le> F'" and "F \<le> F''" thus "F \<le> inf F' F''"
    unfolding le_filter_def eventually_inf
    by (auto elim!: eventually_mono intro: eventually_conj) }
  { show "F \<le> sup F F'" and "F' \<le> sup F F'"
    unfolding le_filter_def eventually_sup by simp_all }
  { assume "F \<le> F''" and "F' \<le> F''" thus "sup F F' \<le> F''"
    unfolding le_filter_def eventually_sup by simp }
  { assume "F'' \<in> S" thus "Inf S \<le> F''"
    unfolding le_filter_def Inf_filter_def eventually_Sup Ball_def by simp }
  { assume "\<And>F'. F' \<in> S \<Longrightarrow> F \<le> F'" thus "F \<le> Inf S"
    unfolding le_filter_def Inf_filter_def eventually_Sup Ball_def by simp }
  { assume "F \<in> S" thus "F \<le> Sup S"
    unfolding le_filter_def eventually_Sup by simp }
  { assume "\<And>F. F \<in> S \<Longrightarrow> F \<le> F'" thus "Sup S \<le> F'"
    unfolding le_filter_def eventually_Sup by simp }
  { show "Inf {} = (top::'a filter)"
    by (auto simp: top_filter_def Inf_filter_def Sup_filter_def)
      (metis (full_types) top_filter_def always_eventually eventually_top) }
  { show "Sup {} = (bot::'a filter)"
    by (auto simp: bot_filter_def Sup_filter_def) }
qed

end

lemma filter_leD:
  "F \<le> F' \<Longrightarrow> eventually P F' \<Longrightarrow> eventually P F"
  unfolding le_filter_def by simp

lemma filter_leI:
  "(\<And>P. eventually P F' \<Longrightarrow> eventually P F) \<Longrightarrow> F \<le> F'"
  unfolding le_filter_def by simp

lemma eventually_False:
  "eventually (\<lambda>x. False) F \<longleftrightarrow> F = bot"
  unfolding filter_eq_iff by (auto elim: eventually_rev_mp)

abbreviation (input) trivial_limit :: "'a filter \<Rightarrow> bool"
  where "trivial_limit F \<equiv> F = bot"

lemma trivial_limit_def: "trivial_limit F \<longleftrightarrow> eventually (\<lambda>x. False) F"
  by (rule eventually_False [symmetric])

lemma eventually_const: "\<not> trivial_limit net \<Longrightarrow> eventually (\<lambda>x. P) net \<longleftrightarrow> P"
  by (cases P) (simp_all add: eventually_False)

lemma eventually_Inf: "eventually P (Inf B) \<longleftrightarrow> (\<exists>X\<subseteq>B. finite X \<and> eventually P (Inf X))"
proof -
  let ?F = "\<lambda>P. \<exists>X\<subseteq>B. finite X \<and> eventually P (Inf X)"
  
  { fix P have "eventually P (Abs_filter ?F) \<longleftrightarrow> ?F P"
    proof (rule eventually_Abs_filter is_filter.intro)+
      show "?F (\<lambda>x. True)"
        by (rule exI[of _ "{}"]) (simp add: le_fun_def)
    next
      fix P Q
      assume "?F P" then guess X ..
      moreover
      assume "?F Q" then guess Y ..
      ultimately show "?F (\<lambda>x. P x \<and> Q x)"
        by (intro exI[of _ "X \<union> Y"])
           (auto simp: Inf_union_distrib eventually_inf)
    next
      fix P Q
      assume "?F P" then guess X ..
      moreover assume "\<forall>x. P x \<longrightarrow> Q x"
      ultimately show "?F Q"
        by (intro exI[of _ X]) (auto elim: eventually_elim1)
    qed }
  note eventually_F = this

  have "Inf B = Abs_filter ?F"
  proof (intro antisym Inf_greatest)
    show "Inf B \<le> Abs_filter ?F"
      by (auto simp: le_filter_def eventually_F dest: Inf_superset_mono)
  next
    fix F assume "F \<in> B" then show "Abs_filter ?F \<le> F"
      by (auto simp add: le_filter_def eventually_F intro!: exI[of _ "{F}"])
  qed
  then show ?thesis
    by (simp add: eventually_F)
qed

lemma eventually_INF: "eventually P (INF b:B. F b) \<longleftrightarrow> (\<exists>X\<subseteq>B. finite X \<and> eventually P (INF b:X. F b))"
  unfolding INF_def[of B] eventually_Inf[of P "F`B"]
  by (metis Inf_image_eq finite_imageI image_mono finite_subset_image)

lemma Inf_filter_not_bot:
  fixes B :: "'a filter set"
  shows "(\<And>X. X \<subseteq> B \<Longrightarrow> finite X \<Longrightarrow> Inf X \<noteq> bot) \<Longrightarrow> Inf B \<noteq> bot"
  unfolding trivial_limit_def eventually_Inf[of _ B]
    bot_bool_def [symmetric] bot_fun_def [symmetric] bot_unique by simp

lemma INF_filter_not_bot:
  fixes F :: "'i \<Rightarrow> 'a filter"
  shows "(\<And>X. X \<subseteq> B \<Longrightarrow> finite X \<Longrightarrow> (INF b:X. F b) \<noteq> bot) \<Longrightarrow> (INF b:B. F b) \<noteq> bot"
  unfolding trivial_limit_def eventually_INF[of _ B]
    bot_bool_def [symmetric] bot_fun_def [symmetric] bot_unique by simp

lemma eventually_Inf_base:
  assumes "B \<noteq> {}" and base: "\<And>F G. F \<in> B \<Longrightarrow> G \<in> B \<Longrightarrow> \<exists>x\<in>B. x \<le> inf F G"
  shows "eventually P (Inf B) \<longleftrightarrow> (\<exists>b\<in>B. eventually P b)"
proof (subst eventually_Inf, safe)
  fix X assume "finite X" "X \<subseteq> B"
  then have "\<exists>b\<in>B. \<forall>x\<in>X. b \<le> x"
  proof induct
    case empty then show ?case
      using `B \<noteq> {}` by auto
  next
    case (insert x X)
    then obtain b where "b \<in> B" "\<And>x. x \<in> X \<Longrightarrow> b \<le> x"
      by auto
    with `insert x X \<subseteq> B` base[of b x] show ?case
      by (auto intro: order_trans)
  qed
  then obtain b where "b \<in> B" "b \<le> Inf X"
    by (auto simp: le_Inf_iff)
  then show "eventually P (Inf X) \<Longrightarrow> Bex B (eventually P)"
    by (intro bexI[of _ b]) (auto simp: le_filter_def)
qed (auto intro!: exI[of _ "{x}" for x])

lemma eventually_INF_base:
  "B \<noteq> {} \<Longrightarrow> (\<And>a b. a \<in> B \<Longrightarrow> b \<in> B \<Longrightarrow> \<exists>x\<in>B. F x \<le> inf (F a) (F b)) \<Longrightarrow>
    eventually P (INF b:B. F b) \<longleftrightarrow> (\<exists>b\<in>B. eventually P (F b))"
  unfolding INF_def by (subst eventually_Inf_base) auto


subsubsection {* Map function for filters *}

definition filtermap :: "('a \<Rightarrow> 'b) \<Rightarrow> 'a filter \<Rightarrow> 'b filter"
  where "filtermap f F = Abs_filter (\<lambda>P. eventually (\<lambda>x. P (f x)) F)"

lemma eventually_filtermap:
  "eventually P (filtermap f F) = eventually (\<lambda>x. P (f x)) F"
  unfolding filtermap_def
  apply (rule eventually_Abs_filter)
  apply (rule is_filter.intro)
  apply (auto elim!: eventually_rev_mp)
  done

lemma filtermap_ident: "filtermap (\<lambda>x. x) F = F"
  by (simp add: filter_eq_iff eventually_filtermap)

lemma filtermap_filtermap:
  "filtermap f (filtermap g F) = filtermap (\<lambda>x. f (g x)) F"
  by (simp add: filter_eq_iff eventually_filtermap)

lemma filtermap_mono: "F \<le> F' \<Longrightarrow> filtermap f F \<le> filtermap f F'"
  unfolding le_filter_def eventually_filtermap by simp

lemma filtermap_bot [simp]: "filtermap f bot = bot"
  by (simp add: filter_eq_iff eventually_filtermap)

lemma filtermap_sup: "filtermap f (sup F1 F2) = sup (filtermap f F1) (filtermap f F2)"
  by (auto simp: filter_eq_iff eventually_filtermap eventually_sup)

lemma filtermap_inf: "filtermap f (inf F1 F2) \<le> inf (filtermap f F1) (filtermap f F2)"
  by (auto simp: le_filter_def eventually_filtermap eventually_inf)

lemma filtermap_INF: "filtermap f (INF b:B. F b) \<le> (INF b:B. filtermap f (F b))"
proof -
  { fix X :: "'c set" assume "finite X"
    then have "filtermap f (INFIMUM X F) \<le> (INF b:X. filtermap f (F b))"
    proof induct
      case (insert x X)
      have "filtermap f (INF a:insert x X. F a) \<le> inf (filtermap f (F x)) (filtermap f (INF a:X. F a))"
        by (rule order_trans[OF _ filtermap_inf]) simp
      also have "\<dots> \<le> inf (filtermap f (F x)) (INF a:X. filtermap f (F a))"
        by (intro inf_mono insert order_refl)
      finally show ?case
        by simp
    qed simp }
  then show ?thesis
    unfolding le_filter_def eventually_filtermap
    by (subst (1 2) eventually_INF) auto
qed
subsubsection {* Standard filters *}

definition principal :: "'a set \<Rightarrow> 'a filter" where
  "principal S = Abs_filter (\<lambda>P. \<forall>x\<in>S. P x)"

lemma eventually_principal: "eventually P (principal S) \<longleftrightarrow> (\<forall>x\<in>S. P x)"
  unfolding principal_def
  by (rule eventually_Abs_filter, rule is_filter.intro) auto

lemma eventually_inf_principal: "eventually P (inf F (principal s)) \<longleftrightarrow> eventually (\<lambda>x. x \<in> s \<longrightarrow> P x) F"
  unfolding eventually_inf eventually_principal by (auto elim: eventually_elim1)

lemma principal_UNIV[simp]: "principal UNIV = top"
  by (auto simp: filter_eq_iff eventually_principal)

lemma principal_empty[simp]: "principal {} = bot"
  by (auto simp: filter_eq_iff eventually_principal)

lemma principal_eq_bot_iff: "principal X = bot \<longleftrightarrow> X = {}"
  by (auto simp add: filter_eq_iff eventually_principal)

lemma principal_le_iff[iff]: "principal A \<le> principal B \<longleftrightarrow> A \<subseteq> B"
  by (auto simp: le_filter_def eventually_principal)

lemma le_principal: "F \<le> principal A \<longleftrightarrow> eventually (\<lambda>x. x \<in> A) F"
  unfolding le_filter_def eventually_principal
  apply safe
  apply (erule_tac x="\<lambda>x. x \<in> A" in allE)
  apply (auto elim: eventually_elim1)
  done

lemma principal_inject[iff]: "principal A = principal B \<longleftrightarrow> A = B"
  unfolding eq_iff by simp

lemma sup_principal[simp]: "sup (principal A) (principal B) = principal (A \<union> B)"
  unfolding filter_eq_iff eventually_sup eventually_principal by auto

lemma inf_principal[simp]: "inf (principal A) (principal B) = principal (A \<inter> B)"
  unfolding filter_eq_iff eventually_inf eventually_principal
  by (auto intro: exI[of _ "\<lambda>x. x \<in> A"] exI[of _ "\<lambda>x. x \<in> B"])

lemma SUP_principal[simp]: "(SUP i : I. principal (A i)) = principal (\<Union>i\<in>I. A i)"
  unfolding filter_eq_iff eventually_Sup SUP_def by (auto simp: eventually_principal)

lemma INF_principal_finite: "finite X \<Longrightarrow> (INF x:X. principal (f x)) = principal (\<Inter>x\<in>X. f x)"
  by (induct X rule: finite_induct) auto

lemma filtermap_principal[simp]: "filtermap f (principal A) = principal (f ` A)"
  unfolding filter_eq_iff eventually_filtermap eventually_principal by simp

subsubsection {* Order filters *}

definition at_top :: "('a::order) filter"
  where "at_top = (INF k. principal {k ..})"

lemma at_top_sub: "at_top = (INF k:{c::'a::linorder..}. principal {k ..})"
  by (auto intro!: INF_eq max.cobounded1 max.cobounded2 simp: at_top_def)

lemma eventually_at_top_linorder: "eventually P at_top \<longleftrightarrow> (\<exists>N::'a::linorder. \<forall>n\<ge>N. P n)"
  unfolding at_top_def
  by (subst eventually_INF_base) (auto simp: eventually_principal intro: max.cobounded1 max.cobounded2)

lemma eventually_ge_at_top:
  "eventually (\<lambda>x. (c::_::linorder) \<le> x) at_top"
  unfolding eventually_at_top_linorder by auto

lemma eventually_at_top_dense: "eventually P at_top \<longleftrightarrow> (\<exists>N::'a::{no_top, linorder}. \<forall>n>N. P n)"
proof -
  have "eventually P (INF k. principal {k <..}) \<longleftrightarrow> (\<exists>N::'a. \<forall>n>N. P n)"
    by (subst eventually_INF_base) (auto simp: eventually_principal intro: max.cobounded1 max.cobounded2)
  also have "(INF k. principal {k::'a <..}) = at_top"
    unfolding at_top_def 
    by (intro INF_eq) (auto intro: less_imp_le simp: Ici_subset_Ioi_iff gt_ex)
  finally show ?thesis .
qed

lemma eventually_gt_at_top:
  "eventually (\<lambda>x. (c::_::unbounded_dense_linorder) < x) at_top"
  unfolding eventually_at_top_dense by auto

definition at_bot :: "('a::order) filter"
  where "at_bot = (INF k. principal {.. k})"

lemma at_bot_sub: "at_bot = (INF k:{.. c::'a::linorder}. principal {.. k})"
  by (auto intro!: INF_eq min.cobounded1 min.cobounded2 simp: at_bot_def)

lemma eventually_at_bot_linorder:
  fixes P :: "'a::linorder \<Rightarrow> bool" shows "eventually P at_bot \<longleftrightarrow> (\<exists>N. \<forall>n\<le>N. P n)"
  unfolding at_bot_def
  by (subst eventually_INF_base) (auto simp: eventually_principal intro: min.cobounded1 min.cobounded2)

lemma eventually_le_at_bot:
  "eventually (\<lambda>x. x \<le> (c::_::linorder)) at_bot"
  unfolding eventually_at_bot_linorder by auto

lemma eventually_at_bot_dense: "eventually P at_bot \<longleftrightarrow> (\<exists>N::'a::{no_bot, linorder}. \<forall>n<N. P n)"
proof -
  have "eventually P (INF k. principal {..< k}) \<longleftrightarrow> (\<exists>N::'a. \<forall>n<N. P n)"
    by (subst eventually_INF_base) (auto simp: eventually_principal intro: min.cobounded1 min.cobounded2)
  also have "(INF k. principal {..< k::'a}) = at_bot"
    unfolding at_bot_def 
    by (intro INF_eq) (auto intro: less_imp_le simp: Iic_subset_Iio_iff lt_ex)
  finally show ?thesis .
qed

lemma eventually_gt_at_bot:
  "eventually (\<lambda>x. x < (c::_::unbounded_dense_linorder)) at_bot"
  unfolding eventually_at_bot_dense by auto

lemma trivial_limit_at_bot_linorder: "\<not> trivial_limit (at_bot ::('a::linorder) filter)"
  unfolding trivial_limit_def
  by (metis eventually_at_bot_linorder order_refl)

lemma trivial_limit_at_top_linorder: "\<not> trivial_limit (at_top ::('a::linorder) filter)"
  unfolding trivial_limit_def
  by (metis eventually_at_top_linorder order_refl)

subsection {* Sequentially *}

abbreviation sequentially :: "nat filter"
  where "sequentially \<equiv> at_top"

lemma eventually_sequentially:
  "eventually P sequentially \<longleftrightarrow> (\<exists>N. \<forall>n\<ge>N. P n)"
  by (rule eventually_at_top_linorder)

lemma sequentially_bot [simp, intro]: "sequentially \<noteq> bot"
  unfolding filter_eq_iff eventually_sequentially by auto

lemmas trivial_limit_sequentially = sequentially_bot

lemma eventually_False_sequentially [simp]:
  "\<not> eventually (\<lambda>n. False) sequentially"
  by (simp add: eventually_False)

lemma le_sequentially:
  "F \<le> sequentially \<longleftrightarrow> (\<forall>N. eventually (\<lambda>n. N \<le> n) F)"
  by (simp add: at_top_def le_INF_iff le_principal)

lemma eventually_sequentiallyI:
  assumes "\<And>x. c \<le> x \<Longrightarrow> P x"
  shows "eventually P sequentially"
using assms by (auto simp: eventually_sequentially)

lemma eventually_sequentially_seg:
  "eventually (\<lambda>n. P (n + k)) sequentially \<longleftrightarrow> eventually P sequentially"
  unfolding eventually_sequentially
  apply safe
   apply (rule_tac x="N + k" in exI)
   apply rule
   apply (erule_tac x="n - k" in allE)
   apply auto []
  apply (rule_tac x=N in exI)
  apply auto []
  done


subsection {* Limits *}

definition filterlim :: "('a \<Rightarrow> 'b) \<Rightarrow> 'b filter \<Rightarrow> 'a filter \<Rightarrow> bool" where
  "filterlim f F2 F1 \<longleftrightarrow> filtermap f F1 \<le> F2"

syntax
  "_LIM" :: "pttrns \<Rightarrow> 'a \<Rightarrow> 'b \<Rightarrow> 'a \<Rightarrow> bool" ("(3LIM (_)/ (_)./ (_) :> (_))" [1000, 10, 0, 10] 10)

translations
  "LIM x F1. f :> F2"   == "CONST filterlim (%x. f) F2 F1"

lemma filterlim_iff:
  "(LIM x F1. f x :> F2) \<longleftrightarrow> (\<forall>P. eventually P F2 \<longrightarrow> eventually (\<lambda>x. P (f x)) F1)"
  unfolding filterlim_def le_filter_def eventually_filtermap ..

lemma filterlim_compose:
  "filterlim g F3 F2 \<Longrightarrow> filterlim f F2 F1 \<Longrightarrow> filterlim (\<lambda>x. g (f x)) F3 F1"
  unfolding filterlim_def filtermap_filtermap[symmetric] by (metis filtermap_mono order_trans)

lemma filterlim_mono:
  "filterlim f F2 F1 \<Longrightarrow> F2 \<le> F2' \<Longrightarrow> F1' \<le> F1 \<Longrightarrow> filterlim f F2' F1'"
  unfolding filterlim_def by (metis filtermap_mono order_trans)

lemma filterlim_ident: "LIM x F. x :> F"
  by (simp add: filterlim_def filtermap_ident)

lemma filterlim_cong:
  "F1 = F1' \<Longrightarrow> F2 = F2' \<Longrightarrow> eventually (\<lambda>x. f x = g x) F2 \<Longrightarrow> filterlim f F1 F2 = filterlim g F1' F2'"
  by (auto simp: filterlim_def le_filter_def eventually_filtermap elim: eventually_elim2)

lemma filterlim_mono_eventually:
  assumes "filterlim f F G" and ord: "F \<le> F'" "G' \<le> G"
  assumes eq: "eventually (\<lambda>x. f x = f' x) G'"
  shows "filterlim f' F' G'"
  apply (rule filterlim_cong[OF refl refl eq, THEN iffD1])
  apply (rule filterlim_mono[OF _ ord])
  apply fact
  done

lemma filtermap_mono_strong: "inj f \<Longrightarrow> filtermap f F \<le> filtermap f G \<longleftrightarrow> F \<le> G"
  apply (auto intro!: filtermap_mono) []
  apply (auto simp: le_filter_def eventually_filtermap)
  apply (erule_tac x="\<lambda>x. P (inv f x)" in allE)
  apply auto
  done

lemma filtermap_eq_strong: "inj f \<Longrightarrow> filtermap f F = filtermap f G \<longleftrightarrow> F = G"
  by (simp add: filtermap_mono_strong eq_iff)

lemma filterlim_principal:
  "(LIM x F. f x :> principal S) \<longleftrightarrow> (eventually (\<lambda>x. f x \<in> S) F)"
  unfolding filterlim_def eventually_filtermap le_principal ..

lemma filterlim_inf:
  "(LIM x F1. f x :> inf F2 F3) \<longleftrightarrow> ((LIM x F1. f x :> F2) \<and> (LIM x F1. f x :> F3))"
  unfolding filterlim_def by simp

lemma filterlim_INF:
  "(LIM x F. f x :> (INF b:B. G b)) \<longleftrightarrow> (\<forall>b\<in>B. LIM x F. f x :> G b)"
  unfolding filterlim_def le_INF_iff ..

lemma filterlim_INF_INF:
  "(\<And>m. m \<in> J \<Longrightarrow> \<exists>i\<in>I. filtermap f (F i) \<le> G m) \<Longrightarrow> LIM x (INF i:I. F i). f x :> (INF j:J. G j)"
  unfolding filterlim_def by (rule order_trans[OF filtermap_INF INF_mono])

lemma filterlim_base:
  "(\<And>m x. m \<in> J \<Longrightarrow> i m \<in> I) \<Longrightarrow> (\<And>m x. m \<in> J \<Longrightarrow> x \<in> F (i m) \<Longrightarrow> f x \<in> G m) \<Longrightarrow> 
    LIM x (INF i:I. principal (F i)). f x :> (INF j:J. principal (G j))"
  by (force intro!: filterlim_INF_INF simp: image_subset_iff)

lemma filterlim_base_iff: 
  assumes "I \<noteq> {}" and chain: "\<And>i j. i \<in> I \<Longrightarrow> j \<in> I \<Longrightarrow> F i \<subseteq> F j \<or> F j \<subseteq> F i"
  shows "(LIM x (INF i:I. principal (F i)). f x :> INF j:J. principal (G j)) \<longleftrightarrow>
    (\<forall>j\<in>J. \<exists>i\<in>I. \<forall>x\<in>F i. f x \<in> G j)"
  unfolding filterlim_INF filterlim_principal
proof (subst eventually_INF_base)
  fix i j assume "i \<in> I" "j \<in> I"
  with chain[OF this] show "\<exists>x\<in>I. principal (F x) \<le> inf (principal (F i)) (principal (F j))"
    by auto
qed (auto simp: eventually_principal `I \<noteq> {}`)

lemma filterlim_filtermap: "filterlim f F1 (filtermap g F2) = filterlim (\<lambda>x. f (g x)) F1 F2"
  unfolding filterlim_def filtermap_filtermap ..

lemma filterlim_sup:
  "filterlim f F F1 \<Longrightarrow> filterlim f F F2 \<Longrightarrow> filterlim f F (sup F1 F2)"
  unfolding filterlim_def filtermap_sup by auto

lemma eventually_sequentially_Suc: "eventually (\<lambda>i. P (Suc i)) sequentially \<longleftrightarrow> eventually P sequentially"
  unfolding eventually_sequentially by (metis Suc_le_D Suc_le_mono le_Suc_eq)

lemma filterlim_sequentially_Suc:
  "(LIM x sequentially. f (Suc x) :> F) \<longleftrightarrow> (LIM x sequentially. f x :> F)"
  unfolding filterlim_iff by (subst eventually_sequentially_Suc) simp

lemma filterlim_Suc: "filterlim Suc sequentially sequentially"
  by (simp add: filterlim_iff eventually_sequentially) (metis le_Suc_eq)


subsection {* Limits to @{const at_top} and @{const at_bot} *}

lemma filterlim_at_top:
  fixes f :: "'a \<Rightarrow> ('b::linorder)"
  shows "(LIM x F. f x :> at_top) \<longleftrightarrow> (\<forall>Z. eventually (\<lambda>x. Z \<le> f x) F)"
  by (auto simp: filterlim_iff eventually_at_top_linorder elim!: eventually_elim1)

lemma filterlim_at_top_mono:
  "LIM x F. f x :> at_top \<Longrightarrow> eventually (\<lambda>x. f x \<le> (g x::'a::linorder)) F \<Longrightarrow>
    LIM x F. g x :> at_top"
  by (auto simp: filterlim_at_top elim: eventually_elim2 intro: order_trans)

lemma filterlim_at_top_dense:
  fixes f :: "'a \<Rightarrow> ('b::unbounded_dense_linorder)"
  shows "(LIM x F. f x :> at_top) \<longleftrightarrow> (\<forall>Z. eventually (\<lambda>x. Z < f x) F)"
  by (metis eventually_elim1[of _ F] eventually_gt_at_top order_less_imp_le
            filterlim_at_top[of f F] filterlim_iff[of f at_top F])

lemma filterlim_at_top_ge:
  fixes f :: "'a \<Rightarrow> ('b::linorder)" and c :: "'b"
  shows "(LIM x F. f x :> at_top) \<longleftrightarrow> (\<forall>Z\<ge>c. eventually (\<lambda>x. Z \<le> f x) F)"
  unfolding at_top_sub[of c] filterlim_INF by (auto simp add: filterlim_principal)

lemma filterlim_at_top_at_top:
  fixes f :: "'a::linorder \<Rightarrow> 'b::linorder"
  assumes mono: "\<And>x y. Q x \<Longrightarrow> Q y \<Longrightarrow> x \<le> y \<Longrightarrow> f x \<le> f y"
  assumes bij: "\<And>x. P x \<Longrightarrow> f (g x) = x" "\<And>x. P x \<Longrightarrow> Q (g x)"
  assumes Q: "eventually Q at_top"
  assumes P: "eventually P at_top"
  shows "filterlim f at_top at_top"
proof -
  from P obtain x where x: "\<And>y. x \<le> y \<Longrightarrow> P y"
    unfolding eventually_at_top_linorder by auto
  show ?thesis
  proof (intro filterlim_at_top_ge[THEN iffD2] allI impI)
    fix z assume "x \<le> z"
    with x have "P z" by auto
    have "eventually (\<lambda>x. g z \<le> x) at_top"
      by (rule eventually_ge_at_top)
    with Q show "eventually (\<lambda>x. z \<le> f x) at_top"
      by eventually_elim (metis mono bij `P z`)
  qed
qed

lemma filterlim_at_top_gt:
  fixes f :: "'a \<Rightarrow> ('b::unbounded_dense_linorder)" and c :: "'b"
  shows "(LIM x F. f x :> at_top) \<longleftrightarrow> (\<forall>Z>c. eventually (\<lambda>x. Z \<le> f x) F)"
  by (metis filterlim_at_top order_less_le_trans gt_ex filterlim_at_top_ge)

lemma filterlim_at_bot: 
  fixes f :: "'a \<Rightarrow> ('b::linorder)"
  shows "(LIM x F. f x :> at_bot) \<longleftrightarrow> (\<forall>Z. eventually (\<lambda>x. f x \<le> Z) F)"
  by (auto simp: filterlim_iff eventually_at_bot_linorder elim!: eventually_elim1)

lemma filterlim_at_bot_dense:
  fixes f :: "'a \<Rightarrow> ('b::{dense_linorder, no_bot})"
  shows "(LIM x F. f x :> at_bot) \<longleftrightarrow> (\<forall>Z. eventually (\<lambda>x. f x < Z) F)"
proof (auto simp add: filterlim_at_bot[of f F])
  fix Z :: 'b
  from lt_ex [of Z] obtain Z' where 1: "Z' < Z" ..
  assume "\<forall>Z. eventually (\<lambda>x. f x \<le> Z) F"
  hence "eventually (\<lambda>x. f x \<le> Z') F" by auto
  thus "eventually (\<lambda>x. f x < Z) F"
    apply (rule eventually_mono[rotated])
    using 1 by auto
  next 
    fix Z :: 'b 
    show "\<forall>Z. eventually (\<lambda>x. f x < Z) F \<Longrightarrow> eventually (\<lambda>x. f x \<le> Z) F"
      by (drule spec [of _ Z], erule eventually_mono[rotated], auto simp add: less_imp_le)
qed

lemma filterlim_at_bot_le:
  fixes f :: "'a \<Rightarrow> ('b::linorder)" and c :: "'b"
  shows "(LIM x F. f x :> at_bot) \<longleftrightarrow> (\<forall>Z\<le>c. eventually (\<lambda>x. Z \<ge> f x) F)"
  unfolding filterlim_at_bot
proof safe
  fix Z assume *: "\<forall>Z\<le>c. eventually (\<lambda>x. Z \<ge> f x) F"
  with *[THEN spec, of "min Z c"] show "eventually (\<lambda>x. Z \<ge> f x) F"
    by (auto elim!: eventually_elim1)
qed simp

lemma filterlim_at_bot_lt:
  fixes f :: "'a \<Rightarrow> ('b::unbounded_dense_linorder)" and c :: "'b"
  shows "(LIM x F. f x :> at_bot) \<longleftrightarrow> (\<forall>Z<c. eventually (\<lambda>x. Z \<ge> f x) F)"
  by (metis filterlim_at_bot filterlim_at_bot_le lt_ex order_le_less_trans)


subsection {* Setup @{typ "'a filter"} for lifting and transfer *}

context begin interpretation lifting_syntax .

definition rel_filter :: "('a \<Rightarrow> 'b \<Rightarrow> bool) \<Rightarrow> 'a filter \<Rightarrow> 'b filter \<Rightarrow> bool"
where "rel_filter R F G = ((R ===> op =) ===> op =) (Rep_filter F) (Rep_filter G)"

lemma rel_filter_eventually:
  "rel_filter R F G \<longleftrightarrow> 
  ((R ===> op =) ===> op =) (\<lambda>P. eventually P F) (\<lambda>P. eventually P G)"
by(simp add: rel_filter_def eventually_def)

lemma filtermap_id [simp, id_simps]: "filtermap id = id"
by(simp add: fun_eq_iff id_def filtermap_ident)

lemma filtermap_id' [simp]: "filtermap (\<lambda>x. x) = (\<lambda>F. F)"
using filtermap_id unfolding id_def .

lemma Quotient_filter [quot_map]:
  assumes Q: "Quotient R Abs Rep T"
  shows "Quotient (rel_filter R) (filtermap Abs) (filtermap Rep) (rel_filter T)"
unfolding Quotient_alt_def
proof(intro conjI strip)
  from Q have *: "\<And>x y. T x y \<Longrightarrow> Abs x = y"
    unfolding Quotient_alt_def by blast

  fix F G
  assume "rel_filter T F G"
  thus "filtermap Abs F = G" unfolding filter_eq_iff
    by(auto simp add: eventually_filtermap rel_filter_eventually * rel_funI del: iffI elim!: rel_funD)
next
  from Q have *: "\<And>x. T (Rep x) x" unfolding Quotient_alt_def by blast

  fix F
  show "rel_filter T (filtermap Rep F) F" 
    by(auto elim: rel_funD intro: * intro!: ext arg_cong[where f="\<lambda>P. eventually P F"] rel_funI
            del: iffI simp add: eventually_filtermap rel_filter_eventually)
qed(auto simp add: map_fun_def o_def eventually_filtermap filter_eq_iff fun_eq_iff rel_filter_eventually
         fun_quotient[OF fun_quotient[OF Q identity_quotient] identity_quotient, unfolded Quotient_alt_def])

lemma eventually_parametric [transfer_rule]:
  "((A ===> op =) ===> rel_filter A ===> op =) eventually eventually"
by(simp add: rel_fun_def rel_filter_eventually)

lemma rel_filter_eq [relator_eq]: "rel_filter op = = op ="
by(auto simp add: rel_filter_eventually rel_fun_eq fun_eq_iff filter_eq_iff)

lemma rel_filter_mono [relator_mono]:
  "A \<le> B \<Longrightarrow> rel_filter A \<le> rel_filter B"
unfolding rel_filter_eventually[abs_def]
by(rule le_funI)+(intro fun_mono fun_mono[THEN le_funD, THEN le_funD] order.refl)

lemma rel_filter_conversep [simp]: "rel_filter A\<inverse>\<inverse> = (rel_filter A)\<inverse>\<inverse>"
by(auto simp add: rel_filter_eventually fun_eq_iff rel_fun_def)

lemma is_filter_parametric_aux:
  assumes "is_filter F"
  assumes [transfer_rule]: "bi_total A" "bi_unique A"
  and [transfer_rule]: "((A ===> op =) ===> op =) F G"
  shows "is_filter G"
proof -
  interpret is_filter F by fact
  show ?thesis
  proof
    have "F (\<lambda>_. True) = G (\<lambda>x. True)" by transfer_prover
    thus "G (\<lambda>x. True)" by(simp add: True)
  next
    fix P' Q'
    assume "G P'" "G Q'"
    moreover
    from bi_total_fun[OF `bi_unique A` bi_total_eq, unfolded bi_total_def]
    obtain P Q where [transfer_rule]: "(A ===> op =) P P'" "(A ===> op =) Q Q'" by blast
    have "F P = G P'" "F Q = G Q'" by transfer_prover+
    ultimately have "F (\<lambda>x. P x \<and> Q x)" by(simp add: conj)
    moreover have "F (\<lambda>x. P x \<and> Q x) = G (\<lambda>x. P' x \<and> Q' x)" by transfer_prover
    ultimately show "G (\<lambda>x. P' x \<and> Q' x)" by simp
  next
    fix P' Q'
    assume "\<forall>x. P' x \<longrightarrow> Q' x" "G P'"
    moreover
    from bi_total_fun[OF `bi_unique A` bi_total_eq, unfolded bi_total_def]
    obtain P Q where [transfer_rule]: "(A ===> op =) P P'" "(A ===> op =) Q Q'" by blast
    have "F P = G P'" by transfer_prover
    moreover have "(\<forall>x. P x \<longrightarrow> Q x) \<longleftrightarrow> (\<forall>x. P' x \<longrightarrow> Q' x)" by transfer_prover
    ultimately have "F Q" by(simp add: mono)
    moreover have "F Q = G Q'" by transfer_prover
    ultimately show "G Q'" by simp
  qed
qed

lemma is_filter_parametric [transfer_rule]:
  "\<lbrakk> bi_total A; bi_unique A \<rbrakk>
  \<Longrightarrow> (((A ===> op =) ===> op =) ===> op =) is_filter is_filter"
apply(rule rel_funI)
apply(rule iffI)
 apply(erule (3) is_filter_parametric_aux)
apply(erule is_filter_parametric_aux[where A="conversep A"])
apply(auto simp add: rel_fun_def)
done

lemma left_total_rel_filter [transfer_rule]:
  assumes [transfer_rule]: "bi_total A" "bi_unique A"
  shows "left_total (rel_filter A)"
proof(rule left_totalI)
  fix F :: "'a filter"
  from bi_total_fun[OF bi_unique_fun[OF `bi_total A` bi_unique_eq] bi_total_eq]
  obtain G where [transfer_rule]: "((A ===> op =) ===> op =) (\<lambda>P. eventually P F) G" 
    unfolding  bi_total_def by blast
  moreover have "is_filter (\<lambda>P. eventually P F) \<longleftrightarrow> is_filter G" by transfer_prover
  hence "is_filter G" by(simp add: eventually_def is_filter_Rep_filter)
  ultimately have "rel_filter A F (Abs_filter G)"
    by(simp add: rel_filter_eventually eventually_Abs_filter)
  thus "\<exists>G. rel_filter A F G" ..
qed

lemma right_total_rel_filter [transfer_rule]:
  "\<lbrakk> bi_total A; bi_unique A \<rbrakk> \<Longrightarrow> right_total (rel_filter A)"
using left_total_rel_filter[of "A\<inverse>\<inverse>"] by simp

lemma bi_total_rel_filter [transfer_rule]:
  assumes "bi_total A" "bi_unique A"
  shows "bi_total (rel_filter A)"
unfolding bi_total_alt_def using assms
by(simp add: left_total_rel_filter right_total_rel_filter)

lemma left_unique_rel_filter [transfer_rule]:
  assumes "left_unique A"
  shows "left_unique (rel_filter A)"
proof(rule left_uniqueI)
  fix F F' G
  assume [transfer_rule]: "rel_filter A F G" "rel_filter A F' G"
  show "F = F'"
    unfolding filter_eq_iff
  proof
    fix P :: "'a \<Rightarrow> bool"
    obtain P' where [transfer_rule]: "(A ===> op =) P P'"
      using left_total_fun[OF assms left_total_eq] unfolding left_total_def by blast
    have "eventually P F = eventually P' G" 
      and "eventually P F' = eventually P' G" by transfer_prover+
    thus "eventually P F = eventually P F'" by simp
  qed
qed

lemma right_unique_rel_filter [transfer_rule]:
  "right_unique A \<Longrightarrow> right_unique (rel_filter A)"
using left_unique_rel_filter[of "A\<inverse>\<inverse>"] by simp

lemma bi_unique_rel_filter [transfer_rule]:
  "bi_unique A \<Longrightarrow> bi_unique (rel_filter A)"
by(simp add: bi_unique_alt_def left_unique_rel_filter right_unique_rel_filter)

lemma top_filter_parametric [transfer_rule]:
  "bi_total A \<Longrightarrow> (rel_filter A) top top"
by(simp add: rel_filter_eventually All_transfer)

lemma bot_filter_parametric [transfer_rule]: "(rel_filter A) bot bot"
by(simp add: rel_filter_eventually rel_fun_def)

lemma sup_filter_parametric [transfer_rule]:
  "(rel_filter A ===> rel_filter A ===> rel_filter A) sup sup"
by(fastforce simp add: rel_filter_eventually[abs_def] eventually_sup dest: rel_funD)

lemma Sup_filter_parametric [transfer_rule]:
  "(rel_set (rel_filter A) ===> rel_filter A) Sup Sup"
proof(rule rel_funI)
  fix S T
  assume [transfer_rule]: "rel_set (rel_filter A) S T"
  show "rel_filter A (Sup S) (Sup T)"
    by(simp add: rel_filter_eventually eventually_Sup) transfer_prover
qed

lemma principal_parametric [transfer_rule]:
  "(rel_set A ===> rel_filter A) principal principal"
proof(rule rel_funI)
  fix S S'
  assume [transfer_rule]: "rel_set A S S'"
  show "rel_filter A (principal S) (principal S')"
    by(simp add: rel_filter_eventually eventually_principal) transfer_prover
qed

context
  fixes A :: "'a \<Rightarrow> 'b \<Rightarrow> bool"
  assumes [transfer_rule]: "bi_unique A" 
begin

lemma le_filter_parametric [transfer_rule]:
  "(rel_filter A ===> rel_filter A ===> op =) op \<le> op \<le>"
unfolding le_filter_def[abs_def] by transfer_prover

lemma less_filter_parametric [transfer_rule]:
  "(rel_filter A ===> rel_filter A ===> op =) op < op <"
unfolding less_filter_def[abs_def] by transfer_prover

context
  assumes [transfer_rule]: "bi_total A"
begin

lemma Inf_filter_parametric [transfer_rule]:
  "(rel_set (rel_filter A) ===> rel_filter A) Inf Inf"
unfolding Inf_filter_def[abs_def] by transfer_prover

lemma inf_filter_parametric [transfer_rule]:
  "(rel_filter A ===> rel_filter A ===> rel_filter A) inf inf"
proof(intro rel_funI)+
  fix F F' G G'
  assume [transfer_rule]: "rel_filter A F F'" "rel_filter A G G'"
  have "rel_filter A (Inf {F, G}) (Inf {F', G'})" by transfer_prover
  thus "rel_filter A (inf F G) (inf F' G')" by simp
qed

end

end

end

end
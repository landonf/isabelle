(*  Title:      HOL/Analysis/Complete_Measure.thy
    Author:     Robert Himmelmann, Johannes Hoelzl, TU Muenchen
*)

theory Complete_Measure
  imports Bochner_Integration
begin

locale complete_measure =
  fixes M :: "'a measure"
  assumes complete: "\<And>A B. B \<subseteq> A \<Longrightarrow> A \<in> null_sets M \<Longrightarrow> B \<in> sets M"

definition
  "split_completion M A p = (if A \<in> sets M then p = (A, {}) else
   \<exists>N'. A = fst p \<union> snd p \<and> fst p \<inter> snd p = {} \<and> fst p \<in> sets M \<and> snd p \<subseteq> N' \<and> N' \<in> null_sets M)"

definition
  "main_part M A = fst (Eps (split_completion M A))"

definition
  "null_part M A = snd (Eps (split_completion M A))"

definition completion :: "'a measure \<Rightarrow> 'a measure" where
  "completion M = measure_of (space M) { S \<union> N |S N N'. S \<in> sets M \<and> N' \<in> null_sets M \<and> N \<subseteq> N' }
    (emeasure M \<circ> main_part M)"

lemma completion_into_space:
  "{ S \<union> N |S N N'. S \<in> sets M \<and> N' \<in> null_sets M \<and> N \<subseteq> N' } \<subseteq> Pow (space M)"
  using sets.sets_into_space by auto

lemma space_completion[simp]: "space (completion M) = space M"
  unfolding completion_def using space_measure_of[OF completion_into_space] by simp

lemma completionI:
  assumes "A = S \<union> N" "N \<subseteq> N'" "N' \<in> null_sets M" "S \<in> sets M"
  shows "A \<in> { S \<union> N |S N N'. S \<in> sets M \<and> N' \<in> null_sets M \<and> N \<subseteq> N' }"
  using assms by auto

lemma completionE:
  assumes "A \<in> { S \<union> N |S N N'. S \<in> sets M \<and> N' \<in> null_sets M \<and> N \<subseteq> N' }"
  obtains S N N' where "A = S \<union> N" "N \<subseteq> N'" "N' \<in> null_sets M" "S \<in> sets M"
  using assms by auto

lemma sigma_algebra_completion:
  "sigma_algebra (space M) { S \<union> N |S N N'. S \<in> sets M \<and> N' \<in> null_sets M \<and> N \<subseteq> N' }"
    (is "sigma_algebra _ ?A")
  unfolding sigma_algebra_iff2
proof (intro conjI ballI allI impI)
  show "?A \<subseteq> Pow (space M)"
    using sets.sets_into_space by auto
next
  show "{} \<in> ?A" by auto
next
  let ?C = "space M"
  fix A assume "A \<in> ?A" from completionE[OF this] guess S N N' .
  then show "space M - A \<in> ?A"
    by (intro completionI[of _ "(?C - S) \<inter> (?C - N')" "(?C - S) \<inter> N' \<inter> (?C - N)"]) auto
next
  fix A :: "nat \<Rightarrow> 'a set" assume A: "range A \<subseteq> ?A"
  then have "\<forall>n. \<exists>S N N'. A n = S \<union> N \<and> S \<in> sets M \<and> N' \<in> null_sets M \<and> N \<subseteq> N'"
    by (auto simp: image_subset_iff)
  from choice[OF this] guess S ..
  from choice[OF this] guess N ..
  from choice[OF this] guess N' ..
  then show "UNION UNIV A \<in> ?A"
    using null_sets_UN[of N']
    by (intro completionI[of _ "UNION UNIV S" "UNION UNIV N" "UNION UNIV N'"]) auto
qed

lemma sets_completion:
  "sets (completion M) = { S \<union> N |S N N'. S \<in> sets M \<and> N' \<in> null_sets M \<and> N \<subseteq> N' }"
  using sigma_algebra.sets_measure_of_eq[OF sigma_algebra_completion] by (simp add: completion_def)

lemma sets_completionE:
  assumes "A \<in> sets (completion M)"
  obtains S N N' where "A = S \<union> N" "N \<subseteq> N'" "N' \<in> null_sets M" "S \<in> sets M"
  using assms unfolding sets_completion by auto

lemma sets_completionI:
  assumes "A = S \<union> N" "N \<subseteq> N'" "N' \<in> null_sets M" "S \<in> sets M"
  shows "A \<in> sets (completion M)"
  using assms unfolding sets_completion by auto

lemma sets_completionI_sets[intro, simp]:
  "A \<in> sets M \<Longrightarrow> A \<in> sets (completion M)"
  unfolding sets_completion by force

lemma null_sets_completion:
  assumes "N' \<in> null_sets M" "N \<subseteq> N'" shows "N \<in> sets (completion M)"
  using assms by (intro sets_completionI[of N "{}" N N']) auto

lemma split_completion:
  assumes "A \<in> sets (completion M)"
  shows "split_completion M A (main_part M A, null_part M A)"
proof cases
  assume "A \<in> sets M" then show ?thesis
    by (simp add: split_completion_def[abs_def] main_part_def null_part_def)
next
  assume nA: "A \<notin> sets M"
  show ?thesis
    unfolding main_part_def null_part_def if_not_P[OF nA]
  proof (rule someI2_ex)
    from assms[THEN sets_completionE] guess S N N' . note A = this
    let ?P = "(S, N - S)"
    show "\<exists>p. split_completion M A p"
      unfolding split_completion_def if_not_P[OF nA] using A
    proof (intro exI conjI)
      show "A = fst ?P \<union> snd ?P" using A by auto
      show "snd ?P \<subseteq> N'" using A by auto
   qed auto
  qed auto
qed

lemma
  assumes "S \<in> sets (completion M)"
  shows main_part_sets[intro, simp]: "main_part M S \<in> sets M"
    and main_part_null_part_Un[simp]: "main_part M S \<union> null_part M S = S"
    and main_part_null_part_Int[simp]: "main_part M S \<inter> null_part M S = {}"
  using split_completion[OF assms]
  by (auto simp: split_completion_def split: if_split_asm)

lemma main_part[simp]: "S \<in> sets M \<Longrightarrow> main_part M S = S"
  using split_completion[of S M]
  by (auto simp: split_completion_def split: if_split_asm)

lemma null_part:
  assumes "S \<in> sets (completion M)" shows "\<exists>N. N\<in>null_sets M \<and> null_part M S \<subseteq> N"
  using split_completion[OF assms] by (auto simp: split_completion_def split: if_split_asm)

lemma null_part_sets[intro, simp]:
  assumes "S \<in> sets M" shows "null_part M S \<in> sets M" "emeasure M (null_part M S) = 0"
proof -
  have S: "S \<in> sets (completion M)" using assms by auto
  have "S - main_part M S \<in> sets M" using assms by auto
  moreover
  from main_part_null_part_Un[OF S] main_part_null_part_Int[OF S]
  have "S - main_part M S = null_part M S" by auto
  ultimately show sets: "null_part M S \<in> sets M" by auto
  from null_part[OF S] guess N ..
  with emeasure_eq_0[of N _ "null_part M S"] sets
  show "emeasure M (null_part M S) = 0" by auto
qed

lemma emeasure_main_part_UN:
  fixes S :: "nat \<Rightarrow> 'a set"
  assumes "range S \<subseteq> sets (completion M)"
  shows "emeasure M (main_part M (\<Union>i. (S i))) = emeasure M (\<Union>i. main_part M (S i))"
proof -
  have S: "\<And>i. S i \<in> sets (completion M)" using assms by auto
  then have UN: "(\<Union>i. S i) \<in> sets (completion M)" by auto
  have "\<forall>i. \<exists>N. N \<in> null_sets M \<and> null_part M (S i) \<subseteq> N"
    using null_part[OF S] by auto
  from choice[OF this] guess N .. note N = this
  then have UN_N: "(\<Union>i. N i) \<in> null_sets M" by (intro null_sets_UN) auto
  have "(\<Union>i. S i) \<in> sets (completion M)" using S by auto
  from null_part[OF this] guess N' .. note N' = this
  let ?N = "(\<Union>i. N i) \<union> N'"
  have null_set: "?N \<in> null_sets M" using N' UN_N by (intro null_sets.Un) auto
  have "main_part M (\<Union>i. S i) \<union> ?N = (main_part M (\<Union>i. S i) \<union> null_part M (\<Union>i. S i)) \<union> ?N"
    using N' by auto
  also have "\<dots> = (\<Union>i. main_part M (S i) \<union> null_part M (S i)) \<union> ?N"
    unfolding main_part_null_part_Un[OF S] main_part_null_part_Un[OF UN] by auto
  also have "\<dots> = (\<Union>i. main_part M (S i)) \<union> ?N"
    using N by auto
  finally have *: "main_part M (\<Union>i. S i) \<union> ?N = (\<Union>i. main_part M (S i)) \<union> ?N" .
  have "emeasure M (main_part M (\<Union>i. S i)) = emeasure M (main_part M (\<Union>i. S i) \<union> ?N)"
    using null_set UN by (intro emeasure_Un_null_set[symmetric]) auto
  also have "\<dots> = emeasure M ((\<Union>i. main_part M (S i)) \<union> ?N)"
    unfolding * ..
  also have "\<dots> = emeasure M (\<Union>i. main_part M (S i))"
    using null_set S by (intro emeasure_Un_null_set) auto
  finally show ?thesis .
qed

lemma emeasure_completion[simp]:
  assumes S: "S \<in> sets (completion M)" shows "emeasure (completion M) S = emeasure M (main_part M S)"
proof (subst emeasure_measure_of[OF completion_def completion_into_space])
  let ?\<mu> = "emeasure M \<circ> main_part M"
  show "S \<in> sets (completion M)" "?\<mu> S = emeasure M (main_part M S) " using S by simp_all
  show "positive (sets (completion M)) ?\<mu>"
    by (simp add: positive_def)
  show "countably_additive (sets (completion M)) ?\<mu>"
  proof (intro countably_additiveI)
    fix A :: "nat \<Rightarrow> 'a set" assume A: "range A \<subseteq> sets (completion M)" "disjoint_family A"
    have "disjoint_family (\<lambda>i. main_part M (A i))"
    proof (intro disjoint_family_on_bisimulation[OF A(2)])
      fix n m assume "A n \<inter> A m = {}"
      then have "(main_part M (A n) \<union> null_part M (A n)) \<inter> (main_part M (A m) \<union> null_part M (A m)) = {}"
        using A by (subst (1 2) main_part_null_part_Un) auto
      then show "main_part M (A n) \<inter> main_part M (A m) = {}" by auto
    qed
    then have "(\<Sum>n. emeasure M (main_part M (A n))) = emeasure M (\<Union>i. main_part M (A i))"
      using A by (auto intro!: suminf_emeasure)
    then show "(\<Sum>n. ?\<mu> (A n)) = ?\<mu> (UNION UNIV A)"
      by (simp add: completion_def emeasure_main_part_UN[OF A(1)])
  qed
qed

lemma emeasure_completion_UN:
  "range S \<subseteq> sets (completion M) \<Longrightarrow>
    emeasure (completion M) (\<Union>i::nat. (S i)) = emeasure M (\<Union>i. main_part M (S i))"
  by (subst emeasure_completion) (auto simp add: emeasure_main_part_UN)

lemma emeasure_completion_Un:
  assumes S: "S \<in> sets (completion M)" and T: "T \<in> sets (completion M)"
  shows "emeasure (completion M) (S \<union> T) = emeasure M (main_part M S \<union> main_part M T)"
proof (subst emeasure_completion)
  have UN: "(\<Union>i. binary (main_part M S) (main_part M T) i) = (\<Union>i. main_part M (binary S T i))"
    unfolding binary_def by (auto split: if_split_asm)
  show "emeasure M (main_part M (S \<union> T)) = emeasure M (main_part M S \<union> main_part M T)"
    using emeasure_main_part_UN[of "binary S T" M] assms
    by (simp add: range_binary_eq, simp add: Un_range_binary UN)
qed (auto intro: S T)

lemma sets_completionI_sub:
  assumes N: "N' \<in> null_sets M" "N \<subseteq> N'"
  shows "N \<in> sets (completion M)"
  using assms by (intro sets_completionI[of _ "{}" N N']) auto

lemma completion_ex_simple_function:
  assumes f: "simple_function (completion M) f"
  shows "\<exists>f'. simple_function M f' \<and> (AE x in M. f x = f' x)"
proof -
  let ?F = "\<lambda>x. f -` {x} \<inter> space M"
  have F: "\<And>x. ?F x \<in> sets (completion M)" and fin: "finite (f`space M)"
    using simple_functionD[OF f] simple_functionD[OF f] by simp_all
  have "\<forall>x. \<exists>N. N \<in> null_sets M \<and> null_part M (?F x) \<subseteq> N"
    using F null_part by auto
  from choice[OF this] obtain N where
    N: "\<And>x. null_part M (?F x) \<subseteq> N x" "\<And>x. N x \<in> null_sets M" by auto
  let ?N = "\<Union>x\<in>f`space M. N x"
  let ?f' = "\<lambda>x. if x \<in> ?N then undefined else f x"
  have sets: "?N \<in> null_sets M" using N fin by (intro null_sets.finite_UN) auto
  show ?thesis unfolding simple_function_def
  proof (safe intro!: exI[of _ ?f'])
    have "?f' ` space M \<subseteq> f`space M \<union> {undefined}" by auto
    from finite_subset[OF this] simple_functionD(1)[OF f]
    show "finite (?f' ` space M)" by auto
  next
    fix x assume "x \<in> space M"
    have "?f' -` {?f' x} \<inter> space M =
      (if x \<in> ?N then ?F undefined \<union> ?N
       else if f x = undefined then ?F (f x) \<union> ?N
       else ?F (f x) - ?N)"
      using N(2) sets.sets_into_space by (auto split: if_split_asm simp: null_sets_def)
    moreover { fix y have "?F y \<union> ?N \<in> sets M"
      proof cases
        assume y: "y \<in> f`space M"
        have "?F y \<union> ?N = (main_part M (?F y) \<union> null_part M (?F y)) \<union> ?N"
          using main_part_null_part_Un[OF F] by auto
        also have "\<dots> = main_part M (?F y) \<union> ?N"
          using y N by auto
        finally show ?thesis
          using F sets by auto
      next
        assume "y \<notin> f`space M" then have "?F y = {}" by auto
        then show ?thesis using sets by auto
      qed }
    moreover {
      have "?F (f x) - ?N = main_part M (?F (f x)) \<union> null_part M (?F (f x)) - ?N"
        using main_part_null_part_Un[OF F] by auto
      also have "\<dots> = main_part M (?F (f x)) - ?N"
        using N \<open>x \<in> space M\<close> by auto
      finally have "?F (f x) - ?N \<in> sets M"
        using F sets by auto }
    ultimately show "?f' -` {?f' x} \<inter> space M \<in> sets M" by auto
  next
    show "AE x in M. f x = ?f' x"
      by (rule AE_I', rule sets) auto
  qed
qed

lemma completion_ex_borel_measurable:
  fixes g :: "'a \<Rightarrow> ennreal"
  assumes g: "g \<in> borel_measurable (completion M)"
  shows "\<exists>g'\<in>borel_measurable M. (AE x in M. g x = g' x)"
proof -
  from g[THEN borel_measurable_implies_simple_function_sequence'] guess f . note f = this
  from this(1)[THEN completion_ex_simple_function]
  have "\<forall>i. \<exists>f'. simple_function M f' \<and> (AE x in M. f i x = f' x)" ..
  from this[THEN choice] obtain f' where
    sf: "\<And>i. simple_function M (f' i)" and
    AE: "\<forall>i. AE x in M. f i x = f' i x" by auto
  show ?thesis
  proof (intro bexI)
    from AE[unfolded AE_all_countable[symmetric]]
    show "AE x in M. g x = (SUP i. f' i x)" (is "AE x in M. g x = ?f x")
    proof (elim AE_mp, safe intro!: AE_I2)
      fix x assume eq: "\<forall>i. f i x = f' i x"
      moreover have "g x = (SUP i. f i x)"
        unfolding f by (auto split: split_max)
      ultimately show "g x = ?f x" by auto
    qed
    show "?f \<in> borel_measurable M"
      using sf[THEN borel_measurable_simple_function] by auto
  qed
qed

lemma null_sets_completionI: "N \<in> null_sets M \<Longrightarrow> N \<in> null_sets (completion M)"
  by (auto simp: null_sets_def)

lemma AE_completion: "(AE x in M. P x) \<Longrightarrow> (AE x in completion M. P x)"
  unfolding eventually_ae_filter by (auto intro: null_sets_completionI)

lemma null_sets_completion_iff: "N \<in> sets M \<Longrightarrow> N \<in> null_sets (completion M) \<longleftrightarrow> N \<in> null_sets M"
  by (auto simp: null_sets_def)

lemma AE_completion_iff: "{x\<in>space M. P x} \<in> sets M \<Longrightarrow> (AE x in M. P x) \<longleftrightarrow> (AE x in completion M. P x)"
  by (simp add: AE_iff_null null_sets_completion_iff)

lemma sets_completion_AE: "(AE x in M. \<not> P x) \<Longrightarrow> Measurable.pred (completion M) P"
  unfolding pred_def sets_completion eventually_ae_filter
  by auto

lemma null_sets_completion_iff2:
  "A \<in> null_sets (completion M) \<longleftrightarrow> (\<exists>N'\<in>null_sets M. A \<subseteq> N')"
proof safe
  assume "A \<in> null_sets (completion M)"
  then have A: "A \<in> sets (completion M)" and "main_part M A \<in> null_sets M"
    by (auto simp: null_sets_def)
  moreover obtain N where "N \<in> null_sets M" "null_part M A \<subseteq> N"
    using null_part[OF A] by auto
  ultimately show "\<exists>N'\<in>null_sets M. A \<subseteq> N'"
  proof (intro bexI)
    show "A \<subseteq> N \<union> main_part M A"
      using \<open>null_part M A \<subseteq> N\<close> by (subst main_part_null_part_Un[OF A, symmetric]) auto
  qed auto
next
  fix N assume "N \<in> null_sets M" "A \<subseteq> N"
  then have "A \<in> sets (completion M)" and N: "N \<in> sets M" "A \<subseteq> N" "emeasure M N = 0"
    by (auto intro: null_sets_completion)
  moreover have "emeasure (completion M) A = 0"
    using N by (intro emeasure_eq_0[of N _ A]) auto
  ultimately show "A \<in> null_sets (completion M)"
    by auto
qed

lemma null_sets_completion_subset:
  "B \<subseteq> A \<Longrightarrow> A \<in> null_sets (completion M) \<Longrightarrow> B \<in> null_sets (completion M)"
  unfolding null_sets_completion_iff2 by auto

lemma null_sets_restrict_space:
  "\<Omega> \<in> sets M \<Longrightarrow> A \<in> null_sets (restrict_space M \<Omega>) \<longleftrightarrow> A \<subseteq> \<Omega> \<and> A \<in> null_sets M"
  by (auto simp: null_sets_def emeasure_restrict_space sets_restrict_space)

lemma completion_ex_borel_measurable_real:
  fixes g :: "'a \<Rightarrow> real"
  assumes g: "g \<in> borel_measurable (completion M)"
  shows "\<exists>g'\<in>borel_measurable M. (AE x in M. g x = g' x)"
proof -
  have "(\<lambda>x. ennreal (g x)) \<in> completion M \<rightarrow>\<^sub>M borel" "(\<lambda>x. ennreal (- g x)) \<in> completion M \<rightarrow>\<^sub>M borel"
    using g by auto
  from this[THEN completion_ex_borel_measurable]
  obtain pf nf :: "'a \<Rightarrow> ennreal"
    where [measurable]: "nf \<in> M \<rightarrow>\<^sub>M borel" "pf \<in> M \<rightarrow>\<^sub>M borel"
      and ae: "AE x in M. pf x = ennreal (g x)" "AE x in M. nf x = ennreal (- g x)"
    by (auto simp: eq_commute)
  then have "AE x in M. pf x = ennreal (g x) \<and> nf x = ennreal (- g x)"
    by auto
  then obtain N where "N \<in> null_sets M" "{x\<in>space M. pf x \<noteq> ennreal (g x) \<and> nf x \<noteq> ennreal (- g x)} \<subseteq> N"
    by (auto elim!: AE_E)
  show ?thesis
  proof
    let ?F = "\<lambda>x. indicator (space M - N) x * (enn2real (pf x) - enn2real (nf x))"
    show "?F \<in> M \<rightarrow>\<^sub>M borel"
      using \<open>N \<in> null_sets M\<close> by auto
    show "AE x in M. g x = ?F x"
      using \<open>N \<in> null_sets M\<close>[THEN AE_not_in] ae AE_space
      apply eventually_elim
      subgoal for x
        by (cases "0::real" "g x" rule: linorder_le_cases) (auto simp: ennreal_neg)
      done
  qed
qed

lemma simple_function_completion: "simple_function M f \<Longrightarrow> simple_function (completion M) f"
  by (simp add: simple_function_def)

lemma simple_integral_completion:
  "simple_function M f \<Longrightarrow> simple_integral (completion M) f = simple_integral M f"
  unfolding simple_integral_def by simp

lemma nn_integral_completion: "nn_integral (completion M) f = nn_integral M f"
  unfolding nn_integral_def
proof (safe intro!: SUP_eq)
  fix s assume s: "simple_function (completion M) s" and "s \<le> f"
  then obtain s' where s': "simple_function M s'" "AE x in M. s x = s' x"
    by (auto dest: completion_ex_simple_function)
  then obtain N where N: "N \<in> null_sets M" "{x\<in>space M. s x \<noteq> s' x} \<subseteq> N"
    by (auto elim!: AE_E)
  then have ae_N: "AE x in M. (s x \<noteq> s' x \<longrightarrow> x \<in> N) \<and> x \<notin> N"
    by (auto dest: AE_not_in)
  define s'' where "s'' x = (if x \<in> N then 0 else s x)" for x
  then have ae_s_eq_s'': "AE x in completion M. s x = s'' x"
    using s' ae_N by (intro AE_completion) auto
  have s'': "simple_function M s''"
  proof (subst simple_function_cong)
    show "t \<in> space M \<Longrightarrow> s'' t = (if t \<in> N then 0 else s' t)" for t
      using N by (auto simp: s''_def dest: sets.sets_into_space)
    show "simple_function M (\<lambda>t. if t \<in> N then 0 else s' t)"
      unfolding s''_def[abs_def] using N by (auto intro!: simple_function_If s')
  qed

  show "\<exists>j\<in>{g. simple_function M g \<and> g \<le> f}. integral\<^sup>S (completion M) s \<le> integral\<^sup>S M j"
  proof (safe intro!: bexI[of _ s''])
    have "integral\<^sup>S (completion M) s = integral\<^sup>S (completion M) s''"
      by (intro simple_integral_cong_AE s simple_function_completion s'' ae_s_eq_s'')
    then show "integral\<^sup>S (completion M) s \<le> integral\<^sup>S M s''"
      using s'' by (simp add: simple_integral_completion)
    from \<open>s \<le> f\<close> show "s'' \<le> f"
      unfolding s''_def le_fun_def by auto
  qed fact
next
  fix s assume "simple_function M s" "s \<le> f"
  then show "\<exists>j\<in>{g. simple_function (completion M) g \<and> g \<le> f}. integral\<^sup>S M s \<le> integral\<^sup>S (completion M) j"
    by (intro bexI[of _ s]) (auto simp: simple_integral_completion simple_function_completion)
qed

locale semifinite_measure =
  fixes M :: "'a measure"
  assumes semifinite:
    "\<And>A. A \<in> sets M \<Longrightarrow> emeasure M A = \<infinity> \<Longrightarrow> \<exists>B\<in>sets M. B \<subseteq> A \<and> emeasure M B < \<infinity>"

locale locally_determined_measure = semifinite_measure +
  assumes locally_determined:
    "\<And>A. A \<subseteq> space M \<Longrightarrow> (\<And>B. B \<in> sets M \<Longrightarrow> emeasure M B < \<infinity> \<Longrightarrow> A \<inter> B \<in> sets M) \<Longrightarrow> A \<in> sets M"

locale cld_measure = complete_measure M + locally_determined_measure M for M :: "'a measure"

definition outer_measure_of :: "'a measure \<Rightarrow> 'a set \<Rightarrow> ennreal"
  where "outer_measure_of M A = (INF B : {B\<in>sets M. A \<subseteq> B}. emeasure M B)"

lemma outer_measure_of_eq[simp]: "A \<in> sets M \<Longrightarrow> outer_measure_of M A = emeasure M A"
  by (auto simp: outer_measure_of_def intro!: INF_eqI emeasure_mono)

lemma outer_measure_of_mono: "A \<subseteq> B \<Longrightarrow> outer_measure_of M A \<le> outer_measure_of M B"
  unfolding outer_measure_of_def by (intro INF_superset_mono) auto

lemma outer_measure_of_attain:
  assumes "A \<subseteq> space M"
  shows "\<exists>E\<in>sets M. A \<subseteq> E \<and> outer_measure_of M A = emeasure M E"
proof -
  have "emeasure M ` {B \<in> sets M. A \<subseteq> B} \<noteq> {}"
    using \<open>A \<subseteq> space M\<close> by auto
  from ennreal_Inf_countable_INF[OF this]
  obtain f
    where f: "range f \<subseteq> emeasure M ` {B \<in> sets M. A \<subseteq> B}" "decseq f"
      and "outer_measure_of M A = (INF i. f i)"
    unfolding outer_measure_of_def by auto
  have "\<exists>E. \<forall>n. (E n \<in> sets M \<and> A \<subseteq> E n \<and> emeasure M (E n) \<le> f n) \<and> E (Suc n) \<subseteq> E n"
  proof (rule dependent_nat_choice)
    show "\<exists>x. x \<in> sets M \<and> A \<subseteq> x \<and> emeasure M x \<le> f 0"
      using f(1) by (fastforce simp: image_subset_iff image_iff intro: eq_refl[OF sym])
  next
    fix E n assume "E \<in> sets M \<and> A \<subseteq> E \<and> emeasure M E \<le> f n"
    moreover obtain F where "F \<in> sets M" "A \<subseteq> F" "f (Suc n) = emeasure M F"
      using f(1) by (auto simp: image_subset_iff image_iff)
    ultimately show "\<exists>y. (y \<in> sets M \<and> A \<subseteq> y \<and> emeasure M y \<le> f (Suc n)) \<and> y \<subseteq> E"
      by (auto intro!: exI[of _ "F \<inter> E"] emeasure_mono)
  qed
  then obtain E
    where [simp]: "\<And>n. E n \<in> sets M"
      and "\<And>n. A \<subseteq> E n"
      and le_f: "\<And>n. emeasure M (E n) \<le> f n"
      and "decseq E"
    by (auto simp: decseq_Suc_iff)
  show ?thesis
  proof cases
    assume fin: "\<exists>i. emeasure M (E i) < \<infinity>"
    show ?thesis
    proof (intro bexI[of _ "\<Inter>i. E i"] conjI)
      show "A \<subseteq> (\<Inter>i. E i)" "(\<Inter>i. E i) \<in> sets M"
        using \<open>\<And>n. A \<subseteq> E n\<close> by auto

      have " (INF i. emeasure M (E i)) \<le> outer_measure_of M A"
        unfolding \<open>outer_measure_of M A = (INF n. f n)\<close>
        by (intro INF_superset_mono le_f) auto
      moreover have "outer_measure_of M A \<le> (INF i. outer_measure_of M (E i))"
        by (intro INF_greatest outer_measure_of_mono \<open>\<And>n. A \<subseteq> E n\<close>)
      ultimately have "outer_measure_of M A = (INF i. emeasure M (E i))"
        by auto
      also have "\<dots> = emeasure M (\<Inter>i. E i)"
        using fin by (intro INF_emeasure_decseq' \<open>decseq E\<close>) (auto simp: less_top)
      finally show "outer_measure_of M A = emeasure M (\<Inter>i. E i)" .
    qed
  next
    assume "\<nexists>i. emeasure M (E i) < \<infinity>"
    then have "f n = \<infinity>" for n
      using le_f by (auto simp: not_less top_unique)
    moreover have "\<exists>E\<in>sets M. A \<subseteq> E \<and> f 0 = emeasure M E"
      using f by auto
    ultimately show ?thesis
      unfolding \<open>outer_measure_of M A = (INF n. f n)\<close> by simp
  qed
qed

lemma SUP_outer_measure_of_incseq:
  assumes A: "\<And>n. A n \<subseteq> space M" and "incseq A"
  shows "(SUP n. outer_measure_of M (A n)) = outer_measure_of M (\<Union>i. A i)"
proof (rule antisym)
  obtain E
    where E: "\<And>n. E n \<in> sets M" "\<And>n. A n \<subseteq> E n" "\<And>n. outer_measure_of M (A n) = emeasure M (E n)"
    using outer_measure_of_attain[OF A] by metis

  define F where "F n = (\<Inter>i\<in>{n ..}. E i)" for n
  with E have F: "incseq F" "\<And>n. F n \<in> sets M"
    by (auto simp: incseq_def)
  have "A n \<subseteq> F n" for n
    using incseqD[OF \<open>incseq A\<close>, of n] \<open>\<And>n. A n \<subseteq> E n\<close> by (auto simp: F_def)

  have eq: "outer_measure_of M (A n) = outer_measure_of M (F n)" for n
  proof (intro antisym)
    have "outer_measure_of M (F n) \<le> outer_measure_of M (E n)"
      by (intro outer_measure_of_mono) (auto simp add: F_def)
    with E show "outer_measure_of M (F n) \<le> outer_measure_of M (A n)"
      by auto
    show "outer_measure_of M (A n) \<le> outer_measure_of M (F n)"
      by (intro outer_measure_of_mono \<open>A n \<subseteq> F n\<close>)
  qed

  have "outer_measure_of M (\<Union>n. A n) \<le> outer_measure_of M (\<Union>n. F n)"
    using \<open>\<And>n. A n \<subseteq> F n\<close> by (intro outer_measure_of_mono) auto
  also have "\<dots> = (SUP n. emeasure M (F n))"
    using F by (simp add: SUP_emeasure_incseq subset_eq)
  finally show "outer_measure_of M (\<Union>n. A n) \<le> (SUP n. outer_measure_of M (A n))"
    by (simp add: eq F)
qed (auto intro: SUP_least outer_measure_of_mono)

definition measurable_envelope :: "'a measure \<Rightarrow> 'a set \<Rightarrow> 'a set \<Rightarrow> bool"
  where "measurable_envelope M A E \<longleftrightarrow>
    (A \<subseteq> E \<and> E \<in> sets M \<and> (\<forall>F\<in>sets M. emeasure M (F \<inter> E) = outer_measure_of M (F \<inter> A)))"

lemma measurable_envelopeD:
  assumes "measurable_envelope M A E"
  shows "A \<subseteq> E"
    and "E \<in> sets M"
    and "\<And>F. F \<in> sets M \<Longrightarrow> emeasure M (F \<inter> E) = outer_measure_of M (F \<inter> A)"
    and "A \<subseteq> space M"
  using assms sets.sets_into_space[of E] by (auto simp: measurable_envelope_def)

lemma measurable_envelopeD1:
  assumes E: "measurable_envelope M A E" and F: "F \<in> sets M" "F \<subseteq> E - A"
  shows "emeasure M F = 0"
proof -
  have "emeasure M F = emeasure M (F \<inter> E)"
    using F by (intro arg_cong2[where f=emeasure]) auto
  also have "\<dots> = outer_measure_of M (F \<inter> A)"
    using measurable_envelopeD[OF E] \<open>F \<in> sets M\<close> by (auto simp: measurable_envelope_def)
  also have "\<dots> = outer_measure_of M {}"
    using \<open>F \<subseteq> E - A\<close> by (intro arg_cong2[where f=outer_measure_of]) auto
  finally show "emeasure M F = 0"
    by simp
qed

lemma measurable_envelope_eq1:
  assumes "A \<subseteq> E" "E \<in> sets M"
  shows "measurable_envelope M A E \<longleftrightarrow> (\<forall>F\<in>sets M. F \<subseteq> E - A \<longrightarrow> emeasure M F = 0)"
proof safe
  assume *: "\<forall>F\<in>sets M. F \<subseteq> E - A \<longrightarrow> emeasure M F = 0"
  show "measurable_envelope M A E"
    unfolding measurable_envelope_def
  proof (rule ccontr, auto simp add: \<open>E \<in> sets M\<close> \<open>A \<subseteq> E\<close>)
    fix F assume "F \<in> sets M" "emeasure M (F \<inter> E) \<noteq> outer_measure_of M (F \<inter> A)"
    then have "outer_measure_of M (F \<inter> A) < emeasure M (F \<inter> E)"
      using outer_measure_of_mono[of "F \<inter> A" "F \<inter> E" M] \<open>A \<subseteq> E\<close> \<open>E \<in> sets M\<close> by (auto simp: less_le)
    then obtain G where G: "G \<in> sets M" "F \<inter> A \<subseteq> G" and less: "emeasure M G < emeasure M (E \<inter> F)"
      unfolding outer_measure_of_def INF_less_iff by (auto simp: ac_simps)
    have le: "emeasure M (G \<inter> E \<inter> F) \<le> emeasure M G"
      using \<open>E \<in> sets M\<close> \<open>G \<in> sets M\<close> \<open>F \<in> sets M\<close> by (auto intro!: emeasure_mono)

    from G have "E \<inter> F - G \<in> sets M" "E \<inter> F - G \<subseteq> E - A"
      using \<open>F \<in> sets M\<close> \<open>E \<in> sets M\<close> by auto
    with * have "0 = emeasure M (E \<inter> F - G)"
      by auto
    also have "E \<inter> F - G = E \<inter> F - (G \<inter> E \<inter> F)"
      by auto
    also have "emeasure M (E \<inter> F - (G \<inter> E \<inter> F)) = emeasure M (E \<inter> F) - emeasure M (G \<inter> E \<inter> F)"
      using \<open>E \<in> sets M\<close> \<open>F \<in> sets M\<close> le less G by (intro emeasure_Diff) (auto simp: top_unique)
    also have "\<dots> > 0"
      using le less by (intro diff_gr0_ennreal) auto
    finally show False by auto
  qed
qed (rule measurable_envelopeD1)

lemma measurable_envelopeD2:
  assumes E: "measurable_envelope M A E" shows "emeasure M E = outer_measure_of M A"
proof -
  from \<open>measurable_envelope M A E\<close> have "emeasure M (E \<inter> E) = outer_measure_of M (E \<inter> A)"
    by (auto simp: measurable_envelope_def)
  with measurable_envelopeD[OF E] show "emeasure M E = outer_measure_of M A"
    by (auto simp: Int_absorb1)
qed

lemma measurable_envelope_eq2:
  assumes "A \<subseteq> E" "E \<in> sets M" "emeasure M E < \<infinity>"
  shows "measurable_envelope M A E \<longleftrightarrow> (emeasure M E = outer_measure_of M A)"
proof safe
  assume *: "emeasure M E = outer_measure_of M A"
  show "measurable_envelope M A E"
    unfolding measurable_envelope_eq1[OF \<open>A \<subseteq> E\<close> \<open>E \<in> sets M\<close>]
  proof (intro conjI ballI impI assms)
    fix F assume F: "F \<in> sets M" "F \<subseteq> E - A"
    with \<open>E \<in> sets M\<close> have le: "emeasure M F \<le> emeasure M  E"
      by (intro emeasure_mono) auto
    from F \<open>A \<subseteq> E\<close> have "outer_measure_of M A \<le> outer_measure_of M (E - F)"
      by (intro outer_measure_of_mono) auto
    then have "emeasure M E - 0 \<le> emeasure M (E - F)"
      using * \<open>E \<in> sets M\<close> \<open>F \<in> sets M\<close> by simp
    also have "\<dots> = emeasure M E - emeasure M F"
      using \<open>E \<in> sets M\<close> \<open>emeasure M E < \<infinity>\<close> F le by (intro emeasure_Diff) (auto simp: top_unique)
    finally show "emeasure M F = 0"
      using ennreal_mono_minus_cancel[of "emeasure M E" 0 "emeasure M F"] le assms by auto
  qed
qed (auto intro: measurable_envelopeD2)

lemma measurable_envelopeI_countable:
  fixes A :: "nat \<Rightarrow> 'a set"
  assumes E: "\<And>n. measurable_envelope M (A n) (E n)"
  shows "measurable_envelope M (\<Union>n. A n) (\<Union>n. E n)"
proof (subst measurable_envelope_eq1)
  show "(\<Union>n. A n) \<subseteq> (\<Union>n. E n)" "(\<Union>n. E n) \<in> sets M"
    using measurable_envelopeD(1,2)[OF E] by auto
  show "\<forall>F\<in>sets M. F \<subseteq> (\<Union>n. E n) - (\<Union>n. A n) \<longrightarrow> emeasure M F = 0"
  proof safe
    fix F assume F: "F \<in> sets M" "F \<subseteq> (\<Union>n. E n) - (\<Union>n. A n)"
    then have "F \<inter> E n \<in> sets M" "F \<inter> E n \<subseteq> E n - A n" "F \<subseteq> (\<Union>n. E n)" for n
      using measurable_envelopeD(1,2)[OF E] by auto
    then have "emeasure M (\<Union>n. F \<inter> E n) = 0"
      by (intro emeasure_UN_eq_0 measurable_envelopeD1[OF E]) auto
    then show "emeasure M F = 0"
      using \<open>F \<subseteq> (\<Union>n. E n)\<close> by (auto simp: Int_absorb2)
  qed
qed

lemma measurable_envelopeI_countable_cover:
  fixes A and C :: "nat \<Rightarrow> 'a set"
  assumes C: "A \<subseteq> (\<Union>n. C n)" "\<And>n. C n \<in> sets M" "\<And>n. emeasure M (C n) < \<infinity>"
  shows "\<exists>E\<subseteq>(\<Union>n. C n). measurable_envelope M A E"
proof -
  have "A \<inter> C n \<subseteq> space M" for n
    using \<open>C n \<in> sets M\<close> by (auto dest: sets.sets_into_space)
  then have "\<forall>n. \<exists>E\<in>sets M. A \<inter> C n \<subseteq> E \<and> outer_measure_of M (A \<inter> C n) = emeasure M E"
    using outer_measure_of_attain[of "A \<inter> C n" M for n] by auto
  then obtain E
    where E: "\<And>n. E n \<in> sets M" "\<And>n. A \<inter> C n \<subseteq> E n"
      and eq: "\<And>n. outer_measure_of M (A \<inter> C n) = emeasure M (E n)"
    by metis

  have "outer_measure_of M (A \<inter> C n) \<le> outer_measure_of M (E n \<inter> C n)" for n
    using E by (intro outer_measure_of_mono) auto
  moreover have "outer_measure_of M (E n \<inter> C n) \<le> outer_measure_of M (E n)" for n
    by (intro outer_measure_of_mono) auto
  ultimately have eq: "outer_measure_of M (A \<inter> C n) = emeasure M (E n \<inter> C n)" for n
    using E C by (intro antisym) (auto simp: eq)

  { fix n
    have "outer_measure_of M (A \<inter> C n) \<le> outer_measure_of M (C n)"
      by (intro outer_measure_of_mono) simp
    also have "\<dots> < \<infinity>"
      using assms by auto
    finally have "emeasure M (E n \<inter> C n) < \<infinity>"
      using eq by simp }
  then have "measurable_envelope M (\<Union>n. A \<inter> C n) (\<Union>n. E n \<inter> C n)"
    using E C by (intro measurable_envelopeI_countable measurable_envelope_eq2[THEN iffD2]) (auto simp: eq)
  with \<open>A \<subseteq> (\<Union>n. C n)\<close> show ?thesis
    by (intro exI[of _ "(\<Union>n. E n \<inter> C n)"]) (auto simp add: Int_absorb2)
qed

lemma (in complete_measure) complete_sets_sandwich:
  assumes [measurable]: "A \<in> sets M" "C \<in> sets M" and subset: "A \<subseteq> B" "B \<subseteq> C"
    and measure: "emeasure M A = emeasure M C" "emeasure M A < \<infinity>"
  shows "B \<in> sets M"
proof -
  have "B - A \<in> sets M"
  proof (rule complete)
    show "B - A \<subseteq> C - A"
      using subset by auto
    show "C - A \<in> null_sets M"
      using measure subset by(simp add: emeasure_Diff null_setsI)
  qed
  then have "A \<union> (B - A) \<in> sets M"
    by measurable
  also have "A \<union> (B - A) = B"
    using \<open>A \<subseteq> B\<close> by auto
  finally show ?thesis .
qed

lemma (in cld_measure) notin_sets_outer_measure_of_cover:
  assumes E: "E \<subseteq> space M" "E \<notin> sets M"
  shows "\<exists>B\<in>sets M. 0 < emeasure M B \<and> emeasure M B < \<infinity> \<and>
    outer_measure_of M (B \<inter> E) = emeasure M B \<and> outer_measure_of M (B - E) = emeasure M B"
proof -
  from locally_determined[OF \<open>E \<subseteq> space M\<close>] \<open>E \<notin> sets M\<close>
  obtain F
    where [measurable]: "F \<in> sets M" and "emeasure M F < \<infinity>" "E \<inter> F \<notin> sets M"
    by blast
  then obtain H H'
    where H: "measurable_envelope M (F \<inter> E) H" and H': "measurable_envelope M (F - E) H'"
    using measurable_envelopeI_countable_cover[of "F \<inter> E" "\<lambda>_. F" M]
       measurable_envelopeI_countable_cover[of "F - E" "\<lambda>_. F" M]
    by auto
  note measurable_envelopeD(2)[OF H', measurable] measurable_envelopeD(2)[OF H, measurable]

  from measurable_envelopeD(1)[OF H'] measurable_envelopeD(1)[OF H]
  have subset: "F - H' \<subseteq> F \<inter> E" "F \<inter> E \<subseteq> F \<inter> H"
    by auto
  moreover define G where "G = (F \<inter> H) - (F - H')"
  ultimately have G: "G = F \<inter> H \<inter> H'"
    by auto
  have "emeasure M (F \<inter> H) \<noteq> 0"
  proof
    assume "emeasure M (F \<inter> H) = 0"
    then have "F \<inter> H \<in> null_sets M"
      by auto
    with \<open>E \<inter> F \<notin> sets M\<close> show False
      using complete[OF \<open>F \<inter> E \<subseteq> F \<inter> H\<close>] by (auto simp: Int_commute)
  qed
  moreover
  have "emeasure M (F - H') \<noteq> emeasure M (F \<inter> H)"
  proof
    assume "emeasure M (F - H') = emeasure M (F \<inter> H)"
    with \<open>E \<inter> F \<notin> sets M\<close> emeasure_mono[of "F \<inter> H" F M] \<open>emeasure M F < \<infinity>\<close>
    have "F \<inter> E \<in> sets M"
      by (intro complete_sets_sandwich[OF _ _ subset]) auto
    with \<open>E \<inter> F \<notin> sets M\<close> show False
      by (simp add: Int_commute)
  qed
  moreover have "emeasure M (F - H') \<le> emeasure M (F \<inter> H)"
    using subset by (intro emeasure_mono) auto
  ultimately have "emeasure M G \<noteq> 0"
    unfolding G_def using subset
    by (subst emeasure_Diff) (auto simp: top_unique diff_eq_0_iff_ennreal)
  show ?thesis
  proof (intro bexI conjI)
    have "emeasure M G \<le> emeasure M F"
      unfolding G by (auto intro!: emeasure_mono)
    with \<open>emeasure M F < \<infinity>\<close> show "0 < emeasure M G" "emeasure M G < \<infinity>"
      using \<open>emeasure M G \<noteq> 0\<close> by (auto simp: zero_less_iff_neq_zero)
    show [measurable]: "G \<in> sets M"
      unfolding G by auto

    have "emeasure M G = outer_measure_of M (F \<inter> H' \<inter> (F \<inter> E))"
      using measurable_envelopeD(3)[OF H, of "F \<inter> H'"] unfolding G by (simp add: ac_simps)
    also have "\<dots> \<le> outer_measure_of M (G \<inter> E)"
      using measurable_envelopeD(1)[OF H] by (intro outer_measure_of_mono) (auto simp: G)
    finally show "outer_measure_of M (G \<inter> E) = emeasure M G"
      using outer_measure_of_mono[of "G \<inter> E" G M] by auto

    have "emeasure M G = outer_measure_of M (F \<inter> H \<inter> (F - E))"
      using measurable_envelopeD(3)[OF H', of "F \<inter> H"] unfolding G by (simp add: ac_simps)
    also have "\<dots> \<le> outer_measure_of M (G - E)"
      using measurable_envelopeD(1)[OF H'] by (intro outer_measure_of_mono) (auto simp: G)
    finally show "outer_measure_of M (G - E) = emeasure M G"
      using outer_measure_of_mono[of "G - E" G M] by auto
  qed
qed

text \<open>The following theorem is a specialization of D.H. Fremlin, Measure Theory vol 4I (413G). We
  only show one direction and do not use a inner regular family $K$.\<close>

lemma (in cld_measure) borel_measurable_cld:
  fixes f :: "'a \<Rightarrow> real"
  assumes "\<And>A a b. A \<in> sets M \<Longrightarrow> 0 < emeasure M A \<Longrightarrow> emeasure M A < \<infinity> \<Longrightarrow> a < b \<Longrightarrow>
      min (outer_measure_of M {x\<in>A. f x \<le> a}) (outer_measure_of M {x\<in>A. b \<le> f x}) < emeasure M A"
  shows "f \<in> M \<rightarrow>\<^sub>M borel"
proof (rule ccontr)
  let ?E = "\<lambda>a. {x\<in>space M. f x \<le> a}" and ?F = "\<lambda>a. {x\<in>space M. a \<le> f x}"

  assume "f \<notin> M \<rightarrow>\<^sub>M borel"
  then obtain a where "?E a \<notin> sets M"
    unfolding borel_measurable_iff_le by blast
  from notin_sets_outer_measure_of_cover[OF _ this]
  obtain K
    where K: "K \<in> sets M" "0 < emeasure M K" "emeasure M K < \<infinity>"
      and eq1: "outer_measure_of M (K \<inter> ?E a) = emeasure M K"
      and eq2: "outer_measure_of M (K - ?E a) = emeasure M K"
    by auto
  then have me_K: "measurable_envelope M (K \<inter> ?E a) K"
    by (subst measurable_envelope_eq2) auto

  define b where "b n = a + inverse (real (Suc n))" for n
  have "(SUP n. outer_measure_of M (K \<inter> ?F (b n))) = outer_measure_of M (\<Union>n. K \<inter> ?F (b n))"
  proof (intro SUP_outer_measure_of_incseq)
    have "x \<le> y \<Longrightarrow> b y \<le> b x" for x y
      by (auto simp: b_def field_simps)
    then show "incseq (\<lambda>n. K \<inter> {x \<in> space M. b n \<le> f x})"
      by (auto simp: incseq_def intro: order_trans)
  qed auto
  also have "(\<Union>n. K \<inter> ?F (b n)) = K - ?E a"
  proof -
    have "b \<longlonglongrightarrow> a"
      unfolding b_def by (rule LIMSEQ_inverse_real_of_nat_add)
    then have "\<forall>n. \<not> b n \<le> f x \<Longrightarrow> f x \<le> a" for x
      by (rule LIMSEQ_le_const) (auto intro: less_imp_le simp: not_le)
    moreover have "\<not> b n \<le> a" for n
      by (auto simp: b_def)
    ultimately show ?thesis
      using \<open>K \<in> sets M\<close>[THEN sets.sets_into_space] by (auto simp: subset_eq intro: order_trans)
  qed
  finally have "0 < (SUP n. outer_measure_of M (K \<inter> ?F (b n)))"
    using K by (simp add: eq2)
  then obtain n where pos_b: "0 < outer_measure_of M (K \<inter> ?F (b n))" and "a < b n"
    unfolding less_SUP_iff by (auto simp: b_def)
  from measurable_envelopeI_countable_cover[of "K \<inter> ?F (b n)" "\<lambda>_. K" M] K
  obtain K' where "K' \<subseteq> K" and me_K': "measurable_envelope M (K \<inter> ?F (b n)) K'"
    by auto
  then have K'_le_K: "emeasure M K' \<le> emeasure M K"
    by (intro emeasure_mono K)
  have "K' \<in> sets M"
    using me_K' by (rule measurable_envelopeD)

  have "min (outer_measure_of M {x\<in>K'. f x \<le> a}) (outer_measure_of M {x\<in>K'. b n \<le> f x}) < emeasure M K'"
  proof (rule assms)
    show "0 < emeasure M K'" "emeasure M K' < \<infinity>"
      using measurable_envelopeD2[OF me_K'] pos_b K K'_le_K by auto
  qed fact+
  also have "{x\<in>K'. f x \<le> a} = K' \<inter> (K \<inter> ?E a)"
    using \<open>K' \<in> sets M\<close>[THEN sets.sets_into_space] \<open>K' \<subseteq> K\<close> by auto
  also have "{x\<in>K'. b n \<le> f x} = K' \<inter> (K \<inter> ?F (b n))"
    using \<open>K' \<in> sets M\<close>[THEN sets.sets_into_space] \<open>K' \<subseteq> K\<close> by auto
  finally have "min (emeasure M K) (emeasure M K') < emeasure M K'"
    unfolding
      measurable_envelopeD(3)[OF me_K \<open>K' \<in> sets M\<close>, symmetric]
      measurable_envelopeD(3)[OF me_K' \<open>K' \<in> sets M\<close>, symmetric]
    using \<open>K' \<subseteq> K\<close> by (simp add: Int_absorb1 Int_absorb2)
  with K'_le_K show False
    by (auto simp: min_def split: if_split_asm)
qed

end

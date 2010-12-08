(*  Title:      Complete_Measure.thy
    Author:     Robert Himmelmann, Johannes Hoelzl, TU Muenchen
*)
theory Complete_Measure
imports Product_Measure
begin

locale completeable_measure_space = measure_space

definition (in completeable_measure_space) completion :: "'a algebra" where
  "completion = \<lparr> space = space M,
    sets = { S \<union> N |S N N'. S \<in> sets M \<and> N' \<in> null_sets \<and> N \<subseteq> N' } \<rparr>"

lemma (in completeable_measure_space) space_completion[simp]:
  "space completion = space M" unfolding completion_def by simp

lemma (in completeable_measure_space) sets_completionE:
  assumes "A \<in> sets completion"
  obtains S N N' where "A = S \<union> N" "N \<subseteq> N'" "N' \<in> null_sets" "S \<in> sets M"
  using assms unfolding completion_def by auto

lemma (in completeable_measure_space) sets_completionI:
  assumes "A = S \<union> N" "N \<subseteq> N'" "N' \<in> null_sets" "S \<in> sets M"
  shows "A \<in> sets completion"
  using assms unfolding completion_def by auto

lemma (in completeable_measure_space) sets_completionI_sets[intro]:
  "A \<in> sets M \<Longrightarrow> A \<in> sets completion"
  unfolding completion_def by force

lemma (in completeable_measure_space) null_sets_completion:
  assumes "N' \<in> null_sets" "N \<subseteq> N'" shows "N \<in> sets completion"
  apply(rule sets_completionI[of N "{}" N N'])
  using assms by auto

sublocale completeable_measure_space \<subseteq> completion!: sigma_algebra completion
proof (unfold sigma_algebra_iff2, safe)
  fix A x assume "A \<in> sets completion" "x \<in> A"
  with sets_into_space show "x \<in> space completion"
    by (auto elim!: sets_completionE)
next
  fix A assume "A \<in> sets completion"
  from this[THEN sets_completionE] guess S N N' . note A = this
  let ?C = "space completion"
  show "?C - A \<in> sets completion" using A
    by (intro sets_completionI[of _ "(?C - S) \<inter> (?C - N')" "(?C - S) \<inter> N' \<inter> (?C - N)"])
       auto
next
  fix A ::"nat \<Rightarrow> 'a set" assume A: "range A \<subseteq> sets completion"
  then have "\<forall>n. \<exists>S N N'. A n = S \<union> N \<and> S \<in> sets M \<and> N' \<in> null_sets \<and> N \<subseteq> N'"
    unfolding completion_def by (auto simp: image_subset_iff)
  from choice[OF this] guess S ..
  from choice[OF this] guess N ..
  from choice[OF this] guess N' ..
  then show "UNION UNIV A \<in> sets completion"
    using null_sets_UN[of N']
    by (intro sets_completionI[of _ "UNION UNIV S" "UNION UNIV N" "UNION UNIV N'"])
       auto
qed auto

definition (in completeable_measure_space)
  "split_completion A p = (\<exists>N'. A = fst p \<union> snd p \<and> fst p \<inter> snd p = {} \<and>
    fst p \<in> sets M \<and> snd p \<subseteq> N' \<and> N' \<in> null_sets)"

definition (in completeable_measure_space)
  "main_part A = fst (Eps (split_completion A))"

definition (in completeable_measure_space)
  "null_part A = snd (Eps (split_completion A))"

lemma (in completeable_measure_space) split_completion:
  assumes "A \<in> sets completion"
  shows "split_completion A (main_part A, null_part A)"
  unfolding main_part_def null_part_def
proof (rule someI2_ex)
  from assms[THEN sets_completionE] guess S N N' . note A = this
  let ?P = "(S, N - S)"
  show "\<exists>p. split_completion A p"
    unfolding split_completion_def using A
  proof (intro exI conjI)
    show "A = fst ?P \<union> snd ?P" using A by auto
    show "snd ?P \<subseteq> N'" using A by auto
  qed auto
qed auto

lemma (in completeable_measure_space)
  assumes "S \<in> sets completion"
  shows main_part_sets[intro, simp]: "main_part S \<in> sets M"
    and main_part_null_part_Un[simp]: "main_part S \<union> null_part S = S"
    and main_part_null_part_Int[simp]: "main_part S \<inter> null_part S = {}"
  using split_completion[OF assms] by (auto simp: split_completion_def)

lemma (in completeable_measure_space) null_part:
  assumes "S \<in> sets completion" shows "\<exists>N. N\<in>null_sets \<and> null_part S \<subseteq> N"
  using split_completion[OF assms] by (auto simp: split_completion_def)

lemma (in completeable_measure_space) null_part_sets[intro, simp]:
  assumes "S \<in> sets M" shows "null_part S \<in> sets M" "\<mu> (null_part S) = 0"
proof -
  have S: "S \<in> sets completion" using assms by auto
  have "S - main_part S \<in> sets M" using assms by auto
  moreover
  from main_part_null_part_Un[OF S] main_part_null_part_Int[OF S]
  have "S - main_part S = null_part S" by auto
  ultimately show sets: "null_part S \<in> sets M" by auto
  from null_part[OF S] guess N ..
  with measure_eq_0[of N "null_part S"] sets
  show "\<mu> (null_part S) = 0" by auto
qed

definition (in completeable_measure_space) "\<mu>' A = \<mu> (main_part A)"

lemma (in completeable_measure_space) \<mu>'_set[simp]:
  assumes "S \<in> sets M" shows "\<mu>' S = \<mu> S"
proof -
  have S: "S \<in> sets completion" using assms by auto
  then have "\<mu> S = \<mu> (main_part S \<union> null_part S)" by simp
  also have "\<dots> = \<mu> (main_part S)"
    using S assms measure_additive[of "main_part S" "null_part S"]
    by (auto simp: measure_additive)
  finally show ?thesis unfolding \<mu>'_def by simp
qed

lemma (in completeable_measure_space) sets_completionI_sub:
  assumes N: "N' \<in> null_sets" "N \<subseteq> N'"
  shows "N \<in> sets completion"
  using assms by (intro sets_completionI[of _ "{}" N N']) auto

lemma (in completeable_measure_space) \<mu>_main_part_UN:
  fixes S :: "nat \<Rightarrow> 'a set"
  assumes "range S \<subseteq> sets completion"
  shows "\<mu>' (\<Union>i. (S i)) = \<mu> (\<Union>i. main_part (S i))"
proof -
  have S: "\<And>i. S i \<in> sets completion" using assms by auto
  then have UN: "(\<Union>i. S i) \<in> sets completion" by auto
  have "\<forall>i. \<exists>N. N \<in> null_sets \<and> null_part (S i) \<subseteq> N"
    using null_part[OF S] by auto
  from choice[OF this] guess N .. note N = this
  then have UN_N: "(\<Union>i. N i) \<in> null_sets" by (intro null_sets_UN) auto
  have "(\<Union>i. S i) \<in> sets completion" using S by auto
  from null_part[OF this] guess N' .. note N' = this
  let ?N = "(\<Union>i. N i) \<union> N'"
  have null_set: "?N \<in> null_sets" using N' UN_N by (intro null_sets_Un) auto
  have "main_part (\<Union>i. S i) \<union> ?N = (main_part (\<Union>i. S i) \<union> null_part (\<Union>i. S i)) \<union> ?N"
    using N' by auto
  also have "\<dots> = (\<Union>i. main_part (S i) \<union> null_part (S i)) \<union> ?N"
    unfolding main_part_null_part_Un[OF S] main_part_null_part_Un[OF UN] by auto
  also have "\<dots> = (\<Union>i. main_part (S i)) \<union> ?N"
    using N by auto
  finally have *: "main_part (\<Union>i. S i) \<union> ?N = (\<Union>i. main_part (S i)) \<union> ?N" .
  have "\<mu> (main_part (\<Union>i. S i)) = \<mu> (main_part (\<Union>i. S i) \<union> ?N)"
    using null_set UN by (intro measure_Un_null_set[symmetric]) auto
  also have "\<dots> = \<mu> ((\<Union>i. main_part (S i)) \<union> ?N)"
    unfolding * ..
  also have "\<dots> = \<mu> (\<Union>i. main_part (S i))"
    using null_set S by (intro measure_Un_null_set) auto
  finally show ?thesis unfolding \<mu>'_def .
qed

lemma (in completeable_measure_space) \<mu>_main_part_Un:
  assumes S: "S \<in> sets completion" and T: "T \<in> sets completion"
  shows "\<mu>' (S \<union> T) = \<mu> (main_part S \<union> main_part T)"
proof -
  have UN: "(\<Union>i. binary (main_part S) (main_part T) i) = (\<Union>i. main_part (binary S T i))"
    unfolding binary_def by (auto split: split_if_asm)
  show ?thesis
    using \<mu>_main_part_UN[of "binary S T"] assms
    unfolding range_binary_eq Un_range_binary UN by auto
qed

sublocale completeable_measure_space \<subseteq> completion!: measure_space completion \<mu>'
proof
  show "\<mu>' {} = 0" by auto
next
  show "countably_additive completion \<mu>'"
  proof (unfold countably_additive_def, intro allI conjI impI)
    fix A :: "nat \<Rightarrow> 'a set" assume A: "range A \<subseteq> sets completion" "disjoint_family A"
    have "disjoint_family (\<lambda>i. main_part (A i))"
    proof (intro disjoint_family_on_bisimulation[OF A(2)])
      fix n m assume "A n \<inter> A m = {}"
      then have "(main_part (A n) \<union> null_part (A n)) \<inter> (main_part (A m) \<union> null_part (A m)) = {}"
        using A by (subst (1 2) main_part_null_part_Un) auto
      then show "main_part (A n) \<inter> main_part (A m) = {}" by auto
    qed
    then have "(\<Sum>\<^isub>\<infinity>n. \<mu>' (A n)) = \<mu> (\<Union>i. main_part (A i))"
      unfolding \<mu>'_def using A by (intro measure_countably_additive) auto
    then show "(\<Sum>\<^isub>\<infinity>n. \<mu>' (A n)) = \<mu>' (UNION UNIV A)"
      unfolding \<mu>_main_part_UN[OF A(1)] .
  qed
qed

lemma (in completeable_measure_space) completion_ex_simple_function:
  assumes f: "completion.simple_function f"
  shows "\<exists>f'. simple_function f' \<and> (AE x. f x = f' x)"
proof -
  let "?F x" = "f -` {x} \<inter> space M"
  have F: "\<And>x. ?F x \<in> sets completion" and fin: "finite (f`space M)"
    using completion.simple_functionD[OF f]
      completion.simple_functionD[OF f] by simp_all
  have "\<forall>x. \<exists>N. N \<in> null_sets \<and> null_part (?F x) \<subseteq> N"
    using F null_part by auto
  from choice[OF this] obtain N where
    N: "\<And>x. null_part (?F x) \<subseteq> N x" "\<And>x. N x \<in> null_sets" by auto
  let ?N = "\<Union>x\<in>f`space M. N x" let "?f' x" = "if x \<in> ?N then undefined else f x"
  have sets: "?N \<in> null_sets" using N fin by (intro null_sets_finite_UN) auto
  show ?thesis unfolding simple_function_def
  proof (safe intro!: exI[of _ ?f'])
    have "?f' ` space M \<subseteq> f`space M \<union> {undefined}" by auto
    from finite_subset[OF this] completion.simple_functionD(1)[OF f]
    show "finite (?f' ` space M)" by auto
  next
    fix x assume "x \<in> space M"
    have "?f' -` {?f' x} \<inter> space M =
      (if x \<in> ?N then ?F undefined \<union> ?N
       else if f x = undefined then ?F (f x) \<union> ?N
       else ?F (f x) - ?N)"
      using N(2) sets_into_space by (auto split: split_if_asm)
    moreover { fix y have "?F y \<union> ?N \<in> sets M"
      proof cases
        assume y: "y \<in> f`space M"
        have "?F y \<union> ?N = (main_part (?F y) \<union> null_part (?F y)) \<union> ?N"
          using main_part_null_part_Un[OF F] by auto
        also have "\<dots> = main_part (?F y) \<union> ?N"
          using y N by auto
        finally show ?thesis
          using F sets by auto
      next
        assume "y \<notin> f`space M" then have "?F y = {}" by auto
        then show ?thesis using sets by auto
      qed }
    moreover {
      have "?F (f x) - ?N = main_part (?F (f x)) \<union> null_part (?F (f x)) - ?N"
        using main_part_null_part_Un[OF F] by auto
      also have "\<dots> = main_part (?F (f x)) - ?N"
        using N `x \<in> space M` by auto
      finally have "?F (f x) - ?N \<in> sets M"
        using F sets by auto }
    ultimately show "?f' -` {?f' x} \<inter> space M \<in> sets M" by auto
  next
    show "AE x. f x = ?f' x"
      by (rule AE_I', rule sets) auto
  qed
qed

lemma (in completeable_measure_space) completion_ex_borel_measurable:
  fixes g :: "'a \<Rightarrow> pextreal"
  assumes g: "g \<in> borel_measurable completion"
  shows "\<exists>g'\<in>borel_measurable M. (AE x. g x = g' x)"
proof -
  from g[THEN completion.borel_measurable_implies_simple_function_sequence]
  obtain f where "\<And>i. completion.simple_function (f i)" "f \<up> g" by auto
  then have "\<forall>i. \<exists>f'. simple_function f' \<and> (AE x. f i x = f' x)"
    using completion_ex_simple_function by auto
  from this[THEN choice] obtain f' where
    sf: "\<And>i. simple_function (f' i)" and
    AE: "\<forall>i. AE x. f i x = f' i x" by auto
  show ?thesis
  proof (intro bexI)
    from AE[unfolded all_AE_countable]
    show "AE x. g x = (SUP i. f' i x)" (is "AE x. g x = ?f x")
    proof (rule AE_mp, safe intro!: AE_cong)
      fix x assume eq: "\<forall>i. f i x = f' i x"
      moreover have "g = SUPR UNIV f" using `f \<up> g` unfolding isoton_def by simp
      ultimately show "g x = ?f x" by (simp add: SUPR_apply)
    qed
    show "?f \<in> borel_measurable M"
      using sf by (auto intro: borel_measurable_simple_function)
  qed
qed

end

(*  Title:      HOL/Probability/Embed_Measure.thy
    Author:     Manuel Eberl, TU München

    Defines measure embeddings with injective functions, i.e. lifting a measure on some values
    to a measure on "tagged" values (e.g. embed_measure M Inl lifts a measure on values 'a to a
    measure on the left part of the sum type 'a + 'b)
*)

section \<open>Embed Measure Spaces with a Function\<close>

theory Embed_Measure
imports Binary_Product_Measure
begin

definition embed_measure :: "'a measure \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> 'b measure" where
  "embed_measure M f = measure_of (f ` space M) {f ` A |A. A \<in> sets M}
                           (\<lambda>A. emeasure M (f -` A \<inter> space M))"

lemma space_embed_measure: "space (embed_measure M f) = f ` space M"
  unfolding embed_measure_def
  by (subst space_measure_of) (auto dest: sets.sets_into_space)

lemma sets_embed_measure':
  assumes inj: "inj_on f (space M)"
  shows "sets (embed_measure M f) = {f ` A |A. A \<in> sets M}"
  unfolding embed_measure_def
proof (intro sigma_algebra.sets_measure_of_eq sigma_algebra_iff2[THEN iffD2] conjI allI ballI impI)
  fix s assume "s \<in> {f ` A |A. A \<in> sets M}"
  then obtain s' where s'_props: "s = f ` s'" "s' \<in> sets M" by auto
  hence "f ` space M - s = f ` (space M - s')" using inj
    by (auto dest: inj_onD sets.sets_into_space)
  also have "... \<in> {f ` A |A. A \<in> sets M}" using s'_props by auto
  finally show "f ` space M - s \<in> {f ` A |A. A \<in> sets M}" .
next
  fix A :: "nat \<Rightarrow> _" assume "range A \<subseteq> {f ` A |A. A \<in> sets M}"
  then obtain A' where A': "\<And>i. A i = f ` A' i" "\<And>i. A' i \<in> sets M"
    by (auto simp: subset_eq choice_iff)
  then have "(\<Union>x. f ` A' x) = f ` (\<Union>x. A' x)" by blast
  with A' show "(\<Union>i. A i) \<in> {f ` A |A. A \<in> sets M}"
    by simp blast
qed (auto dest: sets.sets_into_space)

lemma the_inv_into_vimage:
  "inj_on f X \<Longrightarrow> A \<subseteq> X \<Longrightarrow> the_inv_into X f -` A \<inter> (f`X) = f ` A"
  by (auto simp: the_inv_into_f_f)

lemma sets_embed_eq_vimage_algebra:
  assumes "inj_on f (space M)"
  shows "sets (embed_measure M f) = sets (vimage_algebra (f`space M) (the_inv_into (space M) f) M)"
  by (auto simp: sets_embed_measure'[OF assms] Pi_iff the_inv_into_f_f assms sets_vimage_algebra2 simple_image
           dest: sets.sets_into_space
           intro!: image_cong the_inv_into_vimage[symmetric])

lemma sets_embed_measure:
  assumes inj: "inj f"
  shows "sets (embed_measure M f) = {f ` A |A. A \<in> sets M}"
  using assms by (subst sets_embed_measure') (auto intro!: inj_onI dest: injD)

lemma in_sets_embed_measure: "A \<in> sets M \<Longrightarrow> f ` A \<in> sets (embed_measure M f)"
  unfolding embed_measure_def
  by (intro in_measure_of) (auto dest: sets.sets_into_space)

lemma measurable_embed_measure1:
  assumes g: "(\<lambda>x. g (f x)) \<in> measurable M N"
  shows "g \<in> measurable (embed_measure M f) N"
  unfolding measurable_def
proof safe
  fix A assume "A \<in> sets N"
  with g have "(\<lambda>x. g (f x)) -` A \<inter> space M \<in> sets M"
    by (rule measurable_sets)
  then have "f ` ((\<lambda>x. g (f x)) -` A \<inter> space M) \<in> sets (embed_measure M f)"
    by (rule in_sets_embed_measure)
  also have "f ` ((\<lambda>x. g (f x)) -` A \<inter> space M) = g -` A \<inter> space (embed_measure M f)"
    by (auto simp: space_embed_measure)
  finally show "g -` A \<inter> space (embed_measure M f) \<in> sets (embed_measure M f)" .
qed (insert measurable_space[OF assms], auto simp: space_embed_measure)

lemma measurable_embed_measure2':
  assumes "inj_on f (space M)"
  shows "f \<in> measurable M (embed_measure M f)"
proof-
  {
    fix A assume A: "A \<in> sets M"
    also from A have "A = A \<inter> space M" by auto
    also have "... = f -` f ` A \<inter> space M" using A assms
      by (auto dest: inj_onD sets.sets_into_space)
    finally have "f -` f ` A \<inter> space M \<in> sets M" .
  }
  thus ?thesis using assms unfolding embed_measure_def
    by (intro measurable_measure_of) (auto dest: sets.sets_into_space)
qed

lemma measurable_embed_measure2:
  assumes [simp]: "inj f" shows "f \<in> measurable M (embed_measure M f)"
  by (auto simp: inj_vimage_image_eq embed_measure_def
           intro!: measurable_measure_of dest: sets.sets_into_space)

lemma embed_measure_eq_distr':
  assumes "inj_on f (space M)"
  shows "embed_measure M f = distr M (embed_measure M f) f"
proof-
  have "distr M (embed_measure M f) f =
            measure_of (f ` space M) {f ` A |A. A \<in> sets M}
                       (\<lambda>A. emeasure M (f -` A \<inter> space M))" unfolding distr_def
      by (simp add: space_embed_measure sets_embed_measure'[OF assms])
  also have "... = embed_measure M f" unfolding embed_measure_def ..
  finally show ?thesis ..
qed

lemma embed_measure_eq_distr:
    "inj f \<Longrightarrow> embed_measure M f = distr M (embed_measure M f) f"
  by (rule embed_measure_eq_distr') (auto intro!: inj_onI dest: injD)

lemma nn_integral_embed_measure':
  "inj_on f (space M) \<Longrightarrow> g \<in> borel_measurable (embed_measure M f) \<Longrightarrow>
  nn_integral (embed_measure M f) g = nn_integral M (\<lambda>x. g (f x))"
  apply (subst embed_measure_eq_distr', simp)
  apply (subst nn_integral_distr)
  apply (simp_all add: measurable_embed_measure2')
  done

lemma nn_integral_embed_measure:
  "inj f \<Longrightarrow> g \<in> borel_measurable (embed_measure M f) \<Longrightarrow>
  nn_integral (embed_measure M f) g = nn_integral M (\<lambda>x. g (f x))"
  by(erule nn_integral_embed_measure'[OF subset_inj_on]) simp

lemma emeasure_embed_measure':
    assumes "inj_on f (space M)" "A \<in> sets (embed_measure M f)"
    shows "emeasure (embed_measure M f) A = emeasure M (f -` A \<inter> space M)"
  by (subst embed_measure_eq_distr'[OF assms(1)])
     (simp add: emeasure_distr[OF measurable_embed_measure2'[OF assms(1)] assms(2)])

lemma emeasure_embed_measure:
    assumes "inj f" "A \<in> sets (embed_measure M f)"
    shows "emeasure (embed_measure M f) A = emeasure M (f -` A \<inter> space M)"
 using assms by (intro emeasure_embed_measure') (auto intro!: inj_onI dest: injD)

lemma embed_measure_comp:
  assumes [simp]: "inj f" "inj g"
  shows "embed_measure (embed_measure M f) g = embed_measure M (g \<circ> f)"
proof-
  have [simp]: "inj (\<lambda>x. g (f x))" by (subst o_def[symmetric]) (auto intro: inj_comp)
  note measurable_embed_measure2[measurable]
  have "embed_measure (embed_measure M f) g =
            distr M (embed_measure (embed_measure M f) g) (g \<circ> f)"
      by (subst (1 2) embed_measure_eq_distr)
         (simp_all add: distr_distr sets_embed_measure cong: distr_cong)
  also have "... = embed_measure M (g \<circ> f)"
      by (subst (3) embed_measure_eq_distr, simp add: o_def, rule distr_cong)
         (auto simp: sets_embed_measure o_def image_image[symmetric]
               intro: inj_comp cong: distr_cong)
  finally show ?thesis .
qed

lemma sigma_finite_embed_measure:
  assumes "sigma_finite_measure M" and inj: "inj f"
  shows "sigma_finite_measure (embed_measure M f)"
proof -
  from assms(1) interpret sigma_finite_measure M .
  from sigma_finite_countable obtain A where
      A_props: "countable A" "A \<subseteq> sets M" "\<Union>A = space M" "\<And>X. X\<in>A \<Longrightarrow> emeasure M X \<noteq> \<infinity>" by blast
  from A_props have "countable (op ` f`A)" by auto
  moreover
  from inj and A_props have "op ` f`A \<subseteq> sets (embed_measure M f)"
    by (auto simp: sets_embed_measure)
  moreover
  from A_props and inj have "\<Union>(op ` f`A) = space (embed_measure M f)"
    by (auto simp: space_embed_measure intro!: imageI)
  moreover
  from A_props and inj have "\<forall>a\<in>op ` f ` A. emeasure (embed_measure M f) a \<noteq> \<infinity>"
    by (intro ballI, subst emeasure_embed_measure)
       (auto simp: inj_vimage_image_eq intro: in_sets_embed_measure)
  ultimately show ?thesis by - (standard, blast)
qed

lemma embed_measure_count_space':
    "inj_on f A \<Longrightarrow> embed_measure (count_space A) f = count_space (f`A)"
  apply (subst distr_bij_count_space[of f A "f`A", symmetric])
  apply (simp add: inj_on_def bij_betw_def)
  apply (subst embed_measure_eq_distr')
  apply simp
  apply(auto 4 3 intro!: measure_eqI imageI simp add: sets_embed_measure' subset_image_iff)
  apply (subst (1 2) emeasure_distr)
  apply (auto simp: space_embed_measure sets_embed_measure')
  done

lemma embed_measure_count_space:
    "inj f \<Longrightarrow> embed_measure (count_space A) f = count_space (f`A)"
  by(rule embed_measure_count_space')(erule subset_inj_on, simp)

lemma sets_embed_measure_alt:
    "inj f \<Longrightarrow> sets (embed_measure M f) = (op`f) ` sets M"
  by (auto simp: sets_embed_measure)

lemma emeasure_embed_measure_image':
  assumes "inj_on f (space M)" "X \<in> sets M"
  shows "emeasure (embed_measure M f) (f`X) = emeasure M X"
proof-
  from assms have "emeasure (embed_measure M f) (f`X) = emeasure M (f -` f ` X \<inter> space M)"
    by (subst emeasure_embed_measure') (auto simp: sets_embed_measure')
  also from assms have "f -` f ` X \<inter> space M = X" by (auto dest: inj_onD sets.sets_into_space)
  finally show ?thesis .
qed

lemma emeasure_embed_measure_image:
    "inj f \<Longrightarrow> X \<in> sets M \<Longrightarrow> emeasure (embed_measure M f) (f`X) = emeasure M X"
  by (simp_all add: emeasure_embed_measure in_sets_embed_measure inj_vimage_image_eq)

lemma embed_measure_eq_iff:
  assumes "inj f"
  shows "embed_measure A f = embed_measure B f \<longleftrightarrow> A = B" (is "?M = ?N \<longleftrightarrow> _")
proof
  from assms have I: "inj (op` f)" by (auto intro: injI dest: injD)
  assume asm: "?M = ?N"
  hence "sets (embed_measure A f) = sets (embed_measure B f)" by simp
  with assms have "sets A = sets B" by (simp only: I inj_image_eq_iff sets_embed_measure_alt)
  moreover {
    fix X assume "X \<in> sets A"
    from asm have "emeasure ?M (f`X) = emeasure ?N (f`X)" by simp
    with \<open>X \<in> sets A\<close> and \<open>sets A = sets B\<close> and assms
        have "emeasure A X = emeasure B X" by (simp add: emeasure_embed_measure_image)
  }
  ultimately show "A = B" by (rule measure_eqI)
qed simp

lemma the_inv_into_in_Pi: "inj_on f A \<Longrightarrow> the_inv_into A f \<in> f ` A \<rightarrow> A"
  by (auto simp: the_inv_into_f_f)

lemma map_prod_image: "map_prod f g ` (A \<times> B) = (f`A) \<times> (g`B)"
  using map_prod_surj_on[OF refl refl] .

lemma map_prod_vimage: "map_prod f g -` (A \<times> B) = (f-`A) \<times> (g-`B)"
  by auto

lemma embed_measure_prod:
  assumes f: "inj f" and g: "inj g" and [simp]: "sigma_finite_measure M" "sigma_finite_measure N"
  shows "embed_measure M f \<Otimes>\<^sub>M embed_measure N g = embed_measure (M \<Otimes>\<^sub>M N) (\<lambda>(x, y). (f x, g y))"
    (is "?L = _")
  unfolding map_prod_def[symmetric]
proof (rule pair_measure_eqI)
  have fg[simp]: "\<And>A. inj_on (map_prod f g) A" "\<And>A. inj_on f A" "\<And>A. inj_on g A"
    using f g by (auto simp: inj_on_def)

  note complete_lattice_class.Sup_insert[simp del] ccSup_insert[simp del] SUP_insert[simp del]
     ccSUP_insert[simp del]
  show sets: "sets ?L = sets (embed_measure (M \<Otimes>\<^sub>M N) (map_prod f g))"
    unfolding map_prod_def[symmetric]
    apply (simp add: sets_pair_eq_sets_fst_snd sets_embed_eq_vimage_algebra
      cong: vimage_algebra_cong)
    apply (subst sets_vimage_Sup_eq[where Y="space (M \<Otimes>\<^sub>M N)"])
    apply (simp_all add: space_pair_measure[symmetric])
    apply (auto simp add: the_inv_into_f_f
                simp del: map_prod_simp
                del: prod_fun_imageE) []
    apply auto []
    apply (subst image_insert)
    apply simp
    apply (subst (1 2 3 4 ) vimage_algebra_vimage_algebra_eq)
    apply (simp_all add: the_inv_into_in_Pi Pi_iff[of snd] Pi_iff[of fst] space_pair_measure)
    apply (simp_all add: Pi_iff[of snd] Pi_iff[of fst] the_inv_into_in_Pi vimage_algebra_vimage_algebra_eq
       space_pair_measure[symmetric] map_prod_image[symmetric])
    apply (intro arg_cong[where f=sets] arg_cong[where f=Sup] arg_cong2[where f=insert] vimage_algebra_cong)
    apply (auto simp: map_prod_image the_inv_into_f_f
                simp del: map_prod_simp del: prod_fun_imageE)
    apply (simp_all add: the_inv_into_f_f space_pair_measure)
    done

  note measurable_embed_measure2[measurable]
  fix A B assume AB: "A \<in> sets (embed_measure M f)" "B \<in> sets (embed_measure N g)"
  moreover have "f -` A \<times> g -` B \<inter> space (M \<Otimes>\<^sub>M N) = (f -` A \<inter> space M) \<times> (g -` B \<inter> space N)"
    by (auto simp: space_pair_measure)
  ultimately show "emeasure (embed_measure M f) A * emeasure (embed_measure N g) B =
                     emeasure (embed_measure (M \<Otimes>\<^sub>M N) (map_prod f g)) (A \<times> B)"
    by (simp add: map_prod_vimage sets[symmetric] emeasure_embed_measure
                  sigma_finite_measure.emeasure_pair_measure_Times)
qed (insert assms, simp_all add: sigma_finite_embed_measure)

lemma mono_embed_measure:
  "space M = space M' \<Longrightarrow> sets M \<subseteq> sets M' \<Longrightarrow> sets (embed_measure M f) \<subseteq> sets (embed_measure M' f)"
  unfolding embed_measure_def
  apply (subst (1 2) sets_measure_of)
  apply (blast dest: sets.sets_into_space)
  apply (blast dest: sets.sets_into_space)
  apply simp
  apply (intro sigma_sets_mono')
  apply safe
  apply (simp add: subset_eq)
  apply metis
  done

lemma density_embed_measure:
  assumes inj: "inj f" and Mg[measurable]: "g \<in> borel_measurable (embed_measure M f)"
  shows "density (embed_measure M f) g = embed_measure (density M (g \<circ> f)) f" (is "?M1 = ?M2")
proof (rule measure_eqI)
  fix X assume X: "X \<in> sets ?M1"
  from inj have Mf[measurable]: "f \<in> measurable M (embed_measure M f)"
    by (rule measurable_embed_measure2)
  from Mg and X have "emeasure ?M1 X = \<integral>\<^sup>+ x. g x * indicator X x \<partial>embed_measure M f"
    by (subst emeasure_density) simp_all
  also from X have "... = \<integral>\<^sup>+ x. g (f x) * indicator X (f x) \<partial>M"
    by (subst embed_measure_eq_distr[OF inj], subst nn_integral_distr) auto
  also have "... = \<integral>\<^sup>+ x. g (f x) * indicator (f -` X \<inter> space M) x \<partial>M"
    by (intro nn_integral_cong) (auto split: split_indicator)
  also from X have "... = emeasure (density M (g \<circ> f)) (f -` X \<inter> space M)"
    by (subst emeasure_density) (simp_all add: measurable_comp[OF Mf Mg] measurable_sets[OF Mf])
  also from X and inj have "... = emeasure ?M2 X"
    by (subst emeasure_embed_measure) (simp_all add: sets_embed_measure)
  finally show "emeasure ?M1 X = emeasure ?M2 X" .
qed (simp_all add: sets_embed_measure inj)

lemma density_embed_measure':
  assumes inj: "inj f" and inv: "\<And>x. f' (f x) = x" and Mg[measurable]: "g \<in> borel_measurable M"
  shows "density (embed_measure M f) (g \<circ> f') = embed_measure (density M g) f"
proof-
  have "density (embed_measure M f) (g \<circ> f') = embed_measure (density M (g \<circ> f' \<circ> f)) f"
    by (rule density_embed_measure[OF inj])
       (rule measurable_comp, rule measurable_embed_measure1, subst measurable_cong,
        rule inv, rule measurable_ident_sets, simp, rule Mg)
  also have "density M (g \<circ> f' \<circ> f) = density M g"
    by (intro density_cong) (subst measurable_cong, simp add: o_def inv, simp_all add: Mg inv)
  finally show ?thesis .
qed

lemma inj_on_image_subset_iff:
  assumes "inj_on f C" "A \<subseteq> C"  "B \<subseteq> C"
  shows "f ` A \<subseteq> f ` B \<longleftrightarrow> A \<subseteq> B"
proof (intro iffI subsetI)
  fix x assume A: "f ` A \<subseteq> f ` B" and B: "x \<in> A"
  from B have "f x \<in> f ` A" by blast
  with A have "f x \<in> f ` B" by blast
  then obtain y where "f x = f y" and "y \<in> B" by blast
  with assms and B have "x = y" by (auto dest: inj_onD)
  with \<open>y \<in> B\<close> show "x \<in> B" by simp
qed auto


lemma AE_embed_measure':
  assumes inj: "inj_on f (space M)"
  shows "(AE x in embed_measure M f. P x) \<longleftrightarrow> (AE x in M. P (f x))"
proof
  let ?M = "embed_measure M f"
  assume "AE x in ?M. P x"
  then obtain A where A_props: "A \<in> sets ?M" "emeasure ?M A = 0" "{x\<in>space ?M. \<not>P x} \<subseteq> A"
    by (force elim: AE_E)
  then obtain A' where A'_props: "A = f ` A'" "A' \<in> sets M" by (auto simp: sets_embed_measure' inj)
  moreover have B: "{x\<in>space ?M. \<not>P x} = f ` {x\<in>space M. \<not>P (f x)}"
    by (auto simp: inj space_embed_measure)
  from A_props(3) have "{x\<in>space M. \<not>P (f x)} \<subseteq> A'"
    by (subst (asm) B, subst (asm) A'_props, subst (asm) inj_on_image_subset_iff[OF inj])
       (insert A'_props, auto dest: sets.sets_into_space)
  moreover from A_props A'_props have "emeasure M A' = 0"
    by (simp add: emeasure_embed_measure_image' inj)
  ultimately show "AE x in M. P (f x)" by (intro AE_I)
next
  let ?M = "embed_measure M f"
  assume "AE x in M. P (f x)"
  then obtain A where A_props: "A \<in> sets M" "emeasure M A = 0" "{x\<in>space M. \<not>P (f x)} \<subseteq> A"
    by (force elim: AE_E)
  hence "f`A \<in> sets ?M" "emeasure ?M (f`A) = 0" "{x\<in>space ?M. \<not>P x} \<subseteq> f`A"
    by (auto simp: space_embed_measure emeasure_embed_measure_image' sets_embed_measure' inj)
  thus "AE x in ?M. P x" by (intro AE_I)
qed

lemma AE_embed_measure:
  assumes inj: "inj f"
  shows "(AE x in embed_measure M f. P x) \<longleftrightarrow> (AE x in M. P (f x))"
  using assms by (intro AE_embed_measure') (auto intro!: inj_onI dest: injD)

lemma nn_integral_monotone_convergence_SUP_countable:
  fixes f :: "'a \<Rightarrow> 'b \<Rightarrow> ennreal"
  assumes nonempty: "Y \<noteq> {}"
  and chain: "Complete_Partial_Order.chain op \<le> (f ` Y)"
  and countable: "countable B"
  shows "(\<integral>\<^sup>+ x. (SUP i:Y. f i x) \<partial>count_space B) = (SUP i:Y. (\<integral>\<^sup>+ x. f i x \<partial>count_space B))"
  (is "?lhs = ?rhs")
proof -
  let ?f = "(\<lambda>i x. f i (from_nat_into B x) * indicator (to_nat_on B ` B) x)"
  have "?lhs = \<integral>\<^sup>+ x. (SUP i:Y. f i (from_nat_into B (to_nat_on B x))) \<partial>count_space B"
    by(rule nn_integral_cong)(simp add: countable)
  also have "\<dots> = \<integral>\<^sup>+ x. (SUP i:Y. f i (from_nat_into B x)) \<partial>count_space (to_nat_on B ` B)"
    by(simp add: embed_measure_count_space'[symmetric] inj_on_to_nat_on countable nn_integral_embed_measure' measurable_embed_measure1)
  also have "\<dots> = \<integral>\<^sup>+ x. (SUP i:Y. ?f i x) \<partial>count_space UNIV"
    by(simp add: nn_integral_count_space_indicator ennreal_indicator[symmetric] SUP_mult_right_ennreal nonempty)
  also have "\<dots> = (SUP i:Y. \<integral>\<^sup>+ x. ?f i x \<partial>count_space UNIV)"
  proof(rule nn_integral_monotone_convergence_SUP_nat)
    show "Complete_Partial_Order.chain op \<le> (?f ` Y)"
      by(rule chain_imageI[OF chain, unfolded image_image])(auto intro!: le_funI split: split_indicator dest: le_funD)
  qed fact
  also have "\<dots> = (SUP i:Y. \<integral>\<^sup>+ x. f i (from_nat_into B x) \<partial>count_space (to_nat_on B ` B))"
    by(simp add: nn_integral_count_space_indicator)
  also have "\<dots> = (SUP i:Y. \<integral>\<^sup>+ x. f i (from_nat_into B (to_nat_on B x)) \<partial>count_space B)"
    by(simp add: embed_measure_count_space'[symmetric] inj_on_to_nat_on countable nn_integral_embed_measure' measurable_embed_measure1)
  also have "\<dots> = ?rhs"
    by(intro arg_cong2[where f="SUPREMUM"] ext nn_integral_cong_AE)(simp_all add: AE_count_space countable)
  finally show ?thesis .
qed

end

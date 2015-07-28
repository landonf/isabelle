(*  Title:      HOL/Multivariate_Analysis/Uniform_Limit.thy
    Author:     Christoph Traut, TU München
    Author:     Fabian Immler, TU München
*)

section \<open>Uniform Limit and Uniform Convergence\<close>

theory Uniform_Limit
imports Topology_Euclidean_Space
begin

definition uniformly_on :: "'a set \<Rightarrow> ('a \<Rightarrow> 'b::metric_space) \<Rightarrow> ('a \<Rightarrow> 'b) filter"
  where "uniformly_on S l = (INF e:{0 <..}. principal {f. \<forall>x\<in>S. dist (f x) (l x) < e})"

abbreviation
  "uniform_limit S f l \<equiv> filterlim f (uniformly_on S l)"

lemma uniform_limit_iff:
  "uniform_limit S f l F \<longleftrightarrow> (\<forall>e>0. \<forall>\<^sub>F n in F. \<forall>x\<in>S. dist (f n x) (l x) < e)"
  unfolding filterlim_iff uniformly_on_def
  by (subst eventually_INF_base)
    (fastforce
      simp: eventually_principal uniformly_on_def
      intro: bexI[where x="min a b" for a b]
      elim: eventually_elim1)+

lemma uniform_limitD:
  "uniform_limit S f l F \<Longrightarrow> e > 0 \<Longrightarrow> \<forall>\<^sub>F n in F. \<forall>x\<in>S. dist (f n x) (l x) < e"
  by (simp add: uniform_limit_iff)

lemma uniform_limitI:
  "(\<And>e. e > 0 \<Longrightarrow> \<forall>\<^sub>F n in F. \<forall>x\<in>S. dist (f n x) (l x) < e) \<Longrightarrow> uniform_limit S f l F"
  by (simp add: uniform_limit_iff)

lemma uniform_limit_sequentially_iff:
  "uniform_limit S f l sequentially \<longleftrightarrow> (\<forall>e>0. \<exists>N. \<forall>n\<ge>N. \<forall>x \<in> S. dist (f n x) (l x) < e)"
  unfolding uniform_limit_iff eventually_sequentially ..

lemma uniform_limit_at_iff:
  "uniform_limit S f l (at x) \<longleftrightarrow>
    (\<forall>e>0. \<exists>d>0. \<forall>z. 0 < dist z x \<and> dist z x < d \<longrightarrow> (\<forall>x\<in>S. dist (f z x) (l x) < e))"
  unfolding uniform_limit_iff eventually_at2 ..

lemma uniform_limit_at_le_iff:
  "uniform_limit S f l (at x) \<longleftrightarrow>
    (\<forall>e>0. \<exists>d>0. \<forall>z. 0 < dist z x \<and> dist z x < d \<longrightarrow> (\<forall>x\<in>S. dist (f z x) (l x) \<le> e))"
  unfolding uniform_limit_iff eventually_at2
  by (fastforce dest: spec[where x = "e / 2" for e])

lemma swap_uniform_limit:
  assumes f: "\<forall>\<^sub>F n in F. (f n ---> g n) (at x within S)"
  assumes g: "(g ---> l) F"
  assumes uc: "uniform_limit S f h F"
  assumes "\<not>trivial_limit F"
  shows "(h ---> l) (at x within S)"
proof (rule tendstoI)
  fix e :: real
  def e' \<equiv> "e/3"
  assume "0 < e"
  then have "0 < e'" by (simp add: e'_def)
  from uniform_limitD[OF uc `0 < e'`]
  have "\<forall>\<^sub>F n in F. \<forall>x\<in>S. dist (h x) (f n x) < e'"
    by (simp add: dist_commute)
  moreover
  from f
  have "\<forall>\<^sub>F n in F. \<forall>\<^sub>F x in at x within S. dist (g n) (f n x) < e'"
    by eventually_elim (auto dest!: tendstoD[OF _ `0 < e'`] simp: dist_commute)
  moreover
  from tendstoD[OF g `0 < e'`] have "\<forall>\<^sub>F x in F. dist l (g x) < e'"
    by (simp add: dist_commute)
  ultimately
  have "\<forall>\<^sub>F _ in F. \<forall>\<^sub>F x in at x within S. dist (h x) l < e"
  proof eventually_elim
    case (elim n)
    note fh = elim(1)
    note gl = elim(3)
    have "\<forall>\<^sub>F x in at x within S. x \<in> S"
      by (auto simp: eventually_at_filter)
    with elim(2)
    show ?case
    proof eventually_elim
      case (elim x)
      from fh[rule_format, OF `x \<in> S`] elim(1)
      have "dist (h x) (g n) < e' + e'"
        by (rule dist_triangle_lt[OF add_strict_mono])
      from dist_triangle_lt[OF add_strict_mono, OF this gl]
      show ?case by (simp add: e'_def)
    qed
  qed
  thus "\<forall>\<^sub>F x in at x within S. dist (h x) l < e"
    using eventually_happens by (metis `\<not>trivial_limit F`)
qed

lemma
  tendsto_uniform_limitI:
  assumes "uniform_limit S f l F"
  assumes "x \<in> S"
  shows "((\<lambda>y. f y x) ---> l x) F"
  using assms
  by (auto intro!: tendstoI simp: eventually_elim1 dest!: uniform_limitD)

lemma uniform_limit_theorem:
  assumes c: "\<forall>\<^sub>F n in F. continuous_on A (f n)"
  assumes ul: "uniform_limit A f l F"
  assumes "\<not> trivial_limit F"
  shows "continuous_on A l"
  unfolding continuous_on_def
proof safe
  fix x assume "x \<in> A"
  then have "\<forall>\<^sub>F n in F. (f n ---> f n x) (at x within A)" "((\<lambda>n. f n x) ---> l x) F"
    using c ul
    by (auto simp: continuous_on_def eventually_elim1 tendsto_uniform_limitI)
  then show "(l ---> l x) (at x within A)"
    by (rule swap_uniform_limit) fact+
qed

lemma weierstrass_m_test:
fixes f :: "_ \<Rightarrow> _ \<Rightarrow> _ :: banach"
assumes "\<And>n x. x \<in> A \<Longrightarrow> norm (f n x) \<le> M n"
assumes "summable M"
shows "uniform_limit A (\<lambda>n x. \<Sum>i<n. f i x) (\<lambda>x. suminf (\<lambda>i. f i x)) sequentially"
proof (rule uniform_limitI)
  fix e :: real
  assume "0 < e"
  from suminf_exist_split[OF `0 < e` `summable M`]
  have "\<forall>\<^sub>F k in sequentially. norm (\<Sum>i. M (i + k)) < e"
    by (auto simp: eventually_sequentially)
  thus "\<forall>\<^sub>F n in sequentially. \<forall>x\<in>A. dist (\<Sum>i<n. f i x) (\<Sum>i. f i x) < e"
  proof eventually_elim
    case (elim k)
    show ?case
    proof safe
      fix x assume "x \<in> A"
      have "\<exists>N. \<forall>n\<ge>N. norm (f n x) \<le> M n"
        using assms(1)[OF `x \<in> A`] by simp
      hence summable_norm_f: "summable (\<lambda>n. norm (f n x))"
        by(rule summable_norm_comparison_test[OF _ `summable M`])
      have summable_f: "summable (\<lambda>n. f n x)"
        using summable_norm_cancel[OF summable_norm_f] .
      have summable_norm_f_plus_k: "summable (\<lambda>i. norm (f (i + k) x))"
        using summable_ignore_initial_segment[OF summable_norm_f]
        by auto
      have summable_M_plus_k: "summable (\<lambda>i. M (i + k))"
        using summable_ignore_initial_segment[OF `summable M`]
        by auto

      have "dist (\<Sum>i<k. f i x) (\<Sum>i. f i x) = norm ((\<Sum>i. f i x) - (\<Sum>i<k. f i x))"
        using dist_norm dist_commute by (subst dist_commute)
      also have "... = norm (\<Sum>i. f (i + k) x)"
        using suminf_minus_initial_segment[OF summable_f, where k=k] by simp
      also have "... \<le> (\<Sum>i. norm (f (i + k) x))"
        using summable_norm[OF summable_norm_f_plus_k] .
      also have "... \<le> (\<Sum>i. M (i + k))"
        by (rule suminf_le[OF _ summable_norm_f_plus_k summable_M_plus_k])
           (simp add: assms(1)[OF `x \<in> A`])
      finally show "dist (\<Sum>i<k. f i x) (\<Sum>i. f i x) < e"
        using elim by auto
    qed
  qed
qed

lemma uniform_limit_eq_rhs: "uniform_limit X f l F \<Longrightarrow> l = m \<Longrightarrow> uniform_limit X f m F"
  by simp

named_theorems uniform_limit_intros "introduction rules for uniform_limit"
setup {*
  Global_Theory.add_thms_dynamic (@{binding uniform_limit_eq_intros},
    fn context =>
      Named_Theorems.get (Context.proof_of context) @{named_theorems uniform_limit_intros}
      |> map_filter (try (fn thm => @{thm uniform_limit_eq_rhs} OF [thm])))
*}

lemma (in bounded_linear) uniform_limit[uniform_limit_intros]:
  assumes "uniform_limit X g l F"
  shows "uniform_limit X (\<lambda>a b. f (g a b)) (\<lambda>a. f (l a)) F"
proof (rule uniform_limitI)
  fix e::real
  from pos_bounded obtain K
    where K: "\<And>x y. dist (f x) (f y) \<le> K * dist x y" "K > 0"
    by (auto simp: ac_simps dist_norm diff[symmetric])
  assume "0 < e" with `K > 0` have "e / K > 0" by simp
  from uniform_limitD[OF assms this]
  show "\<forall>\<^sub>F n in F. \<forall>x\<in>X. dist (f (g n x)) (f (l x)) < e"
    by eventually_elim (metis le_less_trans mult.commute pos_less_divide_eq K)
qed

lemmas bounded_linear_uniform_limit_intros[uniform_limit_intros] =
  bounded_linear.uniform_limit[OF bounded_linear_Im]
  bounded_linear.uniform_limit[OF bounded_linear_Re]
  bounded_linear.uniform_limit[OF bounded_linear_cnj]
  bounded_linear.uniform_limit[OF bounded_linear_fst]
  bounded_linear.uniform_limit[OF bounded_linear_snd]
  bounded_linear.uniform_limit[OF bounded_linear_zero]
  bounded_linear.uniform_limit[OF bounded_linear_of_real]
  bounded_linear.uniform_limit[OF bounded_linear_inner_left]
  bounded_linear.uniform_limit[OF bounded_linear_inner_right]
  bounded_linear.uniform_limit[OF bounded_linear_divide]
  bounded_linear.uniform_limit[OF bounded_linear_scaleR_right]
  bounded_linear.uniform_limit[OF bounded_linear_mult_left]
  bounded_linear.uniform_limit[OF bounded_linear_mult_right]
  bounded_linear.uniform_limit[OF bounded_linear_scaleR_left]

lemmas uniform_limit_uminus[uniform_limit_intros] =
  bounded_linear.uniform_limit[OF bounded_linear_minus[OF bounded_linear_ident]]

lemma uniform_limit_add[uniform_limit_intros]:
  fixes f g::"'a \<Rightarrow> 'b \<Rightarrow> 'c::real_normed_vector"
  assumes "uniform_limit X f l F"
  assumes "uniform_limit X g m F"
  shows "uniform_limit X (\<lambda>a b. f a b + g a b) (\<lambda>a. l a + m a) F"
proof (rule uniform_limitI)
  fix e::real
  assume "0 < e"
  hence "0 < e / 2" by simp
  from
    uniform_limitD[OF assms(1) this]
    uniform_limitD[OF assms(2) this]
  show "\<forall>\<^sub>F n in F. \<forall>x\<in>X. dist (f n x + g n x) (l x + m x) < e"
    by eventually_elim (simp add: dist_triangle_add_half)
qed

lemma uniform_limit_minus[uniform_limit_intros]:
  fixes f g::"'a \<Rightarrow> 'b \<Rightarrow> 'c::real_normed_vector"
  assumes "uniform_limit X f l F"
  assumes "uniform_limit X g m F"
  shows "uniform_limit X (\<lambda>a b. f a b - g a b) (\<lambda>a. l a - m a) F"
  unfolding diff_conv_add_uminus
  by (rule uniform_limit_intros assms)+

lemma (in bounded_bilinear) bounded_uniform_limit[uniform_limit_intros]:
  assumes "uniform_limit X f l F"
  assumes "uniform_limit X g m F"
  assumes "bounded (m ` X)"
  assumes "bounded (l ` X)"
  shows "uniform_limit X (\<lambda>a b. prod (f a b) (g a b)) (\<lambda>a. prod (l a) (m a)) F"
proof (rule uniform_limitI)
  fix e::real
  from pos_bounded obtain K where K:
    "0 < K" "\<And>a b. norm (prod a b) \<le> norm a * norm b * K"
    by auto
  hence "sqrt (K*4) > 0" by simp

  from assms obtain Km Kl
  where Km: "Km > 0" "\<And>x. x \<in> X \<Longrightarrow> norm (m x) \<le> Km"
    and Kl: "Kl > 0" "\<And>x. x \<in> X \<Longrightarrow> norm (l x) \<le> Kl"
    by (auto simp: bounded_pos)
  hence "K * Km * 4 > 0" "K * Kl * 4 > 0"
    using `K > 0`
    by simp_all
  assume "0 < e"

  hence "sqrt e > 0" by simp
  from uniform_limitD[OF assms(1) divide_pos_pos[OF this `sqrt (K*4) > 0`]]
    uniform_limitD[OF assms(2) divide_pos_pos[OF this `sqrt (K*4) > 0`]]
    uniform_limitD[OF assms(1) divide_pos_pos[OF `e > 0` `K * Km * 4 > 0`]]
    uniform_limitD[OF assms(2) divide_pos_pos[OF `e > 0` `K * Kl * 4 > 0`]]
  show "\<forall>\<^sub>F n in F. \<forall>x\<in>X. dist (prod (f n x) (g n x)) (prod (l x) (m x)) < e"
  proof eventually_elim
    case (elim n)
    show ?case
    proof safe
      fix x assume "x \<in> X"
      have "dist (prod (f n x) (g n x)) (prod (l x) (m x)) \<le>
        norm (prod (f n x - l x) (g n x - m x)) +
        norm (prod (f n x - l x) (m x)) +
        norm (prod (l x) (g n x - m x))"
        by (auto simp: dist_norm prod_diff_prod intro: order_trans norm_triangle_ineq add_mono)
      also note K(2)[of "f n x - l x" "g n x - m x"]
      also from elim(1)[THEN bspec, OF `_ \<in> X`, unfolded dist_norm]
      have "norm (f n x - l x) \<le> sqrt e / sqrt (K * 4)"
        by simp
      also from elim(2)[THEN bspec, OF `_ \<in> X`, unfolded dist_norm]
      have "norm (g n x - m x) \<le> sqrt e / sqrt (K * 4)"
        by simp
      also have "sqrt e / sqrt (K * 4) * (sqrt e / sqrt (K * 4)) * K = e / 4"
        using `K > 0` `e > 0` by auto
      also note K(2)[of "f n x - l x" "m x"]
      also note K(2)[of "l x" "g n x - m x"]
      also from elim(3)[THEN bspec, OF `_ \<in> X`, unfolded dist_norm]
      have "norm (f n x - l x) \<le> e / (K * Km * 4)"
        by simp
      also from elim(4)[THEN bspec, OF `_ \<in> X`, unfolded dist_norm]
      have "norm (g n x - m x) \<le> e / (K * Kl * 4)"
        by simp
      also note Kl(2)[OF `_ \<in> X`]
      also note Km(2)[OF `_ \<in> X`]
      also have "e / (K * Km * 4) * Km * K = e / 4"
        using `K > 0` `Km > 0` by simp
      also have " Kl * (e / (K * Kl * 4)) * K = e / 4"
        using `K > 0` `Kl > 0` by simp
      also have "e / 4 + e / 4 + e / 4 < e" using `e > 0` by simp
      finally show "dist (prod (f n x) (g n x)) (prod (l x) (m x)) < e"
        using `K > 0` `Kl > 0` `Km > 0` `e > 0`
        by (simp add: algebra_simps mult_right_mono divide_right_mono)
    qed
  qed
qed

lemmas bounded_bilinear_bounded_uniform_limit_intros[uniform_limit_intros] =
  bounded_bilinear.bounded_uniform_limit[OF Inner_Product.bounded_bilinear_inner]
  bounded_bilinear.bounded_uniform_limit[OF Real_Vector_Spaces.bounded_bilinear_mult]
  bounded_bilinear.bounded_uniform_limit[OF Real_Vector_Spaces.bounded_bilinear_scaleR]

lemma metric_uniform_limit_imp_uniform_limit:
  assumes f: "uniform_limit S f a F"
  assumes le: "eventually (\<lambda>x. \<forall>y\<in>S. dist (g x y) (b y) \<le> dist (f x y) (a y)) F"
  shows "uniform_limit S g b F"
proof (rule uniform_limitI)
  fix e :: real assume "0 < e"
  from uniform_limitD[OF f this] le
  show "\<forall>\<^sub>F x in F. \<forall>y\<in>S. dist (g x y) (b y) < e"
    by eventually_elim force
qed

lemma uniform_limit_null_comparison:
  assumes "\<forall>\<^sub>F x in F. \<forall>a\<in>S. norm (f x a) \<le> g x a"
  assumes "uniform_limit S g (\<lambda>_. 0) F"
  shows "uniform_limit S f (\<lambda>_. 0) F"
  using assms(2)
proof (rule metric_uniform_limit_imp_uniform_limit)
  show "\<forall>\<^sub>F x in F. \<forall>y\<in>S. dist (f x y) 0 \<le> dist (g x y) 0"
    using assms(1) by (rule eventually_elim1) (force simp add: dist_norm)
qed

lemma uniform_limit_on_union:
  "uniform_limit I f g F \<Longrightarrow> uniform_limit J f g F \<Longrightarrow> uniform_limit (I \<union> J) f g F"
  by (auto intro!: uniform_limitI dest!: uniform_limitD elim: eventually_elim2)

lemma uniform_limit_on_empty:
  "uniform_limit {} f g F"
  by (auto intro!: uniform_limitI)

lemma uniform_limit_on_UNION:
  assumes "finite S"
  assumes "\<And>s. s \<in> S \<Longrightarrow> uniform_limit (h s) f g F"
  shows "uniform_limit (UNION S h) f g F"
  using assms
  by induct (auto intro: uniform_limit_on_empty uniform_limit_on_union)

lemma uniform_limit_on_Union:
  assumes "finite I"
  assumes "\<And>J. J \<in> I \<Longrightarrow> uniform_limit J f g F"
  shows "uniform_limit (Union I) f g F"
  by (metis SUP_identity_eq assms uniform_limit_on_UNION)

lemma uniform_limit_on_subset:
  "uniform_limit J f g F \<Longrightarrow> I \<subseteq> J \<Longrightarrow> uniform_limit I f g F"
  by (auto intro!: uniform_limitI dest!: uniform_limitD intro: eventually_rev_mono)

end
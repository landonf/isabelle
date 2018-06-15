(*File:      HOL/Analysis/Infinite_Product.thy
  Author:    Manuel Eberl & LC Paulson

  Basic results about convergence and absolute convergence of infinite products
  and their connection to summability.
*)
section \<open>Infinite Products\<close>
theory Infinite_Products
  imports Topology_Euclidean_Space
begin

subsection\<open>Preliminaries\<close>

lemma sum_le_prod:
  fixes f :: "'a \<Rightarrow> 'b :: linordered_semidom"
  assumes "\<And>x. x \<in> A \<Longrightarrow> f x \<ge> 0"
  shows   "sum f A \<le> (\<Prod>x\<in>A. 1 + f x)"
  using assms
proof (induction A rule: infinite_finite_induct)
  case (insert x A)
  from insert.hyps have "sum f A + f x * (\<Prod>x\<in>A. 1) \<le> (\<Prod>x\<in>A. 1 + f x) + f x * (\<Prod>x\<in>A. 1 + f x)"
    by (intro add_mono insert mult_left_mono prod_mono) (auto intro: insert.prems)
  with insert.hyps show ?case by (simp add: algebra_simps)
qed simp_all

lemma prod_le_exp_sum:
  fixes f :: "'a \<Rightarrow> real"
  assumes "\<And>x. x \<in> A \<Longrightarrow> f x \<ge> 0"
  shows   "prod (\<lambda>x. 1 + f x) A \<le> exp (sum f A)"
  using assms
proof (induction A rule: infinite_finite_induct)
  case (insert x A)
  have "(1 + f x) * (\<Prod>x\<in>A. 1 + f x) \<le> exp (f x) * exp (sum f A)"
    using insert.prems by (intro mult_mono insert prod_nonneg exp_ge_add_one_self) auto
  with insert.hyps show ?case by (simp add: algebra_simps exp_add)
qed simp_all

lemma lim_ln_1_plus_x_over_x_at_0: "(\<lambda>x::real. ln (1 + x) / x) \<midarrow>0\<rightarrow> 1"
proof (rule lhopital)
  show "(\<lambda>x::real. ln (1 + x)) \<midarrow>0\<rightarrow> 0"
    by (rule tendsto_eq_intros refl | simp)+
  have "eventually (\<lambda>x::real. x \<in> {-1/2<..<1/2}) (nhds 0)"
    by (rule eventually_nhds_in_open) auto
  hence *: "eventually (\<lambda>x::real. x \<in> {-1/2<..<1/2}) (at 0)"
    by (rule filter_leD [rotated]) (simp_all add: at_within_def)   
  show "eventually (\<lambda>x::real. ((\<lambda>x. ln (1 + x)) has_field_derivative inverse (1 + x)) (at x)) (at 0)"
    using * by eventually_elim (auto intro!: derivative_eq_intros simp: field_simps)
  show "eventually (\<lambda>x::real. ((\<lambda>x. x) has_field_derivative 1) (at x)) (at 0)"
    using * by eventually_elim (auto intro!: derivative_eq_intros simp: field_simps)
  show "\<forall>\<^sub>F x in at 0. x \<noteq> 0" by (auto simp: at_within_def eventually_inf_principal)
  show "(\<lambda>x::real. inverse (1 + x) / 1) \<midarrow>0\<rightarrow> 1"
    by (rule tendsto_eq_intros refl | simp)+
qed auto

subsection\<open>Definitions and basic properties\<close>

definition raw_has_prod :: "[nat \<Rightarrow> 'a::{t2_space, comm_semiring_1}, nat, 'a] \<Rightarrow> bool" 
  where "raw_has_prod f M p \<equiv> (\<lambda>n. \<Prod>i\<le>n. f (i+M)) \<longlonglongrightarrow> p \<and> p \<noteq> 0"

text\<open>The nonzero and zero cases, as in \emph{Complex Analysis} by Joseph Bak and Donald J.Newman, page 241\<close>
definition has_prod :: "(nat \<Rightarrow> 'a::{t2_space, comm_semiring_1}) \<Rightarrow> 'a \<Rightarrow> bool" (infixr "has'_prod" 80)
  where "f has_prod p \<equiv> raw_has_prod f 0 p \<or> (\<exists>i q. p = 0 \<and> f i = 0 \<and> raw_has_prod f (Suc i) q)"

definition convergent_prod :: "(nat \<Rightarrow> 'a :: {t2_space,comm_semiring_1}) \<Rightarrow> bool" where
  "convergent_prod f \<equiv> \<exists>M p. raw_has_prod f M p"

definition prodinf :: "(nat \<Rightarrow> 'a::{t2_space, comm_semiring_1}) \<Rightarrow> 'a"
    (binder "\<Prod>" 10)
  where "prodinf f = (THE p. f has_prod p)"

lemmas prod_defs = raw_has_prod_def has_prod_def convergent_prod_def prodinf_def

lemma has_prod_subst[trans]: "f = g \<Longrightarrow> g has_prod z \<Longrightarrow> f has_prod z"
  by simp

lemma has_prod_cong: "(\<And>n. f n = g n) \<Longrightarrow> f has_prod c \<longleftrightarrow> g has_prod c"
  by presburger

lemma raw_has_prod_nonzero [simp]: "\<not> raw_has_prod f M 0"
  by (simp add: raw_has_prod_def)

lemma raw_has_prod_eq_0:
  fixes f :: "nat \<Rightarrow> 'a::{semidom,t2_space}"
  assumes p: "raw_has_prod f m p" and i: "f i = 0" "i \<ge> m"
  shows "p = 0"
proof -
  have eq0: "(\<Prod>k\<le>n. f (k+m)) = 0" if "i - m \<le> n" for n
  proof -
    have "\<exists>k\<le>n. f (k + m) = 0"
      using i that by auto
    then show ?thesis
      by auto
  qed
  have "(\<lambda>n. \<Prod>i\<le>n. f (i + m)) \<longlonglongrightarrow> 0"
    by (rule LIMSEQ_offset [where k = "i-m"]) (simp add: eq0)
    with p show ?thesis
      unfolding raw_has_prod_def
    using LIMSEQ_unique by blast
qed

lemma raw_has_prod_Suc: 
  "raw_has_prod f (Suc M) a \<longleftrightarrow> raw_has_prod (\<lambda>n. f (Suc n)) M a"
  unfolding raw_has_prod_def by auto

lemma has_prod_0_iff: "f has_prod 0 \<longleftrightarrow> (\<exists>i. f i = 0 \<and> (\<exists>p. raw_has_prod f (Suc i) p))"
  by (simp add: has_prod_def)
      
lemma has_prod_unique2: 
  fixes f :: "nat \<Rightarrow> 'a::{semidom,t2_space}"
  assumes "f has_prod a" "f has_prod b" shows "a = b"
  using assms
  by (auto simp: has_prod_def raw_has_prod_eq_0) (meson raw_has_prod_def sequentially_bot tendsto_unique)

lemma has_prod_unique:
  fixes f :: "nat \<Rightarrow> 'a :: {semidom,t2_space}"
  shows "f has_prod s \<Longrightarrow> s = prodinf f"
  by (simp add: has_prod_unique2 prodinf_def the_equality)

lemma convergent_prod_altdef:
  fixes f :: "nat \<Rightarrow> 'a :: {t2_space,comm_semiring_1}"
  shows "convergent_prod f \<longleftrightarrow> (\<exists>M L. (\<forall>n\<ge>M. f n \<noteq> 0) \<and> (\<lambda>n. \<Prod>i\<le>n. f (i+M)) \<longlonglongrightarrow> L \<and> L \<noteq> 0)"
proof
  assume "convergent_prod f"
  then obtain M L where *: "(\<lambda>n. \<Prod>i\<le>n. f (i+M)) \<longlonglongrightarrow> L" "L \<noteq> 0"
    by (auto simp: prod_defs)
  have "f i \<noteq> 0" if "i \<ge> M" for i
  proof
    assume "f i = 0"
    have **: "eventually (\<lambda>n. (\<Prod>i\<le>n. f (i+M)) = 0) sequentially"
      using eventually_ge_at_top[of "i - M"]
    proof eventually_elim
      case (elim n)
      with \<open>f i = 0\<close> and \<open>i \<ge> M\<close> show ?case
        by (auto intro!: bexI[of _ "i - M"] prod_zero)
    qed
    have "(\<lambda>n. (\<Prod>i\<le>n. f (i+M))) \<longlonglongrightarrow> 0"
      unfolding filterlim_iff
      by (auto dest!: eventually_nhds_x_imp_x intro!: eventually_mono[OF **])
    from tendsto_unique[OF _ this *(1)] and *(2)
      show False by simp
  qed
  with * show "(\<exists>M L. (\<forall>n\<ge>M. f n \<noteq> 0) \<and> (\<lambda>n. \<Prod>i\<le>n. f (i+M)) \<longlonglongrightarrow> L \<and> L \<noteq> 0)" 
    by blast
qed (auto simp: prod_defs)


subsection\<open>Absolutely convergent products\<close>

definition abs_convergent_prod :: "(nat \<Rightarrow> _) \<Rightarrow> bool" where
  "abs_convergent_prod f \<longleftrightarrow> convergent_prod (\<lambda>i. 1 + norm (f i - 1))"

lemma abs_convergent_prodI:
  assumes "convergent (\<lambda>n. \<Prod>i\<le>n. 1 + norm (f i - 1))"
  shows   "abs_convergent_prod f"
proof -
  from assms obtain L where L: "(\<lambda>n. \<Prod>i\<le>n. 1 + norm (f i - 1)) \<longlonglongrightarrow> L"
    by (auto simp: convergent_def)
  have "L \<ge> 1"
  proof (rule tendsto_le)
    show "eventually (\<lambda>n. (\<Prod>i\<le>n. 1 + norm (f i - 1)) \<ge> 1) sequentially"
    proof (intro always_eventually allI)
      fix n
      have "(\<Prod>i\<le>n. 1 + norm (f i - 1)) \<ge> (\<Prod>i\<le>n. 1)"
        by (intro prod_mono) auto
      thus "(\<Prod>i\<le>n. 1 + norm (f i - 1)) \<ge> 1" by simp
    qed
  qed (use L in simp_all)
  hence "L \<noteq> 0" by auto
  with L show ?thesis unfolding abs_convergent_prod_def prod_defs
    by (intro exI[of _ "0::nat"] exI[of _ L]) auto
qed

lemma
  fixes f :: "nat \<Rightarrow> 'a :: {topological_semigroup_mult,t2_space,idom}"
  assumes "convergent_prod f"
  shows   convergent_prod_imp_convergent: "convergent (\<lambda>n. \<Prod>i\<le>n. f i)"
    and   convergent_prod_to_zero_iff:    "(\<lambda>n. \<Prod>i\<le>n. f i) \<longlonglongrightarrow> 0 \<longleftrightarrow> (\<exists>i. f i = 0)"
proof -
  from assms obtain M L 
    where M: "\<And>n. n \<ge> M \<Longrightarrow> f n \<noteq> 0" and "(\<lambda>n. \<Prod>i\<le>n. f (i + M)) \<longlonglongrightarrow> L" and "L \<noteq> 0"
    by (auto simp: convergent_prod_altdef)
  note this(2)
  also have "(\<lambda>n. \<Prod>i\<le>n. f (i + M)) = (\<lambda>n. \<Prod>i=M..M+n. f i)"
    by (intro ext prod.reindex_bij_witness[of _ "\<lambda>n. n - M" "\<lambda>n. n + M"]) auto
  finally have "(\<lambda>n. (\<Prod>i<M. f i) * (\<Prod>i=M..M+n. f i)) \<longlonglongrightarrow> (\<Prod>i<M. f i) * L"
    by (intro tendsto_mult tendsto_const)
  also have "(\<lambda>n. (\<Prod>i<M. f i) * (\<Prod>i=M..M+n. f i)) = (\<lambda>n. (\<Prod>i\<in>{..<M}\<union>{M..M+n}. f i))"
    by (subst prod.union_disjoint) auto
  also have "(\<lambda>n. {..<M} \<union> {M..M+n}) = (\<lambda>n. {..n+M})" by auto
  finally have lim: "(\<lambda>n. prod f {..n}) \<longlonglongrightarrow> prod f {..<M} * L" 
    by (rule LIMSEQ_offset)
  thus "convergent (\<lambda>n. \<Prod>i\<le>n. f i)"
    by (auto simp: convergent_def)

  show "(\<lambda>n. \<Prod>i\<le>n. f i) \<longlonglongrightarrow> 0 \<longleftrightarrow> (\<exists>i. f i = 0)"
  proof
    assume "\<exists>i. f i = 0"
    then obtain i where "f i = 0" by auto
    moreover with M have "i < M" by (cases "i < M") auto
    ultimately have "(\<Prod>i<M. f i) = 0" by auto
    with lim show "(\<lambda>n. \<Prod>i\<le>n. f i) \<longlonglongrightarrow> 0" by simp
  next
    assume "(\<lambda>n. \<Prod>i\<le>n. f i) \<longlonglongrightarrow> 0"
    from tendsto_unique[OF _ this lim] and \<open>L \<noteq> 0\<close>
    show "\<exists>i. f i = 0" by auto
  qed
qed

lemma convergent_prod_iff_nz_lim:
  fixes f :: "nat \<Rightarrow> 'a :: {topological_semigroup_mult,t2_space,idom}"
  assumes "\<And>i. f i \<noteq> 0"
  shows "convergent_prod f \<longleftrightarrow> (\<exists>L. (\<lambda>n. \<Prod>i\<le>n. f i) \<longlonglongrightarrow> L \<and> L \<noteq> 0)"
    (is "?lhs \<longleftrightarrow> ?rhs")
proof
  assume ?lhs then show ?rhs
    using assms convergentD convergent_prod_imp_convergent convergent_prod_to_zero_iff by blast
next
  assume ?rhs then show ?lhs
    unfolding prod_defs
    by (rule_tac x=0 in exI) auto
qed

lemma convergent_prod_iff_convergent: 
  fixes f :: "nat \<Rightarrow> 'a :: {topological_semigroup_mult,t2_space,idom}"
  assumes "\<And>i. f i \<noteq> 0"
  shows "convergent_prod f \<longleftrightarrow> convergent (\<lambda>n. \<Prod>i\<le>n. f i) \<and> lim (\<lambda>n. \<Prod>i\<le>n. f i) \<noteq> 0"
  by (force simp: convergent_prod_iff_nz_lim assms convergent_def limI)


lemma abs_convergent_prod_altdef:
  fixes f :: "nat \<Rightarrow> 'a :: {one,real_normed_vector}"
  shows  "abs_convergent_prod f \<longleftrightarrow> convergent (\<lambda>n. \<Prod>i\<le>n. 1 + norm (f i - 1))"
proof
  assume "abs_convergent_prod f"
  thus "convergent (\<lambda>n. \<Prod>i\<le>n. 1 + norm (f i - 1))"
    by (auto simp: abs_convergent_prod_def intro!: convergent_prod_imp_convergent)
qed (auto intro: abs_convergent_prodI)

lemma weierstrass_prod_ineq:
  fixes f :: "'a \<Rightarrow> real" 
  assumes "\<And>x. x \<in> A \<Longrightarrow> f x \<in> {0..1}"
  shows   "1 - sum f A \<le> (\<Prod>x\<in>A. 1 - f x)"
  using assms
proof (induction A rule: infinite_finite_induct)
  case (insert x A)
  from insert.hyps and insert.prems 
    have "1 - sum f A + f x * (\<Prod>x\<in>A. 1 - f x) \<le> (\<Prod>x\<in>A. 1 - f x) + f x * (\<Prod>x\<in>A. 1)"
    by (intro insert.IH add_mono mult_left_mono prod_mono) auto
  with insert.hyps show ?case by (simp add: algebra_simps)
qed simp_all

lemma norm_prod_minus1_le_prod_minus1:
  fixes f :: "nat \<Rightarrow> 'a :: {real_normed_div_algebra,comm_ring_1}"  
  shows "norm (prod (\<lambda>n. 1 + f n) A - 1) \<le> prod (\<lambda>n. 1 + norm (f n)) A - 1"
proof (induction A rule: infinite_finite_induct)
  case (insert x A)
  from insert.hyps have 
    "norm ((\<Prod>n\<in>insert x A. 1 + f n) - 1) = 
       norm ((\<Prod>n\<in>A. 1 + f n) - 1 + f x * (\<Prod>n\<in>A. 1 + f n))"
    by (simp add: algebra_simps)
  also have "\<dots> \<le> norm ((\<Prod>n\<in>A. 1 + f n) - 1) + norm (f x * (\<Prod>n\<in>A. 1 + f n))"
    by (rule norm_triangle_ineq)
  also have "norm (f x * (\<Prod>n\<in>A. 1 + f n)) = norm (f x) * (\<Prod>x\<in>A. norm (1 + f x))"
    by (simp add: prod_norm norm_mult)
  also have "(\<Prod>x\<in>A. norm (1 + f x)) \<le> (\<Prod>x\<in>A. norm (1::'a) + norm (f x))"
    by (intro prod_mono norm_triangle_ineq ballI conjI) auto
  also have "norm (1::'a) = 1" by simp
  also note insert.IH
  also have "(\<Prod>n\<in>A. 1 + norm (f n)) - 1 + norm (f x) * (\<Prod>x\<in>A. 1 + norm (f x)) =
             (\<Prod>n\<in>insert x A. 1 + norm (f n)) - 1"
    using insert.hyps by (simp add: algebra_simps)
  finally show ?case by - (simp_all add: mult_left_mono)
qed simp_all

lemma convergent_prod_imp_ev_nonzero:
  fixes f :: "nat \<Rightarrow> 'a :: {t2_space,comm_semiring_1}"
  assumes "convergent_prod f"
  shows   "eventually (\<lambda>n. f n \<noteq> 0) sequentially"
  using assms by (auto simp: eventually_at_top_linorder convergent_prod_altdef)

lemma convergent_prod_imp_LIMSEQ:
  fixes f :: "nat \<Rightarrow> 'a :: {real_normed_field}"
  assumes "convergent_prod f"
  shows   "f \<longlonglongrightarrow> 1"
proof -
  from assms obtain M L where L: "(\<lambda>n. \<Prod>i\<le>n. f (i+M)) \<longlonglongrightarrow> L" "\<And>n. n \<ge> M \<Longrightarrow> f n \<noteq> 0" "L \<noteq> 0"
    by (auto simp: convergent_prod_altdef)
  hence L': "(\<lambda>n. \<Prod>i\<le>Suc n. f (i+M)) \<longlonglongrightarrow> L" by (subst filterlim_sequentially_Suc)
  have "(\<lambda>n. (\<Prod>i\<le>Suc n. f (i+M)) / (\<Prod>i\<le>n. f (i+M))) \<longlonglongrightarrow> L / L"
    using L L' by (intro tendsto_divide) simp_all
  also from L have "L / L = 1" by simp
  also have "(\<lambda>n. (\<Prod>i\<le>Suc n. f (i+M)) / (\<Prod>i\<le>n. f (i+M))) = (\<lambda>n. f (n + Suc M))"
    using assms L by (auto simp: fun_eq_iff atMost_Suc)
  finally show ?thesis by (rule LIMSEQ_offset)
qed

lemma abs_convergent_prod_imp_summable:
  fixes f :: "nat \<Rightarrow> 'a :: real_normed_div_algebra"
  assumes "abs_convergent_prod f"
  shows "summable (\<lambda>i. norm (f i - 1))"
proof -
  from assms have "convergent (\<lambda>n. \<Prod>i\<le>n. 1 + norm (f i - 1))" 
    unfolding abs_convergent_prod_def by (rule convergent_prod_imp_convergent)
  then obtain L where L: "(\<lambda>n. \<Prod>i\<le>n. 1 + norm (f i - 1)) \<longlonglongrightarrow> L"
    unfolding convergent_def by blast
  have "convergent (\<lambda>n. \<Sum>i\<le>n. norm (f i - 1))"
  proof (rule Bseq_monoseq_convergent)
    have "eventually (\<lambda>n. (\<Prod>i\<le>n. 1 + norm (f i - 1)) < L + 1) sequentially"
      using L(1) by (rule order_tendstoD) simp_all
    hence "\<forall>\<^sub>F x in sequentially. norm (\<Sum>i\<le>x. norm (f i - 1)) \<le> L + 1"
    proof eventually_elim
      case (elim n)
      have "norm (\<Sum>i\<le>n. norm (f i - 1)) = (\<Sum>i\<le>n. norm (f i - 1))"
        unfolding real_norm_def by (intro abs_of_nonneg sum_nonneg) simp_all
      also have "\<dots> \<le> (\<Prod>i\<le>n. 1 + norm (f i - 1))" by (rule sum_le_prod) auto
      also have "\<dots> < L + 1" by (rule elim)
      finally show ?case by simp
    qed
    thus "Bseq (\<lambda>n. \<Sum>i\<le>n. norm (f i - 1))" by (rule BfunI)
  next
    show "monoseq (\<lambda>n. \<Sum>i\<le>n. norm (f i - 1))"
      by (rule mono_SucI1) auto
  qed
  thus "summable (\<lambda>i. norm (f i - 1))" by (simp add: summable_iff_convergent')
qed

lemma summable_imp_abs_convergent_prod:
  fixes f :: "nat \<Rightarrow> 'a :: real_normed_div_algebra"
  assumes "summable (\<lambda>i. norm (f i - 1))"
  shows   "abs_convergent_prod f"
proof (intro abs_convergent_prodI Bseq_monoseq_convergent)
  show "monoseq (\<lambda>n. \<Prod>i\<le>n. 1 + norm (f i - 1))"
    by (intro mono_SucI1) 
       (auto simp: atMost_Suc algebra_simps intro!: mult_nonneg_nonneg prod_nonneg)
next
  show "Bseq (\<lambda>n. \<Prod>i\<le>n. 1 + norm (f i - 1))"
  proof (rule Bseq_eventually_mono)
    show "eventually (\<lambda>n. norm (\<Prod>i\<le>n. 1 + norm (f i - 1)) \<le> 
            norm (exp (\<Sum>i\<le>n. norm (f i - 1)))) sequentially"
      by (intro always_eventually allI) (auto simp: abs_prod exp_sum intro!: prod_mono)
  next
    from assms have "(\<lambda>n. \<Sum>i\<le>n. norm (f i - 1)) \<longlonglongrightarrow> (\<Sum>i. norm (f i - 1))"
      using sums_def_le by blast
    hence "(\<lambda>n. exp (\<Sum>i\<le>n. norm (f i - 1))) \<longlonglongrightarrow> exp (\<Sum>i. norm (f i - 1))"
      by (rule tendsto_exp)
    hence "convergent (\<lambda>n. exp (\<Sum>i\<le>n. norm (f i - 1)))"
      by (rule convergentI)
    thus "Bseq (\<lambda>n. exp (\<Sum>i\<le>n. norm (f i - 1)))"
      by (rule convergent_imp_Bseq)
  qed
qed

lemma abs_convergent_prod_conv_summable:
  fixes f :: "nat \<Rightarrow> 'a :: real_normed_div_algebra"
  shows "abs_convergent_prod f \<longleftrightarrow> summable (\<lambda>i. norm (f i - 1))"
  by (blast intro: abs_convergent_prod_imp_summable summable_imp_abs_convergent_prod)

lemma abs_convergent_prod_imp_LIMSEQ:
  fixes f :: "nat \<Rightarrow> 'a :: {comm_ring_1,real_normed_div_algebra}"
  assumes "abs_convergent_prod f"
  shows   "f \<longlonglongrightarrow> 1"
proof -
  from assms have "summable (\<lambda>n. norm (f n - 1))"
    by (rule abs_convergent_prod_imp_summable)
  from summable_LIMSEQ_zero[OF this] have "(\<lambda>n. f n - 1) \<longlonglongrightarrow> 0"
    by (simp add: tendsto_norm_zero_iff)
  from tendsto_add[OF this tendsto_const[of 1]] show ?thesis by simp
qed

lemma abs_convergent_prod_imp_ev_nonzero:
  fixes f :: "nat \<Rightarrow> 'a :: {comm_ring_1,real_normed_div_algebra}"
  assumes "abs_convergent_prod f"
  shows   "eventually (\<lambda>n. f n \<noteq> 0) sequentially"
proof -
  from assms have "f \<longlonglongrightarrow> 1" 
    by (rule abs_convergent_prod_imp_LIMSEQ)
  hence "eventually (\<lambda>n. dist (f n) 1 < 1) at_top"
    by (auto simp: tendsto_iff)
  thus ?thesis by eventually_elim auto
qed

lemma convergent_prod_offset:
  assumes "convergent_prod (\<lambda>n. f (n + m))"  
  shows   "convergent_prod f"
proof -
  from assms obtain M L where "(\<lambda>n. \<Prod>k\<le>n. f (k + (M + m))) \<longlonglongrightarrow> L" "L \<noteq> 0"
    by (auto simp: prod_defs add.assoc)
  thus "convergent_prod f" 
    unfolding prod_defs by blast
qed

lemma abs_convergent_prod_offset:
  assumes "abs_convergent_prod (\<lambda>n. f (n + m))"  
  shows   "abs_convergent_prod f"
  using assms unfolding abs_convergent_prod_def by (rule convergent_prod_offset)

subsection\<open>Ignoring initial segments\<close>

lemma raw_has_prod_ignore_initial_segment:
  fixes f :: "nat \<Rightarrow> 'a :: real_normed_field"
  assumes "raw_has_prod f M p" "N \<ge> M"
  obtains q where  "raw_has_prod f N q"
proof -
  have p: "(\<lambda>n. \<Prod>k\<le>n. f (k + M)) \<longlonglongrightarrow> p" and "p \<noteq> 0" 
    using assms by (auto simp: raw_has_prod_def)
  then have nz: "\<And>n. n \<ge> M \<Longrightarrow> f n \<noteq> 0"
    using assms by (auto simp: raw_has_prod_eq_0)
  define C where "C = (\<Prod>k<N-M. f (k + M))"
  from nz have [simp]: "C \<noteq> 0" 
    by (auto simp: C_def)

  from p have "(\<lambda>i. \<Prod>k\<le>i + (N-M). f (k + M)) \<longlonglongrightarrow> p" 
    by (rule LIMSEQ_ignore_initial_segment)
  also have "(\<lambda>i. \<Prod>k\<le>i + (N-M). f (k + M)) = (\<lambda>n. C * (\<Prod>k\<le>n. f (k + N)))"
  proof (rule ext, goal_cases)
    case (1 n)
    have "{..n+(N-M)} = {..<(N-M)} \<union> {(N-M)..n+(N-M)}" by auto
    also have "(\<Prod>k\<in>\<dots>. f (k + M)) = C * (\<Prod>k=(N-M)..n+(N-M). f (k + M))"
      unfolding C_def by (rule prod.union_disjoint) auto
    also have "(\<Prod>k=(N-M)..n+(N-M). f (k + M)) = (\<Prod>k\<le>n. f (k + (N-M) + M))"
      by (intro ext prod.reindex_bij_witness[of _ "\<lambda>k. k + (N-M)" "\<lambda>k. k - (N-M)"]) auto
    finally show ?case
      using \<open>N \<ge> M\<close> by (simp add: add_ac)
  qed
  finally have "(\<lambda>n. C * (\<Prod>k\<le>n. f (k + N)) / C) \<longlonglongrightarrow> p / C"
    by (intro tendsto_divide tendsto_const) auto
  hence "(\<lambda>n. \<Prod>k\<le>n. f (k + N)) \<longlonglongrightarrow> p / C" by simp
  moreover from \<open>p \<noteq> 0\<close> have "p / C \<noteq> 0" by simp
  ultimately show ?thesis
    using raw_has_prod_def that by blast 
qed

corollary convergent_prod_ignore_initial_segment:
  fixes f :: "nat \<Rightarrow> 'a :: real_normed_field"
  assumes "convergent_prod f"
  shows   "convergent_prod (\<lambda>n. f (n + m))"
  using assms
  unfolding convergent_prod_def 
  apply clarify
  apply (erule_tac N="M+m" in raw_has_prod_ignore_initial_segment)
  apply (auto simp add: raw_has_prod_def add_ac)
  done

corollary convergent_prod_ignore_nonzero_segment:
  fixes f :: "nat \<Rightarrow> 'a :: real_normed_field"
  assumes f: "convergent_prod f" and nz: "\<And>i. i \<ge> M \<Longrightarrow> f i \<noteq> 0"
  shows "\<exists>p. raw_has_prod f M p"
  using convergent_prod_ignore_initial_segment [OF f]
  by (metis convergent_LIMSEQ_iff convergent_prod_iff_convergent le_add_same_cancel2 nz prod_defs(1) zero_order(1))

corollary abs_convergent_prod_ignore_initial_segment:
  assumes "abs_convergent_prod f"
  shows   "abs_convergent_prod (\<lambda>n. f (n + m))"
  using assms unfolding abs_convergent_prod_def 
  by (rule convergent_prod_ignore_initial_segment)

lemma abs_convergent_prod_imp_convergent_prod:
  fixes f :: "nat \<Rightarrow> 'a :: {real_normed_div_algebra,complete_space,comm_ring_1}"
  assumes "abs_convergent_prod f"
  shows   "convergent_prod f"
proof -
  from assms have "eventually (\<lambda>n. f n \<noteq> 0) sequentially"
    by (rule abs_convergent_prod_imp_ev_nonzero)
  then obtain N where N: "f n \<noteq> 0" if "n \<ge> N" for n 
    by (auto simp: eventually_at_top_linorder)
  let ?P = "\<lambda>n. \<Prod>i\<le>n. f (i + N)" and ?Q = "\<lambda>n. \<Prod>i\<le>n. 1 + norm (f (i + N) - 1)"

  have "Cauchy ?P"
  proof (rule CauchyI', goal_cases)
    case (1 \<epsilon>)
    from assms have "abs_convergent_prod (\<lambda>n. f (n + N))"
      by (rule abs_convergent_prod_ignore_initial_segment)
    hence "Cauchy ?Q"
      unfolding abs_convergent_prod_def
      by (intro convergent_Cauchy convergent_prod_imp_convergent)
    from CauchyD[OF this 1] obtain M where M: "norm (?Q m - ?Q n) < \<epsilon>" if "m \<ge> M" "n \<ge> M" for m n
      by blast
    show ?case
    proof (rule exI[of _ M], safe, goal_cases)
      case (1 m n)
      have "dist (?P m) (?P n) = norm (?P n - ?P m)"
        by (simp add: dist_norm norm_minus_commute)
      also from 1 have "{..n} = {..m} \<union> {m<..n}" by auto
      hence "norm (?P n - ?P m) = norm (?P m * (\<Prod>k\<in>{m<..n}. f (k + N)) - ?P m)"
        by (subst prod.union_disjoint [symmetric]) (auto simp: algebra_simps)
      also have "\<dots> = norm (?P m * ((\<Prod>k\<in>{m<..n}. f (k + N)) - 1))"
        by (simp add: algebra_simps)
      also have "\<dots> = (\<Prod>k\<le>m. norm (f (k + N))) * norm ((\<Prod>k\<in>{m<..n}. f (k + N)) - 1)"
        by (simp add: norm_mult prod_norm)
      also have "\<dots> \<le> ?Q m * ((\<Prod>k\<in>{m<..n}. 1 + norm (f (k + N) - 1)) - 1)"
        using norm_prod_minus1_le_prod_minus1[of "\<lambda>k. f (k + N) - 1" "{m<..n}"]
              norm_triangle_ineq[of 1 "f k - 1" for k]
        by (intro mult_mono prod_mono ballI conjI norm_prod_minus1_le_prod_minus1 prod_nonneg) auto
      also have "\<dots> = ?Q m * (\<Prod>k\<in>{m<..n}. 1 + norm (f (k + N) - 1)) - ?Q m"
        by (simp add: algebra_simps)
      also have "?Q m * (\<Prod>k\<in>{m<..n}. 1 + norm (f (k + N) - 1)) = 
                   (\<Prod>k\<in>{..m}\<union>{m<..n}. 1 + norm (f (k + N) - 1))"
        by (rule prod.union_disjoint [symmetric]) auto
      also from 1 have "{..m}\<union>{m<..n} = {..n}" by auto
      also have "?Q n - ?Q m \<le> norm (?Q n - ?Q m)" by simp
      also from 1 have "\<dots> < \<epsilon>" by (intro M) auto
      finally show ?case .
    qed
  qed
  hence conv: "convergent ?P" by (rule Cauchy_convergent)
  then obtain L where L: "?P \<longlonglongrightarrow> L"
    by (auto simp: convergent_def)

  have "L \<noteq> 0"
  proof
    assume [simp]: "L = 0"
    from tendsto_norm[OF L] have limit: "(\<lambda>n. \<Prod>k\<le>n. norm (f (k + N))) \<longlonglongrightarrow> 0" 
      by (simp add: prod_norm)

    from assms have "(\<lambda>n. f (n + N)) \<longlonglongrightarrow> 1"
      by (intro abs_convergent_prod_imp_LIMSEQ abs_convergent_prod_ignore_initial_segment)
    hence "eventually (\<lambda>n. norm (f (n + N) - 1) < 1) sequentially"
      by (auto simp: tendsto_iff dist_norm)
    then obtain M0 where M0: "norm (f (n + N) - 1) < 1" if "n \<ge> M0" for n
      by (auto simp: eventually_at_top_linorder)

    {
      fix M assume M: "M \<ge> M0"
      with M0 have M: "norm (f (n + N) - 1) < 1" if "n \<ge> M" for n using that by simp

      have "(\<lambda>n. \<Prod>k\<le>n. 1 - norm (f (k+M+N) - 1)) \<longlonglongrightarrow> 0"
      proof (rule tendsto_sandwich)
        show "eventually (\<lambda>n. (\<Prod>k\<le>n. 1 - norm (f (k+M+N) - 1)) \<ge> 0) sequentially"
          using M by (intro always_eventually prod_nonneg allI ballI) (auto intro: less_imp_le)
        have "norm (1::'a) - norm (f (i + M + N) - 1) \<le> norm (f (i + M + N))" for i
          using norm_triangle_ineq3[of "f (i + M + N)" 1] by simp
        thus "eventually (\<lambda>n. (\<Prod>k\<le>n. 1 - norm (f (k+M+N) - 1)) \<le> (\<Prod>k\<le>n. norm (f (k+M+N)))) at_top"
          using M by (intro always_eventually allI prod_mono ballI conjI) (auto intro: less_imp_le)
        
        define C where "C = (\<Prod>k<M. norm (f (k + N)))"
        from N have [simp]: "C \<noteq> 0" by (auto simp: C_def)
        from L have "(\<lambda>n. norm (\<Prod>k\<le>n+M. f (k + N))) \<longlonglongrightarrow> 0"
          by (intro LIMSEQ_ignore_initial_segment) (simp add: tendsto_norm_zero_iff)
        also have "(\<lambda>n. norm (\<Prod>k\<le>n+M. f (k + N))) = (\<lambda>n. C * (\<Prod>k\<le>n. norm (f (k + M + N))))"
        proof (rule ext, goal_cases)
          case (1 n)
          have "{..n+M} = {..<M} \<union> {M..n+M}" by auto
          also have "norm (\<Prod>k\<in>\<dots>. f (k + N)) = C * norm (\<Prod>k=M..n+M. f (k + N))"
            unfolding C_def by (subst prod.union_disjoint) (auto simp: norm_mult prod_norm)
          also have "(\<Prod>k=M..n+M. f (k + N)) = (\<Prod>k\<le>n. f (k + N + M))"
            by (intro prod.reindex_bij_witness[of _ "\<lambda>i. i + M" "\<lambda>i. i - M"]) auto
          finally show ?case by (simp add: add_ac prod_norm)
        qed
        finally have "(\<lambda>n. C * (\<Prod>k\<le>n. norm (f (k + M + N))) / C) \<longlonglongrightarrow> 0 / C"
          by (intro tendsto_divide tendsto_const) auto
        thus "(\<lambda>n. \<Prod>k\<le>n. norm (f (k + M + N))) \<longlonglongrightarrow> 0" by simp
      qed simp_all

      have "1 - (\<Sum>i. norm (f (i + M + N) - 1)) \<le> 0"
      proof (rule tendsto_le)
        show "eventually (\<lambda>n. 1 - (\<Sum>k\<le>n. norm (f (k+M+N) - 1)) \<le> 
                                (\<Prod>k\<le>n. 1 - norm (f (k+M+N) - 1))) at_top"
          using M by (intro always_eventually allI weierstrass_prod_ineq) (auto intro: less_imp_le)
        show "(\<lambda>n. \<Prod>k\<le>n. 1 - norm (f (k+M+N) - 1)) \<longlonglongrightarrow> 0" by fact
        show "(\<lambda>n. 1 - (\<Sum>k\<le>n. norm (f (k + M + N) - 1)))
                  \<longlonglongrightarrow> 1 - (\<Sum>i. norm (f (i + M + N) - 1))"
          by (intro tendsto_intros summable_LIMSEQ' summable_ignore_initial_segment 
                abs_convergent_prod_imp_summable assms)
      qed simp_all
      hence "(\<Sum>i. norm (f (i + M + N) - 1)) \<ge> 1" by simp
      also have "\<dots> + (\<Sum>i<M. norm (f (i + N) - 1)) = (\<Sum>i. norm (f (i + N) - 1))"
        by (intro suminf_split_initial_segment [symmetric] summable_ignore_initial_segment
              abs_convergent_prod_imp_summable assms)
      finally have "1 + (\<Sum>i<M. norm (f (i + N) - 1)) \<le> (\<Sum>i. norm (f (i + N) - 1))" by simp
    } note * = this

    have "1 + (\<Sum>i. norm (f (i + N) - 1)) \<le> (\<Sum>i. norm (f (i + N) - 1))"
    proof (rule tendsto_le)
      show "(\<lambda>M. 1 + (\<Sum>i<M. norm (f (i + N) - 1))) \<longlonglongrightarrow> 1 + (\<Sum>i. norm (f (i + N) - 1))"
        by (intro tendsto_intros summable_LIMSEQ summable_ignore_initial_segment 
                abs_convergent_prod_imp_summable assms)
      show "eventually (\<lambda>M. 1 + (\<Sum>i<M. norm (f (i + N) - 1)) \<le> (\<Sum>i. norm (f (i + N) - 1))) at_top"
        using eventually_ge_at_top[of M0] by eventually_elim (use * in auto)
    qed simp_all
    thus False by simp
  qed
  with L show ?thesis by (auto simp: prod_defs)
qed

subsection\<open>More elementary properties\<close>

lemma raw_has_prod_cases:
  fixes f :: "nat \<Rightarrow> 'a :: {idom,topological_semigroup_mult,t2_space}"
  assumes "raw_has_prod f M p"
  obtains i where "i<M" "f i = 0" | p where "raw_has_prod f 0 p"
proof -
  have "(\<lambda>n. \<Prod>i\<le>n. f (i + M)) \<longlonglongrightarrow> p" "p \<noteq> 0"
    using assms unfolding raw_has_prod_def by blast+
  then have "(\<lambda>n. prod f {..<M} * (\<Prod>i\<le>n. f (i + M))) \<longlonglongrightarrow> prod f {..<M} * p"
    by (metis tendsto_mult_left)
  moreover have "prod f {..<M} * (\<Prod>i\<le>n. f (i + M)) = prod f {..n+M}" for n
  proof -
    have "{..n+M} = {..<M} \<union> {M..n+M}"
      by auto
    then have "prod f {..n+M} = prod f {..<M} * prod f {M..n+M}"
      by simp (subst prod.union_disjoint; force)
    also have "\<dots> = prod f {..<M} * (\<Prod>i\<le>n. f (i + M))"
      by (metis (mono_tags, lifting) add.left_neutral atMost_atLeast0 prod_shift_bounds_cl_nat_ivl)
    finally show ?thesis by metis
  qed
  ultimately have "(\<lambda>n. prod f {..n}) \<longlonglongrightarrow> prod f {..<M} * p"
    by (auto intro: LIMSEQ_offset [where k=M])
  then have "raw_has_prod f 0 (prod f {..<M} * p)" if "\<forall>i<M. f i \<noteq> 0"
    using \<open>p \<noteq> 0\<close> assms that by (auto simp: raw_has_prod_def)
  then show thesis
    using that by blast
qed

corollary convergent_prod_offset_0:
  fixes f :: "nat \<Rightarrow> 'a :: {idom,topological_semigroup_mult,t2_space}"
  assumes "convergent_prod f" "\<And>i. f i \<noteq> 0"
  shows "\<exists>p. raw_has_prod f 0 p"
  using assms convergent_prod_def raw_has_prod_cases by blast

lemma prodinf_eq_lim:
  fixes f :: "nat \<Rightarrow> 'a :: {idom,topological_semigroup_mult,t2_space}"
  assumes "convergent_prod f" "\<And>i. f i \<noteq> 0"
  shows "prodinf f = lim (\<lambda>n. \<Prod>i\<le>n. f i)"
  using assms convergent_prod_offset_0 [OF assms]
  by (simp add: prod_defs lim_def) (metis (no_types) assms(1) convergent_prod_to_zero_iff)

lemma has_prod_one[simp, intro]: "(\<lambda>n. 1) has_prod 1"
  unfolding prod_defs by auto

lemma convergent_prod_one[simp, intro]: "convergent_prod (\<lambda>n. 1)"
  unfolding prod_defs by auto

lemma prodinf_cong: "(\<And>n. f n = g n) \<Longrightarrow> prodinf f = prodinf g"
  by presburger

lemma convergent_prod_cong:
  fixes f g :: "nat \<Rightarrow> 'a::{field,topological_semigroup_mult,t2_space}"
  assumes ev: "eventually (\<lambda>x. f x = g x) sequentially" and f: "\<And>i. f i \<noteq> 0" and g: "\<And>i. g i \<noteq> 0"
  shows "convergent_prod f = convergent_prod g"
proof -
  from assms obtain N where N: "\<forall>n\<ge>N. f n = g n"
    by (auto simp: eventually_at_top_linorder)
  define C where "C = (\<Prod>k<N. f k / g k)"
  with g have "C \<noteq> 0"
    by (simp add: f)
  have *: "eventually (\<lambda>n. prod f {..n} = C * prod g {..n}) sequentially"
    using eventually_ge_at_top[of N]
  proof eventually_elim
    case (elim n)
    then have "{..n} = {..<N} \<union> {N..n}"
      by auto
    also have "prod f \<dots> = prod f {..<N} * prod f {N..n}"
      by (intro prod.union_disjoint) auto
    also from N have "prod f {N..n} = prod g {N..n}"
      by (intro prod.cong) simp_all
    also have "prod f {..<N} * prod g {N..n} = C * (prod g {..<N} * prod g {N..n})"
      unfolding C_def by (simp add: g prod_dividef)
    also have "prod g {..<N} * prod g {N..n} = prod g ({..<N} \<union> {N..n})"
      by (intro prod.union_disjoint [symmetric]) auto
    also from elim have "{..<N} \<union> {N..n} = {..n}"
      by auto                                                                    
    finally show "prod f {..n} = C * prod g {..n}" .
  qed
  then have cong: "convergent (\<lambda>n. prod f {..n}) = convergent (\<lambda>n. C * prod g {..n})"
    by (rule convergent_cong)
  show ?thesis
  proof
    assume cf: "convergent_prod f"
    then have "\<not> (\<lambda>n. prod g {..n}) \<longlonglongrightarrow> 0"
      using tendsto_mult_left * convergent_prod_to_zero_iff f filterlim_cong by fastforce
    then show "convergent_prod g"
      by (metis convergent_mult_const_iff \<open>C \<noteq> 0\<close> cong cf convergent_LIMSEQ_iff convergent_prod_iff_convergent convergent_prod_imp_convergent g)
  next
    assume cg: "convergent_prod g"
    have "\<exists>a. C * a \<noteq> 0 \<and> (\<lambda>n. prod g {..n}) \<longlonglongrightarrow> a"
      by (metis (no_types) \<open>C \<noteq> 0\<close> cg convergent_prod_iff_nz_lim divide_eq_0_iff g nonzero_mult_div_cancel_right)
    then show "convergent_prod f"
      using "*" tendsto_mult_left filterlim_cong
      by (fastforce simp add: convergent_prod_iff_nz_lim f)
  qed
qed

lemma has_prod_finite:
  fixes f :: "nat \<Rightarrow> 'a::{semidom,t2_space}"
  assumes [simp]: "finite N"
    and f: "\<And>n. n \<notin> N \<Longrightarrow> f n = 1"
  shows "f has_prod (\<Prod>n\<in>N. f n)"
proof -
  have eq: "prod f {..n + Suc (Max N)} = prod f N" for n
  proof (rule prod.mono_neutral_right)
    show "N \<subseteq> {..n + Suc (Max N)}"
      by (auto simp: le_Suc_eq trans_le_add2)
    show "\<forall>i\<in>{..n + Suc (Max N)} - N. f i = 1"
      using f by blast
  qed auto
  show ?thesis
  proof (cases "\<forall>n\<in>N. f n \<noteq> 0")
    case True
    then have "prod f N \<noteq> 0"
      by simp
    moreover have "(\<lambda>n. prod f {..n}) \<longlonglongrightarrow> prod f N"
      by (rule LIMSEQ_offset[of _ "Suc (Max N)"]) (simp add: eq atLeast0LessThan del: add_Suc_right)
    ultimately show ?thesis
      by (simp add: raw_has_prod_def has_prod_def)
  next
    case False
    then obtain k where "k \<in> N" "f k = 0"
      by auto
    let ?Z = "{n \<in> N. f n = 0}"
    have maxge: "Max ?Z \<ge> n" if "f n = 0" for n
      using Max_ge [of ?Z] \<open>finite N\<close> \<open>f n = 0\<close>
      by (metis (mono_tags) Collect_mem_eq f finite_Collect_conjI mem_Collect_eq zero_neq_one)
    let ?q = "prod f {Suc (Max ?Z)..Max N}"
    have [simp]: "?q \<noteq> 0"
      using maxge Suc_n_not_le_n le_trans by force
    have eq: "(\<Prod>i\<le>n + Max N. f (Suc (i + Max ?Z))) = ?q" for n
    proof -
      have "(\<Prod>i\<le>n + Max N. f (Suc (i + Max ?Z))) = prod f {Suc (Max ?Z)..n + Max N + Suc (Max ?Z)}" 
      proof (rule prod.reindex_cong [where l = "\<lambda>i. i + Suc (Max ?Z)", THEN sym])
        show "{Suc (Max ?Z)..n + Max N + Suc (Max ?Z)} = (\<lambda>i. i + Suc (Max ?Z)) ` {..n + Max N}"
          using le_Suc_ex by fastforce
      qed (auto simp: inj_on_def)
      also have "\<dots> = ?q"
        by (rule prod.mono_neutral_right)
           (use Max.coboundedI [OF \<open>finite N\<close>] f in \<open>force+\<close>)
      finally show ?thesis .
    qed
    have q: "raw_has_prod f (Suc (Max ?Z)) ?q"
    proof (simp add: raw_has_prod_def)
      show "(\<lambda>n. \<Prod>i\<le>n. f (Suc (i + Max ?Z))) \<longlonglongrightarrow> ?q"
        by (rule LIMSEQ_offset[of _ "(Max N)"]) (simp add: eq)
    qed
    show ?thesis
      unfolding has_prod_def
    proof (intro disjI2 exI conjI)      
      show "prod f N = 0"
        using \<open>f k = 0\<close> \<open>k \<in> N\<close> \<open>finite N\<close> prod_zero by blast
      show "f (Max ?Z) = 0"
        using Max_in [of ?Z] \<open>finite N\<close> \<open>f k = 0\<close> \<open>k \<in> N\<close> by auto
    qed (use q in auto)
  qed
qed

corollary has_prod_0:
  fixes f :: "nat \<Rightarrow> 'a::{semidom,t2_space}"
  assumes "\<And>n. f n = 1"
  shows "f has_prod 1"
  by (simp add: assms has_prod_cong)

lemma prodinf_zero[simp]: "prodinf (\<lambda>n. 1::'a::real_normed_field) = 1"
  using has_prod_unique by force

lemma convergent_prod_finite:
  fixes f :: "nat \<Rightarrow> 'a::{idom,t2_space}"
  assumes "finite N" "\<And>n. n \<notin> N \<Longrightarrow> f n = 1"
  shows "convergent_prod f"
proof -
  have "\<exists>n p. raw_has_prod f n p"
    using assms has_prod_def has_prod_finite by blast
  then show ?thesis
    by (simp add: convergent_prod_def)
qed

lemma has_prod_If_finite_set:
  fixes f :: "nat \<Rightarrow> 'a::{idom,t2_space}"
  shows "finite A \<Longrightarrow> (\<lambda>r. if r \<in> A then f r else 1) has_prod (\<Prod>r\<in>A. f r)"
  using has_prod_finite[of A "(\<lambda>r. if r \<in> A then f r else 1)"]
  by simp

lemma has_prod_If_finite:
  fixes f :: "nat \<Rightarrow> 'a::{idom,t2_space}"
  shows "finite {r. P r} \<Longrightarrow> (\<lambda>r. if P r then f r else 1) has_prod (\<Prod>r | P r. f r)"
  using has_prod_If_finite_set[of "{r. P r}"] by simp

lemma convergent_prod_If_finite_set[simp, intro]:
  fixes f :: "nat \<Rightarrow> 'a::{idom,t2_space}"
  shows "finite A \<Longrightarrow> convergent_prod (\<lambda>r. if r \<in> A then f r else 1)"
  by (simp add: convergent_prod_finite)

lemma convergent_prod_If_finite[simp, intro]:
  fixes f :: "nat \<Rightarrow> 'a::{idom,t2_space}"
  shows "finite {r. P r} \<Longrightarrow> convergent_prod (\<lambda>r. if P r then f r else 1)"
  using convergent_prod_def has_prod_If_finite has_prod_def by fastforce

lemma has_prod_single:
  fixes f :: "nat \<Rightarrow> 'a::{idom,t2_space}"
  shows "(\<lambda>r. if r = i then f r else 1) has_prod f i"
  using has_prod_If_finite[of "\<lambda>r. r = i"] by simp

context
  fixes f :: "nat \<Rightarrow> 'a :: real_normed_field"
begin

lemma convergent_prod_imp_has_prod: 
  assumes "convergent_prod f"
  shows "\<exists>p. f has_prod p"
proof -
  obtain M p where p: "raw_has_prod f M p"
    using assms convergent_prod_def by blast
  then have "p \<noteq> 0"
    using raw_has_prod_nonzero by blast
  with p have fnz: "f i \<noteq> 0" if "i \<ge> M" for i
    using raw_has_prod_eq_0 that by blast
  define C where "C = (\<Prod>n<M. f n)"
  show ?thesis
  proof (cases "\<forall>n\<le>M. f n \<noteq> 0")
    case True
    then have "C \<noteq> 0"
      by (simp add: C_def)
    then show ?thesis
      by (meson True assms convergent_prod_offset_0 fnz has_prod_def nat_le_linear)
  next
    case False
    let ?N = "GREATEST n. f n = 0"
    have 0: "f ?N = 0"
      using fnz False
      by (metis (mono_tags, lifting) GreatestI_ex_nat nat_le_linear)
    have "f i \<noteq> 0" if "i > ?N" for i
      by (metis (mono_tags, lifting) Greatest_le_nat fnz leD linear that)
    then have "\<exists>p. raw_has_prod f (Suc ?N) p"
      using assms by (auto simp: intro!: convergent_prod_ignore_nonzero_segment)
    then show ?thesis
      unfolding has_prod_def using 0 by blast
  qed
qed

lemma convergent_prod_has_prod [intro]:
  shows "convergent_prod f \<Longrightarrow> f has_prod (prodinf f)"
  unfolding prodinf_def
  by (metis convergent_prod_imp_has_prod has_prod_unique theI')

lemma convergent_prod_LIMSEQ:
  shows "convergent_prod f \<Longrightarrow> (\<lambda>n. \<Prod>i\<le>n. f i) \<longlonglongrightarrow> prodinf f"
  by (metis convergent_LIMSEQ_iff convergent_prod_has_prod convergent_prod_imp_convergent 
      convergent_prod_to_zero_iff raw_has_prod_eq_0 has_prod_def prodinf_eq_lim zero_le)

lemma has_prod_iff: "f has_prod x \<longleftrightarrow> convergent_prod f \<and> prodinf f = x"
proof
  assume "f has_prod x"
  then show "convergent_prod f \<and> prodinf f = x"
    apply safe
    using convergent_prod_def has_prod_def apply blast
    using has_prod_unique by blast
qed auto

lemma convergent_prod_has_prod_iff: "convergent_prod f \<longleftrightarrow> f has_prod prodinf f"
  by (auto simp: has_prod_iff convergent_prod_has_prod)

lemma prodinf_finite:
  assumes N: "finite N"
    and f: "\<And>n. n \<notin> N \<Longrightarrow> f n = 1"
  shows "prodinf f = (\<Prod>n\<in>N. f n)"
  using has_prod_finite[OF assms, THEN has_prod_unique] by simp

end

subsection \<open>Infinite products on ordered, topological monoids\<close>

lemma LIMSEQ_prod_0: 
  fixes f :: "nat \<Rightarrow> 'a::{semidom,topological_space}"
  assumes "f i = 0"
  shows "(\<lambda>n. prod f {..n}) \<longlonglongrightarrow> 0"
proof (subst tendsto_cong)
  show "\<forall>\<^sub>F n in sequentially. prod f {..n} = 0"
  proof
    show "prod f {..n} = 0" if "n \<ge> i" for n
      using that assms by auto
  qed
qed auto

lemma LIMSEQ_prod_nonneg: 
  fixes f :: "nat \<Rightarrow> 'a::{linordered_semidom,linorder_topology}"
  assumes 0: "\<And>n. 0 \<le> f n" and a: "(\<lambda>n. prod f {..n}) \<longlonglongrightarrow> a"
  shows "a \<ge> 0"
  by (simp add: "0" prod_nonneg LIMSEQ_le_const [OF a])


context
  fixes f :: "nat \<Rightarrow> 'a::{linordered_semidom,linorder_topology}"
begin

lemma has_prod_le:
  assumes f: "f has_prod a" and g: "g has_prod b" and le: "\<And>n. 0 \<le> f n \<and> f n \<le> g n"
  shows "a \<le> b"
proof (cases "a=0 \<or> b=0")
  case True
  then show ?thesis
  proof
    assume [simp]: "a=0"
    have "b \<ge> 0"
    proof (rule LIMSEQ_prod_nonneg)
      show "(\<lambda>n. prod g {..n}) \<longlonglongrightarrow> b"
        using g by (auto simp: has_prod_def raw_has_prod_def LIMSEQ_prod_0)
    qed (use le order_trans in auto)
    then show ?thesis
      by auto
  next
    assume [simp]: "b=0"
    then obtain i where "g i = 0"    
      using g by (auto simp: prod_defs)
    then have "f i = 0"
      using antisym le by force
    then have "a=0"
      using f by (auto simp: prod_defs LIMSEQ_prod_0 LIMSEQ_unique)
    then show ?thesis
      by auto
  qed
next
  case False
  then show ?thesis
    using assms
    unfolding has_prod_def raw_has_prod_def
    by (force simp: LIMSEQ_prod_0 intro!: LIMSEQ_le prod_mono)
qed

lemma prodinf_le: 
  assumes f: "f has_prod a" and g: "g has_prod b" and le: "\<And>n. 0 \<le> f n \<and> f n \<le> g n"
  shows "prodinf f \<le> prodinf g"
  using has_prod_le [OF assms] has_prod_unique f g  by blast

end


lemma prod_le_prodinf: 
  fixes f :: "nat \<Rightarrow> 'a::{linordered_idom,linorder_topology}"
  assumes "f has_prod a" "\<And>i. 0 \<le> f i" "\<And>i. i\<ge>n \<Longrightarrow> 1 \<le> f i"
  shows "prod f {..<n} \<le> prodinf f"
  by(rule has_prod_le[OF has_prod_If_finite_set]) (use assms has_prod_unique in auto)

lemma prodinf_nonneg:
  fixes f :: "nat \<Rightarrow> 'a::{linordered_idom,linorder_topology}"
  assumes "f has_prod a" "\<And>i. 1 \<le> f i" 
  shows "1 \<le> prodinf f"
  using prod_le_prodinf[of f a 0] assms
  by (metis order_trans prod_ge_1 zero_le_one)

lemma prodinf_le_const:
  fixes f :: "nat \<Rightarrow> real"
  assumes "convergent_prod f" "\<And>n. prod f {..<n} \<le> x" 
  shows "prodinf f \<le> x"
  by (metis lessThan_Suc_atMost assms convergent_prod_LIMSEQ LIMSEQ_le_const2)

lemma prodinf_eq_one_iff: 
  fixes f :: "nat \<Rightarrow> real"
  assumes f: "convergent_prod f" and ge1: "\<And>n. 1 \<le> f n"
  shows "prodinf f = 1 \<longleftrightarrow> (\<forall>n. f n = 1)"
proof
  assume "prodinf f = 1" 
  then have "(\<lambda>n. \<Prod>i<n. f i) \<longlonglongrightarrow> 1"
    using convergent_prod_LIMSEQ[of f] assms by (simp add: LIMSEQ_lessThan_iff_atMost)
  then have "\<And>i. (\<Prod>n\<in>{i}. f n) \<le> 1"
  proof (rule LIMSEQ_le_const)
    have "1 \<le> prod f n" for n
      by (simp add: ge1 prod_ge_1)
    have "prod f {..<n} = 1" for n
      by (metis \<open>\<And>n. 1 \<le> prod f n\<close> \<open>prodinf f = 1\<close> antisym f convergent_prod_has_prod ge1 order_trans prod_le_prodinf zero_le_one)
    then have "(\<Prod>n\<in>{i}. f n) \<le> prod f {..<n}" if "n \<ge> Suc i" for i n
      by (metis mult.left_neutral order_refl prod.cong prod.neutral_const prod_lessThan_Suc)
    then show "\<exists>N. \<forall>n\<ge>N. (\<Prod>n\<in>{i}. f n) \<le> prod f {..<n}" for i
      by blast      
  qed
  with ge1 show "\<forall>n. f n = 1"
    by (auto intro!: antisym)
qed (metis prodinf_zero fun_eq_iff)

lemma prodinf_pos_iff:
  fixes f :: "nat \<Rightarrow> real"
  assumes "convergent_prod f" "\<And>n. 1 \<le> f n"
  shows "1 < prodinf f \<longleftrightarrow> (\<exists>i. 1 < f i)"
  using prod_le_prodinf[of f 1] prodinf_eq_one_iff
  by (metis convergent_prod_has_prod assms less_le prodinf_nonneg)

lemma less_1_prodinf2:
  fixes f :: "nat \<Rightarrow> real"
  assumes "convergent_prod f" "\<And>n. 1 \<le> f n" "1 < f i"
  shows "1 < prodinf f"
proof -
  have "1 < (\<Prod>n<Suc i. f n)"
    using assms  by (intro less_1_prod2[where i=i]) auto
  also have "\<dots> \<le> prodinf f"
    by (intro prod_le_prodinf) (use assms order_trans zero_le_one in \<open>blast+\<close>)
  finally show ?thesis .
qed

lemma less_1_prodinf:
  fixes f :: "nat \<Rightarrow> real"
  shows "\<lbrakk>convergent_prod f; \<And>n. 1 < f n\<rbrakk> \<Longrightarrow> 1 < prodinf f"
  by (intro less_1_prodinf2[where i=1]) (auto intro: less_imp_le)

lemma prodinf_nonzero:
  fixes f :: "nat \<Rightarrow> 'a :: {idom,topological_semigroup_mult,t2_space}"
  assumes "convergent_prod f" "\<And>i. f i \<noteq> 0"
  shows "prodinf f \<noteq> 0"
  by (metis assms convergent_prod_offset_0 has_prod_unique raw_has_prod_def has_prod_def)

lemma less_0_prodinf:
  fixes f :: "nat \<Rightarrow> real"
  assumes f: "convergent_prod f" and 0: "\<And>i. f i > 0"
  shows "0 < prodinf f"
proof -
  have "prodinf f \<noteq> 0"
    by (metis assms less_irrefl prodinf_nonzero)
  moreover have "0 < (\<Prod>n<i. f n)" for i
    by (simp add: 0 prod_pos)
  then have "prodinf f \<ge> 0"
    using convergent_prod_LIMSEQ [OF f] LIMSEQ_prod_nonneg 0 less_le by blast
  ultimately show ?thesis
    by auto
qed

lemma prod_less_prodinf2:
  fixes f :: "nat \<Rightarrow> real"
  assumes f: "convergent_prod f" and 1: "\<And>m. m\<ge>n \<Longrightarrow> 1 \<le> f m" and 0: "\<And>m. 0 < f m" and i: "n \<le> i" "1 < f i"
  shows "prod f {..<n} < prodinf f"
proof -
  have "prod f {..<n} \<le> prod f {..<i}"
    by (rule prod_mono2) (use assms less_le in auto)
  then have "prod f {..<n} < f i * prod f {..<i}"
    using mult_less_le_imp_less[of 1 "f i" "prod f {..<n}" "prod f {..<i}"] assms
    by (simp add: prod_pos)
  moreover have "prod f {..<Suc i} \<le> prodinf f"
    using prod_le_prodinf[of f _ "Suc i"]
    by (meson "0" "1" Suc_leD convergent_prod_has_prod f \<open>n \<le> i\<close> le_trans less_eq_real_def)
  ultimately show ?thesis
    by (metis le_less_trans mult.commute not_le prod_lessThan_Suc)
qed

lemma prod_less_prodinf:
  fixes f :: "nat \<Rightarrow> real"
  assumes f: "convergent_prod f" and 1: "\<And>m. m\<ge>n \<Longrightarrow> 1 < f m" and 0: "\<And>m. 0 < f m" 
  shows "prod f {..<n} < prodinf f"
  by (meson "0" "1" f le_less prod_less_prodinf2)

lemma raw_has_prodI_bounded:
  fixes f :: "nat \<Rightarrow> real"
  assumes pos: "\<And>n. 1 \<le> f n"
    and le: "\<And>n. (\<Prod>i<n. f i) \<le> x"
  shows "\<exists>p. raw_has_prod f 0 p"
  unfolding raw_has_prod_def add_0_right
proof (rule exI LIMSEQ_incseq_SUP conjI)+
  show "bdd_above (range (\<lambda>n. prod f {..n}))"
    by (metis bdd_aboveI2 le lessThan_Suc_atMost)
  then have "(SUP i. prod f {..i}) > 0"
    by (metis UNIV_I cSUP_upper less_le_trans pos prod_pos zero_less_one)
  then show "(SUP i. prod f {..i}) \<noteq> 0"
    by auto
  show "incseq (\<lambda>n. prod f {..n})"
    using pos order_trans [OF zero_le_one] by (auto simp: mono_def intro!: prod_mono2)
qed

lemma convergent_prodI_nonneg_bounded:
  fixes f :: "nat \<Rightarrow> real"
  assumes "\<And>n. 1 \<le> f n" "\<And>n. (\<Prod>i<n. f i) \<le> x"
  shows "convergent_prod f"
  using convergent_prod_def raw_has_prodI_bounded [OF assms] by blast


subsection \<open>Infinite products on topological spaces\<close>

context
  fixes f g :: "nat \<Rightarrow> 'a::{t2_space,topological_semigroup_mult,idom}"
begin

lemma raw_has_prod_mult: "\<lbrakk>raw_has_prod f M a; raw_has_prod g M b\<rbrakk> \<Longrightarrow> raw_has_prod (\<lambda>n. f n * g n) M (a * b)"
  by (force simp add: prod.distrib tendsto_mult raw_has_prod_def)

lemma has_prod_mult_nz: "\<lbrakk>f has_prod a; g has_prod b; a \<noteq> 0; b \<noteq> 0\<rbrakk> \<Longrightarrow> (\<lambda>n. f n * g n) has_prod (a * b)"
  by (simp add: raw_has_prod_mult has_prod_def)

end


context
  fixes f g :: "nat \<Rightarrow> 'a::real_normed_field"
begin

lemma has_prod_mult:
  assumes f: "f has_prod a" and g: "g has_prod b"
  shows "(\<lambda>n. f n * g n) has_prod (a * b)"
  using f [unfolded has_prod_def]
proof (elim disjE exE conjE)
  assume f0: "raw_has_prod f 0 a"
  show ?thesis
    using g [unfolded has_prod_def]
  proof (elim disjE exE conjE)
    assume g0: "raw_has_prod g 0 b"
    with f0 show ?thesis
      by (force simp add: has_prod_def prod.distrib tendsto_mult raw_has_prod_def)
  next
    fix j q
    assume "b = 0" and "g j = 0" and q: "raw_has_prod g (Suc j) q"
    obtain p where p: "raw_has_prod f (Suc j) p"
      using f0 raw_has_prod_ignore_initial_segment by blast
    then have "Ex (raw_has_prod (\<lambda>n. f n * g n) (Suc j))"
      using q raw_has_prod_mult by blast
    then show ?thesis
      using \<open>b = 0\<close> \<open>g j = 0\<close> has_prod_0_iff by fastforce
  qed
next
  fix i p
  assume "a = 0" and "f i = 0" and p: "raw_has_prod f (Suc i) p"
  show ?thesis
    using g [unfolded has_prod_def]
  proof (elim disjE exE conjE)
    assume g0: "raw_has_prod g 0 b"
    obtain q where q: "raw_has_prod g (Suc i) q"
      using g0 raw_has_prod_ignore_initial_segment by blast
    then have "Ex (raw_has_prod (\<lambda>n. f n * g n) (Suc i))"
      using raw_has_prod_mult p by blast
    then show ?thesis
      using \<open>a = 0\<close> \<open>f i = 0\<close> has_prod_0_iff by fastforce
  next
    fix j q
    assume "b = 0" and "g j = 0" and q: "raw_has_prod g (Suc j) q"
    obtain p' where p': "raw_has_prod f (Suc (max i j)) p'"
      by (metis raw_has_prod_ignore_initial_segment max_Suc_Suc max_def p)
    moreover
    obtain q' where q': "raw_has_prod g (Suc (max i j)) q'"
      by (metis raw_has_prod_ignore_initial_segment max.cobounded2 max_Suc_Suc q)
    ultimately show ?thesis
      using \<open>b = 0\<close> by (simp add: has_prod_def) (metis \<open>f i = 0\<close> \<open>g j = 0\<close> raw_has_prod_mult max_def)
  qed
qed

lemma convergent_prod_mult:
  assumes f: "convergent_prod f" and g: "convergent_prod g"
  shows "convergent_prod (\<lambda>n. f n * g n)"
  unfolding convergent_prod_def
proof -
  obtain M p N q where p: "raw_has_prod f M p" and q: "raw_has_prod g N q"
    using convergent_prod_def f g by blast+
  then obtain p' q' where p': "raw_has_prod f (max M N) p'" and q': "raw_has_prod g (max M N) q'"
    by (meson raw_has_prod_ignore_initial_segment max.cobounded1 max.cobounded2)
  then show "\<exists>M p. raw_has_prod (\<lambda>n. f n * g n) M p"
    using raw_has_prod_mult by blast
qed

lemma prodinf_mult: "convergent_prod f \<Longrightarrow> convergent_prod g \<Longrightarrow> prodinf f * prodinf g = (\<Prod>n. f n * g n)"
  by (intro has_prod_unique has_prod_mult convergent_prod_has_prod)

end

context
  fixes f :: "'i \<Rightarrow> nat \<Rightarrow> 'a::real_normed_field"
    and I :: "'i set"
begin

lemma has_prod_prod: "(\<And>i. i \<in> I \<Longrightarrow> (f i) has_prod (x i)) \<Longrightarrow> (\<lambda>n. \<Prod>i\<in>I. f i n) has_prod (\<Prod>i\<in>I. x i)"
  by (induct I rule: infinite_finite_induct) (auto intro!: has_prod_mult)

lemma prodinf_prod: "(\<And>i. i \<in> I \<Longrightarrow> convergent_prod (f i)) \<Longrightarrow> (\<Prod>n. \<Prod>i\<in>I. f i n) = (\<Prod>i\<in>I. \<Prod>n. f i n)"
  using has_prod_unique[OF has_prod_prod, OF convergent_prod_has_prod] by simp

lemma convergent_prod_prod: "(\<And>i. i \<in> I \<Longrightarrow> convergent_prod (f i)) \<Longrightarrow> convergent_prod (\<lambda>n. \<Prod>i\<in>I. f i n)"
  using convergent_prod_has_prod_iff has_prod_prod prodinf_prod by force

end

subsection \<open>Infinite summability on real normed fields\<close>

context
  fixes f :: "nat \<Rightarrow> 'a::real_normed_field"
begin

lemma raw_has_prod_Suc_iff: "raw_has_prod f M (a * f M) \<longleftrightarrow> raw_has_prod (\<lambda>n. f (Suc n)) M a \<and> f M \<noteq> 0"
proof -
  have "raw_has_prod f M (a * f M) \<longleftrightarrow> (\<lambda>i. \<Prod>j\<le>Suc i. f (j+M)) \<longlonglongrightarrow> a * f M \<and> a * f M \<noteq> 0"
    by (subst LIMSEQ_Suc_iff) (simp add: raw_has_prod_def)
  also have "\<dots> \<longleftrightarrow> (\<lambda>i. (\<Prod>j\<le>i. f (Suc j + M)) * f M) \<longlonglongrightarrow> a * f M \<and> a * f M \<noteq> 0"
    by (simp add: ac_simps atMost_Suc_eq_insert_0 image_Suc_atMost prod_atLeast1_atMost_eq lessThan_Suc_atMost)
  also have "\<dots> \<longleftrightarrow> raw_has_prod (\<lambda>n. f (Suc n)) M a \<and> f M \<noteq> 0"
  proof safe
    assume tends: "(\<lambda>i. (\<Prod>j\<le>i. f (Suc j + M)) * f M) \<longlonglongrightarrow> a * f M" and 0: "a * f M \<noteq> 0"
    with tendsto_divide[OF tends tendsto_const, of "f M"]    
    show "raw_has_prod (\<lambda>n. f (Suc n)) M a"
      by (simp add: raw_has_prod_def)
  qed (auto intro: tendsto_mult_right simp:  raw_has_prod_def)
  finally show ?thesis .
qed

lemma has_prod_Suc_iff:
  assumes "f 0 \<noteq> 0" shows "(\<lambda>n. f (Suc n)) has_prod a \<longleftrightarrow> f has_prod (a * f 0)"
proof (cases "a = 0")
  case True
  then show ?thesis
  proof (simp add: has_prod_def, safe)
    fix i x
    assume "f (Suc i) = 0" and "raw_has_prod (\<lambda>n. f (Suc n)) (Suc i) x"
    then obtain y where "raw_has_prod f (Suc (Suc i)) y"
      by (metis (no_types) raw_has_prod_eq_0 Suc_n_not_le_n raw_has_prod_Suc_iff raw_has_prod_ignore_initial_segment raw_has_prod_nonzero linear)
    then show "\<exists>i. f i = 0 \<and> Ex (raw_has_prod f (Suc i))"
      using \<open>f (Suc i) = 0\<close> by blast
  next
    fix i x
    assume "f i = 0" and x: "raw_has_prod f (Suc i) x"
    then obtain j where j: "i = Suc j"
      by (metis assms not0_implies_Suc)
    moreover have "\<exists> y. raw_has_prod (\<lambda>n. f (Suc n)) i y"
      using x by (auto simp: raw_has_prod_def)
    then show "\<exists>i. f (Suc i) = 0 \<and> Ex (raw_has_prod (\<lambda>n. f (Suc n)) (Suc i))"
      using \<open>f i = 0\<close> j by blast
  qed
next
  case False
  then show ?thesis
    by (auto simp: has_prod_def raw_has_prod_Suc_iff assms)
qed

lemma convergent_prod_Suc_iff:
  shows "convergent_prod (\<lambda>n. f (Suc n)) = convergent_prod f"
proof
  assume "convergent_prod f"
  then obtain M L where M_nz:"\<forall>n\<ge>M. f n \<noteq> 0" and 
        M_L:"(\<lambda>n. \<Prod>i\<le>n. f (i + M)) \<longlonglongrightarrow> L" and "L \<noteq> 0" 
    unfolding convergent_prod_altdef by auto
  have "(\<lambda>n. \<Prod>i\<le>n. f (Suc (i + M))) \<longlonglongrightarrow> L / f M"
  proof -
    have "(\<lambda>n. \<Prod>i\<in>{0..Suc n}. f (i + M)) \<longlonglongrightarrow> L"
      using M_L 
      apply (subst (asm) LIMSEQ_Suc_iff[symmetric]) 
      using atLeast0AtMost by auto
    then have "(\<lambda>n. f M * (\<Prod>i\<in>{0..n}. f (Suc (i + M)))) \<longlonglongrightarrow> L"
      apply (subst (asm) prod.atLeast0_atMost_Suc_shift)
      by simp
    then have "(\<lambda>n. (\<Prod>i\<in>{0..n}. f (Suc (i + M)))) \<longlonglongrightarrow> L/f M"
      apply (drule_tac tendsto_divide)
      using M_nz[rule_format,of M,simplified] by auto
    then show ?thesis unfolding atLeast0AtMost .
  qed
  then show "convergent_prod (\<lambda>n. f (Suc n))" unfolding convergent_prod_altdef
    apply (rule_tac exI[where x=M])
    apply (rule_tac exI[where x="L/f M"])
    using M_nz \<open>L\<noteq>0\<close> by auto
next
  assume "convergent_prod (\<lambda>n. f (Suc n))"
  then obtain M where "\<exists>L. (\<forall>n\<ge>M. f (Suc n) \<noteq> 0) \<and> (\<lambda>n. \<Prod>i\<le>n. f (Suc (i + M))) \<longlonglongrightarrow> L \<and> L \<noteq> 0"
    unfolding convergent_prod_altdef by auto
  then show "convergent_prod f" unfolding convergent_prod_altdef
    apply (rule_tac exI[where x="Suc M"])
    using Suc_le_D by auto
qed

lemma raw_has_prod_inverse: 
  assumes "raw_has_prod f M a" shows "raw_has_prod (\<lambda>n. inverse (f n)) M (inverse a)"
  using assms unfolding raw_has_prod_def by (auto dest: tendsto_inverse simp: prod_inversef [symmetric])

lemma has_prod_inverse: 
  assumes "f has_prod a" shows "(\<lambda>n. inverse (f n)) has_prod (inverse a)"
using assms raw_has_prod_inverse unfolding has_prod_def by auto 

lemma convergent_prod_inverse:
  assumes "convergent_prod f" 
  shows "convergent_prod (\<lambda>n. inverse (f n))"
  using assms unfolding convergent_prod_def  by (blast intro: raw_has_prod_inverse elim: )

end

context 
  fixes f :: "nat \<Rightarrow> 'a::real_normed_field"
begin

lemma raw_has_prod_Suc_iff': "raw_has_prod f M a \<longleftrightarrow> raw_has_prod (\<lambda>n. f (Suc n)) M (a / f M) \<and> f M \<noteq> 0"
  by (metis raw_has_prod_eq_0 add.commute add.left_neutral raw_has_prod_Suc_iff raw_has_prod_nonzero le_add1 nonzero_mult_div_cancel_right times_divide_eq_left)

lemma has_prod_divide: "f has_prod a \<Longrightarrow> g has_prod b \<Longrightarrow> (\<lambda>n. f n / g n) has_prod (a / b)"
  unfolding divide_inverse by (intro has_prod_inverse has_prod_mult)

lemma convergent_prod_divide:
  assumes f: "convergent_prod f" and g: "convergent_prod g"
  shows "convergent_prod (\<lambda>n. f n / g n)"
  using f g has_prod_divide has_prod_iff by blast

lemma prodinf_divide: "convergent_prod f \<Longrightarrow> convergent_prod g \<Longrightarrow> prodinf f / prodinf g = (\<Prod>n. f n / g n)"
  by (intro has_prod_unique has_prod_divide convergent_prod_has_prod)

lemma prodinf_inverse: "convergent_prod f \<Longrightarrow> (\<Prod>n. inverse (f n)) = inverse (\<Prod>n. f n)"
  by (intro has_prod_unique [symmetric] has_prod_inverse convergent_prod_has_prod)

lemma has_prod_Suc_imp: 
  assumes "(\<lambda>n. f (Suc n)) has_prod a"
  shows "f has_prod (a * f 0)"
proof -
  have "f has_prod (a * f 0)" when "raw_has_prod (\<lambda>n. f (Suc n)) 0 a" 
    apply (cases "f 0=0")
    using that unfolding has_prod_def raw_has_prod_Suc 
    by (auto simp add: raw_has_prod_Suc_iff)
  moreover have "f has_prod (a * f 0)" when 
    "(\<exists>i q. a = 0 \<and> f (Suc i) = 0 \<and> raw_has_prod (\<lambda>n. f (Suc n)) (Suc i) q)" 
  proof -
    from that 
    obtain i q where "a = 0" "f (Suc i) = 0" "raw_has_prod (\<lambda>n. f (Suc n)) (Suc i) q"
      by auto
    then show ?thesis unfolding has_prod_def 
      by (auto intro!:exI[where x="Suc i"] simp:raw_has_prod_Suc)
  qed
  ultimately show "f has_prod (a * f 0)" using assms unfolding has_prod_def by auto
qed

lemma has_prod_iff_shift: 
  assumes "\<And>i. i < n \<Longrightarrow> f i \<noteq> 0"
  shows "(\<lambda>i. f (i + n)) has_prod a \<longleftrightarrow> f has_prod (a * (\<Prod>i<n. f i))"
  using assms
proof (induct n arbitrary: a)
  case 0
  then show ?case by simp
next
  case (Suc n)
  then have "(\<lambda>i. f (Suc i + n)) has_prod a \<longleftrightarrow> (\<lambda>i. f (i + n)) has_prod (a * f n)"
    by (subst has_prod_Suc_iff) auto
  with Suc show ?case
    by (simp add: ac_simps)
qed

corollary has_prod_iff_shift':
  assumes "\<And>i. i < n \<Longrightarrow> f i \<noteq> 0"
  shows "(\<lambda>i. f (i + n)) has_prod (a / (\<Prod>i<n. f i)) \<longleftrightarrow> f has_prod a"
  by (simp add: assms has_prod_iff_shift)

lemma has_prod_one_iff_shift:
  assumes "\<And>i. i < n \<Longrightarrow> f i = 1"
  shows "(\<lambda>i. f (i+n)) has_prod a \<longleftrightarrow> (\<lambda>i. f i) has_prod a"
  by (simp add: assms has_prod_iff_shift)

lemma convergent_prod_iff_shift:
  shows "convergent_prod (\<lambda>i. f (i + n)) \<longleftrightarrow> convergent_prod f"
  apply safe
  using convergent_prod_offset apply blast
  using convergent_prod_ignore_initial_segment convergent_prod_def by blast

lemma has_prod_split_initial_segment:
  assumes "f has_prod a" "\<And>i. i < n \<Longrightarrow> f i \<noteq> 0"
  shows "(\<lambda>i. f (i + n)) has_prod (a / (\<Prod>i<n. f i))"
  using assms has_prod_iff_shift' by blast

lemma prodinf_divide_initial_segment:
  assumes "convergent_prod f" "\<And>i. i < n \<Longrightarrow> f i \<noteq> 0"
  shows "(\<Prod>i. f (i + n)) = (\<Prod>i. f i) / (\<Prod>i<n. f i)"
  by (rule has_prod_unique[symmetric]) (auto simp: assms has_prod_iff_shift)

lemma prodinf_split_initial_segment:
  assumes "convergent_prod f" "\<And>i. i < n \<Longrightarrow> f i \<noteq> 0"
  shows "prodinf f = (\<Prod>i. f (i + n)) * (\<Prod>i<n. f i)"
  by (auto simp add: assms prodinf_divide_initial_segment)

lemma prodinf_split_head:
  assumes "convergent_prod f" "f 0 \<noteq> 0"
  shows "(\<Prod>n. f (Suc n)) = prodinf f / f 0"
  using prodinf_split_initial_segment[of 1] assms by simp

end

context 
  fixes f :: "nat \<Rightarrow> 'a::real_normed_field"
begin

lemma convergent_prod_inverse_iff: "convergent_prod (\<lambda>n. inverse (f n)) \<longleftrightarrow> convergent_prod f"
  by (auto dest: convergent_prod_inverse)

lemma convergent_prod_const_iff:
  fixes c :: "'a :: {real_normed_field}"
  shows "convergent_prod (\<lambda>_. c) \<longleftrightarrow> c = 1"
proof
  assume "convergent_prod (\<lambda>_. c)"
  then show "c = 1"
    using convergent_prod_imp_LIMSEQ LIMSEQ_unique by blast 
next
  assume "c = 1"
  then show "convergent_prod (\<lambda>_. c)"
    by auto
qed

lemma has_prod_power: "f has_prod a \<Longrightarrow> (\<lambda>i. f i ^ n) has_prod (a ^ n)"
  by (induction n) (auto simp: has_prod_mult)

lemma convergent_prod_power: "convergent_prod f \<Longrightarrow> convergent_prod (\<lambda>i. f i ^ n)"
  by (induction n) (auto simp: convergent_prod_mult)

lemma prodinf_power: "convergent_prod f \<Longrightarrow> prodinf (\<lambda>i. f i ^ n) = prodinf f ^ n"
  by (metis has_prod_unique convergent_prod_imp_has_prod has_prod_power)

end


subsection\<open>Exponentials and logarithms\<close>

context 
  fixes f :: "nat \<Rightarrow> 'a::{real_normed_field,banach}"
begin

lemma sums_imp_has_prod_exp: 
  assumes "f sums s"
  shows "raw_has_prod (\<lambda>i. exp (f i)) 0 (exp s)"
  using assms continuous_on_exp [of UNIV "\<lambda>x::'a. x"]
  using continuous_on_tendsto_compose [of UNIV exp "(\<lambda>n. sum f {..n})" s]
  by (simp add: prod_defs sums_def_le exp_sum)

lemma convergent_prod_exp: 
  assumes "summable f"
  shows "convergent_prod (\<lambda>i. exp (f i))"
  using sums_imp_has_prod_exp assms unfolding summable_def convergent_prod_def  by blast

lemma prodinf_exp: 
  assumes "summable f"
  shows "prodinf (\<lambda>i. exp (f i)) = exp (suminf f)"
proof -
  have "f sums suminf f"
    using assms by blast
  then have "(\<lambda>i. exp (f i)) has_prod exp (suminf f)"
    by (simp add: has_prod_def sums_imp_has_prod_exp)
  then show ?thesis
    by (rule has_prod_unique [symmetric])
qed

end

lemma exp_suminf_prodinf_real:
  fixes f :: "nat \<Rightarrow> real"
  assumes ge0:"\<And>n. f n \<ge> 0" and ac: "abs_convergent_prod (\<lambda>n. exp (f n))"
  shows "prodinf (\<lambda>i. exp (f i)) = exp (suminf f)"
proof -
  have "summable f" 
    using ac unfolding abs_convergent_prod_conv_summable
  proof (elim summable_comparison_test')
    fix n
    show "norm (f n) \<le> norm (exp (f n) - 1)" 
      using ge0[of n] 
      by (metis abs_of_nonneg add.commute diff_add_cancel diff_ge_0_iff_ge exp_ge_add_one_self 
          exp_le_cancel_iff one_le_exp_iff real_norm_def)
  qed
  then show ?thesis
    by (simp add: prodinf_exp)
qed

lemma has_prod_imp_sums_ln_real: 
  fixes f :: "nat \<Rightarrow> real"
  assumes "raw_has_prod f 0 p" and 0: "\<And>x. f x > 0"
  shows "(\<lambda>i. ln (f i)) sums (ln p)"
proof -
  have "p > 0"
    using assms unfolding prod_defs by (metis LIMSEQ_prod_nonneg less_eq_real_def)
  then show ?thesis
  using assms continuous_on_ln [of "{0<..}" "\<lambda>x. x"]
  using continuous_on_tendsto_compose [of "{0<..}" ln "(\<lambda>n. prod f {..n})" p]
  by (auto simp: prod_defs sums_def_le ln_prod order_tendstoD)
qed

lemma summable_ln_real: 
  fixes f :: "nat \<Rightarrow> real"
  assumes f: "convergent_prod f" and 0: "\<And>x. f x > 0"
  shows "summable (\<lambda>i. ln (f i))"
proof -
  obtain M p where "raw_has_prod f M p"
    using f convergent_prod_def by blast
  then consider i where "i<M" "f i = 0" | p where "raw_has_prod f 0 p"
    using raw_has_prod_cases by blast
  then show ?thesis
  proof cases
    case 1
    with 0 show ?thesis
      by (metis less_irrefl)
  next
    case 2
    then show ?thesis
      using "0" has_prod_imp_sums_ln_real summable_def by blast
  qed
qed

lemma suminf_ln_real: 
  fixes f :: "nat \<Rightarrow> real"
  assumes f: "convergent_prod f" and 0: "\<And>x. f x > 0"
  shows "suminf (\<lambda>i. ln (f i)) = ln (prodinf f)"
proof -
  have "f has_prod prodinf f"
    by (simp add: f has_prod_iff)
  then have "raw_has_prod f 0 (prodinf f)"
    by (metis "0" has_prod_def less_irrefl)
  then have "(\<lambda>i. ln (f i)) sums ln (prodinf f)"
    using "0" has_prod_imp_sums_ln_real by blast
  then show ?thesis
    by (rule sums_unique [symmetric])
qed

lemma prodinf_exp_real: 
  fixes f :: "nat \<Rightarrow> real"
  assumes f: "convergent_prod f" and 0: "\<And>x. f x > 0"
  shows "prodinf f = exp (suminf (\<lambda>i. ln (f i)))"
  by (simp add: "0" f less_0_prodinf suminf_ln_real)


subsection\<open>Embeddings from the reals into some complete real normed field\<close>

lemma tendsto_eq_of_real_lim:
  assumes "(\<lambda>n. of_real (f n) :: 'a::{complete_space,real_normed_field}) \<longlonglongrightarrow> q"
  shows "q = of_real (lim f)"
proof -
  have "convergent (\<lambda>n. of_real (f n) :: 'a)"
    using assms convergent_def by blast 
  then have "convergent f"
    unfolding convergent_def
    by (simp add: convergent_eq_Cauchy Cauchy_def)
  then show ?thesis
    by (metis LIMSEQ_unique assms convergentD sequentially_bot tendsto_Lim tendsto_of_real)
qed

lemma tendsto_eq_of_real:
  assumes "(\<lambda>n. of_real (f n) :: 'a::{complete_space,real_normed_field}) \<longlonglongrightarrow> q"
  obtains r where "q = of_real r"
  using tendsto_eq_of_real_lim assms by blast

lemma has_prod_of_real_iff:
  "(\<lambda>n. of_real (f n) :: 'a::{complete_space,real_normed_field}) has_prod of_real c \<longleftrightarrow> f has_prod c"
  (is "?lhs = ?rhs")
proof
  assume ?lhs
  then show ?rhs
    apply (auto simp: prod_defs LIMSEQ_prod_0 tendsto_of_real_iff simp flip: of_real_prod)
    using tendsto_eq_of_real
    by (metis of_real_0 tendsto_of_real_iff)
next
  assume ?rhs
  with tendsto_of_real_iff show ?lhs
    by (fastforce simp: prod_defs simp flip: of_real_prod)
qed

end

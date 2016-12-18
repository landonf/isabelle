(*  Title:      HOL/Nonstandard_Analysis/HSeries.thy
    Author:     Jacques D. Fleuriot
    Copyright:  1998  University of Cambridge

Converted to Isar and polished by lcp
*)

section \<open>Finite Summation and Infinite Series for Hyperreals\<close>

theory HSeries
  imports HSEQ
begin

definition sumhr :: "hypnat \<times> hypnat \<times> (nat \<Rightarrow> real) \<Rightarrow> hypreal"
  where "sumhr = (\<lambda>(M,N,f). starfun2 (\<lambda>m n. sum f {m..<n}) M N)"

definition NSsums :: "(nat \<Rightarrow> real) \<Rightarrow> real \<Rightarrow> bool"  (infixr "NSsums" 80)
  where "f NSsums s = (\<lambda>n. sum f {..<n}) \<longlonglongrightarrow>\<^sub>N\<^sub>S s"

definition NSsummable :: "(nat \<Rightarrow> real) \<Rightarrow> bool"
  where "NSsummable f \<longleftrightarrow> (\<exists>s. f NSsums s)"

definition NSsuminf :: "(nat \<Rightarrow> real) \<Rightarrow> real"
  where "NSsuminf f = (THE s. f NSsums s)"

lemma sumhr_app: "sumhr (M, N, f) = ( *f2* (\<lambda>m n. sum f {m..<n})) M N"
  by (simp add: sumhr_def)

text \<open>Base case in definition of @{term sumr}.\<close>
lemma sumhr_zero [simp]: "\<And>m. sumhr (m, 0, f) = 0"
  unfolding sumhr_app by transfer simp

text \<open>Recursive case in definition of @{term sumr}.\<close>
lemma sumhr_if:
  "\<And>m n. sumhr (m, n + 1, f) = (if n + 1 \<le> m then 0 else sumhr (m, n, f) + ( *f* f) n)"
  unfolding sumhr_app by transfer simp

lemma sumhr_Suc_zero [simp]: "\<And>n. sumhr (n + 1, n, f) = 0"
  unfolding sumhr_app by transfer simp

lemma sumhr_eq_bounds [simp]: "\<And>n. sumhr (n, n, f) = 0"
  unfolding sumhr_app by transfer simp

lemma sumhr_Suc [simp]: "\<And>m. sumhr (m, m + 1, f) = ( *f* f) m"
  unfolding sumhr_app by transfer simp

lemma sumhr_add_lbound_zero [simp]: "\<And>k m. sumhr (m + k, k, f) = 0"
  unfolding sumhr_app by transfer simp

lemma sumhr_add: "\<And>m n. sumhr (m, n, f) + sumhr (m, n, g) = sumhr (m, n, \<lambda>i. f i + g i)"
  unfolding sumhr_app by transfer (rule sum.distrib [symmetric])

lemma sumhr_mult: "\<And>m n. hypreal_of_real r * sumhr (m, n, f) = sumhr (m, n, \<lambda>n. r * f n)"
  unfolding sumhr_app by transfer (rule sum_distrib_left)

lemma sumhr_split_add: "\<And>n p. n < p \<Longrightarrow> sumhr (0, n, f) + sumhr (n, p, f) = sumhr (0, p, f)"
  unfolding sumhr_app by transfer (simp add: sum_add_nat_ivl)

lemma sumhr_split_diff: "n < p \<Longrightarrow> sumhr (0, p, f) - sumhr (0, n, f) = sumhr (n, p, f)"
  by (drule sumhr_split_add [symmetric, where f = f]) simp

lemma sumhr_hrabs: "\<And>m n. \<bar>sumhr (m, n, f)\<bar> \<le> sumhr (m, n, \<lambda>i. \<bar>f i\<bar>)"
  unfolding sumhr_app by transfer (rule sum_abs)

text \<open>Other general version also needed.\<close>
lemma sumhr_fun_hypnat_eq:
  "(\<forall>r. m \<le> r \<and> r < n \<longrightarrow> f r = g r) \<longrightarrow>
    sumhr (hypnat_of_nat m, hypnat_of_nat n, f) =
    sumhr (hypnat_of_nat m, hypnat_of_nat n, g)"
  unfolding sumhr_app by transfer simp

lemma sumhr_const: "\<And>n. sumhr (0, n, \<lambda>i. r) = hypreal_of_hypnat n * hypreal_of_real r"
  unfolding sumhr_app by transfer simp

lemma sumhr_less_bounds_zero [simp]: "\<And>m n. n < m \<Longrightarrow> sumhr (m, n, f) = 0"
  unfolding sumhr_app by transfer simp

lemma sumhr_minus: "\<And>m n. sumhr (m, n, \<lambda>i. - f i) = - sumhr (m, n, f)"
  unfolding sumhr_app by transfer (rule sum_negf)

lemma sumhr_shift_bounds:
  "\<And>m n. sumhr (m + hypnat_of_nat k, n + hypnat_of_nat k, f) =
    sumhr (m, n, \<lambda>i. f (i + k))"
  unfolding sumhr_app by transfer (rule sum_shift_bounds_nat_ivl)


subsection \<open>Nonstandard Sums\<close>

text \<open>Infinite sums are obtained by summing to some infinite hypernatural
  (such as @{term whn}).\<close>
lemma sumhr_hypreal_of_hypnat_omega: "sumhr (0, whn, \<lambda>i. 1) = hypreal_of_hypnat whn"
  by (simp add: sumhr_const)

lemma sumhr_hypreal_omega_minus_one: "sumhr(0, whn, \<lambda>i. 1) = \<omega> - 1"
  apply (simp add: sumhr_const)
    (* FIXME: need lemma: hypreal_of_hypnat whn = \<omega> - 1 *)
    (* maybe define \<omega> = hypreal_of_hypnat whn + 1 *)
  apply (unfold star_class_defs omega_def hypnat_omega_def of_hypnat_def star_of_def)
  apply (simp add: starfun_star_n starfun2_star_n)
  done

lemma sumhr_minus_one_realpow_zero [simp]: "\<And>N. sumhr (0, N + N, \<lambda>i. (-1) ^ (i + 1)) = 0"
  unfolding sumhr_app
  apply transfer
  apply (simp del: power_Suc add: mult_2 [symmetric])
  apply (induct_tac N)
   apply simp_all
  done

lemma sumhr_interval_const:
  "(\<forall>n. m \<le> Suc n \<longrightarrow> f n = r) \<and> m \<le> na \<Longrightarrow>
    sumhr (hypnat_of_nat m, hypnat_of_nat na, f) = hypreal_of_nat (na - m) * hypreal_of_real r"
  unfolding sumhr_app by transfer simp

lemma starfunNat_sumr: "\<And>N. ( *f* (\<lambda>n. sum f {0..<n})) N = sumhr (0, N, f)"
  unfolding sumhr_app by transfer (rule refl)

lemma sumhr_hrabs_approx [simp]: "sumhr (0, M, f) \<approx> sumhr (0, N, f) \<Longrightarrow> \<bar>sumhr (M, N, f)\<bar> \<approx> 0"
  using linorder_less_linear [where x = M and y = N]
  apply auto
  apply (drule approx_sym [THEN approx_minus_iff [THEN iffD1]])
  apply (auto dest: approx_hrabs simp add: sumhr_split_diff)
  done


subsection \<open>Infinite sums: Standard and NS theorems\<close>

lemma sums_NSsums_iff: "f sums l \<longleftrightarrow> f NSsums l"
  by (simp add: sums_def NSsums_def LIMSEQ_NSLIMSEQ_iff)

lemma summable_NSsummable_iff: "summable f \<longleftrightarrow> NSsummable f"
  by (simp add: summable_def NSsummable_def sums_NSsums_iff)

lemma suminf_NSsuminf_iff: "suminf f = NSsuminf f"
  by (simp add: suminf_def NSsuminf_def sums_NSsums_iff)

lemma NSsums_NSsummable: "f NSsums l \<Longrightarrow> NSsummable f"
  unfolding NSsums_def NSsummable_def by blast

lemma NSsummable_NSsums: "NSsummable f \<Longrightarrow> f NSsums (NSsuminf f)"
  unfolding NSsummable_def NSsuminf_def NSsums_def
  by (blast intro: theI NSLIMSEQ_unique)

lemma NSsums_unique: "f NSsums s \<Longrightarrow> s = NSsuminf f"
  by (simp add: suminf_NSsuminf_iff [symmetric] sums_NSsums_iff sums_unique)

lemma NSseries_zero: "\<forall>m. n \<le> Suc m \<longrightarrow> f m = 0 \<Longrightarrow> f NSsums (sum f {..<n})"
  by (auto simp add: sums_NSsums_iff [symmetric] not_le[symmetric] intro!: sums_finite)

lemma NSsummable_NSCauchy:
  "NSsummable f \<longleftrightarrow> (\<forall>M \<in> HNatInfinite. \<forall>N \<in> HNatInfinite. \<bar>sumhr (M, N, f)\<bar> \<approx> 0)"
  apply (auto simp add: summable_NSsummable_iff [symmetric]
      summable_iff_convergent convergent_NSconvergent_iff atLeast0LessThan[symmetric]
      NSCauchy_NSconvergent_iff [symmetric] NSCauchy_def starfunNat_sumr)
  apply (cut_tac x = M and y = N in linorder_less_linear)
  apply auto
   apply (rule approx_minus_iff [THEN iffD2, THEN approx_sym])
   apply (rule_tac [2] approx_minus_iff [THEN iffD2])
   apply (auto dest: approx_hrabs_zero_cancel simp: sumhr_split_diff atLeast0LessThan[symmetric])
  done

text \<open>Terms of a convergent series tend to zero.\<close>
lemma NSsummable_NSLIMSEQ_zero: "NSsummable f \<Longrightarrow> f \<longlonglongrightarrow>\<^sub>N\<^sub>S 0"
  apply (auto simp add: NSLIMSEQ_def NSsummable_NSCauchy)
  apply (drule bspec)
   apply auto
  apply (drule_tac x = "N + 1 " in bspec)
   apply (auto intro: HNatInfinite_add_one approx_hrabs_zero_cancel)
  done

text \<open>Nonstandard comparison test.\<close>
lemma NSsummable_comparison_test: "\<exists>N. \<forall>n. N \<le> n \<longrightarrow> \<bar>f n\<bar> \<le> g n \<Longrightarrow> NSsummable g \<Longrightarrow> NSsummable f"
  apply (fold summable_NSsummable_iff)
  apply (rule summable_comparison_test, simp, assumption)
  done

lemma NSsummable_rabs_comparison_test:
  "\<exists>N. \<forall>n. N \<le> n \<longrightarrow> \<bar>f n\<bar> \<le> g n \<Longrightarrow> NSsummable g \<Longrightarrow> NSsummable (\<lambda>k. \<bar>f k\<bar>)"
  by (rule NSsummable_comparison_test) auto

end

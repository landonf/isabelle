(*  Title:      HOL/ex/Sum_of_Powers.thy
    Author:     Lukas Bulwahn <lukas.bulwahn-at-gmail.com>
*)

section {* Sum of Powers *}

theory Sum_of_Powers
imports Complex_Main
begin

subsection {* Additions to @{theory Binomial} Theory *}

lemma of_nat_binomial_eq_mult_binomial_Suc:
  assumes "k \<le> n"
  shows "(of_nat :: (nat \<Rightarrow> ('a :: field_char_0))) (n choose k) = of_nat (n + 1 - k) / of_nat (n + 1) * of_nat (Suc n choose k)"
proof -
  have "of_nat (n + 1) * (\<Prod>i<k. of_nat (n - i)) = (of_nat :: (nat \<Rightarrow> 'a)) (n + 1 - k) * (\<Prod>i<k. of_nat (Suc n - i))"
  proof -
    have "of_nat (n + 1) * (\<Prod>i<k. of_nat (n - i)) = (of_nat :: (nat \<Rightarrow> 'a)) (n + 1) * (\<Prod>i\<in>Suc ` {..<k}. of_nat (Suc n - i))"
      by (auto simp add: setprod.reindex)
    also have "... = (\<Prod>i\<le>k. of_nat (Suc n - i))"
    proof (cases k)
      case (Suc k')
      have "of_nat (n + 1) * (\<Prod>i\<in>Suc ` {..<Suc k'}. of_nat (Suc n - i)) = (\<Prod>i\<in>insert 0 (Suc ` {..k'}). of_nat (Suc n - i))"
        by (subst setprod.insert) (auto simp add: lessThan_Suc_atMost)
      also have "... = (\<Prod>i\<le>Suc k'. of_nat (Suc n - i))" by (simp only: Iic_Suc_eq_insert_0)
      finally show ?thesis using Suc by simp
    qed (simp)
    also have "... = (of_nat :: (nat \<Rightarrow> 'a)) (Suc n - k) * (\<Prod>i<k. of_nat (Suc n - i))"
      by (cases k) (auto simp add: atMost_Suc lessThan_Suc_atMost)
    also have "... = (of_nat :: (nat \<Rightarrow> 'a)) (n + 1 - k) * (\<Prod>i<k. of_nat (Suc n - i))"
      by (simp only: Suc_eq_plus1)
    finally show ?thesis .
  qed
  from this have "(\<Prod>i<k. of_nat (n - i)) = (of_nat :: (nat \<Rightarrow> 'a)) (n + 1 - k) / of_nat (n + 1) * (\<Prod>i<k. of_nat (Suc n - i))"
    by (metis le_add2 nonzero_mult_divide_cancel_left not_one_le_zero of_nat_eq_0_iff times_divide_eq_left)
  from assms this show ?thesis
    by (auto simp add: binomial_altdef_of_nat setprod_dividef)
qed

lemma real_binomial_eq_mult_binomial_Suc:
  assumes "k \<le> n"
  shows "(n choose k) = (n + 1 - k) / (n + 1) * (Suc n choose k)"
proof -
  have "real (n choose k) = of_nat (n choose k)" by auto
  also have "... = of_nat (n + 1 - k) / of_nat (n + 1) * of_nat (Suc n choose k)"
    by (simp add: assms of_nat_binomial_eq_mult_binomial_Suc)
  also have "... = (n + 1 - k) / (n + 1) * (Suc n choose k)"
    using real_of_nat_def by auto
  finally show ?thesis
    by (metis (no_types, lifting) assms le_add1 le_trans of_nat_diff real_of_nat_1 real_of_nat_add real_of_nat_def)
qed

subsection {* Preliminaries *}

lemma integrals_eq:
  assumes "f 0 = g 0"
  assumes "\<And> x. ((\<lambda>x. f x - g x) has_real_derivative 0) (at x)"
  shows "f x = g x"
proof -
  show "f x = g x"
  proof (cases "x \<noteq> 0")
    case True
    from assms DERIV_const_ratio_const[OF this, of "\<lambda>x. f x - g x" 0]
    show ?thesis by auto
  qed (simp add: assms)
qed

lemma setsum_diff: "((\<Sum>i\<le>n::nat. f (i + 1) - f i)::'a::field) = f (n + 1) - f 0"
by (induct n) (auto simp add: field_simps)

declare One_nat_def [simp del]

subsection {* Bernoulli Numbers and Bernoulli Polynomials  *}

declare setsum.cong [fundef_cong]

fun bernoulli :: "nat \<Rightarrow> real"
where
  "bernoulli 0 = (1::real)"
| "bernoulli (Suc n) =  (-1 / (n + 2)) * (\<Sum>k \<le> n. ((n + 2 choose k) * bernoulli k))"

declare bernoulli.simps[simp del]

definition
  "bernpoly n = (\<lambda>x. \<Sum>k \<le> n. (n choose k) * bernoulli k * x ^ (n - k))"

subsection {* Basic Observations on Bernoulli Polynomials *}

lemma bernpoly_0: "bernpoly n 0 = bernoulli n"
proof (cases n)
  case 0
  from this show "bernpoly n 0 = bernoulli n"
    unfolding bernpoly_def bernoulli.simps by auto
next
  case (Suc n')
  have "(\<Sum>k\<le>n'. real (Suc n' choose k) * bernoulli k * 0 ^ (Suc n' - k)) = 0"
    by (rule setsum.neutral) auto
  with Suc show ?thesis
    unfolding bernpoly_def by simp
qed

lemma setsum_binomial_times_bernoulli:
  "(\<Sum>k\<le>n. ((Suc n) choose k) * bernoulli k) = (if n = 0 then 1 else 0)"
proof (cases n)
  case 0
  from this show ?thesis by (simp add: bernoulli.simps)
next
  case Suc
  from this show ?thesis
  by (simp add: bernoulli.simps)
    (simp add: field_simps add_2_eq_Suc'[symmetric] del: add_2_eq_Suc add_2_eq_Suc')
qed

subsection {* Sum of Powers with Bernoulli Polynomials *}

lemma bernpoly_derivative [derivative_intros]:
  "(bernpoly (Suc n) has_real_derivative ((n + 1) * bernpoly n x)) (at x)"
proof -
  have "(bernpoly (Suc n) has_real_derivative (\<Sum>k\<le>n. real (Suc n - k) * x ^ (n - k) * (real (Suc n choose k) * bernoulli k))) (at x)"
    unfolding bernpoly_def by (rule DERIV_cong) (fast intro!: derivative_intros, simp)
  moreover have "(\<Sum>k\<le>n. real (Suc n - k) * x ^ (n - k) * (real (Suc n choose k) * bernoulli k)) = (n + 1) * bernpoly n x"
    unfolding bernpoly_def
    by (auto intro: setsum.cong simp add: setsum_right_distrib real_binomial_eq_mult_binomial_Suc[of _ n] Suc_eq_plus1 real_of_nat_diff)
  ultimately show ?thesis by auto
qed

lemma diff_bernpoly:
  "bernpoly n (x + 1) - bernpoly n x = n * x ^ (n - 1)"
proof (induct n arbitrary: x)
  case 0
  show ?case unfolding bernpoly_def by auto
next
  case (Suc n)
  have "bernpoly (Suc n) (0 + 1) - bernpoly (Suc n) 0 = (Suc n) * 0 ^ n"
    unfolding bernpoly_0 unfolding bernpoly_def by (simp add: setsum_binomial_times_bernoulli zero_power)
  from this have const: "bernpoly (Suc n) (0 + 1) - bernpoly (Suc n) 0 = real (Suc n) * 0 ^ n" by (simp add: power_0_left)
  have hyps': "\<And>x. (real n + 1) * bernpoly n (x + 1) - (real n + 1) * bernpoly n x = real n * x ^ (n - Suc 0) * real (Suc n)"
    unfolding right_diff_distrib[symmetric] by (simp add: Suc.hyps One_nat_def)
  note [derivative_intros] = DERIV_chain'[where f = "\<lambda>x::real. x + 1" and g = "bernpoly (Suc n)" and s="UNIV"]
  have derivative: "\<And>x. ((%x. bernpoly (Suc n) (x + 1) - bernpoly (Suc n) x - real (Suc n) * x ^ n) has_real_derivative 0) (at x)"
    by (rule DERIV_cong) (fast intro!: derivative_intros, simp add: hyps')
  from integrals_eq[OF const derivative] show ?case by simp
qed

lemma sum_of_powers: "(\<Sum>k\<le>n::nat. (real k) ^ m) = (bernpoly (Suc m) (n + 1) - bernpoly (Suc m) 0) / (m + 1)"
proof -
  from diff_bernpoly[of "Suc m", simplified] have "(m + (1::real)) * (\<Sum>k\<le>n. (real k) ^ m) = (\<Sum>k\<le>n. bernpoly (Suc m) (real k + 1) - bernpoly (Suc m) (real k))"
    by (auto simp add: setsum_right_distrib intro!: setsum.cong)
  also have "... = (\<Sum>k\<le>n. bernpoly (Suc m) (real (k + 1)) - bernpoly (Suc m) (real k))"
    by (simp only: real_of_nat_1[symmetric] real_of_nat_add[symmetric])
  also have "... = bernpoly (Suc m) (n + 1) - bernpoly (Suc m) 0"
    by (simp only: setsum_diff[where f="\<lambda>k. bernpoly (Suc m) (real k)"]) simp
  finally show ?thesis by (auto simp add: field_simps intro!: eq_divide_imp)
qed

subsection {* Instances for Square And Cubic Numbers *}

lemma binomial_unroll:
  "n > 0 \<Longrightarrow> (n choose k) = (if k = 0 then 1 else (n - 1) choose (k - 1) + ((n - 1) choose k))"
by (cases n) (auto simp add: binomial.simps(2))

lemma setsum_unroll:
  "(\<Sum>k\<le>n::nat. f k) = (if n = 0 then f 0 else f n + (\<Sum>k\<le>n - 1. f k))"
by auto (metis One_nat_def Suc_pred add.commute setsum_atMost_Suc)

lemma bernoulli_unroll:
  "n > 0 \<Longrightarrow> bernoulli n = - 1 / (real n + 1) * (\<Sum>k\<le>n - 1. real (n + 1 choose k) * bernoulli k)"
by (cases n) (simp add: bernoulli.simps One_nat_def)+

lemmas unroll = binomial.simps(1) binomial_unroll
  bernoulli.simps(1) bernoulli_unroll setsum_unroll bernpoly_def

lemma sum_of_squares: "(\<Sum>k\<le>n::nat. k ^ 2) = (2 * n ^ 3 + 3 * n ^ 2 + n) / 6"
proof -
  have "real (\<Sum>k\<le>n::nat. k ^ 2) = (\<Sum>k\<le>n::nat. (real k) ^ 2)" by simp
  also have "... = (bernpoly 3 (real (n + 1)) - bernpoly 3 0) / real (3 :: nat)"
    by (auto simp add: sum_of_powers)
  also have "... = (2 * n ^ 3 + 3 * n ^ 2 + n) / 6"
    by (simp add: unroll algebra_simps power2_eq_square power3_eq_cube One_nat_def[symmetric])
  finally show ?thesis by simp
qed

lemma sum_of_squares_nat: "(\<Sum>k\<le>n::nat. k ^ 2) = (2 * n ^ 3 + 3 * n ^ 2 + n) div 6"
proof -
  from sum_of_squares have "real (6 * (\<Sum>k\<le>n. k ^ 2)) = real (2 * n ^ 3 + 3 * n ^ 2 + n)"
    by (auto simp add: field_simps)
  from this have "6 * (\<Sum>k\<le>n. k ^ 2) = 2 * n ^ 3 + 3 * n ^ 2 + n"
    by (simp only: real_of_nat_inject[symmetric])
  from this show ?thesis by auto
qed

lemma sum_of_cubes: "(\<Sum>k\<le>n::nat. k ^ 3) = (n ^ 2 + n) ^ 2 / 4"
proof -
  have two_plus_two: "2 + 2 = 4" by simp
  have power4_eq: "\<And>x::real. x ^ 4 = x * x * x * x"
    by (simp only: two_plus_two[symmetric] power_add power2_eq_square)
  have "real (\<Sum>k\<le>n::nat. k ^ 3) = (\<Sum>k\<le>n::nat. (real k) ^ 3)" by simp
  also have "... = ((bernpoly 4 (n + 1) - bernpoly 4 0)) / (real (4 :: nat))"
    by (auto simp add: sum_of_powers)
  also have "... = ((n ^ 2 + n) / 2) ^ 2"
    by (simp add: unroll algebra_simps power2_eq_square power4_eq power3_eq_cube)
  finally show ?thesis by simp
qed

lemma sum_of_cubes_nat: "(\<Sum>k\<le>n::nat. k ^ 3) = (n ^ 2 + n) ^ 2 div 4"
proof -
  from sum_of_cubes have "real (4 * (\<Sum>k\<le>n. k ^ 3)) = real ((n ^ 2 + n) ^ 2)"
    by (auto simp add: field_simps)
  from this have "4 * (\<Sum>k\<le>n. k ^ 3) = (n ^ 2 + n) ^ 2"
    by (simp only: real_of_nat_inject[symmetric])
  from this show ?thesis by auto
qed

end

(*  Title       : Limits.thy
    Author      : Brian Huffman
*)

header {* Filters and Limits *}

theory Limits
imports RealVector RComplete
begin

subsection {* Nets *}

text {*
  A net is now defined as a filter base.
  The definition also allows non-proper filter bases.
*}

typedef (open) 'a net =
  "{net :: 'a set set. (\<exists>A. A \<in> net)
    \<and> (\<forall>A\<in>net. \<forall>B\<in>net. \<exists>C\<in>net. C \<subseteq> A \<and> C \<subseteq> B)}"
proof
  show "UNIV \<in> ?net" by auto
qed

lemma Rep_net_nonempty: "\<exists>A. A \<in> Rep_net net"
using Rep_net [of net] by simp

lemma Rep_net_directed:
  "A \<in> Rep_net net \<Longrightarrow> B \<in> Rep_net net \<Longrightarrow> \<exists>C\<in>Rep_net net. C \<subseteq> A \<and> C \<subseteq> B"
using Rep_net [of net] by simp

lemma Abs_net_inverse':
  assumes "\<exists>A. A \<in> net"
  assumes "\<And>A B. A \<in> net \<Longrightarrow> B \<in> net \<Longrightarrow> \<exists>C\<in>net. C \<subseteq> A \<and> C \<subseteq> B" 
  shows "Rep_net (Abs_net net) = net"
using assms by (simp add: Abs_net_inverse)

lemma image_nonempty: "\<exists>x. x \<in> A \<Longrightarrow> \<exists>x. x \<in> f ` A"
by auto


subsection {* Eventually *}

definition
  eventually :: "('a \<Rightarrow> bool) \<Rightarrow> 'a net \<Rightarrow> bool" where
  [code del]: "eventually P net \<longleftrightarrow> (\<exists>A\<in>Rep_net net. \<forall>x\<in>A. P x)"

lemma eventually_True [simp]: "eventually (\<lambda>x. True) net"
unfolding eventually_def using Rep_net_nonempty [of net] by fast

lemma eventually_mono:
  "(\<forall>x. P x \<longrightarrow> Q x) \<Longrightarrow> eventually P net \<Longrightarrow> eventually Q net"
unfolding eventually_def by blast

lemma eventually_conj:
  assumes P: "eventually (\<lambda>x. P x) net"
  assumes Q: "eventually (\<lambda>x. Q x) net"
  shows "eventually (\<lambda>x. P x \<and> Q x) net"
proof -
  obtain A where A: "A \<in> Rep_net net" "\<forall>x\<in>A. P x"
    using P unfolding eventually_def by fast
  obtain B where B: "B \<in> Rep_net net" "\<forall>x\<in>B. Q x"
    using Q unfolding eventually_def by fast
  obtain C where C: "C \<in> Rep_net net" "C \<subseteq> A" "C \<subseteq> B"
    using Rep_net_directed [OF A(1) B(1)] by fast
  then have "\<forall>x\<in>C. P x \<and> Q x" "C \<in> Rep_net net"
    using A(2) B(2) by auto
  then show ?thesis unfolding eventually_def ..
qed

lemma eventually_mp:
  assumes "eventually (\<lambda>x. P x \<longrightarrow> Q x) net"
  assumes "eventually (\<lambda>x. P x) net"
  shows "eventually (\<lambda>x. Q x) net"
proof (rule eventually_mono)
  show "\<forall>x. (P x \<longrightarrow> Q x) \<and> P x \<longrightarrow> Q x" by simp
  show "eventually (\<lambda>x. (P x \<longrightarrow> Q x) \<and> P x) net"
    using assms by (rule eventually_conj)
qed

lemma eventually_rev_mp:
  assumes "eventually (\<lambda>x. P x) net"
  assumes "eventually (\<lambda>x. P x \<longrightarrow> Q x) net"
  shows "eventually (\<lambda>x. Q x) net"
using assms(2) assms(1) by (rule eventually_mp)

lemma eventually_conj_iff:
  "eventually (\<lambda>x. P x \<and> Q x) net \<longleftrightarrow> eventually P net \<and> eventually Q net"
by (auto intro: eventually_conj elim: eventually_rev_mp)

lemma eventually_elim1:
  assumes "eventually (\<lambda>i. P i) net"
  assumes "\<And>i. P i \<Longrightarrow> Q i"
  shows "eventually (\<lambda>i. Q i) net"
using assms by (auto elim!: eventually_rev_mp)

lemma eventually_elim2:
  assumes "eventually (\<lambda>i. P i) net"
  assumes "eventually (\<lambda>i. Q i) net"
  assumes "\<And>i. P i \<Longrightarrow> Q i \<Longrightarrow> R i"
  shows "eventually (\<lambda>i. R i) net"
using assms by (auto elim!: eventually_rev_mp)


subsection {* Standard Nets *}

definition
  sequentially :: "nat net" where
  [code del]: "sequentially = Abs_net (range (\<lambda>n. {n..}))"

definition
  at :: "'a::metric_space \<Rightarrow> 'a net" where
  [code del]: "at a = Abs_net ((\<lambda>r. {x. x \<noteq> a \<and> dist x a < r}) ` {r. 0 < r})"

definition
  within :: "'a net \<Rightarrow> 'a set \<Rightarrow> 'a net" (infixr "within" 70) where
  [code del]: "net within S = Abs_net ((\<lambda>A. A \<inter> S) ` Rep_net net)"

lemma Rep_net_sequentially:
  "Rep_net sequentially = range (\<lambda>n. {n..})"
unfolding sequentially_def
apply (rule Abs_net_inverse')
apply (rule image_nonempty, simp)
apply (clarsimp, rename_tac m n)
apply (rule_tac x="max m n" in exI, auto)
done

lemma Rep_net_at:
  "Rep_net (at a) = ((\<lambda>r. {x. x \<noteq> a \<and> dist x a < r}) ` {r. 0 < r})"
unfolding at_def
apply (rule Abs_net_inverse')
apply (rule image_nonempty, rule_tac x=1 in exI, simp)
apply (clarsimp, rename_tac r s)
apply (rule_tac x="min r s" in exI, auto)
done

lemma Rep_net_within:
  "Rep_net (net within S) = (\<lambda>A. A \<inter> S) ` Rep_net net"
unfolding within_def
apply (rule Abs_net_inverse')
apply (rule image_nonempty, rule Rep_net_nonempty)
apply (clarsimp, rename_tac A B)
apply (drule (1) Rep_net_directed)
apply (clarify, rule_tac x=C in bexI, auto)
done

lemma eventually_sequentially:
  "eventually P sequentially \<longleftrightarrow> (\<exists>N. \<forall>n\<ge>N. P n)"
unfolding eventually_def Rep_net_sequentially by auto

lemma eventually_at:
  "eventually P (at a) \<longleftrightarrow> (\<exists>d>0. \<forall>x. x \<noteq> a \<and> dist x a < d \<longrightarrow> P x)"
unfolding eventually_def Rep_net_at by auto

lemma eventually_within:
  "eventually P (net within S) = eventually (\<lambda>x. x \<in> S \<longrightarrow> P x) net"
unfolding eventually_def Rep_net_within by auto


subsection {* Boundedness *}

definition
  Bfun :: "('a \<Rightarrow> 'b::real_normed_vector) \<Rightarrow> 'a net \<Rightarrow> bool" where
  [code del]: "Bfun S net = (\<exists>K>0. eventually (\<lambda>i. norm (S i) \<le> K) net)"

lemma BfunI: assumes K: "eventually (\<lambda>i. norm (X i) \<le> K) net" shows "Bfun X net"
unfolding Bfun_def
proof (intro exI conjI allI)
  show "0 < max K 1" by simp
next
  show "eventually (\<lambda>i. norm (X i) \<le> max K 1) net"
    using K by (rule eventually_elim1, simp)
qed

lemma BfunE:
  assumes "Bfun S net"
  obtains B where "0 < B" and "eventually (\<lambda>i. norm (S i) \<le> B) net"
using assms unfolding Bfun_def by fast


subsection {* Convergence to Zero *}

definition
  Zfun :: "('a \<Rightarrow> 'b::real_normed_vector) \<Rightarrow> 'a net \<Rightarrow> bool" where
  [code del]: "Zfun S net = (\<forall>r>0. eventually (\<lambda>i. norm (S i) < r) net)"

lemma ZfunI:
  "(\<And>r. 0 < r \<Longrightarrow> eventually (\<lambda>i. norm (S i) < r) net) \<Longrightarrow> Zfun S net"
unfolding Zfun_def by simp

lemma ZfunD:
  "\<lbrakk>Zfun S net; 0 < r\<rbrakk> \<Longrightarrow> eventually (\<lambda>i. norm (S i) < r) net"
unfolding Zfun_def by simp

lemma Zfun_ssubst:
  "eventually (\<lambda>i. X i = Y i) net \<Longrightarrow> Zfun Y net \<Longrightarrow> Zfun X net"
unfolding Zfun_def by (auto elim!: eventually_rev_mp)

lemma Zfun_zero: "Zfun (\<lambda>i. 0) net"
unfolding Zfun_def by simp

lemma Zfun_norm_iff: "Zfun (\<lambda>i. norm (S i)) net = Zfun (\<lambda>i. S i) net"
unfolding Zfun_def by simp

lemma Zfun_imp_Zfun:
  assumes X: "Zfun X net"
  assumes Y: "eventually (\<lambda>i. norm (Y i) \<le> norm (X i) * K) net"
  shows "Zfun (\<lambda>n. Y n) net"
proof (cases)
  assume K: "0 < K"
  show ?thesis
  proof (rule ZfunI)
    fix r::real assume "0 < r"
    hence "0 < r / K"
      using K by (rule divide_pos_pos)
    then have "eventually (\<lambda>i. norm (X i) < r / K) net"
      using ZfunD [OF X] by fast
    with Y show "eventually (\<lambda>i. norm (Y i) < r) net"
    proof (rule eventually_elim2)
      fix i
      assume *: "norm (Y i) \<le> norm (X i) * K"
      assume "norm (X i) < r / K"
      hence "norm (X i) * K < r"
        by (simp add: pos_less_divide_eq K)
      thus "norm (Y i) < r"
        by (simp add: order_le_less_trans [OF *])
    qed
  qed
next
  assume "\<not> 0 < K"
  hence K: "K \<le> 0" by (simp only: not_less)
  show ?thesis
  proof (rule ZfunI)
    fix r :: real
    assume "0 < r"
    from Y show "eventually (\<lambda>i. norm (Y i) < r) net"
    proof (rule eventually_elim1)
      fix i
      assume "norm (Y i) \<le> norm (X i) * K"
      also have "\<dots> \<le> norm (X i) * 0"
        using K norm_ge_zero by (rule mult_left_mono)
      finally show "norm (Y i) < r"
        using `0 < r` by simp
    qed
  qed
qed

lemma Zfun_le: "\<lbrakk>Zfun Y net; \<forall>n. norm (X n) \<le> norm (Y n)\<rbrakk> \<Longrightarrow> Zfun X net"
by (erule_tac K="1" in Zfun_imp_Zfun, simp)

lemma Zfun_add:
  assumes X: "Zfun X net" and Y: "Zfun Y net"
  shows "Zfun (\<lambda>n. X n + Y n) net"
proof (rule ZfunI)
  fix r::real assume "0 < r"
  hence r: "0 < r / 2" by simp
  have "eventually (\<lambda>i. norm (X i) < r/2) net"
    using X r by (rule ZfunD)
  moreover
  have "eventually (\<lambda>i. norm (Y i) < r/2) net"
    using Y r by (rule ZfunD)
  ultimately
  show "eventually (\<lambda>i. norm (X i + Y i) < r) net"
  proof (rule eventually_elim2)
    fix i
    assume *: "norm (X i) < r/2" "norm (Y i) < r/2"
    have "norm (X i + Y i) \<le> norm (X i) + norm (Y i)"
      by (rule norm_triangle_ineq)
    also have "\<dots> < r/2 + r/2"
      using * by (rule add_strict_mono)
    finally show "norm (X i + Y i) < r"
      by simp
  qed
qed

lemma Zfun_minus: "Zfun X net \<Longrightarrow> Zfun (\<lambda>i. - X i) net"
unfolding Zfun_def by simp

lemma Zfun_diff: "\<lbrakk>Zfun X net; Zfun Y net\<rbrakk> \<Longrightarrow> Zfun (\<lambda>i. X i - Y i) net"
by (simp only: diff_minus Zfun_add Zfun_minus)

lemma (in bounded_linear) Zfun:
  assumes X: "Zfun X net"
  shows "Zfun (\<lambda>n. f (X n)) net"
proof -
  obtain K where "\<And>x. norm (f x) \<le> norm x * K"
    using bounded by fast
  then have "eventually (\<lambda>i. norm (f (X i)) \<le> norm (X i) * K) net"
    by simp
  with X show ?thesis
    by (rule Zfun_imp_Zfun)
qed

lemma (in bounded_bilinear) Zfun:
  assumes X: "Zfun X net"
  assumes Y: "Zfun Y net"
  shows "Zfun (\<lambda>n. X n ** Y n) net"
proof (rule ZfunI)
  fix r::real assume r: "0 < r"
  obtain K where K: "0 < K"
    and norm_le: "\<And>x y. norm (x ** y) \<le> norm x * norm y * K"
    using pos_bounded by fast
  from K have K': "0 < inverse K"
    by (rule positive_imp_inverse_positive)
  have "eventually (\<lambda>i. norm (X i) < r) net"
    using X r by (rule ZfunD)
  moreover
  have "eventually (\<lambda>i. norm (Y i) < inverse K) net"
    using Y K' by (rule ZfunD)
  ultimately
  show "eventually (\<lambda>i. norm (X i ** Y i) < r) net"
  proof (rule eventually_elim2)
    fix i
    assume *: "norm (X i) < r" "norm (Y i) < inverse K"
    have "norm (X i ** Y i) \<le> norm (X i) * norm (Y i) * K"
      by (rule norm_le)
    also have "norm (X i) * norm (Y i) * K < r * inverse K * K"
      by (intro mult_strict_right_mono mult_strict_mono' norm_ge_zero * K)
    also from K have "r * inverse K * K = r"
      by simp
    finally show "norm (X i ** Y i) < r" .
  qed
qed

lemma (in bounded_bilinear) Zfun_left:
  "Zfun X net \<Longrightarrow> Zfun (\<lambda>n. X n ** a) net"
by (rule bounded_linear_left [THEN bounded_linear.Zfun])

lemma (in bounded_bilinear) Zfun_right:
  "Zfun X net \<Longrightarrow> Zfun (\<lambda>n. a ** X n) net"
by (rule bounded_linear_right [THEN bounded_linear.Zfun])

lemmas Zfun_mult = mult.Zfun
lemmas Zfun_mult_right = mult.Zfun_right
lemmas Zfun_mult_left = mult.Zfun_left


subsection{* Limits *}

definition
  tendsto :: "('a \<Rightarrow> 'b::metric_space) \<Rightarrow> 'b \<Rightarrow> 'a net \<Rightarrow> bool" where
  [code del]: "tendsto f l net \<longleftrightarrow> (\<forall>e>0. eventually (\<lambda>x. dist (f x) l < e) net)"

lemma tendstoI:
  "(\<And>e. 0 < e \<Longrightarrow> eventually (\<lambda>x. dist (f x) l < e) net)
    \<Longrightarrow> tendsto f l net"
  unfolding tendsto_def by auto

lemma tendstoD:
  "tendsto f l net \<Longrightarrow> 0 < e \<Longrightarrow> eventually (\<lambda>x. dist (f x) l < e) net"
  unfolding tendsto_def by auto

lemma tendsto_Zfun_iff: "tendsto (\<lambda>n. X n) L net = Zfun (\<lambda>n. X n - L) net"
by (simp only: tendsto_def Zfun_def dist_norm)

lemma tendsto_const: "tendsto (\<lambda>n. k) k net"
by (simp add: tendsto_def)

lemma tendsto_norm:
  fixes a :: "'a::real_normed_vector"
  shows "tendsto X a net \<Longrightarrow> tendsto (\<lambda>n. norm (X n)) (norm a) net"
apply (simp add: tendsto_def dist_norm, safe)
apply (drule_tac x="e" in spec, safe)
apply (erule eventually_elim1)
apply (erule order_le_less_trans [OF norm_triangle_ineq3])
done

lemma add_diff_add:
  fixes a b c d :: "'a::ab_group_add"
  shows "(a + c) - (b + d) = (a - b) + (c - d)"
by simp

lemma minus_diff_minus:
  fixes a b :: "'a::ab_group_add"
  shows "(- a) - (- b) = - (a - b)"
by simp

lemma tendsto_add:
  fixes a b :: "'a::real_normed_vector"
  shows "\<lbrakk>tendsto X a net; tendsto Y b net\<rbrakk> \<Longrightarrow> tendsto (\<lambda>n. X n + Y n) (a + b) net"
by (simp only: tendsto_Zfun_iff add_diff_add Zfun_add)

lemma tendsto_minus:
  fixes a :: "'a::real_normed_vector"
  shows "tendsto X a net \<Longrightarrow> tendsto (\<lambda>n. - X n) (- a) net"
by (simp only: tendsto_Zfun_iff minus_diff_minus Zfun_minus)

lemma tendsto_minus_cancel:
  fixes a :: "'a::real_normed_vector"
  shows "tendsto (\<lambda>n. - X n) (- a) net \<Longrightarrow> tendsto X a net"
by (drule tendsto_minus, simp)

lemma tendsto_diff:
  fixes a b :: "'a::real_normed_vector"
  shows "\<lbrakk>tendsto X a net; tendsto Y b net\<rbrakk> \<Longrightarrow> tendsto (\<lambda>n. X n - Y n) (a - b) net"
by (simp add: diff_minus tendsto_add tendsto_minus)

lemma (in bounded_linear) tendsto:
  "tendsto X a net \<Longrightarrow> tendsto (\<lambda>n. f (X n)) (f a) net"
by (simp only: tendsto_Zfun_iff diff [symmetric] Zfun)

lemma (in bounded_bilinear) tendsto:
  "\<lbrakk>tendsto X a net; tendsto Y b net\<rbrakk> \<Longrightarrow> tendsto (\<lambda>n. X n ** Y n) (a ** b) net"
by (simp only: tendsto_Zfun_iff prod_diff_prod
               Zfun_add Zfun Zfun_left Zfun_right)


subsection {* Continuity of Inverse *}

lemma (in bounded_bilinear) Zfun_prod_Bfun:
  assumes X: "Zfun X net"
  assumes Y: "Bfun Y net"
  shows "Zfun (\<lambda>n. X n ** Y n) net"
proof -
  obtain K where K: "0 \<le> K"
    and norm_le: "\<And>x y. norm (x ** y) \<le> norm x * norm y * K"
    using nonneg_bounded by fast
  obtain B where B: "0 < B"
    and norm_Y: "eventually (\<lambda>i. norm (Y i) \<le> B) net"
    using Y by (rule BfunE)
  have "eventually (\<lambda>i. norm (X i ** Y i) \<le> norm (X i) * (B * K)) net"
  using norm_Y proof (rule eventually_elim1)
    fix i
    assume *: "norm (Y i) \<le> B"
    have "norm (X i ** Y i) \<le> norm (X i) * norm (Y i) * K"
      by (rule norm_le)
    also have "\<dots> \<le> norm (X i) * B * K"
      by (intro mult_mono' order_refl norm_Y norm_ge_zero
                mult_nonneg_nonneg K *)
    also have "\<dots> = norm (X i) * (B * K)"
      by (rule mult_assoc)
    finally show "norm (X i ** Y i) \<le> norm (X i) * (B * K)" .
  qed
  with X show ?thesis
  by (rule Zfun_imp_Zfun)
qed

lemma (in bounded_bilinear) flip:
  "bounded_bilinear (\<lambda>x y. y ** x)"
apply default
apply (rule add_right)
apply (rule add_left)
apply (rule scaleR_right)
apply (rule scaleR_left)
apply (subst mult_commute)
using bounded by fast

lemma (in bounded_bilinear) Bfun_prod_Zfun:
  assumes X: "Bfun X net"
  assumes Y: "Zfun Y net"
  shows "Zfun (\<lambda>n. X n ** Y n) net"
using flip Y X by (rule bounded_bilinear.Zfun_prod_Bfun)

lemma inverse_diff_inverse:
  "\<lbrakk>(a::'a::division_ring) \<noteq> 0; b \<noteq> 0\<rbrakk>
   \<Longrightarrow> inverse a - inverse b = - (inverse a * (a - b) * inverse b)"
by (simp add: algebra_simps)

lemma Bfun_inverse_lemma:
  fixes x :: "'a::real_normed_div_algebra"
  shows "\<lbrakk>r \<le> norm x; 0 < r\<rbrakk> \<Longrightarrow> norm (inverse x) \<le> inverse r"
apply (subst nonzero_norm_inverse, clarsimp)
apply (erule (1) le_imp_inverse_le)
done

lemma Bfun_inverse:
  fixes a :: "'a::real_normed_div_algebra"
  assumes X: "tendsto X a net"
  assumes a: "a \<noteq> 0"
  shows "Bfun (\<lambda>n. inverse (X n)) net"
proof -
  from a have "0 < norm a" by simp
  hence "\<exists>r>0. r < norm a" by (rule dense)
  then obtain r where r1: "0 < r" and r2: "r < norm a" by fast
  have "eventually (\<lambda>i. dist (X i) a < r) net"
    using tendstoD [OF X r1] by fast
  hence "eventually (\<lambda>i. norm (inverse (X i)) \<le> inverse (norm a - r)) net"
  proof (rule eventually_elim1)
    fix i
    assume "dist (X i) a < r"
    hence 1: "norm (X i - a) < r"
      by (simp add: dist_norm)
    hence 2: "X i \<noteq> 0" using r2 by auto
    hence "norm (inverse (X i)) = inverse (norm (X i))"
      by (rule nonzero_norm_inverse)
    also have "\<dots> \<le> inverse (norm a - r)"
    proof (rule le_imp_inverse_le)
      show "0 < norm a - r" using r2 by simp
    next
      have "norm a - norm (X i) \<le> norm (a - X i)"
        by (rule norm_triangle_ineq2)
      also have "\<dots> = norm (X i - a)"
        by (rule norm_minus_commute)
      also have "\<dots> < r" using 1 .
      finally show "norm a - r \<le> norm (X i)" by simp
    qed
    finally show "norm (inverse (X i)) \<le> inverse (norm a - r)" .
  qed
  thus ?thesis by (rule BfunI)
qed

lemma tendsto_inverse_lemma:
  fixes a :: "'a::real_normed_div_algebra"
  shows "\<lbrakk>tendsto X a net; a \<noteq> 0; eventually (\<lambda>i. X i \<noteq> 0) net\<rbrakk>
         \<Longrightarrow> tendsto (\<lambda>i. inverse (X i)) (inverse a) net"
apply (subst tendsto_Zfun_iff)
apply (rule Zfun_ssubst)
apply (erule eventually_elim1)
apply (erule (1) inverse_diff_inverse)
apply (rule Zfun_minus)
apply (rule Zfun_mult_left)
apply (rule mult.Bfun_prod_Zfun)
apply (erule (1) Bfun_inverse)
apply (simp add: tendsto_Zfun_iff)
done

lemma tendsto_inverse:
  fixes a :: "'a::real_normed_div_algebra"
  assumes X: "tendsto X a net"
  assumes a: "a \<noteq> 0"
  shows "tendsto (\<lambda>i. inverse (X i)) (inverse a) net"
proof -
  from a have "0 < norm a" by simp
  with X have "eventually (\<lambda>i. dist (X i) a < norm a) net"
    by (rule tendstoD)
  then have "eventually (\<lambda>i. X i \<noteq> 0) net"
    unfolding dist_norm by (auto elim!: eventually_elim1)
  with X a show ?thesis
    by (rule tendsto_inverse_lemma)
qed

lemma tendsto_divide:
  fixes a b :: "'a::real_normed_field"
  shows "\<lbrakk>tendsto X a net; tendsto Y b net; b \<noteq> 0\<rbrakk>
    \<Longrightarrow> tendsto (\<lambda>n. X n / Y n) (a / b) net"
by (simp add: mult.tendsto tendsto_inverse divide_inverse)

end

(*  Title:      Library/Operator_Norm.thy
    Author:     Amine Chaieb, University of Cambridge
*)

header {* Operator Norm *}

theory Operator_Norm
imports Euclidean_Space
begin

definition "onorm f = Sup {norm (f x)| x. norm x = 1}"

lemma norm_bound_generalize:
  fixes f:: "real ^'n \<Rightarrow> real^'m"
  assumes lf: "linear f"
  shows "(\<forall>x. norm x = 1 \<longrightarrow> norm (f x) \<le> b) \<longleftrightarrow> (\<forall>x. norm (f x) \<le> b * norm x)" (is "?lhs \<longleftrightarrow> ?rhs")
proof-
  {assume H: ?rhs
    {fix x :: "real^'n" assume x: "norm x = 1"
      from H[rule_format, of x] x have "norm (f x) \<le> b" by simp}
    then have ?lhs by blast }

  moreover
  {assume H: ?lhs
    from H[rule_format, of "basis arbitrary"]
    have bp: "b \<ge> 0" using norm_ge_zero[of "f (basis arbitrary)"]
      by (auto simp add: norm_basis elim: order_trans [OF norm_ge_zero])
    {fix x :: "real ^'n"
      {assume "x = 0"
        then have "norm (f x) \<le> b * norm x" by (simp add: linear_0[OF lf] bp)}
      moreover
      {assume x0: "x \<noteq> 0"
        hence n0: "norm x \<noteq> 0" by (metis norm_eq_zero)
        let ?c = "1/ norm x"
        have "norm (?c *\<^sub>R x) = 1" using x0 by (simp add: n0)
        with H have "norm (f (?c *\<^sub>R x)) \<le> b" by blast
        hence "?c * norm (f x) \<le> b"
          by (simp add: linear_cmul[OF lf])
        hence "norm (f x) \<le> b * norm x"
          using n0 norm_ge_zero[of x] by (auto simp add: field_simps)}
      ultimately have "norm (f x) \<le> b * norm x" by blast}
    then have ?rhs by blast}
  ultimately show ?thesis by blast
qed

lemma onorm:
  fixes f:: "real ^'n \<Rightarrow> real ^'m"
  assumes lf: "linear f"
  shows "norm (f x) <= onorm f * norm x"
  and "\<forall>x. norm (f x) <= b * norm x \<Longrightarrow> onorm f <= b"
proof-
  {
    let ?S = "{norm (f x) |x. norm x = 1}"
    have Se: "?S \<noteq> {}" using  norm_basis by auto
    from linear_bounded[OF lf] have b: "\<exists> b. ?S *<= b"
      unfolding norm_bound_generalize[OF lf, symmetric] by (auto simp add: setle_def)
    {from Sup[OF Se b, unfolded onorm_def[symmetric]]
      show "norm (f x) <= onorm f * norm x"
        apply -
        apply (rule spec[where x = x])
        unfolding norm_bound_generalize[OF lf, symmetric]
        by (auto simp add: isLub_def isUb_def leastP_def setge_def setle_def)}
    {
      show "\<forall>x. norm (f x) <= b * norm x \<Longrightarrow> onorm f <= b"
        using Sup[OF Se b, unfolded onorm_def[symmetric]]
        unfolding norm_bound_generalize[OF lf, symmetric]
        by (auto simp add: isLub_def isUb_def leastP_def setge_def setle_def)}
  }
qed

lemma onorm_pos_le: assumes lf: "linear (f::real ^'n \<Rightarrow> real ^'m)" shows "0 <= onorm f"
  using order_trans[OF norm_ge_zero onorm(1)[OF lf, of "basis arbitrary"], unfolded norm_basis] by simp

lemma onorm_eq_0: assumes lf: "linear (f::real ^'n \<Rightarrow> real ^'m)"
  shows "onorm f = 0 \<longleftrightarrow> (\<forall>x. f x = 0)"
  using onorm[OF lf]
  apply (auto simp add: onorm_pos_le)
  apply atomize
  apply (erule allE[where x="0::real"])
  using onorm_pos_le[OF lf]
  apply arith
  done

lemma onorm_const: "onorm(\<lambda>x::real^'n. (y::real ^'m)) = norm y"
proof-
  let ?f = "\<lambda>x::real^'n. (y::real ^ 'm)"
  have th: "{norm (?f x)| x. norm x = 1} = {norm y}"
    by(auto intro: vector_choose_size set_ext)
  show ?thesis
    unfolding onorm_def th
    apply (rule Sup_unique) by (simp_all  add: setle_def)
qed

lemma onorm_pos_lt: assumes lf: "linear (f::real ^ 'n \<Rightarrow> real ^'m)"
  shows "0 < onorm f \<longleftrightarrow> ~(\<forall>x. f x = 0)"
  unfolding onorm_eq_0[OF lf, symmetric]
  using onorm_pos_le[OF lf] by arith

lemma onorm_compose:
  assumes lf: "linear (f::real ^'n \<Rightarrow> real ^'m)"
  and lg: "linear (g::real^'k \<Rightarrow> real^'n)"
  shows "onorm (f o g) <= onorm f * onorm g"
  apply (rule onorm(2)[OF linear_compose[OF lg lf], rule_format])
  unfolding o_def
  apply (subst mult_assoc)
  apply (rule order_trans)
  apply (rule onorm(1)[OF lf])
  apply (rule mult_mono1)
  apply (rule onorm(1)[OF lg])
  apply (rule onorm_pos_le[OF lf])
  done

lemma onorm_neg_lemma: assumes lf: "linear (f::real ^'n \<Rightarrow> real^'m)"
  shows "onorm (\<lambda>x. - f x) \<le> onorm f"
  using onorm[OF linear_compose_neg[OF lf]] onorm[OF lf]
  unfolding norm_minus_cancel by metis

lemma onorm_neg: assumes lf: "linear (f::real ^'n \<Rightarrow> real^'m)"
  shows "onorm (\<lambda>x. - f x) = onorm f"
  using onorm_neg_lemma[OF lf] onorm_neg_lemma[OF linear_compose_neg[OF lf]]
  by simp

lemma onorm_triangle:
  assumes lf: "linear (f::real ^'n \<Rightarrow> real ^'m)" and lg: "linear g"
  shows "onorm (\<lambda>x. f x + g x) <= onorm f + onorm g"
  apply(rule onorm(2)[OF linear_compose_add[OF lf lg], rule_format])
  apply (rule order_trans)
  apply (rule norm_triangle_ineq)
  apply (simp add: distrib)
  apply (rule add_mono)
  apply (rule onorm(1)[OF lf])
  apply (rule onorm(1)[OF lg])
  done

lemma onorm_triangle_le: "linear (f::real ^'n \<Rightarrow> real ^'m) \<Longrightarrow> linear g \<Longrightarrow> onorm(f) + onorm(g) <= e
  \<Longrightarrow> onorm(\<lambda>x. f x + g x) <= e"
  apply (rule order_trans)
  apply (rule onorm_triangle)
  apply assumption+
  done

lemma onorm_triangle_lt: "linear (f::real ^'n \<Rightarrow> real ^'m) \<Longrightarrow> linear g \<Longrightarrow> onorm(f) + onorm(g) < e
  ==> onorm(\<lambda>x. f x + g x) < e"
  apply (rule order_le_less_trans)
  apply (rule onorm_triangle)
  by assumption+

end

(*  Title       : Deriv.thy
    Author      : Jacques D. Fleuriot
    Copyright   : 1998  University of Cambridge
    Conversion to Isar and new proofs by Lawrence C Paulson, 2004
    GMVT by Benjamin Porter, 2005
*)

header{* Differentiation *}

theory Deriv
imports Lim
begin

text{*Standard Definitions*}

definition
  deriv :: "['a::real_normed_field \<Rightarrow> 'a, 'a, 'a] \<Rightarrow> bool"
    --{*Differentiation: D is derivative of function f at x*}
          ("(DERIV (_)/ (_)/ :> (_))" [1000, 1000, 60] 60) where
  "DERIV f x :> D = ((%h. (f(x + h) - f x) / h) -- 0 --> D)"

subsection {* Derivatives *}

lemma DERIV_iff: "(DERIV f x :> D) = ((%h. (f(x + h) - f(x))/h) -- 0 --> D)"
by (simp add: deriv_def)

lemma DERIV_D: "DERIV f x :> D ==> (%h. (f(x + h) - f(x))/h) -- 0 --> D"
by (simp add: deriv_def)

lemma DERIV_const [simp]: "DERIV (\<lambda>x. k) x :> 0"
  by (simp add: deriv_def tendsto_const)

lemma DERIV_ident [simp]: "DERIV (\<lambda>x. x) x :> 1"
  by (simp add: deriv_def tendsto_const cong: LIM_cong)

lemma DERIV_add:
  "\<lbrakk>DERIV f x :> D; DERIV g x :> E\<rbrakk> \<Longrightarrow> DERIV (\<lambda>x. f x + g x) x :> D + E"
  by (simp only: deriv_def add_diff_add add_divide_distrib tendsto_add)

lemma DERIV_minus:
  "DERIV f x :> D \<Longrightarrow> DERIV (\<lambda>x. - f x) x :> - D"
  by (simp only: deriv_def minus_diff_minus divide_minus_left tendsto_minus)

lemma DERIV_diff:
  "\<lbrakk>DERIV f x :> D; DERIV g x :> E\<rbrakk> \<Longrightarrow> DERIV (\<lambda>x. f x - g x) x :> D - E"
by (simp only: diff_minus DERIV_add DERIV_minus)

lemma DERIV_add_minus:
  "\<lbrakk>DERIV f x :> D; DERIV g x :> E\<rbrakk> \<Longrightarrow> DERIV (\<lambda>x. f x + - g x) x :> D + - E"
by (simp only: DERIV_add DERIV_minus)

lemma DERIV_isCont: "DERIV f x :> D \<Longrightarrow> isCont f x"
proof (unfold isCont_iff)
  assume "DERIV f x :> D"
  hence "(\<lambda>h. (f(x+h) - f(x)) / h) -- 0 --> D"
    by (rule DERIV_D)
  hence "(\<lambda>h. (f(x+h) - f(x)) / h * h) -- 0 --> D * 0"
    by (intro tendsto_mult tendsto_ident_at)
  hence "(\<lambda>h. (f(x+h) - f(x)) * (h / h)) -- 0 --> 0"
    by simp
  hence "(\<lambda>h. f(x+h) - f(x)) -- 0 --> 0"
    by (simp cong: LIM_cong)
  thus "(\<lambda>h. f(x+h)) -- 0 --> f(x)"
    by (simp add: LIM_def dist_norm)
qed

lemma DERIV_mult_lemma:
  fixes a b c d :: "'a::real_field"
  shows "(a * b - c * d) / h = a * ((b - d) / h) + ((a - c) / h) * d"
  by (simp add: field_simps diff_divide_distrib)

lemma DERIV_mult':
  assumes f: "DERIV f x :> D"
  assumes g: "DERIV g x :> E"
  shows "DERIV (\<lambda>x. f x * g x) x :> f x * E + D * g x"
proof (unfold deriv_def)
  from f have "isCont f x"
    by (rule DERIV_isCont)
  hence "(\<lambda>h. f(x+h)) -- 0 --> f x"
    by (simp only: isCont_iff)
  hence "(\<lambda>h. f(x+h) * ((g(x+h) - g x) / h) +
              ((f(x+h) - f x) / h) * g x)
          -- 0 --> f x * E + D * g x"
    by (intro tendsto_intros DERIV_D f g)
  thus "(\<lambda>h. (f(x+h) * g(x+h) - f x * g x) / h)
         -- 0 --> f x * E + D * g x"
    by (simp only: DERIV_mult_lemma)
qed

lemma DERIV_mult:
    "DERIV f x :> Da \<Longrightarrow> DERIV g x :> Db \<Longrightarrow> DERIV (\<lambda>x. f x * g x) x :> Da * g x + Db * f x"
  by (drule (1) DERIV_mult', simp only: mult_commute add_commute)

lemma DERIV_unique:
    "DERIV f x :> D \<Longrightarrow> DERIV f x :> E \<Longrightarrow> D = E"
  unfolding deriv_def by (rule LIM_unique) 

text{*Differentiation of finite sum*}

lemma DERIV_setsum:
  assumes "finite S"
  and "\<And> n. n \<in> S \<Longrightarrow> DERIV (%x. f x n) x :> (f' x n)"
  shows "DERIV (%x. setsum (f x) S) x :> setsum (f' x) S"
  using assms by induct (auto intro!: DERIV_add)

lemma DERIV_sumr [rule_format (no_asm)]:
     "(\<forall>r. m \<le> r & r < (m + n) --> DERIV (%x. f r x) x :> (f' r x))
      --> DERIV (%x. \<Sum>n=m..<n::nat. f n x :: real) x :> (\<Sum>r=m..<n. f' r x)"
  by (auto intro: DERIV_setsum)

text{*Alternative definition for differentiability*}

lemma DERIV_LIM_iff:
  fixes f :: "'a::{real_normed_vector,inverse} \<Rightarrow> 'a" shows
     "((%h. (f(a + h) - f(a)) / h) -- 0 --> D) =
      ((%x. (f(x)-f(a)) / (x-a)) -- a --> D)"
apply (rule iffI)
apply (drule_tac k="- a" in LIM_offset)
apply (simp add: diff_minus)
apply (drule_tac k="a" in LIM_offset)
apply (simp add: add_commute)
done

lemma DERIV_iff2: "(DERIV f x :> D) = ((%z. (f(z) - f(x)) / (z-x)) -- x --> D)"
by (simp add: deriv_def diff_minus [symmetric] DERIV_LIM_iff)

lemma DERIV_inverse_lemma:
  "\<lbrakk>a \<noteq> 0; b \<noteq> (0::'a::real_normed_field)\<rbrakk>
   \<Longrightarrow> (inverse a - inverse b) / h
     = - (inverse a * ((a - b) / h) * inverse b)"
by (simp add: inverse_diff_inverse)

lemma DERIV_inverse':
  assumes der: "DERIV f x :> D"
  assumes neq: "f x \<noteq> 0"
  shows "DERIV (\<lambda>x. inverse (f x)) x :> - (inverse (f x) * D * inverse (f x))"
    (is "DERIV _ _ :> ?E")
proof (unfold DERIV_iff2)
  from der have lim_f: "f -- x --> f x"
    by (rule DERIV_isCont [unfolded isCont_def])

  from neq have "0 < norm (f x)" by simp
  with LIM_D [OF lim_f] obtain s
    where s: "0 < s"
    and less_fx: "\<And>z. \<lbrakk>z \<noteq> x; norm (z - x) < s\<rbrakk>
                  \<Longrightarrow> norm (f z - f x) < norm (f x)"
    by fast

  show "(\<lambda>z. (inverse (f z) - inverse (f x)) / (z - x)) -- x --> ?E"
  proof (rule LIM_equal2 [OF s])
    fix z
    assume "z \<noteq> x" "norm (z - x) < s"
    hence "norm (f z - f x) < norm (f x)" by (rule less_fx)
    hence "f z \<noteq> 0" by auto
    thus "(inverse (f z) - inverse (f x)) / (z - x) =
          - (inverse (f z) * ((f z - f x) / (z - x)) * inverse (f x))"
      using neq by (rule DERIV_inverse_lemma)
  next
    from der have "(\<lambda>z. (f z - f x) / (z - x)) -- x --> D"
      by (unfold DERIV_iff2)
    thus "(\<lambda>z. - (inverse (f z) * ((f z - f x) / (z - x)) * inverse (f x)))
          -- x --> ?E"
      by (intro tendsto_intros lim_f neq)
  qed
qed

lemma DERIV_divide:
  "\<lbrakk>DERIV f x :> D; DERIV g x :> E; g x \<noteq> 0\<rbrakk>
   \<Longrightarrow> DERIV (\<lambda>x. f x / g x) x :> (D * g x - f x * E) / (g x * g x)"
apply (subgoal_tac "f x * - (inverse (g x) * E * inverse (g x)) +
          D * inverse (g x) = (D * g x - f x * E) / (g x * g x)")
apply (erule subst)
apply (unfold divide_inverse)
apply (erule DERIV_mult')
apply (erule (1) DERIV_inverse')
apply (simp add: ring_distribs nonzero_inverse_mult_distrib)
done

lemma DERIV_power_Suc:
  fixes f :: "'a \<Rightarrow> 'a::{real_normed_field}"
  assumes f: "DERIV f x :> D"
  shows "DERIV (\<lambda>x. f x ^ Suc n) x :> (1 + of_nat n) * (D * f x ^ n)"
proof (induct n)
case 0
  show ?case by (simp add: f)
case (Suc k)
  from DERIV_mult' [OF f Suc] show ?case
    apply (simp only: of_nat_Suc ring_distribs mult_1_left)
    apply (simp only: power_Suc algebra_simps)
    done
qed

lemma DERIV_power:
  fixes f :: "'a \<Rightarrow> 'a::{real_normed_field}"
  assumes f: "DERIV f x :> D"
  shows "DERIV (\<lambda>x. f x ^ n) x :> of_nat n * (D * f x ^ (n - Suc 0))"
by (cases "n", simp, simp add: DERIV_power_Suc f del: power_Suc)

text {* Caratheodory formulation of derivative at a point *}

lemma CARAT_DERIV:
     "(DERIV f x :> l) =
      (\<exists>g. (\<forall>z. f z - f x = g z * (z-x)) & isCont g x & g x = l)"
      (is "?lhs = ?rhs")
proof
  assume der: "DERIV f x :> l"
  show "\<exists>g. (\<forall>z. f z - f x = g z * (z-x)) \<and> isCont g x \<and> g x = l"
  proof (intro exI conjI)
    let ?g = "(%z. if z = x then l else (f z - f x) / (z-x))"
    show "\<forall>z. f z - f x = ?g z * (z-x)" by simp
    show "isCont ?g x" using der
      by (simp add: isCont_iff DERIV_iff diff_minus
               cong: LIM_equal [rule_format])
    show "?g x = l" by simp
  qed
next
  assume "?rhs"
  then obtain g where
    "(\<forall>z. f z - f x = g z * (z-x))" and "isCont g x" and "g x = l" by blast
  thus "(DERIV f x :> l)"
     by (auto simp add: isCont_iff DERIV_iff cong: LIM_cong)
qed

lemma DERIV_chain':
  assumes f: "DERIV f x :> D"
  assumes g: "DERIV g (f x) :> E"
  shows "DERIV (\<lambda>x. g (f x)) x :> E * D"
proof (unfold DERIV_iff2)
  obtain d where d: "\<forall>y. g y - g (f x) = d y * (y - f x)"
    and cont_d: "isCont d (f x)" and dfx: "d (f x) = E"
    using CARAT_DERIV [THEN iffD1, OF g] by fast
  from f have "f -- x --> f x"
    by (rule DERIV_isCont [unfolded isCont_def])
  with cont_d have "(\<lambda>z. d (f z)) -- x --> d (f x)"
    by (rule isCont_tendsto_compose)
  hence "(\<lambda>z. d (f z) * ((f z - f x) / (z - x)))
          -- x --> d (f x) * D"
    by (rule tendsto_mult [OF _ f [unfolded DERIV_iff2]])
  thus "(\<lambda>z. (g (f z) - g (f x)) / (z - x)) -- x --> E * D"
    by (simp add: d dfx)
qed

text {*
 Let's do the standard proof, though theorem
 @{text "LIM_mult2"} follows from a NS proof
*}

lemma DERIV_cmult:
      "DERIV f x :> D ==> DERIV (%x. c * f x) x :> c*D"
by (drule DERIV_mult' [OF DERIV_const], simp)

lemma DERIV_cdivide: "DERIV f x :> D ==> DERIV (%x. f x / c) x :> D / c"
  apply (subgoal_tac "DERIV (%x. (1 / c) * f x) x :> (1 / c) * D", force)
  apply (erule DERIV_cmult)
  done

text {* Standard version *}
lemma DERIV_chain: "[| DERIV f (g x) :> Da; DERIV g x :> Db |] ==> DERIV (f o g) x :> Da * Db"
by (drule (1) DERIV_chain', simp add: o_def mult_commute)

lemma DERIV_chain2: "[| DERIV f (g x) :> Da; DERIV g x :> Db |] ==> DERIV (%x. f (g x)) x :> Da * Db"
by (auto dest: DERIV_chain simp add: o_def)

text {* Derivative of linear multiplication *}
lemma DERIV_cmult_Id [simp]: "DERIV (op * c) x :> c"
by (cut_tac c = c and x = x in DERIV_ident [THEN DERIV_cmult], simp)

lemma DERIV_pow: "DERIV (%x. x ^ n) x :> real n * (x ^ (n - Suc 0))"
apply (cut_tac DERIV_power [OF DERIV_ident])
apply (simp add: real_of_nat_def)
done

text {* Power of @{text "-1"} *}

lemma DERIV_inverse:
  fixes x :: "'a::{real_normed_field}"
  shows "x \<noteq> 0 ==> DERIV (%x. inverse(x)) x :> (-(inverse x ^ Suc (Suc 0)))"
by (drule DERIV_inverse' [OF DERIV_ident]) simp

text {* Derivative of inverse *}
lemma DERIV_inverse_fun:
  fixes x :: "'a::{real_normed_field}"
  shows "[| DERIV f x :> d; f(x) \<noteq> 0 |]
      ==> DERIV (%x. inverse(f x)) x :> (- (d * inverse(f(x) ^ Suc (Suc 0))))"
by (drule (1) DERIV_inverse') (simp add: mult_ac nonzero_inverse_mult_distrib)

text {* Derivative of quotient *}
lemma DERIV_quotient:
  fixes x :: "'a::{real_normed_field}"
  shows "[| DERIV f x :> d; DERIV g x :> e; g(x) \<noteq> 0 |]
       ==> DERIV (%y. f(y) / (g y)) x :> (d*g(x) - (e*f(x))) / (g(x) ^ Suc (Suc 0))"
by (drule (2) DERIV_divide) (simp add: mult_commute)

text {* @{text "DERIV_intros"} *}
ML {*
structure Deriv_Intros = Named_Thms
(
  val name = @{binding DERIV_intros}
  val description = "DERIV introduction rules"
)
*}

setup Deriv_Intros.setup

lemma DERIV_cong: "\<lbrakk> DERIV f x :> X ; X = Y \<rbrakk> \<Longrightarrow> DERIV f x :> Y"
  by simp

declare
  DERIV_const[THEN DERIV_cong, DERIV_intros]
  DERIV_ident[THEN DERIV_cong, DERIV_intros]
  DERIV_add[THEN DERIV_cong, DERIV_intros]
  DERIV_minus[THEN DERIV_cong, DERIV_intros]
  DERIV_mult[THEN DERIV_cong, DERIV_intros]
  DERIV_diff[THEN DERIV_cong, DERIV_intros]
  DERIV_inverse'[THEN DERIV_cong, DERIV_intros]
  DERIV_divide[THEN DERIV_cong, DERIV_intros]
  DERIV_power[where 'a=real, THEN DERIV_cong,
              unfolded real_of_nat_def[symmetric], DERIV_intros]
  DERIV_setsum[THEN DERIV_cong, DERIV_intros]


subsection {* Differentiability predicate *}

definition
  differentiable :: "['a::real_normed_field \<Rightarrow> 'a, 'a] \<Rightarrow> bool"
    (infixl "differentiable" 60) where
  "f differentiable x = (\<exists>D. DERIV f x :> D)"

lemma differentiableE [elim?]:
  assumes "f differentiable x"
  obtains df where "DERIV f x :> df"
  using assms unfolding differentiable_def ..

lemma differentiableD: "f differentiable x ==> \<exists>D. DERIV f x :> D"
by (simp add: differentiable_def)

lemma differentiableI: "DERIV f x :> D ==> f differentiable x"
by (force simp add: differentiable_def)

lemma differentiable_ident [simp]: "(\<lambda>x. x) differentiable x"
  by (rule DERIV_ident [THEN differentiableI])

lemma differentiable_const [simp]: "(\<lambda>z. a) differentiable x"
  by (rule DERIV_const [THEN differentiableI])

lemma differentiable_compose:
  assumes f: "f differentiable (g x)"
  assumes g: "g differentiable x"
  shows "(\<lambda>x. f (g x)) differentiable x"
proof -
  from `f differentiable (g x)` obtain df where "DERIV f (g x) :> df" ..
  moreover
  from `g differentiable x` obtain dg where "DERIV g x :> dg" ..
  ultimately
  have "DERIV (\<lambda>x. f (g x)) x :> df * dg" by (rule DERIV_chain2)
  thus ?thesis by (rule differentiableI)
qed

lemma differentiable_sum [simp]:
  assumes "f differentiable x"
  and "g differentiable x"
  shows "(\<lambda>x. f x + g x) differentiable x"
proof -
  from `f differentiable x` obtain df where "DERIV f x :> df" ..
  moreover
  from `g differentiable x` obtain dg where "DERIV g x :> dg" ..
  ultimately
  have "DERIV (\<lambda>x. f x + g x) x :> df + dg" by (rule DERIV_add)
  thus ?thesis by (rule differentiableI)
qed

lemma differentiable_minus [simp]:
  assumes "f differentiable x"
  shows "(\<lambda>x. - f x) differentiable x"
proof -
  from `f differentiable x` obtain df where "DERIV f x :> df" ..
  hence "DERIV (\<lambda>x. - f x) x :> - df" by (rule DERIV_minus)
  thus ?thesis by (rule differentiableI)
qed

lemma differentiable_diff [simp]:
  assumes "f differentiable x"
  assumes "g differentiable x"
  shows "(\<lambda>x. f x - g x) differentiable x"
  unfolding diff_minus using assms by simp

lemma differentiable_mult [simp]:
  assumes "f differentiable x"
  assumes "g differentiable x"
  shows "(\<lambda>x. f x * g x) differentiable x"
proof -
  from `f differentiable x` obtain df where "DERIV f x :> df" ..
  moreover
  from `g differentiable x` obtain dg where "DERIV g x :> dg" ..
  ultimately
  have "DERIV (\<lambda>x. f x * g x) x :> df * g x + dg * f x" by (rule DERIV_mult)
  thus ?thesis by (rule differentiableI)
qed

lemma differentiable_inverse [simp]:
  assumes "f differentiable x" and "f x \<noteq> 0"
  shows "(\<lambda>x. inverse (f x)) differentiable x"
proof -
  from `f differentiable x` obtain df where "DERIV f x :> df" ..
  hence "DERIV (\<lambda>x. inverse (f x)) x :> - (inverse (f x) * df * inverse (f x))"
    using `f x \<noteq> 0` by (rule DERIV_inverse')
  thus ?thesis by (rule differentiableI)
qed

lemma differentiable_divide [simp]:
  assumes "f differentiable x"
  assumes "g differentiable x" and "g x \<noteq> 0"
  shows "(\<lambda>x. f x / g x) differentiable x"
  unfolding divide_inverse using assms by simp

lemma differentiable_power [simp]:
  fixes f :: "'a::{real_normed_field} \<Rightarrow> 'a"
  assumes "f differentiable x"
  shows "(\<lambda>x. f x ^ n) differentiable x"
  apply (induct n)
  apply simp
  apply (simp add: assms)
  done


subsection {* Nested Intervals and Bisection *}

lemma nested_sequence_unique:
  assumes "\<forall>n. f n \<le> f (Suc n)" "\<forall>n. g (Suc n) \<le> g n" "\<forall>n. f n \<le> g n" "(\<lambda>n. f n - g n) ----> 0"
  shows "\<exists>l::real. ((\<forall>n. f n \<le> l) \<and> f ----> l) \<and> ((\<forall>n. l \<le> g n) \<and> g ----> l)"
proof -
  have "incseq f" unfolding incseq_Suc_iff by fact
  have "decseq g" unfolding decseq_Suc_iff by fact

  { fix n
    from `decseq g` have "g n \<le> g 0" by (rule decseqD) simp
    with `\<forall>n. f n \<le> g n`[THEN spec, of n] have "f n \<le> g 0" by auto }
  then obtain u where "f ----> u" "\<forall>i. f i \<le> u"
    using incseq_convergent[OF `incseq f`] by auto
  moreover
  { fix n
    from `incseq f` have "f 0 \<le> f n" by (rule incseqD) simp
    with `\<forall>n. f n \<le> g n`[THEN spec, of n] have "f 0 \<le> g n" by simp }
  then obtain l where "g ----> l" "\<forall>i. l \<le> g i"
    using decseq_convergent[OF `decseq g`] by auto
  moreover note LIMSEQ_unique[OF assms(4) tendsto_diff[OF `f ----> u` `g ----> l`]]
  ultimately show ?thesis by auto
qed

lemma Bolzano[consumes 1, case_names trans local]:
  fixes P :: "real \<Rightarrow> real \<Rightarrow> bool"
  assumes [arith]: "a \<le> b"
  assumes trans: "\<And>a b c. \<lbrakk>P a b; P b c; a \<le> b; b \<le> c\<rbrakk> \<Longrightarrow> P a c"
  assumes local: "\<And>x. a \<le> x \<Longrightarrow> x \<le> b \<Longrightarrow> \<exists>d>0. \<forall>a b. a \<le> x \<and> x \<le> b \<and> b - a < d \<longrightarrow> P a b"
  shows "P a b"
proof -
  def bisect \<equiv> "nat_rec (a, b) (\<lambda>n (x, y). if P x ((x+y) / 2) then ((x+y)/2, y) else (x, (x+y)/2))"
  def l \<equiv> "\<lambda>n. fst (bisect n)" and u \<equiv> "\<lambda>n. snd (bisect n)"
  have l[simp]: "l 0 = a" "\<And>n. l (Suc n) = (if P (l n) ((l n + u n) / 2) then (l n + u n) / 2 else l n)"
    and u[simp]: "u 0 = b" "\<And>n. u (Suc n) = (if P (l n) ((l n + u n) / 2) then u n else (l n + u n) / 2)"
    by (simp_all add: l_def u_def bisect_def split: prod.split)

  { fix n have "l n \<le> u n" by (induct n) auto } note this[simp]

  have "\<exists>x. ((\<forall>n. l n \<le> x) \<and> l ----> x) \<and> ((\<forall>n. x \<le> u n) \<and> u ----> x)"
  proof (safe intro!: nested_sequence_unique)
    fix n show "l n \<le> l (Suc n)" "u (Suc n) \<le> u n" by (induct n) auto
  next
    { fix n have "l n - u n = (a - b) / 2^n" by (induct n) (auto simp: field_simps) }
    then show "(\<lambda>n. l n - u n) ----> 0" by (simp add: LIMSEQ_divide_realpow_zero)
  qed fact
  then obtain x where x: "\<And>n. l n \<le> x" "\<And>n. x \<le> u n" and "l ----> x" "u ----> x" by auto
  obtain d where "0 < d" and d: "\<And>a b. a \<le> x \<Longrightarrow> x \<le> b \<Longrightarrow> b - a < d \<Longrightarrow> P a b"
    using `l 0 \<le> x` `x \<le> u 0` local[of x] by auto

  show "P a b"
  proof (rule ccontr)
    assume "\<not> P a b" 
    { fix n have "\<not> P (l n) (u n)"
      proof (induct n)
        case (Suc n) with trans[of "l n" "(l n + u n) / 2" "u n"] show ?case by auto
      qed (simp add: `\<not> P a b`) }
    moreover
    { have "eventually (\<lambda>n. x - d / 2 < l n) sequentially"
        using `0 < d` `l ----> x` by (intro order_tendstoD[of _ x]) auto
      moreover have "eventually (\<lambda>n. u n < x + d / 2) sequentially"
        using `0 < d` `u ----> x` by (intro order_tendstoD[of _ x]) auto
      ultimately have "eventually (\<lambda>n. P (l n) (u n)) sequentially"
      proof eventually_elim
        fix n assume "x - d / 2 < l n" "u n < x + d / 2"
        from add_strict_mono[OF this] have "u n - l n < d" by simp
        with x show "P (l n) (u n)" by (rule d)
      qed }
    ultimately show False by simp
  qed
qed

(*HOL style here: object-level formulations*)
lemma IVT_objl: "(f(a::real) \<le> (y::real) & y \<le> f(b) & a \<le> b &
      (\<forall>x. a \<le> x & x \<le> b --> isCont f x))
      --> (\<exists>x. a \<le> x & x \<le> b & f(x) = y)"
apply (blast intro: IVT)
done

lemma IVT2_objl: "(f(b::real) \<le> (y::real) & y \<le> f(a) & a \<le> b &
      (\<forall>x. a \<le> x & x \<le> b --> isCont f x))
      --> (\<exists>x. a \<le> x & x \<le> b & f(x) = y)"
apply (blast intro: IVT2)
done


lemma compact_Icc[simp, intro]: "compact {a .. b::real}"
proof (cases "a \<le> b", rule compactI)
  fix C assume C: "a \<le> b" "\<forall>t\<in>C. open t" "{a..b} \<subseteq> \<Union>C"
  def T == "{a .. b}"
  from C(1,3) show "\<exists>C'\<subseteq>C. finite C' \<and> {a..b} \<subseteq> \<Union>C'"
  proof (induct rule: Bolzano)
    case (trans a b c)
    then have *: "{a .. c} = {a .. b} \<union> {b .. c}" by auto
    from trans obtain C1 C2 where "C1\<subseteq>C \<and> finite C1 \<and> {a..b} \<subseteq> \<Union>C1" "C2\<subseteq>C \<and> finite C2 \<and> {b..c} \<subseteq> \<Union>C2"
      by (auto simp: *)
    with trans show ?case
      unfolding * by (intro exI[of _ "C1 \<union> C2"]) auto
  next
    case (local x)
    then have "x \<in> \<Union>C" using C by auto
    with C(2) obtain c where "x \<in> c" "open c" "c \<in> C" by auto
    then obtain e where "0 < e" "{x - e <..< x + e} \<subseteq> c"
      by (auto simp: open_real_def dist_real_def subset_eq Ball_def abs_less_iff)
    with `c \<in> C` show ?case
      by (safe intro!: exI[of _ "e/2"] exI[of _ "{c}"]) auto
  qed
qed simp

subsection {* Boundedness of continuous functions *}

text{*By bisection, function continuous on closed interval is bounded above*}

lemma isCont_eq_Ub:
  fixes f :: "real \<Rightarrow> 'a::linorder_topology"
  shows "a \<le> b \<Longrightarrow> \<forall>x::real. a \<le> x \<and> x \<le> b \<longrightarrow> isCont f x \<Longrightarrow>
    \<exists>M. (\<forall>x. a \<le> x \<and> x \<le> b \<longrightarrow> f x \<le> M) \<and> (\<exists>x. a \<le> x \<and> x \<le> b \<and> f x = M)"
  using continuous_attains_sup[of "{a .. b}" f]
  apply (simp add: continuous_at_imp_continuous_on Ball_def)
  apply safe
  apply (rule_tac x="f x" in exI)
  apply auto
  done

lemma isCont_eq_Lb:
  fixes f :: "real \<Rightarrow> 'a::linorder_topology"
  shows "a \<le> b \<Longrightarrow> \<forall>x. a \<le> x \<and> x \<le> b \<longrightarrow> isCont f x \<Longrightarrow>
    \<exists>M. (\<forall>x. a \<le> x \<and> x \<le> b \<longrightarrow> M \<le> f x) \<and> (\<exists>x. a \<le> x \<and> x \<le> b \<and> f x = M)"
  using continuous_attains_inf[of "{a .. b}" f]
  apply (simp add: continuous_at_imp_continuous_on Ball_def)
  apply safe
  apply (rule_tac x="f x" in exI)
  apply auto
  done

lemma isCont_bounded:
  fixes f :: "real \<Rightarrow> 'a::linorder_topology"
  shows "a \<le> b \<Longrightarrow> \<forall>x. a \<le> x \<and> x \<le> b \<longrightarrow> isCont f x \<Longrightarrow> \<exists>M. \<forall>x. a \<le> x \<and> x \<le> b \<longrightarrow> f x \<le> M"
  using isCont_eq_Ub[of a b f] by auto

lemma isCont_has_Ub:
  fixes f :: "real \<Rightarrow> 'a::linorder_topology"
  shows "a \<le> b \<Longrightarrow> \<forall>x. a \<le> x \<and> x \<le> b \<longrightarrow> isCont f x \<Longrightarrow>
    \<exists>M. (\<forall>x. a \<le> x \<and> x \<le> b \<longrightarrow> f x \<le> M) \<and> (\<forall>N. N < M \<longrightarrow> (\<exists>x. a \<le> x \<and> x \<le> b \<and> N < f x))"
  using isCont_eq_Ub[of a b f] by auto

text{*Refine the above to existence of least upper bound*}

lemma lemma_reals_complete: "((\<exists>x. x \<in> S) & (\<exists>y. isUb UNIV S (y::real))) -->
      (\<exists>t. isLub UNIV S t)"
by (blast intro: reals_complete)


text{*Another version.*}

lemma isCont_Lb_Ub: "[|a \<le> b; \<forall>x. a \<le> x & x \<le> b --> isCont f x |]
      ==> \<exists>L M::real. (\<forall>x::real. a \<le> x & x \<le> b --> L \<le> f(x) & f(x) \<le> M) &
          (\<forall>y. L \<le> y & y \<le> M --> (\<exists>x. a \<le> x & x \<le> b & (f(x) = y)))"
apply (frule isCont_eq_Lb)
apply (frule_tac [2] isCont_eq_Ub)
apply (assumption+, safe)
apply (rule_tac x = "f x" in exI)
apply (rule_tac x = "f xa" in exI, simp, safe)
apply (cut_tac x = x and y = xa in linorder_linear, safe)
apply (cut_tac f = f and a = x and b = xa and y = y in IVT_objl)
apply (cut_tac [2] f = f and a = xa and b = x and y = y in IVT2_objl, safe)
apply (rule_tac [2] x = xb in exI)
apply (rule_tac [4] x = xb in exI, simp_all)
done


subsection {* Local extrema *}

text{*If @{term "0 < f'(x)"} then @{term x} is Locally Strictly Increasing At The Right*}

lemma DERIV_pos_inc_right:
  fixes f :: "real => real"
  assumes der: "DERIV f x :> l"
      and l:   "0 < l"
  shows "\<exists>d > 0. \<forall>h > 0. h < d --> f(x) < f(x + h)"
proof -
  from l der [THEN DERIV_D, THEN LIM_D [where r = "l"]]
  have "\<exists>s > 0. (\<forall>z. z \<noteq> 0 \<and> \<bar>z\<bar> < s \<longrightarrow> \<bar>(f(x+z) - f x) / z - l\<bar> < l)"
    by (simp add: diff_minus)
  then obtain s
        where s:   "0 < s"
          and all: "!!z. z \<noteq> 0 \<and> \<bar>z\<bar> < s \<longrightarrow> \<bar>(f(x+z) - f x) / z - l\<bar> < l"
    by auto
  thus ?thesis
  proof (intro exI conjI strip)
    show "0<s" using s .
    fix h::real
    assume "0 < h" "h < s"
    with all [of h] show "f x < f (x+h)"
    proof (simp add: abs_if pos_less_divide_eq diff_minus [symmetric]
    split add: split_if_asm)
      assume "~ (f (x+h) - f x) / h < l" and h: "0 < h"
      with l
      have "0 < (f (x+h) - f x) / h" by arith
      thus "f x < f (x+h)"
  by (simp add: pos_less_divide_eq h)
    qed
  qed
qed

lemma DERIV_neg_dec_left:
  fixes f :: "real => real"
  assumes der: "DERIV f x :> l"
      and l:   "l < 0"
  shows "\<exists>d > 0. \<forall>h > 0. h < d --> f(x) < f(x-h)"
proof -
  from l der [THEN DERIV_D, THEN LIM_D [where r = "-l"]]
  have "\<exists>s > 0. (\<forall>z. z \<noteq> 0 \<and> \<bar>z\<bar> < s \<longrightarrow> \<bar>(f(x+z) - f x) / z - l\<bar> < -l)"
    by (simp add: diff_minus)
  then obtain s
        where s:   "0 < s"
          and all: "!!z. z \<noteq> 0 \<and> \<bar>z\<bar> < s \<longrightarrow> \<bar>(f(x+z) - f x) / z - l\<bar> < -l"
    by auto
  thus ?thesis
  proof (intro exI conjI strip)
    show "0<s" using s .
    fix h::real
    assume "0 < h" "h < s"
    with all [of "-h"] show "f x < f (x-h)"
    proof (simp add: abs_if pos_less_divide_eq diff_minus [symmetric]
    split add: split_if_asm)
      assume " - ((f (x-h) - f x) / h) < l" and h: "0 < h"
      with l
      have "0 < (f (x-h) - f x) / h" by arith
      thus "f x < f (x-h)"
  by (simp add: pos_less_divide_eq h)
    qed
  qed
qed


lemma DERIV_pos_inc_left:
  fixes f :: "real => real"
  shows "DERIV f x :> l \<Longrightarrow> 0 < l \<Longrightarrow> \<exists>d > 0. \<forall>h > 0. h < d --> f(x - h) < f(x)"
  apply (rule DERIV_neg_dec_left [of "%x. - f x" x "-l", simplified])
  apply (auto simp add: DERIV_minus)
  done

lemma DERIV_neg_dec_right:
  fixes f :: "real => real"
  shows "DERIV f x :> l \<Longrightarrow> l < 0 \<Longrightarrow> \<exists>d > 0. \<forall>h > 0. h < d --> f(x) > f(x + h)"
  apply (rule DERIV_pos_inc_right [of "%x. - f x" x "-l", simplified])
  apply (auto simp add: DERIV_minus)
  done

lemma DERIV_local_max:
  fixes f :: "real => real"
  assumes der: "DERIV f x :> l"
      and d:   "0 < d"
      and le:  "\<forall>y. \<bar>x-y\<bar> < d --> f(y) \<le> f(x)"
  shows "l = 0"
proof (cases rule: linorder_cases [of l 0])
  case equal thus ?thesis .
next
  case less
  from DERIV_neg_dec_left [OF der less]
  obtain d' where d': "0 < d'"
             and lt: "\<forall>h > 0. h < d' \<longrightarrow> f x < f (x-h)" by blast
  from real_lbound_gt_zero [OF d d']
  obtain e where "0 < e \<and> e < d \<and> e < d'" ..
  with lt le [THEN spec [where x="x-e"]]
  show ?thesis by (auto simp add: abs_if)
next
  case greater
  from DERIV_pos_inc_right [OF der greater]
  obtain d' where d': "0 < d'"
             and lt: "\<forall>h > 0. h < d' \<longrightarrow> f x < f (x + h)" by blast
  from real_lbound_gt_zero [OF d d']
  obtain e where "0 < e \<and> e < d \<and> e < d'" ..
  with lt le [THEN spec [where x="x+e"]]
  show ?thesis by (auto simp add: abs_if)
qed


text{*Similar theorem for a local minimum*}
lemma DERIV_local_min:
  fixes f :: "real => real"
  shows "[| DERIV f x :> l; 0 < d; \<forall>y. \<bar>x-y\<bar> < d --> f(x) \<le> f(y) |] ==> l = 0"
by (drule DERIV_minus [THEN DERIV_local_max], auto)


text{*In particular, if a function is locally flat*}
lemma DERIV_local_const:
  fixes f :: "real => real"
  shows "[| DERIV f x :> l; 0 < d; \<forall>y. \<bar>x-y\<bar> < d --> f(x) = f(y) |] ==> l = 0"
by (auto dest!: DERIV_local_max)


subsection {* Rolle's Theorem *}

text{*Lemma about introducing open ball in open interval*}
lemma lemma_interval_lt:
     "[| a < x;  x < b |]
      ==> \<exists>d::real. 0 < d & (\<forall>y. \<bar>x-y\<bar> < d --> a < y & y < b)"

apply (simp add: abs_less_iff)
apply (insert linorder_linear [of "x-a" "b-x"], safe)
apply (rule_tac x = "x-a" in exI)
apply (rule_tac [2] x = "b-x" in exI, auto)
done

lemma lemma_interval: "[| a < x;  x < b |] ==>
        \<exists>d::real. 0 < d &  (\<forall>y. \<bar>x-y\<bar> < d --> a \<le> y & y \<le> b)"
apply (drule lemma_interval_lt, auto)
apply force
done

text{*Rolle's Theorem.
   If @{term f} is defined and continuous on the closed interval
   @{text "[a,b]"} and differentiable on the open interval @{text "(a,b)"},
   and @{term "f(a) = f(b)"},
   then there exists @{text "x0 \<in> (a,b)"} such that @{term "f'(x0) = 0"}*}
theorem Rolle:
  assumes lt: "a < b"
      and eq: "f(a) = f(b)"
      and con: "\<forall>x. a \<le> x & x \<le> b --> isCont f x"
      and dif [rule_format]: "\<forall>x. a < x & x < b --> f differentiable x"
  shows "\<exists>z::real. a < z & z < b & DERIV f z :> 0"
proof -
  have le: "a \<le> b" using lt by simp
  from isCont_eq_Ub [OF le con]
  obtain x where x_max: "\<forall>z. a \<le> z \<and> z \<le> b \<longrightarrow> f z \<le> f x"
             and alex: "a \<le> x" and xleb: "x \<le> b"
    by blast
  from isCont_eq_Lb [OF le con]
  obtain x' where x'_min: "\<forall>z. a \<le> z \<and> z \<le> b \<longrightarrow> f x' \<le> f z"
              and alex': "a \<le> x'" and x'leb: "x' \<le> b"
    by blast
  show ?thesis
  proof cases
    assume axb: "a < x & x < b"
        --{*@{term f} attains its maximum within the interval*}
    hence ax: "a<x" and xb: "x<b" by arith + 
    from lemma_interval [OF ax xb]
    obtain d where d: "0<d" and bound: "\<forall>y. \<bar>x-y\<bar> < d \<longrightarrow> a \<le> y \<and> y \<le> b"
      by blast
    hence bound': "\<forall>y. \<bar>x-y\<bar> < d \<longrightarrow> f y \<le> f x" using x_max
      by blast
    from differentiableD [OF dif [OF axb]]
    obtain l where der: "DERIV f x :> l" ..
    have "l=0" by (rule DERIV_local_max [OF der d bound'])
        --{*the derivative at a local maximum is zero*}
    thus ?thesis using ax xb der by auto
  next
    assume notaxb: "~ (a < x & x < b)"
    hence xeqab: "x=a | x=b" using alex xleb by arith
    hence fb_eq_fx: "f b = f x" by (auto simp add: eq)
    show ?thesis
    proof cases
      assume ax'b: "a < x' & x' < b"
        --{*@{term f} attains its minimum within the interval*}
      hence ax': "a<x'" and x'b: "x'<b" by arith+ 
      from lemma_interval [OF ax' x'b]
      obtain d where d: "0<d" and bound: "\<forall>y. \<bar>x'-y\<bar> < d \<longrightarrow> a \<le> y \<and> y \<le> b"
  by blast
      hence bound': "\<forall>y. \<bar>x'-y\<bar> < d \<longrightarrow> f x' \<le> f y" using x'_min
  by blast
      from differentiableD [OF dif [OF ax'b]]
      obtain l where der: "DERIV f x' :> l" ..
      have "l=0" by (rule DERIV_local_min [OF der d bound'])
        --{*the derivative at a local minimum is zero*}
      thus ?thesis using ax' x'b der by auto
    next
      assume notax'b: "~ (a < x' & x' < b)"
        --{*@{term f} is constant througout the interval*}
      hence x'eqab: "x'=a | x'=b" using alex' x'leb by arith
      hence fb_eq_fx': "f b = f x'" by (auto simp add: eq)
      from dense [OF lt]
      obtain r where ar: "a < r" and rb: "r < b" by blast
      from lemma_interval [OF ar rb]
      obtain d where d: "0<d" and bound: "\<forall>y. \<bar>r-y\<bar> < d \<longrightarrow> a \<le> y \<and> y \<le> b"
  by blast
      have eq_fb: "\<forall>z. a \<le> z --> z \<le> b --> f z = f b"
      proof (clarify)
        fix z::real
        assume az: "a \<le> z" and zb: "z \<le> b"
        show "f z = f b"
        proof (rule order_antisym)
          show "f z \<le> f b" by (simp add: fb_eq_fx x_max az zb)
          show "f b \<le> f z" by (simp add: fb_eq_fx' x'_min az zb)
        qed
      qed
      have bound': "\<forall>y. \<bar>r-y\<bar> < d \<longrightarrow> f r = f y"
      proof (intro strip)
        fix y::real
        assume lt: "\<bar>r-y\<bar> < d"
        hence "f y = f b" by (simp add: eq_fb bound)
        thus "f r = f y" by (simp add: eq_fb ar rb order_less_imp_le)
      qed
      from differentiableD [OF dif [OF conjI [OF ar rb]]]
      obtain l where der: "DERIV f r :> l" ..
      have "l=0" by (rule DERIV_local_const [OF der d bound'])
        --{*the derivative of a constant function is zero*}
      thus ?thesis using ar rb der by auto
    qed
  qed
qed


subsection{*Mean Value Theorem*}

lemma lemma_MVT:
     "f a - (f b - f a)/(b-a) * a = f b - (f b - f a)/(b-a) * (b::real)"
  by (cases "a = b") (simp_all add: field_simps)

theorem MVT:
  assumes lt:  "a < b"
      and con: "\<forall>x. a \<le> x & x \<le> b --> isCont f x"
      and dif [rule_format]: "\<forall>x. a < x & x < b --> f differentiable x"
  shows "\<exists>l z::real. a < z & z < b & DERIV f z :> l &
                   (f(b) - f(a) = (b-a) * l)"
proof -
  let ?F = "%x. f x - ((f b - f a) / (b-a)) * x"
  have contF: "\<forall>x. a \<le> x \<and> x \<le> b \<longrightarrow> isCont ?F x"
    using con by (fast intro: isCont_intros)
  have difF: "\<forall>x. a < x \<and> x < b \<longrightarrow> ?F differentiable x"
  proof (clarify)
    fix x::real
    assume ax: "a < x" and xb: "x < b"
    from differentiableD [OF dif [OF conjI [OF ax xb]]]
    obtain l where der: "DERIV f x :> l" ..
    show "?F differentiable x"
      by (rule differentiableI [where D = "l - (f b - f a)/(b-a)"],
          blast intro: DERIV_diff DERIV_cmult_Id der)
  qed
  from Rolle [where f = ?F, OF lt lemma_MVT contF difF]
  obtain z where az: "a < z" and zb: "z < b" and der: "DERIV ?F z :> 0"
    by blast
  have "DERIV (%x. ((f b - f a)/(b-a)) * x) z :> (f b - f a)/(b-a)"
    by (rule DERIV_cmult_Id)
  hence derF: "DERIV (\<lambda>x. ?F x + (f b - f a) / (b - a) * x) z
                   :> 0 + (f b - f a) / (b - a)"
    by (rule DERIV_add [OF der])
  show ?thesis
  proof (intro exI conjI)
    show "a < z" using az .
    show "z < b" using zb .
    show "f b - f a = (b - a) * ((f b - f a)/(b-a))" by (simp)
    show "DERIV f z :> ((f b - f a)/(b-a))"  using derF by simp
  qed
qed

lemma MVT2:
     "[| a < b; \<forall>x. a \<le> x & x \<le> b --> DERIV f x :> f'(x) |]
      ==> \<exists>z::real. a < z & z < b & (f b - f a = (b - a) * f'(z))"
apply (drule MVT)
apply (blast intro: DERIV_isCont)
apply (force dest: order_less_imp_le simp add: differentiable_def)
apply (blast dest: DERIV_unique order_less_imp_le)
done


text{*A function is constant if its derivative is 0 over an interval.*}

lemma DERIV_isconst_end:
  fixes f :: "real => real"
  shows "[| a < b;
         \<forall>x. a \<le> x & x \<le> b --> isCont f x;
         \<forall>x. a < x & x < b --> DERIV f x :> 0 |]
        ==> f b = f a"
apply (drule MVT, assumption)
apply (blast intro: differentiableI)
apply (auto dest!: DERIV_unique simp add: diff_eq_eq)
done

lemma DERIV_isconst1:
  fixes f :: "real => real"
  shows "[| a < b;
         \<forall>x. a \<le> x & x \<le> b --> isCont f x;
         \<forall>x. a < x & x < b --> DERIV f x :> 0 |]
        ==> \<forall>x. a \<le> x & x \<le> b --> f x = f a"
apply safe
apply (drule_tac x = a in order_le_imp_less_or_eq, safe)
apply (drule_tac b = x in DERIV_isconst_end, auto)
done

lemma DERIV_isconst2:
  fixes f :: "real => real"
  shows "[| a < b;
         \<forall>x. a \<le> x & x \<le> b --> isCont f x;
         \<forall>x. a < x & x < b --> DERIV f x :> 0;
         a \<le> x; x \<le> b |]
        ==> f x = f a"
apply (blast dest: DERIV_isconst1)
done

lemma DERIV_isconst3: fixes a b x y :: real
  assumes "a < b" and "x \<in> {a <..< b}" and "y \<in> {a <..< b}"
  assumes derivable: "\<And>x. x \<in> {a <..< b} \<Longrightarrow> DERIV f x :> 0"
  shows "f x = f y"
proof (cases "x = y")
  case False
  let ?a = "min x y"
  let ?b = "max x y"
  
  have "\<forall>z. ?a \<le> z \<and> z \<le> ?b \<longrightarrow> DERIV f z :> 0"
  proof (rule allI, rule impI)
    fix z :: real assume "?a \<le> z \<and> z \<le> ?b"
    hence "a < z" and "z < b" using `x \<in> {a <..< b}` and `y \<in> {a <..< b}` by auto
    hence "z \<in> {a<..<b}" by auto
    thus "DERIV f z :> 0" by (rule derivable)
  qed
  hence isCont: "\<forall>z. ?a \<le> z \<and> z \<le> ?b \<longrightarrow> isCont f z"
    and DERIV: "\<forall>z. ?a < z \<and> z < ?b \<longrightarrow> DERIV f z :> 0" using DERIV_isCont by auto

  have "?a < ?b" using `x \<noteq> y` by auto
  from DERIV_isconst2[OF this isCont DERIV, of x] and DERIV_isconst2[OF this isCont DERIV, of y]
  show ?thesis by auto
qed auto

lemma DERIV_isconst_all:
  fixes f :: "real => real"
  shows "\<forall>x. DERIV f x :> 0 ==> f(x) = f(y)"
apply (rule linorder_cases [of x y])
apply (blast intro: sym DERIV_isCont DERIV_isconst_end)+
done

lemma DERIV_const_ratio_const:
  fixes f :: "real => real"
  shows "[|a \<noteq> b; \<forall>x. DERIV f x :> k |] ==> (f(b) - f(a)) = (b-a) * k"
apply (rule linorder_cases [of a b], auto)
apply (drule_tac [!] f = f in MVT)
apply (auto dest: DERIV_isCont DERIV_unique simp add: differentiable_def)
apply (auto dest: DERIV_unique simp add: ring_distribs diff_minus)
done

lemma DERIV_const_ratio_const2:
  fixes f :: "real => real"
  shows "[|a \<noteq> b; \<forall>x. DERIV f x :> k |] ==> (f(b) - f(a))/(b-a) = k"
apply (rule_tac c1 = "b-a" in real_mult_right_cancel [THEN iffD1])
apply (auto dest!: DERIV_const_ratio_const simp add: mult_assoc)
done

lemma real_average_minus_first [simp]: "((a + b) /2 - a) = (b-a)/(2::real)"
by (simp)

lemma real_average_minus_second [simp]: "((b + a)/2 - a) = (b-a)/(2::real)"
by (simp)

text{*Gallileo's "trick": average velocity = av. of end velocities*}

lemma DERIV_const_average:
  fixes v :: "real => real"
  assumes neq: "a \<noteq> (b::real)"
      and der: "\<forall>x. DERIV v x :> k"
  shows "v ((a + b)/2) = (v a + v b)/2"
proof (cases rule: linorder_cases [of a b])
  case equal with neq show ?thesis by simp
next
  case less
  have "(v b - v a) / (b - a) = k"
    by (rule DERIV_const_ratio_const2 [OF neq der])
  hence "(b-a) * ((v b - v a) / (b-a)) = (b-a) * k" by simp
  moreover have "(v ((a + b) / 2) - v a) / ((a + b) / 2 - a) = k"
    by (rule DERIV_const_ratio_const2 [OF _ der], simp add: neq)
  ultimately show ?thesis using neq by force
next
  case greater
  have "(v b - v a) / (b - a) = k"
    by (rule DERIV_const_ratio_const2 [OF neq der])
  hence "(b-a) * ((v b - v a) / (b-a)) = (b-a) * k" by simp
  moreover have " (v ((b + a) / 2) - v a) / ((b + a) / 2 - a) = k"
    by (rule DERIV_const_ratio_const2 [OF _ der], simp add: neq)
  ultimately show ?thesis using neq by (force simp add: add_commute)
qed

(* A function with positive derivative is increasing. 
   A simple proof using the MVT, by Jeremy Avigad. And variants.
*)
lemma DERIV_pos_imp_increasing:
  fixes a::real and b::real and f::"real => real"
  assumes "a < b" and "\<forall>x. a \<le> x & x \<le> b --> (EX y. DERIV f x :> y & y > 0)"
  shows "f a < f b"
proof (rule ccontr)
  assume f: "~ f a < f b"
  have "EX l z. a < z & z < b & DERIV f z :> l
      & f b - f a = (b - a) * l"
    apply (rule MVT)
      using assms
      apply auto
      apply (metis DERIV_isCont)
     apply (metis differentiableI less_le)
    done
  then obtain l z where z: "a < z" "z < b" "DERIV f z :> l"
      and "f b - f a = (b - a) * l"
    by auto
  with assms f have "~(l > 0)"
    by (metis linorder_not_le mult_le_0_iff diff_le_0_iff_le)
  with assms z show False
    by (metis DERIV_unique less_le)
qed

lemma DERIV_nonneg_imp_nondecreasing:
  fixes a::real and b::real and f::"real => real"
  assumes "a \<le> b" and
    "\<forall>x. a \<le> x & x \<le> b --> (\<exists>y. DERIV f x :> y & y \<ge> 0)"
  shows "f a \<le> f b"
proof (rule ccontr, cases "a = b")
  assume "~ f a \<le> f b" and "a = b"
  then show False by auto
next
  assume A: "~ f a \<le> f b"
  assume B: "a ~= b"
  with assms have "EX l z. a < z & z < b & DERIV f z :> l
      & f b - f a = (b - a) * l"
    apply -
    apply (rule MVT)
      apply auto
      apply (metis DERIV_isCont)
     apply (metis differentiableI less_le)
    done
  then obtain l z where z: "a < z" "z < b" "DERIV f z :> l"
      and C: "f b - f a = (b - a) * l"
    by auto
  with A have "a < b" "f b < f a" by auto
  with C have "\<not> l \<ge> 0" by (auto simp add: not_le algebra_simps)
    (metis A add_le_cancel_right assms(1) less_eq_real_def mult_right_mono add_left_mono linear order_refl)
  with assms z show False
    by (metis DERIV_unique order_less_imp_le)
qed

lemma DERIV_neg_imp_decreasing:
  fixes a::real and b::real and f::"real => real"
  assumes "a < b" and
    "\<forall>x. a \<le> x & x \<le> b --> (\<exists>y. DERIV f x :> y & y < 0)"
  shows "f a > f b"
proof -
  have "(%x. -f x) a < (%x. -f x) b"
    apply (rule DERIV_pos_imp_increasing [of a b "%x. -f x"])
    using assms
    apply auto
    apply (metis DERIV_minus neg_0_less_iff_less)
    done
  thus ?thesis
    by simp
qed

lemma DERIV_nonpos_imp_nonincreasing:
  fixes a::real and b::real and f::"real => real"
  assumes "a \<le> b" and
    "\<forall>x. a \<le> x & x \<le> b --> (\<exists>y. DERIV f x :> y & y \<le> 0)"
  shows "f a \<ge> f b"
proof -
  have "(%x. -f x) a \<le> (%x. -f x) b"
    apply (rule DERIV_nonneg_imp_nondecreasing [of a b "%x. -f x"])
    using assms
    apply auto
    apply (metis DERIV_minus neg_0_le_iff_le)
    done
  thus ?thesis
    by simp
qed

text{*Continuity of inverse function*}

lemma isCont_inverse_function:
  fixes f g :: "real \<Rightarrow> real"
  assumes d: "0 < d"
      and inj: "\<forall>z. \<bar>z-x\<bar> \<le> d \<longrightarrow> g (f z) = z"
      and cont: "\<forall>z. \<bar>z-x\<bar> \<le> d \<longrightarrow> isCont f z"
  shows "isCont g (f x)"
proof -
  let ?A = "f (x - d)" and ?B = "f (x + d)" and ?D = "{x - d..x + d}"

  have f: "continuous_on ?D f"
    using cont by (intro continuous_at_imp_continuous_on ballI) auto
  then have g: "continuous_on (f`?D) g"
    using inj by (intro continuous_on_inv) auto

  from d f have "{min ?A ?B <..< max ?A ?B} \<subseteq> f ` ?D"
    by (intro connected_contains_Ioo connected_continuous_image) (auto split: split_min split_max)
  with g have "continuous_on {min ?A ?B <..< max ?A ?B} g"
    by (rule continuous_on_subset)
  moreover
  have "(?A < f x \<and> f x < ?B) \<or> (?B < f x \<and> f x < ?A)"
    using d inj by (intro continuous_inj_imp_mono[OF _ _ f] inj_on_imageI2[of g, OF inj_onI]) auto
  then have "f x \<in> {min ?A ?B <..< max ?A ?B}"
    by auto
  ultimately
  show ?thesis
    by (simp add: continuous_on_eq_continuous_at)
qed

lemma isCont_inverse_function2:
  fixes f g :: "real \<Rightarrow> real" shows
  "\<lbrakk>a < x; x < b;
    \<forall>z. a \<le> z \<and> z \<le> b \<longrightarrow> g (f z) = z;
    \<forall>z. a \<le> z \<and> z \<le> b \<longrightarrow> isCont f z\<rbrakk>
   \<Longrightarrow> isCont g (f x)"
apply (rule isCont_inverse_function
       [where f=f and d="min (x - a) (b - x)"])
apply (simp_all add: abs_le_iff)
done

text {* Derivative of inverse function *}

lemma DERIV_inverse_function:
  fixes f g :: "real \<Rightarrow> real"
  assumes der: "DERIV f (g x) :> D"
  assumes neq: "D \<noteq> 0"
  assumes a: "a < x" and b: "x < b"
  assumes inj: "\<forall>y. a < y \<and> y < b \<longrightarrow> f (g y) = y"
  assumes cont: "isCont g x"
  shows "DERIV g x :> inverse D"
unfolding DERIV_iff2
proof (rule LIM_equal2)
  show "0 < min (x - a) (b - x)"
    using a b by arith 
next
  fix y
  assume "norm (y - x) < min (x - a) (b - x)"
  hence "a < y" and "y < b" 
    by (simp_all add: abs_less_iff)
  thus "(g y - g x) / (y - x) =
        inverse ((f (g y) - x) / (g y - g x))"
    by (simp add: inj)
next
  have "(\<lambda>z. (f z - f (g x)) / (z - g x)) -- g x --> D"
    by (rule der [unfolded DERIV_iff2])
  hence 1: "(\<lambda>z. (f z - x) / (z - g x)) -- g x --> D"
    using inj a b by simp
  have 2: "\<exists>d>0. \<forall>y. y \<noteq> x \<and> norm (y - x) < d \<longrightarrow> g y \<noteq> g x"
  proof (safe intro!: exI)
    show "0 < min (x - a) (b - x)"
      using a b by simp
  next
    fix y
    assume "norm (y - x) < min (x - a) (b - x)"
    hence y: "a < y" "y < b"
      by (simp_all add: abs_less_iff)
    assume "g y = g x"
    hence "f (g y) = f (g x)" by simp
    hence "y = x" using inj y a b by simp
    also assume "y \<noteq> x"
    finally show False by simp
  qed
  have "(\<lambda>y. (f (g y) - x) / (g y - g x)) -- x --> D"
    using cont 1 2 by (rule isCont_LIM_compose2)
  thus "(\<lambda>y. inverse ((f (g y) - x) / (g y - g x)))
        -- x --> inverse D"
    using neq by (rule tendsto_inverse)
qed

subsection {* Generalized Mean Value Theorem *}

theorem GMVT:
  fixes a b :: real
  assumes alb: "a < b"
    and fc: "\<forall>x. a \<le> x \<and> x \<le> b \<longrightarrow> isCont f x"
    and fd: "\<forall>x. a < x \<and> x < b \<longrightarrow> f differentiable x"
    and gc: "\<forall>x. a \<le> x \<and> x \<le> b \<longrightarrow> isCont g x"
    and gd: "\<forall>x. a < x \<and> x < b \<longrightarrow> g differentiable x"
  shows "\<exists>g'c f'c c. DERIV g c :> g'c \<and> DERIV f c :> f'c \<and> a < c \<and> c < b \<and> ((f b - f a) * g'c) = ((g b - g a) * f'c)"
proof -
  let ?h = "\<lambda>x. (f b - f a)*(g x) - (g b - g a)*(f x)"
  from assms have "a < b" by simp
  moreover have "\<forall>x. a \<le> x \<and> x \<le> b \<longrightarrow> isCont ?h x"
    using fc gc by simp
  moreover have "\<forall>x. a < x \<and> x < b \<longrightarrow> ?h differentiable x"
    using fd gd by simp
  ultimately have "\<exists>l z. a < z \<and> z < b \<and> DERIV ?h z :> l \<and> ?h b - ?h a = (b - a) * l" by (rule MVT)
  then obtain l where ldef: "\<exists>z. a < z \<and> z < b \<and> DERIV ?h z :> l \<and> ?h b - ?h a = (b - a) * l" ..
  then obtain c where cdef: "a < c \<and> c < b \<and> DERIV ?h c :> l \<and> ?h b - ?h a = (b - a) * l" ..

  from cdef have cint: "a < c \<and> c < b" by auto
  with gd have "g differentiable c" by simp
  hence "\<exists>D. DERIV g c :> D" by (rule differentiableD)
  then obtain g'c where g'cdef: "DERIV g c :> g'c" ..

  from cdef have "a < c \<and> c < b" by auto
  with fd have "f differentiable c" by simp
  hence "\<exists>D. DERIV f c :> D" by (rule differentiableD)
  then obtain f'c where f'cdef: "DERIV f c :> f'c" ..

  from cdef have "DERIV ?h c :> l" by auto
  moreover have "DERIV ?h c :>  g'c * (f b - f a) - f'c * (g b - g a)"
    using g'cdef f'cdef by (auto intro!: DERIV_intros)
  ultimately have leq: "l =  g'c * (f b - f a) - f'c * (g b - g a)" by (rule DERIV_unique)

  {
    from cdef have "?h b - ?h a = (b - a) * l" by auto
    also with leq have "\<dots> = (b - a) * (g'c * (f b - f a) - f'c * (g b - g a))" by simp
    finally have "?h b - ?h a = (b - a) * (g'c * (f b - f a) - f'c * (g b - g a))" by simp
  }
  moreover
  {
    have "?h b - ?h a =
         ((f b)*(g b) - (f a)*(g b) - (g b)*(f b) + (g a)*(f b)) -
          ((f b)*(g a) - (f a)*(g a) - (g b)*(f a) + (g a)*(f a))"
      by (simp add: algebra_simps)
    hence "?h b - ?h a = 0" by auto
  }
  ultimately have "(b - a) * (g'c * (f b - f a) - f'c * (g b - g a)) = 0" by auto
  with alb have "g'c * (f b - f a) - f'c * (g b - g a) = 0" by simp
  hence "g'c * (f b - f a) = f'c * (g b - g a)" by simp
  hence "(f b - f a) * g'c = (g b - g a) * f'c" by (simp add: mult_ac)

  with g'cdef f'cdef cint show ?thesis by auto
qed


subsection {* Theorems about Limits *}

(* need to rename second isCont_inverse *)

lemma isCont_inv_fun:
  fixes f g :: "real \<Rightarrow> real"
  shows "[| 0 < d; \<forall>z. \<bar>z - x\<bar> \<le> d --> g(f(z)) = z;  
         \<forall>z. \<bar>z - x\<bar> \<le> d --> isCont f z |]  
      ==> isCont g (f x)"
by (rule isCont_inverse_function)

text{*Bartle/Sherbert: Introduction to Real Analysis, Theorem 4.2.9, p. 110*}
lemma LIM_fun_gt_zero:
     "[| f -- c --> (l::real); 0 < l |]  
         ==> \<exists>r. 0 < r & (\<forall>x::real. x \<noteq> c & \<bar>c - x\<bar> < r --> 0 < f x)"
apply (drule (1) LIM_D, clarify)
apply (rule_tac x = s in exI)
apply (simp add: abs_less_iff)
done

lemma LIM_fun_less_zero:
     "[| f -- c --> (l::real); l < 0 |]  
      ==> \<exists>r. 0 < r & (\<forall>x::real. x \<noteq> c & \<bar>c - x\<bar> < r --> f x < 0)"
apply (drule LIM_D [where r="-l"], simp, clarify)
apply (rule_tac x = s in exI)
apply (simp add: abs_less_iff)
done

lemma LIM_fun_not_zero:
     "[| f -- c --> (l::real); l \<noteq> 0 |] 
      ==> \<exists>r. 0 < r & (\<forall>x::real. x \<noteq> c & \<bar>c - x\<bar> < r --> f x \<noteq> 0)"
apply (rule linorder_cases [of l 0])
apply (drule (1) LIM_fun_less_zero, force)
apply simp
apply (drule (1) LIM_fun_gt_zero, force)
done

lemma GMVT':
  fixes f g :: "real \<Rightarrow> real"
  assumes "a < b"
  assumes isCont_f: "\<And>z. a \<le> z \<Longrightarrow> z \<le> b \<Longrightarrow> isCont f z"
  assumes isCont_g: "\<And>z. a \<le> z \<Longrightarrow> z \<le> b \<Longrightarrow> isCont g z"
  assumes DERIV_g: "\<And>z. a < z \<Longrightarrow> z < b \<Longrightarrow> DERIV g z :> (g' z)"
  assumes DERIV_f: "\<And>z. a < z \<Longrightarrow> z < b \<Longrightarrow> DERIV f z :> (f' z)"
  shows "\<exists>c. a < c \<and> c < b \<and> (f b - f a) * g' c = (g b - g a) * f' c"
proof -
  have "\<exists>g'c f'c c. DERIV g c :> g'c \<and> DERIV f c :> f'c \<and>
    a < c \<and> c < b \<and> (f b - f a) * g'c = (g b - g a) * f'c"
    using assms by (intro GMVT) (force simp: differentiable_def)+
  then obtain c where "a < c" "c < b" "(f b - f a) * g' c = (g b - g a) * f' c"
    using DERIV_f DERIV_g by (force dest: DERIV_unique)
  then show ?thesis
    by auto
qed

lemma DERIV_cong_ev: "x = y \<Longrightarrow> eventually (\<lambda>x. f x = g x) (nhds x) \<Longrightarrow> u = v \<Longrightarrow>
    DERIV f x :> u \<longleftrightarrow> DERIV g y :> v"
  unfolding DERIV_iff2
proof (rule filterlim_cong)
  assume "eventually (\<lambda>x. f x = g x) (nhds x)"
  moreover then have "f x = g x" by (auto simp: eventually_nhds)
  moreover assume "x = y" "u = v"
  ultimately show "eventually (\<lambda>xa. (f xa - f x) / (xa - x) = (g xa - g y) / (xa - y)) (at x)"
    by (auto simp: eventually_within at_def elim: eventually_elim1)
qed simp_all

lemma DERIV_shift:
  "(DERIV f (x + z) :> y) \<longleftrightarrow> (DERIV (\<lambda>x. f (x + z)) x :> y)"
  by (simp add: DERIV_iff field_simps)

lemma DERIV_mirror:
  "(DERIV f (- x) :> y) \<longleftrightarrow> (DERIV (\<lambda>x. f (- x::real) :: real) x :> - y)"
  by (simp add: deriv_def filterlim_at_split filterlim_at_left_to_right
                tendsto_minus_cancel_left field_simps conj_commute)

lemma lhopital_right_0:
  fixes f0 g0 :: "real \<Rightarrow> real"
  assumes f_0: "(f0 ---> 0) (at_right 0)"
  assumes g_0: "(g0 ---> 0) (at_right 0)"
  assumes ev:
    "eventually (\<lambda>x. g0 x \<noteq> 0) (at_right 0)"
    "eventually (\<lambda>x. g' x \<noteq> 0) (at_right 0)"
    "eventually (\<lambda>x. DERIV f0 x :> f' x) (at_right 0)"
    "eventually (\<lambda>x. DERIV g0 x :> g' x) (at_right 0)"
  assumes lim: "((\<lambda> x. (f' x / g' x)) ---> x) (at_right 0)"
  shows "((\<lambda> x. f0 x / g0 x) ---> x) (at_right 0)"
proof -
  def f \<equiv> "\<lambda>x. if x \<le> 0 then 0 else f0 x"
  then have "f 0 = 0" by simp

  def g \<equiv> "\<lambda>x. if x \<le> 0 then 0 else g0 x"
  then have "g 0 = 0" by simp

  have "eventually (\<lambda>x. g0 x \<noteq> 0 \<and> g' x \<noteq> 0 \<and>
      DERIV f0 x :> (f' x) \<and> DERIV g0 x :> (g' x)) (at_right 0)"
    using ev by eventually_elim auto
  then obtain a where [arith]: "0 < a"
    and g0_neq_0: "\<And>x. 0 < x \<Longrightarrow> x < a \<Longrightarrow> g0 x \<noteq> 0"
    and g'_neq_0: "\<And>x. 0 < x \<Longrightarrow> x < a \<Longrightarrow> g' x \<noteq> 0"
    and f0: "\<And>x. 0 < x \<Longrightarrow> x < a \<Longrightarrow> DERIV f0 x :> (f' x)"
    and g0: "\<And>x. 0 < x \<Longrightarrow> x < a \<Longrightarrow> DERIV g0 x :> (g' x)"
    unfolding eventually_within eventually_at by (auto simp: dist_real_def)

  have g_neq_0: "\<And>x. 0 < x \<Longrightarrow> x < a \<Longrightarrow> g x \<noteq> 0"
    using g0_neq_0 by (simp add: g_def)

  { fix x assume x: "0 < x" "x < a" then have "DERIV f x :> (f' x)"
      by (intro DERIV_cong_ev[THEN iffD1, OF _ _ _ f0[OF x]])
         (auto simp: f_def eventually_nhds_metric dist_real_def intro!: exI[of _ x]) }
  note f = this

  { fix x assume x: "0 < x" "x < a" then have "DERIV g x :> (g' x)"
      by (intro DERIV_cong_ev[THEN iffD1, OF _ _ _ g0[OF x]])
         (auto simp: g_def eventually_nhds_metric dist_real_def intro!: exI[of _ x]) }
  note g = this

  have "isCont f 0"
    using tendsto_const[of "0::real" "at 0"] f_0
    unfolding isCont_def f_def
    by (intro filterlim_split_at_real)
       (auto elim: eventually_elim1
             simp add: filterlim_def le_filter_def eventually_within eventually_filtermap)
    
  have "isCont g 0"
    using tendsto_const[of "0::real" "at 0"] g_0
    unfolding isCont_def g_def
    by (intro filterlim_split_at_real)
       (auto elim: eventually_elim1
             simp add: filterlim_def le_filter_def eventually_within eventually_filtermap)

  have "\<exists>\<zeta>. \<forall>x\<in>{0 <..< a}. 0 < \<zeta> x \<and> \<zeta> x < x \<and> f x / g x = f' (\<zeta> x) / g' (\<zeta> x)"
  proof (rule bchoice, rule)
    fix x assume "x \<in> {0 <..< a}"
    then have x[arith]: "0 < x" "x < a" by auto
    with g'_neq_0 g_neq_0 `g 0 = 0` have g': "\<And>x. 0 < x \<Longrightarrow> x < a  \<Longrightarrow> 0 \<noteq> g' x" "g 0 \<noteq> g x"
      by auto
    have "\<And>x. 0 \<le> x \<Longrightarrow> x < a \<Longrightarrow> isCont f x"
      using `isCont f 0` f by (auto intro: DERIV_isCont simp: le_less)
    moreover have "\<And>x. 0 \<le> x \<Longrightarrow> x < a \<Longrightarrow> isCont g x"
      using `isCont g 0` g by (auto intro: DERIV_isCont simp: le_less)
    ultimately have "\<exists>c. 0 < c \<and> c < x \<and> (f x - f 0) * g' c = (g x - g 0) * f' c"
      using f g `x < a` by (intro GMVT') auto
    then guess c ..
    moreover
    with g'(1)[of c] g'(2) have "(f x - f 0)  / (g x - g 0) = f' c / g' c"
      by (simp add: field_simps)
    ultimately show "\<exists>y. 0 < y \<and> y < x \<and> f x / g x = f' y / g' y"
      using `f 0 = 0` `g 0 = 0` by (auto intro!: exI[of _ c])
  qed
  then guess \<zeta> ..
  then have \<zeta>: "eventually (\<lambda>x. 0 < \<zeta> x \<and> \<zeta> x < x \<and> f x / g x = f' (\<zeta> x) / g' (\<zeta> x)) (at_right 0)"
    unfolding eventually_within eventually_at by (intro exI[of _ a]) (auto simp: dist_real_def)
  moreover
  from \<zeta> have "eventually (\<lambda>x. norm (\<zeta> x) \<le> x) (at_right 0)"
    by eventually_elim auto
  then have "((\<lambda>x. norm (\<zeta> x)) ---> 0) (at_right 0)"
    by (rule_tac real_tendsto_sandwich[where f="\<lambda>x. 0" and h="\<lambda>x. x"])
       (auto intro: tendsto_const tendsto_ident_at_within)
  then have "(\<zeta> ---> 0) (at_right 0)"
    by (rule tendsto_norm_zero_cancel)
  with \<zeta> have "filterlim \<zeta> (at_right 0) (at_right 0)"
    by (auto elim!: eventually_elim1 simp: filterlim_within filterlim_at)
  from this lim have "((\<lambda>t. f' (\<zeta> t) / g' (\<zeta> t)) ---> x) (at_right 0)"
    by (rule_tac filterlim_compose[of _ _ _ \<zeta>])
  ultimately have "((\<lambda>t. f t / g t) ---> x) (at_right 0)" (is ?P)
    by (rule_tac filterlim_cong[THEN iffD1, OF refl refl])
       (auto elim: eventually_elim1)
  also have "?P \<longleftrightarrow> ?thesis"
    by (rule filterlim_cong) (auto simp: f_def g_def eventually_within)
  finally show ?thesis .
qed

lemma lhopital_right:
  "((f::real \<Rightarrow> real) ---> 0) (at_right x) \<Longrightarrow> (g ---> 0) (at_right x) \<Longrightarrow>
    eventually (\<lambda>x. g x \<noteq> 0) (at_right x) \<Longrightarrow>
    eventually (\<lambda>x. g' x \<noteq> 0) (at_right x) \<Longrightarrow>
    eventually (\<lambda>x. DERIV f x :> f' x) (at_right x) \<Longrightarrow>
    eventually (\<lambda>x. DERIV g x :> g' x) (at_right x) \<Longrightarrow>
    ((\<lambda> x. (f' x / g' x)) ---> y) (at_right x) \<Longrightarrow>
  ((\<lambda> x. f x / g x) ---> y) (at_right x)"
  unfolding eventually_at_right_to_0[of _ x] filterlim_at_right_to_0[of _ _ x] DERIV_shift
  by (rule lhopital_right_0)

lemma lhopital_left:
  "((f::real \<Rightarrow> real) ---> 0) (at_left x) \<Longrightarrow> (g ---> 0) (at_left x) \<Longrightarrow>
    eventually (\<lambda>x. g x \<noteq> 0) (at_left x) \<Longrightarrow>
    eventually (\<lambda>x. g' x \<noteq> 0) (at_left x) \<Longrightarrow>
    eventually (\<lambda>x. DERIV f x :> f' x) (at_left x) \<Longrightarrow>
    eventually (\<lambda>x. DERIV g x :> g' x) (at_left x) \<Longrightarrow>
    ((\<lambda> x. (f' x / g' x)) ---> y) (at_left x) \<Longrightarrow>
  ((\<lambda> x. f x / g x) ---> y) (at_left x)"
  unfolding eventually_at_left_to_right filterlim_at_left_to_right DERIV_mirror
  by (rule lhopital_right[where f'="\<lambda>x. - f' (- x)"]) (auto simp: DERIV_mirror)

lemma lhopital:
  "((f::real \<Rightarrow> real) ---> 0) (at x) \<Longrightarrow> (g ---> 0) (at x) \<Longrightarrow>
    eventually (\<lambda>x. g x \<noteq> 0) (at x) \<Longrightarrow>
    eventually (\<lambda>x. g' x \<noteq> 0) (at x) \<Longrightarrow>
    eventually (\<lambda>x. DERIV f x :> f' x) (at x) \<Longrightarrow>
    eventually (\<lambda>x. DERIV g x :> g' x) (at x) \<Longrightarrow>
    ((\<lambda> x. (f' x / g' x)) ---> y) (at x) \<Longrightarrow>
  ((\<lambda> x. f x / g x) ---> y) (at x)"
  unfolding eventually_at_split filterlim_at_split
  by (auto intro!: lhopital_right[of f x g g' f'] lhopital_left[of f x g g' f'])

lemma lhopital_right_0_at_top:
  fixes f g :: "real \<Rightarrow> real"
  assumes g_0: "LIM x at_right 0. g x :> at_top"
  assumes ev:
    "eventually (\<lambda>x. g' x \<noteq> 0) (at_right 0)"
    "eventually (\<lambda>x. DERIV f x :> f' x) (at_right 0)"
    "eventually (\<lambda>x. DERIV g x :> g' x) (at_right 0)"
  assumes lim: "((\<lambda> x. (f' x / g' x)) ---> x) (at_right 0)"
  shows "((\<lambda> x. f x / g x) ---> x) (at_right 0)"
  unfolding tendsto_iff
proof safe
  fix e :: real assume "0 < e"

  with lim[unfolded tendsto_iff, rule_format, of "e / 4"]
  have "eventually (\<lambda>t. dist (f' t / g' t) x < e / 4) (at_right 0)" by simp
  from eventually_conj[OF eventually_conj[OF ev(1) ev(2)] eventually_conj[OF ev(3) this]]
  obtain a where [arith]: "0 < a"
    and g'_neq_0: "\<And>x. 0 < x \<Longrightarrow> x < a \<Longrightarrow> g' x \<noteq> 0"
    and f0: "\<And>x. 0 < x \<Longrightarrow> x \<le> a \<Longrightarrow> DERIV f x :> (f' x)"
    and g0: "\<And>x. 0 < x \<Longrightarrow> x \<le> a \<Longrightarrow> DERIV g x :> (g' x)"
    and Df: "\<And>t. 0 < t \<Longrightarrow> t < a \<Longrightarrow> dist (f' t / g' t) x < e / 4"
    unfolding eventually_within_le by (auto simp: dist_real_def)

  from Df have
    "eventually (\<lambda>t. t < a) (at_right 0)" "eventually (\<lambda>t::real. 0 < t) (at_right 0)"
    unfolding eventually_within eventually_at by (auto intro!: exI[of _ a] simp: dist_real_def)

  moreover
  have "eventually (\<lambda>t. 0 < g t) (at_right 0)" "eventually (\<lambda>t. g a < g t) (at_right 0)"
    using g_0 by (auto elim: eventually_elim1 simp: filterlim_at_top_dense)

  moreover
  have inv_g: "((\<lambda>x. inverse (g x)) ---> 0) (at_right 0)"
    using tendsto_inverse_0 filterlim_mono[OF g_0 at_top_le_at_infinity order_refl]
    by (rule filterlim_compose)
  then have "((\<lambda>x. norm (1 - g a * inverse (g x))) ---> norm (1 - g a * 0)) (at_right 0)"
    by (intro tendsto_intros)
  then have "((\<lambda>x. norm (1 - g a / g x)) ---> 1) (at_right 0)"
    by (simp add: inverse_eq_divide)
  from this[unfolded tendsto_iff, rule_format, of 1]
  have "eventually (\<lambda>x. norm (1 - g a / g x) < 2) (at_right 0)"
    by (auto elim!: eventually_elim1 simp: dist_real_def)

  moreover
  from inv_g have "((\<lambda>t. norm ((f a - x * g a) * inverse (g t))) ---> norm ((f a - x * g a) * 0)) (at_right 0)"
    by (intro tendsto_intros)
  then have "((\<lambda>t. norm (f a - x * g a) / norm (g t)) ---> 0) (at_right 0)"
    by (simp add: inverse_eq_divide)
  from this[unfolded tendsto_iff, rule_format, of "e / 2"] `0 < e`
  have "eventually (\<lambda>t. norm (f a - x * g a) / norm (g t) < e / 2) (at_right 0)"
    by (auto simp: dist_real_def)

  ultimately show "eventually (\<lambda>t. dist (f t / g t) x < e) (at_right 0)"
  proof eventually_elim
    fix t assume t[arith]: "0 < t" "t < a" "g a < g t" "0 < g t"
    assume ineq: "norm (1 - g a / g t) < 2" "norm (f a - x * g a) / norm (g t) < e / 2"

    have "\<exists>y. t < y \<and> y < a \<and> (g a - g t) * f' y = (f a - f t) * g' y"
      using f0 g0 t(1,2) by (intro GMVT') (force intro!: DERIV_isCont)+
    then guess y ..
    from this
    have [arith]: "t < y" "y < a" and D_eq: "(f t - f a) / (g t - g a) = f' y / g' y"
      using `g a < g t` g'_neq_0[of y] by (auto simp add: field_simps)

    have *: "f t / g t - x = ((f t - f a) / (g t - g a) - x) * (1 - g a / g t) + (f a - x * g a) / g t"
      by (simp add: field_simps)
    have "norm (f t / g t - x) \<le>
        norm (((f t - f a) / (g t - g a) - x) * (1 - g a / g t)) + norm ((f a - x * g a) / g t)"
      unfolding * by (rule norm_triangle_ineq)
    also have "\<dots> = dist (f' y / g' y) x * norm (1 - g a / g t) + norm (f a - x * g a) / norm (g t)"
      by (simp add: abs_mult D_eq dist_real_def)
    also have "\<dots> < (e / 4) * 2 + e / 2"
      using ineq Df[of y] `0 < e` by (intro add_le_less_mono mult_mono) auto
    finally show "dist (f t / g t) x < e"
      by (simp add: dist_real_def)
  qed
qed

lemma lhopital_right_at_top:
  "LIM x at_right x. (g::real \<Rightarrow> real) x :> at_top \<Longrightarrow>
    eventually (\<lambda>x. g' x \<noteq> 0) (at_right x) \<Longrightarrow>
    eventually (\<lambda>x. DERIV f x :> f' x) (at_right x) \<Longrightarrow>
    eventually (\<lambda>x. DERIV g x :> g' x) (at_right x) \<Longrightarrow>
    ((\<lambda> x. (f' x / g' x)) ---> y) (at_right x) \<Longrightarrow>
    ((\<lambda> x. f x / g x) ---> y) (at_right x)"
  unfolding eventually_at_right_to_0[of _ x] filterlim_at_right_to_0[of _ _ x] DERIV_shift
  by (rule lhopital_right_0_at_top)

lemma lhopital_left_at_top:
  "LIM x at_left x. (g::real \<Rightarrow> real) x :> at_top \<Longrightarrow>
    eventually (\<lambda>x. g' x \<noteq> 0) (at_left x) \<Longrightarrow>
    eventually (\<lambda>x. DERIV f x :> f' x) (at_left x) \<Longrightarrow>
    eventually (\<lambda>x. DERIV g x :> g' x) (at_left x) \<Longrightarrow>
    ((\<lambda> x. (f' x / g' x)) ---> y) (at_left x) \<Longrightarrow>
    ((\<lambda> x. f x / g x) ---> y) (at_left x)"
  unfolding eventually_at_left_to_right filterlim_at_left_to_right DERIV_mirror
  by (rule lhopital_right_at_top[where f'="\<lambda>x. - f' (- x)"]) (auto simp: DERIV_mirror)

lemma lhopital_at_top:
  "LIM x at x. (g::real \<Rightarrow> real) x :> at_top \<Longrightarrow>
    eventually (\<lambda>x. g' x \<noteq> 0) (at x) \<Longrightarrow>
    eventually (\<lambda>x. DERIV f x :> f' x) (at x) \<Longrightarrow>
    eventually (\<lambda>x. DERIV g x :> g' x) (at x) \<Longrightarrow>
    ((\<lambda> x. (f' x / g' x)) ---> y) (at x) \<Longrightarrow>
    ((\<lambda> x. f x / g x) ---> y) (at x)"
  unfolding eventually_at_split filterlim_at_split
  by (auto intro!: lhopital_right_at_top[of g x g' f f'] lhopital_left_at_top[of g x g' f f'])

lemma lhospital_at_top_at_top:
  fixes f g :: "real \<Rightarrow> real"
  assumes g_0: "LIM x at_top. g x :> at_top"
  assumes g': "eventually (\<lambda>x. g' x \<noteq> 0) at_top"
  assumes Df: "eventually (\<lambda>x. DERIV f x :> f' x) at_top"
  assumes Dg: "eventually (\<lambda>x. DERIV g x :> g' x) at_top"
  assumes lim: "((\<lambda> x. (f' x / g' x)) ---> x) at_top"
  shows "((\<lambda> x. f x / g x) ---> x) at_top"
  unfolding filterlim_at_top_to_right
proof (rule lhopital_right_0_at_top)
  let ?F = "\<lambda>x. f (inverse x)"
  let ?G = "\<lambda>x. g (inverse x)"
  let ?R = "at_right (0::real)"
  let ?D = "\<lambda>f' x. f' (inverse x) * - (inverse x ^ Suc (Suc 0))"

  show "LIM x ?R. ?G x :> at_top"
    using g_0 unfolding filterlim_at_top_to_right .

  show "eventually (\<lambda>x. DERIV ?G x  :> ?D g' x) ?R"
    unfolding eventually_at_right_to_top
    using Dg eventually_ge_at_top[where c="1::real"]
    apply eventually_elim
    apply (rule DERIV_cong)
    apply (rule DERIV_chain'[where f=inverse])
    apply (auto intro!:  DERIV_inverse)
    done

  show "eventually (\<lambda>x. DERIV ?F x  :> ?D f' x) ?R"
    unfolding eventually_at_right_to_top
    using Df eventually_ge_at_top[where c="1::real"]
    apply eventually_elim
    apply (rule DERIV_cong)
    apply (rule DERIV_chain'[where f=inverse])
    apply (auto intro!:  DERIV_inverse)
    done

  show "eventually (\<lambda>x. ?D g' x \<noteq> 0) ?R"
    unfolding eventually_at_right_to_top
    using g' eventually_ge_at_top[where c="1::real"]
    by eventually_elim auto
    
  show "((\<lambda>x. ?D f' x / ?D g' x) ---> x) ?R"
    unfolding filterlim_at_right_to_top
    apply (intro filterlim_cong[THEN iffD2, OF refl refl _ lim])
    using eventually_ge_at_top[where c="1::real"]
    by eventually_elim simp
qed

end

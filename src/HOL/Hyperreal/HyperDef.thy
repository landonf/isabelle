(*  Title       : HOL/Hyperreal/HyperDef.thy
    ID          : $Id$
    Author      : Jacques D. Fleuriot
    Copyright   : 1998  University of Cambridge
    Conversion to Isar and new proofs by Lawrence C Paulson, 2004
*)

header{*Construction of Hyperreals Using Ultrafilters*}

theory HyperDef
imports StarClasses "../Real/Real"
begin

types hypreal = "real star"

abbreviation
  hypreal_of_real :: "real => real star" where
  "hypreal_of_real == star_of"

definition
  omega :: hypreal where
   -- {*an infinite number @{text "= [<1,2,3,...>]"} *}
  "omega = star_n (\<lambda>n. real (Suc n))"

definition
  epsilon :: hypreal where
   -- {*an infinitesimal number @{text "= [<1,1/2,1/3,...>]"} *}
  "epsilon = star_n (\<lambda>n. inverse (real (Suc n)))"

notation (xsymbols)
  omega  ("\<omega>") and
  epsilon  ("\<epsilon>")

notation (HTML output)
  omega  ("\<omega>") and
  epsilon  ("\<epsilon>")


subsection {* Real vector class instances *}

instance star :: (scaleR) scaleR ..

defs (overloaded)
  star_scaleR_def [transfer_unfold]: "scaleR r \<equiv> *f* (scaleR r)"

lemma Standard_scaleR [simp]: "x \<in> Standard \<Longrightarrow> scaleR r x \<in> Standard"
by (simp add: star_scaleR_def)

lemma star_of_scaleR [simp]: "star_of (scaleR r x) = scaleR r (star_of x)"
by transfer (rule refl)

instance star :: (real_vector) real_vector
proof
  fix a b :: real
  show "\<And>x y::'a star. scaleR a (x + y) = scaleR a x + scaleR a y"
    by transfer (rule scaleR_right_distrib)
  show "\<And>x::'a star. scaleR (a + b) x = scaleR a x + scaleR b x"
    by transfer (rule scaleR_left_distrib)
  show "\<And>x::'a star. scaleR a (scaleR b x) = scaleR (a * b) x"
    by transfer (rule scaleR_scaleR)
  show "\<And>x::'a star. scaleR 1 x = x"
    by transfer (rule scaleR_one)
qed

instance star :: (real_algebra) real_algebra
proof
  fix a :: real
  show "\<And>x y::'a star. scaleR a x * y = scaleR a (x * y)"
    by transfer (rule mult_scaleR_left)
  show "\<And>x y::'a star. x * scaleR a y = scaleR a (x * y)"
    by transfer (rule mult_scaleR_right)
qed

instance star :: (real_algebra_1) real_algebra_1 ..

instance star :: (real_div_algebra) real_div_algebra ..

instance star :: (real_field) real_field ..

lemma star_of_real_def [transfer_unfold]: "of_real r = star_of (of_real r)"
by (unfold of_real_def, transfer, rule refl)

lemma Standard_of_real [simp]: "of_real r \<in> Standard"
by (simp add: star_of_real_def)

lemma star_of_of_real [simp]: "star_of (of_real r) = of_real r"
by transfer (rule refl)

lemma of_real_eq_star_of [simp]: "of_real = star_of"
proof
  fix r :: real
  show "of_real r = star_of r"
    by transfer simp
qed

lemma Reals_eq_Standard: "(Reals :: hypreal set) = Standard"
by (simp add: Reals_def Standard_def)


subsection{*Properties of @{term starrel}*}

lemma lemma_starrel_refl [simp]: "x \<in> starrel `` {x}"
by (simp add: starrel_def)

lemma starrel_in_hypreal [simp]: "starrel``{x}:star"
by (simp add: star_def starrel_def quotient_def, blast)

declare Abs_star_inject [simp] Abs_star_inverse [simp]
declare equiv_starrel [THEN eq_equiv_class_iff, simp]

subsection{*@{term hypreal_of_real}: 
            the Injection from @{typ real} to @{typ hypreal}*}

lemma inj_star_of: "inj star_of"
by (rule inj_onI, simp)

lemma mem_Rep_star_iff: "(X \<in> Rep_star x) = (x = star_n X)"
by (cases x, simp add: star_n_def)

lemma Rep_star_star_n_iff [simp]:
  "(X \<in> Rep_star (star_n Y)) = ({n. Y n = X n} \<in> \<U>)"
by (simp add: star_n_def)

lemma Rep_star_star_n: "X \<in> Rep_star (star_n X)"
by simp

subsection{* Properties of @{term star_n} *}

lemma star_n_add:
  "star_n X + star_n Y = star_n (%n. X n + Y n)"
by (simp only: star_add_def starfun2_star_n)

lemma star_n_minus:
   "- star_n X = star_n (%n. -(X n))"
by (simp only: star_minus_def starfun_star_n)

lemma star_n_diff:
     "star_n X - star_n Y = star_n (%n. X n - Y n)"
by (simp only: star_diff_def starfun2_star_n)

lemma star_n_mult:
  "star_n X * star_n Y = star_n (%n. X n * Y n)"
by (simp only: star_mult_def starfun2_star_n)

lemma star_n_inverse:
      "inverse (star_n X) = star_n (%n. inverse(X n))"
by (simp only: star_inverse_def starfun_star_n)

lemma star_n_le:
      "star_n X \<le> star_n Y =  
       ({n. X n \<le> Y n} \<in> FreeUltrafilterNat)"
by (simp only: star_le_def starP2_star_n)

lemma star_n_less:
      "star_n X < star_n Y = ({n. X n < Y n} \<in> FreeUltrafilterNat)"
by (simp only: star_less_def starP2_star_n)

lemma star_n_zero_num: "0 = star_n (%n. 0)"
by (simp only: star_zero_def star_of_def)

lemma star_n_one_num: "1 = star_n (%n. 1)"
by (simp only: star_one_def star_of_def)

lemma star_n_abs:
     "abs (star_n X) = star_n (%n. abs (X n))"
by (simp only: star_abs_def starfun_star_n)

subsection{*Misc Others*}

lemma hypreal_not_refl2: "!!(x::hypreal). x < y ==> x \<noteq> y"
by (auto)

lemma hypreal_eq_minus_iff: "((x::hypreal) = y) = (x + - y = 0)"
by auto

lemma hypreal_mult_left_cancel: "(c::hypreal) \<noteq> 0 ==> (c*a=c*b) = (a=b)"
by auto
    
lemma hypreal_mult_right_cancel: "(c::hypreal) \<noteq> 0 ==> (a*c=b*c) = (a=b)"
by auto

lemma hypreal_omega_gt_zero [simp]: "0 < omega"
by (simp add: omega_def star_n_zero_num star_n_less)

subsection{*Existence of Infinite Hyperreal Number*}

text{*Existence of infinite number not corresponding to any real number.
Use assumption that member @{term FreeUltrafilterNat} is not finite.*}


text{*A few lemmas first*}

lemma lemma_omega_empty_singleton_disj: "{n::nat. x = real n} = {} |  
      (\<exists>y. {n::nat. x = real n} = {y})"
by force

lemma lemma_finite_omega_set: "finite {n::nat. x = real n}"
by (cut_tac x = x in lemma_omega_empty_singleton_disj, auto)

lemma not_ex_hypreal_of_real_eq_omega: 
      "~ (\<exists>x. hypreal_of_real x = omega)"
apply (simp add: omega_def)
apply (simp add: star_of_def star_n_eq_iff)
apply (auto simp add: real_of_nat_Suc diff_eq_eq [symmetric] 
            lemma_finite_omega_set [THEN FreeUltrafilterNat.finite])
done

lemma hypreal_of_real_not_eq_omega: "hypreal_of_real x \<noteq> omega"
by (insert not_ex_hypreal_of_real_eq_omega, auto)

text{*Existence of infinitesimal number also not corresponding to any
 real number*}

lemma lemma_epsilon_empty_singleton_disj:
     "{n::nat. x = inverse(real(Suc n))} = {} |  
      (\<exists>y. {n::nat. x = inverse(real(Suc n))} = {y})"
by auto

lemma lemma_finite_epsilon_set: "finite {n. x = inverse(real(Suc n))}"
by (cut_tac x = x in lemma_epsilon_empty_singleton_disj, auto)

lemma not_ex_hypreal_of_real_eq_epsilon: "~ (\<exists>x. hypreal_of_real x = epsilon)"
by (auto simp add: epsilon_def star_of_def star_n_eq_iff
                   lemma_finite_epsilon_set [THEN FreeUltrafilterNat.finite])

lemma hypreal_of_real_not_eq_epsilon: "hypreal_of_real x \<noteq> epsilon"
by (insert not_ex_hypreal_of_real_eq_epsilon, auto)

lemma hypreal_epsilon_not_zero: "epsilon \<noteq> 0"
by (simp add: epsilon_def star_zero_def star_of_def star_n_eq_iff
         del: star_of_zero)

lemma hypreal_epsilon_inverse_omega: "epsilon = inverse(omega)"
by (simp add: epsilon_def omega_def star_n_inverse)

lemma hypreal_epsilon_gt_zero: "0 < epsilon"
by (simp add: hypreal_epsilon_inverse_omega)

end

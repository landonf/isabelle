(*  Title       : Real/RealDef.thy
    ID          : $Id$
    Author      : Jacques D. Fleuriot
    Copyright   : 1998  University of Cambridge
    Conversion to Isar and new proofs by Lawrence C Paulson, 2003/4
    Additional contributions by Jeremy Avigad
*)

header{*Defining the Reals from the Positive Reals*}

theory RealDef
imports PReal
uses ("real_arith.ML")
begin

definition
  realrel   ::  "((preal * preal) * (preal * preal)) set" where
  "realrel = {p. \<exists>x1 y1 x2 y2. p = ((x1,y1),(x2,y2)) & x1+y2 = x2+y1}"

typedef (Real)  real = "UNIV//realrel"
  by (auto simp add: quotient_def)

instance real :: "{ord, zero, one, plus, times, minus, inverse}" ..

definition

  (** these don't use the overloaded "real" function: users don't see them **)

  real_of_preal :: "preal => real" where
  "real_of_preal m = Abs_Real(realrel``{(m + 1, 1)})"

consts
   (*overloaded constant for injecting other types into "real"*)
   real :: "'a => real"


defs (overloaded)

  real_zero_def:
  "0 == Abs_Real(realrel``{(1, 1)})"

  real_one_def:
  "1 == Abs_Real(realrel``{(1 + 1, 1)})"

  real_minus_def:
  "- r ==  contents (\<Union>(x,y) \<in> Rep_Real(r). { Abs_Real(realrel``{(y,x)}) })"

  real_add_def:
   "z + w ==
       contents (\<Union>(x,y) \<in> Rep_Real(z). \<Union>(u,v) \<in> Rep_Real(w).
		 { Abs_Real(realrel``{(x+u, y+v)}) })"

  real_diff_def:
   "r - (s::real) == r + - s"

  real_mult_def:
    "z * w ==
       contents (\<Union>(x,y) \<in> Rep_Real(z). \<Union>(u,v) \<in> Rep_Real(w).
		 { Abs_Real(realrel``{(x*u + y*v, x*v + y*u)}) })"

  real_inverse_def:
  "inverse (R::real) == (THE S. (R = 0 & S = 0) | S * R = 1)"

  real_divide_def:
  "R / (S::real) == R * inverse S"

  real_le_def:
   "z \<le> (w::real) == 
    \<exists>x y u v. x+v \<le> u+y & (x,y) \<in> Rep_Real z & (u,v) \<in> Rep_Real w"

  real_less_def: "(x < (y::real)) == (x \<le> y & x \<noteq> y)"

  real_abs_def:  "abs (r::real) == (if r < 0 then - r else r)"


subsection {* Equivalence relation over positive reals *}

lemma preal_trans_lemma:
  assumes "x + y1 = x1 + y"
      and "x + y2 = x2 + y"
  shows "x1 + y2 = x2 + (y1::preal)"
proof -
  have "(x1 + y2) + x = (x + y2) + x1" by (simp add: add_ac)
  also have "... = (x2 + y) + x1"  by (simp add: prems)
  also have "... = x2 + (x1 + y)"  by (simp add: add_ac)
  also have "... = x2 + (x + y1)"  by (simp add: prems)
  also have "... = (x2 + y1) + x"  by (simp add: add_ac)
  finally have "(x1 + y2) + x = (x2 + y1) + x" .
  thus ?thesis by (rule add_right_imp_eq)
qed


lemma realrel_iff [simp]: "(((x1,y1),(x2,y2)) \<in> realrel) = (x1 + y2 = x2 + y1)"
by (simp add: realrel_def)

lemma equiv_realrel: "equiv UNIV realrel"
apply (auto simp add: equiv_def refl_def sym_def trans_def realrel_def)
apply (blast dest: preal_trans_lemma) 
done

text{*Reduces equality of equivalence classes to the @{term realrel} relation:
  @{term "(realrel `` {x} = realrel `` {y}) = ((x,y) \<in> realrel)"} *}
lemmas equiv_realrel_iff = 
       eq_equiv_class_iff [OF equiv_realrel UNIV_I UNIV_I]

declare equiv_realrel_iff [simp]


lemma realrel_in_real [simp]: "realrel``{(x,y)}: Real"
by (simp add: Real_def realrel_def quotient_def, blast)

declare Abs_Real_inject [simp]
declare Abs_Real_inverse [simp]


text{*Case analysis on the representation of a real number as an equivalence
      class of pairs of positive reals.*}
lemma eq_Abs_Real [case_names Abs_Real, cases type: real]: 
     "(!!x y. z = Abs_Real(realrel``{(x,y)}) ==> P) ==> P"
apply (rule Rep_Real [of z, unfolded Real_def, THEN quotientE])
apply (drule arg_cong [where f=Abs_Real])
apply (auto simp add: Rep_Real_inverse)
done


subsection {* Addition and Subtraction *}

lemma real_add_congruent2_lemma:
     "[|a + ba = aa + b; ab + bc = ac + bb|]
      ==> a + ab + (ba + bc) = aa + ac + (b + (bb::preal))"
apply (simp add: add_assoc)
apply (rule add_left_commute [of ab, THEN ssubst])
apply (simp add: add_assoc [symmetric])
apply (simp add: add_ac)
done

lemma real_add:
     "Abs_Real (realrel``{(x,y)}) + Abs_Real (realrel``{(u,v)}) =
      Abs_Real (realrel``{(x+u, y+v)})"
proof -
  have "(\<lambda>z w. (\<lambda>(x,y). (\<lambda>(u,v). {Abs_Real (realrel `` {(x+u, y+v)})}) w) z)
        respects2 realrel"
    by (simp add: congruent2_def, blast intro: real_add_congruent2_lemma) 
  thus ?thesis
    by (simp add: real_add_def UN_UN_split_split_eq
                  UN_equiv_class2 [OF equiv_realrel equiv_realrel])
qed

lemma real_minus: "- Abs_Real(realrel``{(x,y)}) = Abs_Real(realrel `` {(y,x)})"
proof -
  have "(\<lambda>(x,y). {Abs_Real (realrel``{(y,x)})}) respects realrel"
    by (simp add: congruent_def add_commute) 
  thus ?thesis
    by (simp add: real_minus_def UN_equiv_class [OF equiv_realrel])
qed

instance real :: ab_group_add
proof
  fix x y z :: real
  show "(x + y) + z = x + (y + z)"
    by (cases x, cases y, cases z, simp add: real_add add_assoc)
  show "x + y = y + x"
    by (cases x, cases y, simp add: real_add add_commute)
  show "0 + x = x"
    by (cases x, simp add: real_add real_zero_def add_ac)
  show "- x + x = 0"
    by (cases x, simp add: real_minus real_add real_zero_def add_commute)
  show "x - y = x + - y"
    by (simp add: real_diff_def)
qed


subsection {* Multiplication *}

lemma real_mult_congruent2_lemma:
     "!!(x1::preal). [| x1 + y2 = x2 + y1 |] ==>
          x * x1 + y * y1 + (x * y2 + y * x2) =
          x * x2 + y * y2 + (x * y1 + y * x1)"
apply (simp add: add_left_commute add_assoc [symmetric])
apply (simp add: add_assoc right_distrib [symmetric])
apply (simp add: add_commute)
done

lemma real_mult_congruent2:
    "(%p1 p2.
        (%(x1,y1). (%(x2,y2). 
          { Abs_Real (realrel``{(x1*x2 + y1*y2, x1*y2+y1*x2)}) }) p2) p1)
     respects2 realrel"
apply (rule congruent2_commuteI [OF equiv_realrel], clarify)
apply (simp add: mult_commute add_commute)
apply (auto simp add: real_mult_congruent2_lemma)
done

lemma real_mult:
      "Abs_Real((realrel``{(x1,y1)})) * Abs_Real((realrel``{(x2,y2)})) =
       Abs_Real(realrel `` {(x1*x2+y1*y2,x1*y2+y1*x2)})"
by (simp add: real_mult_def UN_UN_split_split_eq
         UN_equiv_class2 [OF equiv_realrel equiv_realrel real_mult_congruent2])

lemma real_mult_commute: "(z::real) * w = w * z"
by (cases z, cases w, simp add: real_mult add_ac mult_ac)

lemma real_mult_assoc: "((z1::real) * z2) * z3 = z1 * (z2 * z3)"
apply (cases z1, cases z2, cases z3)
apply (simp add: real_mult right_distrib add_ac mult_ac)
done

lemma real_mult_1: "(1::real) * z = z"
apply (cases z)
apply (simp add: real_mult real_one_def right_distrib
                  mult_1_right mult_ac add_ac)
done

lemma real_add_mult_distrib: "((z1::real) + z2) * w = (z1 * w) + (z2 * w)"
apply (cases z1, cases z2, cases w)
apply (simp add: real_add real_mult right_distrib add_ac mult_ac)
done

text{*one and zero are distinct*}
lemma real_zero_not_eq_one: "0 \<noteq> (1::real)"
proof -
  have "(1::preal) < 1 + 1"
    by (simp add: preal_self_less_add_left)
  thus ?thesis
    by (simp add: real_zero_def real_one_def)
qed

instance real :: comm_ring_1
proof
  fix x y z :: real
  show "(x * y) * z = x * (y * z)" by (rule real_mult_assoc)
  show "x * y = y * x" by (rule real_mult_commute)
  show "1 * x = x" by (rule real_mult_1)
  show "(x + y) * z = x * z + y * z" by (rule real_add_mult_distrib)
  show "0 \<noteq> (1::real)" by (rule real_zero_not_eq_one)
qed

subsection {* Inverse and Division *}

lemma real_zero_iff: "Abs_Real (realrel `` {(x, x)}) = 0"
by (simp add: real_zero_def add_commute)

text{*Instead of using an existential quantifier and constructing the inverse
within the proof, we could define the inverse explicitly.*}

lemma real_mult_inverse_left_ex: "x \<noteq> 0 ==> \<exists>y. y*x = (1::real)"
apply (simp add: real_zero_def real_one_def, cases x)
apply (cut_tac x = xa and y = y in linorder_less_linear)
apply (auto dest!: less_add_left_Ex simp add: real_zero_iff)
apply (rule_tac
        x = "Abs_Real (realrel``{(1, inverse (D) + 1)})"
       in exI)
apply (rule_tac [2]
        x = "Abs_Real (realrel``{(inverse (D) + 1, 1)})" 
       in exI)
apply (auto simp add: real_mult preal_mult_inverse_right ring_simps)
done

lemma real_mult_inverse_left: "x \<noteq> 0 ==> inverse(x)*x = (1::real)"
apply (simp add: real_inverse_def)
apply (drule real_mult_inverse_left_ex, safe)
apply (rule theI, assumption, rename_tac z)
apply (subgoal_tac "(z * x) * y = z * (x * y)")
apply (simp add: mult_commute)
apply (rule mult_assoc)
done


subsection{*The Real Numbers form a Field*}

instance real :: field
proof
  fix x y z :: real
  show "x \<noteq> 0 ==> inverse x * x = 1" by (rule real_mult_inverse_left)
  show "x / y = x * inverse y" by (simp add: real_divide_def)
qed


text{*Inverse of zero!  Useful to simplify certain equations*}

lemma INVERSE_ZERO: "inverse 0 = (0::real)"
by (simp add: real_inverse_def)

instance real :: division_by_zero
proof
  show "inverse 0 = (0::real)" by (rule INVERSE_ZERO)
qed


subsection{*The @{text "\<le>"} Ordering*}

lemma real_le_refl: "w \<le> (w::real)"
by (cases w, force simp add: real_le_def)

text{*The arithmetic decision procedure is not set up for type preal.
  This lemma is currently unused, but it could simplify the proofs of the
  following two lemmas.*}
lemma preal_eq_le_imp_le:
  assumes eq: "a+b = c+d" and le: "c \<le> a"
  shows "b \<le> (d::preal)"
proof -
  have "c+d \<le> a+d" by (simp add: prems)
  hence "a+b \<le> a+d" by (simp add: prems)
  thus "b \<le> d" by simp
qed

lemma real_le_lemma:
  assumes l: "u1 + v2 \<le> u2 + v1"
      and "x1 + v1 = u1 + y1"
      and "x2 + v2 = u2 + y2"
  shows "x1 + y2 \<le> x2 + (y1::preal)"
proof -
  have "(x1+v1) + (u2+y2) = (u1+y1) + (x2+v2)" by (simp add: prems)
  hence "(x1+y2) + (u2+v1) = (x2+y1) + (u1+v2)" by (simp add: add_ac)
  also have "... \<le> (x2+y1) + (u2+v1)" by (simp add: prems)
  finally show ?thesis by simp
qed

lemma real_le: 
     "(Abs_Real(realrel``{(x1,y1)}) \<le> Abs_Real(realrel``{(x2,y2)})) =  
      (x1 + y2 \<le> x2 + y1)"
apply (simp add: real_le_def)
apply (auto intro: real_le_lemma)
done

lemma real_le_anti_sym: "[| z \<le> w; w \<le> z |] ==> z = (w::real)"
by (cases z, cases w, simp add: real_le)

lemma real_trans_lemma:
  assumes "x + v \<le> u + y"
      and "u + v' \<le> u' + v"
      and "x2 + v2 = u2 + y2"
  shows "x + v' \<le> u' + (y::preal)"
proof -
  have "(x+v') + (u+v) = (x+v) + (u+v')" by (simp add: add_ac)
  also have "... \<le> (u+y) + (u+v')" by (simp add: prems)
  also have "... \<le> (u+y) + (u'+v)" by (simp add: prems)
  also have "... = (u'+y) + (u+v)"  by (simp add: add_ac)
  finally show ?thesis by simp
qed

lemma real_le_trans: "[| i \<le> j; j \<le> k |] ==> i \<le> (k::real)"
apply (cases i, cases j, cases k)
apply (simp add: real_le)
apply (blast intro: real_trans_lemma)
done

(* Axiom 'order_less_le' of class 'order': *)
lemma real_less_le: "((w::real) < z) = (w \<le> z & w \<noteq> z)"
by (simp add: real_less_def)

instance real :: order
proof qed
 (assumption |
  rule real_le_refl real_le_trans real_le_anti_sym real_less_le)+

(* Axiom 'linorder_linear' of class 'linorder': *)
lemma real_le_linear: "(z::real) \<le> w | w \<le> z"
apply (cases z, cases w)
apply (auto simp add: real_le real_zero_def add_ac)
done


instance real :: linorder
  by (intro_classes, rule real_le_linear)


lemma real_le_eq_diff: "(x \<le> y) = (x-y \<le> (0::real))"
apply (cases x, cases y) 
apply (auto simp add: real_le real_zero_def real_diff_def real_add real_minus
                      add_ac)
apply (simp_all add: add_assoc [symmetric])
done

lemma real_add_left_mono: 
  assumes le: "x \<le> y" shows "z + x \<le> z + (y::real)"
proof -
  have "z + x - (z + y) = (z + -z) + (x - y)"
    by (simp add: diff_minus add_ac) 
  with le show ?thesis 
    by (simp add: real_le_eq_diff[of x] real_le_eq_diff[of "z+x"] diff_minus)
qed

lemma real_sum_gt_zero_less: "(0 < S + (-W::real)) ==> (W < S)"
by (simp add: linorder_not_le [symmetric] real_le_eq_diff [of S] diff_minus)

lemma real_less_sum_gt_zero: "(W < S) ==> (0 < S + (-W::real))"
by (simp add: linorder_not_le [symmetric] real_le_eq_diff [of S] diff_minus)

lemma real_mult_order: "[| 0 < x; 0 < y |] ==> (0::real) < x * y"
apply (cases x, cases y)
apply (simp add: linorder_not_le [where 'a = real, symmetric] 
                 linorder_not_le [where 'a = preal] 
                  real_zero_def real_le real_mult)
  --{*Reduce to the (simpler) @{text "\<le>"} relation *}
apply (auto dest!: less_add_left_Ex
     simp add: add_ac mult_ac
          right_distrib preal_self_less_add_left)
done

lemma real_mult_less_mono2: "[| (0::real) < z; x < y |] ==> z * x < z * y"
apply (rule real_sum_gt_zero_less)
apply (drule real_less_sum_gt_zero [of x y])
apply (drule real_mult_order, assumption)
apply (simp add: right_distrib)
done

instance real :: distrib_lattice
  "inf x y \<equiv> min x y"
  "sup x y \<equiv> max x y"
  by default (auto simp add: inf_real_def sup_real_def min_max.sup_inf_distrib1)


subsection{*The Reals Form an Ordered Field*}

instance real :: ordered_field
proof
  fix x y z :: real
  show "x \<le> y ==> z + x \<le> z + y" by (rule real_add_left_mono)
  show "x < y ==> 0 < z ==> z * x < z * y" by (rule real_mult_less_mono2)
  show "\<bar>x\<bar> = (if x < 0 then -x else x)" by (simp only: real_abs_def)
qed

text{*The function @{term real_of_preal} requires many proofs, but it seems
to be essential for proving completeness of the reals from that of the
positive reals.*}

lemma real_of_preal_add:
     "real_of_preal ((x::preal) + y) = real_of_preal x + real_of_preal y"
by (simp add: real_of_preal_def real_add left_distrib add_ac)

lemma real_of_preal_mult:
     "real_of_preal ((x::preal) * y) = real_of_preal x* real_of_preal y"
by (simp add: real_of_preal_def real_mult right_distrib add_ac mult_ac)


text{*Gleason prop 9-4.4 p 127*}
lemma real_of_preal_trichotomy:
      "\<exists>m. (x::real) = real_of_preal m | x = 0 | x = -(real_of_preal m)"
apply (simp add: real_of_preal_def real_zero_def, cases x)
apply (auto simp add: real_minus add_ac)
apply (cut_tac x = x and y = y in linorder_less_linear)
apply (auto dest!: less_add_left_Ex simp add: add_assoc [symmetric])
done

lemma real_of_preal_leD:
      "real_of_preal m1 \<le> real_of_preal m2 ==> m1 \<le> m2"
by (simp add: real_of_preal_def real_le)

lemma real_of_preal_lessI: "m1 < m2 ==> real_of_preal m1 < real_of_preal m2"
by (auto simp add: real_of_preal_leD linorder_not_le [symmetric])

lemma real_of_preal_lessD:
      "real_of_preal m1 < real_of_preal m2 ==> m1 < m2"
by (simp add: real_of_preal_def real_le linorder_not_le [symmetric])

lemma real_of_preal_less_iff [simp]:
     "(real_of_preal m1 < real_of_preal m2) = (m1 < m2)"
by (blast intro: real_of_preal_lessI real_of_preal_lessD)

lemma real_of_preal_le_iff:
     "(real_of_preal m1 \<le> real_of_preal m2) = (m1 \<le> m2)"
by (simp add: linorder_not_less [symmetric])

lemma real_of_preal_zero_less: "0 < real_of_preal m"
apply (insert preal_self_less_add_left [of 1 m])
apply (auto simp add: real_zero_def real_of_preal_def
                      real_less_def real_le_def add_ac)
apply (rule_tac x="m + 1" in exI, rule_tac x="1" in exI)
apply (simp add: add_ac)
done

lemma real_of_preal_minus_less_zero: "- real_of_preal m < 0"
by (simp add: real_of_preal_zero_less)

lemma real_of_preal_not_minus_gt_zero: "~ 0 < - real_of_preal m"
proof -
  from real_of_preal_minus_less_zero
  show ?thesis by (blast dest: order_less_trans)
qed


subsection{*Theorems About the Ordering*}

lemma real_gt_zero_preal_Ex: "(0 < x) = (\<exists>y. x = real_of_preal y)"
apply (auto simp add: real_of_preal_zero_less)
apply (cut_tac x = x in real_of_preal_trichotomy)
apply (blast elim!: real_of_preal_not_minus_gt_zero [THEN notE])
done

lemma real_gt_preal_preal_Ex:
     "real_of_preal z < x ==> \<exists>y. x = real_of_preal y"
by (blast dest!: real_of_preal_zero_less [THEN order_less_trans]
             intro: real_gt_zero_preal_Ex [THEN iffD1])

lemma real_ge_preal_preal_Ex:
     "real_of_preal z \<le> x ==> \<exists>y. x = real_of_preal y"
by (blast dest: order_le_imp_less_or_eq real_gt_preal_preal_Ex)

lemma real_less_all_preal: "y \<le> 0 ==> \<forall>x. y < real_of_preal x"
by (auto elim: order_le_imp_less_or_eq [THEN disjE] 
            intro: real_of_preal_zero_less [THEN [2] order_less_trans] 
            simp add: real_of_preal_zero_less)

lemma real_less_all_real2: "~ 0 < y ==> \<forall>x. y < real_of_preal x"
by (blast intro!: real_less_all_preal linorder_not_less [THEN iffD1])


subsection{*More Lemmas*}

lemma real_mult_left_cancel: "(c::real) \<noteq> 0 ==> (c*a=c*b) = (a=b)"
by auto

lemma real_mult_right_cancel: "(c::real) \<noteq> 0 ==> (a*c=b*c) = (a=b)"
by auto

lemma real_mult_less_iff1 [simp]: "(0::real) < z ==> (x*z < y*z) = (x < y)"
  by (force elim: order_less_asym
            simp add: Ring_and_Field.mult_less_cancel_right)

lemma real_mult_le_cancel_iff1 [simp]: "(0::real) < z ==> (x*z \<le> y*z) = (x\<le>y)"
apply (simp add: mult_le_cancel_right)
apply (blast intro: elim: order_less_asym)
done

lemma real_mult_le_cancel_iff2 [simp]: "(0::real) < z ==> (z*x \<le> z*y) = (x\<le>y)"
by(simp add:mult_commute)

(* FIXME: redundant, but used by Integration/Integral.thy in AFP *)
lemma real_le_add_order: "[| 0 \<le> x; 0 \<le> y |] ==> (0::real) \<le> x + y"
by (rule add_nonneg_nonneg)

lemma real_inverse_gt_one: "[| (0::real) < x; x < 1 |] ==> 1 < inverse x"
by (simp add: one_less_inverse_iff) (* TODO: generalize/move *)


subsection{*Embedding the Integers into the Reals*}

defs (overloaded)
  real_of_nat_def: "real z == of_nat z"
  real_of_int_def: "real z == of_int z"

lemma real_eq_of_nat: "real = of_nat"
  apply (rule ext)
  apply (unfold real_of_nat_def)
  apply (rule refl)
  done

lemma real_eq_of_int: "real = of_int"
  apply (rule ext)
  apply (unfold real_of_int_def)
  apply (rule refl)
  done

lemma real_of_int_zero [simp]: "real (0::int) = 0"  
by (simp add: real_of_int_def) 

lemma real_of_one [simp]: "real (1::int) = (1::real)"
by (simp add: real_of_int_def) 

lemma real_of_int_add [simp]: "real(x + y) = real (x::int) + real y"
by (simp add: real_of_int_def) 

lemma real_of_int_minus [simp]: "real(-x) = -real (x::int)"
by (simp add: real_of_int_def) 

lemma real_of_int_diff [simp]: "real(x - y) = real (x::int) - real y"
by (simp add: real_of_int_def) 

lemma real_of_int_mult [simp]: "real(x * y) = real (x::int) * real y"
by (simp add: real_of_int_def) 

lemma real_of_int_setsum [simp]: "real ((SUM x:A. f x)::int) = (SUM x:A. real(f x))"
  apply (subst real_eq_of_int)+
  apply (rule of_int_setsum)
done

lemma real_of_int_setprod [simp]: "real ((PROD x:A. f x)::int) = 
    (PROD x:A. real(f x))"
  apply (subst real_eq_of_int)+
  apply (rule of_int_setprod)
done

lemma real_of_int_zero_cancel [simp]: "(real x = 0) = (x = (0::int))"
by (simp add: real_of_int_def) 

lemma real_of_int_inject [iff]: "(real (x::int) = real y) = (x = y)"
by (simp add: real_of_int_def) 

lemma real_of_int_less_iff [iff]: "(real (x::int) < real y) = (x < y)"
by (simp add: real_of_int_def) 

lemma real_of_int_le_iff [simp]: "(real (x::int) \<le> real y) = (x \<le> y)"
by (simp add: real_of_int_def) 

lemma real_of_int_gt_zero_cancel_iff [simp]: "(0 < real (n::int)) = (0 < n)"
by (simp add: real_of_int_def) 

lemma real_of_int_ge_zero_cancel_iff [simp]: "(0 <= real (n::int)) = (0 <= n)"
by (simp add: real_of_int_def) 

lemma real_of_int_lt_zero_cancel_iff [simp]: "(real (n::int) < 0) = (n < 0)"
by (simp add: real_of_int_def)

lemma real_of_int_le_zero_cancel_iff [simp]: "(real (n::int) <= 0) = (n <= 0)"
by (simp add: real_of_int_def)

lemma real_of_int_abs [simp]: "real (abs x) = abs(real (x::int))"
by (auto simp add: abs_if)

lemma int_less_real_le: "((n::int) < m) = (real n + 1 <= real m)"
  apply (subgoal_tac "real n + 1 = real (n + 1)")
  apply (simp del: real_of_int_add)
  apply auto
done

lemma int_le_real_less: "((n::int) <= m) = (real n < real m + 1)"
  apply (subgoal_tac "real m + 1 = real (m + 1)")
  apply (simp del: real_of_int_add)
  apply simp
done

lemma real_of_int_div_aux: "d ~= 0 ==> (real (x::int)) / (real d) = 
    real (x div d) + (real (x mod d)) / (real d)"
proof -
  assume "d ~= 0"
  have "x = (x div d) * d + x mod d"
    by auto
  then have "real x = real (x div d) * real d + real(x mod d)"
    by (simp only: real_of_int_mult [THEN sym] real_of_int_add [THEN sym])
  then have "real x / real d = ... / real d"
    by simp
  then show ?thesis
    by (auto simp add: add_divide_distrib ring_simps prems)
qed

lemma real_of_int_div: "(d::int) ~= 0 ==> d dvd n ==>
    real(n div d) = real n / real d"
  apply (frule real_of_int_div_aux [of d n])
  apply simp
  apply (simp add: zdvd_iff_zmod_eq_0)
done

lemma real_of_int_div2:
  "0 <= real (n::int) / real (x) - real (n div x)"
  apply (case_tac "x = 0")
  apply simp
  apply (case_tac "0 < x")
  apply (simp add: compare_rls)
  apply (subst real_of_int_div_aux)
  apply simp
  apply simp
  apply (subst zero_le_divide_iff)
  apply auto
  apply (simp add: compare_rls)
  apply (subst real_of_int_div_aux)
  apply simp
  apply simp
  apply (subst zero_le_divide_iff)
  apply auto
done

lemma real_of_int_div3:
  "real (n::int) / real (x) - real (n div x) <= 1"
  apply(case_tac "x = 0")
  apply simp
  apply (simp add: compare_rls)
  apply (subst real_of_int_div_aux)
  apply assumption
  apply simp
  apply (subst divide_le_eq)
  apply clarsimp
  apply (rule conjI)
  apply (rule impI)
  apply (rule order_less_imp_le)
  apply simp
  apply (rule impI)
  apply (rule order_less_imp_le)
  apply simp
done

lemma real_of_int_div4: "real (n div x) <= real (n::int) / real x" 
  by (insert real_of_int_div2 [of n x], simp)

subsection{*Embedding the Naturals into the Reals*}

lemma real_of_nat_zero [simp]: "real (0::nat) = 0"
by (simp add: real_of_nat_def)

lemma real_of_nat_one [simp]: "real (Suc 0) = (1::real)"
by (simp add: real_of_nat_def)

lemma real_of_nat_add [simp]: "real (m + n) = real (m::nat) + real n"
by (simp add: real_of_nat_def)

(*Not for addsimps: often the LHS is used to represent a positive natural*)
lemma real_of_nat_Suc: "real (Suc n) = real n + (1::real)"
by (simp add: real_of_nat_def)

lemma real_of_nat_less_iff [iff]: 
     "(real (n::nat) < real m) = (n < m)"
by (simp add: real_of_nat_def)

lemma real_of_nat_le_iff [iff]: "(real (n::nat) \<le> real m) = (n \<le> m)"
by (simp add: real_of_nat_def)

lemma real_of_nat_ge_zero [iff]: "0 \<le> real (n::nat)"
by (simp add: real_of_nat_def zero_le_imp_of_nat)

lemma real_of_nat_Suc_gt_zero: "0 < real (Suc n)"
by (simp add: real_of_nat_def del: of_nat_Suc)

lemma real_of_nat_mult [simp]: "real (m * n) = real (m::nat) * real n"
by (simp add: real_of_nat_def of_nat_mult)

lemma real_of_nat_setsum [simp]: "real ((SUM x:A. f x)::nat) = 
    (SUM x:A. real(f x))"
  apply (subst real_eq_of_nat)+
  apply (rule of_nat_setsum)
done

lemma real_of_nat_setprod [simp]: "real ((PROD x:A. f x)::nat) = 
    (PROD x:A. real(f x))"
  apply (subst real_eq_of_nat)+
  apply (rule of_nat_setprod)
done

lemma real_of_card: "real (card A) = setsum (%x.1) A"
  apply (subst card_eq_setsum)
  apply (subst real_of_nat_setsum)
  apply simp
done

lemma real_of_nat_inject [iff]: "(real (n::nat) = real m) = (n = m)"
by (simp add: real_of_nat_def)

lemma real_of_nat_zero_iff [iff]: "(real (n::nat) = 0) = (n = 0)"
by (simp add: real_of_nat_def)

lemma real_of_nat_diff: "n \<le> m ==> real (m - n) = real (m::nat) - real n"
by (simp add: add: real_of_nat_def of_nat_diff)

lemma real_of_nat_gt_zero_cancel_iff [simp]: "(0 < real (n::nat)) = (0 < n)"
by (simp add: add: real_of_nat_def) 

lemma real_of_nat_le_zero_cancel_iff [simp]: "(real (n::nat) \<le> 0) = (n = 0)"
by (simp add: add: real_of_nat_def)

lemma not_real_of_nat_less_zero [simp]: "~ real (n::nat) < 0"
by (simp add: add: real_of_nat_def)

lemma real_of_nat_ge_zero_cancel_iff [simp]: "(0 \<le> real (n::nat)) = (0 \<le> n)"
by (simp add: add: real_of_nat_def)

lemma nat_less_real_le: "((n::nat) < m) = (real n + 1 <= real m)"
  apply (subgoal_tac "real n + 1 = real (Suc n)")
  apply simp
  apply (auto simp add: real_of_nat_Suc)
done

lemma nat_le_real_less: "((n::nat) <= m) = (real n < real m + 1)"
  apply (subgoal_tac "real m + 1 = real (Suc m)")
  apply (simp add: less_Suc_eq_le)
  apply (simp add: real_of_nat_Suc)
done

lemma real_of_nat_div_aux: "0 < d ==> (real (x::nat)) / (real d) = 
    real (x div d) + (real (x mod d)) / (real d)"
proof -
  assume "0 < d"
  have "x = (x div d) * d + x mod d"
    by auto
  then have "real x = real (x div d) * real d + real(x mod d)"
    by (simp only: real_of_nat_mult [THEN sym] real_of_nat_add [THEN sym])
  then have "real x / real d = \<dots> / real d"
    by simp
  then show ?thesis
    by (auto simp add: add_divide_distrib ring_simps prems)
qed

lemma real_of_nat_div: "0 < (d::nat) ==> d dvd n ==>
    real(n div d) = real n / real d"
  apply (frule real_of_nat_div_aux [of d n])
  apply simp
  apply (subst dvd_eq_mod_eq_0 [THEN sym])
  apply assumption
done

lemma real_of_nat_div2:
  "0 <= real (n::nat) / real (x) - real (n div x)"
  apply(case_tac "x = 0")
  apply simp
  apply (simp add: compare_rls)
  apply (subst real_of_nat_div_aux)
  apply assumption
  apply simp
  apply (subst zero_le_divide_iff)
  apply simp
done

lemma real_of_nat_div3:
  "real (n::nat) / real (x) - real (n div x) <= 1"
  apply(case_tac "x = 0")
  apply simp
  apply (simp add: compare_rls)
  apply (subst real_of_nat_div_aux)
  apply assumption
  apply simp
done

lemma real_of_nat_div4: "real (n div x) <= real (n::nat) / real x" 
  by (insert real_of_nat_div2 [of n x], simp)

lemma real_of_int_real_of_nat: "real (int n) = real n"
by (simp add: real_of_nat_def real_of_int_def int_eq_of_nat)

lemma real_of_int_of_nat_eq [simp]: "real (of_nat n :: int) = real n"
by (simp add: real_of_int_def real_of_nat_def)

lemma real_nat_eq_real [simp]: "0 <= x ==> real(nat x) = real x"
  apply (subgoal_tac "real(int(nat x)) = real(nat x)")
  apply force
  apply (simp only: real_of_int_real_of_nat)
done

subsection{*Numerals and Arithmetic*}

instance real :: number ..

defs (overloaded)
  real_number_of_def: "(number_of w :: real) == of_int w"
    --{*the type constraint is essential!*}

instance real :: number_ring
by (intro_classes, simp add: real_number_of_def) 

text{*Collapse applications of @{term real} to @{term number_of}*}
lemma real_number_of [simp]: "real (number_of v :: int) = number_of v"
by (simp add:  real_of_int_def of_int_number_of_eq)

lemma real_of_nat_number_of [simp]:
     "real (number_of v :: nat) =  
        (if neg (number_of v :: int) then 0  
         else (number_of v :: real))"
by (simp add: real_of_int_real_of_nat [symmetric] int_nat_number_of)
 

use "real_arith.ML"

setup real_arith_setup


subsection{* Simprules combining x+y and 0: ARE THEY NEEDED?*}

text{*Needed in this non-standard form by Hyperreal/Transcendental*}
lemma real_0_le_divide_iff:
     "((0::real) \<le> x/y) = ((x \<le> 0 | 0 \<le> y) & (0 \<le> x | y \<le> 0))"
by (simp add: real_divide_def zero_le_mult_iff, auto)

lemma real_add_minus_iff [simp]: "(x + - a = (0::real)) = (x=a)" 
by arith

lemma real_add_eq_0_iff: "(x+y = (0::real)) = (y = -x)"
by auto

lemma real_add_less_0_iff: "(x+y < (0::real)) = (y < -x)"
by auto

lemma real_0_less_add_iff: "((0::real) < x+y) = (-x < y)"
by auto

lemma real_add_le_0_iff: "(x+y \<le> (0::real)) = (y \<le> -x)"
by auto

lemma real_0_le_add_iff: "((0::real) \<le> x+y) = (-x \<le> y)"
by auto


(*
FIXME: we should have this, as for type int, but many proofs would break.
It replaces x+-y by x-y.
declare real_diff_def [symmetric, simp]
*)


subsubsection{*Density of the Reals*}

lemma real_lbound_gt_zero:
     "[| (0::real) < d1; 0 < d2 |] ==> \<exists>e. 0 < e & e < d1 & e < d2"
apply (rule_tac x = " (min d1 d2) /2" in exI)
apply (simp add: min_def)
done


text{*Similar results are proved in @{text Ring_and_Field}*}
lemma real_less_half_sum: "x < y ==> x < (x+y) / (2::real)"
  by auto

lemma real_gt_half_sum: "x < y ==> (x+y)/(2::real) < y"
  by auto


subsection{*Absolute Value Function for the Reals*}

lemma abs_minus_add_cancel: "abs(x + (-y)) = abs (y + (-(x::real)))"
by (simp add: abs_if)

(* FIXME: redundant, but used by Integration/RealRandVar.thy in AFP *)
lemma abs_le_interval_iff: "(abs x \<le> r) = (-r\<le>x & x\<le>(r::real))"
by (force simp add: OrderedGroup.abs_le_iff)

lemma abs_add_one_gt_zero [simp]: "(0::real) < 1 + abs(x)"
by (simp add: abs_if)

lemma abs_real_of_nat_cancel [simp]: "abs (real x) = real (x::nat)"
by (rule abs_of_nonneg [OF real_of_nat_ge_zero])

lemma abs_add_one_not_less_self [simp]: "~ abs(x) + (1::real) < x"
by simp
 
lemma abs_sum_triangle_ineq: "abs ((x::real) + y + (-l + -m)) \<le> abs(x + -l) + abs(y + -m)"
by simp

subsection{*Code generation using Isabelle's rats*}

types_code
  real ("Rat.rat")
attach (term_of) {*
fun term_of_real x =
 let 
  val rT = HOLogic.realT
  val (p, q) = Rat.quotient_of_rat x
 in if q = 1 then HOLogic.mk_number rT p
    else Const("HOL.divide",[rT,rT] ---> rT) $
           (HOLogic.mk_number rT p) $ (HOLogic.mk_number rT q)
end;
*}
attach (test) {*
fun gen_real i =
let val p = random_range 0 i; val q = random_range 0 i;
    val r = if q=0 then Rat.rat_of_int i else Rat.rat_of_quotient(p,q)
in if one_of [true,false] then r else Rat.neg r end;
*}

consts_code
  "0 :: real" ("Rat.zero")
  "1 :: real" ("Rat.one")
  "uminus :: real \<Rightarrow> real" ("Rat.neg")
  "op + :: real \<Rightarrow> real \<Rightarrow> real" ("Rat.add")
  "op * :: real \<Rightarrow> real \<Rightarrow> real" ("Rat.mult")
  "inverse :: real \<Rightarrow> real" ("Rat.inv")
  "op \<le> :: real \<Rightarrow> real \<Rightarrow> bool" ("Rat.le")
  "op < :: real \<Rightarrow> real \<Rightarrow> bool" ("(Rat.ord (_, _) = LESS)")
  "op = :: real \<Rightarrow> real \<Rightarrow> bool" ("curry Rat.eq")
  "real :: int \<Rightarrow> real" ("Rat.rat'_of'_int")
  "real :: nat \<Rightarrow> real" ("(Rat.rat'_of'_int o {*int*})")


lemma [code, code unfold]:
  "number_of k = real (number_of k :: int)"
  by simp

end

(*  Title:   HOL/Ring_and_Field.thy
    ID:      $Id$
    Author:  Gertrud Bauer, Steven Obua, Tobias Nipkow, Lawrence C Paulson, and Markus Wenzel,
             with contributions by Jeremy Avigad
*)

header {* (Ordered) Rings and Fields *}

theory Ring_and_Field
imports OrderedGroup
begin

text {*
  The theory of partially ordered rings is taken from the books:
  \begin{itemize}
  \item \emph{Lattice Theory} by Garret Birkhoff, American Mathematical Society 1979 
  \item \emph{Partially Ordered Algebraic Systems}, Pergamon Press 1963
  \end{itemize}
  Most of the used notions can also be looked up in 
  \begin{itemize}
  \item \url{http://www.mathworld.com} by Eric Weisstein et. al.
  \item \emph{Algebra I} by van der Waerden, Springer.
  \end{itemize}
*}

class semiring = ab_semigroup_add + semigroup_mult +
  assumes left_distrib: "(a \<^loc>+ b) \<^loc>* c = a \<^loc>* c \<^loc>+ b \<^loc>* c"
  assumes right_distrib: "a \<^loc>* (b \<^loc>+ c) = a \<^loc>* b \<^loc>+ a \<^loc>* c"

class mult_zero = times + zero +
  assumes mult_zero_left [simp]: "\<^loc>0 \<^loc>* a = \<^loc>0"
  assumes mult_zero_right [simp]: "a \<^loc>* \<^loc>0 = \<^loc>0"

class semiring_0 = semiring + comm_monoid_add + mult_zero

class semiring_0_cancel = semiring + comm_monoid_add + cancel_ab_semigroup_add

instance semiring_0_cancel \<subseteq> semiring_0
proof
  fix a :: 'a
  have "0 * a + 0 * a = 0 * a + 0"
    by (simp add: left_distrib [symmetric])
  thus "0 * a = 0"
    by (simp only: add_left_cancel)

  have "a * 0 + a * 0 = a * 0 + 0"
    by (simp add: right_distrib [symmetric])
  thus "a * 0 = 0"
    by (simp only: add_left_cancel)
qed

class comm_semiring = ab_semigroup_add + ab_semigroup_mult +
  assumes distrib: "(a \<^loc>+ b) \<^loc>* c = a \<^loc>* c \<^loc>+ b \<^loc>* c"

instance comm_semiring \<subseteq> semiring
proof
  fix a b c :: 'a
  show "(a + b) * c = a * c + b * c" by (simp add: distrib)
  have "a * (b + c) = (b + c) * a" by (simp add: mult_ac)
  also have "... = b * a + c * a" by (simp only: distrib)
  also have "... = a * b + a * c" by (simp add: mult_ac)
  finally show "a * (b + c) = a * b + a * c" by blast
qed

class comm_semiring_0 = comm_semiring + comm_monoid_add + mult_zero

instance comm_semiring_0 \<subseteq> semiring_0 ..

class comm_semiring_0_cancel = comm_semiring + comm_monoid_add + cancel_ab_semigroup_add

instance comm_semiring_0_cancel \<subseteq> semiring_0_cancel ..

instance comm_semiring_0_cancel \<subseteq> comm_semiring_0 ..

class zero_neq_one = zero + one +
  assumes zero_neq_one [simp]: "\<^loc>0 \<noteq> \<^loc>1"

class semiring_1 = zero_neq_one + semiring_0 + monoid_mult

class comm_semiring_1 = zero_neq_one + comm_semiring_0 + comm_monoid_mult
  (*previously almost_semiring*)

instance comm_semiring_1 \<subseteq> semiring_1 ..

class no_zero_divisors = zero + times +
  assumes no_zero_divisors: "a \<noteq> \<^loc>0 \<Longrightarrow> b \<noteq> \<^loc>0 \<Longrightarrow> a \<^loc>* b \<noteq> \<^loc>0"

class semiring_1_cancel = semiring + comm_monoid_add + zero_neq_one
  + cancel_ab_semigroup_add + monoid_mult

instance semiring_1_cancel \<subseteq> semiring_0_cancel ..

instance semiring_1_cancel \<subseteq> semiring_1 ..

class comm_semiring_1_cancel = comm_semiring + comm_monoid_add + comm_monoid_mult
  + zero_neq_one + cancel_ab_semigroup_add

instance comm_semiring_1_cancel \<subseteq> semiring_1_cancel ..

instance comm_semiring_1_cancel \<subseteq> comm_semiring_0_cancel ..

instance comm_semiring_1_cancel \<subseteq> comm_semiring_1 ..

class ring = semiring + ab_group_add

instance ring \<subseteq> semiring_0_cancel ..

class comm_ring = comm_semiring + ab_group_add

instance comm_ring \<subseteq> ring ..

instance comm_ring \<subseteq> comm_semiring_0_cancel ..

class ring_1 = ring + zero_neq_one + monoid_mult

instance ring_1 \<subseteq> semiring_1_cancel ..

class comm_ring_1 = comm_ring + zero_neq_one + comm_monoid_mult
  (*previously ring*)

instance comm_ring_1 \<subseteq> ring_1 ..

instance comm_ring_1 \<subseteq> comm_semiring_1_cancel ..

class ring_no_zero_divisors = ring + no_zero_divisors

class dom = ring_1 + ring_no_zero_divisors
hide const dom

class idom = comm_ring_1 + no_zero_divisors

instance idom \<subseteq> dom ..

class division_ring = ring_1 + inverse +
  assumes left_inverse [simp]:  "a \<noteq> \<^loc>0 \<Longrightarrow> inverse a \<^loc>* a = \<^loc>1"
  assumes right_inverse [simp]: "a \<noteq> \<^loc>0 \<Longrightarrow> a \<^loc>* inverse a = \<^loc>1"

instance division_ring \<subseteq> dom
proof
  fix a b :: 'a
  assume a: "a \<noteq> 0" and b: "b \<noteq> 0"
  show "a * b \<noteq> 0"
  proof
    assume ab: "a * b = 0"
    hence "0 = inverse a * (a * b) * inverse b"
      by simp
    also have "\<dots> = (inverse a * a) * (b * inverse b)"
      by (simp only: mult_assoc)
    also have "\<dots> = 1"
      using a b by simp
    finally show False
      by simp
  qed
qed

class field = comm_ring_1 + inverse +
  assumes field_inverse:  "a \<noteq> 0 \<Longrightarrow> inverse a \<^loc>* a = \<^loc>1"
  assumes divide_inverse: "a \<^loc>/ b = a \<^loc>* inverse b"

instance field \<subseteq> division_ring
proof
  fix a :: 'a
  assume "a \<noteq> 0"
  thus "inverse a * a = 1" by (rule field_inverse)
  thus "a * inverse a = 1" by (simp only: mult_commute)
qed

instance field \<subseteq> idom ..

class division_by_zero = zero + inverse +
  assumes inverse_zero [simp]: "inverse \<^loc>0 = \<^loc>0"


subsection {* Distribution rules *}

text{*For the @{text combine_numerals} simproc*}
lemma combine_common_factor:
     "a*e + (b*e + c) = (a+b)*e + (c::'a::semiring)"
by (simp add: left_distrib add_ac)

lemma minus_mult_left: "- (a * b) = (-a) * (b::'a::ring)"
apply (rule equals_zero_I)
apply (simp add: left_distrib [symmetric]) 
done

lemma minus_mult_right: "- (a * b) = a * -(b::'a::ring)"
apply (rule equals_zero_I)
apply (simp add: right_distrib [symmetric]) 
done

lemma minus_mult_minus [simp]: "(- a) * (- b) = a * (b::'a::ring)"
  by (simp add: minus_mult_left [symmetric] minus_mult_right [symmetric])

lemma minus_mult_commute: "(- a) * b = a * (- b::'a::ring)"
  by (simp add: minus_mult_left [symmetric] minus_mult_right [symmetric])

lemma right_diff_distrib: "a * (b - c) = a * b - a * (c::'a::ring)"
by (simp add: right_distrib diff_minus 
              minus_mult_left [symmetric] minus_mult_right [symmetric]) 

lemma left_diff_distrib: "(a - b) * c = a * c - b * (c::'a::ring)"
by (simp add: left_distrib diff_minus 
              minus_mult_left [symmetric] minus_mult_right [symmetric]) 

lemmas ring_distribs =
  right_distrib left_distrib left_diff_distrib right_diff_distrib

text{*This list of rewrites simplifies ring terms by multiplying
everything out and bringing sums and products into a canonical form
(by ordered rewriting). As a result it decides ring equalities but
also helps with inequalities. *}
lemmas ring_simps = group_simps ring_distribs

class mult_mono = times + zero + ord +
  assumes mult_left_mono: "a \<sqsubseteq> b \<Longrightarrow> \<^loc>0 \<sqsubseteq> c \<Longrightarrow> c \<^loc>* a \<sqsubseteq> c \<^loc>* b"
  assumes mult_right_mono: "a \<sqsubseteq> b \<Longrightarrow> \<^loc>0 \<sqsubseteq> c \<Longrightarrow> a \<^loc>* c \<sqsubseteq> b \<^loc>* c"

class pordered_semiring = mult_mono + semiring_0 + pordered_ab_semigroup_add 

class pordered_cancel_semiring = mult_mono + pordered_ab_semigroup_add
  + semiring + comm_monoid_add + cancel_ab_semigroup_add

instance pordered_cancel_semiring \<subseteq> semiring_0_cancel ..

instance pordered_cancel_semiring \<subseteq> pordered_semiring .. 

class ordered_semiring_strict = semiring + comm_monoid_add + ordered_cancel_ab_semigroup_add +
  assumes mult_strict_left_mono: "a \<sqsubset> b \<Longrightarrow> \<^loc>0 \<sqsubset> c \<Longrightarrow> c \<^loc>* a \<sqsubset> c \<^loc>* b"
  assumes mult_strict_right_mono: "a \<sqsubset> b \<Longrightarrow> \<^loc>0 \<sqsubset> c \<Longrightarrow> a \<^loc>* c \<sqsubset> b \<^loc>* c"

instance ordered_semiring_strict \<subseteq> semiring_0_cancel ..

instance ordered_semiring_strict \<subseteq> pordered_cancel_semiring
apply intro_classes
apply (cases "a < b & 0 < c")
apply (auto simp add: mult_strict_left_mono order_less_le)
apply (auto simp add: mult_strict_left_mono order_le_less)
apply (simp add: mult_strict_right_mono)
done

class mult_mono1 = times + zero + ord +
  assumes mult_mono: "a \<sqsubseteq> b \<Longrightarrow> \<^loc>0 \<sqsubseteq> c \<Longrightarrow> c \<^loc>* a \<sqsubseteq> c \<^loc>* b"

class pordered_comm_semiring = comm_semiring_0
  + pordered_ab_semigroup_add + mult_mono1

class pordered_cancel_comm_semiring = comm_semiring_0_cancel
  + pordered_ab_semigroup_add + mult_mono1
  
instance pordered_cancel_comm_semiring \<subseteq> pordered_comm_semiring ..

class ordered_comm_semiring_strict = comm_semiring_0 + ordered_cancel_ab_semigroup_add +
  assumes mult_strict_mono: "a \<sqsubset> b \<Longrightarrow> \<^loc>0 \<sqsubset> c \<Longrightarrow> c \<^loc>* a \<sqsubset> c \<^loc>* b"

instance pordered_comm_semiring \<subseteq> pordered_semiring
proof
  fix a b c :: 'a
  assume A: "a <= b" "0 <= c"
  with mult_mono show "c * a <= c * b" .

  from mult_commute have "a * c = c * a" ..
  also from mult_mono A have "\<dots> <= c * b" .
  also from mult_commute have "c * b = b * c" ..
  finally show "a * c <= b * c" .
qed

instance pordered_cancel_comm_semiring \<subseteq> pordered_cancel_semiring ..

instance ordered_comm_semiring_strict \<subseteq> ordered_semiring_strict
by (intro_classes, insert mult_strict_mono, simp_all add: mult_commute, blast+)

instance ordered_comm_semiring_strict \<subseteq> pordered_cancel_comm_semiring
apply (intro_classes)
apply (cases "a < b & 0 < c")
apply (auto simp add: mult_strict_left_mono order_less_le)
apply (auto simp add: mult_strict_left_mono order_le_less)
done

class pordered_ring = ring + pordered_cancel_semiring 

instance pordered_ring \<subseteq> pordered_ab_group_add ..

class lordered_ring = pordered_ring + lordered_ab_group_abs

instance lordered_ring \<subseteq> lordered_ab_group_meet ..

instance lordered_ring \<subseteq> lordered_ab_group_join ..

class abs_if = minus + ord + zero +
  assumes abs_if: "abs a = (if a \<sqsubset> 0 then (uminus a) else a)"

class ordered_ring_strict = ring + ordered_semiring_strict + abs_if + lordered_ab_group

instance ordered_ring_strict \<subseteq> lordered_ring
  by intro_classes (simp add: abs_if sup_eq_if)

class pordered_comm_ring = comm_ring + pordered_comm_semiring

instance pordered_comm_ring \<subseteq> pordered_cancel_comm_semiring ..

class ordered_semidom = comm_semiring_1_cancel + ordered_comm_semiring_strict +
  (*previously ordered_semiring*)
  assumes zero_less_one [simp]: "\<^loc>0 \<sqsubset> \<^loc>1"

class ordered_idom = comm_ring_1 + ordered_comm_semiring_strict + abs_if + lordered_ab_group
  (*previously ordered_ring*)

instance ordered_idom \<subseteq> ordered_ring_strict ..

instance ordered_idom \<subseteq> pordered_comm_ring ..

class ordered_field = field + ordered_idom

lemmas linorder_neqE_ordered_idom =
 linorder_neqE[where 'a = "?'b::ordered_idom"]

lemma eq_add_iff1:
  "(a*e + c = b*e + d) = ((a-b)*e + c = (d::'a::ring))"
by (simp add: ring_simps)

lemma eq_add_iff2:
  "(a*e + c = b*e + d) = (c = (b-a)*e + (d::'a::ring))"
by (simp add: ring_simps)

lemma less_add_iff1:
  "(a*e + c < b*e + d) = ((a-b)*e + c < (d::'a::pordered_ring))"
by (simp add: ring_simps)

lemma less_add_iff2:
  "(a*e + c < b*e + d) = (c < (b-a)*e + (d::'a::pordered_ring))"
by (simp add: ring_simps)

lemma le_add_iff1:
  "(a*e + c \<le> b*e + d) = ((a-b)*e + c \<le> (d::'a::pordered_ring))"
by (simp add: ring_simps)

lemma le_add_iff2:
  "(a*e + c \<le> b*e + d) = (c \<le> (b-a)*e + (d::'a::pordered_ring))"
by (simp add: ring_simps)


subsection {* Ordering Rules for Multiplication *}

lemma mult_left_le_imp_le:
  "[|c*a \<le> c*b; 0 < c|] ==> a \<le> (b::'a::ordered_semiring_strict)"
by (force simp add: mult_strict_left_mono linorder_not_less [symmetric])
 
lemma mult_right_le_imp_le:
  "[|a*c \<le> b*c; 0 < c|] ==> a \<le> (b::'a::ordered_semiring_strict)"
by (force simp add: mult_strict_right_mono linorder_not_less [symmetric])

lemma mult_left_less_imp_less:
  "[|c*a < c*b; 0 \<le> c|] ==> a < (b::'a::ordered_semiring_strict)"
by (force simp add: mult_left_mono linorder_not_le [symmetric])
 
lemma mult_right_less_imp_less:
  "[|a*c < b*c; 0 \<le> c|] ==> a < (b::'a::ordered_semiring_strict)"
by (force simp add: mult_right_mono linorder_not_le [symmetric])

lemma mult_strict_left_mono_neg:
  "[|b < a; c < 0|] ==> c * a < c * (b::'a::ordered_ring_strict)"
apply (drule mult_strict_left_mono [of _ _ "-c"])
apply (simp_all add: minus_mult_left [symmetric]) 
done

lemma mult_left_mono_neg:
  "[|b \<le> a; c \<le> 0|] ==> c * a \<le>  c * (b::'a::pordered_ring)"
apply (drule mult_left_mono [of _ _ "-c"])
apply (simp_all add: minus_mult_left [symmetric]) 
done

lemma mult_strict_right_mono_neg:
  "[|b < a; c < 0|] ==> a * c < b * (c::'a::ordered_ring_strict)"
apply (drule mult_strict_right_mono [of _ _ "-c"])
apply (simp_all add: minus_mult_right [symmetric]) 
done

lemma mult_right_mono_neg:
  "[|b \<le> a; c \<le> 0|] ==> a * c \<le>  (b::'a::pordered_ring) * c"
apply (drule mult_right_mono [of _ _ "-c"])
apply (simp)
apply (simp_all add: minus_mult_right [symmetric]) 
done


subsection{* Products of Signs *}

lemma mult_pos_pos: "[| (0::'a::ordered_semiring_strict) < a; 0 < b |] ==> 0 < a*b"
by (drule mult_strict_left_mono [of 0 b], auto)

lemma mult_nonneg_nonneg: "[| (0::'a::pordered_cancel_semiring) \<le> a; 0 \<le> b |] ==> 0 \<le> a*b"
by (drule mult_left_mono [of 0 b], auto)

lemma mult_pos_neg: "[| (0::'a::ordered_semiring_strict) < a; b < 0 |] ==> a*b < 0"
by (drule mult_strict_left_mono [of b 0], auto)

lemma mult_nonneg_nonpos: "[| (0::'a::pordered_cancel_semiring) \<le> a; b \<le> 0 |] ==> a*b \<le> 0"
by (drule mult_left_mono [of b 0], auto)

lemma mult_pos_neg2: "[| (0::'a::ordered_semiring_strict) < a; b < 0 |] ==> b*a < 0" 
by (drule mult_strict_right_mono[of b 0], auto)

lemma mult_nonneg_nonpos2: "[| (0::'a::pordered_cancel_semiring) \<le> a; b \<le> 0 |] ==> b*a \<le> 0" 
by (drule mult_right_mono[of b 0], auto)

lemma mult_neg_neg: "[| a < (0::'a::ordered_ring_strict); b < 0 |] ==> 0 < a*b"
by (drule mult_strict_right_mono_neg, auto)

lemma mult_nonpos_nonpos: "[| a \<le> (0::'a::pordered_ring); b \<le> 0 |] ==> 0 \<le> a*b"
by (drule mult_right_mono_neg[of a 0 b ], auto)

lemma zero_less_mult_pos:
     "[| 0 < a*b; 0 < a|] ==> 0 < (b::'a::ordered_semiring_strict)"
apply (cases "b\<le>0") 
 apply (auto simp add: order_le_less linorder_not_less)
apply (drule_tac mult_pos_neg [of a b]) 
 apply (auto dest: order_less_not_sym)
done

lemma zero_less_mult_pos2:
     "[| 0 < b*a; 0 < a|] ==> 0 < (b::'a::ordered_semiring_strict)"
apply (cases "b\<le>0") 
 apply (auto simp add: order_le_less linorder_not_less)
apply (drule_tac mult_pos_neg2 [of a b]) 
 apply (auto dest: order_less_not_sym)
done

lemma zero_less_mult_iff:
     "((0::'a::ordered_ring_strict) < a*b) = (0 < a & 0 < b | a < 0 & b < 0)"
apply (auto simp add: order_le_less linorder_not_less mult_pos_pos 
  mult_neg_neg)
apply (blast dest: zero_less_mult_pos) 
apply (blast dest: zero_less_mult_pos2)
done

lemma mult_eq_0_iff [simp]:
  fixes a b :: "'a::ring_no_zero_divisors"
  shows "(a * b = 0) = (a = 0 \<or> b = 0)"
by (cases "a = 0 \<or> b = 0", auto dest: no_zero_divisors)

instance ordered_ring_strict \<subseteq> ring_no_zero_divisors
apply intro_classes
apply (auto simp add: linorder_not_less order_le_less linorder_neq_iff)
apply (force dest: mult_strict_right_mono_neg mult_strict_right_mono)+
done

lemma zero_le_mult_iff:
     "((0::'a::ordered_ring_strict) \<le> a*b) = (0 \<le> a & 0 \<le> b | a \<le> 0 & b \<le> 0)"
by (auto simp add: eq_commute [of 0] order_le_less linorder_not_less
                   zero_less_mult_iff)

lemma mult_less_0_iff:
     "(a*b < (0::'a::ordered_ring_strict)) = (0 < a & b < 0 | a < 0 & 0 < b)"
apply (insert zero_less_mult_iff [of "-a" b]) 
apply (force simp add: minus_mult_left[symmetric]) 
done

lemma mult_le_0_iff:
     "(a*b \<le> (0::'a::ordered_ring_strict)) = (0 \<le> a & b \<le> 0 | a \<le> 0 & 0 \<le> b)"
apply (insert zero_le_mult_iff [of "-a" b]) 
apply (force simp add: minus_mult_left[symmetric]) 
done

lemma split_mult_pos_le: "(0 \<le> a & 0 \<le> b) | (a \<le> 0 & b \<le> 0) \<Longrightarrow> 0 \<le> a * (b::_::pordered_ring)"
by (auto simp add: mult_nonneg_nonneg mult_nonpos_nonpos)

lemma split_mult_neg_le: "(0 \<le> a & b \<le> 0) | (a \<le> 0 & 0 \<le> b) \<Longrightarrow> a * b \<le> (0::_::pordered_cancel_semiring)" 
by (auto simp add: mult_nonneg_nonpos mult_nonneg_nonpos2)

lemma zero_le_square[simp]: "(0::'a::ordered_ring_strict) \<le> a*a"
by (simp add: zero_le_mult_iff linorder_linear)

lemma not_square_less_zero[simp]: "\<not> (a * a < (0::'a::ordered_ring_strict))"
by (simp add: not_less)

text{*Proving axiom @{text zero_less_one} makes all @{text ordered_semidom}
      theorems available to members of @{term ordered_idom} *}

instance ordered_idom \<subseteq> ordered_semidom
proof
  have "(0::'a) \<le> 1*1" by (rule zero_le_square)
  thus "(0::'a) < 1" by (simp add: order_le_less) 
qed

instance ordered_idom \<subseteq> idom ..

text{*All three types of comparision involving 0 and 1 are covered.*}

lemmas one_neq_zero = zero_neq_one [THEN not_sym]
declare one_neq_zero [simp]

lemma zero_le_one [simp]: "(0::'a::ordered_semidom) \<le> 1"
  by (rule zero_less_one [THEN order_less_imp_le]) 

lemma not_one_le_zero [simp]: "~ (1::'a::ordered_semidom) \<le> 0"
by (simp add: linorder_not_le) 

lemma not_one_less_zero [simp]: "~ (1::'a::ordered_semidom) < 0"
by (simp add: linorder_not_less) 


subsection{*More Monotonicity*}

text{*Strict monotonicity in both arguments*}
lemma mult_strict_mono:
     "[|a<b; c<d; 0<b; 0\<le>c|] ==> a * c < b * (d::'a::ordered_semiring_strict)"
apply (cases "c=0")
 apply (simp add: mult_pos_pos) 
apply (erule mult_strict_right_mono [THEN order_less_trans])
 apply (force simp add: order_le_less) 
apply (erule mult_strict_left_mono, assumption)
done

text{*This weaker variant has more natural premises*}
lemma mult_strict_mono':
     "[| a<b; c<d; 0 \<le> a; 0 \<le> c|] ==> a * c < b * (d::'a::ordered_semiring_strict)"
apply (rule mult_strict_mono)
apply (blast intro: order_le_less_trans)+
done

lemma mult_mono:
     "[|a \<le> b; c \<le> d; 0 \<le> b; 0 \<le> c|] 
      ==> a * c  \<le>  b * (d::'a::pordered_semiring)"
apply (erule mult_right_mono [THEN order_trans], assumption)
apply (erule mult_left_mono, assumption)
done

lemma mult_mono':
     "[|a \<le> b; c \<le> d; 0 \<le> a; 0 \<le> c|] 
      ==> a * c  \<le>  b * (d::'a::pordered_semiring)"
apply (rule mult_mono)
apply (fast intro: order_trans)+
done

lemma less_1_mult: "[| 1 < m; 1 < n |] ==> 1 < m*(n::'a::ordered_semidom)"
apply (insert mult_strict_mono [of 1 m 1 n]) 
apply (simp add:  order_less_trans [OF zero_less_one]) 
done

lemma mult_less_le_imp_less: "(a::'a::ordered_semiring_strict) < b ==>
    c <= d ==> 0 <= a ==> 0 < c ==> a * c < b * d"
  apply (subgoal_tac "a * c < b * c")
  apply (erule order_less_le_trans)
  apply (erule mult_left_mono)
  apply simp
  apply (erule mult_strict_right_mono)
  apply assumption
done

lemma mult_le_less_imp_less: "(a::'a::ordered_semiring_strict) <= b ==>
    c < d ==> 0 < a ==> 0 <= c ==> a * c < b * d"
  apply (subgoal_tac "a * c <= b * c")
  apply (erule order_le_less_trans)
  apply (erule mult_strict_left_mono)
  apply simp
  apply (erule mult_right_mono)
  apply simp
done


subsection{*Cancellation Laws for Relationships With a Common Factor*}

text{*Cancellation laws for @{term "c*a < c*b"} and @{term "a*c < b*c"},
   also with the relations @{text "\<le>"} and equality.*}

text{*These ``disjunction'' versions produce two cases when the comparison is
 an assumption, but effectively four when the comparison is a goal.*}

lemma mult_less_cancel_right_disj:
    "(a*c < b*c) = ((0 < c & a < b) | (c < 0 & b < (a::'a::ordered_ring_strict)))"
apply (cases "c = 0")
apply (auto simp add: linorder_neq_iff mult_strict_right_mono 
                      mult_strict_right_mono_neg)
apply (auto simp add: linorder_not_less 
                      linorder_not_le [symmetric, of "a*c"]
                      linorder_not_le [symmetric, of a])
apply (erule_tac [!] notE)
apply (auto simp add: order_less_imp_le mult_right_mono 
                      mult_right_mono_neg)
done

lemma mult_less_cancel_left_disj:
    "(c*a < c*b) = ((0 < c & a < b) | (c < 0 & b < (a::'a::ordered_ring_strict)))"
apply (cases "c = 0")
apply (auto simp add: linorder_neq_iff mult_strict_left_mono 
                      mult_strict_left_mono_neg)
apply (auto simp add: linorder_not_less 
                      linorder_not_le [symmetric, of "c*a"]
                      linorder_not_le [symmetric, of a])
apply (erule_tac [!] notE)
apply (auto simp add: order_less_imp_le mult_left_mono 
                      mult_left_mono_neg)
done


text{*The ``conjunction of implication'' lemmas produce two cases when the
comparison is a goal, but give four when the comparison is an assumption.*}

lemma mult_less_cancel_right:
  fixes c :: "'a :: ordered_ring_strict"
  shows      "(a*c < b*c) = ((0 \<le> c --> a < b) & (c \<le> 0 --> b < a))"
by (insert mult_less_cancel_right_disj [of a c b], auto)

lemma mult_less_cancel_left:
  fixes c :: "'a :: ordered_ring_strict"
  shows      "(c*a < c*b) = ((0 \<le> c --> a < b) & (c \<le> 0 --> b < a))"
by (insert mult_less_cancel_left_disj [of c a b], auto)

lemma mult_le_cancel_right:
     "(a*c \<le> b*c) = ((0<c --> a\<le>b) & (c<0 --> b \<le> (a::'a::ordered_ring_strict)))"
by (simp add: linorder_not_less [symmetric] mult_less_cancel_right_disj)

lemma mult_le_cancel_left:
     "(c*a \<le> c*b) = ((0<c --> a\<le>b) & (c<0 --> b \<le> (a::'a::ordered_ring_strict)))"
by (simp add: linorder_not_less [symmetric] mult_less_cancel_left_disj)

lemma mult_less_imp_less_left:
      assumes less: "c*a < c*b" and nonneg: "0 \<le> c"
      shows "a < (b::'a::ordered_semiring_strict)"
proof (rule ccontr)
  assume "~ a < b"
  hence "b \<le> a" by (simp add: linorder_not_less)
  hence "c*b \<le> c*a" using nonneg by (rule mult_left_mono)
  with this and less show False 
    by (simp add: linorder_not_less [symmetric])
qed

lemma mult_less_imp_less_right:
  assumes less: "a*c < b*c" and nonneg: "0 <= c"
  shows "a < (b::'a::ordered_semiring_strict)"
proof (rule ccontr)
  assume "~ a < b"
  hence "b \<le> a" by (simp add: linorder_not_less)
  hence "b*c \<le> a*c" using nonneg by (rule mult_right_mono)
  with this and less show False 
    by (simp add: linorder_not_less [symmetric])
qed  

text{*Cancellation of equalities with a common factor*}
lemma mult_cancel_right [simp]:
  fixes a b c :: "'a::ring_no_zero_divisors"
  shows "(a * c = b * c) = (c = 0 \<or> a = b)"
proof -
  have "(a * c = b * c) = ((a - b) * c = 0)"
    by (simp add: ring_distribs)
  thus ?thesis
    by (simp add: disj_commute)
qed

lemma mult_cancel_left [simp]:
  fixes a b c :: "'a::ring_no_zero_divisors"
  shows "(c * a = c * b) = (c = 0 \<or> a = b)"
proof -
  have "(c * a = c * b) = (c * (a - b) = 0)"
    by (simp add: ring_distribs)
  thus ?thesis
    by simp
qed


subsubsection{*Special Cancellation Simprules for Multiplication*}

text{*These also produce two cases when the comparison is a goal.*}

lemma mult_le_cancel_right1:
  fixes c :: "'a :: ordered_idom"
  shows "(c \<le> b*c) = ((0<c --> 1\<le>b) & (c<0 --> b \<le> 1))"
by (insert mult_le_cancel_right [of 1 c b], simp)

lemma mult_le_cancel_right2:
  fixes c :: "'a :: ordered_idom"
  shows "(a*c \<le> c) = ((0<c --> a\<le>1) & (c<0 --> 1 \<le> a))"
by (insert mult_le_cancel_right [of a c 1], simp)

lemma mult_le_cancel_left1:
  fixes c :: "'a :: ordered_idom"
  shows "(c \<le> c*b) = ((0<c --> 1\<le>b) & (c<0 --> b \<le> 1))"
by (insert mult_le_cancel_left [of c 1 b], simp)

lemma mult_le_cancel_left2:
  fixes c :: "'a :: ordered_idom"
  shows "(c*a \<le> c) = ((0<c --> a\<le>1) & (c<0 --> 1 \<le> a))"
by (insert mult_le_cancel_left [of c a 1], simp)

lemma mult_less_cancel_right1:
  fixes c :: "'a :: ordered_idom"
  shows "(c < b*c) = ((0 \<le> c --> 1<b) & (c \<le> 0 --> b < 1))"
by (insert mult_less_cancel_right [of 1 c b], simp)

lemma mult_less_cancel_right2:
  fixes c :: "'a :: ordered_idom"
  shows "(a*c < c) = ((0 \<le> c --> a<1) & (c \<le> 0 --> 1 < a))"
by (insert mult_less_cancel_right [of a c 1], simp)

lemma mult_less_cancel_left1:
  fixes c :: "'a :: ordered_idom"
  shows "(c < c*b) = ((0 \<le> c --> 1<b) & (c \<le> 0 --> b < 1))"
by (insert mult_less_cancel_left [of c 1 b], simp)

lemma mult_less_cancel_left2:
  fixes c :: "'a :: ordered_idom"
  shows "(c*a < c) = ((0 \<le> c --> a<1) & (c \<le> 0 --> 1 < a))"
by (insert mult_less_cancel_left [of c a 1], simp)

lemma mult_cancel_right1 [simp]:
  fixes c :: "'a :: dom"
  shows "(c = b*c) = (c = 0 | b=1)"
by (insert mult_cancel_right [of 1 c b], force)

lemma mult_cancel_right2 [simp]:
  fixes c :: "'a :: dom"
  shows "(a*c = c) = (c = 0 | a=1)"
by (insert mult_cancel_right [of a c 1], simp)
 
lemma mult_cancel_left1 [simp]:
  fixes c :: "'a :: dom"
  shows "(c = c*b) = (c = 0 | b=1)"
by (insert mult_cancel_left [of c 1 b], force)

lemma mult_cancel_left2 [simp]:
  fixes c :: "'a :: dom"
  shows "(c*a = c) = (c = 0 | a=1)"
by (insert mult_cancel_left [of c a 1], simp)


text{*Simprules for comparisons where common factors can be cancelled.*}
lemmas mult_compare_simps =
    mult_le_cancel_right mult_le_cancel_left
    mult_le_cancel_right1 mult_le_cancel_right2
    mult_le_cancel_left1 mult_le_cancel_left2
    mult_less_cancel_right mult_less_cancel_left
    mult_less_cancel_right1 mult_less_cancel_right2
    mult_less_cancel_left1 mult_less_cancel_left2
    mult_cancel_right mult_cancel_left
    mult_cancel_right1 mult_cancel_right2
    mult_cancel_left1 mult_cancel_left2


subsection {* Fields *}

lemma right_inverse_eq: "b \<noteq> 0 ==> (a / b = 1) = (a = (b::'a::field))"
proof
  assume neq: "b \<noteq> 0"
  {
    hence "a = (a / b) * b" by (simp add: divide_inverse mult_ac)
    also assume "a / b = 1"
    finally show "a = b" by simp
  next
    assume "a = b"
    with neq show "a / b = 1" by (simp add: divide_inverse)
  }
qed

lemma nonzero_inverse_eq_divide: "a \<noteq> 0 ==> inverse (a::'a::field) = 1/a"
by (simp add: divide_inverse)

lemma divide_self[simp]: "a \<noteq> 0 ==> a / (a::'a::field) = 1"
  by (simp add: divide_inverse)

lemma divide_zero [simp]: "a / 0 = (0::'a::{field,division_by_zero})"
by (simp add: divide_inverse)

lemma divide_self_if [simp]:
     "a / (a::'a::{field,division_by_zero}) = (if a=0 then 0 else 1)"
  by (simp add: divide_self)

lemma divide_zero_left [simp]: "0/a = (0::'a::field)"
by (simp add: divide_inverse)

lemma inverse_eq_divide: "inverse (a::'a::field) = 1/a"
by (simp add: divide_inverse)

lemma add_divide_distrib: "(a+b)/(c::'a::field) = a/c + b/c"
by (simp add: divide_inverse ring_distribs) 

(* what ordering?? this is a straight instance of mult_eq_0_iff
text{*Compared with @{text mult_eq_0_iff}, this version removes the requirement
      of an ordering.*}
lemma field_mult_eq_0_iff [simp]:
  "(a*b = (0::'a::division_ring)) = (a = 0 | b = 0)"
by simp
*)
(* subsumed by mult_cancel lemmas on ring_no_zero_divisors
text{*Cancellation of equalities with a common factor*}
lemma field_mult_cancel_right_lemma:
      assumes cnz: "c \<noteq> (0::'a::division_ring)"
         and eq:  "a*c = b*c"
        shows "a=b"
proof -
  have "(a * c) * inverse c = (b * c) * inverse c"
    by (simp add: eq)
  thus "a=b"
    by (simp add: mult_assoc cnz)
qed

lemma field_mult_cancel_right [simp]:
     "(a*c = b*c) = (c = (0::'a::division_ring) | a=b)"
by simp

lemma field_mult_cancel_left [simp]:
     "(c*a = c*b) = (c = (0::'a::division_ring) | a=b)"
by simp
*)
lemma nonzero_imp_inverse_nonzero:
  "a \<noteq> 0 ==> inverse a \<noteq> (0::'a::division_ring)"
proof
  assume ianz: "inverse a = 0"
  assume "a \<noteq> 0"
  hence "1 = a * inverse a" by simp
  also have "... = 0" by (simp add: ianz)
  finally have "1 = (0::'a::division_ring)" .
  thus False by (simp add: eq_commute)
qed


subsection{*Basic Properties of @{term inverse}*}

lemma inverse_zero_imp_zero: "inverse a = 0 ==> a = (0::'a::division_ring)"
apply (rule ccontr) 
apply (blast dest: nonzero_imp_inverse_nonzero) 
done

lemma inverse_nonzero_imp_nonzero:
   "inverse a = 0 ==> a = (0::'a::division_ring)"
apply (rule ccontr) 
apply (blast dest: nonzero_imp_inverse_nonzero) 
done

lemma inverse_nonzero_iff_nonzero [simp]:
   "(inverse a = 0) = (a = (0::'a::{division_ring,division_by_zero}))"
by (force dest: inverse_nonzero_imp_nonzero) 

lemma nonzero_inverse_minus_eq:
      assumes [simp]: "a\<noteq>0"
      shows "inverse(-a) = -inverse(a::'a::division_ring)"
proof -
  have "-a * inverse (- a) = -a * - inverse a"
    by simp
  thus ?thesis 
    by (simp only: mult_cancel_left, simp)
qed

lemma inverse_minus_eq [simp]:
   "inverse(-a) = -inverse(a::'a::{division_ring,division_by_zero})"
proof cases
  assume "a=0" thus ?thesis by (simp add: inverse_zero)
next
  assume "a\<noteq>0" 
  thus ?thesis by (simp add: nonzero_inverse_minus_eq)
qed

lemma nonzero_inverse_eq_imp_eq:
      assumes inveq: "inverse a = inverse b"
	  and anz:  "a \<noteq> 0"
	  and bnz:  "b \<noteq> 0"
	 shows "a = (b::'a::division_ring)"
proof -
  have "a * inverse b = a * inverse a"
    by (simp add: inveq)
  hence "(a * inverse b) * b = (a * inverse a) * b"
    by simp
  thus "a = b"
    by (simp add: mult_assoc anz bnz)
qed

lemma inverse_eq_imp_eq:
  "inverse a = inverse b ==> a = (b::'a::{division_ring,division_by_zero})"
apply (cases "a=0 | b=0") 
 apply (force dest!: inverse_zero_imp_zero
              simp add: eq_commute [of "0::'a"])
apply (force dest!: nonzero_inverse_eq_imp_eq) 
done

lemma inverse_eq_iff_eq [simp]:
  "(inverse a = inverse b) = (a = (b::'a::{division_ring,division_by_zero}))"
by (force dest!: inverse_eq_imp_eq)

lemma nonzero_inverse_inverse_eq:
      assumes [simp]: "a \<noteq> 0"
      shows "inverse(inverse (a::'a::division_ring)) = a"
  proof -
  have "(inverse (inverse a) * inverse a) * a = a" 
    by (simp add: nonzero_imp_inverse_nonzero)
  thus ?thesis
    by (simp add: mult_assoc)
  qed

lemma inverse_inverse_eq [simp]:
     "inverse(inverse (a::'a::{division_ring,division_by_zero})) = a"
  proof cases
    assume "a=0" thus ?thesis by simp
  next
    assume "a\<noteq>0" 
    thus ?thesis by (simp add: nonzero_inverse_inverse_eq)
  qed

lemma inverse_1 [simp]: "inverse 1 = (1::'a::division_ring)"
  proof -
  have "inverse 1 * 1 = (1::'a::division_ring)" 
    by (rule left_inverse [OF zero_neq_one [symmetric]])
  thus ?thesis  by simp
  qed

lemma inverse_unique: 
  assumes ab: "a*b = 1"
  shows "inverse a = (b::'a::division_ring)"
proof -
  have "a \<noteq> 0" using ab by auto
  moreover have "inverse a * (a * b) = inverse a" by (simp add: ab) 
  ultimately show ?thesis by (simp add: mult_assoc [symmetric]) 
qed

lemma nonzero_inverse_mult_distrib: 
      assumes anz: "a \<noteq> 0"
          and bnz: "b \<noteq> 0"
      shows "inverse(a*b) = inverse(b) * inverse(a::'a::division_ring)"
  proof -
  have "inverse(a*b) * (a * b) * inverse(b) = inverse(b)" 
    by (simp add: anz bnz)
  hence "inverse(a*b) * a = inverse(b)" 
    by (simp add: mult_assoc bnz)
  hence "inverse(a*b) * a * inverse(a) = inverse(b) * inverse(a)" 
    by simp
  thus ?thesis
    by (simp add: mult_assoc anz)
  qed

text{*This version builds in division by zero while also re-orienting
      the right-hand side.*}
lemma inverse_mult_distrib [simp]:
     "inverse(a*b) = inverse(a) * inverse(b::'a::{field,division_by_zero})"
  proof cases
    assume "a \<noteq> 0 & b \<noteq> 0" 
    thus ?thesis
      by (simp add: nonzero_inverse_mult_distrib mult_commute)
  next
    assume "~ (a \<noteq> 0 & b \<noteq> 0)" 
    thus ?thesis
      by force
  qed

lemma division_ring_inverse_add:
  "[|(a::'a::division_ring) \<noteq> 0; b \<noteq> 0|]
   ==> inverse a + inverse b = inverse a * (a+b) * inverse b"
by (simp add: ring_simps)

lemma division_ring_inverse_diff:
  "[|(a::'a::division_ring) \<noteq> 0; b \<noteq> 0|]
   ==> inverse a - inverse b = inverse a * (b-a) * inverse b"
by (simp add: ring_simps)

text{*There is no slick version using division by zero.*}
lemma inverse_add:
  "[|a \<noteq> 0;  b \<noteq> 0|]
   ==> inverse a + inverse b = (a+b) * inverse a * inverse (b::'a::field)"
by (simp add: division_ring_inverse_add mult_ac)

lemma inverse_divide [simp]:
  "inverse (a/b) = b / (a::'a::{field,division_by_zero})"
by (simp add: divide_inverse mult_commute)


subsection {* Calculations with fractions *}

text{* There is a whole bunch of simp-rules just for class @{text
field} but none for class @{text field} and @{text nonzero_divides}
because the latter are covered by a simproc. *}

lemma nonzero_mult_divide_mult_cancel_left[simp]:
assumes [simp]: "b\<noteq>0" and [simp]: "c\<noteq>0" shows "(c*a)/(c*b) = a/(b::'a::field)"
proof -
  have "(c*a)/(c*b) = c * a * (inverse b * inverse c)"
    by (simp add: divide_inverse nonzero_inverse_mult_distrib)
  also have "... =  a * inverse b * (inverse c * c)"
    by (simp only: mult_ac)
  also have "... =  a * inverse b"
    by simp
    finally show ?thesis 
    by (simp add: divide_inverse)
qed

lemma mult_divide_mult_cancel_left:
  "c\<noteq>0 ==> (c*a) / (c*b) = a / (b::'a::{field,division_by_zero})"
apply (cases "b = 0")
apply (simp_all add: nonzero_mult_divide_mult_cancel_left)
done

lemma nonzero_mult_divide_mult_cancel_right:
  "[|b\<noteq>0; c\<noteq>0|] ==> (a*c) / (b*c) = a/(b::'a::field)"
by (simp add: mult_commute [of _ c] nonzero_mult_divide_mult_cancel_left) 

lemma mult_divide_mult_cancel_right:
  "c\<noteq>0 ==> (a*c) / (b*c) = a / (b::'a::{field,division_by_zero})"
apply (cases "b = 0")
apply (simp_all add: nonzero_mult_divide_mult_cancel_right)
done

lemma divide_1 [simp]: "a/1 = (a::'a::field)"
by (simp add: divide_inverse)

lemma times_divide_eq_right: "a * (b/c) = (a*b) / (c::'a::field)"
by (simp add: divide_inverse mult_assoc)

lemma times_divide_eq_left: "(b/c) * a = (b*a) / (c::'a::field)"
by (simp add: divide_inverse mult_ac)

lemmas times_divide_eq = times_divide_eq_right times_divide_eq_left

lemma divide_divide_eq_right [simp]:
  "a / (b/c) = (a*c) / (b::'a::{field,division_by_zero})"
by (simp add: divide_inverse mult_ac)

lemma divide_divide_eq_left [simp]:
  "(a / b) / (c::'a::{field,division_by_zero}) = a / (b*c)"
by (simp add: divide_inverse mult_assoc)

lemma add_frac_eq: "(y::'a::field) ~= 0 ==> z ~= 0 ==>
    x / y + w / z = (x * z + w * y) / (y * z)"
apply (subgoal_tac "x / y = (x * z) / (y * z)")
apply (erule ssubst)
apply (subgoal_tac "w / z = (w * y) / (y * z)")
apply (erule ssubst)
apply (rule add_divide_distrib [THEN sym])
apply (subst mult_commute)
apply (erule nonzero_mult_divide_mult_cancel_left [THEN sym])
apply assumption
apply (erule nonzero_mult_divide_mult_cancel_right [THEN sym])
apply assumption
done


subsubsection{*Special Cancellation Simprules for Division*}

lemma mult_divide_mult_cancel_left_if[simp]:
fixes c :: "'a :: {field,division_by_zero}"
shows "(c*a) / (c*b) = (if c=0 then 0 else a/b)"
by (simp add: mult_divide_mult_cancel_left)

lemma nonzero_mult_divide_cancel_right[simp]:
  "b \<noteq> 0 \<Longrightarrow> a * b / b = (a::'a::field)"
using nonzero_mult_divide_mult_cancel_right[of 1 b a] by simp

lemma nonzero_mult_divide_cancel_left[simp]:
  "a \<noteq> 0 \<Longrightarrow> a * b / a = (b::'a::field)"
using nonzero_mult_divide_mult_cancel_left[of 1 a b] by simp


lemma nonzero_divide_mult_cancel_right[simp]:
  "\<lbrakk> a\<noteq>0; b\<noteq>0 \<rbrakk> \<Longrightarrow> b / (a * b) = 1/(a::'a::field)"
using nonzero_mult_divide_mult_cancel_right[of a b 1] by simp

lemma nonzero_divide_mult_cancel_left[simp]:
  "\<lbrakk> a\<noteq>0; b\<noteq>0 \<rbrakk> \<Longrightarrow> a / (a * b) = 1/(b::'a::field)"
using nonzero_mult_divide_mult_cancel_left[of b a 1] by simp


lemma nonzero_mult_divide_mult_cancel_left2[simp]:
  "[|b\<noteq>0; c\<noteq>0|] ==> (c*a) / (b*c) = a/(b::'a::field)"
using nonzero_mult_divide_mult_cancel_left[of b c a] by(simp add:mult_ac)

lemma nonzero_mult_divide_mult_cancel_right2[simp]:
  "[|b\<noteq>0; c\<noteq>0|] ==> (a*c) / (c*b) = a/(b::'a::field)"
using nonzero_mult_divide_mult_cancel_right[of b c a] by(simp add:mult_ac)


subsection {* Division and Unary Minus *}

lemma nonzero_minus_divide_left: "b \<noteq> 0 ==> - (a/b) = (-a) / (b::'a::field)"
by (simp add: divide_inverse minus_mult_left)

lemma nonzero_minus_divide_right: "b \<noteq> 0 ==> - (a/b) = a / -(b::'a::field)"
by (simp add: divide_inverse nonzero_inverse_minus_eq minus_mult_right)

lemma nonzero_minus_divide_divide: "b \<noteq> 0 ==> (-a)/(-b) = a / (b::'a::field)"
by (simp add: divide_inverse nonzero_inverse_minus_eq)

lemma minus_divide_left: "- (a/b) = (-a) / (b::'a::field)"
by (simp add: divide_inverse minus_mult_left [symmetric])

lemma minus_divide_right: "- (a/b) = a / -(b::'a::{field,division_by_zero})"
by (simp add: divide_inverse minus_mult_right [symmetric])


text{*The effect is to extract signs from divisions*}
lemmas divide_minus_left = minus_divide_left [symmetric]
lemmas divide_minus_right = minus_divide_right [symmetric]
declare divide_minus_left [simp]   divide_minus_right [simp]

text{*Also, extract signs from products*}
lemmas mult_minus_left = minus_mult_left [symmetric]
lemmas mult_minus_right = minus_mult_right [symmetric]
declare mult_minus_left [simp]   mult_minus_right [simp]

lemma minus_divide_divide [simp]:
  "(-a)/(-b) = a / (b::'a::{field,division_by_zero})"
apply (cases "b=0", simp) 
apply (simp add: nonzero_minus_divide_divide) 
done

lemma diff_divide_distrib: "(a-b)/(c::'a::field) = a/c - b/c"
by (simp add: diff_minus add_divide_distrib) 

lemma add_divide_eq_iff:
  "(z::'a::field) \<noteq> 0 \<Longrightarrow> x + y/z = (z*x + y)/z"
by(simp add:add_divide_distrib nonzero_mult_divide_cancel_left)

lemma divide_add_eq_iff:
  "(z::'a::field) \<noteq> 0 \<Longrightarrow> x/z + y = (x + z*y)/z"
by(simp add:add_divide_distrib nonzero_mult_divide_cancel_left)

lemma diff_divide_eq_iff:
  "(z::'a::field) \<noteq> 0 \<Longrightarrow> x - y/z = (z*x - y)/z"
by(simp add:diff_divide_distrib nonzero_mult_divide_cancel_left)

lemma divide_diff_eq_iff:
  "(z::'a::field) \<noteq> 0 \<Longrightarrow> x/z - y = (x - z*y)/z"
by(simp add:diff_divide_distrib nonzero_mult_divide_cancel_left)

lemma nonzero_eq_divide_eq: "c\<noteq>0 ==> ((a::'a::field) = b/c) = (a*c = b)"
proof -
  assume [simp]: "c\<noteq>0"
  have "(a = b/c) = (a*c = (b/c)*c)" by simp
  also have "... = (a*c = b)" by (simp add: divide_inverse mult_assoc)
  finally show ?thesis .
qed

lemma nonzero_divide_eq_eq: "c\<noteq>0 ==> (b/c = (a::'a::field)) = (b = a*c)"
proof -
  assume [simp]: "c\<noteq>0"
  have "(b/c = a) = ((b/c)*c = a*c)"  by simp
  also have "... = (b = a*c)"  by (simp add: divide_inverse mult_assoc) 
  finally show ?thesis .
qed

lemma eq_divide_eq:
  "((a::'a::{field,division_by_zero}) = b/c) = (if c\<noteq>0 then a*c = b else a=0)"
by (simp add: nonzero_eq_divide_eq) 

lemma divide_eq_eq:
  "(b/c = (a::'a::{field,division_by_zero})) = (if c\<noteq>0 then b = a*c else a=0)"
by (force simp add: nonzero_divide_eq_eq) 

lemma divide_eq_imp: "(c::'a::{division_by_zero,field}) ~= 0 ==>
    b = a * c ==> b / c = a"
  by (subst divide_eq_eq, simp)

lemma eq_divide_imp: "(c::'a::{division_by_zero,field}) ~= 0 ==>
    a * c = b ==> a = b / c"
  by (subst eq_divide_eq, simp)


lemmas field_eq_simps = ring_simps
  (* pull / out*)
  add_divide_eq_iff divide_add_eq_iff
  diff_divide_eq_iff divide_diff_eq_iff
  (* multiply eqn *)
  nonzero_eq_divide_eq nonzero_divide_eq_eq
(* is added later:
  times_divide_eq_left times_divide_eq_right
*)

text{*An example:*}
lemma fixes a b c d e f :: "'a::field"
shows "\<lbrakk>a\<noteq>b; c\<noteq>d; e\<noteq>f \<rbrakk> \<Longrightarrow> ((a-b)*(c-d)*(e-f))/((c-d)*(e-f)*(a-b)) = 1"
apply(subgoal_tac "(c-d)*(e-f)*(a-b) \<noteq> 0")
 apply(simp add:field_eq_simps)
apply(simp)
done


lemma diff_frac_eq: "(y::'a::field) ~= 0 ==> z ~= 0 ==>
    x / y - w / z = (x * z - w * y) / (y * z)"
by (simp add:field_eq_simps times_divide_eq)

lemma frac_eq_eq: "(y::'a::field) ~= 0 ==> z ~= 0 ==>
    (x / y = w / z) = (x * z = w * y)"
by (simp add:field_eq_simps times_divide_eq)


subsection {* Ordered Fields *}

lemma positive_imp_inverse_positive: 
assumes a_gt_0: "0 < a"  shows "0 < inverse (a::'a::ordered_field)"
proof -
  have "0 < a * inverse a" 
    by (simp add: a_gt_0 [THEN order_less_imp_not_eq2] zero_less_one)
  thus "0 < inverse a" 
    by (simp add: a_gt_0 [THEN order_less_not_sym] zero_less_mult_iff)
qed

lemma negative_imp_inverse_negative:
  "a < 0 ==> inverse a < (0::'a::ordered_field)"
by (insert positive_imp_inverse_positive [of "-a"], 
    simp add: nonzero_inverse_minus_eq order_less_imp_not_eq)

lemma inverse_le_imp_le:
assumes invle: "inverse a \<le> inverse b" and apos:  "0 < a"
shows "b \<le> (a::'a::ordered_field)"
proof (rule classical)
  assume "~ b \<le> a"
  hence "a < b"  by (simp add: linorder_not_le)
  hence bpos: "0 < b"  by (blast intro: apos order_less_trans)
  hence "a * inverse a \<le> a * inverse b"
    by (simp add: apos invle order_less_imp_le mult_left_mono)
  hence "(a * inverse a) * b \<le> (a * inverse b) * b"
    by (simp add: bpos order_less_imp_le mult_right_mono)
  thus "b \<le> a"  by (simp add: mult_assoc apos bpos order_less_imp_not_eq2)
qed

lemma inverse_positive_imp_positive:
assumes inv_gt_0: "0 < inverse a" and nz: "a \<noteq> 0"
shows "0 < (a::'a::ordered_field)"
proof -
  have "0 < inverse (inverse a)"
    using inv_gt_0 by (rule positive_imp_inverse_positive)
  thus "0 < a"
    using nz by (simp add: nonzero_inverse_inverse_eq)
qed

lemma inverse_positive_iff_positive [simp]:
  "(0 < inverse a) = (0 < (a::'a::{ordered_field,division_by_zero}))"
apply (cases "a = 0", simp)
apply (blast intro: inverse_positive_imp_positive positive_imp_inverse_positive)
done

lemma inverse_negative_imp_negative:
assumes inv_less_0: "inverse a < 0" and nz:  "a \<noteq> 0"
shows "a < (0::'a::ordered_field)"
proof -
  have "inverse (inverse a) < 0"
    using inv_less_0 by (rule negative_imp_inverse_negative)
  thus "a < 0" using nz by (simp add: nonzero_inverse_inverse_eq)
qed

lemma inverse_negative_iff_negative [simp]:
  "(inverse a < 0) = (a < (0::'a::{ordered_field,division_by_zero}))"
apply (cases "a = 0", simp)
apply (blast intro: inverse_negative_imp_negative negative_imp_inverse_negative)
done

lemma inverse_nonnegative_iff_nonnegative [simp]:
  "(0 \<le> inverse a) = (0 \<le> (a::'a::{ordered_field,division_by_zero}))"
by (simp add: linorder_not_less [symmetric])

lemma inverse_nonpositive_iff_nonpositive [simp]:
  "(inverse a \<le> 0) = (a \<le> (0::'a::{ordered_field,division_by_zero}))"
by (simp add: linorder_not_less [symmetric])

lemma ordered_field_no_lb: "\<forall> x. \<exists>y. y < (x::'a::ordered_field)"
proof
  fix x::'a
  have m1: "- (1::'a) < 0" by simp
  from add_strict_right_mono[OF m1, where c=x] 
  have "(- 1) + x < x" by simp
  thus "\<exists>y. y < x" by blast
qed

lemma ordered_field_no_ub: "\<forall> x. \<exists>y. y > (x::'a::ordered_field)"
proof
  fix x::'a
  have m1: " (1::'a) > 0" by simp
  from add_strict_right_mono[OF m1, where c=x] 
  have "1 + x > x" by simp
  thus "\<exists>y. y > x" by blast
qed

subsection{*Anti-Monotonicity of @{term inverse}*}

lemma less_imp_inverse_less:
assumes less: "a < b" and apos:  "0 < a"
shows "inverse b < inverse (a::'a::ordered_field)"
proof (rule ccontr)
  assume "~ inverse b < inverse a"
  hence "inverse a \<le> inverse b"
    by (simp add: linorder_not_less)
  hence "~ (a < b)"
    by (simp add: linorder_not_less inverse_le_imp_le [OF _ apos])
  thus False
    by (rule notE [OF _ less])
qed

lemma inverse_less_imp_less:
  "[|inverse a < inverse b; 0 < a|] ==> b < (a::'a::ordered_field)"
apply (simp add: order_less_le [of "inverse a"] order_less_le [of "b"])
apply (force dest!: inverse_le_imp_le nonzero_inverse_eq_imp_eq) 
done

text{*Both premises are essential. Consider -1 and 1.*}
lemma inverse_less_iff_less [simp]:
  "[|0 < a; 0 < b|] ==> (inverse a < inverse b) = (b < (a::'a::ordered_field))"
by (blast intro: less_imp_inverse_less dest: inverse_less_imp_less) 

lemma le_imp_inverse_le:
  "[|a \<le> b; 0 < a|] ==> inverse b \<le> inverse (a::'a::ordered_field)"
by (force simp add: order_le_less less_imp_inverse_less)

lemma inverse_le_iff_le [simp]:
 "[|0 < a; 0 < b|] ==> (inverse a \<le> inverse b) = (b \<le> (a::'a::ordered_field))"
by (blast intro: le_imp_inverse_le dest: inverse_le_imp_le) 


text{*These results refer to both operands being negative.  The opposite-sign
case is trivial, since inverse preserves signs.*}
lemma inverse_le_imp_le_neg:
  "[|inverse a \<le> inverse b; b < 0|] ==> b \<le> (a::'a::ordered_field)"
apply (rule classical) 
apply (subgoal_tac "a < 0") 
 prefer 2 apply (force simp add: linorder_not_le intro: order_less_trans) 
apply (insert inverse_le_imp_le [of "-b" "-a"])
apply (simp add: order_less_imp_not_eq nonzero_inverse_minus_eq) 
done

lemma less_imp_inverse_less_neg:
   "[|a < b; b < 0|] ==> inverse b < inverse (a::'a::ordered_field)"
apply (subgoal_tac "a < 0") 
 prefer 2 apply (blast intro: order_less_trans) 
apply (insert less_imp_inverse_less [of "-b" "-a"])
apply (simp add: order_less_imp_not_eq nonzero_inverse_minus_eq) 
done

lemma inverse_less_imp_less_neg:
   "[|inverse a < inverse b; b < 0|] ==> b < (a::'a::ordered_field)"
apply (rule classical) 
apply (subgoal_tac "a < 0") 
 prefer 2
 apply (force simp add: linorder_not_less intro: order_le_less_trans) 
apply (insert inverse_less_imp_less [of "-b" "-a"])
apply (simp add: order_less_imp_not_eq nonzero_inverse_minus_eq) 
done

lemma inverse_less_iff_less_neg [simp]:
  "[|a < 0; b < 0|] ==> (inverse a < inverse b) = (b < (a::'a::ordered_field))"
apply (insert inverse_less_iff_less [of "-b" "-a"])
apply (simp del: inverse_less_iff_less 
            add: order_less_imp_not_eq nonzero_inverse_minus_eq)
done

lemma le_imp_inverse_le_neg:
  "[|a \<le> b; b < 0|] ==> inverse b \<le> inverse (a::'a::ordered_field)"
by (force simp add: order_le_less less_imp_inverse_less_neg)

lemma inverse_le_iff_le_neg [simp]:
 "[|a < 0; b < 0|] ==> (inverse a \<le> inverse b) = (b \<le> (a::'a::ordered_field))"
by (blast intro: le_imp_inverse_le_neg dest: inverse_le_imp_le_neg) 


subsection{*Inverses and the Number One*}

lemma one_less_inverse_iff:
  "(1 < inverse x) = (0 < x & x < (1::'a::{ordered_field,division_by_zero}))"
proof cases
  assume "0 < x"
    with inverse_less_iff_less [OF zero_less_one, of x]
    show ?thesis by simp
next
  assume notless: "~ (0 < x)"
  have "~ (1 < inverse x)"
  proof
    assume "1 < inverse x"
    also with notless have "... \<le> 0" by (simp add: linorder_not_less)
    also have "... < 1" by (rule zero_less_one) 
    finally show False by auto
  qed
  with notless show ?thesis by simp
qed

lemma inverse_eq_1_iff [simp]:
  "(inverse x = 1) = (x = (1::'a::{field,division_by_zero}))"
by (insert inverse_eq_iff_eq [of x 1], simp) 

lemma one_le_inverse_iff:
  "(1 \<le> inverse x) = (0 < x & x \<le> (1::'a::{ordered_field,division_by_zero}))"
by (force simp add: order_le_less one_less_inverse_iff zero_less_one 
                    eq_commute [of 1]) 

lemma inverse_less_1_iff:
  "(inverse x < 1) = (x \<le> 0 | 1 < (x::'a::{ordered_field,division_by_zero}))"
by (simp add: linorder_not_le [symmetric] one_le_inverse_iff) 

lemma inverse_le_1_iff:
  "(inverse x \<le> 1) = (x \<le> 0 | 1 \<le> (x::'a::{ordered_field,division_by_zero}))"
by (simp add: linorder_not_less [symmetric] one_less_inverse_iff) 


subsection{*Simplification of Inequalities Involving Literal Divisors*}

lemma pos_le_divide_eq: "0 < (c::'a::ordered_field) ==> (a \<le> b/c) = (a*c \<le> b)"
proof -
  assume less: "0<c"
  hence "(a \<le> b/c) = (a*c \<le> (b/c)*c)"
    by (simp add: mult_le_cancel_right order_less_not_sym [OF less])
  also have "... = (a*c \<le> b)"
    by (simp add: order_less_imp_not_eq2 [OF less] divide_inverse mult_assoc) 
  finally show ?thesis .
qed

lemma neg_le_divide_eq: "c < (0::'a::ordered_field) ==> (a \<le> b/c) = (b \<le> a*c)"
proof -
  assume less: "c<0"
  hence "(a \<le> b/c) = ((b/c)*c \<le> a*c)"
    by (simp add: mult_le_cancel_right order_less_not_sym [OF less])
  also have "... = (b \<le> a*c)"
    by (simp add: order_less_imp_not_eq [OF less] divide_inverse mult_assoc) 
  finally show ?thesis .
qed

lemma le_divide_eq:
  "(a \<le> b/c) = 
   (if 0 < c then a*c \<le> b
             else if c < 0 then b \<le> a*c
             else  a \<le> (0::'a::{ordered_field,division_by_zero}))"
apply (cases "c=0", simp) 
apply (force simp add: pos_le_divide_eq neg_le_divide_eq linorder_neq_iff) 
done

lemma pos_divide_le_eq: "0 < (c::'a::ordered_field) ==> (b/c \<le> a) = (b \<le> a*c)"
proof -
  assume less: "0<c"
  hence "(b/c \<le> a) = ((b/c)*c \<le> a*c)"
    by (simp add: mult_le_cancel_right order_less_not_sym [OF less])
  also have "... = (b \<le> a*c)"
    by (simp add: order_less_imp_not_eq2 [OF less] divide_inverse mult_assoc) 
  finally show ?thesis .
qed

lemma neg_divide_le_eq: "c < (0::'a::ordered_field) ==> (b/c \<le> a) = (a*c \<le> b)"
proof -
  assume less: "c<0"
  hence "(b/c \<le> a) = (a*c \<le> (b/c)*c)"
    by (simp add: mult_le_cancel_right order_less_not_sym [OF less])
  also have "... = (a*c \<le> b)"
    by (simp add: order_less_imp_not_eq [OF less] divide_inverse mult_assoc) 
  finally show ?thesis .
qed

lemma divide_le_eq:
  "(b/c \<le> a) = 
   (if 0 < c then b \<le> a*c
             else if c < 0 then a*c \<le> b
             else 0 \<le> (a::'a::{ordered_field,division_by_zero}))"
apply (cases "c=0", simp) 
apply (force simp add: pos_divide_le_eq neg_divide_le_eq linorder_neq_iff) 
done

lemma pos_less_divide_eq:
     "0 < (c::'a::ordered_field) ==> (a < b/c) = (a*c < b)"
proof -
  assume less: "0<c"
  hence "(a < b/c) = (a*c < (b/c)*c)"
    by (simp add: mult_less_cancel_right_disj order_less_not_sym [OF less])
  also have "... = (a*c < b)"
    by (simp add: order_less_imp_not_eq2 [OF less] divide_inverse mult_assoc) 
  finally show ?thesis .
qed

lemma neg_less_divide_eq:
 "c < (0::'a::ordered_field) ==> (a < b/c) = (b < a*c)"
proof -
  assume less: "c<0"
  hence "(a < b/c) = ((b/c)*c < a*c)"
    by (simp add: mult_less_cancel_right_disj order_less_not_sym [OF less])
  also have "... = (b < a*c)"
    by (simp add: order_less_imp_not_eq [OF less] divide_inverse mult_assoc) 
  finally show ?thesis .
qed

lemma less_divide_eq:
  "(a < b/c) = 
   (if 0 < c then a*c < b
             else if c < 0 then b < a*c
             else  a < (0::'a::{ordered_field,division_by_zero}))"
apply (cases "c=0", simp) 
apply (force simp add: pos_less_divide_eq neg_less_divide_eq linorder_neq_iff) 
done

lemma pos_divide_less_eq:
     "0 < (c::'a::ordered_field) ==> (b/c < a) = (b < a*c)"
proof -
  assume less: "0<c"
  hence "(b/c < a) = ((b/c)*c < a*c)"
    by (simp add: mult_less_cancel_right_disj order_less_not_sym [OF less])
  also have "... = (b < a*c)"
    by (simp add: order_less_imp_not_eq2 [OF less] divide_inverse mult_assoc) 
  finally show ?thesis .
qed

lemma neg_divide_less_eq:
 "c < (0::'a::ordered_field) ==> (b/c < a) = (a*c < b)"
proof -
  assume less: "c<0"
  hence "(b/c < a) = (a*c < (b/c)*c)"
    by (simp add: mult_less_cancel_right_disj order_less_not_sym [OF less])
  also have "... = (a*c < b)"
    by (simp add: order_less_imp_not_eq [OF less] divide_inverse mult_assoc) 
  finally show ?thesis .
qed

lemma divide_less_eq:
  "(b/c < a) = 
   (if 0 < c then b < a*c
             else if c < 0 then a*c < b
             else 0 < (a::'a::{ordered_field,division_by_zero}))"
apply (cases "c=0", simp) 
apply (force simp add: pos_divide_less_eq neg_divide_less_eq linorder_neq_iff) 
done


subsection{*Field simplification*}

text{* Lemmas @{text field_simps} multiply with denominators in
in(equations) if they can be proved to be non-zero (for equations) or
positive/negative (for inequations). *}

lemmas field_simps = field_eq_simps
  (* multiply ineqn *)
  pos_divide_less_eq neg_divide_less_eq
  pos_less_divide_eq neg_less_divide_eq
  pos_divide_le_eq neg_divide_le_eq
  pos_le_divide_eq neg_le_divide_eq

text{* Lemmas @{text sign_simps} is a first attempt to automate proofs
of positivity/negativity needed for @{text field_simps}. Have not added @{text
sign_simps} to @{text field_simps} because the former can lead to case
explosions. *}

lemmas sign_simps = group_simps
  zero_less_mult_iff  mult_less_0_iff

(* Only works once linear arithmetic is installed:
text{*An example:*}
lemma fixes a b c d e f :: "'a::ordered_field"
shows "\<lbrakk>a>b; c<d; e<f; 0 < u \<rbrakk> \<Longrightarrow>
 ((a-b)*(c-d)*(e-f))/((c-d)*(e-f)*(a-b)) <
 ((e-f)*(a-b)*(c-d))/((e-f)*(a-b)*(c-d)) + u"
apply(subgoal_tac "(c-d)*(e-f)*(a-b) > 0")
 prefer 2 apply(simp add:sign_simps)
apply(subgoal_tac "(c-d)*(e-f)*(a-b)*u > 0")
 prefer 2 apply(simp add:sign_simps)
apply(simp add:field_simps)
done
*)


subsection{*Division and Signs*}

lemma zero_less_divide_iff:
     "((0::'a::{ordered_field,division_by_zero}) < a/b) = (0 < a & 0 < b | a < 0 & b < 0)"
by (simp add: divide_inverse zero_less_mult_iff)

lemma divide_less_0_iff:
     "(a/b < (0::'a::{ordered_field,division_by_zero})) = 
      (0 < a & b < 0 | a < 0 & 0 < b)"
by (simp add: divide_inverse mult_less_0_iff)

lemma zero_le_divide_iff:
     "((0::'a::{ordered_field,division_by_zero}) \<le> a/b) =
      (0 \<le> a & 0 \<le> b | a \<le> 0 & b \<le> 0)"
by (simp add: divide_inverse zero_le_mult_iff)

lemma divide_le_0_iff:
     "(a/b \<le> (0::'a::{ordered_field,division_by_zero})) =
      (0 \<le> a & b \<le> 0 | a \<le> 0 & 0 \<le> b)"
by (simp add: divide_inverse mult_le_0_iff)

lemma divide_eq_0_iff [simp]:
     "(a/b = 0) = (a=0 | b=(0::'a::{field,division_by_zero}))"
by (simp add: divide_inverse)

lemma divide_pos_pos:
  "0 < (x::'a::ordered_field) ==> 0 < y ==> 0 < x / y"
by(simp add:field_simps)


lemma divide_nonneg_pos:
  "0 <= (x::'a::ordered_field) ==> 0 < y ==> 0 <= x / y"
by(simp add:field_simps)

lemma divide_neg_pos:
  "(x::'a::ordered_field) < 0 ==> 0 < y ==> x / y < 0"
by(simp add:field_simps)

lemma divide_nonpos_pos:
  "(x::'a::ordered_field) <= 0 ==> 0 < y ==> x / y <= 0"
by(simp add:field_simps)

lemma divide_pos_neg:
  "0 < (x::'a::ordered_field) ==> y < 0 ==> x / y < 0"
by(simp add:field_simps)

lemma divide_nonneg_neg:
  "0 <= (x::'a::ordered_field) ==> y < 0 ==> x / y <= 0" 
by(simp add:field_simps)

lemma divide_neg_neg:
  "(x::'a::ordered_field) < 0 ==> y < 0 ==> 0 < x / y"
by(simp add:field_simps)

lemma divide_nonpos_neg:
  "(x::'a::ordered_field) <= 0 ==> y < 0 ==> 0 <= x / y"
by(simp add:field_simps)


subsection{*Cancellation Laws for Division*}

lemma divide_cancel_right [simp]:
     "(a/c = b/c) = (c = 0 | a = (b::'a::{field,division_by_zero}))"
apply (cases "c=0", simp)
apply (simp add: divide_inverse)
done

lemma divide_cancel_left [simp]:
     "(c/a = c/b) = (c = 0 | a = (b::'a::{field,division_by_zero}))" 
apply (cases "c=0", simp)
apply (simp add: divide_inverse)
done


subsection {* Division and the Number One *}

text{*Simplify expressions equated with 1*}
lemma divide_eq_1_iff [simp]:
     "(a/b = 1) = (b \<noteq> 0 & a = (b::'a::{field,division_by_zero}))"
apply (cases "b=0", simp)
apply (simp add: right_inverse_eq)
done

lemma one_eq_divide_iff [simp]:
     "(1 = a/b) = (b \<noteq> 0 & a = (b::'a::{field,division_by_zero}))"
by (simp add: eq_commute [of 1])

lemma zero_eq_1_divide_iff [simp]:
     "((0::'a::{ordered_field,division_by_zero}) = 1/a) = (a = 0)"
apply (cases "a=0", simp)
apply (auto simp add: nonzero_eq_divide_eq)
done

lemma one_divide_eq_0_iff [simp]:
     "(1/a = (0::'a::{ordered_field,division_by_zero})) = (a = 0)"
apply (cases "a=0", simp)
apply (insert zero_neq_one [THEN not_sym])
apply (auto simp add: nonzero_divide_eq_eq)
done

text{*Simplify expressions such as @{text "0 < 1/x"} to @{text "0 < x"}*}
lemmas zero_less_divide_1_iff = zero_less_divide_iff [of 1, simplified]
lemmas divide_less_0_1_iff = divide_less_0_iff [of 1, simplified]
lemmas zero_le_divide_1_iff = zero_le_divide_iff [of 1, simplified]
lemmas divide_le_0_1_iff = divide_le_0_iff [of 1, simplified]

declare zero_less_divide_1_iff [simp]
declare divide_less_0_1_iff [simp]
declare zero_le_divide_1_iff [simp]
declare divide_le_0_1_iff [simp]


subsection {* Ordering Rules for Division *}

lemma divide_strict_right_mono:
     "[|a < b; 0 < c|] ==> a / c < b / (c::'a::ordered_field)"
by (simp add: order_less_imp_not_eq2 divide_inverse mult_strict_right_mono 
              positive_imp_inverse_positive)

lemma divide_right_mono:
     "[|a \<le> b; 0 \<le> c|] ==> a/c \<le> b/(c::'a::{ordered_field,division_by_zero})"
by (force simp add: divide_strict_right_mono order_le_less)

lemma divide_right_mono_neg: "(a::'a::{division_by_zero,ordered_field}) <= b 
    ==> c <= 0 ==> b / c <= a / c"
apply (drule divide_right_mono [of _ _ "- c"])
apply auto
done

lemma divide_strict_right_mono_neg:
     "[|b < a; c < 0|] ==> a / c < b / (c::'a::ordered_field)"
apply (drule divide_strict_right_mono [of _ _ "-c"], simp)
apply (simp add: order_less_imp_not_eq nonzero_minus_divide_right [symmetric])
done

text{*The last premise ensures that @{term a} and @{term b} 
      have the same sign*}
lemma divide_strict_left_mono:
  "[|b < a; 0 < c; 0 < a*b|] ==> c / a < c / (b::'a::ordered_field)"
by(auto simp: field_simps times_divide_eq zero_less_mult_iff mult_strict_right_mono)

lemma divide_left_mono:
  "[|b \<le> a; 0 \<le> c; 0 < a*b|] ==> c / a \<le> c / (b::'a::ordered_field)"
by(auto simp: field_simps times_divide_eq zero_less_mult_iff mult_right_mono)

lemma divide_left_mono_neg: "(a::'a::{division_by_zero,ordered_field}) <= b 
    ==> c <= 0 ==> 0 < a * b ==> c / a <= c / b"
  apply (drule divide_left_mono [of _ _ "- c"])
  apply (auto simp add: mult_commute)
done

lemma divide_strict_left_mono_neg:
  "[|a < b; c < 0; 0 < a*b|] ==> c / a < c / (b::'a::ordered_field)"
by(auto simp: field_simps times_divide_eq zero_less_mult_iff mult_strict_right_mono_neg)


text{*Simplify quotients that are compared with the value 1.*}

lemma le_divide_eq_1:
  fixes a :: "'a :: {ordered_field,division_by_zero}"
  shows "(1 \<le> b / a) = ((0 < a & a \<le> b) | (a < 0 & b \<le> a))"
by (auto simp add: le_divide_eq)

lemma divide_le_eq_1:
  fixes a :: "'a :: {ordered_field,division_by_zero}"
  shows "(b / a \<le> 1) = ((0 < a & b \<le> a) | (a < 0 & a \<le> b) | a=0)"
by (auto simp add: divide_le_eq)

lemma less_divide_eq_1:
  fixes a :: "'a :: {ordered_field,division_by_zero}"
  shows "(1 < b / a) = ((0 < a & a < b) | (a < 0 & b < a))"
by (auto simp add: less_divide_eq)

lemma divide_less_eq_1:
  fixes a :: "'a :: {ordered_field,division_by_zero}"
  shows "(b / a < 1) = ((0 < a & b < a) | (a < 0 & a < b) | a=0)"
by (auto simp add: divide_less_eq)


subsection{*Conditional Simplification Rules: No Case Splits*}

lemma le_divide_eq_1_pos [simp]:
  fixes a :: "'a :: {ordered_field,division_by_zero}"
  shows "0 < a \<Longrightarrow> (1 \<le> b/a) = (a \<le> b)"
by (auto simp add: le_divide_eq)

lemma le_divide_eq_1_neg [simp]:
  fixes a :: "'a :: {ordered_field,division_by_zero}"
  shows "a < 0 \<Longrightarrow> (1 \<le> b/a) = (b \<le> a)"
by (auto simp add: le_divide_eq)

lemma divide_le_eq_1_pos [simp]:
  fixes a :: "'a :: {ordered_field,division_by_zero}"
  shows "0 < a \<Longrightarrow> (b/a \<le> 1) = (b \<le> a)"
by (auto simp add: divide_le_eq)

lemma divide_le_eq_1_neg [simp]:
  fixes a :: "'a :: {ordered_field,division_by_zero}"
  shows "a < 0 \<Longrightarrow> (b/a \<le> 1) = (a \<le> b)"
by (auto simp add: divide_le_eq)

lemma less_divide_eq_1_pos [simp]:
  fixes a :: "'a :: {ordered_field,division_by_zero}"
  shows "0 < a \<Longrightarrow> (1 < b/a) = (a < b)"
by (auto simp add: less_divide_eq)

lemma less_divide_eq_1_neg [simp]:
  fixes a :: "'a :: {ordered_field,division_by_zero}"
  shows "a < 0 \<Longrightarrow> (1 < b/a) = (b < a)"
by (auto simp add: less_divide_eq)

lemma divide_less_eq_1_pos [simp]:
  fixes a :: "'a :: {ordered_field,division_by_zero}"
  shows "0 < a \<Longrightarrow> (b/a < 1) = (b < a)"
by (auto simp add: divide_less_eq)

lemma divide_less_eq_1_neg [simp]:
  fixes a :: "'a :: {ordered_field,division_by_zero}"
  shows "a < 0 \<Longrightarrow> b/a < 1 <-> a < b"
by (auto simp add: divide_less_eq)

lemma eq_divide_eq_1 [simp]:
  fixes a :: "'a :: {ordered_field,division_by_zero}"
  shows "(1 = b/a) = ((a \<noteq> 0 & a = b))"
by (auto simp add: eq_divide_eq)

lemma divide_eq_eq_1 [simp]:
  fixes a :: "'a :: {ordered_field,division_by_zero}"
  shows "(b/a = 1) = ((a \<noteq> 0 & a = b))"
by (auto simp add: divide_eq_eq)


subsection {* Reasoning about inequalities with division *}

lemma mult_right_le_one_le: "0 <= (x::'a::ordered_idom) ==> 0 <= y ==> y <= 1
    ==> x * y <= x"
  by (auto simp add: mult_compare_simps);

lemma mult_left_le_one_le: "0 <= (x::'a::ordered_idom) ==> 0 <= y ==> y <= 1
    ==> y * x <= x"
  by (auto simp add: mult_compare_simps);

lemma mult_imp_div_pos_le: "0 < (y::'a::ordered_field) ==> x <= z * y ==>
    x / y <= z";
  by (subst pos_divide_le_eq, assumption+);

lemma mult_imp_le_div_pos: "0 < (y::'a::ordered_field) ==> z * y <= x ==>
    z <= x / y"
by(simp add:field_simps)

lemma mult_imp_div_pos_less: "0 < (y::'a::ordered_field) ==> x < z * y ==>
    x / y < z"
by(simp add:field_simps)

lemma mult_imp_less_div_pos: "0 < (y::'a::ordered_field) ==> z * y < x ==>
    z < x / y"
by(simp add:field_simps)

lemma frac_le: "(0::'a::ordered_field) <= x ==> 
    x <= y ==> 0 < w ==> w <= z  ==> x / z <= y / w"
  apply (rule mult_imp_div_pos_le)
  apply simp;
  apply (subst times_divide_eq_left);
  apply (rule mult_imp_le_div_pos, assumption)
  apply (rule mult_mono)
  apply simp_all
done

lemma frac_less: "(0::'a::ordered_field) <= x ==> 
    x < y ==> 0 < w ==> w <= z  ==> x / z < y / w"
  apply (rule mult_imp_div_pos_less)
  apply simp;
  apply (subst times_divide_eq_left);
  apply (rule mult_imp_less_div_pos, assumption)
  apply (erule mult_less_le_imp_less)
  apply simp_all
done

lemma frac_less2: "(0::'a::ordered_field) < x ==> 
    x <= y ==> 0 < w ==> w < z  ==> x / z < y / w"
  apply (rule mult_imp_div_pos_less)
  apply simp_all
  apply (subst times_divide_eq_left);
  apply (rule mult_imp_less_div_pos, assumption)
  apply (erule mult_le_less_imp_less)
  apply simp_all
done

text{*It's not obvious whether these should be simprules or not. 
  Their effect is to gather terms into one big fraction, like
  a*b*c / x*y*z. The rationale for that is unclear, but many proofs 
  seem to need them.*}

declare times_divide_eq [simp]


subsection {* Ordered Fields are Dense *}

lemma less_add_one: "a < (a+1::'a::ordered_semidom)"
proof -
  have "a+0 < (a+1::'a::ordered_semidom)"
    by (blast intro: zero_less_one add_strict_left_mono)
  thus ?thesis by simp
qed

lemma zero_less_two: "0 < (1+1::'a::ordered_semidom)"
by (blast intro: order_less_trans zero_less_one less_add_one)

lemma less_half_sum: "a < b ==> a < (a+b) / (1+1::'a::ordered_field)"
by (simp add: field_simps zero_less_two)

lemma gt_half_sum: "a < b ==> (a+b)/(1+1::'a::ordered_field) < b"
by (simp add: field_simps zero_less_two)

lemma dense: "a < b ==> \<exists>r::'a::ordered_field. a < r & r < b"
by (blast intro!: less_half_sum gt_half_sum)


subsection {* Absolute Value *}

lemma abs_one [simp]: "abs 1 = (1::'a::ordered_idom)"
by (simp add: abs_if zero_less_one [THEN order_less_not_sym])

lemma abs_le_mult: "abs (a * b) \<le> (abs a) * (abs (b::'a::lordered_ring))" 
proof -
  let ?x = "pprt a * pprt b - pprt a * nprt b - nprt a * pprt b + nprt a * nprt b"
  let ?y = "pprt a * pprt b + pprt a * nprt b + nprt a * pprt b + nprt a * nprt b"
  have a: "(abs a) * (abs b) = ?x"
    by (simp only: abs_prts[of a] abs_prts[of b] ring_simps)
  {
    fix u v :: 'a
    have bh: "\<lbrakk>u = a; v = b\<rbrakk> \<Longrightarrow> 
              u * v = pprt a * pprt b + pprt a * nprt b + 
                      nprt a * pprt b + nprt a * nprt b"
      apply (subst prts[of u], subst prts[of v])
      apply (simp add: ring_simps) 
      done
  }
  note b = this[OF refl[of a] refl[of b]]
  note addm = add_mono[of "0::'a" _ "0::'a", simplified]
  note addm2 = add_mono[of _ "0::'a" _ "0::'a", simplified]
  have xy: "- ?x <= ?y"
    apply (simp)
    apply (rule_tac y="0::'a" in order_trans)
    apply (rule addm2)
    apply (simp_all add: mult_nonneg_nonneg mult_nonpos_nonpos)
    apply (rule addm)
    apply (simp_all add: mult_nonneg_nonneg mult_nonpos_nonpos)
    done
  have yx: "?y <= ?x"
    apply (simp add:diff_def)
    apply (rule_tac y=0 in order_trans)
    apply (rule addm2, (simp add: mult_nonneg_nonpos mult_nonneg_nonpos2)+)
    apply (rule addm, (simp add: mult_nonneg_nonpos mult_nonneg_nonpos2)+)
    done
  have i1: "a*b <= abs a * abs b" by (simp only: a b yx)
  have i2: "- (abs a * abs b) <= a*b" by (simp only: a b xy)
  show ?thesis
    apply (rule abs_leI)
    apply (simp add: i1)
    apply (simp add: i2[simplified minus_le_iff])
    done
qed

lemma abs_eq_mult: 
  assumes "(0 \<le> a \<or> a \<le> 0) \<and> (0 \<le> b \<or> b \<le> 0)"
  shows "abs (a*b) = abs a * abs (b::'a::lordered_ring)"
proof -
  have s: "(0 <= a*b) | (a*b <= 0)"
    apply (auto)    
    apply (rule_tac split_mult_pos_le)
    apply (rule_tac contrapos_np[of "a*b <= 0"])
    apply (simp)
    apply (rule_tac split_mult_neg_le)
    apply (insert prems)
    apply (blast)
    done
  have mulprts: "a * b = (pprt a + nprt a) * (pprt b + nprt b)"
    by (simp add: prts[symmetric])
  show ?thesis
  proof cases
    assume "0 <= a * b"
    then show ?thesis
      apply (simp_all add: mulprts abs_prts)
      apply (insert prems)
      apply (auto simp add: 
	ring_simps 
	iff2imp[OF zero_le_iff_zero_nprt] iff2imp[OF le_zero_iff_zero_pprt]
	iff2imp[OF le_zero_iff_pprt_id] iff2imp[OF zero_le_iff_nprt_id])
	apply(drule (1) mult_nonneg_nonpos[of a b], simp)
	apply(drule (1) mult_nonneg_nonpos2[of b a], simp)
      done
  next
    assume "~(0 <= a*b)"
    with s have "a*b <= 0" by simp
    then show ?thesis
      apply (simp_all add: mulprts abs_prts)
      apply (insert prems)
      apply (auto simp add: ring_simps)
      apply(drule (1) mult_nonneg_nonneg[of a b],simp)
      apply(drule (1) mult_nonpos_nonpos[of a b],simp)
      done
  qed
qed

lemma abs_mult: "abs (a * b) = abs a * abs (b::'a::ordered_idom)" 
by (simp add: abs_eq_mult linorder_linear)

lemma abs_mult_self: "abs a * abs a = a * (a::'a::ordered_idom)"
by (simp add: abs_if) 

lemma nonzero_abs_inverse:
     "a \<noteq> 0 ==> abs (inverse (a::'a::ordered_field)) = inverse (abs a)"
apply (auto simp add: linorder_neq_iff abs_if nonzero_inverse_minus_eq 
                      negative_imp_inverse_negative)
apply (blast intro: positive_imp_inverse_positive elim: order_less_asym) 
done

lemma abs_inverse [simp]:
     "abs (inverse (a::'a::{ordered_field,division_by_zero})) = 
      inverse (abs a)"
apply (cases "a=0", simp) 
apply (simp add: nonzero_abs_inverse) 
done

lemma nonzero_abs_divide:
     "b \<noteq> 0 ==> abs (a / (b::'a::ordered_field)) = abs a / abs b"
by (simp add: divide_inverse abs_mult nonzero_abs_inverse) 

lemma abs_divide [simp]:
     "abs (a / (b::'a::{ordered_field,division_by_zero})) = abs a / abs b"
apply (cases "b=0", simp) 
apply (simp add: nonzero_abs_divide) 
done

lemma abs_mult_less:
     "[| abs a < c; abs b < d |] ==> abs a * abs b < c*(d::'a::ordered_idom)"
proof -
  assume ac: "abs a < c"
  hence cpos: "0<c" by (blast intro: order_le_less_trans abs_ge_zero)
  assume "abs b < d"
  thus ?thesis by (simp add: ac cpos mult_strict_mono) 
qed

lemma eq_minus_self_iff: "(a = -a) = (a = (0::'a::ordered_idom))"
by (force simp add: order_eq_iff le_minus_self_iff minus_le_self_iff)

lemma less_minus_self_iff: "(a < -a) = (a < (0::'a::ordered_idom))"
by (simp add: order_less_le le_minus_self_iff eq_minus_self_iff)

lemma abs_less_iff: "(abs a < b) = (a < b & -a < (b::'a::ordered_idom))" 
apply (simp add: order_less_le abs_le_iff)  
apply (auto simp add: abs_if minus_le_self_iff eq_minus_self_iff)
apply (simp add: le_minus_self_iff linorder_neq_iff) 
done

lemma abs_mult_pos: "(0::'a::ordered_idom) <= x ==> 
    (abs y) * x = abs (y * x)";
  apply (subst abs_mult);
  apply simp;
done;

lemma abs_div_pos: "(0::'a::{division_by_zero,ordered_field}) < y ==> 
    abs x / y = abs (x / y)";
  apply (subst abs_divide);
  apply (simp add: order_less_imp_le);
done;


subsection {* Bounds of products via negative and positive Part *}

lemma mult_le_prts:
  assumes
  "a1 <= (a::'a::lordered_ring)"
  "a <= a2"
  "b1 <= b"
  "b <= b2"
  shows
  "a * b <= pprt a2 * pprt b2 + pprt a1 * nprt b2 + nprt a2 * pprt b1 + nprt a1 * nprt b1"
proof - 
  have "a * b = (pprt a + nprt a) * (pprt b + nprt b)" 
    apply (subst prts[symmetric])+
    apply simp
    done
  then have "a * b = pprt a * pprt b + pprt a * nprt b + nprt a * pprt b + nprt a * nprt b"
    by (simp add: ring_simps)
  moreover have "pprt a * pprt b <= pprt a2 * pprt b2"
    by (simp_all add: prems mult_mono)
  moreover have "pprt a * nprt b <= pprt a1 * nprt b2"
  proof -
    have "pprt a * nprt b <= pprt a * nprt b2"
      by (simp add: mult_left_mono prems)
    moreover have "pprt a * nprt b2 <= pprt a1 * nprt b2"
      by (simp add: mult_right_mono_neg prems)
    ultimately show ?thesis
      by simp
  qed
  moreover have "nprt a * pprt b <= nprt a2 * pprt b1"
  proof - 
    have "nprt a * pprt b <= nprt a2 * pprt b"
      by (simp add: mult_right_mono prems)
    moreover have "nprt a2 * pprt b <= nprt a2 * pprt b1"
      by (simp add: mult_left_mono_neg prems)
    ultimately show ?thesis
      by simp
  qed
  moreover have "nprt a * nprt b <= nprt a1 * nprt b1"
  proof -
    have "nprt a * nprt b <= nprt a * nprt b1"
      by (simp add: mult_left_mono_neg prems)
    moreover have "nprt a * nprt b1 <= nprt a1 * nprt b1"
      by (simp add: mult_right_mono_neg prems)
    ultimately show ?thesis
      by simp
  qed
  ultimately show ?thesis
    by - (rule add_mono | simp)+
qed

lemma mult_ge_prts:
  assumes
  "a1 <= (a::'a::lordered_ring)"
  "a <= a2"
  "b1 <= b"
  "b <= b2"
  shows
  "a * b >= nprt a1 * pprt b2 + nprt a2 * nprt b2 + pprt a1 * pprt b1 + pprt a2 * nprt b1"
proof - 
  from prems have a1:"- a2 <= -a" by auto
  from prems have a2: "-a <= -a1" by auto
  from mult_le_prts[of "-a2" "-a" "-a1" "b1" b "b2", OF a1 a2 prems(3) prems(4), simplified nprt_neg pprt_neg] 
  have le: "- (a * b) <= - nprt a1 * pprt b2 + - nprt a2 * nprt b2 + - pprt a1 * pprt b1 + - pprt a2 * nprt b1" by simp  
  then have "-(- nprt a1 * pprt b2 + - nprt a2 * nprt b2 + - pprt a1 * pprt b1 + - pprt a2 * nprt b1) <= a * b"
    by (simp only: minus_le_iff)
  then show ?thesis by simp
qed


subsection {* Theorems for proof tools *}

lemma add_mono_thms_ordered_semiring:
  fixes i j k :: "'a\<Colon>pordered_ab_semigroup_add"
  shows "i \<le> j \<and> k \<le> l \<Longrightarrow> i + k \<le> j + l"
    and "i = j \<and> k \<le> l \<Longrightarrow> i + k \<le> j + l"
    and "i \<le> j \<and> k = l \<Longrightarrow> i + k \<le> j + l"
    and "i = j \<and> k = l \<Longrightarrow> i + k = j + l"
by (rule add_mono, clarify+)+

lemma add_mono_thms_ordered_field:
  fixes i j k :: "'a\<Colon>pordered_cancel_ab_semigroup_add"
  shows "i < j \<and> k = l \<Longrightarrow> i + k < j + l"
    and "i = j \<and> k < l \<Longrightarrow> i + k < j + l"
    and "i < j \<and> k \<le> l \<Longrightarrow> i + k < j + l"
    and "i \<le> j \<and> k < l \<Longrightarrow> i + k < j + l"
    and "i < j \<and> k < l \<Longrightarrow> i + k < j + l"
by (auto intro: add_strict_right_mono add_strict_left_mono
  add_less_le_mono add_le_less_mono add_strict_mono)

end

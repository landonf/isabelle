(*  Title:      HOL/AxClasses/Group.thy
    ID:         $Id$
    Author:     Markus Wenzel, TU Muenchen
*)

theory Group imports Main begin

subsection {* Monoids and Groups *}

consts
  times :: "'a => 'a => 'a"    (infixl "[*]" 70)
  invers :: "'a => 'a"
  one :: 'a


axclass monoid < type
  assoc:      "(x [*] y) [*] z = x [*] (y [*] z)"
  left_unit:  "one [*] x = x"
  right_unit: "x [*] one = x"

axclass semigroup < type
  assoc: "(x [*] y) [*] z = x [*] (y [*] z)"

axclass group < semigroup
  left_unit:    "one [*] x = x"
  left_inverse: "invers x [*] x = one"

axclass agroup < group
  commute: "x [*] y = y [*] x"


subsection {* Abstract reasoning *}

theorem group_right_inverse: "x [*] invers x = (one::'a::group)"
proof -
  have "x [*] invers x = one [*] (x [*] invers x)"
    by (simp only: group_class.left_unit)
  also have "... = one [*] x [*] invers x"
    by (simp only: semigroup_class.assoc)
  also have "... = invers (invers x) [*] invers x [*] x [*] invers x"
    by (simp only: group_class.left_inverse)
  also have "... = invers (invers x) [*] (invers x [*] x) [*] invers x"
    by (simp only: semigroup_class.assoc)
  also have "... = invers (invers x) [*] one [*] invers x"
    by (simp only: group_class.left_inverse)
  also have "... = invers (invers x) [*] (one [*] invers x)"
    by (simp only: semigroup_class.assoc)
  also have "... = invers (invers x) [*] invers x"
    by (simp only: group_class.left_unit)
  also have "... = one"
    by (simp only: group_class.left_inverse)
  finally show ?thesis .
qed

theorem group_right_unit: "x [*] one = (x::'a::group)"
proof -
  have "x [*] one = x [*] (invers x [*] x)"
    by (simp only: group_class.left_inverse)
  also have "... = x [*] invers x [*] x"
    by (simp only: semigroup_class.assoc)
  also have "... = one [*] x"
    by (simp only: group_right_inverse)
  also have "... = x"
    by (simp only: group_class.left_unit)
  finally show ?thesis .
qed


subsection {* Abstract instantiation *}

instance monoid < semigroup
proof intro_classes
  fix x y z :: "'a::monoid"
  show "x [*] y [*] z = x [*] (y [*] z)"
    by (rule monoid_class.assoc)
qed

instance group < monoid
proof intro_classes
  fix x y z :: "'a::group"
  show "x [*] y [*] z = x [*] (y [*] z)"
    by (rule semigroup_class.assoc)
  show "one [*] x = x"
    by (rule group_class.left_unit)
  show "x [*] one = x"
    by (rule group_right_unit)
qed


subsection {* Concrete instantiation *}

defs (overloaded)
  times_bool_def:   "x [*] y == x ~= (y::bool)"
  inverse_bool_def: "invers x == x::bool"
  unit_bool_def:    "one == False"

instance bool :: agroup
proof (intro_classes,
    unfold times_bool_def inverse_bool_def unit_bool_def)
  fix x y z
  show "((x ~= y) ~= z) = (x ~= (y ~= z))" by blast
  show "(False ~= x) = x" by blast
  show "(x ~= x) = False" by blast
  show "(x ~= y) = (y ~= x)" by blast
qed


subsection {* Lifting and Functors *}

defs (overloaded)
  times_prod_def: "p [*] q == (fst p [*] fst q, snd p [*] snd q)"

instance * :: (semigroup, semigroup) semigroup
proof (intro_classes, unfold times_prod_def)
  fix p q r :: "'a::semigroup * 'b::semigroup"
  show
    "(fst (fst p [*] fst q, snd p [*] snd q) [*] fst r,
      snd (fst p [*] fst q, snd p [*] snd q) [*] snd r) =
       (fst p [*] fst (fst q [*] fst r, snd q [*] snd r),
        snd p [*] snd (fst q [*] fst r, snd q [*] snd r))"
    by (simp add: semigroup_class.assoc)
qed

end

(*
  Title:  HOL/Algebra/Group.thy
  Id:     $Id$
  Author: Clemens Ballarin, started 4 February 2003

Based on work by Florian Kammueller, L C Paulson and Markus Wenzel.
*)

header {* Algebraic Structures up to Commutative Groups *}

theory Group = FuncSet:

axclass number < type

instance nat :: number ..
instance int :: number ..

section {* From Magmas to Groups *}

text {*
  Definitions follow Jacobson, Basic Algebra I, Freeman, 1985; with
  the exception of \emph{magma} which, following Bourbaki, is a set
  together with a binary, closed operation.
*}

subsection {* Definitions *}

record 'a semigroup =
  carrier :: "'a set"
  mult :: "['a, 'a] => 'a" (infixl "\<otimes>\<index>" 70)

record 'a monoid = "'a semigroup" +
  one :: 'a ("\<one>\<index>")

constdefs
  m_inv :: "[('a, 'm) monoid_scheme, 'a] => 'a" ("inv\<index> _" [81] 80)
  "m_inv G x == (THE y. y \<in> carrier G &
                  mult G x y = one G & mult G y x = one G)"

  Units :: "('a, 'm) monoid_scheme => 'a set"
  "Units G == {y. y \<in> carrier G &
                  (EX x : carrier G. mult G x y = one G & mult G y x = one G)}"

consts
  pow :: "[('a, 'm) monoid_scheme, 'a, 'b::number] => 'a" (infixr "'(^')\<index>" 75)

defs (overloaded)
  nat_pow_def: "pow G a n == nat_rec (one G) (%u b. mult G b a) n"
  int_pow_def: "pow G a z ==
    let p = nat_rec (one G) (%u b. mult G b a)
    in if neg z then m_inv G (p (nat (-z))) else p (nat z)"

locale magma = struct G +
  assumes m_closed [intro, simp]:
    "[| x \<in> carrier G; y \<in> carrier G |] ==> x \<otimes> y \<in> carrier G"

locale semigroup = magma +
  assumes m_assoc:
    "[| x \<in> carrier G; y \<in> carrier G; z \<in> carrier G |] ==>
    (x \<otimes> y) \<otimes> z = x \<otimes> (y \<otimes> z)"

locale monoid = semigroup +
  assumes one_closed [intro, simp]: "\<one> \<in> carrier G"
    and l_one [simp]: "x \<in> carrier G ==> \<one> \<otimes> x = x"
    and r_one [simp]: "x \<in> carrier G ==> x \<otimes> \<one> = x"

lemma monoidI:
  assumes m_closed:
      "!!x y. [| x \<in> carrier G; y \<in> carrier G |] ==> mult G x y \<in> carrier G"
    and one_closed: "one G \<in> carrier G"
    and m_assoc:
      "!!x y z. [| x \<in> carrier G; y \<in> carrier G; z \<in> carrier G |] ==>
      mult G (mult G x y) z = mult G x (mult G y z)"
    and l_one: "!!x. x \<in> carrier G ==> mult G (one G) x = x"
    and r_one: "!!x. x \<in> carrier G ==> mult G x (one G) = x"
  shows "monoid G"
  by (fast intro!: monoid.intro magma.intro semigroup_axioms.intro
    semigroup.intro monoid_axioms.intro
    intro: prems)

lemma (in monoid) Units_closed [dest]:
  "x \<in> Units G ==> x \<in> carrier G"
  by (unfold Units_def) fast

lemma (in monoid) inv_unique:
  assumes eq: "y \<otimes> x = \<one>" "x \<otimes> y' = \<one>"
    and G: "x \<in> carrier G" "y \<in> carrier G" "y' \<in> carrier G"
  shows "y = y'"
proof -
  from G eq have "y = y \<otimes> (x \<otimes> y')" by simp
  also from G have "... = (y \<otimes> x) \<otimes> y'" by (simp add: m_assoc)
  also from G eq have "... = y'" by simp
  finally show ?thesis .
qed

lemma (in monoid) Units_inv_closed [intro, simp]:
  "x \<in> Units G ==> inv x \<in> carrier G"
  apply (unfold Units_def m_inv_def)
  apply auto
  apply (rule theI2, fast)
   apply (fast intro: inv_unique)
  apply fast
  done

lemma (in monoid) Units_l_inv:
  "x \<in> Units G ==> inv x \<otimes> x = \<one>"
  apply (unfold Units_def m_inv_def)
  apply auto
  apply (rule theI2, fast)
   apply (fast intro: inv_unique)
  apply fast
  done

lemma (in monoid) Units_r_inv:
  "x \<in> Units G ==> x \<otimes> inv x = \<one>"
  apply (unfold Units_def m_inv_def)
  apply auto
  apply (rule theI2, fast)
   apply (fast intro: inv_unique)
  apply fast
  done

lemma (in monoid) Units_inv_Units [intro, simp]:
  "x \<in> Units G ==> inv x \<in> Units G"
proof -
  assume x: "x \<in> Units G"
  show "inv x \<in> Units G"
    by (auto simp add: Units_def
      intro: Units_l_inv Units_r_inv x Units_closed [OF x])
qed

lemma (in monoid) Units_l_cancel [simp]:
  "[| x \<in> Units G; y \<in> carrier G; z \<in> carrier G |] ==>
   (x \<otimes> y = x \<otimes> z) = (y = z)"
proof
  assume eq: "x \<otimes> y = x \<otimes> z"
    and G: "x \<in> Units G" "y \<in> carrier G" "z \<in> carrier G"
  then have "(inv x \<otimes> x) \<otimes> y = (inv x \<otimes> x) \<otimes> z"
    by (simp add: m_assoc Units_closed)
  with G show "y = z" by (simp add: Units_l_inv)
next
  assume eq: "y = z"
    and G: "x \<in> Units G" "y \<in> carrier G" "z \<in> carrier G"
  then show "x \<otimes> y = x \<otimes> z" by simp
qed

lemma (in monoid) Units_inv_inv [simp]:
  "x \<in> Units G ==> inv (inv x) = x"
proof -
  assume x: "x \<in> Units G"
  then have "inv x \<otimes> inv (inv x) = inv x \<otimes> x"
    by (simp add: Units_l_inv Units_r_inv)
  with x show ?thesis by (simp add: Units_closed)
qed

lemma (in monoid) inv_inj_on_Units:
  "inj_on (m_inv G) (Units G)"
proof (rule inj_onI)
  fix x y
  assume G: "x \<in> Units G" "y \<in> Units G" and eq: "inv x = inv y"
  then have "inv (inv x) = inv (inv y)" by simp
  with G show "x = y" by simp
qed

text {* Power *}

lemma (in monoid) nat_pow_closed [intro, simp]:
  "x \<in> carrier G ==> x (^) (n::nat) \<in> carrier G"
  by (induct n) (simp_all add: nat_pow_def)

lemma (in monoid) nat_pow_0 [simp]:
  "x (^) (0::nat) = \<one>"
  by (simp add: nat_pow_def)

lemma (in monoid) nat_pow_Suc [simp]:
  "x (^) (Suc n) = x (^) n \<otimes> x"
  by (simp add: nat_pow_def)

lemma (in monoid) nat_pow_one [simp]:
  "\<one> (^) (n::nat) = \<one>"
  by (induct n) simp_all

lemma (in monoid) nat_pow_mult:
  "x \<in> carrier G ==> x (^) (n::nat) \<otimes> x (^) m = x (^) (n + m)"
  by (induct m) (simp_all add: m_assoc [THEN sym])

lemma (in monoid) nat_pow_pow:
  "x \<in> carrier G ==> (x (^) n) (^) m = x (^) (n * m::nat)"
  by (induct m) (simp, simp add: nat_pow_mult add_commute)

text {*
  A group is a monoid all of whose elements are invertible.
*}

locale group = monoid +
  assumes Units: "carrier G <= Units G"

theorem groupI:
  assumes m_closed [simp]:
      "!!x y. [| x \<in> carrier G; y \<in> carrier G |] ==> mult G x y \<in> carrier G"
    and one_closed [simp]: "one G \<in> carrier G"
    and m_assoc:
      "!!x y z. [| x \<in> carrier G; y \<in> carrier G; z \<in> carrier G |] ==>
      mult G (mult G x y) z = mult G x (mult G y z)"
    and l_one [simp]: "!!x. x \<in> carrier G ==> mult G (one G) x = x"
    and l_inv_ex: "!!x. x \<in> carrier G ==> EX y : carrier G. mult G y x = one G"
  shows "group G"
proof -
  have l_cancel [simp]:
    "!!x y z. [| x \<in> carrier G; y \<in> carrier G; z \<in> carrier G |] ==>
    (mult G x y = mult G x z) = (y = z)"
  proof
    fix x y z
    assume eq: "mult G x y = mult G x z"
      and G: "x \<in> carrier G" "y \<in> carrier G" "z \<in> carrier G"
    with l_inv_ex obtain x_inv where xG: "x_inv \<in> carrier G"
      and l_inv: "mult G x_inv x = one G" by fast
    from G eq xG have "mult G (mult G x_inv x) y = mult G (mult G x_inv x) z"
      by (simp add: m_assoc)
    with G show "y = z" by (simp add: l_inv)
  next
    fix x y z
    assume eq: "y = z"
      and G: "x \<in> carrier G" "y \<in> carrier G" "z \<in> carrier G"
    then show "mult G x y = mult G x z" by simp
  qed
  have r_one:
    "!!x. x \<in> carrier G ==> mult G x (one G) = x"
  proof -
    fix x
    assume x: "x \<in> carrier G"
    with l_inv_ex obtain x_inv where xG: "x_inv \<in> carrier G"
      and l_inv: "mult G x_inv x = one G" by fast
    from x xG have "mult G x_inv (mult G x (one G)) = mult G x_inv x"
      by (simp add: m_assoc [symmetric] l_inv)
    with x xG show "mult G x (one G) = x" by simp 
  qed
  have inv_ex:
    "!!x. x \<in> carrier G ==> EX y : carrier G. mult G y x = one G &
      mult G x y = one G"
  proof -
    fix x
    assume x: "x \<in> carrier G"
    with l_inv_ex obtain y where y: "y \<in> carrier G"
      and l_inv: "mult G y x = one G" by fast
    from x y have "mult G y (mult G x y) = mult G y (one G)"
      by (simp add: m_assoc [symmetric] l_inv r_one)
    with x y have r_inv: "mult G x y = one G"
      by simp
    from x y show "EX y : carrier G. mult G y x = one G &
      mult G x y = one G"
      by (fast intro: l_inv r_inv)
  qed
  then have carrier_subset_Units: "carrier G <= Units G"
    by (unfold Units_def) fast
  show ?thesis
    by (fast intro!: group.intro magma.intro semigroup_axioms.intro
      semigroup.intro monoid_axioms.intro group_axioms.intro
      carrier_subset_Units intro: prems r_one)
qed

lemma (in monoid) monoid_groupI:
  assumes l_inv_ex:
    "!!x. x \<in> carrier G ==> EX y : carrier G. mult G y x = one G"
  shows "group G"
  by (rule groupI) (auto intro: m_assoc l_inv_ex)

lemma (in group) Units_eq [simp]:
  "Units G = carrier G"
proof
  show "Units G <= carrier G" by fast
next
  show "carrier G <= Units G" by (rule Units)
qed

lemma (in group) inv_closed [intro, simp]:
  "x \<in> carrier G ==> inv x \<in> carrier G"
  using Units_inv_closed by simp

lemma (in group) l_inv:
  "x \<in> carrier G ==> inv x \<otimes> x = \<one>"
  using Units_l_inv by simp

subsection {* Cancellation Laws and Basic Properties *}

lemma (in group) l_cancel [simp]:
  "[| x \<in> carrier G; y \<in> carrier G; z \<in> carrier G |] ==>
   (x \<otimes> y = x \<otimes> z) = (y = z)"
  using Units_l_inv by simp
(*
lemma (in group) r_one [simp]:  
  "x \<in> carrier G ==> x \<otimes> \<one> = x"
proof -
  assume x: "x \<in> carrier G"
  then have "inv x \<otimes> (x \<otimes> \<one>) = inv x \<otimes> x"
    by (simp add: m_assoc [symmetric] l_inv)
  with x show ?thesis by simp 
qed
*)
lemma (in group) r_inv:
  "x \<in> carrier G ==> x \<otimes> inv x = \<one>"
proof -
  assume x: "x \<in> carrier G"
  then have "inv x \<otimes> (x \<otimes> inv x) = inv x \<otimes> \<one>"
    by (simp add: m_assoc [symmetric] l_inv)
  with x show ?thesis by (simp del: r_one)
qed

lemma (in group) r_cancel [simp]:
  "[| x \<in> carrier G; y \<in> carrier G; z \<in> carrier G |] ==>
   (y \<otimes> x = z \<otimes> x) = (y = z)"
proof
  assume eq: "y \<otimes> x = z \<otimes> x"
    and G: "x \<in> carrier G" "y \<in> carrier G" "z \<in> carrier G"
  then have "y \<otimes> (x \<otimes> inv x) = z \<otimes> (x \<otimes> inv x)"
    by (simp add: m_assoc [symmetric])
  with G show "y = z" by (simp add: r_inv)
next
  assume eq: "y = z"
    and G: "x \<in> carrier G" "y \<in> carrier G" "z \<in> carrier G"
  then show "y \<otimes> x = z \<otimes> x" by simp
qed

lemma (in group) inv_one [simp]:
  "inv \<one> = \<one>"
proof -
  have "inv \<one> = \<one> \<otimes> (inv \<one>)" by simp
  moreover have "... = \<one>" by (simp add: r_inv)
  finally show ?thesis .
qed

lemma (in group) inv_inv [simp]:
  "x \<in> carrier G ==> inv (inv x) = x"
  using Units_inv_inv by simp

lemma (in group) inv_inj:
  "inj_on (m_inv G) (carrier G)"
  using inv_inj_on_Units by simp

lemma (in group) inv_mult_group:
  "[| x \<in> carrier G; y \<in> carrier G |] ==> inv (x \<otimes> y) = inv y \<otimes> inv x"
proof -
  assume G: "x \<in> carrier G" "y \<in> carrier G"
  then have "inv (x \<otimes> y) \<otimes> (x \<otimes> y) = (inv y \<otimes> inv x) \<otimes> (x \<otimes> y)"
    by (simp add: m_assoc l_inv) (simp add: m_assoc [symmetric] l_inv)
  with G show ?thesis by simp
qed

text {* Power *}

lemma (in group) int_pow_def2:
  "a (^) (z::int) = (if neg z then inv (a (^) (nat (-z))) else a (^) (nat z))"
  by (simp add: int_pow_def nat_pow_def Let_def)

lemma (in group) int_pow_0 [simp]:
  "x (^) (0::int) = \<one>"
  by (simp add: int_pow_def2)

lemma (in group) int_pow_one [simp]:
  "\<one> (^) (z::int) = \<one>"
  by (simp add: int_pow_def2)

subsection {* Substructures *}

locale submagma = var H + struct G +
  assumes subset [intro, simp]: "H \<subseteq> carrier G"
    and m_closed [intro, simp]: "[| x \<in> H; y \<in> H |] ==> x \<otimes> y \<in> H"

declare (in submagma) magma.intro [intro] semigroup.intro [intro]
  semigroup_axioms.intro [intro]
(*
alternative definition of submagma

locale submagma = var H + struct G +
  assumes subset [intro, simp]: "carrier H \<subseteq> carrier G"
    and m_equal [simp]: "mult H = mult G"
    and m_closed [intro, simp]:
      "[| x \<in> carrier H; y \<in> carrier H |] ==> x \<otimes> y \<in> carrier H"
*)

lemma submagma_imp_subset:
  "submagma H G ==> H \<subseteq> carrier G"
  by (rule submagma.subset)

lemma (in submagma) subsetD [dest, simp]:
  "x \<in> H ==> x \<in> carrier G"
  using subset by blast

lemma (in submagma) magmaI [intro]:
  includes magma G
  shows "magma (G(| carrier := H |))"
  by rule simp

lemma (in submagma) semigroup_axiomsI [intro]:
  includes semigroup G
  shows "semigroup_axioms (G(| carrier := H |))"
    by rule (simp add: m_assoc)

lemma (in submagma) semigroupI [intro]:
  includes semigroup G
  shows "semigroup (G(| carrier := H |))"
  using prems by fast

locale subgroup = submagma H G +
  assumes one_closed [intro, simp]: "\<one> \<in> H"
    and m_inv_closed [intro, simp]: "x \<in> H ==> inv x \<in> H"

declare (in subgroup) group.intro [intro]
(*
lemma (in subgroup) l_oneI [intro]:
  includes l_one G
  shows "l_one (G(| carrier := H |))"
  by rule simp_all
*)
lemma (in subgroup) group_axiomsI [intro]:
  includes group G
  shows "group_axioms (G(| carrier := H |))"
  by rule (auto intro: l_inv r_inv simp add: Units_def)

lemma (in subgroup) groupI [intro]:
  includes group G
  shows "group (G(| carrier := H |))"
  by (rule groupI) (auto intro: m_assoc l_inv)

text {*
  Since @{term H} is nonempty, it contains some element @{term x}.  Since
  it is closed under inverse, it contains @{text "inv x"}.  Since
  it is closed under product, it contains @{text "x \<otimes> inv x = \<one>"}.
*}

lemma (in group) one_in_subset:
  "[| H \<subseteq> carrier G; H \<noteq> {}; \<forall>a \<in> H. inv a \<in> H; \<forall>a\<in>H. \<forall>b\<in>H. a \<otimes> b \<in> H |]
   ==> \<one> \<in> H"
by (force simp add: l_inv)

text {* A characterization of subgroups: closed, non-empty subset. *}

lemma (in group) subgroupI:
  assumes subset: "H \<subseteq> carrier G" and non_empty: "H \<noteq> {}"
    and inv: "!!a. a \<in> H ==> inv a \<in> H"
    and mult: "!!a b. [|a \<in> H; b \<in> H|] ==> a \<otimes> b \<in> H"
  shows "subgroup H G"
proof
  from subset and mult show "submagma H G" ..
next
  have "\<one> \<in> H" by (rule one_in_subset) (auto simp only: prems)
  with inv show "subgroup_axioms H G"
    by (intro subgroup_axioms.intro) simp_all
qed

text {*
  Repeat facts of submagmas for subgroups.  Necessary???
*}

lemma (in subgroup) subset:
  "H \<subseteq> carrier G"
  ..

lemma (in subgroup) m_closed:
  "[| x \<in> H; y \<in> H |] ==> x \<otimes> y \<in> H"
  ..

declare magma.m_closed [simp]

declare monoid.one_closed [iff] group.inv_closed [simp]
  monoid.l_one [simp] monoid.r_one [simp] group.inv_inv [simp]

lemma subgroup_nonempty:
  "~ subgroup {} G"
  by (blast dest: subgroup.one_closed)

lemma (in subgroup) finite_imp_card_positive:
  "finite (carrier G) ==> 0 < card H"
proof (rule classical)
  have sub: "subgroup H G" using prems ..
  assume fin: "finite (carrier G)"
    and zero: "~ 0 < card H"
  then have "finite H" by (blast intro: finite_subset dest: subset)
  with zero sub have "subgroup {} G" by simp
  with subgroup_nonempty show ?thesis by contradiction
qed

(*
lemma (in monoid) Units_subgroup:
  "subgroup (Units G) G"
*)

subsection {* Direct Products *}

constdefs
  DirProdSemigroup ::
    "[('a, 'm) semigroup_scheme, ('b, 'n) semigroup_scheme]
    => ('a \<times> 'b) semigroup"
    (infixr "\<times>\<^sub>s" 80)
  "G \<times>\<^sub>s H == (| carrier = carrier G \<times> carrier H,
    mult = (%(xg, xh) (yg, yh). (mult G xg yg, mult H xh yh)) |)"

  DirProdGroup ::
    "[('a, 'm) monoid_scheme, ('b, 'n) monoid_scheme] => ('a \<times> 'b) monoid"
    (infixr "\<times>\<^sub>g" 80)
  "G \<times>\<^sub>g H == (| carrier = carrier (G \<times>\<^sub>s H),
    mult = mult (G \<times>\<^sub>s H),
    one = (one G, one H) |)"
(*
  DirProdGroup ::
    "[('a, 'm) group_scheme, ('b, 'n) group_scheme] => ('a \<times> 'b) group"
    (infixr "\<times>\<^sub>g" 80)
  "G \<times>\<^sub>g H == (| carrier = carrier (G \<times>\<^sub>m H),
    mult = mult (G \<times>\<^sub>m H),
    one = one (G \<times>\<^sub>m H),
    m_inv = (%(g, h). (m_inv G g, m_inv H h)) |)"
*)

lemma DirProdSemigroup_magma:
  includes magma G + magma H
  shows "magma (G \<times>\<^sub>s H)"
  by rule (auto simp add: DirProdSemigroup_def)

lemma DirProdSemigroup_semigroup_axioms:
  includes semigroup G + semigroup H
  shows "semigroup_axioms (G \<times>\<^sub>s H)"
  by rule (auto simp add: DirProdSemigroup_def G.m_assoc H.m_assoc)

lemma DirProdSemigroup_semigroup:
  includes semigroup G + semigroup H
  shows "semigroup (G \<times>\<^sub>s H)"
  using prems
  by (fast intro: semigroup.intro
    DirProdSemigroup_magma DirProdSemigroup_semigroup_axioms)

lemma DirProdGroup_magma:
  includes magma G + magma H
  shows "magma (G \<times>\<^sub>g H)"
  by rule
    (auto simp add: DirProdGroup_def DirProdSemigroup_def)

lemma DirProdGroup_semigroup_axioms:
  includes semigroup G + semigroup H
  shows "semigroup_axioms (G \<times>\<^sub>g H)"
  by rule
    (auto simp add: DirProdGroup_def DirProdSemigroup_def
      G.m_assoc H.m_assoc)

lemma DirProdGroup_semigroup:
  includes semigroup G + semigroup H
  shows "semigroup (G \<times>\<^sub>g H)"
  using prems
  by (fast intro: semigroup.intro
    DirProdGroup_magma DirProdGroup_semigroup_axioms)

(* ... and further lemmas for group ... *)

lemma DirProdGroup_group:
  includes group G + group H
  shows "group (G \<times>\<^sub>g H)"
  by (rule groupI)
    (auto intro: G.m_assoc H.m_assoc G.l_inv H.l_inv
      simp add: DirProdGroup_def DirProdSemigroup_def)

subsection {* Homomorphisms *}

constdefs
  hom :: "[('a, 'c) semigroup_scheme, ('b, 'd) semigroup_scheme]
    => ('a => 'b)set"
  "hom G H ==
    {h. h \<in> carrier G -> carrier H &
      (\<forall>x \<in> carrier G. \<forall>y \<in> carrier G. h (mult G x y) = mult H (h x) (h y))}"

lemma (in semigroup) hom:
  includes semigroup G
  shows "semigroup (| carrier = hom G G, mult = op o |)"
proof
  show "magma (| carrier = hom G G, mult = op o |)"
    by rule (simp add: Pi_def hom_def)
next
  show "semigroup_axioms (| carrier = hom G G, mult = op o |)"
    by rule (simp add: o_assoc)
qed

lemma hom_mult:
  "[| h \<in> hom G H; x \<in> carrier G; y \<in> carrier G |] 
   ==> h (mult G x y) = mult H (h x) (h y)"
  by (simp add: hom_def) 

lemma hom_closed:
  "[| h \<in> hom G H; x \<in> carrier G |] ==> h x \<in> carrier H"
  by (auto simp add: hom_def funcset_mem)

locale group_hom = group G + group H + var h +
  assumes homh: "h \<in> hom G H"
  notes hom_mult [simp] = hom_mult [OF homh]
    and hom_closed [simp] = hom_closed [OF homh]

lemma (in group_hom) one_closed [simp]:
  "h \<one> \<in> carrier H"
  by simp

lemma (in group_hom) hom_one [simp]:
  "h \<one> = \<one>\<^sub>2"
proof -
  have "h \<one> \<otimes>\<^sub>2 \<one>\<^sub>2 = h \<one> \<otimes>\<^sub>2 h \<one>"
    by (simp add: hom_mult [symmetric] del: hom_mult)
  then show ?thesis by (simp del: r_one)
qed

lemma (in group_hom) inv_closed [simp]:
  "x \<in> carrier G ==> h (inv x) \<in> carrier H"
  by simp

lemma (in group_hom) hom_inv [simp]:
  "x \<in> carrier G ==> h (inv x) = inv\<^sub>2 (h x)"
proof -
  assume x: "x \<in> carrier G"
  then have "h x \<otimes>\<^sub>2 h (inv x) = \<one>\<^sub>2"
    by (simp add: hom_mult [symmetric] G.r_inv del: hom_mult)
  also from x have "... = h x \<otimes>\<^sub>2 inv\<^sub>2 (h x)"
    by (simp add: hom_mult [symmetric] H.r_inv del: hom_mult)
  finally have "h x \<otimes>\<^sub>2 h (inv x) = h x \<otimes>\<^sub>2 inv\<^sub>2 (h x)" .
  with x show ?thesis by simp
qed

section {* Commutative Structures *}

text {*
  Naming convention: multiplicative structures that are commutative
  are called \emph{commutative}, additive structures are called
  \emph{Abelian}.
*}

subsection {* Definition *}

locale comm_semigroup = semigroup +
  assumes m_comm: "[| x \<in> carrier G; y \<in> carrier G |] ==> x \<otimes> y = y \<otimes> x"

lemma (in comm_semigroup) m_lcomm:
  "[| x \<in> carrier G; y \<in> carrier G; z \<in> carrier G |] ==>
   x \<otimes> (y \<otimes> z) = y \<otimes> (x \<otimes> z)"
proof -
  assume xyz: "x \<in> carrier G" "y \<in> carrier G" "z \<in> carrier G"
  from xyz have "x \<otimes> (y \<otimes> z) = (x \<otimes> y) \<otimes> z" by (simp add: m_assoc)
  also from xyz have "... = (y \<otimes> x) \<otimes> z" by (simp add: m_comm)
  also from xyz have "... = y \<otimes> (x \<otimes> z)" by (simp add: m_assoc)
  finally show ?thesis .
qed

lemmas (in comm_semigroup) m_ac = m_assoc m_comm m_lcomm

locale comm_monoid = comm_semigroup + monoid

lemma comm_monoidI:
  assumes m_closed:
      "!!x y. [| x \<in> carrier G; y \<in> carrier G |] ==> mult G x y \<in> carrier G"
    and one_closed: "one G \<in> carrier G"
    and m_assoc:
      "!!x y z. [| x \<in> carrier G; y \<in> carrier G; z \<in> carrier G |] ==>
      mult G (mult G x y) z = mult G x (mult G y z)"
    and l_one: "!!x. x \<in> carrier G ==> mult G (one G) x = x"
    and m_comm:
      "!!x y. [| x \<in> carrier G; y \<in> carrier G |] ==> mult G x y = mult G y x"
  shows "comm_monoid G"
  using l_one
  by (auto intro!: comm_monoid.intro magma.intro semigroup_axioms.intro
    comm_semigroup_axioms.intro monoid_axioms.intro
    intro: prems simp: m_closed one_closed m_comm)

lemma (in monoid) monoid_comm_monoidI:
  assumes m_comm:
      "!!x y. [| x \<in> carrier G; y \<in> carrier G |] ==> mult G x y = mult G y x"
  shows "comm_monoid G"
  by (rule comm_monoidI) (auto intro: m_assoc m_comm)
(*
lemma (in comm_monoid) r_one [simp]:
  "x \<in> carrier G ==> x \<otimes> \<one> = x"
proof -
  assume G: "x \<in> carrier G"
  then have "x \<otimes> \<one> = \<one> \<otimes> x" by (simp add: m_comm)
  also from G have "... = x" by simp
  finally show ?thesis .
qed
*)

lemma (in comm_monoid) nat_pow_distr:
  "[| x \<in> carrier G; y \<in> carrier G |] ==>
  (x \<otimes> y) (^) (n::nat) = x (^) n \<otimes> y (^) n"
  by (induct n) (simp, simp add: m_ac)

locale comm_group = comm_monoid + group

lemma (in group) group_comm_groupI:
  assumes m_comm: "!!x y. [| x \<in> carrier G; y \<in> carrier G |] ==>
      mult G x y = mult G y x"
  shows "comm_group G"
  by (fast intro: comm_group.intro comm_semigroup_axioms.intro
    group.axioms prems)

lemma comm_groupI:
  assumes m_closed:
      "!!x y. [| x \<in> carrier G; y \<in> carrier G |] ==> mult G x y \<in> carrier G"
    and one_closed: "one G \<in> carrier G"
    and m_assoc:
      "!!x y z. [| x \<in> carrier G; y \<in> carrier G; z \<in> carrier G |] ==>
      mult G (mult G x y) z = mult G x (mult G y z)"
    and m_comm:
      "!!x y. [| x \<in> carrier G; y \<in> carrier G |] ==> mult G x y = mult G y x"
    and l_one: "!!x. x \<in> carrier G ==> mult G (one G) x = x"
    and l_inv_ex: "!!x. x \<in> carrier G ==> EX y : carrier G. mult G y x = one G"
  shows "comm_group G"
  by (fast intro: group.group_comm_groupI groupI prems)

lemma (in comm_group) inv_mult:
  "[| x \<in> carrier G; y \<in> carrier G |] ==> inv (x \<otimes> y) = inv x \<otimes> inv y"
  by (simp add: m_ac inv_mult_group)

end

(*  Title       : HOL/Hyperreal/StarDef.thy
    Author      : Jacques D. Fleuriot and Brian Huffman
*)

section {* Construction of Star Types Using Ultrafilters *}

theory StarDef
imports Free_Ultrafilter
begin

subsection {* A Free Ultrafilter over the Naturals *}

definition
  FreeUltrafilterNat :: "nat filter"  ("\<U>") where
  "\<U> = (SOME U. freeultrafilter U)"

lemma freeultrafilter_FreeUltrafilterNat: "freeultrafilter \<U>"
apply (unfold FreeUltrafilterNat_def)
apply (rule someI_ex)
apply (rule freeultrafilter_Ex)
apply (rule infinite_UNIV_nat)
done

interpretation FreeUltrafilterNat: freeultrafilter FreeUltrafilterNat
by (rule freeultrafilter_FreeUltrafilterNat)

subsection {* Definition of @{text star} type constructor *}

definition
  starrel :: "((nat \<Rightarrow> 'a) \<times> (nat \<Rightarrow> 'a)) set" where
  "starrel = {(X,Y). eventually (\<lambda>n. X n = Y n) \<U>}"

definition "star = (UNIV :: (nat \<Rightarrow> 'a) set) // starrel"

typedef 'a star = "star :: (nat \<Rightarrow> 'a) set set"
  unfolding star_def by (auto intro: quotientI)

definition
  star_n :: "(nat \<Rightarrow> 'a) \<Rightarrow> 'a star" where
  "star_n X = Abs_star (starrel `` {X})"

theorem star_cases [case_names star_n, cases type: star]:
  "(\<And>X. x = star_n X \<Longrightarrow> P) \<Longrightarrow> P"
by (cases x, unfold star_n_def star_def, erule quotientE, fast)

lemma all_star_eq: "(\<forall>x. P x) = (\<forall>X. P (star_n X))"
by (auto, rule_tac x=x in star_cases, simp)

lemma ex_star_eq: "(\<exists>x. P x) = (\<exists>X. P (star_n X))"
by (auto, rule_tac x=x in star_cases, auto)

text {* Proving that @{term starrel} is an equivalence relation *}

lemma starrel_iff [iff]: "((X,Y) \<in> starrel) = (eventually (\<lambda>n. X n = Y n) \<U>)"
by (simp add: starrel_def)

lemma equiv_starrel: "equiv UNIV starrel"
proof (rule equivI)
  show "refl starrel" by (simp add: refl_on_def)
  show "sym starrel" by (simp add: sym_def eq_commute)
  show "trans starrel" by (intro transI) (auto elim: eventually_elim2)
qed

lemmas equiv_starrel_iff =
  eq_equiv_class_iff [OF equiv_starrel UNIV_I UNIV_I]

lemma starrel_in_star: "starrel``{x} \<in> star"
by (simp add: star_def quotientI)

lemma star_n_eq_iff: "(star_n X = star_n Y) = (eventually (\<lambda>n. X n = Y n) \<U>)"
by (simp add: star_n_def Abs_star_inject starrel_in_star equiv_starrel_iff)


subsection {* Transfer principle *}

text {* This introduction rule starts each transfer proof. *}
lemma transfer_start:
  "P \<equiv> eventually (\<lambda>n. Q) \<U> \<Longrightarrow> Trueprop P \<equiv> Trueprop Q"
  by (simp add: FreeUltrafilterNat.proper)

text {*Initialize transfer tactic.*}
ML_file "transfer.ML"

method_setup transfer = {*
  Attrib.thms >> (fn ths => fn ctxt =>
    SIMPLE_METHOD' (Transfer_Principle.transfer_tac ctxt ths))
*} "transfer principle"


text {* Transfer introduction rules. *}

lemma transfer_ex [transfer_intro]:
  "\<lbrakk>\<And>X. p (star_n X) \<equiv> eventually (\<lambda>n. P n (X n)) \<U>\<rbrakk>
    \<Longrightarrow> \<exists>x::'a star. p x \<equiv> eventually (\<lambda>n. \<exists>x. P n x) \<U>"
by (simp only: ex_star_eq eventually_ex)

lemma transfer_all [transfer_intro]:
  "\<lbrakk>\<And>X. p (star_n X) \<equiv> eventually (\<lambda>n. P n (X n)) \<U>\<rbrakk>
    \<Longrightarrow> \<forall>x::'a star. p x \<equiv> eventually (\<lambda>n. \<forall>x. P n x) \<U>"
by (simp only: all_star_eq FreeUltrafilterNat.eventually_all_iff)

lemma transfer_not [transfer_intro]:
  "\<lbrakk>p \<equiv> eventually P \<U>\<rbrakk> \<Longrightarrow> \<not> p \<equiv> eventually (\<lambda>n. \<not> P n) \<U>"
by (simp only: FreeUltrafilterNat.eventually_not_iff)

lemma transfer_conj [transfer_intro]:
  "\<lbrakk>p \<equiv> eventually P \<U>; q \<equiv> eventually Q \<U>\<rbrakk>
    \<Longrightarrow> p \<and> q \<equiv> eventually (\<lambda>n. P n \<and> Q n) \<U>"
by (simp only: eventually_conj_iff)

lemma transfer_disj [transfer_intro]:
  "\<lbrakk>p \<equiv> eventually P \<U>; q \<equiv> eventually Q \<U>\<rbrakk>
    \<Longrightarrow> p \<or> q \<equiv> eventually (\<lambda>n. P n \<or> Q n) \<U>"
by (simp only: FreeUltrafilterNat.eventually_disj_iff)

lemma transfer_imp [transfer_intro]:
  "\<lbrakk>p \<equiv> eventually P \<U>; q \<equiv> eventually Q \<U>\<rbrakk>
    \<Longrightarrow> p \<longrightarrow> q \<equiv> eventually (\<lambda>n. P n \<longrightarrow> Q n) \<U>"
by (simp only: FreeUltrafilterNat.eventually_imp_iff)

lemma transfer_iff [transfer_intro]:
  "\<lbrakk>p \<equiv> eventually P \<U>; q \<equiv> eventually Q \<U>\<rbrakk>
    \<Longrightarrow> p = q \<equiv> eventually (\<lambda>n. P n = Q n) \<U>"
by (simp only: FreeUltrafilterNat.eventually_iff_iff)

lemma transfer_if_bool [transfer_intro]:
  "\<lbrakk>p \<equiv> eventually P \<U>; x \<equiv> eventually X \<U>; y \<equiv> eventually Y \<U>\<rbrakk>
    \<Longrightarrow> (if p then x else y) \<equiv> eventually (\<lambda>n. if P n then X n else Y n) \<U>"
by (simp only: if_bool_eq_conj transfer_conj transfer_imp transfer_not)

lemma transfer_eq [transfer_intro]:
  "\<lbrakk>x \<equiv> star_n X; y \<equiv> star_n Y\<rbrakk> \<Longrightarrow> x = y \<equiv> eventually (\<lambda>n. X n = Y n) \<U>"
by (simp only: star_n_eq_iff)

lemma transfer_if [transfer_intro]:
  "\<lbrakk>p \<equiv> eventually (\<lambda>n. P n) \<U>; x \<equiv> star_n X; y \<equiv> star_n Y\<rbrakk>
    \<Longrightarrow> (if p then x else y) \<equiv> star_n (\<lambda>n. if P n then X n else Y n)"
apply (rule eq_reflection)
apply (auto simp add: star_n_eq_iff transfer_not elim!: eventually_elim1)
done

lemma transfer_fun_eq [transfer_intro]:
  "\<lbrakk>\<And>X. f (star_n X) = g (star_n X) 
    \<equiv> eventually (\<lambda>n. F n (X n) = G n (X n)) \<U>\<rbrakk>
      \<Longrightarrow> f = g \<equiv> eventually (\<lambda>n. F n = G n) \<U>"
by (simp only: fun_eq_iff transfer_all)

lemma transfer_star_n [transfer_intro]: "star_n X \<equiv> star_n (\<lambda>n. X n)"
by (rule reflexive)

lemma transfer_bool [transfer_intro]: "p \<equiv> eventually (\<lambda>n. p) \<U>"
by (simp add: FreeUltrafilterNat.proper)


subsection {* Standard elements *}

definition
  star_of :: "'a \<Rightarrow> 'a star" where
  "star_of x == star_n (\<lambda>n. x)"

definition
  Standard :: "'a star set" where
  "Standard = range star_of"

text {* Transfer tactic should remove occurrences of @{term star_of} *}
setup {* Transfer_Principle.add_const @{const_name star_of} *}

declare star_of_def [transfer_intro]

lemma star_of_inject: "(star_of x = star_of y) = (x = y)"
by (transfer, rule refl)

lemma Standard_star_of [simp]: "star_of x \<in> Standard"
by (simp add: Standard_def)


subsection {* Internal functions *}

definition
  Ifun :: "('a \<Rightarrow> 'b) star \<Rightarrow> 'a star \<Rightarrow> 'b star" ("_ \<star> _" [300,301] 300) where
  "Ifun f \<equiv> \<lambda>x. Abs_star
       (\<Union>F\<in>Rep_star f. \<Union>X\<in>Rep_star x. starrel``{\<lambda>n. F n (X n)})"

lemma Ifun_congruent2:
  "congruent2 starrel starrel (\<lambda>F X. starrel``{\<lambda>n. F n (X n)})"
by (auto simp add: congruent2_def equiv_starrel_iff elim!: eventually_rev_mp)

lemma Ifun_star_n: "star_n F \<star> star_n X = star_n (\<lambda>n. F n (X n))"
by (simp add: Ifun_def star_n_def Abs_star_inverse starrel_in_star
    UN_equiv_class2 [OF equiv_starrel equiv_starrel Ifun_congruent2])

text {* Transfer tactic should remove occurrences of @{term Ifun} *}
setup {* Transfer_Principle.add_const @{const_name Ifun} *}

lemma transfer_Ifun [transfer_intro]:
  "\<lbrakk>f \<equiv> star_n F; x \<equiv> star_n X\<rbrakk> \<Longrightarrow> f \<star> x \<equiv> star_n (\<lambda>n. F n (X n))"
by (simp only: Ifun_star_n)

lemma Ifun_star_of [simp]: "star_of f \<star> star_of x = star_of (f x)"
by (transfer, rule refl)

lemma Standard_Ifun [simp]:
  "\<lbrakk>f \<in> Standard; x \<in> Standard\<rbrakk> \<Longrightarrow> f \<star> x \<in> Standard"
by (auto simp add: Standard_def)

text {* Nonstandard extensions of functions *}

definition
  starfun :: "('a \<Rightarrow> 'b) \<Rightarrow> ('a star \<Rightarrow> 'b star)"  ("*f* _" [80] 80) where
  "starfun f == \<lambda>x. star_of f \<star> x"

definition
  starfun2 :: "('a \<Rightarrow> 'b \<Rightarrow> 'c) \<Rightarrow> ('a star \<Rightarrow> 'b star \<Rightarrow> 'c star)"
    ("*f2* _" [80] 80) where
  "starfun2 f == \<lambda>x y. star_of f \<star> x \<star> y"

declare starfun_def [transfer_unfold]
declare starfun2_def [transfer_unfold]

lemma starfun_star_n: "( *f* f) (star_n X) = star_n (\<lambda>n. f (X n))"
by (simp only: starfun_def star_of_def Ifun_star_n)

lemma starfun2_star_n:
  "( *f2* f) (star_n X) (star_n Y) = star_n (\<lambda>n. f (X n) (Y n))"
by (simp only: starfun2_def star_of_def Ifun_star_n)

lemma starfun_star_of [simp]: "( *f* f) (star_of x) = star_of (f x)"
by (transfer, rule refl)

lemma starfun2_star_of [simp]: "( *f2* f) (star_of x) = *f* f x"
by (transfer, rule refl)

lemma Standard_starfun [simp]: "x \<in> Standard \<Longrightarrow> starfun f x \<in> Standard"
by (simp add: starfun_def)

lemma Standard_starfun2 [simp]:
  "\<lbrakk>x \<in> Standard; y \<in> Standard\<rbrakk> \<Longrightarrow> starfun2 f x y \<in> Standard"
by (simp add: starfun2_def)

lemma Standard_starfun_iff:
  assumes inj: "\<And>x y. f x = f y \<Longrightarrow> x = y"
  shows "(starfun f x \<in> Standard) = (x \<in> Standard)"
proof
  assume "x \<in> Standard"
  thus "starfun f x \<in> Standard" by simp
next
  have inj': "\<And>x y. starfun f x = starfun f y \<Longrightarrow> x = y"
    using inj by transfer
  assume "starfun f x \<in> Standard"
  then obtain b where b: "starfun f x = star_of b"
    unfolding Standard_def ..
  hence "\<exists>x. starfun f x = star_of b" ..
  hence "\<exists>a. f a = b" by transfer
  then obtain a where "f a = b" ..
  hence "starfun f (star_of a) = star_of b" by transfer
  with b have "starfun f x = starfun f (star_of a)" by simp
  hence "x = star_of a" by (rule inj')
  thus "x \<in> Standard"
    unfolding Standard_def by auto
qed

lemma Standard_starfun2_iff:
  assumes inj: "\<And>a b a' b'. f a b = f a' b' \<Longrightarrow> a = a' \<and> b = b'"
  shows "(starfun2 f x y \<in> Standard) = (x \<in> Standard \<and> y \<in> Standard)"
proof
  assume "x \<in> Standard \<and> y \<in> Standard"
  thus "starfun2 f x y \<in> Standard" by simp
next
  have inj': "\<And>x y z w. starfun2 f x y = starfun2 f z w \<Longrightarrow> x = z \<and> y = w"
    using inj by transfer
  assume "starfun2 f x y \<in> Standard"
  then obtain c where c: "starfun2 f x y = star_of c"
    unfolding Standard_def ..
  hence "\<exists>x y. starfun2 f x y = star_of c" by auto
  hence "\<exists>a b. f a b = c" by transfer
  then obtain a b where "f a b = c" by auto
  hence "starfun2 f (star_of a) (star_of b) = star_of c"
    by transfer
  with c have "starfun2 f x y = starfun2 f (star_of a) (star_of b)"
    by simp
  hence "x = star_of a \<and> y = star_of b"
    by (rule inj')
  thus "x \<in> Standard \<and> y \<in> Standard"
    unfolding Standard_def by auto
qed


subsection {* Internal predicates *}

definition unstar :: "bool star \<Rightarrow> bool" where
  "unstar b \<longleftrightarrow> b = star_of True"

lemma unstar_star_n: "unstar (star_n P) = (eventually P \<U>)"
by (simp add: unstar_def star_of_def star_n_eq_iff)

lemma unstar_star_of [simp]: "unstar (star_of p) = p"
by (simp add: unstar_def star_of_inject)

text {* Transfer tactic should remove occurrences of @{term unstar} *}
setup {* Transfer_Principle.add_const @{const_name unstar} *}

lemma transfer_unstar [transfer_intro]:
  "p \<equiv> star_n P \<Longrightarrow> unstar p \<equiv> eventually P \<U>"
by (simp only: unstar_star_n)

definition
  starP :: "('a \<Rightarrow> bool) \<Rightarrow> 'a star \<Rightarrow> bool"  ("*p* _" [80] 80) where
  "*p* P = (\<lambda>x. unstar (star_of P \<star> x))"

definition
  starP2 :: "('a \<Rightarrow> 'b \<Rightarrow> bool) \<Rightarrow> 'a star \<Rightarrow> 'b star \<Rightarrow> bool"  ("*p2* _" [80] 80) where
  "*p2* P = (\<lambda>x y. unstar (star_of P \<star> x \<star> y))"

declare starP_def [transfer_unfold]
declare starP2_def [transfer_unfold]

lemma starP_star_n: "( *p* P) (star_n X) = (eventually (\<lambda>n. P (X n)) \<U>)"
by (simp only: starP_def star_of_def Ifun_star_n unstar_star_n)

lemma starP2_star_n:
  "( *p2* P) (star_n X) (star_n Y) = (eventually (\<lambda>n. P (X n) (Y n)) \<U>)"
by (simp only: starP2_def star_of_def Ifun_star_n unstar_star_n)

lemma starP_star_of [simp]: "( *p* P) (star_of x) = P x"
by (transfer, rule refl)

lemma starP2_star_of [simp]: "( *p2* P) (star_of x) = *p* P x"
by (transfer, rule refl)


subsection {* Internal sets *}

definition
  Iset :: "'a set star \<Rightarrow> 'a star set" where
  "Iset A = {x. ( *p2* op \<in>) x A}"

lemma Iset_star_n:
  "(star_n X \<in> Iset (star_n A)) = (eventually (\<lambda>n. X n \<in> A n) \<U>)"
by (simp add: Iset_def starP2_star_n)

text {* Transfer tactic should remove occurrences of @{term Iset} *}
setup {* Transfer_Principle.add_const @{const_name Iset} *}

lemma transfer_mem [transfer_intro]:
  "\<lbrakk>x \<equiv> star_n X; a \<equiv> Iset (star_n A)\<rbrakk>
    \<Longrightarrow> x \<in> a \<equiv> eventually (\<lambda>n. X n \<in> A n) \<U>"
by (simp only: Iset_star_n)

lemma transfer_Collect [transfer_intro]:
  "\<lbrakk>\<And>X. p (star_n X) \<equiv> eventually (\<lambda>n. P n (X n)) \<U>\<rbrakk>
    \<Longrightarrow> Collect p \<equiv> Iset (star_n (\<lambda>n. Collect (P n)))"
by (simp add: atomize_eq set_eq_iff all_star_eq Iset_star_n)

lemma transfer_set_eq [transfer_intro]:
  "\<lbrakk>a \<equiv> Iset (star_n A); b \<equiv> Iset (star_n B)\<rbrakk>
    \<Longrightarrow> a = b \<equiv> eventually (\<lambda>n. A n = B n) \<U>"
by (simp only: set_eq_iff transfer_all transfer_iff transfer_mem)

lemma transfer_ball [transfer_intro]:
  "\<lbrakk>a \<equiv> Iset (star_n A); \<And>X. p (star_n X) \<equiv> eventually (\<lambda>n. P n (X n)) \<U>\<rbrakk>
    \<Longrightarrow> \<forall>x\<in>a. p x \<equiv> eventually (\<lambda>n. \<forall>x\<in>A n. P n x) \<U>"
by (simp only: Ball_def transfer_all transfer_imp transfer_mem)

lemma transfer_bex [transfer_intro]:
  "\<lbrakk>a \<equiv> Iset (star_n A); \<And>X. p (star_n X) \<equiv> eventually (\<lambda>n. P n (X n)) \<U>\<rbrakk>
    \<Longrightarrow> \<exists>x\<in>a. p x \<equiv> eventually (\<lambda>n. \<exists>x\<in>A n. P n x) \<U>"
by (simp only: Bex_def transfer_ex transfer_conj transfer_mem)

lemma transfer_Iset [transfer_intro]:
  "\<lbrakk>a \<equiv> star_n A\<rbrakk> \<Longrightarrow> Iset a \<equiv> Iset (star_n (\<lambda>n. A n))"
by simp

text {* Nonstandard extensions of sets. *}

definition
  starset :: "'a set \<Rightarrow> 'a star set" ("*s* _" [80] 80) where
  "starset A = Iset (star_of A)"

declare starset_def [transfer_unfold]

lemma starset_mem: "(star_of x \<in> *s* A) = (x \<in> A)"
by (transfer, rule refl)

lemma starset_UNIV: "*s* (UNIV::'a set) = (UNIV::'a star set)"
by (transfer UNIV_def, rule refl)

lemma starset_empty: "*s* {} = {}"
by (transfer empty_def, rule refl)

lemma starset_insert: "*s* (insert x A) = insert (star_of x) ( *s* A)"
by (transfer insert_def Un_def, rule refl)

lemma starset_Un: "*s* (A \<union> B) = *s* A \<union> *s* B"
by (transfer Un_def, rule refl)

lemma starset_Int: "*s* (A \<inter> B) = *s* A \<inter> *s* B"
by (transfer Int_def, rule refl)

lemma starset_Compl: "*s* -A = -( *s* A)"
by (transfer Compl_eq, rule refl)

lemma starset_diff: "*s* (A - B) = *s* A - *s* B"
by (transfer set_diff_eq, rule refl)

lemma starset_image: "*s* (f ` A) = ( *f* f) ` ( *s* A)"
by (transfer image_def, rule refl)

lemma starset_vimage: "*s* (f -` A) = ( *f* f) -` ( *s* A)"
by (transfer vimage_def, rule refl)

lemma starset_subset: "( *s* A \<subseteq> *s* B) = (A \<subseteq> B)"
by (transfer subset_eq, rule refl)

lemma starset_eq: "( *s* A = *s* B) = (A = B)"
by (transfer, rule refl)

lemmas starset_simps [simp] =
  starset_mem     starset_UNIV
  starset_empty   starset_insert
  starset_Un      starset_Int
  starset_Compl   starset_diff
  starset_image   starset_vimage
  starset_subset  starset_eq


subsection {* Syntactic classes *}

instantiation star :: (zero) zero
begin

definition
  star_zero_def:    "0 \<equiv> star_of 0"

instance ..

end

instantiation star :: (one) one
begin

definition
  star_one_def:     "1 \<equiv> star_of 1"

instance ..

end

instantiation star :: (plus) plus
begin

definition
  star_add_def:     "(op +) \<equiv> *f2* (op +)"

instance ..

end

instantiation star :: (times) times
begin

definition
  star_mult_def:    "(op *) \<equiv> *f2* (op *)"

instance ..

end

instantiation star :: (uminus) uminus
begin

definition
  star_minus_def:   "uminus \<equiv> *f* uminus"

instance ..

end

instantiation star :: (minus) minus
begin

definition
  star_diff_def:    "(op -) \<equiv> *f2* (op -)"

instance ..

end

instantiation star :: (abs) abs
begin

definition
  star_abs_def:     "abs \<equiv> *f* abs"

instance ..

end

instantiation star :: (sgn) sgn
begin

definition
  star_sgn_def:     "sgn \<equiv> *f* sgn"

instance ..

end

instantiation star :: (divide) divide
begin

definition
  star_divide_def:  "divide \<equiv> *f2* divide"

instance ..

end

instantiation star :: (inverse) inverse
begin

definition
  star_inverse_def: "inverse \<equiv> *f* inverse"

instance ..

end

instance star :: (Rings.dvd) Rings.dvd ..

instantiation star :: (Divides.div) Divides.div
begin

definition
  star_mod_def:     "(op mod) \<equiv> *f2* (op mod)"

instance ..

end

instantiation star :: (ord) ord
begin

definition
  star_le_def:      "(op \<le>) \<equiv> *p2* (op \<le>)"

definition
  star_less_def:    "(op <) \<equiv> *p2* (op <)"

instance ..

end

lemmas star_class_defs [transfer_unfold] =
  star_zero_def     star_one_def
  star_add_def      star_diff_def     star_minus_def
  star_mult_def     star_divide_def   star_inverse_def
  star_le_def       star_less_def     star_abs_def       star_sgn_def
  star_mod_def

text {* Class operations preserve standard elements *}

lemma Standard_zero: "0 \<in> Standard"
by (simp add: star_zero_def)

lemma Standard_one: "1 \<in> Standard"
by (simp add: star_one_def)

lemma Standard_add: "\<lbrakk>x \<in> Standard; y \<in> Standard\<rbrakk> \<Longrightarrow> x + y \<in> Standard"
by (simp add: star_add_def)

lemma Standard_diff: "\<lbrakk>x \<in> Standard; y \<in> Standard\<rbrakk> \<Longrightarrow> x - y \<in> Standard"
by (simp add: star_diff_def)

lemma Standard_minus: "x \<in> Standard \<Longrightarrow> - x \<in> Standard"
by (simp add: star_minus_def)

lemma Standard_mult: "\<lbrakk>x \<in> Standard; y \<in> Standard\<rbrakk> \<Longrightarrow> x * y \<in> Standard"
by (simp add: star_mult_def)

lemma Standard_divide: "\<lbrakk>x \<in> Standard; y \<in> Standard\<rbrakk> \<Longrightarrow> x / y \<in> Standard"
by (simp add: star_divide_def)

lemma Standard_inverse: "x \<in> Standard \<Longrightarrow> inverse x \<in> Standard"
by (simp add: star_inverse_def)

lemma Standard_abs: "x \<in> Standard \<Longrightarrow> abs x \<in> Standard"
by (simp add: star_abs_def)

lemma Standard_mod: "\<lbrakk>x \<in> Standard; y \<in> Standard\<rbrakk> \<Longrightarrow> x mod y \<in> Standard"
by (simp add: star_mod_def)

lemmas Standard_simps [simp] =
  Standard_zero  Standard_one
  Standard_add   Standard_diff    Standard_minus
  Standard_mult  Standard_divide  Standard_inverse
  Standard_abs   Standard_mod

text {* @{term star_of} preserves class operations *}

lemma star_of_add: "star_of (x + y) = star_of x + star_of y"
by transfer (rule refl)

lemma star_of_diff: "star_of (x - y) = star_of x - star_of y"
by transfer (rule refl)

lemma star_of_minus: "star_of (-x) = - star_of x"
by transfer (rule refl)

lemma star_of_mult: "star_of (x * y) = star_of x * star_of y"
by transfer (rule refl)

lemma star_of_divide: "star_of (x / y) = star_of x / star_of y"
by transfer (rule refl)

lemma star_of_inverse: "star_of (inverse x) = inverse (star_of x)"
by transfer (rule refl)

lemma star_of_mod: "star_of (x mod y) = star_of x mod star_of y"
by transfer (rule refl)

lemma star_of_abs: "star_of (abs x) = abs (star_of x)"
by transfer (rule refl)

text {* @{term star_of} preserves numerals *}

lemma star_of_zero: "star_of 0 = 0"
by transfer (rule refl)

lemma star_of_one: "star_of 1 = 1"
by transfer (rule refl)

text {* @{term star_of} preserves orderings *}

lemma star_of_less: "(star_of x < star_of y) = (x < y)"
by transfer (rule refl)

lemma star_of_le: "(star_of x \<le> star_of y) = (x \<le> y)"
by transfer (rule refl)

lemma star_of_eq: "(star_of x = star_of y) = (x = y)"
by transfer (rule refl)

text{*As above, for 0*}

lemmas star_of_0_less = star_of_less [of 0, simplified star_of_zero]
lemmas star_of_0_le   = star_of_le   [of 0, simplified star_of_zero]
lemmas star_of_0_eq   = star_of_eq   [of 0, simplified star_of_zero]

lemmas star_of_less_0 = star_of_less [of _ 0, simplified star_of_zero]
lemmas star_of_le_0   = star_of_le   [of _ 0, simplified star_of_zero]
lemmas star_of_eq_0   = star_of_eq   [of _ 0, simplified star_of_zero]

text{*As above, for 1*}

lemmas star_of_1_less = star_of_less [of 1, simplified star_of_one]
lemmas star_of_1_le   = star_of_le   [of 1, simplified star_of_one]
lemmas star_of_1_eq   = star_of_eq   [of 1, simplified star_of_one]

lemmas star_of_less_1 = star_of_less [of _ 1, simplified star_of_one]
lemmas star_of_le_1   = star_of_le   [of _ 1, simplified star_of_one]
lemmas star_of_eq_1   = star_of_eq   [of _ 1, simplified star_of_one]

lemmas star_of_simps [simp] =
  star_of_add     star_of_diff    star_of_minus
  star_of_mult    star_of_divide  star_of_inverse
  star_of_mod     star_of_abs
  star_of_zero    star_of_one
  star_of_less    star_of_le      star_of_eq
  star_of_0_less  star_of_0_le    star_of_0_eq
  star_of_less_0  star_of_le_0    star_of_eq_0
  star_of_1_less  star_of_1_le    star_of_1_eq
  star_of_less_1  star_of_le_1    star_of_eq_1

subsection {* Ordering and lattice classes *}

instance star :: (order) order
apply (intro_classes)
apply (transfer, rule less_le_not_le)
apply (transfer, rule order_refl)
apply (transfer, erule (1) order_trans)
apply (transfer, erule (1) order_antisym)
done

instantiation star :: (semilattice_inf) semilattice_inf
begin

definition
  star_inf_def [transfer_unfold]: "inf \<equiv> *f2* inf"

instance
  by default (transfer, auto)+

end

instantiation star :: (semilattice_sup) semilattice_sup
begin

definition
  star_sup_def [transfer_unfold]: "sup \<equiv> *f2* sup"

instance
  by default (transfer, auto)+

end

instance star :: (lattice) lattice ..

instance star :: (distrib_lattice) distrib_lattice
  by default (transfer, auto simp add: sup_inf_distrib1)

lemma Standard_inf [simp]:
  "\<lbrakk>x \<in> Standard; y \<in> Standard\<rbrakk> \<Longrightarrow> inf x y \<in> Standard"
by (simp add: star_inf_def)

lemma Standard_sup [simp]:
  "\<lbrakk>x \<in> Standard; y \<in> Standard\<rbrakk> \<Longrightarrow> sup x y \<in> Standard"
by (simp add: star_sup_def)

lemma star_of_inf [simp]: "star_of (inf x y) = inf (star_of x) (star_of y)"
by transfer (rule refl)

lemma star_of_sup [simp]: "star_of (sup x y) = sup (star_of x) (star_of y)"
by transfer (rule refl)

instance star :: (linorder) linorder
by (intro_classes, transfer, rule linorder_linear)

lemma star_max_def [transfer_unfold]: "max = *f2* max"
apply (rule ext, rule ext)
apply (unfold max_def, transfer, fold max_def)
apply (rule refl)
done

lemma star_min_def [transfer_unfold]: "min = *f2* min"
apply (rule ext, rule ext)
apply (unfold min_def, transfer, fold min_def)
apply (rule refl)
done

lemma Standard_max [simp]:
  "\<lbrakk>x \<in> Standard; y \<in> Standard\<rbrakk> \<Longrightarrow> max x y \<in> Standard"
by (simp add: star_max_def)

lemma Standard_min [simp]:
  "\<lbrakk>x \<in> Standard; y \<in> Standard\<rbrakk> \<Longrightarrow> min x y \<in> Standard"
by (simp add: star_min_def)

lemma star_of_max [simp]: "star_of (max x y) = max (star_of x) (star_of y)"
by transfer (rule refl)

lemma star_of_min [simp]: "star_of (min x y) = min (star_of x) (star_of y)"
by transfer (rule refl)


subsection {* Ordered group classes *}

instance star :: (semigroup_add) semigroup_add
by (intro_classes, transfer, rule add.assoc)

instance star :: (ab_semigroup_add) ab_semigroup_add
by (intro_classes, transfer, rule add.commute)

instance star :: (semigroup_mult) semigroup_mult
by (intro_classes, transfer, rule mult.assoc)

instance star :: (ab_semigroup_mult) ab_semigroup_mult
by (intro_classes, transfer, rule mult.commute)

instance star :: (comm_monoid_add) comm_monoid_add
by (intro_classes, transfer, rule comm_monoid_add_class.add_0)

instance star :: (monoid_mult) monoid_mult
apply (intro_classes)
apply (transfer, rule mult_1_left)
apply (transfer, rule mult_1_right)
done

instance star :: (comm_monoid_mult) comm_monoid_mult
by (intro_classes, transfer, rule mult_1)

instance star :: (cancel_semigroup_add) cancel_semigroup_add
apply (intro_classes)
apply (transfer, erule add_left_imp_eq)
apply (transfer, erule add_right_imp_eq)
done

instance star :: (cancel_ab_semigroup_add) cancel_ab_semigroup_add
by intro_classes (transfer, simp add: diff_diff_eq)+

instance star :: (cancel_comm_monoid_add) cancel_comm_monoid_add ..

instance star :: (ab_group_add) ab_group_add
apply (intro_classes)
apply (transfer, rule left_minus)
apply (transfer, rule diff_conv_add_uminus)
done

instance star :: (ordered_ab_semigroup_add) ordered_ab_semigroup_add
by (intro_classes, transfer, rule add_left_mono)

instance star :: (ordered_cancel_ab_semigroup_add) ordered_cancel_ab_semigroup_add ..

instance star :: (ordered_ab_semigroup_add_imp_le) ordered_ab_semigroup_add_imp_le
by (intro_classes, transfer, rule add_le_imp_le_left)

instance star :: (ordered_comm_monoid_add) ordered_comm_monoid_add ..
instance star :: (ordered_ab_group_add) ordered_ab_group_add ..

instance star :: (ordered_ab_group_add_abs) ordered_ab_group_add_abs 
  by intro_classes (transfer,
    simp add: abs_ge_self abs_leI abs_triangle_ineq)+

instance star :: (linordered_cancel_ab_semigroup_add) linordered_cancel_ab_semigroup_add ..


subsection {* Ring and field classes *}

instance star :: (semiring) semiring
  by (intro_classes; transfer) (fact distrib_right distrib_left)+

instance star :: (semiring_0) semiring_0 
  by (intro_classes; transfer) simp_all

instance star :: (semiring_0_cancel) semiring_0_cancel ..

instance star :: (comm_semiring) comm_semiring 
  by (intro_classes; transfer) (fact distrib_right)

instance star :: (comm_semiring_0) comm_semiring_0 ..
instance star :: (comm_semiring_0_cancel) comm_semiring_0_cancel ..

instance star :: (zero_neq_one) zero_neq_one
  by (intro_classes; transfer) (fact zero_neq_one)

instance star :: (semiring_1) semiring_1 ..
instance star :: (comm_semiring_1) comm_semiring_1 ..

declare dvd_def [transfer_refold]

instance star :: (comm_semiring_1_cancel) comm_semiring_1_cancel
  by (intro_classes; transfer) (fact right_diff_distrib')

instance star :: (semiring_no_zero_divisors) semiring_no_zero_divisors
  by (intro_classes; transfer) (fact no_zero_divisors)

instance star :: (semiring_no_zero_divisors_cancel) semiring_no_zero_divisors_cancel
  by (intro_classes; transfer) simp_all

instance star :: (semiring_1_cancel) semiring_1_cancel ..
instance star :: (ring) ring ..
instance star :: (comm_ring) comm_ring ..
instance star :: (ring_1) ring_1 ..
instance star :: (comm_ring_1) comm_ring_1 ..
instance star :: (semidom) semidom ..

instance star :: (semidom_divide) semidom_divide
  by (intro_classes; transfer) simp_all

instance star :: (semiring_div) semiring_div
  by (intro_classes; transfer) (simp_all add: mod_div_equality)

instance star :: (ring_no_zero_divisors) ring_no_zero_divisors ..
instance star :: (ring_1_no_zero_divisors) ring_1_no_zero_divisors ..
instance star :: (idom) idom .. 
instance star :: (idom_divide) idom_divide ..

instance star :: (division_ring) division_ring
  by (intro_classes; transfer) (simp_all add: divide_inverse)

instance star :: (field) field
  by (intro_classes; transfer) (simp_all add: divide_inverse)

instance star :: (ordered_semiring) ordered_semiring
  by (intro_classes; transfer) (fact mult_left_mono mult_right_mono)+

instance star :: (ordered_cancel_semiring) ordered_cancel_semiring ..

instance star :: (linordered_semiring_strict) linordered_semiring_strict
  by (intro_classes; transfer) (fact mult_strict_left_mono mult_strict_right_mono)+

instance star :: (ordered_comm_semiring) ordered_comm_semiring
  by (intro_classes; transfer) (fact mult_left_mono)

instance star :: (ordered_cancel_comm_semiring) ordered_cancel_comm_semiring ..

instance star :: (linordered_comm_semiring_strict) linordered_comm_semiring_strict
  by (intro_classes; transfer) (fact mult_strict_left_mono)

instance star :: (ordered_ring) ordered_ring ..

instance star :: (ordered_ring_abs) ordered_ring_abs
  by (intro_classes; transfer) (fact abs_eq_mult)

instance star :: (abs_if) abs_if
  by (intro_classes; transfer) (fact abs_if)

instance star :: (sgn_if) sgn_if
  by (intro_classes; transfer) (fact sgn_if)

instance star :: (linordered_ring_strict) linordered_ring_strict ..
instance star :: (ordered_comm_ring) ordered_comm_ring ..

instance star :: (linordered_semidom) linordered_semidom
  apply intro_classes
  apply(transfer, fact zero_less_one)
  apply(transfer, fact le_add_diff_inverse2)
  done

instance star :: (linordered_idom) linordered_idom ..
instance star :: (linordered_field) linordered_field ..

subsection {* Power *}

lemma star_power_def [transfer_unfold]:
  "(op ^) \<equiv> \<lambda>x n. ( *f* (\<lambda>x. x ^ n)) x"
proof (rule eq_reflection, rule ext, rule ext)
  fix n :: nat
  show "\<And>x::'a star. x ^ n = ( *f* (\<lambda>x. x ^ n)) x" 
  proof (induct n)
    case 0
    have "\<And>x::'a star. ( *f* (\<lambda>x. 1)) x = 1"
      by transfer simp
    then show ?case by simp
  next
    case (Suc n)
    have "\<And>x::'a star. x * ( *f* (\<lambda>x\<Colon>'a. x ^ n)) x = ( *f* (\<lambda>x\<Colon>'a. x * x ^ n)) x"
      by transfer simp
    with Suc show ?case by simp
  qed
qed

lemma Standard_power [simp]: "x \<in> Standard \<Longrightarrow> x ^ n \<in> Standard"
  by (simp add: star_power_def)

lemma star_of_power [simp]: "star_of (x ^ n) = star_of x ^ n"
  by transfer (rule refl)


subsection {* Number classes *}

instance star :: (numeral) numeral ..

lemma star_numeral_def [transfer_unfold]:
  "numeral k = star_of (numeral k)"
by (induct k, simp_all only: numeral.simps star_of_one star_of_add)

lemma Standard_numeral [simp]: "numeral k \<in> Standard"
by (simp add: star_numeral_def)

lemma star_of_numeral [simp]: "star_of (numeral k) = numeral k"
by transfer (rule refl)

lemma star_of_nat_def [transfer_unfold]: "of_nat n = star_of (of_nat n)"
by (induct n, simp_all)

lemmas star_of_compare_numeral [simp] =
  star_of_less [of "numeral k", simplified star_of_numeral]
  star_of_le   [of "numeral k", simplified star_of_numeral]
  star_of_eq   [of "numeral k", simplified star_of_numeral]
  star_of_less [of _ "numeral k", simplified star_of_numeral]
  star_of_le   [of _ "numeral k", simplified star_of_numeral]
  star_of_eq   [of _ "numeral k", simplified star_of_numeral]
  star_of_less [of "- numeral k", simplified star_of_numeral]
  star_of_le   [of "- numeral k", simplified star_of_numeral]
  star_of_eq   [of "- numeral k", simplified star_of_numeral]
  star_of_less [of _ "- numeral k", simplified star_of_numeral]
  star_of_le   [of _ "- numeral k", simplified star_of_numeral]
  star_of_eq   [of _ "- numeral k", simplified star_of_numeral] for k

lemma Standard_of_nat [simp]: "of_nat n \<in> Standard"
by (simp add: star_of_nat_def)

lemma star_of_of_nat [simp]: "star_of (of_nat n) = of_nat n"
by transfer (rule refl)

lemma star_of_int_def [transfer_unfold]: "of_int z = star_of (of_int z)"
by (rule_tac z=z in int_diff_cases, simp)

lemma Standard_of_int [simp]: "of_int z \<in> Standard"
by (simp add: star_of_int_def)

lemma star_of_of_int [simp]: "star_of (of_int z) = of_int z"
by transfer (rule refl)

instance star :: (semiring_char_0) semiring_char_0 proof
  have "inj (star_of :: 'a \<Rightarrow> 'a star)" by (rule injI) simp
  then have "inj (star_of \<circ> of_nat :: nat \<Rightarrow> 'a star)" using inj_of_nat by (rule inj_comp)
  then show "inj (of_nat :: nat \<Rightarrow> 'a star)" by (simp add: comp_def)
qed

instance star :: (ring_char_0) ring_char_0 ..

instance star :: (semiring_parity) semiring_parity
apply intro_classes
apply(transfer, rule odd_one)
apply(transfer, erule (1) odd_even_add)
apply(transfer, erule even_multD)
apply(transfer, erule odd_ex_decrement)
done

instance star :: (semiring_div_parity) semiring_div_parity
apply intro_classes
apply(transfer, rule parity)
apply(transfer, rule one_mod_two_eq_one)
apply(transfer, rule zero_not_eq_two)
done

instance star :: (semiring_numeral_div) semiring_numeral_div
apply intro_classes
apply(transfer, fact semiring_numeral_div_class.div_less)
apply(transfer, fact semiring_numeral_div_class.mod_less)
apply(transfer, fact semiring_numeral_div_class.div_positive)
apply(transfer, fact semiring_numeral_div_class.mod_less_eq_dividend)
apply(transfer, fact semiring_numeral_div_class.pos_mod_bound)
apply(transfer, fact semiring_numeral_div_class.pos_mod_sign)
apply(transfer, fact semiring_numeral_div_class.mod_mult2_eq)
apply(transfer, fact semiring_numeral_div_class.div_mult2_eq)
apply(transfer, fact discrete)
done

subsection {* Finite class *}

lemma starset_finite: "finite A \<Longrightarrow> *s* A = star_of ` A"
by (erule finite_induct, simp_all)

instance star :: (finite) finite
apply (intro_classes)
apply (subst starset_UNIV [symmetric])
apply (subst starset_finite [OF finite])
apply (rule finite_imageI [OF finite])
done

end

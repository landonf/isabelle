(*  Title:      HOL/Library/Extended_Nat.thy
    Author:     David von Oheimb, TU Muenchen;  Florian Haftmann, TU Muenchen
    Contributions: David Trachtenherz, TU Muenchen
*)

header {* Extended natural numbers (i.e. with infinity) *}

theory Extended_Nat
imports Main
begin

class infinity =
  fixes infinity :: "'a"

notation (xsymbols)
  infinity  ("\<infinity>")

notation (HTML output)
  infinity  ("\<infinity>")

subsection {* Type definition *}

text {*
  We extend the standard natural numbers by a special value indicating
  infinity.
*}

typedef (open) enat = "UNIV :: nat option set" ..
 
definition enat :: "nat \<Rightarrow> enat" where
  "enat n = Abs_enat (Some n)"
 
instantiation enat :: infinity
begin
  definition "\<infinity> = Abs_enat None"
  instance proof qed
end
 
rep_datatype enat "\<infinity> :: enat"
proof -
  fix P i assume "\<And>j. P (enat j)" "P \<infinity>"
  then show "P i"
  proof induct
    case (Abs_enat y) then show ?case
      by (cases y rule: option.exhaust)
         (auto simp: enat_def infinity_enat_def)
  qed
qed (auto simp add: enat_def infinity_enat_def Abs_enat_inject)

declare [[coercion "enat::nat\<Rightarrow>enat"]]

lemma not_Infty_eq[iff]: "(x \<noteq> \<infinity>) = (EX i. x = enat i)"
by (cases x) auto

lemma not_enat_eq [iff]: "(ALL y. x ~= enat y) = (x = \<infinity>)"
by (cases x) auto

primrec the_enat :: "enat \<Rightarrow> nat"
where "the_enat (enat n) = n"

subsection {* Constructors and numbers *}

instantiation enat :: "{zero, one, number}"
begin

definition
  "0 = enat 0"

definition
  [code_unfold]: "1 = enat 1"

definition
  [code_unfold, code del]: "number_of k = enat (number_of k)"

instance ..

end

definition iSuc :: "enat \<Rightarrow> enat" where
  "iSuc i = (case i of enat n \<Rightarrow> enat (Suc n) | \<infinity> \<Rightarrow> \<infinity>)"

lemma enat_0: "enat 0 = 0"
  by (simp add: zero_enat_def)

lemma enat_1: "enat 1 = 1"
  by (simp add: one_enat_def)

lemma enat_number: "enat (number_of k) = number_of k"
  by (simp add: number_of_enat_def)

lemma one_iSuc: "1 = iSuc 0"
  by (simp add: zero_enat_def one_enat_def iSuc_def)

lemma Infty_ne_i0 [simp]: "(\<infinity>::enat) \<noteq> 0"
  by (simp add: zero_enat_def)

lemma i0_ne_Infty [simp]: "0 \<noteq> (\<infinity>::enat)"
  by (simp add: zero_enat_def)

lemma zero_enat_eq [simp]:
  "number_of k = (0\<Colon>enat) \<longleftrightarrow> number_of k = (0\<Colon>nat)"
  "(0\<Colon>enat) = number_of k \<longleftrightarrow> number_of k = (0\<Colon>nat)"
  unfolding zero_enat_def number_of_enat_def by simp_all

lemma one_enat_eq [simp]:
  "number_of k = (1\<Colon>enat) \<longleftrightarrow> number_of k = (1\<Colon>nat)"
  "(1\<Colon>enat) = number_of k \<longleftrightarrow> number_of k = (1\<Colon>nat)"
  unfolding one_enat_def number_of_enat_def by simp_all

lemma zero_one_enat_neq [simp]:
  "\<not> 0 = (1\<Colon>enat)"
  "\<not> 1 = (0\<Colon>enat)"
  unfolding zero_enat_def one_enat_def by simp_all

lemma Infty_ne_i1 [simp]: "(\<infinity>::enat) \<noteq> 1"
  by (simp add: one_enat_def)

lemma i1_ne_Infty [simp]: "1 \<noteq> (\<infinity>::enat)"
  by (simp add: one_enat_def)

lemma Infty_ne_number [simp]: "(\<infinity>::enat) \<noteq> number_of k"
  by (simp add: number_of_enat_def)

lemma number_ne_Infty [simp]: "number_of k \<noteq> (\<infinity>::enat)"
  by (simp add: number_of_enat_def)

lemma iSuc_enat: "iSuc (enat n) = enat (Suc n)"
  by (simp add: iSuc_def)

lemma iSuc_number_of: "iSuc (number_of k) = enat (Suc (number_of k))"
  by (simp add: iSuc_enat number_of_enat_def)

lemma iSuc_Infty [simp]: "iSuc \<infinity> = \<infinity>"
  by (simp add: iSuc_def)

lemma iSuc_ne_0 [simp]: "iSuc n \<noteq> 0"
  by (simp add: iSuc_def zero_enat_def split: enat.splits)

lemma zero_ne_iSuc [simp]: "0 \<noteq> iSuc n"
  by (rule iSuc_ne_0 [symmetric])

lemma iSuc_inject [simp]: "iSuc m = iSuc n \<longleftrightarrow> m = n"
  by (simp add: iSuc_def split: enat.splits)

lemma number_of_enat_inject [simp]:
  "(number_of k \<Colon> enat) = number_of l \<longleftrightarrow> (number_of k \<Colon> nat) = number_of l"
  by (simp add: number_of_enat_def)


subsection {* Addition *}

instantiation enat :: comm_monoid_add
begin

definition [nitpick_simp]:
  "m + n = (case m of \<infinity> \<Rightarrow> \<infinity> | enat m \<Rightarrow> (case n of \<infinity> \<Rightarrow> \<infinity> | enat n \<Rightarrow> enat (m + n)))"

lemma plus_enat_simps [simp, code]:
  fixes q :: enat
  shows "enat m + enat n = enat (m + n)"
    and "\<infinity> + q = \<infinity>"
    and "q + \<infinity> = \<infinity>"
  by (simp_all add: plus_enat_def split: enat.splits)

instance proof
  fix n m q :: enat
  show "n + m + q = n + (m + q)"
    by (cases n, auto, cases m, auto, cases q, auto)
  show "n + m = m + n"
    by (cases n, auto, cases m, auto)
  show "0 + n = n"
    by (cases n) (simp_all add: zero_enat_def)
qed

end

lemma plus_enat_0 [simp]:
  "0 + (q\<Colon>enat) = q"
  "(q\<Colon>enat) + 0 = q"
  by (simp_all add: plus_enat_def zero_enat_def split: enat.splits)

lemma plus_enat_number [simp]:
  "(number_of k \<Colon> enat) + number_of l = (if k < Int.Pls then number_of l
    else if l < Int.Pls then number_of k else number_of (k + l))"
  unfolding number_of_enat_def plus_enat_simps nat_arith(1) if_distrib [symmetric, of _ enat] ..

lemma iSuc_number [simp]:
  "iSuc (number_of k) = (if neg (number_of k \<Colon> int) then 1 else number_of (Int.succ k))"
  unfolding iSuc_number_of
  unfolding one_enat_def number_of_enat_def Suc_nat_number_of if_distrib [symmetric] ..

lemma iSuc_plus_1:
  "iSuc n = n + 1"
  by (cases n) (simp_all add: iSuc_enat one_enat_def)
  
lemma plus_1_iSuc:
  "1 + q = iSuc q"
  "q + 1 = iSuc q"
by (simp_all add: iSuc_plus_1 add_ac)

lemma iadd_Suc: "iSuc m + n = iSuc (m + n)"
by (simp_all add: iSuc_plus_1 add_ac)

lemma iadd_Suc_right: "m + iSuc n = iSuc (m + n)"
by (simp only: add_commute[of m] iadd_Suc)

lemma iadd_is_0: "(m + n = (0::enat)) = (m = 0 \<and> n = 0)"
by (cases m, cases n, simp_all add: zero_enat_def)

subsection {* Multiplication *}

instantiation enat :: comm_semiring_1
begin

definition times_enat_def [nitpick_simp]:
  "m * n = (case m of \<infinity> \<Rightarrow> if n = 0 then 0 else \<infinity> | enat m \<Rightarrow>
    (case n of \<infinity> \<Rightarrow> if m = 0 then 0 else \<infinity> | enat n \<Rightarrow> enat (m * n)))"

lemma times_enat_simps [simp, code]:
  "enat m * enat n = enat (m * n)"
  "\<infinity> * \<infinity> = (\<infinity>::enat)"
  "\<infinity> * enat n = (if n = 0 then 0 else \<infinity>)"
  "enat m * \<infinity> = (if m = 0 then 0 else \<infinity>)"
  unfolding times_enat_def zero_enat_def
  by (simp_all split: enat.split)

instance proof
  fix a b c :: enat
  show "(a * b) * c = a * (b * c)"
    unfolding times_enat_def zero_enat_def
    by (simp split: enat.split)
  show "a * b = b * a"
    unfolding times_enat_def zero_enat_def
    by (simp split: enat.split)
  show "1 * a = a"
    unfolding times_enat_def zero_enat_def one_enat_def
    by (simp split: enat.split)
  show "(a + b) * c = a * c + b * c"
    unfolding times_enat_def zero_enat_def
    by (simp split: enat.split add: left_distrib)
  show "0 * a = 0"
    unfolding times_enat_def zero_enat_def
    by (simp split: enat.split)
  show "a * 0 = 0"
    unfolding times_enat_def zero_enat_def
    by (simp split: enat.split)
  show "(0::enat) \<noteq> 1"
    unfolding zero_enat_def one_enat_def
    by simp
qed

end

lemma mult_iSuc: "iSuc m * n = n + m * n"
  unfolding iSuc_plus_1 by (simp add: algebra_simps)

lemma mult_iSuc_right: "m * iSuc n = m + m * n"
  unfolding iSuc_plus_1 by (simp add: algebra_simps)

lemma of_nat_eq_enat: "of_nat n = enat n"
  apply (induct n)
  apply (simp add: enat_0)
  apply (simp add: plus_1_iSuc iSuc_enat)
  done

instance enat :: number_semiring
proof
  fix n show "number_of (int n) = (of_nat n :: enat)"
    unfolding number_of_enat_def number_of_int of_nat_id of_nat_eq_enat ..
qed

instance enat :: semiring_char_0 proof
  have "inj enat" by (rule injI) simp
  then show "inj (\<lambda>n. of_nat n :: enat)" by (simp add: of_nat_eq_enat)
qed

lemma imult_is_0[simp]: "((m::enat) * n = 0) = (m = 0 \<or> n = 0)"
by(auto simp add: times_enat_def zero_enat_def split: enat.split)

lemma imult_is_Infty: "((a::enat) * b = \<infinity>) = (a = \<infinity> \<and> b \<noteq> 0 \<or> b = \<infinity> \<and> a \<noteq> 0)"
by(auto simp add: times_enat_def zero_enat_def split: enat.split)


subsection {* Subtraction *}

instantiation enat :: minus
begin

definition diff_enat_def:
"a - b = (case a of (enat x) \<Rightarrow> (case b of (enat y) \<Rightarrow> enat (x - y) | \<infinity> \<Rightarrow> 0)
          | \<infinity> \<Rightarrow> \<infinity>)"

instance ..

end

lemma idiff_enat_enat[simp,code]: "enat a - enat b = enat (a - b)"
by(simp add: diff_enat_def)

lemma idiff_Infty[simp,code]: "\<infinity> - n = (\<infinity>::enat)"
by(simp add: diff_enat_def)

lemma idiff_Infty_right[simp,code]: "enat a - \<infinity> = 0"
by(simp add: diff_enat_def)

lemma idiff_0[simp]: "(0::enat) - n = 0"
by (cases n, simp_all add: zero_enat_def)

lemmas idiff_enat_0[simp] = idiff_0[unfolded zero_enat_def]

lemma idiff_0_right[simp]: "(n::enat) - 0 = n"
by (cases n) (simp_all add: zero_enat_def)

lemmas idiff_enat_0_right[simp] = idiff_0_right[unfolded zero_enat_def]

lemma idiff_self[simp]: "n \<noteq> \<infinity> \<Longrightarrow> (n::enat) - n = 0"
by(auto simp: zero_enat_def)

lemma iSuc_minus_iSuc [simp]: "iSuc n - iSuc m = n - m"
by(simp add: iSuc_def split: enat.split)

lemma iSuc_minus_1 [simp]: "iSuc n - 1 = n"
by(simp add: one_enat_def iSuc_enat[symmetric] zero_enat_def[symmetric])

(*lemmas idiff_self_eq_0_enat = idiff_self_eq_0[unfolded zero_enat_def]*)

subsection {* Ordering *}

instantiation enat :: linordered_ab_semigroup_add
begin

definition [nitpick_simp]:
  "m \<le> n = (case n of enat n1 \<Rightarrow> (case m of enat m1 \<Rightarrow> m1 \<le> n1 | \<infinity> \<Rightarrow> False)
    | \<infinity> \<Rightarrow> True)"

definition [nitpick_simp]:
  "m < n = (case m of enat m1 \<Rightarrow> (case n of enat n1 \<Rightarrow> m1 < n1 | \<infinity> \<Rightarrow> True)
    | \<infinity> \<Rightarrow> False)"

lemma enat_ord_simps [simp]:
  "enat m \<le> enat n \<longleftrightarrow> m \<le> n"
  "enat m < enat n \<longleftrightarrow> m < n"
  "q \<le> (\<infinity>::enat)"
  "q < (\<infinity>::enat) \<longleftrightarrow> q \<noteq> \<infinity>"
  "(\<infinity>::enat) \<le> q \<longleftrightarrow> q = \<infinity>"
  "(\<infinity>::enat) < q \<longleftrightarrow> False"
  by (simp_all add: less_eq_enat_def less_enat_def split: enat.splits)

lemma enat_ord_code [code]:
  "enat m \<le> enat n \<longleftrightarrow> m \<le> n"
  "enat m < enat n \<longleftrightarrow> m < n"
  "q \<le> (\<infinity>::enat) \<longleftrightarrow> True"
  "enat m < \<infinity> \<longleftrightarrow> True"
  "\<infinity> \<le> enat n \<longleftrightarrow> False"
  "(\<infinity>::enat) < q \<longleftrightarrow> False"
  by simp_all

instance by default
  (auto simp add: less_eq_enat_def less_enat_def plus_enat_def split: enat.splits)

end

instance enat :: ordered_comm_semiring
proof
  fix a b c :: enat
  assume "a \<le> b" and "0 \<le> c"
  thus "c * a \<le> c * b"
    unfolding times_enat_def less_eq_enat_def zero_enat_def
    by (simp split: enat.splits)
qed

lemma enat_ord_number [simp]:
  "(number_of m \<Colon> enat) \<le> number_of n \<longleftrightarrow> (number_of m \<Colon> nat) \<le> number_of n"
  "(number_of m \<Colon> enat) < number_of n \<longleftrightarrow> (number_of m \<Colon> nat) < number_of n"
  by (simp_all add: number_of_enat_def)

lemma i0_lb [simp]: "(0\<Colon>enat) \<le> n"
  by (simp add: zero_enat_def less_eq_enat_def split: enat.splits)

lemma ile0_eq [simp]: "n \<le> (0\<Colon>enat) \<longleftrightarrow> n = 0"
by (simp add: zero_enat_def less_eq_enat_def split: enat.splits)

lemma Infty_ileE [elim!]: "\<infinity> \<le> enat m \<Longrightarrow> R"
  by (simp add: zero_enat_def less_eq_enat_def split: enat.splits)

lemma Infty_ilessE [elim!]: "\<infinity> < enat m \<Longrightarrow> R"
  by simp

lemma not_iless0 [simp]: "\<not> n < (0\<Colon>enat)"
  by (simp add: zero_enat_def less_enat_def split: enat.splits)

lemma i0_less [simp]: "(0\<Colon>enat) < n \<longleftrightarrow> n \<noteq> 0"
by (simp add: zero_enat_def less_enat_def split: enat.splits)

lemma iSuc_ile_mono [simp]: "iSuc n \<le> iSuc m \<longleftrightarrow> n \<le> m"
  by (simp add: iSuc_def less_eq_enat_def split: enat.splits)
 
lemma iSuc_mono [simp]: "iSuc n < iSuc m \<longleftrightarrow> n < m"
  by (simp add: iSuc_def less_enat_def split: enat.splits)

lemma ile_iSuc [simp]: "n \<le> iSuc n"
  by (simp add: iSuc_def less_eq_enat_def split: enat.splits)

lemma not_iSuc_ilei0 [simp]: "\<not> iSuc n \<le> 0"
  by (simp add: zero_enat_def iSuc_def less_eq_enat_def split: enat.splits)

lemma i0_iless_iSuc [simp]: "0 < iSuc n"
  by (simp add: zero_enat_def iSuc_def less_enat_def split: enat.splits)

lemma iless_iSuc0[simp]: "(n < iSuc 0) = (n = 0)"
by (simp add: zero_enat_def iSuc_def less_enat_def split: enat.split)

lemma ileI1: "m < n \<Longrightarrow> iSuc m \<le> n"
  by (simp add: iSuc_def less_eq_enat_def less_enat_def split: enat.splits)

lemma Suc_ile_eq: "enat (Suc m) \<le> n \<longleftrightarrow> enat m < n"
  by (cases n) auto

lemma iless_Suc_eq [simp]: "enat m < iSuc n \<longleftrightarrow> enat m \<le> n"
  by (auto simp add: iSuc_def less_enat_def split: enat.splits)

lemma imult_Infty: "(0::enat) < n \<Longrightarrow> \<infinity> * n = \<infinity>"
by (simp add: zero_enat_def less_enat_def split: enat.splits)

lemma imult_Infty_right: "(0::enat) < n \<Longrightarrow> n * \<infinity> = \<infinity>"
by (simp add: zero_enat_def less_enat_def split: enat.splits)

lemma enat_0_less_mult_iff: "(0 < (m::enat) * n) = (0 < m \<and> 0 < n)"
by (simp only: i0_less imult_is_0, simp)

lemma mono_iSuc: "mono iSuc"
by(simp add: mono_def)


lemma min_enat_simps [simp]:
  "min (enat m) (enat n) = enat (min m n)"
  "min q 0 = 0"
  "min 0 q = 0"
  "min q (\<infinity>::enat) = q"
  "min (\<infinity>::enat) q = q"
  by (auto simp add: min_def)

lemma max_enat_simps [simp]:
  "max (enat m) (enat n) = enat (max m n)"
  "max q 0 = q"
  "max 0 q = q"
  "max q \<infinity> = (\<infinity>::enat)"
  "max \<infinity> q = (\<infinity>::enat)"
  by (simp_all add: max_def)

lemma enat_ile: "n \<le> enat m \<Longrightarrow> \<exists>k. n = enat k"
  by (cases n) simp_all

lemma enat_iless: "n < enat m \<Longrightarrow> \<exists>k. n = enat k"
  by (cases n) simp_all

lemma chain_incr: "\<forall>i. \<exists>j. Y i < Y j ==> \<exists>j. enat k < Y j"
apply (induct_tac k)
 apply (simp (no_asm) only: enat_0)
 apply (fast intro: le_less_trans [OF i0_lb])
apply (erule exE)
apply (drule spec)
apply (erule exE)
apply (drule ileI1)
apply (rule iSuc_enat [THEN subst])
apply (rule exI)
apply (erule (1) le_less_trans)
done

instantiation enat :: "{bot, top}"
begin

definition bot_enat :: enat where
  "bot_enat = 0"

definition top_enat :: enat where
  "top_enat = \<infinity>"

instance proof
qed (simp_all add: bot_enat_def top_enat_def)

end

lemma finite_enat_bounded:
  assumes le_fin: "\<And>y. y \<in> A \<Longrightarrow> y \<le> enat n"
  shows "finite A"
proof (rule finite_subset)
  show "finite (enat ` {..n})" by blast

  have "A \<subseteq> {..enat n}" using le_fin by fastsimp
  also have "\<dots> \<subseteq> enat ` {..n}"
    by (rule subsetI) (case_tac x, auto)
  finally show "A \<subseteq> enat ` {..n}" .
qed


subsection {* Well-ordering *}

lemma less_enatE:
  "[| n < enat m; !!k. n = enat k ==> k < m ==> P |] ==> P"
by (induct n) auto

lemma less_InftyE:
  "[| n < \<infinity>; !!k. n = enat k ==> P |] ==> P"
by (induct n) auto

lemma enat_less_induct:
  assumes prem: "!!n. \<forall>m::enat. m < n --> P m ==> P n" shows "P n"
proof -
  have P_enat: "!!k. P (enat k)"
    apply (rule nat_less_induct)
    apply (rule prem, clarify)
    apply (erule less_enatE, simp)
    done
  show ?thesis
  proof (induct n)
    fix nat
    show "P (enat nat)" by (rule P_enat)
  next
    show "P \<infinity>"
      apply (rule prem, clarify)
      apply (erule less_InftyE)
      apply (simp add: P_enat)
      done
  qed
qed

instance enat :: wellorder
proof
  fix P and n
  assume hyp: "(\<And>n\<Colon>enat. (\<And>m\<Colon>enat. m < n \<Longrightarrow> P m) \<Longrightarrow> P n)"
  show "P n" by (blast intro: enat_less_induct hyp)
qed

subsection {* Complete Lattice *}

instantiation enat :: complete_lattice
begin

definition inf_enat :: "enat \<Rightarrow> enat \<Rightarrow> enat" where
  "inf_enat \<equiv> min"

definition sup_enat :: "enat \<Rightarrow> enat \<Rightarrow> enat" where
  "sup_enat \<equiv> max"

definition Inf_enat :: "enat set \<Rightarrow> enat" where
  "Inf_enat A \<equiv> if A = {} then \<infinity> else (LEAST x. x \<in> A)"

definition Sup_enat :: "enat set \<Rightarrow> enat" where
  "Sup_enat A \<equiv> if A = {} then 0
    else if finite A then Max A
                     else \<infinity>"
instance proof
  fix x :: "enat" and A :: "enat set"
  { assume "x \<in> A" then show "Inf A \<le> x"
      unfolding Inf_enat_def by (auto intro: Least_le) }
  { assume "\<And>y. y \<in> A \<Longrightarrow> x \<le> y" then show "x \<le> Inf A"
      unfolding Inf_enat_def
      by (cases "A = {}") (auto intro: LeastI2_ex) }
  { assume "x \<in> A" then show "x \<le> Sup A"
      unfolding Sup_enat_def by (cases "finite A") auto }
  { assume "\<And>y. y \<in> A \<Longrightarrow> y \<le> x" then show "Sup A \<le> x"
      unfolding Sup_enat_def using finite_enat_bounded by auto }
qed (simp_all add: inf_enat_def sup_enat_def)
end

instance enat :: complete_linorder ..

subsection {* Traditional theorem names *}

lemmas enat_defs = zero_enat_def one_enat_def number_of_enat_def iSuc_def
  plus_enat_def less_eq_enat_def less_enat_def

end

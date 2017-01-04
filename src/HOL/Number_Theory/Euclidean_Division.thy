(*  Title:      HOL/Number_Theory/Euclidean_Division.thy
    Author:     Manuel Eberl, TU Muenchen
    Author:     Florian Haftmann, TU Muenchen
*)

section \<open>Division with remainder in euclidean (semi)rings\<close>

theory Euclidean_Division
  imports Main
begin

subsection \<open>Euclidean (semi)rings with explicit division and remainder\<close>
  
class euclidean_semiring = semidom_modulo + normalization_semidom + 
  fixes euclidean_size :: "'a \<Rightarrow> nat"
  assumes size_0 [simp]: "euclidean_size 0 = 0"
  assumes mod_size_less: 
    "b \<noteq> 0 \<Longrightarrow> euclidean_size (a mod b) < euclidean_size b"
  assumes size_mult_mono:
    "b \<noteq> 0 \<Longrightarrow> euclidean_size a \<le> euclidean_size (a * b)"
begin

lemma size_mult_mono': "b \<noteq> 0 \<Longrightarrow> euclidean_size a \<le> euclidean_size (b * a)"
  by (subst mult.commute) (rule size_mult_mono)

lemma euclidean_size_normalize [simp]:
  "euclidean_size (normalize a) = euclidean_size a"
proof (cases "a = 0")
  case True
  then show ?thesis
    by simp
next
  case [simp]: False
  have "euclidean_size (normalize a) \<le> euclidean_size (normalize a * unit_factor a)"
    by (rule size_mult_mono) simp
  moreover have "euclidean_size a \<le> euclidean_size (a * (1 div unit_factor a))"
    by (rule size_mult_mono) simp
  ultimately show ?thesis
    by simp
qed

lemma dvd_euclidean_size_eq_imp_dvd:
  assumes "a \<noteq> 0" and "euclidean_size a = euclidean_size b"
    and "b dvd a" 
  shows "a dvd b"
proof (rule ccontr)
  assume "\<not> a dvd b"
  hence "b mod a \<noteq> 0" using mod_0_imp_dvd [of b a] by blast
  then have "b mod a \<noteq> 0" by (simp add: mod_eq_0_iff_dvd)
  from \<open>b dvd a\<close> have "b dvd b mod a" by (simp add: dvd_mod_iff)
  then obtain c where "b mod a = b * c" unfolding dvd_def by blast
    with \<open>b mod a \<noteq> 0\<close> have "c \<noteq> 0" by auto
  with \<open>b mod a = b * c\<close> have "euclidean_size (b mod a) \<ge> euclidean_size b"
    using size_mult_mono by force
  moreover from \<open>\<not> a dvd b\<close> and \<open>a \<noteq> 0\<close>
  have "euclidean_size (b mod a) < euclidean_size a"
    using mod_size_less by blast
  ultimately show False using \<open>euclidean_size a = euclidean_size b\<close>
    by simp
qed

lemma euclidean_size_times_unit:
  assumes "is_unit a"
  shows   "euclidean_size (a * b) = euclidean_size b"
proof (rule antisym)
  from assms have [simp]: "a \<noteq> 0" by auto
  thus "euclidean_size (a * b) \<ge> euclidean_size b" by (rule size_mult_mono')
  from assms have "is_unit (1 div a)" by simp
  hence "1 div a \<noteq> 0" by (intro notI) simp_all
  hence "euclidean_size (a * b) \<le> euclidean_size ((1 div a) * (a * b))"
    by (rule size_mult_mono')
  also from assms have "(1 div a) * (a * b) = b"
    by (simp add: algebra_simps unit_div_mult_swap)
  finally show "euclidean_size (a * b) \<le> euclidean_size b" .
qed

lemma euclidean_size_unit:
  "is_unit a \<Longrightarrow> euclidean_size a = euclidean_size 1"
  using euclidean_size_times_unit [of a 1] by simp

lemma unit_iff_euclidean_size: 
  "is_unit a \<longleftrightarrow> euclidean_size a = euclidean_size 1 \<and> a \<noteq> 0"
proof safe
  assume A: "a \<noteq> 0" and B: "euclidean_size a = euclidean_size 1"
  show "is_unit a"
    by (rule dvd_euclidean_size_eq_imp_dvd [OF A B]) simp_all
qed (auto intro: euclidean_size_unit)

lemma euclidean_size_times_nonunit:
  assumes "a \<noteq> 0" "b \<noteq> 0" "\<not> is_unit a"
  shows   "euclidean_size b < euclidean_size (a * b)"
proof (rule ccontr)
  assume "\<not>euclidean_size b < euclidean_size (a * b)"
  with size_mult_mono'[OF assms(1), of b] 
    have eq: "euclidean_size (a * b) = euclidean_size b" by simp
  have "a * b dvd b"
    by (rule dvd_euclidean_size_eq_imp_dvd [OF _ eq]) (insert assms, simp_all)
  hence "a * b dvd 1 * b" by simp
  with \<open>b \<noteq> 0\<close> have "is_unit a" by (subst (asm) dvd_times_right_cancel_iff)
  with assms(3) show False by contradiction
qed

lemma dvd_imp_size_le:
  assumes "a dvd b" "b \<noteq> 0" 
  shows   "euclidean_size a \<le> euclidean_size b"
  using assms by (auto elim!: dvdE simp: size_mult_mono)

lemma dvd_proper_imp_size_less:
  assumes "a dvd b" "\<not> b dvd a" "b \<noteq> 0" 
  shows   "euclidean_size a < euclidean_size b"
proof -
  from assms(1) obtain c where "b = a * c" by (erule dvdE)
  hence z: "b = c * a" by (simp add: mult.commute)
  from z assms have "\<not>is_unit c" by (auto simp: mult.commute mult_unit_dvd_iff)
  with z assms show ?thesis
    by (auto intro!: euclidean_size_times_nonunit)
qed

end

class euclidean_ring = idom_modulo + euclidean_semiring

  
subsection \<open>Euclidean (semi)rings with cancel rules\<close>

class euclidean_semiring_cancel = euclidean_semiring + semiring_div

class euclidean_ring_cancel = euclidean_ring + ring_div
  
  
subsection \<open>Uniquely determined division\<close>
  
class unique_euclidean_semiring = euclidean_semiring + 
  fixes uniqueness_constraint :: "'a \<Rightarrow> 'a \<Rightarrow> bool"
  assumes size_mono_mult:
    "b \<noteq> 0 \<Longrightarrow> euclidean_size a < euclidean_size c
      \<Longrightarrow> euclidean_size (a * b) < euclidean_size (c * b)"
    -- \<open>FIXME justify\<close>
  assumes uniqueness_constraint_mono_mult:
    "uniqueness_constraint a b \<Longrightarrow> uniqueness_constraint (a * c) (b * c)"
  assumes uniqueness_constraint_mod:
    "b \<noteq> 0 \<Longrightarrow> \<not> b dvd a \<Longrightarrow> uniqueness_constraint (a mod b) b"
  assumes div_bounded:
    "b \<noteq> 0 \<Longrightarrow> uniqueness_constraint r b
    \<Longrightarrow> euclidean_size r < euclidean_size b
    \<Longrightarrow> (q * b + r) div b = q"
begin

lemma divmod_cases [case_names divides remainder by0]:
  obtains 
    (divides) q where "b \<noteq> 0"
      and "a div b = q"
      and "a mod b = 0"
      and "a = q * b"
  | (remainder) q r where "b \<noteq> 0" and "r \<noteq> 0"
      and "uniqueness_constraint r b"
      and "euclidean_size r < euclidean_size b"
      and "a div b = q"
      and "a mod b = r"
      and "a = q * b + r"
  | (by0) "b = 0"
proof (cases "b = 0")
  case True
  then show thesis
  by (rule by0)
next
  case False
  show thesis
  proof (cases "b dvd a")
    case True
    then obtain q where "a = b * q" ..
    with \<open>b \<noteq> 0\<close> divides
    show thesis
      by (simp add: ac_simps)
  next
    case False
    then have "a mod b \<noteq> 0"
      by (simp add: mod_eq_0_iff_dvd)
    moreover from \<open>b \<noteq> 0\<close> \<open>\<not> b dvd a\<close> have "uniqueness_constraint (a mod b) b"
      by (rule uniqueness_constraint_mod)
    moreover have "euclidean_size (a mod b) < euclidean_size b"
      using \<open>b \<noteq> 0\<close> by (rule mod_size_less)
    moreover have "a = a div b * b + a mod b"
      by (simp add: div_mult_mod_eq)
    ultimately show thesis
      using \<open>b \<noteq> 0\<close> by (blast intro: remainder)
  qed
qed

lemma div_eqI:
  "a div b = q" if "b \<noteq> 0" "uniqueness_constraint r b"
    "euclidean_size r < euclidean_size b" "q * b + r = a"
proof -
  from that have "(q * b + r) div b = q"
    by (auto intro: div_bounded)
  with that show ?thesis
    by simp
qed

lemma mod_eqI:
  "a mod b = r" if "b \<noteq> 0" "uniqueness_constraint r b"
    "euclidean_size r < euclidean_size b" "q * b + r = a" 
proof -
  from that have "a div b = q"
    by (rule div_eqI)
  moreover have "a div b * b + a mod b = a"
    by (fact div_mult_mod_eq)
  ultimately have "a div b * b + a mod b = a div b * b + r"
    using \<open>q * b + r = a\<close> by simp
  then show ?thesis
    by simp
qed

subclass euclidean_semiring_cancel
proof
  show "(a + c * b) div b = c + a div b" if "b \<noteq> 0" for a b c
  proof (cases a b rule: divmod_cases)
    case by0
    with \<open>b \<noteq> 0\<close> show ?thesis
      by simp
  next
    case (divides q)
    then show ?thesis
      by (simp add: ac_simps)
  next
    case (remainder q r)
    then show ?thesis
      by (auto intro: div_eqI simp add: algebra_simps)
  qed
next
  show"(c * a) div (c * b) = a div b" if "c \<noteq> 0" for a b c
  proof (cases a b rule: divmod_cases)
    case by0
    then show ?thesis
      by simp
  next
    case (divides q)
    with \<open>c \<noteq> 0\<close> show ?thesis
      by (simp add: mult.left_commute [of c])
  next
    case (remainder q r)
    from \<open>b \<noteq> 0\<close> \<open>c \<noteq> 0\<close> have "b * c \<noteq> 0"
      by simp
    from remainder \<open>c \<noteq> 0\<close>
    have "uniqueness_constraint (r * c) (b * c)"
      and "euclidean_size (r * c) < euclidean_size (b * c)"
      by (simp_all add: uniqueness_constraint_mono_mult uniqueness_constraint_mod size_mono_mult)
    with remainder show ?thesis
      by (auto intro!: div_eqI [of _ "c * (a mod b)"] simp add: algebra_simps)
        (use \<open>b * c \<noteq> 0\<close> in simp)
  qed
qed
  
end

class unique_euclidean_ring = euclidean_ring + unique_euclidean_semiring
begin

subclass euclidean_ring_cancel ..

end

subsection \<open>Typical instances\<close>

instantiation nat :: unique_euclidean_semiring
begin

definition [simp]:
  "euclidean_size_nat = (id :: nat \<Rightarrow> nat)"

definition [simp]:
  "uniqueness_constraint_nat = (top :: nat \<Rightarrow> nat \<Rightarrow> bool)"

instance
  by standard
    (simp_all add: unit_factor_nat_def mod_greater_zero_iff_not_dvd)

end

instantiation int :: unique_euclidean_ring
begin

definition [simp]:
  "euclidean_size_int = (nat \<circ> abs :: int \<Rightarrow> nat)"

definition [simp]:
  "uniqueness_constraint_int (k :: int) l \<longleftrightarrow> unit_factor k = unit_factor l"
  
instance
  by standard
    (auto simp add: abs_mult nat_mult_distrib sgn_mod zdiv_eq_0_iff sgn_1_pos sgn_mult split: abs_split)

end

end

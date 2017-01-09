(*  Title:      HOL/Library/Polynomial_Factorial.thy
    Author:     Brian Huffman
    Author:     Clemens Ballarin
    Author:     Amine Chaieb
    Author:     Florian Haftmann
    Author:     Manuel Eberl
*)

theory Polynomial_Factorial
imports 
  Complex_Main
  "~~/src/HOL/Library/Polynomial"
  "~~/src/HOL/Library/Normalized_Fraction"
  "~~/src/HOL/Library/Field_as_Ring"
begin

subsection \<open>Various facts about polynomials\<close>

lemma prod_mset_const_poly: "prod_mset (image_mset (\<lambda>x. [:f x:]) A) = [:prod_mset (image_mset f A):]"
  by (induction A) (simp_all add: one_poly_def mult_ac)

lemma irreducible_const_poly_iff:
  fixes c :: "'a :: {comm_semiring_1,semiring_no_zero_divisors}"
  shows "irreducible [:c:] \<longleftrightarrow> irreducible c"
proof
  assume A: "irreducible c"
  show "irreducible [:c:]"
  proof (rule irreducibleI)
    fix a b assume ab: "[:c:] = a * b"
    hence "degree [:c:] = degree (a * b)" by (simp only: )
    also from A ab have "a \<noteq> 0" "b \<noteq> 0" by auto
    hence "degree (a * b) = degree a + degree b" by (simp add: degree_mult_eq)
    finally have "degree a = 0" "degree b = 0" by auto
    then obtain a' b' where ab': "a = [:a':]" "b = [:b':]" by (auto elim!: degree_eq_zeroE)
    from ab have "coeff [:c:] 0 = coeff (a * b) 0" by (simp only: )
    hence "c = a' * b'" by (simp add: ab' mult_ac)
    from A and this have "a' dvd 1 \<or> b' dvd 1" by (rule irreducibleD)
    with ab' show "a dvd 1 \<or> b dvd 1" by (auto simp: one_poly_def)
  qed (insert A, auto simp: irreducible_def is_unit_poly_iff)
next
  assume A: "irreducible [:c:]"
  show "irreducible c"
  proof (rule irreducibleI)
    fix a b assume ab: "c = a * b"
    hence "[:c:] = [:a:] * [:b:]" by (simp add: mult_ac)
    from A and this have "[:a:] dvd 1 \<or> [:b:] dvd 1" by (rule irreducibleD)
    thus "a dvd 1 \<or> b dvd 1" by (simp add: one_poly_def)
  qed (insert A, auto simp: irreducible_def one_poly_def)
qed


subsection \<open>Lifting elements into the field of fractions\<close>

definition to_fract :: "'a :: idom \<Rightarrow> 'a fract" where "to_fract x = Fract x 1"
  -- \<open>FIXME: name \<open>of_idom\<close>, abbreviation\<close>

lemma to_fract_0 [simp]: "to_fract 0 = 0"
  by (simp add: to_fract_def eq_fract Zero_fract_def)

lemma to_fract_1 [simp]: "to_fract 1 = 1"
  by (simp add: to_fract_def eq_fract One_fract_def)

lemma to_fract_add [simp]: "to_fract (x + y) = to_fract x + to_fract y"
  by (simp add: to_fract_def)

lemma to_fract_diff [simp]: "to_fract (x - y) = to_fract x - to_fract y"
  by (simp add: to_fract_def)
  
lemma to_fract_uminus [simp]: "to_fract (-x) = -to_fract x"
  by (simp add: to_fract_def)
  
lemma to_fract_mult [simp]: "to_fract (x * y) = to_fract x * to_fract y"
  by (simp add: to_fract_def)

lemma to_fract_eq_iff [simp]: "to_fract x = to_fract y \<longleftrightarrow> x = y"
  by (simp add: to_fract_def eq_fract)
  
lemma to_fract_eq_0_iff [simp]: "to_fract x = 0 \<longleftrightarrow> x = 0"
  by (simp add: to_fract_def Zero_fract_def eq_fract)

lemma snd_quot_of_fract_nonzero [simp]: "snd (quot_of_fract x) \<noteq> 0"
  by transfer simp

lemma Fract_quot_of_fract [simp]: "Fract (fst (quot_of_fract x)) (snd (quot_of_fract x)) = x"
  by transfer (simp del: fractrel_iff, subst fractrel_normalize_quot_left, simp)

lemma to_fract_quot_of_fract:
  assumes "snd (quot_of_fract x) = 1"
  shows   "to_fract (fst (quot_of_fract x)) = x"
proof -
  have "x = Fract (fst (quot_of_fract x)) (snd (quot_of_fract x))" by simp
  also note assms
  finally show ?thesis by (simp add: to_fract_def)
qed

lemma snd_quot_of_fract_Fract_whole:
  assumes "y dvd x"
  shows   "snd (quot_of_fract (Fract x y)) = 1"
  using assms by transfer (auto simp: normalize_quot_def Let_def gcd_proj2_if_dvd)
  
lemma Fract_conv_to_fract: "Fract a b = to_fract a / to_fract b"
  by (simp add: to_fract_def)

lemma quot_of_fract_to_fract [simp]: "quot_of_fract (to_fract x) = (x, 1)"
  unfolding to_fract_def by transfer (simp add: normalize_quot_def)

lemma fst_quot_of_fract_eq_0_iff [simp]: "fst (quot_of_fract x) = 0 \<longleftrightarrow> x = 0"
  by transfer simp
 
lemma snd_quot_of_fract_to_fract [simp]: "snd (quot_of_fract (to_fract x)) = 1"
  unfolding to_fract_def by (rule snd_quot_of_fract_Fract_whole) simp_all

lemma coprime_quot_of_fract:
  "coprime (fst (quot_of_fract x)) (snd (quot_of_fract x))"
  by transfer (simp add: coprime_normalize_quot)

lemma unit_factor_snd_quot_of_fract: "unit_factor (snd (quot_of_fract x)) = 1"
  using quot_of_fract_in_normalized_fracts[of x] 
  by (simp add: normalized_fracts_def case_prod_unfold)  

lemma unit_factor_1_imp_normalized: "unit_factor x = 1 \<Longrightarrow> normalize x = x"
  by (subst (2) normalize_mult_unit_factor [symmetric, of x])
     (simp del: normalize_mult_unit_factor)
  
lemma normalize_snd_quot_of_fract: "normalize (snd (quot_of_fract x)) = snd (quot_of_fract x)"
  by (intro unit_factor_1_imp_normalized unit_factor_snd_quot_of_fract)


subsection \<open>Lifting polynomial coefficients to the field of fractions\<close>

abbreviation (input) fract_poly 
  where "fract_poly \<equiv> map_poly to_fract"

abbreviation (input) unfract_poly 
  where "unfract_poly \<equiv> map_poly (fst \<circ> quot_of_fract)"
  
lemma fract_poly_smult [simp]: "fract_poly (smult c p) = smult (to_fract c) (fract_poly p)"
  by (simp add: smult_conv_map_poly map_poly_map_poly o_def)

lemma fract_poly_0 [simp]: "fract_poly 0 = 0"
  by (simp add: poly_eqI coeff_map_poly)

lemma fract_poly_1 [simp]: "fract_poly 1 = 1"
  by (simp add: one_poly_def map_poly_pCons)

lemma fract_poly_add [simp]:
  "fract_poly (p + q) = fract_poly p + fract_poly q"
  by (intro poly_eqI) (simp_all add: coeff_map_poly)

lemma fract_poly_diff [simp]:
  "fract_poly (p - q) = fract_poly p - fract_poly q"
  by (intro poly_eqI) (simp_all add: coeff_map_poly)

lemma to_fract_sum [simp]: "to_fract (sum f A) = sum (\<lambda>x. to_fract (f x)) A"
  by (cases "finite A", induction A rule: finite_induct) simp_all 

lemma fract_poly_mult [simp]:
  "fract_poly (p * q) = fract_poly p * fract_poly q"
  by (intro poly_eqI) (simp_all add: coeff_map_poly coeff_mult)

lemma fract_poly_eq_iff [simp]: "fract_poly p = fract_poly q \<longleftrightarrow> p = q"
  by (auto simp: poly_eq_iff coeff_map_poly)

lemma fract_poly_eq_0_iff [simp]: "fract_poly p = 0 \<longleftrightarrow> p = 0"
  using fract_poly_eq_iff[of p 0] by (simp del: fract_poly_eq_iff)

lemma fract_poly_dvd: "p dvd q \<Longrightarrow> fract_poly p dvd fract_poly q"
  by (auto elim!: dvdE)

lemma prod_mset_fract_poly: 
  "prod_mset (image_mset (\<lambda>x. fract_poly (f x)) A) = fract_poly (prod_mset (image_mset f A))"
  by (induction A) (simp_all add: mult_ac)
  
lemma is_unit_fract_poly_iff:
  "p dvd 1 \<longleftrightarrow> fract_poly p dvd 1 \<and> content p = 1"
proof safe
  assume A: "p dvd 1"
  with fract_poly_dvd[of p 1] show "is_unit (fract_poly p)" by simp
  from A show "content p = 1"
    by (auto simp: is_unit_poly_iff normalize_1_iff)
next
  assume A: "fract_poly p dvd 1" and B: "content p = 1"
  from A obtain c where c: "fract_poly p = [:c:]" by (auto simp: is_unit_poly_iff)
  {
    fix n :: nat assume "n > 0"
    have "to_fract (coeff p n) = coeff (fract_poly p) n" by (simp add: coeff_map_poly)
    also note c
    also from \<open>n > 0\<close> have "coeff [:c:] n = 0" by (simp add: coeff_pCons split: nat.splits)
    finally have "coeff p n = 0" by simp
  }
  hence "degree p \<le> 0" by (intro degree_le) simp_all
  with B show "p dvd 1" by (auto simp: is_unit_poly_iff normalize_1_iff elim!: degree_eq_zeroE)
qed
  
lemma fract_poly_is_unit: "p dvd 1 \<Longrightarrow> fract_poly p dvd 1"
  using fract_poly_dvd[of p 1] by simp

lemma fract_poly_smult_eqE:
  fixes c :: "'a :: {idom_divide,ring_gcd} fract"
  assumes "fract_poly p = smult c (fract_poly q)"
  obtains a b 
    where "c = to_fract b / to_fract a" "smult a p = smult b q" "coprime a b" "normalize a = a"
proof -
  define a b where "a = fst (quot_of_fract c)" and "b = snd (quot_of_fract c)"
  have "smult (to_fract a) (fract_poly q) = smult (to_fract b) (fract_poly p)"
    by (subst smult_eq_iff) (simp_all add: a_def b_def Fract_conv_to_fract [symmetric] assms)
  hence "fract_poly (smult a q) = fract_poly (smult b p)" by (simp del: fract_poly_eq_iff)
  hence "smult b p = smult a q" by (simp only: fract_poly_eq_iff)
  moreover have "c = to_fract a / to_fract b" "coprime b a" "normalize b = b"
    by (simp_all add: a_def b_def coprime_quot_of_fract gcd.commute
          normalize_snd_quot_of_fract Fract_conv_to_fract [symmetric])
  ultimately show ?thesis by (intro that[of a b])
qed


subsection \<open>Fractional content\<close>

abbreviation (input) Lcm_coeff_denoms 
    :: "'a :: {semiring_Gcd,idom_divide,ring_gcd} fract poly \<Rightarrow> 'a"
  where "Lcm_coeff_denoms p \<equiv> Lcm (snd ` quot_of_fract ` set (coeffs p))"
  
definition fract_content :: 
      "'a :: {factorial_semiring,semiring_Gcd,ring_gcd,idom_divide} fract poly \<Rightarrow> 'a fract" where
  "fract_content p = 
     (let d = Lcm_coeff_denoms p in Fract (content (unfract_poly (smult (to_fract d) p))) d)" 

definition primitive_part_fract :: 
      "'a :: {factorial_semiring,semiring_Gcd,ring_gcd,idom_divide} fract poly \<Rightarrow> 'a poly" where
  "primitive_part_fract p = 
     primitive_part (unfract_poly (smult (to_fract (Lcm_coeff_denoms p)) p))"

lemma primitive_part_fract_0 [simp]: "primitive_part_fract 0 = 0"
  by (simp add: primitive_part_fract_def)

lemma fract_content_eq_0_iff [simp]:
  "fract_content p = 0 \<longleftrightarrow> p = 0"
  unfolding fract_content_def Let_def Zero_fract_def
  by (subst eq_fract) (auto simp: Lcm_0_iff map_poly_eq_0_iff)

lemma content_primitive_part_fract [simp]: "p \<noteq> 0 \<Longrightarrow> content (primitive_part_fract p) = 1"
  unfolding primitive_part_fract_def
  by (rule content_primitive_part)
     (auto simp: primitive_part_fract_def map_poly_eq_0_iff Lcm_0_iff)  

lemma content_times_primitive_part_fract:
  "smult (fract_content p) (fract_poly (primitive_part_fract p)) = p"
proof -
  define p' where "p' = unfract_poly (smult (to_fract (Lcm_coeff_denoms p)) p)"
  have "fract_poly p' = 
          map_poly (to_fract \<circ> fst \<circ> quot_of_fract) (smult (to_fract (Lcm_coeff_denoms p)) p)"
    unfolding primitive_part_fract_def p'_def 
    by (subst map_poly_map_poly) (simp_all add: o_assoc)
  also have "\<dots> = smult (to_fract (Lcm_coeff_denoms p)) p"
  proof (intro map_poly_idI, unfold o_apply)
    fix c assume "c \<in> set (coeffs (smult (to_fract (Lcm_coeff_denoms p)) p))"
    then obtain c' where c: "c' \<in> set (coeffs p)" "c = to_fract (Lcm_coeff_denoms p) * c'"
      by (auto simp add: Lcm_0_iff coeffs_smult split: if_splits)
    note c(2)
    also have "c' = Fract (fst (quot_of_fract c')) (snd (quot_of_fract c'))"
      by simp
    also have "to_fract (Lcm_coeff_denoms p) * \<dots> = 
                 Fract (Lcm_coeff_denoms p * fst (quot_of_fract c')) (snd (quot_of_fract c'))"
      unfolding to_fract_def by (subst mult_fract) simp_all
    also have "snd (quot_of_fract \<dots>) = 1"
      by (intro snd_quot_of_fract_Fract_whole dvd_mult2 dvd_Lcm) (insert c(1), auto)
    finally show "to_fract (fst (quot_of_fract c)) = c"
      by (rule to_fract_quot_of_fract)
  qed
  also have "p' = smult (content p') (primitive_part p')" 
    by (rule content_times_primitive_part [symmetric])
  also have "primitive_part p' = primitive_part_fract p"
    by (simp add: primitive_part_fract_def p'_def)
  also have "fract_poly (smult (content p') (primitive_part_fract p)) = 
               smult (to_fract (content p')) (fract_poly (primitive_part_fract p))" by simp
  finally have "smult (to_fract (content p')) (fract_poly (primitive_part_fract p)) =
                      smult (to_fract (Lcm_coeff_denoms p)) p" .
  thus ?thesis
    by (subst (asm) smult_eq_iff)
       (auto simp add: Let_def p'_def Fract_conv_to_fract field_simps Lcm_0_iff fract_content_def)
qed

lemma fract_content_fract_poly [simp]: "fract_content (fract_poly p) = to_fract (content p)"
proof -
  have "Lcm_coeff_denoms (fract_poly p) = 1"
    by (auto simp: set_coeffs_map_poly)
  hence "fract_content (fract_poly p) = 
           to_fract (content (map_poly (fst \<circ> quot_of_fract \<circ> to_fract) p))"
    by (simp add: fract_content_def to_fract_def fract_collapse map_poly_map_poly del: Lcm_1_iff)
  also have "map_poly (fst \<circ> quot_of_fract \<circ> to_fract) p = p"
    by (intro map_poly_idI) simp_all
  finally show ?thesis .
qed

lemma content_decompose_fract:
  fixes p :: "'a :: {factorial_semiring,semiring_Gcd,ring_gcd,idom_divide} fract poly"
  obtains c p' where "p = smult c (map_poly to_fract p')" "content p' = 1"
proof (cases "p = 0")
  case True
  hence "p = smult 0 (map_poly to_fract 1)" "content 1 = 1" by simp_all
  thus ?thesis ..
next
  case False
  thus ?thesis
    by (rule that[OF content_times_primitive_part_fract [symmetric] content_primitive_part_fract])
qed


subsection \<open>More properties of content and primitive part\<close>

lemma lift_prime_elem_poly:
  assumes "prime_elem (c :: 'a :: semidom)"
  shows   "prime_elem [:c:]"
proof (rule prime_elemI)
  fix a b assume *: "[:c:] dvd a * b"
  from * have dvd: "c dvd coeff (a * b) n" for n
    by (subst (asm) const_poly_dvd_iff) blast
  {
    define m where "m = (GREATEST m. \<not>c dvd coeff b m)"
    assume "\<not>[:c:] dvd b"
    hence A: "\<exists>i. \<not>c dvd coeff b i" by (subst (asm) const_poly_dvd_iff) blast
    have B: "\<forall>i. \<not>c dvd coeff b i \<longrightarrow> i < Suc (degree b)"
      by (auto intro: le_degree simp: less_Suc_eq_le)
    have coeff_m: "\<not>c dvd coeff b m" unfolding m_def by (rule GreatestI_ex[OF A B])
    have "i \<le> m" if "\<not>c dvd coeff b i" for i
      unfolding m_def by (rule Greatest_le[OF that B])
    hence dvd_b: "c dvd coeff b i" if "i > m" for i using that by force

    have "c dvd coeff a i" for i
    proof (induction i rule: nat_descend_induct[of "degree a"])
      case (base i)
      thus ?case by (simp add: coeff_eq_0)
    next
      case (descend i)
      let ?A = "{..i+m} - {i}"
      have "c dvd coeff (a * b) (i + m)" by (rule dvd)
      also have "coeff (a * b) (i + m) = (\<Sum>k\<le>i + m. coeff a k * coeff b (i + m - k))"
        by (simp add: coeff_mult)
      also have "{..i+m} = insert i ?A" by auto
      also have "(\<Sum>k\<in>\<dots>. coeff a k * coeff b (i + m - k)) =
                   coeff a i * coeff b m + (\<Sum>k\<in>?A. coeff a k * coeff b (i + m - k))"
        (is "_ = _ + ?S")
        by (subst sum.insert) simp_all
      finally have eq: "c dvd coeff a i * coeff b m + ?S" .
      moreover have "c dvd ?S"
      proof (rule dvd_sum)
        fix k assume k: "k \<in> {..i+m} - {i}"
        show "c dvd coeff a k * coeff b (i + m - k)"
        proof (cases "k < i")
          case False
          with k have "c dvd coeff a k" by (intro descend.IH) simp
          thus ?thesis by simp
        next
          case True
          hence "c dvd coeff b (i + m - k)" by (intro dvd_b) simp
          thus ?thesis by simp
        qed
      qed
      ultimately have "c dvd coeff a i * coeff b m"
        by (simp add: dvd_add_left_iff)
      with assms coeff_m show "c dvd coeff a i"
        by (simp add: prime_elem_dvd_mult_iff)
    qed
    hence "[:c:] dvd a" by (subst const_poly_dvd_iff) blast
  }
  thus "[:c:] dvd a \<or> [:c:] dvd b" by blast
qed (insert assms, simp_all add: prime_elem_def one_poly_def)

lemma prime_elem_const_poly_iff:
  fixes c :: "'a :: semidom"
  shows   "prime_elem [:c:] \<longleftrightarrow> prime_elem c"
proof
  assume A: "prime_elem [:c:]"
  show "prime_elem c"
  proof (rule prime_elemI)
    fix a b assume "c dvd a * b"
    hence "[:c:] dvd [:a:] * [:b:]" by (simp add: mult_ac)
    from A and this have "[:c:] dvd [:a:] \<or> [:c:] dvd [:b:]" by (rule prime_elem_dvd_multD)
    thus "c dvd a \<or> c dvd b" by simp
  qed (insert A, auto simp: prime_elem_def is_unit_poly_iff)
qed (auto intro: lift_prime_elem_poly)

context
begin

private lemma content_1_mult:
  fixes f g :: "'a :: {semiring_Gcd,factorial_semiring} poly"
  assumes "content f = 1" "content g = 1"
  shows   "content (f * g) = 1"
proof (cases "f * g = 0")
  case False
  from assms have "f \<noteq> 0" "g \<noteq> 0" by auto

  hence "f * g \<noteq> 0" by auto
  {
    assume "\<not>is_unit (content (f * g))"
    with False have "\<exists>p. p dvd content (f * g) \<and> prime p"
      by (intro prime_divisor_exists) simp_all
    then obtain p where "p dvd content (f * g)" "prime p" by blast
    from \<open>p dvd content (f * g)\<close> have "[:p:] dvd f * g"
      by (simp add: const_poly_dvd_iff_dvd_content)
    moreover from \<open>prime p\<close> have "prime_elem [:p:]" by (simp add: lift_prime_elem_poly)
    ultimately have "[:p:] dvd f \<or> [:p:] dvd g"
      by (simp add: prime_elem_dvd_mult_iff)
    with assms have "is_unit p" by (simp add: const_poly_dvd_iff_dvd_content)
    with \<open>prime p\<close> have False by simp
  }
  hence "is_unit (content (f * g))" by blast
  hence "normalize (content (f * g)) = 1" by (simp add: is_unit_normalize del: normalize_content)
  thus ?thesis by simp
qed (insert assms, auto)

lemma content_mult:
  fixes p q :: "'a :: {factorial_semiring, semiring_Gcd} poly"
  shows "content (p * q) = content p * content q"
proof -
  from content_decompose[of p] guess p' . note p = this
  from content_decompose[of q] guess q' . note q = this
  have "content (p * q) = content p * content q * content (p' * q')"
    by (subst p, subst q) (simp add: mult_ac normalize_mult)
  also from p q have "content (p' * q') = 1" by (intro content_1_mult)
  finally show ?thesis by simp
qed

lemma primitive_part_mult:
  fixes p q :: "'a :: {factorial_semiring, semiring_Gcd, ring_gcd, idom_divide} poly"
  shows "primitive_part (p * q) = primitive_part p * primitive_part q"
proof -
  have "primitive_part (p * q) = p * q div [:content (p * q):]"
    by (simp add: primitive_part_def div_const_poly_conv_map_poly)
  also have "\<dots> = (p div [:content p:]) * (q div [:content q:])"
    by (subst div_mult_div_if_dvd) (simp_all add: content_mult mult_ac)
  also have "\<dots> = primitive_part p * primitive_part q"
    by (simp add: primitive_part_def div_const_poly_conv_map_poly)
  finally show ?thesis .
qed

lemma primitive_part_smult:
  fixes p :: "'a :: {factorial_semiring, semiring_Gcd, ring_gcd, idom_divide} poly"
  shows "primitive_part (smult a p) = smult (unit_factor a) (primitive_part p)"
proof -
  have "smult a p = [:a:] * p" by simp
  also have "primitive_part \<dots> = smult (unit_factor a) (primitive_part p)"
    by (subst primitive_part_mult) simp_all
  finally show ?thesis .
qed  

lemma primitive_part_dvd_primitive_partI [intro]:
  fixes p q :: "'a :: {factorial_semiring, semiring_Gcd, ring_gcd, idom_divide} poly"
  shows "p dvd q \<Longrightarrow> primitive_part p dvd primitive_part q"
  by (auto elim!: dvdE simp: primitive_part_mult)

lemma content_prod_mset: 
  fixes A :: "'a :: {factorial_semiring, semiring_Gcd} poly multiset"
  shows "content (prod_mset A) = prod_mset (image_mset content A)"
  by (induction A) (simp_all add: content_mult mult_ac)

lemma fract_poly_dvdD:
  fixes p :: "'a :: {factorial_semiring,semiring_Gcd,ring_gcd,idom_divide} poly"
  assumes "fract_poly p dvd fract_poly q" "content p = 1"
  shows   "p dvd q"
proof -
  from assms(1) obtain r where r: "fract_poly q = fract_poly p * r" by (erule dvdE)
  from content_decompose_fract[of r] guess c r' . note r' = this
  from r r' have eq: "fract_poly q = smult c (fract_poly (p * r'))" by simp  
  from fract_poly_smult_eqE[OF this] guess a b . note ab = this
  have "content (smult a q) = content (smult b (p * r'))" by (simp only: ab(2))
  hence eq': "normalize b = a * content q" by (simp add: assms content_mult r' ab(4))
  have "1 = gcd a (normalize b)" by (simp add: ab)
  also note eq'
  also have "gcd a (a * content q) = a" by (simp add: gcd_proj1_if_dvd ab(4))
  finally have [simp]: "a = 1" by simp
  from eq ab have "q = p * ([:b:] * r')" by simp
  thus ?thesis by (rule dvdI)
qed

lemma content_prod_eq_1_iff: 
  fixes p q :: "'a :: {factorial_semiring, semiring_Gcd} poly"
  shows "content (p * q) = 1 \<longleftrightarrow> content p = 1 \<and> content q = 1"
proof safe
  assume A: "content (p * q) = 1"
  {
    fix p q :: "'a poly" assume "content p * content q = 1"
    hence "1 = content p * content q" by simp
    hence "content p dvd 1" by (rule dvdI)
    hence "content p = 1" by simp
  } note B = this
  from A B[of p q] B [of q p] show "content p = 1" "content q = 1" 
    by (simp_all add: content_mult mult_ac)
qed (auto simp: content_mult)

end


subsection \<open>Polynomials over a field are a Euclidean ring\<close>

definition unit_factor_field_poly :: "'a :: field poly \<Rightarrow> 'a poly" where
  "unit_factor_field_poly p = [:lead_coeff p:]"

definition normalize_field_poly :: "'a :: field poly \<Rightarrow> 'a poly" where
  "normalize_field_poly p = smult (inverse (lead_coeff p)) p"

definition euclidean_size_field_poly :: "'a :: field poly \<Rightarrow> nat" where
  "euclidean_size_field_poly p = (if p = 0 then 0 else 2 ^ degree p)" 

lemma dvd_field_poly: "dvd.dvd (op * :: 'a :: field poly \<Rightarrow> _) = op dvd"
  by (intro ext) (simp_all add: dvd.dvd_def dvd_def)

interpretation field_poly: 
  unique_euclidean_ring where zero = "0 :: 'a :: field poly"
    and one = 1 and plus = plus and uminus = uminus and minus = minus
    and times = times
    and normalize = normalize_field_poly and unit_factor = unit_factor_field_poly
    and euclidean_size = euclidean_size_field_poly
    and uniqueness_constraint = top
    and divide = divide and modulo = modulo
proof (standard, unfold dvd_field_poly)
  fix p :: "'a poly"
  show "unit_factor_field_poly p * normalize_field_poly p = p"
    by (cases "p = 0") 
       (simp_all add: unit_factor_field_poly_def normalize_field_poly_def)
next
  fix p :: "'a poly" assume "is_unit p"
  then show "unit_factor_field_poly p = p"
    by (elim is_unit_polyE) (auto simp: unit_factor_field_poly_def monom_0 one_poly_def field_simps)
next
  fix p :: "'a poly" assume "p \<noteq> 0"
  thus "is_unit (unit_factor_field_poly p)"
    by (simp add: unit_factor_field_poly_def is_unit_pCons_iff)
next
  fix p q s :: "'a poly" assume "s \<noteq> 0"
  moreover assume "euclidean_size_field_poly p < euclidean_size_field_poly q"
  ultimately show "euclidean_size_field_poly (p * s) < euclidean_size_field_poly (q * s)"
    by (auto simp add: euclidean_size_field_poly_def degree_mult_eq)
next
  fix p q r :: "'a poly" assume "p \<noteq> 0"
  moreover assume "euclidean_size_field_poly r < euclidean_size_field_poly p"
  ultimately show "(q * p + r) div p = q"
    by (cases "r = 0")
      (auto simp add: unit_factor_field_poly_def euclidean_size_field_poly_def div_poly_less)
qed (auto simp: unit_factor_field_poly_def normalize_field_poly_def lead_coeff_mult 
       euclidean_size_field_poly_def Rings.div_mult_mod_eq intro!: degree_mod_less' degree_mult_right_le)

lemma field_poly_irreducible_imp_prime:
  assumes "irreducible (p :: 'a :: field poly)"
  shows   "prime_elem p"
proof -
  have A: "class.comm_semiring_1 op * 1 op + (0 :: 'a poly)" ..
  from field_poly.irreducible_imp_prime_elem[of p] assms
    show ?thesis unfolding irreducible_def prime_elem_def dvd_field_poly
      comm_semiring_1.irreducible_def[OF A] comm_semiring_1.prime_elem_def[OF A] by blast
qed

lemma field_poly_prod_mset_prime_factorization:
  assumes "(x :: 'a :: field poly) \<noteq> 0"
  shows   "prod_mset (field_poly.prime_factorization x) = normalize_field_poly x"
proof -
  have A: "class.comm_monoid_mult op * (1 :: 'a poly)" ..
  have "comm_monoid_mult.prod_mset op * (1 :: 'a poly) = prod_mset"
    by (intro ext) (simp add: comm_monoid_mult.prod_mset_def[OF A] prod_mset_def)
  with field_poly.prod_mset_prime_factorization[OF assms] show ?thesis by simp
qed

lemma field_poly_in_prime_factorization_imp_prime:
  assumes "(p :: 'a :: field poly) \<in># field_poly.prime_factorization x"
  shows   "prime_elem p"
proof -
  have A: "class.comm_semiring_1 op * 1 op + (0 :: 'a poly)" ..
  have B: "class.normalization_semidom op div op + op - (0 :: 'a poly) op * 1 
             unit_factor_field_poly normalize_field_poly" ..
  from field_poly.in_prime_factors_imp_prime [of p x] assms
    show ?thesis unfolding prime_elem_def dvd_field_poly
      comm_semiring_1.prime_elem_def[OF A] normalization_semidom.prime_def[OF B] by blast
qed


subsection \<open>Primality and irreducibility in polynomial rings\<close>

lemma nonconst_poly_irreducible_iff:
  fixes p :: "'a :: {factorial_semiring,semiring_Gcd,ring_gcd,idom_divide} poly"
  assumes "degree p \<noteq> 0"
  shows   "irreducible p \<longleftrightarrow> irreducible (fract_poly p) \<and> content p = 1"
proof safe
  assume p: "irreducible p"

  from content_decompose[of p] guess p' . note p' = this
  hence "p = [:content p:] * p'" by simp
  from p this have "[:content p:] dvd 1 \<or> p' dvd 1" by (rule irreducibleD)
  moreover have "\<not>p' dvd 1"
  proof
    assume "p' dvd 1"
    hence "degree p = 0" by (subst p') (auto simp: is_unit_poly_iff)
    with assms show False by contradiction
  qed
  ultimately show [simp]: "content p = 1" by (simp add: is_unit_const_poly_iff)
  
  show "irreducible (map_poly to_fract p)"
  proof (rule irreducibleI)
    have "fract_poly p = 0 \<longleftrightarrow> p = 0" by (intro map_poly_eq_0_iff) auto
    with assms show "map_poly to_fract p \<noteq> 0" by auto
  next
    show "\<not>is_unit (fract_poly p)"
    proof
      assume "is_unit (map_poly to_fract p)"
      hence "degree (map_poly to_fract p) = 0"
        by (auto simp: is_unit_poly_iff)
      hence "degree p = 0" by (simp add: degree_map_poly)
      with assms show False by contradiction
   qed
 next
   fix q r assume qr: "fract_poly p = q * r"
   from content_decompose_fract[of q] guess cg q' . note q = this
   from content_decompose_fract[of r] guess cr r' . note r = this
   from qr q r p have nz: "cg \<noteq> 0" "cr \<noteq> 0" by auto
   from qr have eq: "fract_poly p = smult (cr * cg) (fract_poly (q' * r'))"
     by (simp add: q r)
   from fract_poly_smult_eqE[OF this] guess a b . note ab = this
   hence "content (smult a p) = content (smult b (q' * r'))" by (simp only:)
   with ab(4) have a: "a = normalize b" by (simp add: content_mult q r)
   hence "normalize b = gcd a b" by simp
   also from ab(3) have "\<dots> = 1" .
   finally have "a = 1" "is_unit b" by (simp_all add: a normalize_1_iff)
   
   note eq
   also from ab(1) \<open>a = 1\<close> have "cr * cg = to_fract b" by simp
   also have "smult \<dots> (fract_poly (q' * r')) = fract_poly (smult b (q' * r'))" by simp
   finally have "p = ([:b:] * q') * r'" by (simp del: fract_poly_smult)
   from p and this have "([:b:] * q') dvd 1 \<or> r' dvd 1" by (rule irreducibleD)
   hence "q' dvd 1 \<or> r' dvd 1" by (auto dest: dvd_mult_right simp del: mult_pCons_left)
   hence "fract_poly q' dvd 1 \<or> fract_poly r' dvd 1" by (auto simp: fract_poly_is_unit)
   with q r show "is_unit q \<or> is_unit r"
     by (auto simp add: is_unit_smult_iff dvd_field_iff nz)
 qed

next

  assume irred: "irreducible (fract_poly p)" and primitive: "content p = 1"
  show "irreducible p"
  proof (rule irreducibleI)
    from irred show "p \<noteq> 0" by auto
  next
    from irred show "\<not>p dvd 1"
      by (auto simp: irreducible_def dest: fract_poly_is_unit)
  next
    fix q r assume qr: "p = q * r"
    hence "fract_poly p = fract_poly q * fract_poly r" by simp
    from irred and this have "fract_poly q dvd 1 \<or> fract_poly r dvd 1" 
      by (rule irreducibleD)
    with primitive qr show "q dvd 1 \<or> r dvd 1"
      by (auto simp:  content_prod_eq_1_iff is_unit_fract_poly_iff)
  qed
qed

context
begin

private lemma irreducible_imp_prime_poly:
  fixes p :: "'a :: {factorial_semiring,semiring_Gcd,ring_gcd,idom_divide} poly"
  assumes "irreducible p"
  shows   "prime_elem p"
proof (cases "degree p = 0")
  case True
  with assms show ?thesis
    by (auto simp: prime_elem_const_poly_iff irreducible_const_poly_iff
             intro!: irreducible_imp_prime_elem elim!: degree_eq_zeroE)
next
  case False
  from assms False have irred: "irreducible (fract_poly p)" and primitive: "content p = 1"
    by (simp_all add: nonconst_poly_irreducible_iff)
  from irred have prime: "prime_elem (fract_poly p)" by (rule field_poly_irreducible_imp_prime)
  show ?thesis
  proof (rule prime_elemI)
    fix q r assume "p dvd q * r"
    hence "fract_poly p dvd fract_poly (q * r)" by (rule fract_poly_dvd)
    hence "fract_poly p dvd fract_poly q * fract_poly r" by simp
    from prime and this have "fract_poly p dvd fract_poly q \<or> fract_poly p dvd fract_poly r"
      by (rule prime_elem_dvd_multD)
    with primitive show "p dvd q \<or> p dvd r" by (auto dest: fract_poly_dvdD)
  qed (insert assms, auto simp: irreducible_def)
qed


lemma degree_primitive_part_fract [simp]:
  "degree (primitive_part_fract p) = degree p"
proof -
  have "p = smult (fract_content p) (fract_poly (primitive_part_fract p))"
    by (simp add: content_times_primitive_part_fract)
  also have "degree \<dots> = degree (primitive_part_fract p)"
    by (auto simp: degree_map_poly)
  finally show ?thesis ..
qed

lemma irreducible_primitive_part_fract:
  fixes p :: "'a :: {idom_divide, ring_gcd, factorial_semiring, semiring_Gcd} fract poly"
  assumes "irreducible p"
  shows   "irreducible (primitive_part_fract p)"
proof -
  from assms have deg: "degree (primitive_part_fract p) \<noteq> 0"
    by (intro notI) 
       (auto elim!: degree_eq_zeroE simp: irreducible_def is_unit_poly_iff dvd_field_iff)
  hence [simp]: "p \<noteq> 0" by auto

  note \<open>irreducible p\<close>
  also have "p = [:fract_content p:] * fract_poly (primitive_part_fract p)" 
    by (simp add: content_times_primitive_part_fract)
  also have "irreducible \<dots> \<longleftrightarrow> irreducible (fract_poly (primitive_part_fract p))"
    by (intro irreducible_mult_unit_left) (simp_all add: is_unit_poly_iff dvd_field_iff)
  finally show ?thesis using deg
    by (simp add: nonconst_poly_irreducible_iff)
qed

lemma prime_elem_primitive_part_fract:
  fixes p :: "'a :: {idom_divide, ring_gcd, factorial_semiring, semiring_Gcd} fract poly"
  shows "irreducible p \<Longrightarrow> prime_elem (primitive_part_fract p)"
  by (intro irreducible_imp_prime_poly irreducible_primitive_part_fract)

lemma irreducible_linear_field_poly:
  fixes a b :: "'a::field"
  assumes "b \<noteq> 0"
  shows "irreducible [:a,b:]"
proof (rule irreducibleI)
  fix p q assume pq: "[:a,b:] = p * q"
  also from pq assms have "degree \<dots> = degree p + degree q" 
    by (intro degree_mult_eq) auto
  finally have "degree p = 0 \<or> degree q = 0" using assms by auto
  with assms pq show "is_unit p \<or> is_unit q"
    by (auto simp: is_unit_const_poly_iff dvd_field_iff elim!: degree_eq_zeroE)
qed (insert assms, auto simp: is_unit_poly_iff)

lemma prime_elem_linear_field_poly:
  "(b :: 'a :: field) \<noteq> 0 \<Longrightarrow> prime_elem [:a,b:]"
  by (rule field_poly_irreducible_imp_prime, rule irreducible_linear_field_poly)

lemma irreducible_linear_poly:
  fixes a b :: "'a::{idom_divide,ring_gcd,factorial_semiring,semiring_Gcd}"
  shows "b \<noteq> 0 \<Longrightarrow> coprime a b \<Longrightarrow> irreducible [:a,b:]"
  by (auto intro!: irreducible_linear_field_poly 
           simp:   nonconst_poly_irreducible_iff content_def map_poly_pCons)

lemma prime_elem_linear_poly:
  fixes a b :: "'a::{idom_divide,ring_gcd,factorial_semiring,semiring_Gcd}"
  shows "b \<noteq> 0 \<Longrightarrow> coprime a b \<Longrightarrow> prime_elem [:a,b:]"
  by (rule irreducible_imp_prime_poly, rule irreducible_linear_poly)

end

 
subsection \<open>Prime factorisation of polynomials\<close>   

context
begin 

private lemma poly_prime_factorization_exists_content_1:
  fixes p :: "'a :: {factorial_semiring,semiring_Gcd,ring_gcd,idom_divide} poly"
  assumes "p \<noteq> 0" "content p = 1"
  shows   "\<exists>A. (\<forall>p. p \<in># A \<longrightarrow> prime_elem p) \<and> prod_mset A = normalize p"
proof -
  let ?P = "field_poly.prime_factorization (fract_poly p)"
  define c where "c = prod_mset (image_mset fract_content ?P)"
  define c' where "c' = c * to_fract (lead_coeff p)"
  define e where "e = prod_mset (image_mset primitive_part_fract ?P)"
  define A where "A = image_mset (normalize \<circ> primitive_part_fract) ?P"
  have "content e = (\<Prod>x\<in>#field_poly.prime_factorization (map_poly to_fract p). 
                      content (primitive_part_fract x))"
    by (simp add: e_def content_prod_mset multiset.map_comp o_def)
  also have "image_mset (\<lambda>x. content (primitive_part_fract x)) ?P = image_mset (\<lambda>_. 1) ?P"
    by (intro image_mset_cong content_primitive_part_fract) auto
  finally have content_e: "content e = 1"
    by simp    
  
  have "fract_poly p = unit_factor_field_poly (fract_poly p) * 
          normalize_field_poly (fract_poly p)" by simp
  also have "unit_factor_field_poly (fract_poly p) = [:to_fract (lead_coeff p):]" 
    by (simp add: unit_factor_field_poly_def monom_0 degree_map_poly coeff_map_poly)
  also from assms have "normalize_field_poly (fract_poly p) = prod_mset ?P" 
    by (subst field_poly_prod_mset_prime_factorization) simp_all
  also have "\<dots> = prod_mset (image_mset id ?P)" by simp
  also have "image_mset id ?P = 
               image_mset (\<lambda>x. [:fract_content x:] * fract_poly (primitive_part_fract x)) ?P"
    by (intro image_mset_cong) (auto simp: content_times_primitive_part_fract)
  also have "prod_mset \<dots> = smult c (fract_poly e)"
    by (subst prod_mset.distrib) (simp_all add: prod_mset_fract_poly prod_mset_const_poly c_def e_def)
  also have "[:to_fract (lead_coeff p):] * \<dots> = smult c' (fract_poly e)"
    by (simp add: c'_def)
  finally have eq: "fract_poly p = smult c' (fract_poly e)" .
  also obtain b where b: "c' = to_fract b" "is_unit b"
  proof -
    from fract_poly_smult_eqE[OF eq] guess a b . note ab = this
    from ab(2) have "content (smult a p) = content (smult b e)" by (simp only: )
    with assms content_e have "a = normalize b" by (simp add: ab(4))
    with ab have ab': "a = 1" "is_unit b" by (simp_all add: normalize_1_iff)
    with ab ab' have "c' = to_fract b" by auto
    from this and \<open>is_unit b\<close> show ?thesis by (rule that)
  qed
  hence "smult c' (fract_poly e) = fract_poly (smult b e)" by simp
  finally have "p = smult b e" by (simp only: fract_poly_eq_iff)
  hence "p = [:b:] * e" by simp
  with b have "normalize p = normalize e" 
    by (simp only: normalize_mult) (simp add: is_unit_normalize is_unit_poly_iff)
  also have "normalize e = prod_mset A"
    by (simp add: multiset.map_comp e_def A_def normalize_prod_mset)
  finally have "prod_mset A = normalize p" ..
  
  have "prime_elem p" if "p \<in># A" for p
    using that by (auto simp: A_def prime_elem_primitive_part_fract prime_elem_imp_irreducible 
                        dest!: field_poly_in_prime_factorization_imp_prime )
  from this and \<open>prod_mset A = normalize p\<close> show ?thesis
    by (intro exI[of _ A]) blast
qed

lemma poly_prime_factorization_exists:
  fixes p :: "'a :: {factorial_semiring,semiring_Gcd,ring_gcd,idom_divide} poly"
  assumes "p \<noteq> 0"
  shows   "\<exists>A. (\<forall>p. p \<in># A \<longrightarrow> prime_elem p) \<and> prod_mset A = normalize p"
proof -
  define B where "B = image_mset (\<lambda>x. [:x:]) (prime_factorization (content p))"
  have "\<exists>A. (\<forall>p. p \<in># A \<longrightarrow> prime_elem p) \<and> prod_mset A = normalize (primitive_part p)"
    by (rule poly_prime_factorization_exists_content_1) (insert assms, simp_all)
  then guess A by (elim exE conjE) note A = this
  moreover from assms have "prod_mset B = [:content p:]"
    by (simp add: B_def prod_mset_const_poly prod_mset_prime_factorization)
  moreover have "\<forall>p. p \<in># B \<longrightarrow> prime_elem p"
    by (auto simp: B_def intro!: lift_prime_elem_poly dest: in_prime_factors_imp_prime)
  ultimately show ?thesis by (intro exI[of _ "B + A"]) auto
qed

end


subsection \<open>Typeclass instances\<close>

instance poly :: (factorial_ring_gcd) factorial_semiring
  by standard (rule poly_prime_factorization_exists)  

instantiation poly :: (factorial_ring_gcd) factorial_ring_gcd
begin

definition gcd_poly :: "'a poly \<Rightarrow> 'a poly \<Rightarrow> 'a poly" where
  [code del]: "gcd_poly = gcd_factorial"

definition lcm_poly :: "'a poly \<Rightarrow> 'a poly \<Rightarrow> 'a poly" where
  [code del]: "lcm_poly = lcm_factorial"
  
definition Gcd_poly :: "'a poly set \<Rightarrow> 'a poly" where
 [code del]: "Gcd_poly = Gcd_factorial"

definition Lcm_poly :: "'a poly set \<Rightarrow> 'a poly" where
 [code del]: "Lcm_poly = Lcm_factorial"
 
instance by standard (simp_all add: gcd_poly_def lcm_poly_def Gcd_poly_def Lcm_poly_def)

end

instantiation poly :: ("{field,factorial_ring_gcd}") unique_euclidean_ring
begin

definition euclidean_size_poly :: "'a poly \<Rightarrow> nat"
  where "euclidean_size_poly p = (if p = 0 then 0 else 2 ^ degree p)"

definition uniqueness_constraint_poly :: "'a poly \<Rightarrow> 'a poly \<Rightarrow> bool"
  where [simp]: "uniqueness_constraint_poly = top"

instance 
  by standard
   (auto simp: euclidean_size_poly_def Rings.div_mult_mod_eq div_poly_less degree_mult_eq intro!: degree_mod_less' degree_mult_right_le
    split: if_splits)

end

instance poly :: ("{field,factorial_ring_gcd}") euclidean_ring_gcd
  by (rule euclidean_ring_gcd_class.intro, rule factorial_euclidean_semiring_gcdI)
    standard

  
subsection \<open>Polynomial GCD\<close>

lemma gcd_poly_decompose:
  fixes p q :: "'a :: factorial_ring_gcd poly"
  shows "gcd p q = 
           smult (gcd (content p) (content q)) (gcd (primitive_part p) (primitive_part q))"
proof (rule sym, rule gcdI)
  have "[:gcd (content p) (content q):] * gcd (primitive_part p) (primitive_part q) dvd
          [:content p:] * primitive_part p" by (intro mult_dvd_mono) simp_all
  thus "smult (gcd (content p) (content q)) (gcd (primitive_part p) (primitive_part q)) dvd p"
    by simp
next
  have "[:gcd (content p) (content q):] * gcd (primitive_part p) (primitive_part q) dvd
          [:content q:] * primitive_part q" by (intro mult_dvd_mono) simp_all
  thus "smult (gcd (content p) (content q)) (gcd (primitive_part p) (primitive_part q)) dvd q"
    by simp
next
  fix d assume "d dvd p" "d dvd q"
  hence "[:content d:] * primitive_part d dvd 
           [:gcd (content p) (content q):] * gcd (primitive_part p) (primitive_part q)"
    by (intro mult_dvd_mono) auto
  thus "d dvd smult (gcd (content p) (content q)) (gcd (primitive_part p) (primitive_part q))"
    by simp
qed (auto simp: normalize_smult)
  

lemma gcd_poly_pseudo_mod:
  fixes p q :: "'a :: factorial_ring_gcd poly"
  assumes nz: "q \<noteq> 0" and prim: "content p = 1" "content q = 1"
  shows   "gcd p q = gcd q (primitive_part (pseudo_mod p q))"
proof -
  define r s where "r = fst (pseudo_divmod p q)" and "s = snd (pseudo_divmod p q)"
  define a where "a = [:coeff q (degree q) ^ (Suc (degree p) - degree q):]"
  have [simp]: "primitive_part a = unit_factor a"
    by (simp add: a_def unit_factor_poly_def unit_factor_power monom_0)
  from nz have [simp]: "a \<noteq> 0" by (auto simp: a_def)
  
  have rs: "pseudo_divmod p q = (r, s)" by (simp add: r_def s_def)
  have "gcd (q * r + s) q = gcd q s"
    using gcd_add_mult[of q r s] by (simp add: gcd.commute add_ac mult_ac)
  with pseudo_divmod(1)[OF nz rs]
    have "gcd (p * a) q = gcd q s" by (simp add: a_def)
  also from prim have "gcd (p * a) q = gcd p q"
    by (subst gcd_poly_decompose)
       (auto simp: primitive_part_mult gcd_mult_unit1 primitive_part_prim 
             simp del: mult_pCons_right )
  also from prim have "gcd q s = gcd q (primitive_part s)"
    by (subst gcd_poly_decompose) (simp_all add: primitive_part_prim)
  also have "s = pseudo_mod p q" by (simp add: s_def pseudo_mod_def)
  finally show ?thesis .
qed

lemma degree_pseudo_mod_less:
  assumes "q \<noteq> 0" "pseudo_mod p q \<noteq> 0"
  shows   "degree (pseudo_mod p q) < degree q"
  using pseudo_mod(2)[of q p] assms by auto

function gcd_poly_code_aux :: "'a :: factorial_ring_gcd poly \<Rightarrow> 'a poly \<Rightarrow> 'a poly" where
  "gcd_poly_code_aux p q = 
     (if q = 0 then normalize p else gcd_poly_code_aux q (primitive_part (pseudo_mod p q)))" 
by auto
termination
  by (relation "measure ((\<lambda>p. if p = 0 then 0 else Suc (degree p)) \<circ> snd)")
     (auto simp: degree_pseudo_mod_less)

declare gcd_poly_code_aux.simps [simp del]

lemma gcd_poly_code_aux_correct:
  assumes "content p = 1" "q = 0 \<or> content q = 1"
  shows   "gcd_poly_code_aux p q = gcd p q"
  using assms
proof (induction p q rule: gcd_poly_code_aux.induct)
  case (1 p q)
  show ?case
  proof (cases "q = 0")
    case True
    thus ?thesis by (subst gcd_poly_code_aux.simps) auto
  next
    case False
    hence "gcd_poly_code_aux p q = gcd_poly_code_aux q (primitive_part (pseudo_mod p q))"
      by (subst gcd_poly_code_aux.simps) simp_all
    also from "1.prems" False 
      have "primitive_part (pseudo_mod p q) = 0 \<or> 
              content (primitive_part (pseudo_mod p q)) = 1"
      by (cases "pseudo_mod p q = 0") auto
    with "1.prems" False 
      have "gcd_poly_code_aux q (primitive_part (pseudo_mod p q)) = 
              gcd q (primitive_part (pseudo_mod p q))"
      by (intro 1) simp_all
    also from "1.prems" False 
      have "\<dots> = gcd p q" by (intro gcd_poly_pseudo_mod [symmetric]) auto
    finally show ?thesis .
  qed
qed

definition gcd_poly_code 
    :: "'a :: factorial_ring_gcd poly \<Rightarrow> 'a poly \<Rightarrow> 'a poly" 
  where "gcd_poly_code p q = 
           (if p = 0 then normalize q else if q = 0 then normalize p else
              smult (gcd (content p) (content q)) 
                (gcd_poly_code_aux (primitive_part p) (primitive_part q)))"

lemma gcd_poly_code [code]: "gcd p q = gcd_poly_code p q"
  by (simp add: gcd_poly_code_def gcd_poly_code_aux_correct gcd_poly_decompose [symmetric])

lemma lcm_poly_code [code]: 
  fixes p q :: "'a :: factorial_ring_gcd poly"
  shows "lcm p q = normalize (p * q) div gcd p q"
  by (fact lcm_gcd)

declare Gcd_set
  [where ?'a = "'a :: factorial_ring_gcd poly", code]

declare Lcm_set
  [where ?'a = "'a :: factorial_ring_gcd poly", code]

text \<open>Example:
  @{lemma "Lcm {[:1, 2, 3:], [:2, 3, 4:]} = [:[:2:], [:7:], [:16:], [:17:], [:12 :: int:]:]" by eval}
\<close>
  
end

(*  Title:      HOL/Algebra/QuotRing.thy
    Author:     Stephan Hohe
    Author:     Paulo Emílio de Vilhena
*)

theory QuotRing
imports RingHom
begin

section \<open>Quotient Rings\<close>

subsection \<open>Multiplication on Cosets\<close>

definition rcoset_mult :: "[('a, _) ring_scheme, 'a set, 'a set, 'a set] \<Rightarrow> 'a set"
    ("[mod _:] _ \<Otimes>\<index> _" [81,81,81] 80)
  where "rcoset_mult R I A B = (\<Union>a\<in>A. \<Union>b\<in>B. I +>\<^bsub>R\<^esub> (a \<otimes>\<^bsub>R\<^esub> b))"


text \<open>@{const "rcoset_mult"} fulfils the properties required by
  congruences\<close>
lemma (in ideal) rcoset_mult_add:
    "x \<in> carrier R \<Longrightarrow> y \<in> carrier R \<Longrightarrow> [mod I:] (I +> x) \<Otimes> (I +> y) = I +> (x \<otimes> y)"
  apply rule
  apply (rule, simp add: rcoset_mult_def, clarsimp)
  defer 1
  apply (rule, simp add: rcoset_mult_def)
  defer 1
proof -
  fix z x' y'
  assume carr: "x \<in> carrier R" "y \<in> carrier R"
    and x'rcos: "x' \<in> I +> x"
    and y'rcos: "y' \<in> I +> y"
    and zrcos: "z \<in> I +> x' \<otimes> y'"

  from x'rcos have "\<exists>h\<in>I. x' = h \<oplus> x"
    by (simp add: a_r_coset_def r_coset_def)
  then obtain hx where hxI: "hx \<in> I" and x': "x' = hx \<oplus> x"
    by fast+

  from y'rcos have "\<exists>h\<in>I. y' = h \<oplus> y"
    by (simp add: a_r_coset_def r_coset_def)
  then obtain hy where hyI: "hy \<in> I" and y': "y' = hy \<oplus> y"
    by fast+

  from zrcos have "\<exists>h\<in>I. z = h \<oplus> (x' \<otimes> y')"
    by (simp add: a_r_coset_def r_coset_def)
  then obtain hz where hzI: "hz \<in> I" and z: "z = hz \<oplus> (x' \<otimes> y')"
    by fast+

  note carr = carr hxI[THEN a_Hcarr] hyI[THEN a_Hcarr] hzI[THEN a_Hcarr]

  from z have "z = hz \<oplus> (x' \<otimes> y')" .
  also from x' y' have "\<dots> = hz \<oplus> ((hx \<oplus> x) \<otimes> (hy \<oplus> y))" by simp
  also from carr have "\<dots> = (hz \<oplus> (hx \<otimes> (hy \<oplus> y)) \<oplus> x \<otimes> hy) \<oplus> x \<otimes> y" by algebra
  finally have z2: "z = (hz \<oplus> (hx \<otimes> (hy \<oplus> y)) \<oplus> x \<otimes> hy) \<oplus> x \<otimes> y" .

  from hxI hyI hzI carr have "hz \<oplus> (hx \<otimes> (hy \<oplus> y)) \<oplus> x \<otimes> hy \<in> I"
    by (simp add: I_l_closed I_r_closed)

  with z2 have "\<exists>h\<in>I. z = h \<oplus> x \<otimes> y" by fast
  then show "z \<in> I +> x \<otimes> y" by (simp add: a_r_coset_def r_coset_def)
next
  fix z
  assume xcarr: "x \<in> carrier R"
    and ycarr: "y \<in> carrier R"
    and zrcos: "z \<in> I +> x \<otimes> y"
  from xcarr have xself: "x \<in> I +> x" by (intro a_rcos_self)
  from ycarr have yself: "y \<in> I +> y" by (intro a_rcos_self)
  show "\<exists>a\<in>I +> x. \<exists>b\<in>I +> y. z \<in> I +> a \<otimes> b"
    using xself and yself and zrcos by fast
qed


subsection \<open>Quotient Ring Definition\<close>

definition FactRing :: "[('a,'b) ring_scheme, 'a set] \<Rightarrow> ('a set) ring"
    (infixl "Quot" 65)
  where "FactRing R I =
    \<lparr>carrier = a_rcosets\<^bsub>R\<^esub> I, mult = rcoset_mult R I,
      one = (I +>\<^bsub>R\<^esub> \<one>\<^bsub>R\<^esub>), zero = I, add = set_add R\<rparr>"


subsection \<open>Factorization over General Ideals\<close>

text \<open>The quotient is a ring\<close>
lemma (in ideal) quotient_is_ring: "ring (R Quot I)"
apply (rule ringI)
   \<comment> \<open>abelian group\<close>
   apply (rule comm_group_abelian_groupI)
   apply (simp add: FactRing_def)
   apply (rule a_factorgroup_is_comm_group[unfolded A_FactGroup_def'])
  \<comment> \<open>mult monoid\<close>
  apply (rule monoidI)
      apply (simp_all add: FactRing_def A_RCOSETS_def RCOSETS_def
             a_r_coset_def[symmetric])
      \<comment> \<open>mult closed\<close>
      apply (clarify)
      apply (simp add: rcoset_mult_add, fast)
     \<comment> \<open>mult \<open>one_closed\<close>\<close>
     apply force
    \<comment> \<open>mult assoc\<close>
    apply clarify
    apply (simp add: rcoset_mult_add m_assoc)
   \<comment> \<open>mult one\<close>
   apply clarify
   apply (simp add: rcoset_mult_add)
  apply clarify
  apply (simp add: rcoset_mult_add)
 \<comment> \<open>distr\<close>
 apply clarify
 apply (simp add: rcoset_mult_add a_rcos_sum l_distr)
apply clarify
apply (simp add: rcoset_mult_add a_rcos_sum r_distr)
done


text \<open>This is a ring homomorphism\<close>

lemma (in ideal) rcos_ring_hom: "((+>) I) \<in> ring_hom R (R Quot I)"
apply (rule ring_hom_memI)
   apply (simp add: FactRing_def a_rcosetsI[OF a_subset])
  apply (simp add: FactRing_def rcoset_mult_add)
 apply (simp add: FactRing_def a_rcos_sum)
apply (simp add: FactRing_def)
done

lemma (in ideal) rcos_ring_hom_ring: "ring_hom_ring R (R Quot I) ((+>) I)"
apply (rule ring_hom_ringI)
     apply (rule is_ring, rule quotient_is_ring)
   apply (simp add: FactRing_def a_rcosetsI[OF a_subset])
  apply (simp add: FactRing_def rcoset_mult_add)
 apply (simp add: FactRing_def a_rcos_sum)
apply (simp add: FactRing_def)
done

text \<open>The quotient of a cring is also commutative\<close>
lemma (in ideal) quotient_is_cring:
  assumes "cring R"
  shows "cring (R Quot I)"
proof -
  interpret cring R by fact
  show ?thesis
    apply (intro cring.intro comm_monoid.intro comm_monoid_axioms.intro)
      apply (rule quotient_is_ring)
     apply (rule ring.axioms[OF quotient_is_ring])
    apply (simp add: FactRing_def A_RCOSETS_defs a_r_coset_def[symmetric])
    apply clarify
    apply (simp add: rcoset_mult_add m_comm)
    done
qed

text \<open>Cosets as a ring homomorphism on crings\<close>
lemma (in ideal) rcos_ring_hom_cring:
  assumes "cring R"
  shows "ring_hom_cring R (R Quot I) ((+>) I)"
proof -
  interpret cring R by fact
  show ?thesis
    apply (rule ring_hom_cringI)
      apply (rule rcos_ring_hom_ring)
     apply (rule is_cring)
    apply (rule quotient_is_cring)
   apply (rule is_cring)
   done
qed


subsection \<open>Factorization over Prime Ideals\<close>

text \<open>The quotient ring generated by a prime ideal is a domain\<close>
lemma (in primeideal) quotient_is_domain: "domain (R Quot I)"
  apply (rule domain.intro)
   apply (rule quotient_is_cring, rule is_cring)
  apply (rule domain_axioms.intro)
   apply (simp add: FactRing_def) defer 1
    apply (simp add: FactRing_def A_RCOSETS_defs a_r_coset_def[symmetric], clarify)
    apply (simp add: rcoset_mult_add) defer 1
proof (rule ccontr, clarsimp)
  assume "I +> \<one> = I"
  then have "\<one> \<in> I" by (simp only: a_coset_join1 one_closed a_subgroup)
  then have "carrier R \<subseteq> I" by (subst one_imp_carrier, simp, fast)
  with a_subset have "I = carrier R" by fast
  with I_notcarr show False by fast
next
  fix x y
  assume carr: "x \<in> carrier R" "y \<in> carrier R"
    and a: "I +> x \<otimes> y = I"
    and b: "I +> y \<noteq> I"

  have ynI: "y \<notin> I"
  proof (rule ccontr, simp)
    assume "y \<in> I"
    then have "I +> y = I" by (rule a_rcos_const)
    with b show False by simp
  qed

  from carr have "x \<otimes> y \<in> I +> x \<otimes> y" by (simp add: a_rcos_self)
  then have xyI: "x \<otimes> y \<in> I" by (simp add: a)

  from xyI and carr have xI: "x \<in> I \<or> y \<in> I" by (simp add: I_prime)
  with ynI have "x \<in> I" by fast
  then show "I +> x = I" by (rule a_rcos_const)
qed

text \<open>Generating right cosets of a prime ideal is a homomorphism
        on commutative rings\<close>
lemma (in primeideal) rcos_ring_hom_cring: "ring_hom_cring R (R Quot I) ((+>) I)"
  by (rule rcos_ring_hom_cring) (rule is_cring)


subsection \<open>Factorization over Maximal Ideals\<close>

text \<open>In a commutative ring, the quotient ring over a maximal ideal
        is a field.
        The proof follows ``W. Adkins, S. Weintraub: Algebra --
        An Approach via Module Theory''\<close>
lemma (in maximalideal) quotient_is_field:
  assumes "cring R"
  shows "field (R Quot I)"
proof -
  interpret cring R by fact
  show ?thesis
    apply (intro cring.cring_fieldI2)
      apply (rule quotient_is_cring, rule is_cring)
     defer 1
     apply (simp add: FactRing_def A_RCOSETS_defs a_r_coset_def[symmetric], clarsimp)
     apply (simp add: rcoset_mult_add) defer 1
  proof (rule ccontr, simp)
    \<comment> \<open>Quotient is not empty\<close>
    assume "\<zero>\<^bsub>R Quot I\<^esub> = \<one>\<^bsub>R Quot I\<^esub>"
    then have II1: "I = I +> \<one>" by (simp add: FactRing_def)
    from a_rcos_self[OF one_closed] have "\<one> \<in> I"
      by (simp add: II1[symmetric])
    then have "I = carrier R" by (rule one_imp_carrier)
    with I_notcarr show False by simp
  next
    \<comment> \<open>Existence of Inverse\<close>
    fix a
    assume IanI: "I +> a \<noteq> I" and acarr: "a \<in> carrier R"

    \<comment> \<open>Helper ideal \<open>J\<close>\<close>
    define J :: "'a set" where "J = (carrier R #> a) <+> I"
    have idealJ: "ideal J R"
      apply (unfold J_def, rule add_ideals)
       apply (simp only: cgenideal_eq_rcos[symmetric], rule cgenideal_ideal, rule acarr)
      apply (rule is_ideal)
      done

    \<comment> \<open>Showing @{term "J"} not smaller than @{term "I"}\<close>
    have IinJ: "I \<subseteq> J"
    proof (rule, simp add: J_def r_coset_def set_add_defs)
      fix x
      assume xI: "x \<in> I"
      have Zcarr: "\<zero> \<in> carrier R" by fast
      from xI[THEN a_Hcarr] acarr
      have "x = \<zero> \<otimes> a \<oplus> x" by algebra
      with Zcarr and xI show "\<exists>xa\<in>carrier R. \<exists>k\<in>I. x = xa \<otimes> a \<oplus> k" by fast
    qed

    \<comment> \<open>Showing @{term "J \<noteq> I"}\<close>
    have anI: "a \<notin> I"
    proof (rule ccontr, simp)
      assume "a \<in> I"
      then have "I +> a = I" by (rule a_rcos_const)
      with IanI show False by simp
    qed

    have aJ: "a \<in> J"
    proof (simp add: J_def r_coset_def set_add_defs)
      from acarr
      have "a = \<one> \<otimes> a \<oplus> \<zero>" by algebra
      with one_closed and additive_subgroup.zero_closed[OF is_additive_subgroup]
      show "\<exists>x\<in>carrier R. \<exists>k\<in>I. a = x \<otimes> a \<oplus> k" by fast
    qed

    from aJ and anI have JnI: "J \<noteq> I" by fast

    \<comment> \<open>Deducing @{term "J = carrier R"} because @{term "I"} is maximal\<close>
    from idealJ and IinJ have "J = I \<or> J = carrier R"
    proof (rule I_maximal, unfold J_def)
      have "carrier R #> a \<subseteq> carrier R"
        using subset_refl acarr by (rule r_coset_subset_G)
      then show "carrier R #> a <+> I \<subseteq> carrier R"
        using a_subset by (rule set_add_closed)
    qed

    with JnI have Jcarr: "J = carrier R" by simp

    \<comment> \<open>Calculating an inverse for @{term "a"}\<close>
    from one_closed[folded Jcarr]
    have "\<exists>r\<in>carrier R. \<exists>i\<in>I. \<one> = r \<otimes> a \<oplus> i"
      by (simp add: J_def r_coset_def set_add_defs)
    then obtain r i where rcarr: "r \<in> carrier R"
      and iI: "i \<in> I" and one: "\<one> = r \<otimes> a \<oplus> i" by fast
    from one and rcarr and acarr and iI[THEN a_Hcarr]
    have rai1: "a \<otimes> r = \<ominus>i \<oplus> \<one>" by algebra

    \<comment> \<open>Lifting to cosets\<close>
    from iI have "\<ominus>i \<oplus> \<one> \<in> I +> \<one>"
      by (intro a_rcosI, simp, intro a_subset, simp)
    with rai1 have "a \<otimes> r \<in> I +> \<one>" by simp
    then have "I +> \<one> = I +> a \<otimes> r"
      by (rule a_repr_independence, simp) (rule a_subgroup)

    from rcarr and this[symmetric]
    show "\<exists>r\<in>carrier R. I +> a \<otimes> r = I +> \<one>" by fast
  qed
qed


lemma (in ring_hom_ring) trivial_hom_iff:
  "(h ` (carrier R) = { \<zero>\<^bsub>S\<^esub> }) = (a_kernel R S h = carrier R)"
  using group_hom.trivial_hom_iff[OF a_group_hom] by (simp add: a_kernel_def)

lemma (in ring_hom_ring) trivial_ker_imp_inj:
  assumes "a_kernel R S h = { \<zero> }"
  shows "inj_on h (carrier R)"
  using group_hom.trivial_ker_imp_inj[OF a_group_hom] assms a_kernel_def[of R S h] by simp 

lemma (in ring_hom_ring) non_trivial_field_hom_imp_inj:
  assumes "field R"
  shows "h ` (carrier R) \<noteq> { \<zero>\<^bsub>S\<^esub> } \<Longrightarrow> inj_on h (carrier R)"
proof -
  assume "h ` (carrier R) \<noteq> { \<zero>\<^bsub>S\<^esub> }"
  hence "a_kernel R S h \<noteq> carrier R"
    using trivial_hom_iff by linarith
  hence "a_kernel R S h = { \<zero> }"
    using field.all_ideals[OF assms] kernel_is_ideal by blast
  thus "inj_on h (carrier R)"
    using trivial_ker_imp_inj by blast
qed

lemma (in ring_hom_ring) img_is_add_subgroup:
  assumes "subgroup H (add_monoid R)"
  shows "subgroup (h ` H) (add_monoid S)"
proof -
  have "group ((add_monoid R) \<lparr> carrier := H \<rparr>)"
    using assms R.add.subgroup_imp_group by blast
  moreover have "H \<subseteq> carrier R" by (simp add: R.add.subgroupE(1) assms)
  hence "h \<in> hom ((add_monoid R) \<lparr> carrier := H \<rparr>) (add_monoid S)"
    unfolding hom_def by (auto simp add: subsetD)
  ultimately have "subgroup (h ` carrier ((add_monoid R) \<lparr> carrier := H \<rparr>)) (add_monoid S)"
    using group_hom.img_is_subgroup[of "(add_monoid R) \<lparr> carrier := H \<rparr>" "add_monoid S" h]
    using a_group_hom group_hom_axioms.intro group_hom_def by blast
  thus "subgroup (h ` H) (add_monoid S)" by simp
qed

lemma (in ring) ring_ideal_imp_quot_ideal:
  assumes "ideal I R"
  shows "ideal J R \<Longrightarrow> ideal ((+>) I ` J) (R Quot I)"
proof -
  assume A: "ideal J R" show "ideal (((+>) I) ` J) (R Quot I)"
  proof (rule idealI)
    show "ring (R Quot I)"
      by (simp add: assms(1) ideal.quotient_is_ring) 
  next
    have "subgroup J (add_monoid R)"
      by (simp add: additive_subgroup.a_subgroup A ideal.axioms(1))
    moreover have "((+>) I) \<in> ring_hom R (R Quot I)"
      by (simp add: assms(1) ideal.rcos_ring_hom)
    ultimately show "subgroup ((+>) I ` J) (add_monoid (R Quot I))"
      using assms(1) ideal.rcos_ring_hom_ring ring_hom_ring.img_is_add_subgroup by blast
  next
    fix a x assume "a \<in> (+>) I ` J" "x \<in> carrier (R Quot I)"
    then obtain i j where i: "i \<in> carrier R" "x = I +> i"
                      and j: "j \<in> J" "a = I +> j"
      unfolding FactRing_def using A_RCOSETS_def'[of R I] by auto
    hence "a \<otimes>\<^bsub>R Quot I\<^esub> x = [mod I:] (I +> j) \<Otimes> (I +> i)"
      unfolding FactRing_def by simp
    hence "a \<otimes>\<^bsub>R Quot I\<^esub> x = I +> (j \<otimes> i)"
      using ideal.rcoset_mult_add[OF assms(1), of j i] i(1) j(1) A ideal.Icarr by force
    thus "a \<otimes>\<^bsub>R Quot I\<^esub> x \<in> (+>) I ` J"
      using A i(1) j(1) by (simp add: ideal.I_r_closed)
  
    have "x \<otimes>\<^bsub>R Quot I\<^esub> a = [mod I:] (I +> i) \<Otimes> (I +> j)"
      unfolding FactRing_def i j by simp
    hence "x \<otimes>\<^bsub>R Quot I\<^esub> a = I +> (i \<otimes> j)"
      using ideal.rcoset_mult_add[OF assms(1), of i j] i(1) j(1) A ideal.Icarr by force
    thus "x \<otimes>\<^bsub>R Quot I\<^esub> a \<in> (+>) I ` J"
      using A i(1) j(1) by (simp add: ideal.I_l_closed)
  qed
qed

lemma (in ring_hom_ring) ideal_vimage:
  assumes "ideal I S"
  shows "ideal { r \<in> carrier R. h r \<in> I } R" (* or (carrier R) \<inter> (h -` I) *)
proof
  show "{ r \<in> carrier R. h r \<in> I } \<subseteq> carrier (add_monoid R)" by auto
next
  show "\<one>\<^bsub>add_monoid R\<^esub> \<in> { r \<in> carrier R. h r \<in> I }"
    by (simp add: additive_subgroup.zero_closed assms ideal.axioms(1))
next
  fix a b
  assume "a \<in> { r \<in> carrier R. h r \<in> I }"
     and "b \<in> { r \<in> carrier R. h r \<in> I }"
  hence a: "a \<in> carrier R" "h a \<in> I"
    and b: "b \<in> carrier R" "h b \<in> I" by auto
  hence "h (a \<oplus> b) = (h a) \<oplus>\<^bsub>S\<^esub> (h b)" using hom_add by blast
  moreover have "(h a) \<oplus>\<^bsub>S\<^esub> (h b) \<in> I" using a b assms
    by (simp add: additive_subgroup.a_closed ideal.axioms(1))
  ultimately show "a \<otimes>\<^bsub>add_monoid R\<^esub> b \<in> { r \<in> carrier R. h r \<in> I }"
    using a(1) b (1) by auto

  have "h (\<ominus> a) = \<ominus>\<^bsub>S\<^esub> (h a)" by (simp add: a)
  moreover have "\<ominus>\<^bsub>S\<^esub> (h a) \<in> I"
    by (simp add: a(2) additive_subgroup.a_inv_closed assms ideal.axioms(1))
  ultimately show "inv\<^bsub>add_monoid R\<^esub> a \<in> { r \<in> carrier R. h r \<in> I }"
    using a by (simp add: a_inv_def)
next
  fix a r
  assume "a \<in> { r \<in> carrier R. h r \<in> I }" and r: "r \<in> carrier R"
  hence a: "a \<in> carrier R" "h a \<in> I" by auto

  have "h a \<otimes>\<^bsub>S\<^esub> h r \<in> I"
    using assms a r by (simp add: ideal.I_r_closed)
  thus "a \<otimes> r \<in> { r \<in> carrier R. h r \<in> I }" by (simp add: a(1) r)

  have "h r \<otimes>\<^bsub>S\<^esub> h a \<in> I"
    using assms a r by (simp add: ideal.I_l_closed)
  thus "r \<otimes> a \<in> { r \<in> carrier R. h r \<in> I }" by (simp add: a(1) r)
qed

lemma (in ring) canonical_proj_vimage_in_carrier:
  assumes "ideal I R"
  shows "J \<subseteq> carrier (R Quot I) \<Longrightarrow> \<Union> J \<subseteq> carrier R"
proof -
  assume A: "J \<subseteq> carrier (R Quot I)" show "\<Union> J \<subseteq> carrier R"
  proof
    fix j assume j: "j \<in> \<Union> J"
    then obtain j' where j': "j' \<in> J" "j \<in> j'" by blast
    then obtain r where r: "r \<in> carrier R" "j' = I +> r"
      using A j' unfolding FactRing_def using A_RCOSETS_def'[of R I] by auto
    thus "j \<in> carrier R" using j' assms
      by (meson a_r_coset_subset_G additive_subgroup.a_subset contra_subsetD ideal.axioms(1)) 
  qed
qed

lemma (in ring) canonical_proj_vimage_mem_iff:
  assumes "ideal I R" "J \<subseteq> carrier (R Quot I)"
  shows "\<And>a. a \<in> carrier R \<Longrightarrow> (a \<in> (\<Union> J)) = (I +> a \<in> J)"
proof -
  fix a assume a: "a \<in> carrier R" show "(a \<in> (\<Union> J)) = (I +> a \<in> J)"
  proof
    assume "a \<in> \<Union> J"
    then obtain j where j: "j \<in> J" "a \<in> j" by blast
    then obtain r where r: "r \<in> carrier R" "j = I +> r"
      using assms j unfolding FactRing_def using A_RCOSETS_def'[of R I] by auto
    hence "I +> r = I +> a"
      using add.repr_independence[of a I r] j r
      by (metis a_r_coset_def additive_subgroup.a_subgroup assms(1) ideal.axioms(1))
    thus "I +> a \<in> J" using r j by simp
  next
    assume "I +> a \<in> J"
    hence "\<zero> \<oplus> a \<in> I +> a"
      using additive_subgroup.zero_closed[OF ideal.axioms(1)[OF assms(1)]]
            a_r_coset_def'[of R I a] by blast
    thus "a \<in> \<Union> J" using a \<open>I +> a \<in> J\<close> by auto 
  qed
qed

corollary (in ring) quot_ideal_imp_ring_ideal:
  assumes "ideal I R"
  shows "ideal J (R Quot I) \<Longrightarrow> ideal (\<Union> J) R"
proof -
  assume A: "ideal J (R Quot I)"
  have "\<Union> J = { r \<in> carrier R. I +> r \<in> J }"
    using canonical_proj_vimage_in_carrier[OF assms, of J]
          canonical_proj_vimage_mem_iff[OF assms, of J]
          additive_subgroup.a_subset[OF ideal.axioms(1)[OF A]] by blast
  thus "ideal (\<Union> J) R"
    using ring_hom_ring.ideal_vimage[OF ideal.rcos_ring_hom_ring[OF assms] A] by simp
qed

lemma (in ring) ideal_incl_iff:
  assumes "ideal I R" "ideal J R"
  shows "(I \<subseteq> J) = (J = (\<Union> j \<in> J. I +> j))"
proof
  assume A: "J = (\<Union> j \<in> J. I +> j)" hence "I +> \<zero> \<subseteq> J"
    using additive_subgroup.zero_closed[OF ideal.axioms(1)[OF assms(2)]] by blast
  thus "I \<subseteq> J" using additive_subgroup.a_subset[OF ideal.axioms(1)[OF assms(1)]] by simp 
next
  assume A: "I \<subseteq> J" show "J = (\<Union>j\<in>J. I +> j)"
  proof
    show "J \<subseteq> (\<Union> j \<in> J. I +> j)"
    proof
      fix j assume j: "j \<in> J"
      have "\<zero> \<in> I" by (simp add: additive_subgroup.zero_closed assms(1) ideal.axioms(1))
      hence "\<zero> \<oplus> j \<in> I +> j"
        using a_r_coset_def'[of R I j] by blast
      thus "j \<in> (\<Union>j\<in>J. I +> j)"
        using assms(2) j additive_subgroup.a_Hcarr ideal.axioms(1) by fastforce 
    qed
  next
    show "(\<Union> j \<in> J. I +> j) \<subseteq> J"
    proof
      fix x assume "x \<in> (\<Union> j \<in> J. I +> j)"
      then obtain j where j: "j \<in> J" "x \<in> I +> j" by blast
      then obtain i where i: "i \<in> I" "x = i \<oplus> j"
        using a_r_coset_def'[of R I j] by blast
      thus "x \<in> J"
        using assms(2) j A additive_subgroup.a_closed[OF ideal.axioms(1)[OF assms(2)]] by blast
    qed
  qed
qed

theorem (in ring) quot_ideal_correspondence:
  assumes "ideal I R"
  shows "bij_betw (\<lambda>J. (+>) I ` J) { J. ideal J R \<and> I \<subseteq> J } { J . ideal J (R Quot I) }"
proof (rule bij_betw_byWitness[where ?f' = "\<lambda>X. \<Union> X"])
  show "\<forall>J \<in> { J. ideal J R \<and> I \<subseteq> J }. (\<lambda>X. \<Union> X) ((+>) I ` J) = J"
    using assms ideal_incl_iff by blast
next
  show "(\<lambda>J. (+>) I ` J) ` { J. ideal J R \<and> I \<subseteq> J } \<subseteq> { J. ideal J (R Quot I) }"
    using assms ring_ideal_imp_quot_ideal by auto
next
  show "(\<lambda>X. \<Union> X) ` { J. ideal J (R Quot I) } \<subseteq> { J. ideal J R \<and> I \<subseteq> J }"
  proof
    fix J assume "J \<in> ((\<lambda>X. \<Union> X) ` { J. ideal J (R Quot I) })"
    then obtain J' where J': "ideal J' (R Quot I)" "J = \<Union> J'" by blast
    hence "ideal J R"
      using assms quot_ideal_imp_ring_ideal by auto
    moreover have "I \<in> J'"
      using additive_subgroup.zero_closed[OF ideal.axioms(1)[OF J'(1)]] unfolding FactRing_def by simp
    ultimately show "J \<in> { J. ideal J R \<and> I \<subseteq> J }" using J'(2) by auto
  qed
next
  show "\<forall>J' \<in> { J. ideal J (R Quot I) }. ((+>) I ` (\<Union> J')) = J'"
  proof
    fix J' assume "J' \<in> { J. ideal J (R Quot I) }"
    hence subset: "J' \<subseteq> carrier (R Quot I) \<and> ideal J' (R Quot I)"
      using additive_subgroup.a_subset ideal_def by blast
    hence "((+>) I ` (\<Union> J')) \<subseteq> J'"
      using canonical_proj_vimage_in_carrier canonical_proj_vimage_mem_iff
      by (meson assms contra_subsetD image_subsetI)
    moreover have "J' \<subseteq> ((+>) I ` (\<Union> J'))"
    proof
      fix x assume "x \<in> J'"
      then obtain r where r: "r \<in> carrier R" "x = I +> r"
        using subset unfolding FactRing_def A_RCOSETS_def'[of R I] by auto
      hence "r \<in> (\<Union> J')"
        using \<open>x \<in> J'\<close> assms canonical_proj_vimage_mem_iff subset by blast
      thus "x \<in> ((+>) I ` (\<Union> J'))" using r(2) by blast
    qed
    ultimately show "((+>) I ` (\<Union> J')) = J'" by blast
  qed
qed

lemma (in cring) quot_domain_imp_primeideal:
  assumes "ideal P R"
  shows "domain (R Quot P) \<Longrightarrow> primeideal P R"
proof -
  assume A: "domain (R Quot P)" show "primeideal P R"
  proof (rule primeidealI)
    show "ideal P R" using assms .
    show "cring R" using is_cring .
  next
    show "carrier R \<noteq> P"
    proof (rule ccontr)
      assume "\<not> carrier R \<noteq> P" hence "carrier R = P" by simp
      hence "\<And>I. I \<in> carrier (R Quot P) \<Longrightarrow> I = P"
        unfolding FactRing_def A_RCOSETS_def' apply simp
        using a_coset_join2 additive_subgroup.a_subgroup assms ideal.axioms(1) by blast
      hence "\<one>\<^bsub>(R Quot P)\<^esub> = \<zero>\<^bsub>(R Quot P)\<^esub>"
        by (metis assms ideal.quotient_is_ring ring.ring_simprules(2) ring.ring_simprules(6))
      thus False using domain.one_not_zero[OF A] by simp
    qed
  next
    fix a b assume a: "a \<in> carrier R" and b: "b \<in> carrier R" and ab: "a \<otimes> b \<in> P"
    hence "P +> (a \<otimes> b) = \<zero>\<^bsub>(R Quot P)\<^esub>" unfolding FactRing_def
      by (simp add: a_coset_join2 additive_subgroup.a_subgroup assms ideal.axioms(1))
    moreover have "(P +> a) \<otimes>\<^bsub>(R Quot P)\<^esub> (P +> b) = P +> (a \<otimes> b)" unfolding FactRing_def
      using a b by (simp add: assms ideal.rcoset_mult_add)
    moreover have "P +> a \<in> carrier (R Quot P) \<and> P +> b \<in> carrier (R Quot P)"
      by (simp add: a b FactRing_def a_rcosetsI additive_subgroup.a_subset assms ideal.axioms(1))
    ultimately have "P +> a = \<zero>\<^bsub>(R Quot P)\<^esub> \<or> P +> b = \<zero>\<^bsub>(R Quot P)\<^esub>"
      using domain.integral[OF A, of "P +> a" "P +> b"] by auto
    thus "a \<in> P \<or> b \<in> P" unfolding FactRing_def apply simp
      using a b assms a_coset_join1 additive_subgroup.a_subgroup ideal.axioms(1) by blast
  qed
qed

lemma (in cring) quot_domain_iff_primeideal:
  assumes "ideal P R"
  shows "domain (R Quot P) = primeideal P R"
  using quot_domain_imp_primeideal[OF assms] primeideal.quotient_is_domain[of P R] by auto


subsection \<open>Isomorphism\<close>

definition
  ring_iso :: "_ \<Rightarrow> _ \<Rightarrow> ('a \<Rightarrow> 'b) set"
  where "ring_iso R S = { h. h \<in> ring_hom R S \<and> bij_betw h (carrier R) (carrier S) }"

definition
  is_ring_iso :: "_ \<Rightarrow> _ \<Rightarrow> bool" (infixr "\<simeq>" 60)
  where "R \<simeq> S = (ring_iso R S \<noteq> {})"

definition
  morphic_prop :: "_ \<Rightarrow> ('a \<Rightarrow> bool) \<Rightarrow> bool"
  where "morphic_prop R P =
           ((P \<one>\<^bsub>R\<^esub>) \<and>
            (\<forall>r \<in> carrier R. P r) \<and>
            (\<forall>r1 \<in> carrier R. \<forall>r2 \<in> carrier R. P (r1 \<otimes>\<^bsub>R\<^esub> r2)) \<and>
            (\<forall>r1 \<in> carrier R. \<forall>r2 \<in> carrier R. P (r1 \<oplus>\<^bsub>R\<^esub> r2)))"

lemma ring_iso_memI:
  fixes R (structure) and S (structure)
  assumes "\<And>x. x \<in> carrier R \<Longrightarrow> h x \<in> carrier S"
      and "\<And>x y. \<lbrakk> x \<in> carrier R; y \<in> carrier R \<rbrakk> \<Longrightarrow> h (x \<otimes> y) = h x \<otimes>\<^bsub>S\<^esub> h y"
      and "\<And>x y. \<lbrakk> x \<in> carrier R; y \<in> carrier R \<rbrakk> \<Longrightarrow> h (x \<oplus> y) = h x \<oplus>\<^bsub>S\<^esub> h y"
      and "h \<one> = \<one>\<^bsub>S\<^esub>"
      and "bij_betw h (carrier R) (carrier S)"
  shows "h \<in> ring_iso R S"
  by (auto simp add: ring_hom_memI assms ring_iso_def)

lemma ring_iso_memE:
  fixes R (structure) and S (structure)
  assumes "h \<in> ring_iso R S"
  shows "\<And>x. x \<in> carrier R \<Longrightarrow> h x \<in> carrier S"
   and "\<And>x y. \<lbrakk> x \<in> carrier R; y \<in> carrier R \<rbrakk> \<Longrightarrow> h (x \<otimes> y) = h x \<otimes>\<^bsub>S\<^esub> h y"
   and "\<And>x y. \<lbrakk> x \<in> carrier R; y \<in> carrier R \<rbrakk> \<Longrightarrow> h (x \<oplus> y) = h x \<oplus>\<^bsub>S\<^esub> h y"
   and "h \<one> = \<one>\<^bsub>S\<^esub>"
   and "bij_betw h (carrier R) (carrier S)"
  using assms unfolding ring_iso_def ring_hom_def by auto

lemma morphic_propI:
  fixes R (structure)
  assumes "P \<one>"
    and "\<And>r. r \<in> carrier R \<Longrightarrow> P r"
    and "\<And>r1 r2. \<lbrakk> r1 \<in> carrier R; r2 \<in> carrier R \<rbrakk> \<Longrightarrow> P (r1 \<otimes> r2)"
    and "\<And>r1 r2. \<lbrakk> r1 \<in> carrier R; r2 \<in> carrier R \<rbrakk> \<Longrightarrow> P (r1 \<oplus> r2)"
  shows "morphic_prop R P"
  unfolding morphic_prop_def using assms by auto

lemma morphic_propE:
  fixes R (structure)
  assumes "morphic_prop R P"
  shows "P \<one>"
    and "\<And>r. r \<in> carrier R \<Longrightarrow> P r"
    and "\<And>r1 r2. \<lbrakk> r1 \<in> carrier R; r2 \<in> carrier R \<rbrakk> \<Longrightarrow> P (r1 \<otimes> r2)"
    and "\<And>r1 r2. \<lbrakk> r1 \<in> carrier R; r2 \<in> carrier R \<rbrakk> \<Longrightarrow> P (r1 \<oplus> r2)"
  using assms unfolding morphic_prop_def by auto

lemma ring_iso_restrict:
  assumes "f \<in> ring_iso R S"
    and "\<And>r. r \<in> carrier R \<Longrightarrow> f r = g r"
    and "ring R"
  shows "g \<in> ring_iso R S"
proof (rule ring_iso_memI)
  show "bij_betw g (carrier R) (carrier S)"
    using assms(1-2) bij_betw_cong ring_iso_memE(5) by blast
  show "g \<one>\<^bsub>R\<^esub> = \<one>\<^bsub>S\<^esub>"
    using assms ring.ring_simprules(6) ring_iso_memE(4) by force
next
  fix x y assume x: "x \<in> carrier R" and y: "y \<in> carrier R"
  show "g x \<in> carrier S"
    using assms(1-2) ring_iso_memE(1) x by fastforce
  show "g (x \<otimes>\<^bsub>R\<^esub> y) = g x \<otimes>\<^bsub>S\<^esub> g y"
    by (metis assms ring.ring_simprules(5) ring_iso_memE(2) x y)
  show "g (x \<oplus>\<^bsub>R\<^esub> y) = g x \<oplus>\<^bsub>S\<^esub> g y"
    by (metis assms ring.ring_simprules(1) ring_iso_memE(3) x y)
qed

lemma ring_iso_morphic_prop:
  assumes "f \<in> ring_iso R S"
    and "morphic_prop R P"
    and "\<And>r. P r \<Longrightarrow> f r = g r"
  shows "g \<in> ring_iso R S"
proof -
  have eq0: "\<And>r. r \<in> carrier R \<Longrightarrow> f r = g r"
   and eq1: "f \<one>\<^bsub>R\<^esub> = g \<one>\<^bsub>R\<^esub>"
   and eq2: "\<And>r1 r2. \<lbrakk> r1 \<in> carrier R; r2 \<in> carrier R \<rbrakk> \<Longrightarrow> f (r1 \<otimes>\<^bsub>R\<^esub> r2) = g (r1 \<otimes>\<^bsub>R\<^esub> r2)"
   and eq3: "\<And>r1 r2. \<lbrakk> r1 \<in> carrier R; r2 \<in> carrier R \<rbrakk> \<Longrightarrow> f (r1 \<oplus>\<^bsub>R\<^esub> r2) = g (r1 \<oplus>\<^bsub>R\<^esub> r2)"
    using assms(2-3) unfolding morphic_prop_def by auto
  show ?thesis
    apply (rule ring_iso_memI)
    using assms(1) eq0 ring_iso_memE(1) apply fastforce
    apply (metis assms(1) eq0 eq2 ring_iso_memE(2))
    apply (metis assms(1) eq0 eq3 ring_iso_memE(3))
    using assms(1) eq1 ring_iso_memE(4) apply fastforce
    using assms(1) bij_betw_cong eq0 ring_iso_memE(5) by blast
qed

lemma (in ring) ring_hom_imp_img_ring:
  assumes "h \<in> ring_hom R S"
  shows "ring (S \<lparr> carrier := h ` (carrier R), one := h \<one>, zero := h \<zero> \<rparr>)" (is "ring ?h_img")
proof -
  have "h \<in> hom (add_monoid R) (add_monoid S)"
    using assms unfolding hom_def ring_hom_def by auto
  hence "comm_group ((add_monoid S) \<lparr>  carrier := h ` (carrier R), one := h \<zero> \<rparr>)"
    using add.hom_imp_img_comm_group[of h "add_monoid S"] by simp
  hence comm_group: "comm_group (add_monoid ?h_img)"
    by (auto intro: comm_monoidI simp add: monoid.defs)

  moreover have "h \<in> hom R S"
    using assms unfolding ring_hom_def hom_def by auto
  hence "monoid (S \<lparr>  carrier := h ` (carrier R), one := h \<one> \<rparr>)"
    using hom_imp_img_monoid[of h S] by simp
  hence monoid: "monoid ?h_img"
    unfolding monoid_def by (simp add: monoid.defs)

  show ?thesis
  proof (rule ringI, simp_all add: comm_group_abelian_groupI[OF comm_group] monoid)
    fix x y z assume "x \<in> h ` carrier R" "y \<in> h ` carrier R" "z \<in> h ` carrier R"
    then obtain r1 r2 r3
      where r1: "r1 \<in> carrier R" "x = h r1"
        and r2: "r2 \<in> carrier R" "y = h r2"
        and r3: "r3 \<in> carrier R" "z = h r3" by blast
    hence "(x \<oplus>\<^bsub>S\<^esub> y) \<otimes>\<^bsub>S\<^esub> z = h ((r1 \<oplus> r2) \<otimes> r3)"
      using ring_hom_memE[OF assms] by auto
    also have " ... = h ((r1 \<otimes> r3) \<oplus> (r2 \<otimes> r3))"
      using l_distr[OF r1(1) r2(1) r3(1)] by simp
    also have " ... = (x \<otimes>\<^bsub>S\<^esub> z) \<oplus>\<^bsub>S\<^esub> (y \<otimes>\<^bsub>S\<^esub> z)"
      using ring_hom_memE[OF assms] r1 r2 r3 by auto
    finally show "(x \<oplus>\<^bsub>S\<^esub> y) \<otimes>\<^bsub>S\<^esub> z = (x \<otimes>\<^bsub>S\<^esub> z) \<oplus>\<^bsub>S\<^esub> (y \<otimes>\<^bsub>S\<^esub> z)" .

    have "z \<otimes>\<^bsub>S\<^esub> (x \<oplus>\<^bsub>S\<^esub> y) = h (r3 \<otimes> (r1 \<oplus> r2))"
      using ring_hom_memE[OF assms] r1 r2 r3 by auto
    also have " ... =  h ((r3 \<otimes> r1) \<oplus> (r3 \<otimes> r2))"
      using r_distr[OF r1(1) r2(1) r3(1)] by simp
    also have " ... = (z \<otimes>\<^bsub>S\<^esub> x) \<oplus>\<^bsub>S\<^esub> (z \<otimes>\<^bsub>S\<^esub> y)"
      using ring_hom_memE[OF assms] r1 r2 r3 by auto
    finally show "z \<otimes>\<^bsub>S\<^esub> (x \<oplus>\<^bsub>S\<^esub> y) = (z \<otimes>\<^bsub>S\<^esub> x) \<oplus>\<^bsub>S\<^esub> (z \<otimes>\<^bsub>S\<^esub> y)" .
  qed
qed

lemma (in ring) ring_iso_imp_img_ring:
  assumes "h \<in> ring_iso R S"
  shows "ring (S \<lparr> one := h \<one>, zero := h \<zero> \<rparr>)"
proof -
  have "ring (S \<lparr> carrier := h ` (carrier R), one := h \<one>, zero := h \<zero> \<rparr>)"
    using ring_hom_imp_img_ring[of h S] assms unfolding ring_iso_def by auto
  moreover have "h ` (carrier R) = carrier S"
    using assms unfolding ring_iso_def bij_betw_def by auto
  ultimately show ?thesis by simp
qed

lemma (in cring) ring_iso_imp_img_cring:
  assumes "h \<in> ring_iso R S"
  shows "cring (S \<lparr> one := h \<one>, zero := h \<zero> \<rparr>)" (is "cring ?h_img")
proof -
  note m_comm
  interpret h_img?: ring ?h_img
    using ring_iso_imp_img_ring[OF assms] .
  show ?thesis 
  proof (unfold_locales)
    fix x y assume "x \<in> carrier ?h_img" "y \<in> carrier ?h_img"
    then obtain r1 r2
      where r1: "r1 \<in> carrier R" "x = h r1"
        and r2: "r2 \<in> carrier R" "y = h r2"
      using assms image_iff[where ?f = h and ?A = "carrier R"]
      unfolding ring_iso_def bij_betw_def by auto
    have "x \<otimes>\<^bsub>(?h_img)\<^esub> y = h (r1 \<otimes> r2)"
      using assms r1 r2 unfolding ring_iso_def ring_hom_def by auto
    also have " ... = h (r2 \<otimes> r1)"
      using m_comm[OF r1(1) r2(1)] by simp
    also have " ... = y \<otimes>\<^bsub>(?h_img)\<^esub> x"
      using assms r1 r2 unfolding ring_iso_def ring_hom_def by auto
    finally show "x \<otimes>\<^bsub>(?h_img)\<^esub> y = y \<otimes>\<^bsub>(?h_img)\<^esub> x" .
  qed
qed

lemma (in domain) ring_iso_imp_img_domain:
  assumes "h \<in> ring_iso R S"
  shows "domain (S \<lparr> one := h \<one>, zero := h \<zero> \<rparr>)" (is "domain ?h_img")
proof -
  note aux = m_closed integral one_not_zero one_closed zero_closed
  interpret h_img?: cring ?h_img
    using ring_iso_imp_img_cring[OF assms] .
  show ?thesis 
  proof (unfold_locales)
    show "\<one>\<^bsub>?h_img\<^esub> \<noteq> \<zero>\<^bsub>?h_img\<^esub>"
      using ring_iso_memE(5)[OF assms] aux(3-4)
      unfolding bij_betw_def inj_on_def by force
  next
    fix a b
    assume A: "a \<otimes>\<^bsub>?h_img\<^esub> b = \<zero>\<^bsub>?h_img\<^esub>" "a \<in> carrier ?h_img" "b \<in> carrier ?h_img"
    then obtain r1 r2
      where r1: "r1 \<in> carrier R" "a = h r1"
        and r2: "r2 \<in> carrier R" "b = h r2"
      using assms image_iff[where ?f = h and ?A = "carrier R"]
      unfolding ring_iso_def bij_betw_def by auto
    hence "a \<otimes>\<^bsub>?h_img\<^esub> b = h (r1 \<otimes> r2)"
      using assms r1 r2 unfolding ring_iso_def ring_hom_def by auto
    hence "h (r1 \<otimes> r2) = h \<zero>"
      using A(1) by simp
    hence "r1 \<otimes> r2 = \<zero>"
      using ring_iso_memE(5)[OF assms] aux(1)[OF r1(1) r2(1)] aux(5)
      unfolding bij_betw_def inj_on_def by force
    hence "r1 = \<zero> \<or> r2 = \<zero>"
      using aux(2)[OF _ r1(1) r2(1)] by simp
    thus "a = \<zero>\<^bsub>?h_img\<^esub> \<or> b = \<zero>\<^bsub>?h_img\<^esub>"
      unfolding r1 r2 by auto
  qed
qed

lemma (in field) ring_iso_imp_img_field:
  assumes "h \<in> ring_iso R S"
  shows "field (S \<lparr> one := h \<one>, zero := h \<zero> \<rparr>)" (is "field ?h_img")
proof -
  interpret h_img?: domain ?h_img
    using ring_iso_imp_img_domain[OF assms] .
  show ?thesis
  proof (unfold_locales, auto simp add: Units_def)
    interpret field R using field_axioms .
    fix a assume a: "a \<in> carrier S" "a \<otimes>\<^bsub>S\<^esub> h \<zero> = h \<one>"
    then obtain r where r: "r \<in> carrier R" "a = h r"
      using assms image_iff[where ?f = h and ?A = "carrier R"]
      unfolding ring_iso_def bij_betw_def by auto
    have "a \<otimes>\<^bsub>S\<^esub> h \<zero> = h (r \<otimes> \<zero>)" unfolding r(2)
      using ring_iso_memE(2)[OF assms r(1)] by simp
    hence "h \<one> = h \<zero>"
      using r(1) a(2) by simp
    thus False
      using ring_iso_memE(5)[OF assms]
      unfolding bij_betw_def inj_on_def by force
  next
    interpret field R using field_axioms .
    fix s assume s: "s \<in> carrier S" "s \<noteq> h \<zero>"
    then obtain r where r: "r \<in> carrier R" "s = h r"
      using assms image_iff[where ?f = h and ?A = "carrier R"]
      unfolding ring_iso_def bij_betw_def by auto
    hence "r \<noteq> \<zero>" using s(2) by auto 
    hence inv_r: "inv r \<in> carrier R" "inv r \<noteq> \<zero>" "r \<otimes> inv r = \<one>" "inv r \<otimes> r = \<one>"
      using field_Units r(1) by auto
    have "h (inv r) \<otimes>\<^bsub>S\<^esub> h r = h \<one>" and "h r \<otimes>\<^bsub>S\<^esub> h (inv r) = h \<one>"
      using ring_iso_memE(2)[OF assms inv_r(1) r(1)] inv_r(3-4)
            ring_iso_memE(2)[OF assms r(1) inv_r(1)] by auto
    thus "\<exists>s' \<in> carrier S. s' \<otimes>\<^bsub>S\<^esub> s = h \<one> \<and> s \<otimes>\<^bsub>S\<^esub> s' = h \<one>"
      using ring_iso_memE(1)[OF assms inv_r(1)] r(2) by auto
  qed
qed

lemma ring_iso_same_card: "R \<simeq> S \<Longrightarrow> card (carrier R) = card (carrier S)"
proof -
  assume "R \<simeq> S"
  then obtain h where "bij_betw h (carrier R) (carrier S)"
    unfolding is_ring_iso_def ring_iso_def by auto
  thus "card (carrier R) = card (carrier S)"
    using bij_betw_same_card[of h "carrier R" "carrier S"] by simp
qed

lemma ring_iso_set_refl: "id \<in> ring_iso R R"
  by (rule ring_iso_memI) (auto)

corollary ring_iso_refl: "R \<simeq> R"
  using is_ring_iso_def ring_iso_set_refl by auto 

lemma ring_iso_set_trans:
  "\<lbrakk> f \<in> ring_iso R S; g \<in> ring_iso S Q \<rbrakk> \<Longrightarrow> (g \<circ> f) \<in> ring_iso R Q"
  unfolding ring_iso_def using bij_betw_trans ring_hom_trans by fastforce 

corollary ring_iso_trans: "\<lbrakk> R \<simeq> S; S \<simeq> Q \<rbrakk> \<Longrightarrow> R \<simeq> Q"
  using ring_iso_set_trans unfolding is_ring_iso_def by blast 

lemma ring_iso_set_sym:
  assumes "ring R" and h: "h \<in> ring_iso R S"
  shows "(inv_into (carrier R) h) \<in> ring_iso S R"
proof -
  have h_hom: "h \<in> ring_hom R S"
    and h_surj: "h ` (carrier R) = (carrier S)"
    and h_inj:  "\<And> x1 x2. \<lbrakk> x1 \<in> carrier R; x2 \<in> carrier R \<rbrakk> \<Longrightarrow>  h x1 = h x2 \<Longrightarrow> x1 = x2"
    using h unfolding ring_iso_def bij_betw_def inj_on_def by auto

  have h_inv_bij: "bij_betw (inv_into (carrier R) h) (carrier S) (carrier R)"
      using bij_betw_inv_into h ring_iso_def by fastforce

  show "inv_into (carrier R) h \<in> ring_iso S R"
    apply (rule ring_iso_memI)
    apply (simp add: h_surj inv_into_into)
       apply (auto simp add: h_inv_bij)
    using ring_iso_memE [OF h] bij_betwE [OF h_inv_bij] 
    apply (simp_all add: \<open>ring R\<close> bij_betw_def bij_betw_inv_into_right inv_into_f_eq ring.ring_simprules(5))
    using ring_iso_memE [OF h] bij_betw_inv_into_right [of h "carrier R" "carrier S"]
    apply (simp add: \<open>ring R\<close> inv_into_f_eq ring.ring_simprules(1))
    by (simp add: \<open>ring R\<close> inv_into_f_eq ring.ring_simprules(6))
qed

corollary ring_iso_sym:
  assumes "ring R"
  shows "R \<simeq> S \<Longrightarrow> S \<simeq> R"
  using assms ring_iso_set_sym unfolding is_ring_iso_def by auto 

lemma (in ring_hom_ring) the_elem_simp [simp]:
  "\<And>x. x \<in> carrier R \<Longrightarrow> the_elem (h ` ((a_kernel R S h) +> x)) = h x"
proof -
  fix x assume x: "x \<in> carrier R"
  hence "h x \<in> h ` ((a_kernel R S h) +> x)"
    using homeq_imp_rcos by blast
  thus "the_elem (h ` ((a_kernel R S h) +> x)) = h x"
    by (metis (no_types, lifting) x empty_iff homeq_imp_rcos rcos_imp_homeq the_elem_image_unique)
qed

lemma (in ring_hom_ring) the_elem_inj:
  "\<And>X Y. \<lbrakk> X \<in> carrier (R Quot (a_kernel R S h)); Y \<in> carrier (R Quot (a_kernel R S h)) \<rbrakk> \<Longrightarrow>
           the_elem (h ` X) = the_elem (h ` Y) \<Longrightarrow> X = Y"
proof -
  fix X Y
  assume "X \<in> carrier (R Quot (a_kernel R S h))"
     and "Y \<in> carrier (R Quot (a_kernel R S h))"
     and Eq: "the_elem (h ` X) = the_elem (h ` Y)"
  then obtain x y where x: "x \<in> carrier R" "X = (a_kernel R S h) +> x"
                    and y: "y \<in> carrier R" "Y = (a_kernel R S h) +> y"
    unfolding FactRing_def A_RCOSETS_def' by auto
  hence "h x = h y" using Eq by simp
  hence "x \<ominus> y \<in> (a_kernel R S h)"
    by (simp add: a_minus_def abelian_subgroup.a_rcos_module_imp
                  abelian_subgroup_a_kernel homeq_imp_rcos x(1) y(1))
  thus "X = Y"
    by (metis R.a_coset_add_inv1 R.minus_eq abelian_subgroup.a_rcos_const
        abelian_subgroup_a_kernel additive_subgroup.a_subset additive_subgroup_a_kernel x y)
qed

lemma (in ring_hom_ring) quot_mem:
  "\<And>X. X \<in> carrier (R Quot (a_kernel R S h)) \<Longrightarrow> \<exists>x \<in> carrier R. X = (a_kernel R S h) +> x"
proof -
  fix X assume "X \<in> carrier (R Quot (a_kernel R S h))"
  thus "\<exists>x \<in> carrier R. X = (a_kernel R S h) +> x"
    unfolding FactRing_def RCOSETS_def A_RCOSETS_def by (simp add: a_r_coset_def)
qed

lemma (in ring_hom_ring) the_elem_wf:
  "\<And>X. X \<in> carrier (R Quot (a_kernel R S h)) \<Longrightarrow> \<exists>y \<in> carrier S. (h ` X) = { y }"
proof -
  fix X assume "X \<in> carrier (R Quot (a_kernel R S h))"
  then obtain x where x: "x \<in> carrier R" and X: "X = (a_kernel R S h) +> x"
    using quot_mem by blast
  hence "\<And>x'. x' \<in> X \<Longrightarrow> h x' = h x"
  proof -
    fix x' assume "x' \<in> X" hence "x' \<in> (a_kernel R S h) +> x" using X by simp
    then obtain k where k: "k \<in> a_kernel R S h" "x' = k \<oplus> x"
      by (metis R.add.inv_closed R.add.m_assoc R.l_neg R.r_zero
          abelian_subgroup.a_elemrcos_carrier
          abelian_subgroup.a_rcos_module_imp abelian_subgroup_a_kernel x)
    hence "h x' = h k \<oplus>\<^bsub>S\<^esub> h x"
      by (meson additive_subgroup.a_Hcarr additive_subgroup_a_kernel hom_add x)
    also have " ... =  h x"
      using k by (auto simp add: x)
    finally show "h x' = h x" .
  qed
  moreover have "h x \<in> h ` X"
    by (simp add: X homeq_imp_rcos x)
  ultimately have "(h ` X) = { h x }"
    by blast
  thus "\<exists>y \<in> carrier S. (h ` X) = { y }" using x by simp
qed

corollary (in ring_hom_ring) the_elem_wf':
  "\<And>X. X \<in> carrier (R Quot (a_kernel R S h)) \<Longrightarrow> \<exists>r \<in> carrier R. (h ` X) = { h r }"
  using the_elem_wf by (metis quot_mem the_elem_eq the_elem_simp) 

lemma (in ring_hom_ring) the_elem_hom:
  "(\<lambda>X. the_elem (h ` X)) \<in> ring_hom (R Quot (a_kernel R S h)) S"
proof (rule ring_hom_memI)
  show "\<And>x. x \<in> carrier (R Quot a_kernel R S h) \<Longrightarrow> the_elem (h ` x) \<in> carrier S"
    using the_elem_wf by fastforce
  
  show "the_elem (h ` \<one>\<^bsub>R Quot a_kernel R S h\<^esub>) = \<one>\<^bsub>S\<^esub>"
    unfolding FactRing_def  using the_elem_simp[of "\<one>\<^bsub>R\<^esub>"] by simp

  fix X Y
  assume "X \<in> carrier (R Quot a_kernel R S h)"
     and "Y \<in> carrier (R Quot a_kernel R S h)"
  then obtain x y where x: "x \<in> carrier R" "X = (a_kernel R S h) +> x"
                    and y: "y \<in> carrier R" "Y = (a_kernel R S h) +> y"
    using quot_mem by blast

  have "X \<otimes>\<^bsub>R Quot a_kernel R S h\<^esub> Y = (a_kernel R S h) +> (x \<otimes> y)"
    by (simp add: FactRing_def ideal.rcoset_mult_add kernel_is_ideal x y)
  thus "the_elem (h ` (X \<otimes>\<^bsub>R Quot a_kernel R S h\<^esub> Y)) = the_elem (h ` X) \<otimes>\<^bsub>S\<^esub> the_elem (h ` Y)"
    by (simp add: x y)

  have "X \<oplus>\<^bsub>R Quot a_kernel R S h\<^esub> Y = (a_kernel R S h) +> (x \<oplus> y)"
    using ideal.rcos_ring_hom kernel_is_ideal ring_hom_add x y by fastforce
  thus "the_elem (h ` (X \<oplus>\<^bsub>R Quot a_kernel R S h\<^esub> Y)) = the_elem (h ` X) \<oplus>\<^bsub>S\<^esub> the_elem (h ` Y)"
    by (simp add: x y)
qed

lemma (in ring_hom_ring) the_elem_surj:
    "(\<lambda>X. (the_elem (h ` X))) ` carrier (R Quot (a_kernel R S h)) = (h ` (carrier R))"
proof
  show "(\<lambda>X. the_elem (h ` X)) ` carrier (R Quot a_kernel R S h) \<subseteq> h ` carrier R"
    using the_elem_wf' by fastforce
next
  show "h ` carrier R \<subseteq> (\<lambda>X. the_elem (h ` X)) ` carrier (R Quot a_kernel R S h)"
  proof
    fix y assume "y \<in> h ` carrier R"
    then obtain x where x: "x \<in> carrier R" "h x = y"
      by (metis image_iff)
    hence "the_elem (h ` ((a_kernel R S h) +> x)) = y" by simp
    moreover have "(a_kernel R S h) +> x \<in> carrier (R Quot (a_kernel R S h))"
     unfolding FactRing_def RCOSETS_def A_RCOSETS_def by (auto simp add: x a_r_coset_def)
    ultimately show "y \<in> (\<lambda>X. (the_elem (h ` X))) ` carrier (R Quot (a_kernel R S h))" by blast
  qed
qed

proposition (in ring_hom_ring) FactRing_iso_set_aux:
  "(\<lambda>X. the_elem (h ` X)) \<in> ring_iso (R Quot (a_kernel R S h)) (S \<lparr> carrier := h ` (carrier R) \<rparr>)"
proof -
  have "bij_betw (\<lambda>X. the_elem (h ` X)) (carrier (R Quot a_kernel R S h)) (h ` (carrier R))"
    unfolding bij_betw_def inj_on_def using the_elem_surj the_elem_inj by simp

  moreover
  have "(\<lambda>X. the_elem (h ` X)): carrier (R Quot (a_kernel R S h)) \<rightarrow> h ` (carrier R)"
    using the_elem_wf' by fastforce
  hence "(\<lambda>X. the_elem (h ` X)) \<in> ring_hom (R Quot (a_kernel R S h)) (S \<lparr> carrier := h ` (carrier R) \<rparr>)"
    using the_elem_hom the_elem_wf' unfolding ring_hom_def by simp

  ultimately show ?thesis unfolding ring_iso_def using the_elem_hom by simp
qed

theorem (in ring_hom_ring) FactRing_iso_set:
  assumes "h ` carrier R = carrier S"
  shows "(\<lambda>X. the_elem (h ` X)) \<in> ring_iso (R Quot (a_kernel R S h)) S"
  using FactRing_iso_set_aux assms by auto

corollary (in ring_hom_ring) FactRing_iso:
  assumes "h ` carrier R = carrier S"
  shows "R Quot (a_kernel R S h) \<simeq> S"
  using FactRing_iso_set assms is_ring_iso_def by auto

corollary (in ring) FactRing_zeroideal:
  shows "R Quot { \<zero> } \<simeq> R" and "R \<simeq> R Quot { \<zero> }"
proof -
  have "ring_hom_ring R R id"
    using ring_axioms by (auto intro: ring_hom_ringI)
  moreover have "a_kernel R R id = { \<zero> }"
    unfolding a_kernel_def' by auto
  ultimately show "R Quot { \<zero> } \<simeq> R" and "R \<simeq> R Quot { \<zero> }"
    using ring_hom_ring.FactRing_iso[of R R id]
          ring_iso_sym[OF ideal.quotient_is_ring[OF zeroideal], of R] by auto
qed

lemma (in ring_hom_ring) img_is_ring: "ring (S \<lparr> carrier := h ` (carrier R) \<rparr>)"
proof -
  let ?the_elem = "\<lambda>X. the_elem (h ` X)"
  have FactRing_is_ring: "ring (R Quot (a_kernel R S h))"
    by (simp add: ideal.quotient_is_ring kernel_is_ideal)
  have "ring ((S \<lparr> carrier := ?the_elem ` (carrier (R Quot (a_kernel R S h))) \<rparr>)
                 \<lparr>     one := ?the_elem \<one>\<^bsub>(R Quot (a_kernel R S h))\<^esub>,
                      zero := ?the_elem \<zero>\<^bsub>(R Quot (a_kernel R S h))\<^esub> \<rparr>)"
    using ring.ring_iso_imp_img_ring[OF FactRing_is_ring, of ?the_elem
          "S \<lparr> carrier := ?the_elem ` (carrier (R Quot (a_kernel R S h))) \<rparr>"]
          FactRing_iso_set_aux the_elem_surj by auto

  moreover
  have "\<zero> \<in> (a_kernel R S h)"
    using a_kernel_def'[of R S h] by auto
  hence "\<one> \<in> (a_kernel R S h) +> \<one>"
    using a_r_coset_def'[of R "a_kernel R S h" \<one>] by force
  hence "\<one>\<^bsub>S\<^esub> \<in> (h ` ((a_kernel R S h) +> \<one>))"
    using hom_one by force
  hence "?the_elem \<one>\<^bsub>(R Quot (a_kernel R S h))\<^esub> = \<one>\<^bsub>S\<^esub>"
    using the_elem_wf[of "(a_kernel R S h) +> \<one>"] by (simp add: FactRing_def)
  
  moreover
  have "\<zero>\<^bsub>S\<^esub> \<in> (h ` (a_kernel R S h))"
    using a_kernel_def'[of R S h] hom_zero by force
  hence "\<zero>\<^bsub>S\<^esub> \<in> (h ` \<zero>\<^bsub>(R Quot (a_kernel R S h))\<^esub>)"
    by (simp add: FactRing_def)
  hence "?the_elem \<zero>\<^bsub>(R Quot (a_kernel R S h))\<^esub> = \<zero>\<^bsub>S\<^esub>"
    using the_elem_wf[OF ring.ring_simprules(2)[OF FactRing_is_ring]]
    by (metis singletonD the_elem_eq) 

  ultimately
  have "ring ((S \<lparr> carrier := h ` (carrier R) \<rparr>) \<lparr> one := \<one>\<^bsub>S\<^esub>, zero := \<zero>\<^bsub>S\<^esub> \<rparr>)"
    using the_elem_surj by simp
  thus ?thesis
    by auto
qed

lemma (in ring_hom_ring) img_is_cring:
  assumes "cring S"
  shows "cring (S \<lparr> carrier := h ` (carrier R) \<rparr>)"
proof -
  interpret ring "S \<lparr> carrier := h ` (carrier R) \<rparr>"
    using img_is_ring .
  show ?thesis
    apply unfold_locales
    using assms unfolding cring_def comm_monoid_def comm_monoid_axioms_def by auto
qed

lemma (in ring_hom_ring) img_is_domain:
  assumes "domain S"
  shows "domain (S \<lparr> carrier := h ` (carrier R) \<rparr>)"
proof -
  interpret cring "S \<lparr> carrier := h ` (carrier R) \<rparr>"
    using img_is_cring assms unfolding domain_def by simp
  show ?thesis
    apply unfold_locales
    using assms unfolding domain_def domain_axioms_def apply auto
    using hom_closed by blast 
qed

proposition (in ring_hom_ring) primeideal_vimage:
  assumes "cring R"
  shows "primeideal P S \<Longrightarrow> primeideal { r \<in> carrier R. h r \<in> P } R"
proof -
  assume A: "primeideal P S"
  hence is_ideal: "ideal P S" unfolding primeideal_def by simp
  have "ring_hom_ring R (S Quot P) (((+>\<^bsub>S\<^esub>) P) \<circ> h)" (is "ring_hom_ring ?A ?B ?h")
    using ring_hom_trans[OF homh, of "(+>\<^bsub>S\<^esub>) P" "S Quot P"]
          ideal.rcos_ring_hom_ring[OF is_ideal] assms
    unfolding ring_hom_ring_def ring_hom_ring_axioms_def cring_def by simp
  then interpret hom: ring_hom_ring R "S Quot P" "((+>\<^bsub>S\<^esub>) P) \<circ> h" by simp
  
  have "inj_on (\<lambda>X. the_elem (?h ` X)) (carrier (R Quot (a_kernel R (S Quot P) ?h)))"
    using hom.the_elem_inj unfolding inj_on_def by simp
  moreover
  have "ideal (a_kernel R (S Quot P) ?h) R"
    using hom.kernel_is_ideal by auto
  have hom': "ring_hom_ring (R Quot (a_kernel R (S Quot P) ?h)) (S Quot P) (\<lambda>X. the_elem (?h ` X))"
    using hom.the_elem_hom hom.kernel_is_ideal
    by (meson hom.ring_hom_ring_axioms ideal.rcos_ring_hom_ring ring_hom_ring_axioms_def ring_hom_ring_def)
  
  ultimately
  have "primeideal (a_kernel R (S Quot P) ?h) R"
    using ring_hom_ring.inj_on_domain[OF hom'] primeideal.quotient_is_domain[OF A]
          cring.quot_domain_imp_primeideal[OF assms hom.kernel_is_ideal] by simp
  
  moreover have "a_kernel R (S Quot P) ?h = { r \<in> carrier R. h r \<in> P }"
  proof
    show "a_kernel R (S Quot P) ?h \<subseteq> { r \<in> carrier R. h r \<in> P }"
    proof 
      fix r assume "r \<in> a_kernel R (S Quot P) ?h"
      hence r: "r \<in> carrier R" "P +>\<^bsub>S\<^esub> (h r) = P"
        unfolding a_kernel_def kernel_def FactRing_def by auto
      hence "h r \<in> P"
        using S.a_rcosI R.l_zero S.l_zero additive_subgroup.a_subset[OF ideal.axioms(1)[OF is_ideal]]
              additive_subgroup.zero_closed[OF ideal.axioms(1)[OF is_ideal]] hom_closed by metis
      thus "r \<in> { r \<in> carrier R. h r \<in> P }" using r by simp
    qed
  next
    show "{ r \<in> carrier R. h r \<in> P } \<subseteq> a_kernel R (S Quot P) ?h"
    proof
      fix r assume "r \<in> { r \<in> carrier R. h r \<in> P }"
      hence r: "r \<in> carrier R" "h r \<in> P" by simp_all
      hence "?h r = P"
        by (simp add: S.a_coset_join2 additive_subgroup.a_subgroup ideal.axioms(1) is_ideal)
      thus "r \<in> a_kernel R (S Quot P) ?h"
        unfolding a_kernel_def kernel_def FactRing_def using r(1) by auto
    qed
  qed
  ultimately show "primeideal { r \<in> carrier R. h r \<in> P } R" by simp
qed

end

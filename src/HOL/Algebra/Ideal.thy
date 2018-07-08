(*  Title:      HOL/Algebra/Ideal.thy
    Author:     Stephan Hohe, TU Muenchen
*)

theory Ideal
imports Ring AbelCoset
begin

section \<open>Ideals\<close>

subsection \<open>Definitions\<close>

subsubsection \<open>General definition\<close>

locale ideal = additive_subgroup I R + ring R for I and R (structure) +
  assumes I_l_closed: "\<lbrakk>a \<in> I; x \<in> carrier R\<rbrakk> \<Longrightarrow> x \<otimes> a \<in> I"
      and I_r_closed: "\<lbrakk>a \<in> I; x \<in> carrier R\<rbrakk> \<Longrightarrow> a \<otimes> x \<in> I"

sublocale ideal \<subseteq> abelian_subgroup I R
proof (intro abelian_subgroupI3 abelian_group.intro)
  show "additive_subgroup I R"
    by (simp add: is_additive_subgroup)
  show "abelian_monoid R"
    by (simp add: abelian_monoid_axioms)
  show "abelian_group_axioms R"
    using abelian_group_def is_abelian_group by blast
qed

lemma (in ideal) is_ideal: "ideal I R"
  by (rule ideal_axioms)

lemma idealI:
  fixes R (structure)
  assumes "ring R"
  assumes a_subgroup: "subgroup I (add_monoid R)"
    and I_l_closed: "\<And>a x. \<lbrakk>a \<in> I; x \<in> carrier R\<rbrakk> \<Longrightarrow> x \<otimes> a \<in> I"
    and I_r_closed: "\<And>a x. \<lbrakk>a \<in> I; x \<in> carrier R\<rbrakk> \<Longrightarrow> a \<otimes> x \<in> I"
  shows "ideal I R"
proof -
  interpret ring R by fact
  show ?thesis  
    by (auto simp: ideal.intro ideal_axioms.intro additive_subgroupI a_subgroup is_ring I_l_closed I_r_closed)
qed


subsubsection (in ring) \<open>Ideals Generated by a Subset of @{term "carrier R"}\<close>

definition genideal :: "_ \<Rightarrow> 'a set \<Rightarrow> 'a set"  ("Idl\<index> _" [80] 79)
  where "genideal R S = \<Inter>{I. ideal I R \<and> S \<subseteq> I}"

subsubsection \<open>Principal Ideals\<close>

locale principalideal = ideal +
  assumes generate: "\<exists>i \<in> carrier R. I = Idl {i}"

lemma (in principalideal) is_principalideal: "principalideal I R"
  by (rule principalideal_axioms)

lemma principalidealI:
  fixes R (structure)
  assumes "ideal I R"
    and generate: "\<exists>i \<in> carrier R. I = Idl {i}"
  shows "principalideal I R"
proof -
  interpret ideal I R by fact
  show ?thesis
    by (intro principalideal.intro principalideal_axioms.intro)
      (rule is_ideal, rule generate)
qed


subsubsection \<open>Maximal Ideals\<close>

locale maximalideal = ideal +
  assumes I_notcarr: "carrier R \<noteq> I"
    and I_maximal: "\<lbrakk>ideal J R; I \<subseteq> J; J \<subseteq> carrier R\<rbrakk> \<Longrightarrow> (J = I) \<or> (J = carrier R)"

lemma (in maximalideal) is_maximalideal: "maximalideal I R"
  by (rule maximalideal_axioms)

lemma maximalidealI:
  fixes R
  assumes "ideal I R"
    and I_notcarr: "carrier R \<noteq> I"
    and I_maximal: "\<And>J. \<lbrakk>ideal J R; I \<subseteq> J; J \<subseteq> carrier R\<rbrakk> \<Longrightarrow> (J = I) \<or> (J = carrier R)"
  shows "maximalideal I R"
proof -
  interpret ideal I R by fact
  show ?thesis
    by (intro maximalideal.intro maximalideal_axioms.intro)
      (rule is_ideal, rule I_notcarr, rule I_maximal)
qed


subsubsection \<open>Prime Ideals\<close>

locale primeideal = ideal + cring +
  assumes I_notcarr: "carrier R \<noteq> I"
    and I_prime: "\<lbrakk>a \<in> carrier R; b \<in> carrier R; a \<otimes> b \<in> I\<rbrakk> \<Longrightarrow> a \<in> I \<or> b \<in> I"

lemma (in primeideal) primeideal: "primeideal I R"
  by (rule primeideal_axioms)

lemma primeidealI:
  fixes R (structure)
  assumes "ideal I R"
    and "cring R"
    and I_notcarr: "carrier R \<noteq> I"
    and I_prime: "\<And>a b. \<lbrakk>a \<in> carrier R; b \<in> carrier R; a \<otimes> b \<in> I\<rbrakk> \<Longrightarrow> a \<in> I \<or> b \<in> I"
  shows "primeideal I R"
proof -
  interpret ideal I R by fact
  interpret cring R by fact
  show ?thesis
    by (intro primeideal.intro primeideal_axioms.intro)
      (rule is_ideal, rule is_cring, rule I_notcarr, rule I_prime)
qed

lemma primeidealI2:
  fixes R (structure)
  assumes "additive_subgroup I R"
    and "cring R"
    and I_l_closed: "\<And>a x. \<lbrakk>a \<in> I; x \<in> carrier R\<rbrakk> \<Longrightarrow> x \<otimes> a \<in> I"
    and I_r_closed: "\<And>a x. \<lbrakk>a \<in> I; x \<in> carrier R\<rbrakk> \<Longrightarrow> a \<otimes> x \<in> I"
    and I_notcarr: "carrier R \<noteq> I"
    and I_prime: "\<And>a b. \<lbrakk>a \<in> carrier R; b \<in> carrier R; a \<otimes> b \<in> I\<rbrakk> \<Longrightarrow> a \<in> I \<or> b \<in> I"
  shows "primeideal I R"
proof -
  interpret additive_subgroup I R by fact
  interpret cring R by fact
  show ?thesis apply intro_locales
    apply (intro ideal_axioms.intro)
    apply (erule (1) I_l_closed)
    apply (erule (1) I_r_closed)
    by (simp add: I_notcarr I_prime primeideal_axioms.intro)
qed


subsection \<open>Special Ideals\<close>

lemma (in ring) zeroideal: "ideal {\<zero>} R"
  by (intro idealI subgroup.intro) (simp_all add: is_ring)

lemma (in ring) oneideal: "ideal (carrier R) R"
  by (rule idealI) (auto intro: is_ring add.subgroupI)

lemma (in "domain") zeroprimeideal: "primeideal {\<zero>} R"
proof -
  have "carrier R \<noteq> {\<zero>}"
    by (simp add: carrier_one_not_zero)
  then show ?thesis
    by (metis (no_types, lifting) domain_axioms domain_def integral primeidealI singleton_iff zeroideal)
qed


subsection \<open>General Ideal Properies\<close>

lemma (in ideal) one_imp_carrier:
  assumes I_one_closed: "\<one> \<in> I"
  shows "I = carrier R"
proof
  show "carrier R \<subseteq> I"
    using I_r_closed assms by fastforce
  show "I \<subseteq> carrier R"
    by (rule a_subset)
qed

lemma (in ideal) Icarr:
  assumes iI: "i \<in> I"
  shows "i \<in> carrier R"
  using iI by (rule a_Hcarr)


subsection \<open>Intersection of Ideals\<close>

paragraph \<open>Intersection of two ideals\<close>
text \<open>The intersection of any two ideals is again an ideal in @{term R}\<close>

lemma (in ring) i_intersect:
  assumes "ideal I R"
  assumes "ideal J R"
  shows "ideal (I \<inter> J) R"
proof -
  interpret ideal I R by fact
  interpret ideal J R by fact
  have IJ: "I \<inter> J \<subseteq> carrier R"
    by (force simp: a_subset)
  show ?thesis
    apply (intro idealI subgroup.intro)
    apply (simp_all add: IJ is_ring I_l_closed assms ideal.I_l_closed ideal.I_r_closed flip: a_inv_def)
    done
qed

text \<open>The intersection of any Number of Ideals is again an Ideal in @{term R}\<close>

lemma (in ring) i_Intersect:
  assumes Sideals: "\<And>I. I \<in> S \<Longrightarrow> ideal I R" and notempty: "S \<noteq> {}"
  shows "ideal (\<Inter>S) R"
proof -
  { fix x y J
    assume "\<forall>I\<in>S. x \<in> I" "\<forall>I\<in>S. y \<in> I" and JS: "J \<in> S"
    interpret ideal J R by (rule Sideals[OF JS])
    have "x \<oplus> y \<in> J"
      by (simp add: JS \<open>\<forall>I\<in>S. x \<in> I\<close> \<open>\<forall>I\<in>S. y \<in> I\<close>) }
  moreover
    have "\<zero> \<in> J" if "J \<in> S" for J
      by (simp add: that Sideals additive_subgroup.zero_closed ideal.axioms(1)) 
  moreover
  { fix x J
    assume "\<forall>I\<in>S. x \<in> I" and JS: "J \<in> S"
    interpret ideal J R by (rule Sideals[OF JS])
    have "\<ominus> x \<in> J"
      by (simp add: JS \<open>\<forall>I\<in>S. x \<in> I\<close>) }
  moreover
  { fix x y J
    assume "\<forall>I\<in>S. x \<in> I" and ycarr: "y \<in> carrier R" and JS: "J \<in> S"
    interpret ideal J R by (rule Sideals[OF JS])
    have "y \<otimes> x \<in> J" "x \<otimes> y \<in> J" 
      using I_l_closed I_r_closed JS \<open>\<forall>I\<in>S. x \<in> I\<close> ycarr by blast+ }
  moreover
  { fix x
    assume "\<forall>I\<in>S. x \<in> I"
    obtain I0 where I0S: "I0 \<in> S"
      using notempty by blast
    interpret ideal I0 R by (rule Sideals[OF I0S])
    have "x \<in> I0"
      by (simp add: I0S \<open>\<forall>I\<in>S. x \<in> I\<close>) 
    with a_subset have "x \<in> carrier R" by fast }
  ultimately show ?thesis
    by unfold_locales (auto simp: Inter_eq simp flip: a_inv_def)
qed


subsection \<open>Addition of Ideals\<close>

lemma (in ring) add_ideals:
  assumes idealI: "ideal I R" and idealJ: "ideal J R"
  shows "ideal (I <+> J) R"
proof (rule ideal.intro)
  show "additive_subgroup (I <+> J) R"
    by (intro ideal.axioms[OF idealI] ideal.axioms[OF idealJ] add_additive_subgroups)
  show "ring R"
    by (rule is_ring)
  show "ideal_axioms (I <+> J) R"
  proof -
    { fix x i j
      assume xcarr: "x \<in> carrier R" and iI: "i \<in> I" and jJ: "j \<in> J"
      from xcarr ideal.Icarr[OF idealI iI] ideal.Icarr[OF idealJ jJ]
      have "\<exists>h\<in>I. \<exists>k\<in>J. (i \<oplus> j) \<otimes> x = h \<oplus> k"
        by (meson iI ideal.I_r_closed idealJ jJ l_distr local.idealI) }
    moreover
    { fix x i j
      assume xcarr: "x \<in> carrier R" and iI: "i \<in> I" and jJ: "j \<in> J"
      from xcarr ideal.Icarr[OF idealI iI] ideal.Icarr[OF idealJ jJ]
      have "\<exists>h\<in>I. \<exists>k\<in>J. x \<otimes> (i \<oplus> j) = h \<oplus> k"
        by (meson iI ideal.I_l_closed idealJ jJ local.idealI r_distr) }
    ultimately show "ideal_axioms (I <+> J) R"
      by (intro ideal_axioms.intro) (auto simp: set_add_defs)
  qed
qed

subsection (in ring) \<open>Ideals generated by a subset of @{term "carrier R"}\<close>

text \<open>@{term genideal} generates an ideal\<close>
lemma (in ring) genideal_ideal:
  assumes Scarr: "S \<subseteq> carrier R"
  shows "ideal (Idl S) R"
unfolding genideal_def
proof (rule i_Intersect, fast, simp)
  from oneideal and Scarr
  show "\<exists>I. ideal I R \<and> S \<le> I" by fast
qed

lemma (in ring) genideal_self:
  assumes "S \<subseteq> carrier R"
  shows "S \<subseteq> Idl S"
  unfolding genideal_def by fast

lemma (in ring) genideal_self':
  assumes carr: "i \<in> carrier R"
  shows "i \<in> Idl {i}"
  by (simp add: genideal_def)

text \<open>@{term genideal} generates the minimal ideal\<close>
lemma (in ring) genideal_minimal:
  assumes "ideal I R" "S \<subseteq> I"
  shows "Idl S \<subseteq> I"
  unfolding genideal_def by rule (elim InterD, simp add: assms)

text \<open>Generated ideals and subsets\<close>
lemma (in ring) Idl_subset_ideal:
  assumes Iideal: "ideal I R"
    and Hcarr: "H \<subseteq> carrier R"
  shows "(Idl H \<subseteq> I) = (H \<subseteq> I)"
proof
  assume a: "Idl H \<subseteq> I"
  from Hcarr have "H \<subseteq> Idl H" by (rule genideal_self)
  with a show "H \<subseteq> I" by simp
next
  fix x
  assume "H \<subseteq> I"
  with Iideal have "I \<in> {I. ideal I R \<and> H \<subseteq> I}" by fast
  then show "Idl H \<subseteq> I" unfolding genideal_def by fast
qed

lemma (in ring) subset_Idl_subset:
  assumes Icarr: "I \<subseteq> carrier R"
    and HI: "H \<subseteq> I"
  shows "Idl H \<subseteq> Idl I"
proof -
  from Icarr have Iideal: "ideal (Idl I) R"
    by (rule genideal_ideal)
  from HI and Icarr have "H \<subseteq> carrier R"
    by fast
  with Iideal have "(H \<subseteq> Idl I) = (Idl H \<subseteq> Idl I)"
    by (rule Idl_subset_ideal[symmetric])
  then show "Idl H \<subseteq> Idl I"
    by (meson HI Icarr genideal_self order_trans)
qed

lemma (in ring) Idl_subset_ideal':
  assumes acarr: "a \<in> carrier R" and bcarr: "b \<in> carrier R"
  shows "Idl {a} \<subseteq> Idl {b} \<longleftrightarrow> a \<in> Idl {b}"
proof -
  have "Idl {a} \<subseteq> Idl {b} \<longleftrightarrow> {a} \<subseteq> Idl {b}"
    by (simp add: Idl_subset_ideal acarr bcarr genideal_ideal)
  also have "\<dots> \<longleftrightarrow> a \<in> Idl {b}"
    by blast
  finally show ?thesis .
qed

lemma (in ring) genideal_zero: "Idl {\<zero>} = {\<zero>}"
proof
  show "Idl {\<zero>} \<subseteq> {\<zero>}"
    by (simp add: genideal_minimal zeroideal)
  show "{\<zero>} \<subseteq> Idl {\<zero>}"
    by (simp add: genideal_self')
qed

lemma (in ring) genideal_one: "Idl {\<one>} = carrier R"
proof -
  interpret ideal "Idl {\<one>}" "R" by (rule genideal_ideal) fast
  show "Idl {\<one>} = carrier R"
    using genideal_self' one_imp_carrier by blast
qed


text \<open>Generation of Principal Ideals in Commutative Rings\<close>

definition cgenideal :: "_ \<Rightarrow> 'a \<Rightarrow> 'a set"  ("PIdl\<index> _" [80] 79)
  where "cgenideal R a \<equiv> {x \<otimes>\<^bsub>R\<^esub> a | x. x \<in> carrier R}"

lemma cginideal_def': "cgenideal R a = (\<lambda>x. x \<otimes>\<^bsub>R\<^esub> a) ` carrier R"
  by (auto simp add: cgenideal_def)

text \<open>genhideal (?) really generates an ideal\<close>
lemma (in cring) cgenideal_ideal:
  assumes acarr: "a \<in> carrier R"
  shows "ideal (PIdl a) R"
  unfolding cgenideal_def
proof (intro subgroup.intro idealI[OF is_ring], simp_all)
  show "{x \<otimes> a |x. x \<in> carrier R} \<subseteq> carrier R"
    by (blast intro: acarr)
  show "\<And>x y. \<lbrakk>\<exists>u. x = u \<otimes> a \<and> u \<in> carrier R; \<exists>x. y = x \<otimes> a \<and> x \<in> carrier R\<rbrakk>
              \<Longrightarrow> \<exists>v. x \<oplus> y = v \<otimes> a \<and> v \<in> carrier R"
    by (metis assms cring.cring_simprules(1) is_cring l_distr)
  show "\<exists>x. \<zero> = x \<otimes> a \<and> x \<in> carrier R"
    by (metis assms l_null zero_closed)
  show "\<And>x. \<exists>u. x = u \<otimes> a \<and> u \<in> carrier R 
            \<Longrightarrow> \<exists>v. inv\<^bsub>add_monoid R\<^esub> x = v \<otimes> a \<and> v \<in> carrier R"
    by (metis a_inv_def add.inv_closed assms l_minus)
  show "\<And>b x. \<lbrakk>\<exists>x. b = x \<otimes> a \<and> x \<in> carrier R; x \<in> carrier R\<rbrakk>
       \<Longrightarrow> \<exists>z. x \<otimes> b = z \<otimes> a \<and> z \<in> carrier R"
    by (metis assms m_assoc m_closed)
  show "\<And>b x. \<lbrakk>\<exists>x. b = x \<otimes> a \<and> x \<in> carrier R; x \<in> carrier R\<rbrakk>
       \<Longrightarrow> \<exists>z. b \<otimes> x = z \<otimes> a \<and> z \<in> carrier R"
    by (metis assms m_assoc m_comm m_closed)
qed

lemma (in ring) cgenideal_self:
  assumes icarr: "i \<in> carrier R"
  shows "i \<in> PIdl i"
  unfolding cgenideal_def
proof simp
  from icarr have "i = \<one> \<otimes> i"
    by simp
  with icarr show "\<exists>x. i = x \<otimes> i \<and> x \<in> carrier R"
    by fast
qed

text \<open>@{const "cgenideal"} is minimal\<close>

lemma (in ring) cgenideal_minimal:
  assumes "ideal J R"
  assumes aJ: "a \<in> J"
  shows "PIdl a \<subseteq> J"
proof -
  interpret ideal J R by fact
  show ?thesis
    unfolding cgenideal_def
    using I_l_closed aJ by blast
qed

lemma (in cring) cgenideal_eq_genideal:
  assumes icarr: "i \<in> carrier R"
  shows "PIdl i = Idl {i}"
proof
  show "PIdl i \<subseteq> Idl {i}"
    by (simp add: cgenideal_minimal genideal_ideal genideal_self' icarr)
  show "Idl {i} \<subseteq> PIdl i"
    by (simp add: cgenideal_ideal cgenideal_self genideal_minimal icarr)
qed

lemma (in cring) cgenideal_eq_rcos: "PIdl i = carrier R #> i"
  unfolding cgenideal_def r_coset_def by fast

lemma (in cring) cgenideal_is_principalideal:
  assumes "i \<in> carrier R"
  shows "principalideal (PIdl i) R"
proof -
  have "\<exists>i'\<in>carrier R. PIdl i = Idl {i'}"
    using cgenideal_eq_genideal assms by auto
  then show ?thesis
    by (simp add: cgenideal_ideal assms principalidealI)
qed


subsection \<open>Union of Ideals\<close>

lemma (in ring) union_genideal:
  assumes idealI: "ideal I R" and idealJ: "ideal J R"
  shows "Idl (I \<union> J) = I <+> J"
proof
  show "Idl (I \<union> J) \<subseteq> I <+> J"
  proof (rule ring.genideal_minimal [OF is_ring])
    show "ideal (I <+> J) R"
      by (rule add_ideals[OF idealI idealJ])
    have "\<And>x. x \<in> I \<Longrightarrow> \<exists>xa\<in>I. \<exists>xb\<in>J. x = xa \<oplus> xb"
      by (metis additive_subgroup.zero_closed ideal.Icarr idealJ ideal_def local.idealI r_zero)
    moreover have "\<And>x. x \<in> J \<Longrightarrow> \<exists>xa\<in>I. \<exists>xb\<in>J. x = xa \<oplus> xb"
      by (metis additive_subgroup.zero_closed ideal.Icarr idealJ ideal_def l_zero local.idealI)
    ultimately show "I \<union> J \<subseteq> I <+> J"
      by (auto simp: set_add_defs) 
  qed
next
  show "I <+> J \<subseteq> Idl (I \<union> J)"
    by (auto simp: set_add_defs genideal_def additive_subgroup.a_closed ideal_def set_mp)
qed

subsection \<open>Properties of Principal Ideals\<close>

text \<open>The zero ideal is a principal ideal\<close>
corollary (in ring) zeropideal: "principalideal {\<zero>} R"
  using genideal_zero principalidealI zeroideal by blast

text \<open>The unit ideal is a principal ideal\<close>
corollary (in ring) onepideal: "principalideal (carrier R) R"
  using genideal_one oneideal principalidealI by blast

text \<open>Every principal ideal is a right coset of the carrier\<close>
lemma (in principalideal) rcos_generate:
  assumes "cring R"
  shows "\<exists>x\<in>I. I = carrier R #> x"
proof -
  interpret cring R by fact
  from generate obtain i where icarr: "i \<in> carrier R" and I1: "I = Idl {i}"
    by fast+
  then have "I = PIdl i"
    by (simp add: cgenideal_eq_genideal)
  moreover have "i \<in> I"
    by (simp add: I1 genideal_self' icarr)
  moreover have "PIdl i = carrier R #> i"
    unfolding cgenideal_def r_coset_def by fast
  ultimately show "\<exists>x\<in>I. I = carrier R #> x"
    by fast
qed


(* Next lemma contributed by Paulo Emílio de Vilhena. *)

text \<open>This next lemma would be trivial if placed in a theory that imports QuotRing,
      but it makes more sense to have it here (easier to find and coherent with the
      previous developments).\<close>

lemma (in cring) cgenideal_prod:
  assumes "a \<in> carrier R" "b \<in> carrier R"
  shows "(PIdl a) <#> (PIdl b) = PIdl (a \<otimes> b)"
proof -
  have "(carrier R #> a) <#> (carrier R #> b) = carrier R #> (a \<otimes> b)"
  proof
    show "(carrier R #> a) <#> (carrier R #> b) \<subseteq> carrier R #> a \<otimes> b"
    proof
      fix x assume "x \<in> (carrier R #> a) <#> (carrier R #> b)"
      then obtain r1 r2 where r1: "r1 \<in> carrier R" and r2: "r2 \<in> carrier R"
                          and "x = (r1 \<otimes> a) \<otimes> (r2 \<otimes> b)"
        unfolding set_mult_def r_coset_def by blast
      hence "x = (r1 \<otimes> r2) \<otimes> (a \<otimes> b)"
        by (simp add: assms local.ring_axioms m_lcomm ring.ring_simprules(11))
      thus "x \<in> carrier R #> a \<otimes> b"
        unfolding r_coset_def using r1 r2 assms by blast 
    qed
  next
    show "carrier R #> a \<otimes> b \<subseteq> (carrier R #> a) <#> (carrier R #> b)"
    proof
      fix x assume "x \<in> carrier R #> a \<otimes> b"
      then obtain r where r: "r \<in> carrier R" "x = r \<otimes> (a \<otimes> b)"
        unfolding r_coset_def by blast
      hence "x = (r \<otimes> a) \<otimes> (\<one> \<otimes> b)"
        using assms by (simp add: m_assoc)
      thus "x \<in> (carrier R #> a) <#> (carrier R #> b)"
        unfolding set_mult_def r_coset_def using assms r by blast
    qed
  qed
  thus ?thesis
    using cgenideal_eq_rcos[of a] cgenideal_eq_rcos[of b] cgenideal_eq_rcos[of "a \<otimes> b"] by simp
qed


subsection \<open>Prime Ideals\<close>

lemma (in ideal) primeidealCD:
  assumes "cring R"
  assumes notprime: "\<not> primeideal I R"
  shows "carrier R = I \<or> (\<exists>a b. a \<in> carrier R \<and> b \<in> carrier R \<and> a \<otimes> b \<in> I \<and> a \<notin> I \<and> b \<notin> I)"
proof (rule ccontr, clarsimp)
  interpret cring R by fact
  assume InR: "carrier R \<noteq> I"
    and "\<forall>a. a \<in> carrier R \<longrightarrow> (\<forall>b. a \<otimes> b \<in> I \<longrightarrow> b \<in> carrier R \<longrightarrow> a \<in> I \<or> b \<in> I)"
  then have I_prime: "\<And> a b. \<lbrakk>a \<in> carrier R; b \<in> carrier R; a \<otimes> b \<in> I\<rbrakk> \<Longrightarrow> a \<in> I \<or> b \<in> I"
    by simp
  have "primeideal I R"
    by (simp add: I_prime InR is_cring is_ideal primeidealI)
  with notprime show False by simp
qed

lemma (in ideal) primeidealCE:
  assumes "cring R"
  assumes notprime: "\<not> primeideal I R"
  obtains "carrier R = I"
    | "\<exists>a b. a \<in> carrier R \<and> b \<in> carrier R \<and> a \<otimes> b \<in> I \<and> a \<notin> I \<and> b \<notin> I"
proof -
  interpret R: cring R by fact
  assume "carrier R = I ==> thesis"
    and "\<exists>a b. a \<in> carrier R \<and> b \<in> carrier R \<and> a \<otimes> b \<in> I \<and> a \<notin> I \<and> b \<notin> I \<Longrightarrow> thesis"
  then show thesis using primeidealCD [OF R.is_cring notprime] by blast
qed

text \<open>If \<open>{\<zero>}\<close> is a prime ideal of a commutative ring, the ring is a domain\<close>
lemma (in cring) zeroprimeideal_domainI:
  assumes pi: "primeideal {\<zero>} R"
  shows "domain R"
proof (intro domain.intro is_cring domain_axioms.intro)
  show "\<one> \<noteq> \<zero>"
    using genideal_one genideal_zero pi primeideal.I_notcarr by force
  show "a = \<zero> \<or> b = \<zero>" if ab: "a \<otimes> b = \<zero>" and carr: "a \<in> carrier R" "b \<in> carrier R" for a b
  proof -
    interpret primeideal "{\<zero>}" "R" by (rule pi)
    show "a = \<zero> \<or> b = \<zero>"
      using I_prime ab carr by blast
  qed
qed

corollary (in cring) domain_eq_zeroprimeideal: "domain R = primeideal {\<zero>} R"
  using domain.zeroprimeideal zeroprimeideal_domainI by blast


subsection \<open>Maximal Ideals\<close>

lemma (in ideal) helper_I_closed:
  assumes carr: "a \<in> carrier R" "x \<in> carrier R" "y \<in> carrier R"
    and axI: "a \<otimes> x \<in> I"
  shows "a \<otimes> (x \<otimes> y) \<in> I"
proof -
  from axI and carr have "(a \<otimes> x) \<otimes> y \<in> I"
    by (simp add: I_r_closed)
  also from carr have "(a \<otimes> x) \<otimes> y = a \<otimes> (x \<otimes> y)"
    by (simp add: m_assoc)
  finally show "a \<otimes> (x \<otimes> y) \<in> I" .
qed

lemma (in ideal) helper_max_prime:
  assumes "cring R"
  assumes acarr: "a \<in> carrier R"
  shows "ideal {x\<in>carrier R. a \<otimes> x \<in> I} R"
proof -
  interpret cring R by fact
  show ?thesis 
  proof (rule idealI, simp_all)
    show "ring R"
      by (simp add: local.ring_axioms)
    show "subgroup {x \<in> carrier R. a \<otimes> x \<in> I} (add_monoid R)"
      by (rule subgroup.intro) (auto simp: r_distr acarr r_minus simp flip: a_inv_def)
    show "\<And>b x. \<lbrakk>b \<in> carrier R \<and> a \<otimes> b \<in> I; x \<in> carrier R\<rbrakk>
                 \<Longrightarrow> a \<otimes> (x \<otimes> b) \<in> I"
      using acarr helper_I_closed m_comm by auto
    show "\<And>b x. \<lbrakk>b \<in> carrier R \<and> a \<otimes> b \<in> I; x \<in> carrier R\<rbrakk>
                \<Longrightarrow> a \<otimes> (b \<otimes> x) \<in> I"
      by (simp add: acarr helper_I_closed)
  qed
qed

text \<open>In a cring every maximal ideal is prime\<close>
lemma (in cring) maximalideal_prime:
  assumes "maximalideal I R"
  shows "primeideal I R"
proof -
  interpret maximalideal I R by fact
  show ?thesis 
  proof (rule ccontr)
    assume neg: "\<not> primeideal I R"
    then obtain a b where acarr: "a \<in> carrier R" and bcarr: "b \<in> carrier R"
      and abI: "a \<otimes> b \<in> I" and anI: "a \<notin> I" and bnI: "b \<notin> I" 
      using primeidealCE [OF is_cring]
      by (metis I_notcarr)
    define J where "J = {x\<in>carrier R. a \<otimes> x \<in> I}"
    from is_cring and acarr have idealJ: "ideal J R"
      unfolding J_def by (rule helper_max_prime)
    have IsubJ: "I \<subseteq> J"
      using I_l_closed J_def a_Hcarr acarr by blast
    from abI and acarr bcarr have "b \<in> J"
      unfolding J_def by fast
    with bnI have JnI: "J \<noteq> I" by fast
    have "\<one> \<notin> J"
      unfolding J_def by (simp add: acarr anI)
    then have Jncarr: "J \<noteq> carrier R" by fast
    interpret ideal J R by (rule idealJ)    
    have "J = I \<or> J = carrier R"
      by (simp add: I_maximal IsubJ a_subset is_ideal)
    with JnI and Jncarr show False by simp
  qed
qed


subsection \<open>Derived Theorems\<close>

text \<open>A non-zero cring that has only the two trivial ideals is a field\<close>
lemma (in cring) trivialideals_fieldI:
  assumes carrnzero: "carrier R \<noteq> {\<zero>}"
    and haveideals: "{I. ideal I R} = {{\<zero>}, carrier R}"
  shows "field R"
proof (intro cring_fieldI equalityI)
  show "Units R \<subseteq> carrier R - {\<zero>}"
    by (metis Diff_empty Units_closed Units_r_inv_ex carrnzero l_null one_zeroD subsetI subset_Diff_insert)
  show "carrier R - {\<zero>} \<subseteq> Units R"
  proof
    fix x
    assume xcarr': "x \<in> carrier R - {\<zero>}"
    then have xcarr: "x \<in> carrier R" and xnZ: "x \<noteq> \<zero>" by auto
    from xcarr have xIdl: "ideal (PIdl x) R"
      by (intro cgenideal_ideal) fast
    have "PIdl x \<noteq> {\<zero>}"
      using xcarr xnZ cgenideal_self by blast 
    with haveideals have "PIdl x = carrier R"
      by (blast intro!: xIdl)
    then have "\<one> \<in> PIdl x" by simp
    then have "\<exists>y. \<one> = y \<otimes> x \<and> y \<in> carrier R"
      unfolding cgenideal_def by blast
    then obtain y where ycarr: " y \<in> carrier R" and ylinv: "\<one> = y \<otimes> x"
      by fast    
    have "\<exists>y \<in> carrier R. y \<otimes> x = \<one> \<and> x \<otimes> y = \<one>"
      using m_comm xcarr ycarr ylinv by auto
    with xcarr show "x \<in> Units R"
      unfolding Units_def by fast
  qed
qed

lemma (in field) all_ideals: "{I. ideal I R} = {{\<zero>}, carrier R}"
proof (intro equalityI subsetI)
  fix I
  assume a: "I \<in> {I. ideal I R}"
  then interpret ideal I R by simp

  show "I \<in> {{\<zero>}, carrier R}"
  proof (cases "\<exists>a. a \<in> I - {\<zero>}")
    case True
    then obtain a where aI: "a \<in> I" and anZ: "a \<noteq> \<zero>"
      by fast+
    have aUnit: "a \<in> Units R"
      by (simp add: aI anZ field_Units)
    then have a: "a \<otimes> inv a = \<one>" by (rule Units_r_inv)
    from aI and aUnit have "a \<otimes> inv a \<in> I"
      by (simp add: I_r_closed del: Units_r_inv)
    then have oneI: "\<one> \<in> I" by (simp add: a[symmetric])
    have "carrier R \<subseteq> I"
      using oneI one_imp_carrier by auto
    with a_subset have "I = carrier R" by fast
    then show "I \<in> {{\<zero>}, carrier R}" by fast
  next
    case False
    then have IZ: "\<And>a. a \<in> I \<Longrightarrow> a = \<zero>" by simp
    have a: "I \<subseteq> {\<zero>}"
      using False by auto
    have "\<zero> \<in> I" by simp
    with a have "I = {\<zero>}" by fast
    then show "I \<in> {{\<zero>}, carrier R}" by fast
  qed
qed (auto simp: zeroideal oneideal)

\<comment>\<open>"Jacobson Theorem 2.2"\<close>
lemma (in cring) trivialideals_eq_field:
  assumes carrnzero: "carrier R \<noteq> {\<zero>}"
  shows "({I. ideal I R} = {{\<zero>}, carrier R}) = field R"
  by (fast intro!: trivialideals_fieldI[OF carrnzero] field.all_ideals)


text \<open>Like zeroprimeideal for domains\<close>
lemma (in field) zeromaximalideal: "maximalideal {\<zero>} R"
proof (intro maximalidealI zeroideal)
  from one_not_zero have "\<one> \<notin> {\<zero>}" by simp
  with one_closed show "carrier R \<noteq> {\<zero>}" by fast
next
  fix J
  assume Jideal: "ideal J R"
  then have "J \<in> {I. ideal I R}" by fast
  with all_ideals show "J = {\<zero>} \<or> J = carrier R"
    by simp
qed

lemma (in cring) zeromaximalideal_fieldI:
  assumes zeromax: "maximalideal {\<zero>} R"
  shows "field R"
proof (intro trivialideals_fieldI maximalideal.I_notcarr[OF zeromax])
  have "J = carrier R" if Jn0: "J \<noteq> {\<zero>}" and idealJ: "ideal J R" for J
  proof -
    interpret ideal J R by (rule idealJ)
    have "{\<zero>} \<subseteq> J"
      by force
    from zeromax idealJ this a_subset
    have "J = {\<zero>} \<or> J = carrier R"
      by (rule maximalideal.I_maximal)
    with Jn0 show "J = carrier R"
      by simp
  qed
  then show "{I. ideal I R} = {{\<zero>}, carrier R}"
    by (auto simp: zeroideal oneideal)
qed

lemma (in cring) zeromaximalideal_eq_field: "maximalideal {\<zero>} R = field R"
  using field.zeromaximalideal zeromaximalideal_fieldI by blast

end

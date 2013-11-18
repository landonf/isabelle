(*  Title:      HOL/Cardinals/Constructions_on_Wellorders.thy
    Author:     Andrei Popescu, TU Muenchen
    Copyright   2012

Constructions on wellorders.
*)

header {* Constructions on Wellorders *}

theory Constructions_on_Wellorders
imports Constructions_on_Wellorders_LFP Wellorder_Embedding
begin

declare
  ordLeq_Well_order_simp[simp]
  ordLess_Well_order_simp[simp]
  ordIso_Well_order_simp[simp]
  not_ordLeq_iff_ordLess[simp]
  not_ordLess_iff_ordLeq[simp]


subsection {* Restriction to a set  *}

lemma Restr_incr2:
"r <= r' \<Longrightarrow> Restr r A <= Restr r' A"
by blast

lemma Restr_incr:
"\<lbrakk>r \<le> r'; A \<le> A'\<rbrakk> \<Longrightarrow> Restr r A \<le> Restr r' A'"
by blast

lemma Restr_Int:
"Restr (Restr r A) B = Restr r (A Int B)"
by blast

lemma Restr_iff: "(a,b) : Restr r A = (a : A \<and> b : A \<and> (a,b) : r)"
by (auto simp add: Field_def)

lemma Restr_subset1: "Restr r A \<le> r"
by auto

lemma Restr_subset2: "Restr r A \<le> A \<times> A"
by auto

lemma wf_Restr:
"wf r \<Longrightarrow> wf(Restr r A)"
using Restr_subset by (elim wf_subset) simp

lemma Restr_incr1:
"A \<le> B \<Longrightarrow> Restr r A \<le> Restr r B"
by blast


subsection {* Order filters versus restrictions and embeddings  *}

lemma ofilter_Restr:
assumes WELL: "Well_order r" and
        OFA: "ofilter r A" and OFB: "ofilter r B" and SUB: "A \<le> B"
shows "ofilter (Restr r B) A"
proof-
  let ?rB = "Restr r B"
  have Well: "wo_rel r" unfolding wo_rel_def using WELL .
  hence Refl: "Refl r" by (auto simp add: wo_rel.REFL)
  hence Field: "Field ?rB = Field r Int B"
  using Refl_Field_Restr by blast
  have WellB: "wo_rel ?rB \<and> Well_order ?rB" using WELL
  by (auto simp add: Well_order_Restr wo_rel_def)
  (* Main proof *)
  show ?thesis
  proof(auto simp add: WellB wo_rel.ofilter_def)
    fix a assume "a \<in> A"
    hence "a \<in> Field r \<and> a \<in> B" using assms Well
    by (auto simp add: wo_rel.ofilter_def)
    with Field show "a \<in> Field(Restr r B)" by auto
  next
    fix a b assume *: "a \<in> A"  and "b \<in> under (Restr r B) a"
    hence "b \<in> under r a"
    using WELL OFB SUB ofilter_Restr_under[of r B a] by auto
    thus "b \<in> A" using * Well OFA by(auto simp add: wo_rel.ofilter_def)
  qed
qed

lemma ofilter_subset_iso:
assumes WELL: "Well_order r" and
        OFA: "ofilter r A" and OFB: "ofilter r B"
shows "(A = B) = iso (Restr r A) (Restr r B) id"
using assms
by (auto simp add: ofilter_subset_embedS_iso)


subsection {* Ordering the  well-orders by existence of embeddings *}

corollary ordLeq_refl_on: "refl_on {r. Well_order r} ordLeq"
using ordLeq_reflexive unfolding ordLeq_def refl_on_def
by blast

corollary ordLeq_trans: "trans ordLeq"
using trans_def[of ordLeq] ordLeq_transitive by blast

corollary ordLeq_preorder_on: "preorder_on {r. Well_order r} ordLeq"
by(auto simp add: preorder_on_def ordLeq_refl_on ordLeq_trans)

corollary ordIso_refl_on: "refl_on {r. Well_order r} ordIso"
using ordIso_reflexive unfolding refl_on_def ordIso_def
by blast

corollary ordIso_trans: "trans ordIso"
using trans_def[of ordIso] ordIso_transitive by blast

corollary ordIso_sym: "sym ordIso"
by (auto simp add: sym_def ordIso_symmetric)

corollary ordIso_equiv: "equiv {r. Well_order r} ordIso"
by (auto simp add:  equiv_def ordIso_sym ordIso_refl_on ordIso_trans)

lemma ordLess_irrefl: "irrefl ordLess"
by(unfold irrefl_def, auto simp add: ordLess_irreflexive)

lemma ordLess_or_ordIso:
assumes WELL: "Well_order r" and WELL': "Well_order r'"
shows "r <o r' \<or> r' <o r \<or> r =o r'"
unfolding ordLess_def ordIso_def
using assms embedS_or_iso[of r r'] by auto

corollary ordLeq_ordLess_Un_ordIso:
"ordLeq = ordLess \<union> ordIso"
by (auto simp add: ordLeq_iff_ordLess_or_ordIso)

lemma not_ordLeq_ordLess:
"r \<le>o r' \<Longrightarrow> \<not> r' <o r"
using not_ordLess_ordLeq by blast

lemma ordIso_or_ordLess:
assumes WELL: "Well_order r" and WELL': "Well_order r'"
shows "r =o r' \<or> r <o r' \<or> r' <o r"
using assms ordLess_or_ordLeq ordLeq_iff_ordLess_or_ordIso by blast

lemmas ord_trans = ordIso_transitive ordLeq_transitive ordLess_transitive
                   ordIso_ordLeq_trans ordLeq_ordIso_trans
                   ordIso_ordLess_trans ordLess_ordIso_trans
                   ordLess_ordLeq_trans ordLeq_ordLess_trans

lemma ofilter_ordLeq:
assumes "Well_order r" and "ofilter r A"
shows "Restr r A \<le>o r"
proof-
  have "A \<le> Field r" using assms by (auto simp add: wo_rel_def wo_rel.ofilter_def)
  thus ?thesis using assms
  by (simp add: ofilter_subset_ordLeq wo_rel.Field_ofilter
      wo_rel_def Restr_Field)
qed

corollary under_Restr_ordLeq:
"Well_order r \<Longrightarrow> Restr r (under r a) \<le>o r"
by (auto simp add: ofilter_ordLeq wo_rel.under_ofilter wo_rel_def)


subsection {* Copy via direct images  *}

lemma Id_dir_image: "dir_image Id f \<le> Id"
unfolding dir_image_def by auto

lemma Un_dir_image:
"dir_image (r1 \<union> r2) f = (dir_image r1 f) \<union> (dir_image r2 f)"
unfolding dir_image_def by auto

lemma Int_dir_image:
assumes "inj_on f (Field r1 \<union> Field r2)"
shows "dir_image (r1 Int r2) f = (dir_image r1 f) Int (dir_image r2 f)"
proof
  show "dir_image (r1 Int r2) f \<le> (dir_image r1 f) Int (dir_image r2 f)"
  using assms unfolding dir_image_def inj_on_def by auto
next
  show "(dir_image r1 f) Int (dir_image r2 f) \<le> dir_image (r1 Int r2) f"
  proof(clarify)
    fix a' b'
    assume "(a',b') \<in> dir_image r1 f" "(a',b') \<in> dir_image r2 f"
    then obtain a1 b1 a2 b2
    where 1: "a' = f a1 \<and> b' = f b1 \<and> a' = f a2 \<and> b' = f b2" and
          2: "(a1,b1) \<in> r1 \<and> (a2,b2) \<in> r2" and
          3: "{a1,b1} \<le> Field r1 \<and> {a2,b2} \<le> Field r2"
    unfolding dir_image_def Field_def by blast
    hence "a1 = a2 \<and> b1 = b2" using assms unfolding inj_on_def by auto
    hence "a' = f a1 \<and> b' = f b1 \<and> (a1,b1) \<in> r1 Int r2 \<and> (a2,b2) \<in> r1 Int r2"
    using 1 2 by auto
    thus "(a',b') \<in> dir_image (r1 \<inter> r2) f"
    unfolding dir_image_def by blast
  qed
qed

(* More facts on ordinal sum: *)

lemma Osum_embed:
assumes FLD: "Field r Int Field r' = {}" and
        WELL: "Well_order r" and WELL': "Well_order r'"
shows "embed r (r Osum r') id"
proof-
  have 1: "Well_order (r Osum r')"
  using assms by (auto simp add: Osum_Well_order)
  moreover
  have "compat r (r Osum r') id"
  unfolding compat_def Osum_def by auto
  moreover
  have "inj_on id (Field r)" by simp
  moreover
  have "ofilter (r Osum r') (Field r)"
  using 1 proof(auto simp add: wo_rel_def wo_rel.ofilter_def
                               Field_Osum rel.under_def)
    fix a b assume 2: "a \<in> Field r" and 3: "(b,a) \<in> r Osum r'"
    moreover
    {assume "(b,a) \<in> r'"
     hence "a \<in> Field r'" using Field_def[of r'] by blast
     hence False using 2 FLD by blast
    }
    moreover
    {assume "a \<in> Field r'"
     hence False using 2 FLD by blast
    }
    ultimately
    show "b \<in> Field r" by (auto simp add: Osum_def Field_def)
  qed
  ultimately show ?thesis
  using assms by (auto simp add: embed_iff_compat_inj_on_ofilter)
qed

corollary Osum_ordLeq:
assumes FLD: "Field r Int Field r' = {}" and
        WELL: "Well_order r" and WELL': "Well_order r'"
shows "r \<le>o r Osum r'"
using assms Osum_embed Osum_Well_order
unfolding ordLeq_def by blast

lemma Well_order_embed_copy:
assumes WELL: "well_order_on A r" and
        INJ: "inj_on f A" and SUB: "f ` A \<le> B"
shows "\<exists>r'. well_order_on B r' \<and> r \<le>o r'"
proof-
  have "bij_betw f A (f ` A)"
  using INJ inj_on_imp_bij_betw by blast
  then obtain r'' where "well_order_on (f ` A) r''" and 1: "r =o r''"
  using WELL  Well_order_iso_copy by blast
  hence 2: "Well_order r'' \<and> Field r'' = (f ` A)"
  using rel.well_order_on_Well_order by blast
  (*  *)
  let ?C = "B - (f ` A)"
  obtain r''' where "well_order_on ?C r'''"
  using well_order_on by blast
  hence 3: "Well_order r''' \<and> Field r''' = ?C"
  using rel.well_order_on_Well_order by blast
  (*  *)
  let ?r' = "r'' Osum r'''"
  have "Field r'' Int Field r''' = {}"
  using 2 3 by auto
  hence "r'' \<le>o ?r'" using Osum_ordLeq[of r'' r'''] 2 3 by blast
  hence 4: "r \<le>o ?r'" using 1 ordIso_ordLeq_trans by blast
  (*  *)
  hence "Well_order ?r'" unfolding ordLeq_def by auto
  moreover
  have "Field ?r' = B" using 2 3 SUB by (auto simp add: Field_Osum)
  ultimately show ?thesis using 4 by blast
qed


subsection {* The maxim among a finite set of ordinals  *}

text {* The correct phrasing would be ``a maxim of ...", as @{text "\<le>o"} is only a preorder. *}

definition isOmax :: "'a rel set \<Rightarrow> 'a rel \<Rightarrow> bool"
where
"isOmax  R r == r \<in> R \<and> (ALL r' : R. r' \<le>o r)"

definition omax :: "'a rel set \<Rightarrow> 'a rel"
where
"omax R == SOME r. isOmax R r"

lemma exists_isOmax:
assumes "finite R" and "R \<noteq> {}" and "\<forall> r \<in> R. Well_order r"
shows "\<exists> r. isOmax R r"
proof-
  have "finite R \<Longrightarrow> R \<noteq> {} \<longrightarrow> (\<forall> r \<in> R. Well_order r) \<longrightarrow> (\<exists> r. isOmax R r)"
  apply(erule finite_induct) apply(simp add: isOmax_def)
  proof(clarsimp)
    fix r :: "('a \<times> 'a) set" and R assume *: "finite R" and **: "r \<notin> R"
    and ***: "Well_order r" and ****: "\<forall>r\<in>R. Well_order r"
    and IH: "R \<noteq> {} \<longrightarrow> (\<exists>p. isOmax R p)"
    let ?R' = "insert r R"
    show "\<exists>p'. (isOmax ?R' p')"
    proof(cases "R = {}")
      assume Case1: "R = {}"
      thus ?thesis unfolding isOmax_def using ***
      by (simp add: ordLeq_reflexive)
    next
      assume Case2: "R \<noteq> {}"
      then obtain p where p: "isOmax R p" using IH by auto
      hence 1: "Well_order p" using **** unfolding isOmax_def by simp
      {assume Case21: "r \<le>o p"
       hence "isOmax ?R' p" using p unfolding isOmax_def by simp
       hence ?thesis by auto
      }
      moreover
      {assume Case22: "p \<le>o r"
       {fix r' assume "r' \<in> ?R'"
        moreover
        {assume "r' \<in> R"
         hence "r' \<le>o p" using p unfolding isOmax_def by simp
         hence "r' \<le>o r" using Case22 by(rule ordLeq_transitive)
        }
        moreover have "r \<le>o r" using *** by(rule ordLeq_reflexive)
        ultimately have "r' \<le>o r" by auto
       }
       hence "isOmax ?R' r" unfolding isOmax_def by simp
       hence ?thesis by auto
      }
      moreover have "r \<le>o p \<or> p \<le>o r"
      using 1 *** ordLeq_total by auto
      ultimately show ?thesis by blast
    qed
  qed
  thus ?thesis using assms by auto
qed

lemma omax_isOmax:
assumes "finite R" and "R \<noteq> {}" and "\<forall> r \<in> R. Well_order r"
shows "isOmax R (omax R)"
unfolding omax_def using assms
by(simp add: exists_isOmax someI_ex)

lemma omax_in:
assumes "finite R" and "R \<noteq> {}" and "\<forall> r \<in> R. Well_order r"
shows "omax R \<in> R"
using assms omax_isOmax unfolding isOmax_def by blast

lemma Well_order_omax:
assumes "finite R" and "R \<noteq> {}" and "\<forall>r\<in>R. Well_order r"
shows "Well_order (omax R)"
using assms apply - apply(drule omax_in) by auto

lemma omax_maxim:
assumes "finite R" and "\<forall> r \<in> R. Well_order r" and "r \<in> R"
shows "r \<le>o omax R"
using assms omax_isOmax unfolding isOmax_def by blast

lemma omax_ordLeq:
assumes "finite R" and "R \<noteq> {}" and *: "\<forall> r \<in> R. r \<le>o p"
shows "omax R \<le>o p"
proof-
  have "\<forall> r \<in> R. Well_order r" using * unfolding ordLeq_def by simp
  thus ?thesis using assms omax_in by auto
qed

lemma omax_ordLess:
assumes "finite R" and "R \<noteq> {}" and *: "\<forall> r \<in> R. r <o p"
shows "omax R <o p"
proof-
  have "\<forall> r \<in> R. Well_order r" using * unfolding ordLess_def by simp
  thus ?thesis using assms omax_in by auto
qed

lemma omax_ordLeq_elim:
assumes "finite R" and "\<forall> r \<in> R. Well_order r"
and "omax R \<le>o p" and "r \<in> R"
shows "r \<le>o p"
using assms omax_maxim[of R r] apply simp
using ordLeq_transitive by blast

lemma omax_ordLess_elim:
assumes "finite R" and "\<forall> r \<in> R. Well_order r"
and "omax R <o p" and "r \<in> R"
shows "r <o p"
using assms omax_maxim[of R r] apply simp
using ordLeq_ordLess_trans by blast

lemma ordLeq_omax:
assumes "finite R" and "\<forall> r \<in> R. Well_order r"
and "r \<in> R" and "p \<le>o r"
shows "p \<le>o omax R"
using assms omax_maxim[of R r] apply simp
using ordLeq_transitive by blast

lemma ordLess_omax:
assumes "finite R" and "\<forall> r \<in> R. Well_order r"
and "r \<in> R" and "p <o r"
shows "p <o omax R"
using assms omax_maxim[of R r] apply simp
using ordLess_ordLeq_trans by blast

lemma omax_ordLeq_mono:
assumes P: "finite P" and R: "finite R"
and NE_P: "P \<noteq> {}" and Well_R: "\<forall> r \<in> R. Well_order r"
and LEQ: "\<forall> p \<in> P. \<exists> r \<in> R. p \<le>o r"
shows "omax P \<le>o omax R"
proof-
  let ?mp = "omax P"  let ?mr = "omax R"
  {fix p assume "p : P"
   then obtain r where r: "r : R" and "p \<le>o r"
   using LEQ by blast
   moreover have "r <=o ?mr"
   using r R Well_R omax_maxim by blast
   ultimately have "p <=o ?mr"
   using ordLeq_transitive by blast
  }
  thus "?mp <=o ?mr"
  using NE_P P using omax_ordLeq by blast
qed

lemma omax_ordLess_mono:
assumes P: "finite P" and R: "finite R"
and NE_P: "P \<noteq> {}" and Well_R: "\<forall> r \<in> R. Well_order r"
and LEQ: "\<forall> p \<in> P. \<exists> r \<in> R. p <o r"
shows "omax P <o omax R"
proof-
  let ?mp = "omax P"  let ?mr = "omax R"
  {fix p assume "p : P"
   then obtain r where r: "r : R" and "p <o r"
   using LEQ by blast
   moreover have "r <=o ?mr"
   using r R Well_R omax_maxim by blast
   ultimately have "p <o ?mr"
   using ordLess_ordLeq_trans by blast
  }
  thus "?mp <o ?mr"
  using NE_P P omax_ordLess by blast
qed

end

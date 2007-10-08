(*
    ID:         $Id$
    Author:     Amine Chaieb, TU Muenchen
*)

header {* Dense linear order without endpoints
  and a quantifier elimination procedure in Ferrante and Rackoff style *}

theory Dense_Linear_Order
imports Finite_Set
uses
  "Tools/Qelim/qelim.ML"
  "Tools/Qelim/langford_data.ML"
  "Tools/Qelim/ferrante_rackoff_data.ML"
  ("Tools/Qelim/langford.ML")
  ("Tools/Qelim/ferrante_rackoff.ML")
begin

setup Langford_Data.setup
setup Ferrante_Rackoff_Data.setup

context linorder
begin

lemma less_not_permute: "\<not> (x \<^loc>< y \<and> y \<^loc>< x)" by (simp add: not_less linear)

lemma gather_simps: 
  shows 
  "(\<exists>x. (\<forall>y \<in> L. y \<^loc>< x) \<and> (\<forall>y \<in> U. x \<^loc>< y) \<and> x \<^loc>< u \<and> P x) \<longleftrightarrow> (\<exists>x. (\<forall>y \<in> L. y \<^loc>< x) \<and> (\<forall>y \<in> (insert u U). x \<^loc>< y) \<and> P x)"
  and "(\<exists>x. (\<forall>y \<in> L. y \<^loc>< x) \<and> (\<forall>y \<in> U. x \<^loc>< y) \<and> l \<^loc>< x \<and> P x) \<longleftrightarrow> (\<exists>x. (\<forall>y \<in> (insert l L). y \<^loc>< x) \<and> (\<forall>y \<in> U. x \<^loc>< y) \<and> P x)"
  "(\<exists>x. (\<forall>y \<in> L. y \<^loc>< x) \<and> (\<forall>y \<in> U. x \<^loc>< y) \<and> x \<^loc>< u) \<longleftrightarrow> (\<exists>x. (\<forall>y \<in> L. y \<^loc>< x) \<and> (\<forall>y \<in> (insert u U). x \<^loc>< y))"
  and "(\<exists>x. (\<forall>y \<in> L. y \<^loc>< x) \<and> (\<forall>y \<in> U. x \<^loc>< y) \<and> l \<^loc>< x) \<longleftrightarrow> (\<exists>x. (\<forall>y \<in> (insert l L). y \<^loc>< x) \<and> (\<forall>y \<in> U. x \<^loc>< y))"  by auto

lemma 
  gather_start: "(\<exists>x. P x) \<equiv> (\<exists>x. (\<forall>y \<in> {}. y \<^loc>< x) \<and> (\<forall>y\<in> {}. x \<^loc>< y) \<and> P x)" 
  by simp

text{* Theorems for @{text "\<exists>z. \<forall>x. x \<^loc>< z \<longrightarrow> (P x \<longleftrightarrow> P\<^bsub>-\<infinity>\<^esub>)"}*}
lemma minf_lt:  "\<exists>z . \<forall>x. x \<^loc>< z \<longrightarrow> (x \<^loc>< t \<longleftrightarrow> True)" by auto
lemma minf_gt: "\<exists>z . \<forall>x. x \<^loc>< z \<longrightarrow>  (t \<^loc>< x \<longleftrightarrow>  False)"
  by (simp add: not_less) (rule exI[where x="t"], auto simp add: less_le)

lemma minf_le: "\<exists>z. \<forall>x. x \<^loc>< z \<longrightarrow> (x \<^loc>\<le> t \<longleftrightarrow> True)" by (auto simp add: less_le)
lemma minf_ge: "\<exists>z. \<forall>x. x \<^loc>< z \<longrightarrow> (t \<^loc>\<le> x \<longleftrightarrow> False)"
  by (auto simp add: less_le not_less not_le)
lemma minf_eq: "\<exists>z. \<forall>x. x \<^loc>< z \<longrightarrow> (x = t \<longleftrightarrow> False)" by auto
lemma minf_neq: "\<exists>z. \<forall>x. x \<^loc>< z \<longrightarrow> (x \<noteq> t \<longleftrightarrow> True)" by auto
lemma minf_P: "\<exists>z. \<forall>x. x \<^loc>< z \<longrightarrow> (P \<longleftrightarrow> P)" by blast

text{* Theorems for @{text "\<exists>z. \<forall>x. x \<^loc>< z \<longrightarrow> (P x \<longleftrightarrow> P\<^bsub>+\<infinity>\<^esub>)"}*}
lemma pinf_gt:  "\<exists>z . \<forall>x. z \<^loc>< x \<longrightarrow> (t \<^loc>< x \<longleftrightarrow> True)" by auto
lemma pinf_lt: "\<exists>z . \<forall>x. z \<^loc>< x \<longrightarrow>  (x \<^loc>< t \<longleftrightarrow>  False)"
  by (simp add: not_less) (rule exI[where x="t"], auto simp add: less_le)

lemma pinf_ge: "\<exists>z. \<forall>x. z \<^loc>< x \<longrightarrow> (t \<^loc>\<le> x \<longleftrightarrow> True)" by (auto simp add: less_le)
lemma pinf_le: "\<exists>z. \<forall>x. z \<^loc>< x \<longrightarrow> (x \<^loc>\<le> t \<longleftrightarrow> False)"
  by (auto simp add: less_le not_less not_le)
lemma pinf_eq: "\<exists>z. \<forall>x. z \<^loc>< x \<longrightarrow> (x = t \<longleftrightarrow> False)" by auto
lemma pinf_neq: "\<exists>z. \<forall>x. z \<^loc>< x \<longrightarrow> (x \<noteq> t \<longleftrightarrow> True)" by auto
lemma pinf_P: "\<exists>z. \<forall>x. z \<^loc>< x \<longrightarrow> (P \<longleftrightarrow> P)" by blast

lemma nmi_lt: "t \<in> U \<Longrightarrow> \<forall>x. \<not>True \<and> x \<^loc>< t \<longrightarrow>  (\<exists> u\<in> U. u \<^loc>\<le> x)" by auto
lemma nmi_gt: "t \<in> U \<Longrightarrow> \<forall>x. \<not>False \<and> t \<^loc>< x \<longrightarrow>  (\<exists> u\<in> U. u \<^loc>\<le> x)"
  by (auto simp add: le_less)
lemma  nmi_le: "t \<in> U \<Longrightarrow> \<forall>x. \<not>True \<and> x\<^loc>\<le> t \<longrightarrow>  (\<exists> u\<in> U. u \<^loc>\<le> x)" by auto
lemma  nmi_ge: "t \<in> U \<Longrightarrow> \<forall>x. \<not>False \<and> t\<^loc>\<le> x \<longrightarrow>  (\<exists> u\<in> U. u \<^loc>\<le> x)" by auto
lemma  nmi_eq: "t \<in> U \<Longrightarrow> \<forall>x. \<not>False \<and>  x = t \<longrightarrow>  (\<exists> u\<in> U. u \<^loc>\<le> x)" by auto
lemma  nmi_neq: "t \<in> U \<Longrightarrow>\<forall>x. \<not>True \<and> x \<noteq> t \<longrightarrow>  (\<exists> u\<in> U. u \<^loc>\<le> x)" by auto
lemma  nmi_P: "\<forall> x. ~P \<and> P \<longrightarrow>  (\<exists> u\<in> U. u \<^loc>\<le> x)" by auto
lemma  nmi_conj: "\<lbrakk>\<forall>x. \<not>P1' \<and> P1 x \<longrightarrow>  (\<exists> u\<in> U. u \<^loc>\<le> x) ;
  \<forall>x. \<not>P2' \<and> P2 x \<longrightarrow>  (\<exists> u\<in> U. u \<^loc>\<le> x)\<rbrakk> \<Longrightarrow>
  \<forall>x. \<not>(P1' \<and> P2') \<and> (P1 x \<and> P2 x) \<longrightarrow>  (\<exists> u\<in> U. u \<^loc>\<le> x)" by auto
lemma  nmi_disj: "\<lbrakk>\<forall>x. \<not>P1' \<and> P1 x \<longrightarrow>  (\<exists> u\<in> U. u \<^loc>\<le> x) ;
  \<forall>x. \<not>P2' \<and> P2 x \<longrightarrow>  (\<exists> u\<in> U. u \<^loc>\<le> x)\<rbrakk> \<Longrightarrow>
  \<forall>x. \<not>(P1' \<or> P2') \<and> (P1 x \<or> P2 x) \<longrightarrow>  (\<exists> u\<in> U. u \<^loc>\<le> x)" by auto

lemma  npi_lt: "t \<in> U \<Longrightarrow> \<forall>x. \<not>False \<and>  x \<^loc>< t \<longrightarrow>  (\<exists> u\<in> U. x \<^loc>\<le> u)" by (auto simp add: le_less)
lemma  npi_gt: "t \<in> U \<Longrightarrow> \<forall>x. \<not>True \<and> t \<^loc>< x \<longrightarrow>  (\<exists> u\<in> U. x \<^loc>\<le> u)" by auto
lemma  npi_le: "t \<in> U \<Longrightarrow> \<forall>x. \<not>False \<and>  x \<^loc>\<le> t \<longrightarrow>  (\<exists> u\<in> U. x \<^loc>\<le> u)" by auto
lemma  npi_ge: "t \<in> U \<Longrightarrow> \<forall>x. \<not>True \<and> t \<^loc>\<le> x \<longrightarrow>  (\<exists> u\<in> U. x \<^loc>\<le> u)" by auto
lemma  npi_eq: "t \<in> U \<Longrightarrow> \<forall>x. \<not>False \<and>  x = t \<longrightarrow>  (\<exists> u\<in> U. x \<^loc>\<le> u)" by auto
lemma  npi_neq: "t \<in> U \<Longrightarrow> \<forall>x. \<not>True \<and> x \<noteq> t \<longrightarrow>  (\<exists> u\<in> U. x \<^loc>\<le> u )" by auto
lemma  npi_P: "\<forall> x. ~P \<and> P \<longrightarrow>  (\<exists> u\<in> U. x \<^loc>\<le> u)" by auto
lemma  npi_conj: "\<lbrakk>\<forall>x. \<not>P1' \<and> P1 x \<longrightarrow>  (\<exists> u\<in> U. x \<^loc>\<le> u) ;  \<forall>x. \<not>P2' \<and> P2 x \<longrightarrow>  (\<exists> u\<in> U. x \<^loc>\<le> u)\<rbrakk>
  \<Longrightarrow>  \<forall>x. \<not>(P1' \<and> P2') \<and> (P1 x \<and> P2 x) \<longrightarrow>  (\<exists> u\<in> U. x \<^loc>\<le> u)" by auto
lemma  npi_disj: "\<lbrakk>\<forall>x. \<not>P1' \<and> P1 x \<longrightarrow>  (\<exists> u\<in> U. x \<^loc>\<le> u) ; \<forall>x. \<not>P2' \<and> P2 x \<longrightarrow>  (\<exists> u\<in> U. x \<^loc>\<le> u)\<rbrakk>
  \<Longrightarrow> \<forall>x. \<not>(P1' \<or> P2') \<and> (P1 x \<or> P2 x) \<longrightarrow>  (\<exists> u\<in> U. x \<^loc>\<le> u)" by auto

lemma lin_dense_lt: "t \<in> U \<Longrightarrow> \<forall>x l u. (\<forall> t. l \<^loc>< t \<and> t \<^loc>< u \<longrightarrow> t \<notin> U) \<and> l\<^loc>< x \<and> x \<^loc>< u \<and> x \<^loc>< t \<longrightarrow> (\<forall> y. l \<^loc>< y \<and> y \<^loc>< u \<longrightarrow> y \<^loc>< t)"
proof(clarsimp)
  fix x l u y  assume tU: "t \<in> U" and noU: "\<forall>t. l \<^loc>< t \<and> t \<^loc>< u \<longrightarrow> t \<notin> U" and lx: "l \<^loc>< x"
    and xu: "x\<^loc><u"  and px: "x \<^loc>< t" and ly: "l\<^loc><y" and yu:"y \<^loc>< u"
  from tU noU ly yu have tny: "t\<noteq>y" by auto
  {assume H: "t \<^loc>< y"
    from less_trans[OF lx px] less_trans[OF H yu]
    have "l \<^loc>< t \<and> t \<^loc>< u"  by simp
    with tU noU have "False" by auto}
  hence "\<not> t \<^loc>< y"  by auto hence "y \<^loc>\<le> t" by (simp add: not_less)
  thus "y \<^loc>< t" using tny by (simp add: less_le)
qed

lemma lin_dense_gt: "t \<in> U \<Longrightarrow> \<forall>x l u. (\<forall> t. l \<^loc>< t \<and> t\<^loc>< u \<longrightarrow> t \<notin> U) \<and> l \<^loc>< x \<and> x \<^loc>< u \<and> t \<^loc>< x \<longrightarrow> (\<forall> y. l \<^loc>< y \<and> y \<^loc>< u \<longrightarrow> t \<^loc>< y)"
proof(clarsimp)
  fix x l u y
  assume tU: "t \<in> U" and noU: "\<forall>t. l \<^loc>< t \<and> t \<^loc>< u \<longrightarrow> t \<notin> U" and lx: "l \<^loc>< x" and xu: "x\<^loc><u"
  and px: "t \<^loc>< x" and ly: "l\<^loc><y" and yu:"y \<^loc>< u"
  from tU noU ly yu have tny: "t\<noteq>y" by auto
  {assume H: "y\<^loc>< t"
    from less_trans[OF ly H] less_trans[OF px xu] have "l \<^loc>< t \<and> t \<^loc>< u" by simp
    with tU noU have "False" by auto}
  hence "\<not> y\<^loc><t"  by auto hence "t \<^loc>\<le> y" by (auto simp add: not_less)
  thus "t \<^loc>< y" using tny by (simp add:less_le)
qed

lemma lin_dense_le: "t \<in> U \<Longrightarrow> \<forall>x l u. (\<forall> t. l \<^loc>< t \<and> t\<^loc>< u \<longrightarrow> t \<notin> U) \<and> l\<^loc>< x \<and> x \<^loc>< u \<and> x \<^loc>\<le> t \<longrightarrow> (\<forall> y. l \<^loc>< y \<and> y \<^loc>< u \<longrightarrow> y\<^loc>\<le> t)"
proof(clarsimp)
  fix x l u y
  assume tU: "t \<in> U" and noU: "\<forall>t. l \<^loc>< t \<and> t \<^loc>< u \<longrightarrow> t \<notin> U" and lx: "l \<^loc>< x" and xu: "x\<^loc><u"
  and px: "x \<^loc>\<le> t" and ly: "l\<^loc><y" and yu:"y \<^loc>< u"
  from tU noU ly yu have tny: "t\<noteq>y" by auto
  {assume H: "t \<^loc>< y"
    from less_le_trans[OF lx px] less_trans[OF H yu]
    have "l \<^loc>< t \<and> t \<^loc>< u" by simp
    with tU noU have "False" by auto}
  hence "\<not> t \<^loc>< y"  by auto thus "y \<^loc>\<le> t" by (simp add: not_less)
qed

lemma lin_dense_ge: "t \<in> U \<Longrightarrow> \<forall>x l u. (\<forall> t. l \<^loc>< t \<and> t\<^loc>< u \<longrightarrow> t \<notin> U) \<and> l\<^loc>< x \<and> x \<^loc>< u \<and> t \<^loc>\<le> x \<longrightarrow> (\<forall> y. l \<^loc>< y \<and> y \<^loc>< u \<longrightarrow> t \<^loc>\<le> y)"
proof(clarsimp)
  fix x l u y
  assume tU: "t \<in> U" and noU: "\<forall>t. l \<^loc>< t \<and> t \<^loc>< u \<longrightarrow> t \<notin> U" and lx: "l \<^loc>< x" and xu: "x\<^loc><u"
  and px: "t \<^loc>\<le> x" and ly: "l\<^loc><y" and yu:"y \<^loc>< u"
  from tU noU ly yu have tny: "t\<noteq>y" by auto
  {assume H: "y\<^loc>< t"
    from less_trans[OF ly H] le_less_trans[OF px xu]
    have "l \<^loc>< t \<and> t \<^loc>< u" by simp
    with tU noU have "False" by auto}
  hence "\<not> y\<^loc><t"  by auto thus "t \<^loc>\<le> y" by (simp add: not_less)
qed
lemma lin_dense_eq: "t \<in> U \<Longrightarrow> \<forall>x l u. (\<forall> t. l \<^loc>< t \<and> t\<^loc>< u \<longrightarrow> t \<notin> U) \<and> l\<^loc>< x \<and> x \<^loc>< u \<and> x = t   \<longrightarrow> (\<forall> y. l \<^loc>< y \<and> y \<^loc>< u \<longrightarrow> y= t)"  by auto
lemma lin_dense_neq: "t \<in> U \<Longrightarrow> \<forall>x l u. (\<forall> t. l \<^loc>< t \<and> t\<^loc>< u \<longrightarrow> t \<notin> U) \<and> l\<^loc>< x \<and> x \<^loc>< u \<and> x \<noteq> t   \<longrightarrow> (\<forall> y. l \<^loc>< y \<and> y \<^loc>< u \<longrightarrow> y\<noteq> t)"  by auto
lemma lin_dense_P: "\<forall>x l u. (\<forall> t. l \<^loc>< t \<and> t\<^loc>< u \<longrightarrow> t \<notin> U) \<and> l\<^loc>< x \<and> x \<^loc>< u \<and> P   \<longrightarrow> (\<forall> y. l \<^loc>< y \<and> y \<^loc>< u \<longrightarrow> P)"  by auto

lemma lin_dense_conj:
  "\<lbrakk>\<forall>x l u. (\<forall> t. l \<^loc>< t \<and> t\<^loc>< u \<longrightarrow> t \<notin> U) \<and> l\<^loc>< x \<and> x \<^loc>< u \<and> P1 x
  \<longrightarrow> (\<forall> y. l \<^loc>< y \<and> y \<^loc>< u \<longrightarrow> P1 y) ;
  \<forall>x l u. (\<forall> t. l \<^loc>< t \<and> t\<^loc>< u \<longrightarrow> t \<notin> U) \<and> l\<^loc>< x \<and> x \<^loc>< u \<and> P2 x
  \<longrightarrow> (\<forall> y. l \<^loc>< y \<and> y \<^loc>< u \<longrightarrow> P2 y)\<rbrakk> \<Longrightarrow>
  \<forall>x l u. (\<forall> t. l \<^loc>< t \<and> t\<^loc>< u \<longrightarrow> t \<notin> U) \<and> l\<^loc>< x \<and> x \<^loc>< u \<and> (P1 x \<and> P2 x)
  \<longrightarrow> (\<forall> y. l \<^loc>< y \<and> y \<^loc>< u \<longrightarrow> (P1 y \<and> P2 y))"
  by blast
lemma lin_dense_disj:
  "\<lbrakk>\<forall>x l u. (\<forall> t. l \<^loc>< t \<and> t\<^loc>< u \<longrightarrow> t \<notin> U) \<and> l\<^loc>< x \<and> x \<^loc>< u \<and> P1 x
  \<longrightarrow> (\<forall> y. l \<^loc>< y \<and> y \<^loc>< u \<longrightarrow> P1 y) ;
  \<forall>x l u. (\<forall> t. l \<^loc>< t \<and> t\<^loc>< u \<longrightarrow> t \<notin> U) \<and> l\<^loc>< x \<and> x \<^loc>< u \<and> P2 x
  \<longrightarrow> (\<forall> y. l \<^loc>< y \<and> y \<^loc>< u \<longrightarrow> P2 y)\<rbrakk> \<Longrightarrow>
  \<forall>x l u. (\<forall> t. l \<^loc>< t \<and> t\<^loc>< u \<longrightarrow> t \<notin> U) \<and> l\<^loc>< x \<and> x \<^loc>< u \<and> (P1 x \<or> P2 x)
  \<longrightarrow> (\<forall> y. l \<^loc>< y \<and> y \<^loc>< u \<longrightarrow> (P1 y \<or> P2 y))"
  by blast

lemma npmibnd: "\<lbrakk>\<forall>x. \<not> MP \<and> P x \<longrightarrow> (\<exists> u\<in> U. u \<^loc>\<le> x); \<forall>x. \<not>PP \<and> P x \<longrightarrow> (\<exists> u\<in> U. x \<^loc>\<le> u)\<rbrakk>
  \<Longrightarrow> \<forall>x. \<not> MP \<and> \<not>PP \<and> P x \<longrightarrow> (\<exists> u\<in> U. \<exists> u' \<in> U. u \<^loc>\<le> x \<and> x \<^loc>\<le> u')"
by auto

lemma finite_set_intervals:
  assumes px: "P x" and lx: "l \<^loc>\<le> x" and xu: "x \<^loc>\<le> u" and linS: "l\<in> S"
  and uinS: "u \<in> S" and fS:"finite S" and lS: "\<forall> x\<in> S. l \<^loc>\<le> x" and Su: "\<forall> x\<in> S. x \<^loc>\<le> u"
  shows "\<exists> a \<in> S. \<exists> b \<in> S. (\<forall> y. a \<^loc>< y \<and> y \<^loc>< b \<longrightarrow> y \<notin> S) \<and> a \<^loc>\<le> x \<and> x \<^loc>\<le> b \<and> P x"
proof-
  let ?Mx = "{y. y\<in> S \<and> y \<^loc>\<le> x}"
  let ?xM = "{y. y\<in> S \<and> x \<^loc>\<le> y}"
  let ?a = "Max ?Mx"
  let ?b = "Min ?xM"
  have MxS: "?Mx \<subseteq> S" by blast
  hence fMx: "finite ?Mx" using fS finite_subset by auto
  from lx linS have linMx: "l \<in> ?Mx" by blast
  hence Mxne: "?Mx \<noteq> {}" by blast
  have xMS: "?xM \<subseteq> S" by blast
  hence fxM: "finite ?xM" using fS finite_subset by auto
  from xu uinS have linxM: "u \<in> ?xM" by blast
  hence xMne: "?xM \<noteq> {}" by blast
  have ax:"?a \<^loc>\<le> x" using Mxne fMx by auto
  have xb:"x \<^loc>\<le> ?b" using xMne fxM by auto
  have "?a \<in> ?Mx" using Max_in[OF fMx Mxne] by simp hence ainS: "?a \<in> S" using MxS by blast
  have "?b \<in> ?xM" using Min_in[OF fxM xMne] by simp hence binS: "?b \<in> S" using xMS by blast
  have noy:"\<forall> y. ?a \<^loc>< y \<and> y \<^loc>< ?b \<longrightarrow> y \<notin> S"
  proof(clarsimp)
    fix y   assume ay: "?a \<^loc>< y" and yb: "y \<^loc>< ?b" and yS: "y \<in> S"
    from yS have "y\<in> ?Mx \<or> y\<in> ?xM" by (auto simp add: linear)
    moreover {assume "y \<in> ?Mx" hence "y \<^loc>\<le> ?a" using Mxne fMx by auto with ay have "False" by (simp add: not_le[symmetric])}
    moreover {assume "y \<in> ?xM" hence "?b \<^loc>\<le> y" using xMne fxM by auto with yb have "False" by (simp add: not_le[symmetric])}
    ultimately show "False" by blast
  qed
  from ainS binS noy ax xb px show ?thesis by blast
qed

lemma finite_set_intervals2:
  assumes px: "P x" and lx: "l \<^loc>\<le> x" and xu: "x \<^loc>\<le> u" and linS: "l\<in> S"
  and uinS: "u \<in> S" and fS:"finite S" and lS: "\<forall> x\<in> S. l \<^loc>\<le> x" and Su: "\<forall> x\<in> S. x \<^loc>\<le> u"
  shows "(\<exists> s\<in> S. P s) \<or> (\<exists> a \<in> S. \<exists> b \<in> S. (\<forall> y. a \<^loc>< y \<and> y \<^loc>< b \<longrightarrow> y \<notin> S) \<and> a \<^loc>< x \<and> x \<^loc>< b \<and> P x)"
proof-
  from finite_set_intervals[where P="P", OF px lx xu linS uinS fS lS Su]
  obtain a and b where
    as: "a\<in> S" and bs: "b\<in> S" and noS:"\<forall>y. a \<^loc>< y \<and> y \<^loc>< b \<longrightarrow> y \<notin> S"
    and axb: "a \<^loc>\<le> x \<and> x \<^loc>\<le> b \<and> P x"  by auto
  from axb have "x= a \<or> x= b \<or> (a \<^loc>< x \<and> x \<^loc>< b)" by (auto simp add: le_less)
  thus ?thesis using px as bs noS by blast
qed

end

section {* The classical QE after Langford for dense linear orders *}

context dense_linear_order
begin

lemma dlo_qe_bnds: 
  assumes ne: "L \<noteq> {}" and neU: "U \<noteq> {}" and fL: "finite L" and fU: "finite U"
  shows "(\<exists>x. (\<forall>y \<in> L. y \<^loc>< x) \<and> (\<forall>y \<in> U. x \<^loc>< y)) \<equiv> (\<forall> l \<in> L. \<forall>u \<in> U. l \<^loc>< u)"
proof (simp only: atomize_eq, rule iffI)
  assume H: "\<exists>x. (\<forall>y\<in>L. y \<^loc>< x) \<and> (\<forall>y\<in>U. x \<^loc>< y)"
  then obtain x where xL: "\<forall>y\<in>L. y \<^loc>< x" and xU: "\<forall>y\<in>U. x \<^loc>< y" by blast
  {fix l u assume l: "l \<in> L" and u: "u \<in> U"
    from less_trans[OF xL[rule_format, OF l] xU[rule_format, OF u]]
    have "l \<^loc>< u" .}
  thus "\<forall>l\<in>L. \<forall>u\<in>U. l \<^loc>< u" by blast
next
  assume H: "\<forall>l\<in>L. \<forall>u\<in>U. l \<^loc>< u"
  let ?ML = "Max L"
  let ?MU = "Min U"  
  from fL ne have th1: "?ML \<in> L" and th1': "\<forall>l\<in>L. l \<^loc>\<le> ?ML" by auto
  from fU neU have th2: "?MU \<in> U" and th2': "\<forall>u\<in>U. ?MU \<^loc>\<le> u" by auto
  from th1 th2 H have "?ML \<^loc>< ?MU" by auto
  with dense obtain w where th3: "?ML \<^loc>< w" and th4: "w \<^loc>< ?MU" by blast
  from th3 th1' have "\<forall>l \<in> L. l \<^loc>< w" by auto
  moreover from th4 th2' have "\<forall>u \<in> U. w \<^loc>< u" by auto
  ultimately show "\<exists>x. (\<forall>y\<in>L. y \<^loc>< x) \<and> (\<forall>y\<in>U. x \<^loc>< y)" by auto
qed

lemma dlo_qe_noub: 
  assumes ne: "L \<noteq> {}" and fL: "finite L"
  shows "(\<exists>x. (\<forall>y \<in> L. y \<^loc>< x) \<and> (\<forall>y \<in> {}. x \<^loc>< y)) \<equiv> True"
proof(simp add: atomize_eq)
  from gt_ex[rule_format, of "Max L"] obtain M where M: "Max L \<^loc>< M" by blast
  from ne fL have "\<forall>x \<in> L. x \<^loc>\<le> Max L" by simp
  with M have "\<forall>x\<in>L. x \<^loc>< M" by (auto intro: le_less_trans)
  thus "\<exists>x. \<forall>y\<in>L. y \<^loc>< x" by blast
qed

lemma dlo_qe_nolb: 
  assumes ne: "U \<noteq> {}" and fU: "finite U"
  shows "(\<exists>x. (\<forall>y \<in> {}. y \<^loc>< x) \<and> (\<forall>y \<in> U. x \<^loc>< y)) \<equiv> True"
proof(simp add: atomize_eq)
  from lt_ex[rule_format, of "Min U"] obtain M where M: "M \<^loc>< Min U" by blast
  from ne fU have "\<forall>x \<in> U. Min U \<^loc>\<le> x" by simp
  with M have "\<forall>x\<in>U. M \<^loc>< x" by (auto intro: less_le_trans)
  thus "\<exists>x. \<forall>y\<in>U. x \<^loc>< y" by blast
qed

lemma exists_neq: "\<exists>(x::'a). x \<noteq> t" "\<exists>(x::'a). t \<noteq> x" 
  using gt_ex[rule_format, of t] by auto

lemmas dlo_simps = order_refl less_irrefl not_less not_le exists_neq 
  le_less neq_iff linear less_not_permute

lemma axiom: "dense_linear_order (op \<^loc>\<le>) (op \<^loc><)" .
lemma atoms:
  includes meta_term_syntax
  shows "TERM (less :: 'a \<Rightarrow> _)"
    and "TERM (less_eq :: 'a \<Rightarrow> _)"
    and "TERM (op = :: 'a \<Rightarrow> _)" .

declare axiom[langford qe: dlo_qe_bnds dlo_qe_nolb dlo_qe_noub gather: gather_start gather_simps atoms: atoms]
declare dlo_simps[langfordsimp]

end

(* FIXME: Move to HOL -- together with the conj_aci_rule in langford.ML *)
lemma dnf:
  "(P & (Q | R)) = ((P&Q) | (P&R))" 
  "((Q | R) & P) = ((Q&P) | (R&P))"
  by blast+

lemmas weak_dnf_simps = simp_thms dnf

lemma nnf_simps:
    "(\<not>(P \<and> Q)) = (\<not>P \<or> \<not>Q)" "(\<not>(P \<or> Q)) = (\<not>P \<and> \<not>Q)" "(P \<longrightarrow> Q) = (\<not>P \<or> Q)"
    "(P = Q) = ((P \<and> Q) \<or> (\<not>P \<and> \<not> Q))" "(\<not> \<not>(P)) = P"
  by blast+

lemma ex_distrib: "(\<exists>x. P x \<or> Q x) \<longleftrightarrow> ((\<exists>x. P x) \<or> (\<exists>x. Q x))" by blast

lemmas dnf_simps = weak_dnf_simps nnf_simps ex_distrib

use "Tools/Qelim/langford.ML"
method_setup dlo = {*
  Method.ctxt_args (Method.SIMPLE_METHOD' o LangfordQE.dlo_tac)
*} "Langford's algorithm for quantifier elimination in dense linear orders"


section {* Contructive dense linear orders yield QE for linear arithmetic over ordered Fields -- see @{text "Arith_Tools.thy"} *}

text {* Linear order without upper bounds *}

class linorder_no_ub = linorder +
  assumes gt_ex: "\<exists>y. x \<^loc>< y"
begin

lemma ge_ex: "\<exists>y. x \<^loc>\<le> y" using gt_ex by auto

text {* Theorems for @{text "\<exists>z. \<forall>x. z \<^loc>< x \<longrightarrow> (P x \<longleftrightarrow> P\<^bsub>+\<infinity>\<^esub>)"} *}
lemma pinf_conj:
  assumes ex1: "\<exists>z1. \<forall>x. z1 \<^loc>< x \<longrightarrow> (P1 x \<longleftrightarrow> P1')"
  and ex2: "\<exists>z2. \<forall>x. z2 \<^loc>< x \<longrightarrow> (P2 x \<longleftrightarrow> P2')"
  shows "\<exists>z. \<forall>x. z \<^loc><  x \<longrightarrow> ((P1 x \<and> P2 x) \<longleftrightarrow> (P1' \<and> P2'))"
proof-
  from ex1 ex2 obtain z1 and z2 where z1: "\<forall>x. z1 \<^loc>< x \<longrightarrow> (P1 x \<longleftrightarrow> P1')"
     and z2: "\<forall>x. z2 \<^loc>< x \<longrightarrow> (P2 x \<longleftrightarrow> P2')" by blast
  from gt_ex obtain z where z:"max z1 z2 \<^loc>< z" by blast
  from z have zz1: "z1 \<^loc>< z" and zz2: "z2 \<^loc>< z" by simp_all
  {fix x assume H: "z \<^loc>< x"
    from less_trans[OF zz1 H] less_trans[OF zz2 H]
    have "(P1 x \<and> P2 x) \<longleftrightarrow> (P1' \<and> P2')"  using z1 zz1 z2 zz2 by auto
  }
  thus ?thesis by blast
qed

lemma pinf_disj:
  assumes ex1: "\<exists>z1. \<forall>x. z1 \<^loc>< x \<longrightarrow> (P1 x \<longleftrightarrow> P1')"
  and ex2: "\<exists>z2. \<forall>x. z2 \<^loc>< x \<longrightarrow> (P2 x \<longleftrightarrow> P2')"
  shows "\<exists>z. \<forall>x. z \<^loc><  x \<longrightarrow> ((P1 x \<or> P2 x) \<longleftrightarrow> (P1' \<or> P2'))"
proof-
  from ex1 ex2 obtain z1 and z2 where z1: "\<forall>x. z1 \<^loc>< x \<longrightarrow> (P1 x \<longleftrightarrow> P1')"
     and z2: "\<forall>x. z2 \<^loc>< x \<longrightarrow> (P2 x \<longleftrightarrow> P2')" by blast
  from gt_ex obtain z where z:"max z1 z2 \<^loc>< z" by blast
  from z have zz1: "z1 \<^loc>< z" and zz2: "z2 \<^loc>< z" by simp_all
  {fix x assume H: "z \<^loc>< x"
    from less_trans[OF zz1 H] less_trans[OF zz2 H]
    have "(P1 x \<or> P2 x) \<longleftrightarrow> (P1' \<or> P2')"  using z1 zz1 z2 zz2 by auto
  }
  thus ?thesis by blast
qed

lemma pinf_ex: assumes ex:"\<exists>z. \<forall>x. z \<^loc>< x \<longrightarrow> (P x \<longleftrightarrow> P1)" and p1: P1 shows "\<exists> x. P x"
proof-
  from ex obtain z where z: "\<forall>x. z \<^loc>< x \<longrightarrow> (P x \<longleftrightarrow> P1)" by blast
  from gt_ex obtain x where x: "z \<^loc>< x" by blast
  from z x p1 show ?thesis by blast
qed

end

text {* Linear order without upper bounds *}

class linorder_no_lb = linorder +
  assumes lt_ex: "\<exists>y. y \<^loc>< x"
begin

lemma le_ex: "\<exists>y. y \<^loc>\<le> x" using lt_ex by auto


text {* Theorems for @{text "\<exists>z. \<forall>x. x \<^loc>< z \<longrightarrow> (P x \<longleftrightarrow> P\<^bsub>-\<infinity>\<^esub>)"} *}
lemma minf_conj:
  assumes ex1: "\<exists>z1. \<forall>x. x \<^loc>< z1 \<longrightarrow> (P1 x \<longleftrightarrow> P1')"
  and ex2: "\<exists>z2. \<forall>x. x \<^loc>< z2 \<longrightarrow> (P2 x \<longleftrightarrow> P2')"
  shows "\<exists>z. \<forall>x. x \<^loc><  z \<longrightarrow> ((P1 x \<and> P2 x) \<longleftrightarrow> (P1' \<and> P2'))"
proof-
  from ex1 ex2 obtain z1 and z2 where z1: "\<forall>x. x \<^loc>< z1 \<longrightarrow> (P1 x \<longleftrightarrow> P1')"and z2: "\<forall>x. x \<^loc>< z2 \<longrightarrow> (P2 x \<longleftrightarrow> P2')" by blast
  from lt_ex obtain z where z:"z \<^loc>< min z1 z2" by blast
  from z have zz1: "z \<^loc>< z1" and zz2: "z \<^loc>< z2" by simp_all
  {fix x assume H: "x \<^loc>< z"
    from less_trans[OF H zz1] less_trans[OF H zz2]
    have "(P1 x \<and> P2 x) \<longleftrightarrow> (P1' \<and> P2')"  using z1 zz1 z2 zz2 by auto
  }
  thus ?thesis by blast
qed

lemma minf_disj:
  assumes ex1: "\<exists>z1. \<forall>x. x \<^loc>< z1 \<longrightarrow> (P1 x \<longleftrightarrow> P1')"
  and ex2: "\<exists>z2. \<forall>x. x \<^loc>< z2 \<longrightarrow> (P2 x \<longleftrightarrow> P2')"
  shows "\<exists>z. \<forall>x. x \<^loc><  z \<longrightarrow> ((P1 x \<or> P2 x) \<longleftrightarrow> (P1' \<or> P2'))"
proof-
  from ex1 ex2 obtain z1 and z2 where z1: "\<forall>x. x \<^loc>< z1 \<longrightarrow> (P1 x \<longleftrightarrow> P1')"and z2: "\<forall>x. x \<^loc>< z2 \<longrightarrow> (P2 x \<longleftrightarrow> P2')" by blast
  from lt_ex obtain z where z:"z \<^loc>< min z1 z2" by blast
  from z have zz1: "z \<^loc>< z1" and zz2: "z \<^loc>< z2" by simp_all
  {fix x assume H: "x \<^loc>< z"
    from less_trans[OF H zz1] less_trans[OF H zz2]
    have "(P1 x \<or> P2 x) \<longleftrightarrow> (P1' \<or> P2')"  using z1 zz1 z2 zz2 by auto
  }
  thus ?thesis by blast
qed

lemma minf_ex: assumes ex:"\<exists>z. \<forall>x. x \<^loc>< z \<longrightarrow> (P x \<longleftrightarrow> P1)" and p1: P1 shows "\<exists> x. P x"
proof-
  from ex obtain z where z: "\<forall>x. x \<^loc>< z \<longrightarrow> (P x \<longleftrightarrow> P1)" by blast
  from lt_ex obtain x where x: "x \<^loc>< z" by blast
  from z x p1 show ?thesis by blast
qed

end


class constr_dense_linear_order = linorder_no_lb + linorder_no_ub +
  fixes between
  assumes between_less: "x \<^loc>< y \<Longrightarrow> x \<^loc>< between x y \<and> between x y \<^loc>< y"
     and  between_same: "between x x = x"
begin

subclass dense_linear_order
  apply unfold_locales
  using gt_ex lt_ex between_less
    by (auto, rule_tac x="between x y" in exI, simp)

lemma rinf_U:
  assumes fU: "finite U"
  and lin_dense: "\<forall>x l u. (\<forall> t. l \<^loc>< t \<and> t\<^loc>< u \<longrightarrow> t \<notin> U) \<and> l\<^loc>< x \<and> x \<^loc>< u \<and> P x
  \<longrightarrow> (\<forall> y. l \<^loc>< y \<and> y \<^loc>< u \<longrightarrow> P y )"
  and nmpiU: "\<forall>x. \<not> MP \<and> \<not>PP \<and> P x \<longrightarrow> (\<exists> u\<in> U. \<exists> u' \<in> U. u \<^loc>\<le> x \<and> x \<^loc>\<le> u')"
  and nmi: "\<not> MP"  and npi: "\<not> PP"  and ex: "\<exists> x.  P x"
  shows "\<exists> u\<in> U. \<exists> u' \<in> U. P (between u u')"
proof-
  from ex obtain x where px: "P x" by blast
  from px nmi npi nmpiU have "\<exists> u\<in> U. \<exists> u' \<in> U. u \<^loc>\<le> x \<and> x \<^loc>\<le> u'" by auto
  then obtain u and u' where uU:"u\<in> U" and uU': "u' \<in> U" and ux:"u \<^loc>\<le> x" and xu':"x \<^loc>\<le> u'" by auto
  from uU have Une: "U \<noteq> {}" by auto
  let ?l = "Min U"
  let ?u = "Max U"
  have linM: "?l \<in> U" using fU Une by simp
  have uinM: "?u \<in> U" using fU Une by simp
  have lM: "\<forall> t\<in> U. ?l \<^loc>\<le> t" using Une fU by auto
  have Mu: "\<forall> t\<in> U. t \<^loc>\<le> ?u" using Une fU by auto
  have th:"?l \<^loc>\<le> u" using uU Une lM by auto
  from order_trans[OF th ux] have lx: "?l \<^loc>\<le> x" .
  have th: "u' \<^loc>\<le> ?u" using uU' Une Mu by simp
  from order_trans[OF xu' th] have xu: "x \<^loc>\<le> ?u" .
  from finite_set_intervals2[where P="P",OF px lx xu linM uinM fU lM Mu]
  have "(\<exists> s\<in> U. P s) \<or>
      (\<exists> t1\<in> U. \<exists> t2 \<in> U. (\<forall> y. t1 \<^loc>< y \<and> y \<^loc>< t2 \<longrightarrow> y \<notin> U) \<and> t1 \<^loc>< x \<and> x \<^loc>< t2 \<and> P x)" .
  moreover { fix u assume um: "u\<in>U" and pu: "P u"
    have "between u u = u" by (simp add: between_same)
    with um pu have "P (between u u)" by simp
    with um have ?thesis by blast}
  moreover{
    assume "\<exists> t1\<in> U. \<exists> t2 \<in> U. (\<forall> y. t1 \<^loc>< y \<and> y \<^loc>< t2 \<longrightarrow> y \<notin> U) \<and> t1 \<^loc>< x \<and> x \<^loc>< t2 \<and> P x"
      then obtain t1 and t2 where t1M: "t1 \<in> U" and t2M: "t2\<in> U"
        and noM: "\<forall> y. t1 \<^loc>< y \<and> y \<^loc>< t2 \<longrightarrow> y \<notin> U" and t1x: "t1 \<^loc>< x" and xt2: "x \<^loc>< t2" and px: "P x"
        by blast
      from less_trans[OF t1x xt2] have t1t2: "t1 \<^loc>< t2" .
      let ?u = "between t1 t2"
      from between_less t1t2 have t1lu: "t1 \<^loc>< ?u" and ut2: "?u \<^loc>< t2" by auto
      from lin_dense[rule_format, OF] noM t1x xt2 px t1lu ut2 have "P ?u" by blast
      with t1M t2M have ?thesis by blast}
    ultimately show ?thesis by blast
  qed

theorem fr_eq:
  assumes fU: "finite U"
  and lin_dense: "\<forall>x l u. (\<forall> t. l \<^loc>< t \<and> t\<^loc>< u \<longrightarrow> t \<notin> U) \<and> l\<^loc>< x \<and> x \<^loc>< u \<and> P x
   \<longrightarrow> (\<forall> y. l \<^loc>< y \<and> y \<^loc>< u \<longrightarrow> P y )"
  and nmibnd: "\<forall>x. \<not> MP \<and> P x \<longrightarrow> (\<exists> u\<in> U. u \<^loc>\<le> x)"
  and npibnd: "\<forall>x. \<not>PP \<and> P x \<longrightarrow> (\<exists> u\<in> U. x \<^loc>\<le> u)"
  and mi: "\<exists>z. \<forall>x. x \<^loc>< z \<longrightarrow> (P x = MP)"  and pi: "\<exists>z. \<forall>x. z \<^loc>< x \<longrightarrow> (P x = PP)"
  shows "(\<exists> x. P x) \<equiv> (MP \<or> PP \<or> (\<exists> u \<in> U. \<exists> u'\<in> U. P (between u u')))"
  (is "_ \<equiv> (_ \<or> _ \<or> ?F)" is "?E \<equiv> ?D")
proof-
 {
   assume px: "\<exists> x. P x"
   have "MP \<or> PP \<or> (\<not> MP \<and> \<not> PP)" by blast
   moreover {assume "MP \<or> PP" hence "?D" by blast}
   moreover {assume nmi: "\<not> MP" and npi: "\<not> PP"
     from npmibnd[OF nmibnd npibnd]
     have nmpiU: "\<forall>x. \<not> MP \<and> \<not>PP \<and> P x \<longrightarrow> (\<exists> u\<in> U. \<exists> u' \<in> U. u \<^loc>\<le> x \<and> x \<^loc>\<le> u')" .
     from rinf_U[OF fU lin_dense nmpiU nmi npi px] have "?D" by blast}
   ultimately have "?D" by blast}
 moreover
 { assume "?D"
   moreover {assume m:"MP" from minf_ex[OF mi m] have "?E" .}
   moreover {assume p: "PP" from pinf_ex[OF pi p] have "?E" . }
   moreover {assume f:"?F" hence "?E" by blast}
   ultimately have "?E" by blast}
 ultimately have "?E = ?D" by blast thus "?E \<equiv> ?D" by simp
qed

lemmas minf_thms = minf_conj minf_disj minf_eq minf_neq minf_lt minf_le minf_gt minf_ge minf_P
lemmas pinf_thms = pinf_conj pinf_disj pinf_eq pinf_neq pinf_lt pinf_le pinf_gt pinf_ge pinf_P

lemmas nmi_thms = nmi_conj nmi_disj nmi_eq nmi_neq nmi_lt nmi_le nmi_gt nmi_ge nmi_P
lemmas npi_thms = npi_conj npi_disj npi_eq npi_neq npi_lt npi_le npi_gt npi_ge npi_P
lemmas lin_dense_thms = lin_dense_conj lin_dense_disj lin_dense_eq lin_dense_neq lin_dense_lt lin_dense_le lin_dense_gt lin_dense_ge lin_dense_P

lemma ferrack_axiom: "constr_dense_linear_order less_eq less between" by fact
lemma atoms:
  includes meta_term_syntax
  shows "TERM (less :: 'a \<Rightarrow> _)"
    and "TERM (less_eq :: 'a \<Rightarrow> _)"
    and "TERM (op = :: 'a \<Rightarrow> _)" .

declare ferrack_axiom [ferrack minf: minf_thms pinf: pinf_thms
    nmi: nmi_thms npi: npi_thms lindense:
    lin_dense_thms qe: fr_eq atoms: atoms]

declaration {*
let
fun simps phi = map (Morphism.thm phi) [@{thm "not_less"}, @{thm "not_le"}]
fun generic_whatis phi =
 let
  val [lt, le] = map (Morphism.term phi) [@{term "op \<^loc><"}, @{term "op \<^loc>\<le>"}]
  fun h x t =
   case term_of t of
     Const("op =", _)$y$z => if term_of x aconv y then Ferrante_Rackoff_Data.Eq
                            else Ferrante_Rackoff_Data.Nox
   | @{term "Not"}$(Const("op =", _)$y$z) => if term_of x aconv y then Ferrante_Rackoff_Data.NEq
                            else Ferrante_Rackoff_Data.Nox
   | b$y$z => if Term.could_unify (b, lt) then
                 if term_of x aconv y then Ferrante_Rackoff_Data.Lt
                 else if term_of x aconv z then Ferrante_Rackoff_Data.Gt
                 else Ferrante_Rackoff_Data.Nox
             else if Term.could_unify (b, le) then
                 if term_of x aconv y then Ferrante_Rackoff_Data.Le
                 else if term_of x aconv z then Ferrante_Rackoff_Data.Ge
                 else Ferrante_Rackoff_Data.Nox
             else Ferrante_Rackoff_Data.Nox
   | _ => Ferrante_Rackoff_Data.Nox
 in h end
 fun ss phi = HOL_ss addsimps (simps phi)
in
 Ferrante_Rackoff_Data.funs  @{thm "ferrack_axiom"}
  {isolate_conv = K (K (K Thm.reflexive)), whatis = generic_whatis, simpset = ss}
end
*}

end

use "Tools/Qelim/ferrante_rackoff.ML"

method_setup ferrack = {*
  Method.ctxt_args (Method.SIMPLE_METHOD' o FerranteRackoff.dlo_tac)
*} "Ferrante and Rackoff's algorithm for quantifier elimination in dense linear orders"

end 

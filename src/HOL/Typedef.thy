(*  Title:      HOL/Typedef.thy
    Author:     Markus Wenzel, TU Munich
*)

section \<open>HOL type definitions\<close>

theory Typedef
imports Set
keywords "typedef" :: thy_goal and "morphisms"
begin

locale type_definition =
  fixes Rep and Abs and A
  assumes Rep: "Rep x \<in> A"
    and Rep_inverse: "Abs (Rep x) = x"
    and Abs_inverse: "y \<in> A \<Longrightarrow> Rep (Abs y) = y"
  -- \<open>This will be axiomatized for each typedef!\<close>
begin

lemma Rep_inject: "Rep x = Rep y \<longleftrightarrow> x = y"
proof
  assume "Rep x = Rep y"
  then have "Abs (Rep x) = Abs (Rep y)" by (simp only:)
  moreover have "Abs (Rep x) = x" by (rule Rep_inverse)
  moreover have "Abs (Rep y) = y" by (rule Rep_inverse)
  ultimately show "x = y" by simp
next
  assume "x = y"
  then show "Rep x = Rep y" by (simp only:)
qed

lemma Abs_inject:
  assumes "x \<in> A" and "y \<in> A"
  shows "Abs x = Abs y \<longleftrightarrow> x = y"
proof
  assume "Abs x = Abs y"
  then have "Rep (Abs x) = Rep (Abs y)" by (simp only:)
  moreover from \<open>x \<in> A\<close> have "Rep (Abs x) = x" by (rule Abs_inverse)
  moreover from \<open>y \<in> A\<close> have "Rep (Abs y) = y" by (rule Abs_inverse)
  ultimately show "x = y" by simp
next
  assume "x = y"
  then show "Abs x = Abs y" by (simp only:)
qed

lemma Rep_cases [cases set]:
  assumes "y \<in> A"
    and hyp: "\<And>x. y = Rep x \<Longrightarrow> P"
  shows P
proof (rule hyp)
  from \<open>y \<in> A\<close> have "Rep (Abs y) = y" by (rule Abs_inverse)
  then show "y = Rep (Abs y)" ..
qed

lemma Abs_cases [cases type]:
  assumes r: "\<And>y. x = Abs y \<Longrightarrow> y \<in> A \<Longrightarrow> P"
  shows P
proof (rule r)
  have "Abs (Rep x) = x" by (rule Rep_inverse)
  then show "x = Abs (Rep x)" ..
  show "Rep x \<in> A" by (rule Rep)
qed

lemma Rep_induct [induct set]:
  assumes y: "y \<in> A"
    and hyp: "\<And>x. P (Rep x)"
  shows "P y"
proof -
  have "P (Rep (Abs y))" by (rule hyp)
  moreover from y have "Rep (Abs y) = y" by (rule Abs_inverse)
  ultimately show "P y" by simp
qed

lemma Abs_induct [induct type]:
  assumes r: "\<And>y. y \<in> A \<Longrightarrow> P (Abs y)"
  shows "P x"
proof -
  have "Rep x \<in> A" by (rule Rep)
  then have "P (Abs (Rep x))" by (rule r)
  moreover have "Abs (Rep x) = x" by (rule Rep_inverse)
  ultimately show "P x" by simp
qed

lemma Rep_range: "range Rep = A"
proof
  show "range Rep \<subseteq> A" using Rep by (auto simp add: image_def)
  show "A \<subseteq> range Rep"
  proof
    fix x assume "x \<in> A"
    then have "x = Rep (Abs x)" by (rule Abs_inverse [symmetric])
    then show "x \<in> range Rep" by (rule range_eqI)
  qed
qed

lemma Abs_image: "Abs ` A = UNIV"
proof
  show "Abs ` A \<subseteq> UNIV" by (rule subset_UNIV)
  show "UNIV \<subseteq> Abs ` A"
  proof
    fix x
    have "x = Abs (Rep x)" by (rule Rep_inverse [symmetric])
    moreover have "Rep x \<in> A" by (rule Rep)
    ultimately show "x \<in> Abs ` A" by (rule image_eqI)
  qed
qed

end

ML_file "Tools/typedef.ML"

end

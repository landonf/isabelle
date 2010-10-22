(*  Title:      HOLCF/Sprod.thy
    Author:     Franz Regensburger and Brian Huffman
*)

header {* The type of strict products *}

theory Sprod
imports Deflation
begin

default_sort pcpo

subsection {* Definition of strict product type *}

pcpodef (Sprod)  ('a, 'b) sprod (infixr "**" 20) =
        "{p::'a \<times> 'b. p = \<bottom> \<or> (fst p \<noteq> \<bottom> \<and> snd p \<noteq> \<bottom>)}"
by simp_all

instance sprod :: ("{chfin,pcpo}", "{chfin,pcpo}") chfin
by (rule typedef_chfin [OF type_definition_Sprod below_Sprod_def])

type_notation (xsymbols)
  sprod  ("(_ \<otimes>/ _)" [21,20] 20)
type_notation (HTML output)
  sprod  ("(_ \<otimes>/ _)" [21,20] 20)

subsection {* Definitions of constants *}

definition
  sfst :: "('a ** 'b) \<rightarrow> 'a" where
  "sfst = (\<Lambda> p. fst (Rep_Sprod p))"

definition
  ssnd :: "('a ** 'b) \<rightarrow> 'b" where
  "ssnd = (\<Lambda> p. snd (Rep_Sprod p))"

definition
  spair :: "'a \<rightarrow> 'b \<rightarrow> ('a ** 'b)" where
  "spair = (\<Lambda> a b. Abs_Sprod (strict\<cdot>b\<cdot>a, strict\<cdot>a\<cdot>b))"

definition
  ssplit :: "('a \<rightarrow> 'b \<rightarrow> 'c) \<rightarrow> ('a ** 'b) \<rightarrow> 'c" where
  "ssplit = (\<Lambda> f p. strict\<cdot>p\<cdot>(f\<cdot>(sfst\<cdot>p)\<cdot>(ssnd\<cdot>p)))"

syntax
  "_stuple" :: "['a, args] => 'a ** 'b"  ("(1'(:_,/ _:'))")
translations
  "(:x, y, z:)" == "(:x, (:y, z:):)"
  "(:x, y:)"    == "CONST spair\<cdot>x\<cdot>y"

translations
  "\<Lambda>(CONST spair\<cdot>x\<cdot>y). t" == "CONST ssplit\<cdot>(\<Lambda> x y. t)"

subsection {* Case analysis *}

lemma spair_Sprod: "(strict\<cdot>b\<cdot>a, strict\<cdot>a\<cdot>b) \<in> Sprod"
by (simp add: Sprod_def strict_conv_if)

lemma Rep_Sprod_spair: "Rep_Sprod (:a, b:) = (strict\<cdot>b\<cdot>a, strict\<cdot>a\<cdot>b)"
by (simp add: spair_def cont_Abs_Sprod Abs_Sprod_inverse spair_Sprod)

lemmas Rep_Sprod_simps =
  Rep_Sprod_inject [symmetric] below_Sprod_def
  Pair_fst_snd_eq below_prod_def
  Rep_Sprod_strict Rep_Sprod_spair

lemma sprodE [case_names bottom spair, cases type: sprod]:
  obtains "p = \<bottom>" | x y where "p = (:x, y:)" and "x \<noteq> \<bottom>" and "y \<noteq> \<bottom>"
using Rep_Sprod [of p] by (auto simp add: Sprod_def Rep_Sprod_simps)

lemma sprod_induct [case_names bottom spair, induct type: sprod]:
  "\<lbrakk>P \<bottom>; \<And>x y. \<lbrakk>x \<noteq> \<bottom>; y \<noteq> \<bottom>\<rbrakk> \<Longrightarrow> P (:x, y:)\<rbrakk> \<Longrightarrow> P x"
by (cases x, simp_all)

subsection {* Properties of \emph{spair} *}

lemma spair_strict1 [simp]: "(:\<bottom>, y:) = \<bottom>"
by (simp add: Rep_Sprod_simps)

lemma spair_strict2 [simp]: "(:x, \<bottom>:) = \<bottom>"
by (simp add: Rep_Sprod_simps)

lemma spair_strict_iff [simp]: "((:x, y:) = \<bottom>) = (x = \<bottom> \<or> y = \<bottom>)"
by (simp add: Rep_Sprod_simps strict_conv_if)

lemma spair_below_iff:
  "((:a, b:) \<sqsubseteq> (:c, d:)) = (a = \<bottom> \<or> b = \<bottom> \<or> (a \<sqsubseteq> c \<and> b \<sqsubseteq> d))"
by (simp add: Rep_Sprod_simps strict_conv_if)

lemma spair_eq_iff:
  "((:a, b:) = (:c, d:)) =
    (a = c \<and> b = d \<or> (a = \<bottom> \<or> b = \<bottom>) \<and> (c = \<bottom> \<or> d = \<bottom>))"
by (simp add: Rep_Sprod_simps strict_conv_if)

lemma spair_strict: "x = \<bottom> \<or> y = \<bottom> \<Longrightarrow> (:x, y:) = \<bottom>"
by simp

lemma spair_strict_rev: "(:x, y:) \<noteq> \<bottom> \<Longrightarrow> x \<noteq> \<bottom> \<and> y \<noteq> \<bottom>"
by simp

lemma spair_defined: "\<lbrakk>x \<noteq> \<bottom>; y \<noteq> \<bottom>\<rbrakk> \<Longrightarrow> (:x, y:) \<noteq> \<bottom>"
by simp

lemma spair_defined_rev: "(:x, y:) = \<bottom> \<Longrightarrow> x = \<bottom> \<or> y = \<bottom>"
by simp

lemma spair_eq:
  "\<lbrakk>x \<noteq> \<bottom>; y \<noteq> \<bottom>\<rbrakk> \<Longrightarrow> ((:x, y:) = (:a, b:)) = (x = a \<and> y = b)"
by (simp add: spair_eq_iff)

lemma spair_inject:
  "\<lbrakk>x \<noteq> \<bottom>; y \<noteq> \<bottom>; (:x, y:) = (:a, b:)\<rbrakk> \<Longrightarrow> x = a \<and> y = b"
by (rule spair_eq [THEN iffD1])

lemma inst_sprod_pcpo2: "UU = (:UU,UU:)"
by simp

lemma sprodE2: "(\<And>x y. p = (:x, y:) \<Longrightarrow> Q) \<Longrightarrow> Q"
by (cases p, simp only: inst_sprod_pcpo2, simp)

subsection {* Properties of \emph{sfst} and \emph{ssnd} *}

lemma sfst_strict [simp]: "sfst\<cdot>\<bottom> = \<bottom>"
by (simp add: sfst_def cont_Rep_Sprod Rep_Sprod_strict)

lemma ssnd_strict [simp]: "ssnd\<cdot>\<bottom> = \<bottom>"
by (simp add: ssnd_def cont_Rep_Sprod Rep_Sprod_strict)

lemma sfst_spair [simp]: "y \<noteq> \<bottom> \<Longrightarrow> sfst\<cdot>(:x, y:) = x"
by (simp add: sfst_def cont_Rep_Sprod Rep_Sprod_spair)

lemma ssnd_spair [simp]: "x \<noteq> \<bottom> \<Longrightarrow> ssnd\<cdot>(:x, y:) = y"
by (simp add: ssnd_def cont_Rep_Sprod Rep_Sprod_spair)

lemma sfst_defined_iff [simp]: "(sfst\<cdot>p = \<bottom>) = (p = \<bottom>)"
by (cases p, simp_all)

lemma ssnd_defined_iff [simp]: "(ssnd\<cdot>p = \<bottom>) = (p = \<bottom>)"
by (cases p, simp_all)

lemma sfst_defined: "p \<noteq> \<bottom> \<Longrightarrow> sfst\<cdot>p \<noteq> \<bottom>"
by simp

lemma ssnd_defined: "p \<noteq> \<bottom> \<Longrightarrow> ssnd\<cdot>p \<noteq> \<bottom>"
by simp

lemma spair_sfst_ssnd: "(:sfst\<cdot>p, ssnd\<cdot>p:) = p"
by (cases p, simp_all)

lemma below_sprod: "x \<sqsubseteq> y = (sfst\<cdot>x \<sqsubseteq> sfst\<cdot>y \<and> ssnd\<cdot>x \<sqsubseteq> ssnd\<cdot>y)"
apply (simp add: below_Sprod_def sfst_def ssnd_def cont_Rep_Sprod)
apply (simp only: below_prod_def)
done

lemma eq_sprod: "(x = y) = (sfst\<cdot>x = sfst\<cdot>y \<and> ssnd\<cdot>x = ssnd\<cdot>y)"
by (auto simp add: po_eq_conv below_sprod)

lemma spair_below:
  "\<lbrakk>x \<noteq> \<bottom>; y \<noteq> \<bottom>\<rbrakk> \<Longrightarrow> (:x, y:) \<sqsubseteq> (:a, b:) = (x \<sqsubseteq> a \<and> y \<sqsubseteq> b)"
apply (cases "a = \<bottom>", simp)
apply (cases "b = \<bottom>", simp)
apply (simp add: below_sprod)
done

lemma sfst_below_iff: "sfst\<cdot>x \<sqsubseteq> y = x \<sqsubseteq> (:y, ssnd\<cdot>x:)"
apply (cases "x = \<bottom>", simp, cases "y = \<bottom>", simp)
apply (simp add: below_sprod)
done

lemma ssnd_below_iff: "ssnd\<cdot>x \<sqsubseteq> y = x \<sqsubseteq> (:sfst\<cdot>x, y:)"
apply (cases "x = \<bottom>", simp, cases "y = \<bottom>", simp)
apply (simp add: below_sprod)
done

subsection {* Compactness *}

lemma compact_sfst: "compact x \<Longrightarrow> compact (sfst\<cdot>x)"
by (rule compactI, simp add: sfst_below_iff)

lemma compact_ssnd: "compact x \<Longrightarrow> compact (ssnd\<cdot>x)"
by (rule compactI, simp add: ssnd_below_iff)

lemma compact_spair: "\<lbrakk>compact x; compact y\<rbrakk> \<Longrightarrow> compact (:x, y:)"
by (rule compact_Sprod, simp add: Rep_Sprod_spair strict_conv_if)

lemma compact_spair_iff:
  "compact (:x, y:) = (x = \<bottom> \<or> y = \<bottom> \<or> (compact x \<and> compact y))"
apply (safe elim!: compact_spair)
apply (drule compact_sfst, simp)
apply (drule compact_ssnd, simp)
apply simp
apply simp
done

subsection {* Properties of \emph{ssplit} *}

lemma ssplit1 [simp]: "ssplit\<cdot>f\<cdot>\<bottom> = \<bottom>"
by (simp add: ssplit_def)

lemma ssplit2 [simp]: "\<lbrakk>x \<noteq> \<bottom>; y \<noteq> \<bottom>\<rbrakk> \<Longrightarrow> ssplit\<cdot>f\<cdot>(:x, y:) = f\<cdot>x\<cdot>y"
by (simp add: ssplit_def)

lemma ssplit3 [simp]: "ssplit\<cdot>spair\<cdot>z = z"
by (cases z, simp_all)

subsection {* Strict product preserves flatness *}

instance sprod :: (flat, flat) flat
proof
  fix x y :: "'a \<otimes> 'b"
  assume "x \<sqsubseteq> y" thus "x = \<bottom> \<or> x = y"
    apply (induct x, simp)
    apply (induct y, simp)
    apply (simp add: spair_below_iff flat_below_iff)
    done
qed

subsection {* Map function for strict products *}

definition
  sprod_map :: "('a \<rightarrow> 'b) \<rightarrow> ('c \<rightarrow> 'd) \<rightarrow> 'a \<otimes> 'c \<rightarrow> 'b \<otimes> 'd"
where
  "sprod_map = (\<Lambda> f g. ssplit\<cdot>(\<Lambda> x y. (:f\<cdot>x, g\<cdot>y:)))"

lemma sprod_map_strict [simp]: "sprod_map\<cdot>a\<cdot>b\<cdot>\<bottom> = \<bottom>"
unfolding sprod_map_def by simp

lemma sprod_map_spair [simp]:
  "x \<noteq> \<bottom> \<Longrightarrow> y \<noteq> \<bottom> \<Longrightarrow> sprod_map\<cdot>f\<cdot>g\<cdot>(:x, y:) = (:f\<cdot>x, g\<cdot>y:)"
by (simp add: sprod_map_def)

lemma sprod_map_spair':
  "f\<cdot>\<bottom> = \<bottom> \<Longrightarrow> g\<cdot>\<bottom> = \<bottom> \<Longrightarrow> sprod_map\<cdot>f\<cdot>g\<cdot>(:x, y:) = (:f\<cdot>x, g\<cdot>y:)"
by (cases "x = \<bottom> \<or> y = \<bottom>") auto

lemma sprod_map_ID: "sprod_map\<cdot>ID\<cdot>ID = ID"
unfolding sprod_map_def by (simp add: cfun_eq_iff eta_cfun)

lemma sprod_map_map:
  "\<lbrakk>f1\<cdot>\<bottom> = \<bottom>; g1\<cdot>\<bottom> = \<bottom>\<rbrakk> \<Longrightarrow>
    sprod_map\<cdot>f1\<cdot>g1\<cdot>(sprod_map\<cdot>f2\<cdot>g2\<cdot>p) =
     sprod_map\<cdot>(\<Lambda> x. f1\<cdot>(f2\<cdot>x))\<cdot>(\<Lambda> x. g1\<cdot>(g2\<cdot>x))\<cdot>p"
apply (induct p, simp)
apply (case_tac "f2\<cdot>x = \<bottom>", simp)
apply (case_tac "g2\<cdot>y = \<bottom>", simp)
apply simp
done

lemma ep_pair_sprod_map:
  assumes "ep_pair e1 p1" and "ep_pair e2 p2"
  shows "ep_pair (sprod_map\<cdot>e1\<cdot>e2) (sprod_map\<cdot>p1\<cdot>p2)"
proof
  interpret e1p1: pcpo_ep_pair e1 p1 unfolding pcpo_ep_pair_def by fact
  interpret e2p2: pcpo_ep_pair e2 p2 unfolding pcpo_ep_pair_def by fact
  fix x show "sprod_map\<cdot>p1\<cdot>p2\<cdot>(sprod_map\<cdot>e1\<cdot>e2\<cdot>x) = x"
    by (induct x) simp_all
  fix y show "sprod_map\<cdot>e1\<cdot>e2\<cdot>(sprod_map\<cdot>p1\<cdot>p2\<cdot>y) \<sqsubseteq> y"
    apply (induct y, simp)
    apply (case_tac "p1\<cdot>x = \<bottom>", simp, case_tac "p2\<cdot>y = \<bottom>", simp)
    apply (simp add: monofun_cfun e1p1.e_p_below e2p2.e_p_below)
    done
qed

lemma deflation_sprod_map:
  assumes "deflation d1" and "deflation d2"
  shows "deflation (sprod_map\<cdot>d1\<cdot>d2)"
proof
  interpret d1: deflation d1 by fact
  interpret d2: deflation d2 by fact
  fix x
  show "sprod_map\<cdot>d1\<cdot>d2\<cdot>(sprod_map\<cdot>d1\<cdot>d2\<cdot>x) = sprod_map\<cdot>d1\<cdot>d2\<cdot>x"
    apply (induct x, simp)
    apply (case_tac "d1\<cdot>x = \<bottom>", simp, case_tac "d2\<cdot>y = \<bottom>", simp)
    apply (simp add: d1.idem d2.idem)
    done
  show "sprod_map\<cdot>d1\<cdot>d2\<cdot>x \<sqsubseteq> x"
    apply (induct x, simp)
    apply (simp add: monofun_cfun d1.below d2.below)
    done
qed

lemma finite_deflation_sprod_map:
  assumes "finite_deflation d1" and "finite_deflation d2"
  shows "finite_deflation (sprod_map\<cdot>d1\<cdot>d2)"
proof (rule finite_deflation_intro)
  interpret d1: finite_deflation d1 by fact
  interpret d2: finite_deflation d2 by fact
  have "deflation d1" and "deflation d2" by fact+
  thus "deflation (sprod_map\<cdot>d1\<cdot>d2)" by (rule deflation_sprod_map)
  have "{x. sprod_map\<cdot>d1\<cdot>d2\<cdot>x = x} \<subseteq> insert \<bottom>
        ((\<lambda>(x, y). (:x, y:)) ` ({x. d1\<cdot>x = x} \<times> {y. d2\<cdot>y = y}))"
    by (rule subsetI, case_tac x, auto simp add: spair_eq_iff)
  thus "finite {x. sprod_map\<cdot>d1\<cdot>d2\<cdot>x = x}"
    by (rule finite_subset, simp add: d1.finite_fixes d2.finite_fixes)
qed

end

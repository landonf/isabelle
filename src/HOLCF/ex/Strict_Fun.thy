(*  Title:      HOLCF/ex/Strict_Fun.thy
    Author:     Brian Huffman
*)

header {* The Strict Function Type *}

theory Strict_Fun
imports HOLCF
begin

pcpodef (open) ('a, 'b) sfun (infixr "->!" 0)
  = "{f :: 'a \<rightarrow> 'b. f\<cdot>\<bottom> = \<bottom>}"
by simp_all

type_notation (xsymbols)
  sfun  (infixr "\<rightarrow>!" 0)

text {* TODO: Define nice syntax for abstraction, application. *}

definition
  sfun_abs :: "('a \<rightarrow> 'b) \<rightarrow> ('a \<rightarrow>! 'b)"
where
  "sfun_abs = (\<Lambda> f. Abs_sfun (strictify\<cdot>f))"

definition
  sfun_rep :: "('a \<rightarrow>! 'b) \<rightarrow> 'a \<rightarrow> 'b"
where
  "sfun_rep = (\<Lambda> f. Rep_sfun f)"

lemma sfun_rep_beta: "sfun_rep\<cdot>f = Rep_sfun f"
  unfolding sfun_rep_def by (simp add: cont_Rep_sfun)

lemma sfun_rep_strict1 [simp]: "sfun_rep\<cdot>\<bottom> = \<bottom>"
  unfolding sfun_rep_beta by (rule Rep_sfun_strict)

lemma sfun_rep_strict2 [simp]: "sfun_rep\<cdot>f\<cdot>\<bottom> = \<bottom>"
  unfolding sfun_rep_beta by (rule Rep_sfun [simplified])

lemma strictify_cancel: "f\<cdot>\<bottom> = \<bottom> \<Longrightarrow> strictify\<cdot>f = f"
  by (simp add: expand_cfun_eq strictify_conv_if)

lemma sfun_abs_sfun_rep: "sfun_abs\<cdot>(sfun_rep\<cdot>f) = f"
  unfolding sfun_abs_def sfun_rep_def
  apply (simp add: cont_Abs_sfun cont_Rep_sfun)
  apply (simp add: Rep_sfun_inject [symmetric] Abs_sfun_inverse)
  apply (simp add: expand_cfun_eq strictify_conv_if)
  apply (simp add: Rep_sfun [simplified])
  done

lemma sfun_rep_sfun_abs [simp]: "sfun_rep\<cdot>(sfun_abs\<cdot>f) = strictify\<cdot>f"
  unfolding sfun_abs_def sfun_rep_def
  apply (simp add: cont_Abs_sfun cont_Rep_sfun)
  apply (simp add: Abs_sfun_inverse)
  done

lemma ep_pair_sfun: "ep_pair sfun_rep sfun_abs"
apply default
apply (rule sfun_abs_sfun_rep)
apply (simp add: expand_cfun_below strictify_conv_if)
done

interpretation sfun: ep_pair sfun_rep sfun_abs
  by (rule ep_pair_sfun)

subsection {* Map functional for strict function space *}

definition
  sfun_map :: "('b \<rightarrow> 'a) \<rightarrow> ('c \<rightarrow> 'd) \<rightarrow> ('a \<rightarrow>! 'c) \<rightarrow> ('b \<rightarrow>! 'd)"
where
  "sfun_map = (\<Lambda> a b. sfun_abs oo cfun_map\<cdot>a\<cdot>b oo sfun_rep)"

lemma sfun_map_ID: "sfun_map\<cdot>ID\<cdot>ID = ID"
  unfolding sfun_map_def
  by (simp add: cfun_map_ID expand_cfun_eq)

lemma sfun_map_map:
  assumes "f2\<cdot>\<bottom> = \<bottom>" and "g2\<cdot>\<bottom> = \<bottom>" shows
  "sfun_map\<cdot>f1\<cdot>g1\<cdot>(sfun_map\<cdot>f2\<cdot>g2\<cdot>p) =
    sfun_map\<cdot>(\<Lambda> x. f2\<cdot>(f1\<cdot>x))\<cdot>(\<Lambda> x. g1\<cdot>(g2\<cdot>x))\<cdot>p"
unfolding sfun_map_def
by (simp add: expand_cfun_eq strictify_cancel assms cfun_map_map)

lemma ep_pair_sfun_map:
  assumes 1: "ep_pair e1 p1"
  assumes 2: "ep_pair e2 p2"
  shows "ep_pair (sfun_map\<cdot>p1\<cdot>e2) (sfun_map\<cdot>e1\<cdot>p2)"
proof
  interpret e1p1: pcpo_ep_pair e1 p1
    unfolding pcpo_ep_pair_def by fact
  interpret e2p2: pcpo_ep_pair e2 p2
    unfolding pcpo_ep_pair_def by fact
  fix f show "sfun_map\<cdot>e1\<cdot>p2\<cdot>(sfun_map\<cdot>p1\<cdot>e2\<cdot>f) = f"
    unfolding sfun_map_def
    apply (simp add: sfun.e_eq_iff [symmetric] strictify_cancel)
    apply (rule ep_pair.e_inverse)
    apply (rule ep_pair_cfun_map [OF 1 2])
    done
  fix g show "sfun_map\<cdot>p1\<cdot>e2\<cdot>(sfun_map\<cdot>e1\<cdot>p2\<cdot>g) \<sqsubseteq> g"
    unfolding sfun_map_def
    apply (simp add: sfun.e_below_iff [symmetric] strictify_cancel)
    apply (rule ep_pair.e_p_below)
    apply (rule ep_pair_cfun_map [OF 1 2])
    done
qed

lemma deflation_sfun_map:
  assumes 1: "deflation d1"
  assumes 2: "deflation d2"
  shows "deflation (sfun_map\<cdot>d1\<cdot>d2)"
apply (simp add: sfun_map_def)
apply (rule deflation.intro)
apply simp
apply (subst strictify_cancel)
apply (simp add: cfun_map_def deflation_strict 1 2)
apply (simp add: cfun_map_def deflation.idem 1 2)
apply (simp add: sfun.e_below_iff [symmetric])
apply (subst strictify_cancel)
apply (simp add: cfun_map_def deflation_strict 1 2)
apply (rule deflation.below)
apply (rule deflation_cfun_map [OF 1 2])
done

lemma finite_deflation_sfun_map:
  assumes 1: "finite_deflation d1"
  assumes 2: "finite_deflation d2"
  shows "finite_deflation (sfun_map\<cdot>d1\<cdot>d2)"
proof (intro finite_deflation.intro finite_deflation_axioms.intro)
  interpret d1: finite_deflation d1 by fact
  interpret d2: finite_deflation d2 by fact
  have "deflation d1" and "deflation d2" by fact+
  thus "deflation (sfun_map\<cdot>d1\<cdot>d2)" by (rule deflation_sfun_map)
  from 1 2 have "finite_deflation (cfun_map\<cdot>d1\<cdot>d2)"
    by (rule finite_deflation_cfun_map)
  then have "finite {f. cfun_map\<cdot>d1\<cdot>d2\<cdot>f = f}"
    by (rule finite_deflation.finite_fixes)
  moreover have "inj (\<lambda>f. sfun_rep\<cdot>f)"
    by (rule inj_onI, simp)
  ultimately have "finite ((\<lambda>f. sfun_rep\<cdot>f) -` {f. cfun_map\<cdot>d1\<cdot>d2\<cdot>f = f})"
    by (rule finite_vimageI)
  then show "finite {f. sfun_map\<cdot>d1\<cdot>d2\<cdot>f = f}"
    unfolding sfun_map_def sfun.e_eq_iff [symmetric]
    by (simp add: strictify_cancel
         deflation_strict `deflation d1` `deflation d2`)
qed

subsection {* Strict function space is bifinite *}

instantiation sfun :: (bifinite, bifinite) bifinite
begin

definition
  "approx = (\<lambda>i. sfun_map\<cdot>(approx i)\<cdot>(approx i))"

instance proof
  show "chain (approx :: nat \<Rightarrow> ('a \<rightarrow>! 'b) \<rightarrow> ('a \<rightarrow>! 'b))"
    unfolding approx_sfun_def by simp
next
  fix x :: "'a \<rightarrow>! 'b"
  show "(\<Squnion>i. approx i\<cdot>x) = x"
    unfolding approx_sfun_def
    by (simp add: lub_distribs sfun_map_ID [unfolded ID_def])
next
  fix i :: nat and x :: "'a \<rightarrow>! 'b"
  show "approx i\<cdot>(approx i\<cdot>x) = approx i\<cdot>x"
    unfolding approx_sfun_def
    by (intro deflation.idem deflation_sfun_map deflation_approx)
next
  fix i :: nat
  show "finite {x::'a \<rightarrow>! 'b. approx i\<cdot>x = x}"
    unfolding approx_sfun_def
    by (intro finite_deflation.finite_fixes
              finite_deflation_sfun_map
              finite_deflation_approx)
qed

end

subsection {* Strict function space is representable *}

instantiation sfun :: (rep, rep) rep
begin

definition
  "emb = udom_emb oo sfun_map\<cdot>prj\<cdot>emb"

definition
  "prj = sfun_map\<cdot>emb\<cdot>prj oo udom_prj"

instance
apply (default, unfold emb_sfun_def prj_sfun_def)
apply (rule ep_pair_comp)
apply (rule ep_pair_sfun_map)
apply (rule ep_pair_emb_prj)
apply (rule ep_pair_emb_prj)
apply (rule ep_pair_udom)
done

end

text {*
  A deflation constructor lets us configure the domain package to work
  with the strict function space type constructor.
*}

definition
  sfun_defl :: "TypeRep \<rightarrow> TypeRep \<rightarrow> TypeRep"
where
  "sfun_defl = TypeRep_fun2 sfun_map"

lemma cast_sfun_defl:
  "cast\<cdot>(sfun_defl\<cdot>A\<cdot>B) = udom_emb oo sfun_map\<cdot>(cast\<cdot>A)\<cdot>(cast\<cdot>B) oo udom_prj"
unfolding sfun_defl_def
apply (rule cast_TypeRep_fun2)
apply (erule (1) finite_deflation_sfun_map)
done

lemma REP_sfun: "REP('a::rep \<rightarrow>! 'b::rep) = sfun_defl\<cdot>REP('a)\<cdot>REP('b)"
apply (rule cast_eq_imp_eq, rule ext_cfun)
apply (simp add: cast_REP cast_sfun_defl)
apply (simp only: prj_sfun_def emb_sfun_def)
apply (simp add: sfun_map_def cfun_map_def strictify_cancel)
done

lemma isodefl_sfun:
  "isodefl d1 t1 \<Longrightarrow> isodefl d2 t2 \<Longrightarrow>
    isodefl (sfun_map\<cdot>d1\<cdot>d2) (sfun_defl\<cdot>t1\<cdot>t2)"
apply (rule isodeflI)
apply (simp add: cast_sfun_defl cast_isodefl)
apply (simp add: emb_sfun_def prj_sfun_def)
apply (simp add: sfun_map_map deflation_strict [OF isodefl_imp_deflation])
done

setup {*
  Domain_Isomorphism.add_type_constructor
    (@{type_name "sfun"}, @{term sfun_defl}, @{const_name sfun_map},
        @{thm REP_sfun}, @{thm isodefl_sfun}, @{thm sfun_map_ID})
*}

end

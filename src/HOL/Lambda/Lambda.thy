(*  Title:      HOL/Lambda/Lambda.thy
    ID:         $Id$
    Author:     Tobias Nipkow
    Copyright   1995 TU Muenchen
*)

header {* Basic definitions of Lambda-calculus *}

theory Lambda = Main:


subsection {* Lambda-terms in de Bruijn notation and substitution *}

datatype dB =
    Var nat
  | App dB dB (infixl "\<degree>" 200)
  | Abs dB

consts
  subst :: "[dB, dB, nat] => dB"  ("_[_'/_]" [300, 0, 0] 300)
  lift :: "[dB, nat] => dB"

primrec
  "lift (Var i) k = (if i < k then Var i else Var (i + 1))"
  "lift (s \<degree> t) k = lift s k \<degree> lift t k"
  "lift (Abs s) k = Abs (lift s (k + 1))"

primrec  (* FIXME base names *)
  subst_Var: "(Var i)[s/k] =
    (if k < i then Var (i - 1) else if i = k then s else Var i)"
  subst_App: "(t \<degree> u)[s/k] = t[s/k] \<degree> u[s/k]"
  subst_Abs: "(Abs t)[s/k] = Abs (t[lift s 0 / k+1])"

declare subst_Var [simp del]

text {* Optimized versions of @{term subst} and @{term lift}. *}

consts
  substn :: "[dB, dB, nat] => dB"
  liftn :: "[nat, dB, nat] => dB"

primrec
  "liftn n (Var i) k = (if i < k then Var i else Var (i + n))"
  "liftn n (s \<degree> t) k = liftn n s k \<degree> liftn n t k"
  "liftn n (Abs s) k = Abs (liftn n s (k + 1))"

primrec
  "substn (Var i) s k =
    (if k < i then Var (i - 1) else if i = k then liftn k s 0 else Var i)"
  "substn (t \<degree> u) s k = substn t s k \<degree> substn u s k"
  "substn (Abs t) s k = Abs (substn t s (k + 1))"


subsection {* Beta-reduction *}

consts
  beta :: "(dB \<times> dB) set"

syntax
  "_beta" :: "[dB, dB] => bool"  (infixl "->" 50)
  "_beta_rtrancl" :: "[dB, dB] => bool"  (infixl "->>" 50)
syntax (latex)
  "_beta" :: "[dB, dB] => bool"  (infixl "\<rightarrow>\<^sub>\<beta>" 50)
  "_beta_rtrancl" :: "[dB, dB] => bool"  (infixl "\<rightarrow>\<^sub>\<beta>\<^sup>*" 50)
translations
  "s \<rightarrow>\<^sub>\<beta> t" == "(s, t) \<in> beta"
  "s \<rightarrow>\<^sub>\<beta>\<^sup>* t" == "(s, t) \<in> beta^*"

inductive beta
  intros
    beta [simp, intro!]: "Abs s \<degree> t \<rightarrow>\<^sub>\<beta> s[t/0]"
    appL [simp, intro!]: "s \<rightarrow>\<^sub>\<beta> t ==> s \<degree> u \<rightarrow>\<^sub>\<beta> t \<degree> u"
    appR [simp, intro!]: "s \<rightarrow>\<^sub>\<beta> t ==> u \<degree> s \<rightarrow>\<^sub>\<beta> u \<degree> t"
    abs [simp, intro!]: "s \<rightarrow>\<^sub>\<beta> t ==> Abs s \<rightarrow>\<^sub>\<beta> Abs t"

inductive_cases beta_cases [elim!]:
  "Var i \<rightarrow>\<^sub>\<beta> t"
  "Abs r \<rightarrow>\<^sub>\<beta> s"
  "s \<degree> t \<rightarrow>\<^sub>\<beta> u"

declare if_not_P [simp] not_less_eq [simp]
  -- {* don't add @{text "r_into_rtrancl[intro!]"} *}


subsection {* Congruence rules *}

lemma rtrancl_beta_Abs [intro!]:
    "s \<rightarrow>\<^sub>\<beta>\<^sup>* s' ==> Abs s \<rightarrow>\<^sub>\<beta>\<^sup>* Abs s'"
  apply (erule rtrancl_induct)
   apply (blast intro: rtrancl_into_rtrancl)+
  done

lemma rtrancl_beta_AppL:
    "s \<rightarrow>\<^sub>\<beta>\<^sup>* s' ==> s \<degree> t \<rightarrow>\<^sub>\<beta>\<^sup>* s' \<degree> t"
  apply (erule rtrancl_induct)
   apply (blast intro: rtrancl_into_rtrancl)+
  done

lemma rtrancl_beta_AppR:
    "t \<rightarrow>\<^sub>\<beta>\<^sup>* t' ==> s \<degree> t \<rightarrow>\<^sub>\<beta>\<^sup>* s \<degree> t'"
  apply (erule rtrancl_induct)
   apply (blast intro: rtrancl_into_rtrancl)+
  done

lemma rtrancl_beta_App [intro]:
    "[| s \<rightarrow>\<^sub>\<beta>\<^sup>* s'; t \<rightarrow>\<^sub>\<beta>\<^sup>* t' |] ==> s \<degree> t \<rightarrow>\<^sub>\<beta>\<^sup>* s' \<degree> t'"
  apply (blast intro!: rtrancl_beta_AppL rtrancl_beta_AppR
    intro: rtrancl_trans)
  done


subsection {* Substitution-lemmas *}

lemma subst_eq [simp]: "(Var k)[u/k] = u"
  apply (simp add: subst_Var)
  done

lemma subst_gt [simp]: "i < j ==> (Var j)[u/i] = Var (j - 1)"
  apply (simp add: subst_Var)
  done

lemma subst_lt [simp]: "j < i ==> (Var j)[u/i] = Var j"
  apply (simp add: subst_Var)
  done

lemma lift_lift [rule_format]:
    "\<forall>i k. i < k + 1 --> lift (lift t i) (Suc k) = lift (lift t k) i"
  apply (induct_tac t)
    apply auto
  done

lemma lift_subst [simp]:
    "\<forall>i j s. j < i + 1 --> lift (t[s/j]) i = (lift t (i + 1)) [lift s i / j]"
  apply (induct_tac t)
    apply (simp_all add: diff_Suc subst_Var lift_lift split: nat.split)
  done

lemma lift_subst_lt:
    "\<forall>i j s. i < j + 1 --> lift (t[s/j]) i = (lift t i) [lift s i / j + 1]"
  apply (induct_tac t)
    apply (simp_all add: subst_Var lift_lift)
  done

lemma subst_lift [simp]:
    "\<forall>k s. (lift t k)[s/k] = t"
  apply (induct_tac t)
    apply simp_all
  done

lemma subst_subst [rule_format]:
    "\<forall>i j u v. i < j + 1 --> t[lift v i / Suc j][u[v/j]/i] = t[u/i][v/j]"
  apply (induct_tac t)
    apply (simp_all
      add: diff_Suc subst_Var lift_lift [symmetric] lift_subst_lt
      split: nat.split)
  done


subsection {* Equivalence proof for optimized substitution *}

lemma liftn_0 [simp]: "\<forall>k. liftn 0 t k = t"
  apply (induct_tac t)
    apply (simp_all add: subst_Var)
  done

lemma liftn_lift [simp]:
    "\<forall>k. liftn (Suc n) t k = lift (liftn n t k) k"
  apply (induct_tac t)
    apply (simp_all add: subst_Var)
  done

lemma substn_subst_n [simp]:
    "\<forall>n. substn t s n = t[liftn n s 0 / n]"
  apply (induct_tac t)
    apply (simp_all add: subst_Var)
  done

theorem substn_subst_0: "substn t s 0 = t[s/0]"
  apply simp
  done


subsection {* Preservation theorems *}

text {* Not used in Church-Rosser proof, but in Strong
  Normalization. \medskip *}

theorem subst_preserves_beta [simp]:
    "r \<rightarrow>\<^sub>\<beta> s ==> (\<And>t i. r[t/i] \<rightarrow>\<^sub>\<beta> s[t/i])"
  apply (induct set: beta)
     apply (simp_all add: subst_subst [symmetric])
  done

theorem subst_preserves_beta': "r \<rightarrow>\<^sub>\<beta>\<^sup>* s ==> r[t/i] \<rightarrow>\<^sub>\<beta>\<^sup>* s[t/i]"
  apply (erule rtrancl.induct)
  apply (rule rtrancl_refl)
  apply (erule rtrancl_into_rtrancl)
  apply (erule subst_preserves_beta)
  done

theorem lift_preserves_beta [simp]:
    "r \<rightarrow>\<^sub>\<beta> s ==> (\<And>i. lift r i \<rightarrow>\<^sub>\<beta> lift s i)"
  by (induct set: beta) auto

theorem lift_preserves_beta': "r \<rightarrow>\<^sub>\<beta>\<^sup>* s ==> lift r i \<rightarrow>\<^sub>\<beta>\<^sup>* lift s i"
  apply (erule rtrancl.induct)
  apply (rule rtrancl_refl)
  apply (erule rtrancl_into_rtrancl)
  apply (erule lift_preserves_beta)
  done

theorem subst_preserves_beta2 [simp]:
    "\<And>r s i. r \<rightarrow>\<^sub>\<beta> s ==> t[r/i] \<rightarrow>\<^sub>\<beta>\<^sup>* t[s/i]"
  apply (induct t)
    apply (simp add: subst_Var r_into_rtrancl)
   apply (simp add: rtrancl_beta_App)
  apply (simp add: rtrancl_beta_Abs)
  done

theorem subst_preserves_beta2': "r \<rightarrow>\<^sub>\<beta>\<^sup>* s ==> t[r/i] \<rightarrow>\<^sub>\<beta>\<^sup>* t[s/i]"
  apply (erule rtrancl.induct)
  apply (rule rtrancl_refl)
  apply (erule rtrancl_trans)
  apply (erule subst_preserves_beta2)
  done

end

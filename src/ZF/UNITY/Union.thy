(*  Title:      ZF/UNITY/Union.thy
    Author:     Sidi O Ehmety, Computer Laboratory
    Copyright   2001  University of Cambridge

Unions of programs

Partly from Misra's Chapter 5 \<in> Asynchronous Compositions of Programs

Theory ported form HOL..

*)

theory Union imports SubstAx FP
begin

definition
  (*FIXME: conjoin Init(F) \<inter> Init(G) \<noteq> 0 *)
  ok :: "[i, i] => o"     (infixl "ok" 65)  where
    "F ok G == Acts(F) \<subseteq> AllowedActs(G) &
               Acts(G) \<subseteq> AllowedActs(F)"

definition
  (*FIXME: conjoin (\<Inter>i \<in> I. Init(F(i))) \<noteq> 0 *)
  OK  :: "[i, i=>i] => o"  where
    "OK(I,F) == (\<forall>i \<in> I. \<forall>j \<in> I-{i}. Acts(F(i)) \<subseteq> AllowedActs(F(j)))"

definition
  JOIN  :: "[i, i=>i] => i"  where
  "JOIN(I,F) == if I = 0 then SKIP else
                 mk_program(\<Inter>i \<in> I. Init(F(i)), \<Union>i \<in> I. Acts(F(i)),
                 \<Inter>i \<in> I. AllowedActs(F(i)))"

definition
  Join :: "[i, i] => i"    (infixl "Join" 65)  where
  "F Join G == mk_program (Init(F) \<inter> Init(G), Acts(F) \<union> Acts(G),
                                AllowedActs(F) \<inter> AllowedActs(G))"
definition
  (*Characterizes safety properties.  Used with specifying AllowedActs*)
  safety_prop :: "i => o"  where
  "safety_prop(X) == X\<subseteq>program &
      SKIP \<in> X & (\<forall>G \<in> program. Acts(G) \<subseteq> (\<Union>F \<in> X. Acts(F)) \<longrightarrow> G \<in> X)"

notation (xsymbols)
  SKIP  ("\<bottom>") and
  Join  (infixl "\<squnion>" 65)

syntax
  "_JOIN1"     :: "[pttrns, i] => i"         ("(3JN _./ _)" 10)
  "_JOIN"      :: "[pttrn, i, i] => i"       ("(3JN _ \<in> _./ _)" 10)
syntax (xsymbols)
  "_JOIN1"  :: "[pttrns, i] => i"     ("(3\<Squnion> _./ _)" 10)
  "_JOIN"   :: "[pttrn, i, i] => i"   ("(3\<Squnion> _ \<in> _./ _)" 10)

translations
  "JN x \<in> A. B"   == "CONST JOIN(A, (%x. B))"
  "JN x y. B"   == "JN x. JN y. B"
  "JN x. B"     == "CONST JOIN(CONST state,(%x. B))"


subsection\<open>SKIP\<close>

lemma reachable_SKIP [simp]: "reachable(SKIP) = state"
by (force elim: reachable.induct intro: reachable.intros)

text\<open>Elimination programify from ok and Join\<close>

lemma ok_programify_left [iff]: "programify(F) ok G \<longleftrightarrow> F ok G"
by (simp add: ok_def)

lemma ok_programify_right [iff]: "F ok programify(G) \<longleftrightarrow> F ok G"
by (simp add: ok_def)

lemma Join_programify_left [simp]: "programify(F) Join G = F Join G"
by (simp add: Join_def)

lemma Join_programify_right [simp]: "F Join programify(G) = F Join G"
by (simp add: Join_def)

subsection\<open>SKIP and safety properties\<close>

lemma SKIP_in_constrains_iff [iff]: "(SKIP \<in> A co B) \<longleftrightarrow> (A\<subseteq>B & st_set(A))"
by (unfold constrains_def st_set_def, auto)

lemma SKIP_in_Constrains_iff [iff]: "(SKIP \<in> A Co B)\<longleftrightarrow> (state \<inter> A\<subseteq>B)"
by (unfold Constrains_def, auto)

lemma SKIP_in_stable [iff]: "SKIP \<in> stable(A) \<longleftrightarrow> st_set(A)"
by (auto simp add: stable_def)

lemma SKIP_in_Stable [iff]: "SKIP \<in> Stable(A)"
by (unfold Stable_def, auto)

subsection\<open>Join and JOIN types\<close>

lemma Join_in_program [iff,TC]: "F Join G \<in> program"
by (unfold Join_def, auto)

lemma JOIN_in_program [iff,TC]: "JOIN(I,F) \<in> program"
by (unfold JOIN_def, auto)

subsection\<open>Init, Acts, and AllowedActs of Join and JOIN\<close>
lemma Init_Join [simp]: "Init(F Join G) = Init(F) \<inter> Init(G)"
by (simp add: Int_assoc Join_def)

lemma Acts_Join [simp]: "Acts(F Join G) = Acts(F) \<union> Acts(G)"
by (simp add: Int_Un_distrib2 cons_absorb Join_def)

lemma AllowedActs_Join [simp]: "AllowedActs(F Join G) =
  AllowedActs(F) \<inter> AllowedActs(G)"
apply (simp add: Int_assoc cons_absorb Join_def)
done

subsection\<open>Join's algebraic laws\<close>

lemma Join_commute: "F Join G = G Join F"
by (simp add: Join_def Un_commute Int_commute)

lemma Join_left_commute: "A Join (B Join C) = B Join (A Join C)"
apply (simp add: Join_def Int_Un_distrib2 cons_absorb)
apply (simp add: Un_ac Int_ac Int_Un_distrib2 cons_absorb)
done

lemma Join_assoc: "(F Join G) Join H = F Join (G Join H)"
by (simp add: Un_ac Join_def cons_absorb Int_assoc Int_Un_distrib2)

subsection\<open>Needed below\<close>
lemma cons_id [simp]: "cons(id(state), Pow(state * state)) = Pow(state*state)"
by auto

lemma Join_SKIP_left [simp]: "SKIP Join F = programify(F)"
apply (unfold Join_def SKIP_def)
apply (auto simp add: Int_absorb cons_eq)
done

lemma Join_SKIP_right [simp]: "F Join SKIP =  programify(F)"
apply (subst Join_commute)
apply (simp add: Join_SKIP_left)
done

lemma Join_absorb [simp]: "F Join F = programify(F)"
by (rule program_equalityI, auto)

lemma Join_left_absorb: "F Join (F Join G) = F Join G"
by (simp add: Join_assoc [symmetric])

subsection\<open>Join is an AC-operator\<close>
lemmas Join_ac = Join_assoc Join_left_absorb Join_commute Join_left_commute

subsection\<open>Eliminating programify form JN and OK expressions\<close>

lemma OK_programify [iff]: "OK(I, %x. programify(F(x))) \<longleftrightarrow> OK(I, F)"
by (simp add: OK_def)

lemma JN_programify [iff]: "JOIN(I, %x. programify(F(x))) = JOIN(I, F)"
by (simp add: JOIN_def)


subsection\<open>JN\<close>

lemma JN_empty [simp]: "JOIN(0, F) = SKIP"
by (unfold JOIN_def, auto)

lemma Init_JN [simp]:
     "Init(\<Squnion>i \<in> I. F(i)) = (if I=0 then state else (\<Inter>i \<in> I. Init(F(i))))"
by (simp add: JOIN_def INT_extend_simps del: INT_simps)

lemma Acts_JN [simp]:
     "Acts(JOIN(I,F)) = cons(id(state), \<Union>i \<in> I.  Acts(F(i)))"
apply (unfold JOIN_def)
apply (auto simp del: INT_simps UN_simps)
apply (rule equalityI)
apply (auto dest: Acts_type [THEN subsetD])
done

lemma AllowedActs_JN [simp]:
     "AllowedActs(\<Squnion>i \<in> I. F(i)) =
      (if I=0 then Pow(state*state) else (\<Inter>i \<in> I. AllowedActs(F(i))))"
apply (unfold JOIN_def, auto)
apply (rule equalityI)
apply (auto elim!: not_emptyE dest: AllowedActs_type [THEN subsetD])
done

lemma JN_cons [simp]: "(\<Squnion>i \<in> cons(a,I). F(i)) = F(a) Join (\<Squnion>i \<in> I. F(i))"
by (rule program_equalityI, auto)

lemma JN_cong [cong]:
    "[| I=J;  !!i. i \<in> J ==> F(i) = G(i) |] ==>
     (\<Squnion>i \<in> I. F(i)) = (\<Squnion>i \<in> J. G(i))"
by (simp add: JOIN_def)



subsection\<open>JN laws\<close>
lemma JN_absorb: "k \<in> I ==>F(k) Join (\<Squnion>i \<in> I. F(i)) = (\<Squnion>i \<in> I. F(i))"
apply (subst JN_cons [symmetric])
apply (auto simp add: cons_absorb)
done

lemma JN_Un: "(\<Squnion>i \<in> I \<union> J. F(i)) = ((\<Squnion>i \<in> I. F(i)) Join (\<Squnion>i \<in> J. F(i)))"
apply (rule program_equalityI)
apply (simp_all add: UN_Un INT_Un)
apply (simp_all del: INT_simps add: INT_extend_simps, blast)
done

lemma JN_constant: "(\<Squnion>i \<in> I. c) = (if I=0 then SKIP else programify(c))"
by (rule program_equalityI, auto)

lemma JN_Join_distrib:
     "(\<Squnion>i \<in> I. F(i) Join G(i)) = (\<Squnion>i \<in> I. F(i))  Join  (\<Squnion>i \<in> I. G(i))"
apply (rule program_equalityI)
apply (simp_all add: INT_Int_distrib, blast)
done

lemma JN_Join_miniscope: "(\<Squnion>i \<in> I. F(i) Join G) = ((\<Squnion>i \<in> I. F(i) Join G))"
by (simp add: JN_Join_distrib JN_constant)

text\<open>Used to prove guarantees_JN_I\<close>
lemma JN_Join_diff: "i \<in> I==>F(i) Join JOIN(I - {i}, F) = JOIN(I, F)"
apply (rule program_equalityI)
apply (auto elim!: not_emptyE)
done

subsection\<open>Safety: co, stable, FP\<close>


(*Fails if I=0 because it collapses to SKIP \<in> A co B, i.e. to A\<subseteq>B.  So an
  alternative precondition is A\<subseteq>B, but most proofs using this rule require
  I to be nonempty for other reasons anyway.*)

lemma JN_constrains:
 "i \<in> I==>(\<Squnion>i \<in> I. F(i)) \<in> A co B \<longleftrightarrow> (\<forall>i \<in> I. programify(F(i)) \<in> A co B)"

apply (unfold constrains_def JOIN_def st_set_def, auto)
prefer 2 apply blast
apply (rename_tac j act y z)
apply (cut_tac F = "F (j) " in Acts_type)
apply (drule_tac x = act in bspec, auto)
done

lemma Join_constrains [iff]:
     "(F Join G \<in> A co B) \<longleftrightarrow> (programify(F) \<in> A co B & programify(G) \<in> A co B)"
by (auto simp add: constrains_def)

lemma Join_unless [iff]:
     "(F Join G \<in> A unless B) \<longleftrightarrow>
    (programify(F) \<in> A unless B & programify(G) \<in> A unless B)"
by (simp add: Join_constrains unless_def)


(*Analogous weak versions FAIL; see Misra [1994] 5.4.1, Substitution Axiom.
  reachable (F Join G) could be much bigger than reachable F, reachable G
*)

lemma Join_constrains_weaken:
     "[| F \<in> A co A';  G \<in> B co B' |]
      ==> F Join G \<in> (A \<inter> B) co (A' \<union> B')"
apply (subgoal_tac "st_set (A) & st_set (B) & F \<in> program & G \<in> program")
prefer 2 apply (blast dest: constrainsD2, simp)
apply (blast intro: constrains_weaken)
done

(*If I=0, it degenerates to SKIP \<in> state co 0, which is false.*)
lemma JN_constrains_weaken:
  assumes major: "(!!i. i \<in> I ==> F(i) \<in> A(i) co A'(i))"
      and minor: "i \<in> I"
  shows "(\<Squnion>i \<in> I. F(i)) \<in> (\<Inter>i \<in> I. A(i)) co (\<Union>i \<in> I. A'(i))"
apply (cut_tac minor)
apply (simp (no_asm_simp) add: JN_constrains)
apply clarify
apply (rename_tac "j")
apply (frule_tac i = j in major)
apply (frule constrainsD2, simp)
apply (blast intro: constrains_weaken)
done

lemma JN_stable:
     "(\<Squnion>i \<in> I. F(i)) \<in>  stable(A) \<longleftrightarrow> ((\<forall>i \<in> I. programify(F(i)) \<in> stable(A)) & st_set(A))"
apply (auto simp add: stable_def constrains_def JOIN_def)
apply (cut_tac F = "F (i) " in Acts_type)
apply (drule_tac x = act in bspec, auto)
done

lemma initially_JN_I:
  assumes major: "(!!i. i \<in> I ==>F(i) \<in> initially(A))"
      and minor: "i \<in> I"
  shows  "(\<Squnion>i \<in> I. F(i)) \<in> initially(A)"
apply (cut_tac minor)
apply (auto elim!: not_emptyE simp add: Inter_iff initially_def)
apply (frule_tac i = x in major)
apply (auto simp add: initially_def)
done

lemma invariant_JN_I:
  assumes major: "(!!i. i \<in> I ==> F(i) \<in> invariant(A))"
      and minor: "i \<in> I"
  shows "(\<Squnion>i \<in> I. F(i)) \<in> invariant(A)"
apply (cut_tac minor)
apply (auto intro!: initially_JN_I dest: major simp add: invariant_def JN_stable)
apply (erule_tac V = "i \<in> I" in thin_rl)
apply (frule major)
apply (drule_tac [2] major)
apply (auto simp add: invariant_def)
apply (frule stableD2, force)+
done

lemma Join_stable [iff]:
     " (F Join G \<in> stable(A)) \<longleftrightarrow>
      (programify(F) \<in> stable(A) & programify(G) \<in>  stable(A))"
by (simp add: stable_def)

lemma initially_JoinI [intro!]:
     "[| F \<in> initially(A); G \<in> initially(A) |] ==> F Join G \<in> initially(A)"
by (unfold initially_def, auto)

lemma invariant_JoinI:
     "[| F \<in> invariant(A); G \<in> invariant(A) |]
      ==> F Join G \<in> invariant(A)"
apply (subgoal_tac "F \<in> program&G \<in> program")
prefer 2 apply (blast dest: invariantD2)
apply (simp add: invariant_def)
apply (auto intro: Join_in_program)
done


(* Fails if I=0 because \<Inter>i \<in> 0. A(i) = 0 *)
lemma FP_JN: "i \<in> I ==> FP(\<Squnion>i \<in> I. F(i)) = (\<Inter>i \<in> I. FP (programify(F(i))))"
by (auto simp add: FP_def Inter_def st_set_def JN_stable)

subsection\<open>Progress: transient, ensures\<close>

lemma JN_transient:
     "i \<in> I ==>
      (\<Squnion>i \<in> I. F(i)) \<in> transient(A) \<longleftrightarrow> (\<exists>i \<in> I. programify(F(i)) \<in> transient(A))"
apply (auto simp add: transient_def JOIN_def)
apply (unfold st_set_def)
apply (drule_tac [2] x = act in bspec)
apply (auto dest: Acts_type [THEN subsetD])
done

lemma Join_transient [iff]:
     "F Join G \<in> transient(A) \<longleftrightarrow>
      (programify(F) \<in> transient(A) | programify(G) \<in> transient(A))"
apply (auto simp add: transient_def Join_def Int_Un_distrib2)
done

lemma Join_transient_I1: "F \<in> transient(A) ==> F Join G \<in> transient(A)"
by (simp add: Join_transient transientD2)


lemma Join_transient_I2: "G \<in> transient(A) ==> F Join G \<in> transient(A)"
by (simp add: Join_transient transientD2)

(*If I=0 it degenerates to (SKIP \<in> A ensures B) = False, i.e. to ~(A\<subseteq>B) *)
lemma JN_ensures:
     "i \<in> I ==>
      (\<Squnion>i \<in> I. F(i)) \<in> A ensures B \<longleftrightarrow>
      ((\<forall>i \<in> I. programify(F(i)) \<in> (A-B) co (A \<union> B)) &
      (\<exists>i \<in> I. programify(F(i)) \<in> A ensures B))"
by (auto simp add: ensures_def JN_constrains JN_transient)


lemma Join_ensures:
     "F Join G \<in> A ensures B  \<longleftrightarrow>
      (programify(F) \<in> (A-B) co (A \<union> B) & programify(G) \<in> (A-B) co (A \<union> B) &
       (programify(F) \<in>  transient (A-B) | programify(G) \<in> transient (A-B)))"

apply (unfold ensures_def)
apply (auto simp add: Join_transient)
done

lemma stable_Join_constrains:
    "[| F \<in> stable(A);  G \<in> A co A' |]
     ==> F Join G \<in> A co A'"
apply (unfold stable_def constrains_def Join_def st_set_def)
apply (cut_tac F = F in Acts_type)
apply (cut_tac F = G in Acts_type, force)
done

(*Premise for G cannot use Always because  F \<in> Stable A  is
   weaker than G \<in> stable A *)
lemma stable_Join_Always1:
     "[| F \<in> stable(A);  G \<in> invariant(A) |] ==> F Join G \<in> Always(A)"
apply (subgoal_tac "F \<in> program & G \<in> program & st_set (A) ")
prefer 2 apply (blast dest: invariantD2 stableD2)
apply (simp add: Always_def invariant_def initially_def Stable_eq_stable)
apply (force intro: stable_Int)
done

(*As above, but exchanging the roles of F and G*)
lemma stable_Join_Always2:
     "[| F \<in> invariant(A);  G \<in> stable(A) |] ==> F Join G \<in> Always(A)"
apply (subst Join_commute)
apply (blast intro: stable_Join_Always1)
done



lemma stable_Join_ensures1:
     "[| F \<in> stable(A);  G \<in> A ensures B |] ==> F Join G \<in> A ensures B"
apply (subgoal_tac "F \<in> program & G \<in> program & st_set (A) ")
prefer 2 apply (blast dest: stableD2 ensures_type [THEN subsetD])
apply (simp (no_asm_simp) add: Join_ensures)
apply (simp add: stable_def ensures_def)
apply (erule constrains_weaken, auto)
done


(*As above, but exchanging the roles of F and G*)
lemma stable_Join_ensures2:
     "[| F \<in> A ensures B;  G \<in> stable(A) |] ==> F Join G \<in> A ensures B"
apply (subst Join_commute)
apply (blast intro: stable_Join_ensures1)
done

subsection\<open>The ok and OK relations\<close>

lemma ok_SKIP1 [iff]: "SKIP ok F"
by (auto dest: Acts_type [THEN subsetD] simp add: ok_def)

lemma ok_SKIP2 [iff]: "F ok SKIP"
by (auto dest: Acts_type [THEN subsetD] simp add: ok_def)

lemma ok_Join_commute:
     "(F ok G & (F Join G) ok H) \<longleftrightarrow> (G ok H & F ok (G Join H))"
by (auto simp add: ok_def)

lemma ok_commute: "(F ok G) \<longleftrightarrow>(G ok F)"
by (auto simp add: ok_def)

lemmas ok_sym = ok_commute [THEN iffD1]

lemma ok_iff_OK: "OK({<0,F>,<1,G>,<2,H>}, snd) \<longleftrightarrow> (F ok G & (F Join G) ok H)"
by (simp add: ok_def Join_def OK_def Int_assoc cons_absorb
                 Int_Un_distrib2 Ball_def,  safe, force+)

lemma ok_Join_iff1 [iff]: "F ok (G Join H) \<longleftrightarrow> (F ok G & F ok H)"
by (auto simp add: ok_def)

lemma ok_Join_iff2 [iff]: "(G Join H) ok F \<longleftrightarrow> (G ok F & H ok F)"
by (auto simp add: ok_def)

(*useful?  Not with the previous two around*)
lemma ok_Join_commute_I: "[| F ok G; (F Join G) ok H |] ==> F ok (G Join H)"
by (auto simp add: ok_def)

lemma ok_JN_iff1 [iff]: "F ok JOIN(I,G) \<longleftrightarrow> (\<forall>i \<in> I. F ok G(i))"
by (force dest: Acts_type [THEN subsetD] elim!: not_emptyE simp add: ok_def)

lemma ok_JN_iff2 [iff]: "JOIN(I,G) ok F   \<longleftrightarrow>  (\<forall>i \<in> I. G(i) ok F)"
apply (auto elim!: not_emptyE simp add: ok_def)
apply (blast dest: Acts_type [THEN subsetD])
done

lemma OK_iff_ok: "OK(I,F) \<longleftrightarrow> (\<forall>i \<in> I. \<forall>j \<in> I-{i}. F(i) ok (F(j)))"
by (auto simp add: ok_def OK_def)

lemma OK_imp_ok: "[| OK(I,F); i \<in> I; j \<in> I; i\<noteq>j|] ==> F(i) ok F(j)"
by (auto simp add: OK_iff_ok)


lemma OK_0 [iff]: "OK(0,F)"
by (simp add: OK_def)

lemma OK_cons_iff:
     "OK(cons(i, I), F) \<longleftrightarrow>
      (i \<in> I & OK(I, F)) | (i\<notin>I & OK(I, F) & F(i) ok JOIN(I,F))"
apply (simp add: OK_iff_ok)
apply (blast intro: ok_sym)
done


subsection\<open>Allowed\<close>

lemma Allowed_SKIP [simp]: "Allowed(SKIP) = program"
by (auto dest: Acts_type [THEN subsetD] simp add: Allowed_def)

lemma Allowed_Join [simp]:
     "Allowed(F Join G) =
   Allowed(programify(F)) \<inter> Allowed(programify(G))"
apply (auto simp add: Allowed_def)
done

lemma Allowed_JN [simp]:
     "i \<in> I ==>
   Allowed(JOIN(I,F)) = (\<Inter>i \<in> I. Allowed(programify(F(i))))"
apply (auto simp add: Allowed_def, blast)
done

lemma ok_iff_Allowed:
     "F ok G \<longleftrightarrow> (programify(F) \<in> Allowed(programify(G)) &
   programify(G) \<in> Allowed(programify(F)))"
by (simp add: ok_def Allowed_def)


lemma OK_iff_Allowed:
     "OK(I,F) \<longleftrightarrow>
  (\<forall>i \<in> I. \<forall>j \<in> I-{i}. programify(F(i)) \<in> Allowed(programify(F(j))))"
apply (auto simp add: OK_iff_ok ok_iff_Allowed)
done

subsection\<open>safety_prop, for reasoning about given instances of "ok"\<close>

lemma safety_prop_Acts_iff:
     "safety_prop(X) ==> (Acts(G) \<subseteq> cons(id(state), (\<Union>F \<in> X. Acts(F)))) \<longleftrightarrow> (programify(G) \<in> X)"
apply (simp (no_asm_use) add: safety_prop_def)
apply clarify
apply (case_tac "G \<in> program", simp_all, blast, safe)
prefer 2 apply force
apply (force simp add: programify_def)
done

lemma safety_prop_AllowedActs_iff_Allowed:
     "safety_prop(X) ==>
  (\<Union>G \<in> X. Acts(G)) \<subseteq> AllowedActs(F) \<longleftrightarrow> (X \<subseteq> Allowed(programify(F)))"
apply (simp add: Allowed_def safety_prop_Acts_iff [THEN iff_sym]
                 safety_prop_def, blast)
done


lemma Allowed_eq:
     "safety_prop(X) ==> Allowed(mk_program(init, acts, \<Union>F \<in> X. Acts(F))) = X"
apply (subgoal_tac "cons (id (state), \<Union>(RepFun (X, Acts)) \<inter> Pow (state * state)) = \<Union>(RepFun (X, Acts))")
apply (rule_tac [2] equalityI)
  apply (simp del: UN_simps add: Allowed_def safety_prop_Acts_iff safety_prop_def, auto)
apply (force dest: Acts_type [THEN subsetD] simp add: safety_prop_def)+
done

lemma def_prg_Allowed:
     "[| F == mk_program (init, acts, \<Union>F \<in> X. Acts(F)); safety_prop(X) |]
      ==> Allowed(F) = X"
by (simp add: Allowed_eq)

(*For safety_prop to hold, the property must be satisfiable!*)
lemma safety_prop_constrains [iff]:
     "safety_prop(A co B) \<longleftrightarrow> (A \<subseteq> B & st_set(A))"
by (simp add: safety_prop_def constrains_def st_set_def, blast)

(* To be used with resolution *)
lemma safety_prop_constrainsI [iff]:
     "[| A\<subseteq>B; st_set(A) |] ==>safety_prop(A co B)"
by auto

lemma safety_prop_stable [iff]: "safety_prop(stable(A)) \<longleftrightarrow> st_set(A)"
by (simp add: stable_def)

lemma safety_prop_stableI: "st_set(A) ==> safety_prop(stable(A))"
by auto

lemma safety_prop_Int [simp]:
     "[| safety_prop(X) ; safety_prop(Y) |] ==> safety_prop(X \<inter> Y)"
apply (simp add: safety_prop_def, safe, blast)
apply (drule_tac [2] B = "\<Union>(RepFun (X \<inter> Y, Acts))" and C = "\<Union>(RepFun (Y, Acts))" in subset_trans)
apply (drule_tac B = "\<Union>(RepFun (X \<inter> Y, Acts))" and C = "\<Union>(RepFun (X, Acts))" in subset_trans)
apply blast+
done

(* If I=0 the conclusion becomes safety_prop(0) which is false *)
lemma safety_prop_Inter:
  assumes major: "(!!i. i \<in> I ==>safety_prop(X(i)))"
      and minor: "i \<in> I"
  shows "safety_prop(\<Inter>i \<in> I. X(i))"
apply (simp add: safety_prop_def)
apply (cut_tac minor, safe)
apply (simp (no_asm_use) add: Inter_iff)
apply clarify
apply (frule major)
apply (drule_tac [2] i = xa in major)
apply (frule_tac [4] i = xa in major)
apply (auto simp add: safety_prop_def)
apply (drule_tac B = "\<Union>(RepFun (\<Inter>(RepFun (I, X)), Acts))" and C = "\<Union>(RepFun (X (xa), Acts))" in subset_trans)
apply blast+
done

lemma def_UNION_ok_iff:
"[| F == mk_program(init,acts, \<Union>G \<in> X. Acts(G)); safety_prop(X) |]
      ==> F ok G \<longleftrightarrow> (programify(G) \<in> X & acts \<inter> Pow(state*state) \<subseteq> AllowedActs(G))"
apply (unfold ok_def)
apply (drule_tac G = G in safety_prop_Acts_iff)
apply (cut_tac F = G in AllowedActs_type)
apply (cut_tac F = G in Acts_type, auto)
done

end

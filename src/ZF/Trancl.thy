(*  Title:      ZF/trancl.thy
    ID:         $Id$
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1992  University of Cambridge

1. General Properties of relations
2. Transitive closure of a relation
*)

theory Trancl = Fixedpt + Perm + mono:

constdefs
  refl     :: "[i,i]=>o"
    "refl(A,r) == (ALL x: A. <x,x> : r)"

  irrefl   :: "[i,i]=>o"
    "irrefl(A,r) == ALL x: A. <x,x> ~: r"

  equiv    :: "[i,i]=>o"
    "equiv(A,r) == r <= A*A & refl(A,r) & sym(r) & trans(r)"

  sym      :: "i=>o"
    "sym(r) == ALL x y. <x,y>: r --> <y,x>: r"

  asym     :: "i=>o"
    "asym(r) == ALL x y. <x,y>:r --> ~ <y,x>:r"

  antisym  :: "i=>o"
    "antisym(r) == ALL x y.<x,y>:r --> <y,x>:r --> x=y"

  trans    :: "i=>o"
    "trans(r) == ALL x y z. <x,y>: r --> <y,z>: r --> <x,z>: r"

  trans_on :: "[i,i]=>o"  ("trans[_]'(_')")
    "trans[A](r) == ALL x:A. ALL y:A. ALL z:A.       
                          <x,y>: r --> <y,z>: r --> <x,z>: r"

  rtrancl :: "i=>i"  ("(_^*)" [100] 100)  (*refl/transitive closure*)
    "r^* == lfp(field(r)*field(r), %s. id(field(r)) Un (r O s))"

  trancl  :: "i=>i"  ("(_^+)" [100] 100)  (*transitive closure*)
    "r^+ == r O r^*"

subsection{*General properties of relations*}

subsubsection{*irreflexivity*}

lemma irreflI:
    "[| !!x. x:A ==> <x,x> ~: r |] ==> irrefl(A,r)"
by (simp add: irrefl_def); 

lemma symI: "[| irrefl(A,r);  x:A |] ==>  <x,x> ~: r"
apply (simp add: irrefl_def)
done

subsubsection{*symmetry*}

lemma symI:
     "[| !!x y.<x,y>: r ==> <y,x>: r |] ==> sym(r)"
apply (unfold sym_def); 
apply (blast intro: elim:); 
done

lemma antisymI: "[| sym(r); <x,y>: r |]  ==>  <y,x>: r"
apply (unfold sym_def)
apply blast
done

subsubsection{*antisymmetry*}

lemma antisymI:
     "[| !!x y.[| <x,y>: r;  <y,x>: r |] ==> x=y |] ==> antisym(r)"
apply (simp add: antisym_def) 
apply (blast intro: elim:); 
done

lemma antisymE: "[| antisym(r); <x,y>: r;  <y,x>: r |]  ==>  x=y"
apply (simp add: antisym_def)
apply blast
done

subsubsection{*transitivity*}

lemma transD: "[| trans(r);  <a,b>:r;  <b,c>:r |] ==> <a,c>:r"
apply (unfold trans_def)
apply blast
done

lemma trans_onD: 
    "[| trans[A](r);  <a,b>:r;  <b,c>:r;  a:A;  b:A;  c:A |] ==> <a,c>:r"
apply (unfold trans_on_def)
apply blast
done

subsection{*Transitive closure of a relation*}

lemma rtrancl_bnd_mono:
     "bnd_mono(field(r)*field(r), %s. id(field(r)) Un (r O s))"
apply (rule bnd_monoI)
apply (blast intro: elim:)+
done

lemma rtrancl_mono: "r<=s ==> r^* <= s^*"
apply (unfold rtrancl_def)
apply (rule lfp_mono)
apply (rule rtrancl_bnd_mono)+
apply (blast intro: elim:); 
done

(* r^* = id(field(r)) Un ( r O r^* )    *)
lemmas rtrancl_unfold =
     rtrancl_bnd_mono [THEN rtrancl_def [THEN def_lfp_unfold], standard]

(** The relation rtrancl **)

(*  r^* <= field(r) * field(r)  *)
lemmas rtrancl_type = rtrancl_def [THEN def_lfp_subset, standard]

(*Reflexivity of rtrancl*)
lemma rtrancl_refl: "[| a: field(r) |] ==> <a,a> : r^*"
apply (rule rtrancl_unfold [THEN ssubst])
apply (erule idI [THEN UnI1])
done

(*Closure under composition with r  *)
lemma rtrancl_into_rtrancl: "[| <a,b> : r^*;  <b,c> : r |] ==> <a,c> : r^*"
apply (rule rtrancl_unfold [THEN ssubst])
apply (rule compI [THEN UnI2])
apply assumption
apply assumption
done

(*rtrancl of r contains all pairs in r  *)
lemma r_into_rtrancl: "<a,b> : r ==> <a,b> : r^*"
apply (rule rtrancl_refl [THEN rtrancl_into_rtrancl])
apply (blast intro: elim:)+
done

(*The premise ensures that r consists entirely of pairs*)
lemma r_subset_rtrancl: "r <= Sigma(A,B) ==> r <= r^*"
apply (blast intro: r_into_rtrancl)
done

lemma rtrancl_field: "field(r^*) = field(r)"
apply (blast intro: r_into_rtrancl dest!: rtrancl_type [THEN subsetD])
done


(** standard induction rule **)

lemma rtrancl_full_induct:
  "[| <a,b> : r^*;  
      !!x. x: field(r) ==> P(<x,x>);  
      !!x y z.[| P(<x,y>); <x,y>: r^*; <y,z>: r |]  ==>  P(<x,z>) |]  
   ==>  P(<a,b>)"
apply (erule def_induct [OF rtrancl_def rtrancl_bnd_mono])
apply (blast intro: elim:); 
done

(*nice induction rule.
  Tried adding the typing hypotheses y,z:field(r), but these
  caused expensive case splits!*)
lemma rtrancl_induct:
  "[| <a,b> : r^*;                                               
      P(a);                                                      
      !!y z.[| <a,y> : r^*;  <y,z> : r;  P(y) |] ==> P(z)        
   |] ==> P(b)"
(*by induction on this formula*)
apply (subgoal_tac "ALL y. <a,b> = <a,y> --> P (y) ")
(*now solve first subgoal: this formula is sufficient*)
apply (erule spec [THEN mp], rule refl)
(*now do the induction*)
apply (erule rtrancl_full_induct)
apply (blast)+
done

(*transitivity of transitive closure!! -- by induction.*)
lemma trans_rtrancl: "trans(r^*)"
apply (unfold trans_def)
apply (intro allI impI)
apply (erule_tac b = "z" in rtrancl_induct)
apply assumption; 
apply (blast intro: rtrancl_into_rtrancl) 
done

lemmas rtrancl_trans = trans_rtrancl [THEN transD, standard]

(*elimination of rtrancl -- by induction on a special formula*)
lemma rtranclE:
    "[| <a,b> : r^*;  (a=b) ==> P;                        
        !!y.[| <a,y> : r^*;   <y,b> : r |] ==> P |]       
     ==> P"
apply (subgoal_tac "a = b | (EX y. <a,y> : r^* & <y,b> : r) ")
(*see HOL/trancl*)
apply (blast intro: elim:); 
apply (erule rtrancl_induct)
apply (blast intro: elim:)+
done


(**** The relation trancl ****)

(*Transitivity of r^+ is proved by transitivity of r^*  *)
lemma trans_trancl: "trans(r^+)"
apply (unfold trans_def trancl_def)
apply (blast intro: rtrancl_into_rtrancl
                    trans_rtrancl [THEN transD, THEN compI])
done

lemmas trancl_trans = trans_trancl [THEN transD, standard]

(** Conversions between trancl and rtrancl **)

lemma trancl_into_rtrancl: "<a,b> : r^+ ==> <a,b> : r^*"
apply (unfold trancl_def)
apply (blast intro: rtrancl_into_rtrancl)
done

(*r^+ contains all pairs in r  *)
lemma r_into_trancl: "<a,b> : r ==> <a,b> : r^+"
apply (unfold trancl_def)
apply (blast intro!: rtrancl_refl)
done

(*The premise ensures that r consists entirely of pairs*)
lemma r_subset_trancl: "r <= Sigma(A,B) ==> r <= r^+"
apply (blast intro: r_into_trancl)
done

(*intro rule by definition: from r^* and r  *)
lemma rtrancl_into_trancl1: "[| <a,b> : r^*;  <b,c> : r |]   ==>  <a,c> : r^+"
apply (unfold trancl_def)
apply blast
done

(*intro rule from r and r^*  *)
lemma rtrancl_into_trancl2:
    "[| <a,b> : r;  <b,c> : r^* |]   ==>  <a,c> : r^+"
apply (erule rtrancl_induct)
 apply (erule r_into_trancl)
apply (blast intro: r_into_trancl trancl_trans) 
done

(*Nice induction rule for trancl*)
lemma trancl_induct:
  "[| <a,b> : r^+;                                       
      !!y.  [| <a,y> : r |] ==> P(y);                    
      !!y z.[| <a,y> : r^+;  <y,z> : r;  P(y) |] ==> P(z)        
   |] ==> P(b)"
apply (rule compEpair)
apply (unfold trancl_def, assumption)
(*by induction on this formula*)
apply (subgoal_tac "ALL z. <y,z> : r --> P (z) ")
(*now solve first subgoal: this formula is sufficient*)
 apply blast
apply (erule rtrancl_induct)
apply (blast intro: rtrancl_into_trancl1)+
done

(*elimination of r^+ -- NOT an induction rule*)
lemma tranclE:
    "[| <a,b> : r^+;   
        <a,b> : r ==> P;  
        !!y.[| <a,y> : r^+; <y,b> : r |] ==> P   
     |] ==> P"
apply (subgoal_tac "<a,b> : r | (EX y. <a,y> : r^+ & <y,b> : r) ")
apply (blast intro: elim:); 
apply (rule compEpair)
apply (unfold trancl_def, assumption)
apply (erule rtranclE)
apply (blast intro: rtrancl_into_trancl1)+
done

lemma trancl_type: "r^+ <= field(r)*field(r)"
apply (unfold trancl_def)
apply (blast elim: rtrancl_type [THEN subsetD, THEN SigmaE2])
done

lemma trancl_mono: "r<=s ==> r^+ <= s^+"
by (unfold trancl_def, intro comp_mono rtrancl_mono)


(** Suggested by Sidi Ould Ehmety **)

lemma rtrancl_idemp [simp]: "(r^*)^* = r^*"
apply (rule equalityI)
apply auto
 prefer 2
 apply (frule rtrancl_type [THEN subsetD])
 apply (blast intro: r_into_rtrancl elim:); 
txt{*converse direction*}
apply (frule rtrancl_type [THEN subsetD])
apply (clarify ); 
apply (erule rtrancl_induct)
apply (simp add: rtrancl_refl rtrancl_field)
apply (blast intro: rtrancl_trans)
done

lemma rtrancl_subset: "[| R <= S; S <= R^* |] ==> S^* = R^*"
apply (drule rtrancl_mono)
apply (drule rtrancl_mono)
apply simp_all
apply blast
done

lemma rtrancl_Un_rtrancl:
     "[| r<= Sigma(A,B); s<=Sigma(C,D) |] ==> (r^* Un s^*)^* = (r Un s)^*"
apply (rule rtrancl_subset)
apply (blast dest: r_subset_rtrancl)
apply (blast intro: rtrancl_mono [THEN subsetD])
done

(*** "converse" laws by Sidi Ould Ehmety ***)

(** rtrancl **)

lemma rtrancl_converseD: "<x,y>:converse(r)^* ==> <x,y>:converse(r^*)"
apply (rule converseI)
apply (frule rtrancl_type [THEN subsetD])
apply (erule rtrancl_induct)
apply (blast intro: rtrancl_refl)
apply (blast intro: r_into_rtrancl rtrancl_trans)
done

lemma rtrancl_converseI: "<x,y>:converse(r^*) ==> <x,y>:converse(r)^*"
apply (drule converseD)
apply (frule rtrancl_type [THEN subsetD])
apply (erule rtrancl_induct)
apply (blast intro: rtrancl_refl)
apply (blast intro: r_into_rtrancl rtrancl_trans)
done

lemma rtrancl_converse: "converse(r)^* = converse(r^*)"
apply (safe intro!: equalityI)
apply (frule rtrancl_type [THEN subsetD])
apply (safe dest!: rtrancl_converseD intro!: rtrancl_converseI)
done

(** trancl **)

lemma trancl_converseD: "<a, b>:converse(r)^+ ==> <a, b>:converse(r^+)"
apply (erule trancl_induct)
apply (auto intro: r_into_trancl trancl_trans)
done

lemma trancl_converseI: "<x,y>:converse(r^+) ==> <x,y>:converse(r)^+"
apply (drule converseD)
apply (erule trancl_induct)
apply (auto intro: r_into_trancl trancl_trans)
done

lemma trancl_converse: "converse(r)^+ = converse(r^+)"
apply (safe intro!: equalityI)
apply (frule trancl_type [THEN subsetD])
apply (safe dest!: trancl_converseD intro!: trancl_converseI)
done

lemma converse_trancl_induct:
"[| <a, b>:r^+; !!y. <y, b> :r ==> P(y);  
      !!y z. [| <y, z> : r; <z, b> : r^+; P(z) |] ==> P(y) |]  
       ==> P(a)"
apply (drule converseI)
apply (simp (no_asm_use) add: trancl_converse [symmetric])
apply (erule trancl_induct)
apply (auto simp add: trancl_converse)
done

ML
{*
val refl_def = thm "refl_def";
val irrefl_def = thm "irrefl_def";
val equiv_def = thm "equiv_def";
val sym_def = thm "sym_def";
val asym_def = thm "asym_def";
val antisym_def = thm "antisym_def";
val trans_def = thm "trans_def";
val trans_on_def = thm "trans_on_def";

val irreflI = thm "irreflI";
val symI = thm "symI";
val symI = thm "symI";
val antisymI = thm "antisymI";
val antisymE = thm "antisymE";
val transD = thm "transD";
val trans_onD = thm "trans_onD";

val rtrancl_bnd_mono = thm "rtrancl_bnd_mono";
val rtrancl_mono = thm "rtrancl_mono";
val rtrancl_unfold = thm "rtrancl_unfold";
val rtrancl_type = thm "rtrancl_type";
val rtrancl_refl = thm "rtrancl_refl";
val rtrancl_into_rtrancl = thm "rtrancl_into_rtrancl";
val r_into_rtrancl = thm "r_into_rtrancl";
val r_subset_rtrancl = thm "r_subset_rtrancl";
val rtrancl_field = thm "rtrancl_field";
val rtrancl_full_induct = thm "rtrancl_full_induct";
val rtrancl_induct = thm "rtrancl_induct";
val trans_rtrancl = thm "trans_rtrancl";
val rtrancl_trans = thm "rtrancl_trans";
val rtranclE = thm "rtranclE";
val trans_trancl = thm "trans_trancl";
val trancl_trans = thm "trancl_trans";
val trancl_into_rtrancl = thm "trancl_into_rtrancl";
val r_into_trancl = thm "r_into_trancl";
val r_subset_trancl = thm "r_subset_trancl";
val rtrancl_into_trancl1 = thm "rtrancl_into_trancl1";
val rtrancl_into_trancl2 = thm "rtrancl_into_trancl2";
val trancl_induct = thm "trancl_induct";
val tranclE = thm "tranclE";
val trancl_type = thm "trancl_type";
val trancl_mono = thm "trancl_mono";
val rtrancl_idemp = thm "rtrancl_idemp";
val rtrancl_subset = thm "rtrancl_subset";
val rtrancl_Un_rtrancl = thm "rtrancl_Un_rtrancl";
val rtrancl_converseD = thm "rtrancl_converseD";
val rtrancl_converseI = thm "rtrancl_converseI";
val rtrancl_converse = thm "rtrancl_converse";
val trancl_converseD = thm "trancl_converseD";
val trancl_converseI = thm "trancl_converseI";
val trancl_converse = thm "trancl_converse";
val converse_trancl_induct = thm "converse_trancl_induct";
*}

end

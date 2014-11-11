(*  Title:      CCL/Type.thy
    Author:     Martin Coen
    Copyright   1993  University of Cambridge
*)

section {* Types in CCL are defined as sets of terms *}

theory Type
imports Term
begin

consts

  Subtype       :: "['a set, 'a \<Rightarrow> o] \<Rightarrow> 'a set"
  Bool          :: "i set"
  Unit          :: "i set"
  Plus           :: "[i set, i set] \<Rightarrow> i set"        (infixr "+" 55)
  Pi            :: "[i set, i \<Rightarrow> i set] \<Rightarrow> i set"
  Sigma         :: "[i set, i \<Rightarrow> i set] \<Rightarrow> i set"
  Nat           :: "i set"
  List          :: "i set \<Rightarrow> i set"
  Lists         :: "i set \<Rightarrow> i set"
  ILists        :: "i set \<Rightarrow> i set"
  TAll          :: "(i set \<Rightarrow> i set) \<Rightarrow> i set"       (binder "TALL " 55)
  TEx           :: "(i set \<Rightarrow> i set) \<Rightarrow> i set"       (binder "TEX " 55)
  Lift          :: "i set \<Rightarrow> i set"                  ("(3[_])")

  SPLIT         :: "[i, [i, i] \<Rightarrow> i set] \<Rightarrow> i set"

syntax
  "_Pi"         :: "[idt, i set, i set] \<Rightarrow> i set"    ("(3PROD _:_./ _)"
                                [0,0,60] 60)

  "_Sigma"      :: "[idt, i set, i set] \<Rightarrow> i set"    ("(3SUM _:_./ _)"
                                [0,0,60] 60)

  "_arrow"      :: "[i set, i set] \<Rightarrow> i set"         ("(_ ->/ _)"  [54, 53] 53)
  "_star"       :: "[i set, i set] \<Rightarrow> i set"         ("(_ */ _)" [56, 55] 55)
  "_Subtype"    :: "[idt, 'a set, o] \<Rightarrow> 'a set"      ("(1{_: _ ./ _})")

translations
  "PROD x:A. B" => "CONST Pi(A, \<lambda>x. B)"
  "A -> B"      => "CONST Pi(A, \<lambda>_. B)"
  "SUM x:A. B"  => "CONST Sigma(A, \<lambda>x. B)"
  "A * B"       => "CONST Sigma(A, \<lambda>_. B)"
  "{x: A. B}"   == "CONST Subtype(A, \<lambda>x. B)"

print_translation {*
 [(@{const_syntax Pi},
    fn _ => Syntax_Trans.dependent_tr' (@{syntax_const "_Pi"}, @{syntax_const "_arrow"})),
  (@{const_syntax Sigma},
    fn _ => Syntax_Trans.dependent_tr' (@{syntax_const "_Sigma"}, @{syntax_const "_star"}))]
*}

defs
  Subtype_def: "{x:A. P(x)} == {x. x:A \<and> P(x)}"
  Unit_def:          "Unit == {x. x=one}"
  Bool_def:          "Bool == {x. x=true | x=false}"
  Plus_def:           "A+B == {x. (EX a:A. x=inl(a)) | (EX b:B. x=inr(b))}"
  Pi_def:         "Pi(A,B) == {x. EX b. x=lam x. b(x) \<and> (ALL x:A. b(x):B(x))}"
  Sigma_def:   "Sigma(A,B) == {x. EX a:A. EX b:B(a).x=<a,b>}"
  Nat_def:            "Nat == lfp(\<lambda>X. Unit + X)"
  List_def:       "List(A) == lfp(\<lambda>X. Unit + A*X)"

  Lists_def:     "Lists(A) == gfp(\<lambda>X. Unit + A*X)"
  ILists_def:   "ILists(A) == gfp(\<lambda>X.{} + A*X)"

  Tall_def:   "TALL X. B(X) == Inter({X. EX Y. X=B(Y)})"
  Tex_def:     "TEX X. B(X) == Union({X. EX Y. X=B(Y)})"
  Lift_def:           "[A] == A Un {bot}"

  SPLIT_def:   "SPLIT(p,B) == Union({A. EX x y. p=<x,y> \<and> A=B(x,y)})"


lemmas simp_type_defs =
    Subtype_def Unit_def Bool_def Plus_def Sigma_def Pi_def Lift_def Tall_def Tex_def
  and ind_type_defs = Nat_def List_def
  and simp_data_defs = one_def inl_def inr_def
  and ind_data_defs = zero_def succ_def nil_def cons_def

lemma subsetXH: "A <= B \<longleftrightarrow> (ALL x. x:A \<longrightarrow> x:B)"
  by blast


subsection {* Exhaustion Rules *}

lemma EmptyXH: "\<And>a. a : {} \<longleftrightarrow> False"
  and SubtypeXH: "\<And>a A P. a : {x:A. P(x)} \<longleftrightarrow> (a:A \<and> P(a))"
  and UnitXH: "\<And>a. a : Unit          \<longleftrightarrow> a=one"
  and BoolXH: "\<And>a. a : Bool          \<longleftrightarrow> a=true | a=false"
  and PlusXH: "\<And>a A B. a : A+B           \<longleftrightarrow> (EX x:A. a=inl(x)) | (EX x:B. a=inr(x))"
  and PiXH: "\<And>a A B. a : PROD x:A. B(x) \<longleftrightarrow> (EX b. a=lam x. b(x) \<and> (ALL x:A. b(x):B(x)))"
  and SgXH: "\<And>a A B. a : SUM x:A. B(x)  \<longleftrightarrow> (EX x:A. EX y:B(x).a=<x,y>)"
  unfolding simp_type_defs by blast+

lemmas XHs = EmptyXH SubtypeXH UnitXH BoolXH PlusXH PiXH SgXH

lemma LiftXH: "a : [A] \<longleftrightarrow> (a=bot | a:A)"
  and TallXH: "a : TALL X. B(X) \<longleftrightarrow> (ALL X. a:B(X))"
  and TexXH: "a : TEX X. B(X) \<longleftrightarrow> (EX X. a:B(X))"
  unfolding simp_type_defs by blast+

ML {* ML_Thms.bind_thms ("case_rls", XH_to_Es @{thms XHs}) *}


subsection {* Canonical Type Rules *}

lemma oneT: "one : Unit"
  and trueT: "true : Bool"
  and falseT: "false : Bool"
  and lamT: "\<And>b B. (\<And>x. x:A \<Longrightarrow> b(x):B(x)) \<Longrightarrow> lam x. b(x) : Pi(A,B)"
  and pairT: "\<And>b B. \<lbrakk>a:A; b:B(a)\<rbrakk> \<Longrightarrow> <a,b>:Sigma(A,B)"
  and inlT: "a:A \<Longrightarrow> inl(a) : A+B"
  and inrT: "b:B \<Longrightarrow> inr(b) : A+B"
  by (blast intro: XHs [THEN iffD2])+

lemmas canTs = oneT trueT falseT pairT lamT inlT inrT


subsection {* Non-Canonical Type Rules *}

lemma lem: "\<lbrakk>a:B(u); u = v\<rbrakk> \<Longrightarrow> a : B(v)"
  by blast


ML {*
fun mk_ncanT_tac top_crls crls =
  SUBPROOF (fn {context = ctxt, prems = major :: prems, ...} =>
    resolve_tac ([major] RL top_crls) 1 THEN
    REPEAT_SOME (eresolve_tac (crls @ [@{thm exE}, @{thm bexE}, @{thm conjE}, @{thm disjE}])) THEN
    ALLGOALS (asm_simp_tac ctxt) THEN
    ALLGOALS (ares_tac (prems RL [@{thm lem}]) ORELSE' etac @{thm bspec}) THEN
    safe_tac (ctxt addSIs prems))
*}

method_setup ncanT = {*
  Scan.succeed (SIMPLE_METHOD' o mk_ncanT_tac @{thms case_rls} @{thms case_rls})
*}

lemma ifT: "\<lbrakk>b:Bool; b=true \<Longrightarrow> t:A(true); b=false \<Longrightarrow> u:A(false)\<rbrakk> \<Longrightarrow> if b then t else u : A(b)"
  by ncanT

lemma applyT: "\<lbrakk>f : Pi(A,B); a:A\<rbrakk> \<Longrightarrow> f ` a : B(a)"
  by ncanT

lemma splitT: "\<lbrakk>p:Sigma(A,B); \<And>x y. \<lbrakk>x:A; y:B(x); p=<x,y>\<rbrakk> \<Longrightarrow> c(x,y):C(<x,y>)\<rbrakk> \<Longrightarrow> split(p,c):C(p)"
  by ncanT

lemma whenT:
  "\<lbrakk>p:A+B;
    \<And>x. \<lbrakk>x:A; p=inl(x)\<rbrakk> \<Longrightarrow> a(x):C(inl(x));
    \<And>y. \<lbrakk>y:B;  p=inr(y)\<rbrakk> \<Longrightarrow> b(y):C(inr(y))\<rbrakk> \<Longrightarrow> when(p,a,b) : C(p)"
  by ncanT

lemmas ncanTs = ifT applyT splitT whenT


subsection {* Subtypes *}

lemma SubtypeD1: "a : Subtype(A, P) \<Longrightarrow> a : A"
  and SubtypeD2: "a : Subtype(A, P) \<Longrightarrow> P(a)"
  by (simp_all add: SubtypeXH)

lemma SubtypeI: "\<lbrakk>a:A; P(a)\<rbrakk> \<Longrightarrow> a : {x:A. P(x)}"
  by (simp add: SubtypeXH)

lemma SubtypeE: "\<lbrakk>a : {x:A. P(x)}; \<lbrakk>a:A; P(a)\<rbrakk> \<Longrightarrow> Q\<rbrakk> \<Longrightarrow> Q"
  by (simp add: SubtypeXH)


subsection {* Monotonicity *}

lemma idM: "mono (\<lambda>X. X)"
  apply (rule monoI)
  apply assumption
  done

lemma constM: "mono(\<lambda>X. A)"
  apply (rule monoI)
  apply (rule subset_refl)
  done

lemma "mono(\<lambda>X. A(X)) \<Longrightarrow> mono(\<lambda>X.[A(X)])"
  apply (rule subsetI [THEN monoI])
  apply (drule LiftXH [THEN iffD1])
  apply (erule disjE)
   apply (erule disjI1 [THEN LiftXH [THEN iffD2]])
  apply (rule disjI2 [THEN LiftXH [THEN iffD2]])
  apply (drule (1) monoD)
  apply blast
  done

lemma SgM:
  "\<lbrakk>mono(\<lambda>X. A(X)); \<And>x X. x:A(X) \<Longrightarrow> mono(\<lambda>X. B(X,x))\<rbrakk> \<Longrightarrow>
    mono(\<lambda>X. Sigma(A(X),B(X)))"
  by (blast intro!: subsetI [THEN monoI] canTs elim!: case_rls
    dest!: monoD [THEN subsetD])

lemma PiM: "(\<And>x. x:A \<Longrightarrow> mono(\<lambda>X. B(X,x))) \<Longrightarrow> mono(\<lambda>X. Pi(A,B(X)))"
  by (blast intro!: subsetI [THEN monoI] canTs elim!: case_rls
    dest!: monoD [THEN subsetD])

lemma PlusM: "\<lbrakk>mono(\<lambda>X. A(X)); mono(\<lambda>X. B(X))\<rbrakk> \<Longrightarrow> mono(\<lambda>X. A(X)+B(X))"
  by (blast intro!: subsetI [THEN monoI] canTs elim!: case_rls
    dest!: monoD [THEN subsetD])


subsection {* Recursive types *}

subsubsection {* Conversion Rules for Fixed Points via monotonicity and Tarski *}

lemma NatM: "mono(\<lambda>X. Unit+X)"
  apply (rule PlusM constM idM)+
  done

lemma def_NatB: "Nat = Unit + Nat"
  apply (rule def_lfp_Tarski [OF Nat_def])
  apply (rule NatM)
  done

lemma ListM: "mono(\<lambda>X.(Unit+Sigma(A,\<lambda>y. X)))"
  apply (rule PlusM SgM constM idM)+
  done

lemma def_ListB: "List(A) = Unit + A * List(A)"
  apply (rule def_lfp_Tarski [OF List_def])
  apply (rule ListM)
  done

lemma def_ListsB: "Lists(A) = Unit + A * Lists(A)"
  apply (rule def_gfp_Tarski [OF Lists_def])
  apply (rule ListM)
  done

lemma IListsM: "mono(\<lambda>X.({} + Sigma(A,\<lambda>y. X)))"
  apply (rule PlusM SgM constM idM)+
  done

lemma def_IListsB: "ILists(A) = {} + A * ILists(A)"
  apply (rule def_gfp_Tarski [OF ILists_def])
  apply (rule IListsM)
  done

lemmas ind_type_eqs = def_NatB def_ListB def_ListsB def_IListsB


subsection {* Exhaustion Rules *}

lemma NatXH: "a : Nat \<longleftrightarrow> (a=zero | (EX x:Nat. a=succ(x)))"
  and ListXH: "a : List(A) \<longleftrightarrow> (a=[] | (EX x:A. EX xs:List(A).a=x$xs))"
  and ListsXH: "a : Lists(A) \<longleftrightarrow> (a=[] | (EX x:A. EX xs:Lists(A).a=x$xs))"
  and IListsXH: "a : ILists(A) \<longleftrightarrow> (EX x:A. EX xs:ILists(A).a=x$xs)"
  unfolding ind_data_defs
  by (rule ind_type_eqs [THEN XHlemma1], blast intro!: canTs elim!: case_rls)+

lemmas iXHs = NatXH ListXH

ML {* ML_Thms.bind_thms ("icase_rls", XH_to_Es @{thms iXHs}) *}


subsection {* Type Rules *}

lemma zeroT: "zero : Nat"
  and succT: "n:Nat \<Longrightarrow> succ(n) : Nat"
  and nilT: "[] : List(A)"
  and consT: "\<lbrakk>h:A; t:List(A)\<rbrakk> \<Longrightarrow> h$t : List(A)"
  by (blast intro: iXHs [THEN iffD2])+

lemmas icanTs = zeroT succT nilT consT


method_setup incanT = {*
  Scan.succeed (SIMPLE_METHOD' o mk_ncanT_tac @{thms icase_rls} @{thms case_rls})
*}

lemma ncaseT: "\<lbrakk>n:Nat; n=zero \<Longrightarrow> b:C(zero); \<And>x. \<lbrakk>x:Nat; n=succ(x)\<rbrakk> \<Longrightarrow> c(x):C(succ(x))\<rbrakk>
    \<Longrightarrow> ncase(n,b,c) : C(n)"
  by incanT

lemma lcaseT: "\<lbrakk>l:List(A); l = [] \<Longrightarrow> b:C([]); \<And>h t. \<lbrakk>h:A; t:List(A); l=h$t\<rbrakk> \<Longrightarrow> c(h,t):C(h$t)\<rbrakk>
    \<Longrightarrow> lcase(l,b,c) : C(l)"
  by incanT

lemmas incanTs = ncaseT lcaseT


subsection {* Induction Rules *}

lemmas ind_Ms = NatM ListM

lemma Nat_ind: "\<lbrakk>n:Nat; P(zero); \<And>x. \<lbrakk>x:Nat; P(x)\<rbrakk> \<Longrightarrow> P(succ(x))\<rbrakk> \<Longrightarrow> P(n)"
  apply (unfold ind_data_defs)
  apply (erule def_induct [OF Nat_def _ NatM])
  apply (blast intro: canTs elim!: case_rls)
  done

lemma List_ind: "\<lbrakk>l:List(A); P([]); \<And>x xs. \<lbrakk>x:A; xs:List(A); P(xs)\<rbrakk> \<Longrightarrow> P(x$xs)\<rbrakk> \<Longrightarrow> P(l)"
  apply (unfold ind_data_defs)
  apply (erule def_induct [OF List_def _ ListM])
  apply (blast intro: canTs elim!: case_rls)
  done

lemmas inds = Nat_ind List_ind


subsection {* Primitive Recursive Rules *}

lemma nrecT: "\<lbrakk>n:Nat; b:C(zero); \<And>x g. \<lbrakk>x:Nat; g:C(x)\<rbrakk> \<Longrightarrow> c(x,g):C(succ(x))\<rbrakk>
    \<Longrightarrow> nrec(n,b,c) : C(n)"
  by (erule Nat_ind) auto

lemma lrecT: "\<lbrakk>l:List(A); b:C([]); \<And>x xs g. \<lbrakk>x:A; xs:List(A); g:C(xs)\<rbrakk> \<Longrightarrow> c(x,xs,g):C(x$xs) \<rbrakk>
    \<Longrightarrow> lrec(l,b,c) : C(l)"
  by (erule List_ind) auto

lemmas precTs = nrecT lrecT


subsection {* Theorem proving *}

lemma SgE2: "\<lbrakk><a,b> : Sigma(A,B); \<lbrakk>a:A; b:B(a)\<rbrakk> \<Longrightarrow> P\<rbrakk> \<Longrightarrow> P"
  unfolding SgXH by blast

(* General theorem proving ignores non-canonical term-formers,             *)
(*         - intro rules are type rules for canonical terms                *)
(*         - elim rules are case rules (no non-canonical terms appear)     *)

ML {* ML_Thms.bind_thms ("XHEs", XH_to_Es @{thms XHs}) *}

lemmas [intro!] = SubtypeI canTs icanTs
  and [elim!] = SubtypeE XHEs


subsection {* Infinite Data Types *}

lemma lfp_subset_gfp: "mono(f) \<Longrightarrow> lfp(f) <= gfp(f)"
  apply (rule lfp_lowerbound [THEN subset_trans])
   apply (erule gfp_lemma3)
  apply (rule subset_refl)
  done

lemma gfpI:
  assumes "a:A"
    and "\<And>x X. \<lbrakk>x:A; ALL y:A. t(y):X\<rbrakk> \<Longrightarrow> t(x) : B(X)"
  shows "t(a) : gfp(B)"
  apply (rule coinduct)
   apply (rule_tac P = "\<lambda>x. EX y:A. x=t (y)" in CollectI)
   apply (blast intro!: assms)+
  done

lemma def_gfpI: "\<lbrakk>C == gfp(B); a:A; \<And>x X. \<lbrakk>x:A; ALL y:A. t(y):X\<rbrakk> \<Longrightarrow> t(x) : B(X)\<rbrakk> \<Longrightarrow> t(a) : C"
  apply unfold
  apply (erule gfpI)
  apply blast
  done

(* EG *)
lemma "letrec g x be zero$g(x) in g(bot) : Lists(Nat)"
  apply (rule refl [THEN UnitXH [THEN iffD2], THEN Lists_def [THEN def_gfpI]])
  apply (subst letrecB)
  apply (unfold cons_def)
  apply blast
  done


subsection {* Lemmas and tactics for using the rule @{text
  "coinduct3"} on @{text "[="} and @{text "="} *}

lemma lfpI: "\<lbrakk>mono(f); a : f(lfp(f))\<rbrakk> \<Longrightarrow> a : lfp(f)"
  apply (erule lfp_Tarski [THEN ssubst])
  apply assumption
  done

lemma ssubst_single: "\<lbrakk>a = a'; a' : A\<rbrakk> \<Longrightarrow> a : A"
  by simp

lemma ssubst_pair: "\<lbrakk>a = a'; b = b'; <a',b'> : A\<rbrakk> \<Longrightarrow> <a,b> : A"
  by simp


ML {*
  val coinduct3_tac = SUBPROOF (fn {context = ctxt, prems = mono :: prems, ...} =>
    fast_tac (ctxt addIs (mono RS @{thm coinduct3_mono_lemma} RS @{thm lfpI}) :: prems) 1);
*}

method_setup coinduct3 = {* Scan.succeed (SIMPLE_METHOD' o coinduct3_tac) *}

lemma ci3_RI: "\<lbrakk>mono(Agen); a : R\<rbrakk> \<Longrightarrow> a : lfp(\<lambda>x. Agen(x) Un R Un A)"
  by coinduct3

lemma ci3_AgenI: "\<lbrakk>mono(Agen); a : Agen(lfp(\<lambda>x. Agen(x) Un R Un A))\<rbrakk> \<Longrightarrow>
    a : lfp(\<lambda>x. Agen(x) Un R Un A)"
  by coinduct3

lemma ci3_AI: "\<lbrakk>mono(Agen); a : A\<rbrakk> \<Longrightarrow> a : lfp(\<lambda>x. Agen(x) Un R Un A)"
  by coinduct3

ML {*
fun genIs_tac ctxt genXH gen_mono =
  rtac (genXH RS @{thm iffD2}) THEN'
  simp_tac ctxt THEN'
  TRY o fast_tac
    (ctxt addIs [genXH RS @{thm iffD2}, gen_mono RS @{thm coinduct3_mono_lemma} RS @{thm lfpI}])
*}

method_setup genIs = {*
  Attrib.thm -- Attrib.thm >>
    (fn (genXH, gen_mono) => fn ctxt => SIMPLE_METHOD' (genIs_tac ctxt genXH gen_mono))
*}


subsection {* POgen *}

lemma PO_refl: "<a,a> : PO"
  by (rule po_refl [THEN PO_iff [THEN iffD1]])

lemma POgenIs:
  "<true,true> : POgen(R)"
  "<false,false> : POgen(R)"
  "\<lbrakk><a,a'> : R; <b,b'> : R\<rbrakk> \<Longrightarrow> <<a,b>,<a',b'>> : POgen(R)"
  "\<And>b b'. (\<And>x. <b(x),b'(x)> : R) \<Longrightarrow> <lam x. b(x),lam x. b'(x)> : POgen(R)"
  "<one,one> : POgen(R)"
  "<a,a'> : lfp(\<lambda>x. POgen(x) Un R Un PO) \<Longrightarrow>
    <inl(a),inl(a')> : POgen(lfp(\<lambda>x. POgen(x) Un R Un PO))"
  "<b,b'> : lfp(\<lambda>x. POgen(x) Un R Un PO) \<Longrightarrow>
    <inr(b),inr(b')> : POgen(lfp(\<lambda>x. POgen(x) Un R Un PO))"
  "<zero,zero> : POgen(lfp(\<lambda>x. POgen(x) Un R Un PO))"
  "<n,n'> : lfp(\<lambda>x. POgen(x) Un R Un PO) \<Longrightarrow>
    <succ(n),succ(n')> : POgen(lfp(\<lambda>x. POgen(x) Un R Un PO))"
  "<[],[]> : POgen(lfp(\<lambda>x. POgen(x) Un R Un PO))"
  "\<lbrakk><h,h'> : lfp(\<lambda>x. POgen(x) Un R Un PO);  <t,t'> : lfp(\<lambda>x. POgen(x) Un R Un PO)\<rbrakk>
    \<Longrightarrow> <h$t,h'$t'> : POgen(lfp(\<lambda>x. POgen(x) Un R Un PO))"
  unfolding data_defs by (genIs POgenXH POgen_mono)+

ML {*
fun POgen_tac ctxt (rla, rlb) i =
  SELECT_GOAL (safe_tac ctxt) i THEN
  rtac (rlb RS (rla RS @{thm ssubst_pair})) i THEN
  (REPEAT (resolve_tac
      (@{thms POgenIs} @ [@{thm PO_refl} RS (@{thm POgen_mono} RS @{thm ci3_AI})] @
        (@{thms POgenIs} RL [@{thm POgen_mono} RS @{thm ci3_AgenI}]) @
        [@{thm POgen_mono} RS @{thm ci3_RI}]) i))
*}


subsection {* EQgen *}

lemma EQ_refl: "<a,a> : EQ"
  by (rule refl [THEN EQ_iff [THEN iffD1]])

lemma EQgenIs:
  "<true,true> : EQgen(R)"
  "<false,false> : EQgen(R)"
  "\<lbrakk><a,a'> : R; <b,b'> : R\<rbrakk> \<Longrightarrow> <<a,b>,<a',b'>> : EQgen(R)"
  "\<And>b b'. (\<And>x. <b(x),b'(x)> : R) \<Longrightarrow> <lam x. b(x),lam x. b'(x)> : EQgen(R)"
  "<one,one> : EQgen(R)"
  "<a,a'> : lfp(\<lambda>x. EQgen(x) Un R Un EQ) \<Longrightarrow>
    <inl(a),inl(a')> : EQgen(lfp(\<lambda>x. EQgen(x) Un R Un EQ))"
  "<b,b'> : lfp(\<lambda>x. EQgen(x) Un R Un EQ) \<Longrightarrow>
    <inr(b),inr(b')> : EQgen(lfp(\<lambda>x. EQgen(x) Un R Un EQ))"
  "<zero,zero> : EQgen(lfp(\<lambda>x. EQgen(x) Un R Un EQ))"
  "<n,n'> : lfp(\<lambda>x. EQgen(x) Un R Un EQ) \<Longrightarrow>
    <succ(n),succ(n')> : EQgen(lfp(\<lambda>x. EQgen(x) Un R Un EQ))"
  "<[],[]> : EQgen(lfp(\<lambda>x. EQgen(x) Un R Un EQ))"
  "\<lbrakk><h,h'> : lfp(\<lambda>x. EQgen(x) Un R Un EQ); <t,t'> : lfp(\<lambda>x. EQgen(x) Un R Un EQ)\<rbrakk>
    \<Longrightarrow> <h$t,h'$t'> : EQgen(lfp(\<lambda>x. EQgen(x) Un R Un EQ))"
  unfolding data_defs by (genIs EQgenXH EQgen_mono)+

ML {*
fun EQgen_raw_tac i =
  (REPEAT (resolve_tac (@{thms EQgenIs} @
        [@{thm EQ_refl} RS (@{thm EQgen_mono} RS @{thm ci3_AI})] @
        (@{thms EQgenIs} RL [@{thm EQgen_mono} RS @{thm ci3_AgenI}]) @
        [@{thm EQgen_mono} RS @{thm ci3_RI}]) i))

(* Goals of the form R <= EQgen(R) - rewrite elements <a,b> : EQgen(R) using rews and *)
(* then reduce this to a goal <a',b'> : R (hopefully?)                                *)
(*      rews are rewrite rules that would cause looping in the simpifier              *)

fun EQgen_tac ctxt rews i =
 SELECT_GOAL
   (TRY (safe_tac ctxt) THEN
    resolve_tac ((rews @ [@{thm refl}]) RL ((rews @ [@{thm refl}]) RL [@{thm ssubst_pair}])) i THEN
    ALLGOALS (simp_tac ctxt) THEN
    ALLGOALS EQgen_raw_tac) i
*}

method_setup EQgen = {*
  Attrib.thms >> (fn ths => fn ctxt => SIMPLE_METHOD' (EQgen_tac ctxt ths))
*}

end

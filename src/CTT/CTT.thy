(*  Title:      CTT/CTT.thy
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1993  University of Cambridge
*)

section {* Constructive Type Theory *}

theory CTT
imports Pure
begin

ML_file "~~/src/Provers/typedsimp.ML"
setup Pure_Thy.old_appl_syntax_setup

typedecl i
typedecl t
typedecl o

consts
  (*Types*)
  F         :: "t"
  T         :: "t"          (*F is empty, T contains one element*)
  contr     :: "i=>i"
  tt        :: "i"
  (*Natural numbers*)
  N         :: "t"
  succ      :: "i=>i"
  rec       :: "[i, i, [i,i]=>i] => i"
  (*Unions*)
  inl       :: "i=>i"
  inr       :: "i=>i"
  when      :: "[i, i=>i, i=>i]=>i"
  (*General Sum and Binary Product*)
  Sum       :: "[t, i=>t]=>t"
  fst       :: "i=>i"
  snd       :: "i=>i"
  split     :: "[i, [i,i]=>i] =>i"
  (*General Product and Function Space*)
  Prod      :: "[t, i=>t]=>t"
  (*Types*)
  Plus      :: "[t,t]=>t"           (infixr "+" 40)
  (*Equality type*)
  Eq        :: "[t,i,i]=>t"
  eq        :: "i"
  (*Judgements*)
  Type      :: "t => prop"          ("(_ type)" [10] 5)
  Eqtype    :: "[t,t]=>prop"        ("(_ =/ _)" [10,10] 5)
  Elem      :: "[i, t]=>prop"       ("(_ /: _)" [10,10] 5)
  Eqelem    :: "[i,i,t]=>prop"      ("(_ =/ _ :/ _)" [10,10,10] 5)
  Reduce    :: "[i,i]=>prop"        ("Reduce[_,_]")
  (*Types*)

  (*Functions*)
  lambda    :: "(i => i) => i"      (binder "lam " 10)
  app       :: "[i,i]=>i"           (infixl "`" 60)
  (*Natural numbers*)
  Zero      :: "i"                  ("0")
  (*Pairing*)
  pair      :: "[i,i]=>i"           ("(1<_,/_>)")

syntax
  "_PROD"   :: "[idt,t,t]=>t"       ("(3PROD _:_./ _)" 10)
  "_SUM"    :: "[idt,t,t]=>t"       ("(3SUM _:_./ _)" 10)
translations
  "PROD x:A. B" == "CONST Prod(A, %x. B)"
  "SUM x:A. B"  == "CONST Sum(A, %x. B)"

abbreviation
  Arrow     :: "[t,t]=>t"  (infixr "-->" 30) where
  "A --> B == PROD _:A. B"
abbreviation
  Times     :: "[t,t]=>t"  (infixr "*" 50) where
  "A * B == SUM _:A. B"

notation (xsymbols)
  lambda  (binder "\<lambda>\<lambda>" 10) and
  Elem  ("(_ /\<in> _)" [10,10] 5) and
  Eqelem  ("(2_ =/ _ \<in>/ _)" [10,10,10] 5) and
  Arrow  (infixr "\<longrightarrow>" 30) and
  Times  (infixr "\<times>" 50)

notation (HTML output)
  lambda  (binder "\<lambda>\<lambda>" 10) and
  Elem  ("(_ /\<in> _)" [10,10] 5) and
  Eqelem  ("(2_ =/ _ \<in>/ _)" [10,10,10] 5) and
  Times  (infixr "\<times>" 50)

syntax (xsymbols)
  "_PROD"   :: "[idt,t,t] => t"     ("(3\<Pi> _\<in>_./ _)"    10)
  "_SUM"    :: "[idt,t,t] => t"     ("(3\<Sigma> _\<in>_./ _)" 10)

syntax (HTML output)
  "_PROD"   :: "[idt,t,t] => t"     ("(3\<Pi> _\<in>_./ _)"    10)
  "_SUM"    :: "[idt,t,t] => t"     ("(3\<Sigma> _\<in>_./ _)" 10)

  (*Reduction: a weaker notion than equality;  a hack for simplification.
    Reduce[a,b] means either that  a=b:A  for some A or else that "a" and "b"
    are textually identical.*)

  (*does not verify a:A!  Sound because only trans_red uses a Reduce premise
    No new theorems can be proved about the standard judgements.*)
axiomatization where
  refl_red: "\<And>a. Reduce[a,a]" and
  red_if_equal: "\<And>a b A. a = b : A ==> Reduce[a,b]" and
  trans_red: "\<And>a b c A. [| a = b : A;  Reduce[b,c] |] ==> a = c : A" and

  (*Reflexivity*)

  refl_type: "\<And>A. A type ==> A = A" and
  refl_elem: "\<And>a A. a : A ==> a = a : A" and

  (*Symmetry*)

  sym_type:  "\<And>A B. A = B ==> B = A" and
  sym_elem:  "\<And>a b A. a = b : A ==> b = a : A" and

  (*Transitivity*)

  trans_type:   "\<And>A B C. [| A = B;  B = C |] ==> A = C" and
  trans_elem:   "\<And>a b c A. [| a = b : A;  b = c : A |] ==> a = c : A" and

  equal_types:  "\<And>a A B. [| a : A;  A = B |] ==> a : B" and
  equal_typesL: "\<And>a b A B. [| a = b : A;  A = B |] ==> a = b : B" and

  (*Substitution*)

  subst_type:   "\<And>a A B. [| a : A;  !!z. z:A ==> B(z) type |] ==> B(a) type" and
  subst_typeL:  "\<And>a c A B D. [| a = c : A;  !!z. z:A ==> B(z) = D(z) |] ==> B(a) = D(c)" and

  subst_elem:   "\<And>a b A B. [| a : A;  !!z. z:A ==> b(z):B(z) |] ==> b(a):B(a)" and
  subst_elemL:
    "\<And>a b c d A B. [| a=c : A;  !!z. z:A ==> b(z)=d(z) : B(z) |] ==> b(a)=d(c) : B(a)" and


  (*The type N -- natural numbers*)

  NF: "N type" and
  NI0: "0 : N" and
  NI_succ: "\<And>a. a : N ==> succ(a) : N" and
  NI_succL:  "\<And>a b. a = b : N ==> succ(a) = succ(b) : N" and

  NE:
   "\<And>p a b C. [| p: N;  a: C(0);  !!u v. [| u: N; v: C(u) |] ==> b(u,v): C(succ(u)) |]
   ==> rec(p, a, %u v. b(u,v)) : C(p)" and

  NEL:
   "\<And>p q a b c d C. [| p = q : N;  a = c : C(0);
      !!u v. [| u: N; v: C(u) |] ==> b(u,v) = d(u,v): C(succ(u)) |]
   ==> rec(p, a, %u v. b(u,v)) = rec(q,c,d) : C(p)" and

  NC0:
   "\<And>a b C. [| a: C(0);  !!u v. [| u: N; v: C(u) |] ==> b(u,v): C(succ(u)) |]
   ==> rec(0, a, %u v. b(u,v)) = a : C(0)" and

  NC_succ:
   "\<And>p a b C. [| p: N;  a: C(0);
       !!u v. [| u: N; v: C(u) |] ==> b(u,v): C(succ(u)) |] ==>
   rec(succ(p), a, %u v. b(u,v)) = b(p, rec(p, a, %u v. b(u,v))) : C(succ(p))" and

  (*The fourth Peano axiom.  See page 91 of Martin-Lof's book*)
  zero_ne_succ:
    "\<And>a. [| a: N;  0 = succ(a) : N |] ==> 0: F" and


  (*The Product of a family of types*)

  ProdF:  "\<And>A B. [| A type; !!x. x:A ==> B(x) type |] ==> PROD x:A. B(x) type" and

  ProdFL:
   "\<And>A B C D. [| A = C;  !!x. x:A ==> B(x) = D(x) |] ==>
   PROD x:A. B(x) = PROD x:C. D(x)" and

  ProdI:
   "\<And>b A B. [| A type;  !!x. x:A ==> b(x):B(x)|] ==> lam x. b(x) : PROD x:A. B(x)" and

  ProdIL:
   "\<And>b c A B. [| A type;  !!x. x:A ==> b(x) = c(x) : B(x)|] ==>
   lam x. b(x) = lam x. c(x) : PROD x:A. B(x)" and

  ProdE:  "\<And>p a A B. [| p : PROD x:A. B(x);  a : A |] ==> p`a : B(a)" and
  ProdEL: "\<And>p q a b A B. [| p=q: PROD x:A. B(x);  a=b : A |] ==> p`a = q`b : B(a)" and

  ProdC:
   "\<And>a b A B. [| a : A;  !!x. x:A ==> b(x) : B(x)|] ==>
   (lam x. b(x)) ` a = b(a) : B(a)" and

  ProdC2:
   "\<And>p A B. p : PROD x:A. B(x) ==> (lam x. p`x) = p : PROD x:A. B(x)" and


  (*The Sum of a family of types*)

  SumF:  "\<And>A B. [| A type;  !!x. x:A ==> B(x) type |] ==> SUM x:A. B(x) type" and
  SumFL:
    "\<And>A B C D. [| A = C;  !!x. x:A ==> B(x) = D(x) |] ==> SUM x:A. B(x) = SUM x:C. D(x)" and

  SumI:  "\<And>a b A B. [| a : A;  b : B(a) |] ==> <a,b> : SUM x:A. B(x)" and
  SumIL: "\<And>a b c d A B. [| a=c:A;  b=d:B(a) |] ==> <a,b> = <c,d> : SUM x:A. B(x)" and

  SumE:
    "\<And>p c A B C. [| p: SUM x:A. B(x);  !!x y. [| x:A; y:B(x) |] ==> c(x,y): C(<x,y>) |]
    ==> split(p, %x y. c(x,y)) : C(p)" and

  SumEL:
    "\<And>p q c d A B C. [| p=q : SUM x:A. B(x);
       !!x y. [| x:A; y:B(x) |] ==> c(x,y)=d(x,y): C(<x,y>)|]
    ==> split(p, %x y. c(x,y)) = split(q, % x y. d(x,y)) : C(p)" and

  SumC:
    "\<And>a b c A B C. [| a: A;  b: B(a);  !!x y. [| x:A; y:B(x) |] ==> c(x,y): C(<x,y>) |]
    ==> split(<a,b>, %x y. c(x,y)) = c(a,b) : C(<a,b>)" and

  fst_def:   "\<And>a. fst(a) == split(a, %x y. x)" and
  snd_def:   "\<And>a. snd(a) == split(a, %x y. y)" and


  (*The sum of two types*)

  PlusF:   "\<And>A B. [| A type;  B type |] ==> A+B type" and
  PlusFL:  "\<And>A B C D. [| A = C;  B = D |] ==> A+B = C+D" and

  PlusI_inl:   "\<And>a A B. [| a : A;  B type |] ==> inl(a) : A+B" and
  PlusI_inlL: "\<And>a c A B. [| a = c : A;  B type |] ==> inl(a) = inl(c) : A+B" and

  PlusI_inr:   "\<And>b A B. [| A type;  b : B |] ==> inr(b) : A+B" and
  PlusI_inrL: "\<And>b d A B. [| A type;  b = d : B |] ==> inr(b) = inr(d) : A+B" and

  PlusE:
    "\<And>p c d A B C. [| p: A+B;  !!x. x:A ==> c(x): C(inl(x));
                !!y. y:B ==> d(y): C(inr(y)) |]
    ==> when(p, %x. c(x), %y. d(y)) : C(p)" and

  PlusEL:
    "\<And>p q c d e f A B C. [| p = q : A+B;  !!x. x: A ==> c(x) = e(x) : C(inl(x));
                     !!y. y: B ==> d(y) = f(y) : C(inr(y)) |]
    ==> when(p, %x. c(x), %y. d(y)) = when(q, %x. e(x), %y. f(y)) : C(p)" and

  PlusC_inl:
    "\<And>a c d A C. [| a: A;  !!x. x:A ==> c(x): C(inl(x));
              !!y. y:B ==> d(y): C(inr(y)) |]
    ==> when(inl(a), %x. c(x), %y. d(y)) = c(a) : C(inl(a))" and

  PlusC_inr:
    "\<And>b c d A B C. [| b: B;  !!x. x:A ==> c(x): C(inl(x));
              !!y. y:B ==> d(y): C(inr(y)) |]
    ==> when(inr(b), %x. c(x), %y. d(y)) = d(b) : C(inr(b))" and


  (*The type Eq*)

  EqF:    "\<And>a b A. [| A type;  a : A;  b : A |] ==> Eq(A,a,b) type" and
  EqFL: "\<And>a b c d A B. [| A=B;  a=c: A;  b=d : A |] ==> Eq(A,a,b) = Eq(B,c,d)" and
  EqI: "\<And>a b A. a = b : A ==> eq : Eq(A,a,b)" and
  EqE: "\<And>p a b A. p : Eq(A,a,b) ==> a = b : A" and

  (*By equality of types, can prove C(p) from C(eq), an elimination rule*)
  EqC: "\<And>p a b A. p : Eq(A,a,b) ==> p = eq : Eq(A,a,b)" and

  (*The type F*)

  FF: "F type" and
  FE: "\<And>p C. [| p: F;  C type |] ==> contr(p) : C" and
  FEL:  "\<And>p q C. [| p = q : F;  C type |] ==> contr(p) = contr(q) : C" and

  (*The type T
     Martin-Lof's book (page 68) discusses elimination and computation.
     Elimination can be derived by computation and equality of types,
     but with an extra premise C(x) type x:T.
     Also computation can be derived from elimination. *)

  TF: "T type" and
  TI: "tt : T" and
  TE: "\<And>p c C. [| p : T;  c : C(tt) |] ==> c : C(p)" and
  TEL: "\<And>p q c d C. [| p = q : T;  c = d : C(tt) |] ==> c = d : C(p)" and
  TC: "\<And>p. p : T ==> p = tt : T"


subsection "Tactics and derived rules for Constructive Type Theory"

(*Formation rules*)
lemmas form_rls = NF ProdF SumF PlusF EqF FF TF
  and formL_rls = ProdFL SumFL PlusFL EqFL

(*Introduction rules
  OMITTED: EqI, because its premise is an eqelem, not an elem*)
lemmas intr_rls = NI0 NI_succ ProdI SumI PlusI_inl PlusI_inr TI
  and intrL_rls = NI_succL ProdIL SumIL PlusI_inlL PlusI_inrL

(*Elimination rules
  OMITTED: EqE, because its conclusion is an eqelem,  not an elem
           TE, because it does not involve a constructor *)
lemmas elim_rls = NE ProdE SumE PlusE FE
  and elimL_rls = NEL ProdEL SumEL PlusEL FEL

(*OMITTED: eqC are TC because they make rewriting loop: p = un = un = ... *)
lemmas comp_rls = NC0 NC_succ ProdC SumC PlusC_inl PlusC_inr

(*rules with conclusion a:A, an elem judgement*)
lemmas element_rls = intr_rls elim_rls

(*Definitions are (meta)equality axioms*)
lemmas basic_defs = fst_def snd_def

(*Compare with standard version: B is applied to UNSIMPLIFIED expression! *)
lemma SumIL2: "[| c=a : A;  d=b : B(a) |] ==> <c,d> = <a,b> : Sum(A,B)"
apply (rule sym_elem)
apply (rule SumIL)
apply (rule_tac [!] sym_elem)
apply assumption+
done

lemmas intrL2_rls = NI_succL ProdIL SumIL2 PlusI_inlL PlusI_inrL

(*Exploit p:Prod(A,B) to create the assumption z:B(a).
  A more natural form of product elimination. *)
lemma subst_prodE:
  assumes "p: Prod(A,B)"
    and "a: A"
    and "!!z. z: B(a) ==> c(z): C(z)"
  shows "c(p`a): C(p`a)"
apply (rule assms ProdE)+
done


subsection {* Tactics for type checking *}

ML {*

local

fun is_rigid_elem (Const(@{const_name Elem},_) $ a $ _) = not(is_Var (head_of a))
  | is_rigid_elem (Const(@{const_name Eqelem},_) $ a $ _ $ _) = not(is_Var (head_of a))
  | is_rigid_elem (Const(@{const_name Type},_) $ a) = not(is_Var (head_of a))
  | is_rigid_elem _ = false

in

(*Try solving a:A or a=b:A by assumption provided a is rigid!*)
fun test_assume_tac ctxt = SUBGOAL(fn (prem,i) =>
    if is_rigid_elem (Logic.strip_assums_concl prem)
    then  assume_tac ctxt i  else  no_tac)

fun ASSUME ctxt tf i = test_assume_tac ctxt i  ORELSE  tf i

end;

*}

(*For simplification: type formation and checking,
  but no equalities between terms*)
lemmas routine_rls = form_rls formL_rls refl_type element_rls

ML {*
local
  val equal_rls = @{thms form_rls} @ @{thms element_rls} @ @{thms intrL_rls} @
    @{thms elimL_rls} @ @{thms refl_elem}
in

fun routine_tac rls ctxt prems = ASSUME ctxt (filt_resolve_tac (prems @ rls) 4);

(*Solve all subgoals "A type" using formation rules. *)
fun form_tac ctxt = REPEAT_FIRST (ASSUME ctxt (filt_resolve_tac @{thms form_rls} 1));

(*Type checking: solve a:A (a rigid, A flexible) by intro and elim rules. *)
fun typechk_tac ctxt thms =
  let val tac = filt_resolve_tac (thms @ @{thms form_rls} @ @{thms element_rls}) 3
  in  REPEAT_FIRST (ASSUME ctxt tac)  end

(*Solve a:A (a flexible, A rigid) by introduction rules.
  Cannot use stringtrees (filt_resolve_tac) since
  goals like ?a:SUM(A,B) have a trivial head-string *)
fun intr_tac ctxt thms =
  let val tac = filt_resolve_tac(thms @ @{thms form_rls} @ @{thms intr_rls}) 1
  in  REPEAT_FIRST (ASSUME ctxt tac)  end

(*Equality proving: solve a=b:A (where a is rigid) by long rules. *)
fun equal_tac ctxt thms =
  REPEAT_FIRST (ASSUME ctxt (filt_resolve_tac (thms @ equal_rls) 3))

end
*}

method_setup form = {*
  Scan.succeed (fn ctxt => SIMPLE_METHOD (form_tac ctxt))
*}

method_setup typechk = {*
  Attrib.thms >> (fn ths => fn ctxt => SIMPLE_METHOD (typechk_tac ctxt ths))
*}

method_setup intr = {*
  Attrib.thms >> (fn ths => fn ctxt => SIMPLE_METHOD (intr_tac ctxt ths))
*}

method_setup equal = {*
  Attrib.thms >> (fn ths => fn ctxt => SIMPLE_METHOD (equal_tac ctxt ths))
*}


subsection {* Simplification *}

(*To simplify the type in a goal*)
lemma replace_type: "[| B = A;  a : A |] ==> a : B"
apply (rule equal_types)
apply (rule_tac [2] sym_type)
apply assumption+
done

(*Simplify the parameter of a unary type operator.*)
lemma subst_eqtyparg:
  assumes 1: "a=c : A"
    and 2: "!!z. z:A ==> B(z) type"
  shows "B(a)=B(c)"
apply (rule subst_typeL)
apply (rule_tac [2] refl_type)
apply (rule 1)
apply (erule 2)
done

(*Simplification rules for Constructive Type Theory*)
lemmas reduction_rls = comp_rls [THEN trans_elem]

ML {*
(*Converts each goal "e : Eq(A,a,b)" into "a=b:A" for simplification.
  Uses other intro rules to avoid changing flexible goals.*)
fun eqintr_tac ctxt =
  REPEAT_FIRST (ASSUME ctxt (filt_resolve_tac (@{thm EqI} :: @{thms intr_rls}) 1))

(** Tactics that instantiate CTT-rules.
    Vars in the given terms will be incremented!
    The (rtac EqE i) lets them apply to equality judgements. **)

fun NE_tac ctxt sp i =
  TRY (rtac @{thm EqE} i) THEN res_inst_tac ctxt [(("p", 0), sp)] @{thm NE} i

fun SumE_tac ctxt sp i =
  TRY (rtac @{thm EqE} i) THEN res_inst_tac ctxt [(("p", 0), sp)] @{thm SumE} i

fun PlusE_tac ctxt sp i =
  TRY (rtac @{thm EqE} i) THEN res_inst_tac ctxt [(("p", 0), sp)] @{thm PlusE} i

(** Predicate logic reasoning, WITH THINNING!!  Procedures adapted from NJ. **)

(*Finds f:Prod(A,B) and a:A in the assumptions, concludes there is z:B(a) *)
fun add_mp_tac ctxt i =
    rtac @{thm subst_prodE} i  THEN  assume_tac ctxt i  THEN  assume_tac ctxt i

(*Finds P-->Q and P in the assumptions, replaces implication by Q *)
fun mp_tac ctxt i = etac @{thm subst_prodE} i  THEN  assume_tac ctxt i

(*"safe" when regarded as predicate calculus rules*)
val safe_brls = sort (make_ord lessb)
    [ (true, @{thm FE}), (true,asm_rl),
      (false, @{thm ProdI}), (true, @{thm SumE}), (true, @{thm PlusE}) ]

val unsafe_brls =
    [ (false, @{thm PlusI_inl}), (false, @{thm PlusI_inr}), (false, @{thm SumI}),
      (true, @{thm subst_prodE}) ]

(*0 subgoals vs 1 or more*)
val (safe0_brls, safep_brls) =
    List.partition (curry (op =) 0 o subgoals_of_brl) safe_brls

fun safestep_tac ctxt thms i =
    form_tac ctxt ORELSE
    resolve_tac thms i  ORELSE
    biresolve_tac safe0_brls i  ORELSE  mp_tac ctxt i  ORELSE
    DETERM (biresolve_tac safep_brls i)

fun safe_tac ctxt thms i = DEPTH_SOLVE_1 (safestep_tac ctxt thms i)

fun step_tac ctxt thms = safestep_tac ctxt thms  ORELSE'  biresolve_tac unsafe_brls

(*Fails unless it solves the goal!*)
fun pc_tac ctxt thms = DEPTH_SOLVE_1 o (step_tac ctxt thms)
*}

method_setup eqintr = {*
  Scan.succeed (SIMPLE_METHOD o eqintr_tac)
*}

method_setup NE = {*
  Scan.lift Args.name_inner_syntax >> (fn s => fn ctxt => SIMPLE_METHOD' (NE_tac ctxt s))
*}

method_setup pc = {*
  Attrib.thms >> (fn ths => fn ctxt => SIMPLE_METHOD' (pc_tac ctxt ths))
*}

method_setup add_mp = {*
  Scan.succeed (SIMPLE_METHOD' o add_mp_tac)
*}

ML_file "rew.ML"

method_setup rew = {*
  Attrib.thms >> (fn ths => fn ctxt => SIMPLE_METHOD (rew_tac ctxt ths))
*}

method_setup hyp_rew = {*
  Attrib.thms >> (fn ths => fn ctxt => SIMPLE_METHOD (hyp_rew_tac ctxt ths))
*}


subsection {* The elimination rules for fst/snd *}

lemma SumE_fst: "p : Sum(A,B) ==> fst(p) : A"
apply (unfold basic_defs)
apply (erule SumE)
apply assumption
done

(*The first premise must be p:Sum(A,B) !!*)
lemma SumE_snd:
  assumes major: "p: Sum(A,B)"
    and "A type"
    and "!!x. x:A ==> B(x) type"
  shows "snd(p) : B(fst(p))"
  apply (unfold basic_defs)
  apply (rule major [THEN SumE])
  apply (rule SumC [THEN subst_eqtyparg, THEN replace_type])
  apply (typechk assms)
  done

end

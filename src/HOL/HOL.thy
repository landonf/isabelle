(*  Title:      HOL/HOL.thy
    ID:         $Id$
    Author:     Tobias Nipkow
    Copyright   1993  University of Cambridge

Higher-Order Logic.
*)

HOL = CPure +


(** Core syntax **)

global

classes
  term < logic

default
  term

types
  bool

arities
  fun :: (term, term) term
  bool :: term


consts

  (* Constants *)

  Trueprop      :: bool => prop                     ("(_)" 5)
  Not           :: bool => bool                     ("~ _" [40] 40)
  True, False   :: bool
  If            :: [bool, 'a, 'a] => 'a   ("(if (_)/ then (_)/ else (_))" 10)
  arbitrary     :: 'a

  (* Binders *)

  Eps           :: ('a => bool) => 'a
  All           :: ('a => bool) => bool             (binder "! " 10)
  Ex            :: ('a => bool) => bool             (binder "? " 10)
  Ex1           :: ('a => bool) => bool             (binder "?! " 10)
  Let           :: ['a, 'a => 'b] => 'b

  (* Infixes *)

  "="           :: ['a, 'a] => bool                 (infixl 50)
  "&"           :: [bool, bool] => bool             (infixr 35)
  "|"           :: [bool, bool] => bool             (infixr 30)
  "-->"         :: [bool, bool] => bool             (infixr 25)


(* Overloaded Constants *)

axclass
  plus < term

axclass
  minus < term

axclass
  times < term

axclass
  power < term

consts
  "+"           :: ['a::plus, 'a]  => 'a            (infixl 65)
  "-"           :: ['a::minus, 'a] => 'a            (infixl 65)
  uminus        :: ['a::minus] => 'a                ("- _" [71] 70)
  "*"           :: ['a::times, 'a] => 'a            (infixl 70)
  (*See Nat.thy for "^"*)


(** Additional concrete syntax **)

nonterminals
  letbinds  letbind
  case_syn  cases_syn

syntax

  "~="          :: ['a, 'a] => bool                 (infixl 50)

  "@Eps"        :: [pttrn, bool] => 'a              ("(3@ _./ _)" [0, 10] 10)

  (* Alternative Quantifiers *)

  "*All"        :: [idts, bool] => bool             ("(3ALL _./ _)" [0, 10] 10)
  "*Ex"         :: [idts, bool] => bool             ("(3EX _./ _)" [0, 10] 10)
  "*Ex1"        :: [idts, bool] => bool             ("(3EX! _./ _)" [0, 10] 10)

  (* Let expressions *)

  "_bind"       :: [pttrn, 'a] => letbind           ("(2_ =/ _)" 10)
  ""            :: letbind => letbinds              ("_")
  "_binds"      :: [letbind, letbinds] => letbinds  ("_;/ _")
  "_Let"        :: [letbinds, 'a] => 'a             ("(let (_)/ in (_))" 10)

  (* Case expressions *)

  "@case"       :: ['a, cases_syn] => 'b            ("(case _ of/ _)" 10)
  "@case1"      :: ['a, 'b] => case_syn             ("(2_ =>/ _)" 10)
  ""            :: case_syn => cases_syn            ("_")
  "@case2"      :: [case_syn, cases_syn] => cases_syn   ("_/ | _")

translations
  "x ~= y"      == "~ (x = y)"
  "@ x. b"      == "Eps (%x. b)"
  "ALL xs. P"   => "! xs. P"
  "EX xs. P"    => "? xs. P"
  "EX! xs. P"   => "?! xs. P"
  "_Let (_binds b bs) e"  == "_Let b (_Let bs e)"
  "let x = a in e"        == "Let a (%x. e)"

syntax ("" output)
  "op ="        :: ['a, 'a] => bool                 ("(_ =/ _)" [51, 51] 50)
  "op ~="       :: ['a, 'a] => bool                 ("(_ ~=/ _)" [51, 51] 50)

syntax (symbols)
  Not           :: bool => bool                     ("\\<not> _" [40] 40)
  "op &"        :: [bool, bool] => bool             (infixr "\\<and>" 35)
  "op |"        :: [bool, bool] => bool             (infixr "\\<or>" 30)
  "op -->"      :: [bool, bool] => bool             (infixr "\\<midarrow>\\<rightarrow>" 25)
  "op o"        :: ['b => 'c, 'a => 'b, 'a] => 'c   (infixl "\\<circ>" 55)
  "op ~="       :: ['a, 'a] => bool                 (infixl "\\<noteq>" 50)
  "@Eps"        :: [pttrn, bool] => 'a              ("(3\\<epsilon>_./ _)" [0, 10] 10)
  "! "          :: [idts, bool] => bool             ("(3\\<forall>_./ _)" [0, 10] 10)
  "? "          :: [idts, bool] => bool             ("(3\\<exists>_./ _)" [0, 10] 10)
  "?! "         :: [idts, bool] => bool             ("(3\\<exists>!_./ _)" [0, 10] 10)
  "@case1"      :: ['a, 'b] => case_syn             ("(2_ \\<Rightarrow>/ _)" 10)
(*"@case2"      :: [case_syn, cases_syn] => cases_syn   ("_/ \\<orelse> _")*)

syntax (symbols output)
  "op ~="       :: ['a, 'a] => bool                 ("(_ \\<noteq>/ _)" [51, 51] 50)
  "*All"        :: [idts, bool] => bool             ("(3\\<forall>_./ _)" [0, 10] 10)
  "*Ex"         :: [idts, bool] => bool             ("(3\\<exists>_./ _)" [0, 10] 10)
  "*Ex1"        :: [idts, bool] => bool             ("(3\\<exists>!_./ _)" [0, 10] 10)

syntax (xsymbols)
  "op -->"      :: [bool, bool] => bool             (infixr "\\<longrightarrow>" 25)

syntax (HTML output)
  Not           :: bool => bool                     ("\\<not> _" [40] 40)


(** Rules and definitions **)

local

rules

  eq_reflection "(x=y) ==> (x==y)"

  (* Basic Rules *)

  refl          "t = (t::'a)"
  subst         "[| s = t; P(s) |] ==> P(t::'a)"

  (*Extensionality is built into the meta-logic, and this rule expresses
    a related property.  It is an eta-expanded version of the traditional
    rule, and similar to the ABS rule of HOL.*)
  ext           "(!!x::'a. (f x ::'b) = g x) ==> (%x. f x) = (%x. g x)"

  selectI       "P (x::'a) ==> P (@x. P x)"

  impI          "(P ==> Q) ==> P-->Q"
  mp            "[| P-->Q;  P |] ==> Q"

defs

  True_def      "True      == ((%x::bool. x) = (%x. x))"
  All_def       "All(P)    == (P = (%x. True))"
  Ex_def        "Ex(P)     == P(@x. P(x))"
  False_def     "False     == (!P. P)"
  not_def       "~ P       == P-->False"
  and_def       "P & Q     == !R. (P-->Q-->R) --> R"
  or_def        "P | Q     == !R. (P-->R) --> (Q-->R) --> R"
  Ex1_def       "Ex1(P)    == ? x. P(x) & (! y. P(y) --> y=x)"

rules
  (* Axioms *)

  iff           "(P-->Q) --> (Q-->P) --> (P=Q)"
  True_or_False "(P=True) | (P=False)"

defs
  (*misc definitions*)
  Let_def       "Let s f == f(s)"
  if_def        "If P x y == @z::'a. (P=True --> z=x) & (P=False --> z=y)"

  (*arbitrary is completely unspecified, but is made to appear as a
    definition syntactically*)
  arbitrary_def "False ==> arbitrary == (@x. False)"



(** initial HOL theory setup **)

setup Simplifier.setup
setup ClasetThyData.setup


end


ML


(** Choice between the HOL and Isabelle style of quantifiers **)

val HOL_quantifiers = ref true;

fun alt_ast_tr' (name, alt_name) =
  let
    fun ast_tr' (*name*) args =
      if ! HOL_quantifiers then raise Match
      else Syntax.mk_appl (Syntax.Constant alt_name) args;
  in
    (name, ast_tr')
  end;


val print_ast_translation =
  map alt_ast_tr' [("! ", "*All"), ("? ", "*Ex"), ("?! ", "*Ex1")];

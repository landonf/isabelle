(*  Title:      HOL/Library/Pure_term.thy
    ID:         $Id$
    Author:     Florian Haftmann, TU Muenchen
*)

header {* Embedding (a subset of) the Pure term algebra in HOL *}

theory Pure_term
imports ML_String
begin

subsection {* Definitions *}

types vname = ml_string;
types "class" = ml_string;
types sort = "class list"

datatype "typ" =
    Type ml_string "typ list" (infix "{\<struct>}" 120)
  | TFix vname sort (infix "\<Colon>\<epsilon>" 117)

abbreviation
  Fun :: "typ \<Rightarrow> typ \<Rightarrow> typ" (infixr "\<rightarrow>" 115) where
  "ty1 \<rightarrow> ty2 \<equiv> Type (STR ''fun'') [ty1, ty2]"
abbreviation
  Funs :: "typ list \<Rightarrow> typ \<Rightarrow> typ" (infixr "{\<rightarrow>}" 115) where
  "tys {\<rightarrow>} ty \<equiv> foldr (op \<rightarrow>) tys ty"

datatype "term" =
    Const ml_string "typ" (infix "\<Colon>\<subseteq>" 112)
  | Fix   vname "typ" (infix ":\<epsilon>" 112)
  | App   "term" "term" (infixl "\<bullet>" 110)
  | Abs   "vname \<times> typ" "term" (infixr "\<mapsto>" 111)
  | Bnd   nat

abbreviation
  Apps :: "term \<Rightarrow> term list \<Rightarrow> term" (infixl "{\<bullet>}" 110) where
  "t {\<bullet>} ts \<equiv> foldl (op \<bullet>) t ts"
abbreviation
  Abss :: "(vname \<times> typ) list \<Rightarrow> term \<Rightarrow> term" (infixr "{\<mapsto>}" 111) where
  "vs {\<mapsto>} t \<equiv> foldr (op \<mapsto>) vs t"


subsection {* ML interface *}

ML {*
structure Pure_term =
struct

val mk_sort = HOLogic.mk_list @{typ class} o map ML_String.mk;

fun mk_typ f (Type (tyco, tys)) =
      @{term Type} $ ML_String.mk tyco
        $ HOLogic.mk_list @{typ typ} (map (mk_typ f) tys)
  | mk_typ f (TFree v) =
      f v;

fun mk_term f g (Const (c, ty)) =
      @{term Const} $ ML_String.mk c $ g ty
  | mk_term f g (t1 $ t2) =
      @{term App} $ mk_term f g t1 $ mk_term f g t2
  | mk_term f g (Free v) = f v;

end;
*}


subsection {* Code generator setup *}

lemma [code func]:
  "tyco1 {\<struct>} tys1 = tyco2 {\<struct>} tys2 \<longleftrightarrow> tyco1 = tyco2
     \<and> list_all2 (op =) tys1 tys2"
  by (auto simp add: list_all2_eq [symmetric])

code_datatype Const App Fix

lemmas [code func del] = term.recs term.cases term.size
lemma [code func, code func del]: "(t1\<Colon>term) = t2 \<longleftrightarrow> t1 = t2" ..

code_type "typ" and "term"
  (SML "Term.typ" and "Term.term")

code_const Type and TFix
  (SML "Term.Type/ (_, _)" and "Term.TFree/ (_, _)")

code_const Const and App and Fix
  (SML "Term.Const/ (_, _)" and "Term.$/ (_, _)" and "Term.Free/ (_, _)")
 
code_reserved SML Term

end

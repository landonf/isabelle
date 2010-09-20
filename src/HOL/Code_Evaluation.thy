(*  Title:      HOL/Code_Evaluation.thy
    Author:     Florian Haftmann, TU Muenchen
*)

header {* Term evaluation using the generic code generator *}

theory Code_Evaluation
imports Plain Typerep Code_Numeral
uses ("Tools/code_evaluation.ML")
begin

subsection {* Term representation *}

subsubsection {* Terms and class @{text term_of} *}

datatype "term" = dummy_term

definition Const :: "String.literal \<Rightarrow> typerep \<Rightarrow> term" where
  "Const _ _ = dummy_term"

definition App :: "term \<Rightarrow> term \<Rightarrow> term" where
  "App _ _ = dummy_term"

code_datatype Const App

class term_of = typerep +
  fixes term_of :: "'a \<Rightarrow> term"

lemma term_of_anything: "term_of x \<equiv> t"
  by (rule eq_reflection) (cases "term_of x", cases t, simp)

definition valapp :: "('a \<Rightarrow> 'b) \<times> (unit \<Rightarrow> term)
  \<Rightarrow> 'a \<times> (unit \<Rightarrow> term) \<Rightarrow> 'b \<times> (unit \<Rightarrow> term)" where
  "valapp f x = (fst f (fst x), \<lambda>u. App (snd f ()) (snd x ()))"

lemma valapp_code [code, code_unfold]:
  "valapp (f, tf) (x, tx) = (f x, \<lambda>u. App (tf ()) (tx ()))"
  by (simp only: valapp_def fst_conv snd_conv)


subsubsection {* Syntax *}

definition termify :: "'a \<Rightarrow> term" where
  [code del]: "termify x = dummy_term"

abbreviation valtermify :: "'a \<Rightarrow> 'a \<times> (unit \<Rightarrow> term)" where
  "valtermify x \<equiv> (x, \<lambda>u. termify x)"

locale term_syntax
begin

notation App (infixl "<\<cdot>>" 70)
  and valapp (infixl "{\<cdot>}" 70)

end

interpretation term_syntax .

no_notation App (infixl "<\<cdot>>" 70)
  and valapp (infixl "{\<cdot>}" 70)


subsection {* Tools setup and evaluation *}

use "Tools/code_evaluation.ML"

code_reserved Eval Code_Evaluation

setup {* Code_Evaluation.setup *}


subsection {* @{text term_of} instances *}

instantiation "fun" :: (typerep, typerep) term_of
begin

definition
  "term_of (f \<Colon> 'a \<Rightarrow> 'b) = Const (STR ''dummy_pattern'') (Typerep.Typerep (STR ''fun'')
     [Typerep.typerep TYPE('a), Typerep.typerep TYPE('b)])"

instance ..

end

instantiation String.literal :: term_of
begin

definition
  "term_of s = App (Const (STR ''STR'')
    (Typerep.Typerep (STR ''fun'') [Typerep.Typerep (STR ''list'') [Typerep.Typerep (STR ''char'') []],
      Typerep.Typerep (STR ''String.literal'') []])) (term_of (String.explode s))"

instance ..

end


subsubsection {* Code generator setup *}

lemmas [code del] = term.recs term.cases term.size
lemma [code, code del]: "HOL.equal (t1\<Colon>term) t2 \<longleftrightarrow> HOL.equal t1 t2" ..

lemma [code, code del]: "(term_of \<Colon> typerep \<Rightarrow> term) = term_of" ..
lemma [code, code del]: "(term_of \<Colon> term \<Rightarrow> term) = term_of" ..
lemma [code, code del]: "(term_of \<Colon> String.literal \<Rightarrow> term) = term_of" ..
lemma [code, code del]: "(Code_Evaluation.term_of \<Colon> 'a::{type, term_of} Predicate.pred \<Rightarrow> Code_Evaluation.term)
  = Code_Evaluation.term_of" ..
lemma [code, code del]: "(Code_Evaluation.term_of \<Colon> 'a::{type, term_of} Predicate.seq \<Rightarrow> Code_Evaluation.term)
  = Code_Evaluation.term_of" ..

lemma term_of_char [unfolded typerep_fun_def typerep_char_def typerep_nibble_def, code]:
  "Code_Evaluation.term_of c =
    (let (n, m) = nibble_pair_of_char c
  in Code_Evaluation.App (Code_Evaluation.App
    (Code_Evaluation.Const (STR ''String.char.Char'') (TYPEREP(nibble \<Rightarrow> nibble \<Rightarrow> char)))
      (Code_Evaluation.term_of n)) (Code_Evaluation.term_of m))"
  by (subst term_of_anything) rule 

code_type "term"
  (Eval "Term.term")

code_const Const and App
  (Eval "Term.Const/ ((_), (_))" and "Term.$/ ((_), (_))")

code_const "term_of \<Colon> String.literal \<Rightarrow> term"
  (Eval "HOLogic.mk'_literal")

code_reserved Eval HOLogic


subsubsection {* Numeric types *}

definition term_of_num :: "'a\<Colon>{semiring_div} \<Rightarrow> 'a\<Colon>{semiring_div} \<Rightarrow> term" where
  "term_of_num two = (\<lambda>_. dummy_term)"

lemma (in term_syntax) term_of_num_code [code]:
  "term_of_num two k = (if k = 0 then termify Int.Pls
    else (if k mod two = 0
      then termify Int.Bit0 <\<cdot>> term_of_num two (k div two)
      else termify Int.Bit1 <\<cdot>> term_of_num two (k div two)))"
  by (auto simp add: term_of_anything Const_def App_def term_of_num_def Let_def)

lemma (in term_syntax) term_of_nat_code [code]:
  "term_of (n::nat) = termify (number_of :: int \<Rightarrow> nat) <\<cdot>> term_of_num (2::nat) n"
  by (simp only: term_of_anything)

lemma (in term_syntax) term_of_int_code [code]:
  "term_of (k::int) = (if k = 0 then termify (0 :: int)
    else if k > 0 then termify (number_of :: int \<Rightarrow> int) <\<cdot>> term_of_num (2::int) k
      else termify (uminus :: int \<Rightarrow> int) <\<cdot>> (termify (number_of :: int \<Rightarrow> int) <\<cdot>> term_of_num (2::int) (- k)))"
  by (simp only: term_of_anything)

lemma (in term_syntax) term_of_code_numeral_code [code]:
  "term_of (k::code_numeral) = termify (number_of :: int \<Rightarrow> code_numeral) <\<cdot>> term_of_num (2::code_numeral) k"
  by (simp only: term_of_anything)


subsubsection {* Obfuscation *}

print_translation {*
let
  val term = Const ("<TERM>", dummyT);
  fun tr1' [_, _] = term;
  fun tr2' [] = term;
in
  [(@{const_syntax Const}, tr1'),
    (@{const_syntax App}, tr1'),
    (@{const_syntax dummy_term}, tr2')]
end
*}


subsection {* Diagnostic *}

definition tracing :: "String.literal \<Rightarrow> 'a \<Rightarrow> 'a" where
  [code del]: "tracing s x = x"

code_const "tracing :: String.literal => 'a => 'a"
  (Eval "Code'_Evaluation.tracing")


hide_const dummy_term App valapp
hide_const (open) Const termify valtermify term_of term_of_num tracing

end

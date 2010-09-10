(*  Title:      HOL/Library/Code_Integer.thy
    Author:     Florian Haftmann, TU Muenchen
*)

header {* Pretty integer literals for code generation *}

theory Code_Integer
imports Main Code_Natural
begin

text {*
  HOL numeral expressions are mapped to integer literals
  in target languages, using predefined target language
  operations for abstract integer operations.
*}

code_type int
  (SML "IntInf.int")
  (OCaml "Big'_int.big'_int")
  (Haskell "Integer")
  (Scala "BigInt")
  (Eval "int")

code_instance int :: equal
  (Haskell -)

setup {*
  fold (Numeral.add_code @{const_name number_int_inst.number_of_int}
    true Code_Printer.literal_numeral) ["SML", "OCaml", "Haskell", "Scala"]
*}

code_const "Int.Pls" and "Int.Min" and "Int.Bit0" and "Int.Bit1"
  (SML "raise/ Fail/ \"Pls\""
     and "raise/ Fail/ \"Min\""
     and "!((_);/ raise/ Fail/ \"Bit0\")"
     and "!((_);/ raise/ Fail/ \"Bit1\")")
  (OCaml "failwith/ \"Pls\""
     and "failwith/ \"Min\""
     and "!((_);/ failwith/ \"Bit0\")"
     and "!((_);/ failwith/ \"Bit1\")")
  (Haskell "error/ \"Pls\""
     and "error/ \"Min\""
     and "error/ \"Bit0\""
     and "error/ \"Bit1\"")
  (Scala "!error(\"Pls\")"
     and "!error(\"Min\")"
     and "!error(\"Bit0\")"
     and "!error(\"Bit1\")")

code_const Int.pred
  (SML "IntInf.- ((_), 1)")
  (OCaml "Big'_int.pred'_big'_int")
  (Haskell "!(_/ -/ 1)")
  (Scala "!(_ -/ 1)")
  (Eval "!(_/ -/ 1)")

code_const Int.succ
  (SML "IntInf.+ ((_), 1)")
  (OCaml "Big'_int.succ'_big'_int")
  (Haskell "!(_/ +/ 1)")
  (Scala "!(_ +/ 1)")
  (Eval "!(_/ +/ 1)")

code_const "op + \<Colon> int \<Rightarrow> int \<Rightarrow> int"
  (SML "IntInf.+ ((_), (_))")
  (OCaml "Big'_int.add'_big'_int")
  (Haskell infixl 6 "+")
  (Scala infixl 7 "+")
  (Eval infixl 8 "+")

code_const "uminus \<Colon> int \<Rightarrow> int"
  (SML "IntInf.~")
  (OCaml "Big'_int.minus'_big'_int")
  (Haskell "negate")
  (Scala "!(- _)")
  (Eval "~/ _")

code_const "op - \<Colon> int \<Rightarrow> int \<Rightarrow> int"
  (SML "IntInf.- ((_), (_))")
  (OCaml "Big'_int.sub'_big'_int")
  (Haskell infixl 6 "-")
  (Scala infixl 7 "-")
  (Eval infixl 8 "-")

code_const "op * \<Colon> int \<Rightarrow> int \<Rightarrow> int"
  (SML "IntInf.* ((_), (_))")
  (OCaml "Big'_int.mult'_big'_int")
  (Haskell infixl 7 "*")
  (Scala infixl 8 "*")
  (Eval infixl 9 "*")

code_const pdivmod
  (SML "IntInf.divMod/ (IntInf.abs _,/ IntInf.abs _)")
  (OCaml "Big'_int.quomod'_big'_int/ (Big'_int.abs'_big'_int _)/ (Big'_int.abs'_big'_int _)")
  (Haskell "divMod/ (abs _)/ (abs _)")
  (Scala "!((k: BigInt) => (l: BigInt) =>/ if (l == 0)/ (BigInt(0), k) else/ (k.abs '/% l.abs))")
  (Eval "Integer.div'_mod/ (abs _)/ (abs _)")

code_const "HOL.equal \<Colon> int \<Rightarrow> int \<Rightarrow> bool"
  (SML "!((_ : IntInf.int) = _)")
  (OCaml "Big'_int.eq'_big'_int")
  (Haskell infix 4 "==")
  (Scala infixl 5 "==")
  (Eval infixl 6 "=")

code_const "op \<le> \<Colon> int \<Rightarrow> int \<Rightarrow> bool"
  (SML "IntInf.<= ((_), (_))")
  (OCaml "Big'_int.le'_big'_int")
  (Haskell infix 4 "<=")
  (Scala infixl 4 "<=")
  (Eval infixl 6 "<=")

code_const "op < \<Colon> int \<Rightarrow> int \<Rightarrow> bool"
  (SML "IntInf.< ((_), (_))")
  (OCaml "Big'_int.lt'_big'_int")
  (Haskell infix 4 "<")
  (Scala infixl 4 "<")
  (Eval infixl 6 "<")

code_const Code_Numeral.int_of
  (SML "IntInf.fromInt")
  (OCaml "_")
  (Haskell "toInteger")
  (Scala "!_.as'_BigInt")
  (Eval "_")

text {* Evaluation *}

code_const "Code_Evaluation.term_of \<Colon> int \<Rightarrow> term"
  (Eval "HOLogic.mk'_number/ HOLogic.intT")

end
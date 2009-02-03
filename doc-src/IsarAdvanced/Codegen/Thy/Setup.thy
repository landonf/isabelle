theory Setup
imports Complex_Main
uses "../../../antiquote_setup.ML" "../../../more_antiquote.ML"
begin

ML {* no_document use_thys
  ["Efficient_Nat", "Code_Char_chr", "Product_ord", "~~/src/HOL/Imperative_HOL/Imperative_HOL",
   "~~/src/HOL/Reflection/Ferrack"] *}

ML_val {* Code_Target.code_width := 74 *}

end

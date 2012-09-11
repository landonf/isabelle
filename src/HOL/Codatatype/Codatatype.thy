(*  Title:      HOL/Codatatype/Codatatype.thy
    Author:     Dmitriy Traytel, TU Muenchen
    Author:     Andrei Popescu, TU Muenchen
    Author:     Jasmin Blanchette, TU Muenchen
    Copyright   2012

The (co)datatype package.
*)

header {* The (Co)datatype Package *}

theory Codatatype
imports BNF_LFP BNF_GFP BNF_Wrap
keywords
  "data" :: thy_decl and
  "codata" :: thy_decl and
  "defaults"
uses
  "Tools/bnf_fp_sugar_tactics.ML"
  "Tools/bnf_fp_sugar.ML"
begin

end

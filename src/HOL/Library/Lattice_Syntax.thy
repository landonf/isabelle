(* Author: Florian Haftmann, TU Muenchen *)

header {* Pretty syntax for lattice operations *}

(*<*)
theory Lattice_Syntax
imports Complete_Lattice
begin

notation
  top ("\<top>") and
  bot ("\<bottom>") and
  inf  (infixl "\<sqinter>" 70) and
  sup  (infixl "\<squnion>" 65) and
  Inf  ("\<Sqinter>_" [900] 900) and
  Sup  ("\<Squnion>_" [900] 900)

end
(*>*)
(*  Title:      HOLCF/IOA/meta_theory/TLS.thy
    ID:         $Id$
    Author:     Olaf M"uller
    Copyright   1997  TU Muenchen

Logical Connectives lifted to predicates.

ToDo:

<--> einfuehren.

*)   
	       
Pred = Arith +  

default term

types

'a predicate      = "'a => bool"

consts

satisfies    ::"'a  => 'a predicate => bool"    ("_ |= _" [100,9] 8)
valid        ::"'a predicate => bool"           (*  ("|-") *)         

NOT          ::"'a predicate => 'a predicate"  (".~ _" [40] 40)
AND          ::"'a predicate => 'a predicate => 'a predicate"    (infixr ".&" 35)
OR           ::"'a predicate => 'a predicate => 'a predicate"    (infixr ".|" 30)
IMPLIES      ::"'a predicate => 'a predicate => 'a predicate"    (infixr ".-->" 25)


syntax ("" output)
  "NOT"     ::"'a predicate => 'a predicate" ("~ _" [40] 40)
  "AND"     ::"'a predicate => 'a predicate => 'a predicate"    (infixr "&" 35)
  "OR"      ::"'a predicate => 'a predicate => 'a predicate"    (infixr "|" 30)
  "IMPLIES" ::"'a predicate => 'a predicate => 'a predicate"    (infixr "-->" 25)

syntax (symbols output)
  "NOT"    ::"'a predicate => 'a predicate" ("\\<not> _" [40] 40)
  "AND"    ::"'a predicate => 'a predicate => 'a predicate"    (infixr "\\<and>" 35)
  "OR"     ::"'a predicate => 'a predicate => 'a predicate"    (infixr "\\<or>" 30)
  "IMPLIES" ::"'a predicate => 'a predicate => 'a predicate"    (infixr "\\<midarrow>\\<rightarrow>" 25)

syntax (symbols)
  "satisfies"  ::"'a => 'a predicate => bool"    ("_ \\<Turnstile> _" [100,9] 8)


defs

satisfies_def
   "s |= P  == P s" 

(* priority einfuegen, da clash mit |=, wenn graphisches Symbol *)
valid_def
   "valid P == (! s. (s |= P))"


NOT_def
  "NOT P s ==  ~ (P s)"

AND_def
  "(P .& Q) s == (P s) & (Q s)"


OR_def
  "(P .| Q) s ==  (P s) | (Q s)"

IMPLIES_def
  "(P .--> Q) s == (P s) --> (Q s)"

end
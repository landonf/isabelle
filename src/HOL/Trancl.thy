(*  Title:      HOL/Trancl.thy
    ID:         $Id$
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1992  University of Cambridge

Relfexive and Transitive closure of a relation

rtrancl is reflexive/transitive closure;
trancl  is transitive closure
reflcl  is reflexive closure

These postfix operators have MAXIMUM PRIORITY, forcing their operands to be
      atomic.
*)

Trancl = Lfp + Relation + 

constdefs
  rtrancl :: "('a * 'a)set => ('a * 'a)set"   ("(_^*)" [1000] 1000)
  "r^*  ==  lfp(%s. id Un (r O s))"

  trancl  :: "('a * 'a)set => ('a * 'a)set"   ("(_^+)" [1000] 1000)
  "r^+  ==  r O rtrancl(r)"

syntax
  reflcl  :: "('a*'a)set => ('a*'a)set"       ("(_^=)" [1000] 1000)

translations
  "r^=" == "r Un id"

end

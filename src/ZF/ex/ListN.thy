(*  Title:      ZF/ex/ListN
    ID:         $Id$
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1994  University of Cambridge

Inductive definition of lists of n elements

See Ch. Paulin-Mohring, Inductive Definitions in the System Coq.
Research Report 92-49, LIP, ENS Lyon.  Dec 1992.
*)

ListN = Main +

consts  listn ::i=>i
inductive
  domains   "listn(A)" <= "nat*list(A)"
  intrs
    NilI  "<0,Nil> \\<in> listn(A)"
    ConsI "[| a \\<in> A; <n,l> \\<in> listn(A) |] ==> <succ(n), Cons(a,l)> \\<in> listn(A)"
  type_intrs "nat_typechecks @ list.intrs"

end

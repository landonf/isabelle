(*  Title:      HOL/UNITY/Handshake.thy
    ID:         $Id$
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1998  University of Cambridge

Handshake Protocol

From Misra, "Asynchronous Compositions of Programs", Section 5.3.2
*)

Handshake = Union +

record state =
  BB :: bool
  NF :: nat
  NG :: nat

constdefs
  (*F's program*)
  cmdF :: "(state*state) set"
    "cmdF == {(s,s'). s' = s (|NF:= Suc(NF s), BB:=False|) & BB s}"

  prgF :: "state program"
    "prgF == (|Init = {s. NF s = 0 & BB s},
	       Acts0 = {cmdF}|)"

  (*G's program*)
  cmdG :: "(state*state) set"
    "cmdG == {(s,s'). s' = s (|NG:= Suc(NG s), BB:=True|) & ~ BB s}"

  prgG :: "state program"
    "prgG == (|Init = {s. NG s = 0 & BB s},
	       Acts0 = {cmdG}|)"

  (*the joint invariant*)
  invFG :: "state set"
    "invFG == {s. NG s <= NF s & NF s <= Suc (NG s) & (BB s = (NF s = NG s))}"

end

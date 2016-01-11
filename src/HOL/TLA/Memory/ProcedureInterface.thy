(*  Title:      HOL/TLA/Memory/ProcedureInterface.thy
    Author:     Stephan Merz, University of Munich
*)

section \<open>Procedure interface for RPC-Memory components\<close>

theory ProcedureInterface
imports "../TLA" RPCMemoryParams
begin

typedecl ('a,'r) chan
  (* type of channels with argument type 'a and return type 'r.
     we model a channel as an array of variables (of type chan)
     rather than a single array-valued variable because the
     notation gets a little simpler.
  *)
type_synonym ('a,'r) channel =" (PrIds \<Rightarrow> ('a,'r) chan) stfun"


(* data-level functions *)

consts
  cbit          :: "('a,'r) chan \<Rightarrow> bit"
  rbit          :: "('a,'r) chan \<Rightarrow> bit"
  arg           :: "('a,'r) chan \<Rightarrow> 'a"
  res           :: "('a,'r) chan \<Rightarrow> 'r"


(* state functions *)

definition caller :: "('a,'r) channel \<Rightarrow> (PrIds \<Rightarrow> (bit * 'a)) stfun"
  where "caller ch == \<lambda>s p. (cbit (ch s p), arg (ch s p))"

definition rtrner :: "('a,'r) channel \<Rightarrow> (PrIds \<Rightarrow> (bit * 'r)) stfun"
  where "rtrner ch == \<lambda>s p. (rbit (ch s p), res (ch s p))"


(* slice through array-valued state function *)

consts
  slice        :: "('a \<Rightarrow> 'b) stfun \<Rightarrow> 'a \<Rightarrow> 'b stfun"
syntax
  "_slice"    :: "[lift, 'a] \<Rightarrow> lift"      ("(_!_)" [70,70] 70)
translations
  "_slice"  ==  "CONST slice"
defs
  slice_def:     "(PRED (x!i)) s == x s i"


(* state predicates *)

definition Calling :: "('a,'r) channel \<Rightarrow> PrIds \<Rightarrow> stpred"
  where "Calling ch p == PRED cbit< ch!p > \<noteq> rbit< ch!p >"


(* actions *)

consts
  ACall      :: "('a,'r) channel \<Rightarrow> PrIds \<Rightarrow> 'a stfun \<Rightarrow> action"
  AReturn    :: "('a,'r) channel \<Rightarrow> PrIds \<Rightarrow> 'r stfun \<Rightarrow> action"
syntax
  "_Call"     :: "['a, 'b, lift] \<Rightarrow> lift"    ("(Call _ _ _)" [90,90,90] 90)
  "_Return"   :: "['a, 'b, lift] \<Rightarrow> lift"    ("(Return _ _ _)" [90,90,90] 90)
translations
  "_Call"   ==  "CONST ACall"
  "_Return" ==  "CONST AReturn"
defs
  Call_def:      "(ACT Call ch p v)   == ACT  \<not> $Calling ch p
                                     \<and> (cbit<ch!p>$ \<noteq> $rbit<ch!p>)
                                     \<and> (arg<ch!p>$ = $v)"
  Return_def:    "(ACT Return ch p v) == ACT  $Calling ch p
                                     \<and> (rbit<ch!p>$ = $cbit<ch!p>)
                                     \<and> (res<ch!p>$ = $v)"


(* temporal formulas *)

definition PLegalCaller :: "('a,'r) channel \<Rightarrow> PrIds \<Rightarrow> temporal"
  where "PLegalCaller ch p == TEMP
     Init(\<not> Calling ch p)
     \<and> \<box>[\<exists>a. Call ch p a ]_((caller ch)!p)"

definition LegalCaller :: "('a,'r) channel \<Rightarrow> temporal"
  where "LegalCaller ch == TEMP (\<forall>p. PLegalCaller ch p)"

definition PLegalReturner :: "('a,'r) channel \<Rightarrow> PrIds \<Rightarrow> temporal"
  where "PLegalReturner ch p == TEMP \<box>[\<exists>v. Return ch p v ]_((rtrner ch)!p)"

definition LegalReturner :: "('a,'r) channel \<Rightarrow> temporal"
  where "LegalReturner ch == TEMP (\<forall>p. PLegalReturner ch p)"

declare slice_def [simp]

lemmas Procedure_defs = caller_def rtrner_def Calling_def Call_def Return_def
  PLegalCaller_def LegalCaller_def PLegalReturner_def LegalReturner_def

(* Calls and returns change their subchannel *)
lemma Call_changed: "\<turnstile> Call ch p v \<longrightarrow> <Call ch p v>_((caller ch)!p)"
  by (auto simp: angle_def Call_def caller_def Calling_def)

lemma Return_changed: "\<turnstile> Return ch p v \<longrightarrow> <Return ch p v>_((rtrner ch)!p)"
  by (auto simp: angle_def Return_def rtrner_def Calling_def)

end

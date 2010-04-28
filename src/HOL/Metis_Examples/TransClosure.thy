(*  Title:      HOL/MetisTest/TransClosure.thy
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory

Testing the metis method
*)

theory TransClosure
imports Main
begin

types addr = nat

datatype val
  = Unit        -- "dummy result value of void expressions"
  | Null        -- "null reference"
  | Bool bool   -- "Boolean value"
  | Intg int    -- "integer value" 
  | Addr addr   -- "addresses of objects in the heap"

consts R :: "(addr \<times> addr) set"

consts f :: "addr \<Rightarrow> val"

lemma "\<lbrakk>f c = Intg x; \<forall>y. f b = Intg y \<longrightarrow> y \<noteq> x; (a, b) \<in> R\<^sup>*; (b, c) \<in> R\<^sup>*\<rbrakk>
       \<Longrightarrow> \<exists>c. (b, c) \<in> R \<and> (a, c) \<in> R\<^sup>*"
(* sledgehammer *)
proof -
  assume A1: "f c = Intg x"
  assume A2: "\<forall>y. f b = Intg y \<longrightarrow> y \<noteq> x"
  assume A3: "(a, b) \<in> R\<^sup>*"
  assume A4: "(b, c) \<in> R\<^sup>*"
  have F1: "f c \<noteq> f b" using A2 A1 by metis
  have F2: "\<forall>u. (b, u) \<in> R \<longrightarrow> (a, u) \<in> R\<^sup>*" using A3 by (metis transitive_closure_trans(6))
  have F3: "\<exists>x. (b, x R b c) \<in> R \<or> c = b" using A4 by (metis converse_rtranclE)
  have "c \<noteq> b" using F1 by metis
  hence "\<exists>u. (b, u) \<in> R" using F3 by metis
  thus "\<exists>c. (b, c) \<in> R \<and> (a, c) \<in> R\<^sup>*" using F2 by metis
qed

lemma "\<lbrakk>f c = Intg x; \<forall>y. f b = Intg y \<longrightarrow> y \<noteq> x; (a, b) \<in> R\<^sup>*; (b,c) \<in> R\<^sup>*\<rbrakk>
       \<Longrightarrow> \<exists>c. (b, c) \<in> R \<and> (a, c) \<in> R\<^sup>*"
(* sledgehammer [isar_proof, shrink_factor = 2] *)
proof -
  assume A1: "f c = Intg x"
  assume A2: "\<forall>y. f b = Intg y \<longrightarrow> y \<noteq> x"
  assume A3: "(a, b) \<in> R\<^sup>*"
  assume A4: "(b, c) \<in> R\<^sup>*"
  have "(R\<^sup>*) (a, b)" using A3 by (metis mem_def)
  hence F1: "(a, b) \<in> R\<^sup>*" by (metis mem_def)
  have "b \<noteq> c" using A1 A2 by metis
  hence "\<exists>x\<^isub>1. (b, x\<^isub>1) \<in> R" using A4 by (metis converse_rtranclE)
  thus "\<exists>c. (b, c) \<in> R \<and> (a, c) \<in> R\<^sup>*" using F1 by (metis transitive_closure_trans(6))
qed

lemma "\<lbrakk>f c = Intg x; \<forall>y. f b = Intg y \<longrightarrow> y \<noteq> x; (a, b) \<in> R\<^sup>*; (b, c) \<in> R\<^sup>*\<rbrakk> 
       \<Longrightarrow> \<exists>c. (b, c) \<in> R \<and> (a, c) \<in> R\<^sup>*"
apply (erule_tac x = b in converse_rtranclE)
 apply metis
by (metis transitive_closure_trans(6))

end

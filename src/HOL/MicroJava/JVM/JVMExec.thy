(*  Title:      HOL/MicroJava/JVM/JVMExec.thy
    ID:         $Id$
    Author:     Cornelia Pusch
    Copyright   1999 Technische Universitaet Muenchen

Execution of the JVM
*)

JVMExec = JVMExecInstr + 

consts
 exec :: "jvm_prog \\<times> jvm_state \\<Rightarrow> jvm_state option"

(** exec is not recursive. recdef is just used for pattern matching **)
recdef exec "{}"
 "exec (G, xp, hp, []) = None"

 "exec (G, None, hp, (stk,loc,C,sig,pc)#frs) =
  (let 
     i = snd(snd(snd(the(method (G,C) sig)))) ! pc
   in
     Some (exec_instr i G hp stk loc C sig pc frs))"

 "exec (G, Some xp, hp, frs) = None" 


constdefs
 exec_all :: "[jvm_prog,jvm_state,jvm_state] \\<Rightarrow> bool"  ("_ \\<turnstile> _ -jvm\\<rightarrow> _" [61,61,61]60)
 "G \\<turnstile> s -jvm\\<rightarrow> t \\<equiv> (s,t) \\<in> {(s,t). exec(G,s) = Some t}^*"

end

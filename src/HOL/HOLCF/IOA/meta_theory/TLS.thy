(*  Title:      HOL/HOLCF/IOA/meta_theory/TLS.thy
    Author:     Olaf Müller
*)

section \<open>Temporal Logic of Steps -- tailored for I/O automata\<close>

theory TLS
imports IOA TL
begin

default_sort type

type_synonym
  ('a, 's) ioa_temp  = "('a option,'s)transition temporal"

type_synonym
  ('a, 's) step_pred = "('a option,'s)transition predicate"

type_synonym
  's state_pred      = "'s predicate"

consts

option_lift :: "('a => 'b) => 'b => ('a option => 'b)"
plift       :: "('a => bool) => ('a option => bool)"

temp_sat   :: "('a,'s)execution => ('a,'s)ioa_temp => bool"    (infixr "\<TTurnstile>" 22)
xt1        :: "'s predicate => ('a,'s)step_pred"
xt2        :: "'a option predicate => ('a,'s)step_pred"

validTE    :: "('a,'s)ioa_temp => bool"
validIOA   :: "('a,'s)ioa => ('a,'s)ioa_temp => bool"

mkfin      :: "'a Seq => 'a Seq"

ex2seq     :: "('a,'s)execution => ('a option,'s)transition Seq"
ex2seqC    :: "('a,'s)pairs -> ('s => ('a option,'s)transition Seq)"


defs

mkfin_def:
  "mkfin s == if Partial s then @t. Finite t & s = t @@ UU
                           else s"

option_lift_def:
  "option_lift f s y == case y of None => s | Some x => (f x)"

(* plift is used to determine that None action is always false in
   transition predicates *)
plift_def:
  "plift P == option_lift P False"

temp_sat_def:
  "ex \<TTurnstile> P == ((ex2seq ex) \<Turnstile> P)"

xt1_def:
  "xt1 P tr == P (fst tr)"

xt2_def:
  "xt2 P tr == P (fst (snd tr))"

ex2seq_def:
  "ex2seq ex == ((ex2seqC $(mkfin (snd ex))) (fst ex))"

ex2seqC_def:
  "ex2seqC == (fix$(LAM h ex. (%s. case ex of
      nil =>  (s,None,s)\<leadsto>nil
    | x##xs => (flift1 (%pr.
                (s,Some (fst pr), snd pr)\<leadsto> (h$xs) (snd pr))
                $x)
      )))"

validTE_def:
  "validTE P == ! ex. (ex \<TTurnstile> P)"

validIOA_def:
  "validIOA A P == ! ex : executions A . (ex \<TTurnstile> P)"


axiomatization where

mkfin_UU:
  "mkfin UU = nil" and

mkfin_nil:
  "mkfin nil =nil" and

mkfin_cons:
  "(mkfin (a\<leadsto>s)) = (a\<leadsto>(mkfin s))"


lemmas [simp del] = HOL.ex_simps HOL.all_simps split_paired_Ex

setup \<open>map_theory_claset (fn ctxt => ctxt delSWrapper "split_all_tac")\<close>


subsection \<open>ex2seqC\<close>

lemma ex2seqC_unfold: "ex2seqC  = (LAM ex. (%s. case ex of  
       nil =>  (s,None,s)\<leadsto>nil    
     | x##xs => (flift1 (%pr.  
                 (s,Some (fst pr), snd pr)\<leadsto> (ex2seqC$xs) (snd pr))   
                 $x)   
       ))"
apply (rule trans)
apply (rule fix_eq2)
apply (rule ex2seqC_def)
apply (rule beta_cfun)
apply (simp add: flift1_def)
done

lemma ex2seqC_UU: "(ex2seqC $UU) s=UU"
apply (subst ex2seqC_unfold)
apply simp
done

lemma ex2seqC_nil: "(ex2seqC $nil) s = (s,None,s)\<leadsto>nil"
apply (subst ex2seqC_unfold)
apply simp
done

lemma ex2seqC_cons: "(ex2seqC $((a,t)\<leadsto>xs)) s =  
           (s,Some a,t)\<leadsto> ((ex2seqC$xs) t)"
apply (rule trans)
apply (subst ex2seqC_unfold)
apply (simp add: Consq_def flift1_def)
apply (simp add: Consq_def flift1_def)
done

declare ex2seqC_UU [simp] ex2seqC_nil [simp] ex2seqC_cons [simp]



declare mkfin_UU [simp] mkfin_nil [simp] mkfin_cons [simp]

lemma ex2seq_UU: "ex2seq (s, UU) = (s,None,s)\<leadsto>nil"
apply (simp add: ex2seq_def)
done

lemma ex2seq_nil: "ex2seq (s, nil) = (s,None,s)\<leadsto>nil"
apply (simp add: ex2seq_def)
done

lemma ex2seq_cons: "ex2seq (s, (a,t)\<leadsto>ex) = (s,Some a,t) \<leadsto> ex2seq (t, ex)"
apply (simp add: ex2seq_def)
done

declare ex2seqC_UU [simp del] ex2seqC_nil [simp del] ex2seqC_cons [simp del]
declare ex2seq_UU [simp] ex2seq_nil [simp] ex2seq_cons [simp]


lemma ex2seq_nUUnnil: "ex2seq exec ~= UU & ex2seq exec ~= nil"
apply (tactic \<open>pair_tac @{context} "exec" 1\<close>)
apply (tactic \<open>Seq_case_simp_tac @{context} "x2" 1\<close>)
apply (tactic \<open>pair_tac @{context} "a" 1\<close>)
done


subsection \<open>Interface TL -- TLS\<close>

(* uses the fact that in executions states overlap, which is lost in 
   after the translation via ex2seq !! *)

lemma TL_TLS: 
 "[| ! s a t. (P s) & s \<midarrow>a\<midarrow>A\<rightarrow> t --> (Q t) |] 
   ==> ex \<TTurnstile> (Init (%(s,a,t). P s) \<^bold>\<and> Init (%(s,a,t). s \<midarrow>a\<midarrow>A\<rightarrow> t)  
              \<^bold>\<longrightarrow> (Next (Init (%(s,a,t).Q s))))"
apply (unfold Init_def Next_def temp_sat_def satisfies_def IMPLIES_def AND_def)

apply clarify
apply (simp split add: split_if)
(* TL = UU *)
apply (rule conjI)
apply (tactic \<open>pair_tac @{context} "ex" 1\<close>)
apply (tactic \<open>Seq_case_simp_tac @{context} "x2" 1\<close>)
apply (tactic \<open>pair_tac @{context} "a" 1\<close>)
apply (tactic \<open>Seq_case_simp_tac @{context} "s" 1\<close>)
apply (tactic \<open>pair_tac @{context} "a" 1\<close>)
(* TL = nil *)
apply (rule conjI)
apply (tactic \<open>pair_tac @{context} "ex" 1\<close>)
apply (tactic \<open>Seq_case_tac @{context} "x2" 1\<close>)
apply (simp add: unlift_def)
apply fast
apply (simp add: unlift_def)
apply fast
apply (simp add: unlift_def)
apply (tactic \<open>pair_tac @{context} "a" 1\<close>)
apply (tactic \<open>Seq_case_simp_tac @{context} "s" 1\<close>)
apply (tactic \<open>pair_tac @{context} "a" 1\<close>)
(* TL =cons *)
apply (simp add: unlift_def)

apply (tactic \<open>pair_tac @{context} "ex" 1\<close>)
apply (tactic \<open>Seq_case_simp_tac @{context} "x2" 1\<close>)
apply (tactic \<open>pair_tac @{context} "a" 1\<close>)
apply (tactic \<open>Seq_case_simp_tac @{context} "s" 1\<close>)
apply (tactic \<open>pair_tac @{context} "a" 1\<close>)
done

end

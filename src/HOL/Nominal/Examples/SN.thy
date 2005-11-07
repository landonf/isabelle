
theory sn
imports lam_substs  Accessible_Part
begin

(* Strong normalisation according to the P&T book by Girard et al *)

section {* Beta Reduction *}

lemma subst_rename[rule_format]: 
  fixes  c  :: "name"
  and    a  :: "name"
  and    t1 :: "lam"
  and    t2 :: "lam"
  shows "c\<sharp>t1 \<longrightarrow> (t1[a::=t2] = ([(c,a)]\<bullet>t1)[c::=t2])"
apply(nominal_induct t1 rule: lam_induct)
apply(auto simp add: calc_atm fresh_atm fresh_prod abs_fresh)
done

lemma forget[rule_format]: 
  shows "a\<sharp>t1 \<longrightarrow> t1[a::=t2] = t1"
apply (nominal_induct t1 rule: lam_induct)
apply(auto simp add: abs_fresh fresh_atm fresh_prod)
done

lemma fresh_fact[rule_format]: 
  fixes   b :: "name"
  and    a  :: "name"
  and    t1 :: "lam"
  and    t2 :: "lam" 
  shows "a\<sharp>t1\<longrightarrow>a\<sharp>t2\<longrightarrow>a\<sharp>(t1[b::=t2])"
apply(nominal_induct t1 rule: lam_induct)
apply(auto simp add: abs_fresh fresh_prod fresh_atm)
done

lemma subs_lemma:  
  fixes x::"name"
  and   y::"name"
  and   L::"lam"
  and   M::"lam"
  and   N::"lam"
  shows "x\<noteq>y\<longrightarrow>x\<sharp>L\<longrightarrow>M[x::=N][y::=L] = M[y::=L][x::=N[y::=L]]"
apply(nominal_induct M rule: lam_induct)
apply(auto simp add: fresh_fact forget fresh_prod fresh_atm)
done

lemma id_subs: "t[x::=Var x] = t"
apply(nominal_induct t rule: lam_induct)
apply(simp_all add: fresh_atm)
done

consts
  Beta :: "(lam\<times>lam) set"
syntax 
  "_Beta"       :: "lam\<Rightarrow>lam\<Rightarrow>bool" (" _ \<longrightarrow>\<^isub>\<beta> _" [80,80] 80)
  "_Beta_star"  :: "lam\<Rightarrow>lam\<Rightarrow>bool" (" _ \<longrightarrow>\<^isub>\<beta>\<^sup>* _" [80,80] 80)
translations 
  "t1 \<longrightarrow>\<^isub>\<beta> t2" \<rightleftharpoons> "(t1,t2) \<in> Beta"
  "t1 \<longrightarrow>\<^isub>\<beta>\<^sup>* t2" \<rightleftharpoons> "(t1,t2) \<in> Beta\<^sup>*"
inductive Beta
  intros
  b1[intro!]: "s1\<longrightarrow>\<^isub>\<beta>s2 \<Longrightarrow> (App s1 t)\<longrightarrow>\<^isub>\<beta>(App s2 t)"
  b2[intro!]: "s1\<longrightarrow>\<^isub>\<beta>s2 \<Longrightarrow> (App t s1)\<longrightarrow>\<^isub>\<beta>(App t s2)"
  b3[intro!]: "s1\<longrightarrow>\<^isub>\<beta>s2 \<Longrightarrow> (Lam [a].s1)\<longrightarrow>\<^isub>\<beta> (Lam [(a::name)].s2)"
  b4[intro!]: "(App (Lam [(a::name)].s1) s2)\<longrightarrow>\<^isub>\<beta>(s1[a::=s2])"

lemma eqvt_beta: 
  fixes pi :: "name prm"
  and   t  :: "lam"
  and   s  :: "lam"
  shows "t\<longrightarrow>\<^isub>\<beta>s \<Longrightarrow> (pi\<bullet>t)\<longrightarrow>\<^isub>\<beta>(pi\<bullet>s)"
  apply(erule Beta.induct)
  apply(auto)
  done

lemma beta_induct_aux[rule_format]:
  fixes  P :: "lam \<Rightarrow> lam \<Rightarrow>'a::fs_name\<Rightarrow>bool"
  and    t :: "lam"
  and    s :: "lam"
  assumes a: "t\<longrightarrow>\<^isub>\<beta>s"
  and a1:    "\<And>x t s1 s2. 
              s1\<longrightarrow>\<^isub>\<beta>s2 \<Longrightarrow> (\<forall>z. P s1 s2 z) \<Longrightarrow> P (App s1 t) (App s2 t) x"
  and a2:    "\<And>x t s1 s2. 
              s1\<longrightarrow>\<^isub>\<beta>s2 \<Longrightarrow> (\<forall>z. P s1 s2 z) \<Longrightarrow> P (App t s1) (App t s2) x"
  and a3:    "\<And>x (a::name) s1 s2. 
              a\<sharp>x \<Longrightarrow> s1\<longrightarrow>\<^isub>\<beta>s2 \<Longrightarrow> (\<forall>z. P s1 s2 z) \<Longrightarrow> P (Lam [a].s1) (Lam [a].s2) x"
  and a4:    "\<And>x (a::name) t1 s1. a\<sharp>(s1,x) \<Longrightarrow> P (App (Lam [a].t1) s1) (t1[a::=s1]) x"
  shows "\<forall>x (pi::name prm). P (pi\<bullet>t) (pi\<bullet>s) x"
using a
proof (induct)
  case b1 thus ?case using a1 by (simp, blast intro: eqvt_beta)
next
  case b2 thus ?case using a2 by (simp, blast intro: eqvt_beta)
next
  case (b3 a s1 s2)
  assume j1: "s1 \<longrightarrow>\<^isub>\<beta> s2"
  assume j2: "\<forall>x (pi::name prm). P (pi\<bullet>s1) (pi\<bullet>s2) x"
  show ?case 
  proof (simp, intro strip)
    fix pi::"name prm" and x::"'a::fs_name"
     have f: "\<exists>c::name. c\<sharp>(pi\<bullet>a,pi\<bullet>s1,pi\<bullet>s2,x)"
      by (rule at_exists_fresh[OF at_name_inst], simp add: fs_name1)
    then obtain c::"name" 
      where f1: "c\<noteq>(pi\<bullet>a)" and f2: "c\<sharp>x" and f3: "c\<sharp>(pi\<bullet>s1)" and f4: "c\<sharp>(pi\<bullet>s2)"
      by (force simp add: fresh_prod fresh_atm)
    have x: "P (Lam [c].(([(c,pi\<bullet>a)]@pi)\<bullet>s1)) (Lam [c].(([(c,pi\<bullet>a)]@pi)\<bullet>s2)) x"
      using a3 f2 j1 j2 by (simp, blast intro: eqvt_beta)
    have alpha1: "(Lam [c].([(c,pi\<bullet>a)]\<bullet>(pi\<bullet>s1))) = (Lam [(pi\<bullet>a)].(pi\<bullet>s1))" using f1 f3
      by (simp add: lam.inject alpha)
    have alpha2: "(Lam [c].([(c,pi\<bullet>a)]\<bullet>(pi\<bullet>s2))) = (Lam [(pi\<bullet>a)].(pi\<bullet>s2))" using f1 f3
      by (simp add: lam.inject alpha)
    show " P (Lam [(pi\<bullet>a)].(pi\<bullet>s1)) (Lam [(pi\<bullet>a)].(pi\<bullet>s2)) x"
      using x alpha1 alpha2 by (simp only: pt_name2)
  qed
next
  case (b4 a s1 s2)
  show ?case
  proof (simp add: subst_eqvt, intro strip)
    fix pi::"name prm" and x::"'a::fs_name" 
    have f: "\<exists>c::name. c\<sharp>(pi\<bullet>a,pi\<bullet>s1,pi\<bullet>s2,x)"
      by (rule at_exists_fresh[OF at_name_inst], simp add: fs_name1)
    then obtain c::"name" 
      where f1: "c\<noteq>(pi\<bullet>a)" and f2: "c\<sharp>(pi\<bullet>s2,x)" and f3: "c\<sharp>(pi\<bullet>s1)" and f4: "c\<sharp>(pi\<bullet>s2)"
      by (force simp add: fresh_prod fresh_atm)
    have x: "P (App (Lam [c].(([(c,pi\<bullet>a)]@pi)\<bullet>s1)) (pi\<bullet>s2)) ((([(c,pi\<bullet>a)]@pi)\<bullet>s1)[c::=(pi\<bullet>s2)]) x"
      using a4 f2 by (blast intro!: eqvt_beta)
    have alpha1: "(Lam [c].([(c,pi\<bullet>a)]\<bullet>(pi\<bullet>s1))) = (Lam [(pi\<bullet>a)].(pi\<bullet>s1))" using f1 f3
      by (simp add: lam.inject alpha)
    have alpha2: "(([(c,pi\<bullet>a)]@pi)\<bullet>s1)[c::=(pi\<bullet>s2)] = (pi\<bullet>s1)[(pi\<bullet>a)::=(pi\<bullet>s2)]"
      using f3 by (simp only: subst_rename[symmetric] pt_name2)
    show "P (App (Lam [(pi\<bullet>a)].(pi\<bullet>s1)) (pi\<bullet>s2)) ((pi\<bullet>s1)[(pi\<bullet>a)::=(pi\<bullet>s2)]) x"
      using x alpha1 alpha2 by (simp only: pt_name2)
  qed
qed

lemma beta_induct[case_names b1 b2 b3 b4]:
  fixes  P :: "lam \<Rightarrow> lam \<Rightarrow>'a::fs_name\<Rightarrow>bool"
  and    t :: "lam"
  and    s :: "lam"
  and    x :: "'a::fs_name"
  assumes a: "t\<longrightarrow>\<^isub>\<beta>s"
  and a1:    "\<And>x t s1 s2. 
              s1\<longrightarrow>\<^isub>\<beta>s2 \<Longrightarrow> (\<forall>z. P s1 s2 z) \<Longrightarrow> P (App s1 t) (App s2 t) x"
  and a2:    "\<And>x t s1 s2. 
              s1\<longrightarrow>\<^isub>\<beta>s2 \<Longrightarrow> (\<forall>z. P s1 s2 z) \<Longrightarrow> P (App t s1) (App t s2) x"
  and a3:    "\<And>x (a::name) s1 s2. 
              a\<sharp>x \<Longrightarrow> s1\<longrightarrow>\<^isub>\<beta>s2 \<Longrightarrow> (\<forall>z. P s1 s2 z) \<Longrightarrow> P (Lam [a].s1) (Lam [a].s2) x"
  and a4:    "\<And>x (a::name) t1 s1. 
              a\<sharp>(s1,x) \<Longrightarrow> P (App (Lam [a].t1) s1) (t1[a::=s1]) x"
  shows "P t s x"
using a a1 a2 a3 a4
by (auto intro!: beta_induct_aux[of "t" "s" "P" "[]" "x", simplified])

lemma supp_beta: "t\<longrightarrow>\<^isub>\<beta> s\<Longrightarrow>(supp s)\<subseteq>((supp t)::name set)"
apply(erule Beta.induct)
apply(auto intro!: simp add: abs_supp lam.supp subst_supp)
done
lemma beta_abs: "Lam [a].t\<longrightarrow>\<^isub>\<beta> t'\<Longrightarrow>\<exists>t''. t'=Lam [a].t'' \<and> t\<longrightarrow>\<^isub>\<beta> t''"
apply(ind_cases "Lam [a].t  \<longrightarrow>\<^isub>\<beta> t'")
apply(auto simp add: lam.distinct lam.inject)
apply(auto simp add: alpha)
apply(rule_tac x="[(a,aa)]\<bullet>s2" in exI)
apply(rule conjI)
apply(rule sym)
apply(rule pt_bij2[OF pt_name_inst, OF at_name_inst])
apply(simp)
apply(rule pt_name3)
apply(simp add: at_ds5[OF at_name_inst])
apply(rule conjI)
apply(simp add: pt_fresh_left[OF pt_name_inst, OF at_name_inst] calc_atm)
apply(force dest!: supp_beta simp add: fresh_def)
apply(force intro!: eqvt_beta)
done

lemma beta_subst[rule_format]: 
  assumes a: "M \<longrightarrow>\<^isub>\<beta> M'"
  shows "M[x::=N]\<longrightarrow>\<^isub>\<beta> M'[x::=N]" 
using a
apply(nominal_induct M M' rule: beta_induct)
apply(auto simp add: fresh_prod fresh_atm subs_lemma)
done

instance nat :: fs_name
apply(intro_classes)   
apply(simp_all add: supp_def perm_nat_def)
done

datatype ty =
    TVar "string"
  | TArr "ty" "ty" (infix "\<rightarrow>" 200)

primrec
 "pi\<bullet>(TVar s) = TVar s"
 "pi\<bullet>(\<tau> \<rightarrow> \<sigma>) = (\<tau> \<rightarrow> \<sigma>)"

lemma perm_ty[simp]:
  fixes pi ::"name prm"
  and   \<tau>  ::"ty"
  shows "pi\<bullet>\<tau> = \<tau>"
  by (cases \<tau>, simp_all)

lemma fresh_ty:
  fixes a ::"name"
  and   \<tau>  ::"ty"
  shows "a\<sharp>\<tau>"
  by (simp add: fresh_def supp_def)

instance ty :: pt_name
apply(intro_classes)   
apply(simp_all)
done

instance ty :: fs_name
apply(intro_classes)
apply(simp add: supp_def)
done

(* valid contexts *)

consts
  "dom_ty" :: "(name\<times>ty) list \<Rightarrow> (name list)"
primrec
  "dom_ty []    = []"
  "dom_ty (x#\<Gamma>) = (fst x)#(dom_ty \<Gamma>)" 

consts
  ctxts :: "((name\<times>ty) list) set" 
  valid :: "(name\<times>ty) list \<Rightarrow> bool"
translations
  "valid \<Gamma>" \<rightleftharpoons> "\<Gamma> \<in> ctxts"  
inductive ctxts
intros
v1[intro]: "valid []"
v2[intro]: "\<lbrakk>valid \<Gamma>;a\<sharp>\<Gamma>\<rbrakk>\<Longrightarrow> valid ((a,\<sigma>)#\<Gamma>)"

lemma valid_eqvt:
  fixes   pi:: "name prm"
  assumes a: "valid \<Gamma>"
  shows   "valid (pi\<bullet>\<Gamma>)"
using a
apply(induct)
apply(auto simp add: pt_fresh_bij[OF pt_name_inst, OF at_name_inst])
done

(* typing judgements *)

lemma fresh_context[rule_format]: 
  fixes  \<Gamma> :: "(name\<times>ty)list"
  and    a :: "name"
  shows "a\<sharp>\<Gamma>\<longrightarrow>\<not>(\<exists>\<tau>::ty. (a,\<tau>)\<in>set \<Gamma>)"
apply(induct_tac \<Gamma>)
apply(auto simp add: fresh_prod fresh_list_cons fresh_atm)
done

lemma valid_elim: 
  fixes  \<Gamma> :: "(name\<times>ty)list"
  and    pi:: "name prm"
  and    a :: "name"
  and    \<tau> :: "ty"
  shows "valid ((a,\<tau>)#\<Gamma>) \<Longrightarrow> valid \<Gamma> \<and> a\<sharp>\<Gamma>"
apply(ind_cases "valid ((a,\<tau>)#\<Gamma>)", simp)
done

lemma valid_unicity[rule_format]: 
  shows "valid \<Gamma>\<longrightarrow>(c,\<sigma>)\<in>set \<Gamma>\<longrightarrow>(c,\<tau>)\<in>set \<Gamma>\<longrightarrow>\<sigma>=\<tau>" 
apply(induct_tac \<Gamma>)
apply(auto dest!: valid_elim fresh_context)
done

consts
  typing :: "(((name\<times>ty) list)\<times>lam\<times>ty) set" 
syntax
  "_typing_judge" :: "(name\<times>ty) list\<Rightarrow>lam\<Rightarrow>ty\<Rightarrow>bool" (" _ \<turnstile> _ : _ " [80,80,80] 80) 
translations
  "\<Gamma> \<turnstile> t : \<tau>" \<rightleftharpoons> "(\<Gamma>,t,\<tau>) \<in> typing"  

inductive typing
intros
t1[intro]: "\<lbrakk>valid \<Gamma>; (a,\<tau>)\<in>set \<Gamma>\<rbrakk>\<Longrightarrow> \<Gamma> \<turnstile> Var a : \<tau>"
t2[intro]: "\<lbrakk>\<Gamma> \<turnstile> t1 : \<tau>\<rightarrow>\<sigma>; \<Gamma> \<turnstile> t2 : \<tau>\<rbrakk>\<Longrightarrow> \<Gamma> \<turnstile> App t1 t2 : \<sigma>"
t3[intro]: "\<lbrakk>a\<sharp>\<Gamma>;((a,\<tau>)#\<Gamma>) \<turnstile> t : \<sigma>\<rbrakk> \<Longrightarrow> \<Gamma> \<turnstile> Lam [a].t : \<tau>\<rightarrow>\<sigma>"

lemma typing_eqvt: 
  fixes  \<Gamma> :: "(name\<times>ty) list"
  and    t :: "lam"
  and    \<tau> :: "ty"
  and    pi:: "name prm"
  assumes a: "\<Gamma> \<turnstile> t : \<tau>"
  shows "(pi\<bullet>\<Gamma>) \<turnstile> (pi\<bullet>t) : \<tau>"
using a
proof (induct)
  case (t1 \<Gamma> \<tau> a)
  have "valid (pi\<bullet>\<Gamma>)" by (rule valid_eqvt)
  moreover
  have "(pi\<bullet>(a,\<tau>))\<in>((pi::name prm)\<bullet>set \<Gamma>)" by (rule pt_set_bij2[OF pt_name_inst, OF at_name_inst])
  ultimately show "(pi\<bullet>\<Gamma>) \<turnstile> (pi\<bullet>Var a) : \<tau>"
    using typing.intros by (auto simp add: pt_list_set_pi[OF pt_name_inst])
next 
  case (t3 \<Gamma> \<sigma> \<tau> a t)
  moreover have "(pi\<bullet>a)\<sharp>(pi\<bullet>\<Gamma>)" by (rule pt_fresh_bij1[OF pt_name_inst, OF at_name_inst])
  ultimately show "(pi\<bullet>\<Gamma>) \<turnstile> (pi\<bullet>Lam [a].t) : \<tau>\<rightarrow>\<sigma>" 
    using typing.intros by (force)
qed (auto)

lemma typing_induct_aux[rule_format]:
  fixes  P :: "(name\<times>ty) list \<Rightarrow> lam \<Rightarrow> ty \<Rightarrow>'a::fs_name\<Rightarrow>bool"
  and    \<Gamma> :: "(name\<times>ty) list"
  and    t :: "lam"
  and    \<tau> :: "ty"
  assumes a: "\<Gamma> \<turnstile> t : \<tau>"
  and a1:    "\<And>x \<Gamma> (a::name) \<tau>. valid \<Gamma> \<Longrightarrow> (a,\<tau>) \<in> set \<Gamma> \<Longrightarrow> P \<Gamma> (Var a) \<tau> x"
  and a2:    "\<And>x \<Gamma> \<tau> \<sigma> t1 t2. 
              \<Gamma> \<turnstile> t1 : \<tau>\<rightarrow>\<sigma> \<Longrightarrow> (\<And>z. P \<Gamma> t1 (\<tau>\<rightarrow>\<sigma>) z) \<Longrightarrow> \<Gamma> \<turnstile> t2 : \<tau> \<Longrightarrow> (\<And>z. P \<Gamma> t2 \<tau> z)
              \<Longrightarrow> P \<Gamma> (App t1 t2) \<sigma> x"
  and a3:    "\<And>x (a::name) \<Gamma> \<tau> \<sigma> t. 
              a\<sharp>x \<Longrightarrow> a\<sharp>\<Gamma> \<Longrightarrow> ((a,\<tau>) # \<Gamma>) \<turnstile> t : \<sigma> \<Longrightarrow> (\<forall>z. P ((a,\<tau>)#\<Gamma>) t \<sigma> z)
              \<Longrightarrow> P \<Gamma> (Lam [a].t) (\<tau>\<rightarrow>\<sigma>) x"
  shows "\<forall>(pi::name prm) (x::'a::fs_name). P (pi\<bullet>\<Gamma>) (pi\<bullet>t) \<tau> x"
using a
proof (induct)
  case (t1 \<Gamma> \<tau> a)
  assume j1: "valid \<Gamma>"
  assume j2: "(a,\<tau>)\<in>set \<Gamma>"
  show ?case
  proof (intro strip, simp)
    fix pi::"name prm" and x::"'a::fs_name"
    from j1 have j3: "valid (pi\<bullet>\<Gamma>)" by (rule valid_eqvt)
    from j2 have "pi\<bullet>(a,\<tau>)\<in>pi\<bullet>(set \<Gamma>)" by (simp only: pt_set_bij[OF pt_name_inst, OF at_name_inst])  
    hence j4: "(pi\<bullet>a,\<tau>)\<in>set (pi\<bullet>\<Gamma>)" by (simp add: pt_list_set_pi[OF pt_name_inst])
    show "P (pi\<bullet>\<Gamma>) (Var (pi\<bullet>a)) \<tau> x" using a1 j3 j4 by force
  qed
next
  case (t2 \<Gamma> \<sigma> \<tau> t1 t2)
  thus ?case using a2 by (simp, blast intro: typing_eqvt)
next
  case (t3 \<Gamma> \<sigma> \<tau> a t)
  have k1: "a\<sharp>\<Gamma>" by fact
  have k2: "((a,\<tau>)#\<Gamma>)\<turnstile>t:\<sigma>" by fact
  have k3: "\<forall>(pi::name prm) (x::'a::fs_name). P (pi \<bullet> ((a,\<tau>)#\<Gamma>)) (pi\<bullet>t) \<sigma> x" by fact
  show ?case
  proof (intro strip, simp)
    fix pi::"name prm" and x::"'a::fs_name"
    have f: "\<exists>c::name. c\<sharp>(pi\<bullet>a,pi\<bullet>t,pi\<bullet>\<Gamma>,x)"
      by (rule at_exists_fresh[OF at_name_inst], simp add: fs_name1)
    then obtain c::"name" 
      where f1: "c\<noteq>(pi\<bullet>a)" and f2: "c\<sharp>x" and f3: "c\<sharp>(pi\<bullet>t)" and f4: "c\<sharp>(pi\<bullet>\<Gamma>)"
      by (force simp add: fresh_prod fresh_atm)
    from k1 have k1a: "(pi\<bullet>a)\<sharp>(pi\<bullet>\<Gamma>)" 
      by (simp add: pt_fresh_left[OF pt_name_inst, OF at_name_inst] 
                    pt_rev_pi[OF pt_name_inst, OF at_name_inst])
    have l1: "(([(c,pi\<bullet>a)]@pi)\<bullet>\<Gamma>) = (pi\<bullet>\<Gamma>)" using f4 k1a 
      by (simp only: pt_name2, rule pt_fresh_fresh[OF pt_name_inst, OF at_name_inst])
    have "\<forall>x. P (([(c,pi\<bullet>a)]@pi)\<bullet>((a,\<tau>)#\<Gamma>)) (([(c,pi\<bullet>a)]@pi)\<bullet>t) \<sigma> x" using k3 by force
    hence l2: "\<forall>x. P ((c, \<tau>)#(pi\<bullet>\<Gamma>)) (([(c,pi\<bullet>a)]@pi)\<bullet>t) \<sigma> x" using f1 l1
      by (force simp add: pt_name2  calc_atm split: if_splits)
    have "(([(c,pi\<bullet>a)]@pi)\<bullet>((a,\<tau>)#\<Gamma>)) \<turnstile> (([(c,pi\<bullet>a)]@pi)\<bullet>t) : \<sigma>" using k2 by (rule typing_eqvt)
    hence l3: "((c, \<tau>)#(pi\<bullet>\<Gamma>)) \<turnstile> (([(c,pi\<bullet>a)]@pi)\<bullet>t) : \<sigma>" using l1 f1 
      by (force simp add: pt_name2 calc_atm split: if_splits)
    have l4: "P (pi\<bullet>\<Gamma>) (Lam [c].(([(c,pi\<bullet>a)]@pi)\<bullet>t)) (\<tau> \<rightarrow> \<sigma>) x" using f2 f4 l2 l3 a3 by auto
    have alpha: "(Lam [c].([(c,pi\<bullet>a)]\<bullet>(pi\<bullet>t))) = (Lam [(pi\<bullet>a)].(pi\<bullet>t))" using f1 f3
      by (simp add: lam.inject alpha)
    show "P (pi\<bullet>\<Gamma>) (Lam [(pi\<bullet>a)].(pi\<bullet>t)) (\<tau> \<rightarrow> \<sigma>) x" using l4 alpha 
      by (simp only: pt_name2)
  qed
qed

lemma typing_induct[case_names t1 t2 t3]:
  fixes  P :: "(name\<times>ty) list \<Rightarrow> lam \<Rightarrow> ty \<Rightarrow>'a::fs_name\<Rightarrow>bool"
  and    \<Gamma> :: "(name\<times>ty) list"
  and    t :: "lam"
  and    \<tau> :: "ty"
  and    x :: "'a::fs_name"
  assumes a: "\<Gamma> \<turnstile> t : \<tau>"
  and a1:    "\<And>x \<Gamma> (a::name) \<tau>. valid \<Gamma> \<Longrightarrow> (a,\<tau>) \<in> set \<Gamma> \<Longrightarrow> P \<Gamma> (Var a) \<tau> x"
  and a2:    "\<And>x \<Gamma> \<tau> \<sigma> t1 t2. 
              \<Gamma> \<turnstile> t1 : \<tau>\<rightarrow>\<sigma> \<Longrightarrow> (\<forall>z. P \<Gamma> t1 (\<tau>\<rightarrow>\<sigma>) z) \<Longrightarrow> \<Gamma> \<turnstile> t2 : \<tau> \<Longrightarrow> (\<forall>z. P \<Gamma> t2 \<tau> z)
              \<Longrightarrow> P \<Gamma> (App t1 t2) \<sigma> x"
  and a3:    "\<And>x (a::name) \<Gamma> \<tau> \<sigma> t. 
              a\<sharp>x \<Longrightarrow> a\<sharp>\<Gamma> \<Longrightarrow> ((a,\<tau>) # \<Gamma>) \<turnstile> t : \<sigma> \<Longrightarrow> (\<forall>z. P ((a,\<tau>)#\<Gamma>) t \<sigma> z)
              \<Longrightarrow> P \<Gamma> (Lam [a].t) (\<tau>\<rightarrow>\<sigma>) x"
  shows "P \<Gamma> t \<tau> x"
using a a1 a2 a3 typing_induct_aux[of "\<Gamma>" "t" "\<tau>" "P" "[]" "x", simplified] by force

constdefs
  "sub" :: "(name\<times>ty) list \<Rightarrow> (name\<times>ty) list \<Rightarrow> bool" (" _ \<lless> _ " [80,80] 80)
  "\<Gamma>1 \<lless> \<Gamma>2 \<equiv> \<forall>a \<sigma>. (a,\<sigma>)\<in>set \<Gamma>1 \<longrightarrow>  (a,\<sigma>)\<in>set \<Gamma>2"

lemma weakening[rule_format]: 
  assumes a: "\<Gamma>1 \<turnstile> t : \<sigma>"
  shows "valid \<Gamma>2 \<longrightarrow> \<Gamma>1 \<lless> \<Gamma>2 \<longrightarrow> \<Gamma>2 \<turnstile> t:\<sigma>"
using a
apply(nominal_induct \<Gamma>1 t \<sigma> rule: typing_induct)
apply(auto simp add: sub_def)
done

lemma in_ctxt[rule_format]: "(a,\<tau>)\<in>set \<Gamma> \<longrightarrow> (a\<in>set(dom_ty \<Gamma>))"
apply(induct_tac \<Gamma>)
apply(auto)
done

lemma free_vars: 
  assumes a: "\<Gamma> \<turnstile> t : \<tau>"
  shows " (supp t)\<subseteq>set(dom_ty \<Gamma>)"
using a
apply(nominal_induct \<Gamma> t \<tau> rule: typing_induct)
apply(auto simp add: lam.supp abs_supp supp_atm in_ctxt)
done

lemma t1_elim: "\<Gamma> \<turnstile> Var a : \<tau> \<Longrightarrow> valid \<Gamma> \<and> (a,\<tau>) \<in> set \<Gamma>"
apply(ind_cases "\<Gamma> \<turnstile> Var a : \<tau>")
apply(auto simp add: lam.inject lam.distinct)
done

lemma t2_elim: "\<Gamma> \<turnstile> App t1 t2 : \<sigma> \<Longrightarrow> \<exists>\<tau>. (\<Gamma> \<turnstile> t1 : \<tau>\<rightarrow>\<sigma> \<and> \<Gamma> \<turnstile> t2 : \<tau>)"
apply(ind_cases "\<Gamma> \<turnstile> App t1 t2 : \<sigma>")
apply(auto simp add: lam.inject lam.distinct)
done

lemma t3_elim: "\<lbrakk>\<Gamma> \<turnstile> Lam [a].t : \<sigma>;a\<sharp>\<Gamma>\<rbrakk>\<Longrightarrow> \<exists>\<tau> \<tau>'. \<sigma>=\<tau>\<rightarrow>\<tau>' \<and> ((a,\<tau>)#\<Gamma>) \<turnstile> t : \<tau>'"
apply(ind_cases "\<Gamma> \<turnstile> Lam [a].t : \<sigma>")
apply(auto simp add: lam.distinct lam.inject alpha) 
apply(drule_tac pi="[(a,aa)]::name prm" in typing_eqvt)
apply(simp)
apply(subgoal_tac "([(a,aa)]::name prm)\<bullet>\<Gamma> = \<Gamma>")(*A*)
apply(force simp add: calc_atm)
(*A*)
apply(force intro!: pt_fresh_fresh[OF pt_name_inst, OF at_name_inst])
done

lemma typing_valid: 
  assumes a: "\<Gamma> \<turnstile> t : \<tau>" 
  shows "valid \<Gamma>"
using a by (induct, auto dest!: valid_elim)

lemma ty_subs[rule_format]:
  fixes \<Gamma> ::"(name\<times>ty) list"
  and   t1 ::"lam"
  and   t2 ::"lam"
  and   \<tau>  ::"ty"
  and   \<sigma>  ::"ty" 
  and   c  ::"name"
  shows  "((c,\<sigma>)#\<Gamma>) \<turnstile> t1:\<tau>\<longrightarrow> \<Gamma>\<turnstile> t2:\<sigma>\<longrightarrow> \<Gamma> \<turnstile> t1[c::=t2]:\<tau>"
proof(nominal_induct t1 rule: lam_induct)
  case (Var \<Gamma> \<sigma> \<tau> c t2 a)
  show ?case
  proof(intro strip)
    assume a1: "\<Gamma> \<turnstile>t2:\<sigma>"
    assume a2: "((c,\<sigma>)#\<Gamma>) \<turnstile> Var a:\<tau>"
    hence a21: "(a,\<tau>)\<in>set((c,\<sigma>)#\<Gamma>)" and a22: "valid((c,\<sigma>)#\<Gamma>)" by (auto dest: t1_elim)
    from a22 have a23: "valid \<Gamma>" and a24: "c\<sharp>\<Gamma>" by (auto dest: valid_elim) 
    from a24 have a25: "\<not>(\<exists>\<tau>. (c,\<tau>)\<in>set \<Gamma>)" by (rule fresh_context)
    show "\<Gamma>\<turnstile>(Var a)[c::=t2] : \<tau>"
    proof (cases "a=c", simp_all)
      assume case1: "a=c"
      show "\<Gamma> \<turnstile> t2:\<tau>" using a1
      proof (cases "\<sigma>=\<tau>")
	assume "\<sigma>=\<tau>" thus ?thesis using a1 by simp 
      next
	assume a3: "\<sigma>\<noteq>\<tau>"
	show ?thesis
	proof (rule ccontr)
	  from a3 a21 have "(a,\<tau>)\<in>set \<Gamma>" by force
	  with case1 a25 show False by force 
	qed
      qed
    next
      assume case2: "a\<noteq>c"
      with a21 have a26: "(a,\<tau>)\<in>set \<Gamma>" by force 
      from a23 a26 show "\<Gamma> \<turnstile> Var a:\<tau>" by force
    qed
  qed
next
  case (App \<Gamma> \<sigma> \<tau> c t2 s1 s2)
  show ?case
  proof (intro strip, simp)
    assume b1: "\<Gamma> \<turnstile>t2:\<sigma>" 
    assume b2: " ((c,\<sigma>)#\<Gamma>)\<turnstile>App s1 s2 : \<tau>"
    hence "\<exists>\<tau>'. (((c,\<sigma>)#\<Gamma>)\<turnstile>s1:\<tau>'\<rightarrow>\<tau> \<and> ((c,\<sigma>)#\<Gamma>)\<turnstile>s2:\<tau>')" by (rule t2_elim) 
    then obtain \<tau>' where b3a: "((c,\<sigma>)#\<Gamma>)\<turnstile>s1:\<tau>'\<rightarrow>\<tau>" and b3b: "((c,\<sigma>)#\<Gamma>)\<turnstile>s2:\<tau>'" by force
    show "\<Gamma> \<turnstile>  App (s1[c::=t2]) (s2[c::=t2]) : \<tau>" 
      using b1 b3a b3b App by (rule_tac \<tau>="\<tau>'" in t2, auto)
  qed
next
  case (Lam \<Gamma> \<sigma> \<tau> c t2 a s)
  assume "a\<sharp>(\<Gamma>,\<sigma>,\<tau>,c,t2)" 
  hence f1: "a\<sharp>\<Gamma>" and f2: "a\<noteq>c" and f2': "c\<sharp>a" and f3: "a\<sharp>t2" and f4: "a\<sharp>((c,\<sigma>)#\<Gamma>)"
    by (auto simp add: fresh_atm fresh_prod fresh_list_cons)
  show ?case using f2 f3
  proof(intro strip, simp)
    assume c1: "((c,\<sigma>)#\<Gamma>)\<turnstile>Lam [a].s : \<tau>"
    hence "\<exists>\<tau>1 \<tau>2. \<tau>=\<tau>1\<rightarrow>\<tau>2 \<and> ((a,\<tau>1)#(c,\<sigma>)#\<Gamma>) \<turnstile> s : \<tau>2" using f4 by (auto dest: t3_elim) 
    then obtain \<tau>1 \<tau>2 where c11: "\<tau>=\<tau>1\<rightarrow>\<tau>2" and c12: "((a,\<tau>1)#(c,\<sigma>)#\<Gamma>) \<turnstile> s : \<tau>2" by force
    from c12 have "valid ((a,\<tau>1)#(c,\<sigma>)#\<Gamma>)" by (rule typing_valid)
    hence ca: "valid \<Gamma>" and cb: "a\<sharp>\<Gamma>" and cc: "c\<sharp>\<Gamma>" 
      by (auto dest: valid_elim simp add: fresh_list_cons) 
    from c12 have c14: "((c,\<sigma>)#(a,\<tau>1)#\<Gamma>) \<turnstile> s : \<tau>2"
    proof -
      have c2: "((a,\<tau>1)#(c,\<sigma>)#\<Gamma>) \<lless> ((c,\<sigma>)#(a,\<tau>1)#\<Gamma>)" by (force simp add: sub_def)
      have c3: "valid ((c,\<sigma>)#(a,\<tau>1)#\<Gamma>)"
	by (rule v2, rule v2, auto simp add: fresh_list_cons fresh_prod ca cb cc f2' fresh_ty)
      from c12 c2 c3 show ?thesis by (force intro: weakening)
    qed
    assume c8: "\<Gamma> \<turnstile> t2 : \<sigma>"
    have c81: "((a,\<tau>1)#\<Gamma>)\<turnstile>t2 :\<sigma>"
    proof -
      have c82: "\<Gamma> \<lless> ((a,\<tau>1)#\<Gamma>)" by (force simp add: sub_def)
      have c83: "valid ((a,\<tau>1)#\<Gamma>)" using f1 ca by force
      with c8 c82 c83 show ?thesis by (force intro: weakening)
    qed
    show "\<Gamma> \<turnstile> Lam [a].(s[c::=t2]) : \<tau>"
      using c11 Lam c14 c81 f1 by force
  qed
qed

lemma subject[rule_format]: 
  fixes \<Gamma>  ::"(name\<times>ty) list"
  and   t1 ::"lam"
  and   t2 ::"lam"
  and   \<tau>  ::"ty"
  assumes a: "t1\<longrightarrow>\<^isub>\<beta>t2"
  shows "(\<Gamma> \<turnstile> t1:\<tau>) \<longrightarrow> (\<Gamma> \<turnstile> t2:\<tau>)"
using a
proof (nominal_induct t1 t2 rule: beta_induct, auto)
  case (b1 \<Gamma> \<tau> t s1 s2)
  assume i: "\<forall>\<Gamma> \<tau>. \<Gamma> \<turnstile> s1 : \<tau> \<longrightarrow> \<Gamma> \<turnstile> s2 : \<tau>" 
  assume "\<Gamma> \<turnstile> App s1 t : \<tau>"
  hence "\<exists>\<sigma>. (\<Gamma> \<turnstile> s1 : \<sigma>\<rightarrow>\<tau> \<and> \<Gamma> \<turnstile> t : \<sigma>)" by (rule t2_elim)
  then obtain \<sigma> where a1: "\<Gamma> \<turnstile> s1 : \<sigma>\<rightarrow>\<tau>" and a2: "\<Gamma> \<turnstile> t : \<sigma>" by force
  thus "\<Gamma> \<turnstile> App s2 t : \<tau>" using i by force
next
  case (b2 \<Gamma> \<tau> t s1 s2)
  assume i: "\<forall>\<Gamma> \<tau>. \<Gamma> \<turnstile> s1 : \<tau> \<longrightarrow> \<Gamma> \<turnstile> s2 : \<tau>" 
  assume "\<Gamma> \<turnstile> App t s1 : \<tau>"
  hence "\<exists>\<sigma>. (\<Gamma> \<turnstile> t : \<sigma>\<rightarrow>\<tau> \<and> \<Gamma> \<turnstile> s1 : \<sigma>)" by (rule t2_elim)
  then obtain \<sigma> where a1: "\<Gamma> \<turnstile> t : \<sigma>\<rightarrow>\<tau>" and a2: "\<Gamma> \<turnstile> s1 : \<sigma>" by force
  thus "\<Gamma> \<turnstile> App t s2 : \<tau>" using i by force
next
  case (b3 \<Gamma> \<tau> a s1 s2)
  assume "a\<sharp>(\<Gamma>,\<tau>)"
  hence f: "a\<sharp>\<Gamma>" by (simp add: fresh_prod)
  assume i: "\<forall>\<Gamma> \<tau>. \<Gamma> \<turnstile> s1 : \<tau> \<longrightarrow> \<Gamma> \<turnstile> s2 : \<tau>" 
  assume "\<Gamma> \<turnstile> Lam [a].s1 : \<tau>"
  with f have "\<exists>\<tau>1 \<tau>2. \<tau>=\<tau>1\<rightarrow>\<tau>2 \<and> ((a,\<tau>1)#\<Gamma>) \<turnstile> s1 : \<tau>2" by (force dest: t3_elim)
  then obtain \<tau>1 \<tau>2 where a1: "\<tau>=\<tau>1\<rightarrow>\<tau>2" and a2: "((a,\<tau>1)#\<Gamma>) \<turnstile> s1 : \<tau>2" by force
  thus "\<Gamma> \<turnstile> Lam [a].s2 : \<tau>" using f i by force 
next
  case (b4 \<Gamma> \<tau> a s1 s2)
  have "a\<sharp>(s2,\<Gamma>,\<tau>)" by fact
  hence f: "a\<sharp>\<Gamma>" by (simp add: fresh_prod)
  assume "\<Gamma> \<turnstile> App (Lam [a].s1) s2 : \<tau>"
  hence "\<exists>\<sigma>. (\<Gamma> \<turnstile> (Lam [a].s1) : \<sigma>\<rightarrow>\<tau> \<and> \<Gamma> \<turnstile> s2 : \<sigma>)" by (rule t2_elim)
  then obtain \<sigma> where a1: "\<Gamma> \<turnstile> (Lam [(a::name)].s1) : \<sigma>\<rightarrow>\<tau>" and a2: "\<Gamma> \<turnstile> s2 : \<sigma>" by force
  have  "((a,\<sigma>)#\<Gamma>) \<turnstile> s1 : \<tau>" using a1 f by (auto dest!: t3_elim)
  with a2 show "\<Gamma> \<turnstile>  s1[a::=s2] : \<tau>" by (force intro: ty_subs)
qed


lemma subject[rule_format]: 
  fixes \<Gamma>  ::"(name\<times>ty) list"
  and   t1 ::"lam"
  and   t2 ::"lam"
  and   \<tau>  ::"ty"
  assumes a: "t1\<longrightarrow>\<^isub>\<beta>t2"
  shows "\<Gamma> \<turnstile> t1:\<tau> \<longrightarrow> \<Gamma> \<turnstile> t2:\<tau>"
using a
apply(nominal_induct t1 t2 rule: beta_induct)
apply(auto dest!: t2_elim t3_elim intro: ty_subs simp add: fresh_prod)
done



subsection {* some facts about beta *}

constdefs
  "NORMAL" :: "lam \<Rightarrow> bool"
  "NORMAL t \<equiv> \<not>(\<exists>t'. t\<longrightarrow>\<^isub>\<beta> t')"

constdefs
  "SN" :: "lam \<Rightarrow> bool"
  "SN t \<equiv> t\<in>termi Beta"

lemma qq1: "\<lbrakk>SN(t1);t1\<longrightarrow>\<^isub>\<beta> t2\<rbrakk>\<Longrightarrow>SN(t2)"
apply(simp add: SN_def)
apply(drule_tac a="t2" in acc_downward)
apply(auto)
done

lemma qq2: "(\<forall>t2. t1\<longrightarrow>\<^isub>\<beta>t2 \<longrightarrow> SN(t2))\<Longrightarrow>SN(t1)"
apply(simp add: SN_def)
apply(rule accI)
apply(auto)
done


section {* Candidates *}

consts
  RED :: "ty \<Rightarrow> lam set"
primrec
 "RED (TVar X) = {t. SN(t)}"
 "RED (\<tau>\<rightarrow>\<sigma>) =   {t. \<forall>u. (u\<in>RED \<tau> \<longrightarrow> (App t u)\<in>RED \<sigma>)}"

constdefs
  NEUT :: "lam \<Rightarrow> bool"
  "NEUT t \<equiv> (\<exists>a. t=Var a)\<or>(\<exists>t1 t2. t=App t1 t2)" 

(* a slight hack to get the first element of applications *)
consts
  FST :: "(lam\<times>lam) set"
syntax 
  "FST_judge"   :: "lam\<Rightarrow>lam\<Rightarrow>bool" (" _ \<guillemotright> _" [80,80] 80)
translations 
  "t1 \<guillemotright> t2" \<rightleftharpoons> "(t1,t2) \<in> FST"
inductive FST
intros
fst[intro!]:  "(App t s) \<guillemotright> t"

lemma fst_elim[elim!]: "(App t s) \<guillemotright> t' \<Longrightarrow> t=t'"
apply(ind_cases "App t s \<guillemotright> t'")
apply(simp add: lam.inject)
done

lemma qq3: "SN(App t s)\<Longrightarrow>SN(t)"
apply(simp add: SN_def)
apply(subgoal_tac "\<forall>z. (App t s \<guillemotright> z) \<longrightarrow> z\<in>termi Beta")(*A*)
apply(force)
(*A*)
apply(erule acc_induct)
apply(clarify)
apply(ind_cases "x \<guillemotright> z")
apply(clarify)
apply(rule accI)
apply(auto intro: b1)
done

constdefs
   "CR1" :: "ty \<Rightarrow> bool"
   "CR1 \<tau> \<equiv> \<forall> t. (t\<in>RED \<tau> \<longrightarrow> SN(t))"

   "CR2" :: "ty \<Rightarrow> bool"
   "CR2 \<tau> \<equiv> \<forall>t t'. ((t\<in>RED \<tau> \<and> t \<longrightarrow>\<^isub>\<beta> t') \<longrightarrow> t'\<in>RED \<tau>)"

   "CR3_RED" :: "lam \<Rightarrow> ty \<Rightarrow> bool"
   "CR3_RED t \<tau> \<equiv> \<forall>t'. (t\<longrightarrow>\<^isub>\<beta> t' \<longrightarrow>  t'\<in>RED \<tau>)" 

   "CR3" :: "ty \<Rightarrow> bool"
   "CR3 \<tau> \<equiv> \<forall>t. (NEUT t \<and> CR3_RED t \<tau>) \<longrightarrow> t\<in>RED \<tau>"
   
   "CR4" :: "ty \<Rightarrow> bool"
   "CR4 \<tau> \<equiv> \<forall>t. (NEUT t \<and> NORMAL t) \<longrightarrow>t\<in>RED \<tau>"

lemma CR3_CR4: "CR3 \<tau> \<Longrightarrow> CR4 \<tau>"
apply(simp (no_asm_use) add: CR3_def CR3_RED_def CR4_def NORMAL_def)
apply(blast)
done

lemma sub_ind: 
  "SN(u)\<Longrightarrow>(u\<in>RED \<tau>\<longrightarrow>(\<forall>t. (NEUT t\<and>CR2 \<tau>\<and>CR3 \<sigma>\<and>CR3_RED t (\<tau>\<rightarrow>\<sigma>))\<longrightarrow>(App t u)\<in>RED \<sigma>))"
apply(simp add: SN_def)
apply(erule acc_induct)
apply(auto)
apply(simp add: CR3_def)
apply(rotate_tac 5)
apply(drule_tac x="App t x" in spec)
apply(drule mp)
apply(rule conjI)
apply(force simp only: NEUT_def)
apply(simp (no_asm) add: CR3_RED_def)
apply(clarify)
apply(ind_cases "App t x \<longrightarrow>\<^isub>\<beta> t'")
apply(simp_all add: lam.inject)
apply(simp only:  CR3_RED_def)
apply(drule_tac x="s2" in spec)
apply(simp)
apply(drule_tac x="s2" in spec)
apply(simp)
apply(drule mp)
apply(simp (no_asm_use) add: CR2_def)
apply(blast)
apply(drule_tac x="ta" in spec)
apply(force)
apply(auto simp only: NEUT_def lam.inject lam.distinct)
done

lemma RED_props: "CR1 \<tau> \<and> CR2 \<tau> \<and> CR3 \<tau>"
apply(induct_tac \<tau>)
apply(auto)
(* atom types *)
(* C1 *)
apply(simp add: CR1_def)
(* C2 *)
apply(simp add: CR2_def)
apply(clarify)
apply(drule_tac ?t2.0="t'" in  qq1)
apply(assumption)+
(* C3 *)
apply(simp add: CR3_def CR3_RED_def)
apply(clarify)
apply(rule qq2)
apply(assumption)
(* arrow types *)
(* C1 *)
apply(simp (no_asm) add: CR1_def)
apply(clarify)
apply(subgoal_tac "NEUT (Var a)")(*A*)
apply(subgoal_tac "(Var a)\<in>RED ty1")(*C*)
apply(drule_tac x="Var a" in spec)
apply(simp)
apply(simp add: CR1_def)
apply(rotate_tac 1)
apply(drule_tac x="App t (Var a)" in spec)
apply(simp)
apply(drule qq3) 
apply(assumption)
(*C*)
apply(simp (no_asm_use) add: CR3_def CR3_RED_def)
apply(drule_tac x="Var a" in spec)
apply(drule mp)
apply(clarify)
apply(ind_cases " Var a \<longrightarrow>\<^isub>\<beta> t'")
apply(simp (no_asm_use) add: lam.distinct)+ 
(*A*)
apply(simp (no_asm) only: NEUT_def)
apply(rule disjCI)
apply(rule_tac x="a" in exI)
apply(simp (no_asm))
(* C2 *)
apply(simp (no_asm) add: CR2_def)
apply(clarify)
apply(drule_tac x="u" in spec)
apply(simp)
apply(subgoal_tac "App t u \<longrightarrow>\<^isub>\<beta> App t' u")(*X*)
apply(simp (no_asm_use) only: CR2_def)
apply(blast)
(*X*)
apply(force intro!: b1)
(* C3 *)
apply(unfold CR3_def)
apply(rule allI)
apply(rule impI)
apply(erule conjE)
apply(simp (no_asm))
apply(rule allI)
apply(rule impI)
apply(subgoal_tac "SN(u)")(*Z*)
apply(fold CR3_def)
apply(drule_tac \<tau>="ty1" and \<sigma>="ty2" in sub_ind)
apply(simp)
(*Z*)
apply(simp add: CR1_def)
done

lemma double_acc_aux:
  assumes a_acc: "a \<in> acc r"
  and b_acc: "b \<in> acc r"
  and hyp: "\<And>x z.
    (\<And>y. (y, x) \<in> r \<Longrightarrow> y \<in> acc r) \<Longrightarrow>
    (\<And>y. (y, x) \<in> r \<Longrightarrow> P y z) \<Longrightarrow>
    (\<And>u. (u, z) \<in> r \<Longrightarrow> u \<in> acc r) \<Longrightarrow>
    (\<And>u. (u, z) \<in> r \<Longrightarrow> P x u) \<Longrightarrow> P x z"
  shows "P a b"
proof -
  from a_acc
  have r: "\<And>b. b \<in> acc r \<Longrightarrow> P a b"
  proof (induct a rule: acc.induct)
    case (accI x)
    note accI' = accI
    have "b \<in> acc r" .
    thus ?case
    proof (induct b rule: acc.induct)
      case (accI y)
      show ?case
	apply (rule hyp)
	apply (erule accI')
	apply (erule accI')
	apply (rule acc.accI)
	apply (erule accI)
	apply (erule accI)
	apply (erule accI)
	done
    qed
  qed
  from b_acc show ?thesis by (rule r)
qed

lemma double_acc:
  "\<lbrakk>a \<in> acc r; b \<in> acc r; \<forall>x z. ((\<forall>y. (y, x)\<in>r\<longrightarrow>P y z)\<and>(\<forall>u. (u, z)\<in>r\<longrightarrow>P x u))\<longrightarrow>P x z\<rbrakk>\<Longrightarrow>P a b"
apply(rule_tac r="r" in double_acc_aux)
apply(assumption)+
apply(blast)
done

lemma abs_RED[rule_format]: "(\<forall>s\<in>RED \<tau>. t[x::=s]\<in>RED \<sigma>)\<longrightarrow>Lam [x].t\<in>RED (\<tau>\<rightarrow>\<sigma>)"
apply(simp)
apply(clarify)
apply(subgoal_tac "t\<in>termi Beta")(*1*)
apply(erule rev_mp)
apply(subgoal_tac "u \<in> RED \<tau>")(*A*)
apply(erule rev_mp)
apply(rule_tac a="t" and b="u" in double_acc)
apply(assumption)
apply(subgoal_tac "CR1 \<tau>")(*A*)
apply(simp add: CR1_def SN_def)
(*A*)
apply(force simp add: RED_props)
apply(simp)
apply(clarify)
apply(subgoal_tac "CR3 \<sigma>")(*B*)
apply(simp add: CR3_def)
apply(rotate_tac 6)
apply(drule_tac x="App(Lam[x].xa ) z" in spec)
apply(drule mp)
apply(rule conjI)
apply(force simp add: NEUT_def)
apply(simp add: CR3_RED_def)
apply(clarify)
apply(ind_cases "App(Lam[x].xa) z \<longrightarrow>\<^isub>\<beta> t'")
apply(auto simp add: lam.inject lam.distinct)
apply(drule beta_abs)
apply(auto)
apply(drule_tac x="t''" in spec)
apply(simp)
apply(drule mp)
apply(clarify)
apply(drule_tac x="s" in bspec)
apply(assumption)
apply(subgoal_tac "xa [ x ::= s ] \<longrightarrow>\<^isub>\<beta>  t'' [ x ::= s ]")(*B*)
apply(subgoal_tac "CR2 \<sigma>")(*C*)
apply(simp (no_asm_use) add: CR2_def)
apply(blast)
(*C*)
apply(force simp add: RED_props)
(*B*)
apply(force intro!: beta_subst)
apply(assumption)
apply(rotate_tac 3)
apply(drule_tac x="s2" in spec)
apply(subgoal_tac "s2\<in>RED \<tau>")(*D*)
apply(simp)
(*D*)
apply(subgoal_tac "CR2 \<tau>")(*E*)
apply(simp (no_asm_use) add: CR2_def)
apply(blast)
(*E*)
apply(force simp add: RED_props)
apply(simp add: alpha)
apply(erule disjE)
apply(force)
apply(auto)
apply(simp add: subst_rename)
apply(drule_tac x="z" in bspec)
apply(assumption)
(*B*)
apply(force simp add: RED_props)
(*1*)
apply(drule_tac x="Var x" in bspec)
apply(subgoal_tac "CR3 \<tau>")(*2*) 
apply(drule CR3_CR4)
apply(simp add: CR4_def)
apply(drule_tac x="Var x" in spec)
apply(drule mp)
apply(rule conjI)
apply(force simp add: NEUT_def)
apply(simp add: NORMAL_def)
apply(clarify)
apply(ind_cases "Var x \<longrightarrow>\<^isub>\<beta> t'")
apply(auto simp add: lam.inject lam.distinct)
apply(force simp add: RED_props)
apply(simp add: id_subs)
apply(subgoal_tac "CR1 \<sigma>")(*3*)
apply(simp add: CR1_def SN_def)
(*3*)
apply(force simp add: RED_props)
done

lemma all_RED: 
 "((\<forall>a \<sigma>. (a,\<sigma>)\<in>set(\<Gamma>)\<longrightarrow>(a\<in>set(dom_sss \<theta>)\<and>\<theta><a>\<in>RED \<sigma>))\<and>\<Gamma>\<turnstile>t:\<tau>) \<longrightarrow> (t[<\<theta>>]\<in>RED \<tau>)"
apply(nominal_induct t rule: lam_induct)
(* Variables *)
apply(force dest: t1_elim)
(* Applications *)
apply(auto dest!: t2_elim)
apply(drule_tac x="a" in spec)
apply(drule_tac x="a" in spec)
apply(drule_tac x="\<tau>\<rightarrow>aa" in spec)
apply(drule_tac x="\<tau>" in spec)
apply(drule_tac x="b" in spec)
apply(drule_tac x="b" in spec)
apply(force)
(* Abstractions *)
apply(drule t3_elim)
apply(simp add: fresh_prod)
apply(auto)
apply(drule_tac x="((ab,\<tau>)#a)" in spec)
apply(drule_tac x="\<tau>'" in spec)
apply(drule_tac x="b" in spec)
apply(simp)
(* HERE *)


done


(* Author: Tobias Nipkow *)

theory Abs_Int2
imports Abs_Int1
begin

instantiation prod :: (order,order) order
begin

definition "less_eq_prod p1 p2 = (fst p1 \<le> fst p2 \<and> snd p1 \<le> snd p2)"
definition "less_prod p1 p2 = (p1 \<le> p2 \<and> \<not> p2 \<le> (p1::'a*'b))"

instance
proof
  case goal1 show ?case by(rule less_prod_def)
next
  case goal2 show ?case by(simp add: less_eq_prod_def)
next
  case goal3 thus ?case unfolding less_eq_prod_def by(metis order_trans)
next
  case goal4 thus ?case by(simp add: less_eq_prod_def)(metis eq_iff surjective_pairing)
qed

end


subsection "Backward Analysis of Expressions"

class lattice = semilattice + semilattice_inf + bot

locale Val_abs1_gamma =
  Gamma where \<gamma> = \<gamma> for \<gamma> :: "'av::lattice \<Rightarrow> val set" +
assumes inter_gamma_subset_gamma_meet:
  "\<gamma> a1 \<inter> \<gamma> a2 \<subseteq> \<gamma>(a1 \<sqinter> a2)"
and gamma_bot[simp]: "\<gamma> \<bottom> = {}"
begin

lemma in_gamma_meet: "x : \<gamma> a1 \<Longrightarrow> x : \<gamma> a2 \<Longrightarrow> x : \<gamma>(a1 \<sqinter> a2)"
by (metis IntI inter_gamma_subset_gamma_meet set_mp)

lemma gamma_meet[simp]: "\<gamma>(a1 \<sqinter> a2) = \<gamma> a1 \<inter> \<gamma> a2"
by(rule equalityI[OF _ inter_gamma_subset_gamma_meet])
  (metis inf_le1 inf_le2 le_inf_iff mono_gamma)

end


locale Val_abs1 =
  Val_abs1_gamma where \<gamma> = \<gamma>
   for \<gamma> :: "'av::lattice \<Rightarrow> val set" +
fixes test_num' :: "val \<Rightarrow> 'av \<Rightarrow> bool"
and filter_plus' :: "'av \<Rightarrow> 'av \<Rightarrow> 'av \<Rightarrow> 'av * 'av"
and filter_less' :: "bool \<Rightarrow> 'av \<Rightarrow> 'av \<Rightarrow> 'av * 'av"
assumes test_num': "test_num' n a = (n : \<gamma> a)"
and filter_plus': "filter_plus' a a1 a2 = (b1,b2) \<Longrightarrow>
  n1 : \<gamma> a1 \<Longrightarrow> n2 : \<gamma> a2 \<Longrightarrow> n1+n2 : \<gamma> a \<Longrightarrow> n1 : \<gamma> b1 \<and> n2 : \<gamma> b2"
and filter_less': "filter_less' (n1<n2) a1 a2 = (b1,b2) \<Longrightarrow>
  n1 : \<gamma> a1 \<Longrightarrow> n2 : \<gamma> a2 \<Longrightarrow> n1 : \<gamma> b1 \<and> n2 : \<gamma> b2"


locale Abs_Int1 =
  Val_abs1 where \<gamma> = \<gamma> for \<gamma> :: "'av::lattice \<Rightarrow> val set"
begin

lemma in_gamma_sup_UpI:
  "S1 \<in> L X \<Longrightarrow> S2 \<in> L X \<Longrightarrow> s : \<gamma>\<^isub>o S1 \<or> s : \<gamma>\<^isub>o S2 \<Longrightarrow> s : \<gamma>\<^isub>o(S1 \<squnion> S2)"
by (metis (hide_lams, no_types) semilatticeL_class.sup_ge1 semilatticeL_class.sup_ge2 mono_gamma_o subsetD)

fun aval'' :: "aexp \<Rightarrow> 'av st option \<Rightarrow> 'av" where
"aval'' e None = \<bottom>" |
"aval'' e (Some sa) = aval' e sa"

lemma aval''_sound: "s : \<gamma>\<^isub>o S \<Longrightarrow> S \<in> L X \<Longrightarrow> vars a \<subseteq> X \<Longrightarrow> aval a s : \<gamma>(aval'' a S)"
by(simp add: L_option_def L_st_def aval'_sound split: option.splits)

subsubsection "Backward analysis"

fun afilter :: "aexp \<Rightarrow> 'av \<Rightarrow> 'av st option \<Rightarrow> 'av st option" where
"afilter (N n) a S = (if test_num' n a then S else None)" |
"afilter (V x) a S = (case S of None \<Rightarrow> None | Some S \<Rightarrow>
  let a' = fun S x \<sqinter> a in
  if a' = \<bottom> then None else Some(update S x a'))" |
"afilter (Plus e1 e2) a S =
 (let (a1,a2) = filter_plus' a (aval'' e1 S) (aval'' e2 S)
  in afilter e1 a1 (afilter e2 a2 S))"

text{* The test for @{const bot} in the @{const V}-case is important: @{const
bot} indicates that a variable has no possible values, i.e.\ that the current
program point is unreachable. But then the abstract state should collapse to
@{const None}. Put differently, we maintain the invariant that in an abstract
state of the form @{term"Some s"}, all variables are mapped to non-@{const
bot} values. Otherwise the (pointwise) sup of two abstract states, one of
which contains @{const bot} values, may produce too large a result, thus
making the analysis less precise. *}


fun bfilter :: "bexp \<Rightarrow> bool \<Rightarrow> 'av st option \<Rightarrow> 'av st option" where
"bfilter (Bc v) res S = (if v=res then S else None)" |
"bfilter (Not b) res S = bfilter b (\<not> res) S" |
"bfilter (And b1 b2) res S =
  (if res then bfilter b1 True (bfilter b2 True S)
   else bfilter b1 False S \<squnion> bfilter b2 False S)" |
"bfilter (Less e1 e2) res S =
  (let (a1,a2) = filter_less' res (aval'' e1 S) (aval'' e2 S)
   in afilter e1 a1 (afilter e2 a2 S))"

lemma afilter_in_L: "S \<in> L X \<Longrightarrow> vars e \<subseteq> X \<Longrightarrow> afilter e a S \<in> L X"
by(induction e arbitrary: a S)
  (auto simp: Let_def L_st_def split: option.splits prod.split)

lemma afilter_sound: "S \<in> L X \<Longrightarrow> vars e \<subseteq> X \<Longrightarrow>
  s : \<gamma>\<^isub>o S \<Longrightarrow> aval e s : \<gamma> a \<Longrightarrow> s : \<gamma>\<^isub>o (afilter e a S)"
proof(induction e arbitrary: a S)
  case N thus ?case by simp (metis test_num')
next
  case (V x)
  obtain S' where "S = Some S'" and "s : \<gamma>\<^isub>s S'" using `s : \<gamma>\<^isub>o S`
    by(auto simp: in_gamma_option_iff)
  moreover hence "s x : \<gamma> (fun S' x)"
    using V(1,2) by(simp add: \<gamma>_st_def L_st_def)
  moreover have "s x : \<gamma> a" using V by simp
  ultimately show ?case using V(3)
    by(simp add: Let_def \<gamma>_st_def)
      (metis mono_gamma emptyE in_gamma_meet gamma_bot subset_empty)
next
  case (Plus e1 e2) thus ?case
    using filter_plus'[OF _ aval''_sound[OF Plus.prems(3)] aval''_sound[OF Plus.prems(3)]]
    by (auto simp: afilter_in_L split: prod.split)
qed

lemma bfilter_in_L: "S \<in> L X \<Longrightarrow> vars b \<subseteq> X \<Longrightarrow> bfilter b bv S \<in> L X"
by(induction b arbitrary: bv S)(auto simp: afilter_in_L split: prod.split)

lemma bfilter_sound: "S \<in> L X \<Longrightarrow> vars b \<subseteq> X \<Longrightarrow>
  s : \<gamma>\<^isub>o S \<Longrightarrow> bv = bval b s \<Longrightarrow> s : \<gamma>\<^isub>o(bfilter b bv S)"
proof(induction b arbitrary: S bv)
  case Bc thus ?case by simp
next
  case (Not b) thus ?case by simp
next
  case (And b1 b2) thus ?case
    by simp (metis And(1) And(2) bfilter_in_L in_gamma_sup_UpI)
next
  case (Less e1 e2) thus ?case
    by(auto split: prod.split)
      (metis (lifting) afilter_in_L afilter_sound aval''_sound filter_less')
qed

(* Interpretation would be nicer but is impossible *)
definition "step' = Step.Step
  (\<lambda>x e S. case S of None \<Rightarrow> None | Some S \<Rightarrow> Some(update S x (aval' e S)))
  (\<lambda>b S. bfilter b True S)"

lemma [code,simp]: "step' S (SKIP {P}) = (SKIP {S})"
by(simp add: step'_def Step.Step.simps)
lemma [code,simp]: "step' S (x ::= e {P}) =
  x ::= e {case S of None \<Rightarrow> None | Some S \<Rightarrow> Some(update S x (aval' e S))}"
by(simp add: step'_def Step.Step.simps)
lemma [code,simp]: "step' S (C1; C2) = step' S C1; step' (post C1) C2"
by(simp add: step'_def Step.Step.simps)
lemma [code,simp]: "step' S (IF b THEN {P1} C1 ELSE {P2} C2 {Q}) =
  (let P1' = bfilter b True S; C1' = step' P1 C1;
       P2' = bfilter b False S; C2' = step' P2 C2
   in IF b THEN {P1'} C1' ELSE {P2'} C2' {post C1 \<squnion> post C2})"
by(simp add: step'_def Step.Step.simps)
lemma [code,simp]: "step' S ({I} WHILE b DO {p} C {Q}) =
   {S \<squnion> post C}
   WHILE b DO {bfilter b True I} step' p C
   {bfilter b False I}"
by(simp add: step'_def Step.Step.simps)

definition AI :: "com \<Rightarrow> 'av st option acom option" where
"AI c = pfp (step' \<top>\<^bsub>vars c\<^esub>) (bot c)"

lemma strip_step'[simp]: "strip(step' S c) = strip c"
by(induct c arbitrary: S) (simp_all add: Let_def)


subsubsection "Soundness"

lemma in_gamma_update:
  "\<lbrakk> s : \<gamma>\<^isub>s S; i : \<gamma> a \<rbrakk> \<Longrightarrow> s(x := i) : \<gamma>\<^isub>s(update S x a)"
by(simp add: \<gamma>_st_def)

lemma step_step': "C \<in> L X \<Longrightarrow> S \<in> L X \<Longrightarrow> step (\<gamma>\<^isub>o S) (\<gamma>\<^isub>c C) \<le> \<gamma>\<^isub>c (step' S C)"
proof(induction C arbitrary: S)
  case SKIP thus ?case by auto
next
  case Assign thus ?case
    by (fastforce simp: L_st_def intro: aval'_sound in_gamma_update split: option.splits)
next
  case Seq thus ?case by auto
next
  case (If b _ C1 _ C2)
  hence 0: "post C1 \<le> post C1 \<squnion> post C2 \<and> post C2 \<le> post C1 \<squnion> post C2"
    by(simp, metis post_in_L sup_ge1 sup_ge2)
  have "vars b \<subseteq> X" using If.prems by simp
  note vars = `S \<in> L X` `vars b \<subseteq> X`
  show ?case using If 0
    by (auto simp: mono_gamma_o bfilter_sound[OF vars] bfilter_in_L[OF vars])
next
  case (While I b)
  hence vars: "I \<in> L X" "vars b \<subseteq> X" by simp_all
  thus ?case using While
    by (auto simp: mono_gamma_o bfilter_sound[OF vars] bfilter_in_L[OF vars])
qed

lemma step'_in_L[simp]: "\<lbrakk> C \<in> L X; S \<in> L X \<rbrakk> \<Longrightarrow> step' S C \<in> L X"
proof(induction C arbitrary: S)
  case Assign thus ?case by(auto simp add: L_option_def L_st_def split: option.splits)
qed (auto simp add: bfilter_in_L)

lemma AI_sound: "AI c = Some C \<Longrightarrow> CS c \<le> \<gamma>\<^isub>c C"
proof(simp add: CS_def AI_def)
  assume 1: "pfp (step' (Top(vars c))) (bot c) = Some C"
  have "C \<in> L(vars c)"
    by(rule pfp_inv[where P = "%C. C \<in> L(vars c)", OF 1 _ bot_in_L])
      (erule step'_in_L[OF _ Top_in_L])
  have pfp': "step' (Top(vars c)) C \<le> C" by(rule pfp_pfp[OF 1])
  have 2: "step (\<gamma>\<^isub>o(Top(vars c))) (\<gamma>\<^isub>c C) \<le> \<gamma>\<^isub>c C"
  proof(rule order_trans)
    show "step (\<gamma>\<^isub>o (Top(vars c))) (\<gamma>\<^isub>c C) \<le>  \<gamma>\<^isub>c (step' (Top(vars c)) C)"
      by(rule step_step'[OF `C \<in> L(vars c)` Top_in_L])
    show "\<gamma>\<^isub>c (step' (Top(vars c)) C) \<le> \<gamma>\<^isub>c C"
      by(rule mono_gamma_c[OF pfp'])
  qed
  have 3: "strip (\<gamma>\<^isub>c C) = c" by(simp add: strip_pfp[OF _ 1])
  have "lfp c (step (\<gamma>\<^isub>o(Top(vars c)))) \<le> \<gamma>\<^isub>c C"
    by(rule lfp_lowerbound[simplified,where f="step (\<gamma>\<^isub>o(Top(vars c)))", OF 3 2])
  thus "lfp c (step UNIV) \<le> \<gamma>\<^isub>c C" by simp
qed

end


subsubsection "Monotonicity"

locale Abs_Int1_mono = Abs_Int1 +
assumes mono_plus': "a1 \<le> b1 \<Longrightarrow> a2 \<le> b2 \<Longrightarrow> plus' a1 a2 \<le> plus' b1 b2"
and mono_filter_plus': "a1 \<le> b1 \<Longrightarrow> a2 \<le> b2 \<Longrightarrow> r \<le> r' \<Longrightarrow>
  filter_plus' r a1 a2 \<le> filter_plus' r' b1 b2"
and mono_filter_less': "a1 \<le> b1 \<Longrightarrow> a2 \<le> b2 \<Longrightarrow>
  filter_less' bv a1 a2 \<le> filter_less' bv b1 b2"
begin

lemma mono_aval':
  "S1 \<le> S2 \<Longrightarrow> S1 \<in> L X \<Longrightarrow> vars e \<subseteq> X \<Longrightarrow> aval' e S1 \<le> aval' e S2"
by(induction e) (auto simp: less_eq_st_def mono_plus' L_st_def)

lemma mono_aval'':
  "S1 \<le> S2 \<Longrightarrow> S1 \<in> L X \<Longrightarrow> vars e \<subseteq> X \<Longrightarrow> aval'' e S1 \<le> aval'' e S2"
apply(cases S1)
 apply simp
apply(cases S2)
 apply simp
by (simp add: mono_aval')

lemma mono_afilter: "S1 \<in> L X \<Longrightarrow> S2 \<in> L X \<Longrightarrow> vars e \<subseteq> X \<Longrightarrow>
  r1 \<le> r2 \<Longrightarrow> S1 \<le> S2 \<Longrightarrow> afilter e r1 S1 \<le> afilter e r2 S2"
apply(induction e arbitrary: r1 r2 S1 S2)
apply(auto simp: test_num' Let_def inf_mono split: option.splits prod.splits)
apply (metis mono_gamma subsetD)
apply (metis inf_mono le_bot mono_fun_L)
apply (metis inf_mono mono_fun_L mono_update)
apply(metis mono_aval'' mono_filter_plus'[simplified less_eq_prod_def] fst_conv snd_conv afilter_in_L)
done

lemma mono_bfilter: "S1 \<in> L X \<Longrightarrow> S2 \<in> L X \<Longrightarrow> vars b \<subseteq> X \<Longrightarrow>
  S1 \<le> S2 \<Longrightarrow> bfilter b bv S1 \<le> bfilter b bv S2"
apply(induction b arbitrary: bv S1 S2)
apply(simp)
apply(simp)
apply simp
apply(metis sup_least order_trans[OF _ sup_ge1] order_trans[OF _ sup_ge2] bfilter_in_L)
apply (simp split: prod.splits)
apply(metis mono_aval'' mono_afilter mono_filter_less'[simplified less_eq_prod_def] fst_conv snd_conv afilter_in_L)
done

theorem mono_step': "S1 \<in> L X \<Longrightarrow> S2 \<in> L X \<Longrightarrow> C1 \<in> L X \<Longrightarrow> C2 \<in> L X \<Longrightarrow>
  S1 \<le> S2 \<Longrightarrow> C1 \<le> C2 \<Longrightarrow> step' S1 C1 \<le> step' S2 C2"
apply(induction C1 C2 arbitrary: S1 S2 rule: less_eq_acom.induct)
apply (auto simp: Let_def mono_bfilter mono_aval' mono_post
  le_sup_disj le_sup_disj[OF  post_in_L post_in_L] bfilter_in_L
            split: option.split)
done

lemma mono_step'_top: "C1 \<in> L X \<Longrightarrow> C2 \<in> L X \<Longrightarrow>
  C1 \<le> C2 \<Longrightarrow> step' (Top X) C1 \<le> step' (Top X) C2"
by (metis Top_in_L mono_step' order_refl)

end

end

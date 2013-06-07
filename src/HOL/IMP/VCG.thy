(* Author: Tobias Nipkow *)

theory VCG imports Hoare begin

subsection "Verification Conditions"

text{* Annotated commands: commands where loops are annotated with
invariants. *}

datatype acom =
  Askip                  ("SKIP") |
  Aassign vname aexp     ("(_ ::= _)" [1000, 61] 61) |
  Aseq   acom acom       ("_;;/ _"  [60, 61] 60) |
  Aif bexp acom acom     ("(IF _/ THEN _/ ELSE _)"  [0, 0, 61] 61) |
  Awhile assn bexp acom  ("({_}/ WHILE _/ DO _)"  [0, 0, 61] 61)


text{* Strip annotations: *}

fun strip :: "acom \<Rightarrow> com" where
"strip SKIP = com.SKIP" |
"strip (x ::= a) = (x ::= a)" |
"strip (c\<^isub>1;; c\<^isub>2) = (strip c\<^isub>1;; strip c\<^isub>2)" |
"strip (IF b THEN c\<^isub>1 ELSE c\<^isub>2) = (IF b THEN strip c\<^isub>1 ELSE strip c\<^isub>2)" |
"strip ({_} WHILE b DO c) = (WHILE b DO strip c)"

text{* Weakest precondition from annotated commands: *}

fun pre :: "acom \<Rightarrow> assn \<Rightarrow> assn" where
"pre SKIP Q = Q" |
"pre (x ::= a) Q = (\<lambda>s. Q(s(x := aval a s)))" |
"pre (c\<^isub>1;; c\<^isub>2) Q = pre c\<^isub>1 (pre c\<^isub>2 Q)" |
"pre (IF b THEN c\<^isub>1 ELSE c\<^isub>2) Q =
  (\<lambda>s. if bval b s then pre c\<^isub>1 Q s else pre c\<^isub>2 Q s)" |
"pre ({I} WHILE b DO c) Q = I"

text{* Verification condition: *}

fun vc :: "acom \<Rightarrow> assn \<Rightarrow> assn" where
"vc SKIP Q = (\<lambda>s. True)" |
"vc (x ::= a) Q = (\<lambda>s. True)" |
"vc (c\<^isub>1;; c\<^isub>2) Q = (\<lambda>s. vc c\<^isub>1 (pre c\<^isub>2 Q) s \<and> vc c\<^isub>2 Q s)" |
"vc (IF b THEN c\<^isub>1 ELSE c\<^isub>2) Q = (\<lambda>s. vc c\<^isub>1 Q s \<and> vc c\<^isub>2 Q s)" |
"vc ({I} WHILE b DO c) Q =
  (\<lambda>s. (I s \<and> \<not> bval b s \<longrightarrow> Q s) \<and>
       (I s \<and> bval b s \<longrightarrow> pre c I s) \<and>
       vc c I s)"


text {* Soundness: *}

lemma vc_sound: "\<forall>s. vc c Q s \<Longrightarrow> \<turnstile> {pre c Q} strip c {Q}"
proof(induction c arbitrary: Q)
  case (Awhile I b c)
  show ?case
  proof(simp, rule While')
    from `\<forall>s. vc (Awhile I b c) Q s`
    have vc: "\<forall>s. vc c I s" and IQ: "\<forall>s. I s \<and> \<not> bval b s \<longrightarrow> Q s" and
         pre: "\<forall>s. I s \<and> bval b s \<longrightarrow> pre c I s" by simp_all
    have "\<turnstile> {pre c I} strip c {I}" by(rule Awhile.IH[OF vc])
    with pre show "\<turnstile> {\<lambda>s. I s \<and> bval b s} strip c {I}"
      by(rule strengthen_pre)
    show "\<forall>s. I s \<and> \<not>bval b s \<longrightarrow> Q s" by(rule IQ)
  qed
qed (auto intro: hoare.conseq)

corollary vc_sound':
  "\<lbrakk> \<forall>s. vc c Q s; \<forall>s. P s \<longrightarrow> pre c Q s \<rbrakk> \<Longrightarrow> \<turnstile> {P} strip c {Q}"
by (metis strengthen_pre vc_sound)


text{* Completeness: *}

lemma pre_mono:
  "\<forall>s. P s \<longrightarrow> P' s \<Longrightarrow> pre c P s \<Longrightarrow> pre c P' s"
proof (induction c arbitrary: P P' s)
  case Aseq thus ?case by simp metis
qed simp_all

lemma vc_mono:
  "\<forall>s. P s \<longrightarrow> P' s \<Longrightarrow> vc c P s \<Longrightarrow> vc c P' s"
proof(induction c arbitrary: P P')
  case Aseq thus ?case by simp (metis pre_mono)
qed simp_all

lemma vc_complete:
 "\<turnstile> {P}c{Q} \<Longrightarrow> \<exists>c'. strip c' = c \<and> (\<forall>s. vc c' Q s) \<and> (\<forall>s. P s \<longrightarrow> pre c' Q s)"
  (is "_ \<Longrightarrow> \<exists>c'. ?G P c Q c'")
proof (induction rule: hoare.induct)
  case Skip
  show ?case (is "\<exists>ac. ?C ac")
  proof show "?C Askip" by simp qed
next
  case (Assign P a x)
  show ?case (is "\<exists>ac. ?C ac")
  proof show "?C(Aassign x a)" by simp qed
next
  case (Seq P c1 Q c2 R)
  from Seq.IH obtain ac1 where ih1: "?G P c1 Q ac1" by blast
  from Seq.IH obtain ac2 where ih2: "?G Q c2 R ac2" by blast
  show ?case (is "\<exists>ac. ?C ac")
  proof
    show "?C(Aseq ac1 ac2)"
      using ih1 ih2 by (fastforce elim!: pre_mono vc_mono)
  qed
next
  case (If P b c1 Q c2)
  from If.IH obtain ac1 where ih1: "?G (\<lambda>s. P s \<and> bval b s) c1 Q ac1"
    by blast
  from If.IH obtain ac2 where ih2: "?G (\<lambda>s. P s \<and> \<not>bval b s) c2 Q ac2"
    by blast
  show ?case (is "\<exists>ac. ?C ac")
  proof
    show "?C(Aif b ac1 ac2)" using ih1 ih2 by simp
  qed
next
  case (While P b c)
  from While.IH obtain ac where ih: "?G (\<lambda>s. P s \<and> bval b s) c P ac" by blast
  show ?case (is "\<exists>ac. ?C ac")
  proof show "?C(Awhile P b ac)" using ih by simp qed
next
  case conseq thus ?case by(fast elim!: pre_mono vc_mono)
qed

end

(*  Title:      HOL/Isar_examples/MultisetOrder.thy
    ID:         $Id$
    Author:     Markus Wenzel

Wellfoundedness proof for the multiset order.
*)

header {* Wellfoundedness of multiset ordering *};

theory MultisetOrder = Multiset:;

text_raw {*
 \footnote{Original tactic script by Tobias Nipkow (see
 \url{http://isabelle.in.tum.de/library/HOL/Induct/Multiset.html}),
 based on a pen-and-paper proof due to Wilfried Buchholz.}\isanewline
*};

(* FIXME move? *)
theorems [induct type: multiset] = multiset_induct;
theorems [induct set: wf] = wf_induct;
theorems [induct set: acc] = acc_induct;


subsection {* A technical lemma *};

lemma less_add: "(N, M0 + {#a#}) : mult1 r ==>
    (EX M. (M, M0) : mult1 r & N = M + {#a#}) |
    (EX K. (ALL b. elem K b --> (b, a) : r) & N = M0 + K)"
  (concl is "?case1 (mult1 r) | ?case2");
proof (unfold mult1_def);
  let ?r = "\\<lambda>K a. ALL b. elem K b --> (b, a) : r";
  let ?R = "\\<lambda>N M. EX a M0 K. M = M0 + {#a#} & N = M0 + K & ?r K a";
  let ?case1 = "?case1 {(N, M). ?R N M}";

  assume "(N, M0 + {#a#}) : {(N, M). ?R N M}";
  hence "EX a' M0' K.
      M0 + {#a#} = M0' + {#a'#} & N = M0' + K & ?r K a'"; by simp;
  thus "?case1 | ?case2";
  proof (elim exE conjE);
    fix a' M0' K;
    assume N: "N = M0' + K" and r: "?r K a'";
    assume "M0 + {#a#} = M0' + {#a'#}";
    hence "M0 = M0' & a = a' |
        (EX K'. M0 = K' + {#a'#} & M0' = K' + {#a#})";
      by (simp only: add_eq_conv_ex);
    thus ?thesis;
    proof (elim disjE conjE exE);
      assume "M0 = M0'" "a = a'";
      with N r; have "?r K a & N = M0 + K"; by simp;
      hence ?case2; ..; thus ?thesis; ..;
    next;
      fix K';
      assume "M0' = K' + {#a#}";
      with N; have n: "N = K' + K + {#a#}"; by (simp add: union_ac);

      assume "M0 = K' + {#a'#}";
      with r; have "?R (K' + K) M0"; by blast;
      with n; have ?case1; by simp; thus ?thesis; ..;
    qed;
  qed;
qed;


subsection {* The key property *};

lemma all_accessible: "wf r ==> ALL M. M : acc (mult1 r)";
proof;
  let ?R = "mult1 r";
  let ?W = "acc ?R";
  {;
    fix M M0 a;
    assume M0: "M0 : ?W"
      and wf_hyp: "ALL b. (b, a) : r --> (ALL M:?W. M + {#b#} : ?W)"
      and acc_hyp: "ALL M. (M, M0) : ?R --> M + {#a#} : ?W";
    have "M0 + {#a#} : ?W";
    proof (rule accI [of "M0 + {#a#}"]);
      fix N;
      assume "(N, M0 + {#a#}) : ?R";
      hence "((EX M. (M, M0) : ?R & N = M + {#a#}) |
          (EX K. (ALL b. elem K b --> (b, a) : r) & N = M0 + K))";
	by (rule less_add);
      thus "N : ?W";
      proof (elim exE disjE conjE);
	fix M; assume "(M, M0) : ?R" and N: "N = M + {#a#}";
	from acc_hyp; have "(M, M0) : ?R --> M + {#a#} : ?W"; ..;
	hence "M + {#a#} : ?W"; ..;
	thus "N : ?W"; by (simp only: N);
      next;
	fix K;
	assume N: "N = M0 + K";
	assume "ALL b. elem K b --> (b, a) : r";
	have "?this --> M0 + K : ?W" (is "?P K");
	proof (induct K);
	  from M0; have "M0 + {#} : ?W"; by simp;
	  thus "?P {#}"; ..;

	  fix K x; assume hyp: "?P K";
	  show "?P (K + {#x#})";
	  proof;
	    assume a: "ALL b. elem (K + {#x#}) b --> (b, a) : r";
	    hence "(x, a) : r"; by simp;
	    with wf_hyp; have b: "ALL M:?W. M + {#x#} : ?W"; by blast;

	    from a hyp; have "M0 + K : ?W"; by simp;
	    with b; have "(M0 + K) + {#x#} : ?W"; ..;
	    thus "M0 + (K + {#x#}) : ?W"; by (simp only: union_assoc);
	  qed;
	qed;
	hence "M0 + K : ?W"; ..;
	thus "N : ?W"; by (simp only: N);
      qed;
    qed;
  }; note tedious_reasoning = this;

  assume wf: "wf r";
  fix M;
  show "M : ?W";
  proof (induct M);
    show "{#} : ?W";
    proof (rule accI);
      fix b; assume "(b, {#}) : ?R";
      with not_less_empty; show "b : ?W"; by contradiction;
    qed;

    fix M a; assume "M : ?W";
    from wf; have "ALL M:?W. M + {#a#} : ?W";
    proof induct;
      fix a;
      assume "ALL b. (b, a) : r --> (ALL M:?W. M + {#b#} : ?W)";
      show "ALL M:?W. M + {#a#} : ?W";
      proof;
	fix M; assume "M : ?W";
	thus "M + {#a#} : ?W";
          by (rule acc_induct) (rule tedious_reasoning);
      qed;
    qed;
    thus "M + {#a#} : ?W"; ..;
  qed;
qed;


subsection {* Main result *};

theorem wf_mult1: "wf r ==> wf (mult1 r)";
  by (rule acc_wfI, rule all_accessible);

theorem wf_mult: "wf r ==> wf (mult r)";
  by (unfold mult_def, rule wf_trancl, rule wf_mult1);

end;

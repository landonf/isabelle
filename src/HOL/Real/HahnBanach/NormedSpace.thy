(*  Title:      HOL/Real/HahnBanach/NormedSpace.thy
    ID:         $Id$
    Author:     Gertrud Bauer, TU Munich
*)

header {* Normed vector spaces *};

theory NormedSpace =  Subspace:;



subsection {* Quasinorms *};

text{* A \emph{quasinorm} $\norm{\cdot}$ is a  function on a real vector space into the reals 
that has the following properties: *};

constdefs
  is_quasinorm :: "['a::{plus, minus} set, 'a => real] => bool"
  "is_quasinorm V norm == ALL x: V. ALL y:V. ALL a. 
        0r <= norm x 
      & norm (a <*> x) = (rabs a) * (norm x)
      & norm (x + y) <= norm x + norm y";

lemma is_quasinormI [intro]: 
  "[| !! x y a. [| x:V; y:V|] ==>  0r <= norm x;
  !! x a. x:V ==> norm (a <*> x) = (rabs a) * (norm x);
  !! x y. [|x:V; y:V |] ==> norm (x + y) <= norm x + norm y |] 
  ==> is_quasinorm V norm";
  by (unfold is_quasinorm_def, force);

lemma quasinorm_ge_zero [intro!!]:
  "[| is_quasinorm V norm; x:V |] ==> 0r <= norm x";
  by (unfold is_quasinorm_def, force);

lemma quasinorm_mult_distrib: 
  "[| is_quasinorm V norm; x:V |] 
  ==> norm (a <*> x) = (rabs a) * (norm x)";
  by (unfold is_quasinorm_def, force);

lemma quasinorm_triangle_ineq: 
  "[| is_quasinorm V norm; x:V; y:V |] 
  ==> norm (x + y) <= norm x + norm y";
  by (unfold is_quasinorm_def, force);

lemma quasinorm_diff_triangle_ineq: 
  "[| is_quasinorm V norm; x:V; y:V; is_vectorspace V |] 
  ==> norm (x - y) <= norm x + norm y";
proof -;
  assume "is_quasinorm V norm" "x:V" "y:V" "is_vectorspace V";
  have "norm (x - y) = norm (x + - 1r <*> y)";  
    by (simp! add: diff_eq2 negate_eq2);
  also; have "... <= norm x + norm  (- 1r <*> y)"; 
    by (simp! add: quasinorm_triangle_ineq);
  also; have "norm (- 1r <*> y) = rabs (- 1r) * norm y"; 
    by (rule quasinorm_mult_distrib);
  also; have "rabs (- 1r) = 1r"; by (rule rabs_minus_one);
  finally; show "norm (x - y) <= norm x + norm y"; by simp;
qed;

lemma quasinorm_minus: 
  "[| is_quasinorm V norm; x:V; is_vectorspace V |] 
  ==> norm (- x) = norm x";
proof -;
  assume "is_quasinorm V norm" "x:V" "is_vectorspace V";
  have "norm (- x) = norm (-1r <*> x)"; by (simp! only: negate_eq1);
  also; have "... = rabs (-1r) * norm x"; 
    by (rule quasinorm_mult_distrib);
  also; have "rabs (- 1r) = 1r"; by (rule rabs_minus_one);
  finally; show "norm (- x) = norm x"; by simp;
qed;


subsection {* Norms *};

text{* A \emph{norm} $\norm{\cdot}$ is a quasinorm that maps only the
$\zero$ vector to $0$. *};

constdefs
  is_norm :: "['a::{minus, plus} set, 'a => real] => bool"
  "is_norm V norm == ALL x: V.  is_quasinorm V norm 
      & (norm x = 0r) = (x = <0>)";

lemma is_normI [intro]: 
  "ALL x: V.  is_quasinorm V norm  & (norm x = 0r) = (x = <0>) 
  ==> is_norm V norm"; by (simp only: is_norm_def);

lemma norm_is_quasinorm [intro!!]: 
  "[| is_norm V norm; x:V |] ==> is_quasinorm V norm";
  by (unfold is_norm_def, force);

lemma norm_zero_iff: 
  "[| is_norm V norm; x:V |] ==> (norm x = 0r) = (x = <0>)";
  by (unfold is_norm_def, force);

lemma norm_ge_zero [intro!!]:
  "[|is_norm V norm; x:V |] ==> 0r <= norm x";
  by (unfold is_norm_def is_quasinorm_def, force);


subsection {* Normed vector spaces *};

text{* A vector space together with a norm is called
a \emph{normed space}. *};

constdefs
  is_normed_vectorspace :: 
  "['a::{plus, minus} set, 'a => real] => bool"
  "is_normed_vectorspace V norm ==
      is_vectorspace V &
      is_norm V norm";

lemma normed_vsI [intro]: 
  "[| is_vectorspace V; is_norm V norm |] 
  ==> is_normed_vectorspace V norm";
  by (unfold is_normed_vectorspace_def) blast; 

lemma normed_vs_vs [intro!!]: 
  "is_normed_vectorspace V norm ==> is_vectorspace V";
  by (unfold is_normed_vectorspace_def) force;

lemma normed_vs_norm [intro!!]: 
  "is_normed_vectorspace V norm ==> is_norm V norm";
  by (unfold is_normed_vectorspace_def, elim conjE);

lemma normed_vs_norm_ge_zero [intro!!]: 
  "[| is_normed_vectorspace V norm; x:V |] ==> 0r <= norm x";
  by (unfold is_normed_vectorspace_def, rule, elim conjE);

lemma normed_vs_norm_gt_zero [intro!!]: 
  "[| is_normed_vectorspace V norm; x:V; x ~= <0> |] ==> 0r < norm x";
proof (unfold is_normed_vectorspace_def, elim conjE);
  assume "x : V" "x ~= <0>" "is_vectorspace V" "is_norm V norm";
  have "0r <= norm x"; ..;
  also; have "0r ~= norm x";
  proof;
    presume "norm x = 0r";
    also; have "?this = (x = <0>)"; by (rule norm_zero_iff);
    finally; have "x = <0>"; .;
    thus "False"; by contradiction;
  qed (rule sym);
  finally; show "0r < norm x"; .;
qed;

lemma normed_vs_norm_mult_distrib [intro!!]: 
  "[| is_normed_vectorspace V norm; x:V |] 
  ==> norm (a <*> x) = (rabs a) * (norm x)";
  by (rule quasinorm_mult_distrib, rule norm_is_quasinorm, 
      rule normed_vs_norm);

lemma normed_vs_norm_triangle_ineq [intro!!]: 
  "[| is_normed_vectorspace V norm; x:V; y:V |] 
  ==> norm (x + y) <= norm x + norm y";
  by (rule quasinorm_triangle_ineq, rule norm_is_quasinorm, 
     rule normed_vs_norm);

text{* Any subspace of a normed vector space is again a 
normed vectorspace.*};

lemma subspace_normed_vs [intro!!]: 
  "[| is_subspace F E; is_vectorspace E; 
  is_normed_vectorspace E norm |] ==> is_normed_vectorspace F norm";
proof (rule normed_vsI);
  assume "is_subspace F E" "is_vectorspace E" 
         "is_normed_vectorspace E norm";
  show "is_vectorspace F"; ..;
  show "is_norm F norm"; 
  proof (intro is_normI ballI conjI);
    show "is_quasinorm F norm"; 
    proof;
      fix x y a; presume "x : E";
      show "0r <= norm x"; ..;
      show "norm (a <*> x) = rabs a * norm x"; ..;
      presume "y : E";
      show "norm (x + y) <= norm x + norm y"; ..;
    qed (simp!)+;

    fix x; assume "x : F";
    show "(norm x = 0r) = (x = <0>)"; 
    proof (rule norm_zero_iff);
      show "is_norm E norm"; ..;
    qed (simp!);
  qed;
qed;

end;
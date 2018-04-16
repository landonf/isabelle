(*  Title:      HOL/Analysis/Determinants.thy
    Author:     Amine Chaieb, University of Cambridge
*)

section \<open>Traces, Determinant of square matrices and some properties\<close>

theory Determinants
imports
  Cartesian_Euclidean_Space
  "HOL-Library.Permutations"
begin

subsection \<open>Trace\<close>

definition trace :: "'a::semiring_1^'n^'n \<Rightarrow> 'a"
  where "trace A = sum (\<lambda>i. ((A$i)$i)) (UNIV::'n set)"

lemma trace_0: "trace (mat 0) = 0"
  by (simp add: trace_def mat_def)

lemma trace_I: "trace (mat 1 :: 'a::semiring_1^'n^'n) = of_nat(CARD('n))"
  by (simp add: trace_def mat_def)

lemma trace_add: "trace ((A::'a::comm_semiring_1^'n^'n) + B) = trace A + trace B"
  by (simp add: trace_def sum.distrib)

lemma trace_sub: "trace ((A::'a::comm_ring_1^'n^'n) - B) = trace A - trace B"
  by (simp add: trace_def sum_subtractf)

lemma trace_mul_sym: "trace ((A::'a::comm_semiring_1^'n^'m) ** B) = trace (B**A)"
  apply (simp add: trace_def matrix_matrix_mult_def)
  apply (subst sum.swap)
  apply (simp add: mult.commute)
  done

text \<open>Definition of determinant.\<close>

definition det:: "'a::comm_ring_1^'n^'n \<Rightarrow> 'a" where
  "det A =
    sum (\<lambda>p. of_int (sign p) * prod (\<lambda>i. A$i$p i) (UNIV :: 'n set))
      {p. p permutes (UNIV :: 'n set)}"

text \<open>A few general lemmas we need below.\<close>

lemma prod_permute:
  assumes p: "p permutes S"
  shows "prod f S = prod (f \<circ> p) S"
  using assms by (fact prod.permute)

lemma product_permute_nat_interval:
  fixes m n :: nat
  shows "p permutes {m..n} \<Longrightarrow> prod f {m..n} = prod (f \<circ> p) {m..n}"
  by (blast intro!: prod_permute)

text \<open>Basic determinant properties.\<close>

lemma det_transpose [simp]: "det (transpose A) = det (A::'a::comm_ring_1 ^'n^'n)"
proof -
  let ?di = "\<lambda>A i j. A$i$j"
  let ?U = "(UNIV :: 'n set)"
  have fU: "finite ?U" by simp
  {
    fix p
    assume p: "p \<in> {p. p permutes ?U}"
    from p have pU: "p permutes ?U"
      by blast
    have sth: "sign (inv p) = sign p"
      by (metis sign_inverse fU p mem_Collect_eq permutation_permutes)
    from permutes_inj[OF pU]
    have pi: "inj_on p ?U"
      by (blast intro: subset_inj_on)
    from permutes_image[OF pU]
    have "prod (\<lambda>i. ?di (transpose A) i (inv p i)) ?U =
      prod (\<lambda>i. ?di (transpose A) i (inv p i)) (p ` ?U)"
      by simp
    also have "\<dots> = prod ((\<lambda>i. ?di (transpose A) i (inv p i)) \<circ> p) ?U"
      unfolding prod.reindex[OF pi] ..
    also have "\<dots> = prod (\<lambda>i. ?di A i (p i)) ?U"
    proof -
      {
        fix i
        assume i: "i \<in> ?U"
        from i permutes_inv_o[OF pU] permutes_in_image[OF pU]
        have "((\<lambda>i. ?di (transpose A) i (inv p i)) \<circ> p) i = ?di A i (p i)"
          unfolding transpose_def by (simp add: fun_eq_iff)
      }
      then show "prod ((\<lambda>i. ?di (transpose A) i (inv p i)) \<circ> p) ?U =
        prod (\<lambda>i. ?di A i (p i)) ?U"
        by (auto intro: prod.cong)
    qed
    finally have "of_int (sign (inv p)) * (prod (\<lambda>i. ?di (transpose A) i (inv p i)) ?U) =
      of_int (sign p) * (prod (\<lambda>i. ?di A i (p i)) ?U)"
      using sth by simp
  }
  then show ?thesis
    unfolding det_def
    apply (subst sum_permutations_inverse)
    apply (rule sum.cong)
    apply (rule refl)
    apply blast
    done
qed

lemma det_lowerdiagonal:
  fixes A :: "'a::comm_ring_1^('n::{finite,wellorder})^('n::{finite,wellorder})"
  assumes ld: "\<And>i j. i < j \<Longrightarrow> A$i$j = 0"
  shows "det A = prod (\<lambda>i. A$i$i) (UNIV:: 'n set)"
proof -
  let ?U = "UNIV:: 'n set"
  let ?PU = "{p. p permutes ?U}"
  let ?pp = "\<lambda>p. of_int (sign p) * prod (\<lambda>i. A$i$p i) (UNIV :: 'n set)"
  have fU: "finite ?U"
    by simp
  from finite_permutations[OF fU] have fPU: "finite ?PU" .
  have id0: "{id} \<subseteq> ?PU"
    by (auto simp add: permutes_id)
  {
    fix p
    assume p: "p \<in> ?PU - {id}"
    from p have pU: "p permutes ?U" and pid: "p \<noteq> id"
      by blast+
    from permutes_natset_le[OF pU] pid obtain i where i: "p i > i"
      by (metis not_le)
    from ld[OF i] have ex:"\<exists>i \<in> ?U. A$i$p i = 0"
      by blast
    from prod_zero[OF fU ex] have "?pp p = 0"
      by simp
  }
  then have p0: "\<forall>p \<in> ?PU - {id}. ?pp p = 0"
    by blast
  from sum.mono_neutral_cong_left[OF fPU id0 p0] show ?thesis
    unfolding det_def by (simp add: sign_id)
qed

lemma det_upperdiagonal:
  fixes A :: "'a::comm_ring_1^'n::{finite,wellorder}^'n::{finite,wellorder}"
  assumes ld: "\<And>i j. i > j \<Longrightarrow> A$i$j = 0"
  shows "det A = prod (\<lambda>i. A$i$i) (UNIV:: 'n set)"
proof -
  let ?U = "UNIV:: 'n set"
  let ?PU = "{p. p permutes ?U}"
  let ?pp = "(\<lambda>p. of_int (sign p) * prod (\<lambda>i. A$i$p i) (UNIV :: 'n set))"
  have fU: "finite ?U"
    by simp
  from finite_permutations[OF fU] have fPU: "finite ?PU" .
  have id0: "{id} \<subseteq> ?PU"
    by (auto simp add: permutes_id)
  {
    fix p
    assume p: "p \<in> ?PU - {id}"
    from p have pU: "p permutes ?U" and pid: "p \<noteq> id"
      by blast+
    from permutes_natset_ge[OF pU] pid obtain i where i: "p i < i"
      by (metis not_le)
    from ld[OF i] have ex:"\<exists>i \<in> ?U. A$i$p i = 0"
      by blast
    from prod_zero[OF fU ex] have "?pp p = 0"
      by simp
  }
  then have p0: "\<forall>p \<in> ?PU -{id}. ?pp p = 0"
    by blast
  from sum.mono_neutral_cong_left[OF fPU id0 p0] show ?thesis
    unfolding det_def by (simp add: sign_id)
qed

lemma det_diagonal:
  fixes A :: "'a::comm_ring_1^'n^'n"
  assumes ld: "\<And>i j. i \<noteq> j \<Longrightarrow> A$i$j = 0"
  shows "det A = prod (\<lambda>i. A$i$i) (UNIV::'n set)"
proof -
  let ?U = "UNIV:: 'n set"
  let ?PU = "{p. p permutes ?U}"
  let ?pp = "\<lambda>p. of_int (sign p) * prod (\<lambda>i. A$i$p i) (UNIV :: 'n set)"
  have fU: "finite ?U" by simp
  from finite_permutations[OF fU] have fPU: "finite ?PU" .
  have id0: "{id} \<subseteq> ?PU"
    by (auto simp add: permutes_id)
  {
    fix p
    assume p: "p \<in> ?PU - {id}"
    then have "p \<noteq> id"
      by simp
    then obtain i where i: "p i \<noteq> i"
      unfolding fun_eq_iff by auto
    from ld [OF i [symmetric]] have ex:"\<exists>i \<in> ?U. A$i$p i = 0"
      by blast
    from prod_zero [OF fU ex] have "?pp p = 0"
      by simp
  }
  then have p0: "\<forall>p \<in> ?PU - {id}. ?pp p = 0"
    by blast
  from sum.mono_neutral_cong_left[OF fPU id0 p0] show ?thesis
    unfolding det_def by (simp add: sign_id)
qed

lemma det_I [simp]: "det (mat 1 :: 'a::comm_ring_1^'n^'n) = 1"
  by (simp add: det_diagonal mat_def)

lemma det_0 [simp]: "det (mat 0 :: 'a::comm_ring_1^'n^'n) = 0"
  by (simp add: det_def prod_zero power_0_left)

lemma det_permute_rows:
  fixes A :: "'a::comm_ring_1^'n^'n"
  assumes p: "p permutes (UNIV :: 'n::finite set)"
  shows "det (\<chi> i. A$p i :: 'a^'n^'n) = of_int (sign p) * det A"
  apply (simp add: det_def sum_distrib_left mult.assoc[symmetric])
  apply (subst sum_permutations_compose_right[OF p])
proof (rule sum.cong)
  let ?U = "UNIV :: 'n set"
  let ?PU = "{p. p permutes ?U}"
  fix q
  assume qPU: "q \<in> ?PU"
  have fU: "finite ?U"
    by simp
  from qPU have q: "q permutes ?U"
    by blast
  from p q have pp: "permutation p" and qp: "permutation q"
    by (metis fU permutation_permutes)+
  from permutes_inv[OF p] have ip: "inv p permutes ?U" .
  have "prod (\<lambda>i. A$p i$ (q \<circ> p) i) ?U = prod ((\<lambda>i. A$p i$(q \<circ> p) i) \<circ> inv p) ?U"
    by (simp only: prod_permute[OF ip, symmetric])
  also have "\<dots> = prod (\<lambda>i. A $ (p \<circ> inv p) i $ (q \<circ> (p \<circ> inv p)) i) ?U"
    by (simp only: o_def)
  also have "\<dots> = prod (\<lambda>i. A$i$q i) ?U"
    by (simp only: o_def permutes_inverses[OF p])
  finally have thp: "prod (\<lambda>i. A$p i$ (q \<circ> p) i) ?U = prod (\<lambda>i. A$i$q i) ?U"
    by blast
  show "of_int (sign (q \<circ> p)) * prod (\<lambda>i. A$ p i$ (q \<circ> p) i) ?U =
    of_int (sign p) * of_int (sign q) * prod (\<lambda>i. A$i$q i) ?U"
    by (simp only: thp sign_compose[OF qp pp] mult.commute of_int_mult)
qed rule

lemma det_permute_columns:
  fixes A :: "'a::comm_ring_1^'n^'n"
  assumes p: "p permutes (UNIV :: 'n set)"
  shows "det(\<chi> i j. A$i$ p j :: 'a^'n^'n) = of_int (sign p) * det A"
proof -
  let ?Ap = "\<chi> i j. A$i$ p j :: 'a^'n^'n"
  let ?At = "transpose A"
  have "of_int (sign p) * det A = det (transpose (\<chi> i. transpose A $ p i))"
    unfolding det_permute_rows[OF p, of ?At] det_transpose ..
  moreover
  have "?Ap = transpose (\<chi> i. transpose A $ p i)"
    by (simp add: transpose_def vec_eq_iff)
  ultimately show ?thesis
    by simp
qed

lemma det_identical_rows:
  fixes A :: "'a::linordered_idom^'n^'n"
  assumes ij: "i \<noteq> j"
    and r: "row i A = row j A"
  shows "det A = 0"
proof-
  have tha: "\<And>(a::'a) b. a = b \<Longrightarrow> b = - a \<Longrightarrow> a = 0"
    by simp
  have th1: "of_int (-1) = - 1" by simp
  let ?p = "Fun.swap i j id"
  let ?A = "\<chi> i. A $ ?p i"
  from r have "A = ?A" by (simp add: vec_eq_iff row_def Fun.swap_def)
  then have "det A = det ?A" by simp
  moreover have "det A = - det ?A"
    by (simp add: det_permute_rows[OF permutes_swap_id] sign_swap_id ij th1)
  ultimately show "det A = 0" by (metis tha)
qed

lemma det_identical_columns:
  fixes A :: "'a::linordered_idom^'n^'n"
  assumes ij: "i \<noteq> j"
    and r: "column i A = column j A"
  shows "det A = 0"
  apply (subst det_transpose[symmetric])
  apply (rule det_identical_rows[OF ij])
  apply (metis row_transpose r)
  done

lemma det_zero_row:
  fixes A :: "'a::{idom, ring_char_0}^'n^'n"
  assumes r: "row i A = 0"
  shows "det A = 0"
  using r
  apply (simp add: row_def det_def vec_eq_iff)
  apply (rule sum.neutral)
  apply (auto simp: sign_nz)
  done

lemma det_zero_column:
  fixes A :: "'a::{idom,ring_char_0}^'n^'n"
  assumes r: "column i A = 0"
  shows "det A = 0"
  apply (subst det_transpose[symmetric])
  apply (rule det_zero_row [of i])
  apply (metis row_transpose r)
  done

lemma det_row_add:
  fixes a b c :: "'n::finite \<Rightarrow> _ ^ 'n"
  shows "det((\<chi> i. if i = k then a i + b i else c i)::'a::comm_ring_1^'n^'n) =
    det((\<chi> i. if i = k then a i else c i)::'a::comm_ring_1^'n^'n) +
    det((\<chi> i. if i = k then b i else c i)::'a::comm_ring_1^'n^'n)"
  unfolding det_def vec_lambda_beta sum.distrib[symmetric]
proof (rule sum.cong)
  let ?U = "UNIV :: 'n set"
  let ?pU = "{p. p permutes ?U}"
  let ?f = "(\<lambda>i. if i = k then a i + b i else c i)::'n \<Rightarrow> 'a::comm_ring_1^'n"
  let ?g = "(\<lambda> i. if i = k then a i else c i)::'n \<Rightarrow> 'a::comm_ring_1^'n"
  let ?h = "(\<lambda> i. if i = k then b i else c i)::'n \<Rightarrow> 'a::comm_ring_1^'n"
  fix p
  assume p: "p \<in> ?pU"
  let ?Uk = "?U - {k}"
  from p have pU: "p permutes ?U"
    by blast
  have kU: "?U = insert k ?Uk"
    by blast
  {
    fix j
    assume j: "j \<in> ?Uk"
    from j have "?f j $ p j = ?g j $ p j" and "?f j $ p j= ?h j $ p j"
      by simp_all
  }
  then have th1: "prod (\<lambda>i. ?f i $ p i) ?Uk = prod (\<lambda>i. ?g i $ p i) ?Uk"
    and th2: "prod (\<lambda>i. ?f i $ p i) ?Uk = prod (\<lambda>i. ?h i $ p i) ?Uk"
    apply -
    apply (rule prod.cong, simp_all)+
    done
  have th3: "finite ?Uk" "k \<notin> ?Uk"
    by auto
  have "prod (\<lambda>i. ?f i $ p i) ?U = prod (\<lambda>i. ?f i $ p i) (insert k ?Uk)"
    unfolding kU[symmetric] ..
  also have "\<dots> = ?f k $ p k * prod (\<lambda>i. ?f i $ p i) ?Uk"
    apply (rule prod.insert)
    apply simp
    apply blast
    done
  also have "\<dots> = (a k $ p k * prod (\<lambda>i. ?f i $ p i) ?Uk) + (b k$ p k * prod (\<lambda>i. ?f i $ p i) ?Uk)"
    by (simp add: field_simps)
  also have "\<dots> = (a k $ p k * prod (\<lambda>i. ?g i $ p i) ?Uk) + (b k$ p k * prod (\<lambda>i. ?h i $ p i) ?Uk)"
    by (metis th1 th2)
  also have "\<dots> = prod (\<lambda>i. ?g i $ p i) (insert k ?Uk) + prod (\<lambda>i. ?h i $ p i) (insert k ?Uk)"
    unfolding  prod.insert[OF th3] by simp
  finally have "prod (\<lambda>i. ?f i $ p i) ?U = prod (\<lambda>i. ?g i $ p i) ?U + prod (\<lambda>i. ?h i $ p i) ?U"
    unfolding kU[symmetric] .
  then show "of_int (sign p) * prod (\<lambda>i. ?f i $ p i) ?U =
    of_int (sign p) * prod (\<lambda>i. ?g i $ p i) ?U + of_int (sign p) * prod (\<lambda>i. ?h i $ p i) ?U"
    by (simp add: field_simps)
qed rule

lemma det_row_mul:
  fixes a b :: "'n::finite \<Rightarrow> _ ^ 'n"
  shows "det((\<chi> i. if i = k then c *s a i else b i)::'a::comm_ring_1^'n^'n) =
    c * det((\<chi> i. if i = k then a i else b i)::'a::comm_ring_1^'n^'n)"
  unfolding det_def vec_lambda_beta sum_distrib_left
proof (rule sum.cong)
  let ?U = "UNIV :: 'n set"
  let ?pU = "{p. p permutes ?U}"
  let ?f = "(\<lambda>i. if i = k then c*s a i else b i)::'n \<Rightarrow> 'a::comm_ring_1^'n"
  let ?g = "(\<lambda> i. if i = k then a i else b i)::'n \<Rightarrow> 'a::comm_ring_1^'n"
  fix p
  assume p: "p \<in> ?pU"
  let ?Uk = "?U - {k}"
  from p have pU: "p permutes ?U"
    by blast
  have kU: "?U = insert k ?Uk"
    by blast
  {
    fix j
    assume j: "j \<in> ?Uk"
    from j have "?f j $ p j = ?g j $ p j"
      by simp
  }
  then have th1: "prod (\<lambda>i. ?f i $ p i) ?Uk = prod (\<lambda>i. ?g i $ p i) ?Uk"
    apply -
    apply (rule prod.cong)
    apply simp_all
    done
  have th3: "finite ?Uk" "k \<notin> ?Uk"
    by auto
  have "prod (\<lambda>i. ?f i $ p i) ?U = prod (\<lambda>i. ?f i $ p i) (insert k ?Uk)"
    unfolding kU[symmetric] ..
  also have "\<dots> = ?f k $ p k  * prod (\<lambda>i. ?f i $ p i) ?Uk"
    apply (rule prod.insert)
    apply simp
    apply blast
    done
  also have "\<dots> = (c*s a k) $ p k * prod (\<lambda>i. ?f i $ p i) ?Uk"
    by (simp add: field_simps)
  also have "\<dots> = c* (a k $ p k * prod (\<lambda>i. ?g i $ p i) ?Uk)"
    unfolding th1 by (simp add: ac_simps)
  also have "\<dots> = c* (prod (\<lambda>i. ?g i $ p i) (insert k ?Uk))"
    unfolding prod.insert[OF th3] by simp
  finally have "prod (\<lambda>i. ?f i $ p i) ?U = c* (prod (\<lambda>i. ?g i $ p i) ?U)"
    unfolding kU[symmetric] .
  then show "of_int (sign p) * prod (\<lambda>i. ?f i $ p i) ?U =
    c * (of_int (sign p) * prod (\<lambda>i. ?g i $ p i) ?U)"
    by (simp add: field_simps)
qed rule

lemma det_row_0:
  fixes b :: "'n::finite \<Rightarrow> _ ^ 'n"
  shows "det((\<chi> i. if i = k then 0 else b i)::'a::comm_ring_1^'n^'n) = 0"
  using det_row_mul[of k 0 "\<lambda>i. 1" b]
  apply simp
  apply (simp only: vector_smult_lzero)
  done

lemma det_row_operation:
  fixes A :: "'a::linordered_idom^'n^'n"
  assumes ij: "i \<noteq> j"
  shows "det (\<chi> k. if k = i then row i A + c *s row j A else row k A) = det A"
proof -
  let ?Z = "(\<chi> k. if k = i then row j A else row k A) :: 'a ^'n^'n"
  have th: "row i ?Z = row j ?Z" by (vector row_def)
  have th2: "((\<chi> k. if k = i then row i A else row k A) :: 'a^'n^'n) = A"
    by (vector row_def)
  show ?thesis
    unfolding det_row_add [of i] det_row_mul[of i] det_identical_rows[OF ij th] th2
    by simp
qed

lemma det_row_span:
  fixes A :: "real^'n^'n"
  assumes x: "x \<in> span {row j A |j. j \<noteq> i}"
  shows "det (\<chi> k. if k = i then row i A + x else row k A) = det A"
proof -
  let ?U = "UNIV :: 'n set"
  let ?S = "{row j A |j. j \<noteq> i}"
  let ?d = "\<lambda>x. det (\<chi> k. if k = i then x else row k A)"
  let ?P = "\<lambda>x. ?d (row i A + x) = det A"
  {
    fix k
    have "(if k = i then row i A + 0 else row k A) = row k A"
      by simp
  }
  then have P0: "?P 0"
    apply -
    apply (rule cong[of det, OF refl])
    apply (vector row_def)
    done
  moreover
  {
    fix c z y
    assume zS: "z \<in> ?S" and Py: "?P y"
    from zS obtain j where j: "z = row j A" "i \<noteq> j"
      by blast
    let ?w = "row i A + y"
    have th0: "row i A + (c*s z + y) = ?w + c*s z"
      by vector
    have thz: "?d z = 0"
      apply (rule det_identical_rows[OF j(2)])
      using j
      apply (vector row_def)
      done
    have "?d (row i A + (c*s z + y)) = ?d (?w + c*s z)"
      unfolding th0 ..
    then have "?P (c*s z + y)"
      unfolding thz Py det_row_mul[of i] det_row_add[of i]
      by simp
  }
  ultimately show ?thesis
    apply -
    apply (rule span_induct_alt[of ?P ?S, OF P0, folded scalar_mult_eq_scaleR])
    apply blast
    apply (rule x)
    done
qed

lemma matrix_id [simp]: "det (matrix id) = 1"
  by (simp add: matrix_id_mat_1)

lemma det_matrix_scaleR [simp]: "det (matrix ((( *\<^sub>R) r)) :: real^'n^'n) = r ^ CARD('n::finite)"
  apply (subst det_diagonal)
   apply (auto simp: matrix_def mat_def prod_constant)
  apply (simp add: cart_eq_inner_axis inner_axis_axis)
  done

text \<open>
  May as well do this, though it's a bit unsatisfactory since it ignores
  exact duplicates by considering the rows/columns as a set.
\<close>

lemma det_dependent_rows:
  fixes A:: "real^'n^'n"
  assumes d: "dependent (rows A)"
  shows "det A = 0"
proof -
  let ?U = "UNIV :: 'n set"
  from d obtain i where i: "row i A \<in> span (rows A - {row i A})"
    unfolding dependent_def rows_def by blast
  {
    fix j k
    assume jk: "j \<noteq> k" and c: "row j A = row k A"
    from det_identical_rows[OF jk c] have ?thesis .
  }
  moreover
  {
    assume H: "\<And> i j. i \<noteq> j \<Longrightarrow> row i A \<noteq> row j A"
    have th0: "- row i A \<in> span {row j A|j. j \<noteq> i}"
      apply (rule span_neg)
      apply (rule set_rev_mp)
      apply (rule i)
      apply (rule span_mono)
      using H i
      apply (auto simp add: rows_def)
      done
    from det_row_span[OF th0]
    have "det A = det (\<chi> k. if k = i then 0 *s 1 else row k A)"
      unfolding right_minus vector_smult_lzero ..
    with det_row_mul[of i "0::real" "\<lambda>i. 1"]
    have "det A = 0" by simp
  }
  ultimately show ?thesis by blast
qed

lemma det_dependent_columns:
  assumes d: "dependent (columns (A::real^'n^'n))"
  shows "det A = 0"
  by (metis d det_dependent_rows rows_transpose det_transpose)

text \<open>Multilinearity and the multiplication formula.\<close>

lemma Cart_lambda_cong: "(\<And>x. f x = g x) \<Longrightarrow> (vec_lambda f::'a^'n) = (vec_lambda g :: 'a^'n)"
  by (rule iffD1[OF vec_lambda_unique]) vector

lemma det_linear_row_sum:
  assumes fS: "finite S"
  shows "det ((\<chi> i. if i = k then sum (a i) S else c i)::'a::comm_ring_1^'n^'n) =
    sum (\<lambda>j. det ((\<chi> i. if i = k then a  i j else c i)::'a^'n^'n)) S"
proof (induct rule: finite_induct[OF fS])
  case 1
  then show ?case
    apply simp
    unfolding sum.empty det_row_0[of k]
    apply rule
    done
next
  case (2 x F)
  then show ?case
    by (simp add: det_row_add cong del: if_weak_cong)
qed

lemma finite_bounded_functions:
  assumes fS: "finite S"
  shows "finite {f. (\<forall>i \<in> {1.. (k::nat)}. f i \<in> S) \<and> (\<forall>i. i \<notin> {1 .. k} \<longrightarrow> f i = i)}"
proof (induct k)
  case 0
  have th: "{f. \<forall>i. f i = i} = {id}"
    by auto
  show ?case
    by (auto simp add: th)
next
  case (Suc k)
  let ?f = "\<lambda>(y::nat,g) i. if i = Suc k then y else g i"
  let ?S = "?f ` (S \<times> {f. (\<forall>i\<in>{1..k}. f i \<in> S) \<and> (\<forall>i. i \<notin> {1..k} \<longrightarrow> f i = i)})"
  have "?S = {f. (\<forall>i\<in>{1.. Suc k}. f i \<in> S) \<and> (\<forall>i. i \<notin> {1.. Suc k} \<longrightarrow> f i = i)}"
    apply (auto simp add: image_iff)
    apply (rule_tac x="x (Suc k)" in bexI)
    apply (rule_tac x = "\<lambda>i. if i = Suc k then i else x i" in exI)
    apply auto
    done
  with finite_imageI[OF finite_cartesian_product[OF fS Suc.hyps(1)], of ?f]
  show ?case
    by metis
qed


lemma det_linear_rows_sum_lemma:
  assumes fS: "finite S"
    and fT: "finite T"
  shows "det ((\<chi> i. if i \<in> T then sum (a i) S else c i):: 'a::comm_ring_1^'n^'n) =
    sum (\<lambda>f. det((\<chi> i. if i \<in> T then a i (f i) else c i)::'a^'n^'n))
      {f. (\<forall>i \<in> T. f i \<in> S) \<and> (\<forall>i. i \<notin> T \<longrightarrow> f i = i)}"
  using fT
proof (induct T arbitrary: a c set: finite)
  case empty
  have th0: "\<And>x y. (\<chi> i. if i \<in> {} then x i else y i) = (\<chi> i. y i)"
    by vector
  from empty.prems show ?case
    unfolding th0 by (simp add: eq_id_iff)
next
  case (insert z T a c)
  let ?F = "\<lambda>T. {f. (\<forall>i \<in> T. f i \<in> S) \<and> (\<forall>i. i \<notin> T \<longrightarrow> f i = i)}"
  let ?h = "\<lambda>(y,g) i. if i = z then y else g i"
  let ?k = "\<lambda>h. (h(z),(\<lambda>i. if i = z then i else h i))"
  let ?s = "\<lambda> k a c f. det((\<chi> i. if i \<in> T then a i (f i) else c i)::'a^'n^'n)"
  let ?c = "\<lambda>j i. if i = z then a i j else c i"
  have thif: "\<And>a b c d. (if a \<or> b then c else d) = (if a then c else if b then c else d)"
    by simp
  have thif2: "\<And>a b c d e. (if a then b else if c then d else e) =
     (if c then (if a then b else d) else (if a then b else e))"
    by simp
  from \<open>z \<notin> T\<close> have nz: "\<And>i. i \<in> T \<Longrightarrow> i = z \<longleftrightarrow> False"
    by auto
  have "det (\<chi> i. if i \<in> insert z T then sum (a i) S else c i) =
    det (\<chi> i. if i = z then sum (a i) S else if i \<in> T then sum (a i) S else c i)"
    unfolding insert_iff thif ..
  also have "\<dots> = (\<Sum>j\<in>S. det (\<chi> i. if i \<in> T then sum (a i) S else if i = z then a i j else c i))"
    unfolding det_linear_row_sum[OF fS]
    apply (subst thif2)
    using nz
    apply (simp cong del: if_weak_cong cong add: if_cong)
    done
  finally have tha:
    "det (\<chi> i. if i \<in> insert z T then sum (a i) S else c i) =
     (\<Sum>(j, f)\<in>S \<times> ?F T. det (\<chi> i. if i \<in> T then a i (f i)
                                else if i = z then a i j
                                else c i))"
    unfolding insert.hyps unfolding sum.cartesian_product by blast
  show ?case unfolding tha
    using \<open>z \<notin> T\<close>
    by (intro sum.reindex_bij_witness[where i="?k" and j="?h"])
       (auto intro!: cong[OF refl[of det]] simp: vec_eq_iff)
qed

lemma det_linear_rows_sum:
  fixes S :: "'n::finite set"
  assumes fS: "finite S"
  shows "det (\<chi> i. sum (a i) S) =
    sum (\<lambda>f. det (\<chi> i. a i (f i) :: 'a::comm_ring_1 ^ 'n^'n)) {f. \<forall>i. f i \<in> S}"
proof -
  have th0: "\<And>x y. ((\<chi> i. if i \<in> (UNIV:: 'n set) then x i else y i) :: 'a^'n^'n) = (\<chi> i. x i)"
    by vector
  from det_linear_rows_sum_lemma[OF fS, of "UNIV :: 'n set" a, unfolded th0, OF finite]
  show ?thesis by simp
qed

lemma matrix_mul_sum_alt:
  fixes A B :: "'a::comm_ring_1^'n^'n"
  shows "A ** B = (\<chi> i. sum (\<lambda>k. A$i$k *s B $ k) (UNIV :: 'n set))"
  by (vector matrix_matrix_mult_def sum_component)

lemma det_rows_mul:
  "det((\<chi> i. c i *s a i)::'a::comm_ring_1^'n^'n) =
    prod (\<lambda>i. c i) (UNIV:: 'n set) * det((\<chi> i. a i)::'a^'n^'n)"
proof (simp add: det_def sum_distrib_left cong add: prod.cong, rule sum.cong)
  let ?U = "UNIV :: 'n set"
  let ?PU = "{p. p permutes ?U}"
  fix p
  assume pU: "p \<in> ?PU"
  let ?s = "of_int (sign p)"
  from pU have p: "p permutes ?U"
    by blast
  have "prod (\<lambda>i. c i * a i $ p i) ?U = prod c ?U * prod (\<lambda>i. a i $ p i) ?U"
    unfolding prod.distrib ..
  then show "?s * (\<Prod>xa\<in>?U. c xa * a xa $ p xa) =
    prod c ?U * (?s* (\<Prod>xa\<in>?U. a xa $ p xa))"
    by (simp add: field_simps)
qed rule

lemma det_mul:
  fixes A B :: "'a::linordered_idom^'n^'n"
  shows "det (A ** B) = det A * det B"
proof -
  let ?U = "UNIV :: 'n set"
  let ?F = "{f. (\<forall>i\<in> ?U. f i \<in> ?U) \<and> (\<forall>i. i \<notin> ?U \<longrightarrow> f i = i)}"
  let ?PU = "{p. p permutes ?U}"
  have fU: "finite ?U"
    by simp
  have fF: "finite ?F"
    by (rule finite)
  {
    fix p
    assume p: "p permutes ?U"
    have "p \<in> ?F" unfolding mem_Collect_eq permutes_in_image[OF p]
      using p[unfolded permutes_def] by simp
  }
  then have PUF: "?PU \<subseteq> ?F" by blast
  {
    fix f
    assume fPU: "f \<in> ?F - ?PU"
    have fUU: "f ` ?U \<subseteq> ?U"
      using fPU by auto
    from fPU have f: "\<forall>i \<in> ?U. f i \<in> ?U" "\<forall>i. i \<notin> ?U \<longrightarrow> f i = i" "\<not>(\<forall>y. \<exists>!x. f x = y)"
      unfolding permutes_def by auto

    let ?A = "(\<chi> i. A$i$f i *s B$f i) :: 'a^'n^'n"
    let ?B = "(\<chi> i. B$f i) :: 'a^'n^'n"
    {
      assume fni: "\<not> inj_on f ?U"
      then obtain i j where ij: "f i = f j" "i \<noteq> j"
        unfolding inj_on_def by blast
      from ij
      have rth: "row i ?B = row j ?B"
        by (vector row_def)
      from det_identical_rows[OF ij(2) rth]
      have "det (\<chi> i. A$i$f i *s B$f i) = 0"
        unfolding det_rows_mul by simp
    }
    moreover
    {
      assume fi: "inj_on f ?U"
      from f fi have fith: "\<And>i j. f i = f j \<Longrightarrow> i = j"
        unfolding inj_on_def by metis
      note fs = fi[unfolded surjective_iff_injective_gen[OF fU fU refl fUU, symmetric]]
      {
        fix y
        from fs f have "\<exists>x. f x = y"
          by blast
        then obtain x where x: "f x = y"
          by blast
        {
          fix z
          assume z: "f z = y"
          from fith x z have "z = x"
            by metis
        }
        with x have "\<exists>!x. f x = y"
          by blast
      }
      with f(3) have "det (\<chi> i. A$i$f i *s B$f i) = 0"
        by blast
    }
    ultimately have "det (\<chi> i. A$i$f i *s B$f i) = 0"
      by blast
  }
  then have zth: "\<forall> f\<in> ?F - ?PU. det (\<chi> i. A$i$f i *s B$f i) = 0"
    by simp
  {
    fix p
    assume pU: "p \<in> ?PU"
    from pU have p: "p permutes ?U"
      by blast
    let ?s = "\<lambda>p. of_int (sign p)"
    let ?f = "\<lambda>q. ?s p * (\<Prod>i\<in> ?U. A $ i $ p i) * (?s q * (\<Prod>i\<in> ?U. B $ i $ q i))"
    have "(sum (\<lambda>q. ?s q *
        (\<Prod>i\<in> ?U. (\<chi> i. A $ i $ p i *s B $ p i :: 'a^'n^'n) $ i $ q i)) ?PU) =
      (sum (\<lambda>q. ?s p * (\<Prod>i\<in> ?U. A $ i $ p i) * (?s q * (\<Prod>i\<in> ?U. B $ i $ q i))) ?PU)"
      unfolding sum_permutations_compose_right[OF permutes_inv[OF p], of ?f]
    proof (rule sum.cong)
      fix q
      assume qU: "q \<in> ?PU"
      then have q: "q permutes ?U"
        by blast
      from p q have pp: "permutation p" and pq: "permutation q"
        unfolding permutation_permutes by auto
      have th00: "of_int (sign p) * of_int (sign p) = (1::'a)"
        "\<And>a. of_int (sign p) * (of_int (sign p) * a) = a"
        unfolding mult.assoc[symmetric]
        unfolding of_int_mult[symmetric]
        by (simp_all add: sign_idempotent)
      have ths: "?s q = ?s p * ?s (q \<circ> inv p)"
        using pp pq permutation_inverse[OF pp] sign_inverse[OF pp]
        by (simp add:  th00 ac_simps sign_idempotent sign_compose)
      have th001: "prod (\<lambda>i. B$i$ q (inv p i)) ?U = prod ((\<lambda>i. B$i$ q (inv p i)) \<circ> p) ?U"
        by (rule prod_permute[OF p])
      have thp: "prod (\<lambda>i. (\<chi> i. A$i$p i *s B$p i :: 'a^'n^'n) $i $ q i) ?U =
        prod (\<lambda>i. A$i$p i) ?U * prod (\<lambda>i. B$i$ q (inv p i)) ?U"
        unfolding th001 prod.distrib[symmetric] o_def permutes_inverses[OF p]
        apply (rule prod.cong[OF refl])
        using permutes_in_image[OF q]
        apply vector
        done
      show "?s q * prod (\<lambda>i. (((\<chi> i. A$i$p i *s B$p i) :: 'a^'n^'n)$i$q i)) ?U =
        ?s p * (prod (\<lambda>i. A$i$p i) ?U) * (?s (q \<circ> inv p) * prod (\<lambda>i. B$i$(q \<circ> inv p) i) ?U)"
        using ths thp pp pq permutation_inverse[OF pp] sign_inverse[OF pp]
        by (simp add: sign_nz th00 field_simps sign_idempotent sign_compose)
    qed rule
  }
  then have th2: "sum (\<lambda>f. det (\<chi> i. A$i$f i *s B$f i)) ?PU = det A * det B"
    unfolding det_def sum_product
    by (rule sum.cong [OF refl])
  have "det (A**B) = sum (\<lambda>f.  det (\<chi> i. A $ i $ f i *s B $ f i)) ?F"
    unfolding matrix_mul_sum_alt det_linear_rows_sum[OF fU]
    by simp
  also have "\<dots> = sum (\<lambda>f. det (\<chi> i. A$i$f i *s B$f i)) ?PU"
    using sum.mono_neutral_cong_left[OF fF PUF zth, symmetric]
    unfolding det_rows_mul by auto
  finally show ?thesis unfolding th2 .
qed

subsection \<open>Relation to invertibility.\<close>

lemma invertible_left_inverse:
  fixes A :: "real^'n^'n"
  shows "invertible A \<longleftrightarrow> (\<exists>(B::real^'n^'n). B** A = mat 1)"
  by (metis invertible_def matrix_left_right_inverse)

lemma invertible_right_inverse:
  fixes A :: "real^'n^'n"
  shows "invertible A \<longleftrightarrow> (\<exists>(B::real^'n^'n). A** B = mat 1)"
  by (metis invertible_def matrix_left_right_inverse)

lemma invertible_det_nz:
  fixes A::"real ^'n^'n"
  shows "invertible A \<longleftrightarrow> det A \<noteq> 0"
proof -
  {
    assume "invertible A"
    then obtain B :: "real ^'n^'n" where B: "A ** B = mat 1"
      unfolding invertible_right_inverse by blast
    then have "det (A ** B) = det (mat 1 :: real ^'n^'n)"
      by simp
    then have "det A \<noteq> 0"
      by (simp add: det_mul det_I) algebra
  }
  moreover
  {
    assume H: "\<not> invertible A"
    let ?U = "UNIV :: 'n set"
    have fU: "finite ?U"
      by simp
    from H obtain c i where c: "sum (\<lambda>i. c i *s row i A) ?U = 0"
      and iU: "i \<in> ?U"
      and ci: "c i \<noteq> 0"
      unfolding invertible_right_inverse
      unfolding matrix_right_invertible_independent_rows
      by blast
    have *: "\<And>(a::real^'n) b. a + b = 0 \<Longrightarrow> -a = b"
      apply (drule_tac f="(+) (- a)" in cong[OF refl])
      apply (simp only: ab_left_minus add.assoc[symmetric])
      apply simp
      done
    have thr0: "- row i A = sum (\<lambda>j. (1/ c i) *s (c j *s row j A)) (?U - {i})"
      apply (rule vector_mul_lcancel_imp[OF ci])
      using c ci  unfolding sum.remove[OF fU iU] sum_cmul
      apply (auto simp add: field_simps *)
      done
    have thr: "- row i A \<in> span {row j A| j. j \<noteq> i}"
      unfolding thr0
      apply (rule span_sum)
      apply simp
      apply (rule span_mul [where 'a="real^'n"])
      apply (rule span_superset)
      apply auto
      done
    let ?B = "(\<chi> k. if k = i then 0 else row k A) :: real ^'n^'n"
    have thrb: "row i ?B = 0" using iU by (vector row_def)
    have "det A = 0"
      unfolding det_row_span[OF thr, symmetric] right_minus
      unfolding det_zero_row[OF thrb] ..
  }
  ultimately show ?thesis
    by blast
qed

lemma det_nz_iff_inj:
  fixes f :: "real^'n \<Rightarrow> real^'n"
  assumes "linear f"
  shows "det (matrix f) \<noteq> 0 \<longleftrightarrow> inj f"
proof
  assume "det (matrix f) \<noteq> 0"
  then show "inj f"
    using assms invertible_det_nz inj_matrix_vector_mult by force
next
  assume "inj f"
  show "det (matrix f) \<noteq> 0"
    using linear_injective_left_inverse [OF assms \<open>inj f\<close>]
    by (metis assms invertible_det_nz invertible_left_inverse matrix_compose matrix_id_mat_1)
qed

lemma det_eq_0_rank:
  fixes A :: "real^'n^'n"
  shows "det A = 0 \<longleftrightarrow> rank A < CARD('n)"
  using invertible_det_nz [of A]
  by (auto simp: matrix_left_invertible_injective invertible_left_inverse less_rank_noninjective)

subsubsection\<open>Invertibility of matrices and corresponding linear functions\<close>

lemma matrix_left_invertible:
  fixes f :: "real^'m \<Rightarrow> real^'n"
  assumes "linear f"
  shows "((\<exists>B. B ** matrix f = mat 1) \<longleftrightarrow> (\<exists>g. linear g \<and> g \<circ> f = id))"
proof safe
  fix B
  assume 1: "B ** matrix f = mat 1"
  show "\<exists>g. linear g \<and> g \<circ> f = id"
  proof (intro exI conjI)
    show "linear (\<lambda>y. B *v y)"
      by (simp add: matrix_vector_mul_linear)
    show "(( *v) B) \<circ> f = id"
      unfolding o_def
      by (metis assms 1 eq_id_iff matrix_vector_mul matrix_vector_mul_assoc matrix_vector_mul_lid)
  qed
next
  fix g
  assume "linear g" "g \<circ> f = id"
  then have "matrix g ** matrix f = mat 1"
    by (metis assms matrix_compose matrix_id_mat_1)
  then show "\<exists>B. B ** matrix f = mat 1" ..
qed

lemma matrix_right_invertible:
  fixes f :: "real^'m \<Rightarrow> real^'n"
  assumes "linear f"
  shows "((\<exists>B. matrix f ** B = mat 1) \<longleftrightarrow> (\<exists>g. linear g \<and> f \<circ> g = id))"
proof safe
  fix B
  assume 1: "matrix f ** B = mat 1"
  show "\<exists>g. linear g \<and> f \<circ> g = id"
  proof (intro exI conjI)
    show "linear (( *v) B)"
      by (simp add: matrix_vector_mul_linear)
    show "f \<circ> ( *v) B = id"
      by (metis 1 assms comp_apply eq_id_iff linear_id matrix_id_mat_1 matrix_vector_mul_assoc matrix_works)
  qed
next
  fix g
  assume "linear g" and "f \<circ> g = id"
  then have "matrix f ** matrix g = mat 1"
    by (metis assms matrix_compose matrix_id_mat_1)
  then show "\<exists>B. matrix f ** B = mat 1" ..
qed

lemma matrix_invertible:
  fixes f :: "real^'m \<Rightarrow> real^'n"
  assumes "linear f"
  shows  "invertible (matrix f) \<longleftrightarrow> (\<exists>g. linear g \<and> f \<circ> g = id \<and> g \<circ> f = id)"
    (is "?lhs = ?rhs")
proof
  assume ?lhs then show ?rhs
    by (metis assms invertible_def left_right_inverse_eq matrix_left_invertible matrix_right_invertible)
next
  assume ?rhs then show ?lhs
    by (metis assms invertible_def matrix_compose matrix_id_mat_1)
qed

lemma invertible_eq_bij:
  fixes m :: "real^'m^'n"
  shows "invertible m \<longleftrightarrow> bij (( *v) m)"
  using matrix_invertible [OF matrix_vector_mul_linear] o_bij
  apply (auto simp: bij_betw_def)
  by (metis left_right_inverse_eq  linear_injective_left_inverse [OF matrix_vector_mul_linear]
            linear_surjective_right_inverse[OF matrix_vector_mul_linear])

subsection \<open>Cramer's rule.\<close>

lemma cramer_lemma_transpose:
  fixes A:: "real^'n^'n"
    and x :: "real^'n"
  shows "det ((\<chi> i. if i = k then sum (\<lambda>i. x$i *s row i A) (UNIV::'n set)
                             else row i A)::real^'n^'n) = x$k * det A"
  (is "?lhs = ?rhs")
proof -
  let ?U = "UNIV :: 'n set"
  let ?Uk = "?U - {k}"
  have U: "?U = insert k ?Uk"
    by blast
  have fUk: "finite ?Uk"
    by simp
  have kUk: "k \<notin> ?Uk"
    by simp
  have th00: "\<And>k s. x$k *s row k A + s = (x$k - 1) *s row k A + row k A + s"
    by (vector field_simps)
  have th001: "\<And>f k . (\<lambda>x. if x = k then f k else f x) = f"
    by auto
  have "(\<chi> i. row i A) = A" by (vector row_def)
  then have thd1: "det (\<chi> i. row i A) = det A"
    by simp
  have thd0: "det (\<chi> i. if i = k then row k A + (\<Sum>i \<in> ?Uk. x $ i *s row i A) else row i A) = det A"
    apply (rule det_row_span)
    apply (rule span_sum)
    apply (rule span_mul [where 'a="real^'n", folded scalar_mult_eq_scaleR])
    apply (rule span_superset)
    apply auto
    done
  show "?lhs = x$k * det A"
    apply (subst U)
    unfolding sum.insert[OF fUk kUk]
    apply (subst th00)
    unfolding add.assoc
    apply (subst det_row_add)
    unfolding thd0
    unfolding det_row_mul
    unfolding th001[of k "\<lambda>i. row i A"]
    unfolding thd1
    apply (simp add: field_simps)
    done
qed

lemma cramer_lemma:
  fixes A :: "real^'n^'n"
  shows "det((\<chi> i j. if j = k then (A *v x)$i else A$i$j):: real^'n^'n) = x$k * det A"
proof -
  let ?U = "UNIV :: 'n set"
  have *: "\<And>c. sum (\<lambda>i. c i *s row i (transpose A)) ?U = sum (\<lambda>i. c i *s column i A) ?U"
    by (auto simp add: row_transpose intro: sum.cong)
  show ?thesis
    unfolding matrix_mult_sum
    unfolding cramer_lemma_transpose[of k x "transpose A", unfolded det_transpose, symmetric]
    unfolding *[of "\<lambda>i. x$i"]
    apply (subst det_transpose[symmetric])
    apply (rule cong[OF refl[of det]])
    apply (vector transpose_def column_def row_def)
    done
qed

lemma cramer:
  fixes A ::"real^'n^'n"
  assumes d0: "det A \<noteq> 0"
  shows "A *v x = b \<longleftrightarrow> x = (\<chi> k. det(\<chi> i j. if j=k then b$i else A$i$j) / det A)"
proof -
  from d0 obtain B where B: "A ** B = mat 1" "B ** A = mat 1"
    unfolding invertible_det_nz[symmetric] invertible_def
    by blast
  have "(A ** B) *v b = b"
    by (simp add: B matrix_vector_mul_lid)
  then have "A *v (B *v b) = b"
    by (simp add: matrix_vector_mul_assoc)
  then have xe: "\<exists>x. A *v x = b"
    by blast
  {
    fix x
    assume x: "A *v x = b"
    have "x = (\<chi> k. det(\<chi> i j. if j=k then b$i else A$i$j) / det A)"
      unfolding x[symmetric]
      using d0 by (simp add: vec_eq_iff cramer_lemma field_simps)
  }
  with xe show ?thesis
    by auto
qed

subsection \<open>Orthogonality of a transformation and matrix\<close>

definition "orthogonal_transformation f \<longleftrightarrow> linear f \<and> (\<forall>v w. f v \<bullet> f w = v \<bullet> w)"

definition "orthogonal_matrix (Q::'a::semiring_1^'n^'n) \<longleftrightarrow>
  transpose Q ** Q = mat 1 \<and> Q ** transpose Q = mat 1"

lemma orthogonal_transformation:
  "orthogonal_transformation f \<longleftrightarrow> linear f \<and> (\<forall>v. norm (f v) = norm v)"
  unfolding orthogonal_transformation_def
  apply auto
  apply (erule_tac x=v in allE)+
  apply (simp add: norm_eq_sqrt_inner)
  apply (simp add: dot_norm  linear_add[symmetric])
  done

lemma orthogonal_transformation_id [simp]: "orthogonal_transformation (\<lambda>x. x)"
  by (simp add: linear_iff orthogonal_transformation_def)

lemma orthogonal_orthogonal_transformation:
    "orthogonal_transformation f \<Longrightarrow> orthogonal (f x) (f y) \<longleftrightarrow> orthogonal x y"
  by (simp add: orthogonal_def orthogonal_transformation_def)

lemma orthogonal_transformation_compose:
   "\<lbrakk>orthogonal_transformation f; orthogonal_transformation g\<rbrakk> \<Longrightarrow> orthogonal_transformation(f \<circ> g)"
  by (simp add: orthogonal_transformation_def linear_compose)

lemma orthogonal_transformation_neg:
  "orthogonal_transformation(\<lambda>x. -(f x)) \<longleftrightarrow> orthogonal_transformation f"
  by (auto simp: orthogonal_transformation_def dest: linear_compose_neg)

lemma orthogonal_transformation_scaleR: "orthogonal_transformation f \<Longrightarrow> f (c *\<^sub>R v) = c *\<^sub>R f v"
  by (simp add: linear_iff orthogonal_transformation_def)

lemma orthogonal_transformation_linear:
   "orthogonal_transformation f \<Longrightarrow> linear f"
  by (simp add: orthogonal_transformation_def)

lemma orthogonal_transformation_inj:
  "orthogonal_transformation f \<Longrightarrow> inj f"
  unfolding orthogonal_transformation_def inj_on_def
  by (metis vector_eq)

lemma orthogonal_transformation_surj:
  "orthogonal_transformation f \<Longrightarrow> surj f"
  for f :: "'a::euclidean_space \<Rightarrow> 'a::euclidean_space"
  by (simp add: linear_injective_imp_surjective orthogonal_transformation_inj orthogonal_transformation_linear)

lemma orthogonal_transformation_bij:
  "orthogonal_transformation f \<Longrightarrow> bij f"
  for f :: "'a::euclidean_space \<Rightarrow> 'a::euclidean_space"
  by (simp add: bij_def orthogonal_transformation_inj orthogonal_transformation_surj)

lemma orthogonal_transformation_inv:
  "orthogonal_transformation f \<Longrightarrow> orthogonal_transformation (inv f)"
  for f :: "'a::euclidean_space \<Rightarrow> 'a::euclidean_space"
  by (metis (no_types, hide_lams) bijection.inv_right bijection_def inj_linear_imp_inv_linear orthogonal_transformation orthogonal_transformation_bij orthogonal_transformation_inj)

lemma orthogonal_transformation_norm:
  "orthogonal_transformation f \<Longrightarrow> norm (f x) = norm x"
  by (metis orthogonal_transformation)

lemma orthogonal_matrix: "orthogonal_matrix (Q:: real ^'n^'n) \<longleftrightarrow> transpose Q ** Q = mat 1"
  by (metis matrix_left_right_inverse orthogonal_matrix_def)

lemma orthogonal_matrix_id: "orthogonal_matrix (mat 1 :: _^'n^'n)"
  by (simp add: orthogonal_matrix_def transpose_mat matrix_mul_lid)

lemma orthogonal_matrix_mul:
  fixes A :: "real ^'n^'n"
  assumes oA : "orthogonal_matrix A"
    and oB: "orthogonal_matrix B"
  shows "orthogonal_matrix(A ** B)"
  using oA oB
  unfolding orthogonal_matrix matrix_transpose_mul
  apply (subst matrix_mul_assoc)
  apply (subst matrix_mul_assoc[symmetric])
  apply (simp add: matrix_mul_rid)
  done

lemma orthogonal_transformation_matrix:
  fixes f:: "real^'n \<Rightarrow> real^'n"
  shows "orthogonal_transformation f \<longleftrightarrow> linear f \<and> orthogonal_matrix(matrix f)"
  (is "?lhs \<longleftrightarrow> ?rhs")
proof -
  let ?mf = "matrix f"
  let ?ot = "orthogonal_transformation f"
  let ?U = "UNIV :: 'n set"
  have fU: "finite ?U" by simp
  let ?m1 = "mat 1 :: real ^'n^'n"
  {
    assume ot: ?ot
    from ot have lf: "linear f" and fd: "\<forall>v w. f v \<bullet> f w = v \<bullet> w"
      unfolding  orthogonal_transformation_def orthogonal_matrix by blast+
    {
      fix i j
      let ?A = "transpose ?mf ** ?mf"
      have th0: "\<And>b (x::'a::comm_ring_1). (if b then 1 else 0)*x = (if b then x else 0)"
        "\<And>b (x::'a::comm_ring_1). x*(if b then 1 else 0) = (if b then x else 0)"
        by simp_all
      from fd[rule_format, of "axis i 1" "axis j 1",
        simplified matrix_works[OF lf, symmetric] dot_matrix_vector_mul]
      have "?A$i$j = ?m1 $ i $ j"
        by (simp add: inner_vec_def matrix_matrix_mult_def columnvector_def rowvector_def
            th0 sum.delta[OF fU] mat_def axis_def)
    }
    then have "orthogonal_matrix ?mf"
      unfolding orthogonal_matrix
      by vector
    with lf have ?rhs
      by blast
  }
  moreover
  {
    assume lf: "linear f" and om: "orthogonal_matrix ?mf"
    from lf om have ?lhs
      apply (simp only: orthogonal_matrix_def norm_eq orthogonal_transformation)
      apply (simp only: matrix_works[OF lf, symmetric])
      apply (subst dot_matrix_vector_mul)
      apply (simp add: dot_matrix_product matrix_mul_lid)
      done
  }
  ultimately show ?thesis
    by blast
qed

lemma det_orthogonal_matrix:
  fixes Q:: "'a::linordered_idom^'n^'n"
  assumes oQ: "orthogonal_matrix Q"
  shows "det Q = 1 \<or> det Q = - 1"
proof -
  have th: "\<And>x::'a. x = 1 \<or> x = - 1 \<longleftrightarrow> x*x = 1" (is "\<And>x::'a. ?ths x")
  proof -
    fix x:: 'a
    have th0: "x * x - 1 = (x - 1) * (x + 1)"
      by (simp add: field_simps)
    have th1: "\<And>(x::'a) y. x = - y \<longleftrightarrow> x + y = 0"
      apply (subst eq_iff_diff_eq_0)
      apply simp
      done
    have "x * x = 1 \<longleftrightarrow> x * x - 1 = 0"
      by simp
    also have "\<dots> \<longleftrightarrow> x = 1 \<or> x = - 1"
      unfolding th0 th1 by simp
    finally show "?ths x" ..
  qed
  from oQ have "Q ** transpose Q = mat 1"
    by (metis orthogonal_matrix_def)
  then have "det (Q ** transpose Q) = det (mat 1:: 'a^'n^'n)"
    by simp
  then have "det Q * det Q = 1"
    by (simp add: det_mul det_I det_transpose)
  then show ?thesis unfolding th .
qed

lemma orthogonal_transformation_det [simp]:
  fixes f :: "real^'n \<Rightarrow> real^'n"
  shows "orthogonal_transformation f \<Longrightarrow> \<bar>det (matrix f)\<bar> = 1"
  using det_orthogonal_matrix orthogonal_transformation_matrix by fastforce


subsection \<open>Linearity of scaling, and hence isometry, that preserves origin\<close>

lemma scaling_linear:
  fixes f :: "'a::real_inner \<Rightarrow> 'a::real_inner"
  assumes f0: "f 0 = 0"
    and fd: "\<forall>x y. dist (f x) (f y) = c * dist x y"
  shows "linear f"
proof -
  {
    fix v w
    {
      fix x
      note fd[rule_format, of x 0, unfolded dist_norm f0 diff_0_right]
    }
    note th0 = this
    have "f v \<bullet> f w = c\<^sup>2 * (v \<bullet> w)"
      unfolding dot_norm_neg dist_norm[symmetric]
      unfolding th0 fd[rule_format] by (simp add: power2_eq_square field_simps)}
  note fc = this
  show ?thesis
    unfolding linear_iff vector_eq[where 'a="'a"] scalar_mult_eq_scaleR
    by (simp add: inner_add fc field_simps)
qed

lemma isometry_linear:
  "f (0::'a::real_inner) = (0::'a) \<Longrightarrow> \<forall>x y. dist(f x) (f y) = dist x y \<Longrightarrow> linear f"
  by (rule scaling_linear[where c=1]) simp_all

text \<open>Hence another formulation of orthogonal transformation.\<close>

lemma orthogonal_transformation_isometry:
  "orthogonal_transformation f \<longleftrightarrow> f(0::'a::real_inner) = (0::'a) \<and> (\<forall>x y. dist(f x) (f y) = dist x y)"
  unfolding orthogonal_transformation
  apply (auto simp: linear_0 isometry_linear)
   apply (metis (no_types, hide_lams) dist_norm linear_diff)
  by (metis dist_0_norm)


lemma image_orthogonal_transformation_ball:
  fixes f :: "'a::euclidean_space \<Rightarrow> 'a"
  assumes "orthogonal_transformation f"
  shows "f ` ball x r = ball (f x) r"
proof (intro equalityI subsetI)
  fix y assume "y \<in> f ` ball x r"
  with assms show "y \<in> ball (f x) r"
    by (auto simp: orthogonal_transformation_isometry)
next
  fix y assume y: "y \<in> ball (f x) r"
  then obtain z where z: "y = f z"
    using assms orthogonal_transformation_surj by blast
  with y assms show "y \<in> f ` ball x r"
    by (auto simp: orthogonal_transformation_isometry)
qed

lemma image_orthogonal_transformation_cball:
  fixes f :: "'a::euclidean_space \<Rightarrow> 'a"
  assumes "orthogonal_transformation f"
  shows "f ` cball x r = cball (f x) r"
proof (intro equalityI subsetI)
  fix y assume "y \<in> f ` cball x r"
  with assms show "y \<in> cball (f x) r"
    by (auto simp: orthogonal_transformation_isometry)
next
  fix y assume y: "y \<in> cball (f x) r"
  then obtain z where z: "y = f z"
    using assms orthogonal_transformation_surj by blast
  with y assms show "y \<in> f ` cball x r"
    by (auto simp: orthogonal_transformation_isometry)
qed

subsection\<open> We can find an orthogonal matrix taking any unit vector to any other\<close>

lemma orthogonal_matrix_transpose [simp]:
     "orthogonal_matrix(transpose A) \<longleftrightarrow> orthogonal_matrix A"
  by (auto simp: orthogonal_matrix_def)

lemma orthogonal_matrix_orthonormal_columns:
  fixes A :: "real^'n^'n"
  shows "orthogonal_matrix A \<longleftrightarrow>
          (\<forall>i. norm(column i A) = 1) \<and>
          (\<forall>i j. i \<noteq> j \<longrightarrow> orthogonal (column i A) (column j A))"
  by (auto simp: orthogonal_matrix matrix_mult_transpose_dot_column vec_eq_iff mat_def norm_eq_1 orthogonal_def)

lemma orthogonal_matrix_orthonormal_rows:
  fixes A :: "real^'n^'n"
  shows "orthogonal_matrix A \<longleftrightarrow>
          (\<forall>i. norm(row i A) = 1) \<and>
          (\<forall>i j. i \<noteq> j \<longrightarrow> orthogonal (row i A) (row j A))"
  using orthogonal_matrix_orthonormal_columns [of "transpose A"] by simp

lemma orthogonal_matrix_exists_basis:
  fixes a :: "real^'n"
  assumes "norm a = 1"
  obtains A where "orthogonal_matrix A" "A *v (axis k 1) = a"
proof -
  obtain S where "a \<in> S" "pairwise orthogonal S" and noS: "\<And>x. x \<in> S \<Longrightarrow> norm x = 1"
   and "independent S" "card S = CARD('n)" "span S = UNIV"
    using vector_in_orthonormal_basis assms by force
  with independent_imp_finite obtain f0 where "bij_betw f0 (UNIV::'n set) S"
    by (metis finite_class.finite_UNIV finite_same_card_bij)
  then obtain f where f: "bij_betw f (UNIV::'n set) S" and a: "a = f k"
    using bij_swap_iff [of k "inv f0 a" f0]
    by (metis UNIV_I \<open>a \<in> S\<close> bij_betw_inv_into_right bij_betw_swap_iff swap_apply1)
  show thesis
  proof
    have [simp]: "\<And>i. norm (f i) = 1"
      using bij_betwE [OF \<open>bij_betw f UNIV S\<close>] by (blast intro: noS)
    have [simp]: "\<And>i j. i \<noteq> j \<Longrightarrow> orthogonal (f i) (f j)"
      using \<open>pairwise orthogonal S\<close> \<open>bij_betw f UNIV S\<close>
      by (auto simp: pairwise_def bij_betw_def inj_on_def)
    show "orthogonal_matrix (\<chi> i j. f j $ i)"
      by (simp add: orthogonal_matrix_orthonormal_columns column_def)
    show "(\<chi> i j. f j $ i) *v axis k 1 = a"
      by (simp add: matrix_vector_mult_def axis_def a if_distrib cong: if_cong)
  qed
qed

lemma orthogonal_transformation_exists_1:
  fixes a b :: "real^'n"
  assumes "norm a = 1" "norm b = 1"
  obtains f where "orthogonal_transformation f" "f a = b"
proof -
  obtain k::'n where True
    by simp
  obtain A B where AB: "orthogonal_matrix A" "orthogonal_matrix B" and eq: "A *v (axis k 1) = a" "B *v (axis k 1) = b"
    using orthogonal_matrix_exists_basis assms by metis
  let ?f = "\<lambda>x. (B ** transpose A) *v x"
  show thesis
  proof
    show "orthogonal_transformation ?f"
      by (simp add: AB orthogonal_matrix_mul matrix_vector_mul_linear orthogonal_transformation_matrix)
  next
    show "?f a = b"
      using \<open>orthogonal_matrix A\<close> unfolding orthogonal_matrix_def
      by (metis eq matrix_mul_rid matrix_vector_mul_assoc)
  qed
qed

lemma orthogonal_transformation_exists:
  fixes a b :: "real^'n"
  assumes "norm a = norm b"
  obtains f where "orthogonal_transformation f" "f a = b"
proof (cases "a = 0 \<or> b = 0")
  case True
  with assms show ?thesis
    using that by force
next
  case False
  then obtain f where f: "orthogonal_transformation f" and eq: "f (a /\<^sub>R norm a) = (b /\<^sub>R norm b)"
    by (auto intro: orthogonal_transformation_exists_1 [of "a /\<^sub>R norm a" "b /\<^sub>R norm b"])
  show ?thesis
  proof
    have "linear f"
      using f by (simp add: orthogonal_transformation_linear)
    then have "f a /\<^sub>R norm a = f (a /\<^sub>R norm a)"
      by (simp add: linear_cmul [of f])
    also have "\<dots> = b /\<^sub>R norm a"
      by (simp add: eq assms [symmetric])
    finally show "f a = b"
      using False by auto
  qed (use f in auto)
qed


subsection \<open>Can extend an isometry from unit sphere\<close>

lemma isometry_sphere_extend:
  fixes f:: "'a::real_inner \<Rightarrow> 'a"
  assumes f1: "\<forall>x. norm x = 1 \<longrightarrow> norm (f x) = 1"
    and fd1: "\<forall> x y. norm x = 1 \<longrightarrow> norm y = 1 \<longrightarrow> dist (f x) (f y) = dist x y"
  shows "\<exists>g. orthogonal_transformation g \<and> (\<forall>x. norm x = 1 \<longrightarrow> g x = f x)"
proof -
  {
    fix x y x' y' x0 y0 x0' y0' :: "'a"
    assume H:
      "x = norm x *\<^sub>R x0"
      "y = norm y *\<^sub>R y0"
      "x' = norm x *\<^sub>R x0'" "y' = norm y *\<^sub>R y0'"
      "norm x0 = 1" "norm x0' = 1" "norm y0 = 1" "norm y0' = 1"
      "norm(x0' - y0') = norm(x0 - y0)"
    then have *: "x0 \<bullet> y0 = x0' \<bullet> y0' + y0' \<bullet> x0' - y0 \<bullet> x0 "
      by (simp add: norm_eq norm_eq_1 inner_add inner_diff)
    have "norm(x' - y') = norm(x - y)"
      apply (subst H(1))
      apply (subst H(2))
      apply (subst H(3))
      apply (subst H(4))
      using H(5-9)
      apply (simp add: norm_eq norm_eq_1)
      apply (simp add: inner_diff scalar_mult_eq_scaleR)
      unfolding *
      apply (simp add: field_simps)
      done
  }
  note th0 = this
  let ?g = "\<lambda>x. if x = 0 then 0 else norm x *\<^sub>R f (inverse (norm x) *\<^sub>R x)"
  {
    fix x:: "'a"
    assume nx: "norm x = 1"
    have "?g x = f x"
      using nx by auto
  }
  then have thfg: "\<forall>x. norm x = 1 \<longrightarrow> ?g x = f x"
    by blast
  have g0: "?g 0 = 0"
    by simp
  {
    fix x y :: "'a"
    {
      assume "x = 0" "y = 0"
      then have "dist (?g x) (?g y) = dist x y"
        by simp
    }
    moreover
    {
      assume "x = 0" "y \<noteq> 0"
      then have "dist (?g x) (?g y) = dist x y"
        apply (simp add: dist_norm)
        apply (rule f1[rule_format])
        apply (simp add: field_simps)
        done
    }
    moreover
    {
      assume "x \<noteq> 0" "y = 0"
      then have "dist (?g x) (?g y) = dist x y"
        apply (simp add: dist_norm)
        apply (rule f1[rule_format])
        apply (simp add: field_simps)
        done
    }
    moreover
    {
      assume z: "x \<noteq> 0" "y \<noteq> 0"
      have th00:
        "x = norm x *\<^sub>R (inverse (norm x) *\<^sub>R x)"
        "y = norm y *\<^sub>R (inverse (norm y) *\<^sub>R y)"
        "norm x *\<^sub>R f ((inverse (norm x) *\<^sub>R x)) = norm x *\<^sub>R f (inverse (norm x) *\<^sub>R x)"
        "norm y *\<^sub>R f (inverse (norm y) *\<^sub>R y) = norm y *\<^sub>R f (inverse (norm y) *\<^sub>R y)"
        "norm (inverse (norm x) *\<^sub>R x) = 1"
        "norm (f (inverse (norm x) *\<^sub>R x)) = 1"
        "norm (inverse (norm y) *\<^sub>R y) = 1"
        "norm (f (inverse (norm y) *\<^sub>R y)) = 1"
        "norm (f (inverse (norm x) *\<^sub>R x) - f (inverse (norm y) *\<^sub>R y)) =
          norm (inverse (norm x) *\<^sub>R x - inverse (norm y) *\<^sub>R y)"
        using z
        by (auto simp add: field_simps intro: f1[rule_format] fd1[rule_format, unfolded dist_norm])
      from z th0[OF th00] have "dist (?g x) (?g y) = dist x y"
        by (simp add: dist_norm)
    }
    ultimately have "dist (?g x) (?g y) = dist x y"
      by blast
  }
  note thd = this
    show ?thesis
    apply (rule exI[where x= ?g])
    unfolding orthogonal_transformation_isometry
    using g0 thfg thd
    apply metis
    done
qed

subsection \<open>Rotation, reflection, rotoinversion\<close>

definition "rotation_matrix Q \<longleftrightarrow> orthogonal_matrix Q \<and> det Q = 1"
definition "rotoinversion_matrix Q \<longleftrightarrow> orthogonal_matrix Q \<and> det Q = - 1"

lemma orthogonal_rotation_or_rotoinversion:
  fixes Q :: "'a::linordered_idom^'n^'n"
  shows " orthogonal_matrix Q \<longleftrightarrow> rotation_matrix Q \<or> rotoinversion_matrix Q"
  by (metis rotoinversion_matrix_def rotation_matrix_def det_orthogonal_matrix)

text \<open>Explicit formulas for low dimensions.\<close>

lemma prod_neutral_const: "prod f {(1::nat)..1} = f 1"
  by simp

lemma prod_2: "prod f {(1::nat)..2} = f 1 * f 2"
  by (simp add: eval_nat_numeral atLeastAtMostSuc_conv mult.commute)

lemma prod_3: "prod f {(1::nat)..3} = f 1 * f 2 * f 3"
  by (simp add: eval_nat_numeral atLeastAtMostSuc_conv mult.commute)

lemma det_1: "det (A::'a::comm_ring_1^1^1) = A$1$1"
  by (simp add: det_def of_nat_Suc sign_id)

lemma det_2: "det (A::'a::comm_ring_1^2^2) = A$1$1 * A$2$2 - A$1$2 * A$2$1"
proof -
  have f12: "finite {2::2}" "1 \<notin> {2::2}" by auto
  show ?thesis
    unfolding det_def UNIV_2
    unfolding sum_over_permutations_insert[OF f12]
    unfolding permutes_sing
    by (simp add: sign_swap_id sign_id swap_id_eq)
qed

lemma det_3:
  "det (A::'a::comm_ring_1^3^3) =
    A$1$1 * A$2$2 * A$3$3 +
    A$1$2 * A$2$3 * A$3$1 +
    A$1$3 * A$2$1 * A$3$2 -
    A$1$1 * A$2$3 * A$3$2 -
    A$1$2 * A$2$1 * A$3$3 -
    A$1$3 * A$2$2 * A$3$1"
proof -
  have f123: "finite {2::3, 3}" "1 \<notin> {2::3, 3}"
    by auto
  have f23: "finite {3::3}" "2 \<notin> {3::3}"
    by auto

  show ?thesis
    unfolding det_def UNIV_3
    unfolding sum_over_permutations_insert[OF f123]
    unfolding sum_over_permutations_insert[OF f23]
    unfolding permutes_sing
    by (simp add: sign_swap_id permutation_swap_id sign_compose sign_id swap_id_eq)
qed

text\<open> Slightly stronger results giving rotation, but only in two or more dimensions.\<close>

lemma rotation_matrix_exists_basis:
  fixes a :: "real^'n"
  assumes 2: "2 \<le> CARD('n)" and "norm a = 1"
  obtains A where "rotation_matrix A" "A *v (axis k 1) = a"
proof -
  obtain A where "orthogonal_matrix A" and A: "A *v (axis k 1) = a"
    using orthogonal_matrix_exists_basis assms by metis
  with orthogonal_rotation_or_rotoinversion
  consider "rotation_matrix A" | "rotoinversion_matrix A"
    by metis
  then show thesis
  proof cases
    assume "rotation_matrix A"
    then show ?thesis
      using \<open>A *v axis k 1 = a\<close> that by auto
  next
    obtain j where "j \<noteq> k"
      by (metis (full_types) 2 card_2_exists ex_card)
    let ?TA = "transpose A"
    let ?A = "\<chi> i. if i = j then - 1 *\<^sub>R (?TA $ i) else ?TA $i"
    assume "rotoinversion_matrix A"
    then have [simp]: "det A = -1"
      by (simp add: rotoinversion_matrix_def)
    show ?thesis
    proof
      have [simp]: "row i (\<chi> i. if i = j then - 1 *\<^sub>R ?TA $ i else ?TA $ i) = (if i = j then - row i ?TA else row i ?TA)" for i
        by (auto simp: row_def)
      have "orthogonal_matrix ?A"
        unfolding orthogonal_matrix_orthonormal_rows
        using \<open>orthogonal_matrix A\<close> by (auto simp: orthogonal_matrix_orthonormal_columns orthogonal_clauses)
      then show "rotation_matrix (transpose ?A)"
        unfolding rotation_matrix_def
        by (simp add: det_row_mul[of j _ "\<lambda>i. ?TA $ i", unfolded scalar_mult_eq_scaleR])
      show "transpose ?A *v axis k 1 = a"
        using \<open>j \<noteq> k\<close> A by (simp add: matrix_vector_column axis_def scalar_mult_eq_scaleR if_distrib [of "\<lambda>z. z *\<^sub>R c" for c] cong: if_cong)
    qed
  qed
qed

lemma rotation_exists_1:
  fixes a :: "real^'n"
  assumes "2 \<le> CARD('n)" "norm a = 1" "norm b = 1"
  obtains f where "orthogonal_transformation f" "det(matrix f) = 1" "f a = b"
proof -
  obtain k::'n where True
    by simp
  obtain A B where AB: "rotation_matrix A" "rotation_matrix B"
               and eq: "A *v (axis k 1) = a" "B *v (axis k 1) = b"
    using rotation_matrix_exists_basis assms by metis
  let ?f = "\<lambda>x. (B ** transpose A) *v x"
  show thesis
  proof
    show "orthogonal_transformation ?f"
      using AB orthogonal_matrix_mul orthogonal_transformation_matrix rotation_matrix_def matrix_vector_mul_linear by force
    show "det (matrix ?f) = 1"
      using AB by (auto simp: det_mul rotation_matrix_def)
    show "?f a = b"
      using AB unfolding orthogonal_matrix_def rotation_matrix_def
      by (metis eq matrix_mul_rid matrix_vector_mul_assoc)
  qed
qed

lemma rotation_exists:
  fixes a :: "real^'n"
  assumes 2: "2 \<le> CARD('n)" and eq: "norm a = norm b"
  obtains f where "orthogonal_transformation f" "det(matrix f) = 1" "f a = b"
proof (cases "a = 0 \<or> b = 0")
  case True
  with assms have "a = 0" "b = 0"
    by auto
  then show ?thesis
    by (metis eq_id_iff matrix_id orthogonal_transformation_id that)
next
  case False
  with that show thesis
    by (auto simp: eq linear_cmul orthogonal_transformation_def
             intro: rotation_exists_1 [of "a /\<^sub>R norm a" "b /\<^sub>R norm b", OF 2])
qed

lemma rotation_rightward_line:
  fixes a :: "real^'n"
  obtains f where "orthogonal_transformation f" "2 \<le> CARD('n) \<Longrightarrow> det(matrix f) = 1"
                  "f(norm a *\<^sub>R axis k 1) = a"
proof (cases "CARD('n) = 1")
  case True
  obtain f where "orthogonal_transformation f" "f (norm a *\<^sub>R axis k (1::real)) = a"
  proof (rule orthogonal_transformation_exists)
    show "norm (norm a *\<^sub>R axis k (1::real)) = norm a"
      by simp
  qed auto
  then show thesis
    using True that by auto
next
  case False
  obtain f where "orthogonal_transformation f" "det(matrix f) = 1" "f (norm a *\<^sub>R axis k 1) = a"
  proof (rule rotation_exists)
    show "2 \<le> CARD('n)"
      using False one_le_card_finite [where 'a='n] by linarith
    show "norm (norm a *\<^sub>R axis k (1::real)) = norm a"
      by simp
  qed auto
  then show thesis
    using that by blast
qed

end

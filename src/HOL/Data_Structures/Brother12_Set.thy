(* Author: Tobias Nipkow *)

section \<open>A 1-2 Brother Tree Implementation of Sets\<close>

theory Brother12_Set
imports
  Cmp
  Set_by_Ordered
begin

subsection \<open>Data Type and Operations\<close>

datatype 'a bro =
  N0 |
  N1 "'a bro" |
  N2 "'a bro" 'a "'a bro" |
  (* auxiliary constructors: *)
  L2 'a |
  N3 "'a bro" 'a "'a bro" 'a "'a bro"

fun inorder :: "'a bro \<Rightarrow> 'a list" where
"inorder N0 = []" |
"inorder (N1 t) = inorder t" |
"inorder (N2 l a r) = inorder l @ a # inorder r" |
"inorder (L2 a) = [a]" |
"inorder (N3 t1 a1 t2 a2 t3) = inorder t1 @ a1 # inorder t2 @ a2 # inorder t3"

fun isin :: "'a bro \<Rightarrow> 'a::cmp \<Rightarrow> bool" where
"isin N0 x = False" |
"isin (N1 t) x = isin t x" |
"isin (N2 l a r) x =
  (case cmp x a of
     LT \<Rightarrow> isin l x |
     EQ \<Rightarrow> True |
     GT \<Rightarrow> isin r x)"

fun n1 :: "'a bro \<Rightarrow> 'a bro" where
"n1 (L2 a) = N2 N0 a N0" |
"n1 (N3 t1 a1 t2 a2 t3) = N2 (N2 t1 a1 t2) a2 (N1 t3)" |
"n1 t = N1 t"

hide_const (open) insert

locale insert
begin

fun n2 :: "'a bro \<Rightarrow> 'a \<Rightarrow> 'a bro \<Rightarrow> 'a bro" where
"n2 (L2 a1) a2 t = N3 N0 a1 N0 a2 t" |
"n2 (N3 t1 a1 t2 a2 t3) a3 (N1 t4) = N2 (N2 t1 a1 t2) a2 (N2 t3 a3 t4)" |
"n2 (N3 t1 a1 t2 a2 t3) a3 t4 = N3 (N2 t1 a1 t2) a2 (N1 t3) a3 t4" |
"n2 t1 a1 (L2 a2) = N3 t1 a1 N0 a2 N0" |
"n2 (N1 t1) a1 (N3 t2 a2 t3 a3 t4) = N2 (N2 t1 a1 t2) a2 (N2 t3 a3 t4)" |
"n2 t1 a1 (N3 t2 a2 t3 a3 t4) = N3 t1 a1 (N1 t2) a2 (N2 t3 a3 t4)" |
"n2 t1 a t2 = N2 t1 a t2"

fun ins :: "'a::cmp \<Rightarrow> 'a bro \<Rightarrow> 'a bro" where
"ins x N0 = L2 x" |
"ins x (N1 t) = n1 (ins x t)" |
"ins x (N2 l a r) =
  (case cmp x a of
     LT \<Rightarrow> n2 (ins x l) a r |
     EQ \<Rightarrow> N2 l a r |
     GT \<Rightarrow> n2 l a (ins x r))"

fun tree :: "'a bro \<Rightarrow> 'a bro" where
"tree (L2 a) = N2 N0 a N0" |
"tree (N3 t1 a1 t2 a2 t3) = N2 (N2 t1 a1 t2) a2 (N1 t3)" |
"tree t = t"

definition insert :: "'a::cmp \<Rightarrow> 'a bro \<Rightarrow> 'a bro" where
"insert x t = tree(ins x t)"

end

locale delete
begin

fun n2 :: "'a bro \<Rightarrow> 'a \<Rightarrow> 'a bro \<Rightarrow> 'a bro" where
"n2 (N1 t1) a1 (N1 t2) = N1 (N2 t1 a1 t2)" |
"n2 (N1 (N1 t1)) a1 (N2 (N1 t2) a2 (N2 t3 a3 t4)) =
  N1 (N2 (N2 t1 a1 t2) a2 (N2 t3 a3 t4))" |
"n2 (N1 (N1 t1)) a1 (N2 (N2 t2 a2 t3) a3 (N1 t4)) =
  N1 (N2 (N2 t1 a1 t2) a2 (N2 t3 a3 t4))" |
"n2 (N1 (N1 t1)) a1 (N2 (N2 t2 a2 t3) a3 (N2 t4 a4 t5)) =
  N2 (N2 (N1 t1) a1 (N2 t2 a2 t3)) a3 (N1 (N2 t4 a4 t5))" |
"n2 (N2 (N1 t1) a1 (N2 t2 a2 t3)) a3 (N1 (N1 t4)) =
  N1 (N2 (N2 t1 a1 t2) a2 (N2 t3 a3 t4))" |
"n2 (N2 (N2 t1 a1 t2) a2 (N1 t3)) a3 (N1 (N1 t4)) =
  N1 (N2 (N2 t1 a1 t2) a2 (N2 t3 a3 t4))" |
"n2 (N2 (N2 t1 a1 t2) a2 (N2 t3 a3 t4)) a5 (N1 (N1 t5)) =
  N2 (N1 (N2 t1 a1 t2)) a2 (N2 (N2 t3 a3 t4) a5 (N1 t5))" |
"n2 t1 a1 t2 = N2 t1 a1 t2"

fun del_min :: "'a bro \<Rightarrow> ('a \<times> 'a bro) option" where
"del_min N0 = None" |
"del_min (N1 t) =
  (case del_min t of
     None \<Rightarrow> None |
     Some (a, t') \<Rightarrow> Some (a, N1 t'))" |
"del_min (N2 t1 a t2) =
  (case del_min t1 of
     None \<Rightarrow> Some (a, N1 t2) |
     Some (b, t1') \<Rightarrow> Some (b, n2 t1' a t2))"

fun del :: "'a::cmp \<Rightarrow> 'a bro \<Rightarrow> 'a bro" where
"del _ N0         = N0" |
"del x (N1 t)     = N1 (del x t)" |
"del x (N2 l a r) =
  (case cmp x a of
     LT \<Rightarrow> n2 (del x l) a r |
     GT \<Rightarrow> n2 l a (del x r) |
     EQ \<Rightarrow> (case del_min r of
              None \<Rightarrow> N1 l |
              Some (b, r') \<Rightarrow> n2 l b r'))"

fun tree :: "'a bro \<Rightarrow> 'a bro" where
"tree (N1 t) = t" |
"tree t = t"

definition delete :: "'a::cmp \<Rightarrow> 'a bro \<Rightarrow> 'a bro" where
"delete a t = tree (del a t)"

end

subsection \<open>Invariants\<close>

fun B :: "nat \<Rightarrow> 'a bro set"
and U :: "nat \<Rightarrow> 'a bro set" where
"B 0 = {N0}" |
"B (Suc h) = { N2 t1 a t2 | t1 a t2. 
  t1 \<in> B h \<union> U h \<and> t2 \<in> B h \<or> t1 \<in> B h \<and> t2 \<in> B h \<union> U h}" |
"U 0 = {}" |
"U (Suc h) = N1 ` B h"

abbreviation "T h \<equiv> B h \<union> U h"

fun Bp :: "nat \<Rightarrow> 'a bro set" where
"Bp 0 = B 0 \<union> L2 ` UNIV" |
"Bp (Suc 0) = B (Suc 0) \<union> {N3 N0 a N0 b N0|a b. True}" |
"Bp (Suc(Suc h)) = B (Suc(Suc h)) \<union>
  {N3 t1 a t2 b t3 | t1 a t2 b t3. t1 \<in> B (Suc h) \<and> t2 \<in> U (Suc h) \<and> t3 \<in> B (Suc h)}"

fun Um :: "nat \<Rightarrow> 'a bro set" where
"Um 0 = {}" |
"Um (Suc h) = N1 ` T h"


subsection "Functional Correctness Proofs"

subsubsection "Proofs for isin"

lemma
  "t \<in> T h \<Longrightarrow> sorted(inorder t) \<Longrightarrow> isin t x = (x \<in> elems(inorder t))"
by(induction h arbitrary: t) (fastforce simp: elems_simps1 split: if_splits)+

lemma isin_set: "t \<in> T h \<Longrightarrow>
  sorted(inorder t) \<Longrightarrow> isin t x = (x \<in> elems(inorder t))"
by(induction h arbitrary: t) (auto simp: elems_simps2 split: if_splits)

subsubsection "Proofs for insertion"

lemma inorder_n1: "inorder(n1 t) = inorder t"
by(induction t rule: n1.induct) (auto simp: sorted_lems)

context insert
begin

lemma inorder_n2: "inorder(n2 l a r) = inorder l @ a # inorder r"
by(cases "(l,a,r)" rule: n2.cases) (auto simp: sorted_lems)

lemma inorder_tree: "inorder(tree t) = inorder t"
by(cases t) auto

lemma inorder_ins: "t \<in> T h \<Longrightarrow>
  sorted(inorder t) \<Longrightarrow> inorder(ins a t) = ins_list a (inorder t)"
by(induction h arbitrary: t) (auto simp: ins_list_simps inorder_n1 inorder_n2)

lemma inorder_insert: "t \<in> T h \<Longrightarrow>
  sorted(inorder t) \<Longrightarrow> inorder(insert a t) = ins_list a (inorder t)"
by(simp add: insert_def inorder_ins inorder_tree)

end

subsubsection \<open>Proofs for deletion\<close>

context delete
begin

lemma inorder_tree: "inorder(tree t) = inorder t"
by(cases t) auto

lemma inorder_n2: "inorder(n2 l a r) = inorder l @ a # inorder r"
by(induction l a r rule: n2.induct) (auto)

lemma inorder_del_min:
shows "t \<in> B h \<Longrightarrow> (del_min t = None \<longleftrightarrow> inorder t = []) \<and>
  (del_min t = Some(a,t') \<longrightarrow> inorder t = a # inorder t')"
and "t \<in> U h \<Longrightarrow> (del_min t = None \<longleftrightarrow> inorder t = []) \<and>
  (del_min t = Some(a,t') \<longrightarrow> inorder t = a # inorder t')"
by(induction h arbitrary: t a t') (auto simp: inorder_n2 split: option.splits)

lemma inorder_del:
  "t \<in> B h \<Longrightarrow> sorted(inorder t) \<Longrightarrow> inorder(del a t) = del_list a (inorder t)"
  "t \<in> U h \<Longrightarrow> sorted(inorder t) \<Longrightarrow> inorder(del a t) = del_list a (inorder t)"
by(induction h arbitrary: t)
  (auto simp: del_list_simps inorder_n2 inorder_del_min split: option.splits)

end


subsection \<open>Invariant Proofs\<close>

subsubsection \<open>Proofs for insertion\<close>

lemma n1_type: "t \<in> Bp h \<Longrightarrow> n1 t \<in> T (Suc h)"
by(cases h rule: Bp.cases) auto

context insert
begin

lemma tree_type1: "t \<in> Bp h \<Longrightarrow> tree t \<in> B h \<union> B (Suc h)"
by(cases h rule: Bp.cases) auto

lemma tree_type2: "t \<in> T h \<Longrightarrow> tree t \<in> T h"
by(cases h) auto

lemma n2_type:
  "(t1 \<in> Bp h \<and> t2 \<in> T h \<longrightarrow> n2 t1 a t2 \<in> Bp (Suc h)) \<and>
   (t1 \<in> T h \<and> t2 \<in> Bp h \<longrightarrow> n2 t1 a t2 \<in> Bp (Suc h))"
apply(cases h rule: Bp.cases)
apply (auto)[2]
apply(rule conjI impI | erule conjE exE imageE | simp | erule disjE)+
done

lemma Bp_if_B: "t \<in> B h \<Longrightarrow> t \<in> Bp h"
by (cases h rule: Bp.cases) simp_all

text{* An automatic proof: *}

lemma
  "(t \<in> B h \<longrightarrow> ins x t \<in> Bp h) \<and> (t \<in> U h \<longrightarrow> ins x t \<in> T h)"
apply(induction h arbitrary: t)
 apply (simp)
apply (fastforce simp: Bp_if_B n2_type dest: n1_type)
done

text{* A detailed proof: *}

lemma ins_type:
shows "t \<in> B h \<Longrightarrow> ins x t \<in> Bp h" and "t \<in> U h \<Longrightarrow> ins x t \<in> T h"
proof(induction h arbitrary: t)
  case 0
  { case 1 thus ?case by simp
  next
    case 2 thus ?case by simp }
next
  case (Suc h)
  { case 1
    then obtain t1 a t2 where [simp]: "t = N2 t1 a t2" and
      t1: "t1 \<in> T h" and t2: "t2 \<in> T h" and t12: "t1 \<in> B h \<or> t2 \<in> B h"
      by auto
    { assume "x < a"
      hence "?case \<longleftrightarrow> n2 (ins x t1) a t2 \<in> Bp (Suc h)" by simp
      also have "\<dots>"
      proof cases
        assume "t1 \<in> B h"
        with t2 show ?thesis by (simp add: Suc.IH(1) n2_type)
      next
        assume "t1 \<notin> B h"
        hence 1: "t1 \<in> U h" and 2: "t2 \<in> B h" using t1 t12 by auto
        show ?thesis by (metis Suc.IH(2)[OF 1] Bp_if_B[OF 2] n2_type)
      qed
      finally have ?case .
    }
    moreover
    { assume "a < x"
      hence "?case \<longleftrightarrow> n2 t1 a (ins x t2) \<in> Bp (Suc h)" by simp
      also have "\<dots>"
      proof cases
        assume "t2 \<in> B h"
        with t1 show ?thesis by (simp add: Suc.IH(1) n2_type)
      next
        assume "t2 \<notin> B h"
        hence 1: "t1 \<in> B h" and 2: "t2 \<in> U h" using t2 t12 by auto
        show ?thesis by (metis Bp_if_B[OF 1] Suc.IH(2)[OF 2] n2_type)
      qed
    }
    moreover 
    { assume "x = a"
      from 1 have "t \<in> Bp (Suc h)" by(rule Bp_if_B)
      hence "?case" using `x = a` by simp
    }
    ultimately show ?case by auto
  next
    case 2 thus ?case using Suc(1) n1_type by fastforce }
qed

lemma insert_type:
  "t \<in> T h \<Longrightarrow> insert x t \<in> T h \<union> T (Suc h)"
unfolding insert_def by (metis Un_iff ins_type tree_type1 tree_type2)

end

subsubsection "Proofs for deletion"

lemma B_simps[simp]: 
  "N1 t \<in> B h = False"
  "L2 y \<in> B h = False"
  "(N3 t1 a1 t2 a2 t3) \<in> B h = False"
  "N0 \<in> B h \<longleftrightarrow> h = 0"
by (cases h, auto)+

context delete
begin

lemma n2_type1:
  "\<lbrakk>t1 \<in> Um h; t2 \<in> B h\<rbrakk> \<Longrightarrow> n2 t1 a t2 \<in> T (Suc h)"
apply(cases h rule: Bp.cases)
apply auto[2]
apply(erule exE bexE conjE imageE | simp | erule disjE)+
done

lemma n2_type2:
  "\<lbrakk>t1 \<in> B h ; t2 \<in> Um h \<rbrakk> \<Longrightarrow> n2 t1 a t2 \<in> T (Suc h)"
apply(cases h rule: Bp.cases)
apply auto[2]
apply(erule exE bexE conjE imageE | simp | erule disjE)+
done

lemma n2_type3:
  "\<lbrakk>t1 \<in> T h ; t2 \<in> T h \<rbrakk> \<Longrightarrow> n2 t1 a t2 \<in> T (Suc h)"
apply(cases h rule: Bp.cases)
apply auto[2]
apply(erule exE bexE conjE imageE | simp | erule disjE)+
done

lemma del_minNoneN0: "\<lbrakk>t \<in> B h; del_min t = None\<rbrakk> \<Longrightarrow>  t = N0"
by (cases t) (auto split: option.splits)

lemma del_minNoneN1 : "\<lbrakk>t \<in> U h; del_min t = None\<rbrakk> \<Longrightarrow> t = N1 N0"
by (cases h) (auto simp: del_minNoneN0  split: option.splits)

lemma del_min_type:
  "t \<in> B h \<Longrightarrow> del_min t = Some (a, t') \<Longrightarrow> t' \<in> T h"
  "t \<in> U h \<Longrightarrow> del_min t = Some (a, t') \<Longrightarrow> t' \<in> Um h"
proof (induction h arbitrary: t a t')
  case (Suc h)
  { case 1
    then obtain t1 a t2 where [simp]: "t = N2 t1 a t2" and
      t12: "t1 \<in> T h" "t2 \<in> T h" "t1 \<in> B h \<or> t2 \<in> B h"
      by auto
    show ?case
    proof (cases "del_min t1")
      case None
      show ?thesis
      proof cases
        assume "t1 \<in> B h"
        with del_minNoneN0[OF this None] 1 show ?thesis by(auto)
      next
        assume "t1 \<notin> B h"
        thus ?thesis using 1 None by (auto)
      qed
    next
      case [simp]: (Some bt')
      obtain b t1' where [simp]: "bt' = (b,t1')" by fastforce
      show ?thesis
      proof cases
        assume "t1 \<in> B h"
        from Suc.IH(1)[OF this] 1 have "t1' \<in> T h" by simp
        from n2_type3[OF this t12(2)] 1 show ?thesis by auto
      next
        assume "t1 \<notin> B h"
        hence t1: "t1 \<in> U h" and t2: "t2 \<in> B h" using t12 by auto
        from Suc.IH(2)[OF t1] have "t1' \<in> Um h" by simp
        from n2_type1[OF this t2] 1 show ?thesis by auto
      qed
    qed
  }
  { case 2
    then obtain t1 where [simp]: "t = N1 t1" and t1: "t1 \<in> B h" by auto
    show ?case
    proof (cases "del_min t1")
      case None
      with del_minNoneN0[OF t1 None] 2 show ?thesis by(auto)
    next
      case [simp]: (Some bt')
      obtain b t1' where [simp]: "bt' = (b,t1')" by fastforce
      from Suc.IH(1)[OF t1] have "t1' \<in> T h" by simp
      thus ?thesis using 2 by auto
    qed
  }
qed auto

lemma del_type:
  "t \<in> B h \<Longrightarrow> del x t \<in> T h"
  "t \<in> U h \<Longrightarrow> del x t \<in> Um h"
proof (induction h arbitrary: x t)
  case (Suc h)
  { case 1
    then obtain l a r where [simp]: "t = N2 l a r" and
      lr: "l \<in> T h" "r \<in> T h" "l \<in> B h \<or> r \<in> B h" by auto
    { assume "x < a"
      have ?case
      proof cases
        assume "l \<in> B h"
        from n2_type3[OF Suc.IH(1)[OF this] lr(2)]
        show ?thesis using `x<a` by(simp)
      next
        assume "l \<notin> B h"
        hence "l \<in> U h" "r \<in> B h" using lr by auto
        from n2_type1[OF Suc.IH(2)[OF this(1)] this(2)]
        show ?thesis using `x<a` by(simp)
      qed
    } moreover
    { assume "x > a"
      have ?case
      proof cases
        assume "r \<in> B h"
        from n2_type3[OF lr(1) Suc.IH(1)[OF this]]
        show ?thesis using `x>a` by(simp)
      next
        assume "r \<notin> B h"
        hence "l \<in> B h" "r \<in> U h" using lr by auto
        from n2_type2[OF this(1) Suc.IH(2)[OF this(2)]]
        show ?thesis using `x>a` by(simp)
      qed
    } moreover
    { assume [simp]: "x=a"
      have ?case
      proof (cases "del_min r")
        case None
        show ?thesis
        proof cases
          assume "r \<in> B h"
          with del_minNoneN0[OF this None] lr show ?thesis by(simp)
        next
          assume "r \<notin> B h"
          hence "r \<in> U h" using lr by auto
          with del_minNoneN1[OF this None] lr(3) show ?thesis by (simp)
        qed
      next
        case [simp]: (Some br')
        obtain b r' where [simp]: "br' = (b,r')" by fastforce
        show ?thesis
        proof cases
          assume "r \<in> B h"
          from del_min_type(1)[OF this] n2_type3[OF lr(1)]
          show ?thesis by simp
        next
          assume "r \<notin> B h"
          hence "l \<in> B h" and "r \<in> U h" using lr by auto
          from del_min_type(2)[OF this(2)] n2_type2[OF this(1)]
          show ?thesis by simp
        qed
      qed
    } ultimately show ?case by auto
  }
  { case 2 with Suc.IH(1) show ?case by auto }
qed auto

lemma tree_type:
  "t \<in> Um (Suc h) \<Longrightarrow> tree t : T h"
  "t \<in> T (Suc h) \<Longrightarrow> tree t : T h \<union> T(h+1)"
by(auto)

lemma delete_type:
  "t \<in> T h \<Longrightarrow> delete x t \<in> T h \<union> T(h-1)"
unfolding delete_def
by (cases h) (simp, metis del_type tree_type Un_iff Suc_eq_plus1 diff_Suc_1)

end


subsection "Overall correctness"

interpretation Set_by_Ordered
where empty = N0 and isin = isin and insert = insert.insert
and delete = delete.delete and inorder = inorder and inv = "\<lambda>t. \<exists>h. t \<in> T h"
proof (standard, goal_cases)
  case 2 thus ?case by(auto intro!: isin_set)
next
  case 3 thus ?case by(auto intro!: insert.inorder_insert)
next
  case 4 thus ?case
    by(auto simp: delete.delete_def delete.inorder_tree delete.inorder_del)
next
  case 6 thus ?case using insert.insert_type by blast
next
  case 7 thus ?case using delete.delete_type by blast
qed auto

end

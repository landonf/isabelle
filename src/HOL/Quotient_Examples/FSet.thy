(*  Title:      HOL/Quotient_Examples/FSet.thy
    Author:     Cezary Kaliszyk, TU Munich
    Author:     Christian Urban, TU Munich

A reasoning infrastructure for the type of finite sets.
*)

theory FSet
imports Quotient_List
begin

text {* Definiton of List relation and the quotient type *}

fun
  list_eq :: "'a list \<Rightarrow> 'a list \<Rightarrow> bool" (infix "\<approx>" 50)
where
  "list_eq xs ys = (set xs = set ys)"

lemma list_eq_equivp:
  shows "equivp list_eq"
  unfolding equivp_reflp_symp_transp
  unfolding reflp_def symp_def transp_def
  by auto

quotient_type
  'a fset = "'a list" / "list_eq"
  by (rule list_eq_equivp)

text {* Raw definitions of membership, sublist, cardinality,
  intersection
*}

definition
  memb :: "'a \<Rightarrow> 'a list \<Rightarrow> bool"
where
  "memb x xs \<equiv> x \<in> set xs"

definition
  sub_list :: "'a list \<Rightarrow> 'a list \<Rightarrow> bool"
where
  "sub_list xs ys \<equiv> set xs \<subseteq> set ys"

definition
  fcard_raw :: "'a list \<Rightarrow> nat"
where
  "fcard_raw xs = card (set xs)"

primrec
  finter_raw :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list"
where
  "finter_raw [] ys = []"
| "finter_raw (x # xs) ys =
    (if x \<in> set ys then x # (finter_raw xs ys) else finter_raw xs ys)"

primrec
  fminus_raw :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list"
where
  "fminus_raw ys [] = ys"
| "fminus_raw ys (x # xs) = fminus_raw (removeAll x ys) xs"

definition
  rsp_fold
where
  "rsp_fold f = (\<forall>u v w. (f u (f v w) = f v (f u w)))"

primrec
  ffold_raw :: "('a \<Rightarrow> 'b \<Rightarrow> 'b) \<Rightarrow> 'b \<Rightarrow> 'a list \<Rightarrow> 'b"
where
  "ffold_raw f z [] = z"
| "ffold_raw f z (a # xs) =
     (if (rsp_fold f) then
       if a \<in> set xs then ffold_raw f z xs
       else f a (ffold_raw f z xs)
     else z)"

text {* Composition Quotient *}

lemma list_all2_refl1:
  shows "(list_all2 op \<approx>) r r"
  by (rule list_all2_refl) (metis equivp_def fset_equivp)

lemma compose_list_refl:
  shows "(list_all2 op \<approx> OOO op \<approx>) r r"
proof
  have *: "r \<approx> r" by (rule equivp_reflp[OF fset_equivp])
  show "list_all2 op \<approx> r r" by (rule list_all2_refl1)
  with * show "(op \<approx> OO list_all2 op \<approx>) r r" ..
qed

lemma Quotient_fset_list:
  shows "Quotient (list_all2 op \<approx>) (map abs_fset) (map rep_fset)"
  by (fact list_quotient[OF Quotient_fset])

lemma map_rel_cong: "b \<approx> ba \<Longrightarrow> map f b \<approx> map f ba"
  unfolding list_eq.simps
  by (simp only: set_map)

lemma quotient_compose_list[quot_thm]:
  shows  "Quotient ((list_all2 op \<approx>) OOO (op \<approx>))
    (abs_fset \<circ> (map abs_fset)) ((map rep_fset) \<circ> rep_fset)"
  unfolding Quotient_def comp_def
proof (intro conjI allI)
  fix a r s
  show "abs_fset (map abs_fset (map rep_fset (rep_fset a))) = a"
    by (simp add: abs_o_rep[OF Quotient_fset] Quotient_abs_rep[OF Quotient_fset] map_id)
  have b: "list_all2 op \<approx> (map rep_fset (rep_fset a)) (map rep_fset (rep_fset a))"
    by (rule list_all2_refl1)
  have c: "(op \<approx> OO list_all2 op \<approx>) (map rep_fset (rep_fset a)) (map rep_fset (rep_fset a))"
    by (rule, rule equivp_reflp[OF fset_equivp]) (rule b)
  show "(list_all2 op \<approx> OOO op \<approx>) (map rep_fset (rep_fset a)) (map rep_fset (rep_fset a))"
    by (rule, rule list_all2_refl1) (rule c)
  show "(list_all2 op \<approx> OOO op \<approx>) r s = ((list_all2 op \<approx> OOO op \<approx>) r r \<and>
        (list_all2 op \<approx> OOO op \<approx>) s s \<and> abs_fset (map abs_fset r) = abs_fset (map abs_fset s))"
  proof (intro iffI conjI)
    show "(list_all2 op \<approx> OOO op \<approx>) r r" by (rule compose_list_refl)
    show "(list_all2 op \<approx> OOO op \<approx>) s s" by (rule compose_list_refl)
  next
    assume a: "(list_all2 op \<approx> OOO op \<approx>) r s"
    then have b: "map abs_fset r \<approx> map abs_fset s"
    proof (elim pred_compE)
      fix b ba
      assume c: "list_all2 op \<approx> r b"
      assume d: "b \<approx> ba"
      assume e: "list_all2 op \<approx> ba s"
      have f: "map abs_fset r = map abs_fset b"
        using Quotient_rel[OF Quotient_fset_list] c by blast
      have "map abs_fset ba = map abs_fset s"
        using Quotient_rel[OF Quotient_fset_list] e by blast
      then have g: "map abs_fset s = map abs_fset ba" by simp
      then show "map abs_fset r \<approx> map abs_fset s" using d f map_rel_cong by simp
    qed
    then show "abs_fset (map abs_fset r) = abs_fset (map abs_fset s)"
      using Quotient_rel[OF Quotient_fset] by blast
  next
    assume a: "(list_all2 op \<approx> OOO op \<approx>) r r \<and> (list_all2 op \<approx> OOO op \<approx>) s s
      \<and> abs_fset (map abs_fset r) = abs_fset (map abs_fset s)"
    then have s: "(list_all2 op \<approx> OOO op \<approx>) s s" by simp
    have d: "map abs_fset r \<approx> map abs_fset s"
      by (subst Quotient_rel[OF Quotient_fset]) (simp add: a)
    have b: "map rep_fset (map abs_fset r) \<approx> map rep_fset (map abs_fset s)"
      by (rule map_rel_cong[OF d])
    have y: "list_all2 op \<approx> (map rep_fset (map abs_fset s)) s"
      by (fact rep_abs_rsp_left[OF Quotient_fset_list, OF list_all2_refl1[of s]])
    have c: "(op \<approx> OO list_all2 op \<approx>) (map rep_fset (map abs_fset r)) s"
      by (rule pred_compI) (rule b, rule y)
    have z: "list_all2 op \<approx> r (map rep_fset (map abs_fset r))"
      by (fact rep_abs_rsp[OF Quotient_fset_list, OF list_all2_refl1[of r]])
    then show "(list_all2 op \<approx> OOO op \<approx>) r s"
      using a c pred_compI by simp
  qed
qed


lemma set_finter_raw[simp]:
  "set (finter_raw xs ys) = set xs \<inter> set ys"
  by (induct xs) (auto simp add: memb_def)

lemma set_fminus_raw[simp]: 
  "set (fminus_raw xs ys) = (set xs - set ys)"
  by (induct ys arbitrary: xs) (auto)


text {* Respectfullness *}

lemma append_rsp[quot_respect]:
  shows "(op \<approx> ===> op \<approx> ===> op \<approx>) append append"
  by (simp)

lemma sub_list_rsp[quot_respect]:
  shows "(op \<approx> ===> op \<approx> ===> op =) sub_list sub_list"
  by (auto simp add: sub_list_def)

lemma memb_rsp[quot_respect]:
  shows "(op = ===> op \<approx> ===> op =) memb memb"
  by (auto simp add: memb_def)

lemma nil_rsp[quot_respect]:
  shows "(op \<approx>) Nil Nil"
  by simp

lemma cons_rsp[quot_respect]:
  shows "(op = ===> op \<approx> ===> op \<approx>) Cons Cons"
  by simp

lemma map_rsp[quot_respect]:
  shows "(op = ===> op \<approx> ===> op \<approx>) map map"
  by auto

lemma set_rsp[quot_respect]:
  "(op \<approx> ===> op =) set set"
  by auto

lemma list_equiv_rsp[quot_respect]:
  shows "(op \<approx> ===> op \<approx> ===> op =) op \<approx> op \<approx>"
  by auto

lemma finter_raw_rsp[quot_respect]:
  shows "(op \<approx> ===> op \<approx> ===> op \<approx>) finter_raw finter_raw"
  by simp

lemma removeAll_rsp[quot_respect]:
  shows "(op = ===> op \<approx> ===> op \<approx>) removeAll removeAll"
  by simp

lemma fminus_raw_rsp[quot_respect]:
  shows "(op \<approx> ===> op \<approx> ===> op \<approx>) fminus_raw fminus_raw"
  by simp

lemma fcard_raw_rsp[quot_respect]:
  shows "(op \<approx> ===> op =) fcard_raw fcard_raw"
  by (simp add: fcard_raw_def)



lemma not_memb_nil:
  shows "\<not> memb x []"
  by (simp add: memb_def)

lemma memb_cons_iff:
  shows "memb x (y # xs) = (x = y \<or> memb x xs)"
  by (induct xs) (auto simp add: memb_def)

lemma memb_absorb:
  shows "memb x xs \<Longrightarrow> x # xs \<approx> xs"
  by (induct xs) (auto simp add: memb_def)

lemma none_memb_nil:
  "(\<forall>x. \<not> memb x xs) = (xs \<approx> [])"
  by (simp add: memb_def)


lemma memb_commute_ffold_raw:
  "rsp_fold f \<Longrightarrow> h \<in> set b \<Longrightarrow> ffold_raw f z b = f h (ffold_raw f z (removeAll h b))"
  apply (induct b)
  apply (auto simp add: rsp_fold_def)
  done

lemma ffold_raw_rsp_pre:
  "set a = set b \<Longrightarrow> ffold_raw f z a = ffold_raw f z b"
  apply (induct a arbitrary: b)
  apply (simp)
  apply (simp (no_asm_use))
  apply (rule conjI)
  apply (rule_tac [!] impI)
  apply (rule_tac [!] conjI)
  apply (rule_tac [!] impI)
  apply (metis insert_absorb)
  apply (metis List.insert_def List.set.simps(2) List.set_insert ffold_raw.simps(2))
  apply (metis Diff_insert_absorb insertI1 memb_commute_ffold_raw set_removeAll)
  apply(drule_tac x="removeAll a1 b" in meta_spec)
  apply(auto)
  apply(drule meta_mp)
  apply(blast)
  by (metis List.set.simps(2) emptyE ffold_raw.simps(2) in_listsp_conv_set listsp.simps mem_def)

lemma ffold_raw_rsp[quot_respect]:
  shows "(op = ===> op = ===> op \<approx> ===> op =) ffold_raw ffold_raw"
  unfolding fun_rel_def
  by(auto intro: ffold_raw_rsp_pre)

lemma concat_rsp_pre:
  assumes a: "list_all2 op \<approx> x x'"
  and     b: "x' \<approx> y'"
  and     c: "list_all2 op \<approx> y' y"
  and     d: "\<exists>x\<in>set x. xa \<in> set x"
  shows "\<exists>x\<in>set y. xa \<in> set x"
proof -
  obtain xb where e: "xb \<in> set x" and f: "xa \<in> set xb" using d by auto
  have "\<exists>y. y \<in> set x' \<and> xb \<approx> y" by (rule list_all2_find_element[OF e a])
  then obtain ya where h: "ya \<in> set x'" and i: "xb \<approx> ya" by auto
  have "ya \<in> set y'" using b h by simp
  then have "\<exists>yb. yb \<in> set y \<and> ya \<approx> yb" using c by (rule list_all2_find_element)
  then show ?thesis using f i by auto
qed

lemma concat_rsp[quot_respect]:
  shows "(list_all2 op \<approx> OOO op \<approx> ===> op \<approx>) concat concat"
proof (rule fun_relI, elim pred_compE)
  fix a b ba bb
  assume a: "list_all2 op \<approx> a ba"
  assume b: "ba \<approx> bb"
  assume c: "list_all2 op \<approx> bb b"
  have "\<forall>x. (\<exists>xa\<in>set a. x \<in> set xa) = (\<exists>xa\<in>set b. x \<in> set xa)" 
  proof
    fix x
    show "(\<exists>xa\<in>set a. x \<in> set xa) = (\<exists>xa\<in>set b. x \<in> set xa)" 
    proof
      assume d: "\<exists>xa\<in>set a. x \<in> set xa"
      show "\<exists>xa\<in>set b. x \<in> set xa" by (rule concat_rsp_pre[OF a b c d])
    next
      assume e: "\<exists>xa\<in>set b. x \<in> set xa"
      have a': "list_all2 op \<approx> ba a" by (rule list_all2_symp[OF list_eq_equivp, OF a])
      have b': "bb \<approx> ba" by (rule equivp_symp[OF list_eq_equivp, OF b])
      have c': "list_all2 op \<approx> b bb" by (rule list_all2_symp[OF list_eq_equivp, OF c])
      show "\<exists>xa\<in>set a. x \<in> set xa" by (rule concat_rsp_pre[OF c' b' a' e])
    qed
  qed
  then show "concat a \<approx> concat b" by auto
qed

lemma [quot_respect]:
  shows "((op =) ===> op \<approx> ===> op \<approx>) filter filter"
  by auto

text {* Distributive lattice with bot *}

lemma append_inter_distrib:
  "x @ (finter_raw y z) \<approx> finter_raw (x @ y) (x @ z)"
  apply (induct x)
  apply (auto)
  done

instantiation fset :: (type) "{bounded_lattice_bot, distrib_lattice, minus}"
begin

quotient_definition
  "bot :: 'a fset" is "[] :: 'a list"

abbreviation
  fempty  ("{||}")
where
  "{||} \<equiv> bot :: 'a fset"

quotient_definition
  "less_eq_fset \<Colon> ('a fset \<Rightarrow> 'a fset \<Rightarrow> bool)"
is
  "sub_list \<Colon> ('a list \<Rightarrow> 'a list \<Rightarrow> bool)"

abbreviation
  f_subset_eq :: "'a fset \<Rightarrow> 'a fset \<Rightarrow> bool" (infix "|\<subseteq>|" 50)
where
  "xs |\<subseteq>| ys \<equiv> xs \<le> ys"

definition
  less_fset :: "'a fset \<Rightarrow> 'a fset \<Rightarrow> bool"
where  
  "xs < ys \<equiv> xs \<le> ys \<and> xs \<noteq> (ys::'a fset)"

abbreviation
  fsubset :: "'a fset \<Rightarrow> 'a fset \<Rightarrow> bool" (infix "|\<subset>|" 50)
where
  "xs |\<subset>| ys \<equiv> xs < ys"

quotient_definition
  "sup :: 'a fset \<Rightarrow> 'a fset \<Rightarrow> 'a fset"
is
  "append :: 'a list \<Rightarrow> 'a list \<Rightarrow> 'a list"

abbreviation
  funion (infixl "|\<union>|" 65)
where
  "xs |\<union>| ys \<equiv> sup (xs :: 'a fset) ys"

quotient_definition
  "inf :: 'a fset \<Rightarrow> 'a fset \<Rightarrow> 'a fset"
is
  "finter_raw :: 'a list \<Rightarrow> 'a list \<Rightarrow> 'a list"

abbreviation
  finter (infixl "|\<inter>|" 65)
where
  "xs |\<inter>| ys \<equiv> inf (xs :: 'a fset) ys"

quotient_definition
  "minus :: 'a fset \<Rightarrow> 'a fset \<Rightarrow> 'a fset"
is
  "fminus_raw :: 'a list \<Rightarrow> 'a list \<Rightarrow> 'a list"

instance
proof
  fix x y z :: "'a fset"
  show "x |\<subset>| y \<longleftrightarrow> x |\<subseteq>| y \<and> \<not> y |\<subseteq>| x"
    unfolding less_fset_def 
    by (descending) (auto simp add: sub_list_def)
  show "x |\<subseteq>| x"  by (descending) (simp add: sub_list_def)
  show "{||} |\<subseteq>| x" by (descending) (simp add: sub_list_def)
  show "x |\<subseteq>| x |\<union>| y" by (descending) (simp add: sub_list_def)
  show "y |\<subseteq>| x |\<union>| y" by (descending) (simp add: sub_list_def)
  show "x |\<inter>| y |\<subseteq>| x"
    by (descending) (simp add: sub_list_def memb_def[symmetric])
  show "x |\<inter>| y |\<subseteq>| y" 
    by (descending) (simp add: sub_list_def memb_def[symmetric])
  show "x |\<union>| (y |\<inter>| z) = x |\<union>| y |\<inter>| (x |\<union>| z)" 
    by (descending) (rule append_inter_distrib)
next
  fix x y z :: "'a fset"
  assume a: "x |\<subseteq>| y"
  assume b: "y |\<subseteq>| z"
  show "x |\<subseteq>| z" using a b 
    by (descending) (simp add: sub_list_def)
next
  fix x y :: "'a fset"
  assume a: "x |\<subseteq>| y"
  assume b: "y |\<subseteq>| x"
  show "x = y" using a b 
    by (descending) (unfold sub_list_def list_eq.simps, blast)
next
  fix x y z :: "'a fset"
  assume a: "y |\<subseteq>| x"
  assume b: "z |\<subseteq>| x"
  show "y |\<union>| z |\<subseteq>| x" using a b 
    by (descending) (simp add: sub_list_def)
next
  fix x y z :: "'a fset"
  assume a: "x |\<subseteq>| y"
  assume b: "x |\<subseteq>| z"
  show "x |\<subseteq>| y |\<inter>| z" using a b 
    by (descending) (simp add: sub_list_def memb_def[symmetric])
qed

end

section {* Finsert and Membership *}

quotient_definition
  "finsert :: 'a \<Rightarrow> 'a fset \<Rightarrow> 'a fset"
is "Cons"

syntax
  "@Finset"     :: "args => 'a fset"  ("{|(_)|}")

translations
  "{|x, xs|}" == "CONST finsert x {|xs|}"
  "{|x|}"     == "CONST finsert x {||}"

quotient_definition
  fin (infix "|\<in>|" 50)
where
  "fin :: 'a \<Rightarrow> 'a fset \<Rightarrow> bool" is "memb"

abbreviation
  fnotin :: "'a \<Rightarrow> 'a fset \<Rightarrow> bool" (infix "|\<notin>|" 50)
where
  "x |\<notin>| S \<equiv> \<not> (x |\<in>| S)"

section {* Other constants on the Quotient Type *}

quotient_definition
  "fcard :: 'a fset \<Rightarrow> nat"
is
  fcard_raw

quotient_definition
  "fmap :: ('a \<Rightarrow> 'b) \<Rightarrow> 'a fset \<Rightarrow> 'b fset"
is
  map

quotient_definition
  "fdelete :: 'a \<Rightarrow> 'a fset \<Rightarrow> 'a fset"
  is removeAll

quotient_definition
  "fset :: 'a fset \<Rightarrow> 'a set"
  is "set"

quotient_definition
  "ffold :: ('a \<Rightarrow> 'b \<Rightarrow> 'b) \<Rightarrow> 'b \<Rightarrow> 'a fset \<Rightarrow> 'b"
  is "ffold_raw"

quotient_definition
  "fconcat :: ('a fset) fset \<Rightarrow> 'a fset"
is
  "concat"

quotient_definition
  "ffilter :: ('a \<Rightarrow> bool) \<Rightarrow> 'a fset \<Rightarrow> 'a fset"
is
  "filter"

text {* Compositional Respectfullness and Preservation *}

lemma [quot_respect]: "(list_all2 op \<approx> OOO op \<approx>) [] []"
  by (fact compose_list_refl)

lemma [quot_preserve]: "(abs_fset \<circ> map f) [] = abs_fset []"
  by simp

lemma [quot_respect]:
  shows "(op \<approx> ===> list_all2 op \<approx> OOO op \<approx> ===> list_all2 op \<approx> OOO op \<approx>) Cons Cons"
  apply auto
  apply (rule_tac b="x # b" in pred_compI)
  apply auto
  apply (rule_tac b="x # ba" in pred_compI)
  apply auto
  done

lemma [quot_preserve]:
  "(rep_fset ---> (map rep_fset \<circ> rep_fset) ---> (abs_fset \<circ> map abs_fset)) op # = finsert"
  by (simp add: fun_eq_iff Quotient_abs_rep[OF Quotient_fset]
      abs_o_rep[OF Quotient_fset] map_id finsert_def)

lemma [quot_preserve]:
  "((map rep_fset \<circ> rep_fset) ---> (map rep_fset \<circ> rep_fset) ---> (abs_fset \<circ> map abs_fset)) op @ = funion"
  by (simp add: fun_eq_iff Quotient_abs_rep[OF Quotient_fset]
      abs_o_rep[OF Quotient_fset] map_id sup_fset_def)

lemma list_all2_app_l:
  assumes a: "reflp R"
  and b: "list_all2 R l r"
  shows "list_all2 R (z @ l) (z @ r)"
  by (induct z) (simp_all add: b rev_iffD1[OF a meta_eq_to_obj_eq[OF reflp_def]])

lemma append_rsp2_pre0:
  assumes a:"list_all2 op \<approx> x x'"
  shows "list_all2 op \<approx> (x @ z) (x' @ z)"
  using a apply (induct x x' rule: list_induct2')
  by simp_all (rule list_all2_refl1)

lemma append_rsp2_pre1:
  assumes a:"list_all2 op \<approx> x x'"
  shows "list_all2 op \<approx> (z @ x) (z @ x')"
  using a apply (induct x x' arbitrary: z rule: list_induct2')
  apply (rule list_all2_refl1)
  apply (simp_all del: list_eq.simps)
  apply (rule list_all2_app_l)
  apply (simp_all add: reflp_def)
  done

lemma append_rsp2_pre:
  assumes a:"list_all2 op \<approx> x x'"
  and     b: "list_all2 op \<approx> z z'"
  shows "list_all2 op \<approx> (x @ z) (x' @ z')"
  apply (rule list_all2_transp[OF fset_equivp])
  apply (rule append_rsp2_pre0)
  apply (rule a)
  using b apply (induct z z' rule: list_induct2')
  apply (simp_all only: append_Nil2)
  apply (rule list_all2_refl1)
  apply simp_all
  apply (rule append_rsp2_pre1)
  apply simp
  done

lemma [quot_respect]:
  "(list_all2 op \<approx> OOO op \<approx> ===> list_all2 op \<approx> OOO op \<approx> ===> list_all2 op \<approx> OOO op \<approx>) op @ op @"
proof (intro fun_relI, elim pred_compE)
  fix x y z w x' z' y' w' :: "'a list list"
  assume a:"list_all2 op \<approx> x x'"
  and b:    "x' \<approx> y'"
  and c:    "list_all2 op \<approx> y' y"
  assume aa: "list_all2 op \<approx> z z'"
  and bb:   "z' \<approx> w'"
  and cc:   "list_all2 op \<approx> w' w"
  have a': "list_all2 op \<approx> (x @ z) (x' @ z')" using a aa append_rsp2_pre by auto
  have b': "x' @ z' \<approx> y' @ w'" using b bb by simp
  have c': "list_all2 op \<approx> (y' @ w') (y @ w)" using c cc append_rsp2_pre by auto
  have d': "(op \<approx> OO list_all2 op \<approx>) (x' @ z') (y @ w)"
    by (rule pred_compI) (rule b', rule c')
  show "(list_all2 op \<approx> OOO op \<approx>) (x @ z) (y @ w)"
    by (rule pred_compI) (rule a', rule d')
qed

text {* Raw theorems. Finsert, memb, singleron, sub_list *}

lemma nil_not_cons:
  shows "\<not> ([] \<approx> x # xs)"
  and   "\<not> (x # xs \<approx> [])"
  by auto

lemma no_memb_nil:
  "(\<forall>x. \<not> memb x xs) = (xs = [])"
  by (simp add: memb_def)

lemma memb_consI1:
  shows "memb x (x # xs)"
  by (simp add: memb_def)

lemma memb_consI2:
  shows "memb x xs \<Longrightarrow> memb x (y # xs)"
  by (simp add: memb_def)

lemma singleton_list_eq:
  shows "[x] \<approx> [y] \<longleftrightarrow> x = y"
  by (simp)

lemma sub_list_cons:
  "sub_list (x # xs) ys = (memb x ys \<and> sub_list xs ys)"
  by (auto simp add: memb_def sub_list_def)

lemma fminus_raw_red: 
  "fminus_raw (x # xs) ys = (if x \<in> set ys then fminus_raw xs ys else x # (fminus_raw xs ys))"
  by (induct ys arbitrary: xs x) (simp_all)

text {* Cardinality of finite sets *}

lemma fcard_raw_0:
  shows "fcard_raw xs = 0 \<longleftrightarrow> xs \<approx> []"
  unfolding fcard_raw_def
  by (induct xs) (auto)

lemma memb_card_not_0:
  assumes a: "memb a A"
  shows "\<not>(fcard_raw A = 0)"
proof -
  have "\<not>(\<forall>x. \<not> memb x A)" using a by auto
  then have "\<not>A \<approx> []" using none_memb_nil[of A] by simp
  then show ?thesis using fcard_raw_0[of A] by simp
qed

text {* fmap *}

lemma map_append:
  "map f (xs @ ys) \<approx> (map f xs) @ (map f ys)"
  by simp

lemma memb_append:
  "memb x (xs @ ys) \<longleftrightarrow> memb x xs \<or> memb x ys"
  by (induct xs) (simp_all add: not_memb_nil memb_cons_iff)

lemma fset_raw_strong_cases:
  obtains "xs = []"
    | x ys where "\<not> memb x ys" and "xs \<approx> x # ys"
proof (induct xs arbitrary: x ys)
  case Nil
  then show thesis by simp
next
  case (Cons a xs)
  have a: "\<lbrakk>xs = [] \<Longrightarrow> thesis; \<And>x ys. \<lbrakk>\<not> memb x ys; xs \<approx> x # ys\<rbrakk> \<Longrightarrow> thesis\<rbrakk> \<Longrightarrow> thesis" by fact
  have b: "\<And>x' ys'. \<lbrakk>\<not> memb x' ys'; a # xs \<approx> x' # ys'\<rbrakk> \<Longrightarrow> thesis" by fact
  have c: "xs = [] \<Longrightarrow> thesis" by (metis no_memb_nil singleton_list_eq b)
  have "\<And>x ys. \<lbrakk>\<not> memb x ys; xs \<approx> x # ys\<rbrakk> \<Longrightarrow> thesis"
  proof -
    fix x :: 'a
    fix ys :: "'a list"
    assume d:"\<not> memb x ys"
    assume e:"xs \<approx> x # ys"
    show thesis
    proof (cases "x = a")
      assume h: "x = a"
      then have f: "\<not> memb a ys" using d by simp
      have g: "a # xs \<approx> a # ys" using e h by auto
      show thesis using b f g by simp
    next
      assume h: "x \<noteq> a"
      then have f: "\<not> memb x (a # ys)" using d unfolding memb_def by auto
      have g: "a # xs \<approx> x # (a # ys)" using e h by auto
      show thesis using b f g by simp
    qed
  qed
  then show thesis using a c by blast
qed

section {* deletion *}


lemma fset_raw_removeAll_cases:
  "xs = [] \<or> (\<exists>x. memb x xs \<and> xs \<approx> x # removeAll x xs)"
  by (induct xs) (auto simp add: memb_def)

lemma fremoveAll_filter:
  "removeAll y xs = [x \<leftarrow> xs. x \<noteq> y]"
  by (induct xs) simp_all

lemma fcard_raw_delete:
  "fcard_raw (removeAll y xs) = (if memb y xs then fcard_raw xs - 1 else fcard_raw xs)"
  by (auto simp add: fcard_raw_def memb_def)

lemma set_cong:
  shows "(x \<approx> y) = (set x = set y)"
  by auto

lemma inj_map_eq_iff:
  "inj f \<Longrightarrow> (map f l \<approx> map f m) = (l \<approx> m)"
  by (simp add: set_eq_iff[symmetric] inj_image_eq_iff)

text {* alternate formulation with a different decomposition principle
  and a proof of equivalence *}

inductive
  list_eq2
where
  "list_eq2 (a # b # xs) (b # a # xs)"
| "list_eq2 [] []"
| "list_eq2 xs ys \<Longrightarrow> list_eq2 ys xs"
| "list_eq2 (a # a # xs) (a # xs)"
| "list_eq2 xs ys \<Longrightarrow> list_eq2 (a # xs) (a # ys)"
| "\<lbrakk>list_eq2 xs1 xs2; list_eq2 xs2 xs3\<rbrakk> \<Longrightarrow> list_eq2 xs1 xs3"

lemma list_eq2_refl:
  shows "list_eq2 xs xs"
  by (induct xs) (auto intro: list_eq2.intros)

lemma cons_delete_list_eq2:
  shows "list_eq2 (a # (removeAll a A)) (if memb a A then A else a # A)"
  apply (induct A)
  apply (simp add: memb_def list_eq2_refl)
  apply (case_tac "memb a (aa # A)")
  apply (simp_all only: memb_cons_iff)
  apply (case_tac [!] "a = aa")
  apply (simp_all)
  apply (case_tac "memb a A")
  apply (auto simp add: memb_def)[2]
  apply (metis list_eq2.intros(3) list_eq2.intros(4) list_eq2.intros(5) list_eq2.intros(6))
  apply (metis list_eq2.intros(1) list_eq2.intros(5) list_eq2.intros(6))
  apply (auto simp add: list_eq2_refl memb_def)
  done

lemma memb_delete_list_eq2:
  assumes a: "memb e r"
  shows "list_eq2 (e # removeAll e r) r"
  using a cons_delete_list_eq2[of e r]
  by simp

lemma list_eq2_equiv:
  "(l \<approx> r) \<longleftrightarrow> (list_eq2 l r)"
proof
  show "list_eq2 l r \<Longrightarrow> l \<approx> r" by (induct rule: list_eq2.induct) auto
next
  {
    fix n
    assume a: "fcard_raw l = n" and b: "l \<approx> r"
    have "list_eq2 l r"
      using a b
    proof (induct n arbitrary: l r)
      case 0
      have "fcard_raw l = 0" by fact
      then have "\<forall>x. \<not> memb x l" using memb_card_not_0[of _ l] by auto
      then have z: "l = []" using no_memb_nil by auto
      then have "r = []" using `l \<approx> r` by simp
      then show ?case using z list_eq2_refl by simp
    next
      case (Suc m)
      have b: "l \<approx> r" by fact
      have d: "fcard_raw l = Suc m" by fact
      then have "\<exists>a. memb a l" 
	apply(simp add: fcard_raw_def memb_def)
	apply(drule card_eq_SucD)
	apply(blast)
	done
      then obtain a where e: "memb a l" by auto
      then have e': "memb a r" using list_eq.simps[simplified memb_def[symmetric], of l r] b 
	unfolding memb_def by auto
      have f: "fcard_raw (removeAll a l) = m" using fcard_raw_delete[of a l] e d by simp
      have g: "removeAll a l \<approx> removeAll a r" using removeAll_rsp b by simp
      have "list_eq2 (removeAll a l) (removeAll a r)" by (rule Suc.hyps[OF f g])
      then have h: "list_eq2 (a # removeAll a l) (a # removeAll a r)" by (rule list_eq2.intros(5))
      have i: "list_eq2 l (a # removeAll a l)"
        by (rule list_eq2.intros(3)[OF memb_delete_list_eq2[OF e]])
      have "list_eq2 l (a # removeAll a r)" by (rule list_eq2.intros(6)[OF i h])
      then show ?case using list_eq2.intros(6)[OF _ memb_delete_list_eq2[OF e']] by simp
    qed
    }
  then show "l \<approx> r \<Longrightarrow> list_eq2 l r" by blast
qed

text {* Lifted theorems *}

lemma not_fin_fnil: "x |\<notin>| {||}"
  by (descending) (simp add: memb_def)

lemma fin_finsert_iff[simp]:
  "x |\<in>| finsert y S \<longleftrightarrow> x = y \<or> x |\<in>| S"
  by (descending) (simp add: memb_def)

lemma
  shows finsertI1: "x |\<in>| finsert x S"
  and   finsertI2: "x |\<in>| S \<Longrightarrow> x |\<in>| finsert y S"
  by (lifting memb_consI1 memb_consI2)

lemma finsert_absorb[simp]:
  shows "x |\<in>| S \<Longrightarrow> finsert x S = S"
  by (descending) (auto simp add: memb_def)

lemma fempty_not_finsert[simp]:
  "{||} \<noteq> finsert x S"
  "finsert x S \<noteq> {||}"
  by (lifting nil_not_cons)

lemma finsert_left_comm:
  "finsert x (finsert y S) = finsert y (finsert x S)"
  by (descending) (auto)

lemma finsert_left_idem:
  "finsert x (finsert x S) = finsert x S"
  by (descending) (auto)

lemma fsingleton_eq[simp]:
  shows "{|x|} = {|y|} \<longleftrightarrow> x = y"
  by (descending) (auto)


text {* fset *}

lemma fset_simps[simp]:
  "fset {||} = ({} :: 'a set)"
  "fset (finsert (h :: 'a) t) = insert h (fset t)"
  by (lifting set.simps)

lemma in_fset:
  "x \<in> fset S \<equiv> x |\<in>| S"
  by (lifting memb_def[symmetric])

lemma none_fin_fempty:
  "(\<forall>x. x |\<notin>| S) \<longleftrightarrow> S = {||}"
  by (lifting none_memb_nil)

lemma fset_cong:
  "S = T \<longleftrightarrow> fset S = fset T"
  by (lifting set_cong)


text {* fcard *}

lemma fcard_finsert_if [simp]:
  shows "fcard (finsert x S) = (if x |\<in>| S then fcard S else Suc (fcard S))"
  by (descending) (auto simp add: fcard_raw_def memb_def insert_absorb)

lemma fcard_0[simp]:
  shows "fcard S = 0 \<longleftrightarrow> S = {||}"
  by (descending) (simp add: fcard_raw_def)

lemma fcard_fempty[simp]:
  shows "fcard {||} = 0"
  by (simp add: fcard_0)

lemma fcard_1:
  shows "fcard S = 1 \<longleftrightarrow> (\<exists>x. S = {|x|})"
  by (descending) (auto simp add: fcard_raw_def card_Suc_eq)

lemma fcard_gt_0:
  shows "x \<in> fset S \<Longrightarrow> 0 < fcard S"
  by (descending) (auto simp add: fcard_raw_def card_gt_0_iff)
  
lemma fcard_not_fin:
  shows "(x |\<notin>| S) = (fcard (finsert x S) = Suc (fcard S))"
  by (descending) (auto simp add: memb_def fcard_raw_def insert_absorb)

lemma fcard_suc: "fcard S = Suc n \<Longrightarrow> \<exists>x T. x |\<notin>| T \<and> S = finsert x T \<and> fcard T = n"
  apply descending
  apply(simp add: fcard_raw_def memb_def)
  apply(drule card_eq_SucD)
  apply(auto)
  apply(rule_tac x="b" in exI)
  apply(rule_tac x="removeAll b S" in exI)
  apply(auto)
  done

lemma fcard_delete:
  "fcard (fdelete y S) = (if y |\<in>| S then fcard S - 1 else fcard S)"
  by (lifting fcard_raw_delete)

lemma fcard_suc_memb: 
  shows "fcard A = Suc n \<Longrightarrow> \<exists>a. a |\<in>| A"
  apply(descending)
  apply(simp add: fcard_raw_def memb_def)
  apply(drule card_eq_SucD)
  apply(auto)
  done

lemma fin_fcard_not_0: 
  shows "a |\<in>| A \<Longrightarrow> fcard A \<noteq> 0"
  by (descending) (auto simp add: fcard_raw_def memb_def)


text {* funion *}

lemmas [simp] =
  sup_bot_left[where 'a="'a fset", standard]
  sup_bot_right[where 'a="'a fset", standard]

lemma funion_finsert[simp]:
  shows "finsert x S |\<union>| T = finsert x (S |\<union>| T)"
  by (lifting append.simps(2))

lemma singleton_union_left:
  shows "{|a|} |\<union>| S = finsert a S"
  by simp

lemma singleton_union_right:
  shows "S |\<union>| {|a|} = finsert a S"
  by (subst sup.commute) simp


section {* Induction and Cases rules for fsets *}

lemma fset_strong_cases:
  obtains "xs = {||}"
    | x ys where "x |\<notin>| ys" and "xs = finsert x ys"
  by (lifting fset_raw_strong_cases)

lemma fset_exhaust[case_names fempty finsert, cases type: fset]:
  shows "\<lbrakk>S = {||} \<Longrightarrow> P; \<And>x S'. S = finsert x S' \<Longrightarrow> P\<rbrakk> \<Longrightarrow> P"
  by (lifting list.exhaust)

lemma fset_induct_weak[case_names fempty finsert]:
  shows "\<lbrakk>P {||}; \<And>x S. P S \<Longrightarrow> P (finsert x S)\<rbrakk> \<Longrightarrow> P S"
  by (lifting list.induct)

lemma fset_induct[case_names fempty finsert, induct type: fset]:
  assumes prem1: "P {||}"
  and     prem2: "\<And>x S. \<lbrakk>x |\<notin>| S; P S\<rbrakk> \<Longrightarrow> P (finsert x S)"
  shows "P S"
proof(induct S rule: fset_induct_weak)
  case fempty
  show "P {||}" by (rule prem1)
next
  case (finsert x S)
  have asm: "P S" by fact
  show "P (finsert x S)"
    by (cases "x |\<in>| S") (simp_all add: asm prem2)
qed

lemma fset_induct2:
  "P {||} {||} \<Longrightarrow>
  (\<And>x xs. x |\<notin>| xs \<Longrightarrow> P (finsert x xs) {||}) \<Longrightarrow>
  (\<And>y ys. y |\<notin>| ys \<Longrightarrow> P {||} (finsert y ys)) \<Longrightarrow>
  (\<And>x xs y ys. \<lbrakk>P xs ys; x |\<notin>| xs; y |\<notin>| ys\<rbrakk> \<Longrightarrow> P (finsert x xs) (finsert y ys)) \<Longrightarrow>
  P xsa ysa"
  apply (induct xsa arbitrary: ysa)
  apply (induct_tac x rule: fset_induct)
  apply simp_all
  apply (induct_tac xa rule: fset_induct)
  apply simp_all
  done

lemma fset_fcard_induct:
  assumes a: "P {||}"
  and     b: "\<And>xs ys. Suc (fcard xs) = (fcard ys) \<Longrightarrow> P xs \<Longrightarrow> P ys"
  shows "P zs"
proof (induct zs)
  show "P {||}" by (rule a)
next
  fix x :: 'a and zs :: "'a fset"
  assume h: "P zs"
  assume "x |\<notin>| zs"
  then have H1: "Suc (fcard zs) = fcard (finsert x zs)" using fcard_suc by auto
  then show "P (finsert x zs)" using b h by simp
qed

text {* fmap *}

lemma fmap_simps[simp]:
  fixes f::"'a \<Rightarrow> 'b"
  shows "fmap f {||} = {||}"
  and   "fmap f (finsert x S) = finsert (f x) (fmap f S)"
  by (lifting map.simps)

lemma fmap_set_image:
  "fset (fmap f S) = f ` (fset S)"
  by (induct S) simp_all

lemma inj_fmap_eq_iff:
  "inj f \<Longrightarrow> fmap f S = fmap f T \<longleftrightarrow> S = T"
  by (lifting inj_map_eq_iff)

lemma fmap_funion: 
  shows "fmap f (S |\<union>| T) = fmap f S |\<union>| fmap f T"
  by (lifting map_append)

lemma fin_funion:
  shows "x |\<in>| S |\<union>| T \<longleftrightarrow> x |\<in>| S \<or> x |\<in>| T"
  by (lifting memb_append)


section {* fset *}

lemma fin_set: 
  shows "x |\<in>| xs \<longleftrightarrow> x \<in> fset xs"
  by (lifting memb_def)

lemma fnotin_set: 
  shows "x |\<notin>| xs \<longleftrightarrow> x \<notin> fset xs"
  by (simp add: fin_set)

lemma fcard_set: 
  shows "fcard xs = card (fset xs)"
  by (lifting fcard_raw_def)

lemma fsubseteq_set: 
  shows "xs |\<subseteq>| ys \<longleftrightarrow> fset xs \<subseteq> fset ys"
  by (lifting sub_list_def)

lemma fsubset_set: 
  shows "xs |\<subset>| ys \<longleftrightarrow> fset xs \<subset> fset ys"
  unfolding less_fset_def 
  by (descending) (auto simp add: sub_list_def)

lemma ffilter_set [simp]: 
  shows "fset (ffilter P xs) = P \<inter> fset xs"
  by (descending) (auto simp add: mem_def)

lemma fdelete_set [simp]: 
  shows "fset (fdelete x xs) = fset xs - {x}"
  by (lifting set_removeAll)

lemma finter_set [simp]: 
  shows "fset (xs |\<inter>| ys) = fset xs \<inter> fset ys"
  by (lifting set_finter_raw)

lemma funion_set [simp]: 
  shows "fset (xs |\<union>| ys) = fset xs \<union> fset ys"
  by (lifting set_append)

lemma fminus_set [simp]: 
  shows "fset (xs - ys) = fset xs - fset ys"
  by (lifting set_fminus_raw)

lemmas fset_to_set_trans =
  fin_set fnotin_set fcard_set fsubseteq_set fsubset_set
  finter_set funion_set ffilter_set fset_simps
  fset_cong fdelete_set fmap_set_image fminus_set


text {* ffold *}

lemma ffold_nil: 
  shows "ffold f z {||} = z"
  by (lifting ffold_raw.simps(1)[where 'a="'b" and 'b="'a"])

lemma ffold_finsert: "ffold f z (finsert a A) =
  (if rsp_fold f then if a |\<in>| A then ffold f z A else f a (ffold f z A) else z)"
  by (descending) (simp add: memb_def)

lemma fin_commute_ffold:
  "\<lbrakk>rsp_fold f; h |\<in>| b\<rbrakk> \<Longrightarrow> ffold f z b = f h (ffold f z (fdelete h b))"
  by (descending) (simp add: memb_def memb_commute_ffold_raw)


text {* fdelete *}

lemma fin_fdelete:
  shows "x |\<in>| fdelete y S \<longleftrightarrow> x |\<in>| S \<and> x \<noteq> y"
  by (descending) (simp add: memb_def)

lemma fnotin_fdelete:
  shows "x |\<notin>| fdelete x S"
  by (descending) (simp add: memb_def)

lemma fnotin_fdelete_ident:
  shows "x |\<notin>| S \<Longrightarrow> fdelete x S = S"
  by (descending) (simp add: memb_def)

lemma fset_fdelete_cases:
  shows "S = {||} \<or> (\<exists>x. x |\<in>| S \<and> S = finsert x (fdelete x S))"
  by (lifting fset_raw_removeAll_cases)

text {* finite intersection *}

lemma finter_empty_l:
  shows "{||} |\<inter>| S = {||}"
  by simp


lemma finter_empty_r:
  shows "S |\<inter>| {||} = {||}"
  by simp

lemma finter_finsert:
  shows "finsert x S |\<inter>| T = (if x |\<in>| T then finsert x (S |\<inter>| T) else S |\<inter>| T)"
  by (descending) (simp add: memb_def)

lemma fin_finter:
  shows "x |\<in>| (S |\<inter>| T) \<longleftrightarrow> x |\<in>| S \<and> x |\<in>| T"
  by (descending) (simp add: memb_def)

lemma fsubset_finsert:
  shows "finsert x xs |\<subseteq>| ys \<longleftrightarrow> x |\<in>| ys \<and> xs |\<subseteq>| ys"
  by (lifting sub_list_cons)

lemma 
  shows "xs |\<subseteq>| ys \<equiv> \<forall>x. x |\<in>| xs \<longrightarrow> x |\<in>| ys"
  by (descending) (auto simp add: sub_list_def memb_def)

lemma fsubset_fin: 
  shows "xs |\<subseteq>| ys = (\<forall>x. x |\<in>| xs \<longrightarrow> x |\<in>| ys)"
  by (descending) (auto simp add: sub_list_def memb_def)

lemma fminus_fin: 
  shows "x |\<in>| xs - ys \<longleftrightarrow> x |\<in>| xs \<and> x |\<notin>| ys"
  by (descending) (simp add: memb_def)

lemma fminus_red: 
  shows "finsert x xs - ys = (if x |\<in>| ys then xs - ys else finsert x (xs - ys))"
  by (descending) (auto simp add: memb_def)

lemma fminus_red_fin [simp]: 
  shows "x |\<in>| ys \<Longrightarrow> finsert x xs - ys = xs - ys"
  by (simp add: fminus_red)

lemma fminus_red_fnotin[simp]: 
  shows "x |\<notin>| ys \<Longrightarrow> finsert x xs - ys = finsert x (xs - ys)"
  by (simp add: fminus_red)

lemma fset_eq_iff:
  shows "S = T \<longleftrightarrow> (\<forall>x. (x |\<in>| S) = (x |\<in>| T))"
  by (descending) (auto simp add: memb_def)

(* We cannot write it as "assumes .. shows" since Isabelle changes
   the quantifiers to schematic variables and reintroduces them in
   a different order *)
lemma fset_eq_cases:
 "\<lbrakk>a1 = a2;
   \<And>a b xs. \<lbrakk>a1 = finsert a (finsert b xs); a2 = finsert b (finsert a xs)\<rbrakk> \<Longrightarrow> P;
   \<lbrakk>a1 = {||}; a2 = {||}\<rbrakk> \<Longrightarrow> P; \<And>xs ys. \<lbrakk>a1 = ys; a2 = xs; xs = ys\<rbrakk> \<Longrightarrow> P;
   \<And>a xs. \<lbrakk>a1 = finsert a (finsert a xs); a2 = finsert a xs\<rbrakk> \<Longrightarrow> P;
   \<And>xs ys a. \<lbrakk>a1 = finsert a xs; a2 = finsert a ys; xs = ys\<rbrakk> \<Longrightarrow> P;
   \<And>xs1 xs2 xs3. \<lbrakk>a1 = xs1; a2 = xs3; xs1 = xs2; xs2 = xs3\<rbrakk> \<Longrightarrow> P\<rbrakk>
  \<Longrightarrow> P"
  by (lifting list_eq2.cases[simplified list_eq2_equiv[symmetric]])

lemma fset_eq_induct:
  assumes "x1 = x2"
  and "\<And>a b xs. P (finsert a (finsert b xs)) (finsert b (finsert a xs))"
  and "P {||} {||}"
  and "\<And>xs ys. \<lbrakk>xs = ys; P xs ys\<rbrakk> \<Longrightarrow> P ys xs"
  and "\<And>a xs. P (finsert a (finsert a xs)) (finsert a xs)"
  and "\<And>xs ys a. \<lbrakk>xs = ys; P xs ys\<rbrakk> \<Longrightarrow> P (finsert a xs) (finsert a ys)"
  and "\<And>xs1 xs2 xs3. \<lbrakk>xs1 = xs2; P xs1 xs2; xs2 = xs3; P xs2 xs3\<rbrakk> \<Longrightarrow> P xs1 xs3"
  shows "P x1 x2"
  using assms
  by (lifting list_eq2.induct[simplified list_eq2_equiv[symmetric]])

section {* fconcat *}

lemma fconcat_empty:
  shows "fconcat {||} = {||}"
  by (lifting concat.simps(1))

lemma fconcat_insert:
  shows "fconcat (finsert x S) = x |\<union>| fconcat S"
  by (lifting concat.simps(2))

lemma 
  shows "fconcat (xs |\<union>| ys) = fconcat xs |\<union>| fconcat ys"
  by (lifting concat_append)


section {* ffilter *}

lemma subseteq_filter: 
  shows "ffilter P xs <= ffilter Q xs = (\<forall> x. x |\<in>| xs \<longrightarrow> P x \<longrightarrow> Q x)"
  by  (descending) (auto simp add: memb_def sub_list_def)

lemma eq_ffilter: 
  shows "(ffilter P xs = ffilter Q xs) = (\<forall>x. x |\<in>| xs \<longrightarrow> P x = Q x)"
  by (descending) (auto simp add: memb_def)

lemma subset_ffilter:
  shows "(\<And>x. x |\<in>| xs \<Longrightarrow> P x \<Longrightarrow> Q x) \<Longrightarrow> (x |\<in>| xs & \<not> P x & Q x) \<Longrightarrow> ffilter P xs < ffilter Q xs"
  unfolding less_fset_def by (auto simp add: subseteq_filter eq_ffilter)


section {* lemmas transferred from Finite_Set theory *}

text {* finiteness for finite sets holds *}
lemma finite_fset [simp]: 
  shows "finite (fset S)"
  by (induct S) auto

lemma fset_choice: 
  shows "\<forall>x. x |\<in>| A \<longrightarrow> (\<exists>y. P x y) \<Longrightarrow> \<exists>f. \<forall>x. x |\<in>| A \<longrightarrow> P x (f x)"
  unfolding fset_to_set_trans
  by (rule finite_set_choice[simplified Ball_def, OF finite_fset])

lemma fsubseteq_fempty:
  shows "xs |\<subseteq>| {||} \<longleftrightarrow> xs = {||}"
  by (metis finter_empty_r le_iff_inf)

lemma not_fsubset_fnil: 
  shows "\<not> xs |\<subset>| {||}"
  by (metis fset_simps(1) fsubset_set not_psubset_empty)
  
lemma fcard_mono: 
  shows "xs |\<subseteq>| ys \<Longrightarrow> fcard xs \<le> fcard ys"
  unfolding fset_to_set_trans
  by (rule card_mono[OF finite_fset])

lemma fcard_fseteq: 
  shows "xs |\<subseteq>| ys \<Longrightarrow> fcard ys \<le> fcard xs \<Longrightarrow> xs = ys"
  unfolding fcard_set fsubseteq_set
  by (simp add: card_seteq[OF finite_fset] fset_cong)

lemma psubset_fcard_mono: 
  shows "xs |\<subset>| ys \<Longrightarrow> fcard xs < fcard ys"
  unfolding fset_to_set_trans
  by (rule psubset_card_mono[OF finite_fset])

lemma fcard_funion_finter: 
  shows "fcard xs + fcard ys = fcard (xs |\<union>| ys) + fcard (xs |\<inter>| ys)"
  unfolding fset_to_set_trans
  by (rule card_Un_Int[OF finite_fset finite_fset])

lemma fcard_funion_disjoint: 
  shows "xs |\<inter>| ys = {||} \<Longrightarrow> fcard (xs |\<union>| ys) = fcard xs + fcard ys"
  unfolding fset_to_set_trans
  by (rule card_Un_disjoint[OF finite_fset finite_fset])

lemma fcard_delete1_less: 
  shows "x |\<in>| xs \<Longrightarrow> fcard (fdelete x xs) < fcard xs"
  unfolding fset_to_set_trans
  by (rule card_Diff1_less[OF finite_fset])

lemma fcard_delete2_less: 
  shows "x |\<in>| xs \<Longrightarrow> y |\<in>| xs \<Longrightarrow> fcard (fdelete y (fdelete x xs)) < fcard xs"
  unfolding fset_to_set_trans
  by (rule card_Diff2_less[OF finite_fset])

lemma fcard_delete1_le: 
  shows "fcard (fdelete x xs) \<le> fcard xs"
  unfolding fset_to_set_trans
  by (rule card_Diff1_le[OF finite_fset])

lemma fcard_psubset: 
  shows "ys |\<subseteq>| xs \<Longrightarrow> fcard ys < fcard xs \<Longrightarrow> ys |\<subset>| xs"
  unfolding fset_to_set_trans
  by (rule card_psubset[OF finite_fset])

lemma fcard_fmap_le: 
  shows "fcard (fmap f xs) \<le> fcard xs"
  unfolding fset_to_set_trans
  by (rule card_image_le[OF finite_fset])

lemma fin_fminus_fnotin: 
  shows "x |\<in>| F - S \<Longrightarrow> x |\<notin>| S"
  unfolding fset_to_set_trans
  by blast

lemma fin_fnotin_fminus: 
  shows "x |\<in>| S \<Longrightarrow> x |\<notin>| F - S"
  unfolding fset_to_set_trans
  by blast

lemma fin_mdef: 
  "x |\<in>| F \<longleftrightarrow> x |\<notin>| (F - {|x|}) \<and> F = finsert x (F - {|x|})"
  unfolding fset_to_set_trans
  by blast

lemma fcard_fminus_finsert[simp]:
  assumes "a |\<in>| A" and "a |\<notin>| B"
  shows "fcard(A - finsert a B) = fcard(A - B) - 1"
  using assms 
  unfolding fset_to_set_trans
  by (rule card_Diff_insert[OF finite_fset])

lemma fcard_fminus_fsubset:
  assumes "B |\<subseteq>| A"
  shows "fcard (A - B) = fcard A - fcard B"
  using assms unfolding fset_to_set_trans
  by (rule card_Diff_subset[OF finite_fset])

lemma fcard_fminus_subset_finter:
  shows "fcard (A - B) = fcard A - fcard (A |\<inter>| B)"
  unfolding fset_to_set_trans
  by (rule card_Diff_subset_Int) (fold finter_set, rule finite_fset)


ML {*
fun dest_fsetT (Type (@{type_name fset}, [T])) = T
  | dest_fsetT T = raise TYPE ("dest_fsetT: fset type expected", [T], []);
*}

no_notation
  list_eq (infix "\<approx>" 50)

end

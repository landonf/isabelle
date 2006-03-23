(*  Title:      HOL/Library/Library.thy
    ID:         $Id$
    Author:     Norbert Schirmer, Tobias Nipkow, Martin Wildmoser
*)

header {* Map operations implemented on association lists*}

theory AssocList 
imports Map

begin

text {* The operations preserve distinctness of keys and 
        function @{term "clearjunk"} distributes over them.*}
consts 
  delete     :: "'key \<Rightarrow> ('key * 'val)list \<Rightarrow>  ('key * 'val)list"
  update     :: "'key \<Rightarrow> 'val \<Rightarrow> ('key * 'val)list \<Rightarrow>  ('key * 'val)list"
  updates    :: "'key list \<Rightarrow> 'val list \<Rightarrow> ('key * 'val)list \<Rightarrow>  ('key * 'val)list"
  merge      :: "('key * 'val)list \<Rightarrow> ('key * 'val)list \<Rightarrow> ('key * 'val)list"
  compose    :: "('key * 'a)list \<Rightarrow> ('a * 'b)list \<Rightarrow> ('key * 'b)list"
  restrict   :: "('key set) \<Rightarrow> ('key * 'val)list \<Rightarrow> ('key * 'val)list"

  clearjunk  :: "('key * 'val)list \<Rightarrow> ('key * 'val)list"

(* a bit special
  substitute :: "'val \<Rightarrow> 'val \<Rightarrow> ('key * 'val)list \<Rightarrow>  ('key * 'val)list"
  map_at     :: "('val \<Rightarrow> 'val) \<Rightarrow> 'key \<Rightarrow> ('key * 'val)list \<Rightarrow>  ('key * 'val) list"
*)

defs
delete_def: "delete k \<equiv> filter (\<lambda>p. fst p \<noteq> k)"

primrec
"update k v [] = [(k,v)]"
"update k v (p#ps) = (if fst p = k then (k,v)#ps else p # update k v ps)"
primrec
"updates [] vs al = al"
"updates (k#ks) vs al = (case vs of [] \<Rightarrow> al 
                         | (v#vs') \<Rightarrow> updates ks vs' (update k v al))"
primrec
"merge xs [] = xs"
"merge xs (p#ps) = update (fst p) (snd p) (merge xs ps)"

(*
primrec
"substitute v v' [] = []"
"substitute v v' (p#ps) = (if snd p = v then (fst p,v')#substitute v v' ps
                          else p#substitute v v' ps)"
primrec
"map_at f k [] = []"
"map_at f k (p#ps) = (if fst p = k then (k,f (snd p))#ps else p # map_at f k ps)"
*)

lemma length_delete_le: "length (delete k al) \<le> length al"
proof (induct al)
  case Nil thus ?case by (simp add: delete_def)
next
  case (Cons a al)
  note length_filter_le [of "\<lambda>p. fst p \<noteq> fst a" al] 
  also have "\<And>n. n \<le> Suc n"
    by simp
  finally have "length [p\<in>al . fst p \<noteq> fst a] \<le> Suc (length al)" .
  with Cons show ?case
    by (auto simp add: delete_def)
qed

lemma compose_hint: "length (delete k al) < Suc (length al)"
proof -
  note length_delete_le
  also have "\<And>n. n < Suc n"
    by simp
  finally show ?thesis .
qed

recdef compose "measure size"
"compose [] = (\<lambda>ys. [])"
"compose (x#xs) = (\<lambda>ys. (case (map_of ys (snd x)) of
                          None \<Rightarrow> compose (delete (fst x) xs) ys
                         | Some v \<Rightarrow> (fst x,v)#compose xs ys))"
(hints intro: compose_hint)

defs  
restrict_def: "restrict A \<equiv> filter (\<lambda>(k,v). k \<in> A)"

recdef clearjunk "measure size"
"clearjunk [] = []"
"clearjunk (p#ps) = p # clearjunk (delete (fst p) ps)"
(hints intro: compose_hint)


(* ******************************************************************************** *)
subsection {* Lookup *}
(* ******************************************************************************** *)

lemma lookup_simps: 
  "map_of [] k = None"
  "map_of (p#ps) k = (if fst p = k then Some (snd p) else map_of ps k)"
  by simp_all

(* ******************************************************************************** *)
subsection {* @{const delete} *}
(* ******************************************************************************** *)

lemma delete_simps [simp]:
"delete k [] = []"
"delete k (p#ps) = (if fst p = k then delete k ps else p # delete k ps)"
  by (simp_all add: delete_def)

lemma delete_id[simp]: "k \<notin> fst ` set al \<Longrightarrow> delete k al = al"
by(induct al, auto)

lemma delete_conv: "map_of (delete k al) k' = ((map_of al)(k := None)) k'"
  by (induct al) auto

lemma delete_conv': "map_of (delete k al) = ((map_of al)(k := None))"
  by (rule ext) (rule delete_conv)

lemma delete_idem: "delete k (delete k al) = delete k al"
  by (induct al) auto

lemma map_of_delete[simp]:
 "k' \<noteq> k \<Longrightarrow> map_of (delete k al) k' = map_of al k'"
by(induct al, auto)

lemma delete_notin_dom: "k \<notin> fst ` set (delete k al)"
  by (induct al) auto

lemma dom_delete_subset: "fst ` set (delete k al) \<subseteq> fst ` set al"
  by (induct al) auto

lemma distinct_delete:
  assumes "distinct (map fst al)" 
  shows "distinct (map fst (delete k al))"
using prems
proof (induct al)
  case Nil thus ?case by simp
next
  case (Cons a al)
  from Cons.prems obtain 
    a_notin_al: "fst a \<notin> fst ` set al" and
    dist_al: "distinct (map fst al)"
    by auto
  show ?case
  proof (cases "fst a = k")
    case True
    from True dist_al show ?thesis by simp
  next
    case False
    from dist_al
    have "distinct (map fst (delete k al))"
      by (rule Cons.hyps)
    moreover from a_notin_al dom_delete_subset [of k al] 
    have "fst a \<notin> fst ` set (delete k al)"
      by blast
    ultimately show ?thesis using False by simp
  qed
qed

lemma delete_twist: "delete x (delete y al) = delete y (delete x al)"
  by (induct al) auto

lemma clearjunk_delete: "clearjunk (delete x al) = delete x (clearjunk al)"
  by (induct al rule: clearjunk.induct) (auto simp add: delete_idem delete_twist)

(* ******************************************************************************** *)
subsection {* @{const clearjunk} *}
(* ******************************************************************************** *)

lemma insert_fst_filter: 
  "insert a(fst ` {x \<in> set ps. fst x \<noteq> a}) = insert a (fst ` set ps)"
  by (induct ps) auto

lemma dom_clearjunk: "fst ` set (clearjunk al) = fst ` set al"
  by (induct al rule: clearjunk.induct) (simp_all add: insert_fst_filter delete_def)

lemma notin_filter_fst: "a \<notin> fst ` {x \<in> set ps. fst x \<noteq> a}"
  by (induct ps) auto

lemma distinct_clearjunk [simp]: "distinct (map fst (clearjunk al))"
  by (induct al rule: clearjunk.induct) 
     (simp_all add: dom_clearjunk notin_filter_fst delete_def)

lemma map_of_filter: "k \<noteq> a \<Longrightarrow> map_of [q\<in>ps . fst q \<noteq> a] k = map_of ps k"
  by (induct ps) auto

lemma map_of_clearjunk: "map_of (clearjunk al) = map_of al"
  apply (rule ext)
  apply (induct al rule: clearjunk.induct)
  apply  simp
  apply (simp add: map_of_filter)
  done

lemma length_clearjunk: "length (clearjunk al) \<le> length al"
proof (induct al rule: clearjunk.induct [case_names Nil Cons])
  case Nil thus ?case by simp
next
  case (Cons k v ps)
  from Cons have "length (clearjunk [q\<in>ps . fst q \<noteq> k]) \<le> length [q\<in>ps . fst q \<noteq> k]" 
    by (simp add: delete_def)
  also have "\<dots> \<le> length ps"
    by simp
  finally show ?case
    by (simp add: delete_def)
qed

lemma notin_fst_filter: "a \<notin> fst ` set ps \<Longrightarrow> [q\<in>ps . fst q \<noteq> a] = ps"
  by (induct ps) auto
            
lemma distinct_clearjunk_id [simp]: "distinct (map fst al) \<Longrightarrow> clearjunk al = al"
  by (induct al rule: clearjunk.induct) (auto simp add: notin_fst_filter)

lemma clearjunk_idem: "clearjunk (clearjunk al) = clearjunk al"
  by simp

(* ******************************************************************************** *)
subsection {* @{const dom} and @{term "ran"} *}
(* ******************************************************************************** *)

lemma dom_map_of': "fst ` set al = dom (map_of al)"
  by (induct al) auto

lemmas dom_map_of = dom_map_of' [symmetric]

lemma ran_clearjunk: "ran (map_of (clearjunk al)) = ran (map_of al)"
  by (simp add: map_of_clearjunk)

lemma ran_distinct: 
  assumes dist: "distinct (map fst al)" 
  shows "ran (map_of al) = snd ` set al"
using dist
proof (induct al) 
  case Nil
  thus ?case by simp
next
  case (Cons a al)
  hence hyp: "snd ` set al = ran (map_of al)"
    by simp

  have "ran (map_of (a # al)) = {snd a} \<union> ran (map_of al)"
  proof 
    show "ran (map_of (a # al)) \<subseteq> {snd a} \<union> ran (map_of al)"
    proof   
      fix v
      assume "v \<in> ran (map_of (a#al))"
      then obtain x where "map_of (a#al) x = Some v"
	by (auto simp add: ran_def)
      then show "v \<in> {snd a} \<union> ran (map_of al)"
	by (auto split: split_if_asm simp add: ran_def)
    qed
  next
    show "{snd a} \<union> ran (map_of al) \<subseteq> ran (map_of (a # al))"
    proof 
      fix v
      assume v_in: "v \<in> {snd a} \<union> ran (map_of al)"
      show "v \<in> ran (map_of (a#al))"
      proof (cases "v=snd a")
	case True
	with v_in show ?thesis
	  by (auto simp add: ran_def)
      next
	case False
	with v_in have "v \<in> ran (map_of al)" by auto
	then obtain x where al_x: "map_of al x = Some v"
	  by (auto simp add: ran_def)
	from map_of_SomeD [OF this]
	have "x \<in> fst ` set al"
	  by (force simp add: image_def)
	with Cons.prems have "x\<noteq>fst a"
	  by - (rule ccontr,simp)
	with al_x
	show ?thesis
	  by (auto simp add: ran_def)
      qed
    qed
  qed
  with hyp show ?case
    by (simp only:) auto
qed

lemma ran_map_of: "ran (map_of al) = snd ` set (clearjunk al)"
proof -
  have "ran (map_of al) = ran (map_of (clearjunk al))"
    by (simp add: ran_clearjunk)
  also have "\<dots> = snd ` set (clearjunk al)"
    by (simp add: ran_distinct)
  finally show ?thesis .
qed
   
(* ******************************************************************************** *)
subsection {* @{const update} *}
(* ******************************************************************************** *)

lemma update_conv: "map_of (update k v al) k' = ((map_of al)(k\<mapsto>v)) k'"
  by (induct al) auto

lemma update_conv': "map_of (update k v al)  = ((map_of al)(k\<mapsto>v))"
  by (rule ext) (rule update_conv)

lemma dom_update: "fst ` set (update k v al) = {k} \<union> fst ` set al"
  by (induct al) auto

lemma distinct_update:
  assumes "distinct (map fst al)" 
  shows "distinct (map fst (update k v al))"
using prems
proof (induct al)
  case Nil thus ?case by simp
next
  case (Cons a al)
  from Cons.prems obtain 
    a_notin_al: "fst a \<notin> fst ` set al" and
    dist_al: "distinct (map fst al)"
    by auto
  show ?case
  proof (cases "fst a = k")
    case True
    from True dist_al a_notin_al show ?thesis by simp
  next
    case False
    from dist_al
    have "distinct (map fst (update k v al))"
      by (rule Cons.hyps)
    with False a_notin_al show ?thesis by (simp add: dom_update)
  qed
qed

lemma update_filter: 
  "a\<noteq>k \<Longrightarrow> update k v [q\<in>ps . fst q \<noteq> a] = [q\<in>update k v ps . fst q \<noteq> a]"
  by (induct ps) auto

lemma clearjunk_update: "clearjunk (update k v al) = update k v (clearjunk al)"
  by (induct al rule: clearjunk.induct) (auto simp add: update_filter delete_def)

lemma update_triv: "map_of al k = Some v \<Longrightarrow> update k v al = al"
  by (induct al) auto

lemma update_nonempty [simp]: "update k v al \<noteq> []"
  by (induct al) auto

lemma update_eqD: "update k v al = update k v' al' \<Longrightarrow> v=v'"
proof (induct al fixing: al') 
  case Nil thus ?case 
    by (cases al') (auto split: split_if_asm)
next
  case Cons thus ?case
    by (cases al') (auto split: split_if_asm)
qed

lemma update_last [simp]: "update k v (update k v' al) = update k v al"
  by (induct al) auto

text {* Note that the lists are not necessarily the same:
        @{term "update k v (update k' v' []) = [(k',v'),(k,v)]"} and 
        @{term "update k' v' (update k v []) = [(k,v),(k',v')]"}.*}
lemma update_swap: "k\<noteq>k' 
  \<Longrightarrow> map_of (update k v (update k' v' al)) = map_of (update k' v' (update k v al))"
  by (auto simp add: update_conv' intro: ext)

lemma update_Some_unfold: 
  "(map_of (update k v al) x = Some y) = 
     (x = k \<and> v = y \<or> x \<noteq> k \<and> map_of al x = Some y)"
  by (simp add: update_conv' map_upd_Some_unfold)

lemma image_update[simp]: "x \<notin> A \<Longrightarrow> map_of (update x y al) ` A = map_of al ` A"
  by (simp add: update_conv' image_map_upd)


(* ******************************************************************************** *)
subsection {* @{const updates} *}
(* ******************************************************************************** *)

lemma updates_conv: "map_of (updates ks vs al) k = ((map_of al)(ks[\<mapsto>]vs)) k"
proof (induct ks fixing: vs al)
  case Nil
  thus ?case by simp
next
  case (Cons k ks)
  show ?case
  proof (cases vs)
    case Nil
    with Cons show ?thesis by simp
  next
    case (Cons k ks')
    with Cons.hyps show ?thesis
      by (simp add: update_conv fun_upd_def)
  qed
qed

lemma updates_conv': "map_of (updates ks vs al) = ((map_of al)(ks[\<mapsto>]vs))"
  by (rule ext) (rule updates_conv)

lemma distinct_updates:
  assumes "distinct (map fst al)"
  shows "distinct (map fst (updates ks vs al))"
  using prems
by (induct ks fixing: vs al) (auto simp add: distinct_update split: list.splits)

lemma clearjunk_updates:
 "clearjunk (updates ks vs al) = updates ks vs (clearjunk al)"
  by (induct ks fixing: vs al) (auto simp add: clearjunk_update split: list.splits)

lemma updates_empty[simp]: "updates vs [] al = al"
  by (induct vs) auto 

lemma updates_Cons: "updates (k#ks) (v#vs) al = updates ks vs (update k v al)"
  by simp

lemma updates_append1[simp]: "size ks < size vs \<Longrightarrow>
  updates (ks@[k]) vs al = update k (vs!size ks) (updates ks vs al)"
  by (induct ks fixing: vs al) (auto split: list.splits)

lemma updates_list_update_drop[simp]:
 "\<lbrakk>size ks \<le> i; i < size vs\<rbrakk>
   \<Longrightarrow> updates ks (vs[i:=v]) al = updates ks vs al"
  by (induct ks fixing: al vs i) (auto split:list.splits nat.splits)

lemma update_updates_conv_if: "
 map_of (updates xs ys (update x y al)) =
 map_of (if x \<in>  set(take (length ys) xs) then updates xs ys al
                                  else (update x y (updates xs ys al)))"
  by (simp add: updates_conv' update_conv' map_upd_upds_conv_if)

lemma updates_twist [simp]:
 "k \<notin> set ks \<Longrightarrow> 
  map_of (updates ks vs (update k v al)) = map_of (update k v (updates ks vs al))"
  by (simp add: updates_conv' update_conv' map_upds_twist)

lemma updates_apply_notin[simp]:
 "k \<notin> set ks ==> map_of (updates ks vs al) k = map_of al k"
  by (simp add: updates_conv)

lemma updates_append_drop[simp]:
  "size xs = size ys \<Longrightarrow> updates (xs@zs) ys al = updates xs ys al"
  by (induct xs fixing: ys al) (auto split: list.splits)

lemma updates_append2_drop[simp]:
  "size xs = size ys \<Longrightarrow> updates xs (ys@zs) al = updates xs ys al"
  by (induct xs fixing: ys al) (auto split: list.splits)

(*
(* ******************************************************************************** *)
subsection {* @{const substitute} *}
(* ******************************************************************************** *)

lemma substitute_conv: "map_of (substitute v v' al) k = ((map_of al)(v ~> v')) k"
  by (induct al) auto

lemma substitute_conv': "map_of (substitute v v' al) = ((map_of al)(v ~> v'))"
  by (rule ext) (rule substitute_conv)

lemma dom_substitute: "fst ` set (substitute v v' al) = fst ` set al"
  by (induct al) auto

lemma distinct_substitute: 
  "distinct (map fst al) \<Longrightarrow> distinct (map fst (substitute v v' al))"
  by (induct al) (auto simp add: dom_substitute)

lemma substitute_filter: 
  "(substitute v v' [q\<in>ps . fst q \<noteq> a]) = [q\<in>substitute v v' ps . fst q \<noteq> a]"
  by (induct ps) auto

lemma clearjunk_substitute:
 "clearjunk (substitute v v' al) = substitute v v' (clearjunk al)"
  by (induct al rule: clearjunk.induct) (auto simp add: substitute_filter delete_def)
*)
(*
(* ******************************************************************************** *)
subsection {* @{const map_at} *}
(* ******************************************************************************** *)
  
lemma map_at_conv: "map_of (map_at f k al) k' = (chg_map f k (map_of al)) k'"
  by (induct al) (auto simp add: chg_map_def split: option.splits)

lemma map_at_conv': "map_of (map_at f k al) = (chg_map f k (map_of al))"
  by (rule ext) (rule map_at_conv)

lemma dom_map_at: "fst ` set (map_at f k al) = fst ` set al"
  by (induct al) auto

lemma distinct_map_at: 
  assumes "distinct (map fst al)"
  shows "distinct (map fst (map_at f k al))"
using prems by (induct al) (auto simp add: dom_map_at)

lemma map_at_notin_filter: 
  "a \<noteq> k \<Longrightarrow> (map_at f k [q\<in>ps . fst q \<noteq> a]) = [q\<in>map_at f k ps . fst q \<noteq> a]"
  by (induct ps) auto

lemma clearjunk_map_at:
 "clearjunk (map_at f k al) = map_at f k (clearjunk al)"
  by (induct al rule: clearjunk.induct) (auto simp add: map_at_notin_filter delete_def)

lemma map_at_new[simp]: "map_of al k = None \<Longrightarrow> map_at f k al = al"
  by (induct al) auto

lemma map_at_update: "map_of al k = Some v \<Longrightarrow> map_at f k al = update k (f v) al"
  by (induct al) auto

lemma map_at_other [simp]: "a \<noteq> b \<Longrightarrow> map_of (map_at f a al) b = map_of al b"
  by (simp add: map_at_conv')
*)
(* ******************************************************************************** *)
subsection {* @{const merge} *}
(* ******************************************************************************** *)

lemma dom_merge: "fst ` set (merge xs ys) = fst ` set xs \<union> fst ` set ys"
  by (induct ys fixing: xs) (auto simp add: dom_update)

lemma distinct_merge:
  assumes "distinct (map fst xs)"
  shows "distinct (map fst (merge xs ys))"
  using prems
by (induct ys fixing: xs) (auto simp add: dom_merge distinct_update)

lemma clearjunk_merge:
 "clearjunk (merge xs ys) = merge (clearjunk xs) ys"
  by (induct ys) (auto simp add: clearjunk_update)

lemma merge_conv: "map_of (merge xs ys) k = (map_of xs ++ map_of ys) k"
proof (induct ys)
  case Nil thus ?case by simp 
next
  case (Cons y ys)
  show ?case
  proof (cases "k = fst y")
    case True
    from True show ?thesis
      by (simp add: update_conv)
  next
    case False
    from False show ?thesis
      by (auto simp add: update_conv Cons.hyps map_add_def)
  qed
qed

lemma merge_conv': "map_of (merge xs ys) = (map_of xs ++ map_of ys)"
  by (rule ext) (rule merge_conv)

lemma merge_emty: "map_of (merge [] ys) = map_of ys"
  by (simp add: merge_conv')

lemma merge_assoc[simp]: "map_of (merge m1 (merge m2 m3)) = 
                           map_of (merge (merge m1 m2) m3)"
  by (simp add: merge_conv')

lemma merge_Some_iff: 
 "(map_of (merge m n) k = Some x) = 
  (map_of n k = Some x \<or> map_of n k = None \<and> map_of m k = Some x)"
  by (simp add: merge_conv' map_add_Some_iff)

lemmas merge_SomeD = merge_Some_iff [THEN iffD1, standard]
declare merge_SomeD [dest!]

lemma merge_find_right[simp]: "map_of n k = Some v \<Longrightarrow> map_of (merge m n) k = Some v"
  by (simp add: merge_conv')

lemma merge_None [iff]: 
  "(map_of (merge m n) k = None) = (map_of n k = None \<and> map_of m k = None)"
  by (simp add: merge_conv')

lemma merge_upd[simp]: 
  "map_of (merge m (update k v n)) = map_of (update k v (merge m n))"
  by (simp add: update_conv' merge_conv')

lemma merge_updatess[simp]: 
  "map_of (merge m (updates xs ys n)) = map_of (updates xs ys (merge m n))"
  by (simp add: updates_conv' merge_conv')

lemma merge_append: "map_of (xs@ys) = map_of (merge ys xs)"
  by (simp add: merge_conv')

(* ******************************************************************************** *)
subsection {* @{const compose} *}
(* ******************************************************************************** *)

lemma compose_induct [case_names Nil Cons]: 
  assumes Nil: "P [] ys"
  assumes Cons: "\<And>x xs.
     \<lbrakk>\<And>v. map_of ys (snd x) = Some v \<Longrightarrow> P xs ys;
      map_of ys (snd x) = None \<Longrightarrow> P (delete (fst x) xs) ys\<rbrakk>
     \<Longrightarrow> P (x # xs) ys"
  shows "P xs ys"
apply (rule compose.induct [where ?P="\<lambda>xs. P xs ys"])
apply (rule Nil)
apply  (rule Cons)
apply (erule allE, erule allE, erule impE, assumption,assumption)
apply (erule allE, erule impE,assumption,assumption)
done

lemma compose_first_None [simp]: 
  assumes "map_of xs k = None" 
  shows "map_of (compose xs ys) k = None"
using prems
by (induct xs ys rule: compose_induct) (auto split: option.splits split_if_asm)


lemma compose_conv: 
  shows "map_of (compose xs ys) k = (map_of ys \<circ>\<^sub>m map_of xs) k"
proof (induct xs ys rule: compose_induct )
  case Nil thus ?case by simp
next
  case (Cons x xs)
  show ?case
  proof (cases "map_of ys (snd x)")
    case None
    with Cons
    have hyp: "map_of (compose (delete (fst x) xs) ys) k =
               (map_of ys \<circ>\<^sub>m map_of (delete (fst x) xs)) k"
      by simp
    show ?thesis
    proof (cases "fst x = k")
      case True
      from True delete_notin_dom [of k xs]
      have "map_of (delete (fst x) xs) k = None"
	by (simp add: map_of_eq_None_iff)
      with hyp show ?thesis
	using True None
	by simp
    next
      case False
      from False have "map_of (delete (fst x) xs) k = map_of xs k"
	by simp
      with hyp show ?thesis
	using False None
	by (simp add: map_comp_def)
    qed
  next
    case (Some v)
    with Cons
    have "map_of (compose xs ys) k = (map_of ys \<circ>\<^sub>m map_of xs) k"
      by simp
    with Some show ?thesis
      by (auto simp add: map_comp_def)
  qed
qed
   
lemma compose_conv': 
  shows "map_of (compose xs ys) = (map_of ys \<circ>\<^sub>m map_of xs)"
  by (rule ext) (rule compose_conv)

lemma compose_first_Some [simp]:
  assumes "map_of xs k = Some v" 
  shows "map_of (compose xs ys) k = map_of ys v"
using prems by (simp add: compose_conv)

lemma dom_compose: "fst ` set (compose xs ys) \<subseteq> fst ` set xs"
proof (induct xs ys rule: compose_induct )
  case Nil thus ?case by simp
next
  case (Cons x xs)
  show ?case
  proof (cases "map_of ys (snd x)")
    case None
    with Cons.hyps
    have "fst ` set (compose (delete (fst x) xs) ys) \<subseteq> fst ` set (delete (fst x) xs)"
      by simp
    also
    have "\<dots> \<subseteq> fst ` set xs"
      by (rule dom_delete_subset)
    finally show ?thesis
      using None
      by auto
  next
    case (Some v)
    with Cons.hyps
    have "fst ` set (compose xs ys) \<subseteq> fst ` set xs"
      by simp
    with Some show ?thesis
      by auto
  qed
qed

lemma distinct_compose:
 assumes "distinct (map fst xs)"
 shows "distinct (map fst (compose xs ys))"
using prems
proof (induct xs ys rule: compose_induct)
  case Nil thus ?case by simp
next
  case (Cons x xs)
  show ?case
  proof (cases "map_of ys (snd x)")
    case None
    with Cons show ?thesis by simp
  next
    case (Some v)
    with Cons dom_compose [of xs ys] show ?thesis 
      by (auto)
  qed
qed

lemma compose_delete_twist: "(compose (delete k xs) ys) = delete k (compose xs ys)"
proof (induct xs ys rule: compose_induct)
  case Nil thus ?case by simp
next
  case (Cons x xs)
  show ?case
  proof (cases "map_of ys (snd x)")
    case None
    with Cons have 
      hyp: "compose (delete k (delete (fst x) xs)) ys =
            delete k (compose (delete (fst x) xs) ys)"
      by simp
    show ?thesis
    proof (cases "fst x = k")
      case True
      with None hyp
      show ?thesis
	by (simp add: delete_idem)
    next
      case False
      from None False hyp
      show ?thesis
	by (simp add: delete_twist)
    qed
  next
    case (Some v)
    with Cons have hyp: "compose (delete k xs) ys = delete k (compose xs ys)" by simp
    with Some show ?thesis
      by simp
  qed
qed

lemma compose_clearjunk: "compose xs (clearjunk ys) = compose xs ys"
  by (induct xs ys rule: compose_induct) 
     (auto simp add: map_of_clearjunk split: option.splits)
   
lemma clearjunk_compose: "clearjunk (compose xs ys) = compose (clearjunk xs) ys"
  by (induct xs rule: clearjunk.induct)
     (auto split: option.splits simp add: clearjunk_delete delete_idem
               compose_delete_twist)
   
lemma compose_empty [simp]:
 "compose xs [] = []"
  by (induct xs rule: compose_induct [where ys="[]"]) auto


lemma compose_Some_iff:
  "(map_of (compose xs ys) k = Some v) = 
     (\<exists>k'. map_of xs k = Some k' \<and> map_of ys k' = Some v)" 
  by (simp add: compose_conv map_comp_Some_iff)

lemma map_comp_None_iff:
  "(map_of (compose xs ys) k = None) = 
    (map_of xs k = None \<or> (\<exists>k'. map_of xs k = Some k' \<and> map_of ys k' = None)) " 
  by (simp add: compose_conv map_comp_None_iff)


(* ******************************************************************************** *)
subsection {* @{const restrict} *}
(* ******************************************************************************** *)

lemma restrict_simps [simp]: 
  "restrict A [] = []"
  "restrict A (p#ps) = (if fst p \<in> A then p#restrict A ps else restrict A ps)"
  by (auto simp add: restrict_def)

lemma distinct_restr: "distinct (map fst al) \<Longrightarrow> distinct (map fst (restrict A al))"
  by (induct al) (auto simp add: restrict_def)

lemma restr_conv: "map_of (restrict A al) k = ((map_of al)|` A) k"
  apply (induct al)
  apply  (simp add: restrict_def)
  apply (cases "k\<in>A")
  apply (auto simp add: restrict_def)
  done

lemma restr_conv': "map_of (restrict A al) = ((map_of al)|` A)"
  by (rule ext) (rule restr_conv)

lemma restr_empty [simp]: 
  "restrict {} al = []" 
  "restrict A [] = []"
  by (induct al) (auto simp add: restrict_def)

lemma restr_in [simp]: "x \<in> A \<Longrightarrow> map_of (restrict A al) x = map_of al x"
  by (simp add: restr_conv')

lemma restr_out [simp]: "x \<notin> A \<Longrightarrow> map_of (restrict A al) x = None"
  by (simp add: restr_conv')

lemma dom_restr [simp]: "fst ` set (restrict A al) = fst ` set al \<inter> A"
  by (induct al) (auto simp add: restrict_def)

lemma restr_upd_same [simp]: "restrict (-{x}) (update x y al) = restrict (-{x}) al"
  by (induct al) (auto simp add: restrict_def)

lemma restr_restr [simp]: "restrict A (restrict B al) = restrict (A\<inter>B) al"
  by (induct al) (auto simp add: restrict_def)

lemma restr_update[simp]:
 "map_of (restrict D (update x y al)) = 
  map_of ((if x \<in> D then (update x y (restrict (D-{x}) al)) else restrict D al))"
  by (simp add: restr_conv' update_conv')

lemma restr_delete [simp]:
  "(delete x (restrict D al)) = 
    (if x\<in> D then restrict (D - {x}) al else restrict D al)"
proof (induct al)
  case Nil thus ?case by simp
next
  case (Cons a al)
  show ?case
  proof (cases "x \<in> D")
    case True
    note x_D = this
    with Cons have hyp: "delete x (restrict D al) = restrict (D - {x}) al"
      by simp
    show ?thesis
    proof (cases "fst a = x")
      case True
      from Cons.hyps
      show ?thesis
	using x_D True
	by simp
    next
      case False
      note not_fst_a_x = this
      show ?thesis
      proof (cases "fst a \<in> D")
	case True 
	with not_fst_a_x 
	have "delete x (restrict D (a#al)) = a#(delete x (restrict D al))"
	  by (cases a) (simp add: restrict_def)
	also from not_fst_a_x True hyp have "\<dots> = restrict (D - {x}) (a # al)"
	  by (cases a) (simp add: restrict_def)
	finally show ?thesis
	  using x_D by simp
      next
	case False
	hence "delete x (restrict D (a#al)) = delete x (restrict D al)"
	  by (cases a) (simp add: restrict_def)
	moreover from False not_fst_a_x
	have "restrict (D - {x}) (a # al) = restrict (D - {x}) al"
	  by (cases a) (simp add: restrict_def)
	ultimately
	show ?thesis using x_D hyp by simp
      qed
    qed
  next
    case False
    from False Cons show ?thesis
      by simp
  qed
qed

lemma update_restr:
 "map_of (update x y (restrict D al)) = map_of (update x y (restrict (D-{x}) al))"
  by (simp add: update_conv' restr_conv') (rule fun_upd_restrict)

lemma upate_restr_conv[simp]:
 "x \<in> D \<Longrightarrow> 
 map_of (update x y (restrict D al)) = map_of (update x y (restrict (D-{x}) al))"
  by (simp add: update_conv' restr_conv')

lemma restr_updates[simp]: "
 \<lbrakk> length xs = length ys; set xs \<subseteq> D \<rbrakk>
 \<Longrightarrow> map_of (restrict D (updates xs ys al)) = 
     map_of (updates xs ys (restrict (D - set xs) al))"
  by (simp add: updates_conv' restr_conv')

lemma restr_delete_twist: "(restrict A (delete a ps)) = delete a (restrict A ps)"
  by (induct ps) auto

lemma clearjunk_restrict:
 "clearjunk (restrict A al) = restrict A (clearjunk al)"
  by (induct al rule: clearjunk.induct) (auto simp add: restr_delete_twist)

end

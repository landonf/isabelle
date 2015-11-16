(* Author: Tobias Nipkow *)

section {* Implementing Ordered Maps *}

theory Map_by_Ordered
imports AList_Upd_Del
begin

locale Map =
fixes empty :: "'m"
fixes update :: "'a \<Rightarrow> 'b \<Rightarrow> 'm \<Rightarrow> 'm"
fixes delete :: "'a \<Rightarrow> 'm \<Rightarrow> 'm"
fixes map_of :: "'m \<Rightarrow> 'a \<Rightarrow> 'b option"
fixes invar :: "'m \<Rightarrow> bool"
assumes map_empty: "map_of empty = (\<lambda>_. None)"
and map_update: "invar m \<Longrightarrow> map_of(update a b m) = (map_of m)(a := Some b)"
and map_delete: "invar m \<Longrightarrow> map_of(delete a m) = (map_of m)(a := None)"
and invar_empty: "invar empty"
and invar_update: "invar m \<Longrightarrow> invar(update a b m)"
and invar_delete: "invar m \<Longrightarrow> invar(delete a m)"

locale Map_by_Ordered =
fixes empty :: "'t"
fixes update :: "'a::linorder \<Rightarrow> 'b \<Rightarrow> 't \<Rightarrow> 't"
fixes delete :: "'a \<Rightarrow> 't \<Rightarrow> 't"
fixes lookup :: "'t \<Rightarrow> 'a \<Rightarrow> 'b option"
fixes inorder :: "'t \<Rightarrow> ('a * 'b) list"
fixes inv :: "'t \<Rightarrow> bool"
assumes empty: "inorder empty = []"
and lookup: "inv t \<and> sorted1 (inorder t) \<Longrightarrow>
  lookup t a = map_of (inorder t) a"
and update: "inv t \<and> sorted1 (inorder t) \<Longrightarrow>
  inorder(update a b t) = upd_list a b (inorder t)"
and delete: "inv t \<and> sorted1 (inorder t) \<Longrightarrow>
  inorder(delete a t) = del_list a (inorder t)"
and inv_empty:  "inv empty"
and inv_insert: "inv t \<and> sorted1 (inorder t) \<Longrightarrow> inv(update a b t)"
and inv_delete: "inv t \<and> sorted1 (inorder t) \<Longrightarrow> inv(delete a t)"
begin

sublocale Map
  empty update delete "map_of o inorder" "\<lambda>t. inv t \<and> sorted1 (inorder t)"
proof(standard, goal_cases)
  case 1 show ?case by (auto simp: empty)
next
  case 2 thus ?case by(simp add: update map_of_ins_list)
next
  case 3 thus ?case by(simp add: delete map_of_del_list)
next
  case 4 thus ?case by(simp add: empty inv_empty)
next
  case 5 thus ?case by(simp add: update inv_insert sorted_upd_list)
next
  case 6 thus ?case by (auto simp: delete inv_delete sorted_del_list)
qed

end

end

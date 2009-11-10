(*  Title:      HOL/Record.thy
    Author:     Wolfgang Naraschewski, TU Muenchen
    Author:     Markus Wenzel, TU Muenchen
    Author:     Norbert Schirmer, TU Muenchen
    Author:     Thomas Sewell, NICTA
    Author:     Florian Haftmann, TU Muenchen
*)

header {* Extensible records with structural subtyping *}

theory Record
imports Datatype
uses ("Tools/record.ML")
begin

subsection {* Introduction *}

text {*
  Records are isomorphic to compound tuple types. To implement
  efficient records, we make this isomorphism explicit. Consider the
  record access/update simplification @{text "alpha (beta_update f
  rec) = alpha rec"} for distinct fields alpha and beta of some record
  rec with n fields. There are @{text "n ^ 2"} such theorems, which
  prohibits storage of all of them for large n. The rules can be
  proved on the fly by case decomposition and simplification in O(n)
  time. By creating O(n) isomorphic-tuple types while defining the
  record, however, we can prove the access/update simplification in
  @{text "O(log(n)^2)"} time.

  The O(n) cost of case decomposition is not because O(n) steps are
  taken, but rather because the resulting rule must contain O(n) new
  variables and an O(n) size concrete record construction. To sidestep
  this cost, we would like to avoid case decomposition in proving
  access/update theorems.

  Record types are defined as isomorphic to tuple types. For instance,
  a record type with fields @{text "'a"}, @{text "'b"}, @{text "'c"}
  and @{text "'d"} might be introduced as isomorphic to @{text "'a \<times>
  ('b \<times> ('c \<times> 'd))"}. If we balance the tuple tree to @{text "('a \<times>
  'b) \<times> ('c \<times> 'd)"} then accessors can be defined by converting to the
  underlying type then using O(log(n)) fst or snd operations.
  Updators can be defined similarly, if we introduce a @{text
  "fst_update"} and @{text "snd_update"} function. Furthermore, we can
  prove the access/update theorem in O(log(n)) steps by using simple
  rewrites on fst, snd, @{text "fst_update"} and @{text "snd_update"}.

  The catch is that, although O(log(n)) steps were taken, the
  underlying type we converted to is a tuple tree of size
  O(n). Processing this term type wastes performance. We avoid this
  for large n by taking each subtree of size K and defining a new type
  isomorphic to that tuple subtree. A record can now be defined as
  isomorphic to a tuple tree of these O(n/K) new types, or, if @{text
  "n > K*K"}, we can repeat the process, until the record can be
  defined in terms of a tuple tree of complexity less than the
  constant K.

  If we prove the access/update theorem on this type with the
  analagous steps to the tuple tree, we consume @{text "O(log(n)^2)"}
  time as the intermediate terms are @{text "O(log(n))"} in size and
  the types needed have size bounded by K.  To enable this analagous
  traversal, we define the functions seen below: @{text
  "istuple_fst"}, @{text "istuple_snd"}, @{text "istuple_fst_update"}
  and @{text "istuple_snd_update"}. These functions generalise tuple
  operations by taking a parameter that encapsulates a tuple
  isomorphism.  The rewrites needed on these functions now need an
  additional assumption which is that the isomorphism works.

  These rewrites are typically used in a structured way. They are here
  presented as the introduction rule @{text "isomorphic_tuple.intros"}
  rather than as a rewrite rule set. The introduction form is an
  optimisation, as net matching can be performed at one term location
  for each step rather than the simplifier searching the term for
  possible pattern matches. The rule set is used as it is viewed
  outside the locale, with the locale assumption (that the isomorphism
  is valid) left as a rule assumption. All rules are structured to aid
  net matching, using either a point-free form or an encapsulating
  predicate.
*}

subsection {* Operators and lemmas for types isomorphic to tuples *}

datatype ('a, 'b, 'c) tuple_isomorphism = TupleIsomorphism "'a \<Rightarrow> 'b \<times> 'c" "'b \<times> 'c \<Rightarrow> 'a"

primrec repr :: "('a, 'b, 'c) tuple_isomorphism \<Rightarrow> 'a \<Rightarrow> 'b \<times> 'c" where
  "repr (TupleIsomorphism r a) = r"

primrec abst :: "('a, 'b, 'c) tuple_isomorphism \<Rightarrow> 'b \<times> 'c \<Rightarrow> 'a" where
  "abst (TupleIsomorphism r a) = a"

definition istuple_fst :: "('a, 'b, 'c) tuple_isomorphism \<Rightarrow> 'a \<Rightarrow> 'b" where
  "istuple_fst isom = fst \<circ> repr isom"

definition istuple_snd :: "('a, 'b, 'c) tuple_isomorphism \<Rightarrow> 'a \<Rightarrow> 'c" where
  "istuple_snd isom = snd \<circ> repr isom"

definition istuple_fst_update :: "('a, 'b, 'c) tuple_isomorphism \<Rightarrow> ('b \<Rightarrow> 'b) \<Rightarrow> ('a \<Rightarrow> 'a)" where
  "istuple_fst_update isom f = abst isom \<circ> apfst f \<circ> repr isom"

definition istuple_snd_update :: "('a, 'b, 'c) tuple_isomorphism \<Rightarrow> ('c \<Rightarrow> 'c) \<Rightarrow> ('a \<Rightarrow> 'a)" where
  "istuple_snd_update isom f = abst isom \<circ> apsnd f \<circ> repr isom"

definition istuple_cons :: "('a, 'b, 'c) tuple_isomorphism \<Rightarrow> 'b \<Rightarrow> 'c \<Rightarrow> 'a" where
  "istuple_cons isom = curry (abst isom)"


subsection {* Logical infrastructure for records *}

definition istuple_surjective_proof_assist :: "'a \<Rightarrow> 'b \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> bool" where
  "istuple_surjective_proof_assist x y f \<longleftrightarrow> f x = y"

definition istuple_update_accessor_cong_assist :: "(('b \<Rightarrow> 'b) \<Rightarrow> ('a \<Rightarrow> 'a)) \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> bool" where
  "istuple_update_accessor_cong_assist upd acc \<longleftrightarrow> 
     (\<forall>f v. upd (\<lambda>x. f (acc v)) v = upd f v) \<and> (\<forall>v. upd id v = v)"

definition istuple_update_accessor_eq_assist :: "(('b \<Rightarrow> 'b) \<Rightarrow> ('a \<Rightarrow> 'a)) \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> 'a \<Rightarrow> ('b \<Rightarrow> 'b) \<Rightarrow> 'a \<Rightarrow> 'b \<Rightarrow> bool" where
  "istuple_update_accessor_eq_assist upd acc v f v' x \<longleftrightarrow>
     upd f v = v' \<and> acc v = x \<and> istuple_update_accessor_cong_assist upd acc"

lemma update_accessor_congruence_foldE:
  assumes uac: "istuple_update_accessor_cong_assist upd acc"
  and       r: "r = r'" and v: "acc r' = v'"
  and       f: "\<And>v. v' = v \<Longrightarrow> f v = f' v"
  shows        "upd f r = upd f' r'"
  using uac r v [symmetric]
  apply (subgoal_tac "upd (\<lambda>x. f (acc r')) r' = upd (\<lambda>x. f' (acc r')) r'")
   apply (simp add: istuple_update_accessor_cong_assist_def)
  apply (simp add: f)
  done

lemma update_accessor_congruence_unfoldE:
  "istuple_update_accessor_cong_assist upd acc \<Longrightarrow> r = r' \<Longrightarrow> acc r' = v' \<Longrightarrow> (\<And>v. v = v' \<Longrightarrow> f v = f' v)
     \<Longrightarrow> upd f r = upd f' r'"
  apply (erule(2) update_accessor_congruence_foldE)
  apply simp
  done

lemma istuple_update_accessor_cong_assist_id:
  "istuple_update_accessor_cong_assist upd acc \<Longrightarrow> upd id = id"
  by rule (simp add: istuple_update_accessor_cong_assist_def)

lemma update_accessor_noopE:
  assumes uac: "istuple_update_accessor_cong_assist upd acc"
      and acc: "f (acc x) = acc x"
  shows        "upd f x = x"
using uac by (simp add: acc istuple_update_accessor_cong_assist_id [OF uac, unfolded id_def]
  cong: update_accessor_congruence_unfoldE [OF uac])

lemma update_accessor_noop_compE:
  assumes uac: "istuple_update_accessor_cong_assist upd acc"
  assumes acc: "f (acc x) = acc x"
  shows      "upd (g \<circ> f) x = upd g x"
  by (simp add: acc cong: update_accessor_congruence_unfoldE[OF uac])

lemma update_accessor_cong_assist_idI:
  "istuple_update_accessor_cong_assist id id"
  by (simp add: istuple_update_accessor_cong_assist_def)

lemma update_accessor_cong_assist_triv:
  "istuple_update_accessor_cong_assist upd acc \<Longrightarrow> istuple_update_accessor_cong_assist upd acc"
  by assumption

lemma update_accessor_accessor_eqE:
  "istuple_update_accessor_eq_assist upd acc v f v' x \<Longrightarrow> acc v = x"
  by (simp add: istuple_update_accessor_eq_assist_def)

lemma update_accessor_updator_eqE:
  "istuple_update_accessor_eq_assist upd acc v f v' x \<Longrightarrow> upd f v = v'"
  by (simp add: istuple_update_accessor_eq_assist_def)

lemma istuple_update_accessor_eq_assist_idI:
  "v' = f v \<Longrightarrow> istuple_update_accessor_eq_assist id id v f v' v"
  by (simp add: istuple_update_accessor_eq_assist_def update_accessor_cong_assist_idI)

lemma istuple_update_accessor_eq_assist_triv:
  "istuple_update_accessor_eq_assist upd acc v f v' x \<Longrightarrow> istuple_update_accessor_eq_assist upd acc v f v' x"
  by assumption

lemma istuple_update_accessor_cong_from_eq:
  "istuple_update_accessor_eq_assist upd acc v f v' x \<Longrightarrow> istuple_update_accessor_cong_assist upd acc"
  by (simp add: istuple_update_accessor_eq_assist_def)

lemma o_eq_dest:
  "a o b = c o d \<Longrightarrow> a (b v) = c (d v)"
  apply (clarsimp simp: o_def)
  apply (erule fun_cong)
  done

lemma o_eq_elim:
  "a o b = c o d \<Longrightarrow> ((\<And>v. a (b v) = c (d v)) \<Longrightarrow> R) \<Longrightarrow> R"
  apply (erule meta_mp)
  apply (erule o_eq_dest)
  done

lemma istuple_surjective_proof_assistI:
  "f x = y \<Longrightarrow> istuple_surjective_proof_assist x y f"
  by (simp add: istuple_surjective_proof_assist_def)

lemma istuple_surjective_proof_assist_idE:
  "istuple_surjective_proof_assist x y id \<Longrightarrow> x = y"
  by (simp add: istuple_surjective_proof_assist_def)

locale isomorphic_tuple =
  fixes isom :: "('a, 'b, 'c) tuple_isomorphism"
    and repr and abst
  defines "repr \<equiv> Record.repr isom"
  defines "abst \<equiv> Record.abst isom"
  assumes repr_inv: "\<And>x. abst (repr x) = x"
  assumes abst_inv: "\<And>y. repr (abst y) = y"
begin

lemma repr_inj:
  "repr x = repr y \<longleftrightarrow> x = y"
  apply (rule iffI, simp_all)
  apply (drule_tac f=abst in arg_cong, simp add: repr_inv)
  done

lemma abst_inj:
  "abst x = abst y \<longleftrightarrow> x = y"
  apply (rule iffI, simp_all)
  apply (drule_tac f=repr in arg_cong, simp add: abst_inv)
  done

lemmas simps = Let_def repr_inv abst_inv repr_inj abst_inj repr_def [symmetric] abst_def [symmetric]

lemma istuple_access_update_fst_fst:
  "f o h g = j o f \<Longrightarrow>
    (f o istuple_fst isom) o (istuple_fst_update isom o h) g
          = j o (f o istuple_fst isom)"
  by (clarsimp simp: istuple_fst_update_def istuple_fst_def simps
             intro!: ext elim!: o_eq_elim)

lemma istuple_access_update_snd_snd:
  "f o h g = j o f \<Longrightarrow>
    (f o istuple_snd isom) o (istuple_snd_update isom o h) g
          = j o (f o istuple_snd isom)"
  by (clarsimp simp: istuple_snd_update_def istuple_snd_def simps
             intro!: ext elim!: o_eq_elim)

lemma istuple_access_update_fst_snd:
  "(f o istuple_fst isom) o (istuple_snd_update isom o h) g
          = id o (f o istuple_fst isom)"
  by (clarsimp simp: istuple_snd_update_def istuple_fst_def simps
             intro!: ext elim!: o_eq_elim)

lemma istuple_access_update_snd_fst:
  "(f o istuple_snd isom) o (istuple_fst_update isom o h) g
          = id o (f o istuple_snd isom)"
  by (clarsimp simp: istuple_fst_update_def istuple_snd_def simps
             intro!: ext elim!: o_eq_elim)

lemma istuple_update_swap_fst_fst:
  "h f o j g = j g o h f \<Longrightarrow>
    (istuple_fst_update isom o h) f o (istuple_fst_update isom o j) g
          = (istuple_fst_update isom o j) g o (istuple_fst_update isom o h) f"
  by (clarsimp simp: istuple_fst_update_def simps apfst_compose intro!: ext)

lemma istuple_update_swap_snd_snd:
  "h f o j g = j g o h f \<Longrightarrow>
    (istuple_snd_update isom o h) f o (istuple_snd_update isom o j) g
          = (istuple_snd_update isom o j) g o (istuple_snd_update isom o h) f"
  by (clarsimp simp: istuple_snd_update_def simps apsnd_compose intro!: ext)

lemma istuple_update_swap_fst_snd:
  "(istuple_snd_update isom o h) f o (istuple_fst_update isom o j) g
          = (istuple_fst_update isom o j) g o (istuple_snd_update isom o h) f"
  by (clarsimp simp: istuple_fst_update_def istuple_snd_update_def simps intro!: ext)

lemma istuple_update_swap_snd_fst:
  "(istuple_fst_update isom o h) f o (istuple_snd_update isom o j) g
          = (istuple_snd_update isom o j) g o (istuple_fst_update isom o h) f"
  by (clarsimp simp: istuple_fst_update_def istuple_snd_update_def simps intro!: ext)

lemma istuple_update_compose_fst_fst:
  "h f o j g = k (f o g) \<Longrightarrow>
    (istuple_fst_update isom o h) f o (istuple_fst_update isom o j) g
          = (istuple_fst_update isom o k) (f o g)"
  by (clarsimp simp: istuple_fst_update_def simps apfst_compose intro!: ext)

lemma istuple_update_compose_snd_snd:
  "h f o j g = k (f o g) \<Longrightarrow>
    (istuple_snd_update isom o h) f o (istuple_snd_update isom o j) g
          = (istuple_snd_update isom o k) (f o g)"
  by (clarsimp simp: istuple_snd_update_def simps apsnd_compose intro!: ext)

lemma istuple_surjective_proof_assist_step:
  "istuple_surjective_proof_assist v a (istuple_fst isom o f) \<Longrightarrow>
     istuple_surjective_proof_assist v b (istuple_snd isom o f)
      \<Longrightarrow> istuple_surjective_proof_assist v (istuple_cons isom a b) f"
  by (clarsimp simp: istuple_surjective_proof_assist_def simps
    istuple_fst_def istuple_snd_def istuple_cons_def)

lemma istuple_fst_update_accessor_cong_assist:
  assumes "istuple_update_accessor_cong_assist f g"
  shows "istuple_update_accessor_cong_assist (istuple_fst_update isom o f) (g o istuple_fst isom)"
proof -
  from assms have "f id = id" by (rule istuple_update_accessor_cong_assist_id)
  with assms show ?thesis by (clarsimp simp: istuple_update_accessor_cong_assist_def simps
    istuple_fst_update_def istuple_fst_def)
qed

lemma istuple_snd_update_accessor_cong_assist:
  assumes "istuple_update_accessor_cong_assist f g"
  shows "istuple_update_accessor_cong_assist (istuple_snd_update isom o f) (g o istuple_snd isom)"
proof -
  from assms have "f id = id" by (rule istuple_update_accessor_cong_assist_id)
  with assms show ?thesis by (clarsimp simp: istuple_update_accessor_cong_assist_def simps
    istuple_snd_update_def istuple_snd_def)
qed

lemma istuple_fst_update_accessor_eq_assist:
  assumes "istuple_update_accessor_eq_assist f g a u a' v"
  shows "istuple_update_accessor_eq_assist (istuple_fst_update isom o f) (g o istuple_fst isom)
    (istuple_cons isom a b) u (istuple_cons isom a' b) v"
proof -
  from assms have "f id = id"
    by (auto simp add: istuple_update_accessor_eq_assist_def intro: istuple_update_accessor_cong_assist_id)
  with assms show ?thesis by (clarsimp simp: istuple_update_accessor_eq_assist_def
    istuple_fst_update_def istuple_fst_def istuple_update_accessor_cong_assist_def istuple_cons_def simps)
qed

lemma istuple_snd_update_accessor_eq_assist:
  assumes "istuple_update_accessor_eq_assist f g b u b' v"
  shows "istuple_update_accessor_eq_assist (istuple_snd_update isom o f) (g o istuple_snd isom)
    (istuple_cons isom a b) u (istuple_cons isom a b') v"
proof -
  from assms have "f id = id"
    by (auto simp add: istuple_update_accessor_eq_assist_def intro: istuple_update_accessor_cong_assist_id)
  with assms show ?thesis by (clarsimp simp: istuple_update_accessor_eq_assist_def
    istuple_snd_update_def istuple_snd_def istuple_update_accessor_cong_assist_def istuple_cons_def simps)
qed

lemma istuple_cons_conj_eqI:
  "a = c \<and> b = d \<and> P \<longleftrightarrow> Q \<Longrightarrow>
    istuple_cons isom a b = istuple_cons isom c d \<and> P \<longleftrightarrow> Q"
  by (clarsimp simp: istuple_cons_def simps)

lemmas intros =
    istuple_access_update_fst_fst
    istuple_access_update_snd_snd
    istuple_access_update_fst_snd
    istuple_access_update_snd_fst
    istuple_update_swap_fst_fst
    istuple_update_swap_snd_snd
    istuple_update_swap_fst_snd
    istuple_update_swap_snd_fst
    istuple_update_compose_fst_fst
    istuple_update_compose_snd_snd
    istuple_surjective_proof_assist_step
    istuple_fst_update_accessor_eq_assist
    istuple_snd_update_accessor_eq_assist
    istuple_fst_update_accessor_cong_assist
    istuple_snd_update_accessor_cong_assist
    istuple_cons_conj_eqI

end

lemma isomorphic_tuple_intro:
  fixes repr abst
  assumes repr_inj: "\<And>x y. repr x = repr y \<longleftrightarrow> x = y"
     and abst_inv: "\<And>z. repr (abst z) = z"
  assumes v: "v \<equiv> TupleIsomorphism repr abst"
  shows "isomorphic_tuple v"
  apply (rule isomorphic_tuple.intro)
  apply (simp_all add: abst_inv v)
  apply (cut_tac x="abst (repr x)" and y="x" in repr_inj)
  apply (simp add: abst_inv)
  done

definition
  "tuple_istuple \<equiv> TupleIsomorphism id id"

lemma tuple_istuple:
  "isomorphic_tuple tuple_istuple"
  by (simp add: isomorphic_tuple_intro [OF _ _ reflexive] tuple_istuple_def)

lemma refl_conj_eq:
  "Q = R \<Longrightarrow> P \<and> Q \<longleftrightarrow> P \<and> R"
  by simp

lemma istuple_UNIV_I: "x \<in> UNIV \<equiv> True"
  by simp

lemma istuple_True_simp: "(True \<Longrightarrow> PROP P) \<equiv> PROP P"
  by simp

lemma prop_subst: "s = t \<Longrightarrow> PROP P t \<Longrightarrow> PROP P s"
  by simp

lemma K_record_comp: "(\<lambda>x. c) \<circ> f = (\<lambda>x. c)" 
  by (simp add: comp_def)

lemma o_eq_dest_lhs:
  "a o b = c \<Longrightarrow> a (b v) = c v"
  by clarsimp

lemma o_eq_id_dest:
  "a o b = id o c \<Longrightarrow> a (b v) = c v"
  by clarsimp


subsection {* Concrete record syntax *}

nonterminals
  ident field_type field_types field fields update updates
syntax
  "_constify"           :: "id => ident"                        ("_")
  "_constify"           :: "longid => ident"                    ("_")

  "_field_type"         :: "[ident, type] => field_type"        ("(2_ ::/ _)")
  ""                    :: "field_type => field_types"          ("_")
  "_field_types"        :: "[field_type, field_types] => field_types"    ("_,/ _")
  "_record_type"        :: "field_types => type"                ("(3'(| _ |'))")
  "_record_type_scheme" :: "[field_types, type] => type"        ("(3'(| _,/ (2... ::/ _) |'))")

  "_field"              :: "[ident, 'a] => field"               ("(2_ =/ _)")
  ""                    :: "field => fields"                    ("_")
  "_fields"             :: "[field, fields] => fields"          ("_,/ _")
  "_record"             :: "fields => 'a"                       ("(3'(| _ |'))")
  "_record_scheme"      :: "[fields, 'a] => 'a"                 ("(3'(| _,/ (2... =/ _) |'))")

  "_update_name"        :: idt
  "_update"             :: "[ident, 'a] => update"              ("(2_ :=/ _)")
  ""                    :: "update => updates"                  ("_")
  "_updates"            :: "[update, updates] => updates"       ("_,/ _")
  "_record_update"      :: "['a, updates] => 'b"                ("_/(3'(| _ |'))" [900,0] 900)

syntax (xsymbols)
  "_record_type"        :: "field_types => type"                ("(3\<lparr>_\<rparr>)")
  "_record_type_scheme" :: "[field_types, type] => type"        ("(3\<lparr>_,/ (2\<dots> ::/ _)\<rparr>)")
  "_record"             :: "fields => 'a"                               ("(3\<lparr>_\<rparr>)")
  "_record_scheme"      :: "[fields, 'a] => 'a"                 ("(3\<lparr>_,/ (2\<dots> =/ _)\<rparr>)")
  "_record_update"      :: "['a, updates] => 'b"                ("_/(3\<lparr>_\<rparr>)" [900,0] 900)


subsection {* Record package *}

use "Tools/record.ML"
setup Record.setup

hide (open) const TupleIsomorphism repr abst istuple_fst istuple_snd
  istuple_fst_update istuple_snd_update istuple_cons
  istuple_surjective_proof_assist istuple_update_accessor_cong_assist
  istuple_update_accessor_eq_assist tuple_istuple

end

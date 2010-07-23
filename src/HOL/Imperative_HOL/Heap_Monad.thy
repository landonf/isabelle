(*  Title:      HOL/Imperative_HOL/Heap_Monad.thy
    Author:     John Matthews, Galois Connections; Alexander Krauss, Lukas Bulwahn & Florian Haftmann, TU Muenchen
*)

header {* A monad with a polymorphic heap and primitive reasoning infrastructure *}

theory Heap_Monad
imports Heap Monad_Syntax
begin

subsection {* The monad *}

subsubsection {* Monad construction *}

text {* Monadic heap actions either produce values
  and transform the heap, or fail *}
datatype 'a Heap = Heap "heap \<Rightarrow> ('a \<times> heap) option"

primrec execute :: "'a Heap \<Rightarrow> heap \<Rightarrow> ('a \<times> heap) option" where
  [code del]: "execute (Heap f) = f"

lemma Heap_cases [case_names succeed fail]:
  fixes f and h
  assumes succeed: "\<And>x h'. execute f h = Some (x, h') \<Longrightarrow> P"
  assumes fail: "execute f h = None \<Longrightarrow> P"
  shows P
  using assms by (cases "execute f h") auto

lemma Heap_execute [simp]:
  "Heap (execute f) = f" by (cases f) simp_all

lemma Heap_eqI:
  "(\<And>h. execute f h = execute g h) \<Longrightarrow> f = g"
    by (cases f, cases g) (auto simp: expand_fun_eq)

ML {* structure Execute_Simps = Named_Thms(
  val name = "execute_simps"
  val description = "simplification rules for execute"
) *}

setup Execute_Simps.setup

lemma execute_Let [execute_simps]:
  "execute (let x = t in f x) = (let x = t in execute (f x))"
  by (simp add: Let_def)


subsubsection {* Specialised lifters *}

definition tap :: "(heap \<Rightarrow> 'a) \<Rightarrow> 'a Heap" where
  [code del]: "tap f = Heap (\<lambda>h. Some (f h, h))"

lemma execute_tap [execute_simps]:
  "execute (tap f) h = Some (f h, h)"
  by (simp add: tap_def)

definition heap :: "(heap \<Rightarrow> 'a \<times> heap) \<Rightarrow> 'a Heap" where
  [code del]: "heap f = Heap (Some \<circ> f)"

lemma execute_heap [execute_simps]:
  "execute (heap f) = Some \<circ> f"
  by (simp add: heap_def)

definition guard :: "(heap \<Rightarrow> bool) \<Rightarrow> (heap \<Rightarrow> 'a \<times> heap) \<Rightarrow> 'a Heap" where
  [code del]: "guard P f = Heap (\<lambda>h. if P h then Some (f h) else None)"

lemma execute_guard [execute_simps]:
  "\<not> P h \<Longrightarrow> execute (guard P f) h = None"
  "P h \<Longrightarrow> execute (guard P f) h = Some (f h)"
  by (simp_all add: guard_def)


subsubsection {* Predicate classifying successful computations *}

definition success :: "'a Heap \<Rightarrow> heap \<Rightarrow> bool" where
  "success f h \<longleftrightarrow> execute f h \<noteq> None"

lemma successI:
  "execute f h \<noteq> None \<Longrightarrow> success f h"
  by (simp add: success_def)

lemma successE:
  assumes "success f h"
  obtains r h' where "r = fst (the (execute c h))"
    and "h' = snd (the (execute c h))"
    and "execute f h \<noteq> None"
  using assms by (simp add: success_def)

ML {* structure Success_Intros = Named_Thms(
  val name = "success_intros"
  val description = "introduction rules for success"
) *}

setup Success_Intros.setup

lemma success_tapI [success_intros]:
  "success (tap f) h"
  by (rule successI) (simp add: execute_simps)

lemma success_heapI [success_intros]:
  "success (heap f) h"
  by (rule successI) (simp add: execute_simps)

lemma success_guardI [success_intros]:
  "P h \<Longrightarrow> success (guard P f) h"
  by (rule successI) (simp add: execute_guard)

lemma success_LetI [success_intros]:
  "x = t \<Longrightarrow> success (f x) h \<Longrightarrow> success (let x = t in f x) h"
  by (simp add: Let_def)

lemma success_ifI:
  "(c \<Longrightarrow> success t h) \<Longrightarrow> (\<not> c \<Longrightarrow> success e h) \<Longrightarrow>
    success (if c then t else e) h"
  by (simp add: success_def)


subsubsection {* Predicate for a simple relational calculus *}

text {*
  The @{text crel} predicate states that when a computation @{text c}
  runs with the heap @{text h} will result in return value @{text r}
  and a heap @{text "h'"}, i.e.~no exception occurs.
*}  

definition crel :: "'a Heap \<Rightarrow> heap \<Rightarrow> heap \<Rightarrow> 'a \<Rightarrow> bool" where
  crel_def: "crel c h h' r \<longleftrightarrow> execute c h = Some (r, h')"

lemma crelI:
  "execute c h = Some (r, h') \<Longrightarrow> crel c h h' r"
  by (simp add: crel_def)

lemma crelE:
  assumes "crel c h h' r"
  obtains "r = fst (the (execute c h))"
    and "h' = snd (the (execute c h))"
    and "success c h"
proof (rule that)
  from assms have *: "execute c h = Some (r, h')" by (simp add: crel_def)
  then show "success c h" by (simp add: success_def)
  from * have "fst (the (execute c h)) = r" and "snd (the (execute c h)) = h'"
    by simp_all
  then show "r = fst (the (execute c h))"
    and "h' = snd (the (execute c h))" by simp_all
qed

lemma crel_success:
  "crel c h h' r \<Longrightarrow> success c h"
  by (simp add: crel_def success_def)

lemma success_crelE:
  assumes "success c h"
  obtains r h' where "crel c h h' r"
  using assms by (auto simp add: crel_def success_def)

lemma crel_deterministic:
  assumes "crel f h h' a"
    and "crel f h h'' b"
  shows "a = b" and "h' = h''"
  using assms unfolding crel_def by auto

ML {* structure Crel_Intros = Named_Thms(
  val name = "crel_intros"
  val description = "introduction rules for crel"
) *}

ML {* structure Crel_Elims = Named_Thms(
  val name = "crel_elims"
  val description = "elimination rules for crel"
) *}

setup "Crel_Intros.setup #> Crel_Elims.setup"

lemma crel_LetI [crel_intros]:
  assumes "x = t" "crel (f x) h h' r"
  shows "crel (let x = t in f x) h h' r"
  using assms by simp

lemma crel_LetE [crel_elims]:
  assumes "crel (let x = t in f x) h h' r"
  obtains "crel (f t) h h' r"
  using assms by simp

lemma crel_ifI:
  assumes "c \<Longrightarrow> crel t h h' r"
    and "\<not> c \<Longrightarrow> crel e h h' r"
  shows "crel (if c then t else e) h h' r"
  by (cases c) (simp_all add: assms)

lemma crel_ifE:
  assumes "crel (if c then t else e) h h' r"
  obtains "c" "crel t h h' r"
    | "\<not> c" "crel e h h' r"
  using assms by (cases c) simp_all

lemma crel_tapI [crel_intros]:
  assumes "h' = h" "r = f h"
  shows "crel (tap f) h h' r"
  by (rule crelI) (simp add: assms execute_simps)

lemma crel_tapE [crel_elims]:
  assumes "crel (tap f) h h' r"
  obtains "h' = h" and "r = f h"
  using assms by (rule crelE) (auto simp add: execute_simps)

lemma crel_heapI [crel_intros]:
  assumes "h' = snd (f h)" "r = fst (f h)"
  shows "crel (heap f) h h' r"
  by (rule crelI) (simp add: assms execute_simps)

lemma crel_heapE [crel_elims]:
  assumes "crel (heap f) h h' r"
  obtains "h' = snd (f h)" and "r = fst (f h)"
  using assms by (rule crelE) (simp add: execute_simps)

lemma crel_guardI [crel_intros]:
  assumes "P h" "h' = snd (f h)" "r = fst (f h)"
  shows "crel (guard P f) h h' r"
  by (rule crelI) (simp add: assms execute_simps)

lemma crel_guardE [crel_elims]:
  assumes "crel (guard P f) h h' r"
  obtains "h' = snd (f h)" "r = fst (f h)" "P h"
  using assms by (rule crelE)
    (auto simp add: execute_simps elim!: successE, cases "P h", auto simp add: execute_simps)


subsubsection {* Monad combinators *}

definition return :: "'a \<Rightarrow> 'a Heap" where
  [code del]: "return x = heap (Pair x)"

lemma execute_return [execute_simps]:
  "execute (return x) = Some \<circ> Pair x"
  by (simp add: return_def execute_simps)

lemma success_returnI [success_intros]:
  "success (return x) h"
  by (rule successI) (simp add: execute_simps)

lemma crel_returnI [crel_intros]:
  "h = h' \<Longrightarrow> crel (return x) h h' x"
  by (rule crelI) (simp add: execute_simps)

lemma crel_returnE [crel_elims]:
  assumes "crel (return x) h h' r"
  obtains "r = x" "h' = h"
  using assms by (rule crelE) (simp add: execute_simps)

definition raise :: "string \<Rightarrow> 'a Heap" where -- {* the string is just decoration *}
  [code del]: "raise s = Heap (\<lambda>_. None)"

lemma execute_raise [execute_simps]:
  "execute (raise s) = (\<lambda>_. None)"
  by (simp add: raise_def)

lemma crel_raiseE [crel_elims]:
  assumes "crel (raise x) h h' r"
  obtains "False"
  using assms by (rule crelE) (simp add: success_def execute_simps)

definition bind :: "'a Heap \<Rightarrow> ('a \<Rightarrow> 'b Heap) \<Rightarrow> 'b Heap" where
  [code del]: "bind f g = Heap (\<lambda>h. case execute f h of
                  Some (x, h') \<Rightarrow> execute (g x) h'
                | None \<Rightarrow> None)"

setup {*
  Adhoc_Overloading.add_variant 
    @{const_name Monad_Syntax.bind} @{const_name Heap_Monad.bind}
*}

lemma execute_bind [execute_simps]:
  "execute f h = Some (x, h') \<Longrightarrow> execute (f \<guillemotright>= g) h = execute (g x) h'"
  "execute f h = None \<Longrightarrow> execute (f \<guillemotright>= g) h = None"
  by (simp_all add: bind_def)

lemma execute_bind_success:
  "success f h \<Longrightarrow> execute (f \<guillemotright>= g) h = execute (g (fst (the (execute f h)))) (snd (the (execute f h)))"
  by (cases f h rule: Heap_cases) (auto elim!: successE simp add: bind_def)

lemma success_bind_executeI:
  "execute f h = Some (x, h') \<Longrightarrow> success (g x) h' \<Longrightarrow> success (f \<guillemotright>= g) h"
  by (auto intro!: successI elim!: successE simp add: bind_def)

lemma success_bind_crelI [success_intros]:
  "crel f h h' x \<Longrightarrow> success (g x) h' \<Longrightarrow> success (f \<guillemotright>= g) h"
  by (auto simp add: crel_def success_def bind_def)

lemma crel_bindI [crel_intros]:
  assumes "crel f h h' r" "crel (g r) h' h'' r'"
  shows "crel (f \<guillemotright>= g) h h'' r'"
  using assms
  apply (auto intro!: crelI elim!: crelE successE)
  apply (subst execute_bind, simp_all)
  done

lemma crel_bindE [crel_elims]:
  assumes "crel (f \<guillemotright>= g) h h'' r'"
  obtains h' r where "crel f h h' r" "crel (g r) h' h'' r'"
  using assms by (auto simp add: crel_def bind_def split: option.split_asm)

lemma execute_bind_eq_SomeI:
  assumes "execute f h = Some (x, h')"
    and "execute (g x) h' = Some (y, h'')"
  shows "execute (f \<guillemotright>= g) h = Some (y, h'')"
  using assms by (simp add: bind_def)

lemma return_bind [simp]: "return x \<guillemotright>= f = f x"
  by (rule Heap_eqI) (simp add: execute_bind execute_simps)

lemma bind_return [simp]: "f \<guillemotright>= return = f"
  by (rule Heap_eqI) (simp add: bind_def execute_simps split: option.splits)

lemma bind_bind [simp]: "(f \<guillemotright>= g) \<guillemotright>= k = (f :: 'a Heap) \<guillemotright>= (\<lambda>x. g x \<guillemotright>= k)"
  by (rule Heap_eqI) (simp add: bind_def execute_simps split: option.splits)

lemma raise_bind [simp]: "raise e \<guillemotright>= f = raise e"
  by (rule Heap_eqI) (simp add: execute_simps)


subsection {* Generic combinators *}

subsubsection {* Assertions *}

definition assert :: "('a \<Rightarrow> bool) \<Rightarrow> 'a \<Rightarrow> 'a Heap" where
  "assert P x = (if P x then return x else raise ''assert'')"

lemma execute_assert [execute_simps]:
  "P x \<Longrightarrow> execute (assert P x) h = Some (x, h)"
  "\<not> P x \<Longrightarrow> execute (assert P x) h = None"
  by (simp_all add: assert_def execute_simps)

lemma success_assertI [success_intros]:
  "P x \<Longrightarrow> success (assert P x) h"
  by (rule successI) (simp add: execute_assert)

lemma crel_assertI [crel_intros]:
  "P x \<Longrightarrow> h' = h \<Longrightarrow> r = x \<Longrightarrow> crel (assert P x) h h' r"
  by (rule crelI) (simp add: execute_assert)
 
lemma crel_assertE [crel_elims]:
  assumes "crel (assert P x) h h' r"
  obtains "P x" "r = x" "h' = h"
  using assms by (rule crelE) (cases "P x", simp_all add: execute_assert success_def)

lemma assert_cong [fundef_cong]:
  assumes "P = P'"
  assumes "\<And>x. P' x \<Longrightarrow> f x = f' x"
  shows "(assert P x >>= f) = (assert P' x >>= f')"
  by (rule Heap_eqI) (insert assms, simp add: assert_def)


subsubsection {* Plain lifting *}

definition lift :: "('a \<Rightarrow> 'b) \<Rightarrow> 'a \<Rightarrow> 'b Heap" where
  "lift f = return o f"

lemma lift_collapse [simp]:
  "lift f x = return (f x)"
  by (simp add: lift_def)

lemma bind_lift:
  "(f \<guillemotright>= lift g) = (f \<guillemotright>= (\<lambda>x. return (g x)))"
  by (simp add: lift_def comp_def)


subsubsection {* Iteration -- warning: this is rarely useful! *}

primrec fold_map :: "('a \<Rightarrow> 'b Heap) \<Rightarrow> 'a list \<Rightarrow> 'b list Heap" where
  "fold_map f [] = return []"
| "fold_map f (x # xs) = do {
     y \<leftarrow> f x;
     ys \<leftarrow> fold_map f xs;
     return (y # ys)
   }"

lemma fold_map_append:
  "fold_map f (xs @ ys) = fold_map f xs \<guillemotright>= (\<lambda>xs. fold_map f ys \<guillemotright>= (\<lambda>ys. return (xs @ ys)))"
  by (induct xs) simp_all

lemma execute_fold_map_unchanged_heap [execute_simps]:
  assumes "\<And>x. x \<in> set xs \<Longrightarrow> \<exists>y. execute (f x) h = Some (y, h)"
  shows "execute (fold_map f xs) h =
    Some (List.map (\<lambda>x. fst (the (execute (f x) h))) xs, h)"
using assms proof (induct xs)
  case Nil show ?case by (simp add: execute_simps)
next
  case (Cons x xs)
  from Cons.prems obtain y
    where y: "execute (f x) h = Some (y, h)" by auto
  moreover from Cons.prems Cons.hyps have "execute (fold_map f xs) h =
    Some (map (\<lambda>x. fst (the (execute (f x) h))) xs, h)" by auto
  ultimately show ?case by (simp, simp only: execute_bind(1), simp add: execute_simps)
qed

subsection {* Code generator setup *}

subsubsection {* Logical intermediate layer *}

primrec raise' :: "String.literal \<Rightarrow> 'a Heap" where
  [code del, code_post]: "raise' (STR s) = raise s"

lemma raise_raise' [code_inline]:
  "raise s = raise' (STR s)"
  by simp

code_datatype raise' -- {* avoid @{const "Heap"} formally *}


subsubsection {* SML and OCaml *}

code_type Heap (SML "unit/ ->/ _")
code_const bind (SML "!(fn/ f'_/ =>/ fn/ ()/ =>/ f'_/ (_/ ())/ ())")
code_const return (SML "!(fn/ ()/ =>/ _)")
code_const Heap_Monad.raise' (SML "!(raise/ Fail/ _)")

code_type Heap (OCaml "unit/ ->/ _")
code_const bind (OCaml "!(fun/ f'_/ ()/ ->/ f'_/ (_/ ())/ ())")
code_const return (OCaml "!(fun/ ()/ ->/ _)")
code_const Heap_Monad.raise' (OCaml "failwith")


subsubsection {* Haskell *}

text {* Adaption layer *}

code_include Haskell "Heap"
{*import qualified Control.Monad;
import qualified Control.Monad.ST;
import qualified Data.STRef;
import qualified Data.Array.ST;

type RealWorld = Control.Monad.ST.RealWorld;
type ST s a = Control.Monad.ST.ST s a;
type STRef s a = Data.STRef.STRef s a;
type STArray s a = Data.Array.ST.STArray s Integer a;

newSTRef = Data.STRef.newSTRef;
readSTRef = Data.STRef.readSTRef;
writeSTRef = Data.STRef.writeSTRef;

newArray :: Integer -> a -> ST s (STArray s a);
newArray k = Data.Array.ST.newArray (0, k);

newListArray :: [a] -> ST s (STArray s a);
newListArray xs = Data.Array.ST.newListArray (0, toInteger (length xs)) xs;

newFunArray :: Integer -> (Integer -> a) -> ST s (STArray s a);
newFunArray k f = Data.Array.ST.newListArray (0, k) (map f [0..k-1]);

lengthArray :: STArray s a -> ST s Integer;
lengthArray a = Control.Monad.liftM snd (Data.Array.ST.getBounds a);

readArray :: STArray s a -> Integer -> ST s a;
readArray = Data.Array.ST.readArray;

writeArray :: STArray s a -> Integer -> a -> ST s ();
writeArray = Data.Array.ST.writeArray;*}

code_reserved Haskell Heap

text {* Monad *}

code_type Heap (Haskell "Heap.ST/ Heap.RealWorld/ _")
code_monad bind Haskell
code_const return (Haskell "return")
code_const Heap_Monad.raise' (Haskell "error")


subsubsection {* Scala *}

code_include Scala "Heap"
{*def bind[A, B](f: Unit => A, g: A => Unit => B): Unit => B = (_: Unit) => g (f ()) ()

class Ref[A](x: A) {
  var value = x
}

object Ref {
  def apply[A](x: A): Ref[A] = new Ref[A](x)
}

def lookup[A](r: Ref[A]): A = r.value

def update[A](r: Ref[A], x: A): Unit = { r.value = x }*}

code_reserved Scala Heap

code_type Heap (Scala "Unit/ =>/ _")
code_const bind (Scala "bind")
code_const return (Scala "('_: Unit)/ =>/ _")
code_const Heap_Monad.raise' (Scala "!error((_))")


subsubsection {* Target variants with less units *}

setup {*

let

open Code_Thingol;

fun imp_program naming =

  let
    fun is_const c = case lookup_const naming c
     of SOME c' => (fn c'' => c' = c'')
      | NONE => K false;
    val is_bind = is_const @{const_name bind};
    val is_return = is_const @{const_name return};
    val dummy_name = "";
    val dummy_type = ITyVar dummy_name;
    val dummy_case_term = IVar NONE;
    (*assumption: dummy values are not relevant for serialization*)
    val unitt = case lookup_const naming @{const_name Unity}
     of SOME unit' => IConst (unit', (([], []), []))
      | NONE => error ("Must include " ^ @{const_name Unity} ^ " in generated constants.");
    fun dest_abs ((v, ty) `|=> t, _) = ((v, ty), t)
      | dest_abs (t, ty) =
          let
            val vs = fold_varnames cons t [];
            val v = Name.variant vs "x";
            val ty' = (hd o fst o unfold_fun) ty;
          in ((SOME v, ty'), t `$ IVar (SOME v)) end;
    fun force (t as IConst (c, _) `$ t') = if is_return c
          then t' else t `$ unitt
      | force t = t `$ unitt;
    fun tr_bind' [(t1, _), (t2, ty2)] =
      let
        val ((v, ty), t) = dest_abs (t2, ty2);
      in ICase (((force t1, ty), [(IVar v, tr_bind'' t)]), dummy_case_term) end
    and tr_bind'' t = case unfold_app t
         of (IConst (c, (_, ty1 :: ty2 :: _)), [x1, x2]) => if is_bind c
              then tr_bind' [(x1, ty1), (x2, ty2)]
              else force t
          | _ => force t;
    fun imp_monad_bind'' ts = (SOME dummy_name, dummy_type) `|=> ICase (((IVar (SOME dummy_name), dummy_type),
      [(unitt, tr_bind' ts)]), dummy_case_term)
    and imp_monad_bind' (const as (c, (_, tys))) ts = if is_bind c then case (ts, tys)
       of ([t1, t2], ty1 :: ty2 :: _) => imp_monad_bind'' [(t1, ty1), (t2, ty2)]
        | ([t1, t2, t3], ty1 :: ty2 :: _) => imp_monad_bind'' [(t1, ty1), (t2, ty2)] `$ t3
        | (ts, _) => imp_monad_bind (eta_expand 2 (const, ts))
      else IConst const `$$ map imp_monad_bind ts
    and imp_monad_bind (IConst const) = imp_monad_bind' const []
      | imp_monad_bind (t as IVar _) = t
      | imp_monad_bind (t as _ `$ _) = (case unfold_app t
         of (IConst const, ts) => imp_monad_bind' const ts
          | (t, ts) => imp_monad_bind t `$$ map imp_monad_bind ts)
      | imp_monad_bind (v_ty `|=> t) = v_ty `|=> imp_monad_bind t
      | imp_monad_bind (ICase (((t, ty), pats), t0)) = ICase
          (((imp_monad_bind t, ty),
            (map o pairself) imp_monad_bind pats),
              imp_monad_bind t0);

  in (Graph.map_nodes o map_terms_stmt) imp_monad_bind end;

in

Code_Target.extend_target ("SML_imp", ("SML", imp_program))
#> Code_Target.extend_target ("OCaml_imp", ("OCaml", imp_program))
#> Code_Target.extend_target ("Scala_imp", ("Scala", imp_program))

end

*}


hide_const (open) Heap heap guard raise' fold_map

end

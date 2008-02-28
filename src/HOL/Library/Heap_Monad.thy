(*  Title:      HOL/Library/Heap_Monad.thy
    ID:         $Id$
    Author:     John Matthews, Galois Connections; Alexander Krauss, Lukas Bulwahn & Florian Haftmann, TU Muenchen
*)

header {* A monad with a polymorphic heap *}

theory Heap_Monad
imports Heap
begin

subsection {* The monad *}

subsubsection {* Monad combinators *}

datatype exception = Exn

text {* Monadic heap actions either produce values
  and transform the heap, or fail *}
datatype 'a Heap = Heap "heap \<Rightarrow> ('a + exception) \<times> heap"

primrec
  execute :: "'a Heap \<Rightarrow> heap \<Rightarrow> ('a + exception) \<times> heap" where
  "execute (Heap f) = f"
lemmas [code del] = execute.simps

lemma Heap_execute [simp]:
  "Heap (execute f) = f" by (cases f) simp_all

lemma Heap_eqI:
  "(\<And>h. execute f h = execute g h) \<Longrightarrow> f = g"
    by (cases f, cases g) (auto simp: expand_fun_eq)

lemma Heap_eqI':
  "(\<And>h. (\<lambda>x. execute (f x) h) = (\<lambda>y. execute (g y) h)) \<Longrightarrow> f = g"
    by (auto simp: expand_fun_eq intro: Heap_eqI)

lemma Heap_strip: "(\<And>f. PROP P f) \<equiv> (\<And>g. PROP P (Heap g))"
proof
  fix g :: "heap \<Rightarrow> ('a + exception) \<times> heap" 
  assume "\<And>f. PROP P f"
  then show "PROP P (Heap g)" .
next
  fix f :: "'a Heap" 
  assume assm: "\<And>g. PROP P (Heap g)"
  then have "PROP P (Heap (execute f))" .
  then show "PROP P f" by simp
qed

definition
  heap :: "(heap \<Rightarrow> 'a \<times> heap) \<Rightarrow> 'a Heap" where
  [code del]: "heap f = Heap (\<lambda>h. apfst Inl (f h))"

lemma execute_heap [simp]:
  "execute (heap f) h = apfst Inl (f h)"
  by (simp add: heap_def)

definition
  run :: "'a Heap \<Rightarrow> 'a Heap" where
  run_drop [code del]: "run f = f"

definition
  bindM :: "'a Heap \<Rightarrow> ('a \<Rightarrow> 'b Heap) \<Rightarrow> 'b Heap" (infixl ">>=" 54) where
  [code del]: "f >>= g = Heap (\<lambda>h. case execute f h of
                  (Inl x, h') \<Rightarrow> execute (g x) h'
                | r \<Rightarrow> r)"

notation
  bindM (infixl "\<guillemotright>=" 54)

abbreviation
  chainM :: "'a Heap \<Rightarrow> 'b Heap \<Rightarrow> 'b Heap"  (infixl ">>" 54) where
  "f >> g \<equiv> f >>= (\<lambda>_. g)"

notation
  chainM (infixl "\<guillemotright>" 54)

definition
  return :: "'a \<Rightarrow> 'a Heap" where
  [code del]: "return x = heap (Pair x)"

lemma execute_return [simp]:
  "execute (return x) h = apfst Inl (x, h)"
  by (simp add: return_def)

definition
  raise :: "string \<Rightarrow> 'a Heap" where -- {* the string is just decoration *}
  [code del]: "raise s = Heap (Pair (Inr Exn))"

notation (latex output)
  "raise" ("\<^raw:{\textsf{raise}}>")

lemma execute_raise [simp]:
  "execute (raise s) h = (Inr Exn, h)"
  by (simp add: raise_def)


subsubsection {* do-syntax *}

text {*
  We provide a convenient do-notation for monadic expressions
  well-known from Haskell.  @{const Let} is printed
  specially in do-expressions.
*}

nonterminals do_expr

syntax
  "_do" :: "do_expr \<Rightarrow> 'a"
    ("(do (_)//done)" [12] 100)
  "_bindM" :: "pttrn \<Rightarrow> 'a \<Rightarrow> do_expr \<Rightarrow> do_expr"
    ("_ <- _;//_" [1000, 13, 12] 12)
  "_chainM" :: "'a \<Rightarrow> do_expr \<Rightarrow> do_expr"
    ("_;//_" [13, 12] 12)
  "_let" :: "pttrn \<Rightarrow> 'a \<Rightarrow> do_expr \<Rightarrow> do_expr"
    ("let _ = _;//_" [1000, 13, 12] 12)
  "_nil" :: "'a \<Rightarrow> do_expr"
    ("_" [12] 12)

syntax (xsymbols)
  "_bindM" :: "pttrn \<Rightarrow> 'a \<Rightarrow> do_expr \<Rightarrow> do_expr"
    ("_ \<leftarrow> _;//_" [1000, 13, 12] 12)
syntax (latex output)
  "_do" :: "do_expr \<Rightarrow> 'a"
    ("(\<^raw:{\textsf{do}}> (_))" [12] 100)
  "_let" :: "pttrn \<Rightarrow> 'a \<Rightarrow> do_expr \<Rightarrow> do_expr"
    ("\<^raw:\textsf{let}> _ = _;//_" [1000, 13, 12] 12)
notation (latex output)
  "return" ("\<^raw:{\textsf{return}}>")

translations
  "_do f" => "CONST run f"
  "_bindM x f g" => "f \<guillemotright>= (\<lambda>x. g)"
  "_chainM f g" => "f \<guillemotright> g"
  "_let x t f" => "CONST Let t (\<lambda>x. f)"
  "_nil f" => "f"

print_translation {*
let
  fun dest_abs_eta (Abs (abs as (_, ty, _))) =
        let
          val (v, t) = Syntax.variant_abs abs;
        in ((v, ty), t) end
    | dest_abs_eta t =
        let
          val (v, t) = Syntax.variant_abs ("", dummyT, t $ Bound 0);
        in ((v, dummyT), t) end
  fun unfold_monad (Const (@{const_syntax bindM}, _) $ f $ g) =
        let
          val ((v, ty), g') = dest_abs_eta g;
          val v_used = fold_aterms
            (fn Free (w, _) => (fn s => s orelse v = w) | _ => I) g' false;
        in if v_used then
          Const ("_bindM", dummyT) $ Free (v, ty) $ f $ unfold_monad g'
        else
          Const ("_chainM", dummyT) $ f $ unfold_monad g'
        end
    | unfold_monad (Const (@{const_syntax chainM}, _) $ f $ g) =
        Const ("_chainM", dummyT) $ f $ unfold_monad g
    | unfold_monad (Const (@{const_syntax Let}, _) $ f $ g) =
        let
          val ((v, ty), g') = dest_abs_eta g;
        in Const ("_let", dummyT) $ Free (v, ty) $ f $ unfold_monad g' end
    | unfold_monad (Const (@{const_syntax Pair}, _) $ f) =
        Const ("return", dummyT) $ f
    | unfold_monad f = f;
  fun tr' (f::ts) =
    list_comb (Const ("_do", dummyT) $ unfold_monad f, ts)
in [(@{const_syntax "run"}, tr')] end;
*}

subsubsection {* Plain evaluation *}

definition
  evaluate :: "'a Heap \<Rightarrow> 'a"
where
  [code del]: "evaluate f = (case execute f Heap.empty
    of (Inl x, _) \<Rightarrow> x)"


subsection {* Monad properties *}

subsubsection {* Superfluous runs *}

text {* @{term run} is just a doodle *}

lemma run_simp [simp]:
  "\<And>f. run (run f) = run f"
  "\<And>f g. run f \<guillemotright>= g = f \<guillemotright>= g"
  "\<And>f g. run f \<guillemotright> g = f \<guillemotright> g"
  "\<And>f g. f \<guillemotright>= (\<lambda>x. run g) = f \<guillemotright>= (\<lambda>x. g)"
  "\<And>f g. f \<guillemotright> run g = f \<guillemotright> g"
  "\<And>f. f = run g \<longleftrightarrow> f = g"
  "\<And>f. run f = g \<longleftrightarrow> f = g"
  unfolding run_drop by rule+

subsubsection {* Monad laws *}

lemma return_bind: "return x \<guillemotright>= f = f x"
  by (simp add: bindM_def return_def)

lemma bind_return: "f \<guillemotright>= return = f"
proof (rule Heap_eqI)
  fix h
  show "execute (f \<guillemotright>= return) h = execute f h"
    by (auto simp add: bindM_def return_def split: sum.splits prod.splits)
qed

lemma bind_bind: "(f \<guillemotright>= g) \<guillemotright>= h = f \<guillemotright>= (\<lambda>x. g x \<guillemotright>= h)"
  by (rule Heap_eqI) (auto simp add: bindM_def split: split: sum.splits prod.splits)

lemma bind_bind': "f \<guillemotright>= (\<lambda>x. g x \<guillemotright>= h x) = f \<guillemotright>= (\<lambda>x. g x \<guillemotright>= (\<lambda>y. return (x, y))) \<guillemotright>= (\<lambda>(x, y). h x y)"
  by (rule Heap_eqI) (auto simp add: bindM_def split: split: sum.splits prod.splits)

lemma raise_bind: "raise e \<guillemotright>= f = raise e"
  by (simp add: raise_def bindM_def)


lemmas monad_simp = return_bind bind_return bind_bind raise_bind


subsection {* Generic combinators *}

definition
  liftM :: "('a \<Rightarrow> 'b) \<Rightarrow> 'a \<Rightarrow> 'b Heap"
where
  "liftM f = return o f"

definition
  compM :: "('a \<Rightarrow> 'b Heap) \<Rightarrow> ('b \<Rightarrow> 'c Heap) \<Rightarrow> 'a \<Rightarrow> 'c Heap" (infixl ">>==" 54)
where
  "(f >>== g) = (\<lambda>x. f x \<guillemotright>= g)"

notation
  compM (infixl "\<guillemotright>==" 54)

lemma liftM_collapse: "liftM f x = return (f x)"
  by (simp add: liftM_def)

lemma liftM_compM: "liftM f \<guillemotright>== g = g o f"
  by (auto intro: Heap_eqI' simp add: expand_fun_eq liftM_def compM_def bindM_def)

lemma compM_return: "f \<guillemotright>== return = f"
  by (simp add: compM_def monad_simp)

lemma compM_compM: "(f \<guillemotright>== g) \<guillemotright>== h = f \<guillemotright>== (g \<guillemotright>== h)"
  by (simp add: compM_def monad_simp)

lemma liftM_bind:
  "(\<lambda>x. liftM f x \<guillemotright>= liftM g) = liftM (\<lambda>x. g (f x))"
  by (rule Heap_eqI') (simp add: monad_simp liftM_def bindM_def)

lemma liftM_comp:
  "liftM f o g = liftM (f o g)"
  by (rule Heap_eqI') (simp add: liftM_def)

lemmas monad_simp' = monad_simp liftM_compM compM_return
  compM_compM liftM_bind liftM_comp

primrec 
  mapM :: "('a \<Rightarrow> 'b Heap) \<Rightarrow> 'a list \<Rightarrow> 'b list Heap"
where
  "mapM f [] = return []"
  | "mapM f (x#xs) = do y \<leftarrow> f x;
                        ys \<leftarrow> mapM f xs;
                        return (y # ys)
                     done"

primrec
  foldM :: "('a \<Rightarrow> 'b \<Rightarrow> 'b Heap) \<Rightarrow> 'a list \<Rightarrow> 'b \<Rightarrow> 'b Heap"
where
  "foldM f [] s = return s"
  | "foldM f (x#xs) s = f x s \<guillemotright>= foldM f xs"

hide (open) const heap execute


subsection {* Code generator setup *}

subsubsection {* Logical intermediate layer *}

definition
  Fail :: "message_string \<Rightarrow> exception"
where
  [code func del]: "Fail s = Exn"

definition
  raise_exc :: "exception \<Rightarrow> 'a Heap"
where
  [code func del]: "raise_exc e = raise []"

lemma raise_raise_exc [code func, code inline]:
  "raise s = raise_exc (Fail (STR s))"
  unfolding Fail_def raise_exc_def raise_def ..

hide (open) const Fail raise_exc


subsubsection {* SML *}

code_type Heap (SML "_")
code_const Heap (SML "raise/ (Fail/ \"bare Heap\")")
code_monad run "op \<guillemotright>=" SML
code_const run (SML "_")
code_const return (SML "_")
code_const "Heap_Monad.Fail" (SML "Fail")
code_const "Heap_Monad.raise_exc" (SML "raise")


subsubsection {* OCaml *}

code_type Heap (OCaml "_")
code_const Heap (OCaml "failwith/ \"bare Heap\"")
code_monad run "op \<guillemotright>=" OCaml
code_const run (OCaml "_")
code_const return (OCaml "_")
code_const "Heap_Monad.Fail" (OCaml "Failure")
code_const "Heap_Monad.raise_exc" (OCaml "raise")

code_reserved OCaml Failure raise


subsubsection {* Haskell *}

text {* Adaption layer *}

code_include Haskell "STMonad"
{*import qualified Control.Monad;
import qualified Control.Monad.ST;
import qualified Data.STRef;
import qualified Data.Array.ST;

type ST s a = Control.Monad.ST.ST s a;
type STRef s a = Data.STRef.STRef s a;
type STArray s a = Data.Array.ST.STArray s Integer a;

runST :: (forall s. ST s a) -> a;
runST s = Control.Monad.ST.runST s;

newSTRef = Data.STRef.newSTRef;
readSTRef = Data.STRef.readSTRef;
writeSTRef = Data.STRef.writeSTRef;

newArray :: (Integer, Integer) -> a -> ST s (STArray s a);
newArray = Data.Array.ST.newArray;

newListArray :: (Integer, Integer) -> [a] -> ST s (STArray s a);
newListArray = Data.Array.ST.newListArray;

length :: STArray s a -> ST s Integer;
length a = Control.Monad.liftM snd (Data.Array.ST.getBounds a);

readArray :: STArray s a -> Integer -> ST s a;
readArray = Data.Array.ST.readArray;

writeArray :: STArray s a -> Integer -> a -> ST s ();
writeArray = Data.Array.ST.writeArray;*}

code_reserved Haskell ST STRef Array
  runST
  newSTRef reasSTRef writeSTRef
  newArray newListArray bounds readArray writeArray

text {* Monad *}

code_type Heap (Haskell "ST '_s _")
code_const Heap (Haskell "error \"bare Heap\")")
code_const evaluate (Haskell "runST")
code_monad run bindM Haskell
code_const return (Haskell "return")
code_const "Heap_Monad.Fail" (Haskell "_")
code_const "Heap_Monad.raise_exc" (Haskell "error")

end

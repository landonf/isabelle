(*  Title:      HOL/Prod.thy
    ID:         Prod.thy,v 1.5 1994/08/19 09:04:27 lcp Exp
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1992  University of Cambridge

Ordered Pairs and the Cartesian product type.
The unit type.
*)

Prod = Fun +

(** Products **)

(* type definition *)

constdefs
  Pair_Rep      :: ['a, 'b] => ['a, 'b] => bool
  "Pair_Rep == (%a b. %x y. x=a & y=b)"

typedef (Prod)
  ('a, 'b) "*"          (infixr 20)
    = "{f. ? a b. f = Pair_Rep (a::'a) (b::'b)}"


(* abstract constants and syntax *)

consts
  fst           :: "'a * 'b => 'a"
  snd           :: "'a * 'b => 'b"
  split         :: "[['a, 'b] => 'c, 'a * 'b] => 'c"
  prod_fun      :: "['a => 'b, 'c => 'd, 'a * 'c] => 'b * 'd"
  Pair          :: "['a, 'b] => 'a * 'b"
  Sigma         :: "['a set, 'a => 'b set] => ('a * 'b) set"

(** Patterns -- extends pre-defined type "pttrn" used in abstractions **)
types pttrns

syntax
  "@Tuple"      :: "['a, args] => 'a * 'b"            ("(1'(_,/ _'))")

  "@pttrn"  :: [pttrn,pttrns] => pttrn              ("'(_,/_')")
  ""        ::  pttrn         => pttrns             ("_")
  "@pttrns" :: [pttrn,pttrns] => pttrns             ("_,/_")

  "@Sigma"  :: "[idt,'a set,'b set] => ('a * 'b)set"
               ("(3SIGMA _:_./ _)" 10)
  "@Times"  :: "['a set, 'a => 'b set] => ('a * 'b) set"
               ("_ Times _" [81,80] 80)

translations
  "(x, y, z)"   == "(x, (y, z))"
  "(x, y)"      == "Pair x y"

  "%(x,y,zs).b"   == "split(%x (y,zs).b)"
  "%(x,y).b"      == "split(%x y.b)"
(*<<<<<<< Prod.thy*)
(* The <= direction fails if split has more than one argument because
   ast-matching fails. Otherwise it would work fine *)

(*=======*)

  "SIGMA x:A. B"  =>  "Sigma A (%x.B)"
  "A Times B"     =>  "Sigma A (_K B)"

(*>>>>>>> 1.13*)
defs
  Pair_def      "Pair a b == Abs_Prod(Pair_Rep a b)"
  fst_def       "fst(p) == @a. ? b. p = (a, b)"
  snd_def       "snd(p) == @b. ? a. p = (a, b)"
  split_def     "split == (%c p. c (fst p) (snd p))"
  prod_fun_def  "prod_fun f g == split(%x y.(f(x), g(y)))"
  Sigma_def     "Sigma A B == UN x:A. UN y:B(x). {(x, y)}"

(** Unit **)

typedef (Unit)
  unit = "{p. p = True}"

consts
  "()"          :: unit                           ("'(')")

defs
  Unity_def     "() == Abs_Unit(True)"

(* start 8bit 1 *)
(* end 8bit 1 *)

end
(*<<<<<<< Prod.thy*)
(*
ML

local open Syntax

fun pttrn(_ $ s $ t) = const"@pttrn" $ s $ t;
fun pttrns s t = const"@pttrns" $ s $ t;

fun split2(Abs(x,T,t)) =
      let val (pats,u) = split1 t
      in (pttrns (Free(x,T)) pats, subst_bounds([free x],u)) end
  | split2(Const("split",_) $ r) =
      let val (pats,s) = split2(r)
          val (pats2,t) = split1(s)
      in (pttrns (pttrn pats) pats2, t) end
and split1(Abs(x,T,t)) =  (Free(x,T), subst_bounds([free x],t))
  | split1(Const("split",_)$t) = split2(t);

fun split_tr'(t::args) =
  let val (pats,ft) = split2(t)
  in list_comb(const"_lambda" $ pttrn pats $ ft, args) end;

in

val print_translation = [("split", split_tr')];

end;
*)
(*=======*)

ML

val print_translation = [("Sigma", dependent_tr' ("@Sigma", "@Times"))];

(*>>>>>>> 1.13*)

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

consts
  Pair_Rep      :: "['a, 'b] => ['a, 'b] => bool"

defs
  Pair_Rep_def  "Pair_Rep == (%a b. %x y. x=a & y=b)"

subtype (Prod)
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

syntax
  "@Tuple"      :: "args => 'a * 'b"            ("(1<_>)")

translations
  "<x, y, z>"   == "<x, <y, z>>"
  "<x, y>"      == "Pair x y"
  "<x>"         => "x"

defs
  Pair_def      "Pair a b == Abs_Prod(Pair_Rep a b)"
  fst_def       "fst(p) == @a. ? b. p = <a, b>"
  snd_def       "snd(p) == @b. ? a. p = <a, b>"
  split_def     "split c p == c (fst p) (snd p)"
  prod_fun_def  "prod_fun f g == split(%x y.<f(x), g(y)>)"
  Sigma_def     "Sigma A B == UN x:A. UN y:B(x). {<x, y>}"



(** Unit **)

subtype (Unit)
  unit = "{p. p = True}"

consts
  Unity         :: "unit"                       ("'(')")

defs
  Unity_def     "Unity == Abs_Unit(True)"

end

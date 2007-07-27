(*  ID:         $Id$
    Authors:    Klaus Aehlig, Tobias Nipkow
*)

header {* Alternativ implementation of "normalization by evaluation" for HOL, including test examples *}

theory Nbe
imports Main
uses
  "~~/src/Tools/Nbe/nbe_eval.ML"
  "~~/src/Tools/Nbe/nbe_package.ML"
begin

lemma [code inline]: "If b f g = bool_case f g b" by auto
lemma [code func]: "null xs \<longleftrightarrow> (case xs of [] \<Rightarrow> True | _ \<Rightarrow> False)"
by (cases xs) auto


ML {* reset Toplevel.debug *}

setup Nbe_Package.setup

method_setup normalization = {*
  Method.no_args (Method.SIMPLE_METHOD'
    (CONVERSION (ObjectLogic.judgment_conv Nbe_Package.normalization_conv)
      THEN' resolve_tac [TrueI, refl]))
*} "solve goal by normalization"


text {* lazy @{const If} *}

definition
  if_delayed :: "bool \<Rightarrow> (bool \<Rightarrow> 'a) \<Rightarrow> (bool \<Rightarrow> 'a) \<Rightarrow> 'a" where
  [code func del]: "if_delayed b f g = (if b then f True else g False)"

lemma [code func]:
  shows "if_delayed True f g = f True"
    and "if_delayed False f g = g False"
  unfolding if_delayed_def by simp_all

lemma [normal pre, symmetric, normal post]:
  "(if b then x else y) = if_delayed b (\<lambda>_. x) (\<lambda>_. y)"
  unfolding if_delayed_def ..

hide (open) const if_delayed

lemma "True"
by normalization
lemma "x = x" by normalization
lemma "True \<or> False"
by normalization
lemma "True \<or> p" by normalization
lemma "p \<longrightarrow> True"
by normalization
declare disj_assoc [code func]
lemma "((P | Q) | R) = (P | (Q | R))" by normalization
declare disj_assoc [code func del]
lemma "0 + (n::nat) = n" by normalization
lemma "0 + Suc n = Suc n" by normalization
lemma "Suc n + Suc m = n + Suc (Suc m)" by normalization
lemma "~((0::nat) < (0::nat))" by normalization

datatype n = Z | S n
consts
  add :: "n \<Rightarrow> n \<Rightarrow> n"
  add2 :: "n \<Rightarrow> n \<Rightarrow> n"
  mul :: "n \<Rightarrow> n \<Rightarrow> n"
  mul2 :: "n \<Rightarrow> n \<Rightarrow> n"
  exp :: "n \<Rightarrow> n \<Rightarrow> n"
primrec
  "add Z = id"
  "add (S m) = S o add m"
primrec
  "add2 Z n = n"
  "add2 (S m) n = S(add2 m n)"

lemma [code]: "add2 (add2 n m) k = add2 n (add2 m k)"
  by(induct n) auto
lemma [code]: "add2 n (S m) =  S (add2 n m)"
  by(induct n) auto
lemma [code]: "add2 n Z = n"
  by(induct n) auto

lemma "add2 (add2 n m) k = add2 n (add2 m k)" by normalization
lemma "add2 (add2 (S n) (S m)) (S k) = S(S(S(add2 n (add2 m k))))" by normalization
lemma "add2 (add2 (S n) (add2 (S m) Z)) (S k) = S(S(S(add2 n (add2 m k))))" by normalization

primrec
  "mul Z = (%n. Z)"
  "mul (S m) = (%n. add (mul m n) n)"
primrec
  "mul2 Z n = Z"
  "mul2 (S m) n = add2 n (mul2 m n)"
primrec
  "exp m Z = S Z"
  "exp m (S n) = mul (exp m n) m"

lemma "mul2 (S(S(S(S(S Z))))) (S(S(S Z))) = S(S(S(S(S(S(S(S(S(S(S(S(S(S(S Z))))))))))))))" by normalization
lemma "mul (S(S(S(S(S Z))))) (S(S(S Z))) = S(S(S(S(S(S(S(S(S(S(S(S(S(S(S Z))))))))))))))" by normalization
lemma "exp (S(S Z)) (S(S(S(S Z)))) = exp (S(S(S(S Z)))) (S(S Z))" by normalization

normal_form "f"
normal_form "f x"
normal_form "(f o g) x"
normal_form "(f o id) x"
normal_form "id"
normal_form "\<lambda>x. x"

lemma "[] @ [] = []" by normalization
lemma "[] @ xs = xs" by normalization
normal_form "[a, b, c] @ xs = a # b # c # xs"
normal_form "map f [x,y,z::'x] = [f x, f y, f z]"
normal_form "map (%f. f True) [id, g, Not] = [True, g True, False]"
normal_form "map (%f. f True) ([id, g, Not] @ fs) = [True, g True, False] @ map (%f. f True) fs"
normal_form "rev [a, b, c] = [c, b, a]"
normal_form "rev (a#b#cs) = rev cs @ [b, a]"
normal_form "map (%F. F [a,b,c::'x]) (map map [f,g,h])"
normal_form "map (%F. F ([a,b,c] @ ds)) (map map ([f,g,h]@fs))"
normal_form "map (%F. F [Z,S Z,S(S Z)]) (map map [S,add (S Z),mul (S(S Z)),id])"
normal_form "filter (%x. x) ([True,False,x]@xs)"
normal_form "filter Not ([True,False,x]@xs)"

normal_form "[x,y,z] @ [a,b,c] = [x, y, z, a, b ,c]"

lemma "(2::int) + 3 - 1 + (- k) * 2 = 4 + - k * 2" by normalization
lemma "(-4::int) * 2 = -8" by normalization
lemma "abs ((-4::int) + 2 * 1) = 2" by normalization
lemma "(2::int) + 3 = 5" by normalization
lemma "(2::int) + 3 * (- 4) * (- 1) = 14" by normalization
lemma "(2::int) + 3 * (- 4) * 1 + 0 = -10" by normalization
lemma "(2::int) < 3" by normalization
lemma "(2::int) <= 3" by normalization
lemma "abs ((-4::int) + 2 * 1) = 2" by normalization
lemma "4 - 42 * abs (3 + (-7\<Colon>int)) = -164" by normalization
lemma "(if (0\<Colon>nat) \<le> (x\<Colon>nat) then 0\<Colon>nat else x) = 0" by normalization

lemma "last [a, b, c] = c"
  by normalization
lemma "last ([a, b, c] @ xs) = (if null xs then c else last xs)"
  by normalization

lemma "(%((x,y),(u,v)). add (add x y) (add u v)) ((Z,Z),(Z,Z)) = Z" by normalization
lemma "split (%x y. x) (a, b) = a" by normalization
lemma "case Z of Z \<Rightarrow> True | S x \<Rightarrow> False" by normalization
lemma "(let ((x,y),(u,v)) = ((Z,Z),(Z,Z)) in add (add x y) (add u v)) = Z" 
by normalization
normal_form "map (%x. case x of None \<Rightarrow> False | Some y \<Rightarrow> True) [None, Some ()]"
normal_form "case xs of [] \<Rightarrow> True | x#xs \<Rightarrow> False"
normal_form "map (%x. case x of None \<Rightarrow> False | Some y \<Rightarrow> True) xs"
normal_form "let x = y::'x in [x,x]"
normal_form "Let y (%x. [x,x])"
normal_form "case n of Z \<Rightarrow> True | S x \<Rightarrow> False"
normal_form "(%(x,y). add x y) (S z,S z)"
normal_form "(%(xs, ys). xs @ ys) ([a, b, c], [d, e, f]) = [a, b, c, d, e, f]"
normal_form "map (%x. case x of None \<Rightarrow> False | Some y \<Rightarrow> True) [None, Some ()] = [False, True]"

normal_form "Suc 0 \<in> set ms"

(* Church numerals: *)

normal_form "(%m n f x. m f (n f x)) (%f x. f(f(f(x)))) (%f x. f(f(f(x))))"
normal_form "(%m n f x. m (n f) x) (%f x. f(f(f(x)))) (%f x. f(f(f(x))))"
normal_form "(%m n. n m) (%f x. f(f(f(x)))) (%f x. f(f(f(x))))"


lemma "nat 4 = Suc (Suc (Suc (Suc 0)))" by normalization
lemma "4 = Suc (Suc (Suc (Suc 0)))" by normalization
lemma "null [x] = False" by normalization
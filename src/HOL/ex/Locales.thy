(*  Title:      HOL/ex/Locales.thy
    ID:         $Id$
    Author:     Markus Wenzel, LMU Muenchen
    License:    GPL (GNU GENERAL PUBLIC LICENSE)
*)

header {* Basic use of locales *}

theory Locales = Main:

text {*
  The inevitable group theory examples formulated with locales.
*}


subsection {* Local contexts as mathematical structures *}

text_raw {*
  \newcommand{\isasyminv}{\isasyminverse}
  \newcommand{\isasymone}{\isamath{1}}
*}

locale group =
  fixes prod :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"    (infixl "\<cdot>" 70)
    and inv :: "'a \<Rightarrow> 'a"    ("(_\<inv>)" [1000] 999)
    and one :: 'a    ("\<one>")
  assumes assoc: "(x \<cdot> y) \<cdot> z = x \<cdot> (y \<cdot> z)"
    and left_inv: "x\<inv> \<cdot> x = \<one>"
    and left_one: "\<one> \<cdot> x = x"

locale abelian_group = group +
  assumes commute: "x \<cdot> y = y \<cdot> x"

theorem (in group)
  right_inv: "x \<cdot> x\<inv> = \<one>"
proof -
  have "x \<cdot> x\<inv> = \<one> \<cdot> (x \<cdot> x\<inv>)" by (simp only: left_one)
  also have "\<dots> = \<one> \<cdot> x \<cdot> x\<inv>" by (simp only: assoc)
  also have "\<dots> = (x\<inv>)\<inv> \<cdot> x\<inv> \<cdot> x \<cdot> x\<inv>" by (simp only: left_inv)
  also have "\<dots> = (x\<inv>)\<inv> \<cdot> (x\<inv> \<cdot> x) \<cdot> x\<inv>" by (simp only: assoc)
  also have "\<dots> = (x\<inv>)\<inv> \<cdot> \<one> \<cdot> x\<inv>" by (simp only: left_inv)
  also have "\<dots> = (x\<inv>)\<inv> \<cdot> (\<one> \<cdot> x\<inv>)" by (simp only: assoc)
  also have "\<dots> = (x\<inv>)\<inv> \<cdot> x\<inv>" by (simp only: left_one)
  also have "\<dots> = \<one>" by (simp only: left_inv)
  finally show ?thesis .
qed

theorem (in group)
  right_one: "x \<cdot> \<one> = x"
proof -
  have "x \<cdot> \<one> = x \<cdot> (x\<inv> \<cdot> x)" by (simp only: left_inv)
  also have "\<dots> = x \<cdot> x\<inv> \<cdot> x" by (simp only: assoc)
  also have "\<dots> = \<one> \<cdot> x" by (simp only: right_inv)
  also have "\<dots> = x" by (simp only: left_one)
  finally show ?thesis .
qed

theorem (in group)
  (assumes eq: "e \<cdot> x = x")
  one_equality: "\<one> = e"
proof -
  have "\<one> = x \<cdot> x\<inv>" by (simp only: right_inv)
  also have "\<dots> = (e \<cdot> x) \<cdot> x\<inv>" by (simp only: eq)
  also have "\<dots> = e \<cdot> (x \<cdot> x\<inv>)" by (simp only: assoc)
  also have "\<dots> = e \<cdot> \<one>" by (simp only: right_inv)
  also have "\<dots> = e" by (simp only: right_one)
  finally show ?thesis .
qed

theorem (in group)
  (assumes eq: "x' \<cdot> x = \<one>")
  inv_equality: "x\<inv> = x'"
proof -
  have "x\<inv> = \<one> \<cdot> x\<inv>" by (simp only: left_one)
  also have "\<dots> = (x' \<cdot> x) \<cdot> x\<inv>" by (simp only: eq)
  also have "\<dots> = x' \<cdot> (x \<cdot> x\<inv>)" by (simp only: assoc)
  also have "\<dots> = x' \<cdot> \<one>" by (simp only: right_inv)
  also have "\<dots> = x'" by (simp only: right_one)
  finally show ?thesis .
qed

theorem (in group)
  inv_prod: "(x \<cdot> y)\<inv> = y\<inv> \<cdot> x\<inv>"
proof (rule inv_equality)
  show "(y\<inv> \<cdot> x\<inv>) \<cdot> (x \<cdot> y) = \<one>"
  proof -
    have "(y\<inv> \<cdot> x\<inv>) \<cdot> (x \<cdot> y) = (y\<inv> \<cdot> (x\<inv> \<cdot> x)) \<cdot> y" by (simp only: assoc)
    also have "\<dots> = (y\<inv> \<cdot> \<one>) \<cdot> y" by (simp only: left_inv)
    also have "\<dots> = y\<inv> \<cdot> y" by (simp only: right_one)
    also have "\<dots> = \<one>" by (simp only: left_inv)
    finally show ?thesis .
  qed
qed

theorem (in abelian_group)
  inv_prod': "(x \<cdot> y)\<inv> = x\<inv> \<cdot> y\<inv>"
proof -
  have "(x \<cdot> y)\<inv> = y\<inv> \<cdot> x\<inv>" by (rule inv_prod)
  also have "\<dots> = x\<inv> \<cdot> y\<inv>" by (rule commute)
  finally show ?thesis .
qed

theorem (in group)
  inv_inv: "(x\<inv>)\<inv> = x"
proof (rule inv_equality)
  show "x \<cdot> x\<inv> = \<one>" by (simp only: right_inv)
qed

theorem (in group)
  (assumes eq: "x\<inv> = y\<inv>")
  inv_inject: "x = y"
proof -
  have "x = x \<cdot> \<one>" by (simp only: right_one)
  also have "\<dots> = x \<cdot> (y\<inv> \<cdot> y)" by (simp only: left_inv)
  also have "\<dots> = x \<cdot> (x\<inv> \<cdot> y)" by (simp only: eq)
  also have "\<dots> = (x \<cdot> x\<inv>) \<cdot> y" by (simp only: assoc)
  also have "\<dots> = \<one> \<cdot> y" by (simp only: right_inv)
  also have "\<dots> = y" by (simp only: left_one)
  finally show ?thesis .
qed


subsection {* Referencing structures implicitly *}

record 'a semigroup =
  prod :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"

syntax
  "_prod1" :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"    (infixl "\<odot>" 70)
  "_prod2" :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"    (infixl "\<odot>\<^sub>2" 70)
  "_prod3" :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"    (infixl "\<odot>\<^sub>3" 70)
translations
  "x \<odot> y" \<rightleftharpoons> "(\<struct>prod) x y"
  "x \<odot>\<^sub>2 y" \<rightleftharpoons> "(\<struct>\<struct>prod) x y"
  "x \<odot>\<^sub>3 y" \<rightleftharpoons> "(\<struct>\<struct>\<struct>prod) x y"

lemma
  (fixes S :: "'a semigroup" (structure)
    and T :: "'a semigroup" (structure)
    and U :: "'a semigroup" (structure))
  "prod S a b = a \<odot> b" ..

lemma
  (fixes S :: "'a semigroup" (structure)
    and T :: "'a semigroup" (structure)
    and U :: "'a semigroup" (structure))
  "prod T a b = a \<odot>\<^sub>2 b" ..

lemma
  (fixes S :: "'a semigroup" (structure)
    and T :: "'a semigroup" (structure)
    and U :: "'a semigroup" (structure))
  "prod U a b = a \<odot>\<^sub>3 b" ..

end
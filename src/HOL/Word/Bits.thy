(*  Title:      HOL/Word/Bits.thy
    Author:     Brian Huffman, PSU and Gerwin Klein, NICTA
*)

section \<open>Syntactic type classes for bit operations\<close>

theory Bits
  imports Main
begin

class bit_operations =
  fixes bitNOT :: "'a \<Rightarrow> 'a"  ("NOT")
    and bitAND :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"  (infixr "AND" 64)
    and bitOR :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"  (infixr "OR"  59)
    and bitXOR :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"  (infixr "XOR" 59)
    and shiftl :: "'a \<Rightarrow> nat \<Rightarrow> 'a"  (infixl "<<" 55)
    and shiftr :: "'a \<Rightarrow> nat \<Rightarrow> 'a"  (infixl ">>" 55)
  fixes test_bit :: "'a \<Rightarrow> nat \<Rightarrow> bool"  (infixl "!!" 100)
    and lsb :: "'a \<Rightarrow> bool"
    and msb :: "'a \<Rightarrow> bool"
    and set_bit :: "'a \<Rightarrow> nat \<Rightarrow> bool \<Rightarrow> 'a"

text \<open>
  We want the bitwise operations to bind slightly weaker
  than \<open>+\<close> and \<open>-\<close>, but \<open>~~\<close> to
  bind slightly stronger than \<open>*\<close>.
\<close>

end

(*  Title:      HOL/Word/More_thy
*)

section \<open>Ancient comprehensive Word Library\<close>

theory More_Word
imports
  Word
  Ancient_Numeral
  Reversed_Bit_Lists
  Bits_Int
  Misc_Auxiliary
  Misc_Arithmetic
  Misc_set_bit
  Misc_lsb
begin

declare signed_take_bit_Suc [simp]

lemmas bshiftr1_def = bshiftr1_eq
lemmas is_down_def = is_down_eq
lemmas is_up_def = is_up_eq
lemmas mask_def = mask_eq_decr_exp
lemmas scast_def = scast_eq
lemmas shiftl1_def = shiftl1_eq
lemmas shiftr1_def = shiftr1_eq
lemmas sshiftr1_def = sshiftr1_eq
lemmas sshiftr_def = sshiftr_eq
lemmas to_bl_def = to_bl_eq
lemmas ucast_def = ucast_eq
lemmas unat_def = unat_eq_nat_uint
lemmas word_cat_def = word_cat_eq
lemmas word_reverse_def = word_reverse_eq_of_bl_rev_to_bl
lemmas word_roti_def = word_roti_eq_word_rotr_word_rotl
lemmas word_rotl_def = word_rotl_eq
lemmas word_rotr_def = word_rotr_eq
lemmas word_sle_def = word_sle_eq
lemmas word_sless_def = word_sless_eq

lemma shiftl_transfer [transfer_rule]:
  includes lifting_syntax
  shows "(pcr_word ===> (=) ===> pcr_word) (<<) (<<)"
  by (auto intro!: rel_funI word_eqI simp add: word.pcr_cr_eq cr_word_def word_size nth_shiftl)

end

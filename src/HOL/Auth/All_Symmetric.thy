theory All_Symmetric
imports Message
begin

text \<open>All keys are symmetric\<close>

defs all_symmetric_def: "all_symmetric \<equiv> True"

lemma isSym_keys: "K \<in> symKeys"
  by (simp add: symKeys_def all_symmetric_def invKey_symmetric) 

end

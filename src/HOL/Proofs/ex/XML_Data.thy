(*  Title:      HOL/Proofs/ex/XML_Data.thy
    Author:     Makarius
    Author:     Stefan Berghofer

XML data representation of proof terms.
*)

theory XML_Data
  imports "HOL-Isar_Examples.Drinker"
begin

subsection \<open>Export and re-import of global proof terms\<close>

ML \<open>
  fun export_proof thy thm =
    Proofterm.encode (Sign.consts_of thy)
      (Proofterm.reconstruct_proof thy (Thm.prop_of thm) (Thm.standard_proof_of true thm));

  fun import_proof thy xml =
    let
      val prf = Proofterm.decode (Sign.consts_of thy) xml;
      val (prf', _) = Proofterm.freeze_thaw_prf prf;
    in Drule.export_without_context (Proof_Checker.thm_of_proof thy prf') end;
\<close>


subsection \<open>Examples\<close>

ML \<open>val thy1 = \<^theory>\<close>

lemma ex: "A \<longrightarrow> A" ..

ML_val \<open>
  val xml = export_proof thy1 @{thm ex};
  val thm = import_proof thy1 xml;
\<close>

ML_val \<open>
  val xml = export_proof thy1 @{thm de_Morgan};
  val thm = import_proof thy1 xml;
\<close>

ML_val \<open>
  val xml = export_proof thy1 @{thm Drinker's_Principle};
  val thm = import_proof thy1 xml;
\<close>

text \<open>Some fairly large proof:\<close>

ML_val \<open>
  val xml = export_proof thy1 @{thm abs_less_iff};
  val thm = import_proof thy1 xml;
  \<^assert> (size (YXML.string_of_body xml) > 500000);
\<close>

end

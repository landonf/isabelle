(*  Title:      HOL/Reconstruction.thy
    ID:         $Id$
    Author:     Lawrence C Paulson
    Copyright   2004  University of Cambridge
*)

header{* Reconstructing external resolution proofs *}

theory Reconstruction
imports Hilbert_Choice Map Infinite_Set Extraction
uses 	 "Tools/polyhash.ML"
         "Tools/res_clause.ML"
	 "Tools/res_hol_clause.ML"
	 "Tools/res_axioms.ML"
	 "Tools/ATP/recon_order_clauses.ML"
	 "Tools/ATP/recon_translate_proof.ML"
	 "Tools/ATP/recon_parse.ML"
	 "Tools/ATP/recon_transfer_proof.ML"
	 "Tools/ATP/AtpCommunication.ML"
	 "Tools/ATP/watcher.ML"
         "Tools/ATP/reduce_axiomsN.ML"
	 "Tools/ATP/res_clasimpset.ML"
	 "Tools/res_atp.ML"
	 "Tools/reconstruction.ML"

begin

setup ResAxioms.meson_method_setup
setup Reconstruction.setup

end

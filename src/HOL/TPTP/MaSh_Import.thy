(*  Title:      HOL/TPTP/MaSh_Import.thy
    Author:     Jasmin Blanchette, TU Muenchen
*)

header {* MaSh Importer *}

theory MaSh_Import
imports MaSh_Export
uses "mash_import.ML"
begin

declare [[sledgehammer_instantiate_inducts]]

ML {*
open MaSh_Import
*}

ML {*
val do_it = false (* switch to "true" to generate the files *);
val thy = @{theory List};
val params = Sledgehammer_Isar.default_params @{context} []
*}

ML {*
if do_it then
  import_and_evaluate_mash_suggestions @{context} params thy "/tmp/mash_suggestions_list"
else
  ()
*}

end

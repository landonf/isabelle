(*  Title:      HOL/TPTP/MaSh_Export.thy
    Author:     Jasmin Blanchette, TU Muenchen
*)

header {* MaSh Exporter *}

theory MaSh_Export
imports MaSh_Export_Base
begin

ML {*
if do_it then
  Isabelle_System.mkdir (Path.explode prefix)
else
  ()
*}

ML {*
if do_it then
  generate_mash_suggestions "nb" @{context} params (range, step) thys max_suggestions
    (prefix ^ "mash_nb_suggestions")
else
  ()
*}

ML {*
if do_it then
  generate_mash_suggestions "knn" @{context} params (range, step) thys max_suggestions
    (prefix ^ "mash_knn_suggestions")
else
  ()
*}

ML {*
if do_it then
  generate_mepo_suggestions @{context} params (range, step) thys max_suggestions
    (prefix ^ "mepo_suggestions")
else
  ()
*}

ML {*
if do_it then
  generate_mesh_suggestions max_suggestions (prefix ^ "mash_nb_suggestions")
    (prefix ^ "mepo_suggestions") (prefix ^ "mesh_nb_suggestions")
else
  ()
*}

ML {*
if do_it then
  generate_mesh_suggestions max_suggestions (prefix ^ "mash_knn_suggestions")
    (prefix ^ "mepo_suggestions") (prefix ^ "mesh_knn_suggestions")
else
  ()
*}

ML {*
if do_it then
  generate_prover_dependencies @{context} params range thys
    (prefix ^ "mash_nb_prover_dependencies")
else
  ()
*}

ML {*
if do_it then
  generate_prover_dependencies @{context} params range thys
    (prefix ^ "mash_knn_prover_dependencies")
else
  ()
*}

ML {*
if do_it then
  generate_mesh_suggestions max_suggestions (prefix ^ "mash_nb_prover_suggestions")
    (prefix ^ "mepo_suggestions") (prefix ^ "mesh_nb_prover_suggestions")
else
  ()
*}

ML {*
if do_it then
  generate_mesh_suggestions max_suggestions (prefix ^ "mash_knn_prover_suggestions")
    (prefix ^ "mepo_suggestions") (prefix ^ "mesh_knn_prover_suggestions")
else
  ()
*}

ML {*
if do_it then
  generate_accessibility @{context} thys (prefix ^ "mash_accessibility")
else
  ()
*}

ML {*
if do_it then
  generate_features @{context} thys (prefix ^ "mash_features")
else
  ()
*}

ML {*
if do_it then
  generate_isar_dependencies @{context} range thys (prefix ^ "mash_dependencies")
else
  ()
*}

ML {*
if do_it then
  generate_isar_commands @{context} prover (range, step) thys max_suggestions
    (prefix ^ "mash_commands")
else
  ()
*}

ML {*
if do_it then
  generate_prover_commands @{context} params (range, step) thys max_suggestions
    (prefix ^ "mash_prover_commands")
else
  ()
*}

end

(*  Title:      HOL/IOA/Asig.thy
    ID:         $Id$
    Author:     Tobias Nipkow & Konrad Slind
    Copyright   1994  TU Muenchen

Action signatures
*)

Asig = Prod +

types 

'a signature = "('a set * 'a set * 'a set)"

consts
  actions,inputs,outputs,internals,externals
                ::"'action signature => 'action set"
  is_asig       ::"'action signature => bool"
  mk_ext_asig   ::"'action signature => 'action signature"


defs

asig_inputs_def    "inputs == fst"
asig_outputs_def   "outputs == (fst o snd)"
asig_internals_def "internals == (snd o snd)"

actions_def
   "actions(asig) == (inputs(asig) Un outputs(asig) Un internals(asig))"

externals_def
   "externals(asig) == (inputs(asig) Un outputs(asig))"

is_asig_def
  "is_asig(triple) ==            
      ((inputs(triple) Int outputs(triple) = {})    & 
       (outputs(triple) Int internals(triple) = {}) & 
       (inputs(triple) Int internals(triple) = {}))"


mk_ext_asig_def
  "mk_ext_asig(triple) == (inputs(triple), outputs(triple), {})"


end 

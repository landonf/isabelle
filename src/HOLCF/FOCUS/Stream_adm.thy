(*  Title:      HOLCF/ex/Stream_adm.thy
    ID:         $Id$
    Author:     David von Oheimb, TU Muenchen
*)

header {* Admissibility for streams *}

theory Stream_adm
imports Stream Continuity
begin

constdefs

  stream_monoP  :: "(('a stream) set \<Rightarrow> ('a stream) set) \<Rightarrow> bool"
  "stream_monoP F \<equiv> \<exists>Q i. \<forall>P s. Fin i \<le> #s \<longrightarrow>
                    (s \<in> F P) = (stream_take i\<cdot>s \<in> Q \<and> iterate i\<cdot>rt\<cdot>s \<in> P)"

  stream_antiP  :: "(('a stream) set \<Rightarrow> ('a stream) set) \<Rightarrow> bool"
  "stream_antiP F \<equiv> \<forall>P x. \<exists>Q i.
                (#x  < Fin i \<longrightarrow> (\<forall>y. x \<sqsubseteq> y \<longrightarrow> y \<in> F P \<longrightarrow> x \<in> F P)) \<and>
                (Fin i <= #x \<longrightarrow> (\<forall>y. x \<sqsubseteq> y \<longrightarrow>
                (y \<in> F P) = (stream_take i\<cdot>y \<in> Q \<and> iterate i\<cdot>rt\<cdot>y \<in> P)))"

  antitonP :: "'a set => bool"
  "antitonP P \<equiv> \<forall>x y. x \<sqsubseteq> y \<longrightarrow> y\<in>P \<longrightarrow> x\<in>P"

ML {* use_legacy_bindings (the_context ()) *}

end

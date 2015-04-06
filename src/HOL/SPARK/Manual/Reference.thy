(*<*)
theory Reference
imports "../SPARK"
begin

syntax (my_constrain output)
  "_constrain" :: "logic => type => logic" ("_ \<Colon> _" [4, 0] 3)
(*>*)

chapter {* HOL-\SPARK{} Reference *}

text {*
\label{sec:spark-reference}
This section is intended as a quick reference for the HOL-\SPARK{} verification
environment. In \secref{sec:spark-commands}, we give a summary of the commands
provided by the HOL-\SPARK{}, while \secref{sec:spark-types} contains a description
of how particular types of \SPARK{} and FDL are modelled in Isabelle.
*}

section {* Commands *}

text {*
\label{sec:spark-commands}
This section describes the syntax and effect of each of the commands provided
by HOL-\SPARK{}.
@{rail \<open>
  @'spark_open' name ('(' name ')')?
\<close>}
Opens a new \SPARK{} verification environment and loads a \texttt{*.siv} file with VCs.
Alternatively, \texttt{*.vcg} files can be loaded using \isa{\isacommand{spark\_open\_vcg}}.
The corresponding \texttt{*.fdl} and \texttt{*.rls}
files must reside in the same directory as the file given as an argument to the command.
This command also generates records and datatypes for the types specified in the
\texttt{*.fdl} file, unless they have already been associated with user-defined
Isabelle types (see below).
Since the full package name currently cannot be determined from the files generated by the
\SPARK{} Examiner, the command also allows to specify an optional package prefix in the
format \texttt{$p_1$\_\_$\ldots$\_\_$p_n$}. When working with projects consisting of several
packages, this is necessary in order for the verification environment to be able to map proof
functions and types defined in Isabelle to their \SPARK{} counterparts.
@{rail \<open>
  @'spark_proof_functions' ((name '=' term)+)
\<close>}
Associates a proof function with the given name to a term. The name should be the full name
of the proof function as it appears in the \texttt{*.fdl} file, including the package prefix.
This command can be used both inside and outside a verification environment. The latter
variant is useful for introducing proof functions that are shared by several procedures
or packages, whereas the former allows the given term to refer to the types generated
by \isa{\isacommand{spark\_open}} for record or enumeration types specified in the
\texttt{*.fdl} file.
@{rail \<open>
  @'spark_types' ((name '=' type (mapping?))+)
  ;
  mapping: '('((name '=' nameref)+',')')'
\<close>}
Associates a \SPARK{} type with the given name with an Isabelle type. This command can
only be used outside a verification environment. The given type must be either a record
or a datatype, where the names of fields or constructors must either match those of the
corresponding \SPARK{} types (modulo casing), or a mapping from \SPARK{} to Isabelle
names has to be provided.
This command is useful when having to define
proof functions referring to record or enumeration types that are shared by several
procedures or packages. First, the types required by the proof functions can be introduced
using Isabelle's commands for defining records or datatypes. Having introduced the
types, the proof functions can be defined in Isabelle. Finally, both the proof
functions and the types can be associated with their \SPARK{} counterparts.
@{rail \<open>
  @'spark_status' (('(proved)' | '(unproved)')?)
\<close>}
Outputs the variables declared in the \texttt{*.fdl} file, the rules declared in
the \texttt{*.rls} file, and all VCs, together with their status (proved, unproved).
The output can be restricted to the proved or unproved VCs by giving the corresponding
option to the command.
@{rail \<open>
  @'spark_vc' name
\<close>}
Initiates the proof of the VC with the given name. Similar to the standard
\isa{\isacommand{lemma}} or \isa{\isacommand{theorem}} commands, this command
must be followed by a sequence of proof commands. The command introduces the
hypotheses \texttt{H1} \dots \texttt{H$n$}, as well as the identifiers
\texttt{?C1} \dots \texttt{?C$m$} corresponding to the conclusions of the VC.
@{rail \<open>
  @'spark_end' '(incomplete)'?
\<close>}
Closes the current verification environment. Unless the \texttt{incomplete}
option is given, all VCs must have been proved,
otherwise the command issues an error message. As a side effect, the command
generates a proof review (\texttt{*.prv}) file to inform POGS of the proved
VCs.
*}

section {* Types *}

text {*
\label{sec:spark-types}
The main types of FDL are integers, enumeration types, records, and arrays.
In the following sections, we describe how these types are modelled in
Isabelle.
*}

subsection {* Integers *}

text {*
The FDL type \texttt{integer} is modelled by the Isabelle type @{typ int}.
While the FDL \texttt{mod} operator behaves in the same way as its Isabelle
counterpart, this is not the case for the \texttt{div} operator. As has already
been mentioned in \secref{sec:proving-vcs}, the \texttt{div} operator of \SPARK{}
always truncates towards zero, whereas the @{text div} operator of Isabelle
truncates towards minus infinity. Therefore, the FDL \texttt{div} operator is
mapped to the @{text sdiv} operator in Isabelle. The characteristic theorems
of @{text sdiv}, in particular those describing the relationship with the standard
@{text div} operator, are shown in \figref{fig:sdiv-properties}
\begin{figure}
\begin{center}
\small
\begin{tabular}{ll}
@{text sdiv_def}: & @{thm sdiv_def} \\
@{text sdiv_minus_dividend}: & @{thm sdiv_minus_dividend} \\
@{text sdiv_minus_divisor}: & @{thm sdiv_minus_divisor} \\
@{text sdiv_pos_pos}: & @{thm [mode=no_brackets] sdiv_pos_pos} \\
@{text sdiv_pos_neg}: & @{thm [mode=no_brackets] sdiv_pos_neg} \\
@{text sdiv_neg_pos}: & @{thm [mode=no_brackets] sdiv_neg_pos} \\
@{text sdiv_neg_neg}: & @{thm [mode=no_brackets] sdiv_neg_neg} \\
\end{tabular}
\end{center}
\caption{Characteristic properties of @{text sdiv}}
\label{fig:sdiv-properties}
\end{figure}

\begin{figure}
\begin{center}
\small
\begin{tabular}{ll}
@{text AND_lower}: & @{thm [mode=no_brackets] AND_lower} \\
@{text OR_lower}: & @{thm [mode=no_brackets] OR_lower} \\
@{text XOR_lower}: & @{thm [mode=no_brackets] XOR_lower} \\
@{text AND_upper1}: & @{thm [mode=no_brackets] AND_upper1} \\
@{text AND_upper2}: & @{thm [mode=no_brackets] AND_upper2} \\
@{text OR_upper}: & @{thm [mode=no_brackets] OR_upper} \\
@{text XOR_upper}: & @{thm [mode=no_brackets] XOR_upper} \\
@{text AND_mod}: & @{thm [mode=no_brackets] AND_mod}
\end{tabular}
\end{center}
\caption{Characteristic properties of bitwise operators}
\label{fig:bitwise}
\end{figure}
The bitwise logical operators of \SPARK{} and FDL are modelled by the operators
@{text AND}, @{text OR} and @{text XOR} from Isabelle's @{text Word} library,
all of which have type @{typ "int \<Rightarrow> int \<Rightarrow> int"}. A list of properties of these
operators that are useful in proofs about \SPARK{} programs are shown in
\figref{fig:bitwise}
*}

subsection {* Enumeration types *}

text {*
The FDL enumeration type
\begin{alltt}
type \(t\) = (\(e\sb{1}\), \(e\sb{2}\), \dots, \(e\sb{n}\));
\end{alltt}
is modelled by the Isabelle datatype
\begin{isabelle}
\normalsize
\isacommand{datatype}\ $t$\ =\ $e_1$\ $\mid$\ $e_2$\ $\mid$\ \dots\ $\mid$\ $e_n$
\end{isabelle}
The HOL-\SPARK{} environment defines a type class @{class spark_enum} that captures
the characteristic properties of all enumeration types. It provides the following
polymorphic functions and constants for all types @{text "'a"} of this type class:
\begin{flushleft}
@{term_type [mode=my_constrain] pos} \\
@{term_type [mode=my_constrain] val} \\
@{term_type [mode=my_constrain] succ} \\
@{term_type [mode=my_constrain] pred} \\
@{term_type [mode=my_constrain] first_el} \\
@{term_type [mode=my_constrain] last_el}
\end{flushleft}
In addition, @{class spark_enum} is a subclass of the @{class linorder} type class,
which allows the comparison operators @{text "<"} and @{text "\<le>"} to be used on
enumeration types. The polymorphic operations shown above enjoy a number of
generic properties that hold for all enumeration types. These properties are
listed in \figref{fig:enum-generic-properties}.
Moreover, \figref{fig:enum-specific-properties} shows a list of properties
that are specific to each enumeration type $t$, such as the characteristic
equations for @{term val} and @{term pos}.
\begin{figure}[t]
\begin{center}
\small
\begin{tabular}{ll}
@{text range_pos}: & @{thm range_pos} \\
@{text less_pos}: & @{thm less_pos} \\
@{text less_eq_pos}: & @{thm less_eq_pos} \\
@{text val_def}: & @{thm val_def} \\
@{text succ_def}: & @{thm succ_def} \\
@{text pred_def}: & @{thm pred_def} \\
@{text first_el_def}: & @{thm first_el_def} \\
@{text last_el_def}: & @{thm last_el_def} \\
@{text inj_pos}: & @{thm inj_pos} \\
@{text val_pos}: & @{thm val_pos} \\
@{text pos_val}: & @{thm pos_val} \\
@{text first_el_smallest}: & @{thm first_el_smallest} \\
@{text last_el_greatest}: & @{thm last_el_greatest} \\
@{text pos_succ}: & @{thm pos_succ} \\
@{text pos_pred}: & @{thm pos_pred} \\
@{text succ_val}: & @{thm succ_val} \\
@{text pred_val}: & @{thm pred_val}
\end{tabular}
\end{center}
\caption{Generic properties of functions on enumeration types}
\label{fig:enum-generic-properties}
\end{figure}
\begin{figure}[t]
\begin{center}
\small
\begin{tabular}{ll@ {\hspace{2cm}}ll}
\texttt{$t$\_val}: & \isa{val\ $0$\ =\ $e_1$} & \texttt{$t$\_pos}: & pos\ $e_1$\ =\ $0$ \\
                   & \isa{val\ $1$\ =\ $e_2$} &                    & pos\ $e_2$\ =\ $1$ \\
                   & \hspace{1cm}\vdots       &                    & \hspace{1cm}\vdots \\
                   & \isa{val\ $(n-1)$\ =\ $e_n$} &                & pos\ $e_n$\ =\ $n-1$
\end{tabular} \\[3ex]
\begin{tabular}{ll}
\texttt{$t$\_card}: & \isa{card($t$)\ =\ $n$} \\
\texttt{$t$\_first\_el}: & \isa{first\_el\ =\ $e_1$} \\
\texttt{$t$\_last\_el}: & \isa{last\_el\ =\ $e_n$}
\end{tabular}
\end{center}
\caption{Type-specific properties of functions on enumeration types}
\label{fig:enum-specific-properties}
\end{figure}
*}

subsection {* Records *}

text {*
The FDL record type
\begin{alltt}
type \(t\) = record
      \(f\sb{1}\) : \(t\sb{1}\);
       \(\vdots\)
      \(f\sb{n}\) : \(t\sb{n}\)
   end;
\end{alltt}
is modelled by the Isabelle record type
\begin{isabelle}
\normalsize
\isacommand{record}\ t\ = \isanewline
\ \ $f_1$\ ::\ $t_1$ \isanewline
\ \ \ \vdots \isanewline
\ \ $f_n$\ ::\ $t_n$
\end{isabelle}
Records are constructed using the notation
\isa{\isasymlparr$f_1$\ =\ $v_1$,\ $\ldots$,\ $f_n$\ =\ $v_n$\isasymrparr},
a field $f_i$ of a record $r$ is selected using the notation $f_i~r$, and the
fields $f$ and $f'$ of a record $r$ can be updated using the notation
\mbox{\isa{$r$\ \isasymlparr$f$\ :=\ $v$,\ $f'$\ :=\ $v'$\isasymrparr}}.
*}

subsection {* Arrays *}

text {*
The FDL array type
\begin{alltt}
type \(t\) = array [\(t\sb{1}\), \(\ldots\), \(t\sb{n}\)] of \(u\);
\end{alltt}
is modelled by the Isabelle function type $t_1 \times \cdots \times t_n \Rightarrow u$.
Array updates are written as \isa{$A$($x_1$\ := $y_1$,\ \dots,\ $x_n$\ :=\ $y_n$)}.
To allow updating an array at a set of indices, HOL-\SPARK{} provides the notation
\isa{\dots\ [:=]\ \dots}, which can be combined with \isa{\dots\ :=\ \dots} and has
the properties
@{thm [display,mode=no_brackets] fun_upds_in fun_upds_notin upds_singleton}
Thus, we can write expressions like
@{term [display] "(A::int\<Rightarrow>int) ({0..9} [:=] 42, 15 := 99, {20..29} [:=] 0)"}
that would be cumbersome to write using single updates.
*}

section {* User-defined proof functions and types *}

text {*
To illustrate the interplay between the commands for introducing user-defined proof
functions and types mentioned in \secref{sec:spark-commands}, we now discuss a larger
example involving the definition of proof functions on complex types. Assume we would
like to define an array type, whose elements are records that themselves contain
arrays. Moreover, assume we would like to initialize all array elements and record
fields of type \texttt{Integer} in an array of this type with the value \texttt{0}.
The specification of package \texttt{Complex\_Types} containing the definition of
the array type, which we call \texttt{Array\_Type2}, is shown in \figref{fig:complex-types}.
It also contains the declaration of a proof function \texttt{Initialized} that is used
to express that the array has been initialized. The two other proof functions
\texttt{Initialized2} and \texttt{Initialized3} are used to reason about the
initialization of the inner array. Since the array types and proof functions
may be used by several packages, such as the one shown in \figref{fig:complex-types-app},
it is advantageous to define the proof functions in a central theory that can
be included by other theories containing proofs about packages using \texttt{Complex\_Types}.
We show this theory in \figref{fig:complex-types-thy}. Since the proof functions
refer to the enumeration and record types defined in \texttt{Complex\_Types},
we need to define the Isabelle counterparts of these types using the
\isa{\isacommand{datatype}} and \isa{\isacommand{record}} commands in order
to be able to write down the definition of the proof functions. These types are
linked to the corresponding \SPARK{} types using the \isa{\isacommand{spark\_types}}
command. Note that we have to specify the full name of the \SPARK{} functions
including the package prefix. Using the logic of Isabelle, we can then define
functions involving the enumeration and record types introduced above, and link
them to the corresponding \SPARK{} proof functions. It is important that the
\isa{\isacommand{definition}} commands are preceeded by the \isa{\isacommand{spark\_types}}
command, since the definition of @{text initialized3} uses the @{text val}
function for enumeration types that is only available once that @{text day}
has been declared as a \SPARK{} type.
\begin{figure}
\lstinputlisting{complex_types.ads}
\caption{Nested array and record types}
\label{fig:complex-types}
\end{figure}
\begin{figure}
\lstinputlisting{complex_types_app.ads}
\lstinputlisting{complex_types_app.adb}
\caption{Application of \texttt{Complex\_Types} package}
\label{fig:complex-types-app}
\end{figure}
\begin{figure}
\input{Complex_Types}
\caption{Theory defining proof functions for complex types}
\label{fig:complex-types-thy}
\end{figure}
*}

(*<*)
end
(*>*)

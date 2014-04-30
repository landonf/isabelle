(*<*)
theory Example_Verification
imports "../Examples/Gcd/Greatest_Common_Divisor" Simple_Greatest_Common_Divisor
begin
(*>*)

chapter {* Verifying an Example Program *}

text {*
\label{sec:example-verification}
\begin{figure}
\lstinputlisting{Gcd.ads}
\lstinputlisting{Gcd.adb}
\caption{\SPARK{} program for computing the greatest common divisor}
\label{fig:gcd-prog}
\end{figure}

\begin{figure}
\input{Greatest_Common_Divisor}
\caption{Correctness proof for the greatest common divisor program}
\label{fig:gcd-proof}
\end{figure}
We will now explain the usage of the \SPARK{} verification environment by proving
the correctness of an example program. As an example, we use a program for computing
the \emph{greatest common divisor} of two natural numbers shown in \figref{fig:gcd-prog},
which has been taken from the book about \SPARK{} by Barnes \cite[\S 11.6]{Barnes}.
*}

section {* Importing \SPARK{} VCs into Isabelle *}

text {*
In order to specify that the \SPARK{} procedure \texttt{G\_C\_D} behaves like its
mathematical counterpart, Barnes introduces a \emph{proof function} \texttt{Gcd}
in the package specification. Invoking the \SPARK{} Examiner and Simplifier on
this program yields a file \texttt{g\_c\_d.siv} containing the simplified VCs,
as well as files \texttt{g\_c\_d.fdl} and \texttt{g\_c\_d.rls}, containing FDL
declarations and rules, respectively. The files generated by \SPARK{} are assumed to reside in the
subdirectory \texttt{greatest\_common\_divisor}. For \texttt{G\_C\_D} the
Examiner generates ten VCs, eight of which are proved automatically by
the Simplifier. We now show how to prove the remaining two VCs
interactively using HOL-\SPARK{}. For this purpose, we create a \emph{theory}
\texttt{Greatest\_Common\_Divisor}, which is shown in \figref{fig:gcd-proof}.
A theory file always starts with the keyword \isa{\isacommand{theory}} followed
by the name of the theory, which must be the same as the file name. The theory
name is followed by the keyword \isa{\isacommand{imports}} and a list of theories
imported by the current theory. All theories using the HOL-\SPARK{} verification
environment must import the theory \texttt{SPARK}. In addition, we also include
the \texttt{GCD} theory. The list of imported theories is followed by the
\isa{\isacommand{begin}} keyword. In order to interactively process the theory
shown in \figref{fig:gcd-proof}, we start Isabelle with the command
\begin{verbatim}
  isabelle emacs -l HOL-SPARK Greatest_Common_Divisor.thy
\end{verbatim}
The option ``\texttt{-l HOL-SPARK}'' instructs Isabelle to load the right
object logic image containing the verification environment. Each proof function
occurring in the specification of a \SPARK{} program must be linked with a
corresponding Isabelle function. This is accomplished by the command
\isa{\isacommand{spark\_proof\_functions}}, which expects a list of equations
of the form \emph{name}\texttt{\ =\ }\emph{term}, where \emph{name} is the
name of the proof function and \emph{term} is the corresponding Isabelle term.
In the case of \texttt{gcd}, both the \SPARK{} proof function and its Isabelle
counterpart happen to have the same name. Isabelle checks that the type of the
term linked with a proof function agrees with the type of the function declared
in the \texttt{*.fdl} file.
It is worth noting that the
\isa{\isacommand{spark\_proof\_functions}} command can be invoked both outside,
i.e.\ before \isa{\isacommand{spark\_open}}, and inside the environment, i.e.\ after
\isa{\isacommand{spark\_open}}, but before any \isa{\isacommand{spark\_vc}} command. The
former variant is useful when having to declare proof functions that are shared by several
procedures, whereas the latter has the advantage that the type of the proof function
can be checked immediately, since the VCs, and hence also the declarations of proof
functions in the \texttt{*.fdl} file have already been loaded.
\begin{figure}
\begin{flushleft}
\tt
Context: \\
\ \\
\begin{tabular}{ll}
fixes & @{text "m ::"}\ "@{text int}" \\
and   & @{text "n ::"}\ "@{text int}" \\
and   & @{text "c ::"}\ "@{text int}" \\
and   & @{text "d ::"}\ "@{text int}" \\
assumes & @{text "g_c_d_rules1:"}\ "@{text "0 \<le> integer__size"}" \\
and     & @{text "g_c_d_rules6:"}\ "@{text "0 \<le> natural__size"}" \\
\multicolumn{2}{l}{notes definition} \\
\multicolumn{2}{l}{\hspace{2ex}@{text "defns ="}\ `@{text "integer__first = - 2147483648"}`} \\
\multicolumn{2}{l}{\hspace{4ex}`@{text "integer__last = 2147483647"}`} \\
\multicolumn{2}{l}{\hspace{4ex}\dots}
\end{tabular}\ \\[1.5ex]
\ \\
Definitions: \\
\ \\
\begin{tabular}{ll}
@{text "g_c_d_rules2:"} & @{text "integer__first = - 2147483648"} \\
@{text "g_c_d_rules3:"} & @{text "integer__last = 2147483647"} \\
\dots
\end{tabular}\ \\[1.5ex]
\ \\
Verification conditions: \\
\ \\
path(s) from assertion of line 10 to assertion of line 10 \\
\ \\
@{text procedure_g_c_d_4}\ (unproved) \\
\ \ \begin{tabular}{ll}
assumes & @{text "H1:"}\ "@{text "0 \<le> c"}" \\
and     & @{text "H2:"}\ "@{text "0 < d"}" \\
and     & @{text "H3:"}\ "@{text "gcd c d = gcd m n"}" \\
\dots \\
shows & "@{text "0 < c - c sdiv d * d"}" \\
and   & "@{text "gcd d (c - c sdiv d * d) = gcd m n"}
\end{tabular}\ \\[1.5ex]
\ \\
path(s) from assertion of line 10 to finish \\
\ \\
@{text procedure_g_c_d_11}\ (unproved) \\
\ \ \begin{tabular}{ll}
assumes & @{text "H1:"}\ "@{text "0 \<le> c"}" \\
and     & @{text "H2:"}\ "@{text "0 < d"}" \\
and     & @{text "H3:"}\ "@{text "gcd c d = gcd m n"}" \\
\dots \\
shows & "@{text "d = gcd m n"}"
\end{tabular}
\end{flushleft}
\caption{Output of \isa{\isacommand{spark\_status}} for \texttt{g\_c\_d.siv}}
\label{fig:gcd-status}
\end{figure}
We now instruct Isabelle to open
a new verification environment and load a set of VCs. This is done using the
command \isa{\isacommand{spark\_open}}, which must be given the name of a
\texttt{*.siv} file as an argument. Behind the scenes, Isabelle
parses this file and the corresponding \texttt{*.fdl} and \texttt{*.rls} files,
and converts the VCs to Isabelle terms. Using the command \isa{\isacommand{spark\_status}},
the user can display the current VCs together with their status (proved, unproved).
The variants \isa{\isacommand{spark\_status}\ (proved)}
and \isa{\isacommand{spark\_status}\ (unproved)} show only proved and unproved
VCs, respectively. For \texttt{g\_c\_d.siv}, the output of
\isa{\isacommand{spark\_status}} is shown in \figref{fig:gcd-status}.
To minimize the number of assumptions, and hence the size of the VCs,
FDL rules of the form ``\dots\ \texttt{may\_be\_replaced\_by}\ \dots'' are
turned into native Isabelle definitions, whereas other rules are modelled
as assumptions.
*}

section {* Proving the VCs *}

text {*
\label{sec:proving-vcs}
The two open VCs are @{text procedure_g_c_d_4} and @{text procedure_g_c_d_11},
both of which contain the @{text gcd} proof function that the \SPARK{} Simplifier
does not know anything about. The proof of a particular VC can be started with
the \isa{\isacommand{spark\_vc}} command, which is similar to the standard
\isa{\isacommand{lemma}} and \isa{\isacommand{theorem}} commands, with the
difference that it only takes a name of a VC but no formula as an argument.
A VC can have several conclusions that can be referenced by the identifiers
@{text "?C1"}, @{text "?C2"}, etc. If there is just one conclusion, it can
also be referenced by @{text "?thesis"}. It is important to note that the
\texttt{div} operator of FDL behaves differently from the @{text div} operator
of Isabelle/HOL on negative numbers. The former always truncates towards zero,
whereas the latter truncates towards minus infinity. This is why the FDL
\texttt{div} operator is mapped to the @{text sdiv} operator in Isabelle/HOL,
which is defined as
@{thm [display] sdiv_def}
For example, we have that
@{lemma "-5 sdiv 4 = -1" by (simp add: sdiv_neg_pos)}, but
@{lemma "(-5::int) div 4 = -2" by simp}.
For non-negative dividend and divisor, @{text sdiv} is equivalent to @{text div},
as witnessed by theorem @{text sdiv_pos_pos}:
@{thm [display,mode=no_brackets] sdiv_pos_pos}
In contrast, the behaviour of the FDL \texttt{mod} operator is equivalent to
the one of Isabelle/HOL. Moreover, since FDL has no counterpart of the \SPARK{}
operator \textbf{rem}, the \SPARK{} expression \texttt{c}\ \textbf{rem}\ \texttt{d}
just becomes @{text "c - c sdiv d * d"} in Isabelle. The first conclusion of
@{text procedure_g_c_d_4} requires us to prove that the remainder of @{text c}
and @{text d} is greater than @{text 0}. To do this, we use the theorem
@{text zmod_zdiv_equality'} describing the correspondence between @{text div}
and @{text mod}
@{thm [display] zmod_zdiv_equality'}
together with the theorem @{text pos_mod_sign} saying that the result of the
@{text mod} operator is non-negative when applied to a non-negative divisor:
@{thm [display] pos_mod_sign}
We will also need the aforementioned theorem @{text sdiv_pos_pos} in order for
the standard Isabelle/HOL theorems about @{text div} to be applicable
to the VC, which is formulated using @{text sdiv} rather that @{text div}.
Note that the proof uses \texttt{`@{text "0 \<le> c"}`} and \texttt{`@{text "0 < d"}`}
rather than @{text H1} and @{text H2} to refer to the hypotheses of the current
VC. While the latter variant seems more compact, it is not particularly robust,
since the numbering of hypotheses can easily change if the corresponding
program is modified, making the proof script hard to adjust when there are many hypotheses.
Moreover, proof scripts using abbreviations like @{text H1} and @{text H2}
are hard to read without assistance from Isabelle.
The second conclusion of @{text procedure_g_c_d_4} requires us to prove that
the @{text gcd} of @{text d} and the remainder of @{text c} and @{text d}
is equal to the @{text gcd} of the original input values @{text m} and @{text n},
which is the actual \emph{invariant} of the procedure. This is a consequence
of theorem @{text gcd_non_0_int}
@{thm [display] gcd_non_0_int}
Again, we also need theorems @{text zmod_zdiv_equality'} and @{text sdiv_pos_pos}
to justify that \SPARK{}'s \textbf{rem} operator is equivalent to Isabelle's
@{text mod} operator for non-negative operands.
The VC @{text procedure_g_c_d_11} says that if the loop invariant holds before
the last iteration of the loop, the postcondition of the procedure will hold
after execution of the loop body. To prove this, we observe that the remainder
of @{text c} and @{text d}, and hence @{text "c mod d"} is @{text 0} when exiting
the loop. This implies that @{text "gcd c d = d"}, since @{text c} is divisible
by @{text d}, so the conclusion follows using the assumption @{text "gcd c d = gcd m n"}.
This concludes the proofs of the open VCs, and hence the \SPARK{} verification
environment can be closed using the command \isa{\isacommand{spark\_end}}.
This command checks that all VCs have been proved and issues an error message
if there are remaining unproved VCs. Moreover, Isabelle checks that there is
no open \SPARK{} verification environment when the final \isa{\isacommand{end}}
command of a theory is encountered.
*}

section {* Optimizing the proof *}

text {*
\begin{figure}
\lstinputlisting{Simple_Gcd.adb}
\input{Simple_Greatest_Common_Divisor}
\caption{Simplified greatest common divisor program and proof}
\label{fig:simple-gcd-proof}
\end{figure}
When looking at the program from \figref{fig:gcd-prog} once again, several
optimizations come to mind. First of all, like the input parameters of the
procedure, the local variables \texttt{C}, \texttt{D}, and \texttt{R} can
be declared as \texttt{Natural} rather than \texttt{Integer}. Since natural
numbers are non-negative by construction, the values computed by the algorithm
are trivially proved to be non-negative. Since we are working with non-negative
numbers, we can also just use \SPARK{}'s \textbf{mod} operator instead of
\textbf{rem}, which spares us an application of theorems @{text zmod_zdiv_equality'}
and @{text sdiv_pos_pos}. Finally, as noted by Barnes \cite[\S 11.5]{Barnes},
we can simplify matters by placing the \textbf{assert} statement between
\textbf{while} and \textbf{loop} rather than directly after the \textbf{loop}.
In the former case, the loop invariant has to be proved only once, whereas in
the latter case, it has to be proved twice: since the \textbf{assert} occurs after
the check of the exit condition, the invariant has to be proved for the path
from the \textbf{assert} statement to the \textbf{assert} statement, and for
the path from the \textbf{assert} statement to the postcondition. In the case
of the \texttt{G\_C\_D} procedure, this might not seem particularly problematic,
since the proof of the invariant is very simple, but it can unnecessarily
complicate matters if the proof of the invariant is non-trivial. The simplified
program for computing the greatest common divisor, together with its correctness
proof, is shown in \figref{fig:simple-gcd-proof}. Since the package specification
has not changed, we only show the body of the packages. The two VCs can now be
proved by a single application of Isabelle's proof method @{text simp}.
*}

(*<*)
end
(*>*)

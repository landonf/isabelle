(*<*)
theory Example_Verification
imports "HOL-SPARK-Examples.Greatest_Common_Divisor" Simple_Greatest_Common_Divisor
begin
(*>*)

chapter \<open>Verifying an Example Program\<close>

text \<open>
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
which has been taken from the book about \SPARK{} by Barnes @{cite \<open>\S 11.6\<close> Barnes}.
\<close>

section \<open>Importing \SPARK{} VCs into Isabelle\<close>

text \<open>
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
fixes & \<open>m ::\<close>\ "\<open>int\<close>" \\
and   & \<open>n ::\<close>\ "\<open>int\<close>" \\
and   & \<open>c ::\<close>\ "\<open>int\<close>" \\
and   & \<open>d ::\<close>\ "\<open>int\<close>" \\
assumes & \<open>g_c_d_rules1:\<close>\ "\<open>0 \<le> integer__size\<close>" \\
and     & \<open>g_c_d_rules6:\<close>\ "\<open>0 \<le> natural__size\<close>" \\
\multicolumn{2}{l}{notes definition} \\
\multicolumn{2}{l}{\hspace{2ex}\<open>defns =\<close>\ `\<open>integer__first = - 2147483648\<close>`} \\
\multicolumn{2}{l}{\hspace{4ex}`\<open>integer__last = 2147483647\<close>`} \\
\multicolumn{2}{l}{\hspace{4ex}\dots}
\end{tabular}\ \\[1.5ex]
\ \\
Definitions: \\
\ \\
\begin{tabular}{ll}
\<open>g_c_d_rules2:\<close> & \<open>integer__first = - 2147483648\<close> \\
\<open>g_c_d_rules3:\<close> & \<open>integer__last = 2147483647\<close> \\
\dots
\end{tabular}\ \\[1.5ex]
\ \\
Verification conditions: \\
\ \\
path(s) from assertion of line 10 to assertion of line 10 \\
\ \\
\<open>procedure_g_c_d_4\<close>\ (unproved) \\
\ \ \begin{tabular}{ll}
assumes & \<open>H1:\<close>\ "\<open>0 \<le> c\<close>" \\
and     & \<open>H2:\<close>\ "\<open>0 < d\<close>" \\
and     & \<open>H3:\<close>\ "\<open>gcd c d = gcd m n\<close>" \\
\dots \\
shows & "\<open>0 < c - c sdiv d * d\<close>" \\
and   & "\<open>gcd d (c - c sdiv d * d) = gcd m n\<close>
\end{tabular}\ \\[1.5ex]
\ \\
path(s) from assertion of line 10 to finish \\
\ \\
\<open>procedure_g_c_d_11\<close>\ (unproved) \\
\ \ \begin{tabular}{ll}
assumes & \<open>H1:\<close>\ "\<open>0 \<le> c\<close>" \\
and     & \<open>H2:\<close>\ "\<open>0 < d\<close>" \\
and     & \<open>H3:\<close>\ "\<open>gcd c d = gcd m n\<close>" \\
\dots \\
shows & "\<open>d = gcd m n\<close>"
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
\<close>

section \<open>Proving the VCs\<close>

text \<open>
\label{sec:proving-vcs}
The two open VCs are \<open>procedure_g_c_d_4\<close> and \<open>procedure_g_c_d_11\<close>,
both of which contain the \<open>gcd\<close> proof function that the \SPARK{} Simplifier
does not know anything about. The proof of a particular VC can be started with
the \isa{\isacommand{spark\_vc}} command, which is similar to the standard
\isa{\isacommand{lemma}} and \isa{\isacommand{theorem}} commands, with the
difference that it only takes a name of a VC but no formula as an argument.
A VC can have several conclusions that can be referenced by the identifiers
\<open>?C1\<close>, \<open>?C2\<close>, etc. If there is just one conclusion, it can
also be referenced by \<open>?thesis\<close>. It is important to note that the
\texttt{div} operator of FDL behaves differently from the \<open>div\<close> operator
of Isabelle/HOL on negative numbers. The former always truncates towards zero,
whereas the latter truncates towards minus infinity. This is why the FDL
\texttt{div} operator is mapped to the \<open>sdiv\<close> operator in Isabelle/HOL,
which is defined as
@{thm [display] sdiv_def}
For example, we have that
@{lemma "-5 sdiv 4 = -1" by (simp add: sdiv_neg_pos)}, but
@{lemma "(-5::int) div 4 = -2" by simp}.
For non-negative dividend and divisor, \<open>sdiv\<close> is equivalent to \<open>div\<close>,
as witnessed by theorem \<open>sdiv_pos_pos\<close>:
@{thm [display,mode=no_brackets] sdiv_pos_pos}
In contrast, the behaviour of the FDL \texttt{mod} operator is equivalent to
the one of Isabelle/HOL. Moreover, since FDL has no counterpart of the \SPARK{}
operator \textbf{rem}, the \SPARK{} expression \texttt{c}\ \textbf{rem}\ \texttt{d}
just becomes \<open>c - c sdiv d * d\<close> in Isabelle. The first conclusion of
\<open>procedure_g_c_d_4\<close> requires us to prove that the remainder of \<open>c\<close>
and \<open>d\<close> is greater than \<open>0\<close>. To do this, we use the theorem
\<open>minus_div_mult_eq_mod [symmetric]\<close> describing the correspondence between \<open>div\<close>
and \<open>mod\<close>
@{thm [display] minus_div_mult_eq_mod [symmetric]}
together with the theorem \<open>pos_mod_sign\<close> saying that the result of the
\<open>mod\<close> operator is non-negative when applied to a non-negative divisor:
@{thm [display] pos_mod_sign}
We will also need the aforementioned theorem \<open>sdiv_pos_pos\<close> in order for
the standard Isabelle/HOL theorems about \<open>div\<close> to be applicable
to the VC, which is formulated using \<open>sdiv\<close> rather that \<open>div\<close>.
Note that the proof uses \texttt{`\<open>0 \<le> c\<close>`} and \texttt{`\<open>0 < d\<close>`}
rather than \<open>H1\<close> and \<open>H2\<close> to refer to the hypotheses of the current
VC. While the latter variant seems more compact, it is not particularly robust,
since the numbering of hypotheses can easily change if the corresponding
program is modified, making the proof script hard to adjust when there are many hypotheses.
Moreover, proof scripts using abbreviations like \<open>H1\<close> and \<open>H2\<close>
are hard to read without assistance from Isabelle.
The second conclusion of \<open>procedure_g_c_d_4\<close> requires us to prove that
the \<open>gcd\<close> of \<open>d\<close> and the remainder of \<open>c\<close> and \<open>d\<close>
is equal to the \<open>gcd\<close> of the original input values \<open>m\<close> and \<open>n\<close>,
which is the actual \emph{invariant} of the procedure. This is a consequence
of theorem \<open>gcd_non_0_int\<close>
@{thm [display] gcd_non_0_int}
Again, we also need theorems \<open>minus_div_mult_eq_mod [symmetric]\<close> and \<open>sdiv_pos_pos\<close>
to justify that \SPARK{}'s \textbf{rem} operator is equivalent to Isabelle's
\<open>mod\<close> operator for non-negative operands.
The VC \<open>procedure_g_c_d_11\<close> says that if the loop invariant holds before
the last iteration of the loop, the postcondition of the procedure will hold
after execution of the loop body. To prove this, we observe that the remainder
of \<open>c\<close> and \<open>d\<close>, and hence \<open>c mod d\<close> is \<open>0\<close> when exiting
the loop. This implies that \<open>gcd c d = d\<close>, since \<open>c\<close> is divisible
by \<open>d\<close>, so the conclusion follows using the assumption \<open>gcd c d = gcd m n\<close>.
This concludes the proofs of the open VCs, and hence the \SPARK{} verification
environment can be closed using the command \isa{\isacommand{spark\_end}}.
This command checks that all VCs have been proved and issues an error message
if there are remaining unproved VCs. Moreover, Isabelle checks that there is
no open \SPARK{} verification environment when the final \isa{\isacommand{end}}
command of a theory is encountered.
\<close>

section \<open>Optimizing the proof\<close>

text \<open>
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
\textbf{rem}, which spares us an application of theorems \<open>minus_div_mult_eq_mod [symmetric]\<close>
and \<open>sdiv_pos_pos\<close>. Finally, as noted by Barnes @{cite \<open>\S 11.5\<close> Barnes},
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
proved by a single application of Isabelle's proof method \<open>simp\<close>.
\<close>

(*<*)
end
(*>*)

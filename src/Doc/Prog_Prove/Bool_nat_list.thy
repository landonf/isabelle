(*<*)
theory Bool_nat_list
imports Complex_Main
begin
(*>*)

text\<open>
\vspace{-4ex}
\section{\texorpdfstring{Types \<^typ>\<open>bool\<close>, \<^typ>\<open>nat\<close> and \<open>list\<close>}{Types bool, nat and list}}

These are the most important predefined types. We go through them one by one.
Based on examples we learn how to define (possibly recursive) functions and
prove theorems about them by induction and simplification.

\subsection{Type \indexed{\<^typ>\<open>bool\<close>}{bool}}

The type of boolean values is a predefined datatype
@{datatype[display] bool}
with the two values \indexed{\<^const>\<open>True\<close>}{True} and \indexed{\<^const>\<open>False\<close>}{False} and
with many predefined functions:  \<open>\<not>\<close>, \<open>\<and>\<close>, \<open>\<or>\<close>, \<open>\<longrightarrow>\<close>, etc. Here is how conjunction could be defined by pattern matching:
\<close>

fun conj :: "bool \<Rightarrow> bool \<Rightarrow> bool" where
"conj True True = True" |
"conj _ _ = False"

text\<open>Both the datatype and function definitions roughly follow the syntax
of functional programming languages.

\subsection{Type \indexed{\<^typ>\<open>nat\<close>}{nat}}

Natural numbers are another predefined datatype:
@{datatype[display] nat}\index{Suc@\<^const>\<open>Suc\<close>}
All values of type \<^typ>\<open>nat\<close> are generated by the constructors
\<open>0\<close> and \<^const>\<open>Suc\<close>. Thus the values of type \<^typ>\<open>nat\<close> are
\<open>0\<close>, \<^term>\<open>Suc 0\<close>, \<^term>\<open>Suc(Suc 0)\<close>, etc.
There are many predefined functions: \<open>+\<close>, \<open>*\<close>, \<open>\<le>\<close>, etc. Here is how you could define your own addition:
\<close>

fun add :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
"add 0 n = n" |
"add (Suc m) n = Suc(add m n)"

text\<open>And here is a proof of the fact that \<^prop>\<open>add m 0 = m\<close>:\<close>

lemma add_02: "add m 0 = m"
apply(induction m)
apply(auto)
done
(*<*)
lemma "add m 0 = m"
apply(induction m)
(*>*)
txt\<open>The \isacom{lemma} command starts the proof and gives the lemma
a name, \<open>add_02\<close>. Properties of recursively defined functions
need to be established by induction in most cases.
Command \isacom{apply}\<open>(induction m)\<close> instructs Isabelle to
start a proof by induction on \<open>m\<close>. In response, it will show the
following proof state\ifsem\footnote{See page \pageref{proof-state} for how to
display the proof state.}\fi:
@{subgoals[display,indent=0]}
The numbered lines are known as \emph{subgoals}.
The first subgoal is the base case, the second one the induction step.
The prefix \<open>\<And>m.\<close> is Isabelle's way of saying ``for an arbitrary but fixed \<open>m\<close>''. The \<open>\<Longrightarrow>\<close> separates assumptions from the conclusion.
The command \isacom{apply}\<open>(auto)\<close> instructs Isabelle to try
and prove all subgoals automatically, essentially by simplifying them.
Because both subgoals are easy, Isabelle can do it.
The base case \<^prop>\<open>add 0 0 = 0\<close> holds by definition of \<^const>\<open>add\<close>,
and the induction step is almost as simple:
\<open>add\<^latex>\<open>~\<close>(Suc m) 0 = Suc(add m 0) = Suc m\<close>
using first the definition of \<^const>\<open>add\<close> and then the induction hypothesis.
In summary, both subproofs rely on simplification with function definitions and
the induction hypothesis.
As a result of that final \isacom{done}, Isabelle associates the lemma
just proved with its name. You can now inspect the lemma with the command
\<close>

thm add_02

txt\<open>which displays @{thm[show_question_marks,display] add_02} The free
variable \<open>m\<close> has been replaced by the \concept{unknown}
\<open>?m\<close>. There is no logical difference between the two but there is an
operational one: unknowns can be instantiated, which is what you want after
some lemma has been proved.

Note that there is also a proof method \<open>induct\<close>, which behaves almost
like \<open>induction\<close>; the difference is explained in \autoref{ch:Isar}.

\begin{warn}
Terminology: We use \concept{lemma}, \concept{theorem} and \concept{rule}
interchangeably for propositions that have been proved.
\end{warn}
\begin{warn}
  Numerals (\<open>0\<close>, \<open>1\<close>, \<open>2\<close>, \dots) and most of the standard
  arithmetic operations (\<open>+\<close>, \<open>-\<close>, \<open>*\<close>, \<open>\<le>\<close>,
  \<open><\<close>, etc.) are overloaded: they are available
  not just for natural numbers but for other types as well.
  For example, given the goal \<open>x + 0 = x\<close>, there is nothing to indicate
  that you are talking about natural numbers. Hence Isabelle can only infer
  that \<^term>\<open>x\<close> is of some arbitrary type where \<open>0\<close> and \<open>+\<close>
  exist. As a consequence, you will be unable to prove the goal.
%  To alert you to such pitfalls, Isabelle flags numerals without a
%  fixed type in its output: @ {prop"x+0 = x"}.
  In this particular example, you need to include
  an explicit type constraint, for example \<open>x+0 = (x::nat)\<close>. If there
  is enough contextual information this may not be necessary: \<^prop>\<open>Suc x =
  x\<close> automatically implies \<open>x::nat\<close> because \<^term>\<open>Suc\<close> is not
  overloaded.
\end{warn}

\subsubsection{An Informal Proof}

Above we gave some terse informal explanation of the proof of
\<^prop>\<open>add m 0 = m\<close>. A more detailed informal exposition of the lemma
might look like this:
\bigskip

\noindent
\textbf{Lemma} \<^prop>\<open>add m 0 = m\<close>

\noindent
\textbf{Proof} by induction on \<open>m\<close>.
\begin{itemize}
\item Case \<open>0\<close> (the base case): \<^prop>\<open>add 0 0 = 0\<close>
  holds by definition of \<^const>\<open>add\<close>.
\item Case \<^term>\<open>Suc m\<close> (the induction step):
  We assume \<^prop>\<open>add m 0 = m\<close>, the induction hypothesis (IH),
  and we need to show \<open>add (Suc m) 0 = Suc m\<close>.
  The proof is as follows:\smallskip

  \begin{tabular}{@ {}rcl@ {\quad}l@ {}}
  \<^term>\<open>add (Suc m) 0\<close> &\<open>=\<close>& \<^term>\<open>Suc(add m 0)\<close>
  & by definition of \<open>add\<close>\\
              &\<open>=\<close>& \<^term>\<open>Suc m\<close> & by IH
  \end{tabular}
\end{itemize}
Throughout this book, \concept{IH} will stand for ``induction hypothesis''.

We have now seen three proofs of \<^prop>\<open>add m 0 = 0\<close>: the Isabelle one, the
terse four lines explaining the base case and the induction step, and just now a
model of a traditional inductive proof. The three proofs differ in the level
of detail given and the intended reader: the Isabelle proof is for the
machine, the informal proofs are for humans. Although this book concentrates
on Isabelle proofs, it is important to be able to rephrase those proofs
as informal text comprehensible to a reader familiar with traditional
mathematical proofs. Later on we will introduce an Isabelle proof language
that is closer to traditional informal mathematical language and is often
directly readable.

\subsection{Type \indexed{\<open>list\<close>}{list}}

Although lists are already predefined, we define our own copy for
demonstration purposes:
\<close>
(*<*)
apply(auto)
done 
declare [[names_short]]
(*>*)
datatype 'a list = Nil | Cons 'a "'a list"
(*<*)
for map: map
(*>*)

text\<open>
\begin{itemize}
\item Type \<^typ>\<open>'a list\<close> is the type of lists over elements of type \<^typ>\<open>'a\<close>. Because \<^typ>\<open>'a\<close> is a type variable, lists are in fact \concept{polymorphic}: the elements of a list can be of arbitrary type (but must all be of the same type).
\item Lists have two constructors: \<^const>\<open>Nil\<close>, the empty list, and \<^const>\<open>Cons\<close>, which puts an element (of type \<^typ>\<open>'a\<close>) in front of a list (of type \<^typ>\<open>'a list\<close>).
Hence all lists are of the form \<^const>\<open>Nil\<close>, or \<^term>\<open>Cons x Nil\<close>,
or \<^term>\<open>Cons x (Cons y Nil)\<close>, etc.
\item \isacom{datatype} requires no quotation marks on the
left-hand side, but on the right-hand side each of the argument
types of a constructor needs to be enclosed in quotation marks, unless
it is just an identifier (e.g., \<^typ>\<open>nat\<close> or \<^typ>\<open>'a\<close>).
\end{itemize}
We also define two standard functions, append and reverse:\<close>

fun app :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list" where
"app Nil ys = ys" |
"app (Cons x xs) ys = Cons x (app xs ys)"

fun rev :: "'a list \<Rightarrow> 'a list" where
"rev Nil = Nil" |
"rev (Cons x xs) = app (rev xs) (Cons x Nil)"

text\<open>By default, variables \<open>xs\<close>, \<open>ys\<close> and \<open>zs\<close> are of
\<open>list\<close> type.

Command \indexed{\isacom{value}}{value} evaluates a term. For example,\<close>

value "rev(Cons True (Cons False Nil))"

text\<open>yields the result \<^value>\<open>rev(Cons True (Cons False Nil))\<close>. This works symbolically, too:\<close>

value "rev(Cons a (Cons b Nil))"

text\<open>yields \<^value>\<open>rev(Cons a (Cons b Nil))\<close>.
\medskip

Figure~\ref{fig:MyList} shows the theory created so far.
Because \<open>list\<close>, \<^const>\<open>Nil\<close>, \<^const>\<open>Cons\<close>, etc.\ are already predefined,
 Isabelle prints qualified (long) names when executing this theory, for example, \<open>MyList.Nil\<close>
 instead of \<^const>\<open>Nil\<close>.
 To suppress the qualified names you can insert the command
 \texttt{declare [[names\_short]]}.
 This is not recommended in general but is convenient for this unusual example.
% Notice where the
%quotations marks are needed that we mostly sweep under the carpet.  In
%particular, notice that \isacom{datatype} requires no quotation marks on the
%left-hand side, but that on the right-hand side each of the argument
%types of a constructor needs to be enclosed in quotation marks.

\begin{figure}[htbp]
\begin{alltt}
\input{MyList.thy}\end{alltt}
\caption{A theory of lists}
\label{fig:MyList}
\index{comment}
\end{figure}

\subsubsection{Structural Induction for Lists}

Just as for natural numbers, there is a proof principle of induction for
lists. Induction over a list is essentially induction over the length of
the list, although the length remains implicit. To prove that some property
\<open>P\<close> holds for all lists \<open>xs\<close>, i.e., \mbox{\<^prop>\<open>P(xs)\<close>},
you need to prove
\begin{enumerate}
\item the base case \<^prop>\<open>P(Nil)\<close> and
\item the inductive case \<^prop>\<open>P(Cons x xs)\<close> under the assumption \<^prop>\<open>P(xs)\<close>, for some arbitrary but fixed \<open>x\<close> and \<open>xs\<close>.
\end{enumerate}
This is often called \concept{structural induction} for lists.

\subsection{The Proof Process}

We will now demonstrate the typical proof process, which involves
the formulation and proof of auxiliary lemmas.
Our goal is to show that reversing a list twice produces the original
list.\<close>

theorem rev_rev [simp]: "rev(rev xs) = xs"

txt\<open>Commands \isacom{theorem} and \isacom{lemma} are
interchangeable and merely indicate the importance we attach to a
proposition. Via the bracketed attribute \<open>simp\<close> we also tell Isabelle
to make the eventual theorem a \conceptnoidx{simplification rule}: future proofs
involving simplification will replace occurrences of \<^term>\<open>rev(rev xs)\<close> by
\<^term>\<open>xs\<close>. The proof is by induction:\<close>

apply(induction xs)

txt\<open>
As explained above, we obtain two subgoals, namely the base case (\<^const>\<open>Nil\<close>) and the induction step (\<^const>\<open>Cons\<close>):
@{subgoals[display,indent=0,margin=65]}
Let us try to solve both goals automatically:
\<close>

apply(auto)

txt\<open>Subgoal~1 is proved, and disappears; the simplified version
of subgoal~2 becomes the new subgoal~1:
@{subgoals[display,indent=0,margin=70]}
In order to simplify this subgoal further, a lemma suggests itself.

\subsubsection{A First Lemma}

We insert the following lemma in front of the main theorem:
\<close>
(*<*)
oops
(*>*)
lemma rev_app [simp]: "rev(app xs ys) = app (rev ys) (rev xs)"

txt\<open>There are two variables that we could induct on: \<open>xs\<close> and
\<open>ys\<close>. Because \<^const>\<open>app\<close> is defined by recursion on
the first argument, \<open>xs\<close> is the correct one:
\<close>

apply(induction xs)

txt\<open>This time not even the base case is solved automatically:\<close>
apply(auto)
txt\<open>
\vspace{-5ex}
@{subgoals[display,goals_limit=1]}
Again, we need to abandon this proof attempt and prove another simple lemma
first.

\subsubsection{A Second Lemma}

We again try the canonical proof procedure:
\<close>
(*<*)
oops
(*>*)
lemma app_Nil2 [simp]: "app xs Nil = xs"
apply(induction xs)
apply(auto)
done

text\<open>
Thankfully, this worked.
Now we can continue with our stuck proof attempt of the first lemma:
\<close>

lemma rev_app [simp]: "rev(app xs ys) = app (rev ys) (rev xs)"
apply(induction xs)
apply(auto)

txt\<open>
We find that this time \<open>auto\<close> solves the base case, but the
induction step merely simplifies to
@{subgoals[display,indent=0,goals_limit=1]}
The missing lemma is associativity of \<^const>\<open>app\<close>,
which we insert in front of the failed lemma \<open>rev_app\<close>.

\subsubsection{Associativity of \<^const>\<open>app\<close>}

The canonical proof procedure succeeds without further ado:
\<close>
(*<*)oops(*>*)
lemma app_assoc [simp]: "app (app xs ys) zs = app xs (app ys zs)"
apply(induction xs)
apply(auto)
done
(*<*)
lemma rev_app [simp]: "rev(app xs ys) = app (rev ys)(rev xs)"
apply(induction xs)
apply(auto)
done

theorem rev_rev [simp]: "rev(rev xs) = xs"
apply(induction xs)
apply(auto)
done
(*>*)
text\<open>
Finally the proofs of @{thm[source] rev_app} and @{thm[source] rev_rev}
succeed, too.

\subsubsection{Another Informal Proof}

Here is the informal proof of associativity of \<^const>\<open>app\<close>
corresponding to the Isabelle proof above.
\bigskip

\noindent
\textbf{Lemma} \<^prop>\<open>app (app xs ys) zs = app xs (app ys zs)\<close>

\noindent
\textbf{Proof} by induction on \<open>xs\<close>.
\begin{itemize}
\item Case \<open>Nil\<close>: \ \<^prop>\<open>app (app Nil ys) zs = app ys zs\<close> \<open>=\<close>
  \mbox{\<^term>\<open>app Nil (app ys zs)\<close>} \ holds by definition of \<open>app\<close>.
\item Case \<open>Cons x xs\<close>: We assume
  \begin{center} \hfill \<^term>\<open>app (app xs ys) zs\<close> \<open>=\<close>
  \<^term>\<open>app xs (app ys zs)\<close> \hfill (IH) \end{center}
  and we need to show
  \begin{center} \<^prop>\<open>app (app (Cons x xs) ys) zs = app (Cons x xs) (app ys zs)\<close>.\end{center}
  The proof is as follows:\smallskip

  \begin{tabular}{@ {}l@ {\quad}l@ {}}
  \<^term>\<open>app (app (Cons x xs) ys) zs\<close>\\
  \<open>= app (Cons x (app xs ys)) zs\<close> & by definition of \<open>app\<close>\\
  \<open>= Cons x (app (app xs ys) zs)\<close> & by definition of \<open>app\<close>\\
  \<open>= Cons x (app xs (app ys zs))\<close> & by IH\\
  \<open>= app (Cons x xs) (app ys zs)\<close> & by definition of \<open>app\<close>
  \end{tabular}
\end{itemize}
\medskip

\noindent Didn't we say earlier that all proofs are by simplification? But
in both cases, going from left to right, the last equality step is not a
simplification at all! In the base case it is \<^prop>\<open>app ys zs = app Nil (app
ys zs)\<close>. It appears almost mysterious because we suddenly complicate the
term by appending \<open>Nil\<close> on the left. What is really going on is this:
when proving some equality \mbox{\<^prop>\<open>s = t\<close>}, both \<open>s\<close> and \<open>t\<close> are
simplified until they ``meet in the middle''. This heuristic for equality proofs
works well for a functional programming context like ours. In the base case
both \<^term>\<open>app (app Nil ys) zs\<close> and \<^term>\<open>app Nil (app
ys zs)\<close> are simplified to \<^term>\<open>app ys zs\<close>, the term in the middle.

\subsection{Predefined Lists}
\label{sec:predeflists}

Isabelle's predefined lists are the same as the ones above, but with
more syntactic sugar:
\begin{itemize}
\item \<open>[]\<close> is \indexed{\<^const>\<open>Nil\<close>}{Nil},
\item \<^term>\<open>x # xs\<close> is \<^term>\<open>Cons x xs\<close>\index{Cons@\<^const>\<open>Cons\<close>},
\item \<open>[x\<^sub>1, \<dots>, x\<^sub>n]\<close> is \<open>x\<^sub>1 # \<dots> # x\<^sub>n # []\<close>, and
\item \<^term>\<open>xs @ ys\<close> is \<^term>\<open>app xs ys\<close>.
\end{itemize}
There is also a large library of predefined functions.
The most important ones are the length function
\<open>length :: 'a list \<Rightarrow> nat\<close>\index{length@\<^const>\<open>length\<close>} (with the obvious definition),
and the \indexed{\<^const>\<open>map\<close>}{map} function that applies a function to all elements of a list:
\begin{isabelle}
\isacom{fun} \<^const>\<open>map\<close> \<open>::\<close> @{typ[source] "('a \<Rightarrow> 'b) \<Rightarrow> 'a list \<Rightarrow> 'b list"} \isacom{where}\\
\<open>"\<close>@{thm list.map(1) [of f]}\<open>" |\<close>\\
\<open>"\<close>@{thm list.map(2) [of f x xs]}\<open>"\<close>
\end{isabelle}

\ifsem
Also useful are the \concept{head} of a list, its first element,
and the \concept{tail}, the rest of the list:
\begin{isabelle}\index{hd@\<^const>\<open>hd\<close>}
\isacom{fun} \<open>hd :: 'a list \<Rightarrow> 'a\<close>\\
\<^prop>\<open>hd(x#xs) = x\<close>
\end{isabelle}
\begin{isabelle}\index{tl@\<^const>\<open>tl\<close>}
\isacom{fun} \<open>tl :: 'a list \<Rightarrow> 'a list\<close>\\
\<^prop>\<open>tl [] = []\<close> \<open>|\<close>\\
\<^prop>\<open>tl(x#xs) = xs\<close>
\end{isabelle}
Note that since HOL is a logic of total functions, \<^term>\<open>hd []\<close> is defined,
but we do not know what the result is. That is, \<^term>\<open>hd []\<close> is not undefined
but underdefined.
\fi
%

From now on lists are always the predefined lists.

\ifsem\else
\subsection{Types \<^typ>\<open>int\<close> and \<^typ>\<open>real\<close>}

In addition to \<^typ>\<open>nat\<close> there are also the types \<^typ>\<open>int\<close> and \<^typ>\<open>real\<close>, the mathematical integers
and real numbers. As mentioned above, numerals and most of the standard arithmetic operations are overloaded.
In particular they are defined on \<^typ>\<open>int\<close> and \<^typ>\<open>real\<close>.

\begin{warn}
There are two infix exponentiation operators:
\<^term>\<open>(^)\<close> for \<^typ>\<open>nat\<close> and \<^typ>\<open>int\<close> (with exponent of type \<^typ>\<open>nat\<close> in both cases)
and \<^term>\<open>(powr)\<close> for \<^typ>\<open>real\<close>.
\end{warn}
\begin{warn}
Type  \<^typ>\<open>int\<close> is already part of theory \<^theory>\<open>Main\<close>, but in order to use \<^typ>\<open>real\<close> as well, you have to import
theory \<^theory>\<open>Complex_Main\<close> instead of \<^theory>\<open>Main\<close>.
\end{warn}

There are three coercion functions that are inclusions and do not lose information:
\begin{quote}
\begin{tabular}{rcl}
\<^const>\<open>int\<close> &\<open>::\<close>& \<^typ>\<open>nat \<Rightarrow> int\<close>\\
\<^const>\<open>real\<close> &\<open>::\<close>& \<^typ>\<open>nat \<Rightarrow> real\<close>\\
\<^const>\<open>real_of_int\<close> &\<open>::\<close>& \<^typ>\<open>int \<Rightarrow> real\<close>\\
\end{tabular}
\end{quote}

Isabelle inserts these inclusions automatically once you import \<open>Complex_Main\<close>.
If there are multiple type-correct completions, Isabelle chooses an arbitrary one.
For example, the input \noquotes{@{term[source] "(i::int) + (n::nat)"}} has the unique
type-correct completion \<^term>\<open>(i::int) + int(n::nat)\<close>. In contrast,
\noquotes{@{term[source] "((n::nat) + n) :: real"}} has two type-correct completions,
\noquotes{@{term[source]"real(n+n)"}} and \noquotes{@{term[source]"real n + real n"}}.

There are also the coercion functions in the other direction:
\begin{quote}
\begin{tabular}{rcl}
\<^const>\<open>nat\<close> &\<open>::\<close>& \<^typ>\<open>int \<Rightarrow> nat\<close>\\
\<^const>\<open>floor\<close> &\<open>::\<close>& \<^typ>\<open>real \<Rightarrow> int\<close>\\
\<^const>\<open>ceiling\<close> &\<open>::\<close>& \<^typ>\<open>real \<Rightarrow> int\<close>\\
\end{tabular}
\end{quote}
\fi

\subsection*{Exercises}

\begin{exercise}
Use the \isacom{value} command to evaluate the following expressions:
@{term[source] "1 + (2::nat)"}, @{term[source] "1 + (2::int)"},
@{term[source] "1 - (2::nat)"} and @{term[source] "1 - (2::int)"}.
\end{exercise}

\begin{exercise}
Start from the definition of \<^const>\<open>add\<close> given above.
Prove that \<^const>\<open>add\<close> is associative and commutative.
Define a recursive function \<open>double\<close> \<open>::\<close> \<^typ>\<open>nat \<Rightarrow> nat\<close>
and prove \<^prop>\<open>double m = add m m\<close>.
\end{exercise}

\begin{exercise}
Define a function \<open>count ::\<close> \<^typ>\<open>'a \<Rightarrow> 'a list \<Rightarrow> nat\<close>
that counts the number of occurrences of an element in a list. Prove
\<^prop>\<open>count x xs \<le> length xs\<close>.
\end{exercise}

\begin{exercise}
Define a recursive function \<open>snoc ::\<close> \<^typ>\<open>'a list \<Rightarrow> 'a \<Rightarrow> 'a list\<close>
that appends an element to the end of a list. With the help of \<open>snoc\<close>
define a recursive function \<open>reverse ::\<close> \<^typ>\<open>'a list \<Rightarrow> 'a list\<close>
that reverses a list. Prove \<^prop>\<open>reverse(reverse xs) = xs\<close>.
\end{exercise}

\begin{exercise}
Define a recursive function \<open>sum_upto ::\<close> \<^typ>\<open>nat \<Rightarrow> nat\<close> such that
\mbox{\<open>sum_upto n\<close>} \<open>=\<close> \<open>0 + ... + n\<close> and prove
\<^prop>\<open> sum_upto (n::nat) = n * (n+1) div 2\<close>.
\end{exercise}
\<close>
(*<*)
end
(*>*)

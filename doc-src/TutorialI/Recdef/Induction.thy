(*<*)
theory Induction = examples + simplification:;
(*>*)

text{*
Assuming we have defined our function such that Isabelle could prove
termination and that the recursion equations (or some suitable derived
equations) are simplification rules, we might like to prove something about
our function. Since the function is recursive, the natural proof principle is
again induction. But this time the structural form of induction that comes
with datatypes is unlikely to work well---otherwise we could have defined the
function by \isacommand{primrec}. Therefore \isacommand{recdef} automatically
proves a suitable induction rule $f$\isa{.induct} that follows the
recursion pattern of the particular function $f$. We call this
\textbf{recursion induction}. Roughly speaking, it
requires you to prove for each \isacommand{recdef} equation that the property
you are trying to establish holds for the left-hand side provided it holds
for all recursive calls on the right-hand side. Here is a simple example
*}

lemma "map f (sep(x,xs)) = sep(f x, map f xs)";

txt{*\noindent
involving the predefined \isa{map} functional on lists: \isa{map f xs}
is the result of applying \isa{f} to all elements of \isa{xs}. We prove
this lemma by recursion induction w.r.t. \isa{sep}:
*}

apply(induct_tac x xs rule: sep.induct);

txt{*\noindent
The resulting proof state has three subgoals corresponding to the three
clauses for \isa{sep}:
\begin{isabellepar}%
~1.~{\isasymAnd}a.~map~f~(sep~(a,~[]))~=~sep~(f~a,~map~f~[])\isanewline
~2.~{\isasymAnd}a~x.~map~f~(sep~(a,~[x]))~=~sep~(f~a,~map~f~[x])\isanewline
~3.~{\isasymAnd}a~x~y~zs.\isanewline
~~~~~~~map~f~(sep~(a,~y~\#~zs))~=~sep~(f~a,~map~f~(y~\#~zs))~{\isasymLongrightarrow}\isanewline
~~~~~~~map~f~(sep~(a,~x~\#~y~\#~zs))~=~sep~(f~a,~map~f~(x~\#~y~\#~zs))%
\end{isabellepar}%
The rest is pure simplification:
*}

apply auto.;

text{*
Try proving the above lemma by structural induction, and you find that you
need an additional case distinction. What is worse, the names of variables
are invented by Isabelle and have nothing to do with the names in the
definition of \isa{sep}.

In general, the format of invoking recursion induction is
\begin{ttbox}
apply(induct_tac \(x@1 \dots x@n\) rule: \(f\).induct)
\end{ttbox}\index{*induct_tac}%
where $x@1~\dots~x@n$ is a list of free variables in the subgoal and $f$ the
name of a function that takes an $n$-tuple. Usually the subgoal will
contain the term $f~x@1~\dots~x@n$ but this need not be the case. The
induction rules do not mention $f$ at all. For example \isa{sep.induct}
\begin{isabellepar}%
{\isasymlbrakk}~{\isasymAnd}a.~?P~a~[];\isanewline
~~{\isasymAnd}a~x.~?P~a~[x];\isanewline
~~{\isasymAnd}a~x~y~zs.~?P~a~(y~\#~zs)~{\isasymLongrightarrow}~?P~a~(x~\#~y~\#~zs){\isasymrbrakk}\isanewline
{\isasymLongrightarrow}~?P~?u~?v%
\end{isabellepar}%
merely says that in order to prove a property \isa{?P} of \isa{?u} and
\isa{?v} you need to prove it for the three cases where \isa{?v} is the
empty list, the singleton list, and the list with at least two elements
(in which case you may assume it holds for the tail of that list).
*}

(*<*)
end
(*>*)

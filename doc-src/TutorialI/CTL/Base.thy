(*<*)theory Base = Main:(*>*)

section{*A verified model checker*}

text{*
Model checking is a very popular technique for the verification of finite
state systems (implementations) w.r.t.\ temporal logic formulae
(specifications) \cite{Clark}. Its foundations are completely set theoretic
and this section shall develop them in HOL. This is done in two steps: first
we consider a very simple ``temporal'' logic called propositional dynamic
logic (PDL) which we then extend to the temporal logic CTL used in many real
model checkers. In each case we give both a traditional semantics (@{text \<Turnstile>}) and a
recursive function @{term mc} that maps a formula into the set of all states of
the system where the formula is valid. If the system has a finite number of
states, @{term mc} is directly executable, i.e.\ a model checker, albeit not a
very efficient one. The main proof obligation is to show that the semantics
and the model checker agree.

\underscoreon

Our models are \emph{transition systems}, i.e.\ sets of \emph{states} with
transitions between them, as shown in this simple example:
\begin{center}
\unitlength.5mm
\thicklines
\begin{picture}(100,60)
\put(50,50){\circle{20}}
\put(50,50){\makebox(0,0){$p,q$}}
\put(61,55){\makebox(0,0)[l]{$s_0$}}
\put(44,42){\vector(-1,-1){26}}
\put(16,18){\vector(1,1){26}}
\put(57,43){\vector(1,-1){26}}
\put(10,10){\circle{20}}
\put(10,10){\makebox(0,0){$q,r$}}
\put(-1,15){\makebox(0,0)[r]{$s_1$}}
\put(20,10){\vector(1,0){60}}
\put(90,10){\circle{20}}
\put(90,10){\makebox(0,0){$r$}}
\put(98, 5){\line(1,0){10}}
\put(108, 5){\line(0,1){10}}
\put(108,15){\vector(-1,0){10}}
\put(91,21){\makebox(0,0)[bl]{$s_2$}}
\end{picture}
\end{center}
Each state has a unique name or number ($s_0,s_1,s_2$), and in each
state certain \emph{atomic propositions} ($p,q,r$) are true.
The aim of temporal logic is to formalize statements such as ``there is no
transition sequence starting from $s_2$ leading to a state where $p$ or $q$
are true''.

Abstracting from this concrete example, we assume there is some type of
states
*}

typedecl state

text{*\noindent
which we merely declare rather than define because it is an implicit
parameter of our model.  Of course it would have been more generic to make
@{typ state} a type parameter of everything but fixing @{typ state} as above
reduces clutter.
Similarly we declare an arbitrary but fixed transition system, i.e.\
relation between states:
*}

consts M :: "(state \<times> state)set";

text{*\noindent
Again, we could have made @{term M} a parameter of everything.
Finally we introduce a type of atomic propositions
*}

typedecl atom

text{*\noindent
and a \emph{labelling function}
*}

consts L :: "state \<Rightarrow> atom set"

text{*\noindent
telling us which atomic propositions are true in each state.
*}

(*<*)end(*>*)

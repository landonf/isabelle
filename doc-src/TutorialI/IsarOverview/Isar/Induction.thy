(*<*)theory Induction = Main:(*>*)

section{*Case distinction and induction \label{sec:Induct}*}


subsection{*Case distinction*}

text{* We have already met the @{text cases} method for performing
binary case splits. Here is another example: *}
lemma "P \<or> \<not> P"
proof cases
  assume "P" thus ?thesis ..
next
  assume "\<not> P" thus ?thesis ..
qed
text{*\noindent Note that the two cases must come in this order.

This form is appropriate if @{term P} is textually small.  However, if
@{term P} is large, we don't want to repeat it. This can be avoided by
the following idiom *}

lemma "P \<or> \<not> P"
proof (cases "P")
  case True thus ?thesis ..
next
  case False thus ?thesis ..
qed
text{*\noindent which is simply a shorthand for the previous
proof. More precisely, the phrases \isakeyword{case}~@{prop
True}/@{prop False} abbreviate the corresponding assumptions @{prop P}
and @{prop"\<not>P"}. In contrast to the previous proof we can prove the cases
in arbitrary order.

The same game can be played with other datatypes, for example lists:
*}
(*<*)declare length_tl[simp del](*>*)
lemma "length(tl xs) = length xs - 1"
proof (cases xs)
  case Nil thus ?thesis by simp
next
  case Cons thus ?thesis by simp
qed
text{*\noindent Here \isakeyword{case}~@{text Nil} abbreviates
\isakeyword{assume}~@{prop"xs = []"} and \isakeyword{case}~@{text Cons}
abbreviates \isakeyword{fix}~@{text"? ??"}
\isakeyword{assume}~@{text"xs = ? # ??"} where @{text"?"} and @{text"??"}
stand for variable names that have been chosen by the system.
Therefore we cannot
refer to them (this would lead to obscure proofs) and have not even shown
them. Luckily, this proof is simple enough we do not need to refer to them.
However, sometimes one may have to. Hence Isar offers a simple scheme for
naming those variables: replace the anonymous @{text Cons} by, for example,
@{text"(Cons y ys)"}, which abbreviates \isakeyword{fix}~@{text"y ys"}
\isakeyword{assume}~@{text"xs = Cons y ys"}, i.e.\ @{prop"xs = y # ys"}. Here
is a (somewhat contrived) example: *}

lemma "length(tl xs) = length xs - 1"
proof (cases xs)
  case Nil thus ?thesis by simp
next
  case (Cons y ys)
  hence "length(tl xs) = length ys  \<and>  length xs = length ys + 1"
    by simp
  thus ?thesis by simp
qed


subsection{*Structural induction*}

text{* We start with a simple inductive proof where both cases are proved automatically: *}
lemma "2 * (\<Sum>i<n+1. i) = n*(n+1)"
by (induct n, simp_all)

text{*\noindent If we want to expose more of the structure of the
proof, we can use pattern matching to avoid having to repeat the goal
statement: *}
lemma "2 * (\<Sum>i<n+1. i) = n*(n+1)" (is "?P n")
proof (induct n)
  show "?P 0" by simp
next
  fix n assume "?P n"
  thus "?P(Suc n)" by simp
qed

text{* \noindent We could refine this further to show more of the equational
proof. Instead we explore the same avenue as for case distinctions:
introducing context via the \isakeyword{case} command: *}
lemma "2 * (\<Sum>i<n+1. i) = n*(n+1)"
proof (induct n)
  case 0 show ?case by simp
next
  case Suc thus ?case by simp
qed

text{* \noindent The implicitly defined @{text ?case} refers to the
corresponding case to be proved, i.e.\ @{text"?P 0"} in the first case and
@{text"?P(Suc n)"} in the second case. Context \isakeyword{case}~@{text 0} is
empty whereas \isakeyword{case}~@{text Suc} assumes @{text"?P n"}. Again we
have the same problem as with case distinctions: we cannot refer to an anonymous @{term n}
in the induction step because it has not been introduced via \isakeyword{fix}
(in contrast to the previous proof). The solution is the same as above:
replace @{term Suc} by @{text"(Suc i)"}: *}
lemma fixes n::nat shows "n < n*n + 1"
proof (induct n)
  case 0 show ?case by simp
next
  case (Suc i) thus "Suc i < Suc i * Suc i + 1" by simp
qed

text{* \noindent Of course we could again have written
\isakeyword{thus}~@{text ?case} instead of giving the term explicitly
but we wanted to use @{term i} somewhere. *}

subsection{*Induction formulae involving @{text"\<And>"} or @{text"\<Longrightarrow>"}*}

text{* Let us now consider the situation where the goal to be proved contains
@{text"\<And>"} or @{text"\<Longrightarrow>"}, say @{prop"\<And>x. P x \<Longrightarrow> Q x"} --- motivation and a
real example follow shortly.  This means that in each case of the induction,
@{text ?case} would be of the same form @{prop"\<And>x. P' x \<Longrightarrow> Q' x"}.  Thus the
first proof steps will be the canonical ones, fixing @{text x} and assuming
@{prop"P' x"}. To avoid this tedium, induction performs these steps
automatically: for example in case @{text"(Suc n)"}, @{text ?case} is only
@{prop"Q' x"} whereas the assumptions (named @{term Suc}) contain both the
usual induction hypothesis \emph{and} @{prop"P' x"}. To fix the name of the
bound variable @{term x} you may write @{text"(Suc n x)"}, thus abbreviating
\isakeyword{fix}~@{term x}.
It should be clear how this example generalizes to more complex formulae.

As a concrete example we will now prove complete induction via
structural induction: *}

lemma assumes A: "(\<And>n. (\<And>m. m < n \<Longrightarrow> P m) \<Longrightarrow> P n)"
  shows "P(n::nat)"
proof (rule A)
  show "\<And>m. m < n \<Longrightarrow> P m"
  proof (induct n)
    case 0 thus ?case by simp
  next
    case (Suc n m)    -- {*@{text"?m < n \<Longrightarrow> P ?m"}  and  @{prop"m < Suc n"}*}
    show ?case       -- {*@{term ?case}*}
    proof cases
      assume eq: "m = n"
      from Suc A have "P n" by blast
      with eq show "P m" by simp
    next
      assume "m \<noteq> n"
      with Suc have "m < n" by arith
      thus "P m" by(rule Suc)
    qed
  qed
qed
text{* \noindent Given the explanations above and the comments in
the proof text, the proof should be quite readable.

The statement of the lemma is interesting because it deviates from the style in
the Tutorial~\cite{LNCS2283}, which suggests to introduce @{text"\<forall>"} or
@{text"\<longrightarrow>"} into a theorem to strengthen it for induction. In structured Isar
proofs we can use @{text"\<And>"} and @{text"\<Longrightarrow>"} instead. This simplifies the
proof and means we do not have to convert between the two kinds of
connectives.
*}

subsection{*Rule induction*}

text{* We define our own version of reflexive transitive closure of a
relation *}
consts rtc :: "('a \<times> 'a)set \<Rightarrow> ('a \<times> 'a)set"   ("_*" [1000] 999)
inductive "r*"
intros
refl:  "(x,x) \<in> r*"
step:  "\<lbrakk> (x,y) \<in> r; (y,z) \<in> r* \<rbrakk> \<Longrightarrow> (x,z) \<in> r*"

text{* \noindent and prove that @{term"r*"} is indeed transitive: *}
lemma assumes A: "(x,y) \<in> r*" shows "(y,z) \<in> r* \<Longrightarrow> (x,z) \<in> r*"
using A
proof induct
  case refl thus ?case .
next
  case step thus ?case by(blast intro: rtc.step)
qed
text{*\noindent Rule induction is triggered by a fact $(x_1,\dots,x_n)
\in R$ piped into the proof, here \isakeyword{using}~@{text A}. The
proof itself follows the inductive definition very
closely: there is one case for each rule, and it has the same name as
the rule, analogous to structural induction.

However, this proof is rather terse. Here is a more readable version:
*}

lemma assumes A: "(x,y) \<in> r*" and B: "(y,z) \<in> r*"
  shows "(x,z) \<in> r*"
proof -
  from A B show ?thesis
  proof induct
    fix x assume "(x,z) \<in> r*"  -- {*@{text B}[@{text y} := @{text x}]*}
    thus "(x,z) \<in> r*" .
  next
    fix x' x y
    assume 1: "(x',x) \<in> r" and
           IH: "(y,z) \<in> r* \<Longrightarrow> (x,z) \<in> r*" and
           B:  "(y,z) \<in> r*"
    from 1 IH[OF B] show "(x',z) \<in> r*" by(rule rtc.step)
  qed
qed
text{*\noindent We start the proof with \isakeyword{from}~@{text"A
B"}. Only @{text A} is ``consumed'' by the induction step.
Since @{text B} is left over we don't just prove @{text
?thesis} but @{text"B \<Longrightarrow> ?thesis"}, just as in the previous proof. The
base case is trivial. In the assumptions for the induction step we can
see very clearly how things fit together and permit ourselves the
obvious forward step @{text"IH[OF B]"}. *}

subsection{*More induction*}

text{* We close the section by demonstrating how arbitrary induction rules
are applied. As a simple example we have chosen recursion induction, i.e.\
induction based on a recursive function definition. The example is an unusual
definition of rotation: *}

consts rot :: "'a list \<Rightarrow> 'a list"
recdef rot "measure length"
"rot [] = []"
"rot [x] = [x]"
"rot (x#y#zs) = y # rot(x#zs)"

text{* In the first proof we set up each case explicitly, merely using
pattern matching to abbreviate the statement: *}

lemma "length(rot xs) = length xs" (is "?P xs")
proof (induct xs rule: rot.induct)
  show "?P []" by simp
next
  fix x show "?P [x]" by simp
next
  fix x y zs assume "?P (x#zs)"
  thus "?P (x#y#zs)" by simp
qed
text{*\noindent
This proof skeleton works for arbitrary induction rules, not just
@{thm[source]rot.induct}.

In the following proof we rely on a default naming scheme for cases: they are
called 1, 2, etc, unless they have been named explicitly. The latter happens
only with datatypes and inductively defined sets, but not with recursive
functions. *}

lemma "xs \<noteq> [] \<Longrightarrow> rot xs = tl xs @ [hd xs]"
proof (induct xs rule: rot.induct)
  case 1 thus ?case by simp
next
  case 2 show ?case by simp
next
  case 3 thus ?case by simp
qed

text{*\noindent Why can case 2 get away with \isakeyword{show} instead of
\isakeyword{thus}?

Of course both proofs are so simple that they can be condensed to*}
(*<*)lemma "xs \<noteq> [] \<Longrightarrow> rot xs = tl xs @ [hd xs]"(*>*)
by (induct xs rule: rot.induct, simp_all)
(*<*)end(*>*)

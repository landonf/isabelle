(*  Title:      HOL/Isar_examples/Summation.thy
    ID:         $Id$
    Author:     Markus Wenzel
*)

header {* Summing natural numbers *};

theory Summation = Main:;

text_raw {*
 \footnote{This example is somewhat reminiscent of the
 \url{http://isabelle.in.tum.de/library/HOL/ex/NatSum.html}, which is
 discussed in \cite{isabelle-ref} in the context of permutative
 rewrite rules and ordered rewriting.}
*};

text {*
 Subsequently, we prove some summation laws of natural numbers
 (including odds, squares and cubes).  These examples demonstrate how
 plain natural deduction (including induction) may be combined with
 calculational proof.
*};


subsection {* A summation operator *};

text {*
  The binder operator $\idt{sum} :: (\idt{nat} \To \idt{nat}) \To
 \idt{nat} \To \idt{nat}$ formalizes summation from $0$ up to $k$
 (excluding the bound).
 \[
 \sum\limits_{i < k} f(i) = \idt{sum} \ap (\lam i f \ap i) \ap k
 \]
*};

consts
  sum   :: "[nat => nat, nat] => nat";

primrec
  "sum f 0 = 0"
  "sum f (Suc n) = f n + sum f n";

syntax
  "_SUM" :: "idt => nat => nat => nat"
    ("SUM _ < _. _" [0, 0, 10] 10);
translations
  "SUM i < k. b" == "sum (%i. b) k";


subsection {* Summation laws *};

text_raw {* \begin{comment} *};

(* FIXME binary arithmetic does not yet work here *)

syntax
  "3" :: nat  ("3")
  "4" :: nat  ("4")
  "6" :: nat  ("6");

translations
  "3" == "Suc 2"
  "4" == "Suc 3"
  "6" == "Suc (Suc 4)";

theorems [simp] = add_mult_distrib add_mult_distrib2 mult_ac;

text_raw {* \end{comment} *};

text {*
 The sum of natural numbers $0 + \cdots + n$ equals $n \times (n +
 1)/2$.  In order to avoid formal reasoning about division, we just
 show $2 \times \Sigma_{i < n} i = n \times (n + 1)$.
*};

theorem sum_of_naturals:
  "2 * (SUM i < n + 1. i) = n * (n + 1)"
  (is "?P n" is "?S n = _");
proof (induct n);
  show "?P 0"; by simp;

  fix n;
  have "?S (n + 1) = ?S n + 2 * (n + 1)"; by simp;
  also; assume "?S n = n * (n + 1)";
  also; have "... + 2 * (n + 1) = (n + 1) * (n + 2)"; by simp;
  finally; show "?P (Suc n)"; by simp;
qed;

text {*
 The above proof is a typical instance of mathematical induction.  The
 main statement is viewed as some $\var{P} \ap n$ that is split by the
 induction method into base case $\var{P} \ap 0$, and step case
 $\var{P} \ap n \Impl \var{P} \ap (\idt{Suc} \ap n)$ for any $n$.

 The step case is established by a short calculation in forward
 manner.  Starting from the left-hand side $\var{S} \ap (n + 1)$ of
 the thesis, the final result is achieved by basic transformations
 involving arithmetic reasoning (using the Simplifier).  The main
 point is where the induction hypothesis $\var{S} \ap n = n \times (n
 + 1)$ is introduced in order to replace a certain subterm.  So the
 ``transitivity'' rule involved here is actual \emph{substitution}.
 Also note how the occurrence of ``\dots'' in the subsequent step
 documents the position where the right-hand side of the hypotheses
 got filled in.

 \medskip A further notable point here is integration of calculations
 with plain natural deduction.  This works works quite well in Isar
 for two reasons.

 \begin{enumerate}

 \item Facts involved in \isakeyword{also}~/ \isakeyword{finally}
 calculational chains may be just anything.  There is nothing special
 about \isakeyword{have}, so the natural deduction element
 \isakeyword{assume} works just as well.

 \item There are two \emph{separate} primitives for building natural
 deduction contexts: \isakeyword{fix}~$x$ and \isakeyword{assume}~$A$.
 Thus it is possible to start reasoning with new ``arbitrary, but
 fixed'' elements before bringing in the actual assumptions.
 Occasionally, natural deduction is formalized with basic context
 elements of the form $x:A$; this would rule out mixing with
 calculations as done here.

 \end{enumerate}
*};

text {*
 \medskip We derive further summation laws for odds, squares, cubes as
 follows.  The basic technique of induction plus calculation is the
 same.
*};

theorem sum_of_odds:
  "(SUM i < n. 2 * i + 1) = n^2"
  (is "?P n" is "?S n = _");
proof (induct n);
  show "?P 0"; by simp;

  fix n;
  have "?S (n + 1) = ?S n + 2 * n + 1"; by simp;
  also; assume "?S n = n^2";
  also; have "... + 2 * n + 1 = (n + 1)^2"; by simp;
  finally; show "?P (Suc n)"; by simp;
qed;

theorem sum_of_squares:
  "6 * (SUM i < n + 1. i^2) = n * (n + 1) * (2 * n + 1)"
  (is "?P n" is "?S n = _");
proof (induct n);
  show "?P 0"; by simp;

  fix n;
  have "?S (n + 1) = ?S n + 6 * (n + 1)^2"; by simp;
  also; assume "?S n = n * (n + 1) * (2 * n + 1)";
  also; have "... + 6 * (n + 1)^2 =
    (n + 1) * (n + 2) * (2 * (n + 1) + 1)"; by simp;
  finally; show "?P (Suc n)"; by simp;
qed;

theorem sum_of_cubes:
  "4 * (SUM i < n + 1. i^3) = (n * (n + 1))^2"
  (is "?P n" is "?S n = _");
proof (induct n);
  show "?P 0"; by simp;

  fix n;
  have "?S (n + 1) = ?S n + 4 * (n + 1)^3"; by simp;
  also; assume "?S n = (n * (n + 1))^2";
  also; have "... + 4 * (n + 1)^3 = ((n + 1) * ((n + 1) + 1))^2";
    by simp;
  finally; show "?P (Suc n)"; by simp;
qed;

text {*
 Comparing these examples with the tactic script version
 \url{http://isabelle.in.tum.de/library/HOL/ex/NatSum.html}, we note
 an important difference how of induction vs.\ simplification is
 applied.  While \cite[\S10]{isabelle-ref} advises for these examples
 that ``induction should not be applied until the goal is in the
 simplest form'' this would be a very bad idea in our setting.

 Simplification normalizes all arithmetic expressions involved,
 producing huge intermediate goals.  Applying induction afterwards,
 the Isar document would then have to reflect the emerging
 configuration by appropriate the sub-proofs.  This would result in
 badly structured, low-level technical reasoning, without any good
 idea of the actual point.

 \medskip As a general rule of good proof style, automatic methods
 such as $\idt{simp}$ or $\idt{auto}$ should normally never used as
 initial proof methods, but only as terminal ones, solving certain
 goals completely.
*};

end;

(* $Id$ *)

theory Introduction
imports Pure
begin

chapter {* Introduction *}

section {* Overview *}

text {*
  The \emph{Isabelle} system essentially provides a generic
  infrastructure for building deductive systems (programmed in
  Standard ML), with a special focus on interactive theorem proving in
  higher-order logics.  In the olden days even end-users would refer
  to certain ML functions (goal commands, tactics, tacticals etc.) to
  pursue their everyday theorem proving tasks
  \cite{isabelle-intro,isabelle-ref}.
  
  In contrast \emph{Isar} provides an interpreted language environment
  of its own, which has been specifically tailored for the needs of
  theory and proof development.  Compared to raw ML, the Isabelle/Isar
  top-level provides a more robust and comfortable development
  platform, with proper support for theory development graphs,
  single-step transactions with unlimited undo, etc.  The
  Isabelle/Isar version of the \emph{Proof~General} user interface
  \cite{proofgeneral,Aspinall:TACAS:2000} provides an adequate
  front-end for interactive theory and proof development in this
  advanced theorem proving environment.

  \medskip Apart from the technical advances over bare-bones ML
  programming, the main purpose of the Isar language is to provide a
  conceptually different view on machine-checked proofs
  \cite{Wenzel:1999:TPHOL,Wenzel-PhD}.  ``Isar'' stands for
  ``Intelligible semi-automated reasoning''.  Drawing from both the
  traditions of informal mathematical proof texts and high-level
  programming languages, Isar offers a versatile environment for
  structured formal proof documents.  Thus properly written Isar
  proofs become accessible to a broader audience than unstructured
  tactic scripts (which typically only provide operational information
  for the machine).  Writing human-readable proof texts certainly
  requires some additional efforts by the writer to achieve a good
  presentation, both of formal and informal parts of the text.  On the
  other hand, human-readable formal texts gain some value in their own
  right, independently of the mechanic proof-checking process.

  Despite its grand design of structured proof texts, Isar is able to
  assimilate the old tactical style as an ``improper'' sub-language.
  This provides an easy upgrade path for existing tactic scripts, as
  well as additional means for interactive experimentation and
  debugging of structured proofs.  Isabelle/Isar supports a broad
  range of proof styles, both readable and unreadable ones.

  \medskip The Isabelle/Isar framework is generic and should work
  reasonably well for any Isabelle object-logic that conforms to the
  natural deduction view of the Isabelle/Pure framework.  Major
  Isabelle logics like HOL \cite{isabelle-HOL}, HOLCF
  \cite{MuellerNvOS99}, FOL \cite{isabelle-logics}, and ZF
  \cite{isabelle-ZF} have already been set up for end-users.
*}


section {* Quick start *}

subsection {* Terminal sessions *}

text {*
  The Isabelle \texttt{tty} tool provides a very interface for running
  the Isar interaction loop, with some support for command line
  editing.  For example:
\begin{ttbox}
isatool tty\medskip
{\out Welcome to Isabelle/HOL (Isabelle2008)}\medskip
theory Foo imports Main begin;
definition foo :: nat where "foo == 1";
lemma "0 < foo" by (simp add: foo_def);
end;
\end{ttbox}

  Any Isabelle/Isar command may be retracted by @{command "undo"}.
  See the Isabelle/Isar Quick Reference (\appref{ap:refcard}) for a
  comprehensive overview of available commands and other language
  elements.
*}


subsection {* Proof General *}

text {*
  Plain TTY-based interaction as above used to be quite feasible with
  traditional tactic based theorem proving, but developing Isar
  documents really demands some better user-interface support.  The
  Proof~General environment by David Aspinall
  \cite{proofgeneral,Aspinall:TACAS:2000} offers a generic Emacs
  interface for interactive theorem provers that organizes all the
  cut-and-paste and forward-backward walk through the text in a very
  neat way.  In Isabelle/Isar, the current position within a partial
  proof document is equally important than the actual proof state.
  Thus Proof~General provides the canonical working environment for
  Isabelle/Isar, both for getting acquainted (e.g.\ by replaying
  existing Isar documents) and for production work.
*}


subsubsection{* Proof~General as default Isabelle interface *}

text {*
  The Isabelle interface wrapper script provides an easy way to invoke
  Proof~General (including XEmacs or GNU Emacs).  The default
  configuration of Isabelle is smart enough to detect the
  Proof~General distribution in several canonical places (e.g.\
  @{verbatim "$ISABELLE_HOME/contrib/ProofGeneral"}).  Thus the
  capital @{verbatim Isabelle} executable would already refer to the
  @{verbatim "ProofGeneral/isar"} interface without further ado.  The
  Isabelle interface script provides several options; pass @{verbatim
  "-?"}  to see its usage.

  With the proper Isabelle interface setup, Isar documents may now be edited by
  visiting appropriate theory files, e.g.\ 
\begin{ttbox}
Isabelle \({\langle}isabellehome{\rangle}\)/src/HOL/Isar_examples/Summation.thy
\end{ttbox}
  Beginners may note the tool bar for navigating forward and backward
  through the text (this depends on the local Emacs installation).
  Consult the Proof~General documentation \cite{proofgeneral} for
  further basic command sequences, in particular ``@{verbatim "C-c C-return"}''
  and ``@{verbatim "C-c u"}''.

  \medskip Proof~General may be also configured manually by giving
  Isabelle settings like this (see also \cite{isabelle-sys}):

\begin{ttbox}
ISABELLE_INTERFACE=\$ISABELLE_HOME/contrib/ProofGeneral/isar/interface
PROOFGENERAL_OPTIONS=""
\end{ttbox}
  You may have to change @{verbatim
  "$ISABELLE_HOME/contrib/ProofGeneral"} to the actual installation
  directory of Proof~General.

  \medskip Apart from the Isabelle command line, defaults for
  interface options may be given by the @{verbatim PROOFGENERAL_OPTIONS}
  setting.  For example, the Emacs executable to be used may be
  configured in Isabelle's settings like this:
\begin{ttbox}
PROOFGENERAL_OPTIONS="-p xemacs-mule"  
\end{ttbox}

  Occasionally, a user's @{verbatim "~/.emacs"} file contains code
  that is incompatible with the (X)Emacs version used by
  Proof~General, causing the interface startup to fail prematurely.
  Here the @{verbatim "-u false"} option helps to get the interface
  process up and running.  Note that additional Lisp customization
  code may reside in @{verbatim "proofgeneral-settings.el"} of
  @{verbatim "$ISABELLE_HOME/etc"} or @{verbatim
  "$ISABELLE_HOME_USER/etc"}.
*}


subsubsection {* The X-Symbol package *}

text {*
  Proof~General incorporates a version of the Emacs X-Symbol package
  \cite{x-symbol}, which handles proper mathematical symbols displayed
  on screen.  Pass option @{verbatim "-x true"} to the Isabelle
  interface script, or check the appropriate Proof~General menu
  setting by hand.  The main challenge of getting X-Symbol to work
  properly is the underlying (semi-automated) X11 font setup.

  \medskip Using proper mathematical symbols in Isabelle theories can
  be very convenient for readability of large formulas.  On the other
  hand, the plain ASCII sources easily become somewhat unintelligible.
  For example, @{text "\<Longrightarrow>"} would appear as @{verbatim "\<Longrightarrow>"} according
  the default set of Isabelle symbols.  Nevertheless, the Isabelle
  document preparation system (see \secref{sec:document-prep}) will be
  happy to print non-ASCII symbols properly.  It is even possible to
  invent additional notation beyond the display capabilities of Emacs
  and X-Symbol.
*}


section {* Isabelle/Isar theories *}

text {*
  Isabelle/Isar offers the following main improvements over classic
  Isabelle.

  \begin{enumerate}
  
  \item A \emph{theory format} that integrates specifications and
  proofs, supporting interactive development and unlimited undo
  operation.
  
  \item A \emph{formal proof document language} designed to support
  intelligible semi-automated reasoning.  Instead of putting together
  unreadable tactic scripts, the author is enabled to express the
  reasoning in way that is close to usual mathematical practice.  The
  old tactical style has been assimilated as ``improper'' language
  elements.
  
  \item A simple document preparation system, for typesetting formal
  developments together with informal text.  The resulting
  hyper-linked PDF documents are equally well suited for WWW
  presentation and as printed copies.

  \end{enumerate}

  The Isar proof language is embedded into the new theory format as a
  proper sub-language.  Proof mode is entered by stating some
  @{command "theorem"} or @{command "lemma"} at the theory level, and
  left again with the final conclusion (e.g.\ via @{command "qed"}).
  A few theory specification mechanisms also require some proof, such
  as HOL's @{command "typedef"} which demands non-emptiness of the
  representing sets.
*}


subsection {* Document preparation \label{sec:document-prep} *}

text {*
  Isabelle/Isar provides a simple document preparation system based on
  existing {PDF-\LaTeX} technology, with full support of hyper-links
  (both local references and URLs) and bookmarks.  Thus the results
  are equally well suited for WWW browsing and as printed copies.

  \medskip Isabelle generates {\LaTeX} output as part of the run of a
  \emph{logic session} (see also \cite{isabelle-sys}).  Getting
  started with a working configuration for common situations is quite
  easy by using the Isabelle @{verbatim mkdir} and @{verbatim make}
  tools.  First invoke
\begin{ttbox}
  isatool mkdir Foo
\end{ttbox}
  to initialize a separate directory for session @{verbatim Foo} ---
  it is safe to experiment, since @{verbatim "isatool mkdir"} never
  overwrites existing files.  Ensure that @{verbatim "Foo/ROOT.ML"}
  holds ML commands to load all theories required for this session;
  furthermore @{verbatim "Foo/document/root.tex"} should include any
  special {\LaTeX} macro packages required for your document (the
  default is usually sufficient as a start).

  The session is controlled by a separate @{verbatim IsaMakefile}
  (with crude source dependencies by default).  This file is located
  one level up from the @{verbatim Foo} directory location.  Now
  invoke
\begin{ttbox}
  isatool make Foo
\end{ttbox}
  to run the @{verbatim Foo} session, with browser information and
  document preparation enabled.  Unless any errors are reported by
  Isabelle or {\LaTeX}, the output will appear inside the directory
  @{verbatim ISABELLE_BROWSER_INFO}, as reported by the batch job in
  verbose mode.

  \medskip You may also consider to tune the @{verbatim usedir}
  options in @{verbatim IsaMakefile}, for example to change the output
  format from @{verbatim pdf} to @{verbatim dvi}, or activate the
  @{verbatim "-D"} option to retain a second copy of the generated
  {\LaTeX} sources.

  \medskip See \emph{The Isabelle System Manual} \cite{isabelle-sys}
  for further details on Isabelle logic sessions and theory
  presentation.  The Isabelle/HOL tutorial \cite{isabelle-hol-book}
  also covers theory presentation issues.
*}


subsection {* How to write Isar proofs anyway? \label{sec:isar-howto} *}

text {*
  This is one of the key questions, of course.  First of all, the
  tactic script emulation of Isabelle/Isar essentially provides a
  clarified version of the very same unstructured proof style of
  classic Isabelle.  Old-time users should quickly become acquainted
  with that (slightly degenerative) view of Isar.

  Writing \emph{proper} Isar proof texts targeted at human readers is
  quite different, though.  Experienced users of the unstructured
  style may even have to unlearn some of their habits to master proof
  composition in Isar.  In contrast, new users with less experience in
  old-style tactical proving, but a good understanding of mathematical
  proof in general, often get started easier.

  \medskip The present text really is only a reference manual on
  Isabelle/Isar, not a tutorial.  Nevertheless, we will attempt to
  give some clues of how the concepts introduced here may be put into
  practice.  Especially note that \appref{ap:refcard} provides a quick
  reference card of the most common Isabelle/Isar language elements.

  Further issues concerning the Isar concepts are covered in the
  literature
  \cite{Wenzel:1999:TPHOL,Wiedijk:2000:MV,Bauer-Wenzel:2000:HB,Bauer-Wenzel:2001}.
  The author's PhD thesis \cite{Wenzel-PhD} presently provides the
  most complete exposition of Isar foundations, techniques, and
  applications.  A number of example applications are distributed with
  Isabelle, and available via the Isabelle WWW library (e.g.\
  \url{http://isabelle.in.tum.de/library/}).  The ``Archive of Formal
  Proofs'' \url{http://afp.sourceforge.net/} also provides plenty of
  examples, both in proper Isar proof style and unstructured tactic
  scripts.
*}

end

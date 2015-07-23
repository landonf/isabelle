theory Adaptation
imports Setup
begin

setup %invisible \<open>Code_Target.add_derived_target ("\<SML>", [("SML", I)])
  #> Code_Target.add_derived_target ("\<SMLdummy>", [("Haskell", I)])\<close>

section \<open>Adaptation to target languages \label{sec:adaptation}\<close>

subsection \<open>Adapting code generation\<close>

text \<open>
  The aspects of code generation introduced so far have two aspects
  in common:

  \begin{itemize}

    \item They act uniformly, without reference to a specific target
       language.

    \item They are \emph{safe} in the sense that as long as you trust
       the code generator meta theory and implementation, you cannot
       produce programs that yield results which are not derivable in
       the logic.

  \end{itemize}

  \noindent In this section we will introduce means to \emph{adapt}
  the serialiser to a specific target language, i.e.~to print program
  fragments in a way which accommodates \qt{already existing}
  ingredients of a target language environment, for three reasons:

  \begin{itemize}
    \item improving readability and aesthetics of generated code
    \item gaining efficiency
    \item interface with language parts which have no direct counterpart
      in @{text "HOL"} (say, imperative data structures)
  \end{itemize}

  \noindent Generally, you should avoid using those features yourself
  \emph{at any cost}:

  \begin{itemize}

    \item The safe configuration methods act uniformly on every target
      language, whereas for adaptation you have to treat each target
      language separately.

    \item Application is extremely tedious since there is no
      abstraction which would allow for a static check, making it easy
      to produce garbage.

    \item Subtle errors can be introduced unconsciously.

  \end{itemize}

  \noindent However, even if you ought refrain from setting up
  adaptation yourself, already @{text "HOL"} comes with some
  reasonable default adaptations (say, using target language list
  syntax).  There also some common adaptation cases which you can
  setup by importing particular library theories.  In order to
  understand these, we provide some clues here; these however are not
  supposed to replace a careful study of the sources.
\<close>


subsection \<open>The adaptation principle\<close>

text \<open>
  Figure \ref{fig:adaptation} illustrates what \qt{adaptation} is
  conceptually supposed to be:

  \begin{figure}[h]
    \begin{tikzpicture}[scale = 0.5]
      \tikzstyle water=[color = blue, thick]
      \tikzstyle ice=[color = black, very thick, cap = round, join = round, fill = white]
      \tikzstyle process=[color = green, semithick, ->]
      \tikzstyle adaptation=[color = red, semithick, ->]
      \tikzstyle target=[color = black]
      \foreach \x in {0, ..., 24}
        \draw[style=water] (\x, 0.25) sin + (0.25, 0.25) cos + (0.25, -0.25) sin
          + (0.25, -0.25) cos + (0.25, 0.25);
      \draw[style=ice] (1, 0) --
        (3, 6) node[above, fill=white] {logic} -- (5, 0) -- cycle;
      \draw[style=ice] (9, 0) --
        (11, 6) node[above, fill=white] {intermediate language} -- (13, 0) -- cycle;
      \draw[style=ice] (15, -6) --
        (19, 6) node[above, fill=white] {target language} -- (23, -6) -- cycle;
      \draw[style=process]
        (3.5, 3) .. controls (7, 5) .. node[fill=white] {translation} (10.5, 3);
      \draw[style=process]
        (11.5, 3) .. controls (15, 5) .. node[fill=white] (serialisation) {serialisation} (18.5, 3);
      \node (adaptation) at (11, -2) [style=adaptation] {adaptation};
      \node at (19, 3) [rotate=90] {generated};
      \node at (19.5, -5) {language};
      \node at (19.5, -3) {library};
      \node (includes) at (19.5, -1) {includes};
      \node (reserved) at (16.5, -3) [rotate=72] {reserved}; % proper 71.57
      \draw[style=process]
        (includes) -- (serialisation);
      \draw[style=process]
        (reserved) -- (serialisation);
      \draw[style=adaptation]
        (adaptation) -- (serialisation);
      \draw[style=adaptation]
        (adaptation) -- (includes);
      \draw[style=adaptation]
        (adaptation) -- (reserved);
    \end{tikzpicture}
    \caption{The adaptation principle}
    \label{fig:adaptation}
  \end{figure}

  \noindent In the tame view, code generation acts as broker between
  @{text logic}, @{text "intermediate language"} and @{text "target
  language"} by means of @{text translation} and @{text
  serialisation}; for the latter, the serialiser has to observe the
  structure of the @{text language} itself plus some @{text reserved}
  keywords which have to be avoided for generated code.  However, if
  you consider @{text adaptation} mechanisms, the code generated by
  the serializer is just the tip of the iceberg:

  \begin{itemize}

    \item @{text serialisation} can be \emph{parametrised} such that
      logical entities are mapped to target-specific ones
      (e.g. target-specific list syntax, see also
      \secref{sec:adaptation_mechanisms})

    \item Such parametrisations can involve references to a
      target-specific standard @{text library} (e.g. using the @{text
      Haskell} @{verbatim Maybe} type instead of the @{text HOL}
      @{type "option"} type); if such are used, the corresponding
      identifiers (in our example, @{verbatim Maybe}, @{verbatim
      Nothing} and @{verbatim Just}) also have to be considered @{text
      reserved}.

    \item Even more, the user can enrich the library of the
      target-language by providing code snippets (\qt{@{text
      "includes"}}) which are prepended to any generated code (see
      \secref{sec:include}); this typically also involves further
      @{text reserved} identifiers.

  \end{itemize}

  \noindent As figure \ref{fig:adaptation} illustrates, all these
  adaptation mechanisms have to act consistently; it is at the
  discretion of the user to take care for this.
\<close>

subsection \<open>Common adaptation applications\<close>

text \<open>
  The @{theory HOL} @{theory Main} theory already provides a code
  generator setup which should be suitable for most applications.
  Common extensions and modifications are available by certain
  theories in @{file "~~/src/HOL/Library"}; beside being useful in
  applications, they may serve as a tutorial for customising the code
  generator setup (see below \secref{sec:adaptation_mechanisms}).

  \begin{description}

    \item[@{theory "Code_Numeral"}] provides additional numeric
       types @{typ integer} and @{typ natural} isomorphic to types
       @{typ int} and @{typ nat} respectively.  Type @{typ integer}
       is mapped to target-language built-in integers; @{typ natural}
       is implemented as abstract type over @{typ integer}.
       Useful for code setups which involve e.g.~indexing
       of target-language arrays.  Part of @{text "HOL-Main"}.

    \item[@{text "Code_Target_Int"}] implements type @{typ int}
       by @{typ integer} and thus by target-language built-in integers.

    \item[@{text "Code_Binary_Nat"}] implements type
       @{typ nat} using a binary rather than a linear representation,
       which yields a considerable speedup for computations.
       Pattern matching with @{term "0\<Colon>nat"} / @{const "Suc"} is eliminated
       by a preprocessor.\label{abstract_nat}

    \item[@{text "Code_Target_Nat"}] implements type @{typ nat}
       by @{typ integer} and thus by target-language built-in integers.
       Pattern matching with @{term "0\<Colon>nat"} / @{const "Suc"} is eliminated
       by a preprocessor.

    \item[@{text "Code_Target_Numeral"}] is a convenience theory
       containing both @{text "Code_Target_Nat"} and
       @{text "Code_Target_Int"}.

    \item[@{theory "String"}] provides an additional datatype @{typ
       String.literal} which is isomorphic to strings; @{typ
       String.literal}s are mapped to target-language strings.  Useful
       for code setups which involve e.g.~printing (error) messages.
       Part of @{text "HOL-Main"}.

    \item[@{text "Code_Char"}] represents @{text HOL} characters by
       character literals in target languages.  \emph{Warning:} This
       modifies adaptation in a non-conservative manner and thus
       should always be imported \emph{last} in a theory header.

    \item[@{theory "IArray"}] provides a type @{typ "'a iarray"}
       isomorphic to lists but implemented by (effectively immutable)
       arrays \emph{in SML only}.

  \end{description}
\<close>


subsection \<open>Parametrising serialisation \label{sec:adaptation_mechanisms}\<close>

text \<open>
  Consider the following function and its corresponding SML code:
\<close>

primrec %quote in_interval :: "nat \<times> nat \<Rightarrow> nat \<Rightarrow> bool" where
  "in_interval (k, l) n \<longleftrightarrow> k \<le> n \<and> n \<le> l"
(*<*)
code_printing %invisible
  type_constructor bool \<rightharpoonup> (SML)
| constant True \<rightharpoonup> (SML)
| constant False \<rightharpoonup> (SML)
| constant HOL.conj \<rightharpoonup> (SML)
| constant Not \<rightharpoonup> (SML)
(*>*)
text %quotetypewriter \<open>
  @{code_stmts in_interval (SML)}
\<close>

text \<open>
  \noindent Though this is correct code, it is a little bit
  unsatisfactory: boolean values and operators are materialised as
  distinguished entities with have nothing to do with the SML-built-in
  notion of \qt{bool}.  This results in less readable code;
  additionally, eager evaluation may cause programs to loop or break
  which would perfectly terminate when the existing SML @{verbatim
  "bool"} would be used.  To map the HOL @{typ bool} on SML @{verbatim
  "bool"}, we may use \qn{custom serialisations}:
\<close>

code_printing %quotett
  type_constructor bool \<rightharpoonup> (SML) "bool"
| constant True \<rightharpoonup> (SML) "true"
| constant False \<rightharpoonup> (SML) "false"
| constant HOL.conj \<rightharpoonup> (SML) "_ andalso _"

text \<open>
  \noindent The @{command_def code_printing} command takes a series
  of symbols (contants, type constructor, \ldots)
  together with target-specific custom serialisations.  Each
  custom serialisation starts with a target language identifier
  followed by an expression, which during code serialisation is
  inserted whenever the type constructor would occur.  Each
  ``@{verbatim "_"}'' in a serialisation expression is treated as a
  placeholder for the constant's or the type constructor's arguments.
\<close>

text %quotetypewriter \<open>
  @{code_stmts in_interval (SML)}
\<close>

text \<open>
  \noindent This still is not perfect: the parentheses around the
  \qt{andalso} expression are superfluous.  Though the serialiser by
  no means attempts to imitate the rich Isabelle syntax framework, it
  provides some common idioms, notably associative infixes with
  precedences which may be used here:
\<close>

code_printing %quotett
  constant HOL.conj \<rightharpoonup> (SML) infixl 1 "andalso"

text %quotetypewriter \<open>
  @{code_stmts in_interval (SML)}
\<close>

text \<open>
  \noindent The attentive reader may ask how we assert that no
  generated code will accidentally overwrite.  For this reason the
  serialiser has an internal table of identifiers which have to be
  avoided to be used for new declarations.  Initially, this table
  typically contains the keywords of the target language.  It can be
  extended manually, thus avoiding accidental overwrites, using the
  @{command_def "code_reserved"} command:
\<close>

code_reserved %quote "\<SMLdummy>" bool true false andalso

text \<open>
  \noindent Next, we try to map HOL pairs to SML pairs, using the
  infix ``@{verbatim "*"}'' type constructor and parentheses:
\<close>
(*<*)
code_printing %invisible
  type_constructor prod \<rightharpoonup> (SML)
| constant Pair \<rightharpoonup> (SML)
(*>*)
code_printing %quotett
  type_constructor prod \<rightharpoonup> (SML) infix 2 "*"
| constant Pair \<rightharpoonup> (SML) "!((_),/ (_))"

text \<open>
  \noindent The initial bang ``@{verbatim "!"}'' tells the serialiser
  never to put parentheses around the whole expression (they are
  already present), while the parentheses around argument place
  holders tell not to put parentheses around the arguments.  The slash
  ``@{verbatim "/"}'' (followed by arbitrary white space) inserts a
  space which may be used as a break if necessary during pretty
  printing.

  These examples give a glimpse what mechanisms custom serialisations
  provide; however their usage requires careful thinking in order not
  to introduce inconsistencies -- or, in other words: custom
  serialisations are completely axiomatic.

  A further noteworthy detail is that any special character in a
  custom serialisation may be quoted using ``@{verbatim "'"}''; thus,
  in ``@{verbatim "fn '_ => _"}'' the first ``@{verbatim "_"}'' is a
  proper underscore while the second ``@{verbatim "_"}'' is a
  placeholder.
\<close>


subsection \<open>@{text Haskell} serialisation\<close>

text \<open>
  For convenience, the default @{text HOL} setup for @{text Haskell}
  maps the @{class equal} class to its counterpart in @{text Haskell},
  giving custom serialisations for the class @{class equal}
  and its operation @{const [source] HOL.equal}.
\<close>

code_printing %quotett
  type_class equal \<rightharpoonup> (Haskell) "Eq"
| constant HOL.equal \<rightharpoonup> (Haskell) infixl 4 "=="

text \<open>
  \noindent A problem now occurs whenever a type which is an instance
  of @{class equal} in @{text HOL} is mapped on a @{text
  Haskell}-built-in type which is also an instance of @{text Haskell}
  @{text Eq}:
\<close>

typedecl %quote bar

instantiation %quote bar :: equal
begin

definition %quote "HOL.equal (x\<Colon>bar) y \<longleftrightarrow> x = y"

instance %quote by default (simp add: equal_bar_def)

end %quote (*<*)

(*>*) code_printing %quotett
  type_constructor bar \<rightharpoonup> (Haskell) "Integer"

text \<open>
  \noindent The code generator would produce an additional instance,
  which of course is rejected by the @{text Haskell} compiler.  To
  suppress this additional instance:
\<close>

code_printing %quotett
  class_instance bar :: "HOL.equal" \<rightharpoonup> (Haskell) -


subsection \<open>Enhancing the target language context \label{sec:include}\<close>

text \<open>
  In rare cases it is necessary to \emph{enrich} the context of a
  target language; this can also be accomplished using the @{command
  "code_printing"} command:
\<close>

code_printing %quotett
  code_module "Errno" \<rightharpoonup> (Haskell)
    \<open>errno i = error ("Error number: " ++ show i)\<close>

code_reserved %quotett Haskell Errno

text \<open>
  \noindent Such named modules are then prepended to every
  generated code.  Inspect such code in order to find out how
  this behaves with respect to a particular
  target language.
\<close>

end


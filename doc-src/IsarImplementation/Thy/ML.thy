
(* $Id$ *)

theory "ML" imports base begin

chapter {* Aesthetics of ML programming *}

text FIXME

text {* This style guide is loosely based on
  \url{http://caml.inria.fr/resources/doc/guides/guidelines.en.html}.
%  FIMXE \url{http://www.cs.cornell.edu/Courses/cs312/2003sp/handouts/style.htm}

  Like any style guide, it should not be interpreted dogmatically.
  Instead, it forms a collection of recommendations which,
  if obeyed, result in code that is not considered to be
  obfuscated.  In certain cases, derivations are encouraged,
  as far as you know what you are doing.

  \begin{description}

    \item[fundamental law of programming]
      Whenever writing code, keep in mind: A program is
      written once, modified ten times, and read
      100 times.  So simplify its writing,
      always keep future modifications in mind,
      and never jeopardize readability.  Every second you hesitate
      to spend on making your code more clear you will
      have to spend ten times understanding what you have
      written later on.

    \item[white space matters]
      Treat white space in your code as if it determines
      the meaning of code.

      \begin{itemize}

        \item The space bar is the easiest key to find on the keyboard,
          press it as often as necessary. {\ttfamily 2 + 2} is better
          than {\ttfamily 2+2}, likewise {\ttfamily f (x, y)}
          better than {\ttfamily f(x,y)}.

        \item Restrict your lines to \emph{at most} 80 characters.
          This will allow you to keep the beginning of a line
          in view while watching its end.

        \item Ban tabs; they are a context-sensitive formatting
          feature and likely to confuse anyone not using your
          favourite editor.

        \item Get rid of trailing whitespace.  Instead, do not
          surpess a trailing newline at the end of your files.

        \item Choose a generally accepted style of indentation,
          then use it systematically throughout the whole
          application.  An indentation of two spaces is appropriate.
          Avoid dangling indentation.

      \end{itemize}

    \item[cut-and-paste succeeds over copy-and-paste]
      \emph{Never} copy-and-paste code when programming.  If you
        need the same piece of code twice, introduce a
        reasonable auxiliary function (if there is no
        such function, very likely you got something wrong).
        Any copy-and-paste will turn out to be painful 
        when something has to be changed or fixed later on.

    \item[comments]
      are a device which requires careful thinking before using
      it.  The best comment for your code should be the code itself.
      Prefer efforts to write clear, understandable code
      over efforts to explain nasty code.

    \item[functional programming is based on functions]
      Avoid ``constructivisms'', e.g. pass a table lookup function,
      rather than an actual table with lookup in body.  Accustom
      your way of codeing to the level of expressiveness
      a functional programming language is giving onto you.

    \item[tuples]
      are often in the way.  When there is no striking argument
      to tuple function arguments, just write your function curried.

    \item[telling names]
      Any name should tell its purpose as exactly as possible,
      while keeping its length to the absolutely neccessary minimum.
      Always give the same name to function arguments which
      have the same meaning. Separate words by underscores
      (``@{verbatim int_of_string}'', not ``@{verbatim intOfString}'')

  \end{description}
*}


chapter {* Basic library functions *}

text {* FIXME beyond the NJ basis library proposal *}


chapter {* Cookbook *}

section {* A method that depends on declarations in the context *}

text FIXME

end

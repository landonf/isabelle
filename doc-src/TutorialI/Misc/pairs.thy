(*<*)
theory pairs = Main:;
(*>*)
text{*\label{sec:pairs}\indexbold{product type}
\index{pair|see{product type}}\index{tuple|see{product type}}
HOL also has pairs: \isa{($a@1$,$a@2$)} is of type $\tau@1$
\indexboldpos{\isasymtimes}{$Isatype} $\tau@2$ provided each $a@i$ is of type
$\tau@i$. The components of a pair are extracted by \isaindexbold{fst} and
\isaindexbold{snd}:
 \isa{fst($x$,$y$) = $x$} and \isa{snd($x$,$y$) = $y$}. Tuples
are simulated by pairs nested to the right: \isa{($a@1$,$a@2$,$a@3$)} stands
for \isa{($a@1$,($a@2$,$a@3$))} and $\tau@1 \times \tau@2 \times \tau@3$ for
$\tau@1 \times (\tau@2 \times \tau@3)$. Therefore we have
\isa{fst(snd($a@1$,$a@2$,$a@3$)) = $a@2$}.

There is also the type \isaindexbold{unit}, which contains exactly one
element denoted by \ttindexboldpos{()}{$Isatype}. This type can be viewed
as a degenerate Cartesian product of 0 types.

Note that products, like type @{typ nat}, are datatypes, which means
in particular that @{text induct_tac} and @{text case_tac} are applicable to
products (see \S\ref{sec:products}).

Instead of tuples with many components (where ``many'' is not much above 2),
it is far preferable to use records (see \S\ref{sec:records}).
*}
(*<*)
end
(*>*)

(*<*)
theory Fundata = Main:
(*>*)
datatype ('a,'i)bigtree = Tip | Br 'a "'i \<Rightarrow> ('a,'i)bigtree"

text{*\noindent
Parameter @{typ"'a"} is the type of values stored in
the @{term Br}anches of the tree, whereas @{typ"'i"} is the index
type over which the tree branches. If @{typ"'i"} is instantiated to
@{typ"bool"}, the result is a binary tree; if it is instantiated to
@{typ"nat"}, we have an infinitely branching tree because each node
has as many subtrees as there are natural numbers. How can we possibly
write down such a tree? Using functional notation! For example, the term
@{term[display]"Br 0 (%i. Br i (%n. Tip))"}
of type @{typ"(nat,nat)bigtree"} is the tree whose
root is labeled with 0 and whose $i$th subtree is labeled with $i$ and
has merely @{term"Tip"}s as further subtrees.

Function @{term"map_bt"} applies a function to all labels in a @{text"bigtree"}:
*}

consts map_bt :: "('a \<Rightarrow> 'b) \<Rightarrow> ('a,'i)bigtree \<Rightarrow> ('b,'i)bigtree"
primrec
"map_bt f Tip      = Tip"
"map_bt f (Br a F) = Br (f a) (\<lambda>i. map_bt f (F i))"

text{*\noindent This is a valid \isacommand{primrec} definition because the
recursive calls of @{term"map_bt"} involve only subtrees obtained from
@{term"F"}, i.e.\ the left-hand side. Thus termination is assured.  The
seasoned functional programmer might have written @{term"map_bt f o F"}
instead of @{term"%i. map_bt f (F i)"}, but the former is not accepted by
Isabelle because the termination proof is not as obvious since
@{term"map_bt"} is only partially applied.

The following lemma has a simple proof by induction:  *}

lemma "map_bt (g o f) T = map_bt g (map_bt f T)";
apply(induct_tac T, simp_all)
done
(*<*)lemma "map_bt (g o f) T = map_bt g (map_bt f T)";
apply(induct_tac T, rename_tac[2] F)(*>*)
txt{*\noindent
It is worth taking a look at the proof state after the induction step
to understand what the presence of the function type entails.
Notice the quantified induction hypothesis:
@{subgoals[display,indent=0]}
*}
(*<*)
oops
end
(*>*)

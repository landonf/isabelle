(*  Title:      HOL/wf.ML
    ID:         $Id$
    Author:     Tobias Nipkow
    Copyright   1992  University of Cambridge

Well-founded Recursion
*)

WF = Trancl +

constdefs
  wf         :: "('a * 'a)set => bool"
  "wf(r) == (!P. (!x. (!y. (y,x):r --> P(y)) --> P(x)) --> (!x.P(x)))"

  cut        :: "('a => 'b) => ('a * 'a)set => 'a => 'a => 'b"
  "cut f r x == (%y. if (y,x):r then f y else arbitrary)"

  is_recfun  :: "('a * 'a)set => (('a=>'b) => ('a=>'b)) =>'a=>('a=>'b) => bool"
  "is_recfun r H a f == (f = cut (%x. H (cut f r x) x) r a)"

  the_recfun :: "('a * 'a)set => (('a=>'b) => ('a=>'b)) => 'a => 'a => 'b"
  "the_recfun r H a  == (@f. is_recfun r H a f)"

  wfrec      :: "('a * 'a)set => (('a=>'b) => ('a=>'b)) => 'a => 'b"
  "wfrec r H == (%x. H (cut (the_recfun (trancl r) (%f v. H (cut f r v) v) x)
                            r x)  x)"

end

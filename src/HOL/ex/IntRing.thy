(*  Title:      HOL/Integ/IntRing.thy
    ID:         $Id$
    Author:     Tobias Nipkow and Markus Wenzel
    Copyright   1996 TU Muenchen

The integers form a commutative ring.
With an application of Lagrange's lemma.
*)

IntRing = Ring + Lagrange +

instance int :: add_semigroup (zadd_assoc)
instance int :: add_monoid (Zero_int_def,zadd_int0,zadd_int0_right)
instance int :: add_group {|Auto_tac|}
instance int :: add_agroup (zadd_commute)
instance int :: ring (zmult_assoc,zadd_zmult_distrib2,zadd_zmult_distrib)
instance int :: cring (zmult_commute)

end

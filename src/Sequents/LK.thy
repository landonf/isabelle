(*  Title:      LK/LK
    ID:         $Id$
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1993  University of Cambridge

Axiom to express monotonicity (a variant of the deduction theorem).  Makes the
link between |- and ==>, needed for instance to prove imp_cong.

CANNOT be added to LK0.thy because modal logic is built upon it, and
various modal rules would become inconsistent.
*)

LK = LK0 +

rules

  monotonic  "($H |- P ==> $H |- Q) ==> $H, P |- Q"

end

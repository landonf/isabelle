(*  Title: 	HOLCF/lift1.thy
    ID:         $Id$
    Author: 	Franz Regensburger
    Copyright   1993  Technische Universitaet Muenchen


Lifting

*)

Lift1 = Cfun3 +

(* new type for lifting *)

types "u" 1

arities "u" :: (pcpo)term	

consts

  Rep_Lift	:: "('a)u => (void + 'a)"
  Abs_Lift	:: "(void + 'a) => ('a)u"

  Iup           :: "'a => ('a)u"
  UU_lift       :: "('a)u"
  Ilift         :: "('a->'b)=>('a)u => 'b"
  less_lift     :: "('a)u => ('a)u => bool"

rules

  (*faking a type definition... *)
  (* ('a)u is isomorphic to void + 'a  *)

  Rep_Lift_inverse	"Abs_Lift(Rep_Lift(p)) = p"	
  Abs_Lift_inverse	"Rep_Lift(Abs_Lift(p)) = p"

   (*defining the abstract constants*)

  UU_lift_def   "UU_lift == Abs_Lift(Inl(UU))"
  Iup_def       "Iup(x)  == Abs_Lift(Inr(x))"

  Ilift_def     "Ilift(f)(x)==\
\                sum_case  (Rep_Lift(x)) (%y.UU) (%z.f[z])"
 
  less_lift_def "less_lift(x1)(x2) == \
\          (sum_case (Rep_Lift(x1))\
\                    (% y1.True)\
\                    (% y2.sum_case (Rep_Lift(x2))\
\                                   (% z1.False)\
\                                   (% z2.y2<<z2)))"

end




(*  Title:      ZF/Integ/Int.thy
    ID:         $Id$
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1993  University of Cambridge

The integers as equivalence classes over nat*nat.
*)

Int = EquivClass + Arith +

constdefs
  intrel :: i
    "intrel == {p:(nat*nat)*(nat*nat).                 
                EX x1 y1 x2 y2. p=<<x1,y1>,<x2,y2>> & x1#+y2 = x2#+y1}"

  int :: i
    "int == (nat*nat)//intrel"  

  int_of :: i=>i (*coercion from nat to int*)    ("$# _" [80] 80)
    "$# m == intrel `` {<natify(m), 0>}"

  intify :: i=>i (*coercion from ANYTHING to int*) 
    "intify(m) == if m : int then m else $#0"

  raw_zminus :: i=>i
    "raw_zminus(z) == UN <x,y>: z. intrel``{<y,x>}"

  zminus :: i=>i                                 ("$~ _" [80] 80)
    "$~ z == raw_zminus (intify(z))"

  znegative   ::      i=>o
    "znegative(z) == EX x y. x<y & y:nat & <x,y>:z"
  
  zmagnitude  ::      i=>i
    "zmagnitude(z) ==
     THE m. m : nat & ((~ znegative(z) & z = $# m) |
		       (znegative(z) & $~ z = $# m))"

  raw_zmult   ::      [i,i]=>i
    (*Cannot use UN<x1,y2> here or in zadd because of the form of congruent2.
      Perhaps a "curried" or even polymorphic congruent predicate would be
      better.*)
     "raw_zmult(z1,z2) == 
       UN p1:z1. UN p2:z2.  split(%x1 y1. split(%x2 y2.        
                   intrel``{<x1#*x2 #+ y1#*y2, x1#*y2 #+ y1#*x2>}, p2), p1)"

  zmult       ::      [i,i]=>i      (infixl "$*" 70)
     "z1 $* z2 == raw_zmult (intify(z1),intify(z2))"

  raw_zadd    ::      [i,i]=>i
     "raw_zadd (z1, z2) == 
       UN z1:z1. UN z2:z2. let <x1,y1>=z1; <x2,y2>=z2                 
                           in intrel``{<x1#+x2, y1#+y2>}"

  zadd        ::      [i,i]=>i      (infixl "$+" 65)
     "z1 $+ z2 == raw_zadd (intify(z1),intify(z2))"

  zdiff        ::      [i,i]=>i      (infixl "$-" 65)
     "z1 $- z2 == z1 $+ zminus(z2)"

  zless        ::      [i,i]=>o      (infixl "$<" 50)
     "z1 $< z2 == znegative(z1 $- z2)"
  
(*div and mod await definitions!*)
consts
  "$'/"       ::      [i,i]=>i      (infixl 70) 

  "$'/'/"     ::      [i,i]=>i      (infixl 70)
    
end

(*  Title:      HOL/Power.thy
    ID:         $Id$
    Author:     Lawrence C Paulson, Cambridge University Computer Laboratory
    Copyright   1997  University of Cambridge

The (overloaded) exponentiation operator, ^ :: [nat,nat]=>nat
Also binomial coefficents
*)

Power = Divides + 
consts
  binomial :: "[nat,nat] => nat"      ("'(_ choose _')" [50,50])

primrec "op ^" nat
  "p ^ 0 = 1"
  "p ^ (Suc n) = (p::nat) * (p ^ n)"
  
primrec "binomial" nat
  binomial_0   "(0     choose k) = (if k = 0 then 1 else 0)"

  binomial_Suc "(Suc n choose k) =
                (if k = 0 then 1 else (n choose pred k) + (n choose k))"

end


(*  Title: 	ZF/AC/HH.thy
    ID:         $Id$
    Author: 	Krzysztof Gr`abczewski

The theory file for the proofs of
  AC17 ==> AC1
  AC1 ==> WO2
  AC15 ==> WO6
*)

HH = AC_Equiv + Hartog + WO_AC +

consts
 
  HH                      :: "[i, i, i] => i"

defs

  HH_def  "HH(f,x,a)  == transrec(a, %b r. (lam z:Pow(x).   
	                 if(f`z:Pow(z)-{0}, f`z, {x}))`(x - (UN c:b. r`c)))"

end


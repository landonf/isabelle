(*  Title:      ZF/Resid/Redex.thy
    ID:         $Id$
    Author:     Ole Rasmussen
    Copyright   1995  University of Cambridge
    Logic Image: ZF
*)

Redex = Main +
consts
  redexes     :: i

datatype
  "redexes" = Var ("n \\<in> nat")            
            | Fun ("t \\<in> redexes")
            | App ("b \\<in> bool" ,"f \\<in> redexes" , "a \\<in> redexes")


consts
  Ssub,Scomp,Sreg  :: i
  "<==","~"        :: [i,i]=>o (infixl 70)
  un               :: [i,i]=>i (infixl 70)
  union_aux        :: i=>i
  regular          :: i=>o
  
translations
  "a<==b"        == "<a,b>:Ssub"
  "a ~ b"        == "<a,b>:Scomp"
  "regular(a)"   == "a \\<in> Sreg"


primrec (*explicit lambda is required because both arguments of "un" vary*)
  "union_aux(Var(n)) =
     (\\<lambda>t \\<in> redexes. redexes_case(%j. Var(n), %x. 0, %b x y.0, t))"

  "union_aux(Fun(u)) =
     (\\<lambda>t \\<in> redexes. redexes_case(%j. 0, %y. Fun(union_aux(u)`y),
	 			  %b y z. 0, t))"

  "union_aux(App(b,f,a)) =
     (\\<lambda>t \\<in> redexes.
        redexes_case(%j. 0, %y. 0,
		     %c z u. App(b or c, union_aux(f)`z, union_aux(a)`u), t))"

defs
  union_def  "u un v == union_aux(u)`v"


inductive
  domains       "Ssub" <= "redexes*redexes"
  intrs
    Sub_Var     "n \\<in> nat ==> Var(n)<== Var(n)"
    Sub_Fun     "[|u<== v|]==> Fun(u)<== Fun(v)"
    Sub_App1    "[|u1<== v1; u2<== v2; b \\<in> bool|]==>   
                     App(0,u1,u2)<== App(b,v1,v2)"
    Sub_App2    "[|u1<== v1; u2<== v2|]==>   
                     App(1,u1,u2)<== App(1,v1,v2)"
  type_intrs    "redexes.intrs@bool_typechecks"

inductive
  domains       "Scomp" <= "redexes*redexes"
  intrs
    Comp_Var    "n \\<in> nat ==> Var(n) ~ Var(n)"
    Comp_Fun    "[|u ~ v|]==> Fun(u) ~ Fun(v)"
    Comp_App    "[|u1 ~ v1; u2 ~ v2; b1 \\<in> bool; b2 \\<in> bool|]==>   
                     App(b1,u1,u2) ~ App(b2,v1,v2)"
  type_intrs    "redexes.intrs@bool_typechecks"

inductive
  domains       "Sreg" <= "redexes"
  intrs
    Reg_Var     "n \\<in> nat ==> regular(Var(n))"
    Reg_Fun     "[|regular(u)|]==> regular(Fun(u))"
    Reg_App1    "[|regular(Fun(u)); regular(v) 
                     |]==>regular(App(1,Fun(u),v))"
    Reg_App2    "[|regular(u); regular(v) 
                     |]==>regular(App(0,u,v))"
  type_intrs    "redexes.intrs@bool_typechecks"


end


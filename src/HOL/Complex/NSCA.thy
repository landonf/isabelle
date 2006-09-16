(*  Title       : NSCA.thy
    Author      : Jacques D. Fleuriot
    Copyright   : 2001,2002 University of Edinburgh
*)

header{*Non-Standard Complex Analysis*}

theory NSCA
imports NSComplex
begin

definition

   CInfinitesimal  :: "hcomplex set"
   "CInfinitesimal = {x. \<forall>r \<in> Reals. 0 < r --> hcmod x < r}"

    capprox    :: "[hcomplex,hcomplex] => bool"  (infixl "@c=" 50)  
      --{*the ``infinitely close'' relation*}
      "x @c= y = ((x - y) \<in> CInfinitesimal)"     
  
   (* standard complex numbers reagarded as an embedded subset of NS complex *)
   SComplex  :: "hcomplex set"
   "SComplex = {x. \<exists>r. x = hcomplex_of_complex r}"

   CFinite :: "hcomplex set"
   "CFinite = {x. \<exists>r \<in> Reals. hcmod x < r}"

   CInfinite :: "hcomplex set"
   "CInfinite = {x. \<forall>r \<in> Reals. r < hcmod x}"

   stc :: "hcomplex => hcomplex"
    --{* standard part map*}
   "stc x = (SOME r. x \<in> CFinite & r:SComplex & r @c= x)"

   cmonad    :: "hcomplex => hcomplex set"
   "cmonad x = {y. x @c= y}"

   cgalaxy   :: "hcomplex => hcomplex set"
   "cgalaxy x = {y. (x - y) \<in> CFinite}"



subsection{*Closure Laws for SComplex, the Standard Complex Numbers*}

lemma SComplex_add: "[| x \<in> SComplex; y \<in> SComplex |] ==> x + y \<in> SComplex"
apply (simp add: SComplex_def, safe)
apply (rule_tac x = "r + ra" in exI, simp)
done

lemma SComplex_mult: "[| x \<in> SComplex; y \<in> SComplex |] ==> x * y \<in> SComplex"
apply (simp add: SComplex_def, safe)
apply (rule_tac x = "r * ra" in exI, simp)
done

lemma SComplex_inverse: "x \<in> SComplex ==> inverse x \<in> SComplex"
apply (simp add: SComplex_def)
apply (blast intro: star_of_inverse [symmetric])
done

lemma SComplex_divide: "[| x \<in> SComplex;  y \<in> SComplex |] ==> x/y \<in> SComplex"
by (simp add: SComplex_mult SComplex_inverse divide_inverse)

lemma SComplex_minus: "x \<in> SComplex ==> -x \<in> SComplex"
apply (simp add: SComplex_def)
apply (blast intro: star_of_minus [symmetric])
done

lemma SComplex_minus_iff [simp]: "(-x \<in> SComplex) = (x \<in> SComplex)"
apply auto
apply (erule_tac [2] SComplex_minus)
apply (drule SComplex_minus, auto)
done

lemma SComplex_diff: "[| x \<in> SComplex; y \<in> SComplex |] ==> x - y \<in> SComplex"
by (simp add: diff_minus SComplex_add) 

lemma SComplex_add_cancel:
     "[| x + y \<in> SComplex; y \<in> SComplex |] ==> x \<in> SComplex"
by (drule SComplex_diff, assumption, simp)

lemma SReal_hcmod_hcomplex_of_complex [simp]:
     "hcmod (hcomplex_of_complex r) \<in> Reals"
by (auto simp add: hcmod SReal_def star_of_def)

lemma SReal_hcmod_number_of [simp]: "hcmod (number_of w ::hcomplex) \<in> Reals"
apply (subst star_of_number_of [symmetric])
apply (rule SReal_hcmod_hcomplex_of_complex)
done

lemma SReal_hcmod_SComplex: "x \<in> SComplex ==> hcmod x \<in> Reals"
by (auto simp add: SComplex_def)

lemma SComplex_hcomplex_of_complex [simp]: "hcomplex_of_complex x \<in> SComplex"
by (simp add: SComplex_def)

lemma SComplex_number_of [simp]: "(number_of w ::hcomplex) \<in> SComplex"
apply (subst star_of_number_of [symmetric])
apply (rule SComplex_hcomplex_of_complex)
done

lemma SComplex_divide_number_of:
     "r \<in> SComplex ==> r/(number_of w::hcomplex) \<in> SComplex"
apply (simp only: divide_inverse)
apply (blast intro!: SComplex_number_of SComplex_mult SComplex_inverse)
done

lemma SComplex_UNIV_complex:
     "{x. hcomplex_of_complex x \<in> SComplex} = (UNIV::complex set)"
by (simp add: SComplex_def)

lemma SComplex_iff: "(x \<in> SComplex) = (\<exists>y. x = hcomplex_of_complex y)"
by (simp add: SComplex_def)

lemma hcomplex_of_complex_image:
     "hcomplex_of_complex `(UNIV::complex set) = SComplex"
by (auto simp add: SComplex_def)

lemma inv_hcomplex_of_complex_image: "inv hcomplex_of_complex `SComplex = UNIV"
apply (auto simp add: SComplex_def)
apply (rule inj_hcomplex_of_complex [THEN inv_f_f, THEN subst], blast)
done

lemma SComplex_hcomplex_of_complex_image: 
      "[| \<exists>x. x: P; P \<le> SComplex |] ==> \<exists>Q. P = hcomplex_of_complex ` Q"
apply (simp add: SComplex_def, blast)
done

lemma SComplex_SReal_dense:
     "[| x \<in> SComplex; y \<in> SComplex; hcmod x < hcmod y  
      |] ==> \<exists>r \<in> Reals. hcmod x< r & r < hcmod y"
apply (auto intro: SReal_dense simp add: SReal_hcmod_SComplex)
done

lemma SComplex_hcmod_SReal: 
      "z \<in> SComplex ==> hcmod z \<in> Reals"
by (auto simp add: SComplex_def SReal_def hcmod_def)

lemma SComplex_zero [simp]: "0 \<in> SComplex"
by (simp add: SComplex_def)

lemma SComplex_one [simp]: "1 \<in> SComplex"
by (simp add: SComplex_def)

(*
Goalw [SComplex_def,SReal_def] "hcmod z \<in> Reals ==> z \<in> SComplex"
by (res_inst_tac [("z","z")] eq_Abs_hcomplex 1);
by (auto_tac (claset(),simpset() addsimps [hcmod,hypreal_of_real_def,
    hcomplex_of_complex_def,cmod_def]));
*)


subsection{*The Finite Elements form a Subring*}

lemma CFinite_add: "[|x \<in> CFinite; y \<in> CFinite|] ==> (x+y) \<in> CFinite"
apply (simp add: CFinite_def)
apply (blast intro!: SReal_add hcmod_add_less)
done

lemma CFinite_mult: "[|x \<in> CFinite; y \<in> CFinite|] ==> x*y \<in> CFinite"
apply (simp add: CFinite_def)
apply (blast intro!: SReal_mult hcmod_mult_less)
done

lemma CFinite_minus_iff [simp]: "(-x \<in> CFinite) = (x \<in> CFinite)"
by (simp add: CFinite_def)

lemma SComplex_subset_CFinite [simp]: "SComplex \<le> CFinite"
apply (auto simp add: SComplex_def CFinite_def)
apply (rule_tac x = "1 + hcmod (hcomplex_of_complex r) " in bexI)
apply (auto intro: SReal_add)
done

lemma HFinite_hcmod_hcomplex_of_complex [simp]:
     "hcmod (hcomplex_of_complex r) \<in> HFinite"
by (auto intro!: SReal_subset_HFinite [THEN subsetD])

lemma CFinite_hcomplex_of_complex [simp]: "hcomplex_of_complex x \<in> CFinite"
by (auto intro!: SComplex_subset_CFinite [THEN subsetD])

lemma CFiniteD: "x \<in> CFinite ==> \<exists>t \<in> Reals. hcmod x < t"
by (simp add: CFinite_def)

lemma CFinite_hcmod_iff: "(x \<in> CFinite) = (hcmod x \<in> HFinite)"
by (simp add: CFinite_def HFinite_def)

lemma CFinite_number_of [simp]: "number_of w \<in> CFinite"
by (rule SComplex_number_of [THEN SComplex_subset_CFinite [THEN subsetD]])

lemma CFinite_bounded: "[|x \<in> CFinite; y \<le> hcmod x; 0 \<le> y |] ==> y: HFinite"
by (auto intro: HFinite_bounded simp add: CFinite_hcmod_iff)


subsection{*The Complex Infinitesimals form a Subring*}
	 
lemma CInfinitesimal_zero [iff]: "0 \<in> CInfinitesimal"
by (simp add: CInfinitesimal_def)

lemma hcomplex_sum_of_halves: "x/(2::hcomplex) + x/(2::hcomplex) = x"
by auto

lemma CInfinitesimal_hcmod_iff: 
   "(z \<in> CInfinitesimal) = (hcmod z \<in> Infinitesimal)"
by (simp add: CInfinitesimal_def Infinitesimal_def)

lemma one_not_CInfinitesimal [simp]: "1 \<notin> CInfinitesimal"
by (simp add: CInfinitesimal_hcmod_iff)

lemma CInfinitesimal_add:
     "[| x \<in> CInfinitesimal; y \<in> CInfinitesimal |] ==> (x+y) \<in> CInfinitesimal"
apply (auto simp add: CInfinitesimal_hcmod_iff)
apply (rule hrabs_le_Infinitesimal)
apply (rule_tac y = "hcmod y" in Infinitesimal_add, auto)
done

lemma CInfinitesimal_minus_iff [simp]:
     "(-x:CInfinitesimal) = (x:CInfinitesimal)"
by (simp add: CInfinitesimal_def)

lemma CInfinitesimal_diff:
     "[| x \<in> CInfinitesimal;  y \<in> CInfinitesimal |] ==> x-y \<in> CInfinitesimal"
by (simp add: diff_minus CInfinitesimal_add)

lemma CInfinitesimal_mult:
     "[| x \<in> CInfinitesimal; y \<in> CInfinitesimal |] ==> x * y \<in> CInfinitesimal"
by (auto intro: Infinitesimal_mult simp add: CInfinitesimal_hcmod_iff hcmod_mult)

lemma CInfinitesimal_CFinite_mult:
     "[| x \<in> CInfinitesimal; y \<in> CFinite |] ==> (x * y) \<in> CInfinitesimal"
by (auto intro: Infinitesimal_HFinite_mult simp add: CInfinitesimal_hcmod_iff CFinite_hcmod_iff hcmod_mult)

lemma CInfinitesimal_CFinite_mult2:
     "[| x \<in> CInfinitesimal; y \<in> CFinite |] ==> (y * x) \<in> CInfinitesimal"
by (auto dest: CInfinitesimal_CFinite_mult simp add: mult_commute)

lemma CInfinite_hcmod_iff: "(z \<in> CInfinite) = (hcmod z \<in> HInfinite)"
by (simp add: CInfinite_def HInfinite_def)

lemma CInfinite_inverse_CInfinitesimal:
     "x \<in> CInfinite ==> inverse x \<in> CInfinitesimal"
by (auto intro: HInfinite_inverse_Infinitesimal simp add: CInfinitesimal_hcmod_iff CInfinite_hcmod_iff hcmod_hcomplex_inverse)

lemma CInfinite_mult: "[|x \<in> CInfinite; y \<in> CInfinite|] ==> (x*y): CInfinite"
by (auto intro: HInfinite_mult simp add: CInfinite_hcmod_iff hcmod_mult)

lemma CInfinite_minus_iff [simp]: "(-x \<in> CInfinite) = (x \<in> CInfinite)"
by (simp add: CInfinite_def)

lemma CFinite_sum_squares:
     "[|a \<in> CFinite; b \<in> CFinite; c \<in> CFinite|]   
      ==> a*a + b*b + c*c \<in> CFinite"
by (auto intro: CFinite_mult CFinite_add)

lemma not_CInfinitesimal_not_zero: "x \<notin> CInfinitesimal ==> x \<noteq> 0"
by auto

lemma not_CInfinitesimal_not_zero2: "x \<in> CFinite - CInfinitesimal ==> x \<noteq> 0"
by auto

lemma CFinite_diff_CInfinitesimal_hcmod:
     "x \<in> CFinite - CInfinitesimal ==> hcmod x \<in> HFinite - Infinitesimal"
by (simp add: CFinite_hcmod_iff CInfinitesimal_hcmod_iff)

lemma hcmod_less_CInfinitesimal:
     "[| e \<in> CInfinitesimal; hcmod x < hcmod e |] ==> x \<in> CInfinitesimal"
by (auto intro: hrabs_less_Infinitesimal simp add: CInfinitesimal_hcmod_iff)

lemma hcmod_le_CInfinitesimal:
     "[| e \<in> CInfinitesimal; hcmod x \<le> hcmod e |] ==> x \<in> CInfinitesimal"
by (auto intro: hrabs_le_Infinitesimal simp add: CInfinitesimal_hcmod_iff)

lemma CInfinitesimal_interval:
     "[| e \<in> CInfinitesimal;  
          e' \<in> CInfinitesimal;  
          hcmod e' < hcmod x ; hcmod x < hcmod e  
       |] ==> x \<in> CInfinitesimal"
by (auto intro: Infinitesimal_interval simp add: CInfinitesimal_hcmod_iff)

lemma CInfinitesimal_interval2:
     "[| e \<in> CInfinitesimal;  
         e' \<in> CInfinitesimal;  
         hcmod e' \<le> hcmod x ; hcmod x \<le> hcmod e  
      |] ==> x \<in> CInfinitesimal"
by (auto intro: Infinitesimal_interval2 simp add: CInfinitesimal_hcmod_iff)

lemma not_CInfinitesimal_mult:
     "[| x \<notin> CInfinitesimal;  y \<notin> CInfinitesimal|] ==> (x*y) \<notin> CInfinitesimal"
apply (auto simp add: CInfinitesimal_hcmod_iff hcmod_mult)
apply (drule not_Infinitesimal_mult, auto)
done

lemma CInfinitesimal_mult_disj:
     "x*y \<in> CInfinitesimal ==> x \<in> CInfinitesimal | y \<in> CInfinitesimal"
by (auto dest: Infinitesimal_mult_disj simp add: CInfinitesimal_hcmod_iff hcmod_mult)

lemma CFinite_CInfinitesimal_diff_mult:
     "[| x \<in> CFinite - CInfinitesimal; y \<in> CFinite - CInfinitesimal |] 
      ==> x*y \<in> CFinite - CInfinitesimal"
by (blast dest: CFinite_mult not_CInfinitesimal_mult)

lemma CInfinitesimal_subset_CFinite: "CInfinitesimal \<le> CFinite"
by (auto intro: Infinitesimal_subset_HFinite [THEN subsetD]
         simp add: CInfinitesimal_hcmod_iff CFinite_hcmod_iff)

lemma CInfinitesimal_hcomplex_of_complex_mult:
     "x \<in> CInfinitesimal ==> x * hcomplex_of_complex r \<in> CInfinitesimal"
by (auto intro!: Infinitesimal_HFinite_mult simp add: CInfinitesimal_hcmod_iff hcmod_mult)

lemma CInfinitesimal_hcomplex_of_complex_mult2:
     "x \<in> CInfinitesimal ==> hcomplex_of_complex r * x \<in> CInfinitesimal"
by (auto intro!: Infinitesimal_HFinite_mult2 simp add: CInfinitesimal_hcmod_iff hcmod_mult)


subsection{*The ``Infinitely Close'' Relation*}

(*
Goalw [capprox_def,approx_def] "(z @c= w) = (hcmod z @= hcmod w)"
by (auto_tac (claset(),simpset() addsimps [CInfinitesimal_hcmod_iff]));
*)

lemma mem_cinfmal_iff: "x:CInfinitesimal = (x @c= 0)"
by (simp add: CInfinitesimal_hcmod_iff capprox_def)

lemma capprox_minus_iff: "(x @c= y) = (x + -y @c= 0)"
by (simp add: capprox_def diff_minus)

lemma capprox_minus_iff2: "(x @c= y) = (-y + x @c= 0)"
by (simp add: capprox_def diff_minus add_commute)

lemma capprox_refl [simp]: "x @c= x"
by (simp add: capprox_def)

lemma capprox_sym: "x @c= y ==> y @c= x"
by (simp add: capprox_def CInfinitesimal_def hcmod_diff_commute)

lemma capprox_trans: "[| x @c= y; y @c= z |] ==> x @c= z"
apply (simp add: capprox_def)
apply (drule CInfinitesimal_add, assumption)
apply (simp add: diff_minus)
done

lemma capprox_trans2: "[| r @c= x; s @c= x |] ==> r @c= s"
by (blast intro: capprox_sym capprox_trans)

lemma capprox_trans3: "[| x @c= r; x @c= s|] ==> r @c= s"
by (blast intro: capprox_sym capprox_trans)

lemma number_of_capprox_reorient [simp]:
     "(number_of w @c= x) = (x @c= number_of w)"
by (blast intro: capprox_sym)

lemma CInfinitesimal_capprox_minus: "(x-y \<in> CInfinitesimal) = (x @c= y)"
by (simp add: diff_minus capprox_minus_iff [symmetric] mem_cinfmal_iff)

lemma capprox_monad_iff: "(x @c= y) = (cmonad(x)=cmonad(y))"
by (auto simp add: cmonad_def dest: capprox_sym elim!: capprox_trans equalityCE)

lemma Infinitesimal_capprox:
     "[| x \<in> CInfinitesimal; y \<in> CInfinitesimal |] ==> x @c= y"
apply (simp add: mem_cinfmal_iff)
apply (blast intro: capprox_trans capprox_sym)
done

lemma capprox_add: "[| a @c= b; c @c= d |] ==> a+c @c= b+d"
apply (simp add: capprox_def diff_minus) 
apply (rule minus_add_distrib [THEN ssubst])
apply (rule add_assoc [THEN ssubst])
apply (rule_tac b1 = c in add_left_commute [THEN subst])
apply (rule add_assoc [THEN subst])
apply (blast intro: CInfinitesimal_add)
done

lemma capprox_minus: "a @c= b ==> -a @c= -b"
apply (rule capprox_minus_iff [THEN iffD2, THEN capprox_sym])
apply (drule capprox_minus_iff [THEN iffD1])
apply (simp add: add_commute)
done

lemma capprox_minus2: "-a @c= -b ==> a @c= b"
by (auto dest: capprox_minus)

lemma capprox_minus_cancel [simp]: "(-a @c= -b) = (a @c= b)"
by (blast intro: capprox_minus capprox_minus2)

lemma capprox_add_minus: "[| a @c= b; c @c= d |] ==> a + -c @c= b + -d"
by (blast intro!: capprox_add capprox_minus)

lemma capprox_mult1: 
      "[| a @c= b; c \<in> CFinite|] ==> a*c @c= b*c"
apply (simp add: capprox_def diff_minus)
apply (simp only: CInfinitesimal_CFinite_mult minus_mult_left left_distrib [symmetric])
done

lemma capprox_mult2: "[|a @c= b; c \<in> CFinite|] ==> c*a @c= c*b"
by (simp add: capprox_mult1 mult_commute)

lemma capprox_mult_subst:
     "[|u @c= v*x; x @c= y; v \<in> CFinite|] ==> u @c= v*y"
by (blast intro: capprox_mult2 capprox_trans)

lemma capprox_mult_subst2:
     "[| u @c= x*v; x @c= y; v \<in> CFinite |] ==> u @c= y*v"
by (blast intro: capprox_mult1 capprox_trans)

lemma capprox_mult_subst_SComplex:
     "[| u @c= x*hcomplex_of_complex v; x @c= y |] 
      ==> u @c= y*hcomplex_of_complex v"
by (auto intro: capprox_mult_subst2)

lemma capprox_eq_imp: "a = b ==> a @c= b"
by (simp add: capprox_def)

lemma CInfinitesimal_minus_capprox: "x \<in> CInfinitesimal ==> -x @c= x"
by (blast intro: CInfinitesimal_minus_iff [THEN iffD2] mem_cinfmal_iff [THEN iffD1] capprox_trans2)

lemma bex_CInfinitesimal_iff: "(\<exists>y \<in> CInfinitesimal. x - z = y) = (x @c= z)"
by (unfold capprox_def, blast)

lemma bex_CInfinitesimal_iff2: "(\<exists>y \<in> CInfinitesimal. x = z + y) = (x @c= z)"
by (simp add: bex_CInfinitesimal_iff [symmetric], force)

lemma CInfinitesimal_add_capprox:
     "[| y \<in> CInfinitesimal; x + y = z |] ==> x @c= z"
apply (rule bex_CInfinitesimal_iff [THEN iffD1])
apply (drule CInfinitesimal_minus_iff [THEN iffD2])
apply (simp add: eq_commute compare_rls)
done

lemma CInfinitesimal_add_capprox_self: "y \<in> CInfinitesimal ==> x @c= x + y"
apply (rule bex_CInfinitesimal_iff [THEN iffD1])
apply (drule CInfinitesimal_minus_iff [THEN iffD2])
apply (simp add: eq_commute compare_rls)
done

lemma CInfinitesimal_add_capprox_self2: "y \<in> CInfinitesimal ==> x @c= y + x"
by (auto dest: CInfinitesimal_add_capprox_self simp add: add_commute)

lemma CInfinitesimal_add_minus_capprox_self:
     "y \<in> CInfinitesimal ==> x @c= x + -y"
by (blast intro!: CInfinitesimal_add_capprox_self CInfinitesimal_minus_iff [THEN iffD2])

lemma CInfinitesimal_add_cancel:
     "[| y \<in> CInfinitesimal; x+y @c= z|] ==> x @c= z"
apply (drule_tac x = x in CInfinitesimal_add_capprox_self [THEN capprox_sym])
apply (erule capprox_trans3 [THEN capprox_sym], assumption)
done

lemma CInfinitesimal_add_right_cancel:
     "[| y \<in> CInfinitesimal; x @c= z + y|] ==> x @c= z"
apply (drule_tac x = z in CInfinitesimal_add_capprox_self2 [THEN capprox_sym])
apply (erule capprox_trans3 [THEN capprox_sym])
apply (simp add: add_commute)
apply (erule capprox_sym)
done

lemma capprox_add_left_cancel: "d + b  @c= d + c ==> b @c= c"
apply (drule capprox_minus_iff [THEN iffD1])
apply (simp add: minus_add_distrib capprox_minus_iff [symmetric] add_ac)
done

lemma capprox_add_right_cancel: "b + d @c= c + d ==> b @c= c"
apply (rule capprox_add_left_cancel)
apply (simp add: add_commute)
done

lemma capprox_add_mono1: "b @c= c ==> d + b @c= d + c"
apply (rule capprox_minus_iff [THEN iffD2])
apply (simp add: capprox_minus_iff [symmetric] add_ac)
done

lemma capprox_add_mono2: "b @c= c ==> b + a @c= c + a"
apply (simp (no_asm_simp) add: add_commute capprox_add_mono1)
done

lemma capprox_add_left_iff [iff]: "(a + b @c= a + c) = (b @c= c)"
by (fast elim: capprox_add_left_cancel capprox_add_mono1)

lemma capprox_add_right_iff [iff]: "(b + a @c= c + a) = (b @c= c)"
by (simp add: add_commute)

lemma capprox_CFinite: "[| x \<in> CFinite; x @c= y |] ==> y \<in> CFinite"
apply (drule bex_CInfinitesimal_iff2 [THEN iffD2], safe)
apply (drule CInfinitesimal_subset_CFinite [THEN subsetD, THEN CFinite_minus_iff [THEN iffD2]])
apply (drule CFinite_add)
apply (assumption, auto)
done

lemma capprox_hcomplex_of_complex_CFinite:
     "x @c= hcomplex_of_complex D ==> x \<in> CFinite"
by (rule capprox_sym [THEN [2] capprox_CFinite], auto)

lemma capprox_mult_CFinite:
     "[|a @c= b; c @c= d; b \<in> CFinite; d \<in> CFinite|] ==> a*c @c= b*d"
apply (rule capprox_trans)
apply (rule_tac [2] capprox_mult2)
apply (rule capprox_mult1)
prefer 2 apply (blast intro: capprox_CFinite capprox_sym, auto)
done

lemma capprox_mult_hcomplex_of_complex:
     "[|a @c= hcomplex_of_complex b; c @c= hcomplex_of_complex d |]  
      ==> a*c @c= hcomplex_of_complex b * hcomplex_of_complex d"
apply (blast intro!: capprox_mult_CFinite capprox_hcomplex_of_complex_CFinite CFinite_hcomplex_of_complex)
done

lemma capprox_SComplex_mult_cancel_zero:
     "[| a \<in> SComplex; a \<noteq> 0; a*x @c= 0 |] ==> x @c= 0"
apply (drule SComplex_inverse [THEN SComplex_subset_CFinite [THEN subsetD]])
apply (auto dest: capprox_mult2 simp add: mult_assoc [symmetric])
done

lemma capprox_mult_SComplex1: "[| a \<in> SComplex; x @c= 0 |] ==> x*a @c= 0"
by (auto dest: SComplex_subset_CFinite [THEN subsetD] capprox_mult1)

lemma capprox_mult_SComplex2: "[| a \<in> SComplex; x @c= 0 |] ==> a*x @c= 0"
by (auto dest: SComplex_subset_CFinite [THEN subsetD] capprox_mult2)

lemma capprox_mult_SComplex_zero_cancel_iff [simp]:
     "[|a \<in> SComplex; a \<noteq> 0 |] ==> (a*x @c= 0) = (x @c= 0)"
by (blast intro: capprox_SComplex_mult_cancel_zero capprox_mult_SComplex2)

lemma capprox_SComplex_mult_cancel:
     "[| a \<in> SComplex; a \<noteq> 0; a* w @c= a*z |] ==> w @c= z"
apply (drule SComplex_inverse [THEN SComplex_subset_CFinite [THEN subsetD]])
apply (auto dest: capprox_mult2 simp add: mult_assoc [symmetric])
done

lemma capprox_SComplex_mult_cancel_iff1 [simp]:
     "[| a \<in> SComplex; a \<noteq> 0|] ==> (a* w @c= a*z) = (w @c= z)"
by (auto intro!: capprox_mult2 SComplex_subset_CFinite [THEN subsetD]
            intro: capprox_SComplex_mult_cancel)

lemma capprox_hcmod_approx_zero: "(x @c= y) = (hcmod (y - x) @= 0)"
apply (rule capprox_minus_iff [THEN ssubst])
apply (simp add: capprox_def CInfinitesimal_hcmod_iff mem_infmal_iff diff_minus [symmetric] hcmod_diff_commute)
done

lemma capprox_approx_zero_iff: "(x @c= 0) = (hcmod x @= 0)"
by (simp add: capprox_hcmod_approx_zero)

lemma capprox_minus_zero_cancel_iff [simp]: "(-x @c= 0) = (x @c= 0)"
by (simp add: capprox_hcmod_approx_zero)

lemma Infinitesimal_hcmod_add_diff:
     "u @c= 0 ==> hcmod(x + u) - hcmod x \<in> Infinitesimal"
apply (rule_tac e = "hcmod u" and e' = "- hcmod u" in Infinitesimal_interval2)
apply (auto dest: capprox_approx_zero_iff [THEN iffD1]
             simp add: mem_infmal_iff [symmetric] diff_def)
apply (rule_tac c1 = "hcmod x" in add_le_cancel_left [THEN iffD1])
apply (auto simp add: diff_minus [symmetric])
done

lemma approx_hcmod_add_hcmod: "u @c= 0 ==> hcmod(x + u) @= hcmod x"
apply (rule approx_minus_iff [THEN iffD2])
apply (auto intro: Infinitesimal_hcmod_add_diff simp add: mem_infmal_iff [symmetric] diff_minus [symmetric])
done

lemma capprox_hcmod_approx: "x @c= y ==> hcmod x @= hcmod y"
by (auto intro: approx_hcmod_add_hcmod 
         dest!: bex_CInfinitesimal_iff2 [THEN iffD2]
         simp add: mem_cinfmal_iff)


subsection{*Zero is the Only Infinitesimal Complex Number*}

lemma CInfinitesimal_less_SComplex:
   "[| x \<in> SComplex; y \<in> CInfinitesimal; 0 < hcmod x |] ==> hcmod y < hcmod x"
by (auto intro!: Infinitesimal_less_SReal SComplex_hcmod_SReal simp add: CInfinitesimal_hcmod_iff)

lemma SComplex_Int_CInfinitesimal_zero: "SComplex Int CInfinitesimal = {0}"
apply (auto simp add: SComplex_def CInfinitesimal_hcmod_iff)
apply (cut_tac r = r in SReal_hcmod_hcomplex_of_complex)
apply (drule_tac A = Reals in IntI, assumption)
apply (subgoal_tac "hcmod (hcomplex_of_complex r) = 0")
apply simp
apply (simp add: SReal_Int_Infinitesimal_zero) 
done

lemma SComplex_CInfinitesimal_zero:
     "[| x \<in> SComplex; x \<in> CInfinitesimal|] ==> x = 0"
by (cut_tac SComplex_Int_CInfinitesimal_zero, blast)

lemma SComplex_CFinite_diff_CInfinitesimal:
     "[| x \<in> SComplex; x \<noteq> 0 |] ==> x \<in> CFinite - CInfinitesimal"
by (auto dest: SComplex_CInfinitesimal_zero SComplex_subset_CFinite [THEN subsetD])

lemma hcomplex_of_complex_CFinite_diff_CInfinitesimal:
     "hcomplex_of_complex x \<noteq> 0 
      ==> hcomplex_of_complex x \<in> CFinite - CInfinitesimal"
by (rule SComplex_CFinite_diff_CInfinitesimal, auto)

lemma hcomplex_of_complex_CInfinitesimal_iff_0 [iff]:
     "(hcomplex_of_complex x \<in> CInfinitesimal) = (x=0)"
apply (auto)
apply (rule ccontr)
apply (rule hcomplex_of_complex_CFinite_diff_CInfinitesimal [THEN DiffD2], auto)
done

lemma number_of_not_CInfinitesimal [simp]:
     "number_of w \<noteq> (0::hcomplex) ==> number_of w \<notin> CInfinitesimal"
by (fast dest: SComplex_number_of [THEN SComplex_CInfinitesimal_zero])

lemma capprox_SComplex_not_zero:
     "[| y \<in> SComplex; x @c= y; y\<noteq> 0 |] ==> x \<noteq> 0"
by (auto dest: SComplex_CInfinitesimal_zero capprox_sym [THEN mem_cinfmal_iff [THEN iffD2]])

lemma CFinite_diff_CInfinitesimal_capprox:
     "[| x @c= y; y \<in> CFinite - CInfinitesimal |]  
      ==> x \<in> CFinite - CInfinitesimal"
apply (auto intro: capprox_sym [THEN [2] capprox_CFinite] 
            simp add: mem_cinfmal_iff)
apply (drule capprox_trans3, assumption)
apply (blast dest: capprox_sym)
done

lemma CInfinitesimal_ratio:
     "[| y \<noteq> 0;  y \<in> CInfinitesimal;  x/y \<in> CFinite |] ==> x \<in> CInfinitesimal"
apply (drule CInfinitesimal_CFinite_mult2, assumption)
apply (simp add: divide_inverse mult_assoc)
done

lemma SComplex_capprox_iff:
     "[|x \<in> SComplex; y \<in> SComplex|] ==> (x @c= y) = (x = y)"
apply auto
apply (simp add: capprox_def)
apply (subgoal_tac "x-y = 0", simp) 
apply (rule SComplex_CInfinitesimal_zero)
apply (simp add: SComplex_diff, assumption)
done

lemma number_of_capprox_iff [simp]:
    "(number_of v @c= number_of w) = (number_of v = (number_of w :: hcomplex))"
by (rule SComplex_capprox_iff, auto)

lemma number_of_CInfinitesimal_iff [simp]:
     "(number_of w \<in> CInfinitesimal) = (number_of w = (0::hcomplex))"
apply (rule iffI)
apply (fast dest: SComplex_number_of [THEN SComplex_CInfinitesimal_zero])
apply (simp (no_asm_simp))
done

lemma hcomplex_of_complex_approx_iff [simp]:
     "(hcomplex_of_complex k @c= hcomplex_of_complex m) = (k = m)"
apply auto
apply (rule inj_hcomplex_of_complex [THEN injD])
apply (rule SComplex_capprox_iff [THEN iffD1], auto)
done

lemma hcomplex_of_complex_capprox_number_of_iff [simp]:
     "(hcomplex_of_complex k @c= number_of w) = (k = number_of w)"
by (subst hcomplex_of_complex_approx_iff [symmetric], auto)

lemma capprox_unique_complex:
     "[| r \<in> SComplex; s \<in> SComplex; r @c= x; s @c= x|] ==> r = s"
by (blast intro: SComplex_capprox_iff [THEN iffD1] capprox_trans2)

lemma hcomplex_capproxD1:
     "star_n X @c= star_n Y
      ==> star_n (%n. Re(X n)) @= star_n (%n. Re(Y n))"
apply (simp add: approx_FreeUltrafilterNat_iff2, safe)
apply (drule capprox_minus_iff [THEN iffD1])
apply (simp add: star_n_minus star_n_add mem_cinfmal_iff [symmetric] CInfinitesimal_hcmod_iff hcmod Infinitesimal_FreeUltrafilterNat_iff2)
apply (drule_tac x = m in spec)
apply (erule ultra, rule FreeUltrafilterNat_all, clarify)
apply (rule_tac y="cmod (X n + - Y n)" in order_le_less_trans)
apply (case_tac "X n")
apply (case_tac "Y n")
apply (auto simp add: complex_minus complex_add complex_mod
            simp del: realpow_Suc)
done

(* same proof *)
lemma hcomplex_capproxD2:
     "star_n X @c= star_n Y
      ==> star_n (%n. Im(X n)) @= star_n (%n. Im(Y n))"
apply (simp add: approx_FreeUltrafilterNat_iff2, safe)
apply (drule capprox_minus_iff [THEN iffD1])
apply (simp add: star_n_minus star_n_add mem_cinfmal_iff [symmetric] CInfinitesimal_hcmod_iff hcmod Infinitesimal_FreeUltrafilterNat_iff2)
apply (drule_tac x = m in spec)
apply (erule ultra, rule FreeUltrafilterNat_all, clarify)
apply (rule_tac y="cmod (X n + - Y n)" in order_le_less_trans)
apply (case_tac "X n")
apply (case_tac "Y n")
apply (auto simp add: complex_minus complex_add complex_mod
            simp del: realpow_Suc)
done

lemma hcomplex_capproxI:
     "[| star_n (%n. Re(X n)) @= star_n (%n. Re(Y n));  
         star_n (%n. Im(X n)) @= star_n (%n. Im(Y n))  
      |] ==> star_n X @c= star_n Y"
apply (drule approx_minus_iff [THEN iffD1])
apply (drule approx_minus_iff [THEN iffD1])
apply (rule capprox_minus_iff [THEN iffD2])
apply (auto simp add: mem_cinfmal_iff [symmetric] mem_infmal_iff [symmetric] star_n_add star_n_minus CInfinitesimal_hcmod_iff hcmod Infinitesimal_FreeUltrafilterNat_iff)
apply (drule_tac x = "u/2" in spec)
apply (drule_tac x = "u/2" in spec, auto, ultra)
apply (case_tac "X x")
apply (case_tac "Y x")
apply (auto simp add: complex_minus complex_add complex_mod snd_conv fst_conv numeral_2_eq_2)
apply (rename_tac a b c d)
apply (subgoal_tac "sqrt (abs (a + - c) ^ 2 + abs (b + - d) ^ 2) < u")
apply (rule_tac [2] lemma_sqrt_hcomplex_capprox, auto)
apply (simp add: power2_eq_square)
done

lemma capprox_approx_iff:
     "(star_n X @c= star_n Y) = 
       (star_n (%n. Re(X n)) @= star_n (%n. Re(Y n)) &  
        star_n (%n. Im(X n)) @= star_n (%n. Im(Y n)))"
apply (blast intro: hcomplex_capproxI hcomplex_capproxD1 hcomplex_capproxD2)
done

lemma hcomplex_of_hypreal_capprox_iff [simp]:
     "(hcomplex_of_hypreal x @c= hcomplex_of_hypreal z) = (x @= z)"
apply (cases x, cases z)
apply (simp add: hcomplex_of_hypreal capprox_approx_iff)
done

lemma CFinite_HFinite_Re:
     "star_n X \<in> CFinite  
      ==> star_n (%n. Re(X n)) \<in> HFinite"
apply (auto simp add: CFinite_hcmod_iff hcmod HFinite_FreeUltrafilterNat_iff)
apply (rule_tac x = u in exI, ultra)
apply (case_tac "X x")
apply (auto simp add: complex_mod numeral_2_eq_2 simp del: realpow_Suc)
apply (rule ccontr, drule linorder_not_less [THEN iffD1])
apply (drule order_less_le_trans, assumption)
apply (drule real_sqrt_ge_abs1 [THEN [2] order_less_le_trans]) 
apply (auto simp add: numeral_2_eq_2 [symmetric]) 
done

lemma CFinite_HFinite_Im:
     "star_n X \<in> CFinite  
      ==> star_n (%n. Im(X n)) \<in> HFinite"
apply (auto simp add: CFinite_hcmod_iff hcmod HFinite_FreeUltrafilterNat_iff)
apply (rule_tac x = u in exI, ultra)
apply (case_tac "X x")
apply (auto simp add: complex_mod simp del: realpow_Suc)
apply (rule ccontr, drule linorder_not_less [THEN iffD1])
apply (drule order_less_le_trans, assumption)
apply (drule real_sqrt_ge_abs2 [THEN [2] order_less_le_trans], auto) 
done

lemma HFinite_Re_Im_CFinite:
     "[| star_n (%n. Re(X n)) \<in> HFinite;  
         star_n (%n. Im(X n)) \<in> HFinite  
      |] ==> star_n X \<in> CFinite"
apply (auto simp add: CFinite_hcmod_iff hcmod HFinite_FreeUltrafilterNat_iff)
apply (rename_tac u v)
apply (rule_tac x = "2* (u + v) " in exI)
apply ultra
apply (case_tac "X x")
apply (auto simp add: complex_mod numeral_2_eq_2 simp del: realpow_Suc)
apply (subgoal_tac "0 < u")
 prefer 2 apply arith
apply (subgoal_tac "0 < v")
 prefer 2 apply arith
apply (subgoal_tac "sqrt (abs (Re (X x)) ^ 2 + abs (Im (X x)) ^ 2) < 2*u + 2*v")
apply (rule_tac [2] lemma_sqrt_hcomplex_capprox, auto)
apply (simp add: power2_eq_square)
done

lemma CFinite_HFinite_iff:
     "(star_n X \<in> CFinite) =  
      (star_n (%n. Re(X n)) \<in> HFinite &  
       star_n (%n. Im(X n)) \<in> HFinite)"
by (blast intro: HFinite_Re_Im_CFinite CFinite_HFinite_Im CFinite_HFinite_Re)

lemma SComplex_Re_SReal:
     "star_n X \<in> SComplex  
      ==> star_n (%n. Re(X n)) \<in> Reals"
apply (auto simp add: SComplex_def SReal_def star_of_def star_n_eq_iff)
apply (rule_tac x = "Re r" in exI, ultra)
done

lemma SComplex_Im_SReal:
     "star_n X \<in> SComplex  
      ==> star_n (%n. Im(X n)) \<in> Reals"
apply (auto simp add: SComplex_def SReal_def star_of_def star_n_eq_iff)
apply (rule_tac x = "Im r" in exI, ultra)
done

lemma Reals_Re_Im_SComplex:
     "[| star_n (%n. Re(X n)) \<in> Reals;  
         star_n (%n. Im(X n)) \<in> Reals  
      |] ==> star_n X \<in> SComplex"
apply (auto simp add: SComplex_def SReal_def star_of_def star_n_eq_iff)
apply (rule_tac x = "Complex r ra" in exI, ultra)
done

lemma SComplex_SReal_iff:
     "(star_n X \<in> SComplex) =  
      (star_n (%n. Re(X n)) \<in> Reals &  
       star_n (%n. Im(X n)) \<in> Reals)"
by (blast intro: SComplex_Re_SReal SComplex_Im_SReal Reals_Re_Im_SComplex)

lemma CInfinitesimal_Infinitesimal_iff:
     "(star_n X \<in> CInfinitesimal) =  
      (star_n (%n. Re(X n)) \<in> Infinitesimal &  
       star_n (%n. Im(X n)) \<in> Infinitesimal)"
by (simp add: mem_cinfmal_iff mem_infmal_iff star_n_zero_num capprox_approx_iff)

lemma eq_Abs_star_EX:
     "(\<exists>t. P t) = (\<exists>X. P (star_n X))"
by (rule ex_star_eq)

lemma eq_Abs_star_Bex:
     "(\<exists>t \<in> A. P t) = (\<exists>X. star_n X \<in> A & P (star_n X))"
by (simp add: Bex_def ex_star_eq)

(* Here we go - easy proof now!! *)
lemma stc_part_Ex: "x:CFinite ==> \<exists>t \<in> SComplex. x @c= t"
apply (cases x)
apply (auto simp add: CFinite_HFinite_iff eq_Abs_star_Bex SComplex_SReal_iff capprox_approx_iff)
apply (drule st_part_Ex, safe)+
apply (rule_tac x = t in star_cases)
apply (rule_tac x = ta in star_cases, auto)
apply (rule_tac x = "%n. Complex (Xa n) (Xb n) " in exI)
apply auto
done

lemma stc_part_Ex1: "x:CFinite ==> EX! t. t \<in> SComplex &  x @c= t"
apply (drule stc_part_Ex, safe)
apply (drule_tac [2] capprox_sym, drule_tac [2] capprox_sym, drule_tac [2] capprox_sym)
apply (auto intro!: capprox_unique_complex)
done

lemma CFinite_Int_CInfinite_empty: "CFinite Int CInfinite = {}"
by (simp add: CFinite_def CInfinite_def, auto)

lemma CFinite_not_CInfinite: "x \<in> CFinite ==> x \<notin> CInfinite"
by (insert CFinite_Int_CInfinite_empty, blast)

text{*Not sure this is a good idea!*}
declare CFinite_Int_CInfinite_empty [simp]

lemma not_CFinite_CInfinite: "x\<notin> CFinite ==> x \<in> CInfinite"
by (auto intro: not_HFinite_HInfinite simp add: CFinite_hcmod_iff CInfinite_hcmod_iff)

lemma CInfinite_CFinite_disj: "x \<in> CInfinite | x \<in> CFinite"
by (blast intro: not_CFinite_CInfinite)

lemma CInfinite_CFinite_iff: "(x \<in> CInfinite) = (x \<notin> CFinite)"
by (blast dest: CFinite_not_CInfinite not_CFinite_CInfinite)

lemma CFinite_CInfinite_iff: "(x \<in> CFinite) = (x \<notin> CInfinite)"
by (simp add: CInfinite_CFinite_iff)

lemma CInfinite_diff_CFinite_CInfinitesimal_disj:
     "x \<notin> CInfinitesimal ==> x \<in> CInfinite | x \<in> CFinite - CInfinitesimal"
by (fast intro: not_CFinite_CInfinite)

lemma CFinite_inverse:
     "[| x \<in> CFinite; x \<notin> CInfinitesimal |] ==> inverse x \<in> CFinite"
apply (cut_tac x = "inverse x" in CInfinite_CFinite_disj)
apply (auto dest!: CInfinite_inverse_CInfinitesimal)
done

lemma CFinite_inverse2: "x \<in> CFinite - CInfinitesimal ==> inverse x \<in> CFinite"
by (blast intro: CFinite_inverse)

lemma CInfinitesimal_inverse_CFinite:
     "x \<notin> CInfinitesimal ==> inverse(x) \<in> CFinite"
apply (drule CInfinite_diff_CFinite_CInfinitesimal_disj)
apply (blast intro: CFinite_inverse CInfinite_inverse_CInfinitesimal CInfinitesimal_subset_CFinite [THEN subsetD])
done


lemma CFinite_not_CInfinitesimal_inverse:
     "x \<in> CFinite - CInfinitesimal ==> inverse x \<in> CFinite - CInfinitesimal"
apply (auto intro: CInfinitesimal_inverse_CFinite)
apply (drule CInfinitesimal_CFinite_mult2, assumption)
apply (simp add: not_CInfinitesimal_not_zero)
done

lemma capprox_inverse:
     "[| x @c= y; y \<in>  CFinite - CInfinitesimal |] ==> inverse x @c= inverse y"
apply (frule CFinite_diff_CInfinitesimal_capprox, assumption)
apply (frule not_CInfinitesimal_not_zero2)
apply (frule_tac x = x in not_CInfinitesimal_not_zero2)
apply (drule CFinite_inverse2)+
apply (drule capprox_mult2, assumption, auto)
apply (drule_tac c = "inverse x" in capprox_mult1, assumption)
apply (auto intro: capprox_sym simp add: mult_assoc)
done

lemmas hcomplex_of_complex_capprox_inverse =
  hcomplex_of_complex_CFinite_diff_CInfinitesimal [THEN [2] capprox_inverse]

lemma inverse_add_CInfinitesimal_capprox:
     "[| x \<in> CFinite - CInfinitesimal;  
         h \<in> CInfinitesimal |] ==> inverse(x + h) @c= inverse x"
by (auto intro: capprox_inverse capprox_sym CInfinitesimal_add_capprox_self)

lemma inverse_add_CInfinitesimal_capprox2:
     "[| x \<in> CFinite - CInfinitesimal;  
         h \<in> CInfinitesimal |] ==> inverse(h + x) @c= inverse x"
apply (rule add_commute [THEN subst])
apply (blast intro: inverse_add_CInfinitesimal_capprox)
done

lemma inverse_add_CInfinitesimal_approx_CInfinitesimal:
     "[| x \<in> CFinite - CInfinitesimal;  
         h \<in> CInfinitesimal |] ==> inverse(x + h) - inverse x @c= h"
apply (rule capprox_trans2)
apply (auto intro: inverse_add_CInfinitesimal_capprox 
       simp add: mem_cinfmal_iff diff_minus capprox_minus_iff [symmetric])
done

lemma CInfinitesimal_square_iff [iff]:
     "(x*x \<in> CInfinitesimal) = (x \<in> CInfinitesimal)"
by (simp add: CInfinitesimal_hcmod_iff hcmod_mult)

lemma capprox_CFinite_mult_cancel:
     "[| a \<in> CFinite-CInfinitesimal; a*w @c= a*z |] ==> w @c= z"
apply safe
apply (frule CFinite_inverse, assumption)
apply (drule not_CInfinitesimal_not_zero)
apply (auto dest: capprox_mult2 simp add: mult_assoc [symmetric])
done

lemma capprox_CFinite_mult_cancel_iff1:
     "a \<in> CFinite-CInfinitesimal ==> (a * w @c= a * z) = (w @c= z)"
by (auto intro: capprox_mult2 capprox_CFinite_mult_cancel)


subsection{*Theorems About Monads*}

lemma capprox_cmonad_iff: "(x @c= y) = (cmonad(x)=cmonad(y))"
apply (simp add: cmonad_def)
apply (auto dest: capprox_sym elim!: capprox_trans equalityCE)
done

lemma CInfinitesimal_cmonad_eq:
     "e \<in> CInfinitesimal ==> cmonad (x+e) = cmonad x"
by (fast intro!: CInfinitesimal_add_capprox_self [THEN capprox_sym] capprox_cmonad_iff [THEN iffD1])

lemma mem_cmonad_iff: "(u \<in> cmonad x) = (-u \<in> cmonad (-x))"
by (simp add: cmonad_def)

lemma CInfinitesimal_cmonad_zero_iff: "(x:CInfinitesimal) = (x \<in> cmonad 0)"
by (auto intro: capprox_sym simp add: mem_cinfmal_iff cmonad_def)

lemma cmonad_zero_minus_iff: "(x \<in> cmonad 0) = (-x \<in> cmonad 0)"
by (simp add: CInfinitesimal_cmonad_zero_iff [symmetric])

lemma cmonad_zero_hcmod_iff: "(x \<in> cmonad 0) = (hcmod x:monad 0)"
by (simp add: CInfinitesimal_cmonad_zero_iff [symmetric] CInfinitesimal_hcmod_iff Infinitesimal_monad_zero_iff [symmetric])

lemma mem_cmonad_self [simp]: "x \<in> cmonad x"
by (simp add: cmonad_def)


subsection{*Theorems About Standard Part*}

lemma stc_capprox_self: "x \<in> CFinite ==> stc x @c= x"
apply (simp add: stc_def)
apply (frule stc_part_Ex, safe)
apply (rule someI2)
apply (auto intro: capprox_sym)
done

lemma stc_SComplex: "x \<in> CFinite ==> stc x \<in> SComplex"
apply (simp add: stc_def)
apply (frule stc_part_Ex, safe)
apply (rule someI2)
apply (auto intro: capprox_sym)
done

lemma stc_CFinite: "x \<in> CFinite ==> stc x \<in> CFinite"
by (erule stc_SComplex [THEN SComplex_subset_CFinite [THEN subsetD]])

lemma stc_SComplex_eq [simp]: "x \<in> SComplex ==> stc x = x"
apply (simp add: stc_def)
apply (rule some_equality)
apply (auto intro: SComplex_subset_CFinite [THEN subsetD])
apply (blast dest: SComplex_capprox_iff [THEN iffD1])
done

lemma stc_hcomplex_of_complex:
     "stc (hcomplex_of_complex x) = hcomplex_of_complex x"
by auto

lemma stc_eq_capprox:
     "[| x \<in> CFinite; y \<in> CFinite; stc x = stc y |] ==> x @c= y"
by (auto dest!: stc_capprox_self elim!: capprox_trans3)

lemma capprox_stc_eq:
     "[| x \<in> CFinite; y \<in> CFinite; x @c= y |] ==> stc x = stc y"
by (blast intro: capprox_trans capprox_trans2 SComplex_capprox_iff [THEN iffD1]
          dest: stc_capprox_self stc_SComplex)

lemma stc_eq_capprox_iff:
     "[| x \<in> CFinite; y \<in> CFinite|] ==> (x @c= y) = (stc x = stc y)"
by (blast intro: capprox_stc_eq stc_eq_capprox)

lemma stc_CInfinitesimal_add_SComplex:
     "[| x \<in> SComplex; e \<in> CInfinitesimal |] ==> stc(x + e) = x"
apply (frule stc_SComplex_eq [THEN subst])
prefer 2 apply assumption
apply (frule SComplex_subset_CFinite [THEN subsetD])
apply (frule CInfinitesimal_subset_CFinite [THEN subsetD])
apply (drule stc_SComplex_eq)
apply (rule capprox_stc_eq)
apply (auto intro: CFinite_add simp add: CInfinitesimal_add_capprox_self [THEN capprox_sym])
done

lemma stc_CInfinitesimal_add_SComplex2:
     "[| x \<in> SComplex; e \<in> CInfinitesimal |] ==> stc(e + x) = x"
apply (rule add_commute [THEN subst])
apply (blast intro!: stc_CInfinitesimal_add_SComplex)
done

lemma CFinite_stc_CInfinitesimal_add:
     "x \<in> CFinite ==> \<exists>e \<in> CInfinitesimal. x = stc(x) + e"
by (blast dest!: stc_capprox_self [THEN capprox_sym] bex_CInfinitesimal_iff2 [THEN iffD2])

lemma stc_add:
     "[| x \<in> CFinite; y \<in> CFinite |] ==> stc (x + y) = stc(x) + stc(y)"
apply (frule CFinite_stc_CInfinitesimal_add)
apply (frule_tac x = y in CFinite_stc_CInfinitesimal_add, safe)
apply (subgoal_tac "stc (x + y) = stc ((stc x + e) + (stc y + ea))")
apply (drule_tac [2] sym, drule_tac [2] sym)
 prefer 2 apply simp 
apply (simp (no_asm_simp) add: add_ac)
apply (drule stc_SComplex)+
apply (drule SComplex_add, assumption)
apply (drule CInfinitesimal_add, assumption)
apply (rule add_assoc [THEN subst])
apply (blast intro!: stc_CInfinitesimal_add_SComplex2)
done

lemma stc_number_of [simp]: "stc (number_of w) = number_of w"
by (rule SComplex_number_of [THEN stc_SComplex_eq])

lemma stc_zero [simp]: "stc 0 = 0"
by simp

lemma stc_one [simp]: "stc 1 = 1"
by simp

lemma stc_minus: "y \<in> CFinite ==> stc(-y) = -stc(y)"
apply (frule CFinite_minus_iff [THEN iffD2])
apply (rule hcomplex_add_minus_eq_minus)
apply (drule stc_add [symmetric], assumption)
apply (simp add: add_commute)
done

lemma stc_diff: 
     "[| x \<in> CFinite; y \<in> CFinite |] ==> stc (x-y) = stc(x) - stc(y)"
apply (simp add: diff_minus)
apply (frule_tac y1 = y in stc_minus [symmetric])
apply (drule_tac x1 = y in CFinite_minus_iff [THEN iffD2])
apply (auto intro: stc_add)
done

lemma lemma_stc_mult:
     "[| x \<in> CFinite; y \<in> CFinite;  
         e \<in> CInfinitesimal;        
         ea: CInfinitesimal |]    
       ==> e*y + x*ea + e*ea: CInfinitesimal"
apply (frule_tac x = e and y = y in CInfinitesimal_CFinite_mult)
apply (frule_tac [2] x = ea and y = x in CInfinitesimal_CFinite_mult)
apply (drule_tac [3] CInfinitesimal_mult)
apply (auto intro: CInfinitesimal_add simp add: add_ac mult_ac)
done

lemma stc_mult:
     "[| x \<in> CFinite; y \<in> CFinite |]  
               ==> stc (x * y) = stc(x) * stc(y)"
apply (frule CFinite_stc_CInfinitesimal_add)
apply (frule_tac x = y in CFinite_stc_CInfinitesimal_add, safe)
apply (subgoal_tac "stc (x * y) = stc ((stc x + e) * (stc y + ea))")
apply (drule_tac [2] sym, drule_tac [2] sym)
 prefer 2 apply simp 
apply (erule_tac V = "x = stc x + e" in thin_rl)
apply (erule_tac V = "y = stc y + ea" in thin_rl)
apply (simp add: left_distrib right_distrib)
apply (drule stc_SComplex)+
apply (simp (no_asm_use) add: add_assoc)
apply (rule stc_CInfinitesimal_add_SComplex)
apply (blast intro!: SComplex_mult)
apply (drule SComplex_subset_CFinite [THEN subsetD])+
apply (rule add_assoc [THEN subst])
apply (blast intro!: lemma_stc_mult)
done

lemma stc_CInfinitesimal: "x \<in> CInfinitesimal ==> stc x = 0"
apply (rule stc_zero [THEN subst])
apply (rule capprox_stc_eq)
apply (auto intro: CInfinitesimal_subset_CFinite [THEN subsetD]
                 simp add: mem_cinfmal_iff [symmetric])
done

lemma stc_not_CInfinitesimal: "stc(x) \<noteq> 0 ==> x \<notin> CInfinitesimal"
by (fast intro: stc_CInfinitesimal)

lemma stc_inverse:
     "[| x \<in> CFinite; stc x \<noteq> 0 |]  
      ==> stc(inverse x) = inverse (stc x)"
apply (rule_tac c1 = "stc x" in hcomplex_mult_left_cancel [THEN iffD1])
apply (auto simp add: stc_mult [symmetric] stc_not_CInfinitesimal CFinite_inverse)
apply (subst right_inverse, auto)
done

lemma stc_divide [simp]:
     "[| x \<in> CFinite; y \<in> CFinite; stc y \<noteq> 0 |]  
      ==> stc(x/y) = (stc x) / (stc y)"
by (simp add: divide_inverse stc_mult stc_not_CInfinitesimal CFinite_inverse stc_inverse)

lemma stc_idempotent [simp]: "x \<in> CFinite ==> stc(stc(x)) = stc(x)"
by (blast intro: stc_CFinite stc_capprox_self capprox_stc_eq)

lemma CFinite_HFinite_hcomplex_of_hypreal:
     "z \<in> HFinite ==> hcomplex_of_hypreal z \<in> CFinite"
apply (cases z)
apply (simp add: hcomplex_of_hypreal CFinite_HFinite_iff star_n_zero_num [symmetric])
done

lemma SComplex_SReal_hcomplex_of_hypreal:
     "x \<in> Reals ==>  hcomplex_of_hypreal x \<in> SComplex"
by (auto simp add: SReal_def SComplex_def hcomplex_of_hypreal_def)

lemma stc_hcomplex_of_hypreal: 
 "z \<in> HFinite ==> stc(hcomplex_of_hypreal z) = hcomplex_of_hypreal (st z)"
apply (simp add: st_def stc_def)
apply (frule st_part_Ex, safe)
apply (rule someI2)
apply (auto intro: approx_sym)
apply (drule CFinite_HFinite_hcomplex_of_hypreal)
apply (frule stc_part_Ex, safe)
apply (rule someI2)
apply (auto intro: capprox_sym intro!: capprox_unique_complex dest: SComplex_SReal_hcomplex_of_hypreal)
done

(*
Goal "x \<in> CFinite ==> hcmod(stc x) = st(hcmod x)"
by (dtac stc_capprox_self 1)
by (auto_tac (claset(),simpset() addsimps [bex_CInfinitesimal_iff2 RS sym]));


approx_hcmod_add_hcmod
*)

lemma CInfinitesimal_hcnj_iff [simp]:
     "(hcnj z \<in> CInfinitesimal) = (z \<in> CInfinitesimal)"
by (simp add: CInfinitesimal_hcmod_iff)

lemma CInfinite_HInfinite_iff:
     "(star_n X \<in> CInfinite) =  
      (star_n (%n. Re(X n)) \<in> HInfinite |  
       star_n (%n. Im(X n)) \<in> HInfinite)"
by (simp add: CInfinite_CFinite_iff HInfinite_HFinite_iff CFinite_HFinite_iff)

text{*These theorems should probably be deleted*}
lemma hcomplex_split_CInfinitesimal_iff:
     "(hcomplex_of_hypreal x + iii * hcomplex_of_hypreal y \<in> CInfinitesimal) =  
      (x \<in> Infinitesimal & y \<in> Infinitesimal)"
apply (cases x, cases y)
apply (simp add: iii_def star_of_def star_n_add star_n_mult hcomplex_of_hypreal CInfinitesimal_Infinitesimal_iff)
done

lemma hcomplex_split_CFinite_iff:
     "(hcomplex_of_hypreal x + iii * hcomplex_of_hypreal y \<in> CFinite) =  
      (x \<in> HFinite & y \<in> HFinite)"
apply (cases x, cases y)
apply (simp add: iii_def star_of_def star_n_add star_n_mult hcomplex_of_hypreal CFinite_HFinite_iff)
done

lemma hcomplex_split_SComplex_iff:
     "(hcomplex_of_hypreal x + iii * hcomplex_of_hypreal y \<in> SComplex) =  
      (x \<in> Reals & y \<in> Reals)"
apply (cases x, cases y)
apply (simp add: iii_def star_of_def star_n_add star_n_mult hcomplex_of_hypreal SComplex_SReal_iff)
done

lemma hcomplex_split_CInfinite_iff:
     "(hcomplex_of_hypreal x + iii * hcomplex_of_hypreal y \<in> CInfinite) =  
      (x \<in> HInfinite | y \<in> HInfinite)"
apply (cases x, cases y)
apply (simp add: iii_def star_of_def star_n_add star_n_mult hcomplex_of_hypreal CInfinite_HInfinite_iff)
done

lemma hcomplex_split_capprox_iff:
     "(hcomplex_of_hypreal x + iii * hcomplex_of_hypreal y @c=  
       hcomplex_of_hypreal x' + iii * hcomplex_of_hypreal y') =  
      (x @= x' & y @= y')"
apply (cases x, cases y, cases x', cases y')
apply (simp add: iii_def star_of_def star_n_add star_n_mult hcomplex_of_hypreal capprox_approx_iff)
done

lemma complex_seq_to_hcomplex_CInfinitesimal:
     "\<forall>n. cmod (X n - x) < inverse (real (Suc n)) ==>  
      star_n X - hcomplex_of_complex x \<in> CInfinitesimal"
apply (simp add: star_n_diff CInfinitesimal_hcmod_iff star_of_def Infinitesimal_FreeUltrafilterNat_iff hcmod)
apply (auto dest: FreeUltrafilterNat_inverse_real_of_posnat FreeUltrafilterNat_all FreeUltrafilterNat_Int intro: order_less_trans FreeUltrafilterNat_subset)
done

lemma CInfinitesimal_hcomplex_of_hypreal_epsilon [simp]:
     "hcomplex_of_hypreal epsilon \<in> CInfinitesimal"
by (simp add: CInfinitesimal_hcmod_iff)

lemma hcomplex_of_complex_approx_zero_iff [simp]:
     "(hcomplex_of_complex z @c= 0) = (z = 0)"
by (simp add: star_of_zero [symmetric] del: star_of_zero)

lemma hcomplex_of_complex_approx_zero_iff2 [simp]:
     "(0 @c= hcomplex_of_complex z) = (z = 0)"
by (simp add: star_of_zero [symmetric] del: star_of_zero)

end

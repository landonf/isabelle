(*  Title:      HOL/NatSimprocs.thy
    ID:         $Id$
    Copyright   2003 TU Muenchen
*)

header {*Simprocs for the Naturals*}

theory NatSimprocs
imports Groebner_Basis
uses
  "~~/src/Provers/Arith/cancel_numeral_factor.ML"
  "~~/src/Provers/Arith/extract_common_term.ML"
  "int_factor_simprocs.ML"
  "nat_simprocs.ML"
begin

setup nat_simprocs_setup

subsection{*For simplifying @{term "Suc m - K"} and  @{term "K - Suc m"}*}

text{*Where K above is a literal*}

lemma Suc_diff_eq_diff_pred: "Numeral0 < n ==> Suc m - n = m - (n - Numeral1)"
by (simp add: numeral_0_eq_0 numeral_1_eq_1 split add: nat_diff_split)

text {*Now just instantiating @{text n} to @{text "number_of v"} does
  the right simplification, but with some redundant inequality
  tests.*}
lemma neg_number_of_pred_iff_0:
  "neg (number_of (Numeral.pred v)::int) = (number_of v = (0::nat))"
apply (subgoal_tac "neg (number_of (Numeral.pred v)) = (number_of v < Suc 0) ")
apply (simp only: less_Suc_eq_le le_0_eq)
apply (subst less_number_of_Suc, simp)
done

text{*No longer required as a simprule because of the @{text inverse_fold}
   simproc*}
lemma Suc_diff_number_of:
     "neg (number_of (uminus v)::int) ==>  
      Suc m - (number_of v) = m - (number_of (Numeral.pred v))"
apply (subst Suc_diff_eq_diff_pred)
apply simp
apply (simp del: nat_numeral_1_eq_1)
apply (auto simp only: diff_nat_number_of less_0_number_of [symmetric] 
                        neg_number_of_pred_iff_0)
done

lemma diff_Suc_eq_diff_pred: "m - Suc n = (m - 1) - n"
by (simp add: numerals split add: nat_diff_split)


subsection{*For @{term nat_case} and @{term nat_rec}*}

lemma nat_case_number_of [simp]:
     "nat_case a f (number_of v) =  
        (let pv = number_of (Numeral.pred v) in  
         if neg pv then a else f (nat pv))"
by (simp split add: nat.split add: Let_def neg_number_of_pred_iff_0)

lemma nat_case_add_eq_if [simp]:
     "nat_case a f ((number_of v) + n) =  
       (let pv = number_of (Numeral.pred v) in  
         if neg pv then nat_case a f n else f (nat pv + n))"
apply (subst add_eq_if)
apply (simp split add: nat.split
            del: nat_numeral_1_eq_1
	    add: numeral_1_eq_Suc_0 [symmetric] Let_def 
                 neg_imp_number_of_eq_0 neg_number_of_pred_iff_0)
done

lemma nat_rec_number_of [simp]:
     "nat_rec a f (number_of v) =  
        (let pv = number_of (Numeral.pred v) in  
         if neg pv then a else f (nat pv) (nat_rec a f (nat pv)))"
apply (case_tac " (number_of v) ::nat")
apply (simp_all (no_asm_simp) add: Let_def neg_number_of_pred_iff_0)
apply (simp split add: split_if_asm)
done

lemma nat_rec_add_eq_if [simp]:
     "nat_rec a f (number_of v + n) =  
        (let pv = number_of (Numeral.pred v) in  
         if neg pv then nat_rec a f n  
                   else f (nat pv + n) (nat_rec a f (nat pv + n)))"
apply (subst add_eq_if)
apply (simp split add: nat.split
            del: nat_numeral_1_eq_1
            add: numeral_1_eq_Suc_0 [symmetric] Let_def neg_imp_number_of_eq_0
                 neg_number_of_pred_iff_0)
done


subsection{*Various Other Lemmas*}

subsubsection{*Evens and Odds, for Mutilated Chess Board*}

text{*Lemmas for specialist use, NOT as default simprules*}
lemma nat_mult_2: "2 * z = (z+z::nat)"
proof -
  have "2*z = (1 + 1)*z" by simp
  also have "... = z+z" by (simp add: left_distrib)
  finally show ?thesis .
qed

lemma nat_mult_2_right: "z * 2 = (z+z::nat)"
by (subst mult_commute, rule nat_mult_2)

text{*Case analysis on @{term "n<2"}*}
lemma less_2_cases: "(n::nat) < 2 ==> n = 0 | n = Suc 0"
by arith

lemma div2_Suc_Suc [simp]: "Suc(Suc m) div 2 = Suc (m div 2)"
by arith

lemma add_self_div_2 [simp]: "(m + m) div 2 = (m::nat)"
by (simp add: nat_mult_2 [symmetric])

lemma mod2_Suc_Suc [simp]: "Suc(Suc(m)) mod 2 = m mod 2"
apply (subgoal_tac "m mod 2 < 2")
apply (erule less_2_cases [THEN disjE])
apply (simp_all (no_asm_simp) add: Let_def mod_Suc nat_1)
done

lemma mod2_gr_0 [simp]: "!!m::nat. (0 < m mod 2) = (m mod 2 = 1)"
apply (subgoal_tac "m mod 2 < 2")
apply (force simp del: mod_less_divisor, simp) 
done

subsubsection{*Removal of Small Numerals: 0, 1 and (in additive positions) 2*}

lemma add_2_eq_Suc [simp]: "2 + n = Suc (Suc n)"
by simp

lemma add_2_eq_Suc' [simp]: "n + 2 = Suc (Suc n)"
by simp

text{*Can be used to eliminate long strings of Sucs, but not by default*}
lemma Suc3_eq_add_3: "Suc (Suc (Suc n)) = 3 + n"
by simp


text{*These lemmas collapse some needless occurrences of Suc:
    at least three Sucs, since two and fewer are rewritten back to Suc again!
    We already have some rules to simplify operands smaller than 3.*}

lemma div_Suc_eq_div_add3 [simp]: "m div (Suc (Suc (Suc n))) = m div (3+n)"
by (simp add: Suc3_eq_add_3)

lemma mod_Suc_eq_mod_add3 [simp]: "m mod (Suc (Suc (Suc n))) = m mod (3+n)"
by (simp add: Suc3_eq_add_3)

lemma Suc_div_eq_add3_div: "(Suc (Suc (Suc m))) div n = (3+m) div n"
by (simp add: Suc3_eq_add_3)

lemma Suc_mod_eq_add3_mod: "(Suc (Suc (Suc m))) mod n = (3+m) mod n"
by (simp add: Suc3_eq_add_3)

lemmas Suc_div_eq_add3_div_number_of =
    Suc_div_eq_add3_div [of _ "number_of v", standard]
declare Suc_div_eq_add3_div_number_of [simp]

lemmas Suc_mod_eq_add3_mod_number_of =
    Suc_mod_eq_add3_mod [of _ "number_of v", standard]
declare Suc_mod_eq_add3_mod_number_of [simp]



subsection{*Special Simplification for Constants*}

text{*These belong here, late in the development of HOL, to prevent their
interfering with proofs of abstract properties of instances of the function
@{term number_of}*}

text{*These distributive laws move literals inside sums and differences.*}
lemmas left_distrib_number_of = left_distrib [of _ _ "number_of v", standard]
declare left_distrib_number_of [simp]

lemmas right_distrib_number_of = right_distrib [of "number_of v", standard]
declare right_distrib_number_of [simp]


lemmas left_diff_distrib_number_of =
    left_diff_distrib [of _ _ "number_of v", standard]
declare left_diff_distrib_number_of [simp]

lemmas right_diff_distrib_number_of =
    right_diff_distrib [of "number_of v", standard]
declare right_diff_distrib_number_of [simp]


text{*These are actually for fields, like real: but where else to put them?*}
lemmas zero_less_divide_iff_number_of =
    zero_less_divide_iff [of "number_of w", standard]
declare zero_less_divide_iff_number_of [simp]

lemmas divide_less_0_iff_number_of =
    divide_less_0_iff [of "number_of w", standard]
declare divide_less_0_iff_number_of [simp]

lemmas zero_le_divide_iff_number_of =
    zero_le_divide_iff [of "number_of w", standard]
declare zero_le_divide_iff_number_of [simp]

lemmas divide_le_0_iff_number_of =
    divide_le_0_iff [of "number_of w", standard]
declare divide_le_0_iff_number_of [simp]


(****
IF times_divide_eq_right and times_divide_eq_left are removed as simprules,
then these special-case declarations may be useful.

text{*These simprules move numerals into numerators and denominators.*}
lemma times_recip_eq_right [simp]: "a * (1/c) = a / (c::'a::field)"
by (simp add: times_divide_eq)

lemma times_recip_eq_left [simp]: "(1/c) * a = a / (c::'a::field)"
by (simp add: times_divide_eq)

lemmas times_divide_eq_right_number_of =
    times_divide_eq_right [of "number_of w", standard]
declare times_divide_eq_right_number_of [simp]

lemmas times_divide_eq_right_number_of =
    times_divide_eq_right [of _ _ "number_of w", standard]
declare times_divide_eq_right_number_of [simp]

lemmas times_divide_eq_left_number_of =
    times_divide_eq_left [of _ "number_of w", standard]
declare times_divide_eq_left_number_of [simp]

lemmas times_divide_eq_left_number_of =
    times_divide_eq_left [of _ _ "number_of w", standard]
declare times_divide_eq_left_number_of [simp]

****)

text {*Replaces @{text "inverse #nn"} by @{text "1/#nn"}.  It looks
  strange, but then other simprocs simplify the quotient.*}

lemmas inverse_eq_divide_number_of =
    inverse_eq_divide [of "number_of w", standard]
declare inverse_eq_divide_number_of [simp]


subsubsection{*These laws simplify inequalities, moving unary minus from a term
into the literal.*}
lemmas less_minus_iff_number_of =
    less_minus_iff [of "number_of v", standard]
declare less_minus_iff_number_of [simp]

lemmas le_minus_iff_number_of =
    le_minus_iff [of "number_of v", standard]
declare le_minus_iff_number_of [simp]

lemmas equation_minus_iff_number_of =
    equation_minus_iff [of "number_of v", standard]
declare equation_minus_iff_number_of [simp]


lemmas minus_less_iff_number_of =
    minus_less_iff [of _ "number_of v", standard]
declare minus_less_iff_number_of [simp]

lemmas minus_le_iff_number_of =
    minus_le_iff [of _ "number_of v", standard]
declare minus_le_iff_number_of [simp]

lemmas minus_equation_iff_number_of =
    minus_equation_iff [of _ "number_of v", standard]
declare minus_equation_iff_number_of [simp]


subsubsection{*To Simplify Inequalities Where One Side is the Constant 1*}

lemma less_minus_iff_1 [simp]: 
  fixes b::"'b::{ordered_idom,number_ring}" 
  shows "(1 < - b) = (b < -1)"
by auto

lemma le_minus_iff_1 [simp]: 
  fixes b::"'b::{ordered_idom,number_ring}" 
  shows "(1 \<le> - b) = (b \<le> -1)"
by auto

lemma equation_minus_iff_1 [simp]: 
  fixes b::"'b::number_ring" 
  shows "(1 = - b) = (b = -1)"
by (subst equation_minus_iff, auto) 

lemma minus_less_iff_1 [simp]: 
  fixes a::"'b::{ordered_idom,number_ring}" 
  shows "(- a < 1) = (-1 < a)"
by auto

lemma minus_le_iff_1 [simp]: 
  fixes a::"'b::{ordered_idom,number_ring}" 
  shows "(- a \<le> 1) = (-1 \<le> a)"
by auto

lemma minus_equation_iff_1 [simp]: 
  fixes a::"'b::number_ring" 
  shows "(- a = 1) = (a = -1)"
by (subst minus_equation_iff, auto) 


subsubsection {*Cancellation of constant factors in comparisons (@{text "<"} and @{text "\<le>"}) *}

lemmas mult_less_cancel_left_number_of =
    mult_less_cancel_left [of "number_of v", standard]
declare mult_less_cancel_left_number_of [simp]

lemmas mult_less_cancel_right_number_of =
    mult_less_cancel_right [of _ "number_of v", standard]
declare mult_less_cancel_right_number_of [simp]

lemmas mult_le_cancel_left_number_of =
    mult_le_cancel_left [of "number_of v", standard]
declare mult_le_cancel_left_number_of [simp]

lemmas mult_le_cancel_right_number_of =
    mult_le_cancel_right [of _ "number_of v", standard]
declare mult_le_cancel_right_number_of [simp]


subsubsection {*Multiplying out constant divisors in comparisons (@{text "<"}, @{text "\<le>"} and @{text "="}) *}

lemmas le_divide_eq_number_of = le_divide_eq [of _ _ "number_of w", standard]
declare le_divide_eq_number_of [simp]

lemmas divide_le_eq_number_of = divide_le_eq [of _ "number_of w", standard]
declare divide_le_eq_number_of [simp]

lemmas less_divide_eq_number_of = less_divide_eq [of _ _ "number_of w", standard]
declare less_divide_eq_number_of [simp]

lemmas divide_less_eq_number_of = divide_less_eq [of _ "number_of w", standard]
declare divide_less_eq_number_of [simp]

lemmas eq_divide_eq_number_of = eq_divide_eq [of _ _ "number_of w", standard]
declare eq_divide_eq_number_of [simp]

lemmas divide_eq_eq_number_of = divide_eq_eq [of _ "number_of w", standard]
declare divide_eq_eq_number_of [simp]



subsection{*Optional Simplification Rules Involving Constants*}

text{*Simplify quotients that are compared with a literal constant.*}

lemmas le_divide_eq_number_of = le_divide_eq [of "number_of w", standard]
lemmas divide_le_eq_number_of = divide_le_eq [of _ _ "number_of w", standard]
lemmas less_divide_eq_number_of = less_divide_eq [of "number_of w", standard]
lemmas divide_less_eq_number_of = divide_less_eq [of _ _ "number_of w", standard]
lemmas eq_divide_eq_number_of = eq_divide_eq [of "number_of w", standard]
lemmas divide_eq_eq_number_of = divide_eq_eq [of _ _ "number_of w", standard]


text{*Not good as automatic simprules because they cause case splits.*}
lemmas divide_const_simps =
  le_divide_eq_number_of divide_le_eq_number_of less_divide_eq_number_of
  divide_less_eq_number_of eq_divide_eq_number_of divide_eq_eq_number_of
  le_divide_eq_1 divide_le_eq_1 less_divide_eq_1 divide_less_eq_1

subsubsection{*Division By @{text "-1"}*}

lemma divide_minus1 [simp]:
     "x/-1 = -(x::'a::{field,division_by_zero,number_ring})" 
by simp

lemma minus1_divide [simp]:
     "-1 / (x::'a::{field,division_by_zero,number_ring}) = - (1/x)"
by (simp add: divide_inverse inverse_minus_eq)

lemma half_gt_zero_iff:
     "(0 < r/2) = (0 < (r::'a::{ordered_field,division_by_zero,number_ring}))"
by auto

lemmas half_gt_zero = half_gt_zero_iff [THEN iffD2, standard]
declare half_gt_zero [simp]

(* The following lemma should appear in Divides.thy, but there the proof
   doesn't work. *)

lemma nat_dvd_not_less:
  "[| 0 < m; m < n |] ==> \<not> n dvd (m::nat)"
  by (unfold dvd_def) auto

ML {*
val divide_minus1 = @{thm divide_minus1};
val minus1_divide = @{thm minus1_divide};
*}

section{* Installing Groebner Bases for Fields *}


interpretation class_fieldgb: 
  fieldgb["op +" "op *" "op ^" "0::'a::{field,recpower,number_ring}" "1" "op -" "uminus" "op /" "inverse"] apply (unfold_locales) by (simp_all add: divide_inverse)

lemma divide_Numeral1: "(x::'a::{field,number_ring}) / Numeral1 = x" by simp
lemma divide_Numeral0: "(x::'a::{field,number_ring, division_by_zero}) / Numeral0 = 0" 
  by simp
lemma mult_frac_frac: "((x::'a::{field,division_by_zero}) / y) * (z / w) = (x*z) / (y*w)" 
  by simp
lemma mult_frac_num: "((x::'a::{field, division_by_zero}) / y) * z  = (x*z) / y" 
  by simp
lemma mult_num_frac: "((x::'a::{field, division_by_zero}) / y) * z  = (x*z) / y" 
  by simp

lemma Numeral1_eq1_nat: "(1::nat) = Numeral1" by simp

lemma add_frac_num: "y\<noteq> 0 \<Longrightarrow> (x::'a::{field, division_by_zero}) / y + z = (x + z*y) / y" 
  by (simp add: add_divide_distrib)
lemma add_num_frac: "y\<noteq> 0 \<Longrightarrow> z + (x::'a::{field, division_by_zero}) / y = (x + z*y) / y" 
  by (simp add: add_divide_distrib)

declaration{*
let
 val zr = @{cpat "0"}
 val zT = ctyp_of_term zr
 val geq = @{cpat "op ="}
 val eqT = Thm.dest_ctyp (ctyp_of_term geq) |> hd
 val add_frac_eq = mk_meta_eq @{thm "add_frac_eq"} 
 val add_frac_num = mk_meta_eq @{thm "add_frac_num"}
 val add_num_frac = mk_meta_eq @{thm "add_num_frac"}

 fun prove_nz ss T t = 
    let 
      val z = instantiate_cterm ([(zT,T)],[]) zr 
      val eq = instantiate_cterm ([(eqT,T)],[]) geq
      val th = Simplifier.rewrite (ss addsimps simp_thms) 
           (Thm.capply @{cterm "Trueprop"} (Thm.capply @{cterm "Not"} 
                  (Thm.capply (Thm.capply eq t) z)))
    in equal_elim (symmetric th) TrueI
    end

 fun proc phi ss ct = 
  let 
    val ((x,y),(w,z)) = 
         (Thm.dest_binop #> (fn (a,b) => (Thm.dest_binop a, Thm.dest_binop b))) ct
    val _ = map (HOLogic.dest_number o term_of) [x,y,z,w] 
    val T = ctyp_of_term x
    val [y_nz, z_nz] = map (prove_nz ss T) [y, z]
    val th = instantiate' [SOME T] (map SOME [y,z,x,w]) add_frac_eq
  in SOME (implies_elim (implies_elim th y_nz) z_nz)
  end
  handle CTERM _ => NONE | TERM _ => NONE | THM _ => NONE

 fun proc2 phi ss ct = 
  let 
    val (l,r) = Thm.dest_binop ct
    val T = ctyp_of_term l
  in (case (term_of l, term_of r) of
      (Const(@{const_name "HOL.divide"},_)$_$_, _) => 
        let val (x,y) = Thm.dest_binop l val z = r
            val _ = map (HOLogic.dest_number o term_of) [x,y,z]
            val ynz = prove_nz ss T y
        in SOME (implies_elim (instantiate' [SOME T] (map SOME [y,x,z]) add_frac_num) ynz)
        end
     | (_, Const (@{const_name "HOL.divide"},_)$_$_) => 
        let val (x,y) = Thm.dest_binop r val z = l
            val _ = map (HOLogic.dest_number o term_of) [x,y,z]
            val ynz = prove_nz ss T y
        in SOME (implies_elim (instantiate' [SOME T] (map SOME [y,z,x]) add_num_frac) ynz)
        end
     | _ => NONE)
  end
  handle CTERM _ => NONE | TERM _ => NONE | THM _ => NONE

 fun is_number (Const(@{const_name "HOL.divide"},_)$a$b) = is_number a andalso is_number b
   | is_number t = can HOLogic.dest_number t

 val is_number = is_number o term_of

 fun proc3 phi ss ct =
  (case term_of ct of
    Const(@{const_name "Orderings.less"},_)$(Const(@{const_name "HOL.divide"},_)$_$_)$_ => 
      let 
        val ((a,b),c) = Thm.dest_binop ct |>> Thm.dest_binop
        val _ = map is_number [a,b,c]
        val T = ctyp_of_term c
        val th = instantiate' [SOME T] (map SOME [a,b,c]) @{thm "divide_less_eq"}
      in SOME (mk_meta_eq th) end
  | Const(@{const_name "Orderings.less_eq"},_)$(Const(@{const_name "HOL.divide"},_)$_$_)$_ => 
      let 
        val ((a,b),c) = Thm.dest_binop ct |>> Thm.dest_binop
        val _ = map is_number [a,b,c]
        val T = ctyp_of_term c
        val th = instantiate' [SOME T] (map SOME [a,b,c]) @{thm "divide_le_eq"}
      in SOME (mk_meta_eq th) end
  | Const("op =",_)$(Const(@{const_name "HOL.divide"},_)$_$_)$_ => 
      let 
        val ((a,b),c) = Thm.dest_binop ct |>> Thm.dest_binop
        val _ = map is_number [a,b,c]
        val T = ctyp_of_term c
        val th = instantiate' [SOME T] (map SOME [a,b,c]) @{thm "divide_eq_eq"}
      in SOME (mk_meta_eq th) end
  | Const(@{const_name "Orderings.less"},_)$_$(Const(@{const_name "HOL.divide"},_)$_$_) => 
    let 
      val (a,(b,c)) = Thm.dest_binop ct ||> Thm.dest_binop
        val _ = map is_number [a,b,c]
        val T = ctyp_of_term c
        val th = instantiate' [SOME T] (map SOME [a,b,c]) @{thm "less_divide_eq"}
      in SOME (mk_meta_eq th) end
  | Const(@{const_name "Orderings.less_eq"},_)$_$(Const(@{const_name "HOL.divide"},_)$_$_) => 
    let 
      val (a,(b,c)) = Thm.dest_binop ct ||> Thm.dest_binop
        val _ = map is_number [a,b,c]
        val T = ctyp_of_term c
        val th = instantiate' [SOME T] (map SOME [a,b,c]) @{thm "le_divide_eq"}
      in SOME (mk_meta_eq th) end
  | Const("op =",_)$_$(Const(@{const_name "HOL.divide"},_)$_$_) => 
    let 
      val (a,(b,c)) = Thm.dest_binop ct ||> Thm.dest_binop
        val _ = map is_number [a,b,c]
        val T = ctyp_of_term c
        val th = instantiate' [SOME T] (map SOME [a,b,c]) @{thm "eq_divide_eq"}
      in SOME (mk_meta_eq th) end
  | _ => NONE)
  handle TERM _ => NONE | CTERM _ => NONE | THM _ => NONE

val add_frac_frac_simproc = 
       make_simproc {lhss = [@{cpat "(?x::?'a::field)/?y + (?w::?'a::field)/?z"}], 
                     name = "add_frac_frac_simproc",
                     proc = proc, identifier = []}

val add_frac_num_simproc = 
       make_simproc {lhss = [@{cpat "(?x::?'a::field)/?y + ?z"}, @{cpat "?z + (?x::?'a::field)/?y"}], 
                     name = "add_frac_num_simproc",
                     proc = proc2, identifier = []}

val ord_frac_simproc = 
  make_simproc 
    {lhss = [@{cpat "(?a::(?'a::{field, ord}))/?b < ?c"}, 
             @{cpat "(?a::(?'a::{field, ord}))/?b \<le> ?c"}, 
             @{cpat "?c < (?a::(?'a::{field, ord}))/?b"}, 
             @{cpat "?c \<le> (?a::(?'a::{field, ord}))/?b"},
             @{cpat "?c = ((?a::(?'a::{field, ord}))/?b)"},
             @{cpat "((?a::(?'a::{field, ord}))/ ?b) = ?c"}],
             name = "ord_frac_simproc", proc = proc3, identifier = []}

val nat_arith = map thm ["add_nat_number_of", "diff_nat_number_of", 
               "mult_nat_number_of", "eq_nat_number_of", "less_nat_number_of"]

val comp_arith = (map thm ["Let_def", "if_False", "if_True", "add_0", 
                 "add_Suc", "add_number_of_left", "mult_number_of_left", 
                 "Suc_eq_add_numeral_1"])@
                 (map (fn s => thm s RS sym) ["numeral_1_eq_1", "numeral_0_eq_0"])
                 @ arith_simps@ nat_arith @ rel_simps 
val ths = [@{thm "mult_numeral_1"}, @{thm "mult_numeral_1_right"}, 
           @{thm "divide_Numeral1"}, 
           @{thm "Ring_and_Field.divide_zero"}, @{thm "divide_Numeral0"},
           @{thm "divide_divide_eq_left"}, @{thm "mult_frac_frac"},
           @{thm "mult_num_frac"}, @{thm "mult_frac_num"}, 
           @{thm "mult_frac_frac"}, @{thm "times_divide_eq_right"}, 
           @{thm "times_divide_eq_left"}, @{thm "divide_divide_eq_right"},
           @{thm "diff_def"}, @{thm "minus_divide_left"}, 
           @{thm "Numeral1_eq1_nat"}, @{thm "add_divide_distrib"} RS sym]

val ss = HOL_basic_ss addsimps @{thms "Groebner_Basis.comp_arith"} 
                 addsimps ths addsimps comp_arith addsimps simp_thms
                 addsimprocs field_cancel_numeral_factors
                 addsimprocs [add_frac_frac_simproc, add_frac_num_simproc,
                              ord_frac_simproc]
                 addcongs [@{thm "if_weak_cong"}]

val comp_conv = Simplifier.rewrite ss

fun numeral_is_const ct = 
  case term_of ct of 
   Const (@{const_name "HOL.divide"},_) $ a $ b => 
     can HOLogic.dest_number a andalso can HOLogic.dest_number b
 | t => can HOLogic.dest_number t

fun dest_const ct = case term_of ct of
   Const (@{const_name "HOL.divide"},_) $ a $ b=>
    Rat.rat_of_quotient (snd (HOLogic.dest_number a), snd (HOLogic.dest_number b))
 | t => Rat.rat_of_int (snd (HOLogic.dest_number t))

fun mk_const phi cT x = 
 let val (a, b) = Rat.quotient_of_rat x
 in if b = 1 then Normalizer.mk_cnumber cT a
    else Thm.capply 
         (Thm.capply (Drule.cterm_rule (instantiate' [SOME cT] []) @{cpat "op /"}) 
                     (Normalizer.mk_cnumber cT a))
         (Normalizer.mk_cnumber cT b)
  end

in 
 NormalizerData.funs @{thm class_fieldgb.axioms}
   {is_const = K numeral_is_const,
    dest_const = K dest_const,
    mk_const = mk_const,
    conv = K comp_conv}
end

*}

end

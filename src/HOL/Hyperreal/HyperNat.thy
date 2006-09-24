(*  Title       : HyperNat.thy
    Author      : Jacques D. Fleuriot
    Copyright   : 1998  University of Cambridge

Converted to Isar and polished by lcp    
*)

header{*Hypernatural numbers*}

theory HyperNat
imports Star
begin

types hypnat = "nat star"

abbreviation
  hypnat_of_nat :: "nat => nat star"
  "hypnat_of_nat == star_of"

subsection{*Properties Transferred from Naturals*}

lemma hypnat_minus_zero [simp]: "!!z. z - z = (0::hypnat)"
by transfer (rule diff_self_eq_0)

lemma hypnat_diff_0_eq_0 [simp]: "!!n. (0::hypnat) - n = 0"
by transfer (rule diff_0_eq_0)

lemma hypnat_add_is_0 [iff]: "!!m n. (m+n = (0::hypnat)) = (m=0 & n=0)"
by transfer (rule add_is_0)

lemma hypnat_diff_diff_left: "!!i j k. (i::hypnat) - j - k = i - (j+k)"
by transfer (rule diff_diff_left)

lemma hypnat_diff_commute: "!!i j k. (i::hypnat) - j - k = i-k-j"
by transfer (rule diff_commute)

lemma hypnat_diff_add_inverse [simp]: "!!m n. ((n::hypnat) + m) - n = m"
by transfer (rule diff_add_inverse)

lemma hypnat_diff_add_inverse2 [simp]:  "!!m n. ((m::hypnat) + n) - n = m"
by transfer (rule diff_add_inverse2)

lemma hypnat_diff_cancel [simp]: "!!k m n. ((k::hypnat) + m) - (k+n) = m - n"
by transfer (rule diff_cancel)

lemma hypnat_diff_cancel2 [simp]: "!!k m n. ((m::hypnat) + k) - (n+k) = m - n"
by transfer (rule diff_cancel2)

lemma hypnat_diff_add_0 [simp]: "!!m n. (n::hypnat) - (n+m) = (0::hypnat)"
by transfer (rule diff_add_0)

lemma hypnat_diff_mult_distrib: "!!k m n. ((m::hypnat) - n) * k = (m * k) - (n * k)"
by transfer (rule diff_mult_distrib)

lemma hypnat_diff_mult_distrib2: "!!k m n. (k::hypnat) * (m - n) = (k * m) - (k * n)"
by transfer (rule diff_mult_distrib2)

lemma hypnat_le_zero_cancel [iff]: "!!n. (n \<le> (0::hypnat)) = (n = 0)"
by transfer (rule le_0_eq)

lemma hypnat_mult_is_0 [simp]: "!!m n. (m*n = (0::hypnat)) = (m=0 | n=0)"
by transfer (rule mult_is_0)

lemma hypnat_diff_is_0_eq [simp]: "!!m n. ((m::hypnat) - n = 0) = (m \<le> n)"
by transfer (rule diff_is_0_eq)

lemma hypnat_not_less0 [iff]: "!!n. ~ n < (0::hypnat)"
by transfer (rule not_less0)

lemma hypnat_less_one [iff]:
      "!!n. (n < (1::hypnat)) = (n=0)"
by transfer (rule less_one)

lemma hypnat_add_diff_inverse: "!!m n. ~ m<n ==> n+(m-n) = (m::hypnat)"
by transfer (rule add_diff_inverse)

lemma hypnat_le_add_diff_inverse [simp]: "!!m n. n \<le> m ==> n+(m-n) = (m::hypnat)"
by transfer (rule le_add_diff_inverse)

lemma hypnat_le_add_diff_inverse2 [simp]: "!!m n. n\<le>m ==> (m-n)+n = (m::hypnat)"
by transfer (rule le_add_diff_inverse2)

declare hypnat_le_add_diff_inverse2 [OF order_less_imp_le]

lemma hypnat_le0 [iff]: "!!n. (0::hypnat) \<le> n"
by transfer (rule le0)

lemma hypnat_add_self_le [simp]: "!!x n. (x::hypnat) \<le> n + x"
by transfer (rule le_add2)

lemma hypnat_add_one_self_less [simp]: "(x::hypnat) < x + (1::hypnat)"
by (insert add_strict_left_mono [OF zero_less_one], auto)

lemma hypnat_neq0_conv [iff]: "!!n. (n \<noteq> 0) = (0 < (n::hypnat))"
by transfer (rule neq0_conv)

lemma hypnat_gt_zero_iff: "((0::hypnat) < n) = ((1::hypnat) \<le> n)"
by (auto simp add: linorder_not_less [symmetric])

lemma hypnat_gt_zero_iff2: "(0 < n) = (\<exists>m. n = m + (1::hypnat))"
apply safe
 apply (rule_tac x = "n - (1::hypnat) " in exI)
 apply (simp add: hypnat_gt_zero_iff) 
apply (insert add_le_less_mono [OF _ zero_less_one, of 0], auto) 
done

lemma hypnat_add_self_not_less: "~ (x + y < (x::hypnat))"
by (simp add: linorder_not_le [symmetric] add_commute [of x]) 

lemma hypnat_diff_split:
    "P(a - b::hypnat) = ((a<b --> P 0) & (ALL d. a = b + d --> P d))"
    -- {* elimination of @{text -} on @{text hypnat} *}
proof (cases "a<b" rule: case_split)
  case True
    thus ?thesis
      by (auto simp add: hypnat_add_self_not_less order_less_imp_le 
                         hypnat_diff_is_0_eq [THEN iffD2])
next
  case False
    thus ?thesis
      by (auto simp add: linorder_not_less dest: order_le_less_trans) 
qed

subsection{*Properties of the set of embedded natural numbers*}

lemma hypnat_of_nat_def: "hypnat_of_nat m == of_nat m"
by (transfer, simp)

lemma hypnat_of_nat_one [simp]: "hypnat_of_nat (Suc 0) = (1::hypnat)"
by simp

lemma hypnat_of_nat_Suc [simp]:
     "hypnat_of_nat (Suc n) = hypnat_of_nat n + (1::hypnat)"
by (simp add: hypnat_of_nat_def)

lemma of_nat_eq_add [rule_format]:
     "\<forall>d::hypnat. of_nat m = of_nat n + d --> d \<in> range of_nat"
apply (induct n) 
apply (auto simp add: add_assoc) 
apply (case_tac x) 
apply (auto simp add: add_commute [of 1]) 
done

lemma Nats_diff [simp]: "[|a \<in> Nats; b \<in> Nats|] ==> (a-b :: hypnat) \<in> Nats"
by (auto simp add: of_nat_eq_add Nats_def split: hypnat_diff_split)



subsection{*Existence of an infinite hypernatural number*}

definition
  (* omega is in fact an infinite hypernatural number = [<1,2,3,...>] *)
  whn :: hypnat
  hypnat_omega_def: "whn = star_n (%n::nat. n)"

text{*Existence of infinite number not corresponding to any natural number
follows because member @{term FreeUltrafilterNat} is not finite.
See @{text HyperDef.thy} for similar argument.*}

text{* Example of an hypersequence (i.e. an extended standard sequence)
   whose term with an hypernatural suffix is an infinitesimal i.e.
   the whn'nth term of the hypersequence is a member of Infinitesimal*}

lemma SEQ_Infinitesimal:
      "( *f* (%n::nat. inverse(real(Suc n)))) whn : Infinitesimal"
apply (simp add: hypnat_omega_def starfun star_n_inverse)
apply (simp add: Infinitesimal_FreeUltrafilterNat_iff)
apply (simp add: real_of_nat_Suc_gt_zero FreeUltrafilterNat_inverse_real_of_posnat)
done

lemma lemma_unbounded_set [simp]: "{n::nat. m < n} \<in> FreeUltrafilterNat"
apply (insert finite_atMost [of m]) 
apply (simp add: atMost_def) 
apply (drule FreeUltrafilterNat_finite) 
apply (drule FreeUltrafilterNat_Compl_mem, ultra)
done

lemma Compl_Collect_le: "- {n::nat. N \<le> n} = {n. n < N}"
by (simp add: Collect_neg_eq [symmetric] linorder_not_le) 

lemma hypnat_of_nat_eq:
     "hypnat_of_nat m  = star_n (%n::nat. m)"
by (simp add: star_of_def)

lemma SHNat_eq: "Nats = {n. \<exists>N. n = hypnat_of_nat N}"
by (force simp add: hypnat_of_nat_def Nats_def) 

lemma hypnat_omega_gt_SHNat:
     "n \<in> Nats ==> n < whn"
by (auto simp add: hypnat_of_nat_eq star_n_less hypnat_omega_def SHNat_eq)

(* Infinite hypernatural not in embedded Nats *)
lemma SHNAT_omega_not_mem [simp]: "whn \<notin> Nats"
by (blast dest: hypnat_omega_gt_SHNat)

lemma hypnat_of_nat_less_whn [simp]: "hypnat_of_nat n < whn"
apply (insert hypnat_omega_gt_SHNat [of "hypnat_of_nat n"])
apply (simp add: hypnat_of_nat_def) 
done

lemma hypnat_of_nat_le_whn [simp]: "hypnat_of_nat n \<le> whn"
by (rule hypnat_of_nat_less_whn [THEN order_less_imp_le])

lemma hypnat_zero_less_hypnat_omega [simp]: "0 < whn"
by (simp add: hypnat_omega_gt_SHNat)

lemma hypnat_one_less_hypnat_omega [simp]: "(1::hypnat) < whn"
by (simp add: hypnat_omega_gt_SHNat)


subsection{*Infinite Hypernatural Numbers -- @{term HNatInfinite}*}

definition
  (* the set of infinite hypernatural numbers *)
  HNatInfinite :: "hypnat set"
  "HNatInfinite = {n. n \<notin> Nats}"

lemma HNatInfinite_whn [simp]: "whn \<in> HNatInfinite"
by (simp add: HNatInfinite_def)

lemma Nats_not_HNatInfinite_iff: "(x \<in> Nats) = (x \<notin> HNatInfinite)"
by (simp add: HNatInfinite_def)

lemma HNatInfinite_not_Nats_iff: "(x \<in> HNatInfinite) = (x \<notin> Nats)"
by (simp add: HNatInfinite_def)


subsubsection{*Alternative characterization of the set of infinite hypernaturals*}

text{* @{term "HNatInfinite = {N. \<forall>n \<in> Nats. n < N}"}*}

(*??delete? similar reasoning in hypnat_omega_gt_SHNat above*)
lemma HNatInfinite_FreeUltrafilterNat_lemma:
     "\<forall>N::nat. {n. f n \<noteq> N} \<in> FreeUltrafilterNat
      ==> {n. N < f n} \<in> FreeUltrafilterNat"
apply (induct_tac N)
apply (drule_tac x = 0 in spec)
apply (rule ccontr, drule FreeUltrafilterNat_Compl_mem, drule FreeUltrafilterNat_Int, assumption, simp)
apply (drule_tac x = "Suc n" in spec, ultra)
done

lemma HNatInfinite_iff: "HNatInfinite = {N. \<forall>n \<in> Nats. n < N}"
apply (auto simp add: HNatInfinite_def SHNat_eq hypnat_of_nat_eq)
apply (rule_tac x = x in star_cases)
apply (auto elim: HNatInfinite_FreeUltrafilterNat_lemma 
            simp add: star_n_less FreeUltrafilterNat_Compl_iff1 
                      star_n_eq_iff Collect_neg_eq [symmetric])
done


subsubsection{*Alternative Characterization of @{term HNatInfinite} using 
Free Ultrafilter*}

lemma HNatInfinite_FreeUltrafilterNat:
     "star_n X \<in> HNatInfinite ==> \<forall>u. {n. u < X n}:  FreeUltrafilterNat"
apply (auto simp add: HNatInfinite_iff SHNat_eq)
apply (drule_tac x="star_of u" in spec, simp)
apply (simp add: star_of_def star_n_less)
done

lemma FreeUltrafilterNat_HNatInfinite:
     "\<forall>u. {n. u < X n}:  FreeUltrafilterNat ==> star_n X \<in> HNatInfinite"
by (auto simp add: star_n_less HNatInfinite_iff SHNat_eq hypnat_of_nat_eq)

lemma HNatInfinite_FreeUltrafilterNat_iff:
     "(star_n X \<in> HNatInfinite) = (\<forall>u. {n. u < X n}:  FreeUltrafilterNat)"
by (rule iffI [OF HNatInfinite_FreeUltrafilterNat 
                 FreeUltrafilterNat_HNatInfinite])

lemma HNatInfinite_gt_one [simp]: "x \<in> HNatInfinite ==> (1::hypnat) < x"
by (auto simp add: HNatInfinite_iff)

lemma zero_not_mem_HNatInfinite [simp]: "0 \<notin> HNatInfinite"
apply (auto simp add: HNatInfinite_iff)
apply (drule_tac a = " (1::hypnat) " in equals0D)
apply simp
done

lemma HNatInfinite_not_eq_zero: "x \<in> HNatInfinite ==> 0 < x"
apply (drule HNatInfinite_gt_one) 
apply (auto simp add: order_less_trans [OF zero_less_one])
done

lemma HNatInfinite_ge_one [simp]: "x \<in> HNatInfinite ==> (1::hypnat) \<le> x"
by (blast intro: order_less_imp_le HNatInfinite_gt_one)


subsubsection{*Closure Rules*}

lemma HNatInfinite_add:
     "[| x \<in> HNatInfinite; y \<in> HNatInfinite |] ==> x + y \<in> HNatInfinite"
apply (auto simp add: HNatInfinite_iff)
apply (drule bspec, assumption)
apply (drule bspec [OF _ Nats_0])
apply (drule add_strict_mono, assumption, simp)
done

lemma HNatInfinite_SHNat_add:
     "[| x \<in> HNatInfinite; y \<in> Nats |] ==> x + y \<in> HNatInfinite"
apply (auto simp add: HNatInfinite_not_Nats_iff) 
apply (drule_tac a = "x + y" in Nats_diff, auto) 
done

lemma HNatInfinite_Nats_imp_less: "[| x \<in> HNatInfinite; y \<in> Nats |] ==> y < x"
by (simp add: HNatInfinite_iff) 

lemma HNatInfinite_SHNat_diff:
  assumes x: "x \<in> HNatInfinite" and y: "y \<in> Nats" 
  shows "x - y \<in> HNatInfinite"
proof -
  have "y < x" by (simp add: HNatInfinite_Nats_imp_less prems)
  hence "x - y + y = x" by (simp add: order_less_imp_le)
  with x show ?thesis
    by (force simp add: HNatInfinite_not_Nats_iff 
              dest: Nats_add [of "x-y", OF _ y]) 
qed

lemma HNatInfinite_add_one:
     "x \<in> HNatInfinite ==> x + (1::hypnat) \<in> HNatInfinite"
by (auto intro: HNatInfinite_SHNat_add)

lemma HNatInfinite_is_Suc: "x \<in> HNatInfinite ==> \<exists>y. x = y + (1::hypnat)"
apply (rule_tac x = "x - (1::hypnat) " in exI)
apply auto
done


subsection{*Embedding of the Hypernaturals into the Hyperreals*}
text{*Obtained using the nonstandard extension of the naturals*}

definition
  hypreal_of_hypnat :: "hypnat => hypreal"
  "hypreal_of_hypnat = *f* real"

declare hypreal_of_hypnat_def [transfer_unfold]

lemma HNat_hypreal_of_nat [simp]: "hypreal_of_nat N \<in> Nats"
by (simp add: hypreal_of_nat_def) 

lemma hypreal_of_hypnat:
      "hypreal_of_hypnat (star_n X) = star_n (%n. real (X n))"
by (simp add: hypreal_of_hypnat_def starfun)

lemma hypreal_of_hypnat_inject [simp]:
     "!!m n. (hypreal_of_hypnat m = hypreal_of_hypnat n) = (m=n)"
by (transfer, simp)

lemma hypreal_of_hypnat_zero: "hypreal_of_hypnat 0 = 0"
by (simp add: star_n_zero_num hypreal_of_hypnat)

lemma hypreal_of_hypnat_one: "hypreal_of_hypnat (1::hypnat) = 1"
by (simp add: star_n_one_num hypreal_of_hypnat)

lemma hypreal_of_hypnat_add [simp]:
     "!!m n. hypreal_of_hypnat (m + n) = hypreal_of_hypnat m + hypreal_of_hypnat n"
by (transfer, rule real_of_nat_add)

lemma hypreal_of_hypnat_mult [simp]:
     "!!m n. hypreal_of_hypnat (m * n) = hypreal_of_hypnat m * hypreal_of_hypnat n"
by (transfer, rule real_of_nat_mult)

lemma hypreal_of_hypnat_less_iff [simp]:
     "!!m n. (hypreal_of_hypnat n < hypreal_of_hypnat m) = (n < m)"
by (transfer, simp)

lemma hypreal_of_hypnat_eq_zero_iff: "(hypreal_of_hypnat N = 0) = (N = 0)"
by (simp add: hypreal_of_hypnat_zero [symmetric])
declare hypreal_of_hypnat_eq_zero_iff [simp]

lemma hypreal_of_hypnat_ge_zero [simp]: "!!n. 0 \<le> hypreal_of_hypnat n"
by (transfer, simp)

lemma HNatInfinite_inverse_Infinitesimal [simp]:
     "n \<in> HNatInfinite ==> inverse (hypreal_of_hypnat n) \<in> Infinitesimal"
apply (cases n)
apply (auto simp add: hypreal_of_hypnat star_n_inverse real_norm_def
      HNatInfinite_FreeUltrafilterNat_iff
      Infinitesimal_FreeUltrafilterNat_iff2)
apply (drule_tac x="Suc m" in spec)
apply (erule ultra, simp)
done

lemma HNatInfinite_hypreal_of_hypnat_gt_zero:
     "N \<in> HNatInfinite ==> 0 < hypreal_of_hypnat N"
apply (rule ccontr)
apply (simp add: hypreal_of_hypnat_zero [symmetric] linorder_not_less)
done

end

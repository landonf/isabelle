header{*Proving instances of Separation using Reflection!*}

theory Separation = L_axioms:

text{*Helps us solve for de Bruijn indices!*}
lemma nth_ConsI: "[|nth(n,l) = x; n \<in> nat|] ==> nth(succ(n), Cons(a,l)) = x"
by simp

lemmas nth_rules = nth_0 nth_ConsI nat_0I nat_succI
lemmas sep_rules = nth_0 nth_ConsI FOL_iff_sats fun_plus_iff_sats

lemma Collect_conj_in_DPow:
     "[| {x\<in>A. P(x)} \<in> DPow(A);  {x\<in>A. Q(x)} \<in> DPow(A) |] 
      ==> {x\<in>A. P(x) & Q(x)} \<in> DPow(A)"
by (simp add: Int_in_DPow Collect_Int_Collect_eq [symmetric]) 

lemma Collect_conj_in_DPow_Lset:
     "[|z \<in> Lset(j); {x \<in> Lset(j). P(x)} \<in> DPow(Lset(j))|]
      ==> {x \<in> Lset(j). x \<in> z & P(x)} \<in> DPow(Lset(j))"
apply (frule mem_Lset_imp_subset_Lset)
apply (simp add: Collect_conj_in_DPow Collect_mem_eq 
                 subset_Int_iff2 elem_subset_in_DPow)
done

lemma separation_CollectI:
     "(\<And>z. L(z) ==> L({x \<in> z . P(x)})) ==> separation(L, \<lambda>x. P(x))"
apply (unfold separation_def, clarify) 
apply (rule_tac x="{x\<in>z. P(x)}" in rexI) 
apply simp_all
done

text{*Reduces the original comprehension to the reflected one*}
lemma reflection_imp_L_separation:
      "[| \<forall>x\<in>Lset(j). P(x) <-> Q(x);
          {x \<in> Lset(j) . Q(x)} \<in> DPow(Lset(j)); 
          Ord(j);  z \<in> Lset(j)|] ==> L({x \<in> z . P(x)})"
apply (rule_tac i = "succ(j)" in L_I)
 prefer 2 apply simp
apply (subgoal_tac "{x \<in> z. P(x)} = {x \<in> Lset(j). x \<in> z & (Q(x))}")
 prefer 2
 apply (blast dest: mem_Lset_imp_subset_Lset) 
apply (simp add: Lset_succ Collect_conj_in_DPow_Lset)
done


subsection{*Separation for Intersection*}

lemma Inter_Reflects:
     "REFLECTS[\<lambda>x. \<forall>y[L]. y\<in>A --> x \<in> y, 
               \<lambda>i x. \<forall>y\<in>Lset(i). y\<in>A --> x \<in> y]"
by (intro FOL_reflection)  

lemma Inter_separation:
     "L(A) ==> separation(L, \<lambda>x. \<forall>y[L]. y\<in>A --> x\<in>y)"
apply (rule separation_CollectI) 
apply (rule_tac A="{A,z}" in subset_LsetE, blast ) 
apply (rule ReflectsE [OF Inter_Reflects], assumption)
apply (drule subset_Lset_ltD, assumption) 
apply (erule reflection_imp_L_separation)
  apply (simp_all add: lt_Ord2, clarify)
apply (rule DPowI2) 
apply (rule ball_iff_sats) 
apply (rule imp_iff_sats)
apply (rule_tac [2] i=1 and j=0 and env="[y,x,A]" in mem_iff_sats)
apply (rule_tac i=0 and j=2 in mem_iff_sats)
apply (simp_all add: succ_Un_distrib [symmetric])
done

subsection{*Separation for Cartesian Product*}

lemma cartprod_Reflects [simplified]:
     "REFLECTS[\<lambda>z. \<exists>x[L]. x\<in>A & (\<exists>y[L]. y\<in>B & pair(L,x,y,z)),
                \<lambda>i z. \<exists>x\<in>Lset(i). x\<in>A & (\<exists>y\<in>Lset(i). y\<in>B & 
                                   pair(**Lset(i),x,y,z))]"
by (intro FOL_reflection function_reflection)  

lemma cartprod_separation:
     "[| L(A); L(B) |] 
      ==> separation(L, \<lambda>z. \<exists>x[L]. x\<in>A & (\<exists>y[L]. y\<in>B & pair(L,x,y,z)))"
apply (rule separation_CollectI) 
apply (rule_tac A="{A,B,z}" in subset_LsetE, blast ) 
apply (rule ReflectsE [OF cartprod_Reflects], assumption)
apply (drule subset_Lset_ltD, assumption) 
apply (erule reflection_imp_L_separation)
  apply (simp_all add: lt_Ord2, clarify) 
apply (rule DPowI2)
apply (rename_tac u)  
apply (rule bex_iff_sats) 
apply (rule conj_iff_sats)
apply (rule_tac i=0 and j=2 and env="[x,u,A,B]" in mem_iff_sats, simp_all)
apply (rule sep_rules | simp)+
apply (simp_all add: succ_Un_distrib [symmetric])
done

subsection{*Separation for Image*}

text{*No @{text simplified} here: it simplifies the occurrence of 
      the predicate @{term pair}!*}
lemma image_Reflects:
     "REFLECTS[\<lambda>y. \<exists>p[L]. p\<in>r & (\<exists>x[L]. x\<in>A & pair(L,x,y,p)),
           \<lambda>i y. \<exists>p\<in>Lset(i). p\<in>r & (\<exists>x\<in>Lset(i). x\<in>A & pair(**Lset(i),x,y,p))]"
by (intro FOL_reflection function_reflection)


lemma image_separation:
     "[| L(A); L(r) |] 
      ==> separation(L, \<lambda>y. \<exists>p[L]. p\<in>r & (\<exists>x[L]. x\<in>A & pair(L,x,y,p)))"
apply (rule separation_CollectI) 
apply (rule_tac A="{A,r,z}" in subset_LsetE, blast ) 
apply (rule ReflectsE [OF image_Reflects], assumption)
apply (drule subset_Lset_ltD, assumption) 
apply (erule reflection_imp_L_separation)
  apply (simp_all add: lt_Ord2, clarify)
apply (rule DPowI2)
apply (rule bex_iff_sats) 
apply (rule conj_iff_sats)
apply (rule_tac env="[p,y,A,r]" in mem_iff_sats)
apply (rule sep_rules | simp)+
apply (simp_all add: succ_Un_distrib [symmetric])
done


subsection{*Separation for Converse*}

lemma converse_Reflects:
  "REFLECTS[\<lambda>z. \<exists>p[L]. p\<in>r & (\<exists>x[L]. \<exists>y[L]. pair(L,x,y,p) & pair(L,y,x,z)),
     \<lambda>i z. \<exists>p\<in>Lset(i). p\<in>r & (\<exists>x\<in>Lset(i). \<exists>y\<in>Lset(i). 
                     pair(**Lset(i),x,y,p) & pair(**Lset(i),y,x,z))]"
by (intro FOL_reflection function_reflection)

lemma converse_separation:
     "L(r) ==> separation(L, 
         \<lambda>z. \<exists>p[L]. p\<in>r & (\<exists>x[L]. \<exists>y[L]. pair(L,x,y,p) & pair(L,y,x,z)))"
apply (rule separation_CollectI) 
apply (rule_tac A="{r,z}" in subset_LsetE, blast ) 
apply (rule ReflectsE [OF converse_Reflects], assumption)
apply (drule subset_Lset_ltD, assumption) 
apply (erule reflection_imp_L_separation)
  apply (simp_all add: lt_Ord2, clarify)
apply (rule DPowI2)
apply (rename_tac u) 
apply (rule bex_iff_sats) 
apply (rule conj_iff_sats)
apply (rule_tac i=0 and j="2" and env="[p,u,r]" in mem_iff_sats, simp_all)
apply (rule sep_rules | simp)+
apply (simp_all add: succ_Un_distrib [symmetric])
done


subsection{*Separation for Restriction*}

lemma restrict_Reflects:
     "REFLECTS[\<lambda>z. \<exists>x[L]. x\<in>A & (\<exists>y[L]. pair(L,x,y,z)),
        \<lambda>i z. \<exists>x\<in>Lset(i). x\<in>A & (\<exists>y\<in>Lset(i). pair(**Lset(i),x,y,z))]"
by (intro FOL_reflection function_reflection)

lemma restrict_separation:
   "L(A) ==> separation(L, \<lambda>z. \<exists>x[L]. x\<in>A & (\<exists>y[L]. pair(L,x,y,z)))"
apply (rule separation_CollectI) 
apply (rule_tac A="{A,z}" in subset_LsetE, blast ) 
apply (rule ReflectsE [OF restrict_Reflects], assumption)
apply (drule subset_Lset_ltD, assumption) 
apply (erule reflection_imp_L_separation)
  apply (simp_all add: lt_Ord2, clarify)
apply (rule DPowI2)
apply (rename_tac u) 
apply (rule bex_iff_sats) 
apply (rule conj_iff_sats)
apply (rule_tac i=0 and j="2" and env="[x,u,A]" in mem_iff_sats, simp_all)
apply (rule sep_rules | simp)+
apply (simp_all add: succ_Un_distrib [symmetric])
done


subsection{*Separation for Composition*}

lemma comp_Reflects:
     "REFLECTS[\<lambda>xz. \<exists>x[L]. \<exists>y[L]. \<exists>z[L]. \<exists>xy[L]. \<exists>yz[L]. 
		  pair(L,x,z,xz) & pair(L,x,y,xy) & pair(L,y,z,yz) & 
                  xy\<in>s & yz\<in>r,
        \<lambda>i xz. \<exists>x\<in>Lset(i). \<exists>y\<in>Lset(i). \<exists>z\<in>Lset(i). \<exists>xy\<in>Lset(i). \<exists>yz\<in>Lset(i). 
		  pair(**Lset(i),x,z,xz) & pair(**Lset(i),x,y,xy) & 
                  pair(**Lset(i),y,z,yz) & xy\<in>s & yz\<in>r]"
by (intro FOL_reflection function_reflection)

lemma comp_separation:
     "[| L(r); L(s) |]
      ==> separation(L, \<lambda>xz. \<exists>x[L]. \<exists>y[L]. \<exists>z[L]. \<exists>xy[L]. \<exists>yz[L]. 
		  pair(L,x,z,xz) & pair(L,x,y,xy) & pair(L,y,z,yz) & 
                  xy\<in>s & yz\<in>r)"
apply (rule separation_CollectI) 
apply (rule_tac A="{r,s,z}" in subset_LsetE, blast ) 
apply (rule ReflectsE [OF comp_Reflects], assumption)
apply (drule subset_Lset_ltD, assumption) 
apply (erule reflection_imp_L_separation)
  apply (simp_all add: lt_Ord2, clarify)
apply (rule DPowI2)
apply (rename_tac u) 
apply (rule bex_iff_sats)+
apply (rename_tac x y z)  
apply (rule conj_iff_sats)
apply (rule_tac env="[z,y,x,u,r,s]" in pair_iff_sats)
apply (rule sep_rules | simp)+
apply (simp_all add: succ_Un_distrib [symmetric])
done

subsection{*Separation for Predecessors in an Order*}

lemma pred_Reflects:
     "REFLECTS[\<lambda>y. \<exists>p[L]. p\<in>r & pair(L,y,x,p),
                    \<lambda>i y. \<exists>p \<in> Lset(i). p\<in>r & pair(**Lset(i),y,x,p)]"
by (intro FOL_reflection function_reflection)

lemma pred_separation:
     "[| L(r); L(x) |] ==> separation(L, \<lambda>y. \<exists>p[L]. p\<in>r & pair(L,y,x,p))"
apply (rule separation_CollectI) 
apply (rule_tac A="{r,x,z}" in subset_LsetE, blast ) 
apply (rule ReflectsE [OF pred_Reflects], assumption)
apply (drule subset_Lset_ltD, assumption) 
apply (erule reflection_imp_L_separation)
  apply (simp_all add: lt_Ord2, clarify)
apply (rule DPowI2)
apply (rename_tac u) 
apply (rule bex_iff_sats)
apply (rule conj_iff_sats)
apply (rule_tac env = "[p,u,r,x]" in mem_iff_sats) 
apply (rule sep_rules | simp)+
apply (simp_all add: succ_Un_distrib [symmetric])
done


subsection{*Separation for the Membership Relation*}

lemma Memrel_Reflects:
     "REFLECTS[\<lambda>z. \<exists>x[L]. \<exists>y[L]. pair(L,x,y,z) & x \<in> y,
            \<lambda>i z. \<exists>x \<in> Lset(i). \<exists>y \<in> Lset(i). pair(**Lset(i),x,y,z) & x \<in> y]"
by (intro FOL_reflection function_reflection)

lemma Memrel_separation:
     "separation(L, \<lambda>z. \<exists>x[L]. \<exists>y[L]. pair(L,x,y,z) & x \<in> y)"
apply (rule separation_CollectI) 
apply (rule_tac A="{z}" in subset_LsetE, blast ) 
apply (rule ReflectsE [OF Memrel_Reflects], assumption)
apply (drule subset_Lset_ltD, assumption) 
apply (erule reflection_imp_L_separation)
  apply (simp_all add: lt_Ord2)
apply (rule DPowI2)
apply (rename_tac u) 
apply (rule bex_iff_sats conj_iff_sats)+
apply (rule_tac env = "[y,x,u]" in pair_iff_sats) 
apply (rule sep_rules | simp)+
apply (simp_all add: succ_Un_distrib [symmetric])
done


subsection{*Replacement for FunSpace*}
		
lemma funspace_succ_Reflects:
 "REFLECTS[\<lambda>z. \<exists>p[L]. p\<in>A & (\<exists>f[L]. \<exists>b[L]. \<exists>nb[L]. \<exists>cnbf[L]. 
	    pair(L,f,b,p) & pair(L,n,b,nb) & is_cons(L,nb,f,cnbf) &
	    upair(L,cnbf,cnbf,z)),
	\<lambda>i z. \<exists>p \<in> Lset(i). p\<in>A & (\<exists>f \<in> Lset(i). \<exists>b \<in> Lset(i). 
	      \<exists>nb \<in> Lset(i). \<exists>cnbf \<in> Lset(i). 
		pair(**Lset(i),f,b,p) & pair(**Lset(i),n,b,nb) & 
		is_cons(**Lset(i),nb,f,cnbf) & upair(**Lset(i),cnbf,cnbf,z))]"
by (intro FOL_reflection function_reflection)

lemma funspace_succ_replacement:
     "L(n) ==> 
      strong_replacement(L, \<lambda>p z. \<exists>f[L]. \<exists>b[L]. \<exists>nb[L]. \<exists>cnbf[L]. 
                pair(L,f,b,p) & pair(L,n,b,nb) & is_cons(L,nb,f,cnbf) &
                upair(L,cnbf,cnbf,z))"
apply (rule strong_replacementI) 
apply (rule rallI) 
apply (rule separation_CollectI) 
apply (rule_tac A="{n,A,z}" in subset_LsetE, blast ) 
apply (rule ReflectsE [OF funspace_succ_Reflects], assumption)
apply (drule subset_Lset_ltD, assumption) 
apply (erule reflection_imp_L_separation)
  apply (simp_all add: lt_Ord2)
apply (rule DPowI2)
apply (rename_tac u) 
apply (rule bex_iff_sats)
apply (rule conj_iff_sats)
apply (rule_tac env = "[x,u,n,A]" in mem_iff_sats) 
apply (rule sep_rules | simp)+
apply (simp_all add: succ_Un_distrib [symmetric])
done


subsection{*Separation for Order-Isomorphisms*}

lemma well_ord_iso_Reflects:
  "REFLECTS[\<lambda>x. x\<in>A --> 
                (\<exists>y[L]. \<exists>p[L]. fun_apply(L,f,x,y) & pair(L,y,x,p) & p \<in> r),
        \<lambda>i x. x\<in>A --> (\<exists>y \<in> Lset(i). \<exists>p \<in> Lset(i). 
                fun_apply(**Lset(i),f,x,y) & pair(**Lset(i),y,x,p) & p \<in> r)]"
by (intro FOL_reflection function_reflection)

lemma well_ord_iso_separation:
     "[| L(A); L(f); L(r) |] 
      ==> separation (L, \<lambda>x. x\<in>A --> (\<exists>y[L]. (\<exists>p[L]. 
		     fun_apply(L,f,x,y) & pair(L,y,x,p) & p \<in> r)))"
apply (rule separation_CollectI) 
apply (rule_tac A="{A,f,r,z}" in subset_LsetE, blast ) 
apply (rule ReflectsE [OF well_ord_iso_Reflects], assumption)
apply (drule subset_Lset_ltD, assumption) 
apply (erule reflection_imp_L_separation)
  apply (simp_all add: lt_Ord2)
apply (rule DPowI2)
apply (rename_tac u) 
apply (rule imp_iff_sats)
apply (rule_tac env = "[u,A,f,r]" in mem_iff_sats) 
apply (rule sep_rules | simp)+
apply (simp_all add: succ_Un_distrib [symmetric])
done


subsection{*Separation for @{term "obase"}*}

lemma obase_reflects:
  "REFLECTS[\<lambda>a. \<exists>x[L]. \<exists>g[L]. \<exists>mx[L]. \<exists>par[L]. 
	     ordinal(L,x) & membership(L,x,mx) & pred_set(L,A,a,r,par) &
	     order_isomorphism(L,par,r,x,mx,g),
        \<lambda>i a. \<exists>x \<in> Lset(i). \<exists>g \<in> Lset(i). \<exists>mx \<in> Lset(i). \<exists>par \<in> Lset(i). 
	     ordinal(**Lset(i),x) & membership(**Lset(i),x,mx) & pred_set(**Lset(i),A,a,r,par) &
	     order_isomorphism(**Lset(i),par,r,x,mx,g)]"
by (intro FOL_reflection function_reflection fun_plus_reflection)

lemma obase_separation:
     --{*part of the order type formalization*}
     "[| L(A); L(r) |] 
      ==> separation(L, \<lambda>a. \<exists>x[L]. \<exists>g[L]. \<exists>mx[L]. \<exists>par[L]. 
	     ordinal(L,x) & membership(L,x,mx) & pred_set(L,A,a,r,par) &
	     order_isomorphism(L,par,r,x,mx,g))"
apply (rule separation_CollectI) 
apply (rule_tac A="{A,r,z}" in subset_LsetE, blast ) 
apply (rule ReflectsE [OF obase_reflects], assumption)
apply (drule subset_Lset_ltD, assumption) 
apply (erule reflection_imp_L_separation)
  apply (simp_all add: lt_Ord2)
apply (rule DPowI2)
apply (rename_tac u) 
apply (rule bex_iff_sats)
apply (rule conj_iff_sats)
apply (rule_tac env = "[x,u,A,r]" in ordinal_iff_sats) 
apply (rule sep_rules | simp)+
apply (simp_all add: succ_Un_distrib [symmetric])
done


subsection{*Separation for a Theorem about @{term "obase"}*}

lemma obase_equals_reflects:
  "REFLECTS[\<lambda>x. x\<in>A --> ~(\<exists>y[L]. \<exists>g[L]. 
		ordinal(L,y) & (\<exists>my[L]. \<exists>pxr[L]. 
		membership(L,y,my) & pred_set(L,A,x,r,pxr) &
		order_isomorphism(L,pxr,r,y,my,g))),
	\<lambda>i x. x\<in>A --> ~(\<exists>y \<in> Lset(i). \<exists>g \<in> Lset(i). 
		ordinal(**Lset(i),y) & (\<exists>my \<in> Lset(i). \<exists>pxr \<in> Lset(i). 
		membership(**Lset(i),y,my) & pred_set(**Lset(i),A,x,r,pxr) &
		order_isomorphism(**Lset(i),pxr,r,y,my,g)))]"
by (intro FOL_reflection function_reflection fun_plus_reflection)


lemma obase_equals_separation:
     "[| L(A); L(r) |] 
      ==> separation (L, \<lambda>x. x\<in>A --> ~(\<exists>y[L]. \<exists>g[L]. 
			      ordinal(L,y) & (\<exists>my[L]. \<exists>pxr[L]. 
			      membership(L,y,my) & pred_set(L,A,x,r,pxr) &
			      order_isomorphism(L,pxr,r,y,my,g))))"
apply (rule separation_CollectI) 
apply (rule_tac A="{A,r,z}" in subset_LsetE, blast ) 
apply (rule ReflectsE [OF obase_equals_reflects], assumption)
apply (drule subset_Lset_ltD, assumption) 
apply (erule reflection_imp_L_separation)
  apply (simp_all add: lt_Ord2)
apply (rule DPowI2)
apply (rename_tac u) 
apply (rule imp_iff_sats ball_iff_sats disj_iff_sats not_iff_sats)+
apply (rule_tac env = "[u,A,r]" in mem_iff_sats) 
apply (rule sep_rules | simp)+
apply (simp_all add: succ_Un_distrib [symmetric])
done


subsection{*Replacement for @{term "omap"}*}

lemma omap_reflects:
 "REFLECTS[\<lambda>z. \<exists>a[L]. a\<in>B & (\<exists>x[L]. \<exists>g[L]. \<exists>mx[L]. \<exists>par[L]. 
     ordinal(L,x) & pair(L,a,x,z) & membership(L,x,mx) & 
     pred_set(L,A,a,r,par) & order_isomorphism(L,par,r,x,mx,g)),
 \<lambda>i z. \<exists>a \<in> Lset(i). a\<in>B & (\<exists>x \<in> Lset(i). \<exists>g \<in> Lset(i). \<exists>mx \<in> Lset(i). 
        \<exists>par \<in> Lset(i). 
	 ordinal(**Lset(i),x) & pair(**Lset(i),a,x,z) & 
         membership(**Lset(i),x,mx) & pred_set(**Lset(i),A,a,r,par) & 
         order_isomorphism(**Lset(i),par,r,x,mx,g))]"
by (intro FOL_reflection function_reflection fun_plus_reflection)

lemma omap_replacement:
     "[| L(A); L(r) |] 
      ==> strong_replacement(L,
             \<lambda>a z. \<exists>x[L]. \<exists>g[L]. \<exists>mx[L]. \<exists>par[L]. 
	     ordinal(L,x) & pair(L,a,x,z) & membership(L,x,mx) & 
	     pred_set(L,A,a,r,par) & order_isomorphism(L,par,r,x,mx,g))"
apply (rule strong_replacementI) 
apply (rule rallI)
apply (rename_tac B)  
apply (rule separation_CollectI) 
apply (rule_tac A="{A,B,r,z}" in subset_LsetE, blast ) 
apply (rule ReflectsE [OF omap_reflects], assumption)
apply (drule subset_Lset_ltD, assumption) 
apply (erule reflection_imp_L_separation)
  apply (simp_all add: lt_Ord2)
apply (rule DPowI2)
apply (rename_tac u) 
apply (rule bex_iff_sats conj_iff_sats)+
apply (rule_tac env = "[x,u,A,B,r]" in mem_iff_sats) 
apply (rule sep_rules | simp)+
apply (simp_all add: succ_Un_distrib [symmetric])
done

end

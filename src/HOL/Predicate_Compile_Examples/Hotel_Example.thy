theory Hotel_Example
imports Predicate_Compile_Alternative_Defs Code_Prolog
begin

datatype guest = Guest0 | Guest1
datatype key = Key0 | Key1 | Key2 | Key3
datatype room = Room0

types card = "key * key"

datatype event =
   Check_in guest room card | Enter guest room card | Exit guest room

definition initk :: "room \<Rightarrow> key"
  where "initk = (%r. Key0)"

declare initk_def[code_pred_def, code]

primrec owns :: "event list \<Rightarrow> room \<Rightarrow> guest option"
where
  "owns [] r = None"
| "owns (e#s) r = (case e of
    Check_in g r' c \<Rightarrow> if r' = r then Some g else owns s r |
    Enter g r' c \<Rightarrow> owns s r |
    Exit g r' \<Rightarrow> owns s r)"

primrec currk :: "event list \<Rightarrow> room \<Rightarrow> key"
where
  "currk [] r = initk r"
| "currk (e#s) r = (let k = currk s r in
    case e of Check_in g r' (k1, k2) \<Rightarrow> if r' = r then k2 else k
            | Enter g r' c \<Rightarrow> k
            | Exit g r \<Rightarrow> k)"

primrec issued :: "event list \<Rightarrow> key set"
where
  "issued [] = range initk"
| "issued (e#s) = issued s \<union>
  (case e of Check_in g r (k1, k2) \<Rightarrow> {k2} | Enter g r c \<Rightarrow> {} | Exit g r \<Rightarrow> {})"

primrec cards :: "event list \<Rightarrow> guest \<Rightarrow> card set"
where
  "cards [] g = {}"
| "cards (e#s) g = (let C = cards s g in
                    case e of Check_in g' r c \<Rightarrow> if g' = g then insert c C
                                                else C
                            | Enter g r c \<Rightarrow> C
                            | Exit g r \<Rightarrow> C)"

primrec roomk :: "event list \<Rightarrow> room \<Rightarrow> key"
where
  "roomk [] r = initk r"
| "roomk (e#s) r = (let k = roomk s r in
    case e of Check_in g r' c \<Rightarrow> k
            | Enter g r' (x,y) \<Rightarrow> if r' = r (*& x = k*) then y else k
            | Exit g r \<Rightarrow> k)"

primrec isin :: "event list \<Rightarrow> room \<Rightarrow> guest set"
where
  "isin [] r = {}"
| "isin (e#s) r = (let G = isin s r in
                 case e of Check_in g r c \<Rightarrow> G
                 | Enter g r' c \<Rightarrow> if r' = r then {g} \<union> G else G
                 | Exit g r' \<Rightarrow> if r'=r then G - {g} else G)"

primrec hotel :: "event list \<Rightarrow> bool"
where
  "hotel []  = True"
| "hotel (e # s) = (hotel s & (case e of
  Check_in g r (k,k') \<Rightarrow> k = currk s r \<and> k' \<notin> issued s |
  Enter g r (k,k') \<Rightarrow> (k,k') : cards s g & (roomk s r : {k, k'}) |
  Exit g r \<Rightarrow> g : isin s r))"

lemma issued_nil: "issued [] = {Key0}"
by (auto simp add: initk_def)

lemmas issued_simps[code, code_pred_def] = issued_nil issued.simps(2)

declare Let_def[code_pred_inline]

lemma [code_pred_inline]: "insert == (%y A x. y = x | A x)"
by (auto simp add: insert_iff[unfolded mem_def] fun_eq_iff intro!: eq_reflection)

lemma [code_pred_inline]: "(op -) == (%A B x. A x \<and> \<not> B x)"
by (auto simp add: Diff_iff[unfolded mem_def] fun_eq_iff intro!: eq_reflection)

setup {* Code_Prolog.map_code_options (K
  {ensure_groundness = true,
  limited_types = [],
  limited_predicates = [],
  replacing = [],
  manual_reorder = []}) *}

values 40 "{s. hotel s}"


setup {* Context.theory_map (Quickcheck.add_generator ("prolog", Code_Prolog.quickcheck)) *}

lemma "\<lbrakk> hotel s; g \<in> isin s r \<rbrakk> \<Longrightarrow> owns s r = Some g"
quickcheck[generator = code, iterations = 100000, report]
quickcheck[generator = prolog, iterations = 1, expect = counterexample]
oops


definition no_Check_in :: "event list \<Rightarrow> room \<Rightarrow> bool" where(*>*)
[code del]: "no_Check_in s r \<equiv> \<not>(\<exists>g c. Check_in g r c \<in> set s)"


definition feels_safe :: "event list \<Rightarrow> room \<Rightarrow> bool"
where
  "feels_safe s r = (\<exists>s\<^isub>1 s\<^isub>2 s\<^isub>3 g c c'.
   s = s\<^isub>3 @ [Enter g r c] @ s\<^isub>2 @ [Check_in g r c'] @ s\<^isub>1 \<and>
   no_Check_in (s\<^isub>3 @ s\<^isub>2) r \<and> isin (s\<^isub>2 @ [Check_in g r c] @ s\<^isub>1) r = {})"

setup {* Code_Prolog.map_code_options (K 
  {ensure_groundness = true,
   limited_types = [],
   limited_predicates = [(["hotel"], 5)],
   replacing = [(("hotel", "limited_hotel"), "quickcheck")],
   manual_reorder = []}) *}

lemma
  "hotel s ==> feels_safe s r ==> g \<in> isin s r ==> owns s r = Some g"
quickcheck[generator = prolog, iterations = 1, expect = counterexample]
oops

end
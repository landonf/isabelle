(*  Author:     Makarius

Example theory involving Unicode characters (UTF-8 encoding) -- both
formal and informal ones.
*)

section \<open>A Hebrew theory\<close>

theory Hebrew
imports Main
begin

subsection \<open>Warning: formal Unicode considered harmful\<close>

text \<open>
  Important note: editors or browsers that implement the \<^emph>\<open>Unicode
  Bidirectional Algorithm\<close> correctly (!) will display the following mix of
  left-to-right versus right-to-left characters in a way that is logical
  nonsense.

  To avoid such uncertainty, formal notation should be restricted to
  well-known Isabelle symbols and their controlled rendering (in Unicode or
  LaTeX).
\<close>

subsection \<open>The Hebrew Alef-Bet (א-ב).\<close>

datatype alef_bet =
    Alef    ("א")
  | Bet     ("ב")
  | Gimel   ("ג")
  | Dalet   ("ד")
  | He      ("ה")
  | Vav     ("ו")
  | Zayin   ("ז")
  | Het     ("ח")
  | Tet     ("ט")
  | Yod     ("י")
  | Kaf     ("כ")
  | Lamed   ("ל")
  | Mem     ("מ")
  | Nun     ("נ")
  | Samekh  ("ס")
  | Ayin    ("ע")
  | Pe      ("פ")
  | Tsadi   ("צ")
  | Qof     ("ק")
  | Resh    ("ר")
  | Shin    ("ש")
  | Tav     ("ת")

thm alef_bet.induct


subsection \<open>Interpreting Hebrew letters as numbers.\<close>

primrec mispar :: "alef_bet \<Rightarrow> nat"
where
  "mispar א = 1"
| "mispar ב = 2"
| "mispar ג = 3"
| "mispar ד = 4"
| "mispar ה = 5"
| "mispar ו = 6"
| "mispar ז = 7"
| "mispar ח = 8"
| "mispar ט = 9"
| "mispar י = 10"
| "mispar כ = 20"
| "mispar ל = 30"
| "mispar מ = 40"
| "mispar נ = 50"
| "mispar ס = 60"
| "mispar ע = 70"
| "mispar פ = 80"
| "mispar צ = 90"
| "mispar ק = 100"
| "mispar ר = 200"
| "mispar ש = 300"
| "mispar ת = 400"

thm mispar.simps

lemma "mispar ק + mispar ל + mispar ה = 135"
  by simp

end

#
# $Id$
# Author: David von Oheimb, TU Muenchen
# License: GPL (GNU GENERAL PUBLIC LICENSE)
#
# convert.pl - convert legacy tactic scripts to Isabelle/Isar tactic
#   emulation using heuristics - leaves unrecognized patterns unchanged
#   produces from each input file (on the command line) a new file with
#   ".thy" appended and renames the original input file by appending "~0~"


sub thmlist {
  my $s = shift;
  $s =~ s/^\[(.*)\]$/$1/sg;
  $s =~ s/, +/ /g;
  $s =~ s/,/ /g;
  $s;
}

sub mult_assumption {
  my $n = shift;
  my $r = "";
  for($i=0; $i<$n; $i++) { $r = $r.", assumption"; }
  $r;
}

sub process_tac {
  my $lead = shift;
  my $t = shift;
  my $simpmodmod = ($t =~ m/auto_tac|force_tac|clarsimp_tac/) ? "simp " : "";

  $_ = $t;
  s/\s+/ /sg;             # remove multiple whitespace
  s/\s/ /sg;              # substitute all remaining tabs and newlines by space
  s/\( /\(/g; s/ \)/\)/g; # remove leading and trailing space inside parentheses
  s/\[ /\[/g; s/ \]/\]/g; # remove leading and trailing space inside sq brackets
  s/ ?\( ?\)/\(\)/g;      # remove space before and inside empty tuples
  s/\(\)([^ ])/\(\) $1/g; # possibly add space after empty tuples

  s/Blast_tac 1/blast/g;
  s/Fast_tac 1/fast/g;
  s/Slow_tac 1/slow/g;
  s/Best_tac 1/best/g;
  s/Safe_tac/safe/g;
  s/Clarify_tac 1/clarify/g;

  s/blast_tac \(claset\(\) (.*?)\) 1/blast $1/g;
  s/fast_tac \(claset\(\) (.*?)\) 1/fast $1/g;
  s/slow_tac \(claset\(\) (.*?)\) 1/slow $1/g;
  s/best_tac \(claset\(\) (.*?)\) 1/best $1/g;
  s/safe_tac \(claset\(\) (.*?)\)/safe $1/g;
  s/clarify_tac \(claset\(\) (.*?)\) 1/clarify $1/g;

  s/Auto_tac/auto/g;
  s/Force_tac 1/force/g;
  s/Clarsimp_tac 1/clarsimp/g;

  s/auto_tac \(claset\(\) (.*?), *simpset\(\) (.*?)\)/auto $1 $2/g;
  s/force_tac \(claset\(\) (.*?), *simpset\(\) (.*?)\) 1/force $1 $2/g;
  s/clarsimp_tac \(claset\(*\) (.*?), *simpset\(\) (.*?)\) 1/clarsimp $1 $2/g;

  s/Asm_full_simp_tac 1/simp/g;
  s/Full_simp_tac 1/simp (no_asm_use)/g;
  s/Asm_simp_tac 1/simp (no_asm_simp)/g;
  s/Simp_tac 1/simp (no_asm)/g;
  s/ALLGOALS Asm_full_simp_tac/simp_all/g;
  s/ALLGOALS Full_simp_tac 1/simp_all (no_asm_use)/g;
  s/ALLGOALS Asm_simp_tac 1/simp_all (no_asm_simp)/g;
  s/ALLGOALS Simp_tac/simp_all (no_asm)/g;

  s/asm_full_simp_tac \(simpset\(\) (.*?)\) 1/simp $1/g;
  s/full_simp_tac \(simpset\(\) (.*?)\) 1/simp (no_asm_use) $1/g;
  s/asm_simp_tac \(simpset\(\) (.*?)\) 1/simp (no_asm_simp) $1/g;
  s/simp_tac \(simpset\(\) (.*?)\) 1/simp (no_asm) $1/g;
  s/ALLGOALS \(asm_full_simp_tac \(simpset\(\) (.*?)\)\)/simp_all $1/g;
  s/ALLGOALS \(full_simp_tac \(simpset\(\) (.*?)\)\)/simp_all (no_asm_use) $1/g;
  s/ALLGOALS \(asm_simp_tac \(simpset\(\) (.*?)\)\)/simp_all (no_asm_simp) $1/g;
  s/ALLGOALS \(simp_tac \(simpset\(\) (.*?)\)\)/simp_all (no_asm) $1/g;

  s/atac 1/assumption/g;
  s/hypsubst_tac 1/hypsubst/g;
  s/arith_tac 1/arith/g;
  s/strip_tac 1/intro strip/g;
  s/split_all_tac 1/simp (no_asm_simp) only: split_tupled_all/g;

  s/rotate_tac ([~\d]+) 1/rotate_tac $1/g;
  s/rotate_tac ([~\d]+) (\d+)/rotate_tac [$2] $1/g;
  s/rename_tac *(\".*?\") *1/rename_tac $1/g;
  s/rename_tac *(\".*?\") *(\d+)/rename_tac [$2] $1/g;
  s/case_tac *(\".*?\") *1/case_tac $1/g;
  s/case_tac *(\".*?\") *(\d+)/case_tac [$2] $1/g;
  s/induct_tac *(\".*?\") *1/induct_tac $1/g;
  s/induct_tac *(\".*?\") *(\d+)/induct_tac [$2] $1/g;
  s/subgoal_tac *(\".*?\") *1/subgoal_tac $1/g;
  s/subgoal_tac *(\".*?\") *(\d+)/subgoal_tac [$2] $1/g;
  s/thin_tac *(\".*?\") *1/erule_tac P = $1 thin_rl/g;
  s/thin_tac *(\".*?\") *(\d+)/erule_tac [$2] P = $1/g;

  s/stac ([\w\.]+) 1/subst $1/g;
  s/rtac ([\w\.]+) 1/rule $1/g;
  s/rtac ([\w\.]+) (\d+)/rule_tac [$2] $1/g;
  s/res_inst_tac \[\((\".*?\"),(\".*?\")\)\] ([\w\.]+) 1/rule_tac $1 = $2 $3/g;
  s/ratac ([\w\.]+) (\d+) 1/"rule $1".mult_assumption($2)/eg;
  s/dtac ([\w\.]+) 1/drule $1/g;
  s/dtac ([\w\.]+) (\d+)/drule_tac [$2] $1/g;
  s/dres_inst_tac \[\((\".*?\"),(\".*?\")\)\] ([\w\.]+) 1/drule_tac $1 = $2 $3/g;
  s/datac ([\w\.]+) (\d+) 1/"drule $1".mult_assumption($2)/eg;
  s/etac ([\w\.]+) 1/erule $1/g;
  s/etac ([\w\.]+) (\d+)/erule_tac [$2] $1/g;
  s/eres_inst_tac \[\((\".*?\"),(\".*?\")\)\] ([\w\.]+) 1/erule_tac $1 = $2 $3/g;
  s/eatac ([\w\.]+) (\d+) 1/"erule $1".mult_assumption($2)/eg;
  s/forward_tac \[([\w\.]+)\] 1/frule $1/g;
  s/ftac ([\w\.]+) 1/frule $1/g;
  s/ftac ([\w\.]+) (\d+)/frule_tac [$2] $1/g;
  s/forw_inst_tac \[\((\".*?\"),(\".*?\")\)\] ([\w\.]+) 1/frule_tac $1 = $2 $3/g;
  s/fatac ([\w\.]+) (\d+) 1/"frule $1".mult_assumption($2)/eg;


  s/THEN /, /g;
  s/ORELSE/|/g;
  s/fold_goals_tac *(\[[\w\. ,]*\]|[\w\.]+)/"fold ".thmlist($1)/eg;
  s/rewrite_goals_tac *(\[[\w\. ,]*\]|[\w\.]+)/"unfold ".thmlist($1)/eg;
  s/cut_facts_tac *(\[[\w\. ,]*\]|[\w\.]+) 1/"cut_tac ".thmlist($1)/eg;
  s/resolve_tac *(\[[\w\. ,]*\]|[\w\.]+) 1/"rule ".thmlist($1)/eg;
  s/EVERY *(\[[\w\. ,]*\]|[\w\.]+)/thmlist($1)/eg;

  s/addIs *(\[[\w\. ,]*\]|[\w\.]+)/"intro: ".thmlist($1)/eg;
  s/addSIs *(\[[\w\. ,]*\]|[\w\.]+)/"intro!: ".thmlist($1)/eg;
  s/addEs *(\[[\w\. ,]*\]|[\w\.]+)/"elim: ".thmlist($1)/eg;
  s/addSEs *(\[[\w\. ,]*\]|[\w\.]+)/"elim!: ".thmlist($1)/eg;
  s/addDs *(\[[\w\. ,]*\]|[\w\.]+)/"dest: ".thmlist($1)/eg;
  s/addSDs *(\[[\w\. ,]*\]|[\w\.]+)/"dest!: ".thmlist($1)/eg;
  s/delrules *(\[[\w\. ,]*\]|[\w\.]+)/"del: ".thmlist($1)/eg;
  s/addsimps *(\[[\w\. ,]*\]|[\w\.]+)/"$simpmodmod"."add: ".thmlist($1)/eg;
  s/delsimps *(\[[\w\. ,]*\]|[\w\.]+)/"$simpmodmod"."del: ".thmlist($1)/eg;
  s/addcongs *(\[[\w\. ,]*\]|[\w\.]+)/"cong add: ".thmlist($1)/eg;
  s/delcongs *(\[[\w\. ,]*\]|[\w\.]+)/"cong del: ".thmlist($1)/eg;
  s/addsplits *(\[[\w\. ,]*\]|[\w\.]+)/"split add: ".thmlist($1)/eg;
  s/delsplits *(\[[\w\. ,]*\]|[\w\.]+)/"split del: ".thmlist($1)/eg;

  s/([\w\.]+) RS ([\w\.]+)/$1 \[THEN $2\]/g;

  s/ +/ /g;                  # remove multiple whitespace
  s/\( /\(/; s/ \)/\)/g;  # remove leading and trailing space inside parentheses
  s/^ *(.*?) *$/$1/s;        # remove enclosing whitespace
  s/^\( *([\w\.]+) *\)$/$1/; # remove outermost parentheses if around atoms
  s/^([a-zA-Z])/ $1/ if (!($lead =~ m/[\s\(]$/)); # add space if required
  $_;
}

sub thmname { "@@" . ++$thmcount . "@@"; }

sub backpatch_thmnames {
  if($currfile ne "") {
    select(STDOUT);
    close(ARGVOUT);
    open(TMPW, '>'.$finalfile);
    open TMPR,$tmpfile or die "Can't find tmp file $tmp: $!\n";
    while(<TMPR>) {
      s/@@(\d+)@@/$thmnames[$1]/eg;
      print TMPW $_;
    }
    system("mv $currfile $currfile.~0~");
    system("rm $tmpfile");
  }
}

sub done {
  my $name = shift;
  my $attr = shift;
  $thmnames[$thmcount] = $name.$attr;
  "done";
}

$next = "nonempty";
while (<>) { # main loop
  if ($ARGV ne $currfile) {
    $x=$_; backpatch_thmnames; $_=$x;
    $currfile = $ARGV;
    $thmcount=0;
    $finalfile = "$currfile.thy";
    $tmpfile   = "$finalfile.~0~";
    open(ARGVOUT, '>'.$tmpfile);
    select(ARGVOUT);
  }

 nl:
  if(!(s/;\s*?(\n?)$/$1/s)) {# no end_of_ML_command marker
    $next = <>; $_ = $_ . $next;
    if($next) { goto nl; }
  }
  s/\\(\s*\n\s*)\\/ $1 /g; # remove backslashes escaping newlines
 nlc:
  m/^(\s*)(.*?)(\s*)$/s;
  $head=$1; $line=$2; $tail=$3;
  $tail =~ s/\s+\n/\n/sg;  # remove trailing whitespace at end of lines
  print $head; $_=$2.$tail;
  if ($line =~ m/^\(\*/) { # start comment
    while (($i = index $_,"*)") == -1) { # no end comment
      print $_;
      $_ = <>;
    }
    print substr $_,0,$i+2;
    $_ = substr $_,$i+2;
    goto nlc;
  }
  $_=$line;
  s/^Goalw *(\[[\w\.\s,]*\]|[\w\.]+) *(.+)/
    "lemma ".thmname().": $2$head"."apply (unfold ".thmlist($1).")"/se;
  s/^Goal *(.+)/"lemma ".thmname().": $1"/se;
  s/ goal/"(*".thmname()."*) goal"/se; # ugly old-style goals
  s/^qed_spec_mp *\"(.*?)\"/done($1," [rule_format (no_asm)]")/se;
  s/^qed *\"(.*?)\"/done($1,"")/se;
  s/^bind_thm *\( *\"(.*?)\" *, *(.*?result *\( *\).*?) *\) *$/done($1,"[?? $2 ??] ")/se;
  s/^by(\s*\(?\s*)(.*?)$/"apply$1".process_tac($1,$2)/se;
  print "$_$tail";
  if(!$next) { last; } # prevents reading finally from stdin (thru <>)!
}
backpatch_thmnames;
select(STDOUT);

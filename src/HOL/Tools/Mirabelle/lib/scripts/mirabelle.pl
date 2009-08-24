#
# Author: Jasmin Blanchette and Sascha Boehme
#
# Testing tool for automated proof tools.
#

use File::Basename;

# environment

my $isabelle_home = $ENV{'ISABELLE_HOME'};
my $mirabelle_home = $ENV{'MIRABELLE_HOME'};
my $mirabelle_logic = $ENV{'MIRABELLE_LOGIC'};
my $mirabelle_theory = $ENV{'MIRABELLE_THEORY'};
my $output_path = $ENV{'MIRABELLE_OUTPUT_PATH'};
my $verbose = $ENV{'MIRABELLE_VERBOSE'};
my $timeout = $ENV{'MIRABELLE_TIMEOUT'};

my $mirabelle_thy = $mirabelle_home . "/Mirabelle";


# arguments

my $actions = $ARGV[0];

my $thy_file = $ARGV[1];
my $start_line = "0";
my $end_line = "~1";
if ($thy_file =~ /^(.*)\[([0-9]+)\:(~?[0-9]+)\]$/) { # FIXME
  my $thy_file = $1;
  my $start_line = $2;
  my $end_line = $3;
}
my ($thy_name, $path, $ext) = fileparse($thy_file, ".thy");
my $new_thy_name = $thy_name . "_Mirabelle";
my $new_thy_file = $output_path . "/" . $new_thy_name . $ext;


# setup

my $setup_thy_name = $thy_name . "_Setup";
my $setup_file = $output_path . "/" . $setup_thy_name . ".thy";
my $log_file = $output_path . "/" . $thy_name . ".log";

my @action_files;
my @action_names;
foreach (split(/:/, $actions)) {
  if (m/([^[]*)/) {
    push @action_files, "\"$mirabelle_home/Tools/mirabelle_$1.ML\"";
    push @action_names, $1;
  }
}
my $tools = "";
if ($#action_files >= 0) {
  $tools = "uses " . join(" ", @action_files);
}

open(SETUP_FILE, ">$setup_file") || die "Could not create file '$setup_file'";

print SETUP_FILE <<END;
theory "$setup_thy_name"
imports "$mirabelle_thy" "$mirabelle_theory"
$tools
begin

setup {* 
  Config.put_thy Mirabelle.logfile "$log_file" #>
  Config.put_thy Mirabelle.timeout $timeout #>
  Config.put_thy Mirabelle.verbose $verbose #>
  Config.put_thy Mirabelle.start_line $start_line #>
  Config.put_thy Mirabelle.end_line $end_line
*}

END

foreach (split(/:/, $actions)) {
  if (m/([^[]*)(?:\[(.*)\])?/) {
    my ($name, $settings_str) = ($1, $2 || "");
    $name =~ s/^([a-z])/\U$1/;
    print SETUP_FILE "setup {* Mirabelle_$name.invoke [";
    my $sep = "";
    foreach (split(/,/, $settings_str)) {
      if (m/\s*(.*)\s*=\s*(.*)\s*/) {
        print SETUP_FILE "$sep(\"$1\", \"$2\")";
        $sep = ", ";
      }
    }
    print SETUP_FILE "] *}\n";
  }
}

print SETUP_FILE "\nend";
close SETUP_FILE;


# modify target theory file

open(OLD_FILE, "<$thy_file") || die "Cannot open file '$thy_file'";
my @lines = <OLD_FILE>;
close(OLD_FILE);

my $thy_text = join("", @lines);
my $old_len = length($thy_text);
$thy_text =~ s/(theory\s+)\"?$thy_name\"?/$1"$new_thy_name"/g;
$thy_text =~ s/(imports)(\s+)/$1 "$setup_thy_name"$2/g;
die "No 'imports' found" if length($thy_text) == $old_len;

open(NEW_FILE, ">$new_thy_file") || die "Cannot create file '$new_thy_file'";
print NEW_FILE $thy_text;
close(NEW_FILE);

my $root_file = "$output_path/ROOT_$thy_name.ML";
open(ROOT_FILE, ">$root_file") || die "Cannot create file '$root_file'";
print ROOT_FILE "use_thy \"$output_path/$new_thy_name\";\n";
close(ROOT_FILE);


# run isabelle

open(LOG_FILE, ">$log_file");
print LOG_FILE "Run of $new_thy_file with:\n";
foreach $name (@action_names) {
  print LOG_FILE "  $name\n";
}
print LOG_FILE "\n\n";
close(LOG_FILE);

my $r = system "$isabelle_home/bin/isabelle-process " .
  "-e 'use \"$root_file\";' -q $mirabelle_logic" . "\n";


# cleanup

unlink $root_file;
unlink $setup_file;

exit $r;


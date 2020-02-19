#!perl -n
# have fun reading that :)
next unless /: (.*)/;$total++;if(/no impact/&&/detected/){$noimp_detect++;}elsif(/no effect/){$noimp_nodetect++}elsif(/timeout/||/crashed/){$crash++}elsif(/error/){$error++}elsif(/detected/){$impact_detect++;}else{die$_} }{ printf "%5.2f\\%% & %5.2f\\%% & %5.2f\\%% & %5.2f\\%% & %5.2f\\%% & %d \\", $impact_detect/$total*100, $error/$total*100, $noimp_detect/$total*100, $noimp_nodetect/$total*100, $crash/$total*100, $total

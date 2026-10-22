Update Perl file ---  /usr/lib/monitorix/ipmi.pm

Find this line:
my @data = <IN>;

Leave it in place and add immediately after add:
my $temp_occurrence = 0;
for my $line (@data) {
    if ($line =~ /^Temp\s+\|/) {
        $temp_occurrence++;
        my $name = $temp_occurrence == 1 ? "Temp1" : "Temp2";
        $line =~ s/^Temp(\s+\|)/$name$1/;
    }
}

Like this:
sub ipmi_update {
        my $myself = (caller(0))[3];
        my ($package, $config, $debug) = @_;
        my $rrd = $config->{base_lib} . $package . ".rrd";
        my $ipmi = $config->{ipmi};
        my $args = $ipmi->{extra_args} || "";
        my $use_nan_for_missing_data = lc($ipmi->{use_nan_for_missing_data} || "") eq "y" ? 1 : 0;

        my @sens;

        my $n;
        my $str;
        my $rrdata = "N";

        if(!open(IN, "ipmitool $args sdr |")) {
                logger("$myself: unable to execute 'ipmitool'. $!");
                return;
        }
        my @data = <IN>;
        my $temp_occurrence = 0;
        for my $line (@data) {
            if ($line =~ /^Temp\s+\|/) {
                $temp_occurrence++;
                my $name = $temp_occurrence == 1 ? "Temp1" : "Temp2";
                $line =~ s/^Temp(\s+\|)/$name$1/;
            }
        }
        close(IN);

        my @sensor_list = split(',', $ipmi->{list});



        ### END ###

Under the IPMI sensor Statistics and Temperatures Graph:

IPMI shows two CPU temperatures, but does not distinguish properly in the output Monitorix uses -
The --- /usr/lib/monitorix/ipmi.pm --- Perl code current code loops through every matching sensor and overwrites the previous reading.
We can prevent this by making the matching logic aware of the duplicate names.


$ ipmitool sdr | grep -E '^Temp[[:space:]]+\|'
Temp             | 73 degrees C      | ok
Temp             | 66 degrees C      | ok

Both shows up as "Temp"

Fix it as follow:

Update Monitorix config file ---  /etc/monitorix/monitorix.conf

Change -

0 = Inlet Temp, Exhaust Temp, Temp, Temp

To -

0 = Inlet Temp, Exhaust Temp, Temp1, Temp2

Like this:

# IPMI graph
# -----------------------------------------------------------------------------
<ipmi>
        list = Temperatures, Fans, Voltages, Current, Pwr Consumption
        <desc>
                0 = Inlet Temp, Exhaust Temp, Temp1, Temp2
                1 = Fan1 RPM, Fan2 RPM, Fan3 RPM, Fan4 RPM, Fan5 RPM, Fan6 RPM
                2 = Voltage 1, Voltage 2
                3 = Current 1, Current 2
                4 = Pwr Consumption
        </desc>
        <units>
                0 = degrees C
                1 = RPM
                2 = Volts
                3 = Amps
                4 = Watts
        </units>


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

#!/usr/bin/perl

use English qw( -no_match_vars );
use Parallel::ForkManager;
use XML::Twig;
use XML::Parser;
use POSIX;
use File::Path qw(make_path);
use File::Spec::Functions;
use File::Temp qw/ tempfile /;
select(STDERR);
$| = 1;
select(STDOUT);
$| = 1;

my $STORAGE_DIR         = '/opt/opennms/tmp/emc-unisphere';
my $STATS_XSL           = '/opt/opennms/etc/xml-datacollection/emc-unisphere.xsl';
my $NAVISECCLI_CMD      = '/opt/Navisphere/bin/naviseccli';
my $NAVISECCLI_USER     = 'admin';
my $NAVISECCLI_PASSWORD = '********';
my @NAVISPHERE_HOST_IPADDRS = qw( );
my $opt_compress        = 0;

if ( !-x $NAVISECCLI_CMD ) {
    die "Missing EMC Unisphere/Navisphere naviseccli command: /opt/Navisphere/bin/naviseccli\n";
}
if ( !-x '/usr/bin/Xalan' ) {
    die "Missing Xalan xsl processor\n";
}
if ( !-f $STATS_XSL ) {
    die "Missing $STATS_XSL xslt file.\n";
}
if ( !-d $STORAGE_DIR ) {
    make_path( $STORAGE_DIR );    
}

#
# Subroutines
#

sub get_timestamp {
    return POSIX::strftime( "%Y-%m-%d %H:%M:%S", localtime($BASETIME) );
}

sub parse_speed {
    my $text = shift;
    if ( $text =~ /^(\d+)Kbps$/ ) {
        return $1 * 1_000;
    }
    if ( $text =~ /^(\d+)Mbps$/ ) {
        return $1 * 1_000_000;
    }
    if ( $text =~ /^(\d+)Gbps$/ ) {
        return $1 * 1_000_000_000;
    }
    if ( $text =~ /^(\d+)Tbps$/ ) {
        return $1 * 1_000_000_000_000;
    }

    return $text;
}

##############################################################################
#
# MAIN
#
##############################################################################

my %diskignore = (
    'Vendor Id'                => 0,
    'Product Id'               => 0,
    'Product Revision'         => 0,
    'Type'                     => 0,
    'State'                    => 0,
    'Hot Spare'                => 0,
    'Prct Rebuilt'             => 0,
    'Prct Bound'               => 0,
    'Serial Number'            => 0,
    'Sectors'                  => 0,
    'Capacity'                 => 0,
    'Private'                  => 0,
    'Bind Signature'           => 0,
    'Number of Luns'           => 0,
    'Clariion Part Number'     => 0,
    'Request Service Time'     => 0,
    'Clariion TLA Part Number' => 0,
    'User Capacity'            => 0,
    'Remapped Sectors'         => 0,
    'Read Retries'             => 0,
    'Write Retries'            => 0,
    'Number of Reads'          => 0,
    'Number of Writes'         => 0,

    #  'Lun' => 0,
);
my %lunignore = (
    'Variable length prefetching'                              => 0,
    'Prefetched data retained'                                 => 0,
    'Read cache configured according to specified parameters.' => 0,
    'Minimum latency reads'                                    => 0,
    'State'                                                    => 0,
    'Current owner'                                            => 0,
    'Auto-trespass'                                            => 0,
    'Auto-assign'                                              => 0,
    'Write cache'                                              => 0,
    'Read cache'                                               => 0,
    'Read Hit Ratio'                                           => 0,
    'Write Hit Ratio'                                          => 0,
    'Default Owner'                                            => 0,
    'Rebuild Priority'                                         => 0,
    'Verify Priority'                                          => 0,
    'Usage'                                                    => 0,
    'Snapshots List'                                           => 0,
    'MirrorView Name if any'                                   => 0,

    #  'Is Private' => 0,
);
my %metalunignore = (
    'Current State' => 0,
    'Current Owner' => 0,
    'Default Owner' => 0,
    'Auto-assign'   => 0,
    'Auto-trespass' => 0,
    'Is Redundant'  => 0,
);
my %addxml = (
    'getcache' => '-Xml',
    'getdisk'  => '-Xml',
    'getrg'    => '-Xml',
    'getsp'    => '-Xml',
    'getlun'   => '-Xml',
    'metalun'  => '-Xml',
);

my %code = (
    getsp => sub {
        my $twig    = shift;
        my $txtfile = shift;

        my $start_time = time;
        printf "time[%d]: >>>> getsp ( twig )\n", $start_time;
        $twig->parsefile($txtfile);
        my $end_time = time;
        printf "time[%d]: >>>> parsed file '%s' in %d seconds\n", $end_time, $txtfile, $end_time - $start_time;

        my $root = XML::Twig::Elt->new( 'unisphere' => { 'timestamp' => get_timestamp() } );

        my $parent = $twig->get_xpath( '/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE', 0 );

        # print "<<<< PARENT >>>>\n"; $parent->print('indented'); print "\n";
        my $sp = undef;
        foreach my $elt ( $parent->find_nodes('VALUE/PARAMVALUE') ) {
            $elt->del_att('TYPE');
            $elt->set_text( $elt->first_child_trimmed_text('VALUE') );
            if ( $elt->att('NAME') =~ /^SP [AB]$/ ) {
                $sp = XML::Twig::Elt->new( 'storageprocessor' => { name => $elt->att('NAME') } );
                $elt->cut;
                $sp->paste( 'last_child' => $root );
                next;
            }
            if ( defined $sp ) {
                $elt->cut;
                $elt->set_tag('param');
                $elt->del_att('TYPE');
                $elt->lc_attnames();
                $elt->paste( 'last_child' => $sp );
            }
        }
        $twig->set_root($root);
    },
    getrg => sub {
        my $twig    = shift;
        my $txtfile = shift;
        $twig->parsefile($txtfile);
        printf ">>>> getrg ( twig )\n";

        my $root = XML::Twig::Elt->new( 'unisphere' => { 'timestamp' => get_timestamp() } );

        my $parent = $twig->get_xpath( '/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE', 0 );
        my $value = $parent->get_xpath( './VALUE', 0 );

        # print "<<<< PARENT >>>>\n"; $parent->print('indented'); print "\n";
        my $rg = undef;
        foreach my $elt ( $value->find_nodes('./PARAMVALUE') ) {

            # $elt->print; print "\n";
            if ( $elt->att('NAME') eq "RaidGroup ID" ) {
                $rg = XML::Twig::Elt->new( 'raidgroup' => { id => $elt->first_child_trimmed_text('VALUE') } );
                $elt->set_tag('param');
                $elt->del_att('TYPE');
                $elt->set_text( $elt->first_child_trimmed_text );
                $elt->cut;
                $elt->lc_attnames();
                $rg->paste( 'last_child' => $root );
                $elt->paste( 'last_child' => $rg );
                next;
            }
            if ( defined $rg ) {
                $elt->del_att('TYPE');
                my $text = $elt->first_child_trimmed_text;
                if ( $elt->att('NAME') eq "List of disks" ) {
                    $text =~ s{Bus\s+(\d+)\s+Enclosure\s+(\d+)\s+Disk\s+(\d+)(\s*)}{b$1.e$2.d$3$4}gms;
                }
                if ( $elt->att('NAME') eq "List of luns" ) {
                    $text =
                      join( " ", sort( { $a <=> $b } split( /\s+/, $text ) ) );
                }
                $elt->set_text($text);
                $elt->set_tag('param');

                $elt->cut;
                $elt->lc_attnames();
                $elt->paste( 'last_child' => $rg );
            }
        }

        $twig->set_root($root);
    },
    getdisk => sub {
        my $twig    = shift;
        my $txtfile = shift;
        $twig->parsefile($txtfile);
        printf ">>>> getdisk ( twig )\n";

        my $root = XML::Twig::Elt->new( 'unisphere' => { 'timestamp' => get_timestamp() } );

        my $parent = $twig->get_xpath( '/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE', 0 );
        my $value = $parent->get_xpath( './VALUE', 0 );

        # print "<<<< PARENT >>>>\n"; $parent->print('indented'); print "\n";
        my $disk = undef;
        foreach my $elt ( $value->find_nodes('./PARAMVALUE') ) {

            # $elt->print; print "\n";
            if ( $elt->att('NAME') =~ /^Bus\s+(\d+)\s+Enclosure\s+(\d+)\s+Disk\s+(\d+)$/ ) {
                my $b    = $1;
                my $e    = $2;
                my $d    = $3;
                my $name = 'b' . $b . '.e' . $e . '.d' . $d;
                $disk = XML::Twig::Elt->new(
                    'disk' => {
                        name            => $name,
                        bus             => $b,
                        enclosure       => $e,
                        drive           => $d,
                        speed           => 0,
                        'maximum-speed' => 0,
                        'drive-type'    => '',
                        'raid-group'    => '',
                    }
                );
                $elt->purge;
                $disk->paste( 'last_child' => $root );

                #$elt->paste('last_child' => $disk);
                next;
            }
            if ( defined $disk ) {
                if ( !exists $diskignore{ $elt->att('NAME') } ) {
                    $elt->set_tag('param');
                    $elt->del_att('TYPE');
                    my $text = $elt->first_child_trimmed_text;
                    if ( $elt->att('NAME') eq 'Current Speed' ) {
                        $disk->set_att( 'speed' => parse_speed($text) );
                        next;
                    }
                    if ( $elt->att('NAME') eq 'Maximum Speed' ) {
                        $disk->set_att( 'maximum-speed' => parse_speed($text) );
                        next;
                    }
                    if ( $elt->att('NAME') eq 'Drive Type' ) {
                        $disk->set_att( 'drive-type' => $text );
                        next;
                    }
                    if ( $elt->att('NAME') eq 'Raid Group ID' ) {
                        $disk->set_att( 'raid-group' => $text );
                        next;
                    }
                    $elt->set_text($text);
                    $elt->lc_attnames();
                    $elt->cut;
                    $elt->paste( 'last_child' => $disk );
                }
            }
        }
        $twig->set_root($root);
    },
    getlun => sub {
        my $twig    = shift;
        my $txtfile = shift;

        my $root = XML::Twig::Elt->new( 'unisphere' => { 'timestamp' => get_timestamp() } );

        my $pre_process_cmd = "/usr/bin/Xalan '$txtfile' $STATS_XSL > '$txtfile.converted'";
        my $start_time      = time;
        printf "time[%d]: pre_process_cmd: %s\n", $start_time, $pre_process_cmd;
        system($pre_process_cmd);
        my $end_time = time;
        printf "time[%d]: >>>> pre-processed file '%s' in %d seconds\n", $end_time, $txtfile, $end_time - $start_time;

        $start_time = time;
        printf "time[%d]: >>>> getlun ( twig )\n", $start_time;
        $twig->parsefile( $txtfile . '.converted' );
        $end_time = time;
        printf "time[%d]: >>>> parsed file '%s' in %d seconds\n", $end_time, $txtfile, $end_time - $start_time;
        unlink( $txtfile . '.converted' );

        my $parent = $twig->get_xpath( '/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE', 0 );
        my $value = $parent->get_xpath( './VALUE', 0 );
        my $lun = undef;
        foreach my $elt ( $value->find_nodes('./PARAMVALUE') ) {
            if ( $elt->att('NAME') eq 'LOGICAL UNIT NUMBER' ) {
                $lun = XML::Twig::Elt->new(
                    'lun' => {
                        'id'         => $elt->text,
                        'private'    => 'YES',
                        'raid-type'  => 'N/A',
                        'raid-group' => '0'
                    }
                );
                $lun->paste( 'last_child' => $root );
                next;
            }
            if ( defined $lun ) {
                if ( !exists $lunignore{ $elt->att('NAME') } ) {
                    my $text = $elt->first_child_trimmed_text;
                    if ( $elt->att('NAME') eq 'Is Private' ) {
                        $lun->set_att( 'private' => $text );
                        next;
                    }
                    if ( $elt->att('NAME') eq 'RAID Type' ) {
                        $lun->set_att( 'raid-type', $text );
                        next;
                    }
                    if ( $elt->att('NAME') eq 'RAIDGroup ID' ) {
                        $lun->set_att( 'raid-group', $text );
                        next;
                    }
                    $elt->set_tag('param');
                    $elt->del_att('TYPE');
                    $elt->set_text($text);
                    $elt->lc_attnames();
                    $elt->cut;
                    $elt->paste( 'last_child' => $lun );
                }
            }
        }

        foreach my $elt ( $root->find_nodes('./lun[@private="YES" or @raid-type="N/A"]') ) {
            $elt->cut;
        }

        foreach my $elt ( $root->find_nodes('./lun[@raid-type="N/A"]') ) {
            $elt->cut;
        }

        $start_time = time;
        printf "time[%d]: >>>> sorting children\n", $start_time;
        $root->sort_children(
            sub {
                $_[0]->{'att'}->{'id'} + $_[0]->{'att'}->{'private'} * 1_000_000;
            },
            'type' => 'numeric'
        );
        $end_time = time;
        printf "time[%d]: >>>> sorted children in %d seconds\n", $end_time, $end_time - $start_time;

        $twig->set_root($root);
    },
    'metalun -list -name -percentexp -totalusercap -actualusercap -rhist -whist -rwr -brw' => sub {
        my $twig    = shift;
        my $txtfile = shift;

        my $root = XML::Twig::Elt->new( 'unisphere' => { 'timestamp' => get_timestamp() } );

        my $start_time = time;
        printf "time[%d]: >>>> metalun ( twig )\n", $start_time;
        $twig->parsefile($txtfile);
        my $end_time = time;
        printf "time[%d]: >>>> parsed file '%s' in %d seconds\n", $end_time, $txtfile, $end_time - $start_time;

        my $parent = $twig->get_xpath( '/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE', 0 );
        my $metalun = undef;
        foreach my $elt ( $parent->find_nodes('./PARAMVALUE') ) {
            if ( $elt->att('NAME') eq ' ' ) { $elt->cut; next; }
            if ( $elt->att('NAME') eq 'MetaLUN Number' ) {
                $metalun = XML::Twig::Elt->new( 'metalun' => { 'id' => $elt->text, } );
                $metalun->paste( 'last_child' => $root );
                next;
            }
            if ( defined $metalun ) {
                if ( !exists $metalunignore{ $elt->att('NAME') } ) {
                    my $text = $elt->first_child_trimmed_text;
                    if ( $elt->att('NAME') eq 'Total User Capacity (Blocks/Megabytes)' ) {
                        my @caps = split( "/", $text );
                        XML::Twig::Elt->new(
                            'param' => { 'name' => 'Total User Capacity (Blocks)' },
                            $caps[0]
                        )->paste( 'last_child' => $metalun );
                        XML::Twig::Elt->new(
                            'param' => { 'name' => 'Total User Capacity (Megabytes)' },
                            $caps[1]
                        )->paste( 'last_child' => $metalun );
                        next;
                    }
                    if ( $elt->att('NAME') eq 'Actual User Capacity (Blocks/Megabytes)' ) {
                        my @caps = split( "/", $text );
                        XML::Twig::Elt->new(
                            'param' => { 'name' => 'Actual User Capacity (Blocks)' },
                            $caps[0]
                        )->paste( 'last_child' => $metalun );
                        XML::Twig::Elt->new(
                            'param' => { 'name' => 'Actual User Capacity (Megabytes)' },
                            $caps[1]
                        )->paste( 'last_child' => $metalun );
                        next;
                    }
                    $elt->set_tag('param');
                    $elt->del_att('TYPE');
                    $elt->set_text($text);
                    $elt->lc_attnames();
                    $elt->cut;
                    $elt->paste( 'last_child' => $metalun );
                }
            }
        }

        $twig->set_root($root);
    },
    'port -list -sp -all' => sub {
        my $twig    = shift;
        my $txtfile = shift;
        my $root    = $twig->root;
        if ( !defined $root ) {
            $root = XML::Twig::Elt->new( 'unisphere' => { 'timestamp' => get_timestamp() } );
            $twig->set_root($root);
        }

        my $current_sp    = undef;
        my $current_port  = undef;
        my $current_stats = undef;

        open( my $fh, '<', $txtfile )
          or die "Could not open file '$txtfile' for reading...\n";
        while (<$fh>) {
            chomp;
            if (/^Total number of initiators:\s+(\d+)/) {
                XML::Twig::Elt->new( 'total-initiators' => $1 )->paste( 'last_child' => $root );
                next;
            }
            if (/^SP Name:\s+(.*?)\s*$/) {
                $current_sp = $1;
                next;
            }
            if ( defined $current_sp && /^SP Port ID:\s+(\d+)\s*$/ ) {
                my $port_id = $1;
                my $name    = $current_sp . '-Port ' . $port_id;
                $current_port = $root->get_xpath( '/unisphere/port[@name="' . $name . '"]', 0 );
                if ( !defined $current_port ) {
                    $current_port = XML::Twig::Elt->new(
                        'port' => {
                            'name' => $name,
                            sp     => $current_sp,
                            port   => $port_id,
                        }
                    )->paste( 'last_child' => $root );
                }
                $current_stats = $current_port->get_xpath( './stats', 0 );
                if ( !defined $current_stats ) {
                    $current_stats = XML::Twig::Elt->new('stats')->paste( 'last_child' => $current_port );
                }

                next;
            }
            if ( defined $current_port ) {
                if (/^Registered Initiators:\s+(\d+)\s*$/) {
                    XML::Twig::Elt->new( 'param' => { 'id' => 'Registered Initiators', value => $1 } )
                      ->paste( 'last_child' => $current_port );
                }
                elsif (/^Logged\-In Initiators:\s+(\d+)\s*$/) {
                    XML::Twig::Elt->new( 'param' => { 'id' => 'Logged-In Initiators', value => $1 } )
                      ->paste( 'last_child' => $current_port );
                }
                elsif (/^Not Logged\-In Initiators:\s+(\d+)\s*$/) {
                    XML::Twig::Elt->new( 'param' => { 'id' => 'Not Logged-In Initiators', value => $1 } )
                      ->paste( 'last_child' => $current_port );
                }
                elsif (/^SP UID:\s+(.*?)\s*$/) {
                    XML::Twig::Elt->new( 'param' => { 'id' => 'SP UID', value => $1 } )
                      ->paste( 'last_child' => $current_port );
                }
                elsif (/^Link Status:\s+(.*?)\s*$/) {
                    XML::Twig::Elt->new( 'param' => { 'id' => 'Link Status', value => $1 } )
                      ->paste( 'last_child' => $current_port );
                }
                elsif (/^Port Status:\s+(.*?)\s*$/) {
                    XML::Twig::Elt->new( 'param' => { 'id' => 'Port Status', value => $1 } )
                      ->paste( 'last_child' => $current_port );
                }
                elsif (/^Switch Present:\s+(.*?)\s*$/) {
                    XML::Twig::Elt->new( 'param' => { 'id' => 'Switch Present', value => $1 } )
                      ->paste( 'last_child' => $current_port );
                }
                elsif (/^Switch UID:\s+(.*?)\s*$/) {
                    XML::Twig::Elt->new( 'param' => { 'id' => 'Switch UID', value => $1 } )
                      ->paste( 'last_child' => $current_port );
                }
                elsif (/^SP Source ID:\s+(.*?)\s*$/) {
                    XML::Twig::Elt->new( 'param' => { 'id' => 'SP Source ID', value => $1 } )
                      ->paste( 'last_child' => $current_port );
                }
                elsif (/^ALPA Value:\s+(.*?)\s*$/) {
                    XML::Twig::Elt->new( 'param' => { 'id' => 'ALPA Value', value => $1 } )
                      ->paste( 'last_child' => $current_port );
                }
                elsif (/^Speed Value\s+:\s+(.*?)\s*$/) {
                    my $speed = parse_speed($1);
                    XML::Twig::Elt->new( 'param' => { 'id' => 'Speed Value', value => $speed } )
                      ->paste( 'last_child' => $current_port );
                }
                elsif (/^Auto Negotiable\s+:\s+(.*?)\s*$/) {
                    XML::Twig::Elt->new( 'param' => { 'id' => 'Auto Negotiable', value => $1 } )
                      ->paste( 'last_child' => $current_port );
                }
                elsif (/^Requested Value\s*:\s+(.*?)\s*$/) {
                    XML::Twig::Elt->new( 'param' => { 'id' => 'Requested Value', value => $1 } )
                      ->paste( 'last_child' => $current_port );
                }
                elsif (/^MAC Address\s*:\s+(.*?)\s*$/) {
                    XML::Twig::Elt->new( 'param' => { 'id' => 'MAC Address', value => $1 } )
                      ->paste( 'last_child' => $current_port );
                }
                elsif (/^SFP State\s*:\s+(.*?)\s*$/) {
                    XML::Twig::Elt->new( 'param' => { 'id' => 'SFP State', value => $1 } )
                      ->paste( 'last_child' => $current_port );
                }
                next;
            }
            if ( defined $current_stats ) {
                if (/^Reads\s*:\s+(.*?)\s*$/) {
                    $current_stats->set_att( 'reads' => $1 );
                }
                elsif (/^Writes\s*:\s+(.*?)\s*$/) {
                    $current_stats->set_att( 'writes' => $1 );
                }
                elsif (/^Blocks Read\s*:\s+(.*?)\s*$/) {
                    $current_stats->set_att( 'blocks-read' => $1 );
                }
                elsif (/^Blocks Written\s*:\s+(.*?)\s*$/) {
                    $current_stats->set_att( 'blocks-written' => $1 );
                }
                elsif (/^Queue Full\/Busy\s*:\s+(.*?)\s*$/) {
                    $current_stats->set_att( 'queue-full-busy' => $1 );
                }
                next;
            }

            if (/^\s*$/) {
                $current_sp = $current_port = $current_stats = undef;
                next;
            }
        }
        close($fh);
    },
    getcache => sub {
        my $twig    = shift;
        my $txtfile = shift;
        $twig->parsefile($txtfile);

        my $root = XML::Twig::Elt->new( 'unisphere' => { 'timestamp' => get_timestamp() } );

        my $parent = $twig->get_xpath( '/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE', 0 );

        # print "<<<< PARENT >>>>\n"; $parent->print('indented'); print "\n";
        my $value = $parent->get_xpath( './VALUE', 0 );
        foreach my $elt ( $value->find_nodes('./PARAMVALUE') ) {
            my $name = $elt->att('NAME');
            $name =~ s{\s+$}{};
            $name =~ s{\s+=$}{};
            $elt->set_tag('param');
            $elt->set_att( 'NAME' => $name );
            $elt->del_att('TYPE');
            $elt->set_text( $elt->first_child_trimmed_text );
            $elt->lc_attnames();
            $elt->cut;
            $elt->paste( 'last_child' => $root );
        }

        $twig->set_root($root);
    },
);

my %retrieved_responses = ();                             # for collecting responses
my $pm                  = new Parallel::ForkManager(4);
$pm->run_on_finish(
    sub {
        my ( $pid, $exit_code, $ident, $exit_signal, $core_dump, $data_structure_reference ) = @_;

        # see what the child sent us, if anything
        if ( defined($data_structure_reference) ) {       # test rather than assume child sent anything
            my $reftype = ref($data_structure_reference);

            # we can also collect retrieved data structures for processing after all children have exited
            $retrieved_responses{$ident} = $data_structure_reference;
        }
        else {
            print qq[ident "$ident" did not send anything.\n\n];
        }
    }
);

my @gets = (
    'getcache', 'getdisk', 'getrg', 'port -list -sp -all',
    'getlun', 'metalun -list -name -percentexp -totalusercap -actualusercap -rhist -whist -rwr -brw',
);

my $t0_time = time;
foreach my $get (@gets) {
    my $firstword = $get;
    $firstword =~ s/\s+.*$//;

    foreach my $host (@NAVISPHERE_HOST_IPADDRS) {
        $pm->start( join( "/", $host, $firstword ) ) && next;
        my ( undef, $txtfile ) = tempfile( 'unisphere-data-file.XXXXXXXXXX', UNLINK => 0, TMPDIR => 1 );

        my $getcmd =
            $NAVISECCLI_CMD
          . ' -User '
          . $NAVISECCLI_USER
          . ' -Password '
          . $NAVISECCLI_PASSWORD
          . qq[ -Scope 0 -Address $host $addxml{$firstword} $get >$txtfile];
        my $start_time = time;
        printf "time[%d]: cmd: %s\n", $start_time, $getcmd;
        system($getcmd);
        my $end_time = time;
        printf "time[%d]: cmd finished in %d seconds\n", $end_time, $end_time - $start_time;

        $pm->finish( 0, { 'host' => $host, 'get' => $get, 'input_file' => $txtfile, } );
    }
}

$pm->wait_all_children;
my $t1_time = time;
printf "time[%d]: finished gathering input data in %d seconds.\n", $t1_time, $t1_time - $t0_time;

$pm->set_max_procs(4);
$pm->run_on_finish( sub { } );

foreach my $ident ( sort keys %retrieved_responses ) {
    my $ref = $retrieved_responses{$ident};

    $pm->start($ident) && next;

    my $host      = $ref->{'host'};
    my $get       = $ref->{'get'};
    my $firstword = $get;
    $firstword =~ s/\s+.*$//;

    my $output_file = catfile( $STORAGE_DIR, $host . '.' . $firstword . '.' . $BASETIME );

    if ( exists $code{$get} && ref $code{$get} eq "CODE" ) {
        my $twig = XML::Twig->new();
        $twig->set_encoding('utf-8');
        $twig->set_xml_version('1.0');

        my $start_time = time;
        printf "time[%d]: code chunk '%s' starting processing file '%s'\n",
          $start_time, $firstword, $ref->{'input_file'};
        &{ $code{$get} }( $twig, $ref->{'input_file'} );
        my $end_time = time;
        printf
          "time[%d]: code chunk '%s' finished processing file '%s' in %d seconds\n",
          $end_time, $firstword, $ref->{'input_file'}, $end_time - $start_time;

        $twig->print_to_file( $output_file . '.xml', 'pretty_print' => 'none', );
    }
    else {
        system( 'cp', $ref->{'input_file'}, $output_file . '.xml' );
    }

    unlink( $ref->{'input_file'} );

    $pm->finish(0);
}

$pm->wait_all_children;

$end_time = time;
printf "time[%d]: script finished in %d seconds.\n", $end_time, $end_time - $BASETIME;

my @files = glob( $STORAGE_DIR . '/*xml' ), glob( $STORAGE_DIR . '/*txt' );
if ($opt_compress) {
    system('gzip --best $STORAGE_DIR/*xml $STORAGE_DIR/*txt 2>/dev/null');
}
foreach my $file (@files) {
    my $real = $file;
    $real =~ s{ \. \d+ \.(xml|txt) $ }{\.$1}gxms;
    if ( $real eq $file ) { next; }
    if ( -f $file ) {
        unlink($real);
        symlink( $file, $real );
    }
    if ( -f $file . '.gz' ) {
        unlink( $real . '.gz' );
        symlink( $file . '.gz', $real . '.gz' );
    }
}

exit(0);
__END__

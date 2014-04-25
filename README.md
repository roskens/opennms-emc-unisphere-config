OpenNMS - EMC Unisphere datacollection

This requires the opennms xml-datacollection plugin installed.
This also requires the EMC naviseccli command line utility to
be installed.

Copy all files to their respective paths under $OPENNMS_HOME/.

Edit bin/unisphere-stats-xml.pl and modify these lines per
your environment:
    my $NAVISECCLI_USER     = 'admin';
    my $NAVISECCLI_PASSWORD = '********';
    my @NAVISPHERE_HOST_IPADDRS    = qw( );

The array @NAVISPHERE_HOST_IPADDRS should contain the ip addresses
of your EMC Unisphere SPs.

Run the script and it should create xml output files for each SP
in /opt/opennms/tmp/emc-unisphere.

You can set this script to run via a cron job. Gathering the disk,
lun and metalun metrics requires a fair amount of time. In our
environment, the script takes about 90 seconds to run, so we
kept to the standard 5 minute datacollection period.

For OpenNMS:
1. Edit $OPENNMS_HOME/etc/datacollection-config.xml and add
 include-collection for 'EMC-Unisphere' so the resource types get defined.
2. Edit $OPENNMS_HOME/etc/xml-datacollection-config.xml and
   add the contents from etc/xml-datacollection-config.xml.part.
3. Add a service to your EMC SP nodes for this XmlCollector.
4. Add a service entry in collectd-configuration.xml for this XmlCollector
   service.

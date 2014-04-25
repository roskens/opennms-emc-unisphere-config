<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  >
  <xsl:output method="xml" indent="yes"/>
  <xsl:strip-space elements="*" />

  <!-- XSL Stylesheet that will strip out unneeded data from the kstat-snmp output. -->

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>

  <!-- list of xpaths to strip out -->
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Prefetch size (blocks) ']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Prefetch multiplier ']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Segment size (blocks) ']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Segment multiplier ']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Maximum prefetch (blocks) ']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Prefetch Disable Size (blocks) ']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Prefetch idle count ']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Variable length prefetching']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Prefetched data retained']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Read cache configured according to specified parameters.']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Minimum latency reads']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Element Size']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Prefetching']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Read Hit Ratio']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Write Hit Ratio']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Read cache misses']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Auto-trespass']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Auto-assign']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Write cache']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Read cache']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Idle Threshold']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Idle Delay Time']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Rebuild Priority']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Verify Priority']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Prct Reads Forced Flushed']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Prct Writes Forced Flushed']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Offset']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Write Aside Size']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Usage']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Snapshots List']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='MirrorView Name if any']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[substring(@NAME, 1, 4) = 'Bus ']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[substring(@NAME, 1, 4) = 'Bus ' and substring(@NAME, string-length(@NAME)-12+1) = 'Queue Length']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[substring(@NAME, 1, 4) = 'Bus ' and substring(@NAME, string-length(@NAME)-16+1) = 'Hard Read Errors']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[substring(@NAME, 1, 4) = 'Bus ' and substring(@NAME, string-length(@NAME)-17+1) = 'Hard Write Errors']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[substring(@NAME, 1, 4) = 'Bus ' and substring(@NAME, string-length(@NAME)-16+1) = 'Soft Read Errors']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[substring(@NAME, 1, 4) = 'Bus ' and substring(@NAME, string-length(@NAME)-17+1) = 'Soft Write Errors']" />

  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Reads']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Writes']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Blocks Read']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Blocks Written']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Queue Max']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Queue Avg']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Avg Service Time']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Prct Idle']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Prct Busy']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Remapped Sectors']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Read Retries']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='Write Retries']" />
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE/@TYPE" />

<!--
  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE[@NAME='LOGICAL UNIT NUMBER']">
  <PARAMVALUE NAME="LOGICAL UNIT NUMBER"><xsl:value-of select="text()"/></PARAMVALUE>
  <lun id="{VALUE/text()}"/>
  </xsl:template>
-->

  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/PARAMVALUE/VALUE/PARAMVALUE/VALUE">
    <xsl:value-of select="text()" />
  </xsl:template>


  <xsl:template match="/CIM/MESSAGE/SIMPLERSP/METHODRESPONSE/RETURNVALUE" />

<!--
if ($_->att('NAME') =~ /^Bus\s\d+\s+Enclosure\s+\d+\s+Disk\s+\d+\s+(Queue Length|(Hard|Soft) (Read|Write) Errors)$/) {
-->

</xsl:stylesheet>

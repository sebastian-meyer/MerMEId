<?xml version="1.0" encoding="UTF-8" ?>
<xsl:transform xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	       xmlns="http://www.music-encoding.org/ns/mei" 
	       xmlns:m="http://www.music-encoding.org/ns/mei" 
	       xmlns:xl="http://www.w3.org/1999/xlink"
	       xmlns:xlink="http://www.w3.org/1999/xlink"
	       xmlns:exsl="http://exslt.org/common"
	       xmlns:dyn="http://exslt.org/dynamic"
	       extension-element-prefixes="dyn exsl"
	       exclude-result-prefixes="xl xlink xsl m"
	       version="1.0">

  <xsl:output method="xml"
	      encoding="UTF-8"
	      omit-xml-declaration="yes" />
  <xsl:strip-space elements="*" />
  <xsl:variable name="empty_doc" select="document('/editor/forms/mei/model/empty_doc.xml')" />
  
  <xsl:template match="m:mei">
    <!-- make a copy with an extra meiHead from the empty model document -->
    <xsl:variable name="janus">
      <mei xmlns="http://www.music-encoding.org/ns/mei"
        xmlns:xl="http://www.w3.org/1999/xlink">
        <xsl:copy-of select="@*"/>
        <xsl:copy-of select="$empty_doc/m:mei/m:meiHead"/>
        <xsl:copy-of select="@*|*"/>
      </mei>
    </xsl:variable>
    <!-- make it a nodeset -->
    <xsl:variable name="janus_nodeset" select="exsl:node-set($janus)"/>
    <!-- start copying from model -->
    <xsl:apply-templates select="$janus_nodeset" mode="second_run"/>
  </xsl:template>
  
  <xsl:template match="m:mei" mode="second_run">
    <!-- transform original header and remove the temporary model header -->
    <mei xmlns="http://www.music-encoding.org/ns/mei"
      xmlns:xl="http://www.w3.org/1999/xlink">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="m:meiHead[2]" mode="header"/>
      <xsl:apply-templates select="m:music"/>
    </mei>
  </xsl:template>
  
  <!-- the actual copying from the model header to the data header -->
  <xsl:template match="*" mode="header">
    <!-- build an xpath string to locate the corresponding node in the model header -->
    <xsl:variable name="path"><xsl:for-each 
      select="ancestor-or-self::*">/<xsl:if 
        test="namespace-uri()='http://www.music-encoding.org/ns/mei'">m:</xsl:if><xsl:if 
          test="namespace-uri()='http://www.tei-c.org/ns/1.0'">t:</xsl:if><xsl:value-of 
            select="name()"/><xsl:if test="local-name()='meiHead'">[1]</xsl:if></xsl:for-each>
    </xsl:variable>
    <xsl:element name="{name()}" namespace="{namespace-uri()}">
      <xsl:copy-of select="@*"/>
      <xsl:variable name="model" select="dyn:evaluate($path)"/>
      <xsl:variable name="data_node" select="."/>
      <!-- Add all missing empty attributes. Ignores non-empty attributes in the model in order not to inject unwanted data -->
      <xsl:for-each select="$model/@*[.='']">
        <xsl:variable name="this_att" select="local-name()"/>
        <xsl:if test="not($data_node/@*[local-name()=$this_att])"><xsl:attribute name="{name()}"/></xsl:if>
      </xsl:for-each>
      <!-- Add all missing child elements (to nodes without text - to avoid mixed content)-->
      <!-- Disabled; has to be aware of the order of elements (and other details...) before it is useable  
        <xsl:for-each select="$model/*">
        <xsl:variable name="element" select="name()"/>
        <xsl:if test="count($data_node/*[local-name()=$element])=0">
        <xsl:copy-of select="."/>
        </xsl:if>
        </xsl:for-each>-->
      <xsl:apply-templates mode="header"/>
    </xsl:element>
  </xsl:template>    

  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

</xsl:transform>

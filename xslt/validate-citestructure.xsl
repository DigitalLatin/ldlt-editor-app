<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:err="http://www.w3.org/2005/xqt-errors"
  xmlns:v="urn:ldlt:validation"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="xs err v">

  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:mode on-no-match="shallow-skip"/>

  <xsl:template match="/">
    <xsl:variable name="reports" as="element(v:issue)*">
      <xsl:apply-templates select="//refsDecl/citeStructure" mode="check">
        <xsl:with-param name="contexts" select="/*"/>
      </xsl:apply-templates>
    </xsl:variable>
    <xsl:text>LDLT citation structure validation&#10;</xsl:text>
    <xsl:for-each select="$reports">
      <xsl:value-of select="concat(upper-case(@severity), ' [', @kind, '] ', @location, '&#10;  ', @message, '&#10;')"/>
    </xsl:for-each>
    <xsl:value-of select="concat('Summary: ', count($reports[@severity='error']), ' error(s), ', count($reports[@severity='warning']), ' warning(s).', '&#10;')"/>
    <xsl:if test="exists($reports[@severity='error'])">
      <xsl:text>VALIDATION FAILED: Correct the errors listed above.&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="citeStructure" mode="check">
    <xsl:param name="contexts" as="element()*" required="yes"/>
    <xsl:variable name="structure" select="."/>
    <xsl:variable name="expression" select="string(@match)"/>
    <xsl:variable name="location" select="concat('citeStructure[', count(preceding::citeStructure) + 1, ']')"/>

    <!-- Evaluate the XPath separately against every matching parent context. -->
    <xsl:variable name="results" as="item()*">
      <xsl:for-each select="$contexts">
        <xsl:try>
          <xsl:evaluate xpath="$expression"
            context-item="."
            _xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>
          <xsl:catch>
            <v:error detail="{$err:description}"/>
          </xsl:catch>
        </xsl:try>
      </xsl:for-each>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="empty($contexts)">
        <v:issue severity="warning" kind="unreachable" location="{$location}"
          message="Parent citeStructure matched nothing; this child cannot be evaluated."/>
      </xsl:when>
      <xsl:when test="exists($results[. instance of element(v:error)])">
        <v:issue severity="error" kind="invalid-match" location="{$location}"
          message="Invalid @match XPath: {$expression}. {$results[. instance of element(v:error)][1]/@detail}"/>
      </xsl:when>
      <xsl:when test="empty($results[not(. instance of element(v:error))])">
        <v:issue severity="error" kind="unmatched" location="{$location}"
          message="@match selected no elements: {$expression}"/>
      </xsl:when>
    </xsl:choose>

    <xsl:variable name="matched" as="element()*"
      select="$results[. instance of element()
      and not(. instance of element(v:error))]"/>

    <xsl:for-each select="citeData">
      <xsl:variable name="data" select="."/>
      <xsl:variable name="xpath" select="string(@use)"/>
      <xsl:variable name="property" select="string(@property)"/>
      <xsl:variable name="checks" as="item()*">
        <xsl:for-each select="$matched">
          <xsl:try>
            <xsl:evaluate xpath="$xpath"
              context-item="."
              _xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>
            <xsl:catch>
              <v:error detail="{$err:description}"/>
            </xsl:catch>
          </xsl:try>
        </xsl:for-each>
      </xsl:variable>
      <xsl:if test="exists($results[. instance of element(v:error)])">
        <v:issue severity="error" kind="invalid-use" location="{$location} / citeData[@property='{$property}']"
          message="Invalid @use XPath: {$xpath}. {$checks[. instance of element(v:error)][1]/@detail}"/>
      </xsl:if>
      <xsl:if test="$property='dc:requires' and exists($matched) and empty($checks[not(. instance of element(v:error))])
        and empty($checks[. instance of element(v:error)])">
        <v:issue severity="warning" kind="missing-dependency" location="{$location}"
          message="dc:requires matched nothing: {$xpath}"/>
      </xsl:if>
    </xsl:for-each>

    <xsl:for-each-group select="citeData[@property='function']/@use" group-by="string(.)">
      <xsl:if test="count(current-group()) gt 1">
        <v:issue severity="warning" kind="duplicate-function" location="{$location}"
          message="Repeated function: {current-grouping-key()}"/>
      </xsl:if>
    </xsl:for-each-group>

    <xsl:apply-templates select="citeStructure" mode="check">
      <xsl:with-param name="contexts" select="$matched"/>
    </xsl:apply-templates>
  </xsl:template>
</xsl:stylesheet>

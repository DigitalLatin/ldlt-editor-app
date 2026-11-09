<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:dts="https://w3id.org/dts/api#"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="xs dts xlink"
  expand-text="yes"
  version="3.0">
  <xsl:output method="xml" omit-xml-declaration="yes" indent="no"/>
  
  <xsl:param name="dir">./</xsl:param>
  
  <!-- Generates a table of contents used as an index page and a sidebar -->
  <xsl:variable name="toc">
    <xsl:apply-templates select="//refsDecl" mode="toc"/>
  </xsl:variable>
  <xsl:variable name="root" select="/TEI"/>
  
  <!-- Generates a copy of the document with IDs added to all elements -->
  <xsl:variable name="doc-with-ids">
    <xsl:apply-templates select="/*" mode="add-ids"/>
  </xsl:variable>
  
  <!-- A tree consisting of citable elements plus their (partial) reference strings -->
  <xsl:variable name="citables">
    <xsl:apply-templates select="$doc-with-ids//refsDecl/citeStructure" mode="citables"/>
  </xsl:variable>
  
  <!-- A list of IDs that can be used to check if a given element has a reference string -->
  <xsl:variable name="citable-list" as="item()*">
    <xsl:variable name="list">
      <xsl:apply-templates select="$doc-with-ids//refsDecl/citeStructure" mode="citable-list"/>
    </xsl:variable>
    <xsl:sequence select="tokenize($list, '\s+')"></xsl:sequence>
  </xsl:variable>
  
  <xsl:template match="/">---
layout: edition_index
title: "{//text/front/titlePage/docTitle/titlePart}"
citables: "{{<xsl:apply-templates select="$doc-with-ids//refsDecl/citeStructure" mode="citations"/>}}"
---
<div id="tei">
  <xsl:apply-templates select="//titlePage"/>
  <div class="toc">
    <xsl:copy-of select="$toc"/>
  </div>
</div>
<xsl:for-each select="$doc-with-ids//refsDecl//citeStructure[citeData[@property='function' and contains(@use,'split')]]">
  <xsl:apply-templates select="." mode="split"/>
</xsl:for-each>
<div id="citesearch">
  <form>
    <label for="getcite">Find citation</label> <input type="text" name="getcite"/> <button onclick="resolveCite(); return false;">Go</button>
  </form>
</div>
    <xsl:result-document href="../../_includes/editions.html">
      <xsl:call-template name="index"/>
    </xsl:result-document>
  </xsl:template>
  
  <xsl:template name="index">
    <ul>
      <xsl:for-each select="uri-collection('../sources?select=*.xml')">
        <xsl:variable name="name" select="translate(replace(.,'.*/([^/]+).xml','$1'),'_',' ')"/>
        <li><a href="/editions/{lower-case(replace(.,'.*/([^/]+).xml','$1'))}">{$name}</a></li>
      </xsl:for-each>
    </ul>
  </xsl:template>
  
  <!-- Convert TEI elements to CETEIcean-style -->
  <xsl:template match="*">
    <xsl:element name="tei-{local-name(.)}">
      <xsl:for-each select="@*">
        <xsl:choose>
          <xsl:when test="name(.) = 'xml:id' and not(starts-with(., 'tmp'))">
            <xsl:attribute name="xml:id" select="."/>
            <xsl:attribute name="id" select="."/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:copy-of select="."/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
      <xsl:attribute name="data-origname" select="local-name(.)"/>
      <xsl:if test="not(.//node())">
        <xsl:attribute name="data-empty"/>
      </xsl:if>
      <xsl:if test="$citable-list = xs:string(@xml:id)">
        <xsl:attribute name="data-citation">{dts:resolve_citation(.)}</xsl:attribute>
      </xsl:if>
      <xsl:if test="not(.//node())">
        <xsl:text>&#x200B;</xsl:text>
      </xsl:if>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>
  
  <!-- Resolve internal cross-references into the correct split-out document. -->
  <xsl:template match="ref[starts-with(@target, '#')]">
    <xsl:variable name="target" select="substring-after(@target,'#')"/>
    <tei-ref target="{$root/id($target)/ancestor::div[@type = ('section','textpart','bibliography')][1]/@xml:id}.html{@target}">
      <xsl:apply-templates/>
    </tei-ref>
  </xsl:template>
  
  <!-- Called by $doc-with-ids -->
  <xsl:template match="*" mode="add-ids">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:if test="not(@xml:id)">
        <xsl:attribute name="xml:id" select="generate-id(.)"/>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="add-ids"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Table of Contents -->
  <xsl:template match="refsDecl" mode="toc">
    <ul>
      <xsl:call-template name="process-toc">
        <xsl:with-param name="citestructures" select="citeStructure"/>
      </xsl:call-template>
    </ul>
  </xsl:template>
  
  <xsl:template name="process-toc">
    <xsl:param name="context" select="/TEI"/>
    <xsl:param name="citestructures"/>
    <xsl:variable name="matches" select="string-join($citestructures/@match, ' | ')"/>
    <xsl:variable name="structures">
      <xsl:evaluate context-item="$context" xpath="$matches"/>
    </xsl:variable>
    <xsl:for-each select="$structures/*">
      <xsl:variable name="current" select="."/>
      <xsl:for-each select="$citestructures">
        <xsl:variable name="resolved" select="dts:resolve_citestructure($context,.)"/>
        <xsl:if test="$resolved = $current">
          <xsl:apply-templates select="." mode="toc">
            <xsl:with-param name="context" select="$context"/>
            <xsl:with-param name="matched" select="$current"/>
          </xsl:apply-templates>
        </xsl:if>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:template>
  
  <!-- Generate the list items in the table of contents -->
  <xsl:template match="citeStructure" mode="toc">
    <xsl:param name="context" select="."/>
    <xsl:param name="matched"/>
    <xsl:variable name="current" select="."/>
    <xsl:variable name="match" select="@match"/>
    <xsl:variable name="matches">
      <xsl:choose>
        <xsl:when test="$matched">
          <xsl:sequence select="$matched"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:evaluate xpath="$match" context-item="$context"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="dts:resolve_citedata(.,.,'function') = 'toc-entry'">
      <xsl:for-each select="$matches/*">
        <li>
          <!-- When a toc-entry has an ancestor that will be split into a separate document, make a link to split_document.html#id, 
               when it's to be split out itself, do split_document.html. No link otherwise. -->
          <xsl:choose>
            <xsl:when test="$current/citeData[@property='function' and contains(@use,'split')] or $current/ancestor::citeStructure[citeData[@property='function' and contains(@use,'split')]] ">
              <a>
                <xsl:variable name="link">
                  <xsl:variable name="split" select="$current/ancestor::citeStructure[citeData[@property='function' and contains(@use,'split')]]"/>
                  <xsl:choose>
                    <xsl:when test="$split">
                      <xsl:variable name="ancestor" select="dts:resolve_id($context,$split)"/>
                      <xsl:value-of select="$ancestor|| '.html#'|| dts:resolve_id(., $current)"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="dts:resolve_id(.,$current) || '.html'"/>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <xsl:choose>
                  <xsl:when test="$current/citeData[@property='dc:title']">
                    <xsl:attribute name="href" select="$link"/>
                    <xsl:value-of select="dts:resolve_citedata(., $current, 'dc:title')"/>
                  </xsl:when>
                  <xsl:when test="$current/citeData[@property='dc:identifier']">
                    <xsl:variable name="use" select="$current/@use"/>
                    <xsl:attribute name="href" select="$link"></xsl:attribute>
                    <xsl:evaluate xpath="$use" context-item="."/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:variable name="use" select="$current/@use"/>
                    <xsl:attribute name="href" select="$link"></xsl:attribute>
                    <xsl:evaluate xpath="$use" context-item="." _xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>
                  </xsl:otherwise>
                </xsl:choose>
              </a>
            </xsl:when>
            <xsl:otherwise>
              <xsl:choose>
                <xsl:when test="$current/citeData[@property='dc:title']">
                  <xsl:value-of select="dts:resolve_citedata(., $current, 'dc:title')"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:variable name="use" select="$current/@use"/>
                  <xsl:evaluate xpath="$use" context-item="." _xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:if test="$current/citeStructure[dts:resolve_citedata(.,.,'function') = 'toc-entry']">
            <ul>
              <xsl:call-template name="process-toc">
                <xsl:with-param name="citestructures" select="$current/citeStructure[dts:resolve_citedata(.,.,'function') = 'toc-entry']"/>
                <xsl:with-param name="context" select="."></xsl:with-param>
              </xsl:call-template>
            </ul>
          </xsl:if>
        </li>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>
  
  <!-- Generate a separate HTML document for each citeStructure -->
  <xsl:template match="citeStructure" mode="split">
    <xsl:variable name="current" select="."/>
    <xsl:variable name="doc" select="$doc-with-ids/TEI"/>
    <xsl:variable name="match">
      <xsl:choose>
        <xsl:when test="starts-with(@match,'/')">{@match}</xsl:when>
        <xsl:otherwise>{string-join(ancestor::citeStructure/@match, '/') || '/' || @match}</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="matches">
      <xsl:evaluate xpath="$match" context-item="$doc"/>
    </xsl:variable>
    
    <xsl:for-each select="$matches/*">
      <xsl:result-document href="{lower-case(dts:resolve_id(.,$current))}.md">---
layout: edition
title: "{$doc//text/front/titlePage/docTitle/titlePart}: {head}"
citables: "{{<xsl:apply-templates select="$doc-with-ids//refsDecl/citeStructure" mode="citations"/>}}"
--- 
  <div id="prevNext">
    -
  </div>

  <div class="TEI" id="tei">
    <xsl:apply-templates select="$doc//teiHeader"/>
    <xsl:variable name="id" select="./@xml:id"/>
    <xsl:variable name="tree">
      <xsl:call-template name="ancestors-and-self">
        <xsl:with-param name="elt" select="$doc-with-ids/id($id)/parent::*"/>
        <xsl:with-param name="newtree" select="."/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:apply-templates select="$tree/*"/>
    <xsl:for-each select="dts:resolve_citedata($doc,$current,'dc:requires')">
      <div style="display:none;">
        <xsl:apply-templates select="."/>
      </div>
    </xsl:for-each>
  </div>
  <div id="controls" class="">
    <div id="citesearch">
      <form>
        <label for="getcite">Find citation</label><xsl:text> </xsl:text><input type="text" name="getcite"/><xsl:text> </xsl:text><button onclick="resolveCite(); return false;">Go</button>
      </form>
    </div>
    
    <div id="editing">
      <ul>
        <li><button onclick="app.undo()" title="undo"><svg class="svg-icon">
          <use xlink:href="#undo-icon"></use>
        </svg></button></li>
        <li><button onclick="app.redo()" title="redo"><svg class="svg-icon">
          <use xlink:href="#redo-icon"></use>
        </svg></button></li>
        <li><button onclick="while (app.log.length > 0) {{app.undo();}}" title="undo all"><svg class="svg-icon">
          <use xlink:href="#reload-icon"></use>
        </svg></button></li>
      </ul>
    </div>
    
    <div id="display">
      <form class="">
        <ul>
          <li><input type="checkbox" name="orthographical" value="true"/><label for="orthographical">Hide orthographical variants</label></li>
          <li><input type="checkbox" name="morphological" value="true"/><label for="morphological">Hide morphological variants</label></li>
          <li><input type="checkbox" name="lexical" value="true"/><label for="lexical">Hide lexical variants</label></li>
        </ul>
      </form>
    </div>
    
    <div id="navigation">
      <xsl:copy-of select="$toc"/>
    </div>
  </div>
    
      </xsl:result-document>
    </xsl:for-each>
  </xsl:template>
  
  <!-- Returns a tree containing copies of an element plus its ancestors -->
  <xsl:template name="ancestors-and-self">
    <xsl:param name="elt"/>
    <xsl:param name="newtree"/>
    <xsl:choose>
      <xsl:when test="$elt">
        <xsl:call-template name="ancestors-and-self">
          <xsl:with-param name="elt" select="$elt/parent::*"/>
          <xsl:with-param name="newtree">
            <xsl:copy select="$elt">
              <xsl:copy-of select="@*"/>
              <xsl:copy-of select="$newtree"/>
            </xsl:copy>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$newtree"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Produces a tree containing copies of just the citable elements without 
       their full content plus their partial citation -->
  <xsl:template match="citeStructure" mode="citables">
    <xsl:param name="context" select="$doc-with-ids/TEI"/>
    <xsl:variable name="current" select="."/>
    <xsl:variable name="use" select="'xs:string(' || @use || ')'"/>
    <xsl:choose>
      <xsl:when test="@unit">
        <xsl:for-each select="dts:resolve_citestructure($context, .)">
          <xsl:copy>
            <xsl:copy-of select="@*"/>
            <dts-cite xmlns="http://www.tei-c.org/ns/1.0"><xsl:value-of select="$current/@delim"/><xsl:evaluate context-item="." xpath="$use"/></dts-cite>
            <xsl:apply-templates select="$current/citeStructure" mode="citables">
              <xsl:with-param name="context" select="."/>
            </xsl:apply-templates>
          </xsl:copy>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="$current/citeStructure" mode="citables">
          <xsl:with-param name="context" select="."/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Produces a list of IDs for citable elements -->
  <xsl:template match="citeStructure" mode="citable-list">
    <xsl:param name="context" select="$doc-with-ids/TEI"/>
    <xsl:variable name="current" select="."/>
    <xsl:variable name="use" select="'xs:string(' || @use || ')'"/>
    <xsl:choose>
      <xsl:when test="@unit">
        <xsl:for-each select="dts:resolve_citestructure($context,.)">
          <xsl:sequence select="xs:string(@xml:id)"/>
          <xsl:apply-templates select="$current/citeStructure" mode="citable-list">
            <xsl:with-param name="context" select="."/>
          </xsl:apply-templates>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="$current/citeStructure" mode="citable-list">
          <xsl:with-param name="context" select="."/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Build a list of citations pointing to the file containing the cite and the cite itself -->
  <xsl:template match="citeStructure" mode="citations">
    <xsl:param name="context" select="$doc-with-ids/TEI"/>
    <xsl:param name="parentcite" select="''"/>
    <xsl:param name="parenttarget" select="''"/>
    <xsl:param name="parentmatch" select="''"/>
    <xsl:variable name="current" select="."/>
    <xsl:variable name="matches" select="dts:resolve_citestructure($context,.)"/>
    <xsl:choose>
      <xsl:when test="@unit">
        <xsl:variable name="use" select="'xs:string(' || @use || ')'"/>
        <xsl:variable name="delim" select="@delim"/>
        <xsl:for-each select="$matches">
          <xsl:variable name="citationpart">
            <xsl:evaluate context-item="." xpath="$use"/>
          </xsl:variable>
          <!-- when function is split do {@xml:id}.html -->
          <xsl:choose>
            <xsl:when test="dts:resolve_citedata(.,$current,'function') = 'split'">'{$parentcite || $delim || $citationpart}': '{dts:resolve_citedata(.,$current,'dc:identifier')}.html',<xsl:apply-templates select="$current/citeStructure" mode="citations">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="parentcite" select="$parentcite || $delim || $citationpart"/>
                <xsl:with-param name="parenttarget">{dts:resolve_citedata(.,$current,'dc:identifier')}.html</xsl:with-param>
                <xsl:with-param name="parentmatch" select="$current/@match"/>
              </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>'{$parentcite || $delim || $citationpart}': '{$parenttarget}#{$parentcite || $delim || $citationpart}',<xsl:apply-templates select="$current/citeStructure" mode="citations">
                <xsl:with-param name="context" select="."/>
                <xsl:with-param name="parentcite" select="$parentcite || $delim || $citationpart"/>
                <xsl:with-param name="parenttarget">{$parenttarget}</xsl:with-param>
                <xsl:with-param name="parentmatch" select="$parentmatch || $current/@match"/>
              </xsl:apply-templates>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="citeStructure" mode="citations">
          <xsl:with-param name="context" select="$matches"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Given a context element and a citeStructure, find the corresponding element(s) in the document -->
  <xsl:function name="dts:resolve_citestructure">
    <xsl:param name="context"/>
    <xsl:param name="current"/>
    <xsl:variable name="match" select="$current/@match"/>
    <xsl:evaluate xpath="$match" context-item="$context"/>
  </xsl:function>
  
  <!-- Given a context element and a citeStructure, get the value indicated -->
  <xsl:function name="dts:resolve_citedata">
    <xsl:param name="context"/>
    <xsl:param name="current"/>
    <xsl:param name="property"/>
    <xsl:for-each select="$current/citeData[@property=$property]/@use">
      <xsl:variable name="use" select="string(.)"/>
      <xsl:choose>
        <xsl:when test="$use = ''"><xsl:text></xsl:text></xsl:when>
        <xsl:when test="starts-with($use,'@')">
          <xsl:evaluate xpath="$use" context-item="$context" _xpath-default-namespace=""/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:evaluate xpath="$use" context-item="$context" _xpath-default-namespace="http://www.tei-c.org/ns/1.0"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:function>
  
  <!-- Special (common) case of dts:resolve_citedata, get the identifier -->
  <xsl:function name="dts:resolve_id">
    <xsl:param name="context"/>
    <xsl:param name="current"/>
    <xsl:choose>
      <xsl:when test="$current/citeData[@property='dc:identifier']">
        <xsl:sequence select="dts:resolve_citedata($context,$current,'dc:identifier')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="use" select="$current/@use"/>
        <xsl:evaluate context-item="$context" xpath="$use"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- Given an element, use the $citables global variable to get a full citation -->
  <xsl:function name="dts:resolve_citation" as="xs:string">
    <xsl:param name="current"/>
    <xsl:variable name="id" select="$current/@xml:id"/>
    <xsl:variable name="citable" select="$citables//*[@xml:id=$id]"/>
    <xsl:value-of select="string-join($citable/ancestor-or-self::*/dts-cite)"/>
  </xsl:function>
  
</xsl:stylesheet>
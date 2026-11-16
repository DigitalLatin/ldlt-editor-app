<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xpath-default-namespace="http://www.tei-c.org/ns/1.0"
  exclude-result-prefixes="xs">

  <xsl:output method="json" encoding="UTF-8" indent="yes"/>
  <xsl:param name="edition-slug" as="xs:string" required="yes"/>

  <xsl:template match="/">
    <xsl:variable name="file" select="/TEI/teiHeader/fileDesc"/>
    <xsl:variable name="titles" select="$file/titleStmt"/>
    <xsl:variable name="license" select="$file/publicationStmt/availability/licence[1]"/>

    <xsl:sequence select="map {
      'slug': $edition-slug,
      'title': normalize-space(string($titles/title[1])),
      'authors': array { $titles/author ! normalize-space(string(.)) },
      'editors': array { $titles/editor ! normalize-space(string(.)) },
      'edition': normalize-space(string($file/editionStmt/edition[1])),
      'series': normalize-space(string($file/seriesStmt/title[1])),
      'publisher': normalize-space(string($file/publicationStmt/publisher[1])),
      'tei_encoders': array {
        $titles/respStmt[starts-with(normalize-space(string(resp[1])), 'TEI XML encoding')]/name
          ! normalize-space(string(.))
      },
      'license': map {
        'name': normalize-space(string($license)),
        'url': string($license/@target)
      }
    }"/>
  </xsl:template>
</xsl:stylesheet>

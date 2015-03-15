<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet [
	<!ENTITY LF "&#xA;">
]>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:a="http://relaxng.org/ns/compatibility/annotations/1.0"
	xmlns:rng="http://relaxng.org/ns/structure/1.0" version="1.0" extension-element-prefixes="rng a">
	<xsl:output method="text" />

	<xsl:param name="title">
		RELAX-NG Schema Documentation
	</xsl:param>
	<xsl:param name="default.documentation.string" select="'No documentation available.'" />
	<xsl:param name="target" select="osgr" />

	<xsl:output method="text" />

	<xsl:template match="rng:grammar">
		<xsl:apply-templates select="a:documentation" />
		<xsl:apply-templates select="rng:start" />
	</xsl:template>

	<xsl:template match="rng:start">
		<xsl:apply-templates select="rng:choice" mode="schemaRoot"/>
	</xsl:template>
	
	<xsl:template match="rng:choice" mode="schemaRoot" >
		<xsl:text>&LF;= `</xsl:text>
		<xsl:value-of select="*/@name" />
		<xsl:text>` =&LF;</xsl:text>
		
		<xsl:apply-templates select="a:documentation" />

		<xsl:apply-templates select="rng:element" />
		<xsl:apply-templates select="rng:ref" />
	</xsl:template>

	<xsl:template match="rng:ref">
		<xsl:param name="path" />

		<xsl:variable name="ref" select="@name" />
		<xsl:apply-templates select="//rng:define[@name=$ref]">
			<xsl:with-param name="path" select="$path" />
		</xsl:apply-templates>
	</xsl:template>


	<xsl:template match="rng:define">
		<xsl:param name="path" />

		<xsl:apply-templates select="rng:element">
			<xsl:with-param name="path" select="$path" />
		</xsl:apply-templates>
	</xsl:template>

	<!-- <xsl:template match="rng:grammar"> = <xsl:value-of select="$title"/> = <xsl:apply-templates select="a:documentation"/> 
		<xsl:apply-templates select="//rng:element"/> <xsl:apply-templates select="//rng:define"/> </xsl:template> -->

	<xsl:template match="rng:element">
		<xsl:param name="path" />

		<xsl:variable name="name" select="@name|rng:name" />
		<xsl:variable name="fullPath">
			<xsl:value-of select="$path" />
			<xsl:text>/</xsl:text>
			<xsl:value-of select="$name" />
		</xsl:variable>

		<xsl:text>&LF;== `</xsl:text>
		<xsl:value-of select="$fullPath" />
		<xsl:text>` ==&LF;</xsl:text>
		
		<xsl:apply-templates select="a:documentation" />

		<xsl:text>&LF;|| *Content* || </xsl:text>
		<xsl:apply-templates mode="content-model" />
		<xsl:text>||&LF;</xsl:text>
		
		<xsl:text>|| *Attributes* || TODO</xsl:text>
		<xsl:text> ||&LF;</xsl:text>

		<xsl:variable name="hasatts">
			<xsl:apply-templates select="." mode="has-attributes" />
		</xsl:variable>
		<xsl:if test="starts-with($hasatts, 'true')">
			<xsl:variable name="nesting" select="count(ancestor::rng:element)" />
			<xsl:apply-templates
					select=".//rng:attribute[count(ancestor::rng:element)=$nesting+1] | .//rng:ref[count(ancestor::rng:element)=$nesting+1]"
					mode="attributes">
				<xsl:with-param name="matched" select="." />
				<xsl:with-param name="optional">
					<xsl:value-of select="false()" />
				</xsl:with-param>
				<xsl:with-param name="path">
					<xsl:value-of select="$fullPath" />
				</xsl:with-param>
			</xsl:apply-templates>
		</xsl:if>
		 
		<xsl:apply-templates select="*/rng:ref">
			<xsl:with-param name="path" select="$fullPath" />
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="rng:attribute" mode="attributes">
		<xsl:param name="matched" />
		<xsl:param name="optional" />
		<xsl:param name="path" />
		
		<xsl:text>&LF;=== `</xsl:text>
			<xsl:value-of select="$path" />
			<xsl:text>/@</xsl:text>
			<xsl:value-of select="@name" />
		<xsl:text>` ===&LF;</xsl:text>

		<xsl:text>&LF;|| *Use* || </xsl:text>
		<xsl:choose>
			<xsl:when test="ancestor::rng:optional">
				<xsl:text>Optional</xsl:text>
			</xsl:when>
			<xsl:when test="boolean($optional)">
				<xsl:text>Optional</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>Required</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>||&LF;</xsl:text>
		
		<xsl:text>|| *Type* || </xsl:text>
		<xsl:choose>
			<xsl:when test="rng:data">
				<xsl:text>xsd: </xsl:text>
				<xsl:value-of select="rng:data/@type" />
			</xsl:when>
			<xsl:when test="rng:text">
				<xsl:text>TEXT</xsl:text>
			</xsl:when>
			<xsl:when test="rng:choice">
				<xsl:text>Enumeration</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>TEXT </xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text> ||&LF;</xsl:text>
		
		<xsl:if test="rng:choice">
			<xsl:text>|| *Values* || </xsl:text>
			<xsl:for-each select="rng:choice/rng:value">
				<xsl:value-of select="." />
				<xsl:if test="following-sibling::*">
					<xsl:text>, </xsl:text>
				</xsl:if>
			</xsl:for-each>
			<xsl:text> ||&LF;</xsl:text>
			
			<xsl:text>|| *Default Value* || </xsl:text>
			<xsl:value-of select="./@a:defaultValue" />
			<xsl:text> ||&LF;</xsl:text>
		</xsl:if> 

		<xsl:apply-templates select="a:documentation[1]" />
	</xsl:template>

	<xsl:template match="rng:ref" mode="attributes">
		<xsl:param name="matched" />
		<xsl:param name="optional" />
		<xsl:param name="path" />
				
		<xsl:variable name="name" select="@name" />
		<xsl:variable name="opt" select="count(ancestor::rng:optional) > 0" />
		<xsl:apply-templates select="//rng:define[@name=$name]" mode="attributes">
			<xsl:with-param name="matched" select="$matched" />
			<xsl:with-param name="optional" select="boolean($optional) or boolean($opt)" />
			<xsl:with-param name="path" select="$path" />
		</xsl:apply-templates>
	</xsl:template>

	<xsl:template match="rng:define" mode="attributes">
		<xsl:param name="matched" />
		<xsl:param name="optional" />
		<xsl:param name="path" />
		
		<xsl:if test="not(count(matched)=count(matched|.))">
			<xsl:apply-templates select=".//rng:attribute[not(ancestor::rng:element)] | .//rng:ref[not(ancestor::rng:element)]"
					mode="attributes">
				<xsl:with-param name="matched" select="$matched|." />
				<xsl:with-param name="optional" select="$optional or ancestor::rng:optional" />
				<xsl:with-param name="path" select="$path" />
			</xsl:apply-templates>
		</xsl:if>
	</xsl:template>

	<xsl:template match="rng:element" mode="has-attributes">
		<xsl:choose>
			<xsl:when test=".//rng:attribute[count(ancestor::rng:element)=count(current()/ancestor::rng:element) + 1]">true</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select=".//rng:ref[count(ancestor::rng:element)=count(current()/ancestor::rng:element) + 1]"
					mode="has-attributes" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="rng:ref" mode="has-attributes">
		<xsl:variable name="name" select="@name" />
		<xsl:apply-templates select="//rng:define[@name=$name]" mode="has-attributes" />
	</xsl:template>

	<xsl:template match="rng:define" mode="has-attributes">
		<xsl:choose>
			<xsl:when test=".//rng:attribute[not(ancestor::rng:element)]">true</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select=".//rng:ref[not(ancestor::rng:element)]" mode="has-attributes" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="rng:*" mode="has-attributes">
		<xsl:apply-templates mode="has-attributes" />
	</xsl:template>

	<xsl:template match="*|node()" mode="has-attributes">
		<!-- suppress -->
	</xsl:template>

	<xsl:template match="rng:define" mode="content-model">
		<xsl:variable name="name" select="@name" />
		<xsl:apply-templates select="rng:element" mode="content-model" />
	</xsl:template>

	<xsl:template match="rng:define" mode="define-base">
		<xsl:variable name="name" select="@name" />
		<xsl:variable name="haselements">
			<xsl:apply-templates select="." mode="find-element">
				<xsl:with-param name="matched" select=".." />
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:variable name="combined">
			<xsl:if test="@combine">
				<xsl:value-of select="following::rng:define[@name=$name]" />
			</xsl:if>
			<xsl:if test="not(@combine)">
				<xsl:value-of select="//rng:define[@name=$name and @combine]" />
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="nsuri">
			<xsl:choose>
				<xsl:when test="ancestor::rng:div[@ns][1]">
					<xsl:value-of select="ancestor::rng:div[@ns][1]/@ns" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="ancestor::rng:grammar[@ns][1]/@ns" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>

		<section>
			<xsl:attribute name="id"><xsl:value-of select="@name" /></xsl:attribute>
			<title>
				Pattern:
				<xsl:value-of select="@name" />
			</title>
			<table>
				<title>
					Pattern:
					<xsl:value-of select="@name" />
				</title>
				<tgroup cols="2">
					<colspec colnum="1" />
					<colspec colnum="2" colwidth="*" />
					<tbody>
						<row>
							<entry class="header" valign="top">
								<para>Namespace</para>
							</entry>
							<entry>
								<para>
									<xsl:value-of select="$nsuri" />
								</para>
							</entry>
						</row>
						<xsl:if test="a:documentation or not($default.documentation.string='')">
							<row>
								<entry class="header" valign="top">
									<para>Documentation</para>
								</entry>
								<entry>
									<para>
										<xsl:choose>
											<xsl:when test="a:documentation">
												<xsl:apply-templates select="a:documentation" />
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="$default.documentation.string" />
											</xsl:otherwise>
										</xsl:choose>
									</para>
								</entry>
							</row>
						</xsl:if>
						<xsl:if test="starts-with($haselements, 'true')">
							<row valign="top">
								<entry class="header">
									<para>Content Model</para>
								</entry>
								<entry>
									<para>
										<xsl:apply-templates select="*" mode="content-model" />
										<xsl:if test="@combine">
											<xsl:apply-templates select="following::rng:define[@name=$name]" mode="define-combine" />
										</xsl:if>
										<xsl:if test="not(@combine)">
											<xsl:apply-templates select="//rng:define[@name=$name and @combine]" mode="define-combine" />
										</xsl:if>
									</para>
								</entry>
							</row>
						</xsl:if>
						<xsl:variable name="hasatts">
							<xsl:apply-templates select="." mode="has-attributes" />
						</xsl:variable>
						<xsl:if test="starts-with($hasatts, 'true')">
							<row valign="top">
								<entry class="header">Attributes</entry>
								<entrytbl cols="3">
									<tbody>
										<row>
											<entry role="header">
												<para>Attribute</para>
											</entry>
											<entry role="header">
												<para>Type</para>
											</entry>
											<entry role="header">
												<para>Use</para>
											</entry>
											<entry role="header">
												<para>Documentation</para>
											</entry>
										</row>
										<xsl:variable name="nesting" select="count(ancestor::rng:element)" />
										<xsl:apply-templates
											select=".//rng:attribute[count(ancestor::rng:element)=$nesting] | .//rng:ref[count(ancestor::rng:element)=$nesting]"
											mode="attributes">
											<xsl:with-param name="matched" select="." />
										</xsl:apply-templates>
									</tbody>
								</entrytbl>
							</row>
						</xsl:if>
					</tbody>
				</tgroup>
			</table>
		</section>
	</xsl:template>

	<xsl:template match="rng:define" mode="define-combine">
		<xsl:choose>
			<xsl:when test="@combine='choice'">
				<xsl:text> | (</xsl:text>
				<xsl:apply-templates mode="content-model" />
				<xsl:text>)</xsl:text>
			</xsl:when>
			<xsl:when test="@combine='interleave'">
				<xsl:text>&amp; (</xsl:text>
				<xsl:apply-templates mode="content-model" />
				<xsl:text>)</xsl:text>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="rng:element" mode="makeid">
		<xsl:apply-templates select="ancestor::rng:element[1]" mode="makeid" />
		.
		<xsl:value-of select="@name" />
	</xsl:template>

	<xsl:template match="rng:define" mode="makeid">
		<xsl:value-of select="@name" />
	</xsl:template>

	<xsl:template match="*" mode="makeid">
		<xsl:apply-templates select="ancestor::rng:element[1] | ancestor::rng:define[1]" />
	</xsl:template>

	<xsl:template name="makeid">
		<xsl:param name="node" />
		<xsl:variable name="id">
			<xsl:apply-templates select="$node" mode="makeid" />
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="ancestor-or-self::rng:define">
				<xsl:value-of select="ancestor-or-self::rng:define[1]/@name" />
				<xsl:value-of select="$id" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="substring-after($id, '.')" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- ================================================= -->
	<!-- CONTENT MODEL PATTERNS -->
	<!-- The following patterns construct a text -->
	<!-- description of an element content model -->
	<!-- ================================================= -->
	<xsl:template match="rng:element" mode="content-model">
		<xsl:value-of select="@name" />
		<xsl:if
			test="not(parent::rng:choice) and (following-sibling::rng:element | following-sibling::rng:optional | following-sibling::rng:oneOrMore | following-sibling::rng:zeroOrMore)">
			<xsl:text>, </xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="rng:group" mode="content-model">
		<xsl:text>(</xsl:text>
		<xsl:apply-templates mode="content-model" />
		<xsl:text>)</xsl:text>
	</xsl:template>

	<xsl:template match="rng:optional" mode="content-model">
		<xsl:if test=".//rng:element | .//rng:ref[not(ancestor::rng:attribute)]">
			<xsl:apply-templates mode="content-model" />
			<xsl:text>?</xsl:text>
			<xsl:if
				test="not(parent::rng:choice) and (following-sibling::rng:element | following-sibling::rng:optional | following-sibling::rng:oneOrMore | following-sibling::rng:zeroOrMore)">
				<xsl:text>, </xsl:text>
			</xsl:if>
		</xsl:if>
	</xsl:template>

	<xsl:template match="rng:oneOrMore" mode="content-model">
		<xsl:text>(</xsl:text>
		<xsl:apply-templates mode="content-model" />
		<xsl:text>)+</xsl:text>
		<xsl:if
			test="not(parent::rng:choice) and (following-sibling::rng:element | following-sibling::rng:optional | following-sibling::rng:oneOrMore | following-sibling::rng:zeroOrMore)">
			<xsl:text>, </xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="rng:zeroOrMore" mode="content-model">
		<xsl:text>(</xsl:text>
		<xsl:apply-templates mode="content-model" />
		<xsl:text>)*</xsl:text>
		<xsl:if
			test="not(parent::rng:choice) and (following-sibling::rng:element | following-sibling::rng:optional | following-sibling::rng:oneOrMore | following-sibling::rng:zeroOrMore)">
			<xsl:text>, </xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="rng:choice" mode="content-model">
		<xsl:text>(</xsl:text>
		<xsl:for-each select="*">
			<xsl:apply-templates select="." mode="content-model" />
			<xsl:if test="following-sibling::rng:*">
				<xsl:text>|</xsl:text>
			</xsl:if>
		</xsl:for-each>
		<xsl:text>)</xsl:text>
	</xsl:template>

	<xsl:template match="rng:value" mode="content-model">
		<xsl:text>"</xsl:text>
		<xsl:value-of select="." />
		<xsl:text>"</xsl:text>
	</xsl:template>

	<xsl:template match="rng:empty" mode="content-model">
		<xsl:text>EMPTY</xsl:text>
	</xsl:template>

	<xsl:template match="rng:ref" mode="content-model">
		<xsl:variable name="ref" select="@name" />

		<xsl:variable name="haselement">
			<xsl:apply-templates select="." mode="find-element" />
		</xsl:variable>
		<xsl:if test="starts-with($haselement, 'true')">
			<xsl:apply-templates select="//rng:define[@name=$ref]" mode="content-model" />
			<xsl:if
				test="not(parent::rng:choice) and (following-sibling::rng:element | following-sibling::rng:optional | following-sibling::rng:oneOrMore | following-sibling::rng:zeroOrMore)">
				<xsl:text>, </xsl:text>
			</xsl:if>
		</xsl:if>
	</xsl:template>

	<xsl:template match="rng:text" mode="content-model">
		<xsl:text>TEXT</xsl:text>
		<xsl:if
			test="not(parent::rng:choice) and (following-sibling::rng:element | following-sibling::rng:optional | following-sibling::rng:oneOrMore | following-sibling::rng:zeroOrMore)">
			<xsl:text>, </xsl:text>
		</xsl:if>
	</xsl:template>

	<xsl:template match="rng:data" mode="content-model">
		<xsl:text>xsd: </xsl:text>
		<xsl:value-of select="@type" />
	</xsl:template>

	<!-- suppress -->
	<xsl:template match="*|text()" mode="content-model" />



	<xsl:template match="rng:define" mode="find-element">
		<xsl:param name="matched" />
		<xsl:if test="not(count($matched | .)=count($matched))">
			<xsl:choose>
				<xsl:when test=".//rng:element|.//rng:text">
					<xsl:value-of select="true()" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select=".//rng:ref[not(ancestor::rng:attribute)]" mode="find-element">
						<xsl:with-param name="matched" select="$matched | ." />
					</xsl:apply-templates>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>

	<xsl:template match="rng:ref" mode="find-element">
		<xsl:param name="matched" select="." />
		<xsl:variable name="ref" select="@name" />
		<xsl:apply-templates select="//rng:define[@name=$ref]" mode="find-element">
			<xsl:with-param name="matched" select="$matched" />
		</xsl:apply-templates>
	</xsl:template>


</xsl:stylesheet>

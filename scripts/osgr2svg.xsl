<?xml version="1.0" encoding="windows-1250"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:m="http://graph2svg.googlecode.com"
	xmlns:gr="http://graph2svg.googlecode.com"
	xmlns:svg="http://www.w3.org/2000/svg"
	xmlns:math="http://exslt.org/math"	
	extension-element-prefixes="math"
	exclude-result-prefixes="m math xs gr"
	version="2.0">
 
<xsl:output method="xml" encoding="utf-8" indent="yes"/>
<!--doctype-public="-//W3C//DTD SVG 1.1//EN"
"doctype-system="http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"-->

<xsl:template name="m:osgr2svg">
	<xsl:variable name="gra">
		<ph>
		<xsl:apply-templates select="$graph/@*" mode="m:processValues">
			<xsl:with-param name="graph" select="$graph" tunnel="yes"/>
		</xsl:apply-templates>
		<xsl:attribute name="legend" select="
			if (($graph/@legend) = 'right') then 'right' else
			if (($graph/@legend) = 'left') then 'left' else
			if (($graph/@legend) = 'top') then 'top' else
			if (($graph/@legend) = 'bottom') then 'bottom' else 'none' "/>
		<xsl:apply-templates select="$graph/(*|text())" mode="m:processValues">
			<xsl:with-param name="graph" select="$graph" tunnel="yes"/>
		</xsl:apply-templates>
		</ph>
	</xsl:variable>
	<!--xsl:copy-of select="$gra/ph"/-->

	<!-- constants OSGR overwrites-->
	<xsl:variable name="legendFontSize"  select="m:Att('legendFontSize', 12)"/>
	
	<!-- constants specific to OSGR-->
	<xsl:variable name="labelInFontSize"  select="$labelFontSize"/>
	<xsl:variable name="labelOutFontSize"  select="$labelFontSize"/>
	<xsl:variable name="labelOutFontWd"  select="0.60"/>
	
	<xsl:variable name="pieRadiusX" select="100"/>  
	<xsl:variable name="pieRadiusY" select="if ($gra/ph/@effect = '3D') then 60 else 100"/>  
	<xsl:variable name="pie3DHg" select="if ($gra/ph/@effect = '3D') then 10 else 0"/>  
	<xsl:variable name="labelInRadiusRatio" select="0.75"/>  
	
	
	<!-- variable calculations-->
	
	<!-- calculation of common variables -->
		<!-- color schemas -->
	<xsl:variable name="colorSch" select="
			if ($gra/ph/@colorScheme = 'black') then $colorSchemeBlack else
			if ($gra/ph/@colorScheme = 'cold') then $colorSchemeCold else
			if ($gra/ph/@colorScheme = 'warm') then $colorSchemeWarm else
			if ($gra/ph/@colorScheme = 'grey') then $colorSchemeGrey else  $colorSchemeColor "/>
		<!-- title and the legend -->
	<xsl:variable name="titleHg"  select="if ($gra/ph/title) then 2*$titleMargin + $titleFontSize else 0"/>
	<xsl:variable name="legendWd"  select="
			if ($gra/ph/@legend = 'left' or $gra/ph/@legend =  'right') then (
				$legendMargin + $legendPictureWd + $legendGap  +
				$legendFontSize * $legendFontWd * 
				max(for $a in ($gra/ph/names/name, '') return string-length($a))
			) else 
			if ($gra/ph/@legend = 'top' or $gra/ph/@legend =  'bottom') then (
				2*$legendMargin + sum(
					for $a in ($gra/ph/names/name) return 
						string-length($a)*$legendFontSize*$legendFontWd +$legendPictureWd +$legendGap +$legendMargin) 
			) else 0			
			"/>	
	<xsl:variable name="legendHg"  select="
			if ($gra/ph/@legend = 'left' or $gra/ph/@legend =  'right') then (
				2*$legendMargin +$legendLineHg * 
				count($gra/ph/names/name)
			) else 
			if ($gra/ph/@legend = 'top' or $gra/ph/@legend =  'bottom') then (
				$legendMargin + $legendLineHg
			) else 0"/>
	<xsl:variable name="legendL"  select="if ($gra/ph/@legend = 'left') then $legendWd else 0"/>
	<xsl:variable name="legendR"  select="if ($gra/ph/@legend = 'right') then $legendWd else 0"/>
	<xsl:variable name="legendT"  select="if ($gra/ph/@legend = 'top') then $legendHg else 0"/>
	<xsl:variable name="legendB"  select="if ($gra/ph/@legend = 'bottom') then $legendHg else 0"/>
	
	<!-- normalization of values of labelIn properties - important if there is no DTD defined -->
	<xsl:variable name="labelIn" select="m:LookUp($gra/ph/@labelIn, ('value', 'percent', 'name'), ('value', 'percent', 'name'), 'none')"/>
	<xsl:variable name="labelOut" select="m:LookUp($gra/ph/@labelOut, ('value', 'percent', 'name'), ('value', 'percent', 'name'), 'none')"/>

	
<!-- division according GRAPHTYPE-->
<xsl:choose>
<xsl:when test="$gra/ph/@graphType = 'pie'">  <!-- ***************graphType = 'pie'-->
	<!-- calculation of variables for pie-->
		<!-- pie graph itselvse -->
	<xsl:variable name="pieValSum" select="sum($gra/ph/values/value)"/>  
	<xsl:variable name="pieTSpace"  select="$graphMargin + 
			(if ($labelOut = 'none') then 0 else 1.5*$labelOutFontSize)"/>  
	<xsl:variable name="pieBSpace"  select="$graphMargin + $pie3DHg +
			(if ($labelOut = 'none') then 0 else 1.5*$labelOutFontSize)"/>	
	<xsl:variable name="pieLSpace"  select="$graphMargin + 
			(if (not ($labelOut = 'none'))  then 
				max((0, (
					for $a in $gra/ph/values/value return (
						string-length(
							if ($labelOut = 'value')  then $a else 
							if ($labelOut = 'percent') then format-number(. div $pieValSum, '0%') else
							if ($labelOut = 'name') then 
								$gra/ph/names/name[count($a/preceding-sibling::value)+1] else '')
						)*$labelOutFontSize*$labelOutFontWd
						- $pieRadiusX - ($pieRadiusX+0.85*$labelOutFontSize)*
							math:sin(2*$pi*(sum($a/preceding-sibling::value) + 0.5*$a) div $pieValSum) )
				))
			else 0)
		"/>  
	<xsl:variable name="pieRSpace"  select="$graphMargin+ 
			(if (not ($labelOut = 'none'))  then 
				max((0, (
					for $a in $gra/ph/values/value return (
						string-length(
							if ($labelOut = 'value')  then $a else 
							if ($labelOut = 'percent') then format-number(. div $pieValSum, '0%') else
							if ($labelOut = 'name') then 
								$gra/ph/names/name[count($a/preceding-sibling::value)+1] else '')
						)*$labelOutFontSize*$labelOutFontWd
						- $pieRadiusX + ($pieRadiusX+0.85*$labelOutFontSize)*
							math:sin(2*$pi*(sum($a/preceding-sibling::value) + 0.5*$a) div $pieValSum) )
				))
			else 0)"/>	
	<xsl:variable name="graphWd"  select="$pieLSpace + 2*$pieRadiusX + $pieRSpace"/>	
	<xsl:variable name="graphHg"  select="$pieTSpace + 2*$pieRadiusY + $pieBSpace"/>
	
	<xsl:variable name="pieXCenter" select="$legendL +  $pieLSpace + $pieRadiusX +
			(if ($gra/ph/@legend = 'top' or $gra/ph/@legend =  'bottom') then 
				max(($legendWd - $graphWd, 0)) div 2     else 0)"/>  
	<xsl:variable name="pieYCenter" select="$titleHg + $legendT + $pieTSpace + $pieRadiusY +
			(if ($gra/ph/@legend = 'left' or $gra/ph/@legend =  'right') then 
				max(($legendHg - $graphHg, 0)) div 2     else 0)"/>  
	
		<!-- ledend items layout for pie type -->
	<xsl:variable name="legendSX" select=" 
			if ($gra/ph/@legend = 'right' or $gra/ph/@legend = 'left') then (
				for $a in $gra/ph/names/name return
					(if ($gra/ph/@legend = 'right') then $graphWd else $legendMargin)
			) else
			if ($gra/ph/@legend = 'top' or $gra/ph/@legend = 'bottom') then (
				for $a in $gra/ph/names/name return (
					$legendMargin + 0.5*max(($graphWd - $legendWd, 0)) +
					sum(	for $b in $a/preceding-sibling::name return 
								(string-length($b)*$legendFontSize*$legendFontWd 
								+$legendPictureWd +$legendGap +$legendMargin)
						  )
				)
			) else ''
			"/>
	<xsl:variable name="legendSY" select=" 
			if ($gra/ph/@legend = 'right' or $gra/ph/@legend = 'left') then (
				for $a in $gra/ph/names/name return
					$titleHg + 0.5*max(($graphHg - $legendHg, 0)) + $legendMargin +
					$legendLineHg * (count($a/preceding-sibling::name) + 0.5)
			) else 
			if ($gra/ph/@legend = 'top' or $gra/ph/@legend = 'bottom') then (
				for $a in $gra/ph/names/name return (
					$titleHg + (if ($gra/ph/@legend = 'bottom') then $graphHg else $legendMargin) +0.5*$legendLineHg
				)
			) else ''
			"/>
		<!-- whole window for pie -->
	<xsl:variable name="width"  select="$legendL + $legendR + 
			(if ($gra/ph/@legend = 'top' or $gra/ph/@legend =  'bottom') then max(($graphWd, $legendWd)) else $graphWd)"/>	
	<xsl:variable name="height"  select="$titleHg +  $legendT + $legendB + 
			(if ($gra/ph/@legend = 'left' or $gra/ph/@legend =  'right') then max(($graphHg, $legendHg)) else $graphHg)"/>	
		
	<!-- begin of the SVG document for pie type-->
	<svg:svg viewBox="0 0 {m:R($width)} {m:R($height)}">
	
	<xsl:call-template name="m:drawDescritptionAndTitle">
		<xsl:with-param name="width" select="$width"/>
	</xsl:call-template>
	
	<!-- the pie graph -->
	<svg:g stroke-width="1" stroke="black" stroke-linejoin="round"> 
	<xsl:for-each select="$gra/ph/values/value">
		<xsl:variable name="sn"  select="count(preceding-sibling::value)"/>
		<xsl:variable name="cn"  select="$sn mod count($colorSch)+1"/>
		<xsl:variable name="cc"  select="if (./@color) then ./@color else $colorSch[$cn]"/>
		
		<xsl:variable name="startS" select="sum(preceding-sibling::value)"/>  
		<xsl:variable name="endS" select="$startS+ (.)"/>  
		<xsl:variable name="sA" select="2*$pi*$startS div $pieValSum"/>  
		<xsl:variable name="eA" select="2*$pi*$endS div $pieValSum"/>  
		<xsl:variable name="laf" select="if (2*(.) &gt; $pieValSum) then 1 else 0"/>  
		<svg:path d="{concat('M', $pieXCenter, ',', $pieYCenter, 
				' l', $pieRadiusX*math:sin($sA), ',',  -$pieRadiusY*math:cos($sA), 
				' a', $pieRadiusX, ',', $pieRadiusY, ' 0 ', $laf, ',1 ', 
					$pieRadiusX*(math:sin($eA) - math:sin($sA)), ',',
					-$pieRadiusY*(math:cos($eA)  - math:cos($sA)), ' z')}" 
				fill="{$cc}"/>
		<xsl:if test="($gra/ph/@effect = '3D') and 
				(($sA &gt; 0.5*$pi and $sA &lt; 1.5*$pi ) or
				 ($eA &gt; 0.5*$pi and $eA &lt; 1.5*$pi ))">
			<xsl:variable name="sAp" select="if ($sA &lt; 0.5*$pi) then 0.5*$pi else $sA"/>  
			<xsl:variable name="eAp" select="if ($eA &gt; 1.5*$pi) then 1.5*$pi else $eA"/>  
			<svg:path d="{concat('M', $pieXCenter +$pieRadiusX*math:sin($sAp), ',', 
							$pieYCenter -$pieRadiusY*math:cos($sAp), 
					' v', $pie3DHg, 
					' a', $pieRadiusX, ',', $pieRadiusY, ' 0 ', $laf, ',1 ', 
					$pieRadiusX*(math:sin($eAp) - math:sin($sAp)), ',',
					-$pieRadiusY*(math:cos($eAp)  - math:cos($sAp)), 
					' v', -$pie3DHg, 
					' a', $pieRadiusX, ',', $pieRadiusY, ' 0 ', $laf, ',0 ', 
					-$pieRadiusX*(math:sin($eAp) - math:sin($sAp)), ',',
					$pieRadiusY*(math:cos($eAp)  - math:cos($sAp)), ' z')}" 
					fill="{$cc}"/>
		</xsl:if>
				<!-- areas in legend -->
		<xsl:if test="not ($gra/ph/@legend = 'none') and ($legendSY[1+$sn] &gt; 0)"> 
			<svg:rect x="{$legendSX[1+$sn]}" y="{$legendSY[1+$sn] - 0.5*$legendPictureHg}"
						width="{$legendPictureWd}" height="{$legendPictureHg}" fill="{$cc}"/> 
		</xsl:if>
	</xsl:for-each>
	</svg:g> 
	
	<xsl:if test="$gra/ph/@effect = '3D'"> 
		<svg:defs>
		<svg:linearGradient id="lg_pie" x1="{$pieXCenter -$pieRadiusX}"   y1="0"   
					x2="{$pieXCenter +$pieRadiusX}" y2="0" gradientUnits="userSpaceOnUse">
			<svg:stop offset="0" stop-opacity="0.6"/>
			<svg:stop offset="0.35" stop-opacity="0" />
			<svg:stop offset="0.5" stop-opacity="0" />
			<svg:stop offset="1" stop-opacity="0.8"/>
		</svg:linearGradient>
		</svg:defs>
		<svg:path d="{concat('M', $pieXCenter +$pieRadiusX, ',', $pieYCenter, 
					' v', $pie3DHg, 
					' a', $pieRadiusX, ',', $pieRadiusY, ' 0 1,1 ', -2*$pieRadiusX, ',0',
					' v', -$pie3DHg, 
					' a', $pieRadiusX, ',', $pieRadiusY, ' 0 1,0 ', 2*$pieRadiusX, ',0', ' z')}" 
					fill="url(#lg_pie)" stroke="none"/>
	</xsl:if>
	
	<!-- values in labelIn - pie-->
	<xsl:if test="(not ($labelIn = 'none'))">
		<svg:g text-anchor="middle" font-family="Verdana" font-size="{$labelInFontSize}" fill="black"> 
		<xsl:for-each select="$gra/ph/values/value">
			<xsl:variable name="sn"  select="count(preceding-sibling::value)"/>
			<xsl:variable name="middleS" select="sum(preceding-sibling::value) + 0.5*(.)"/>  
			<xsl:variable name="mA" select="2*$pi*$middleS div $pieValSum"/>  
			<svg:text x="{$pieXCenter + $pieRadiusX*$labelInRadiusRatio*math:sin($mA)}" 	
					y="{$pieYCenter -$pieRadiusY*$labelInRadiusRatio*math:cos($mA) + 0.35* $labelInFontSize}">
				<xsl:choose>
					<xsl:when test="$labelIn = 'value' ">
						<xsl:value-of select="."/>
					</xsl:when>
					<xsl:when test="$labelIn = 'percent' ">
						<xsl:value-of select="format-number(. div $pieValSum, '0%')"/>
					</xsl:when>
					<xsl:when test="$labelIn = 'name' ">
						<xsl:value-of select="$gra/ph/names/name[1+$sn]"/>
					</xsl:when>
					<xsl:otherwise/> 
				</xsl:choose>
			</svg:text>
		</xsl:for-each> 		
		</svg:g> 
	</xsl:if>
	
	<!-- values in labelOut - pie-->
	<xsl:if test="(not ($labelOut = 'none'))">
		<svg:g  font-family="Verdana" font-size="{$labelOutFontSize}" fill="black"> 
		<xsl:for-each select="$gra/ph/values/value">
			<xsl:variable name="sn"  select="count(preceding-sibling::value)"/>
			<xsl:variable name="middleS" select="sum(preceding-sibling::value) + 0.5*(.)"/>  
			<xsl:variable name="mA" select="2*$pi*$middleS div $pieValSum"/>  
			<svg:text x="{$pieXCenter + ($pieRadiusX+0.85*$labelOutFontSize)*math:sin($mA)}" 	
					y="{$pieYCenter -($pieRadiusY + 0.85*$labelOutFontSize + 
						( if (math:cos($mA) &lt; 0)  then $pie3DHg else 0 )
					)*math:cos($mA) + 0.35* $labelOutFontSize}"
					text-anchor="{if ($mA &lt;= $pi) then 'start' else 'end'}">
				<xsl:choose>
					<xsl:when test="$labelOut = 'value' ">
						<xsl:value-of select="."/>
					</xsl:when>
					<xsl:when test="$labelOut = 'percent' ">
						<xsl:value-of select="format-number(. div $pieValSum, '0%')"/>
					</xsl:when>
					<xsl:when test="$labelOut = 'name' ">
						<xsl:value-of select="$gra/ph/names/name[1+$sn]"/>
					</xsl:when>
					<xsl:otherwise/> 
				</xsl:choose>
			</svg:text>
		</xsl:for-each> 		
		</svg:g> 
	</xsl:if>
	
	<!-- legend for pie-->
	<xsl:if test="(not ($gra/ph/@legend = 'none'))">
		<svg:g text-anchor="start" font-family="Verdana" font-size="{$legendFontSize}" fill="black"> 
		<xsl:for-each select="$gra/ph/names/name">
			<xsl:variable name="sn"  select="count(preceding-sibling::name)"/>
			<!--xsl:variable name="cn"  select="$sn mod count($colorSch)+1"/>
			<xsl:variable name="cc"  select="if (@color) then @color else $colorSch[$cn]"/-->
			<svg:text x="{$legendSX[1+$sn] + $legendPictureWd + $legendGap}" 	
					y="{$legendSY[1+$sn] + 0.35* $legendFontSize}">
				<xsl:value-of select="."/>
			</svg:text>
		</xsl:for-each> 		
		</svg:g>	
	</xsl:if>

	<xsl:call-template name="m:drawFrame">
		<xsl:with-param name="width" select="$width"/>
		<xsl:with-param name="height" select="$height"/>
	</xsl:call-template>
  
	</svg:svg> 
</xsl:when>
<xsl:otherwise>  <!--******************************graphType = 'norm' a other types-->
	<!-- variable calculation for norm type -->
		<!-- X axis - categories -->
	<xsl:variable name="catGap" select="m:Att('categoryGap', 10)"/> 
	<xsl:variable name="colWd" select="m:Att('columnWd', 30)"/> 
	<xsl:variable name="catCount" as="xs:integer" select="count($gra/ph/names/name) cast as xs:integer"/> 
	<xsl:variable name="catWd" select="2*$catGap+$colWd"/> 
	<xsl:variable name="xAxisWd" select="$catCount * $catWd"/>
	<xsl:variable name="maxXLabelWd" select="0.9 * $labelFontSize * $labelFontWd *
			max(for $a in $gra/ph/names/name return string-length($a))"/>
	<xsl:variable name="xLabelRotation" select="if ($maxXLabelWd &gt;= $catWd) then $maxXLabelWd else 0"/>	

		<!-- Y axis -->
	<xsl:variable name="dataMaxY"  select="max($gra/ph/values/value)"/>	
	<xsl:variable name="dataMinY"  select="min($gra/ph/values/value)"/>
	<xsl:variable name="yAxisDim" select="m:CalculateAxisDimension($dataMinY, $dataMaxY, $gra/ph/@yAxisType, $gra/ph/@yAxisMin, $gra/ph/@yAxisMax, $gra/ph/@yAxisStep, $gra/ph/@yAxisMarkCount)"/>
	<xsl:variable name="yAxisStep" select="$yAxisDim[3]"/>
	<xsl:variable name="yAxisMin" select="$yAxisDim[1]"/>
	<xsl:variable name="yAxisMax" select="$yAxisDim[2]"/>
	<xsl:variable name="yAxisLen" select="$yAxisMax - $yAxisMin"/>
	<xsl:variable name="yAxisMarkCount" select="round($yAxisLen div $yAxisStep) cast as xs:integer"/>
	<xsl:variable name="yAxisHg" select="$yAxisMarkCount * $yAxisMarkDist"/>
	<xsl:variable name="yKoef" select="- $yAxisHg div $yAxisLen"/>
	<xsl:variable name="originYShift" select="
			if ($gra/ph/@xAxisPos = 'bottom') then 0 else
			if ($yAxisMin &gt;= 0) then 0 else - min((- $yAxisMin, $yAxisLen)) * $yKoef "/>
	<xsl:variable name="maxYLabelWd" select="$labelFontSize * $labelFontWd *
			max(for $a in (0 to $yAxisMarkCount) return 
				string-length(string-join(m:FormatValue($yAxisMin + $a * $yAxisStep, $yAxisStep, $gra/ph/@yAxisType, $gra/ph/@yAxisLabelsFormat, $gra/ph/@stacked), ''))
			)"/>

		<!-- norm graph itselves -->
	<xsl:variable name="yAxisTSpace"  select="$graphMargin + max(($labelFontSize div 2, $depthY))"/>  
	<xsl:variable name="yAxisBSpace"  select="m:R($graphMargin + 
			max(($labelFontSize div 2, max(($labelFontSize + $majorMarkLen, 
				$xLabelRotation*math:sin($pi*$labelAngle div 180) )) - $originYShift)))"/>	
	<xsl:variable name="xAxisLSpace"  select="$graphMargin + $maxYLabelWd "/>
	<xsl:variable name="xAxisRSpace"  select="m:R($graphMargin + 
			max(($xLabelRotation*math:cos($pi*$labelAngle div 180) -$catWd +$catGap, $depthX)))"/>	
	<xsl:variable name="graphWd"  select="$xAxisLSpace + $xAxisWd + $xAxisRSpace"/>	
	<xsl:variable name="graphHg"  select="$yAxisTSpace + $yAxisHg + $yAxisBSpace"/>
	<xsl:variable name="xAxisLStart"  select="$legendL + $xAxisLSpace + 
			(if ($gra/ph/@legend = 'top' or $gra/ph/@legend =  'bottom') then 
				max(($legendWd - $graphWd, 0)) div 2     else 0)"/>	
	<xsl:variable name="yAxisTStart"  select="$titleHg + $legendT + $yAxisTSpace + 
			(if ($gra/ph/@legend = 'left' or $gra/ph/@legend =  'right') then 
				max(($legendHg - $graphHg, 0)) div 2     else 0)"/>	
	<xsl:variable name="originX"  select="$xAxisLStart"/>	
	<xsl:variable name="originY"  select="$yAxisTStart + $yAxisHg - $originYShift"/>	
	<xsl:variable name="yShift"  select="$yAxisTStart + $yAxisHg - $yKoef * $yAxisMin"/>	

		<!-- legend itmes layout for norm type -->
	<xsl:variable name="legendSX" select=" 
			if ($gra/ph/@legend = 'right' or $gra/ph/@legend = 'left') then (
				for $a in $gra/ph/names/name return
					(if ($gra/ph/@legend = 'right') then $graphWd else $legendMargin)
			) else
			if ($gra/ph/@legend = 'top' or $gra/ph/@legend = 'bottom') then (
				for $a in $gra/ph/names/name return (
					$legendMargin + 0.5*max(($graphWd - $legendWd, 0)) +
					sum(	for $b in $a/preceding-sibling::name return 
								(string-length($b)*$legendFontSize*$legendFontWd 
								+$legendPictureWd +$legendGap +$legendMargin)
						  )
				)
			) else ''
			"/>
	<xsl:variable name="legendSY" select=" 
			if ($gra/ph/@legend = 'right' or $gra/ph/@legend = 'left') then (
				for $a in $gra/ph/names/name return
					$titleHg + 0.5*max(($graphHg - $legendHg, 0)) + $legendMargin +
					$legendLineHg * (count($a/preceding-sibling::name) + 0.5)
			) else 
			if ($gra/ph/@legend = 'top' or $gra/ph/@legend = 'bottom') then (
				for $a in $gra/ph/names/name return (
					$titleHg + (if ($gra/ph/@legend = 'bottom') then $graphHg else $legendMargin) +0.5*$legendLineHg
				)
			) else ''
			"/>
		<!-- whole window for norm type -->
	<xsl:variable name="width"  select="$legendL + $legendR + 
			(if ($gra/ph/@legend = 'top' or $gra/ph/@legend =  'bottom') then max(($graphWd, $legendWd)) else $graphWd)"/>	
	<xsl:variable name="height"  select="$titleHg +  $legendT + $legendB + 
			(if ($gra/ph/@legend = 'left' or $gra/ph/@legend =  'right') then max(($graphHg, $legendHg)) else $graphHg)"/>	
	
	<!-- variables for axis and grids - norm type-->
	<xsl:variable name="LB" select="$gra/ph/@xAxisPos = 'bottom'"/>
	<xsl:variable name="mYpom"  select="				
			if ($LB) then 
				(0 to $yAxisMarkCount)
			else 
				if ($yAxisMin &gt; 0) then (1 to $yAxisMarkCount) else
				if ($yAxisMax &lt; 0) then (0 to $yAxisMarkCount - 1) else 
					(0 to $yAxisMarkCount)   "/>
	
	<!-- start of SVG document -->
	<svg:svg viewBox="0 0 {m:R($width)} {m:R($height)}"> 

	<xsl:call-template name="m:drawDescritptionAndTitle">
		<xsl:with-param name="width" select="$width"/>
	</xsl:call-template>
	

	<!-- major and minor grid for both axes -->
	<xsl:call-template name="m:drawXGrid">  
		<xsl:with-param name="xAxisLStart" select="$xAxisLStart"/>
		<xsl:with-param name="yAxisTStart" select="$yAxisTStart"/>
		<xsl:with-param name="catGap" select="$catGap"/>
		<xsl:with-param name="colWd" select="$colWd"/>
		<xsl:with-param name="catWd" select="$catWd"/>
		<xsl:with-param name="catCount" select="$catCount"/>
		<xsl:with-param name="yAxisHg" select="$yAxisHg"/>
		<xsl:with-param name="originY" select="$originY"/>
		<xsl:with-param name="serCount" select="1"/>
		<xsl:with-param name="shift" select="0"/>
	</xsl:call-template>
	<xsl:call-template name="m:drawYGrid">  
		<xsl:with-param name="xAxisLStart" select="$xAxisLStart"/>
		<xsl:with-param name="yAxisTStart" select="$yAxisTStart"/>
		<xsl:with-param name="xAxisWd" select="$xAxisWd"/>
		<xsl:with-param name="yAxisHg" select="$yAxisHg"/>
		<xsl:with-param name="mYpom" select="$mYpom"/>
	</xsl:call-template>
			
	<!-- drawing of columns -->
	<xsl:if test="not ($gra/ph/@colType = 'none')"> 
		<!-- gradient definition for area filling -->
		<xsl:if test="($gra/ph/@colType = 'cone') or ($gra/ph/@colType = 'cylinder') "> 
			<xsl:variable name="gradLBorder"  select="-0.7"/>
			<xsl:variable name="gradRBorder"  select="0.9"/>
			<svg:defs>
			<xsl:for-each select="$gra/ph/values/value">
				<xsl:variable name="vn"  select="count(preceding-sibling::value)"/>
				<xsl:variable name="cn"  select="$vn mod count($colorSch)+1"/>
				<xsl:variable name="cc"  select="if (./@color) then (./@color) else $colorSch[$cn]"/>
				<xsl:variable name="pomS"  select="if ($gra/ph/@effect = '3D') then -0.5*$depthX else 0"/>
				<svg:linearGradient id="lg{$vn}" x1="{$gradLBorder*$colWd -$pomS}"   y1="0"   
						x2="{$gradRBorder*$colWd -$pomS}" y2="0" gradientUnits="userSpaceOnUse">
				 <svg:stop offset="0" stop-color="#000"/>
				 <svg:stop offset="0.35" stop-color="{$cc}" />
				 <svg:stop offset="1" stop-color="#000"/>
				 </svg:linearGradient>
			</xsl:for-each>
			</svg:defs>
		</xsl:if>
		
		<!-- drawing of columns itselves -->
		<svg:g stroke-width="0.4" stroke="black" stroke-linejoin="round"> 
		<xsl:for-each select="$gra/ph/values/value">
			<xsl:variable name="vn"  select="count(preceding-sibling::value)"/>
			<xsl:variable name="cn"  select="$vn mod count($colorSch)+1"/>
			<xsl:variable name="cc"  select="if (@color) then (@color) else $colorSch[$cn]"/>
			<xsl:variable name="x" select="$xAxisLStart + $catGap + 0.5*$colWd + $vn*$catWd "/>
			<xsl:variable name="y" select="$originY"/>
			
			
			<svg:g transform="translate({m:R($x)}, {$y})"  fill="{
					if ($gra/ph/@colType = 'cone' or $gra/ph/@colType = 'cylinder') then
						concat('url(#lg', $vn, ')') else $cc}" >
			<xsl:call-template name="m:drawCol"> <!-- dwaw a column -->
				<xsl:with-param name="type" select="$gra/ph/@colType"/>
				<xsl:with-param name="effect" select="$gra/ph/@effect"/>
				<xsl:with-param name="color" select="$cc"/>
				<xsl:with-param name="hg" select="$originY - $yShift - $yKoef * (.)"/>
				<xsl:with-param name="tW" select="0"/>
				<xsl:with-param name="bW" select="1"/>
				<xsl:with-param name="colW" select="0.5*$colWd"/>
			</xsl:call-template>
			</svg:g>
			<!-- column of a given type for the legend  -->
			<xsl:if test="not ($gra/ph/@legend = 'none')"> 
				<svg:g transform="translate({$legendSX[1+$vn] + 0.5*$legendPictureWd}, 
							{$legendSY[1+$vn] +0.5*$legendPictureHg})"
						fill="{if ($gra/ph/@colType = 'cone' or $gra/ph/@colType = 'cylinder') then
							concat('url(#lg', $vn, ')') else $cc}" >
				<xsl:call-template name="m:drawColLegend"> <!-- draw a column-->
					<xsl:with-param name="type" select="$gra/ph/@colType"/>
					<xsl:with-param name="effect" select="$gra/ph/@effect"/>
					<xsl:with-param name="color" select="$cc"/>
					<xsl:with-param name="colW" select="0.5*0.5*$colWd"/>
				</xsl:call-template>
				</svg:g>
			</xsl:if>
		</xsl:for-each>
		</svg:g>
	</xsl:if>
	
	<!-- major and minor marks for both axes -->
	<svg:g stroke="black"> 
	<xsl:if test="(not ($gra/ph/@xAxisDivision='none' or $gra/ph/@xAxisDivision='major'))">    <!-- minor marks of X axis -->
		<xsl:variable name="mXMinor"  select="	
				concat('M', $xAxisLStart +$catGap + $colWd div 2, ',', $originY -$minorMarkLen),
				for $a in (1 to $catCount) return 
					concat(' v', $minorMarkLen, ' m', 2*$catGap+$colWd, ',-', $minorMarkLen)"/>   
		<svg:path d="{$mXMinor}" stroke-width="{$minorMarkStroke-width}"/>  
	</xsl:if>
	<xsl:if test="($gra/ph/@xAxisDivision='major' or $gra/ph/@xAxisDivision='both' )">    <!-- major marks of X axis -->
		<xsl:variable name="mXMajor"  select="	
				concat('M', $xAxisLStart, ',', $originY, ' v', $majorMarkLen),
				for $n in (2 to $catCount) return concat('m', $catWd, ',-', $majorMarkLen, ' v', $majorMarkLen)"/>   
		<svg:path d="{$mXMajor}" stroke-width="{$majorMarkStroke-width}"/>  
	</xsl:if>
	<xsl:if test="($yAxisDiv &gt; 1)">    <!-- minor marks for Y axis -->
		<xsl:variable name="mYMinor"  select="
			concat('M', m:R($originX -$minorMarkLen), ',', m:R($yAxisTStart +$yAxisHg -$mYpom[1]*$yAxisMarkDist), 
					' l', m:R(2*$minorMarkLen), ',0 '), 
			if ($gra/ph/@yAxisType='log') then (
				for $a in $mYpom[. != 1], $b in $logDiv return 
					concat('m-', m:R(2*$minorMarkLen), ',-', m:R($yAxisMarkDist*$b), ' l', m:R(2*$minorMarkLen), ',0 ')
			) else (
				for $n in (for $a in (1 to $yAxisDiv) return $mYpom[. != 1]) return 
					concat('m-', m:R(2*$minorMarkLen), ',-', m:R($yAxisMarkDist div $yAxisDiv), ' l', m:R(2*$minorMarkLen), ',0 ')
			)"/>   
		<svg:path d="{$mYMinor}"  stroke-width="{$minorMarkStroke-width}"/>   
	</xsl:if>
	<xsl:if test="($yAxisDiv &gt; 0)">    <!-- major marks for Y axis -->
		<xsl:variable name="mYMajor"  select="	
				concat('M', m:R($originX - $majorMarkLen), ',', m:R($yAxisTStart + $yAxisHg - $mYpom[1] * $yAxisMarkDist),
					' l', m:R(2 * $majorMarkLen), ',0 '),
				for $n in $mYpom[(.) != 1] return 
					concat('m-', m:R(2 * $majorMarkLen), ',-', m:R($yAxisMarkDist), ' l', m:R(2 * $majorMarkLen), ',0 ')
		"/>
		<svg:path d="{$mYMajor}"  stroke-width="{$majorMarkStroke-width}"/> 
	</xsl:if>
	</svg:g>
	
	<!-- X axis with labels -->
	<svg:line x1="{$xAxisLStart}" y1="{$originY}" 
				x2="{$xAxisLStart + $xAxisWd}" y2="{$originY}"
				stroke="black" stroke-width="{$axesStroke-width}"/> 
		<!-- X axis labels -->
	<xsl:if test="not ($xLabelRotation)">
		<svg:g text-anchor="middle" font-family="Verdana" font-size="{$labelFontSize}" fill="black"> 
		<xsl:for-each select="$gra/ph/names/name">
			<xsl:variable name="nn"  select="count(preceding-sibling::name)"/>
			<svg:text x="{$xAxisLStart + ($nn +0.5)*$catWd}" y="{$originY + $majorMarkLen + $labelFontSize}">
			<xsl:value-of select="."/>
			</svg:text>
		</xsl:for-each> 
		</svg:g>
	</xsl:if>
	<xsl:if test="$xLabelRotation"> 
		<svg:g font-family="Verdana" font-size="{$labelFontSize}" fill="black"> 
		<xsl:for-each select="$gra/ph/names/name">
			<xsl:variable name="nn"  select="count(preceding-sibling::name)"/>
			<svg:g transform="translate({m:R($xAxisLStart + ($nn)*$catWd +$catGap)}, 
					{m:R($originY + $majorMarkLen + $labelFontSize)}) rotate({$labelAngle}) ">
			<svg:text>
			<xsl:value-of select="."/>
			</svg:text>
			</svg:g>
		</xsl:for-each>
		</svg:g>
	</xsl:if>
	
	
	<!-- Y axis with labels -->
	<svg:g stroke="black" stroke-width="{$axesStroke-width}">
	<xsl:if test="$mYpom[1] != 0">
		<svg:line stroke-dasharray="2,3"
				x1="{$originX}" y1="{$yAxisTStart + $yAxisHg - $yAxisMarkDist}" 
				x2="{$originX}" y2="{$yAxisTStart + $yAxisHg}" />  
	</xsl:if>
	<svg:line x1="{$originX}" y1="{$yAxisTStart + $yAxisHg - $mYpom[1] * $yAxisMarkDist}" 
					x2="{$originX}" y2="{$yAxisTStart + $yAxisHg - $mYpom[last()]*$yAxisMarkDist}"/>
	<xsl:if test="$mYpom[last()] != $yAxisMarkCount"> 
		<svg:line stroke-dasharray="2,3"
			x1="{$originX}" y1="{$yAxisTStart}" 
			x2="{$originX}" y2="{$yAxisTStart + $yAxisMarkDist}"/>   
	</xsl:if>
	</svg:g>
		<!-- Y axis labels -->
	<xsl:if test="($yAxisDiv &gt; 0)">
		<svg:g text-anchor="end" font-family="Verdana" font-size="{$labelFontSize}" fill="black"> 
		<xsl:for-each  select="(for $a in ($mYpom[. &gt; -1]) return $yAxisMin + $a * $yAxisStep)"> 
			<svg:text x="{m:R($originX - $majorMarkLen - 3)}" y="{m:R($yShift + $yKoef * (.) + 0.35 * $labelFontSize)}">
			<xsl:sequence select="m:FormatValue(., $yAxisStep, $gra/ph/@yAxisType, $gra/ph/@yAxisLabelsFormat, $gra/ph/@stacked)"/>
			</svg:text>
		</xsl:for-each> 
		</svg:g>
	</xsl:if>
	
	<xsl:variable name="pX"  select="$xAxisLStart +$catGap +0.5*$colWd"/>
	<xsl:variable name="normValSum" select="sum($gra/ph/values/value)"/>  
	<!-- drawing of the curve -->
	<xsl:if test="$gra/ph/@lineType != 'none'">
		<xsl:variable name="lp"  select="min(($catCount, count($gra/ph/values/value)))"/>
		<xsl:variable name="sk"  select="0.18"/>
		<xsl:variable name="line"  select="
			concat('M', $pX, ',', m:R($yShift + $yKoef * $gra/ph/values/value[1])), 
			if ($gra/ph/@smooth = 'yes') then (
				(for $a in (1 to $lp -2)  return 
					concat(' S ', m:R($pX +$a*$catWd - 2*$catWd*$sk),
					',', m:R($yShift + $yKoef *($gra/ph/values/value[$a+1] - ($gra/ph/values/value[$a+2] - 
							$gra/ph/values/value[$a])*$sk)),
					' ',  $pX +$a*$catWd,',', m:R($yShift + $yKoef *$gra/ph/values/value[$a+1]) )
				),
				concat (' S ', $pX +($lp -1)*$catWd,',', m:R($yShift + $yKoef *$gra/ph/values/value[$lp])),
				concat ($pX +($lp -1)*$catWd,',', m:R($yShift + $yKoef *$gra/ph/values/value[$lp]))
			) else (
				for $a in (1 to $lp -1)  return 
					concat('L', $pX +$a*$catWd,',', m:R($yShift + $yKoef *$gra/ph/values/value[$a+1]))
			)" /> 
		<svg:path d="{$line}" stroke="black" stroke-width="1.5" fill="none" 
				stroke-linecap="round" stroke-linejoin="round">
			<xsl:if test="$gra/ph/@lineType != 'solid'">
				<xsl:attribute name="stroke-dasharray" select="m:LineType($gra/ph/@lineType)"/>
			</xsl:if>
		</svg:path>
	</xsl:if>
	
	<!-- draw points -->
	<xsl:if test="some $a in ($gra/ph/values/value/@pointType, $gra/ph/@pointType) 
				satisfies $a != 'none'">  
		<svg:g stroke-width="1.5" fill="none" stroke-linecap="round"> 
		<xsl:for-each select="$gra/ph/values/value[(position() &lt;= $catCount) and
				((@pointType != 'none') or ($gra/ph/@pointType != 'none'))]">
			<xsl:variable name="vn"  select="count(preceding-sibling::value)"/>
			<xsl:variable name="cn"  select="$vn mod count($colorSch)+1"/>
			<xsl:variable name="cc"  select="if (@color) then (@color) else $colorSch[$cn]"/>
			<xsl:call-template name="m:drawPoint">  <!-- draw a point (mark) of a given type -->
				<xsl:with-param name="type" select="
						if (@pointType) then @pointType else
							if ($gra/ph/@pointType) then $gra/ph/@pointType else 'none'"/>
					<xsl:with-param name="x" select="$pX + $vn*$catWd "/>
					<xsl:with-param name="y" select="m:R($yShift + $yKoef * (.) )"/>
					<xsl:with-param name="color" select="$cc"/>
				</xsl:call-template>
			<!-- point of a given type for the legend -->
			<xsl:if test="not ($gra/ph/@legend = 'none')">
				<xsl:call-template name="m:drawPoint">  
					<xsl:with-param name="type" select="
							if (@pointType) then @pointType else
							if ($gra/ph/@pointType) then $gra/ph/@pointType else 'none'"/>
					<xsl:with-param name="x" select="$legendSX[1+$vn] + 0.5*$legendPictureWd"/>
					<xsl:with-param name="y" select="$legendSY[1+$vn]"/>
					<xsl:with-param name="color" select="$cc"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:for-each>	
		</svg:g>
	</xsl:if>
	
	<!-- values in labelIn - norm-->
	<xsl:if test="(not ($labelIn = 'none'))">
		<svg:g text-anchor="middle" font-family="Verdana" font-size="{$labelInFontSize}" fill="black"> 
		<xsl:for-each select="$gra/ph/values/value">
			<xsl:variable name="vn"  select="count(preceding-sibling::value)"/>
			<svg:text x="{$pX + $vn*$catWd}" 	
					y="{m:R( 0.5*($originY +$yShift +$yKoef * (.)) + 0.35*$labelInFontSize )}">
				<xsl:choose>
					<xsl:when test="$labelIn = 'value' ">
						<xsl:value-of select="."/>
					</xsl:when>
					<xsl:when test="$labelIn = 'percent' ">
						<xsl:value-of select="format-number(. div $normValSum, '0%')"/>
					</xsl:when>
					<xsl:when test="$labelIn = 'name' ">
						<xsl:value-of select="$gra/ph/names/name[1+$vn]"/>
					</xsl:when>
					<xsl:otherwise/> 
				</xsl:choose>
			</svg:text>
		</xsl:for-each> 		
		</svg:g> 
	</xsl:if>
	
	<!-- values in labelOut - norm-->
	<xsl:if test="(not ($labelOut = 'none'))">
		<svg:g text-anchor="middle" font-family="Verdana" font-size="{$labelOutFontSize}" fill="black"> 
		<xsl:for-each select="$gra/ph/values/value">
			<xsl:variable name="vn"  select="count(preceding-sibling::value)"/>
			<svg:text x="{$pX + $vn*$catWd  +0.5*$depthX}" 	
					y="{m:R($yShift + $yKoef * (.) ) + 
						(if (. &gt;= 0) then (-4 -$depthY) else ($labelOutFontSize +2))}">
				<xsl:choose>
					<xsl:when test="$labelOut = 'value' ">
						<xsl:value-of select="."/>
					</xsl:when>
					<xsl:when test="$labelOut = 'percent' ">
						<xsl:value-of select="format-number(. div $normValSum, '0%')"/>
					</xsl:when>
					<xsl:when test="$labelOut = 'name' ">
						<xsl:value-of select="$gra/ph/names/name[1+$vn]"/>
					</xsl:when>
					<xsl:otherwise/> 
				</xsl:choose>
			</svg:text>
		</xsl:for-each> 		
		</svg:g> 
	</xsl:if>
		
	<!-- legend norm -->
	<xsl:if test="(not ($gra/ph/@legend = 'none'))">
		<svg:g text-anchor="start" font-family="Verdana" font-size="{$legendFontSize}" fill="black"> 
		<xsl:for-each select="$gra/ph/names/name">
			<xsl:variable name="sn"  select="count(preceding-sibling::name)"/>
			<!--xsl:variable name="cn"  select="$sn mod count($colorSch)+1"/>
			<xsl:variable name="cc"  select="if (@color) then @color else $colorSch[$cn]"/-->
			<svg:text x="{$legendSX[1+$sn] + $legendPictureWd + $legendGap}" 	
					y="{$legendSY[1+$sn] + 0.35* $legendFontSize}">
				<xsl:value-of select="."/>
			</svg:text>
		</xsl:for-each> 		
		</svg:g>	
	</xsl:if>
	
	<xsl:call-template name="m:drawFrame">
		<xsl:with-param name="width" select="$width"/>
		<xsl:with-param name="height" select="$height"/>
	</xsl:call-template>

	<!-- debuging frames >
	<svg:rect x="1" y="1" width="{$width - 2}" height="{$titleHg - 2}"  
			stroke="blue" fill="none" stroke-width="1"/> 
	<svg:rect x="{$legendL + 1}" y="{$titleHg + $legendT +1}" width="{$graphWd - 2}" height="{$graphHg - 2}"  
			stroke="red" fill="none" stroke-width="1"/> 
	<svg:rect x="{$legendX - $legendMargin + 1}" y="{$legendY - $legendMargin + 1}" width="{$legendWd - 2}" height="{$legendHg - 2}"  
			stroke="blue" fill="none" stroke-width="1"/> 
	<svg:rect x="0.5" y="{$titleMargin}" width="{$width - 0.5}" height="{$titleFontSize}"  
			stroke="grey" fill="none" stroke-width="1"/> 
	<xsl:if test="(not ($gra/ph/@legend = 'none'))">
		<xsl:for-each select="$gra/ph/values[title]">
			<xsl:variable name="sn"  select="count(preceding-sibling::values)"/>
			<svg:rect x="{$legendSX[$sn+1]}" y="{$legendSY[$sn+1] -0.5*$legendLineHg}" width="{$legendPictureWd}" height="{$legendLineHg}"
					stroke="red" fill="none" stroke-width="1"/> 
		</xsl:for-each> 		
	</xsl:if>
	-->
	
	<!-- debuging prints -->
	<!--svg:text x="{$legendX}" y="{$legendY}" font-family="Verdana" font-size="{$labelFontSize}">
		<xsl:value-of select="m:Round(3999.99, 20)"/>
	</svg:text-->
	
	<!-- print to console -->
	<!-- 
	<xsl:message>
		<xsl:copy-of select="/"/>
	</xsl:message>
	 -->

	</svg:svg> 
</xsl:otherwise>
</xsl:choose>

</xsl:template>

</xsl:stylesheet>

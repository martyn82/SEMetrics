module Main

import IO;
import Map;
import util::Math;

import lang::java::m3::Core;

import Analyze::Code;
import Analyze::Complexity;
import Analyze::Model;
import Analyze::Volume;

import Quality;

import Data::Metrics;

/* Predefined projects */
public loc sample = |project://Sample|;
public loc smallsql = |project://smallsql/src/smallsql/database|;
public loc hsqldb = |project://hsqldb-2.3.1/hsqldb/src|;

/* Analyzes the given project location. */
public Metrics getMetrics( loc project ) {
	M3 model = getModel( project );
	
	Metrics m = metrics( project );
	
	m@complexity  = getComplexityPartitions( model );
	m@volume      = analyzeVolume( model );
	m@clones      = analyzeClones( model );
	m@files       = analyzeFiles( model );
	m@classes     = analyzeClasses( model );
	m@methods     = analyzeMethods( model );
	m@duplication = analyzeDuplication( model );
	m@size        = analyzeSize( model );

	return m;
}

public void analyze( Metrics m ) {
	println( "Analyzability: <rankToScore( getAnalyzabilityRank( m ) )>" );
	println( "Changeability: <rankToScore( getChangeabilityRank( m ) )>" );
	println( "Stability: <rankToScore( getStabilityRank( m ) )>" );
	println( "Testability: <rankToScore( getTestabilityRank( m ) )>" );
	println( "General Maintainability: <rankToScore( getMaintainabilityRank( m ) )>" );
}

/* Analyzes size. */
private tuple[int linesOfCode, int lines, real manDays, real manMonths, real manYears] analyzeSize( M3 model ) {
	files = getFiles( model );
	return <getLinesOfCode( files ), getLineCount( files ), getManDays( files ), getManMonths( files ), getManYears( files )>;
}
/* Analyzes duplication. */
private tuple[int absoluteLOC, real relativeLOC, int cloneCount, int minimumCloneSize] analyzeDuplication( M3 model ) {
	duplications = getDuplicationLOCCounts( model );
	duplicated = getDuplications( model );
	return <
		duplications.absLOC,
		duplications.relLOC,
		size( duplicated.clone ),
		getMinimumCloneSize()
	>;
}
/* Analyzes complexity. */
private tuple[
	tuple[rel[loc method, int complexity] methods, int absoluteLOC, real relativeLOC] low,
	tuple[rel[loc method, int complexity] methods, int absoluteLOC, real relativeLOC] moderate,
	tuple[rel[loc method, int complexity] methods, int absoluteLOC, real relativeLOC] high,
	tuple[rel[loc method, int complexity] methods, int absoluteLOC, real relativeLOC] veryHigh
] analyzeComplexity( M3 model ) {
	partitions = getComplexityPartitions( model );
	return <
		<partitions[1].c, partitions[1].absLOC, partitions[1].relLOC>,
		<partitions[2].c, partitions[2].absLOC, partitions[2].relLOC>,
		<partitions[3].c, partitions[3].absLOC, partitions[3].relLOC>,
		<partitions[4].c, partitions[4].absLOC, partitions[4].relLOC>
	>;
}
/* Analyzes the volume of the model to construct partitions. */
private tuple[
	tuple[rel[loc method, int size] methods, int absoluteLOC, real relativeLOC] small,
	tuple[rel[loc method, int size] methods, int absoluteLOC, real relativeLOC] medium,
	tuple[rel[loc method, int size] methods, int absoluteLOC, real relativeLOC] large,
	tuple[rel[loc method, int size] methods, int absoluteLOC, real relativeLOC] xlarge
] analyzeVolume( M3 model ) {
	partitions = getVolumePartitions( model );
	return <
		<partitions[1].s, partitions[1].absLOC, partitions[1].relLOC>,
		<partitions[2].s, partitions[2].absLOC, partitions[2].relLOC>,
		<partitions[3].s, partitions[3].absLOC, partitions[3].relLOC>,
		<partitions[4].s, partitions[4].absLOC, partitions[4].relLOC>
	>;
}
/* Analyzes the clones from the model. */
private rel[loc method, int cloneStart, int size] analyzeClones( M3 model ) {
	rel[loc method, int cloneStart, int size] result = {};
	duplications = getDuplications( model );
	for ( clone <- duplications.clone ) {
		result += {<clone.method, clone.cloneStart, duplications.clone[clone]>};
	}
	return result;
}
/* Analyzes files from the model. */
private rel[loc file, int size] analyzeFiles( M3 model ) = {<file, getLinesOfCode( file )> | file <- getFiles( model )};
/* Analyzes classes from the model. */
private rel[loc class, int size, real manDays] analyzeClasses( M3 model ) =
	{<class, getLinesOfCode( class ), getManDays( class ) > | class <- getClasses( model )};
/* Analyzes methods from the model. */
private rel[loc method, int size, real manDays, int complexity] analyzeMethods( M3 model ) =
	{< method, getLinesOfCode( method ), getManDays( method ), getMethodComplexity( method )>
		| method <- getMethods( model )};

/* Converts a ranking value to score. */
private str rankToScore( int rank ) {
	switch ( rank ) {
		case 1: return "--";
		case 2: return "-";
		case 3: return "o";
		case 4: return "+";
		case 5: return "++";
	}
}
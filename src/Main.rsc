module Main

import IO;
import Map;
import util::Math;

import lang::java::m3::Core;

import debug::Profiler;

import Quality;

import Analyze::Code;
import Analyze::Complexity;
import Analyze::Model;
import Analyze::Volume;

import Data::Metrics;

/* Predefined projects */
public loc sample = |project://Sample|;
public loc smallsql = |project://smallsql|;
public loc hsqldb = |project://hsqldb-2.3.1|;

/* Analyzes the given project location. */
public Metrics getMetrics( loc project ) {
	log( "Composing metrics for <project>..." );
	
	log( "Create model..." );
	M3 model = getModel( project );
	
	log( "Construct metrics..." );
	Metrics m = metrics( project );
	
	log( "Get complexity partitions..." );
	m@complexity = getComplexityPartitions( model );
	
	log( "Analyze volume..." );
	m@volume = getVolumePartitions( model );
	
	log( "Analyze clones..." );
	m@clones = analyzeClones( model );
	
	log( "Analyze files..." );
	m@files = analyzeFiles( model );
	
	log( "Analyze classes..." );
	m@classes = analyzeClasses( model );
	
	log( "Analyze methods..." );
	m@methods = analyzeMethods( model );
	
	log( "Analyze duplications..." );
	m@duplication = analyzeDuplication( model );
	
	log( "Analyze effort..." );
	m@effort = analyzeEffort( model );

	log( "Done." );
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
private tuple[int linesOfCode, int lines, real manDays, real manMonths, real manYears] analyzeEffort( M3 model ) {
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
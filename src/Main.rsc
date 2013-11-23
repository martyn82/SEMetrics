module Main

import IO;
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
public loc smallsql = |project://smallsql/database|;
public loc hsqldb = |project://hsqldb-2.3.1/src|;

/* Analyzes the given project location. */
public Metrics analyze( loc project ) {
	M3 model = getModel( project );
	
	Metrics m = metrics( project );
	
	m@clones  = analyzeClones( model );
	m@files   = analyzeFiles( model );
	m@classes = analyzeClasses( model );
	m@methods = analyzeMethods( model );

	return m;
	
	//println( "Analyzability: <rankToScore( getAnalyzabilityRank( model ) )>" );
	//println( "Changeability: <rankToScore( getChangeabilityRank( model ) )>" );
	//println( "Stability: <rankToScore( getStabilityRank( model ) )>" );
	//println( "Testability: <rankToScore( getTestabilityRank( model ) )>" );
}

private rel[loc method, int cloneStart, int size] analyzeClones( M3 model ) {
	rel[loc method, int cloneStart, int size] result = {};
	duplications = getDuplications( model );
	for ( clone <- duplications.clone ) {
		result += {<clone.method, clone.cloneStart, duplications.clone[clone]>};
	}
	return result;
}

private rel[loc file, int size] analyzeFiles( M3 model ) = {<file, getLinesOfCode( file )> | file <- getFiles( model )};

private rel[loc class, int size, real manMonths] analyzeClasses( M3 model ) =
	{<class, getLinesOfCode( class ), getManMonths( class ) > | class <- getClasses( model )};

private rel[loc method, int size, real manMonths, int complexity] analyzeMethods( M3 model ) =
	{< method, getLinesOfCode( method ), getManMonths( method ), getMethodComplexity( method )>
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
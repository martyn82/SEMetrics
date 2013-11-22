module Main

import IO;
import util::Math;

import lang::java::m3::Core;

import Analyze::Model;
import Quality;

/* Predefined projects */
public loc sample = |project://Sample|;
public loc smallsql = |project://smallsql/database|;
public loc hsqldb = |project://hsqldb-2.3.1/src|;

/* Ranks given project on maintainability attributes. */
public void analyzeProject( loc project ) {
	M3 model = getModel( project );
	
	println( "Analyzability: <rankToScore( getAnalyzabilityRank( model ) )>" );
	println( "Changeability: <rankToScore( getChangeabilityRank( model ) )>" );
	println( "Stability: <rankToScore( getStabilityRank( model ) )>" );
	println( "Testability: <rankToScore( getTestabilityRank( model ) )>" );
}

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
module Metrics

import IO;

import List;
import Relation;
import Set;
import String;

import lang::java::m3::Core;

import util::FileSystem;
import util::Math;

import Analyze::Clones;
import Analyze::Complexity;
import Analyze::Volume;
import Extract::Parser;
import Extract::Volume;

/* Predefined projects */
public loc smallsql = |project://smallsql|;
public loc sample = |project://Sample|;

public void analyzeProject( loc project ) {
	M3 model = getModel( project );
	set[loc] files = getProjectFiles( model );
	set[loc] classes = getClasses( model );
	set[loc] methods = getMethods( model );
	
	println( "<size(files)> files in project" );
	println( "Volume of project <project>: <getTotalPhysicalLOC( files )>" );
	
	for ( loc f <- files ) {
		println( "Volume of <f>: <getPhysicalLOC( f )>" );
		println( "Man-months of <f>: <getManMonths( f )>" );
	}
	
	for ( loc c <- classes ) {
		println( "Volume of <c>: <getPhysicalLOC( c )>" );
		println( "Man-months of <c>: <getManMonths( c )>" );
	}
	
	for ( loc m <- methods ) {
		println( "Volume of <m>: <getPhysicalLOC( m )>" );
		println( "Man-months of <m>: <getManMonths( m )>" );
		println( "Complexity of <m>: <getMethodComplexity( m )>" );
	}
}

/*
	Partitions the given project into risk areas.
	Returns a mapping from string specifying the risk category to
	a triple consisting of:
	1: A relation of unit locations to their cyclomatic complexity,
	2: The absolute number of LOC,
	3: The relative number of LOC
*/
public map[str, tuple[rel[loc, int], int, int]] complexityPartitions( loc project ) {
	M3 model = getModel( project );
	set[loc] methods = getMethods( model );
	rel[loc location, int complexity] complexities = {};
	
	for ( loc method <- methods ) {
		complexities += {<method, getMethodComplexity( method )>};
	}
	
	int lowSize = 0;
	int midSize = 0;
	int highSize = 0;
	int vHighSize = 0;
	
	rel[loc, int] lows = {};
	rel[loc, int] mids = {};
	rel[loc, int] highs = {};
	rel[loc, int] vhighs = {};

	for ( comp <- complexities ) {
		if ( comp.complexity < 11 ) {
			lowSize += getPhysicalLOC( comp.location );
			lows += {comp};
		}
		
		if ( comp.complexity > 10 && comp.complexity < 21 ) {
			midSize += getPhysicalLOC( comp.location );
			mids += {comp};
		}
		
		if ( comp.complexity > 20 && comp.complexity < 51 ) {
			highSize += getPhysicalLOC( comp.location );
			highs += {comp};
		}

		if ( comp.complexity > 50 ) {
			vHighSize += getPhysicalLOC( comp.location );
			vhighs += {comp};
		}
	}
	
	int totalSize = lowSize + midSize + highSize + vHighSize;
	
	return (
		"low risk" : <lows, lowSize, ( ( lowSize * 100 ) / totalSize )>,
		"moderate risk" : <mids, midSize, ( ( midSize * 100 ) / totalSize )>,
		"high risk" : <highs, highSize, ( ( highSize * 100 ) / totalSize )>,
		"very high risk" : <vhighs, vHighSize, ( ( vHighSize * 100 ) / totalSize )>
	);
}

/* Retrieves the amount of code cloned. */
public tuple[int absLines, int relLines] duplicatedCode( loc project ) {
	M3 model = getModel( project );
	set[loc] files = getProjectFiles( model );
	int totalSize = getTotalPhysicalLOC( files );
	rel[loc method, list[str] lines, int numLines, int numClones] duplications = getClones( model );
	int clonedLines = 0;
	
	for ( duplication <- duplications ) {
		clonedLines += duplication.numLines * duplication.numClones;
	}
	
	return <clonedLines, ( ( clonedLines * 100 ) / totalSize )>;
}

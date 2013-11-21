module Metrics

import IO;
import util::Math;

import lang::java::m3::Core;

import Analyze::Clones;
import Analyze::Complexity;
import Analyze::Volume;
import Extract::Model;
import Extract::Volume;
import Synthesize::Clones;
import Synthesize::Complexity;

/* Predefined projects */
public loc sample = |project://Sample|;
public loc smallsql = |project://smallsql|;
public loc hsqldb = |project://hsqldb-2.3.1|;

/*
Ranks:
	-2: --
	-1: -
	 0: o
	+1: +
	+2: ++
*/
private int plus2 = 2;
private int plus = 1;
private int neutral = 0;
private int minus = -1;
private int minus2 = -2;

/* Ranks given project on maintainability attributes. */
public void rankProject( loc project ) {
	M3 model = getModel( project );
	
	println( "Analyzability: <getAnalyzabilityRank( model )>" );
	println( "Changeability: <getChangeabilityRank( model )>" );
	println( "Stability: <getStabilityRank( model )>" );
	println( "Testability: <getTestabilityRank( model )>" );
}

/* Computes the complexity ranking */
public int getComplexityRank( M3 model ) {
	map[int category, tuple[rel[loc unit, int complexity] c, int absLOC, real relLOC] t] partitions =
		getComplexityPartitions( model );
	
	int midIndex = 2;
	int highIndex = 3;
	int vHighIndex = 4;
	
	real midLOC = partitions[midIndex].relLOC;
	real highLOC = partitions[highIndex].relLOC;
	real vHighLOC = partitions[vHighIndex].relLOC;
	
	if ( midLOC <= 25 && highLOC == 0 && vHighLOC == 0 ) {
		return plus2;
	}
	
	if ( midLOC <= 30 && highLOC < 6 && vHighLOC == 0 ) {
		return plus;
	}
	
	if ( midLOC <= 40 && highLOC <= 10 && vHighLOC == 0 ) {
		return neutral;
	}
	
	if ( midLOC <= 50 && highLOC <= 15 && vHighLOC <= 5 ) {
		return minus;
	}
	
	return minus2;
}

/* Computes the rank of volume. */
public int getVolumeRank( M3 model ) {
	set[loc] files = getProjectFiles( model );
	real manMonths = getManMonths( files );
	int manYears = ceil( manMonths * 12 );
	
	if ( manYears >= 160 ) {
		return minus2;
	}
	
	if ( manYears >= 80 && manYears < 160 ) {
		return minus;
	}
	
	if ( manYears >= 30 && manYears < 80 ) {
		return neutral;
	}
	
	if ( manYears >= 8 && manYears < 30 ) {
		return plus;
	}
	
	return plus2;
}

/* Computes the rank for duplicated code. */
public int getDuplicationRank( M3 model ) {
	tuple[int absLOC, real relLOC] duplicated = getDuplicationLOCCounts( model );
	
	if ( duplicated.relLOC < 3 ) {
		return plus2;
	}
	
	if ( duplicated.relLOC >= 3 && duplicated.relLOC < 5 ) {
		return plus;
	}
	
	if ( duplicated.relLOC >= 5 && duplicated.relLOC < 10 ) {
		return neutral;
	}
	
	if ( duplicated.relLOC >= 10 && duplicated.relLOC < 20 ) {
		return minus;
	}
	
	return minus2;
}

/* Computes the rank for unit size. */
public int getUnitSizeRank( M3 model ) {
	return neutral; // How to determine this one?
}

/* Computes rank for unit testing. */
public int getUnitTestRank( M3 model ) {
	return neutral;
}

/* Computes the rank for analyzability. */
public int getAnalyzabilityRank( M3 model ) {
	int volumeRank = getVolumeRank( model );
	int duplicationRank = getDuplicationRank( model );
	int unitSizeRank = getUnitSizeRank( model );
	int unitTestRank = getUnitTestRank( model );
	
	return ( volumeRank + duplicationRank + unitSizeRank + unitTestRank );
}

/* Computes the rank for changeability. */
public int getChangeabilityRank( M3 model ) {
	int complexityRank = getComplexityRank( model );
	int duplicationRank = getDuplicationRank( model );
	
	return ( complexityRank + duplicationRank );
}

/* Computes the rank for stability. */
public int getStabilityRank( M3 model ) {
	int unitTestRank = getUnitTestRank( model );
	
	return unitTestRank;
}

/* Computes the rank for testability. */
public int getTestabilityRank( M3 model ) {
	int complexityRank = getComplexityRank( model );
	int unitSizeRank = getUnitSizeRank( model );
	int unitTestRank = getUnitTestRank( model );
	
	return ( complexityRank + unitSizeRank + unitTestRank );
}
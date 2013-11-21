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
import Synthesize::Volume;

/* Predefined projects */
public loc sample = |project://Sample|;
public loc smallsql = |project://smallsql/database|;
public loc hsqldb = |project://hsqldb-2.3.1/src|;

/*
Ranks:
	1: --
	2: -
	3: o
	4: +
	5: ++
*/
private int plus2 = 5;
private int plus = 4;
private int neutral = 3;
private int minus = 2;
private int minus2 = 1;

private int complexityRank = 0;
private int unitSizeRank = 0;
private int volumeRank = 0;
private int duplicationRank = 0;
private int unitTestRank = 0;

/* Ranks given project on maintainability attributes. */
public void scoreProject( loc project ) {
	M3 model = getModel( project );
	
	complexityRank = 0;
	unitSizeRank = 0;
	volumeRank = 0;
	duplicationRank = 0;
	unitTestRank = 0;
	
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

/* Computes the complexity ranking */
public int getComplexityRank( M3 model ) {
	if ( complexityRank > 0 ) {
		return complexityRank;
	}

	map[int category, tuple[rel[loc unit, int complexity] c, int absLOC, real relLOC] t] partitions =
		getComplexityPartitions( model );
	
	int midIndex = 2;
	int highIndex = 3;
	int vHighIndex = 4;
	
	real midLOC = partitions[midIndex].relLOC;
	real highLOC = partitions[highIndex].relLOC;
	real vHighLOC = partitions[vHighIndex].relLOC;
	
	if ( midLOC <= 25 && highLOC == 0 && vHighLOC == 0 ) {
		complexityRank = plus2;
		return plus2;
	}
	
	if ( midLOC <= 30 && highLOC < 6 && vHighLOC == 0 ) {
		complexityRank = plus;
		return plus;
	}
	
	if ( midLOC <= 40 && highLOC <= 10 && vHighLOC == 0 ) {
		complexityRank = neutral;
		return neutral;
	}
	
	if ( midLOC <= 50 && highLOC <= 15 && vHighLOC <= 5 ) {
		complexityRank = minus;
		return minus;
	}
	
	complexityRank = minus2;
	return minus2;
}

/* Computes the rank of volume. */
public int getVolumeRank( M3 model ) {
	if ( volumeRank > 0 ) {
		return volumeRank;
	}

	set[loc] files = getProjectFiles( model );
	real manMonths = getManMonths( files );
	int manYears = ceil( manMonths * 12 );
	
	if ( manYears >= 160 ) {
		volumeRank = minus2;
		return minus2;
	}
	
	if ( manYears >= 80 && manYears < 160 ) {
		volumeRank = minus;
		return minus;
	}
	
	if ( manYears >= 30 && manYears < 80 ) {
		volumeRank = neutral;
		return neutral;
	}
	
	if ( manYears >= 8 && manYears < 30 ) {
		volumeRank = plus;
		return plus;
	}
	
	volumeRank = plus2;
	return plus2;
}

/* Computes the rank for duplicated code. */
public int getDuplicationRank( M3 model ) {
	if ( duplicationRank > 0 ) {
		return duplicationRank;
	}
	
	tuple[int absLOC, real relLOC] duplicated = getDuplicationLOCCounts( model );
	
	if ( duplicated.relLOC < 3 ) {
		duplicationRank = plus2;
		return plus2;
	}
	
	if ( duplicated.relLOC >= 3 && duplicated.relLOC < 5 ) {
		duplicationRank = plus;
		return plus;
	}
	
	if ( duplicated.relLOC >= 5 && duplicated.relLOC < 10 ) {
		duplicationRank = neutral;
		return neutral;
	}
	
	if ( duplicated.relLOC >= 10 && duplicated.relLOC < 20 ) {
		duplicationRank = minus;
		return minus;
	}
	
	duplicationRank = minus2;
	return minus2;
}

/* Computes the rank for unit size. */
public int getUnitSizeRank( M3 model ) {
	if ( unitSizeRank > 0 ) {
		return unitSizeRank;
	}
	
	map[int category, tuple[rel[loc unit, int size] s, int absLOC, real relLOC] t] partitions =
		getVolumePartitions( model );
	
	int midIndex = 2;
	int highIndex = 3;
	int vHighIndex = 4;
	
	real midLOC = partitions[midIndex].relLOC;
	real highLOC = partitions[highIndex].relLOC;
	real vHighLOC = partitions[vHighIndex].relLOC;
	
	if ( midLOC <= 25 && highLOC == 0 && vHighLOC == 0 ) {
		unitSizeRank = plus2;
		return plus2;
	}
	
	if ( midLOC <= 30 && highLOC < 6 && vHighLOC == 0 ) {
		unitSizeRank = plus;
		return plus;
	}
	
	if ( midLOC <= 40 && highLOC <= 10 && vHighLOC == 0 ) {
		unitSizeRank = neutral;
		return neutral;
	}
	
	if ( midLOC <= 50 && highLOC <= 15 && vHighLOC <= 5 ) {
		unitSizeRank = minus;
		return minus;
	}
	
	unitSizeRank = minus2;
	return minus2;
}

/* Computes rank for unit testing. */
public int getUnitTestRank( M3 model ) {
	unitTestRank = neutral;
	return neutral;
}

/* Computes the rank for analyzability. */
public int getAnalyzabilityRank( M3 model ) {
	int volumeRank = getVolumeRank( model );
	int duplicationRank = getDuplicationRank( model );
	int unitSizeRank = getUnitSizeRank( model );
	int unitTestRank = getUnitTestRank( model );
	
	return ( volumeRank + duplicationRank + unitSizeRank + unitTestRank ) / 4;
}

/* Computes the rank for changeability. */
public int getChangeabilityRank( M3 model ) {
	int complexityRank = getComplexityRank( model );
	int duplicationRank = getDuplicationRank( model );
	
	return ( complexityRank + duplicationRank ) / 2;
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
	
	return ( complexityRank + unitSizeRank + unitTestRank ) / 3;
}
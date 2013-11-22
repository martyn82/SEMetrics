module Quality

import lang::java::m3::Core;

import Rank;

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
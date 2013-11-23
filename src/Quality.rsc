module Quality

import adt::Metrics;
import Rank;

/* Computes the rank for maintainability in general. */
public int getMaintainabilityRank( Metrics m ) {
	int analyzability = getAnalyzabilityRank( m );
	int changeability = getChangeabilityRank( m );
	int stability     = getStabilityRank( m );
	int testability   = getTestabilityRank( m );
	
	return ( analyzability + changeability + stability + testability ) / 4;
}

/* Computes the rank for analyzability. */
public int getAnalyzabilityRank( Metrics m ) {
	int volumeRank = getVolumeRank( m );
	int duplicationRank = getDuplicationRank( m );
	int unitSizeRank = getUnitSizeRank( m );
	int unitTestRank = getUnitTestRank( m );
	
	return ( volumeRank + duplicationRank + unitSizeRank + unitTestRank ) / 4;
}

/* Computes the rank for changeability. */
public int getChangeabilityRank( Metrics m ) {
	int complexityRank = getComplexityRank( m );
	int duplicationRank = getDuplicationRank( m );
	
	return ( complexityRank + duplicationRank ) / 2;
}

/* Computes the rank for stability. */
public int getStabilityRank( Metrics m ) {
	return getUnitTestRank( m );
}

/* Computes the rank for testability. */
public int getTestabilityRank( Metrics m ) {
	int complexityRank = getComplexityRank( m );
	int unitSizeRank = getUnitSizeRank( m );
	int unitTestRank = getUnitTestRank( m );
	
	return ( complexityRank + unitSizeRank + unitTestRank ) / 3;
}
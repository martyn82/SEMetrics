module Rank

import util::Math;
import Data::Metrics;

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

/* Computes the complexity ranking */
public int getComplexityRank( Metrics m ) {
	c = m@complexity;
	
	if (
		c.moderate.relativeLOC <= 25
		&& c.high.relativeLOC == 0
		&& c.veryHigh.relativeLOC == 0
	) {
		return plus2;
	}
	
	if (
		c.moderate.relativeLOC <= 30
		&& c.high.relativeLOC <= 5
		&& c.veryHigh.relativeLOC == 0
	) {
		return plus;
	}
	
	if (
		c.moderate.relativeLOC <= 40
		&& c.high.relativeLOC <= 10
		&& c.veryHigh.relativeLOC == 0
	) {
		return neutral;
	}
	
	if (
		c.moderate.relativeLOC <= 50
		&& c.high.relativeLOC <= 15
		&& c.veryHigh.relativeLOC <= 5
	) {
		return minus;
	}
	
	return minus2;
}

/* Computes the rank of volume. */
public int getVolumeRank( Metrics m ) {
	real manYears = ( m@size ).manYears;
	
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
public int getDuplicationRank( Metrics m ) {
	duplicated = m@duplication;

	if ( duplicated.relativeLOC < 3 ) {
		return plus2;
	}
	
	if ( duplicated.relativeLOC >= 3 && duplicated.relativeLOC < 5 ) {
		return plus;
	}
	
	if ( duplicated.relativeLOC >= 5 && duplicated.relativeLOC < 10 ) {
		return neutral;
	}
	
	if ( duplicated.relativeLOC >= 10 && duplicated.relativeLOC < 20 ) {
		return minus;
	}
	
	return minus2;
}

/* Computes the rank for unit size. */
public int getUnitSizeRank( Metrics m ) {
	v = m@volume;
	
	if (
		v.medium.relativeLOC <= 25
		&& v.large.relativeLOC == 0
		&& v.xlarge.relativeLOC == 0
	) {
		return plus2;
	}
	
	if (
		v.medium.relativeLOC <= 30
		&& v.large.relativeLOC <= 5
		&& v.xlarge.relativeLOC == 0
	) {
		return plus;
	}
	
	if (
		v.medium.relativeLOC <= 40
		&& v.large.relativeLOC <= 10
		&& v.xlarge.relativeLOC == 0
	) {
		return neutral;
	}
	
	if (
		v.medium.relativeLOC <= 50
		&& v.large.relativeLOC <= 15
		&& v.xlarge.relativeLOC <= 5
	) {
		return minus;
	}
	
	return minus2;
}

/* Computes rank for unit testing. */
public int getUnitTestRank( Metrics m ) {
	return neutral;
}
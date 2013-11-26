module Rank

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

public int getVolumeRank(int linesOfCode) {
	// For now this method only works for Java projects.
	// Here is an implicit conversion to the manyears table mentioned in the paper.
	if (linesOfCode > 1310000 ) {
		return minus2;
    }
    
    if (linesOfCode > 655000) {
        return minus;
    }
    
    if (linesOfCode > 246000) {
        return neutral;
    }
    
    if (linesOfCode > 66000) {
        return plus;
    }
    
    return plus2;
}

public int getComplexityRank(tuple[real low, real moderate, real high, real veryHigh] rc) {
    if (rc.moderate <= 25 && rc.high == 0 && rc.veryHigh == 0) {
        return plus2;
    }
    
    if (rc.moderate <= 30 && rc.high <= 5 && rc.veryHigh == 0) {
        return plus;
    }
    
    if (rc.moderate <= 40 && rc.high <= 10 && rc.veryHigh == 0) {
        return neutral;
    }
    
    if (rc.moderate <= 50 && rc.high <= 15 && rc.veryHigh <= 5) {
        return minus;
    }
    
    return minus2;
}

public int getDuplicationRank(real rd) {
	if (rd >= 20) {
		return minus2;
	}
	
	if (rd >= 10) {
		return minus;
	}
	
	if (rd >= 5) {
		return neutral;
	}
	
	if (rd >= 3) {
		return plus;
	}
	
    return plus2;
}

public int getUnitSizeRank(tuple[real low, real moderate, real high, real veryHigh] rus) {
	// Here the thresholds of the complexity rank are used again. The different threshold values could not be found.
    if (rus.moderate <= 25 && rus.high == 0 && rus.veryHigh == 0) {
        return plus2;
    }
    
    if (rus.moderate <= 30 && rus.high <= 5 && rus.veryHigh == 0) {
        return plus;
    }
    
    if (rus.moderate <= 40 && rus.high <= 10 && rus.veryHigh == 0) {
        return neutral;
    }
    
    if (rus.moderate <= 50 && rus.high <= 15 && rus.veryHigh <= 5) {
        return minus;
    }
    
    return minus2;
}

public int getUnitTestRank() {
	// Not implemented, thus ranked neutral.
	// TODO Dit moet denk ik weg. Beïnvloedt de score misschien te veel?
    return neutral;
}

public str rankToString(int rank) {
	switch (rank) {
		case plus2:   return "++";
		case plus:    return "+";
		case neutral: return "o";
		case minus:   return "-";
		case minus2:  return "--";
	}
}
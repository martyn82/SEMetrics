module Quality

import Rank;

import IO;

public void showMaintainabilityMatrix(int volumeRank, int complexityRank, int duplicationRank, int unitSizeRank, int unitTestRank) {
	println("Volume: <rankToString(volumeRank)>");
	println("Complexity per unit: <rankToString(complexityRank)>");
	println("Duplication: <rankToString(duplicationRank)>");
	println("Unit size: <rankToString(unitSizeRank)>");
	
	println("");
	
	analyzability = getAnalyzabilityRank(volumeRank, duplicationRank, unitSizeRank);
    changeability = getChangeabilityRank(complexityRank, duplicationRank);
    testability   = getTestabilityRank(complexityRank, unitSizeRank);
	
	println("Analysability: <rankToString(analyzability)>");
	println("Changeability: <rankToString(changeability)>");
	println("Stability: ?");
	println("Testability: <rankToString(testability)>");
	
	println("");
	
	score = getMaintainabilityRank(analyzability, changeability, testability);
	println("Maintainability: <rankToString(score)>");
}

private int getMaintainabilityRank(int analyzability, int changeability, int testability) {
    return ( analyzability + changeability + testability ) / 3;
}

private int getAnalyzabilityRank(int volumeRank, int duplicationRank, int unitSizeRank) {
    return ( volumeRank + duplicationRank + unitSizeRank ) / 3;
}

private int getChangeabilityRank(int complexityRank, int duplicationRank) {
    return ( complexityRank + duplicationRank ) / 2;
}

private int getTestabilityRank(int complexityRank, int unitSizeRank) {
    return ( complexityRank + unitSizeRank ) / 2;
}
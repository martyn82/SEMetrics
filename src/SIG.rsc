module SIG

import lang::java::jdt::m3::Core;

import analyze::Volume;
import analyze::Complexity;
import analyze::Duplication;
import analyze::UnitSize;

import Rank;
import Quality;

// Import to print progress.
import IO;
import DateTime;

public loc sample = |project://Sample|;
public loc smallsql = |project://smallsql|;
public loc hsqldb = |project://hsqldb-2.3.1|;

public void calculateMI( loc project )
{
	println("<now()> Working on model...");
	model = createM3FromEclipseProject(project);
	
	// Volume
	println("<now()> Working on Volume...");
	fileAndSourceLines = getSourceLinesOfProject(model);
	
	// Complexity
	println("<now()> Working on Complexity...");
	unitComplexity = calculateUnitComplexity(model);
	
	// Duplication
	println("<now()> Working on Duplication...");
	duplicateSourceLineCount = getDuplicateSourceLinesOfProject(fileAndSourceLines);
	
	// Unit size
	println("<now()> Working on Unit size...");
	unitSize = calculateUnitSize(model, fileAndSourceLines);
	
	//  Create MI.
	println("<now()> Working on MI matrix...");
	
	sourceLineCount = countSourceLinesOfProject(fileAndSourceLines);
	int volumeRank = getVolumeRank(sourceLineCount);
	
	relativeComplexity = countRelativeComplexity(model, unitComplexity, unitSize);
	int complexityRank = getComplexityRank(relativeComplexity);
	
	relativeDuplication = countRelativeDuplication(duplicateSourceLineCount, sourceLineCount);
	int duplicationRank = getDuplicationRank(relativeDuplication);
	
	relativeSize = countRelativeSize(model, unitSize);
	int unitSizeRank = getUnitSizeRank(relativeSize);
	
	int unitTestRank = getUnitTestRank();
	
	println("LOC: <sourceLineCount>");
	println("Rel. CC: <relativeComplexity>");
	println("Dupe LOC: <duplicateSourceLineCount>");
	println("Rel. dup: <relativeDuplication>");
	println("Rel. size: <relativeSize>");
	println("");
	
	showMaintainabilityMatrix(volumeRank, complexityRank, duplicationRank, unitSizeRank, unitTestRank);
}
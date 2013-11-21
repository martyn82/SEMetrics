module Synthesize::Clones

import lang::java::m3::Core;

import Analyze::Clones;
import Extract::Model;
import Extract::Volume;

/* Retrieves the duplicated LOC counts of the given model. */
public tuple[int absLOC, real relLOC] getDuplicationLOCCounts( M3 model ) {
	tuple[map[loc file, set[int] lineNumbers] blockStart, int lineCount] duplications = getDuplications( model );
	
	set[loc] files = getProjectFiles( model );
	int totalLOC = getTotalPhysicalLOC( files );
	
	int duplicatedLines = duplications.lineCount;
	real relativeLineCount = ( duplicatedLines * 100.0 ) / totalLOC;
	
	return <duplicatedLines, relativeLineCount>;
}
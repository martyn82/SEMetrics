module Synthesize::Clones

import lang::java::m3::Core;

import Analyze::Clones;
import Extract::Model;
import Extract::Volume;

/* Retrieves the duplicated LOC counts of the given model. */
public tuple[int absLOC, real relLOC] getDuplicationLOCCounts( M3 model ) {
	lrel[loc methodA, loc methodB, tuple[int, int] block, int numLines] duplications = getCodeClones( model );
	set[loc] files = getProjectFiles( model );
	int totalLOC = getTotalPhysicalLOC( files );
	
	int absLOC = 0;
	
	for ( dup <- duplications ) {
		absLOC += dup.numLines;
	}
	
	real relLOC = ( absLOC * 100.0 ) / totalLOC;
	return <absLOC, relLOC>;
}
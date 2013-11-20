module Synthesize::Complexity

import lang::java::m3::Core;

import Analyze::Complexity;
import Extract::Parser;
import Extract::Volume;

/*
	Partitions the given project into risk areas.
	Returns a mapping from string specifying the risk category to a triple consisting of:
	1: A relation of unit locations to their cyclomatic complexity,
	2: The absolute number of LOC,
	3: The relative number of LOC
*/
public map[int category, tuple[rel[loc unit, int complexity] c, int absLOC, real relLOC] t] getComplexityPartitions( M3 model ) {
	set[loc] methods = getMethods( model );
	rel[loc location, int complexity] complexities = {};
	
	for ( loc method <- methods ) {
		complexities += {<method, getMethodComplexity( method )>};
	}
	
	int lowSize = 0;
	int midSize = 0;
	int highSize = 0;
	int vHighSize = 0;
	
	rel[loc, int] lows = {};
	rel[loc, int] mids = {};
	rel[loc, int] highs = {};
	rel[loc, int] vhighs = {};

	for ( comp <- complexities ) {
		if ( comp.complexity < 11 ) {
			lowSize += getPhysicalLOC( comp.location );
			lows += {comp};
		}
		
		if ( comp.complexity > 10 && comp.complexity < 21 ) {
			midSize += getPhysicalLOC( comp.location );
			mids += {comp};
		}
		
		if ( comp.complexity > 20 && comp.complexity < 51 ) {
			highSize += getPhysicalLOC( comp.location );
			highs += {comp};
		}

		if ( comp.complexity > 50 ) {
			vHighSize += getPhysicalLOC( comp.location );
			vhighs += {comp};
		}
	}
	
	int totalSize = lowSize + midSize + highSize + vHighSize;
	
	return (
		1 : <lows, lowSize, ( ( lowSize * 100.0 ) / totalSize )>,
		2 : <mids, midSize, ( ( midSize * 100.0 ) / totalSize )>,
		3 : <highs, highSize, ( ( highSize * 100.0 ) / totalSize )>,
		4 : <vhighs, vHighSize, ( ( vHighSize * 100.0 ) / totalSize )>
	);
}
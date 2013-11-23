module Analyze::Complexity

import Exception;

import lang::java::jdt::m3::Core;
import lang::java::m3::AST;

import Analyze::Model;
import Analyze::Volume;

/* Retrieves the complexity for the given unit. */
public int getMethodComplexity( loc unit ) = computeComplexity( unit );

/* Computes the cyclomatic complexity of given method location. */
private int computeComplexity( loc unit ) {
	if ( !isMethod( unit ) ) {
		throw IllegalArgument( "Given unit location must be a method: <unit>" );
	}
	
	Declaration method = getMethodASTEclipse( unit );
	int count = 1;

	visit ( method ) {
		case \if(Expression _, Statement _): count += 1;
		case \if(Expression _, Statement _, Statement _): count += 1;
		case \conditional(Expression _, Expression _, Expression _): count += 1;
		
		case \catch(Declaration _, Statement _): count += 1;
		
		case \for(list[Expression] _, Expression _, list[Expression] _, Statement _): count += 1;
		case \for(list[Expression] _, list[Expression] _, Statement _): count += 1;
		case \foreach(Declaration _, Expression _, Statement _): count += 1;
		case \while(Expression _, Statement _): count += 1;
		
		case \switch(Expression _, list[Statement] _): count += 1;
		case \case(Expression _): count += 1;
	};

	return count;
}

/*
	Partitions the given model into risk areas (1 := low, 2 := moderate, 3 := high, 4 := very high).
	Returns a mapping from string specifying the risk category to a triple consisting of:
	1: A relation of unit locations to their cyclomatic complexity,
	2: The absolute number of LOC,
	3: The relative number of LOC
*/
public map[int category, tuple[rel[loc unit, int complexity] c, int absLOC, real relLOC] t] getComplexityPartitions(
	M3 model
) {
	rel[loc location, int complexity] complexities = {<method, getMethodComplexity( method )>
		| method <- getMethods( model )};
	
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
			lowSize += getLinesOfCode( comp.location );
			lows += {comp};
		}
		
		if ( comp.complexity > 10 && comp.complexity < 21 ) {
			midSize += getLinesOfCode( comp.location );
			mids += {comp};
		}
		
		if ( comp.complexity > 20 && comp.complexity < 51 ) {
			highSize += getLinesOfCode( comp.location );
			highs += {comp};
		}

		if ( comp.complexity > 50 ) {
			vHighSize += getLinesOfCode( comp.location );
			vhighs += {comp};
		}
	}
	
	int totalSize = ( lowSize + midSize + highSize + vHighSize ); // Should this be total measured lines or total LOC?
	
	return (
		1 : <lows, lowSize, ( ( lowSize * 100.0 ) / totalSize )>,
		2 : <mids, midSize, ( ( midSize * 100.0 ) / totalSize )>,
		3 : <highs, highSize, ( ( highSize * 100.0 ) / totalSize )>,
		4 : <vhighs, vHighSize, ( ( vHighSize * 100.0 ) / totalSize )>
	);
}
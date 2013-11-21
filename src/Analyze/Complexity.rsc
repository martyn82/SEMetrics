module Analyze::Complexity

import Exception;

import lang::java::jdt::m3::Core;
import lang::java::m3::AST;

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

	return count < 1 ? 1 : count;
}
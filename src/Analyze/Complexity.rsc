module Analyze::Complexity

import Exception;

import lang::java::jdt::m3::Core;
import lang::java::m3::AST;

/* Retrieves the complexity for the given unit. */
public int getMethodComplexity( loc unit ) = computeComplexity( unit );

/* Computes the McCabe complexity of given method location. */
private int computeComplexity( loc unit ) {
	if ( !isMethod( unit ) ) {
		throw IllegalArgument( "Given unit location must be a method: <unit>" );
	}
	
	Declaration method = getMethodASTEclipse( unit );

	/*
	 McCabe formula:
	 C = 2 + I + L + S - R
	 I := number of IF and CATCH conditions
	 L := number of LOOP conditions
	 S := number of SWITCH CASE conditions
	 R := number of RETURN statements (void methods have 0)
	 The constant 2 ensures that C has an absolute minimum of 1.
	 */
	count = 2;

	visit ( method ) {
		// IFs
		case \if(Expression _, Statement _): count += 1;
		case \if(Expression _, Statement _, Statement _): count += 1;
		case \conditional(Expression _, Expression _, Expression _): count += 1;
		
		// CATCHs
		case \catch(Declaration _, Statement _): count += 1;
		
		// LOOPs
		case \for(list[Expression] _, Expression _, list[Expression] _, Statement _): count += 1;
		case \for(list[Expression] _, list[Expression] _, Statement _): count += 1;
		case \foreach(Declaration _, Expression _, Statement _): count += 1;
		case \while(Expression _, Statement _): count += 1;
		case \do(Statement _, Expression _): count += 1;
		
		// CASEs
		case \swtich(Expression _, list[Statement] _): count += 1;
		case \case(Expression _): count += 1;
		
		// RETURNs
		case \return(): count -= 1;
		case \return(Expression _): count -= 1;
	};

	return count < 1 ? 1 : count;
}
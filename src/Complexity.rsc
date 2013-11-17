module Complexity

import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::\syntax::Java15;

import IO;

/* Retrieves the complexity for the given unit. */
public int getComplexity( MethodDec method ) = computeComplexity( method );
public int getComplexity( ConstrDec method ) = computeComplexity( method );

/* Computes the McCabe complexity of given AST */
private int computeComplexity( value method ) {
	/*
	 McCabe formula:
	 C = 2 + I + L + S - R
	 I := number of IF and CATCH conditions
	 L := number of LOOP conditions
	 S := number of SWITCH CASE conditions
	 R := number of RETURN statements (void methods have 0)
	 The constant 2 ensures that C has an absolute minimum of 1.
	 
	 How about ternary statements? e.g.: x > 0 ? 12 : 9;
	 */
	count = 2;

	visit ( method ) {
		// IFs
		case (Stm)`if (<Expr _>) <Stm _>`: count += 1;
		case (Stm)`if (<Expr _>) <Stm _> else <Stm _>`: count += 1;
		
		// CATCHs
		case (CatchClause)`catch (<FormalParam _>) <Block _>`: count += 1;
		
		// LOOPs
		case (Stm)`for (<{Expr ","}* _>; <Expr? _>; <{Expr ","}* _>) <Stm _>`: count += 1;
		case (Stm)`for (<LocalVarDec _>; <Expr? _>; <{Expr ","}* _>) <Stm _>`: count += 1;
		case (Stm)`for (<FormalParam _> : <Expr _>) <Stm _>`: count += 1;
		case (Stm)`while (<Expr _>) <Stm _>`: count += 1;
		case (Stm)`do <Stm _> while (<Expr _>);`: count += 1;

		// CASEs
		case (Stm)`switch (<Expr _>) <SwitchBlock _>`: count += 1;
		case (SwitchLabel)`case <Expr _>:`: count += 1;
		
		// RETURNs
		case (Stm)`return <Expr? _>;`: count -= 1;
	};

	return count > 0 ? count : 1;
}

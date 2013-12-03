module analyze::Complexity

import lang::java::jdt::m3::Core;
import lang::java::m3::AST;

import Set;
import Map;

public tuple[real low, real moderate, real high, real veryHigh] countRelativeComplexity(
	M3 model,
	map[tuple[loc,loc],int] complexity,
	map[tuple[loc,loc],int] size
) {
	// For a java project a unit is a method.
	units = { m | m <- model@declarations, isMethod(m.name) };
	
	low      = (0 | it + size[u] | u <- units, complexity[u] <= 10);
	moderate = (0 | it + size[u] | u <- units, 11 <= complexity[u] && complexity[u] <= 20);
	high     = (0 | it + size[u] | u <- units, 21 <= complexity[u] && complexity[u] <= 50);
	veryHigh = (0 | it + size[u] | u <- units, 51 <= complexity[u]);
	
	totalSize = low + moderate + high + veryHigh;
	return <low * 100.0 / totalSize, moderate * 100.0 / totalSize, high * 100.0 / totalSize, veryHigh * 100.0 / totalSize>;
}

public map[tuple[loc name,loc src] unit, int complexity] calculateUnitComplexity(M3 model)
{
    // For a java project a unit is a method. Initializers appear to be not supported by Rascal M3 yet.
    units = { <m, getMethodASTEclipse(m.name)> | m <- model@declarations, isMethod(m.name) };
    
    return ( unit : getComplexity(ast) | <unit, ast> <- units );
}

private int getComplexity(Declaration ast)
{
	// The Cyclomatic Complexity counts the maximum number of  linearly independent paths.
	// Simplified to counting predicates.
    int c = 1;
    visit (ast)
    {
        case \if(Expression _, Statement _): c += 1;
        case \if(Expression _, Statement _, Statement _): c += 1;
        case \infix(Expression _, str operator, Expression _, list[Expression] _):
        {
        	// McCabe's paper describes compund predicates such as A && B are treated as contributing two to complexity
        	// since without the connective we would have: IF A THEN IF B THEN ...
        	// Here we add 1 because we also count IFs
        	if (operator == "||" || operator == "&&")
        	{
        		c += 1;
        	}
        }
        
     	// Loops
     	case \while(Expression _, Statement _): c += 1;   
        case \foreach(Declaration _, Expression _, Statement _): c += 1;
        case \for(list[Expression] _, Expression _, list[Expression] _, Statement _): c += 1;
        case \for(list[Expression] _, list[Expression] _, Statement _): c += 1;
        case \do(Statement _, Expression _): c += 1;
        
        case \catch(Declaration _, Statement _): c += 1;
        case \case(Expression _): c += 1;
    };
    
    return c;
}
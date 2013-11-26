module analyze::UnitSize

import lang::java::jdt::m3::Core;

import Set;
import List;
import Map;

public tuple[real low, real moderate, real high, real veryHigh] countRelativeSize(M3 model, map[tuple[loc,loc], int] size)
{
	// For a java project a unit is a method.
	units = { m | m <- model@declarations, isMethod(m.name) };
	
	// Here the same thresholds as for complexity are used. The different threshold values could not be found.
	low      = (0 | it + size[u] | u <- units, size[u] <= 10);
	moderate = (0 | it + size[u] | u <- units, 11 <= size[u] && size[u] <= 20);
	high     = (0 | it + size[u] | u <- units, 21 <= size[u] && size[u] <= 50);
	veryHigh = (0 | it + size[u] | u <- units, 51 <= size[u]);
	
	totalSize = low + moderate + high + veryHigh;
	return <low * 100.0 / totalSize, moderate * 100.0 / totalSize, high * 100.0 / totalSize, veryHigh * 100.0 / totalSize>;
}

public map[tuple[loc,loc] unit, int size] calculateUnitSize(M3 model, map[loc, lrel[int,str]] fileAndSourceLines)
{
	// For a java project a unit is a method.
	units = { m | m <- model@declarations, isMethod(m.name) };
	
	// We want to get the location of the file in which the unit is declared.
	// First we take the transitive closure of the @containment relation to get all
	// units in a certain file.
	// Next we enrich all unitnames with file information.
	// Finally we calculate the unit size.
	fileToUnits = { <f,m> | <f,m> <- model@containment++, isCompilationUnit(f), isMethod(m) };
	rel[loc name,loc src] files = { f | f <- model@declarations, isCompilationUnit(f.name) };
	filesMap = toMapUnique(files);
	
	unitToFile = { <u,f> | <f,m> <- fileToUnits
	                     , u <- units
	                     , m == u.name && u.src.uri == filesMap[f].uri };
	unitToFileMap = toMapUnique(unitToFile);
	
	return ( u : getSize(u.src, fileAndSourceLines[unitToFileMap[u]]) | u <- units );
}

private int getSize(loc unit, lrel[int number, str source] sourceLines)
{
	lineNumbers = for (n <- sourceLines<number>)
	{
		if (n < unit.begin.line)
		{
			continue;
		}
		
		append n;
		
		if (n >= unit.end.line)
		{
			break;
		}
	};
	
	return size(lineNumbers);
}
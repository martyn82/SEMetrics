module Volume

import List;

import Code;
import Model;

import lang::java::m3::Core;

/* Retrieves the number of lines of code from the given unit. */
public int getLineCount( loc unit ) = size( getSourceLines( unit ) );

/* Retrieves the total number of lines of code for the given set of files. */
public int getLineCount( set[loc] files ) = (0 | it + getLineCount( f ) | f <- files);

/* Retrieves the number of physical lines of code from the given unit. */ 
public int getLinesOfCode( loc unit ) = size( getNormalizedSourceLines( unit ) );

/* Retrieves the total number of physical lines of code for the given set of files. */
public int getLinesOfCode( set[loc] files ) = (0 | it + getLinesOfCode( f ) | f <- files);

/* Retrieves a relation between a location and its LOC count. */
public rel[loc, int] getUnitLineCounts( set[loc] units ) = ({} | it + {<f, getLineCount( f )>} | f <- units);

/* Retrieves a relation between a location and its physical LOC count. */
public rel[loc, int] getUnitLinesOfCode( set[loc] units ) = ({} | it + {<f, getLinesOfCode( f )>} | f <- units);

/* The number of lines one developer adds each month. */
/*
	8250 LOC per man-year
	8250 / 12 = 687 LOC per man-month
	
	 MY      |  kLOC Java
	0 - 8    |   0 - 66
	8 - 30   |  66 - 246
	30 - 80  | 246 - 665
	80 - 160 | 665 - 1310
	   > 160 |     > 1310
	
	But, there is a caveat with this man-years/man-months metric;
	A project that was recently highly refactored where many complex module code was reduced to far less LOC of more
	simple code. Then the man-months might differ a lot from the actual time that was spent on the program.
*/
private real getFPRatioJava() = 687.0;

/* Retrieves the number of man-months for given unit. */
public real getManMonths( loc unit ) = ( getLinesOfCode( unit ) / getFPRatioJava() );

/* Retrieves the number of man-months for given units. */
public real getManMonths( set[loc] units ) = ( 0.0 | it + getManMonths( unit ) | unit <- units );

/*
	Partitions the given model into volume areas.
	Returns a mapping from int specifying the category (1 := small, 2:= moderate, 3 := large, 4 := very large
	to a triple consisting of:
	1: A relation of unit locations to their volume,
	2: The absolute number of LOC,
	3: The relative number of LOC
*/
public map[int category, tuple[rel[loc unit, int size] s, int absLOC, real relLOC] t] getVolumePartitions( M3 model ) {
	set[loc] methods = getMethods( model );
	rel[loc method, int size] sizes = {};
	
	for ( loc method <- methods ) {
		sizes += {<method, getLinesOfCode( method )>};
	}
	
	int smallSize = 0;
	int midSize = 0;
	int largeSize = 0;
	int vLargeSize = 0;
	
	rel[loc, int] smalls = {};
	rel[loc, int] mids = {};
	rel[loc, int] larges = {};
	rel[loc, int] vLarges = {};
	
	for ( unitSize <- sizes ) {
		if ( unitSize.size < 11 ) {
			smallSize += unitSize.size;
			smalls += {unitSize};
		}
		
		if ( unitSize.size > 10 && unitSize.size < 21 ) {
			midSize += unitSize.size;
			mids += {unitSize};
		}
		
		if ( unitSize.size > 20 && unitSize.size < 51 ) {
			largeSize += unitSize.size;
			larges += {unitSize};
		}
		
		if ( unitSize.size > 50 ) {
			vLargeSize += unitSize.size;
			vLarges += {unitSize};
		}
	}
	
	int totalVolume = ( smallSize + midSize + largeSize + vLargeSize );
	
	return (
		1 : <smalls, smallSize, ( ( smallSize * 100.0 ) / totalVolume )>,
		2 : <mids, midSize, ( ( midSize * 100.0 ) / totalVolume )>,
		3 : <larges, largeSize, ( ( largeSize * 100.0 ) / totalVolume )>,
		4 : <vLarges, vLargeSize, ( ( vLargeSize * 100.0 ) / totalVolume )>
	);
}
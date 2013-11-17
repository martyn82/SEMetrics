module Metrics

import IO;

import List;
import ParseTree;
import Relation;
import Set;
import String;

import util::FileSystem;
import util::Math;

import lang::java::\syntax::Disambiguate;
import lang::java::\syntax::Java15;

import CodeSize;
import Complexity;

/* Predefined projects */
public loc smallsql = |project://smallsql0.21_src|;
public loc sample = |project://Sample|;

/* Get volume metrics of given project as map from unit location to size. */
public rel[loc, int] volume( loc project ) {
	Tree parseTree;
	set[ClassBodyDec] allUnits;
	set[loc] unitLocations;
	rel[loc, int] result = {};
	
	for ( file <- getFiles( project ) ) {
		parseTree = parse( #start[CompilationUnit], file );
		
		allUnits = getClasses( parseTree ) + getAllMethods( parseTree );
		unitLocations = {parseTree@\loc} + {u@\loc | u <- allUnits};
		
		for ( unit <- unitLocations ) {
			result += {<unit, getCodeSize( unit )>};
		}
	}
	
	return result;
}

/* Retrieves the total LOC volume of given project. */
public int totalVolume( loc project ) {
	Tree parseTree;
	list[int] sizes = [];
	
	for ( file <- getFiles( project ) ) {
		parseTree = parse( #start[CompilationUnit], file );
		sizes += getCodeSize( parseTree@\loc );
	}
	
	return (0 | it + i | i <- sizes);
}

/* Retrieves the man months of the given project per unit. */
public rel[loc, int] manMonths( loc project ) {
	/*
		8250 LOC per man-year
		8250 / 12 = 687 LOC per man-month
		
		 MY      |  kLOC Java
		0 - 8    |   0 - 66
		8 - 30   |  66 - 246
		30 - 80  | 246 - 665
		80 - 160 | 665 - 1310
		   > 160 |     > 1310
		
		There is a flaw with this metric;
		A project that was recently highly refactored where many complex module
		code was reduced to far less LOC of simple code. In that case the
		man-months might differ a lot from the actual time that was spent to
		create the program.
	*/
	
	int fpRatio = 687;
	rel[loc, int] result = {};
	rel[loc location, int size] volumes = volume( project );
	int months;
	
	for ( v <- volumes ) {
		months = ceil( v.size / fpRatio );
		result += {<v.location, months>};
	}
	
	return result;
}

/*
	Get complexity metrics for given model as map from unit location
	to complexity index.
*/
public rel[loc, int] complexity( loc project ) {
	rel[loc, int] result = {};
	Tree parseTree;
	
	for ( file <- getFiles( project ) ) {
		parseTree = parse( #start[CompilationUnit], file );

		for ( method <- getAllMethods( parseTree ) ) {
			result += {<method@\loc, getComplexity( method )>};
		}
	}
	
	return result;
}

/*
	Partitions the given project into risk areas.
	Returns a mapping from string specifying the risk category to
	a triple consisting of:
	1: A relation of unit locations to their cyclomatic complexity,
	2: The absolute number of LOC,
	3: The relative number of LOC
*/
public map[str, tuple[rel[loc, int], int, int]] complexityPartitions( loc project ) {
	int lowSize = 0;
	int midSize = 0;
	int highSize = 0;
	int vHighSize = 0;
	
	rel[loc, int] lows = {};
	rel[loc, int] mids = {};
	rel[loc, int] highs = {};
	rel[loc, int] vhighs = {};

	rel[loc location, int complexity] complexities = complexity( project );
		
	for ( comp <- complexities ) {
		if ( comp.complexity < 11 ) {
			lowSize += getCodeSize( comp.location );
			lows += {comp};
		}
		
		if ( comp.complexity > 10 && comp.complexity < 21 ) {
			midSize += getCodeSize( comp.location );
			mids += {comp};
		}
		
		if ( comp.complexity > 20 && comp.complexity < 51 ) {
			highSize += getCodeSize( comp.location );
			highs += {comp};
		}

		if ( comp.complexity > 50 ) {
			vHighSize += getCodeSize( comp.location );
			vhighs += {comp};
		}
	}
	
	int totalSize = lowSize + midSize + highSize + vHighSize;
	
	return (
		"low risk" : <lows, lowSize, ( ( lowSize * 100 ) / totalSize )>,
		"moderate risk" : <mids, midSize, ( ( midSize * 100 ) / totalSize )>,
		"high risk" : <highs, highSize, ( ( highSize * 100 ) / totalSize )>,
		"very high risk" : <vhighs, vHighSize, ( ( vHighSize * 100 ) / totalSize )>
	);
}

/*
	Retrieves code clones in the given project.
	Returns a relation with three parts:
	1: List of strings representing the code block lines that were duplicated.
	2: An integer which is the number of lines of the duplicated block.
	3: An integer representing the number of times the block was duplicated in the project.
*/
public rel[list[str], int, int] duplication( loc project ) {
	Tree parseTree;
	int chunkSize = 6;
	rel[list[str], int, int] result = {};
	
	for ( file <- getFiles( project ) ) {
		parseTree = parse( #start[CompilationUnit], file );
		
		for ( method <- getAllMethods( parseTree ) ) {
			list[str] allLines = [ trim( l ) | l <- readFileLines( method@\loc ) ];
			
			int i = 0;
			while ( i < ( size( allLines ) - chunkSize ) ) {
				list[str] chunk = allLines[ i..( chunkSize + i ) ];
				int timesFound = ( findChunk( chunk, project ) - 1 );
				
				if ( timesFound > 0 ) {
					int found = timesFound;
					int newChunkSize = chunkSize;
					
					while ( found > 0 && newChunkSize <= ( size( allLines ) - i - 1 ) ) {
						newChunkSize += 1;
						chunk = allLines[ i..( newChunkSize + i ) ];
						found = ( findChunk( chunk, project ) - 1 );
					}

					result += {<chunk, size( chunk ), found>};
					i += newChunkSize;
				}
				else {
					i += 1;
				}
			}
		}
	}
	
	return result;
}

private int findChunk( [], _ ) = 1;
private int findChunk( [""], _ ) = 1;
private int findChunk( list[str] chunk, loc project ) {
	int result = 0;
	
	for ( file <- getFiles( project ) ) {
		parseTree = parse( #start[CompilationUnit], file );
		
		for ( method <- getAllMethods( parseTree ) ) {
			lines = [ trim( l ) | l <- readFileLines( method@\loc ) ];
			
			if ( lines == [] ) {
				continue;
			}
			
			if ( [*L, chunk, *Q] := lines ) {
				result += 1;
			}
		}
	}
	
	return result;
}

/* Retrieves the amount of code cloned. */
public tuple[int, int] duplicatedCode( loc project ) {
	rel[list[str] lines, int numLines, int numClones] duplications = duplication( project );
	int clonedLines = 0;
	int totalSize = totalVolume( project );
	
	for ( duplication <- duplications ) {
		clonedLines += duplication.numLines * duplication.numClones;
	}
	
	return <clonedLines, ( ( clonedLines * 100 ) / totalSize )>;
}

/* Retrieves all methods in the given tree. */
private set[ClassBodyDec] getAllMethods( Tree tree ) = getMethods( tree ) + getConstructors( tree );

/* Retrieves all class declaration in the given tree. */
private set[ClassDec] getClasses( Tree tree ) = {c | /ClassDec c := tree};

/* Retrieves all constructor declarations in the given tree. */
private set[ConstrDec] getConstructors( Tree tree ) = {m | /ConstrDec m := tree};

/* Retrieves all method declarations in the given tree. */
private set[MethodDec] getMethods( Tree tree ) = {m | /MethodDec m := tree};

/* Retrieves all source files in the given project. */
private set[loc] getFiles( loc project ) = {f | /file( f ) <- crawl( project ), f.extension == "java"};

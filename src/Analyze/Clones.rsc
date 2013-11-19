module Analyze::Clones

import IO;
import List;
import ListRelation;
import Relation;
import String;

import lang::java::m3::Core;

import Extract::Code;
import Extract::Parser;

/* The minimum chunk size for clone detection. */
private int minChunkSize = 6;

/*
	Duplications should be represented as follows:
	rel[loc origin<start,end>, loc clone<start,end>]
	
	How to find:
	0. Define the condition for a clone: MIN_CLONE_SIZE
	1. Create a lookup table rel[loc method, list[str] lines]
	2. Loop through the table A
		2.1: Loop through the table B
			2.1.1: Take a chunk of MIN_CLONE_SIZE lines from linesA
			2.1.2: If there is a linesB that matches the chunk, then try MIN_CLONE_SIZE+1
			2.1.3: Repeat until there is no more match or no more lines in A or B
			2.1.4: Store the chunk that is a duplicate
			2.1.5: Reset chunk size, try offset + 1
*/

public lrel[loc, loc, int] getCodeClones( M3 model ) {
	lrel[loc, loc, int] result = [];

	rel[loc method, lrel[int, str] lines] tableA = createSourceTableNum( model );
	rel[loc method, lrel[int, str] lines] tableB = createSourceTableNum( model );

	bool match = false;
	int offset = 0;
	int limit = minChunkSize;
	set[loc] methodsPassed = {};
	list[str] chunkA;
	list[str] chunkB;

	for ( entryA <- tableA ) {
		if ( size( entryA.lines ) < ( offset + limit ) ) {
			continue;
		}
		
		chunkA = range( entryA.lines );
		
		for ( entryB <- tableB ) {
			if ( size( entryB.lines ) < ( offset + limit ) ) {
				continue;
			}

			match = false;
			chunkB = range( entryB.lines[offset..(limit + offset)] );

			while ( [*_, chunkB, *_] := chunkA ) {
				match = true;
				limit += 1;

				if ( size( entryB.lines ) < ( offset + limit ) ) {
					limit -= 1;
					break;
				}

				chunkB = range( entryB.lines[offset..(limit + offset)] );
			}

			if ( match ) { // && !( entryA.method == entryB.method && chunkA == chunkB ) ) {
				result += [<entryA.method, entryB.method, size( chunkB )>];
			}
			
			offset = 0;
			limit = minChunkSize;
		}
	}

	return result;
}

public rel[loc origin, loc clone, tuple[int, int] block] getClones( M3 model ) {
	rel[loc method, list[tuple[int, str]] lines] tableA = createSourceTableNum( model );
	rel[loc method, list[tuple[int, str]] lines] tableB = createSourceTableNum( model );
	set[loc] passed = {};
	rel[loc, loc, tuple[int, int]] result = {};

	for ( entryA <- tableA ) {
		if ( size( entryA.lines ) < minChunkSize ) {
			continue;
		}

		for ( entryB <- tableB ) {
			if ( entryB.method in passed || size( entryB.lines ) < minChunkSize ) {
				continue;
			}

			int offset = 0;
			int limit = minChunkSize;
			lrel[int, str] chunkA = entryA.lines[offset..limit];
			
			while ( size( entryA.lines ) >= ( offset + limit ) && size( entryB.lines ) >= ( offset + limit ) ) {
				lrel[int, str] chunkB = entryB.lines[offset..limit];
				
				bool match = false;
				
				while ( [*_, chunkA, *_] := chunkB ) {
					match = true;
					limit += 1;
					
					if ( size( entryA.lines ) < ( limit + offset ) || size( entryB.lines ) < ( limit + offset ) ) {
						break;
					}
					
					chunkA = entryA.lines[offset..limit];
					chunkB = entryB.lines[offset..limit];
				}
				
				if ( match && !( entryA.method == entryB.method && offset == 0 && limit == size( entryA.lines ) ) ) {
					result += {<entryA.method, entryB.method, <offset, (limit + offset)>>};
				}
				
				offset += limit;
				limit = minChunkSize;
				
				if ( size( entryA.lines ) < ( offset + limit ) ) {
					continue;
				}
				
				chunkA = entryA.lines[offset..limit];
			}
		}
		
		passed += {entryA.method};
	}

	return result;
}

/*
	Detects code clones in the given model.
	Returns a relation from method location to cloned block, lines cloned, and number of times cloned.
*/
public rel[loc, list[str], int, int] _getClones( M3 model ) {
	rel[loc, list[str], int, int] result = {};
	rel[loc method, list[str] source] table = createSourceTable( model );
	
	for ( entry <- table ) {
		int offset = 0;
		int limit = minChunkSize;
		list[str] source = entry.source;
		int lineCount = size( source );
		
		while ( lineCount > ( limit + offset ) ) {
			list[str] chunk = source[offset..(limit + offset)];
			int timesFound = ( findChunk( chunk, table ) - 1 );
			
			if ( timesFound > 0 ) {
				int found = timesFound;
				limit += 1;
				
				while ( found > 0 && lineCount > ( limit + offset ) ) {
					chunk = source[offset..(limit + offset)];
					found = ( findChunk( chunk, table ) - 1 );
					limit += 1;
				}
				
				if ( found == 0 ) {
					found = timesFound;
				}
				else {
					offset += minChunkSize;
					limit = minChunkSize;
				}

				result += {<entry.method, chunk, size( chunk ), found>};
			}
			else {
				offset += 1;
				limit = minChunkSize;
			}
		}
	}
	
	return result;
}

public rel[loc, list[tuple[int, str]]] createSourceTableNum( M3 model ) {
	rel[loc, list[tuple[int, str]]] result = {};
	tuple[int, str] lines;
	for ( loc method <- getMethods( model ) ) {
		lines = getNormalizedSourceLinesNumbered( method );
		result += {<method, lines>};
	}
	return result;
}

/* Creates a source table for the given model. */
private rel[loc, list[str]] createSourceTable( M3 model ) =
	{<method, getNormalizedSourceLines( method )> | method <- getMethods( model )};

/* Searches for given chunk within the table and returns the number of occurances. */
private int findChunk( [], _ ) = 1;
private int findChunk( [""], _ ) = 1;
private int findChunk( list[str] chunk, rel[loc method, list[str] source] table ) {
	int result = 0;
	
	for ( entry <- table ) {
		if ( [*_, chunk, *_] := entry.source ) {
			result += 1;
		}
	}
	
	return result;
}
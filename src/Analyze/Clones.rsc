module Analyze::Clones

import IO;
import List;
import Relation;
import String;

import lang::java::m3::Core;

import Extract::Code;
import Extract::Parser;

/* The minimum chunk size for clone detection. */
private int minChunkSize = 6;

/*
	Detects code clones in the given model.
	Returns a relation from method location to cloned block, lines cloned, and number of times cloned.
*/
public rel[loc, list[str], int, int] getClones( M3 model ) {
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
module Analyze::Clones

import List;
import ListRelation;
import String;

import lang::java::m3::Core;

import Extract::Code;
import Extract::Parser;

/* The minimum chunk size for clone detection. */
private int minChunkSize = 6;

/* Cached clones. */
private lrel[loc methodA, loc methodB, tuple[int, int] block, int numLines] clones = [];

/* Detects code clones in the given model. */
public lrel[loc methodA, loc methodB, tuple[int, int] block, int numLines] getCodeClones( M3 model ) {
	if ( size( clones ) > 0 ) {
		return clones;
	}

	rel[loc method, lrel[int, str] lines] tableA = createSourceTableNum( model );
	rel[loc method, lrel[int, str] lines] tableB = tableA;

	int initialOffset = 1;
	int offset = initialOffset;
	int limit = minChunkSize;
	
	rel[loc, int] duplicatedBlocks = {};

	for ( entryA <- tableA ) {
		if ( size( entryA.lines ) < ( offset + limit ) ) {
			continue;
		}
		
		list[str] sourceLines = range( entryA.lines );
		// skip method declaration and closing bracket, will hardly match on clone
		list[str] chunkA = slice( sourceLines, 1, size( sourceLines ) - 2 );

		for ( entryB <- tableB ) {
			while ( size( entryB.lines ) > ( offset + limit ) ) {
				bool match = false;
				lrel[int ,str] chunkB = entryB.lines[offset..(limit + offset)];
				list[str] searchLines = range( chunkB );
	
				while ( [*_, searchLines, *_] := chunkA ) {
					match = true;
	
					if ( size( entryB.lines ) < ( offset + limit + 1 ) ) {
						break;
					}

					limit += 1;
					chunkB = entryB.lines[offset..(limit + offset)];
					searchLines = range( chunkB );
				}
				
				if ( match ) {
					// There was a match, but not anymore.
					// The length of the block is one line less than the last and failed attempt to match.
					limit -= 1;
					chunkB = entryB.lines[offset..(limit + offset)];
					searchLines = range( chunkB );
				}

				if ( match && !( entryA.method == entryB.method && chunkA == searchLines ) ) {
					list[int] lineNumsB = domain( chunkB );

					int cloneStartB = head( lineNumsB );
					int cloneEndB = last( lineNumsB );
					int cloneLength = cloneEndB - cloneStartB + 1; // Method declaration starts at 1

					// Filter out the blocks that were previously recorded, but in different order.
					if (
						<entryA.method, cloneLength> notin duplicatedBlocks
						&& <entryB.method, cloneLength> notin duplicatedBlocks
					 ) {
						duplicatedBlocks += {<entryA.method, cloneLength>};
						clones += [<entryA.method, entryB.method, <cloneStartB, cloneEndB>, cloneLength>];
					}
				}
				
				break; // We should try to match further within the method, without matching on itself.
			}
			
			offset = initialOffset;
			limit = minChunkSize;
		}
	}

	return clones;
}

/* Creates source table numbered. */
private rel[loc, list[tuple[int, str]]] createSourceTableNum( M3 model ) {
	rel[loc, list[tuple[int, str]]] result = {};
	for ( loc method <- getMethods( model ) ) {
		lrel[int, str] lines = getNormalizedSourceLinesNumbered( method );
		result += { <method, lines> };
	}
	return result;
}
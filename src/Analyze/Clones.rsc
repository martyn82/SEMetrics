module Analyze::Clones

import List;
import ListRelation;
import Set;
import String;

import lang::java::m3::Core;

import Extract::Code;
import Extract::Model;
import Extract::Volume;

/* The minimum chunk size for clone detection. */
private int minChunkSize = 6;

/* Cached clones. */
private lrel[loc methodA, loc methodB, tuple[int, int] block, int numLines] clones = [];

/* Retrieves duplications as tuple with a map from file to starting lines, and total count duplicated lines. */
public tuple[map[loc, set[int]], int] getDuplications( M3 model ) {
	int blockSize = 6;

	set[loc] files = getProjectFiles( model );
	lrel[loc file, lrel[int lineNumber, list[str] block] blocks] codeBlocks = getFileBlocks( files, blockSize );
	lrel[loc, int] duplicatedBlocks = [];
	
	int beforeUnion = 0;
	int lastLine = 0;
	loc lastFile = |unknown:///|;

	int duplicatedLines = 0;
	set[list[str]] uniqueBlocks = {};
	
	for ( fileCodeBlock <- codeBlocks ) {
		for ( codeBlock <- fileCodeBlock.blocks ) {
			int beforeUnion = size( uniqueBlocks );
			uniqueBlocks += {codeBlock.block};
			
			if ( beforeUnion == size( uniqueBlocks ) ) {
				if ( lastFile == fileCodeBlock.file && codeBlock.lineNumber == lastLine + 1 ) {
					duplicatedLines += 1;
				}
				else {
					duplicatedLines += blockSize;
					duplicatedBlocks += [<fileCodeBlock.file, codeBlock.lineNumber>];
				}
				
				lastFile = fileCodeBlock.file;
				lastLine = codeBlock.lineNumber;
			}
		}
	}
	
	return <toMap( duplicatedBlocks ), duplicatedLines>;
}

/* Retrieves the blocks per file. */
private lrel[loc, lrel[int, list[str]]] getFileBlocks( set[loc] files, int blockSize ) {
	lrel[loc file, lrel[int lineNumber, list[str] block] blocks] result = [];
	
	for ( loc file <- files ) {
		lrel[int lineNumber, list[str] block] blocks = getCodeBlocks( file, blockSize );
		result += [<file, blocks>];
	}
	
	return result;
}

/* Retrieves code blocks for the given file. */
private lrel[int lineNumber, list[str] block] getCodeBlocks( loc file, int blockSize ) {
	int offset = 0;
	lrel[int lineNumber, str line] fileSource = getNormalizedSourceLinesNumbered( file );
	lrel[int lineNumber, list[str] block] result = [];
	int limit = blockSize;
	
	while ( size( fileSource ) >= ( offset + limit ) ) {
		lrel[int lineNumber, str line] block = fileSource[offset..(offset + limit)];
		list[str] blockLines = range( block );
		int blockStart = head( domain( block ) );

		result += [<blockStart, blockLines>];
		offset += 1;
	}
	
	return result;
}
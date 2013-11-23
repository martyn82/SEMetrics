module analyze::Code

import IO;
import List;
import ListRelation;
import Set;
import String;

import lang::java::m3::Core;

import debug::Profiler;

import analyze::Model;
import analyze::Volume;

private bool inComment = false;
private int lineIndex = -1;
private list[str] lines;

/* Retrieves a list of strings containing the source lines of code. */
public list[str] getSourceLines( loc unit ) = getLinesFromLocation( unit );

/* Retrieves a list of strings containing the normalized source lines of code. */
public list[str] getNormalizedSourceLines( loc unit ) = normalizeSource( getSourceLines( unit ) );

/* Retrieves a list of tuples as the numbered lines of source code for given location. */
public lrel[int, str] getSourceLinesNumbered( loc unit ) {
	int lineNum = 1;
	list[str] lines = getLinesFromLocation( unit );
	
	return for ( str line <- lines ) {
		append <lineNum, line>;
		lineNum += 1;
	};
}

/* Retrieves a list of tuples as the numbered and normalized lines of source code for given location. */
public lrel[int, str] getNormalizedSourceLinesNumbered( loc unit ) =
	normalizeNumberedSource( getSourceLinesNumbered( unit ) );

private map[loc, list[str]] linesCache = ();

/* Retrieves a list of lines from the given unit. */
private list[str] getLinesFromLocation( loc unit ) {
	if ( unit in linesCache ) {
		return linesCache[ unit ];
	}
	
	list[str] lines = readFileLines( unit );
	linesCache[ unit ] = lines;
	return lines;
}

/* Retrieves a list of normalized numbered lines of source code. */
private lrel[int, str] normalizeNumberedSource( list[tuple[int, str]] source ) =
	[<n, trim( l )> | <n, l> <- source, isCode( trim( l ) )];

/* Normalizes the list of lines to physical lines of code. */
private list[str] normalizeSource( list[str] source ) {
	lines = source;
	lineIndex = -1;
	list[str] result = [];
	
	while ( !isEOF() ) {
		str line = getNextLine();
		
		if ( !isCode( line ) ) {
			continue;
		}
		
		result += line;
	}
	
	return result;
}

/* Retrieves the next line from internal cursor. */
private str getNextLine() {
	lineIndex += 1;
	return trim( lines[ lineIndex ] );
}

/* Determines whether the end of the source has been reached. */
private bool isEOF() = ( lineIndex >= ( size( lines ) - 1 ) );

/* Determines whether the given string is actual code. */
private bool isCode( str line ) = ( !isBlank( line ) && !isComment( line ) );

/* Determines whether the given string is blank. */
private bool isBlank( str line ) = ( line == "" );

/* Determines whether the given string is commented. */
private bool isComment( "" ) = inComment;
private bool isComment( str line ) {
	if ( inComment && /\*\/$/ := line ) {
		// within a comment block, line ending occurance of "*/" is comment end.
		inComment = false;
		return true;
	}

	if ( !inComment ) {
		if ( /^\/\// := line ) { // A line starting with "//" is a comment.
			return true;
		}
	
		if ( /^\/\*.[^\*\/]*\*\/$/ := line ) {
			// A line starting with "/*" and ending with "*/" without
			// intermediate comment-endings is a comment.
			return true;
		}
	
		if ( /^\/\*<inside:.*>$/ := line ) {
			if ( !( /\*\/.*/ := inside) ) {
				// A line starting with "/*" and having no comment-ends
				// is a comment block start.
				inComment = true;
				return true;
			}
		}
	}

	return inComment;
}

/* Returns the minimum clone size. */
public int getMinimumCloneSize() = 6;

/* Caching of duplications. */
private map[M3 model, tuple[map[tuple[loc method, int cloneStart] location, int cloneSize] clone, int linesCloned] dupes] dupes = ();
private bool hasDupes( M3 model ) = model in dupes;

/* Retrieves duplications as tuple with a map from file to starting lines, and total count duplicated lines. */
public tuple[map[tuple[loc method, int cloneStart] location, int cloneSize] clone, int linesCloned] getDuplications(
	M3 model
) {
	if ( hasDupes( model ) ) {
		log( "Got duplications from cache." );
		return dupes[ model ];
	}
	
	log( "Start clone detection..." );
	int blockSize = getMinimumCloneSize();

	log( "Getting files..." );
	set[loc] files = getFiles( model );
	
	log( "Getting code blocks..." );
	lrel[loc file, lrel[int lineNumber, list[str] block] blocks] codeBlocks = getFileBlocks( files, blockSize );
	map[tuple[loc, int], int] duplicatedBlocks = ();
	
	int lastLine = 0;
	loc lastFile = |unknown:///|;
	int blockStart = 0;

	set[list[str]] uniqueBlocks = {};
	int duplicatedLines = 0;
	
	log( "Searching for clones..." );
	
	for ( fileCodeBlock <- codeBlocks ) {
		for ( codeBlock <- fileCodeBlock.blocks ) {
			int beforeUnion = size( uniqueBlocks );
			uniqueBlocks += {codeBlock.block};
			
			if ( beforeUnion == size( uniqueBlocks ) ) {
				if ( lastFile == fileCodeBlock.file && codeBlock.lineNumber == lastLine + 1 ) {
					duplicatedBlocks[<lastFile, blockStart>] += 1;
					duplicatedLines += 1;
				}
				else {
					blockStart = codeBlock.lineNumber;
					duplicatedLines += blockSize;
					duplicatedBlocks += ( <fileCodeBlock.file, blockStart> : blockSize );
				}
				
				lastFile = fileCodeBlock.file;
				lastLine = codeBlock.lineNumber;
			}
		}
	}
	
	log( "Clone detection done." );
	
	dupes[model] = <duplicatedBlocks, duplicatedLines>;
	return dupes[model];
}

/* Retrieves the blocks per file. */
private lrel[loc, lrel[int, list[str]]] getFileBlocks( set[loc] files, int blockSize ) =
	[<file, getCodeBlocks( file, blockSize)> | file <- files ];

/* Retrieves code blocks for the given file. */
private lrel[int lineNumber, list[str] block] getCodeBlocks( loc file, int blockSize ) {
	lrel[int lineNumber, str line] fileSource = getNormalizedSourceLinesNumbered( file );
	
	int limit = blockSize;
	int offset = 0;
	
	return while ( size( fileSource ) >= ( offset + limit ) ) {
		lrel[int lineNumber, str line] block = fileSource[offset..(offset + limit)];
		list[str] blockLines = range( block );
		int blockStart = head( domain( block ) );

		append <blockStart, blockLines>;
		offset += 1;
	};
}

/* Retrieves the duplicated LOC counts of the given model. */
public tuple[int absLOC, real relLOC] getDuplicationLOCCounts( M3 model ) {
	tuple[map[tuple[loc file, int blockStart] k, int blockSize] m, int lineCount] duplications = 
		getDuplications( model );
	
	set[loc] files = getFiles( model );
	int totalLOC = getLineCount( files );
	
	int duplicatedLines = duplications.lineCount;
	real relativeLineCount = ( duplicatedLines * 100.0 ) / totalLOC;
	
	return <duplicatedLines, relativeLineCount>;
}
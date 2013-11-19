module Extract::Code

import IO;
import List;
import String;

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
	lrel[int, str] result = [];
	
	for ( str line <- lines ) {
		result += [<lineNum, line>];
		lineNum += 1;
	}
	
	return result;
}

/* Retrieves a list of tuples as the numbered and normalized lines of source code for given location. */
public lrel[int, str] getNormalizedSourceLinesNumbered( loc unit ) =
	normalizeNumberedSource( getSourceLinesNumbered( unit ) );

/* Retrieves a list of lines from the given unit. */
private list[str] getLinesFromLocation( loc unit ) = readFileLines( unit );

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
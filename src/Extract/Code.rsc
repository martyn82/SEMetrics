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

/* Retrieves a list of lines from the given unit. */
private list[str] getLinesFromLocation( loc unit ) = readFileLines( unit );

/* Normalizes the list of lines to physical lines of code. */
private list[str] normalizeSource( list[str] source ) {
	lines = source;
	lineIndex = -1;
	list[str] result = [];
	
	while ( !isEOF() ) {
		str line = getNextLine();
		
		if ( isCode( line ) ) {
			result += line;
		}
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
private bool isComment( str line ) {
	if ( line == "" ) {
		return inComment;
	}
	
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
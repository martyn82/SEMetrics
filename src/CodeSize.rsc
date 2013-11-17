module CodeSize

import IO;
import List;
import Map;
import String;

private bool inComment = false;
private int lineIndex = -1;
private list[str] lines;

/* Retrieves the size of the given location. */
public int getCodeSize( loc unit ) = countLinesOfCode( readFileLines( unit ) );

/* Computes the LOC for the given list of string source code lines. */
private int countLinesOfCode( list[str] source ) {
	lines = source;
	lineIndex = -1;
	count = 0;
	
	while ( !isEOF() ) {
		line = getNextLine();
		
		if ( isCode( line ) ) {
			count += 1;
		}
	}
	
	return count;
}

/* Retrieves the next line from internal cursor. */
private str getNextLine() {
	lineIndex += 1;
	return trim( lines[ lineIndex ] );
}

/* Determines whether the end of the source has been reached. */
private bool isEOF() = (lineIndex >= (size( lines ) - 1));

/* Determines whether the given string is actual code. */
private bool isCode( str line ) = ( !isBlank( line ) && !isComment( line ) );

/* Determines whether the given string is blank. */
private bool isBlank( str line ) = (line == "");

/* Determines whether the given string is a single bracket. */
private bool isBracket( str line ) = (line == "}" || line == "{");

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

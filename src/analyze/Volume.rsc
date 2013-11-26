module analyze::Volume

import lang::java::jdt::m3::Core;

import IO;

import Set;
import List;
import Map;
import String;

public int countSourceLinesOfProject(map[loc, lrel[int,str]] fileAndSourceLines)
{
	return (0 | it + size(fileAndSourceLines[file]) | loc file <- fileAndSourceLines);
}

public map[loc file, lrel[int number, str source] lines] getSourceLinesOfProject(M3 model)
{
	set[loc] files = files(model);
	return ( f : getSourceCodeLines(f, model) | f <- files );
}

private lrel[int number, str source] getSourceCodeLines(loc file, M3 model)
{
	lines = readFileLines(file);
	
	lineCount = size(lines);
	numberedLines = zip([1..lineCount+1], lines); // One-based index.
	
	/*
	 * To transform lines to sourcelines:
	 * 1 strip documentation,
	 * 2 strip empty lines.
	 */
	fileComments = { d.comments | d <- model@documentation, d.definition == file };
	return for (tuple[int index, str source] l <- numberedLines)
	{
		// strip documentation
		relevantComments = { d | loc d <- fileComments, d.begin.line <= l.index && d.end.line >= l.index };
		int offset = 0;
		undocumented = for (d <- sort(relevantComments, bool(loc a, loc b){ return a.offset < b.offset; }))
		{
			// Part of multiline.
			if (d.begin.line < l.index && l.index < d.end.line)
			{
				offset = size(l.source);
				continue;
			}
			
			// Start of comment, append source from offset to begin of comment.
			if (d.begin.line == l.index)
			{
				append l.source[offset..d.begin.column];
			}
			
			// End of comment, move offset.
			if (d.end.line != l.index)
			{
				offset = size(l.source);
				continue;
			}
			else
			{
				length = size(l.source);
				if (d.end.column == length)
				{
					offset = length;
				}
				else
				{
					offset = d.end.column;
				}
				
				continue;
			}
		};
		
		sourceLine = offset == size(l.source)
			? ("" | it + e | e <- undocumented)
			: ("" | it + e | e <- undocumented + l.source[offset..]);
		
		trimmedSourceLine = trim(sourceLine);
		if (!isEmpty(trimmedSourceLine))
		{
			append <l.index, trimmedSourceLine>;
		}
	};
}
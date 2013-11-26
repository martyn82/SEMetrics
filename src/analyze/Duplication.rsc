module analyze::Duplication

import lang::java::jdt::m3::Core;

import Set;
import List;
import Map;

public real countRelativeDuplication(int duplicateSourceLineCount, int sourceLineCount)
{
	return duplicateSourceLineCount * 100.0 / sourceLineCount;
}

public int getDuplicateSourceLinesOfProject(map[loc, lrel[int,str]] fileAndSourceLines)
{
	// Create code blocks as <block of sourceLines, <file, index>>.
	codeBlocks = [*getBlocks(file, fileAndSourceLines[file]) | loc file <- fileAndSourceLines];
	
	// Put codeBlocks in a dictionary, to get collisions aka duplicates.
	codeBlocksMap = toMap(codeBlocks);	
	duplicateCodeBlocks = { *codeBlocksMap[block] | list[str] block <- codeBlocksMap, size(codeBlocksMap[block]) > 1 };
	
	// Put duplicateCodeBlocks in a dictionary to get <file, indices>
	duplicateCodeBlocksMap = toMap(duplicateCodeBlocks);	
	return (0 | it + countDuplicateLines(duplicateCodeBlocksMap[file]) | loc file <- duplicateCodeBlocksMap);
}

private int countDuplicateLines(set[int] indices)
{
	length = size(indices);
	if (length == 0)
	{
		return 0;
	}
	elseif (length == 1)
	{
		return 6;
	}
	else
	{
		// Sort indices
		sIndices = sort(indices);
		
		// Get head and iterate over tail.
		begin = head(sIndices);
		count = 6;
		
		for (i <- tail(sIndices))
		{
			if (i < (begin + 6))
			{
				count += (i - begin);
			}
			else
			{
				count += 6;
			}
			
			begin = i;
		}
	
		return count;
	}
}

private lrel[list[str], tuple[loc,int]] getBlocks(loc file, lrel[int number, str source] sourceLines)
{
	length = size(sourceLines);
	
	int index = 0;
	int blockSize = 6;
	
	return while (length >= (index + blockSize))
	{
		lines = [line.source | line <- sourceLines[index..(index+blockSize)]];
		append <lines, <file, index>>;
		
		index += 1;
	};
}

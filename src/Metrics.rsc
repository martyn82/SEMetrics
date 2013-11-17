module Metrics

import IO;

import List;
import ParseTree;
import Relation;
import Set;
import String;

import util::FileSystem;
import util::Math;

import lang::java::\syntax::Disambiguate;
import lang::java::\syntax::Java15;

import Extract::Parser;
import Extract::Volume;
import Analyze::Volume;
import Analyze::Complexity;

/* Predefined projects */
public loc smallsql = |project://smallsql|;
public loc sample = |project://Sample|;

private rel[loc file, Tree tree] parseTrees = {};
private set[loc] projectFiles = {};

public void analyzeJavaProject( loc project ) {
	projectFiles = getJavaFiles( project );
	Tree tree;
	
	println( "<size(projectFiles)> files" );
	println("Volume of project <project>: <getTotalPhysicalLOC( projectFiles )>");
	
	for ( loc f <- projectFiles ) {
		println( "Volume of file <f>: <getPhysicalLOC( f )>");
		println( "Man-months of file <f>: <getManMonths( f )>" );
	
		tree = getTreeOfFile( f );
	}
	
	for ( loc method <- getAllMethods( parseTrees.tree ) ) {
		println("Volume of method <method>: <getPhysicalLOC( method )>");
		println("Man-months of method <method>: <getManMonths( method )>");
		println("Complexity of method <method>: <getComplexity( method )>");
	}
	
	for ( loc cls <- getClasses( parseTrees.tree ) ) {
		println("Volume of class <cls>: <getPhysicalLOC( cls )>");
		println("Man-months of class <cls>: <getManMonths( cls )>");
	}
}

/* Retrieves a parse tree from given file. */
public Tree getTreeOfFile( loc file ) {
	for ( t <- parseTrees ) {
		if ( t.file == file ) {
			return t.tree;
		}
	}
	
	Tree tree = getParseTree( file );
	parseTrees += {<file, tree>};
	return tree;
}

/*
	Get complexity metrics for given model as map from unit location
	to complexity index.
*/
public rel[loc, int] complexity( loc project ) {
	rel[loc, int] result = {};
	Tree parseTree;
	
	for ( file <- getJavaFiles( project ) ) {
		parseTree = parse( #start[CompilationUnit], file );

		for ( method <- getAllMethods( parseTree ) ) {
			result += {<method@\loc, getComplexity( method )>};
		}
	}
	
	return result;
}

/*
	Partitions the given project into risk areas.
	Returns a mapping from string specifying the risk category to
	a triple consisting of:
	1: A relation of unit locations to their cyclomatic complexity,
	2: The absolute number of LOC,
	3: The relative number of LOC
*/
public map[str, tuple[rel[loc, int], int, int]] complexityPartitions( loc project ) {
	int lowSize = 0;
	int midSize = 0;
	int highSize = 0;
	int vHighSize = 0;
	
	rel[loc, int] lows = {};
	rel[loc, int] mids = {};
	rel[loc, int] highs = {};
	rel[loc, int] vhighs = {};

	rel[loc location, int complexity] complexities = complexity( project );
		
	for ( comp <- complexities ) {
		if ( comp.complexity < 11 ) {
			lowSize += getPhysicalLOC( comp.location );
			lows += {comp};
		}
		
		if ( comp.complexity > 10 && comp.complexity < 21 ) {
			midSize += getPhysicalLOC( comp.location );
			mids += {comp};
		}
		
		if ( comp.complexity > 20 && comp.complexity < 51 ) {
			highSize += getPhysicalLOC( comp.location );
			highs += {comp};
		}

		if ( comp.complexity > 50 ) {
			vHighSize += getPhysicalLOC( comp.location );
			vhighs += {comp};
		}
	}
	
	int totalSize = lowSize + midSize + highSize + vHighSize;
	
	return (
		"low risk" : <lows, lowSize, ( ( lowSize * 100 ) / totalSize )>,
		"moderate risk" : <mids, midSize, ( ( midSize * 100 ) / totalSize )>,
		"high risk" : <highs, highSize, ( ( highSize * 100 ) / totalSize )>,
		"very high risk" : <vhighs, vHighSize, ( ( vHighSize * 100 ) / totalSize )>
	);
}

/*
	Retrieves code clones in the given project.
	Returns a relation with three parts:
	1: List of strings representing the code block lines that were duplicated.
	2: An integer which is the number of lines of the duplicated block.
	3: An integer representing the number of times the block was duplicated in the project.
*/
//public rel[list[str], int, int] duplication( loc project ) {
//	Tree parseTree;
//	int chunkSize = 6;
//	rel[list[str], int, int] result = {};
//	
//	for ( file <- getFiles( project ) ) {
//		parseTree = parse( #start[CompilationUnit], file );
//		
//		for ( method <- getAllMethods( parseTree ) ) {
//			list[str] allLines = [ trim( l ) | l <- readFileLines( method@\loc ) ];
//			
//			int i = 0;
//			while ( i < ( size( allLines ) - chunkSize ) ) {
//				list[str] chunk = allLines[ i..( chunkSize + i ) ];
//				int timesFound = ( findChunk( chunk, project ) - 1 );
//				
//				if ( timesFound > 0 ) {
//					int found = timesFound;
//					int newChunkSize = chunkSize;
//					
//					while ( found > 0 && newChunkSize <= ( size( allLines ) - i - 1 ) ) {
//						newChunkSize += 1;
//						chunk = allLines[ i..( newChunkSize + i ) ];
//						found = ( findChunk( chunk, project ) - 1 );
//					}
//
//					result += {<chunk, size( chunk ), found>};
//					i += newChunkSize;
//				}
//				else {
//					i += 1;
//				}
//			}
//		}
//	}
//	
//	return result;
//}

//private int findChunk( [], _ ) = 1;
//private int findChunk( [""], _ ) = 1;
//private int findChunk( list[str] chunk, loc project ) {
//	int result = 0;
//	
//	for ( file <- getFiles( project ) ) {
//		Tree parseTree = parse( #start[CompilationUnit], file );
//		
//		for ( MethodDec method <- getAllMethods( parseTree ) ) {
//			list[str] lines = [ trim( l ) | l <- readFileLines( method@\loc ) ];
//			
//			if ( lines == [] ) {
//				continue;
//			}
//			
//			if ( [*L, chunk, *Q] := lines ) {
//				result += 1;
//			}
//		}
//	}
//	
//	return result;
//}

/* Retrieves the amount of code cloned. */
//public tuple[int, int] duplicatedCode( loc project ) {
//	rel[list[str] lines, int numLines, int numClones] duplications = duplication( project );
//	int clonedLines = 0;
//	int totalSize = totalVolume( project );
//	
//	for ( duplication <- duplications ) {
//		clonedLines += duplication.numLines * duplication.numClones;
//	}
//	
//	return <clonedLines, ( ( clonedLines * 100 ) / totalSize )>;
//}

/* Retrieves all methods in the given tree. */
//private set[ClassBodyDec] getAllMethods( Tree tree ) = getMethods( tree ) + getConstructors( tree );

/* Retrieves all class declaration in the given tree. */
//private set[ClassDec] getClasses( Tree tree ) = {c | /ClassDec c := tree};

/* Retrieves all constructor declarations in the given tree. */
//private set[ConstrDec] getConstructors( Tree tree ) = {m | /ConstrDec m := tree};

/* Retrieves all method declarations in the given tree. */
//private set[MethodDec] getMethods( Tree tree ) = {m | /MethodDec m := tree};

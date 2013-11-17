module Extract::Parser

import ParseTree;

import lang::java::\syntax::Disambiguate;
import lang::java::\syntax::Java15;

import util::FileSystem;

/* Retrieves a parse tree from given file. */
public Tree getParseTree( loc file ) = parse( #start[CompilationUnit], file );

/* Retrieves a set of java locations in the given project. */
public set[loc] getJavaFiles( loc project ) = getProjectFiles( project, "java" );

/* Retrieves a set of file locations for the given project and file name extension. */
private set[loc] getProjectFiles( loc project, str ext ) = {f | /file( f ) <- crawl( project ), f.extension == ext};

/* Retrieves a set of class locations from the given trees. */
public set[loc] getClasses( set[Tree] trees ) = ({} | it + getClassesFromTree( t ) | t <- trees);

/* Retrieves a set of method and constructor locations from the given trees. */
public set[loc] getAllMethods( set[Tree] trees ) = getMethods( trees ) + getConstructors( trees );

/* Retrieves a set of method locations from the given trees. */
public set[loc] getMethods( set[Tree] trees ) = ({} | it + getMethodsFromTree( t ) | t <- trees);

/* Retrieves a set of constructor locations from the given trees. */
public set[loc] getConstructors( set[Tree] trees ) = ({} | it + getConstructorsFromTree( t ) | t <- trees);

/* Retrieves a set of method locations from the given tree. */
public set[loc] getMethodsFromTree( Tree tree ) = {m@\loc | /MethodDec m := tree};

/* Retrieves a set of constructor locations from the given tree. */
public set[loc] getConstructorsFromTree( Tree tree ) = {m@\loc | /ConstrDec m := tree};

/* Retrieves a set of class locations from the given tree. */
public set[loc] getClassesFromTree( Tree tree ) = {c@\loc | /ClassDec c := tree};

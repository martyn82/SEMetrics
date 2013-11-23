module analyze::Model

import lang::java::jdt::m3::Core;

/* Retrieves a M3 model from the given project. */
public M3 getModel( loc project ) = createM3FromEclipseProject( project );

/* Retrieves a set of file locations for the given model and file name extension. */
public set[loc] getFiles( M3 model ) = files( model );

/* Retrieves a set of class locations from the given model. */
public set[loc] getClasses( M3 model ) = classes( model ) + interfaces( model );

/* Retrieves a set of method and constructor locations from the model. */
public set[loc] getMethods( M3 model ) = methods( model );

/* Retrieves a set of interface locations from the model. */
public set[loc] getInterfaces( M3 model ) = interfaces( model );
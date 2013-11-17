module Extract::Volume

import List;

import Extract::Code;

/* Retrieves the number of lines of code from the given unit. */
public int getLOC( loc unit ) = size( getSourceLines( unit ) );

/* Retrieves the number of physical lines of code from the given unit. */ 
public int getPhysicalLOC( loc unit ) = size( getNormalizedSourceLines( unit ) );

/* Retrieves the total number of lines of code for the given set of files. */
public int getTotalLOC( set[loc] files ) = (0 | it + getLOC( f ) | f <- files);

/* Retrieves the total number of physical lines of code for the given set of files. */
public int getTotalPhysicalLOC( set[loc] files ) = (0 | it + getPhysicalLOC( f ) | f <- files);

/* Retrieves a relation between a location and its LOC count. */
public rel[loc, int] getUnitToLOC( set[loc] units ) = ({} | it + {<f, getLOC( f )>} | f <- units);

/* Retrieves a relation between a location and its physical LOC count. */
public rel[loc, int] getUnitToPhysicalLOC( set[loc] units ) = ({} | it + {<f, getPhysicalLOC( f )>} | f <- units);
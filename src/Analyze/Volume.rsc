module Analyze::Volume

import Extract::Volume;

/* The number of lines one developer adds each month. */
/*
	8250 LOC per man-year
	8250 / 12 = 687 LOC per man-month
	
	 MY      |  kLOC Java
	0 - 8    |   0 - 66
	8 - 30   |  66 - 246
	30 - 80  | 246 - 665
	80 - 160 | 665 - 1310
	   > 160 |     > 1310
	
	But, there is a caveat with this man-years/man-months metric;
	A project that was recently highly refactored where many complex module code was reduced to far less LOC of more
	simple code. Then the man-months might differ a lot from the actual time that was spent on the program.
*/
private real fpRatioJava = 687.0;

/* Retrieves the number of man-months for given unit. */
public real getManMonths( loc unit ) = ( getPhysicalLOC( unit ) / fpRatioJava );

/* Retrieves the number of man-months for given units. */
public real getManMonths( set[loc] units ) = (0.0 | it + getManMonths( unit ) | unit <- units);
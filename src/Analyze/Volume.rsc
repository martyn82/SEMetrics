module Analyze::Volume

import util::Math;

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
*/
private int fpRatioJava = 687;

/* Retrieves the number of man months for given unit. */
/*
	There is a flaw with this metric;
	A project that was recently highly refactored where many complex module code was reduced to far less LOC of more
	simple code. Then the man-months might differ a lot from the actual time that was spent on the program.
*/
public int getManMonths( loc unit ) = ceil( getPhysicalLOC( unit ) / fpRatioJava );
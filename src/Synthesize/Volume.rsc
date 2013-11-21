module Synthesize::Volume

import lang::java::m3::Core;

import Extract::Model;
import Extract::Volume;

/*
	Partitions the given model into volume areas.
	Returns a mapping from int specifying the category (1 := small, 2:= moderate, 3 := large, 4 := very large
	to a triple consisting of:
	1: A relation of unit locations to their volume,
	2: The absolute number of LOC,
	3: The relative number of LOC
*/
public map[int category, tuple[rel[loc unit, int size] s, int absLOC, real relLOC] t] getVolumePartitions( M3 model ) {
	set[loc] methods = getMethods( model );
	rel[loc method, int size] sizes = {};
	
	for ( loc method <- methods ) {
		sizes += {<method, getPhysicalLOC( method )>};
	}
	
	int smallSize = 0;
	int midSize = 0;
	int largeSize = 0;
	int vLargeSize = 0;
	
	rel[loc, int] smalls = {};
	rel[loc, int] mids = {};
	rel[loc, int] larges = {};
	rel[loc, int] vLarges = {};
	
	for ( unitSize <- sizes ) {
		if ( unitSize.size < 11 ) {
			smallSize += unitSize.size;
			smalls += {unitSize};
		}
		
		if ( unitSize.size > 10 && unitSize.size < 21 ) {
			midSize += unitSize.size;
			mids += {unitSize};
		}
		
		if ( unitSize.size > 20 && unitSize.size < 51 ) {
			largeSize += unitSize.size;
			larges += {unitSize};
		}
		
		if ( unitSize.size > 50 ) {
			vLargeSize += unitSize.size;
			vLarges += {unitSize};
		}
	}
	
	int totalVolume = ( smallSize + midSize + largeSize + vLargeSize );
	
	return (
		1 : <smalls, smallSize, ( ( smallSize * 100.0 ) / totalVolume )>,
		2 : <mids, midSize, ( ( midSize * 100.0 ) / totalVolume )>,
		3 : <larges, largeSize, ( ( largeSize * 100.0 ) / totalVolume )>,
		4 : <vLarges, vLargeSize, ( ( vLargeSize * 100.0 ) / totalVolume )>
	);
}
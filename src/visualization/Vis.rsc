module visualization::Vis

import lang::java::jdt::m3::Core;

import analyze::Complexity;
import analyze::UnitSize;
import analyze::Volume;

import vis::Figure;
import vis::Render;

import visualization::Containers;
import visualization::Blocks;

public str containers = "containers";
public str treemap = "treemap";

private M3 modelObj;
private map[loc,int] complexityObj;
private map[loc,int] sizeObj;

public void visualize( loc project ) {
	modelObj = createM3FromEclipseProject( project );
	complexityObj = loadComplexities( modelObj );
	sizeObj = loadMethodSizes( modelObj );

	render(
		"Choose...",
		vcat( [
			button(
				"Show complexities as containers",
				void() {
					drawContainers( modelObj, complexityObj, sizeObj );
				}
			),
			button(
				"Show complexities as treemap",
				void() {
					drawBlocks( modelObj, complexityObj, sizeObj );
				}
			)
		] )
	);
}

public map[loc, int] loadComplexities( M3 model ) {
	unitComplexities = calculateUnitComplexity( model );
	complexities = ();
	for ( unit <- unitComplexities ) {
		complexities[ unit.name ] = unitComplexities[ unit ];
	}
	return complexities;
}

public map[loc, int] loadMethodSizes( M3 model ) {
	fileSourceLines = getSourceLinesOfProject( model );
	unitSizes = calculateUnitSize( model, fileSourceLines );
	sizes = ();
	for ( unit <- unitSizes ) {
		sizes[ unit.name ] = unitSizes[ unit ];
	}
	return sizes;
}
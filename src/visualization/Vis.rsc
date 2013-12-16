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

public void visualize( loc project ) {
	model = createM3FromEclipseProject( project );
	complexities = loadComplexities( model );
	sizes = loadMethodSizes( model );

	render(
		"Choose...",
		vcat( [
			button(
				"Show complexities as containers",
				void() {
					drawContainers( model, complexities, sizes );
				}
			),
			button(
				"Show complexities as treemap",
				void() {
					drawBlocks( model, complexities, sizes );
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
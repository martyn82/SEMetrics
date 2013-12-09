module visualization::Blocks

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

import List;

import vis::Figure;
import vis::Render;
import vis::KeySym;

import analyze::Complexity;
import analyze::UnitSize;
import analyze::Volume;

import util::Editors;

import IO;

public void draw( loc project ) {
	model = createM3FromEclipseProject( project );
	draw( model, "Project analysis" );
}

public void draw( M3 model, str title ) {
	complexities = loadComplexities( model );
	sizes = loadMethodSizes( model );
	
	methodLocs = (m : l | <m,l> <- model@declarations, isMethod( m ));
	str message = "\<Hover over a node to view information\>";
	
	figures = for ( method <- methods( model ) ) {
		bool hover = false;
		int complexity = complexities[ method ];
		loc methodLocation = methodLocs[ method ];
		int methodSize = sizes[ method ];
		loc methodName = method;
		
		append box(
			size( 20, 19 + methodSize ),
			fillColor( getMethodColor( complexity ) ),
			lineWidth( 1 ),
			lineColor( Color () {
				return hover ? color( "black", .3 ) : color( "white" );
			} ),
			onMouseEnter( void () {
				hover = true;
				message = "Method: <methodName>\nComplexity: <complexity>\nSize: <methodSize>\n";
			} ),
			onMouseExit( void () {
				hover = false;
			} ),
			onMouseDown(
				bool ( int button, map[ KeyModifier, bool] modifiers ) {
					edit( methodLocation );
					return false;
				}
			)
		);
	};
	
	header = box(
		text( title, fontSize( 20 ), fontColor( "white" ), left() ),
		fillColor( rgb( 1, 128, 62 ) ),
		lineWidth( 0 ),
		height( 40 ),
		vresizable( false )
	);
	
	infobox = box(
		text( str () { return message; }, fontSize( 12 ), fontColor( "white" ), left() ),
		fillColor( rgb( 1, 38, 19 ) ),
		lineWidth( 0 ),
		height( 50 ),
		vresizable( false )
	);
	
	render(
		vcat( [header] + pack( figures ) + [infobox] )
	);
}

private map[loc, int] loadComplexities( M3 model ) {
	complexities = ();
	unitComplexities = calculateUnitComplexity( model );
	for ( item <- unitComplexities ) {
		complexities[ item.name ] = unitComplexities[ item ];
	}
	return complexities;
}

private map[loc, int] loadMethodSizes( M3 model ) {
	sizes = ();
	fileAndSourceLines = getSourceLinesOfProject(model);
	unitSizes = calculateUnitSize( model, fileAndSourceLines );
	for ( item <- unitSizes ) {
		sizes[ item.name ] = unitSizes[ item ];
	}
	return sizes;
}

private Color from = color( "yellow" );
private Color to = color( "red" );

private Color getMethodColor( int complexity ) {
	return interpolateColor( from, to, ( complexity * 100 / 5000.0 ) );
}

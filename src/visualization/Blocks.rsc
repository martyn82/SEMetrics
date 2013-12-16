module visualization::Blocks

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

import List;
import Map;
import Set;

import vis::Figure;
import vis::Render;
import vis::KeySym;

import util::Editors;

import IO;

public void drawBlocks( M3 model, map[loc, int] complexities, map[loc,int] sizes ) {
	methodLocs = (m : l | <m,l> <- model@declarations, isMethod( m ));
	classLocs = (c : l | <c, l> <- model@declarations, isClass( c ));
	
	str message = "\<Hover over a node to view information\>";
	
	figures = for ( class <- classes( model ) ) {
		bool classHover = false;
		loc classLocation = classLocs[ class ];
		loc className = class;
		set[loc] classMethods = {m | <c, m> <- model@containment, c == class, isMethod( m )};
		int methodCount = size( classMethods );
		
		mFigures = for ( method <- classMethods ) {
			bool hover = false;
			int complexity = complexities[ method ];
			loc methodLocation = methodLocs[ method ];
			int methodSize = sizes[ method ];
			loc methodName = method;
			
			append box(
				area( 19 + methodSize ),
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
				onMouseDown( bool ( int button, map[ KeyModifier, bool ] modifiers ) {
					edit( methodLocation );
					return true;
				} )
			);
		};
		
		append box(
			treemap( mFigures ),
			area( 10 + methodCount ),
			gap( 1 ),
			lineWidth( 1 ),
			fillColor( color( "black", .2 ) ),
			lineColor( Color () {
				return classHover ? color( "black", 1.0 ) : color( "black", .3 );
			} ),
			onMouseEnter( void () {
				classHover = true;
				message = "Class: <className>\nNumber of methods: <methodCount>\n";
			} ),
			onMouseExit( void () {
				classHover = false;
			} ),
			onMouseDown( bool ( int button, map[ KeyModifier, bool ] modifiers ) {
				edit( classLocation );
				return true;
			} )
		);
	};
	
	infobox = box(
		text( str () { return message; }, fontSize( 12 ), fontColor( "white" ), left() ),
		fillColor( rgb( 1, 38, 19 ) ),
		lineWidth( 0 ),
		height( 50 ),
		vresizable( false )
	);
	
	render(
		"TreeMap",
		vcat( [treemap( figures ), infobox] )
	);
}

private Color from = color( "yellow" );
private Color to = color( "red" );
private Color getMethodColor( int complexity ) = interpolateColor( from, to, ( complexity * 100 / 5000.0 ) );

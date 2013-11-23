module debug::Profiler

import DateTime;
import IO;

private bool isEnabled = true;

public void enable( bool v ) {
	isEnabled = v;
}

public void log( str msg ) {
	if ( !isEnabled ) {
		return;
	}
	
	println( "<now()> <msg>" );
}
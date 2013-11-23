module Data::Metrics

data Metrics = metrics( loc id );

/* Volume partitions. */
anno tuple[
	tuple[rel[loc method, int size] methods, int absoluteLOC, real relativeLOC] small,
	tuple[rel[loc method, int size] methods, int absoluteLOC, real relativeLOC] medium,
	tuple[rel[loc method, int size] methods, int absoluteLOC, real relativeLOC] large,
	tuple[rel[loc method, int size] methods, int absoluteLOC, real relativeLOC] xlarge
] Metrics@volume;

/* Complexity partitions. */
anno tuple[
	tuple[rel[loc method, int complexity] methods, int absoluteLOC, real relativeLOC] low,
	tuple[rel[loc method, int complexity] methods, int absoluteLOC, real relativeLOC] moderate,
	tuple[rel[loc method, int complexity] methods, int absoluteLOC, real relativeLOC] high,
	tuple[rel[loc method, int complexity] methods, int absoluteLOC, real relativeLOC] veryHigh
] Metrics@complexity;

/* Duplication */
anno tuple[int absoluteLOC, real relativeLOC, int cloneCount, int minimumCloneSize] Metrics@duplication;
/* Size */
anno tuple[int linesOfCode, int lines] Metrics@size;
/* Clones */
anno rel[loc method, int cloneStart, int size] Metrics@clones;
/* Files */
anno rel[loc file, int size] Metrics@files;
/* Classes */
anno rel[loc class, int size, real manDays] Metrics@classes;
/* Interfaces */
anno rel[loc interface, int size, real manDays] Metrics@interfaces;
/* Methods */
anno rel[loc method, int size, real manDays, int complexity] Metrics@methods;

@memo public tuple[
	tuple[rel[loc method, int size] methods, int absoluteLOC, real relativeLOC] small,
	tuple[rel[loc method, int size] methods, int absoluteLOC, real relativeLOC] medium,
	tuple[rel[loc method, int size] methods, int absoluteLOC, real relativeLOC] large,
	tuple[rel[loc method, int size] methods, int absoluteLOC, real relativeLOC] xlarge
] volume( Metrics m ) = m@volume;

@memo public tuple[
	tuple[rel[loc method, int complexity] methods, int absoluteLOC, real relativeLOC] low,
	tuple[rel[loc method, int complexity] methods, int absoluteLOC, real relativeLOC] moderate,
	tuple[rel[loc method, int complexity] methods, int absoluteLOC, real relativeLOC] high,
	tuple[rel[loc method, int complexity] methods, int absoluteLOC, real relativeLOC] veryHigh
] complexity( Metrics m ) = m@complexity;

@memo public tuple[int absoluteLOC, real relativeLOC, int cloneCount, int minimumCloneSize] duplication( Metrics m ) =
	m@duplication;
@memo public tuple[int linesOfCode, int lines] size( Metrics m ) = m@size;
@memo public rel[loc method, int cloneStart, int size] clones( Metrics m ) = m@clones;
@memo public rel[loc file, int size] files( Metrics m ) = m@files;
@memo public rel[loc class, int size, real manDays] classes( Metrics m ) = m@classes;
@memo public rel[loc interface, int size, real manDays] interfaces( Metrics m ) = m@interfaces;
@memo public rel[loc method, int size, real manDays, int complexity] methods( Metrics m ) = m@methods;

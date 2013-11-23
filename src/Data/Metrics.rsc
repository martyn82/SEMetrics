module Data::Metrics

data Metrics = metrics( loc id );

anno rel[loc method, int cloneStart, int size] Metrics@clones;
anno rel[loc file, int size] Metrics@files;
anno rel[loc class, int size, real manMonths] Metrics@classes;
anno rel[loc method, int size, real manMonths, int complexity] Metrics@methods;

@memo public rel[loc method, int cloneStart, int size] clones( Metrics m ) = {};
@memo public rel[loc file, int size] files( Metrics m ) = {};
@memo public rel[loc class, int size, real manMonths] classes( Metrics m ) = {};
@memo public rel[loc method, int size, real manMonths, int complexity] methods( Metrics m ) = {};
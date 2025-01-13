"\n\n*** vessel & NTMI for UdK 50 performance.\n\n".postln;
"\n\n*** assumes NTMI is already loaded.\n\n".postln;

~vessel = ~vessel ? ();
~vessel.dir = ~vessel.dir ? thisProcess.nowExecutingPath.dirname;

LoadMe("vessel.scd", ~vessel.dir);

// other LoadMes here



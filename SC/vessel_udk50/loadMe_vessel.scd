"\n\n*** NTMI for UdK 50 performance.\n\n".postln;

~vessel = ~vessel ? ();
~vessel.dir = ~vessel.dir ? thisProcess.nowExecutingPath.dirname;

NTMI.finalSetup = {
	// potentially other files to load after NTMI is ready
	LoadMe("vessel.scd", ~vessel.dir);
};

NTMI.run;


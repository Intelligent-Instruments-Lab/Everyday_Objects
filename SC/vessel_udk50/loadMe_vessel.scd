"\n\n*** vessel & NTMI for UdK 50 performance.\n\n".postln;
"\n\n*** assumes NTMI is already loaded.\n\n".postln;

{
	~vessel = ~vessel ? ();
	~vessel.dir = ~vessel.dir ? thisProcess.nowExecutingPath.dirname;

	0.2.wait;

	// load the vessels interfaces
	LoadMe("vessel.scd", ~vessel.dir);

	// load the four NN models
	Butz(\NTMI).add(\MODELS);
	LoadMe("NN_four.scd", ~vessel.dir);
	s.sync;
	0.2.wait;
	LoadMe("vesselFuncs.scd", ~vessel.dir);
	LoadMe("scenes.scd", ~vessel.dir);

	LoadMe("en16.scd", ~vessel.dir);

	Butz(\NTMI).run(\InfluxMixer);

	"*** VESSEL AND MODEL loading done!".postln;

}.forkIfNeeded(AppClock);

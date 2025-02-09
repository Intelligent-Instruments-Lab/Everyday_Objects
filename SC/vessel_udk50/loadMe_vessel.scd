"\n\n*** vessel & NTMI for UdK 50 performance.\n\n".postln;
"\n\n*** assumes NTMI is already loaded.\n\n".postln;

WinBounds.stored.putAll( (
	\InfluxMixer: Rect(12.0, 42.0, 500.0, 286.0),
	\slotSounds: Rect(719.0, 10.0, 782.0, 460.0),
	\MODELS: Rect(140, 216.0, 820.0, 700.0)
) );

{

	~vessel = ~vessel ? ();
	~vessel.dir = ~vessel.dir ? thisProcess.nowExecutingPath.dirname;

	NTMI.nn = NTMI.nn ? ();

	0.2.wait;

	// load the vessels interfaces
	LoadMe("vessel.scd", ~vessel.dir);
	LoadMe("en16.scd", ~vessel.dir);
	Butz(\NTMI).run(\InfluxMixer);

	// load the four NN models
	Butz(\NTMI).add(\MODELS);

	LoadMe("scenes.scd", ~vessel.dir);
	LoadMe("ctlTable.scd", ~vessel.dir);

	// worry about decoupling later
	NTMI.nn.decoupled = Set[];
	NTMI.nn.toSetNow = { NTMI.nn.ndefs.select {|nd|
		NTMI.nn.decoupled.includes(nd).not and: { nd.monitor.isPlaying }
	} };

	NTMI.nn.decouple = { |nn, ndef|
		NTMI.nn.decoupled.add(ndef);
	};
	NTMI.nn.couple = { |nn, ndef|
		NTMI.nn.decoupled.remove(ndef);
	};

	/*
	NTMI.nn.decouple(Ndef(\BBC_big));
	NTMI.nn.couple(Ndef(\BBC_big));
	*/

	Butz(\NTMI).run(\slotSounds);

	LoadMe("NN_four.scd", ~vessel.dir);
	s.sync;
	0.2.wait;
	LoadMe("vesselFuncs.scd", ~vessel.dir);

	// all models have sound inputs open
	NTMI.nn.ndefs.do(_.set(\latSnd, 2.5, \liveIn, 0.5));

	// all vessels always active:
	MFdef(\v1).enable(\move2inf);
	MFdef(\v3).enable(\move2inf);
	MFdef(\v6).enable(\move2inf);

	"*** VESSEL AND MODEL loading done!".postln;

	Butz(\NTMI).run(\MODELS);

}.forkIfNeeded(AppClock);

/*

1. make 4 NN instances for four models example for RAVE players with SC / NTMI

2. use 4 NTMI slots as audioIns to models,
--- crossfadable

3. NTMI influx controls model parameters

4. when little activity, calm down


// read help file:
NN.help
*/
(
NTMI.nn = NTMI.nn ? ();

// this is a dir where we can put models:
~nndir = Platform.userAppSupportDir +/+ "nnar/";
// ~nndir.mkdir.openOS;

// and these are the ts file paths found there:
~tspaths = (~nndir +/+ "*.ts").pathMatch;
// post nicely
~tspaths.collect(_.basename).printAll; ~tspaths.size.postln; "";

// load four of them
NN.load(\BBC_big, ~nndir +/+ "BBC_big.ts", action: _.describe);
NN.load(\guitar, ~nndir +/+ "guitar_iil_b2048_r48000_z16.ts", action: _.describe);
NN.load(\marmals, ~nndir +/+ "marinemammals_pondbrain_b2048_r48000_z20.ts", action: _.describe);
NN.load(\water, ~nndir +/+ "water_pondbrain_b2048_r48000_z16.ts", action: _.describe);

NTMI.nn = NTMI.nn ? ();
NTMI.nn.models = [\BBC_big, \guitar, \marmals, \water];


// prepare for 8 latent space params: make them as specs
~latnames = (1..20).collect { |i| "lat%".format(i).asSymbol };
~latnames.do( Spec.add(_, \pan));
\lat1.asSpec.postcs;

// simple forward play, but two channels
Spec.add(\gain, [0, 11, \amp]);
Ndef(\nn).clear;
Ndef(\nn, { |gain=5|
	var in = Ndef(\zz1).ar; // first NTMI slot
	// try stereo synthesis
	[
		NN(\BBC_big, \forward).ar(in[0]),
		NN(\BBC_big, \forward).ar(in[1])
	] * gain;
});

Ndef(\nn).play;
Ndef(\nn).gui(12);
Ndef(\nn).scope;
Ndef(\nn).end;

// encode and decode to two input channels,
// plus offset mod controls
(
// Ndef(\nn).clear;
Spec.add(\gain, [0, 11, \amp]);
Spec.add(\modLev, [0, 4, \amp]);

Ndef(\nn, { |latSnd = 5, modLev = 1|
	var model = \BBC_big;
	var in = Ndef(\zz1).ar * latSnd; // first NTMI slot
	var mods = ~latnames.collect (_.kr(1.0.rand2)) * modLev;
	var lats0 = NN(model, \encode).ar(in[0]);
	var lats1 = NN(model, \encode).ar(in[1]);
	var mods0 = lats0 + mods;
	var mods1 = lats1 + mods;

	[
		NN(model, \decode).ar(mods0),
		NN(model, \decode).ar(mods1)
	];
});
)	
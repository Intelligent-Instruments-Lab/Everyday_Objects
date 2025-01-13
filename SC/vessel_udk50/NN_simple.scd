/* Simple example for RAVE players with SC / NTMI

1. install nn.ar as described here:
"https://github.com/elgiano/nn.ar".openOS;

2. put some models in the ~nndir folder

3. play with patches below

// read help file:
NN.help

*/

// this is a dir where we can put models:
~nndir = Platform.userAppSupportDir +/+ "nnar/";
~nndir.mkdir.openOS;

// and these are the ts file paths found there:
~tspaths = (~nndir +/+ "*.ts").pathMatch;
// post nicely
~tspaths.collect(_.basename).printAll; ~tspaths.size.postln; "";

// load two of them
NN.load(\BBC_big, ~nndir +/+ "BBC_big.ts", action: _.describe);
NN.load(\nasa, ~nndir +/+ "nasa.ts", action: _.describe);

// play nase model, driven by first NTMI slot
Ndef(\nn, { |gain=4|
	// var in = WhiteNoise.ar; // also try noise
	var in = Ndef(\zz1).ar(1);
	NN(\nasa, \forward).ar(in * 4)
}).play

// prepare for 8 latent space params: make them as specs
~latnames = (1..8).collect { |i| "lat%".format(i).asSymbol };
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
Ndef(\nn).clear;
Spec.add(\gain, [0, 11, \amp]);
Spec.add(\nnLevel, [0, 4, \amp]);
Spec.add(\modLevel, [0, 4, \amp]);

Ndef(\nn, { |gain=5, nnLevel = 1, modLevel = 1|
	var model = \nasa;
	var in = Ndef(\zz1).ar; // first NTMI slot
	var mods = ~latnames.collect (_.kr(1.0.rand2)) * modLevel;
	var lats0 = NN(model, \encode).ar(in[0]);
	var lats1 = NN(model, \encode).ar(in[1]);
	var mods0 = lats0 * nnLevel + mods;
	var mods1 = lats1 * nnLevel + mods;

	[
		NN(model, \decode).ar(mods0),
		NN(model, \decode).ar(mods1)
	] * gain;
});
)
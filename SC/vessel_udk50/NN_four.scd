/*

1. make 4 NN instances for four models example for RAVE players with SC / NTMI

2. use 4 NTMI slots as audioIns to models,
--- crossfadable

3. NTMI influx controls model parameters

4. when little activity, calm down

// read help file:
NN.help

MainVol from vessel activity:

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

if (NTMI.nn.loaded != true) {
	"loading four models...".postln;
	NN.load(\BBC_big, ~nndir +/+ "BBC_big.ts", action: _.describe);
	try { s.sync; 0.1.wait; };
	NN.load(\guitar, ~nndir +/+ "guitar_iil_b2048_r48000_z16.ts", action: _.describe);
	try { s.sync; 0.1.wait; };
	NN.load(\marmals, ~nndir +/+ "marinemammals_pondbrain_b2048_r48000_z20.ts", action: _.describe);
	NN.load(\water, ~nndir +/+ "water_pondbrain_b2048_r48000_z16.ts", action: _.describe);
	try { s.sync; 0.1.wait; };
	NTMI.nn.loaded = true;
	"*** 4 NNs loaded.".postln;
};

NTMI.nn = NTMI.nn ? ();
NTMI.nn.modelNames = [\BBC_big, \guitar, \marmals, \water];

// prepare for 8 latent space params: make them as specs
~latnames = (1..20).collect { |i| "lat%".format(i).asSymbol };
~latnames.do( Spec.add(_, \pan));
\lat1.asSpec.postcs;

~maxLats = 8;

// simple forward play, but two channels
Spec.add(\sndSlot, [0, 4]);
Spec.add(\latSnd, [0, 11, \amp]);
Spec.add(\liveIn, [0, 11, \amp]);
Spec.add(\modLev, [0, 11, \amp]);

// [0, 11, 4.605].asSpec.map(0.5)

NTMI.nn.pres = NTMI.nn.modelNames.collect { |name, idx|

	var ndefpre;
	var ndef = Ndef(name, { |amp = 0.25, sndSlot=0, latSnd = 2.5, liveIn = 0.5, modLev = 3|
		var model = name.postln;

		// var in = NTMI.slots.zz[idx.postln].postln.ar * latSnd; // one NTMI slot
		var inSlot = SelectX.kr(sndSlot, NTMI.slots.zz) * latSnd; // xfade NTMI slots
		var live = Ndef(\liveInput).ar(1) * liveIn;
		var ins = inSlot + live;
		var lats0 = NN(model, \encode).ar(ins[0]);
		var lats1 = NN(model, \encode).ar(ins[1]);
		var mods = ~latnames.keep(lats0.size.min(~maxLats)).collect (_.kr(0, 0.1)) * modLev;
		var mods0 = (lats0 + mods);
		var mods1 = (lats1 + mods);


		[
			NN(model, \decode).ar(mods0.clip2(3)),
			NN(model, \decode).ar(mods1.clip2(3))
		].zap * (4 * amp.lag(0.1));


	});

	ndef.addHalo(\namesToInflux, ndef.controlKeys.reject(_ == \sndSlot));
	ndef.set(\sndSlot, idx);

	ndefpre = NdefPreset(ndef, ~latnames.keep(~maxLats));
	ndefpre.storeToDisk = true;
	ndefpre.storePath = NTMI.dir.userPOOL +/+ name ++".pxpreset.scd";

	ndefpre.loadSettings;
	ndefpre;
};

NTMI.nn.ndefs = NTMI.nn.pres.collect(_.proxy);



WinBounds.addMake(\MODELS, {
	var w = Window("MODELS", Rect(400,200,820,700)).front;
	w.addFlowLayout;
	NTMI.nn.pres.do { |pre|
		var ng = NdefPresetGui(pre, 14, w, 400@320);
		NTMI.g.tuneNameView(ng.proxyGui);
		ProxyMeter.addNdefGui(ng.proxyGui);
	};
	w.alpha_(NTMI.g.alpha);
});
Butz(\NTMI).remove(\miniNTMI);

Butz(\NTMI).add(\MODELS, { WinBounds.showOrMake(\MODELS) });

)

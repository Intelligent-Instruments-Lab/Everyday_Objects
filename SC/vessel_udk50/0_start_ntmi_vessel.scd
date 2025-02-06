/* NTMI for vessels at udk 50:

StartupFile.dialog

load NTMI first, then:
"~/src/Everyday_Objects/SC/vessel_udk50/loadMe_vessel.scd".standardizePath.openOS

todo:
1. reroute vessel4 wet to vessel3 wet, remove vessel4
2. flexify setRelInf: allow variable custom ndef destinations
2. prepare other scenes

// presets should store here:
/Users/adc/NTMI/POOL/2_process/presets/bleepo.pxpreset.scd
NdefPreset(\water).storeToDisk = true;
NdefPreset(\water).storePath.openOS;
NdefPreset(\bleepo).storePath

MFdef(\vesIn).enable(\postRaw);
MFdef(\vesIn).disable(\postRaw);

NdefPreset(\BBC_big).storePath.openOS

scene 1: WATER
- cello amped
- water model, influx by vessels
- faders shift model area
- cello input modulates into water
- any synth

scene 2: AETHER
- slow build from nothing
- master hipass, bring down with volume / more activity
- cello delay patch played by one vessel? could be elefant, or

chain 1 : singing drone, vessel 1,
chain 2 : guitar model, vessel 2
overall activity controls highpass
3 params of proximity does latents (RAVE) / sound parameters (singing drone)


scene 3 : surprise



scee 4 : Loop

//////////// debug: ////////
// toggle postRaw for all interfaces
MFdef(\vesIn).enable(\postRaw);
MFdef(\vesIn).disable(\postRaw);
MFdef(\vesIn).enable(\post3);
MFdef(\vesIn).disable(\post3);

~vessel.skipActi.stop;
~vessel.skipActi.play;
~vessel.activity;

NTMI.nn.pres;
NTMI.nn.ndefs = NTMI.nn.pres.collect(_.proxy);

NTMI.ndef.groups.put(\nn, );

NTMI.defaults;
*/

s.volume = -6;

////// NTMI server config:
NTMI.numChans = 2;
NTMI.preBoot = {
	// 8 chan out works out of the box!
	s.options.memSize = (2**20).asInteger; // 1 GB, 2GB possible
	s.options.device = "SSL 12";
	s.options.sampleRate = 48000;
	s.options.hardwareBufferSize = 128;
	s.options.numOutputBusChannels = 8;
	s.options.numInputBusChannels = 4;
};


// // load subset only?
// NTMI.process_namesToLoad = [
// 	\bleepo -> \sparz,
// 	\moogSing -> \ovatony,
// 	\revFB -> \slolo,
// 	\mayer
// 	// \simWire2
// ];

// load defaults:
NTMI.defaultActives = [
	\bleepo,
	\moogSing,
	\revFB,
	\mayer
	// \simWire2
];

NTMI.modelPresetPath = thisProcess.nowExecutingPath;

NTMI.interfacesToLoad = [\uc4];
NTMI.interfacesToShow =  [ 'uc4', /*'en16',*/ 'nanoKtl', 'mu8' ];
NTMI.connectFoundInterfaces = false;

// NTMI.usesMainFX = false;
NTMI.mfx = NTMI.mfx ? ();
NTMI.mfx.domainName = \baseset;


NTMI.finalSetup = {
	///// retweak some settings
	// tweak latency for no complaints
	s.latency = 0.06;

	Butz(\NTMI).remove(\miniNTMI);
	// avoid denormal complaints when volume is off;
	MainFX(s).proxy.addSpec(\mainVol, [0.000001, 4, \amp]);
	MainFX(s).proxy.get(\mainVol);

	// customize sound input for vessels
	[ \cello0, \roomMic1, \plonk2].do { |name| Spec.add(name, [0, 4, \amp]) };
	Spec.add(\gateLev, [0, 0.25, \amp]);

	Ndef(\liveInput, { |cello0 = 1, roomMic1 = 0.5, plonk2 = 0.5, gateLev=0.0|
		var in = SoundIn.ar([0, 1, 2]);
		var amps = [ cello0, roomMic1, plonk2].lag(0.3);
		var snd = (in * amps).sum;
		var ampli = Amplitude.kr(snd, 0, 2);
		snd = (ampli>gateLev).lag(0.0, 1) * snd;

		// noisegate
		snd = Compander.ar(snd, snd, gateLev, 10, 1, 0.0001, 0.3);
		// Limiter
		snd = Compander.ar(snd, snd, 0.9, 1, 0.1, 0.0001, 0.3);

		snd + BrownNoise.ar(0.00001); // no bangs!*/

	});

	NTMI.slots.endOnStop = false;

	NdefPreset(\bleepo).setCurr(\achter).setProxy(\achter);
	NdefPreset(\moogSing).setCurr(\lizzes).setProxy(\lizzes);
	NdefPreset(\revFB).setCurr(\ghosty).setProxy(\ghosty);
	NdefPreset(\mayer).setRand(1.0, seed: 4711);

	// redirect to the loadMe file in my dev folder:
	/*
	"~/src/Everyday_Objects/SC/vessel_udk50/loadMe_vessel.scd".standardizePath.openOS;
	*/
	LoadMe("~/src/Everyday_Objects/SC/vessel_udk50/loadMe_vessel.scd".standardizePath);
};

NTMI.run;
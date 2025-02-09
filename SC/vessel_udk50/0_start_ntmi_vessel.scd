/* NTMI for vessels at udk 50:

*** Sound Vessels - Four Elements ***

Instruments:

- Cello, amped directly via SSL direct monitoring,
and going into models and sound processing
- Four NTMI synthesis slots,
influxed by Faderfox uc4 + vessels
- Four RAVE Models, driven by mic sound,
controlled by intech en16 controller

Controllers:
vessels 1, 3, 6, w. magnetometers, imu, water sensors
Faderfox uc4 (for NTMI), intech en16 (models & specials)

// this script loads NTMI first, then the Vessels setup:
"~/src/Everyday_Objects/SC/vessel_udk50/loadMe_vessel.scd".standardizePath.openOS


*** TODO, NOTES & QUESTIONS ***

- water scene: maybe add activity?
- generally add a separate acticity models on each MKtl?
- NTMI synth sounds vol: adjust by general activity?
- add gui(s) for activity

// recording is 5 chans for stereo out and 3 mics
s.recChannels = 5; s.record;



////// SETUP and Tests ////

**** VESSELS CHECK:
- InfluxMixer should show MKtl(\vessel1), 3, 4, 6
- vessel 1, 3, 6 should blink, 4 is white (its wet sensor goes to 3)

// debugging vessels:
MFdef(\vesIn).enable(\postRaw);   // all data
MFdef(\vesIn).disable(\postRaw);
MFdef(\vesIn).enable(\post1);     // by specific vessel
MFdef(\vesIn).disable(\post1);
MFdef(\vesIn).enable(\post3);
MFdef(\vesIn).disable(\post3);
MFdef(\vesIn).enable(\post3);
MFdef(\vesIn).disable(\post3);

// global vessel activity is tracked here:
~vessel.activity.level;


***** Four RAVE MODELS are here:

NTMI.nn.ndefs; // the four Models as Ndefs
NTMI.nn.pres;  // and their NdefPresets
NTMI.ndef.groups.nn; // and here as subgroup for mixer

// Models presets should store in NTMI.dir.userPOOL
NdefPreset(\water).storeToDisk; // should be true
NdefPreset(\water).storePath.postln.openOS;

**** Four SCENES are on Butz Window, click to switch
s1Water, s2Loop, s3Surprise, s4Aether

"~/src/Everyday_Objects/SC/vessel_udk50/scenes.scd".standardizePath.openOS;

*/

// prep for recording in SC:
// 2 chan stereo, 3 chans for mic inputs
s.recChannels = 5;
s.recHeaderFormat = \wav;
// play mics out to chans 3-5 for recording raw
Ndef(\liveInRec, { |cello0 = 1, roomMic1 = 0.5, plonk2 = 0.5, gateLev=0.0|
	SoundIn.ar([0, 1, 2]);
}).play(2);


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
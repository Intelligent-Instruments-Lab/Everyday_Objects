[\s1Water, \s2Loop, \s3Surprise, \s4Aether ].do { |name|
	Butz(\NTMI).add(name, { NTMI.q[name].value });
};

// general stuff:

// custom HPF for aether scene
ProxyChain.add3( '5HPF',
	\filterIn -> { arg in, bpm=80, freqH = 2000, modH =3, rqH =1.2;
		var fr, seq, tempo;
		tempo = bpm / 60;   // quarter tempo..
		rqH = rqH.lag(0.5);
		fr = (freqH.lag(0.3) * (SinOsc.kr((tempo), [0, 0.76pi], modH).midiratio)).clip(20, 15000);
		RHPF.ar(RHPF.ar(in, fr * 0.8, rqH), fr, rqH);
	},
	1,
	[
		\bpm, [20, 360, \exp],
		\rqH, [0.2, 2, \exp],
		\modH, [0, 36],
		\freqH, \freq,
	]
);


/*
NTMI.mFX.proxyChain.slotNames;
NTMI.mFX.add('0_comp', 1);
*/

// custom ducker for surprise scene - not used
ProxyChain.add3( '0_comp',
	\filterIn -> { arg in, depth = 2, relaxTime = 1, liveIn = 0.0;
		var liveInSig = Ndef(\liveInput).ar(1);
		var amp = Amplitude.ar(liveInSig, 0.001, relaxTime);
		var duckedAmp = (1 - (amp * depth).clip(0, 1));
		// duckedAmp.poll(10, "ducky");
		(in * duckedAmp) + (liveInSig * liveIn);
	},
	1,
	[
		\depth, [0, 4, \amp],
		\relaxTime, [0.03, 3, \exp],
		\liveIn, [0, 1, \amp],
	]
);

////// SCENES:

NTMI.s1Water = {

	NTMI.currScene = \s1Water.postln;

	/*
	- cello amped - always
	- water model, influx by vessels motion
	- en16 knobs 5-16 shift model area
	- cello input modulates into water
	- bring in 1 or 2 synths ad lib
	*/

	// stop or reset things from other scenes
	NTMI.mFX.remove('5HPF', 1);
	NTMI.mFX.remove('0_comp');
	ControlTable(\ct).stop;
	Ndef(\moogSing).addHalo(\namesToInflux,
		[ 'amp', 'moogRoot', 'lpRatio', 'lfDepth', 'lfSpeed', 'reso', 'strobe', 'dense' ]);

	// which slots
	NTMI.slots.addActive(0, Ndef(\bleepo));
	NTMI.slots.addActive(1, Ndef(\moogSing));
	NTMI.slots.addActive(2, Ndef(\revFB));
	NTMI.slots.addActive(3, Ndef(\mayer));

	// which ones play
	NTMI.ndefs[0].postln.vol = 0;
	NTMI.slots.playAt(0);
	NTMI.slots.stopAt(1);
	NTMI.slots.stopAt(2);
	NTMI.slots.stopAt(3);

	// make vessel zoom big
	NTMI.vessel1.zoom = 1;
	NTMI.vessel3.zoom = 1;
	NTMI.vessel6.zoom = 1;

	////// MODELS:
	// water model uses preset start:
	NdefPreset(\water).setCurr(\start).setProxy(\start);
	// only cello into model, no synth
	Ndef(\water).set(\liveIn, 2.5, \latSnd, 0);
	// and fade in
	Ndef(\water).play(vol: 0.25, fadeTime: 10).postln;

	// water model uses preset start:
	Ndef(\guitar).stop(fadeTime: 2);
	Ndef(\BBC_big).stop(fadeTime: 2);
	Ndef(\marmals).stop(fadeTime: 2);

};


NTMI.s2Loop = {

	NTMI.mFX.remove('5HPF', 1);
	NTMI.mFX.remove('0_comp');
	ControlTable(\ct).stop;
	Ndef(\moogSing).addHalo(\namesToInflux,
		[ 'amp', 'moogRoot', 'lpRatio', 'lfDepth', 'lfSpeed', 'reso', 'strobe', 'dense' ]);

	// bleepo, moogSing, revFB, rjkChaos
	NTMI.slots.addActive(0, Ndef(\bleepo));
	NTMI.slots.addActive(1, Ndef(\moogSing));
	NTMI.slots.addActive(2, Ndef(\revFB));
	NTMI.slots.addActive(3, Ndef(\rjkChaos));

	NTMI.slots.playAt(0); NTMI.ndefs[0].vol = 0.1;
	NTMI.slots.stopAt(1);
	NTMI.slots.playAt(2); NTMI.ndefs[2].vol = 0.1;
	NTMI.slots.stopAt(3);

	NTMI.vessel1.zoom = 1;
	NTMI.vessel3.zoom = 1;
	NTMI.vessel6.zoom = 1;

	Ndef(\BBC_big).play(vol: 0.25, fadeTime: 2).postln;
	Ndef(\guitar).stop(fadeTime: 2);
	Ndef(\water).stop(fadeTime: 2);
	Ndef(\marmals).stop(fadeTime: 2);

	// show controlTable for Loop C here:
	Butz(\NTMI).run(\CtlTable);

};

// scene 3 : surprise
/* SCORE:
SURPRISE

Entangle all synths with all RAVE models so that you can’t be sure what sounds will happen exactly. Add element of randomness?
Use triangle or sine waves linked directly to the latents like in stacco orchestra and vessels affect the phase of the waves, change the frequency and amplitude, the shape of the wave
Egg Vessels
Repeat vessel movement from “WATER”
Quick, sudden movements
Interrupted by cello - or no cello?
---

4 random-chosen NTMI sounds, all 4 models
vessels influence all of them
-> NTMI inputs -> sound params / latents

option/later: LFOs only on the latents to  modulate their params
option/later: cello ducks all sound

*/

NTMI.s3Surprise = {

	NTMI.currScene = \surprise3.postln;

	NTMI.mFX.remove('5HPF', 1);
	NTMI.mFX.remove('0_comp');
	ControlTable(\ct).stop;
	Ndef(\moogSing).addHalo(\namesToInflux,
		[ 'amp', 'moogRoot', 'lpRatio', 'lfDepth', 'lfSpeed', 'reso', 'strobe', 'dense' ]);

	// get 4 random ones?
	NTMI.ndefs.do(_.vol_(0.25));
	NTMI.slots.stepNext(0, 200.rand);
	NTMI.slots.stepNext(1, 200.rand);
	NTMI.slots.stepNext(2, 200.rand);
	NTMI.slots.stepNext(3, 200.rand);

	NTMI.slots.playAt(0);
	NTMI.slots.playAt(1);
	NTMI.slots.playAt(2);
	NTMI.slots.playAt(3);

	NTMI.nn.ndefs.do(_.play(vol: 0.25));
};


/*
scene 2: AETHER
- slow build from nothing
- MainFX hipass filter, bring down with vessel activity

NOT done :
chain 1 : singing drone, vessel 1,
chain 2 : guitar model, vessel 2
3 params of proximity does latents (RAVE) / sound parameters (singing drone)
add cello delay patch played by one vessel? could be elephant, or
*/

NTMI.s4Aether = {
	NTMI.currScene = \s4Aether.postln;

	ControlTable(\ct).stop;

	NTMI.mFX.add('5HPF', 1);
	NTMI.mFX.set(\rqH, 1.3, \freqH, 20000, \bpm, 23, \modH, 2);

	Ndef(\moogSing).getHalo.namesToInflux.remove(\moogRoot);
	Ndef(\moogSing).set(\moogRoot, 24);

	NTMI.slots.addActive(0, Ndef(\bleepo));
	NTMI.slots.addActive(1, Ndef(\moogSing));
	NTMI.slots.addActive(2, Ndef(\revFB));
	NTMI.slots.addActive(3, Ndef(\robTron));

	NdefPreset(\bleepo).setCurr(\loCricken).setProxy(\loCricken);
	NdefPreset(\moogSing).setCurr(\sanglich).setProxy(\sanglich);
	NdefPreset(\revFB).setCurr(\slolo).setProxy(\slolo);
	NdefPreset(\robTron).setCurr(\guzzl).setProxy(\guzzl);

	NTMI.slots.stopAt(0);
	NTMI.slots.playAt(1);
	NTMI.slots.stopAt(2);
	NTMI.slots.playAt(3);


	Ndef(\water).stop(fadeTime: 3);
	Ndef(\guitar).play(vol: 0.1, fadeTime: 10);

	MFdef(\actiFunc).enable(\setRel);

	MKtl('en16').elAt(\enc, 15).action = { |enc|
		var diff = enc.value - enc.prevValue;
		RelSet(NTMI.mFX.proxy, *[\freqH, diff]);
		if (enc.deviceValue == 127) { enc.deviceValue = 120 };
		if (enc.deviceValue == 0) { enc.deviceValue = 7 };
	};
};

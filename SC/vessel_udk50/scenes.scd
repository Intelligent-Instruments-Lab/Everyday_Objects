[\water1, \aether2, \surprise3, \loop4].do { |name|
	Butz(\NTMI).add(name, { NTMI.q[name].value });
};


NTMI.nn.ndefs.do(_.set(\latSnd, 2.5, \liveIn, 0.5));
NTMI.water1 = {
	NTMI.currScene = \water1.postln;
	/*
	- cello amped - always
	- water model, influx by vessels motion
	- faders shift model area
	- bring in cello input modulates into water?
	- any synths?
	*/

	NTMI.mFX.remove('5HPF');
	NTMI.ndefs.do(_.stop(5));
	Ndef(\water).set(\latSnd, 0.0, \liveIn, 0);
	Ndef(\water).play(fadeTime: 10);

	Ndef(\guitar).stop(fadeTime: 2);
	Ndef(\BBC_big).stop(fadeTime: 2);
	Ndef(\marmals).stop(fadeTime: 2);

	MFdef(\v3).enable(\move2inf);
	MFdef(\v6).enable(\move2inf);

};

// my HPF:
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
scene 2: AETHER
- slow build from nothing
- master hipass, bring down with volume / more activity
- cello delay patch played by one vessel? could be elefant, or

chain 1 : singing drone, vessel 1,
chain 2 : guitar model, vessel 2
overall activity controls highpass
3 params of proximity does latents (RAVE) / sound parameters (singing drone)

//
*/

NTMI.aether2 = {

	NTMI.mFX.remove('5HPF');

	NTMI.ndefs[[0,2,3]].do(_.stop(5));

	NTMI.currScene = \aether2.postln;

	NTMI.mFX.set(\rqH, 0.7, \freqH, 20000, \bpm, 23, \modH, 2);
	NTMI.mFX.add('5HPF', 1);
	// moogSing in slot 1
	NTMI.ndefs.do(_.play(vol: 0.1, fadeTime: 10));

	Ndef(\water).stop(fadeTime: 3);
	Ndef(\guitar).play(vol: 0.1, fadeTime: 10);
	Ndef(\guitar).set(\latSnd, 0.5, \liveIn, 2.5);

	MFdef(\actiFunc).enable(\setRel);

	MKtl('en16').elAt(\enc, 15).action = { |enc|
		var diff = enc.value - enc.prevValue;
		RelSet(NTMI.mFX.proxy, *[\freqH, diff]);
		if (enc.deviceValue == 127) { enc.deviceValue = 120 };
		if (enc.deviceValue == 0) { enc.deviceValue = 7 };
	};

};


// scene 3 : surprise
/*
SURPRISE

Entangle all synths with all RAVE models so that you can’t be sure what sounds will happen exactly. Add element of randomness?
Use triangle or sine waves linked directly to the latents like in stacco orchestra and vessels affect the phase of the waves, change the frequency and amplitude, the shape of the wave
Egg Vessels
Repeat vessel movement from “WATER”
Quick, sudden movements
Interrupted by cello - or no cello?

4 sounds, 4 models, best on one machine?
vessels
-> NTMI inputs -> sound params / latents
-> possibly LFOs on the latents? and modulate their params?
-> cello ducks everything?

*/

NTMI.surprise3 = {
	NTMI.currScene = \surprise3.postln;

	NTMI.slots.playAt(0);
	NTMI.slots.playAt(1);
	NTMI.slots.playAt(2);
	NTMI.slots.playAt(3);
	NTMI.ndefs.do(_.play(vol: 0.25));

	NTMI.nn.ndefs.do(_.play(vol: 0.25));

};


/*
LOOP

    Cello circle bowing at first
    Then builds into a loop navigating the “cello latent” that includes a circle bow as part of the loop
    Second loop navigates cello latent in a different way

    RAVE Orchestra + Feedback Reverb - create as complex sound as you can that you can also repeat. Use multiple vessels. Machine-like. Overlaps with cello loops
    Make sure to use lots of pouring - different colours of liquid?
    Use everyday actions
    List of actions in natural language - machine-like, programming, pseudo-code, repeat x times then move onto next one
    Add in accels and ralls etc
    Second loop navigates vessels in a different way
    Third loop is in sync between both players
    Any vessels

- cello circle bowing -> loop
- first loop: cello
- second loop: cello + vessels (+ rave+feedback big sound, vessel movement loop)
- third loop: vessels and cello sync
    different sound material? again both, accels & ralls
/

// scee 4 : Loop
NTMI.loop4 = {
	NTMI.currScene = \loop4.postln;
	// NTMI.mFX.add('5HPF').set(\rqH, 0.7, \freqH, 10000, \bpm, 23);
	// // moogSing in slot 1
	// NTMI.ndefs[1].play(vol: 0.25, fadeTime: 10);
	//
	// Ndef(\water).set(\latSnd, 0.5, \liveIn, 2.5);
	// Ndef(\water).play(fadeTime: 10);

};


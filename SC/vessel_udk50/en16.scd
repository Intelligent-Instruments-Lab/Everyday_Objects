// use en16 grid for NN models!

MKtl(\en16, "intech-grid");
/*
MKtl(\en16).gui;
*/

// top buts select which ones to affect for param tuning
MKtl(\en16).elAt(\bt, (0..3), \on).do { |bt| bt.action = nil };
MKtl(\en16).elAt(\bt, (12..15), \on).do { |bt, i|
	bt.action = {
		var ndef = NTMI.nn.ndefs[i].post;
		if (ndef.monitor.isPlaying) {
			" -stop".postln; ndef.stop } {
			" -play".postln; ndef.play;
		};
	}
};

// top 4 knobs for volume
MKtl(\en16).elAt(\enc, (0..3)).do { |kn, i|
	kn.deviceValue = 64;
	kn.action = {
		var ndef = NTMI.nn.ndefs[i];
		var univol = \amp.asSpec.unmap(ndef.vol).postln;
		var delta = (kn.value - kn.prevValue).postln.clip2(0.025);
		ndef.vol = \amp.asSpec.map(univol + delta);
		if (kn.deviceValue == 127) { kn.deviceValue = 120.postln };
		if (kn.deviceValue == 0) { kn.deviceValue = 7.postln };
	}
};

// use lower 12 encoders for param tuning if knobs held;
// else they do influx!
MKtl(\en16).elAt(\enc, (4..15)).do { |kn, i|
	kn.deviceValue = 64;
	kn.action = {
		var modelKeys = NTMI.nn.ndefs[0].controlKeys;
		var ndefIndices = MKtl(\en16).elAt(\bt, (0..3)).selectIndices(_.isOn);
		var ndefs = NTMI.nn.ndefs[ndefIndices];
		var delta = (kn.value - kn.prevValue).postln.clip2(0.05);
		if (ndefs.size > 0) {
			var paramKey = modelKeys[i].postln;
			ndefs.do { |ndef| RelSet(ndef, paramKey, delta) };
			if (kn.deviceValue == 127) { kn.deviceValue = 120.postln };
			if (kn.deviceValue == 0) { kn.deviceValue = 7.postln };
		} {
			MFdef(\setRelInfModel).(
				i + NTMI.inph.sliderOffset,
				delta,
				NTMI.zoom
			)
		}
	}
};


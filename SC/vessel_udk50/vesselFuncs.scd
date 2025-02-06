
// measure overall vessel activity
(
NTMI.vessel.funcs.put(1, MFdef(\v1));
NTMI.vessel.funcs.put(3, MFdef(\v3));
NTMI.vessel.funcs.put(4, MFdef(\v4));
NTMI.vessel.funcs.put(6, MFdef(\v6));

MFdef(\v1).add(\post, { "v1".postln });
MFdef(\v3).add(\post, { "v3".postln });
MFdef(\v4).add(\post, { "v-4".postln });
MFdef(\v6).add(\post, { "v---6".postln });

MFdef(\v1).enable(\post);
MFdef(\v3).enable(\post);
MFdef(\v4).enable(\post);
MFdef(\v6).enable(\post);

MFdef(\v1).disable(\post);
MFdef(\v3).disable(\post);
MFdef(\v4).disable(\post);
MFdef(\v6).disable(\post);
);

NTMI.nn.ndefs.do { |ndef|
	ndef.addHalo(\namesToInflux, ~latnames.keep(8));
};

MFdef(\setRelInfModel).value(4, 0.02);

MFdef(\setRelInfModel).add(\set, { |inIndices, diffs, zoom = 0.5|
	var vector;
	var ndefsToSet = NTMI.nn.toSetNow;
	// "*** in setRelInf: ".postln;
	// [inIndices, diffs, zoom].postln;
	if (ndefsToSet.notEmpty) {
		vector = NTMI.inphlux.changeVector(inIndices, diffs, zoom);
		ndefsToSet.do { |ndef|
			var params = ndef.getHalo.namesToInflux ?? { ndef.controlKeys };
			var deltaPairs = [params, vector.keep(params.size)].flop;
			MFdef(\relSet).(ndef, deltaPairs);
		}
	}
});

(
// influx by vessel motion:
~magExpo = 1;
~mapMags = { |val| val.abs ** ~magExpo * val.sign * 5 };

MFdef(\move2inf).add(\move, { |mktl, data|
	var id = data[0];

	// on mags rescale values so changes around the middle are bigger
	var mags = mktl.elAt(\mag);
	var magdiffs = ~mapMags.(mags.value.unibi) - ~mapMags.(mags.prevValue.unibi) * 2;

	var angs = mktl.elAt(\angvel);
	var angdiffs = angs.value - angs.prevValue;

	var accels = mktl.elAt(\angvel);
	var acceldiffs = accels.value - accels.prevValue;
	var diffs = magdiffs ++ angdiffs ++ acceldiffs;

	// ("move2inf" + id).postln;
	// ("magdiffs: " + magdiffs.round(0.001)).postln;

	// do relative param set on the running slots:
	// which influxIndices, the diffs, and a zoom (def. 1)
	MFdef(\setRelInf).((0..8) + 3, diffs, NTMI.vessel3.zoom);
	MFdef(\setRelInfModel).((0..8) + 3, diffs, NTMI.vessel3.zoom);
});

MFdef(\v1).add(\move2inf, MFdef(\move2inf));
MFdef(\v3).add(\move2inf, MFdef(\move2inf));
MFdef(\v6).add(\move2inf, MFdef(\move2inf));
);

////////////////// BACKUP
// MFdef(\v6).add(\move2inf, { |mktl, data|
// 	var id = data[0];
//
// 	var angs = mktl.elAt(\angvel);
// 	var angdiffs = angs.value - angs.prevValue;
// 	var accels = mktl.elAt(\angvel);
// 	var acceldiffs = accels.value - accels.prevValue;
// 	var diffs = angdiffs ++ acceldiffs;
//
// 	// do relative param set on the running slots:
// 	// which influxIndices, the diffs, and a zoom (def. 1)
// 	MFdef(\setRelInf).((0..5) + 3, diffs, NTMI.vessel3.zoom);
// 	MFdef(\setRelInfModel).((0..5) + 3, diffs, NTMI.vessel3.zoom);
//
// });

~vessel.activity = Activity.new;
MFdef(\vesIn).add(\activity, { |datArr|
	if (datArr[0] != 4) {
		var diff = ~vessels.collect { |ves|
			(ves.elAt.value.flat - ves.elAt.prevValue.flat).abs.sum;
		}.sum;
		~vessel.activity.add(diff);
		MFdef(\actiFunc).value(~vessel.activity.level);
	};
});

MFdef(\actiFunc).add(\setRel, {
	var acti = ~vessel.activity;
	var level = acti.level;
	var diff = level - (acti.getHalo(\prevLevel) ? level);
	acti.addHalo(\prevLevel, level);
	// "vess lev: % diff: %\n".postf(level.round(0.001), diff.round(0.001));
	RelSet(NTMI.mFX.proxy, *[\freqH, diff * -0.2])
});

MFdef(\actiFunc).add(\post, {
	("acti level: " + ~vessel.activity.level.round(0.01)).postln;
});

MFdef(\actiFunc).disable(\post);
MFdef(\actiFunc).disable(\setRel);


/* test how relSet works
MFdef(\setRelInf).(
[0, 1, 2],  // influx input chan indices to use
[0.1, 0.1, -0.1], // diff steps for each input
1      // zoom factor for diffs
).postln;

//// magnetometer is distance.squared,
//// so it has very low values until very close.
/// how to rescale data for NTMI?

~magExpo = 1;      // linear
~magExpo = 0.5;    // square root
~magExpo = 0.3;    // more sensitive at distance

(-33000, -32900 .. 33000).collect { |val| val.abs ** ~magExpo * val.sign }.plot;

// better use it on normalized values
(-1, -0.99 .. 1).collect { |val| (val.abs ** ~magExpo) * val.sign }.plot;
*/
//

/*
This file connects the vessel esp receiver for up to 6 vessel sensors to NTMI.

"https://s4ntp.org/NTMI/".openOS

- opens SerialPort of esp receiver
- pipes esp data for 6 vessels into respective MKtls
- in the receiving function,
uses mag, angvel, accel and wet as relative influx inputs,
which get applied to all running sounds.

ToDo FV:
- document existing vessels :
which sensors exist, with which vessel ID, ranges etc

------ id  1    2    3    4    5    6    7    8    9    10    11    12
Kit_1  1   magx magy magz angx angy angz accx accy accz flow  wt/pr touch
Kit_2  2   magx magy magz angx angy angz accx accy accz flow  wt/pr touch

Kit_3  3   magx magy magz angx angy angz accx accy accz 0     wt/pr 0
Kit_4  4   0 ------------------------------------------------ pn34 ----
Kit_6  6   magx magy magz gyrx gyry gyrz accx accy accz 0     bt17  0

- tune one setting for vessel6
- decide on sounds you like
- walk thru NTMI tutoirals and demos
- esp. how to customize


adc:
- make all existing vessels work in code
- maybe they should have different mappings,
even different receive funcs?
 - window with independent zooms for mag etc per vessel

// check which devices are there
SerialPort.devices;
SerialPort.closeAll;

// start and stop listening routine
NTMI.vessel.rout.stop;
NTMI.vessel.serial.close;

// make a gui for first vessel w id 6
MKtl(\vessel6).gui;


*/

// general setup

NTMI.vessel = NTMI.vessel ? ();
~vessels = ~vessels ? ();

// open Serial port:
(
SerialPort.closeAll;
/* this is a macOS device name - edit to match your port. See
SerialPort.listDevices
*/
NTMI.vessel = NTMI.vessel ? ();
// on FV laptop:
NTMI.vessel.devname = "/dev/cu.usbserial*".pathMatch.first;
// on adc laptop (macOS 13.7.2)
NTMI.vessel.devname = "/dev/cu.usbmodem*".pathMatch.first;
// this should match both:
NTMI.vessel.devname = "/dev/cu.usb*".pathMatch.first;

if (NTMI.vessel.devname.isNil) {
	"NTMI.vessel: could not find device matching \"/dev/cu.usbserial*\"".warn;
	"continuing with virtual device.".postln
} {

	NTMI.vessel.serial = SerialPort(
		NTMI.vessel.devname,
		baudrate: 115200,    //check that baudrate matches w arduino sketch
		crtscts: true
	).postln;


	// read serial data sent from Arduino's Serial.println> we get 3 strings:
	// b[0,0,1...] for 10 buttons,
	// p[123,1023,...] for 10 pots, 10bit, i.e. 0-1023, and
	// r[0,500,1023,0] for 4 ribbons, also 10bit.

	(
		try{NTMI.vessel.rout.stop};
		NTMI.vessel.rout = Routine({
			var byte, str, res;
			var t0 = Main.elapsedTime;
			var t = t0;
			inf.do { |i|
				if(NTMI.vessel.serial.read==10, {
					var id, valArray;
					str = "";
					while({byte = NTMI.vessel.serial.read; byte !=13 }, {
						str = str++byte.asAscii;
					});
					try {
						// if message begins with id number, use it
						if (str.first.isDecDigit) {

							MFdef(\vesIn).(str.split($ ).drop(-1).collect(_.interpret))
						} {
							// else post it (e.g. debug messages)
							str.postln;
						}
					};
				});
				t = Main.elapsedTime;
				// "%, ".postf((t - t0).round(0.0001));
				t0 = t;
			};
		}).play;
	);
};


MFdef(\vesIn).add(\post, { |dataArray| dataArray.drop(0).postln });

MFdef(\vesIn).add(\setMKtl, { |dataArray|
	var id = dataArray.first;
	var data = dataArray.drop(1);
	var mktl = ~vessels[id];
	if (mktl.notNil) {
		// "setting % \n".postf(mktl);
		mktl.elAt(\mag).deviceValueAction_(data[0..2]);
		mktl.elAt(\angvel).deviceValueAction_(data[3..5]);
		mktl.elAt(\accel).deviceValueAction_(data[6..8]);
		mktl.elAt(\bt).deviceValueAction_(data[9]);
		mktl.elAt(\wet).deviceValueAction_(data[10]);
	}
});


~dataTrace = List[];
MFdef(\vesIn).add(\record, { |dataArray|
	~dataTrace.add(dataArray);
	~dataTrace.size.postln;
});

MFdef(\vesIn).remove(\post);
MFdef(\vesIn).remove(\record);

/*
~dataTrace.flop.collect { |chan, i|
[i, chan.minItem, chan.maxItem]
}.printAll;

~dataTrace.copyRange(400, 420).printAll
*/
);

//// Make an MKtl description for the vessel
(
NTMI.vessel.desc = MKtlDesc.fromDict((
	descName: "vessel",
	idInfo: "vessel",
	deviceInfo: (
		longName: "vessel"
	),

	idInfo: ( ipAddress: "127.0.0.1", ),
	protocol: \osc,
	//////// should be done with collective set, not working yet
	// collectives: (
	// 	vals: (
	// 		oscPath: 'vals',
	// 		ioType: \in,
	// 		// the order in this array determines the order how the message is parsed
	// 		elements: [
	// 			[\mag, 0], [\mag, 1], [\mag, 2],
	// 			[\angvel, 0], [\angvel, 1], [\angvel, 2],
	// 			[\accel, 0], [\accel, 1], [\accel, 2],
	// 			[\bt], [\wet]
	// 		],
	//
	// 	),
	// ),

	elementsDesc: (
		elements: [
			(
				key: 'mag',
				shared: ( elementType: 'slider', ioType: \collectiveIn, \spec: [-33000, 33000] ),
				elements: 3.collect { () }
			),
			(
				key: 'angvel',
				shared: ( elementType: 'slider', ioType: \collectiveIn, \spec: [-1000, 1000] ),
				elements: 3.collect { () }
			),
			(
				key: 'accel',
				shared: ( elementType: 'slider', ioType: \collectiveIn, \spec: [-4, 4] ),
				elements: 3.collect { () }
			),
			( key: \bt, elementType: 'button',  \spec: [0, 1, \lin, 1]),
			( key: \wet, elementType: 'slider',  \spec: [0, 2000]),
		]
	)
));
);

///// make all active vessels:
// the vessel IDs we use:
~vesselIDs = [1, 2, 3, 4, 6];
// info on what is on each vessel goes here ...


~vesselIDs.do { |id|
	var name = "vessel%".format(id).asSymbol;
	var mktl = MKtl(name, NTMI.vessel.desc);
	~vessels.put(id, mktl);
};

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

(
// proximity curve for magnets:
// 1 is linear, with less, e.g. 0.3, distant is more sensitive
~magExpo = 0.5;

// in the data receiving func,
// take difference in mag etc values to change running sound params:
MFdef(\vesIn).add(\mag2NTMI, {
	var mapMags = { |val| val.abs ** ~magExpo * val.sign };

	var mags = MKtl(\vessel6).elAt(\mag);
	// on mags rescale values so changes around the middle are bigger
	var magdiffs = mapMags.(mags.value.unibi) - mapMags.(mags.prevValue.unibi);

	var angs = MKtl(\vessel6).elAt(\angvel);
	var angdiffs = angs.value - angs.prevValue;
	var accels = MKtl(\vessel6).elAt(\angvel);
	var acceldiffs = accels.value - accels.prevValue;
	var wet = MKtl(\vessel6).elAt(\wet);
	var wetdiff = wet.value - wet.prevValue;

	// do relative param set on all running slots
	MFdef(\setRelInf).(
		[0, 1, 2],
		magdiffs * 3,
		1
	);

	MFdef(\setRelInf).(
		[0, 1, 2] + 3,
		angdiffs * 3,
		1
	);
	MFdef(\setRelInf).(
		[0, 1, 2] + 6,
		acceldiffs * 3,
		1
	);

	MFdef(\setRelInf).(9, wetdiff * 3, 1);

});
);
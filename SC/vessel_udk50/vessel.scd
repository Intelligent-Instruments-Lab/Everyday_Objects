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

MKtl(\vessel1).free; // mag, ang, acc, no water //
MKtl(\vessel3).free; // mag, ang, acc, no water, in egg1
MKtl(\vessel4).free; // just water in egg1
MKtl(\vessel6).free; // mag, ang, acc, water - all in egg2


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

~vessels;  // should be all active vessels

// make a gui for first vessels
MKtl(\vessel1).gui; // mag, ang, acc, no water //
MKtl(\vessel3).gui; // mag, ang, acc, no water, in egg1
MKtl(\vessel4).gui; // just water in egg1
MKtl(\vessel6).gui; // mag, ang, acc, water - all in egg2

MFdef(\vesIn).enable(\postRaw);
MFdef(\vesIn).disable(\postRaw);
MFdef(\vesIn).enable(\post3);
MFdef(\vesIn).disable(\post3);


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
NTMI.vessel.devname = "/dev/cu.usb*".pathMatch.last;

if (NTMI.vessel.devname.isNil) {
	"NTMI.vessel: could not find device matching \"/dev/cu.usbserial*\"".warn;
	"continuing with virtual device.".postln
} {

	NTMI.vessel.serial = SerialPort(
		NTMI.vessel.devname,
		baudrate: 115200,    //check that baudrate matches w arduino sketch
		crtscts: true
	);
	"*** NTMI.vessel.serial: ".postln;
	NTMI.vessel.serial.dump;

	NTMI.vessel.funcs = ();

	// read serial data sent from Arduino's Serial.println> we get 3 strings:
	// b[0,0,1...] for 10 buttons,
	// p[123,1023,...] for 10 pots, 10bit, i.e. 0-1023, and
	// r[0,500,1023,0] for 4 ribbons, also 10bit.

	(
		try{NTMI.vessel.rout.stop};
		NTMI.vessel.rout = Routine({
			var byte, str, res;
			var data, id, mktl;
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
							data = str.split($ ).drop(-1).collect(_.interpret);
							id = data[0];
							mktl = ~vessels[id];
							// update all Mktls
							MFdef(\vesIn).(data);
							// run a specific vesIn func for each device:
							NTMI.vessel.funcs[id].value(mktl, data);
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

MFdef(\vesIn).add(\postRaw, { |dataArray| if (dataArray[0] != 4) { dataArray.postln } });
MFdef(\vesIn).disable(\postRaw);
MFdef(\vesIn).add(\postID, { |dataArray| var id = dataArray[0]; if (id != 4) { id.postln } });
MFdef(\vesIn).disable(\postID);

MFdef(\vesIn).add(\post1, { |arr| if (arr[0] == 1) { arr.postln } }, false);
MFdef(\vesIn).add(\post3, { |arr| if (arr[0] == 3) { arr.postln } }, false);
MFdef(\vesIn).add(\post6, { |arr| if (arr[0] == 6) { arr.postln } }, false);
MFdef(\vesIn).disable(\post1);
MFdef(\vesIn).disable(\post3);
MFdef(\vesIn).disable(\post6);



// with my  cube magnets:
// bottom is roughly 0.0026 -> subtract zeroOffset
// difference to zeroed bottom begins at 1m distance,
// 0.001 at 30 cm
// 0.003 at 15 cm
// 0.01 at 10cm
// 0.1 at 5cm
// 0.5 when touching
// after touching, center offset are gone

MFdef(\vesIn).add(\post3, { |dataArray|
	var magmag = MKtl(\vessel3).elAt(\mag).value.unibi;
	var val = (magmag - ~zero).abs.sum;
	// val.round(0.0001).postln;
});

MFdef(\vesIn).disable(\post3);

/*
~zero = 0;
~zero = MKtl(\vessel3).elAt(\mag).value.unibi;

~zero1 = MKtl(\vessel3).elAt(\mag).value.unibi;
~zero2 = MKtl(\vessel3).elAt(\mag).value.unibi;
~zero3 = MKtl(\vessel3).elAt(\mag).value.unibi;

(~zero1 - ~zero2).abs.sum
(~zero1 - ~zero3).abs.sum
(~zero2 - ~zero3).abs.sum
*/

NTMI.vessel.ids = Set[];

MFdef(\vesIn).add(\setMKtl, { |dataArray|
	var id = dataArray.first;
	var data = dataArray.drop(1);
	var mktl = ~vessels[id];
	NTMI.vessel.ids.add(id);
	// optimize by vessel
	if (mktl.notNil) {
		if ([1, 3, 6].includes(id)) {
			// "setting % \n".postf(mktl);
			mktl.elAt(\mag).deviceValueAction_(data[0..2]);
			mktl.elAt(\angvel).deviceValueAction_(data[3..5]);
			mktl.elAt(\accel).deviceValueAction_(data[6..8]);
			mktl.elAt(\bt).deviceValueAction_(data[9]);
		};
		// merge wet 4 into 3
		if (id == 4) {
			~vessels[3].elAt(\wet).deviceValueAction_(data[10]);
		};
		if (id == 6) {
			mktl.elAt(\wet).deviceValueAction_(data[10]);
		};

	}
});


~dataTrace = List[];
MFdef(\vesIn).add(\record, { |dataArray|
	if (dataArray[1] == 3) {
		~dataTrace.add(dataArray);
		~dataTrace.size.postln;
	}
});
MFdef(\vesIn).disable(\record);

/*
fork {
	~dataTrace = List[];
	MFdef(\vesIn).enable(\record);
	5.wait;
	MFdef(\vesIn).disable(\record);
	~dataTrace.size.postln;
};
*/


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

	elementsDesc: (
		elements: [
			(
				key: 'mag',
				shared: ( elementType: 'slider', ioType: \collectiveIn, \spec: [-10000, 10000] ),
				elements: 3.collect { |i|
					(style: (row: 0, column: i*0.5, width: 0.5, height: 2))
				}
			),
			(
				key: 'angvel',
				shared: ( elementType: 'slider', ioType: \collectiveIn, \spec: [-1000, 1000] ),
				elements: 3.collect { |i|
					(style: (row: 0, column: i*0.5 + 2, width: 0.5, height: 2))
				}
			),
			(
				key: 'accel',
				shared: ( elementType: 'slider', ioType: \collectiveIn, \spec: [-4, 4] ),
				elements: 3.collect { |i|
					(style: (row: 0, column: i*0.5 + 4, width: 0.5, height: 2))
				}
			),
			( key: \bt, elementType: 'button',  \spec: [0, 1, \lin, 1]),
			( key: \wet, elementType: 'slider',  \spec: [0, 2000],
				style: (row: 0, column: 6, width: 0.5, height: 2)
			)
		]
	)
));
);

///// make all active vessels here by ID:
// the vessel IDs we use:
~vesselIDs = [1, 3, 4, 6];
// info on what is on each vessel goes here ...

~vesselIDs.do { |id|
	var name = "vessel%".format(id).asSymbol;
	MKtl.all[name].free;
	MKtl(name, NTMI.vessel.desc);

	~vessels.put(id, MKtl(name));
};

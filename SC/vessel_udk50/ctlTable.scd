/*
A ControlTable with tables for the Loop scene
*/

~vessel.ct = ControlTable(\ct,
	2.collect { Signal.sineFill(2048, { 1.0.linrand }!5, { pi.rand2 }!5) };
);
~vessel.ct.toNTMI;

Butz(\NTMI).add(\CtlTable, { WinBounds.showOrMake(\CtlTable) });
WinBounds.addMake(\CtlTable, {
	var w;
	~vessel.ct.gui;
	w = Window.find('Control Table ct');
	w.view.alpha_(NTMI.g.alpha).name_(\CtlTable);
});

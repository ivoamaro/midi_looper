//Line6 Loop Pedal Emulation
//(condensed into one SynthDef)
//FEEDBACK WARNING! USE HEADPHONES!
s.quit;
(
~mainOut = 0;
~micIn = 0;
~num = [];
~overdub = [];
~track = 0;

2.do({
	~num = ~num.add(0);
	~overdub = ~overdub.add(false);
});



s.waitForBoot({
	MIDIIn.connectAll;
	Buffer.freeAll;
	s.sync;
	//~b = Buffer.alloc(s, s.sampleRate * 300);
	~buffers = [];
	2.do({
		~buffers = ~buffers.add(
			Buffer.alloc(s, s.sampleRate * 300)
		);
	});

	SynthDef(\looper, {
		var mic, trig, max, ptr, loop, rec, mix;
		var xfade = \xfade.kr(0.02);
		var buf = \buf.kr(0);
		mic = SoundIn.ar(\in.ir(0));
		trig = Trig1.ar(\trig.tr(0), ControlDur.ir);
		max = Sweep.ar(trig, SampleRate.ir * \run.kr(0));
		ptr = Phasor.ar(trig, 1, 0, max, 0);
		loop = BufRd.ar(1, buf, ptr);
		rec = sum([
			mic * \reclev.kr(0).varlag(xfade,-2),
			loop * \prelev.kr(0).varlag(xfade,-2)
		]);
		rec = rec * \recAmp.kr(1).varlag(xfade,-2);
		BufWr.ar(rec, buf, ptr);
		mix = sum([
			loop * \loopAmp.kr(1).varlag(xfade,-2),
			mic * \micAmp.kr(1).varlag(xfade,-2)
		]);
		mix = mix * \mixAmp.kr(1).varlag(xfade,-2);
		Out.ar(\out.ir(0), mix!2);
	}).add;


	MIDIdef.noteOn(\on, {
		arg val, num, chan, src;
		num.postln;
		switch (num,
			44,   { ~track = 0;},
			45,   { ~track = 1;},
			46,   { s.freeAll;},
			48, {
				~buffers[~track].zero; ~loopers[~track].set(\trig, 1, \run, 0, \reclev, 0, \prelev, 0, \xfade, 0.02);
				~overdub[~track] = false;
				~num[~track] = 0;
			 }
		);

	});

	MIDIdef.cc(\te, {
		arg val, num, chan, src;
		num.postln;

		if ( val == 0 && num == 64, {
			if (~num[~track] % 2 == 0,
			{
				if (~overdub[~track] == false,{
					~loopers[~track].set(\trig, 1, \run, 1, \reclev, 1, \prelev, 1, \xfade, 0.02);
					~overdub[~track] = true;
				}, {
					~loopers[~track].set(\run, 0, \reclev, 1, \prelev, -1.dbamp);
				});


			},
			{~loopers[~track].set(\run, 0, \reclev, 0, \prelev, 1);}
			);
			~num[~track] = ~num[~track] +1;
		});
	});



	s.sync;

	/*~looper = Synth(
		\looper, [
			\in, ~micIn,
			\buf, ~b.bufnum,
			\out, ~mainOut
		]
	);*/

	~loopers = [];
	2.do({ arg i;
		~loopers = ~loopers.add(
			Synth( \looper, [ \in, ~micIn, \buf, ~buffers[i].bufnum, \out, ~mainOut])
		);
	});


});
)



s.plotTree;
s.freeAll;

//Line6 Loop Pedal Emulation
//(condensed into one SynthDef)
//FEEDBACK WARNING! USE HEADPHONES!

(
~mainOut = 0;
~micIn = 0;
~num = 0;
~overdub = false;
~track = 1;

s.waitForBoot({
	MIDIIn.connectAll;
	Buffer.freeAll;
	s.sync;
	~b = Buffer.alloc(s, s.sampleRate * 300);
	~b2 = Buffer.alloc(s, s.sampleRate * 300);

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
	
	
	~looper_kill = {
		arg loop, buffer;
		buffer.zero; loop.set(\trig, 1, \run, 0, \reclev, 0, \prelev, 0, \xfade, 0.02);
	};
	
	~looper_start = {
		arg loop;
		loop.set(\trig, 1, \run, 1, \reclev, 1, \prelev, 1, \xfade, 0.02);
	};
	 
	~looper_overdub = {
		arg loop;
		loop.set(\run, 0, \reclev, 1, \prelev, -1.dbamp);
	};   

	MIDIdef.noteOn(\on, {
		arg val, num, chan, src;

		switch (num,
			44,   { ~track = 1;},
			45,   { ~track = 2;},
			48, {
				/*~b.zero; ~looper.set(\trig, 1, \run, 0, \reclev, 0, \prelev, 0, \xfade, 0.02);
				~overdub = false;
				~num = 0;*/
				if (~track == 1, {~looper_kill(\loop, ~looper, \buffer, ~b);} , {~looper_kill(\loop, ~looper2, \buffer, ~b2);});
			 }
		);

	});
	
	MIDIdef.cc(\te, {
		arg val, num, chan, src;
		if ( val == 0 && num == 64, {
			if (~num % 2 == 0,
				{
				if (~overdub == false,{ 
					~looper.set(\trig, 1, \run, 1, \reclev, 1, \prelev, 1, \xfade, 0.02);
					~overdub = true;
				}, {
					~looper.set(\run, 0, \reclev, 1, \prelev, -1.dbamp);
				});
				
				
				},
				{~looper.set(\run, 0, \reclev, 0, \prelev, 1);}
			);
			~num = ~num +1;
		});
	});



	s.sync;

	~looper = Synth(
		\looper, [
			\in, ~micIn,
			\buf, ~b.bufnum,
			\out, ~mainOut
		]
	);
	
	~looper2 = Synth(
		\looper, [
			\in, ~micIn,
			\buf, ~b2.bufnum,
			\out, ~mainOut
		]
	);
});
)



(
Server.killAll;
~track_number = 4;
~track = 0;
~num = [];
~overdub = [];
~track_number.do({
	~num = ~num.add(0);
	~overdub = ~overdub.add(false);
});


~mainOut = 0;
~micIn = 0;
~ptrBus = Bus.audio(s,1);
~micBus = Bus.audio(s,1);
s.waitForBoot({
	MIDIIn.connectAll;
	Buffer.freeAll;
	s.sync;
	~b = Buffer.alloc(s, s.sampleRate * 300);
	~b2 = Buffer.alloc(s, s.sampleRate * 300);

	~buffers = [];
	~track_number.do({
		~buffers = ~buffers.add(
			Buffer.alloc(s, s.sampleRate * 300)
		);
	});

	SynthDef(\mic, {
		var sig;
		sig = SoundIn.ar(\in.ar(0));
		Out.ar(\outMic.ir(0), sig);
	}).add;

	SynthDef(\pointer, {
		var trig, max,ptr;
		trig = Trig1.ar(\trig.tr(0), ControlDur.ir);
		max = Sweep.ar(trig, SampleRate.ir * \run.kr(0));
		ptr = Phasor.ar(trig, 1, 0, max, 0);
		Out.ar(\outPointer.ir(0), ptr);
	}).add;

	SynthDef(\looper, {
		var mic, ptr, loop, rec, mix;
		var xfade = \xfade.kr(0.02);
		var buf = \buf.kr(0);
		mic = In.ar(\inMic.ir(0), 1);
		ptr = In.ar(\inPointer.ir(0), 1);
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


	s.sync;

		MIDIdef.noteOn(\on, {
		arg val, num, chan, src;
		num.postln;
		switch (num,
			44,   { ~track = 0;},
			45,   { ~track = 1;},
			46,   { ~track = 2;},
			47,   { ~track = 3;},
			48,   {
				//free all buffers
				~track_number.do({ arg i;
					~ptrSynth.set(\trig, 1, \run, 0);
					~buffers[i].zero; ~loopers[i].set(\reclev, 0, \prelev, 0, \xfade, 0.02);
					~overdub[i] = false;
					~num[i] = 0;
					~track = 0;
				});
			},
			49, {
				//free specific buffer
				~buffers[~track].zero; ~loopers[~track].set(\reclev, 0, \prelev, 0, \xfade, 0.02);
				~overdub[~track] = false;
				~num[~track] = 0;
			 },
			50,   { ~loopers[~track].set(\loopAmp, 0, \xfade, 1);},
			51,   { ~loopers[~track].set(\loopAmp, 1, \xfade, 1);},
		);

	});

	MIDIdef.cc(\cc, {
		arg val, num, chan, src;

		if ( val == 0 && num == 64, {
			num.postln;
			if (~num[~track] % 2 == 0,
			{
				if (~overdub[~track] == false,{
					~ptrSynth.set(\trig, 1, \run, 1);
					~loopers[~track].set(\reclev, 1, \prelev, 1, \xfade, 0.02);
					~overdub[~track] = true;
				}, {
					~ptrSynth.set(\run, 0);
					~loopers[~track].set( \reclev, 1, \prelev, -1.dbamp);
				});
			},
			{~ptrSynth.set(\run, 0); ~loopers[~track].set(\reclev, 0, \prelev, 1);}
			);
			~num[~track] = ~num[~track] +1;
		});
	});

	~loopers = [];
	~track_number.do({ arg i;
		~loopers = ~loopers.add(
			Synth( \looper, [ \inMic, ~micBus, \buf, ~buffers[i].bufnum, \out, ~mainOut, \inPointer, ~ptrBus]);
		);
	});

	~mic = Synth(\mic, [\in, ~micIn, \outMic, ~micBus]);
	~ptrSynth = Synth(\pointer, [ \outPointer, ~ptrBus, ]);


});
)

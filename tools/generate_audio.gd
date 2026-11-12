extends SceneTree
# Original chiptune music and sound effects for Sugar Rush (v0.31), synthesized from scratch.
# Run: Godot --headless --audio-driver Dummy --path . -s res://tools/generate_audio.gd
# Writes 16-bit mono WAV files to res://assets/audio/. Deterministic: same output every run.
const RATE: int = 22050
const OUT: String = "res://assets/audio/"
var noise_state: int = 12345

func _init() -> void:
	var made: Array[String] = []
	made.append(write("music_game", music_game()))
	made.append(write("music_shop", music_shop()))
	made.append(write("music_boss", music_boss()))
	for sfx_name: String in SFX_BUILDERS:
		made.append(write("sfx_"+sfx_name, call(SFX_BUILDERS[sfx_name])))
	print("Wrote %s audio files: %s" % [made.size(), ", ".join(made)])
	quit()

# --- Synthesis helpers -----------------------------------------------------------
func midi_hz(note: float) -> float:
	return 440.0*pow(2.0,(note-69.0)/12.0)
func noise() -> float:
	noise_state = (noise_state*1103515245+12345)%2147483648
	return float(noise_state)/1073741824.0-1.0
func osc(wave: String, phase: float, duty: float = 0.5) -> float:
	var f: float = phase-floorf(phase)
	match wave:
		"square": return 1.0 if f < duty else -1.0
		"triangle": return 4.0*absf(f-0.5)-1.0
		"saw": return 2.0*f-1.0
		"sine": return sin(f*TAU)
	return 0.0
func buffer(seconds: float) -> PackedFloat32Array:
	var buf: PackedFloat32Array = PackedFloat32Array()
	buf.resize(int(seconds*RATE))
	return buf
# Add a note with attack/release, optional pitch slide and vibrato.
func note(buf: PackedFloat32Array, start: float, length: float, hz: float, wave: String, vol: float, duty: float = 0.5, release: float = 0.04, slide_to: float = 0.0, vibrato: float = 0.0) -> void:
	var first: int = int(start*RATE)
	var count: int = int((length+release)*RATE)
	var phase: float = 0.0
	for i: int in range(count):
		var index: int = first+i
		if index < 0 or index >= buf.size(): continue
		var t: float = float(i)/RATE
		var env: float = minf(1.0,t/0.004)
		if t > length: env *= maxf(0.0,1.0-(t-length)/maxf(release,0.001))
		var freq: float = hz
		if slide_to > 0.0: freq = lerpf(hz,slide_to,minf(1.0,t/maxf(length,0.001)))
		if vibrato > 0.0 and t > 0.12: freq *= 1.0+vibrato*sin(t*TAU*5.5)
		phase += freq/RATE
		buf[index] += osc(wave,phase,duty)*vol*env
# Noise burst with exponential decay; bright = crude high-pass for hats and crackles.
func burst(buf: PackedFloat32Array, start: float, length: float, vol: float, decay: float, bright: bool = false) -> void:
	var first: int = int(start*RATE)
	var last: float = 0.0
	for i: int in range(int(length*RATE)):
		var index: int = first+i
		if index < 0 or index >= buf.size(): continue
		var t: float = float(i)/RATE
		var n: float = noise()
		var sample: float = (n-last) if bright else n
		last = n
		buf[index] += sample*vol*exp(-t*decay)
func kick(buf: PackedFloat32Array, start: float, vol: float) -> void:
	var first: int = int(start*RATE)
	var phase: float = 0.0
	for i: int in range(int(0.18*RATE)):
		var index: int = first+i
		if index >= buf.size(): break
		var t: float = float(i)/RATE
		phase += lerpf(130.0,45.0,minf(1.0,t/0.12))/RATE
		buf[index] += sin(phase*TAU)*vol*exp(-t*18.0)
func chord_tones(root: int, minor: bool) -> Array[int]:
	return [root,root+(3 if minor else 4),root+7]

# Write a float buffer as 16-bit mono WAV (soft-limited).
func write(file_name: String, buf: PackedFloat32Array) -> String:
	var peak: float = 0.0001
	for v: float in buf: peak = maxf(peak,absf(v))
	var gain: float = 0.92/peak if peak > 0.92 else 1.0
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(buf.size()*2)
	for i: int in range(buf.size()):
		var v: float = clampf(buf[i]*gain,-1.0,1.0)
		bytes.encode_s16(i*2,int(v*32767.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	stream.save_to_wav(OUT+file_name+".wav")
	return file_name

# --- Music ---------------------------------------------------------------------------
# A shared arranger: chords per bar, a melody list of [bar, beat, beats, midi], drums and voices.
func arrange(bpm: float, chords: Array, melody: Array, style: Dictionary) -> PackedFloat32Array:
	var beat: float = 60.0/bpm
	var bars: int = chords.size()
	var buf: PackedFloat32Array = buffer(bars*4*beat+0.05)
	for bar: int in range(bars):
		var c: Array = chords[bar]
		var root: int = c[0]
		var minor: bool = c[1]
		var bar_start: float = bar*4*beat
		var tones: Array[int] = chord_tones(root,minor)
		# Bass.
		var bass_pattern: Array = style.get("bass",[0,0,7,12,0,0,7,12])
		for k: int in range(bass_pattern.size()):
			var step_len: float = 4.0*beat/bass_pattern.size()
			note(buf,bar_start+k*step_len,step_len*0.85,midi_hz(root-12+int(bass_pattern[k])),style.get("bass_wave","triangle"),style.get("bass_vol",0.32),0.5,0.02)
		# Arpeggio (16ths) or pads.
		if style.get("arp",true):
			var arp: Array = [0,1,2,1,0,1,2,1,0,1,2,1,0,2,1,2]
			for k: int in range(16):
				var tone: int = tones[int(arp[k])]+12
				note(buf,bar_start+k*beat/4.0,beat/4.0*0.7,midi_hz(tone+12),"square",style.get("arp_vol",0.08),0.25,0.02)
		if style.get("pad",false):
			for tone: int in tones+[root+11 if not minor else root+10]:
				note(buf,bar_start,4*beat*0.95,midi_hz(tone+12),"triangle",0.06,0.5,0.25,0.0,0.004)
		# Drums.
		for b: int in range(4):
			var t: float = bar_start+b*beat
			if style.get("four_on_floor",false) or b%2 == 0: kick(buf,t,style.get("kick_vol",0.55))
			if b%2 == 1: burst(buf,t,0.12,style.get("snare_vol",0.22),26.0)
			for h: int in range(2):
				burst(buf,t+h*beat/2.0,0.03,style.get("hat_vol",0.06),90.0,true)
	# Melody.
	for m: Array in melody:
		var start: float = (float(m[0])*4.0+float(m[1]))*beat
		note(buf,start,float(m[2])*beat*0.92,midi_hz(float(m[3])),style.get("lead_wave","square"),style.get("lead_vol",0.16),style.get("lead_duty",0.5),0.06,0.0,0.006)
	return buf
func repeat_melody(melody: Array, offset_bars: int, transpose: int) -> Array:
	var out: Array = []
	for m: Array in melody: out.append([int(m[0])+offset_bars,m[1],m[2],int(m[3])+transpose])
	return out

func music_game() -> PackedFloat32Array:
	# Upbeat candy-pop: C G Am F | C G F G, twice; second pass an octave up on a softer voice.
	var chords: Array = [[48,false],[43,false],[45,true],[41,false],[48,false],[43,false],[41,false],[43,false]]
	chords = chords+chords
	var a: Array = [
		[0,0,1,76],[0,1,1,79],[0,2,2,84],
		[1,0,1,83],[1,1,1,79],[1,2,1.5,74],[1,3.5,0.5,79],
		[2,0,1,81],[2,1,1,76],[2,2,2,72],
		[3,0,1,77],[3,1,1,81],[3,2,1,84],[3,3,1,81],
		[4,0,0.5,79],[4,0.5,0.5,81],[4,1,1,79],[4,2,2,76],
		[5,0,1,74],[5,1,1,79],[5,2,2,83],
		[6,0,1,81],[6,1,1,77],[6,2,1,72],[6,3,1,77],
		[7,0,1,79],[7,1,1,74],[7,2,2,79]]
	var melody: Array = a+repeat_melody(a,8,12)
	return arrange(112.0,chords,melody,{"lead_vol":0.13,"arp_vol":0.07})

func music_shop() -> PackedFloat32Array:
	# Laid-back shop groove: Fmaj7 Cmaj7 Am7 G, gentle pads, walking bass, soft triangle lead.
	var chords: Array = [[41,false],[48,false],[45,true],[43,false]]
	chords = chords+chords+chords+chords
	var a: Array = [
		[0,0,1.5,81],[0,1.5,0.5,79],[0,2,2,76],
		[1,0,1,79],[1,1,1,76],[1,2,2,72],
		[2,0,1.5,76],[2,1.5,0.5,74],[2,2,2,72],
		[3,0,1,74],[3,1,1,71],[3,2,2,67]]
	var melody: Array = a+repeat_melody(a,4,0)+repeat_melody(a,8,12)+repeat_melody(a,12,0)
	return arrange(90.0,chords,melody,{"bass":[0,4,7,9],"arp":false,"pad":true,"lead_wave":"triangle","lead_vol":0.16,"kick_vol":0.3,"snare_vol":0.1,"hat_vol":0.04})

func music_boss() -> PackedFloat32Array:
	# Tense boss theme: Am F G E, driving bass and four-on-the-floor kick.
	var chords: Array = [[45,true],[41,false],[43,false],[40,false]]
	chords = chords+chords+chords+chords
	var a: Array = [
		[0,0,0.5,81],[0,0.5,0.5,84],[0,1,1,83],[0,2,1,81],[0,3,1,76],
		[1,0,1,77],[1,1,1,81],[1,2,2,84],
		[2,0,0.5,83],[2,0.5,0.5,81],[2,1,1,79],[2,2,2,74],
		[3,0,1,76],[3,1,1,80],[3,2,2,83]]
	var melody: Array = a+repeat_melody(a,4,0)+repeat_melody(a,8,12)+repeat_melody(a,12,0)
	return arrange(128.0,chords,melody,{"bass":[0,0,12,0,0,12,0,7],"bass_wave":"square","bass_vol":0.2,"four_on_floor":true,"kick_vol":0.6,"lead_duty":0.25,"lead_vol":0.14,"arp_vol":0.06})

# --- Sound effects -----------------------------------------------------------------------
const SFX_BUILDERS: Dictionary = {
	"swap":"sfx_swap","invalid":"sfx_invalid","match_big":"sfx_match_big","special_make":"sfx_special_make",
	"special_fire":"sfx_special_fire","combo":"sfx_combo","crack":"sfx_crack","chocolate":"sfx_chocolate",
	"tick":"sfx_tick","coin":"sfx_coin","sell":"sfx_sell","reroll":"sfx_reroll","pack_open":"sfx_pack_open",
	"card_take":"sfx_card_take","click":"sfx_click","hover":"sfx_hover","round_win":"sfx_round_win",
	"defeat":"sfx_defeat","boss":"sfx_boss","victory":"sfx_victory","skip":"sfx_skip","use_item":"sfx_use_item",
}
func sfx_swap() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.12)
	note(b,0.0,0.07,midi_hz(72),"square",0.35,0.25,0.03,midi_hz(79))
	return b
func sfx_invalid() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.3)
	note(b,0.0,0.09,midi_hz(55),"square",0.35,0.5,0.02)
	note(b,0.11,0.12,midi_hz(50),"square",0.35,0.5,0.05)
	return b
func sfx_match_big() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.4)
	for i: int in range(4): note(b,i*0.045,0.12,midi_hz([72,76,79,84][i]),"triangle",0.3,0.5,0.1)
	burst(b,0.0,0.15,0.12,30.0,true)
	return b
func sfx_special_make() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.5)
	for i: int in range(6): note(b,i*0.04,0.08,midi_hz(79+[0,4,7,12,16,19][i]),"square",0.2,0.25,0.08)
	return b
func sfx_special_fire() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.45)
	note(b,0.0,0.3,midi_hz(88),"square",0.25,0.5,0.1,midi_hz(52))
	burst(b,0.0,0.35,0.25,9.0,true)
	return b
func sfx_combo() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.9)
	kick(b,0.0,0.9)
	burst(b,0.0,0.6,0.35,6.0)
	for tone: int in [60,64,67,72]: note(b,0.05,0.4,midi_hz(tone),"square",0.12,0.5,0.35)
	note(b,0.1,0.5,midi_hz(96),"triangle",0.15,0.5,0.3,midi_hz(72))
	return b
func sfx_crack() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.25)
	burst(b,0.0,0.2,0.5,28.0,true)
	note(b,0.0,0.04,midi_hz(96),"square",0.15,0.5,0.03)
	return b
func sfx_chocolate() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.45)
	note(b,0.0,0.35,midi_hz(45),"sine",0.6,0.5,0.08,midi_hz(38),0.05)
	burst(b,0.0,0.3,0.08,10.0)
	return b
func sfx_tick() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.05)
	note(b,0.0,0.015,midi_hz(96),"square",0.2,0.5,0.01)
	return b
func sfx_coin() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.35)
	note(b,0.0,0.06,midi_hz(83),"square",0.3,0.5,0.02)
	note(b,0.06,0.18,midi_hz(88),"square",0.3,0.5,0.1)
	return b
func sfx_sell() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.35)
	note(b,0.0,0.06,midi_hz(88),"square",0.28,0.5,0.02)
	note(b,0.06,0.16,midi_hz(81),"square",0.28,0.5,0.1)
	return b
func sfx_reroll() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.4)
	for i: int in range(6): burst(b,i*0.05,0.03,0.35,60.0,true)
	note(b,0.28,0.06,midi_hz(84),"square",0.2,0.25,0.04)
	return b
func sfx_pack_open() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.7)
	burst(b,0.0,0.25,0.4,8.0,true)
	note(b,0.0,0.2,midi_hz(60),"saw",0.12,0.5,0.05,midi_hz(84))
	for i: int in range(5): note(b,0.22+i*0.05,0.08,midi_hz(84+[0,4,7,12,16][i]),"triangle",0.22,0.5,0.1)
	return b
func sfx_card_take() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.3)
	burst(b,0.0,0.12,0.2,20.0,true)
	note(b,0.02,0.12,midi_hz(72),"triangle",0.3,0.5,0.06,midi_hz(84))
	return b
func sfx_click() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.05)
	note(b,0.0,0.012,midi_hz(84),"square",0.18,0.25,0.01)
	return b
func sfx_hover() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.06)
	note(b,0.0,0.02,midi_hz(91),"triangle",0.12,0.5,0.02)
	return b
func sfx_round_win() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(1.0)
	var tune: Array = [[0.0,72],[0.1,76],[0.2,79],[0.3,84]]
	for t: Array in tune: note(b,t[0],0.1,midi_hz(t[1]),"square",0.25,0.5,0.05)
	for tone: int in [72,76,79,84]: note(b,0.42,0.4,midi_hz(tone),"triangle",0.14,0.5,0.15,0.0,0.006)
	return b
func sfx_defeat() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(1.3)
	var tune: Array = [[0.0,67],[0.25,64],[0.5,60],[0.75,55]]
	for t: Array in tune: note(b,t[0],0.22,midi_hz(t[1]),"square",0.25,0.5,0.06,0.0,0.01)
	note(b,1.0,0.25,midi_hz(43),"triangle",0.3,0.5,0.1)
	return b
func sfx_boss() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(1.0)
	kick(b,0.0,0.9)
	for tone: int in [45,48,51]: note(b,0.0,0.7,midi_hz(tone),"saw",0.12,0.5,0.25,0.0,0.01)
	burst(b,0.0,0.5,0.15,5.0)
	return b
func sfx_victory() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(2.2)
	var tune: Array = [[0.0,72,0.12],[0.13,72,0.12],[0.26,72,0.12],[0.4,79,0.4],[0.85,77,0.12],[0.98,79,0.12],[1.1,84,0.8]]
	for t: Array in tune: note(b,t[0],t[2],midi_hz(t[1]),"square",0.24,0.5,0.06,0.0,0.006)
	for tone: int in [60,64,67,72]: note(b,1.1,0.8,midi_hz(tone),"triangle",0.12,0.5,0.3)
	kick(b,1.1,0.7)
	return b
func sfx_skip() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.35)
	note(b,0.0,0.2,midi_hz(67),"triangle",0.3,0.5,0.08,midi_hz(91))
	burst(b,0.0,0.15,0.12,20.0,true)
	return b
func sfx_use_item() -> PackedFloat32Array:
	var b: PackedFloat32Array = buffer(0.4)
	for i: int in range(3): note(b,i*0.06,0.1,midi_hz([76,81,88][i]),"triangle",0.28,0.5,0.1)
	burst(b,0.0,0.2,0.1,15.0,true)
	return b

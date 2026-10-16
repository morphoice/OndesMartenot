declare name "OndesMartenot";
declare description "Ondes Martenot-style voice: sine core, timbre drawer, touche, and the four diffuseurs";
import("stdfaust.lib");

// ---------- player controls ----------
ruban  = hslider("[0]ruban (pitch) [unit:Hz][scale:log]", 440, 55, 1760, 0.01) : si.smoo;   // ribbon glide
touche = hslider("[1]touche (intensity)", 0, 0, 1, 0.001) : si.smooth(ba.tau2pole(0.03));   // left-hand key
vibR   = hslider("[2]vibrato rate [unit:Hz]", 5.5, 0, 9, 0.01);
vibD   = hslider("[3]vibrato depth [unit:cents]", 12, 0, 60, 0.1);

f = ruban * pow(2, vibD * os.osc(vibR) / 1200);

// ---------- timbre drawer (O, C, G, 8, N, S) ----------
gO = hslider("h:timbres/[0]O onde", 1, 0, 1, 0.01);
gC = hslider("h:timbres/[1]C creux", 0, 0, 1, 0.01);
gG = hslider("h:timbres/[2]G gambe", 0, 0, 1, 0.01);
g8 = hslider("h:timbres/[3]8 octaviant", 0, 0, 1, 0.01);
gN = hslider("h:timbres/[4]N nasillard", 0, 0, 1, 0.01);
gS = hslider("h:timbres/[5]S souffle", 0, 0, 1, 0.01);

onde      = os.osc(f);
creux     = os.square(f) : fi.lowpass(2, f*3);        // hollow, odd harmonics
gambe     = os.sawtooth(f) : fi.lowpass(2, f*5);      // bowed-string-ish
octav     = os.osc(2*f);
nasillard = os.pulsetrain(f, 0.12) : fi.highpass(1, f*2);
souffle   = no.noise : fi.resonbp(f, 6, 1);           // breathy, pitched noise

src   = onde*gO + creux*gC + gambe*gG + octav*g8 + nasillard*gN + souffle*gS*0.3;
voice = src * pow(touche, 1.6) * 0.3;                 // soft-curve intensity

// ---------- diffuseurs ----------
// Palme: 12 sympathetic strings tuned chromatically (Karplus-Strong-style loops)
string(fr) = (+ : de.fdelay(4096, ma.SR/fr - 1)) ~ (fi.lowpass(1, 5000) : *(0.996));
palme = *(0.02) <: par(i, 12, string(220 * pow(2, i/12.0))) :> _;

// Metallique: gong used as speaker membrane -> inharmonic modal bank
gong = (1.0, 1.47, 2.09, 2.56, 3.39, 4.17, 4.95, 6.12);
metallique = _ <: par(i, 8, fi.resonbp(180 * ba.take(i+1, gong), 60, 0.02)) :> _;

// Resonance: spring reverb -> dispersive allpass chain in a feedback loop (the "chirp")
ap(a) = _ <: *(a), mem : + : (+ ~ *(-a));
resonance = (+ : seq(i, 40, ap(0.62)) : de.delay(4096, 1100) : fi.lowpass(2, 4500)) ~ *(0.55) : *(0.4);

dPr  = hslider("h:diffuseurs/[0]principal", 1, 0, 1, 0.01);
dPal = hslider("h:diffuseurs/[1]palme", 0.5, 0, 1, 0.01);
dMet = hslider("h:diffuseurs/[2]metallique", 0, 0, 1, 0.01);
dRes = hslider("h:diffuseurs/[3]resonance", 0.3, 0, 1, 0.01);

process = voice <: _*dPr + palme*dPal + metallique*dMet + resonance*dRes <: _,_;

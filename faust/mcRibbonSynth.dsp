import("stdfaust.lib");
declare options "[midi:on]";

// -------------------------------------------------------------------//
// A Series
// -------------------------------------------------------------------//

//carrier_freq_low = 27.5;    // A0 - carrier frequency low value
carrier_freq_low = 55;    // A1 - carrier frequency low value
//carrier_freq_low = 110;    // A2 - carrier frequency low value
//carrier_freq_low = 220;    // A3 - carrier frequency low value
//carrier_freq_low = 440;    // A4 - carrier frequency low value
// -------------------------------------------------------------------//
//carrier_freq_high = 880;   // A5 -  carrier frequency high value
//carrier_freq_high = 1760;   // A6 -  carrier frequency high value
carrier_freq_high = 3520; // A7 -  carrier frequency high value
//carrier_freq_high = 7040; // A8 -  carrier frequency high value

// -------------------------------------------------------------------//
// D Series
// -------------------------------------------------------------------//
//carrier_freq_low = 36.708095989676;  // D1 - carrier frequency low value
//carrier_freq_low = 73.4161919793519;  // D2 - carrier frequency low value
//carrier_freq_low = 146.832383958704;  // D3 - carrier frequency low valu
//carrier_freq_low = 293.66476791741;  // D4 - carrier frequency low value
//carrier_freq_low = 587.32953583482;  // D5 - carrier frequency low value

//carrier_freq_high = 1174.6590716696;  // D6 - carrier frequency low value
//carrier_freq_low = 2349.3181433393;  // D7 - carrier frequency low value
//carrier_freq_low = 4698.6362866785;  // D8 - carrier frequency low value
//carrier_freq_low = 9397.272573357;  // D9 - carrier frequency low value

// -------------------------------------------------------------------//
// Globals
// -------------------------------------------------------------------//
input_resolution = 127;     // analog pins 10bit 0-1023

/* AM Modulation
import("stdfaust.lib");
declare options "[midi:on]";

sqr2o2 = sqrt(2)/2;
freq = hslider("freq",50,27.5,3520,0.01);
gain = hslider("gain", 0.5, 0, 1.0, 0.01) : ba.lin2LogGain * 0.5;
gate = button("gate");

am_low = 0.5;
am_high = 5.0;
am_freq = checkbox("rotorspeed") * (am_high - am_low) + am_low : si.smooth(4);
am = os.osc(am_freq);

env = en.adsr(0.1,1,0.5, 0.5, gate);
am_env = en.asr(4.0, 1, 0.5, gate );
trem_env = en.asr(2.0, 1, 0.5, gate );
am_phasor = os.lf_triangle(am_freq) * 0.5 + 0.5;
am_l = 1 - abs(sin(am_phasor)) * trem_env;
am_r = 1 - abs(cos(am_phasor))  * trem_env;
process = os.sawtooth(freq) * gain * env : *am <: _,_;
*/

// -------------------------------------------------------------------//
// Carrier Frequency
// -------------------------------------------------------------------//

carrierGroup(x) = vgroup("Carrier", x);
carrier_scaler = ma.log2(carrier_freq_high/carrier_freq_low); 

carrier_freq_slider = carrierGroup(hslider("[0]control value[midi:ctrl 1 1]", 65, 0, input_resolution, 0.01) : si.smoo);
carrier_freq = 2^(carrier_freq_slider/input_resolution*carrier_scaler) * carrier_freq_low  : si.smoo //ba.line(ma.SR * 0.1) 
    <: attach(_,
        carrierGroup(hbargraph("[1]freq",carrier_freq_low, carrier_freq_high))
    ); // create and display frequency

carrier_gain_slider = carrierGroup(hslider("[2]gain[midi:ctrl 2 1]", 0.5, 0, 1, 0.001) : si.smoo);
gain = carrier_gain_slider : ba.lin2LogGain
    <: attach(_, 
        carrierGroup(hbargraph("[3]level", 0, 1))
    );

chorus_width_slider = carrierGroup(hslider("[4]chorus width[midi:ctrl 5 1]", 0, 0, 1, .00001) : si.smoo);
chorus_width = chorus_width_slider * 0.01;
pan_width_slider = carrierGroup(hslider("[5]pan width[midi:ctrl 6 1]", 0, 0, 1, .00001) : si.smoo);
pan_width = pan_width_slider * 0.25;

modulatorGroup(x) = vgroup("Modulator", x);
modulation_scaler = ma.log2(carrier_freq_high/carrier_freq_low*2); 
modulator_freq_slider = modulatorGroup(hslider("[6]moduator freq[midi:ctrl 3 1]", 0, 0, input_resolution, 0.01) : si.smoo);
modulator_freq = 2^(modulator_freq_slider/input_resolution * modulation_scaler) * carrier_freq_low
    <: attach(_,
       modulatorGroup( hbargraph("[7]modulator freq", carrier_freq_low, carrier_freq_high * 2) )
    );
modulator_index_slider = modulatorGroup(hslider("[8]mod ammount[midi:ctrl 4 1]", 0, 0, input_resolution, 0.01) : si.smoo);
modulator_index = modulator_index_slider/input_resolution * carrier_freq;
modulator = os.lf_triangle(modulator_freq) * modulator_index;


dist = hslider("h:[3]effect/[9]dist[midi:ctrl 7 1]", 0, 0, 127, 0.01)/input_resolution;
noise_slider = hslider("h:[3]effect/[10]noise[midi:ctrl 8 1]", 0, 0, 127, 0.01)/input_resolution;
noise_scaler = 0.1;
noise1 = no.noise * noise_scaler * noise_slider;
noise2 = no.noise * noise_scaler * noise_slider;
noise3 = no.noise * noise_scaler * noise_slider;

c1_l = os.triangle(carrier_freq - (carrier_freq * chorus_width) + modulator ) + noise1 : ef.cubicnl(dist, 0) : _ / 3 * sqrt(2)/2 * (cos(ma.PI*2*pan_width));
c1_r = os.triangle(carrier_freq - (carrier_freq * chorus_width) + modulator ) + noise1 : ef.cubicnl(dist, 0) : _ / 3 * sqrt(2)/2 * (sin(ma.PI*2*pan_width));
c2_l = os.sawtooth(carrier_freq + modulator ) + noise2: ef.cubicnl(dist, 0) : _ / 3 * sqrt(2)/2 * (cos(ma.PI*2*0.125) );
c2_r = os.sawtooth(carrier_freq + modulator ) + noise2: ef.cubicnl(dist, 0) : _ / 3 * sqrt(2)/2 * (sin(ma.PI*2*0.125) );
c3_l = os.triangle(carrier_freq + (carrier_freq * chorus_width) + modulator ) + noise3 : ef.cubicnl(dist, 0) : _ / 3 * sqrt(2)/2 * (sin(ma.PI*2*pan_width));    
c3_r = os.triangle(carrier_freq + (carrier_freq * chorus_width) + modulator ) + noise3 : ef.cubicnl(dist, 0) : _ / 3 * sqrt(2)/2 * (cos(ma.PI*2*pan_width));    

process = (c1_l  + c2_l + c3_l) * gain, (c1_r  + c2_r + c3_r) * gain;
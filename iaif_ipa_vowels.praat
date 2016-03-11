########################################################
# Praat script for synthesizing IPA vowels using an excitation
# source derived from natural speech.
# Record a word, segment the vowel using 'extract selected sound', then select it 
# and run this script.
# Bandwidths can be set as constants or modelled based on the coefficients in 
# Hawks & Miller (1995)
# Set 'hf_rest' to 1 or 0 to toggle restoration of HF component from original token
# Set 'pitch_track' to 1 or 0 to toggle pitch manipulation.
# This method is based on Alku, P., Tiitinen, H. & Naatanen, R. (1999) 
# 'A method for generating natural-sounding speech stimuli for cognitive
# brain research'.Clinical Neurophysiology 110 1329-1333.
# Created by Daniel Lawrence 07/04/15.
#########################################################
bandwidth_estimation$ = "Normal" 
#"Normal" or "Hawks & Miller 1995"
speaker_sex$ = "Male"
f0=200
minf=4
hf_rest=1
liprad=1
pitch_track=0
filter_cutoff=4000
filter_crossover=2000
Rename... Original_A_token
source_segment$=selected$("Sound")
if pitch_track=1
call F0_extract 'source_segment$'
endif

###Set up polynomials for bandwidth prediction#####
if bandwidth_estimation$="Hawks & Miller 1995"
	low_k=165.327516
	Create Polynomial: "low_x", 1, 5, "-0.673636734000000015 0.001808744460000000 -0.000004522016820000 0.000000007495140000 -0.000000000004702192  "
	high_k=15.8146139
	Create Polynomial: "high_x", 1, 5, "0.0810159009000000068790 -0.0000979728215000000004 0.0000000528725064000000 -0.0000000000107099264000 0.0000000000000007915285  "
endif
##########################################


call HPfilter 'source_segment$' filter_cutoff filter_crossover
call LPfilter 'source_segment$' filter_cutoff filter_crossover

@extractSource
@cardinalVowels

procedure extractSource
	select Sound 'source_segment$'
	Resample... 10000 50
	target_resamp$ = selected$("Sound")
	target_int= Get intensity (dB)
		call iaif 'target_resamp$'
	select Sound G
	Resample... 48000 50
	Scale intensity... target_int
	source_seg_duration= Get total duration
	Rename... whitened_source
	whitened_source$ = selected$("Sound")
endproc

procedure cardinalVowels
###Make an empty formantgrid
	Create FormantGrid... Clean 0 source_seg_duration 4 550 1100 60 50
	for f from 1 to 4
		Remove formant points between... 'f' 0 source_seg_duration
		Remove bandwidth points between... 'f' 0 source_seg_duration
	endfor
###Do the synthesis
call synthVowel 'whitened_source$' Clean upper_high_front 294 2343 3251 4251 70
call synthVowel 'whitened_source$' Clean lower_high_front 360 2187 2830 3830 70
call synthVowel 'whitened_source$' Clean upper_mid_front 434 2148 2763 3763 70
call synthVowel 'whitened_source$' Clean lower_mid_front 581 1840 2429 3429 70
call synthVowel 'whitened_source$' Clean upper_low_front 766 1728 2398 3398 70
call synthVowel 'whitened_source$' Clean lower_low_front 806 1632 2684 3684 70
call synthVowel 'whitened_source$' Clean lower_low_back 652 843 2011 3011 70
call synthVowel 'whitened_source$' Clean lower_mid_back 541 830 2221 3221 70
call synthVowel 'whitened_source$' Clean upper_mid_back 406 727 2090 3090 70
call synthVowel 'whitened_source$' Clean lower_high_back 334 910 2300 3300 70
call synthVowel 'whitened_source$' Clean upper_high_back 295 750 2342 3342 70
call synthVowel 'whitened_source$' Clean mid_central_unrounded 500 1500 2500 3500 70
	#300 2300 2600 3500 70
	#800 1150 2400 3400 70
	#350 800 2300 3100 70
	#500 1500 2500 3500 70
###Concatenate the vowels
# put the vowels together
	select Sound upper_high_front
	plus Sound lower_high_front
	plus Sound upper_mid_front
	plus Sound lower_mid_front
	plus Sound upper_low_front
	plus Sound lower_low_front
	plus Sound lower_low_back
	plus Sound lower_mid_back
	plus Sound upper_mid_back
	plus Sound lower_high_back
	plus Sound upper_high_back
	plus Sound mid_central_unrounded
	Concatenate recoverably
	select Sound upper_high_front
	plus Sound lower_high_front
	plus Sound upper_mid_front
	plus Sound lower_mid_front
	plus Sound upper_low_front
	plus Sound lower_low_front
	plus Sound lower_low_back
	plus Sound lower_mid_back
	plus Sound upper_mid_back
	plus Sound lower_high_back
	plus Sound upper_high_back
	plus Sound mid_central_unrounded
	Remove
	select Sound chain
	Rename... Cardinal_vowels
	select TextGrid chain
	Rename... Cardinal_vowels
	select Sound Cardinal_vowels
	plus TextGrid Cardinal_vowels
	View & Edit
endproc

procedure synthVowel .source$ .filter$ .name$ .f1 .f2 .f3 .f4 .int
	select FormantGrid '.filter$'
	Copy... '.name$'
for .formant from 1 to minf
	.f5 = 4500
	freq=.f5
@predictBand: .formant, freq
	select FormantGrid '.name$'
	Add formant point... '.formant' 0 .f'.formant'
	if .formant=1
		freq=.f1
	endif
	if .formant=2
		freq=.f2
	endif
	if .formant=3
		freq=.f3
	endif
	if .formant=4
		freq=.f4
	endif
Add bandwidth point... '.formant' 0.1 predictBand.value
endfor
###Combine with source
	select Sound '.source$'
	plus FormantGrid '.name$'
	Filter
if liprad=1
###Pre-emphasis filter to restore lip radiation effect
	Filter (pre-emphasis)... 100
endif
	Rename... '.name$'
###LP filter
call HPfilter '.name$' filter_cutoff filter_crossover
###Delete original
select Sound '.name$'
plus IntensityTier '.name$'_LF_portion_intensity
plus FormantGrid '.name$'
Remove
###Restore HF energy
call addHF '.name$'_LF_portion '.target$'_HP_portion
Scale intensity... '.int'
Rename... '.name$'
endproc

##Bandwidth estimation from formant value
procedure predictBand .formantname .freq
	if bandwidth_estimation$ = "Hawks & Miller 1995"
	scalard=88
	scalaren=f0-132
	mult=scalaren/scalard
	scalar=1+0.25*mult
	if .freq<500
		select Polynomial low_x
		poly=Get value... '.freq'
		constantpoly=low_k+poly
		.value=scalar*constantpoly
	endif

	if .freq>500
		select Polynomial high_x
		poly=Get value... '.freq'
		constantpoly=high_k+poly
		.value=scalar*constantpoly
	endif
endif

if bandwidth_estimation$="Normal"
	f1BW = 75
	f2BW = 85
	f3BW = 90
	f4BW = 100
	f5BW = 210
		if .formantname =1
			.value=f1BW
		endif
		if .formantname =2
			.value=f2BW
		endif
		if .formantname =3
			.value=f3BW
		endif
		if .formantname=4
			value=f4BW
		endif
		if .formantname=5
			.value=f5BW
		endif
endif
endproc

##Hann filtering
procedure HPfilter .target$ .cutoff .cross
	select Sound '.target$'
	Filter (pass Hann band)... 0 .cutoff .cross
	original_LF_intensity = Get intensity (dB)
	To Intensity... 100 0 yes
	Down to IntensityTier
	Rename... '.target$'_LF_portion_intensity
	select Intensity '.target$'_band
	Remove
	select Sound '.target$'_band
	Rename... '.target$'_LF_portion
	last_LF$=selected$("Sound")
endproc

procedure LPfilter .target$ .cutoff .cross
	select Sound '.target$'
	Filter (stop Hann band)... 0 .cutoff .cross
	select Sound '.target$'_band
	Rename... '.target$'_HP_portion
endproc	

##HF component restoration 
procedure addHF .sound$ .filteredsound$
	select Sound '.sound$'
if hf_rest=1
	Formula... self [col] + Sound_Original_A_token_HP_portion [col]
endif
endproc

procedure F0_extract .target$
	select Sound '.target$'
	oldsource$=selected$("Sound")
	To Manipulation... 0.01 75 600
	View & Edit
	editor Manipulation '.target$'
	pause Check accuracy of F0 tracking, modify as desired
	Publish resynthesis
	Close
	endeditor
	Rename... "Pitch manipulated A token"
	source$=selected$("Sound")
	select Manipulation 'oldsource$'
	Extract pitch tier
	f0=Get mean (points)... 0 0
	select PitchTier 'oldsource$'
	select Sound 'oldsource$'
	plus Manipulation 'oldsource$'
	Remove
endproc

###############################
#Praat script for Iterative Adaptive Inverse Filtering
#Following Alku (1992). 
###############################

procedure iaif .sound$
select Sound '.sound$'
sf=Get sampling frequency
tstart=Get start time
tend=Get end time
###	Parameters
d=0.99
p_gl=2*round(sf/4000)
p_vt=2*round(sf/2000)+4
preflt = p_vt+1

###	Create the leaky integrator
Create Sound from formula... lip_rad mono tstart tend sf exp(-x/(1-d))

###Block 1-2	
select Sound '.sound$'
To LPC (autocorrelation)... 1 0.025 0.005 70
Rename... Hg1

###Block 3
plus Sound '.sound$'
Filter (inverse)
Rename... Y

###Block 4
select Sound Y
To LPC (autocorrelation)... p_vt 0.025 0.005 0
Rename... Hvt1

###Block 5
plus Sound '.sound$'
Filter (inverse)
###Block 6
if liprad=1
Rename... G1_norad
plus Sound lip_rad
Convolve: "sum", "zero"
Rename... G_est
Edit
editor Sound G_est
	Select: tstart, tend
	Extract selected sound (time from 0)
	Close
endeditor
endif
Rename... G1

###Block 7
select Sound G1
To LPC (autocorrelation)... p_gl 0.025 0.005 0
Rename... G1
###Block 8
plus Sound '.sound$'
Filter (inverse)
Rename... Hg2
###Block 9
if liprad=1
Rename... Hg2_norad
plus Sound lip_rad
Convolve: "sum", "zero"
Rename... HG2_est
Edit
editor Sound HG2_est
	Select: tstart, tend
	Extract selected sound (time from 0)
	Close
endeditor
endif
Rename... Hg2
###Block 10
select Sound Hg2
To LPC (autocorrelation)... p_vt 0.025 0.005 0
Rename... Hvt2

###Block 11
plus Sound '.sound$'
Filter (inverse)
Rename... Hvt2_norad

###Block 12
if liprad=1
plus Sound lip_rad
Convolve: "sum", "zero"
Rename... Hvt2_est
Edit
editor Sound Hvt2_est
	Select: tstart, tend
	Extract selected sound (time from 0)
	Close
endeditor
endif
Rename... G
select LPC Hg1
plus Sound Y
plus LPC Hvt1
if liprad=1
plus Sound G1_norad
plus Sound G_est
endif
plus Sound G1
plus LPC G1
plus Sound Hg2
plus LPC Hvt2
if liprad=1
plus Sound Hvt2_norad
plus Sound Hvt2_est
endif
Remove
endproc


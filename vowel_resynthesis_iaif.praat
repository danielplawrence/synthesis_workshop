########################################################
# Praat script for LPC analysis and resynthesis with
# high-frequency filtering for high quality
# semisynthetic stimuli.
# This method is based on Alku, P., Tiitinen, H. & Naatanen, R. (1999) 
# 'A method for generating natural-sounding speech stimuli for cognitive
# brain research'.Clinical Neurophysiology 110 1329-1333
# Created by Daniel Lawrence 07/04/2015
#########################################################
##Get options
dir$=defaultDirectory$+"/Continuum/"
beginPause: "Vowel Resynthesis options 1"
	boolean: "Modify duration", 1
	boolean: "Modify f1", 1
	boolean: "Modify f2", 1
	boolean: "Modify f3", 0
	boolean: "Modify f4", 0
	boolean: "Modify f5", 0
	boolean: "Simulate lip radiation", 1
	boolean: "Write_targets to directory", 1
	text: "dir", dir$
	boolean: "Clean_up", 1
clicked = endPause: "Continue",1

beginPause: "Vowel Resynthesis options 2"
	choice: "Bandwidth estimation", 2
	option: "Hawks and Miller 1995"
	option: "Normal"
	choice: "Speaker sex", 1
	option: "Male"
	option: "Female"
	choice: "Interpolation method", 1
	option: "Bark" 
	option: "Linear"
	positive: "Reference f1", 550
	positive: "Reference f2", 1650
	positive: "Reference f3", 2750
	positive: "Reference f4", 3850
	positive: "Reference f5", 4950
	positive: "Filter cutoff", 3500
	positive: "Filter crossover", 1000
	positive: "Number of steps", 6
	positive: "Crossfade overlap", 0.07
clicked = endPause: "Continue", 1

## This is the main program body -- check out each function to see what it does##
call setVars
call selectSounds
call F0_extract 'source$'
call segmentAndExtract
call durationMatching 'source_segment$' 'target_segment$'
call HPfilter 'source_segment$' filter_cutoff filter_crossover
call LPfilter 'source_segment$' filter_cutoff filter_crossover
call extractSource
call newFilter 'source_segment$' 5 5000 0.025 A_token
call newFilter 'target_segment$' 5 5000 0.025 B_token
call checkFormantGrid A_token Endpoint_A 'source_segment$'
call checkFormantGrid B_token Endpoint_B 'target_segment$'
call cardinalVowels
call interpolateFormants 'source_segment$' 'target_segment$' nsteps
call morphDuration stimulus_step_1 target_seg_duration nsteps 75 600
call concatenate cat_overlap nsteps
call cleanUp
################################################################
########Functions################################################
##LPC decomposition
procedure extractSource
	select Sound 'source_segment$'
	Resample... 10000 50
	target_resamp$ = selected$("Sound")
	target_int= Get intensity (dB)
	call iaif 'target_resamp$'
	select Sound G
	Resample... source_samplerate 50
	Scale intensity... target_int
	Rename... whitened_source
	whitened_source$ = selected$("Sound")
	call matchInt 'whitened_source$' 'last_LF$' 1
	select Intensity whitened_source
	plus IntensityTier whitened_source
	Remove
endproc

##Prompt user to check the endpoints
procedure checkFormantGrid .agrid$ .name$ .formantname$
	select FormantGrid '.agrid$'
	View & Edit
	editor FormantGrid '.agrid$'
		pause Please check formant grid for '.name$'
		Close
	endeditor
To Formant... 0.01 0.1
Rename... '.formantname$'
endproc

##Duration matching
###In order to calculate values for continua, we need a version of the B endpoint which matches the 
###duration of the source
procedure durationMatching .source$ .target$
###Match the durations of two sounds
###First, get ratio of source to target:
if which_b=1
	select Sound '.source$'
	duration_of_source = Get total duration
	select Sound '.target$'
	duration_of_target = Get total duration
	duration_ratio = duration_of_source/duration_of_target
###Create a manipulation object 

	select Sound '.target$'
	To Manipulation... 0.01 75 600
	target_manip$= selected$("Manipulation")
	Extract duration tier
	target_dur$= selected$("DurationTier")

###Lengthen by the desired amount

	Add point... 0 duration_ratio
	Add point... duration_of_target duration_ratio
		
###Combine with manipulation

select Manipulation 'target_manip$'
plus DurationTier 'target_dur$'
Replace duration tier

select Manipulation 'target_manip$'
Get resynthesis (overlap-add)
Rename... '.target$'_duration_matched
target_segment$=selected$("Sound")
select Manipulation 'target_manip$'
select DurationTier 'target_dur$'
Remove
endif
endproc

##Simulate cardinal vowels
procedure cardinalVowels
###Make an empty formantgrid
	Create FormantGrid... Clean 0 source_seg_duration minf 550 1100 60 50
	for f from 1 to minf
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
	pause Check quality of vowels and re-run script as necessary 
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

##Interpolation
procedure interpolateFormants .formanta$ .formantb$ .nsteps

##First thing we need to do is work out a distance matrix between 
##A and B, with a distance at every point for every formant

for f from 1 to minf
select Formant '.formanta$'
	alen= Get number of frames
	To Matrix... f
	Rename... source_f'f'
select Formant '.formantb$'
	blen = Get number of frames
	To Matrix... f
	Rename... target_f'f'

if interpolation_method$="Bark"
select Matrix source_f'f'
Formula... (26.81/(1+(1960/self))) - 0.53
select Matrix target_f'f'
Formula... (26.81/(1+(1960/self))) - 0.53
endif

maxlen=max(alen,blen)
	Create simple Matrix... f_'f'_distances 1 maxlen x=0

	for j from 1 to maxlen
	if Matrix_target_f'f'[1,j] <> undefined && Matrix_source_f'f'[1,j] <> undefined
		val=Matrix_target_f'f'[1,j]-Matrix_source_f'f'[1,j]
		Set value... 1 j val
	endif
	endfor
endfor

##Time-domain conversion
select Formant 'source_segment$'
Copy... clean_grid
Down to Table... yes yes 6 no 3 yes 3 no
for step from 1 to .nsteps
Create FormantGrid... grid_step_'step' 0 source_seg_duration minf 550 1100 60 50
	for f from 1 to minf
		if modify_f'f'=1
		Remove formant points between... 'f' 0 source_seg_duration
		Remove bandwidth points between... 'f' 0 source_seg_duration
		endif
	endfor
	for f from 1 to minf
	running_mean=0
	#Calculate interval and add points
		if modify_f'f'=1
		for point from 1 to maxlen
			time= Table_clean_grid [point, 2]
			thisdist=Matrix_f_'f'_distances[1,point]/(.nsteps - 1)
			newval= (thisdist*('step'-1)) + Matrix_source_f'f'[1,point]
			if interpolation_method$="Bark"
			newval=1960/(26.81/(newval + 0.53) - 1)
			endif
			running_mean=running_mean+newval
			select FormantGrid grid_step_'step'
			if newval>0
				Add formant point... 'f' 'time' 'newval'
			endif
		endfor
		running_mean=running_mean/maxlen
		endif
		call setBandWidths grid_step_'step' 'f' running_mean
	endfor
call makeStimulus 'whitened_source$' grid_step_'step' stimulus_step_'step' 70 
endfor
select Table clean_grid
if bandwidth_estimation$="Hawks and Miller 1995"
plus Polynomial low_x
plus Polynomial high_x
endif
Remove
endproc
##

##Selection of endpoints
procedure selectSounds
	pause Select the source sound
	source$ = selected$ ("Sound")
	source_samplerate = Get sampling frequency
	source_numchannels = Get number of channels
	source_duration = Get total duration
     if source_numchannels = 2
	   select Sound 'source$'
	   Convert to mono
   	source$ = selected$ ("Sound")
	source_samplerate = Get sampling frequency
	source_numchannels = Get number of channels
	source_duration = Get total duration
     endif
	
   beginPause ("Choose B endpoint")
	comment ("How would you like to create the continuum endpoint?")
    choice ("which_b", 1)
       option ("Select B endpoint")
       option ("Generate endpoint by modifiying original")    
     endPause ("Cancel", "OK", 2)
 	if which_b = 1
 		pause Select the sound to be used as B endpoint
		   target$ = selected$ ("Sound")
		   target_samplerate = Get sampling frequency
		   target_numchannels = Get number of channels
		   target_duration = Get total duration
		 if target_numchannels = 2
	 		  select Sound 'target$'
	  		  Convert to mono
   			  target$ = selected$ ("Sound")
			  target_samplerate = Get sampling frequency
			  target_numchannels = Get number of channels
			  target_duration = Get total duration
                  endif
		else
		   select Sound 'source$'
		   Copy... Original_B_token
		   target$ = selected$ ("Sound")
		   target_samplerate = Get sampling frequency
		   target_numchannels = Get number of channels
		   target_duration = Get total duration
		 if target_numchannels = 2
	 		  select Sound 'target$'
	  		  Convert to mono
   			  target$ = selected$ ("Sound")
			  target_samplerate = Get sampling frequency
			  target_numchannels = Get number of channels
			  target_duration = Get total duration
			 target_seg
                  endif
	endif
if write_targets_to_directory=1
select Sound 'source$'
Save as WAV file... 'dir$'Originals/Original_A_token.wav
select Sound 'target$'
Save as WAV file... 'dir$'Originals/Original_B_token.wav
endif
endproc

##Identification of target segments, preceding context, following context
procedure segmentAndExtract
###First get the target vowels
	select Sound 'source$'
	View & Edit
	editor Sound 'source$'
	pause Select target segment in source token
	Move start of selection to nearest zero crossing
	Move end of selection to nearest zero crossing
	source_seg_start_time = Get start of selection
	source_seg_end_time = Get end of selection
	source_seg_duration = Get selection length
	Extract selected sound (time from 0)
	Close
	Rename: "Original A token"
	source_segment$ = selected$("Sound")
	endeditor
		if which_b = 1
			select Sound 'target$'
			View & Edit
			editor Sound 'target$'
			pause Select target segment in target token
			Move start of selection to nearest zero crossing
			Move end of selection to nearest zero crossing
			target_seg_start_time = Get start of selection
			target_seg_end_time = Get end of selection
			target_seg_duration = Get selection length
			Extract selected sound (time from 0)
			Close
			Rename: "Original B token"
			target_segment$ = selected$("Sound")
			endeditor
		else
			select Sound 'source_segment$'
			Copy... Copy of source token
			target_segment$ = selected$("Sound")
			target_seg_start_time = 0
			target_seg_end_time = 0
			target_seg_duration = Get total duration
		endif
###Now prompt user for preceding and following context for synthesis
####Preceding
beginPause ("Choose source of preceding context")
	comment ("How would you like to generate the preceding context?")
    choice ("preceding_source", 1)
       option ("From token A (source)")
       option ("From token B (target)")     
       option ("Generate silence:")    
		positive ("duration_of_silence","0.05")
     endPause ("Cancel", "OK", 2)
if preceding_source = 1
	select Sound 'source$'
	View & Edit
	editor Sound 'source$'
	pause Select preceding segment in source token
	Move start of selection to nearest zero crossing
	Move end of selection to nearest zero crossing
	pre_seg_start_time = Get start of selection
	pre_seg_end_time = Get end of selection
	pre_seg_duration = Get selection length
	Extract selected sound (time from 0)
	Close
	Rename: "preceding_context"
	endeditor
endif
if preceding_source = 2
	select Sound 'target$'
	View & Edit
	editor Sound 'target$'
	pause Select preceding segment in source token
	Move start of selection to nearest zero crossing
	Move end of selection to nearest zero crossing
	pre_seg_start_time = Get start of selection
	pre_seg_end_time = Get end of selection
	pre_seg_duration = Get selection length
	Extract selected sound (time from 0)
	Close
	Rename: "preceding_context"
	endeditor
endif
if preceding_source = 3
	Create Sound from formula: "preceding_context", 1, 'duration_of_silence', 1, 'source_samplerate' , "0"
		pre_seg_start_time = 0
	pre_seg_end_time = 0
	pre_seg_duration = Get total duration
endif
preceding_segment$ = selected$("Sound")
####Following
beginPause ("Choose source of following context")
	comment ("How would you like to generate the following context?")
    choice ("following_source", 1)
       option ("From token A (source)")
       option ("From token B (target)")     
       option ("Generate silence:")    
		positive ("duration_of_silence","0.05")
     endPause ("Cancel", "OK", 2)
if following_source = 1
	select Sound 'source$'
	View & Edit
	editor Sound 'source$'
	pause Select following segment in source token
	Move start of selection to nearest zero crossing
	Move end of selection to nearest zero crossing
	fol_seg_start_time = Get start of selection
	fol_seg_end_time = Get end of selection
	fol_seg_duration = Get selection length
	Extract selected sound (time from 0)
	Close
	Rename: "following_context"
	endeditor
endif
if following_source = 2
	select Sound 'target$'
	View & Edit
	editor Sound 'target$'
	pause Select following segment in source token
	Move start of selection to nearest zero crossing
	Move end of selection to nearest zero crossing
	fol_seg_start_time = Get start of selection
	fol_seg_end_time = Get end of selection
	fol_seg_duration = Get selection length
	Extract selected sound (time from 0)
	Close
	Rename: "following_context"
	endeditor
endif
if following_source = 3
	Create Sound from formula: "following_context", 1, 'duration_of_silence', 1, 'source_samplerate', "0"
	fol_seg_start_time = 0
	fol_seg_end_time = 0
	fol_seg_duration = Get total duration
endif
following_segment$ = selected$("Sound")
if write_targets_to_directory=1
select Sound 'following_segment$'
Save as WAV file... 'dir$'Originals/Following_segment.wav
select Sound 'preceding_segment$'
Save as WAV file... 'dir$'Originals/Preceding_segment.wav
select Sound 'source$'
Save as WAV file... 'dir$'Originals/Source_segment.wav
select Sound 'target_segment$'
Save as WAV file... 'dir$'Originals/Target_segment.wav
appendFileLine: dir$+"log.txt", "Source segment start:", source_seg_start_time
appendFileLine: dir$+"log.txt", "Source segment end:", source_seg_end_time
appendFileLine: dir$+"log.txt", "Source segment duration:", source_seg_duration
appendFileLine: dir$+"log.txt", "Target segment start:", target_seg_start_time
appendFileLine: dir$+"log.txt", "Target segment end:", target_seg_end_time
appendFileLine: dir$+"log.txt", "Target segment duration:", target_seg_duration
appendFileLine: dir$+"log.txt", "Preceding context source:", preceding_source
appendFileLine: dir$+"log.txt", "Following context source:", following_source
appendFileLine: dir$+"log.txt", "Preceding context start:", pre_seg_start_time
appendFileLine: dir$+"log.txt", "Preceding context end:", pre_seg_end_time
appendFileLine: dir$+"log.txt", "Preceding context duration:", pre_seg_duration
appendFileLine: dir$+"log.txt", "Following context start:", fol_seg_start_time
appendFileLine: dir$+"log.txt", "Following context end:", fol_seg_end_time
appendFileLine: dir$+"log.txt", "Following context duration:", fol_seg_duration
endif
select Sound _Pitch_manipulated_A_token_
Remove
endproc

##Formantgrid creation and modification
procedure newFilter .sound$ nformants maxf winLen .name$
	select Sound '.sound$'
	To Formant (burg)... 0 nformants maxf winLen 50
	current$=selected$("Formant")
	minf=Get minimum number of formants
	Track... minf ref1 ref2 ref3 ref4 ref5 1 1 1
	new$=selected$("Formant")
	Down to FormantGrid
	Rename... '.name$'
	select Formant 'current$'
	Remove
endproc

#Duration morphing 
##Get duration for each end of the continuum
##Interpolate, then work out the continuum steps
##Lengthen the sounds

procedure morphDuration .first_step$ .target_dur .nsteps .minpitch .maxpitch
if morph_duration =1	
select Sound '.first_step$'
	first_length=Get total duration
	morphing_distance = .target_dur-first_length
	morphing_amount = morphing_distance/(.nsteps-1)
		for step from 1 to .nsteps
			target_length = first_length+(morphing_amount*(step-1))
			this_factor = target_length/first_length
			select Sound stimulus_step_'step'
			current$=selected$("Sound")
			Lengthen (overlap-add)... .minpitch .maxpitch this_factor
			new$=selected$("Sound")
			select Sound 'current$'
			Remove
			select Sound 'new$'
			Rename... stimulus_step_'step'
			if write_targets_to_directory=1
				appendFileLine: dir$+"log.txt", "Duration token ",step," ",target_length
			endif
		endfor
endif
endproc
#Filter FormantGrid
procedure makeStimulus .source$ .filter$ .name$ .int
	select Sound '.source$'
	plus FormantGrid '.filter$'
	Filter
###Pre-emphasis filter to restore lip radiation effect
	Filter (pre-emphasis)... 0
	current$=selected$("Sound")
###LP filter
call HPfilter 'current$' filter_cutoff filter_crossover
###Delete original
select Sound 'current$'
plus IntensityTier 'current$'_LF_portion_intensity
Remove
###Restore HF energy
call addHF 'current$'_LF_portion 'current$'_HP_portion
Scale intensity... '.int'
Rename... '.name$'
call matchInt '.name$' 'source_segment$' 0
if write_targets_to_directory=1
select FormantGrid '.filter$'
To Formant... 0.01 0.1
thisform$=selected$("Formant")
Down to Table... yes yes 6 no 3 yes 3 yes
thistable$=selected$("Table")
Save as comma-separated file... 'dir$'Measurements/'.filter$'.csv
select Sound '.name$'
Save as WAV file... 'dir$'Stimuli/'.name$'_vowel.wav
select Table 'thistable$'
plus Formant 'thisform$'
Remove
endif
endproc

##Source-filter resynthesis
###Set formant and bandwidth values
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
###Pre-emphasis filter to restore lip radiation effect
	Filter (pre-emphasis)... 100
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


##
procedure setBandWidths .grid$ .formant .mean
call predictBand .formant .mean
	select FormantGrid '.grid$'
		if .formant =1
			Add bandwidth point... 1 0.5 predictBand.value
		endif
		if .formant =2
			Add bandwidth point... 2 0.5 predictBand.value
		endif
		if .formant =3
			Add bandwidth point... 3 0.5 predictBand.value
		endif
		if .formant=4
			Add bandwidth point... 4 0.5 predictBand.value
		endif
		if .formant=5
			Add bandwidth point... 5 0.5 predictBand.value
		endif
endproc

##HF component restoration 
procedure addHF .sound$ .filteredsound$
	select Sound '.sound$'
	Formula... self [col] + Sound_Original_A_token_HP_portion [col]
endproc

##Concatenate 
procedure concatenate .cross .nsteps
		for i from 1 to .nsteps
			select Sound 'preceding_segment$'
			plus Sound stimulus_step_'i'
			Concatenate with overlap... '.cross'
			temp_chain$=selected$("Sound")
			select Sound 'following_segment$'
			Copy... following_segment_temp
			select Sound 'temp_chain$'
			plus Sound following_segment_temp
			Concatenate with overlap... '.cross'
			Rename... stimulus_item_'i'
			current$=selected$("Sound")
				if write_targets_to_directory=1
					Save as WAV file... 'dir$'Stimuli/Stimulus_item_'i'.wav
				endif
			select Sound 'temp_chain$'
			plus Sound following_segment_temp
			Remove
		endfor
		select Sound stimulus_item_1
		for i from 2 to .nsteps
		plus Sound stimulus_item_'i'
		endfor
		Concatenate recoverably
		select Sound chain
		Rename... Synthesized continuum
		cont$=selected$("Sound")
		select TextGrid chain
		Rename... Synthesized continuum
		cont_grid$=selected$("TextGrid")
		if write_targets_to_directory=1
			select Sound 'cont$'
			Save as WAV file... 'dir$'Stimuli/Continuum.wav
			select TextGrid 'cont_grid$'
			Save as text file... 'dir$'Stimuli/Continuum.TextGrid
		endif
		select Sound Synthesized_continuum
		plus TextGrid Synthesized_continuum
		View & Edit
endproc
##Pitch extraction, checking, and matching
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

##Intensity extraction, checking, and matching
procedure matchInt .target$ .source$ pause
###First, get the intensity of the source
	select Sound '.source$'
	intensity=Get intensity (dB)
	To Intensity... 100 0 yes
	Down to IntensityTier
	target_intensity$=selected$("IntensityTier")
###Now we do the same trick as inverse filtering in the spectral domain
###But this time we will do it in the time/intensity domain
	select Sound '.target$'
	To Intensity... 100 0 yes
	mean = Get mean... 0 0 dB
	Down to IntensityTier
	intensity_to_change$=selected$("IntensityTier")
###Sutract original from mean to make an inverse model
	select IntensityTier 'intensity_to_change$'
	Copy... inverse_intensity
	Formula... -(self-mean)
###Combine to produce a neutralized intensity contour
select Sound '.target$'
	plus IntensityTier inverse_intensity
	Multiply... no
	Rename... '.target$'_neutralized
	select Sound '.target$'
	Remove
###Check with user if pause is set to 1
	if pause = 1
		select IntensityTier 'target_intensity$'
		View & Edit
		editor IntensityTier 'target_intensity$'
		pause Check intensity and modify if necessary
		Close
		endeditor
	endif
###Combine with source intensity
	select IntensityTier 'target_intensity$'
	plus Sound '.target$'_neutralized
	Multiply... no
	Scale intensity... 'intensity'
	Rename... '.target$'
	select IntensityTier inverse_intensity
	plus IntensityTier 'target_intensity$'
	plus Intensity 'target_intensity$'
	plus Sound '.target$'_neutralized
	plus Intensity '.source$'
	plus IntensityTier '.source$'
	Remove
endproc

##Bandwidth estimation from formant value
procedure predictBand .formantname .freq
	if bandwidth_estimation$ = "Hawks and Miller 1995"
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

###Draw waveform
procedure drawSound .sound$ max min .x1 .x2 .y1 .y2
select Sound '.sound$'
demo Font size... 10
demo Select inner viewport: .x1, .x2, .y1, .y2
demo Draw... 0 0 max min yes Curve
endproc
###Draw spectrogram from sound
procedure drawSpec .sound$ max min .x1 .x2 .y1 .y2
select Sound '.sound$'
To Spectrogram... 0.005 5000 0.002 20 Gaussian
demo Font size... 10
demo Select inner viewport: .x1, .x2, .y1, .y2
demo Paint... 0 0 0 0 100 yes 50 6 0 yes
select Spectrogram '.sound$'
Remove
endproc
###Clean up
procedure cleanUp
if clean_up =1
for i from 1 to minf
select Matrix source_f'i'
plus Matrix target_f'i'
plus Matrix f_'i'_distances
Remove
endfor

for i from 1 to nsteps
select FormantGrid grid_step_'i'
plus Intensity stimulus_step_'i'
plus IntensityTier stimulus_step_'i'
Remove
endfor
select Sound Original_A_token
plus Sound Original_B_token
plus Sound preceding_context
plus Sound following_context
if which_b=1
plus Manipulation Original_B_token
plus Sound Original_B_token_duration_matched
plus Formant Original_B_token_duration_matched
endif
if which_b=2
plus Sound Copy_of_source_token
plus Formant Copy_of_source_token
endif
plus Sound Original_A_token_LF_portion
plus IntensityTier Original_A_token_LF_portion_intensity
plus Sound Original_A_token_HP_portion
plus Sound Original_A_token_10000
plus Sound Original_A_token_10000
plus Sound whitened_source
plus Formant Original_A_token
plus FormantGrid A_token
plus FormantGrid Clean
plus Formant clean_grid
plus Sound preceding_context
plus Sound following_context
plus Sound lip_rad
if liprad=1
plus Sound Hg2_norad
plus Sound HG2_est
endif
plus Sound G
plus Formant Original_A_token
	Remove
for i from 1 to nsteps
	select Sound stimulus_step_'i'
	Remove
endfor
items=12+nsteps
for i from 1 to items
	select Sound whitened_source_filt
	Remove
endif
endproc

###############################
#Praat routine for Iterative Adaptive Inverse Filtering
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

procedure setVars
liprad=simulate_lip_radiation
morph_duration = modify_duration
bandwidth_estimation$ = bandwidth_estimation$
speaker_sex$ = speaker_sex$
clean_up = clean_up
modify_f1 = modify_f1
modify_f2 = modify_f2
modify_f3 = modify_f3
modify_f4 = modify_f4
modify_f5 = modify_f5
demo_mode=0
ref1 =reference_f1
ref2 =reference_f2
ref3 =reference_f3
ref4 =reference_f4
ref5 =reference_f5
filter_cutoff=filter_cutoff
filter_crossover=filter_crossover
cat_overlap=crossfade_overlap
nsteps=number_of_steps
if bandwidth_estimation$="Hawks and Miller 1995"
low_k=165.327516
	Create Polynomial: "low_x", 1, 5, "-0.673636734000000015 0.001808744460000000 -0.000004522016820000 0.000000007495140000 -0.000000000004702192  "
	high_k=15.8146139
	Create Polynomial: "high_x", 1, 5, "0.0810159009000000068790 -0.0000979728215000000004 0.0000000528725064000000 -0.0000000000107099264000 0.0000000000000007915285  "
endif
if write_targets_to_directory=1
	createDirectory: dir$
	createDirectory: dir$+"/Stimuli"
	createDirectory: dir$+"/Measurements"
	createDirectory: dir$+"/Originals"
	deleteFile:dir$+"log.txt"
	date$ = date$ ()
	appendFileLine: dir$+"log.txt", "Date:", date$
	appendFileLine: dir$+"log.txt", "Morph duration:", morph_duration
	appendFileLine: dir$+"log.txt", "Modify F1:", modify_f1
	appendFileLine: dir$+"log.txt", "Modify F2:", modify_f2
	appendFileLine: dir$+"log.txt", "Modify F3:", modify_f3
	appendFileLine: dir$+"log.txt", "Modify F4:", modify_f4
	appendFileLine: dir$+"log.txt", "Modify F5:", modify_f5
	appendFileLine: dir$+"log.txt", "Simulate lip radition:",liprad
	appendFileLine: dir$+"log.txt", "Bandwidth estimation:",bandwidth_estimation$
	appendFileLine: dir$+"log.txt", "Speaker sex:",speaker_sex$
	appendFileLine: dir$+"log.txt", "Interpolation method:",interpolation_method$
	appendFileLine: dir$+"log.txt", "Reference F1:",ref1
	appendFileLine: dir$+"log.txt", "Reference F1:",ref2
	appendFileLine: dir$+"log.txt", "Reference F1:",ref3
	appendFileLine: dir$+"log.txt", "Reference F1:",ref4
	appendFileLine: dir$+"log.txt", "Reference F1:",ref5
	appendFileLine: dir$+"log.txt", "Filter cutoff:",filter_cutoff
	appendFileLine: dir$+"log.txt", "Filter crossover:",filter_crossover
	appendFileLine: dir$+"log.txt", "Number of steps:",nsteps
	appendFileLine: dir$+"log.txt", "Crossfade overlap:",cat_overlap
endif
endproc

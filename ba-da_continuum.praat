########################################################################
#Creating a ba-da continuum in Praat.
#This script simulates the glottal source using a 'PointProcess' object.
#It then creates a set of FormantTier objects, which represent the 
#vocal tract transfer function. 
#Each FormatTier has a slightly raised F2 and F3 at the onset, 
#giving the impression of a transition from a coronal stop.
#Based on methods described in 
#Blomert, L., & Mitterer, H. (2004). 
#The fragile nature of the speech-perception deficit in dyslexia: 
#Natural vs. synthetic speech. Brain and Language, 89(1), 21-26.
########################################################################
#Steady-state formant values
f1 = 750
b1 = 100
f2 =  1200
b2 = 150
f3 = 2350
b3 = 200
f4 = 3300
b4 = 300
f5 = 4000
b5 = 500
########################################################################
#Onset formant values (endpoints)
f1bd = 300
f2b = 1000
f2d = 1800
f3b = 2150
f3d = 2600
########################################################################
#Generating the source representation
Create PitchTier: "f0", 0.00, 0.25
Add point: 0.00, 150
Add point: 0.25, 100
To PointProcess
Remove points between: 0.00, 0.05
Remove points between: 0.20, 0.25
fzero=To Sound (phonation): 44100, 0.6, 0.05, 0.7, 0.03, 3.0, 4.0
########################################################################
#Modelling the stop closure using an indensity tier
Create IntensityTier: "intens", 0.00, 0.25
Add point: 0.025, 40
Add point: 0.05, 100
########################################################################
#Generate the glottal source signal
plusObject: fzero
Multiply
Rename: "source"
########################################################################
#Generate tokens iteratively, interpolating between the onset F2 values at every step
for i from 0 to 6
	#calculate onset values for f2 and f3
        for f from 2 to 3
           	f'f'Onset = (6-i)/6 * f'f'b+ i/6 * f'f'd
        endfor
	temp=Create FormantTier... bda'i' 0 0.25        
	Add point... 0.025 'f1bd' 'b1' 'f2Onset' 'b2' 'f3Onset' 'b3' 'f4' 'b4' 'f5' 'b5'
	Add point... 0.075 'f1' 'b1' 'f2' 'b2' 'f3' 'b3' 'f4' 'b4' 'f5' 'b5'
    plus Sound source
	Filter
    Rename...  bda'i'
	removeObject: temp
endfor     
########################################################################
#Concatenate the tokens for ease of listening/viewing
select Sound bda1
for i from 0 to 6
	plus Sound bda'i'
endfor
Concatenate recoverably
View & Edit
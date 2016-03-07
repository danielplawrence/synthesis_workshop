########################################################################
#A simple demonstration of source-filter synthesis in Praat
#This script simulates the glottal source using a 'PointProcess' object.
#It then creates a FormantGrid object, which represents the vocal tract
#transfer function as a function of time. Filtering these two together allows
#us to synthesize a vowel.
########################################################################
#Creating the source
pitchTier = Create PitchTier: "source", 0, 0.5
Add point: 0.0, 150
Add point: 0.5, 100
pulses = To PointProcess
source = To Sound (phonation): 44100, 0.6, 0.05, 0.7, 0.03, 3.0, 4.0
removeObject: pitchTier, pulses
selectObject: source
View & Edit
pauseScript: "Source generated "
########################################################################
#Creating a filter
filter=Create FormantGrid: "filter", 0, 0.5, 10, 550, 1100, 60, 50
Remove formant points between: 1, 0, 0.5
Add formant point: 1, 0.00, 350
Add formant point: 1, 0.05, 700
Remove formant points between: 2, 0, 0.5
Add formant point: 2, 0.00, 700
Add formant point: 2, 0.05, 1100	
selectObject: filter
View & Edit
pauseScript: "Filter generated "
########################################################################
#Synthesizing a vowel
selectObject: source,filter
vowel=Filter
selectObject: vowel
View & Edit
pauseScript: "Vowel generated "


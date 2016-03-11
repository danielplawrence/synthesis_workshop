#Example of basic LPC-inverse filtering in Praat
#First we resample and estimate the LPC filter:
Resample: 10000, 50
sound$=selected$("Sound")
To LPC (burg): 10, 0.025, 0.005, 50

#Subtracting the LPC filter from the original signal
#gives us the LPC residual -- an estimation of the glottal flow derivative
select Sound 'sound$'
plus LPC 'sound$'
Filter (inverse)
source$=selected$("Sound")

#Now we create and modify a formant object -- adding 400Hz to F2
select LPC 'sound$'
To Formant
Formula (frequencies): "if row = 2 then self + 400 else self fi"

#Exciting the modified filter with the LPC residual gives us a resynthesized vowel
select Sound 'source$'
plus Formant 'sound$'
Filter
Play

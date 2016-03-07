########################################################################
#Using Praat's built-in Klatt synthesizer.
########################################################################

########################################################################
#A vowel
Create KlattGrid... kg 0 0.3 6 1 1 6 1 1 1  
Add pitch point... 0.1 150
Add pitch point... 0.3 100
Add voicing amplitude poin	t... 0.1 90

Add oral formant frequency point... 1 0.1 800
Add oral formant bandwidth point... 1 0.1 50
Add oral formant frequency point... 2 0.1 1200
Add oral formant bandwidth point... 2 0.1 50
Add oral formant frequency point... 3 0.1 3500
Add oral formant bandwidth point... 3 0.1 50
Add oral formant frequency point... 1 0.3 300
Add oral formant frequency point... 1 0.3 600

To Sound
########################################################################
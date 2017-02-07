# AudioAnalyser
Audio Analysis for iOS

This application is purely code experiment in using Core Audio and building a working real-time FFT analysis of input audio signal.

Current stage: 
- Integrated with Core Audio and tested with the built-in microphone on iPhone. 
- Oscilloscope view showing sample of the input data
- Spectrum analyser with FFT and Hanning windowing. Not much tested but appears to be working.
- A signal generation function that replaces the microphone input, feeding sinusoidal signal directly to the views for testing.

Things to do:
- Research alternative to the Audio Session that allows better integration of the signal generator. This way we can have it replace the input and also output it to the speakers.
- Add support for multi-channel audio, different bit rates and sample rates - currently I assume 16bit, 44100, 1024 samples buffer sizes, single channel everywhere
- Improve the FFT binning - at the moment the spectrum is analysed at 1000 points spread 20Hz appart. This should be improved
- Figure out how to convert the data from the FFT to actual dB levels to present to the user. At the moment I have no clue what units I am working with and all the drawing of the data is configured to match my testing scenarios
- Add some GUI with standard controls

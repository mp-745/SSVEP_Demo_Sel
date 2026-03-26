# SSVEP Stimulus Frequency Change: 14/18 Hz → 15/20 Hz

## Background

The original SSVEP system (developed by Dhruv) used stimulus frequencies of **14 Hz** (left/rotate) and **18 Hz** (right/select). These frequencies were chosen somewhat arbitrarily as a reasonable pair within the SSVEP-responsive range, with enough separation for the FFT-based classifier to distinguish them.

## The Problem: Refresh Rate Mismatch

During live testing, we discovered that the chosen stimulus frequencies were **not evenly divisible by the display's refresh rate**. This is a critical issue for SSVEP systems.

For a visual flicker to produce a clean, stable frequency in the brain's evoked response, the on/off timing of each frame must be consistent. When the stimulus frequency does not divide evenly into the monitor's refresh rate, the actual flicker becomes irregular — some cycles are slightly longer or shorter than others, depending on which frames land on the on/off transitions. This temporal jitter smears the evoked response across neighbouring frequencies in the EEG spectrum, reducing the signal-to-noise ratio at the target frequency and making classification harder.

For example, on a 60 Hz display:

- **14 Hz** requires 60/14 ≈ 4.29 frames per cycle — not an integer, so the flicker pattern is uneven
- **18 Hz** requires 60/18 ≈ 3.33 frames per cycle — also not an integer

In contrast:

- **15 Hz** requires 60/15 = **4 frames per cycle** (2 on, 2 off) — perfectly even
- **20 Hz** requires 60/20 = **3 frames per cycle** (1.5 on, 1.5 off, or a 2-1 pattern) — clean division

## The Fix

We switched the stimulus frequencies to **15 Hz** and **20 Hz**, which are both integer divisors of 60 Hz. This ensures that every flicker cycle has exactly the same duration, producing a spectrally clean SSVEP response at the target frequency.

## Result

After switching to refresh-rate-aligned frequencies, decoding accuracy improved noticeably — even though the SVM was initially trained on data collected at 14/18 Hz. The cleaner spectral peaks at 15 Hz and 20 Hz gave the classifier more reliable features to work with than the smeared peaks at 14 Hz and 18 Hz.

The training data and all code references have since been updated to use 15/20 Hz throughout.

## Lesson Learned

When designing an SSVEP BCI, stimulus frequencies should always be chosen as integer divisors (or near-integer divisors) of the display's refresh rate. Common refresh-rate-compatible frequency pairs on a 60 Hz display include: 10/12 Hz, 10/15 Hz, 12/15 Hz, 15/20 Hz, and 12/20 Hz. If using a higher refresh rate display (e.g. 120 Hz, 144 Hz), additional frequencies become available.

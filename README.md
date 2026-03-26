# SSVEP_Demo_Sel — SSVEP Brain-Computer Interface System

A real-time BCI system that uses Steady-State Visual Evoked Potentials (SSVEPs) to let a user control on-screen elements by looking at flickering stimuli. Built for the **OpenBCI Cyton** and **Unicorn Hybrid Black** EEG headsets.

The system presents two flickering stimuli (15 Hz and 20 Hz), records EEG from occipital channels, classifies which stimulus the user is attending to via SVM, and uses the result to drive either a game or a knob interface.

---

## Quick Start

### Option A: Knob Demo — MATLAB Only (No Python, No Headset)

1. In MATLAB, `cd` to the Presentation folder and run `BCI_main`:
   ```matlab
   cd('C:\SSVEP_Demo_Sel\openBCI_game\Presentation')
   BCI_main
   ```
2. By default, `MODE = 'csv'` — the system trains an SVM on two CSV files, launches the Psychtoolbox knob display, and plays back a CSV recording as if it were a live EEG stream. No Python, no LSL, no headset required.
3. If the training CSV files are not found on disk, the script automatically generates synthetic SSVEP data (15 Hz and 20 Hz, 30 seconds each) via `generateSyntheticSSVEP.m` and saves them to `Processing/SampleData/`. No manual setup needed.
4. To change which CSV file is played back during the demo, edit the `csvTestFile` variable in `BCI_main.m`.

### Option B: Knob Demo — Live EEG (Requires Headset + Python or Unicorn Recorder)

1. Connect a Unicorn Hybrid Black headset.
2. Start the LSL stream: run `openBCI_EEG_stream/unicorn_lsl_streamer.py` in Python, **or** use Unicorn Recorder's built-in LSL output.
3. In `BCI_main.m`, change `MODE = 'lsl'`.
4. Run `BCI_main.m` — it trains the SVM, launches the display, and connects to the live EEG stream for real-time classification.

### Option C: Game Pipeline (Requires Headset + Python or Unicorn Recorder)

1. Connect headset and start the LSL stream (Python or Unicorn Recorder).
2. In one MATLAB instance, run `openBCI_game/Processing/run_stream_test.m` (acquires EEG, trains classifier, writes feedback to shared files).
3. In a second MATLAB instance, run one of the game demos in `openBCI_game/Presentation/` (e.g. `demo_v1.m`).
4. Go through the calibration block first, then play the game — your gaze drives the ship left or right.

### Option D: Offline Analysis Only (No Python, No Headset)

1. Run `openBCI_game/Processing/SSVEP_train_test.m` to train and test the SVM on existing CSV recordings.
2. Use the visualizer scripts to inspect data (see Processing section below).

---

## Project Structure

```
SSVEP_Demo_Sel/
├── README.md                        ← You are here
├── OpenBCI System Usage.pptx        ← Setup guide for the OpenBCI hardware
├── openBCI_EEG_stream/              ← Python: EEG → LSL streaming
├── openBCI_game/
│   ├── Presentation/                ← MATLAB + Psychtoolbox: visual stimuli & game
│   ├── Processing/                  ← MATLAB: EEG acquisition, classification, offline analysis
│   ├── SharedFiles/                 ← Text files for inter-process communication
│   └── Libraries/                   ← Bundled dependencies (Psychtoolbox, liblsl-Matlab, EEG_Analyses_v3)
```

---

## openBCI_EEG_stream/ — Python LSL Streamers

These scripts read raw EEG from the headset and push it over Lab Streaming Layer (LSL) so MATLAB can receive it.

| File | What it does |
|---|---|
| `py_lslstreamer.py` | Streams 8-channel EEG at 250 Hz from an **OpenBCI Cyton** board (COM4) using `pyOpenBCI`. Stream name: `OpenBCIEEG`. |
| `unicorn_lsl_streamer.py` | Streams 8-channel EEG at 250 Hz from a **Unicorn Hybrid Black** using the Unicorn DLL via ctypes. Stream name: `UnicornEEG`. |

**Dependencies:** `pylsl`, `numpy`. For Cyton: `pyOpenBCI`. For Unicorn: Unicorn Suite SDK installed.

---

## openBCI_game/Presentation/ — Visual Stimulus & Game Display

Most scripts use Psychtoolbox (PTB) for timing-accurate visual presentation. `BCI_main.m` uses `SSVEP_Display_Fig.m` (standard MATLAB figures) as a fallback since PTB is currently not licensed on this machine — see Known Issues.

### Main Entry Points

| File | What it does |
|---|---|
| `BCI_main.m` | **Primary entry point for the knob demo.** Supports two modes: `MODE = 'csv'` (default) plays back a CSV file with no Python/LSL needed; `MODE = 'lsl'` connects to a live Unicorn EEG stream. Trains an SVM on two CSV files (15 Hz vs 20 Hz), launches the knob display via `SSVEP_Display_Fig()` (standard MATLAB figures, no PTB needed), then classifies via `realtimeEEGClassifier_CSV` or `realtimeEEGClassifier`. Classifier output: 0 = rotate knob, 1 = confirm selection. Uses channels [6, 7, 8], Fs = 250 Hz, 2.0 s FFT window, 0.25 s update interval. |
| `demo_v1.m` | **Game entry point (with OpenBCI).** Initializes PTB, grating stimuli, and game objects, then enters the block/trial state machine. EEG flag enabled. |
| `demo_v2.m` | **Game entry point (no EEG).** Same as demo_v1 but with EEG disabled — useful for testing the game visuals without a headset. |

### SSVEP Demos (Standalone)

| File | What it does |
|---|---|
| `SSVEP_demo.m` | Simplest demo. Displays a single flickering red circle at 5 Hz with sinusoidal intensity modulation. Good for verifying PTB timing. |
| `SSVEP_demo_2stim.m` | Two-stimulus demo. Prompts user for number of stimuli (1 or 2) and screen side (left/right). Flickers circles at configurable frequencies. Circle radius 200 px, offset 800 px. |
| `SSVEP_with_knob.m` | Standalone knob interface (no classifier). Displays a rotary knob with 8 labeled drum/beat options, surrounded by two flickering SSVEP circles (15 Hz left, 20 Hz right). Left stimulus rotates the pointer, right stimulus selects. |

### Display & Rendering

| File | What it does |
|---|---|
| `SSVEP_Display.m` | PTB rendering loop for the knob demo. Draws a "DRUMS" title, grey knob circle, rotating pointer line, 8 labeled ticks, and two flickering SSVEP circles. Reads knob state from figure `UserData` (set by the classifier). Exits on ESC. |
| `realtimeEEGClassifier.m` | **LSL mode only.** Connects to the `UnicornRecorderLSLStream` via LSL. Pulls EEG chunks into a rolling buffer, extracts FFT features in 4 frequency bands, runs the trained SVM, and applies a 3-consecutive-window stability check before calling the display update callback. Requires Python LSL streamer or Unicorn Recorder. |
| `realtimeEEGClassifier_CSV.m` | **CSV mode (no Python needed).** Drop-in replacement for `realtimeEEGClassifier.m` that reads from a pre-recorded Unicorn CSV file instead of an LSL stream. Same feature extraction, SVM classification, and 3-window stability logic. Simulates real-time pacing during playback. Used by default in `BCI_main.m`. |

### Game State Machine

| File | What it does |
|---|---|
| `BlockType.m` | Mode selection menu. Keys 1–4 choose: Calibration, Practice, Game, or Exit. Sets flags for neurofeedback, objects, and obstacles. Calibration runs 10 trials at 6 s each. Reads calibration accuracy from `acc_shared.txt`. |
| `GameMain.m` | Runs the trial loop for a given block type. Sends triggers (100 = calibration start, 200 = game start, 20 = trial start, 30 = trial stop, 253 = block stop) via `openbci_send_triggers.m`. |
| `TrialMain.m` | Per-frame rendering. Draws moving objects (yellow dots, 5 pts each), obstacles (red circles), enemy ships (magenta), player ship (white, 50x50 px), and SSVEP gratings in the bottom corners (15 Hz left, 20 Hz right). Reads the BCI feedback value (1 = left, 2 = right) from `ft_shared.txt` to move the ship. Handles collision detection and scoring. |
| `TrialInterrupt.m` | Checks for ESC key press each frame. Sets `breakLoop = true` to exit the current trial. |

### Initialization & Helpers

| File | What it does |
|---|---|
| `InitMain.m` | Sets SSVEP flicker frequencies (15 Hz left, 20 Hz right), disables PTB sync tests, sets trial duration to 10 s. |
| `StimuliInit.m` | Opens a fullscreen PTB window on the last monitor. Computes screen center, refresh rate, flip interval, priority level. Defines color constants (black, white, gray, yellow). |
| `InitPresentationPaths.m` | Defines directory paths for the game folder and shared file locations (feedback file, accuracy file). Hardcoded to `C:\SSVEP_Demo_Sel\openBCI_game`. |
| `InitPPort.m` | Initializes a serial port connection (COM4, 115200 baud) for parallel-port-style EEG triggers. |
| `Stimuli_game.m` | Creates all game objects: 30 collectible yellow dots, 4 red obstacles (100 px), 1 magenta enemy ship (50 px), 1 white player ship (50 px, speed 4 px/frame). Positions objects across 2 screen heights for scrolling. |
| `Stimuli_grating.m` | Positions the two SSVEP stimulus circles (100 px radius) in the bottom-left and bottom-right corners with 25 px margins. Also defines the score display polygon (170x50 px, centered). |

### Trigger Scripts

| File | What it does |
|---|---|
| `cog_send_triggers.m` | Maps named trigger strings to numeric values for the parallel port. Supports: `pause_off` (254), `pause_on` (253), `fixation_leftCue` (11), `fixation_rightCue` (12), `trialstart` (20), `Cue` (25), `trialstop` (30), `response` (40), `reset` (0), and more. Also accepts raw numeric values. |
| `openbci_send_triggers.m` | Writes a trigger value to `SharedFiles/openbci_trig_values.txt` so the processing script can read it. Input: `val` (trigger code), `flag` (enable/disable). |

### Shared Text Files (in Presentation/)

| File | What it does |
|---|---|
| `acc_shared.txt` | Calibration accuracy (a decimal 0–1). Written by the processing module after training, read by `BlockType.m` to display accuracy. |
| `ft_shared.txt` | Real-time feedback value. Written by the processing module (1 = left/15 Hz, 2 = right/20 Hz), read by `TrialMain.m` to steer the player ship. |

---

## openBCI_game/Processing/ — EEG Acquisition, Classification & Offline Analysis

### Main Real-Time Scripts

| File | What it does |
|---|---|
| `run_stream_test.m` | **Primary real-time acquisition loop for the game.** Resolves `UnicornRecorderDataLSLStream` via LSL. Reads triggers from `openbci_trig_values.txt`. During calibration blocks: stores 3 s EEG windows per trial (discards first 1 s), then trains SVM/LDA/Decision Tree classifiers on SSVEP power features. During game blocks: classifies each window in real time and writes the decision (1 or 2) to `ft_shared.txt`. Saves all data to a timestamped `.mat` file. |
| `unicorn_runstream_main.m` | Enhanced variant of `run_stream_test.m` for the Unicorn headset. Uses UDP socket (port 1000) for trigger input instead of file-based triggers. Focuses on electrodes [6, 7, 8] (occipital). |
| `realtimeDecisionDemo.m` | Offline simulation of the real-time pipeline. Reads a CSV file, classifies sliding windows with a trained SVM, applies a 3-window stability check, and fires a callback on stable decisions. Good for testing the classifier on recorded data without a live stream. |

### Training & Testing

| File | What it does |
|---|---|
| `trainSSVEP_SVM.m` | Trains a linear SVM (`fitcsvm`, standardized) on FFT features extracted from two CSV recordings — one recorded while attending 15 Hz, one while attending 20 Hz. Labels: 1 = 15 Hz, 2 = 20 Hz. Returns the trained `SVMModel`. |
| `extractFeaturesFromCSV.m` | Reads a Unicorn CSV file, selects channels, applies linear detrend + Hann window + FFT, then extracts mean power in narrow bands (±0.5 Hz) around each target frequency and its harmonics. Returns a feature matrix (one row per sliding window). |
| `SSVEP_train_test.m` | End-to-end offline pipeline. Loads two CSV training files (15 Hz and 20 Hz), trains the SVM via `trainSSVEP_SVM`, runs `offlineTestCSV` for offline validation, then runs `realtimeDecisionDemo` for simulated real-time testing. Parameters: Fs = 250 Hz, channels [6, 7, 8], nFFT = 500 (2 s window), step = 62 samples (0.25 s). |
| `offlineTestCSV.m` | Offline test function. Extracts features from a CSV, predicts each window with the SVM, takes the mode as the final decision, and prints the result (15 Hz or 20 Hz). |

### Signal Processing

| File | What it does |
|---|---|
| `RT_Preprocess.m` | Real-time EEG preprocessing. Applies `cog_filter`, optional demeaning, average rereferencing, and z-score normalization based on flags in `EEG_PARAMS`. |
| `RT_SSVEP_noDSS.m` | Extracts SSVEP power at target frequencies from a ring buffer using multitaper spectral estimation (`mtspectrumc`). Returns a 1x2 power array (15 Hz, 20 Hz). |
| `cog_filter.m` | Applies either a digital filter (using `filtfilt` if passed a filter object) or simple differencing (lag subtraction). |
| `RT_reset.m` | Resets all processing buffers to zeros for a new trial. Initializes `final_vec`, `iter_count`, `SSVEP_all`, `Classifier_out_all`. |
| `init_params.m` | Loads parameters from `PARAMS.mat` and initializes ring buffers and filter settings. |

### Visualization

| File | What it does |
|---|---|
| `unicorn_csv_data_visualizer.m` | Plays back a Unicorn CSV recording. Top plot: 5 s rolling time-domain trace (channels 6–8). Bottom plot: FFT magnitude spectrum (0–40 Hz). Updates every 0.3 s. |
| `unicorn_csv_data_visualizer_v2.m` | Enhanced version. Uses a 2.0 s Hann-windowed FFT (better frequency resolution) and 0.25 s update interval. |
| `unicorn_data_visualizer.m` | Live LSL stream visualizer. Resolves `UnicornRecorderLSLStream`, displays a rolling 5 s time trace and FFT spectrum (channels 6–8) updated every 1.0 s. Average rereferencing applied. |
| `PlotSSVEPPowers.m` | Plots averaged power spectra from training data for left (15 Hz) and right (20 Hz) conditions using multitaper spectral estimation. One figure per stimulus. |

### Data Generation

| File | What it does |
|---|---|
| `generateSyntheticSSVEP.m` | Generates synthetic SSVEP CSV files for demo/testing when real Unicorn Recorder data is not available. Creates two files (15 Hz and 20 Hz) with 8 channels of realistic EEG: pink noise + alpha rhythm on all channels, plus SSVEP fundamental and 2nd harmonic on occipital channels 6–8. Called automatically by `BCI_main.m` if training CSVs are missing. |

### Initialization & Testing

| File | What it does |
|---|---|
| `InitPath.m` | Sets the working directory and adds `EEG_Analyses_v3` and `liblsl-Matlab` to the MATLAB path. Defines paths for trigger, accuracy, and feedback shared files. |
| `InitSave.m` | Generates a timestamped filename for saving recorded data: `Recorded_Data(two_stim)_yyyy_mm_dd_hh_MM_ss_(freq1_freq2).mat`. |
| `srate_test.m` | LSL stream diagnostic. Resolves an EEG stream and pulls samples/chunks to verify streaming rate and data format. |
| `Game_test.m` | Interactive game block tester using PTB. Keyboard-driven state machine (S = start game, T = start trial, P = stop trial, ESC = stop block). Displays colored backgrounds to indicate state. |
| `AcquisitionInterrupt.m` | Key interrupt handler for acquisition loops. Checks for 'D' key press to set `breakLoop = true`. |
| `SSVEP_Display.m` | Processing-side copy of the PTB knob display (identical to Presentation/SSVEP_Display.m). |

---

## openBCI_game/SharedFiles/ — Inter-Process Communication

The presentation and processing MATLAB instances communicate through these text files:

| File | Written by | Read by | Contents |
|---|---|---|---|
| `openbci_trig_values.txt` | Presentation (`openbci_send_triggers.m`) | Processing (`run_stream_test.m`) | Current trigger code (e.g. 20 = trial start, 30 = trial stop, 100 = calibration, 253 = block stop) |
| `ft_shared.txt` | Processing (`run_stream_test.m`) | Presentation (`TrialMain.m`) | BCI feedback value: 1 = attend left (15 Hz), 2 = attend right (20 Hz) |
| `acc_shared.txt` | Processing (`run_stream_test.m`) | Presentation (`BlockType.m`) | Calibration accuracy as a decimal (0.0 – 1.0) |

---

## openBCI_game/Libraries/ — Bundled Dependencies

| Library | What it provides |
|---|---|
| `Psychtoolbox/` | Full Psychtoolbox-3 distribution. Handles timing-accurate screen drawing, keyboard input, audio, and hardware interfaces. |
| `liblsl-Matlab/` | MATLAB bindings for Lab Streaming Layer. Provides `lsl_loadlib`, `lsl_resolve_byprop`, `lsl_inlet` for receiving EEG streams. |
| `EEG_Analyses_v3/` | Custom EEG analysis toolbox. Modules: Core (data loading, epoching, preprocessing, FFT, CDF estimation), DSS (Denoising Source Separation), GPFA (Gaussian Process Factor Analysis), NoiseTools (artifact rejection, denoising), Initialization, Plotting, RT (real-time helpers), Util/SCADS. |

---

## Recorded Data

Located in `openBCI_game/Processing/Recorded_Data/`:

| Folder | Subject | Date | Sessions |
|---|---|---|---|
| `Shankhadeep_21022020/` | Shankhadeep | Feb 21, 2020 | 5 sessions at frequency pairs: (15,18), (15,18), (13,17), (13,18), (13,17) |
| `Swagatha_27022020/` | Swagatha | Feb 27, 2020 | 6 sessions at frequency pairs: (13,17), (13,17), (14,18), (14,18), (14,18), (14,18) |

Each `.mat` file contains the raw EEG, triggers, SSVEP power values, and classifier outputs from a two-stimulus session.

---

## Saved Models & Parameters

| File | Contents |
|---|---|
| `Processing/PARAMS.mat` | Default processing parameters (filter settings, buffer sizes, analysis config) |
| `Processing/SSVEP_SVM_Model.mat` | Pre-trained SVM classifier |
| `Processing/SVM_Out_1.mat` | Saved SVM output/results |
| `Processing/data.mat` | Saved experimental data |

---

## Key Parameters

| Parameter | Value | Where set |
|---|---|---|
| Sampling rate | 250 Hz | All scripts |
| EEG channels used | [6, 7, 8] (occipital) | `BCI_main.m`, `realtimeEEGClassifier.m`, visualizers |
| Left stimulus frequency | 15 Hz | `InitMain.m`, `SSVEP_with_knob.m` |
| Right stimulus frequency | 20 Hz | `InitMain.m`, `SSVEP_with_knob.m` |
| FFT window | 2.0 s (500 samples) | `BCI_main.m`, `SSVEP_train_test.m` |
| Classification step | 0.25 s (62 samples) | `BCI_main.m`, `SSVEP_train_test.m` |
| Stability check | 3 consecutive identical predictions required | `realtimeEEGClassifier.m`, `realtimeDecisionDemo.m` |
| Classifier | Linear SVM (standardized) | `trainSSVEP_SVM.m` |
| Feature bands | 13–17 Hz, 28–32 Hz (15 Hz + harmonic), 18–22 Hz, 38–42 Hz (20 Hz + harmonic) | `realtimeEEGClassifier.m`, `realtimeDecisionDemo.m` |

---

## Hardware Requirements

**For the knob demo in CSV mode (Option A) — minimal requirements:**
- MATLAB (with Statistics and Machine Learning Toolbox for `fitcsvm`)
- No Psychtoolbox, Python, or EEG headset needed

**For live EEG modes (Options B & C):**
- EEG headset: OpenBCI Cyton (8-channel, via COM4) or Unicorn Hybrid Black
- Python 3 with `pylsl` and `numpy`
- For Cyton: `pyOpenBCI` Python package
- For Unicorn: Unicorn Suite SDK installed

**For the game demos and PTB-based scripts:**
- Psychtoolbox-3 (licensed and working — see Known Issues below)
- A monitor with a known refresh rate

---

## Known Issues & Things to Fix

### Psychtoolbox Licensing

The `Screen` function in Psychtoolbox is currently **not licensed** on this machine. This means the following scripts will fail with `"This Psychtoolbox function is currently not licensed for use on this machine"`:

| Script | Status | Workaround |
|---|---|---|
| `Presentation/SSVEP_Display.m` | **Broken** — calls `InitMain` → `Screen()` | `BCI_main.m` now uses `SSVEP_Display_Fig.m` instead (standard MATLAB figures) |
| `Presentation/SSVEP_demo.m` | **Broken** — uses `Screen()` directly | Needs PTB license fix, or needs a MATLAB figure rewrite |
| `Presentation/SSVEP_demo_2stim.m` | **Broken** — uses `Screen()` directly | Needs PTB license fix, or needs a MATLAB figure rewrite |
| `Presentation/SSVEP_with_knob.m` | **Broken** — uses `Screen()` via `InitMain` | Needs PTB license fix, or needs a MATLAB figure rewrite |
| `Presentation/demo_v1.m` | **Broken** — full game, uses `Screen()` throughout | Needs PTB license fix |
| `Presentation/demo_v2.m` | **Broken** — full game, uses `Screen()` throughout | Needs PTB license fix |
| `Presentation/InitMain.m` | **Broken** — calls `Screen('Preference', ...)` on line 8 | Root cause for most of the above |
| `Presentation/StimuliInit.m` | **Broken** — calls `Screen('OpenWindow', ...)` | Root cause for most of the above |
| `Processing/Game_test.m` | **Broken** — uses `Screen()` for game block testing | Needs PTB license fix |

**What still works without Psychtoolbox:**
- `BCI_main.m` (uses `SSVEP_Display_Fig.m` — standard MATLAB figures with timer-based flicker)
- `Processing/SSVEP_Display.m` (uses standard MATLAB `figure` + `plot`)
- All CSV visualizers, training scripts, and offline analysis scripts
- `realtimeEEGClassifier_CSV.m` and `realtimeDecisionDemo.m`

**To fix:** Either resolve the Psychtoolbox license (reinstall PTB, run `PsychLinuxConfiguration` or `SetupPsychtoolbox`, check flavor), or rewrite the remaining PTB scripts to use standard MATLAB figures like `SSVEP_Display_Fig.m`.

### Missing Training CSV Files

The original Unicorn Recorder CSV training files (15 Hz and 20 Hz recordings from Dhruv's machine) are **not present** on this machine. The paths pointed to:

```
C:\Users\maxpo\OneDrive\Documents\gtec\Unicorn Suite\Hybrid Black\Unicorn Recorder\Sample data\14 Hz\UnicornRecorder_16_01_2026_16_24_340.csv
C:\Users\maxpo\OneDrive\Documents\gtec\Unicorn Suite\Hybrid Black\Unicorn Recorder\Sample data\18 Hz\UnicornRecorder_16_01_2026_16_27_410.csv
```

**Status:** `BCI_main.m` now auto-generates synthetic SSVEP data if these files are missing (saved to `Processing/SampleData/`). However, the following scripts still reference the old paths and will fail:

| Script | Fix needed |
|---|---|
| `Processing/SSVEP_train_test.m` | Update `file15`/`file20` paths, or add auto-generation like `BCI_main.m` |
| `Processing/SSVEP_Display.m` | Update the CSV path on line 65 |
| `Processing/unicorn_csv_data_visualizer.m` | Update `filename` on line 20 |
| `Processing/unicorn_csv_data_visualizer_v2.m` | Update `filename` on line 23 |

### trainSSVEP_SVM Argument Mismatch

The function `trainSSVEP_SVM(file15, file20, Fs, chSel, freqs, harms, nFFT, step, hannWin)` expects **9 arguments** including `freqs` (SSVEP target frequencies, e.g. `[15 20]`) and `harms` (harmonics, e.g. `[1 2]`). Some calling scripts were missing these two arguments. `BCI_main.m` has been fixed. Check that any other scripts calling `trainSSVEP_SVM` pass all 9 arguments.

### Game Pipeline Not Tested

The full game pipeline (`demo_v1.m` → `BlockType.m` → `GameMain.m` → `TrialMain.m` + `run_stream_test.m`) has not been tested on this machine. It requires both Psychtoolbox (currently broken) and a live LSL stream. This pipeline is non-functional until PTB licensing is resolved and a headset is connected.

### Flicker Timing Accuracy

`SSVEP_Display_Fig.m` uses a MATLAB timer at ~60 Hz to approximate the SSVEP flicker. This is **not as precise** as Psychtoolbox's frame-locked flipping. For actual BCI experiments where flicker timing matters (driving real SSVEP responses), Psychtoolbox should be fixed and used instead. The MATLAB figure version is suitable for demos and development only.

---

## Hardcoded Paths

All paths have been updated to the current machine (`C:\Users\maxpo\...`). If you move the project or switch machines, update these files:

| Script | What the path points to |
|---|---|
| `Presentation/BCI_main.m` | CSV training file locations (auto-generates if missing) |
| `Presentation/InitPresentationPaths.m` | Project root directory for shared files |
| `Presentation/openbci_send_triggers.m` | Trigger output file path |
| `Processing/InitPath.m` | Project root directory, library paths, shared file paths |
| `Processing/SSVEP_train_test.m` | CSV training file locations (still points to missing files) |
| `Processing/SSVEP_Display.m` | CSV file for offline demo playback (still points to missing files) |
| `Processing/unicorn_csv_data_visualizer.m` | CSV file for visualization (still points to missing files) |
| `Processing/unicorn_csv_data_visualizer_v2.m` | CSV file for visualization (still points to missing files) |
| `Libraries/EEG_Analyses_v3/RT/RT_init.m` | Feedback and accuracy shared file paths |
| `openBCI_EEG_stream/unicorn_lsl_streamer.py` | Unicorn Suite SDK DLL path |

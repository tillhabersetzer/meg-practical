# MEG Training Practical

This repository archives the materials for a Magnetoencephalography (MEG) training practical taught at the Carl von Ossietzky University of Oldenburg. It provides a complete framework for students, including the instruction manual, experimental presentation scripts and the data analysis pipeline.

The practical is designed to replicate key findings from the following study:
Rupp, André, et al. "The representation of peripheral neural activity in the middle-latency evoked field of primary auditory cortex in humans." Hearing research 174.1-2 (2002): 19-31.
https://doi.org/10.1016/S0378-5955(02)00614-7

## Repository Structure

The repository is organized as follows. Folders shown in brackets `[...]` are required to run the code locally but are excluded from this repository due to file size constraints.

```text
practical_meg/
├── 📂 analysis/        # MATLAB/FieldTrip scripts for analyzing the MEG data
├── 📂 experiments/     # Scripts to run the auditory stimulus presentation paradigms
├── [📂 fieldtrip/]     # Excluded: The FieldTrip toolbox (must be added manually)
├── [📂 rawdata/]       # Excluded: Recorded subject MEG datasets (e.g., .fif files)
└── 📄 experiment.pdf   # The main instruction manual and theoretical background
```

### Excluded Dependencies
To fully execute the analysis pipeline, you must download the [FieldTrip toolbox](https://www.fieldtriptoolbox.org/) and place your MEG recordings in a `rawdata` folder. Ensure both are placed in the root directory exactly as shown in the tree above.

## Experiments

Please read the `experiment.pdf` manual for comprehensive details regarding the experimental paradigm and analysis pipeline. A brief overview of the experimental setup is provided below.

This folder contains two experimental paradigms implemented as MATLAB Apps. Because these are auditory experiments, they require both [MATLAB](https://www.mathworks.com/) and an installed version of [SoundmexPro](https://www.soundmexpro.de/) for low-latency audio playback.

```text
experiments/
├── 📂 code/                    # Underlying MATLAB functions and settings scripts
├── 📱 hearing_threshold.mlapp  # MATLAB App: Adaptive hearing threshold measurement
└── 📱 practical_meg.mlapp      # MATLAB App: Main auditory MEG experiment
```

Pleae read the manual for more details regrading the experiment and analysis pipeline. Some descripotions will be provided here.

### Setup & Calibration

Before running the experiment, you must configure the hardware and calibration settings located in the `code` folder via the `generate_settings.m` script. Make sure to execute this script whenever a change is made in order to instantiate the new settings:

1. **Select the Soundcard Driver:** Update `Settings.Driver` to match your specific audio interface and select a suitable driver (e.g., `'ASIO Fireface USB'` for an RME Fireface UCX soundcard).
2. **Set System Calibration (Peak SPL):** Input the maximum peak SPL values measured for your specific hardware setup. This is a fixed value measured only once per hardware configuration:
   `Settings.Calibration.peakSPL.CalVal = [145.7471, 147.2471];`
   *(Note: The `hearing_threshold` app uses this to set its starting level to 85 Peak SPL).*
3. **Input Subject Thresholds:** After running the threshold measurement for a participant, insert their individual results (left/right) into the settings script. These values are shown in the `hearing_threshold` GUI and are also saved automatically afterwards. When the threshold is found, this final dB FS value corresponds to the subject's 0 dB Sensation Level (SL):
   `Settings.Calibration.CalVal = [101.7, 99.25];` 
   This ensures the stimuli in the main experiment will be presented accurately at 50 dB SL.

### During the Experiment

When conducting the experiment, the MEG recordings must be saved as `.fif` files, which is the standard format for the Elekta (MEGIN) Neuromag TRIUX system used in this setup. The `rawdata` folder must be organized according to the [BIDS (Brain Imaging Data Structure) format](https://bids.neuroimaging.io/). Please refer to the instruction manual for more detailed guidelines.

Each subject's data must be structured as follows:

```text
rawdata/
└── 📂 sub-XX/           # Subject-specific folder (replace XX with subject ID)
    ├── 📂 anat/         # Anatomical MRI scans required for source analysis
    ├── 📂 beh/          # Behavioral data (measured thresholds and optional audiograms)
    └── 📂 meg/          # The raw MEG recordings (.fif files)
```

### Analysis

The analysis pipeline for the MEG data is contained in the `analysis` folder. It performs the computation of middle-latency auditory evoked fields (MLAEFs) and subsequent dipole fitting using a two-dipole model. Please refer to the manual and the corresponding article for more detailed background.

Optionally, the raw files can be preprocessed using the [Maxwell filter in MNE-Python](https://mne.tools/stable/generated/mne.preprocessing.maxwell_filter.html).

```text
analysis/
├── 📂 maxfilter/           # Scripts for MNE-Python preprocessing (optional)
├── 📂 sensorlevel/         # MATLAB scripts for computing MLAEFs
├── 📂 sourcelevel/         # MATLAB scripts for two-dipole fitting
├── 📄 settings_analysis.m  # Configuration file for project paths
└── 📄 startup.m            # Script to initialize FieldTrip and local paths
```

#### Requirements & Setup
The analysis scripts require the [FieldTrip toolbox to be installed](https://www.fieldtriptoolbox.org/faq/matlab/installation/). Once downloaded, you can add it to your MATLAB path using the provided `startup.m` script (be sure to adjust the toolbox path inside the script).

To make the pipeline work, the `settings_analysis.m` file must be updated with your local directory paths. Specifically, you need to set the paths to the FieldTrip toolbox and the main project directory. For example:

```matlab
settings.path2fieldtrip = fullfile('M:\practical_meg\fieldtrip');
settings.path2project   = fullfile('M:\practical_meg');
```
#### Maxilter
the AMxfilter directory contains the follwoung script: 

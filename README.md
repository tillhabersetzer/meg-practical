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
├── 📂 derivatives/      # Derived experimental results
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

| Script Name | Description |
| :--- | :--- |
| `settings_analysis.m` | Configuration file that defines core project paths (data and derivatives directories) and sets pipeline parameters such as trigger IDs, epoch windows, filter frequencies and processing flags like latency correction. |
| `startup.m` | Initialization script that adds the FieldTrip toolbox to the environment and executes FieldTrip's default setup. |

#### Requirements & Setup
The analysis scripts require the [FieldTrip toolbox to be installed](https://www.fieldtriptoolbox.org/faq/matlab/installation/). Once downloaded, you can add it to your MATLAB path using the provided `startup.m` script (be sure to adjust the toolbox path inside the script).

To make the pipeline work, the `settings_analysis.m` file must be updated with your local directory paths. Specifically, you need to set the paths to the FieldTrip toolbox and the main project directory. For example:

```matlab
settings.path2fieldtrip = fullfile('M:\practical_meg\fieldtrip');
settings.path2project   = fullfile('M:\practical_meg');
```
#### Maxwell Filtering (📂 maxfilter)

| Script Name | Description |
| :--- | :--- |
| `apply_maxfilter_parallel.py` | Executes parallelized Maxwell filtering (SSS/tSSS) on BIDS-formatted MEG data. It automatically detects bad channels, computes continuous head positions (cHPI) and applies movement compensation to suppress external noise. |
| `check_maxfilter_stats.py` | Analyzes and visualizes head movement statistics (pitch, yaw, roll and translation) extracted from the maxfiltered recordings, generating group-level distributions and subject-level scatter plots. |
| `plot_trafo.py` | A visualization utility module that generates 3D plots of head position transformations (rotation and translation) between different coordinate spaces. |

All computed analysis results for the subjects will be saved in the `derivatives` folder, located in the main project directory alongside `rawdata`. Currently, this folder contains only the fine calibration and cross-talk files required for Maxwell filtering.

#### Sensor Level Analysis (📂 sensorlevel)

| Script Name | Description |
| :--- | :--- |
| `compute_erfs.m` | A pipeline for cleaning MEG data and computing MLAEFs. It performs epoch definition with audio-delay latency correction, filtering, semi-automated visual artifact rejection and condition pooling to output averaged waveform data. |
| `plot_erfs.m` | A script for visualizing task-related MLAEF responses at the sensor level. It generates multi-sensor topographic array plots, single-channel waveform responses and spatial scalp topography distributions averaged over specific time windows. |

#### Source Level Analysis (📂 sourcelevel)

#### Source Level Analysis

```text
sourcelevel/
├── 📂 dipolefitting/      # MATLAB scripts for equivalent current dipole (ECD) fitting
└── 📂 forward_modelling/  # MATLAB scripts for MRI coregistration and head model generation
```

##### 📂 dipolefitting

| Script Name | Description |
| :--- | :--- |
| `check_diploc.m` | A utility function that evaluates the spatial locations of a 2-dipole fit to accurately map them to the left and right hemispheres. |
| `constrained_dipolfitting.m` | Computes scalar dipole moments for two dipoles using specified locations and orientations. It calculates the orientations using either a timecourse mean or Singular Value Decomposition (SVD) before solving the linear equation. |
| `dipolefitting.m` | An automated Equivalent Current Dipole (ECD) fitting pipeline that models auditory evoked fields. It establishes spatial starting points via a symmetric grid search, refines the fit non-linearly without symmetry constraints and reconstructs source time courses. |
| `plot_dipolfitting_subjectlevel.m` | A visualization script that overlays estimated dipole locations onto the subject's structural MRI slices and maps the coordinates into standard MNI space using the AAL atlas. It generates time-series figures comparing source waveforms across different orientation strategies. |

##### 📂 forward_modelling

| Script Name | Description |
| :--- | :--- |
| `check_coregistration.m` | A quality control script used to visually inspect the coregistration between the MEG sensor space, digitized headshape and structural MRI space. It generates diagnostic figures that overlay MEG sensors with the headmodel and plots the MRI anatomy alongside brain and scalp segmentations. |
| `headmodel.m` | Processes structural MRI and MEG digitization data to compute a singleshell volume conduction headmodel. It performs interactive fiducial alignment and automatic Iterative Closest Point (ICP) headshape fitting, reslices the coregistered MRI to a 1mm isotropic resolution and segments the MRI. |
| `volumetric_sourcemodel.m` | Generates subject-specific volumetric source spaces for spatial filtering and dipole fitting. The script loads a standard MNI template grid and applies non-linear spatial warping to project the grid into the subject's native anatomical space based on their segmented MRI. |

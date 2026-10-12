%--------------------------------------------------------------------------
% Experimental Settings & Calibration Configuration
%
% MATLAB script to initialize and save the global configuration parameters 
% required for the MEG auditory stimulus presentation paradigm.
%
% Processing Steps:
% - Defines hardware trigger ID mappings for Click, Up-Chirp, and Down-Chirp.
% - Computes the required digital attenuation (AttdB) to achieve the target 
%   presentation level (e.g., 50 dB HL). This is calculated using the baseline 
%   RMS of the sequence-equalized stimuli and hardware-specific calibration 
%   values (CalVal).
% - Defines secondary calibration settings for hearing threshold detection 
%   (Peak SPL).
% - Configures system-level paradigm variables, including the ASIO driver, 
%   sampling frequency, total trial count (1200) and inter-stimulus jitter.
%
% Outputs:
% - Generates and saves a 'Settings.mat' file, which serves as the central 
%   configuration structure loaded by the stimulus presentation scripts.
%--------------------------------------------------------------------------

close all;
clear all;
clc;

% Define Trigger ID's
%--------------------------------------------------------------------------
TrigID.click     = 1; 
TrigID.upchirp   = 2; 
TrigID.downchirp = 4; 
Settings.TrigID  = TrigID;

% Calibration: Sepcify RMS vales in dB (all Stimuli are rms equalized: 
% (same for click, up and down)
%--------------------------------------------------------------------------
calibration_signal      = 'calibration_up_rmseq.wav';
[calsig, ~]             = audioread(fullfile('..','Stimuli','calibration',calibration_signal));
Calibration.RMSdBStim   = 20*log10(rms(calsig)); % calibration_signal.m
Calibration.TargetLevel = 50; % 50 dB HL
Calibration.CalVal      = [101.7,99.25]; % (measured: new for each subject (left/right)

% AttdB + RMSdBStim + CalVal = TargetLevel
% scaling = 10^( (TargetLevel - RMSdBStim - CalVal)/20)
Calibration.AttdB       = Calibration.TargetLevel - Calibration.RMSdBStim - Calibration.CalVal;
Settings.Calibration    = Calibration;

% Calibration for hearing threshold detection (Peak SPL)
%-------------------------------------------------------
Settings.Calibration.peakSPL.TargetLevel = 85; % 85 Peak SPL 
Settings.Calibration.peakSPL.CalVal      = [145.7471,147.2471]; % (fixed, only measured once)
Settings.Calibration.peakSPL.AttdB       = Settings.Calibration.peakSPL.TargetLevel - Settings.Calibration.RMSdBStim - Settings.Calibration.peakSPL.CalVal;

% Create Settings-file
%--------------------------------------------------------------------------
Settings.Setup       = 'Practical MEG';
%  Settings.Driver      = 'ASIO Fireface USB'; % soundcard driver
Settings.Driver      = 'Focusrite USB ASIO';
Settings.SampFreq    = 44100;
Settings.Nstimuli    = 1200;
Settings.Jitter      = [0.35,0.05];         % 350 ms + 50 ms randomized jitter
Settings.LastUpadate = datestr(datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss Z')); % time of last update
Settings.TrigID      = TrigID;                

% Save Settings
%--------------
save('Settings.mat','Settings')
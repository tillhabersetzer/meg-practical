%--------------------------------------------------------------------------
% Till Habersetzer, 19.11.2024
% Communication Acoustics, CvO University Oldenburg
% till.habersetzer@uol.de
%--------------------------------------------------------------------------

% ensure that we don't mix up settings
clear settings

% Define paths
%-------------
settings.path2fieldtrip   = fullfile('M:\practical_meg\fieldtrip-20250114');
settings.path2project     = fullfile('M:\practical_meg');
settings.path2rawdata     = fullfile(settings.path2project,'rawdata');
settings.path2derivatives = fullfile(settings.path2project,'derivatives');

% Other settings
%---------------
settings.use_maxfilter            = true;
settings.apply_latency_correction = true;
settings.audio_latency            = 3/1000; % 3 ms (see measurements 28.06.24)
settings.apply_epoch_rejection    = true;

% Transient
%----------
settings.trig_id.click = 1;
settings.trig_id.up    = 2;
settings.trig_id.down  = 4;

settings.trialdef.prestim  = 0.05;  
settings.trialdef.poststim = 0.35;  

settings.bpfreq  = [16,120];
settings.dftfreq = [50,100];


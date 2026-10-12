%--------------------------------------------------------------------------
% Till Habersetzer, 26.11.2024
% Communication Acoustics, CvO University Oldenburg
% till.habersetzer@uol.de
%
% MEG Sensor-Level ERF Visualization
%
% FieldTrip-based MATLAB script for visualizing auditory evoked fields 
% (MLAEFs) at the sensor level to evaluate task-related responses.
%
% Features:
% - Loads precomputed subject-level time-locked averages.
% - Calculates combined planar gradiometer representations.
% - Generates multi-sensor topographic array plots (ft_multiplotER) to 
%   compare conditions across magnetometers and gradiometers.
% - Extracts and plots single-channel waveform responses (ft_singleplotER).
% - Plots spatial scalp topography distributions (ft_topoplotER) averaged 
%   over specific latency time windows.
%
% Check out: https://www.fieldtriptoolbox.org/tutorial/eventrelatedaveraging/
%--------------------------------------------------------------------------

close all
clearvars
clc 

%% Import main settings 
%--------------------------------------------------------------------------
current_dir = pwd;
cd(fullfile('..'))
settings_analysis
cd(current_dir)

%% Script settings
%--------------------------------------------------------------------------
% Choose subject for plotting
subject = 'sub-02'; % 'sub-02'

%% Load data
%--------------------------------------------------------------------------
data       = importdata(fullfile(settings.path2project,'derivatives',subject,'sensorlevel',[subject,'_erfs.mat']));    
avgs       = data.avgs;
n_trials   = data.n_trials;
conditions = data.conditions;
clear data

n_conditions = length(conditions);

%% Add combined planar gradiometers
%--------------------------------------------------------------------------
avgs_cmb = cell(1,n_conditions);
for con_idx = 1:n_conditions
    cfg               = [];
    cfg.method        = 'sum';
    avgs_cmb{con_idx} = ft_combineplanar(cfg,avgs{con_idx});
end

%% Plot of event related fields for all sensors arranged topographically 
%--------------------------------------------------------------------------

% meg: all meg channels
% megmag: only magnetometers
% megplanar: only planar gradiometers
% meg_cmb: only combined planar gradiometers
% channels2plot = {'meg','megmag','megplanar','meg_cmb'};
channels2plot = {'megmag','megplanar'};

% Select subset of conditions for plotting
%-----------------------------------------
con_idx = (contains(conditions,'click') | contains(conditions,'down'))  | contains(conditions,'up');
% con_idx = contains(conditions,'pooled');

for chan_idx = 1:length(channels2plot)
    channel2plot = channels2plot{chan_idx};

    switch channel2plot 
        case 'meg'
            layout    = 'neuromag306all_helmet.lay';
            channel   = 'meg';
            avgs2plot = avgs;
        case 'megmag'
            layout    = 'neuromag306mag_helmet.lay';
            channel   = 'meg';
            avgs2plot = avgs;
        case 'megplanar'
            layout    = 'neuromag306planar_helmet.lay';
            channel   = 'meg';
            avgs2plot = avgs;
        case 'meg_cmb'
            layout    = 'neuromag306cmb_helmet.lay';
            channel   = channel2plot;
            avgs2plot = avgs_cmb;
    end

    figure
    cfg            = [];
    cfg.showlabels = 'yes';
    cfg.fontsize   = 6;
    cfg.layout     = layout;
    %cfg.linecolor  = 'rbg';
    ft_multiplotER(cfg, avgs2plot{con_idx}); % -> maybe needs to be changed
    legend(conditions{con_idx},'Interpreter','none');
    title([subject,': ',channel2plot],'Interpreter','none')

end

%% Plot one specific channel
%--------------------------------------------------------------------------
% Same condition as above
chan2plot = 'MEG1221'; % e.g. magnetometer

cfg         = [];
cfg.channel = chan2plot;
ft_singleplotER(cfg, avgs{con_idx});
legend(conditions{con_idx},'Interpreter','none');
title([subject,': ',channel2plot],'Interpreter','none')

%% Plot the topographic distribution of the data
%--------------------------------------------------------------------------
timewin = [0.025 0.055]; % time window to look at in more detail

% Select sensors for plotting
% channel2plot = 'megmag';
% channel2plot = 'megplanar';
channel2plot = 'meg_cmb';

% Select conditions for plotting
con_idx = (contains(conditions,'click') | contains(conditions,'down'))  | contains(conditions,'up');
% con_idx = contains(conditions,'pooled');
n_cond2plot = length(con_idx);

switch channel2plot 
    case 'megmag'
        layout    = 'neuromag306mag_helmet.lay';
        avgs2plot = avgs;
    case 'megplanar'
        layout    = 'neuromag306planar_helmet.lay';
        avgs2plot = avgs;
    case 'meg_cmb'
        layout    = 'neuromag306cmb_helmet.lay';
        avgs2plot = avgs_cmb;
end

cfg          = [];
cfg.layout   = layout;
cfg.xlim     = timewin;
cfg.style    = 'straight';
cfg.comment  = 'no';
cfg.marker   = 'off';
cfg.colorbar = 'southoutside';
cfg.style    = 'both'; % both colormap and contour lines

figure
con_idx = find(con_idx);
for con_idx2 = 1:n_cond2plot

    cfg.figure = subplot(1,n_cond2plot,con_idx2);
    ft_topoplotER(cfg, avgs2plot{con_idx(con_idx2)});
    title(conditions{con_idx(con_idx2)},'Interpreter','none');

end
sgtitle([subject,': ',channel2plot],'Interpreter','none')
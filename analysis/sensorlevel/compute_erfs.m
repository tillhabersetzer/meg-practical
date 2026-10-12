%--------------------------------------------------------------------------
% Till Habersetzer, 26.11.2024
% Communication Acoustics, CvO University Oldenburg
% till.habersetzer@uol.de
% 
% Auditory Evoked Fields (MLAEF) Preprocessing Pipeline
%
% FieldTrip-based MATLAB pipeline for cleaning MEG data and computing 
% Middle Latency Auditory Evoked Fields across different auditory tasks.
%
% Processing Steps:
% - Epoch definition with hardware audio-delay latency correction.
% - Continuous data filtering (band-pass and notch/DFT filtering).
% - Semi-automated visual artifact rejection (separated by sensor type).
% - Baseline correction (demeaning) and trial averaging (time-lock analysis).
% - Condition pooling (e.g., click + down-chirp) to increase signal-to-noise ratio.
%
% Outputs:
% - Subject-level ERF (.mat) files containing averaged waveforms, 
%   preserved trial counts, and pooled condition data.
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

%% Script Settings
%--------------------------------------------------------------------------

% Select subjects for processing
subjects = [1,2,3];
n_subj   = length(subjects);

tasks        = {'click','up','down'};
n_tasks      = length(tasks);
conditions   = [tasks,{'pooled'}]; % pooled conditions is added
n_conditions = length(condtitions);

% Event Values
eventvalues       = struct;
eventvalues.click = settings.trig_id.click;
eventvalues.up    = settings.trig_id.up;

% Filter settings
bpfreq  = settings.bpfreq;
dftfreq = settings.dftfreq;

% Epoch length
prestim  = settings.trialdef.prestim;
poststim = settings.trialdef.poststim;

% Maxfilter
use_maxfilter = settings.use_maxfilter;

% Latency Correction (Audio - Trigger)
apply_latency_correction = settings.apply_latency_correction;
audio_latency            = settings.audio_latency;

% Reject bad epochs with semi-automatic artifact rejection
% apply_epoch_rejection = settings.apply_epoch_rejection;
apply_epoch_rejection = true;

%% Preprocess data
%--------------------------------------------------------------------------

for sub_idx = 1:n_subj % loop over subjects

    subject    = sprintf('sub-%02d', subjects(sub_idx));
    epochs_all = cell(1,n_conditions); % + pooled condition
    avgs       = cell(1,n_conditions);
    n_trials   = zeros(1,n_conditions);

    for tsk_idx = 1:n_tasks % loop over tasks

        % Define datapath
        %----------------
        task = tasks{tsk_idx};
   
        if use_maxfilter
            datapath = fullfile(settings.path2derivatives,subject,'maxfilter',sprintf('%s_task-%s_proc-tsss_meg.fif',subject,task));
        else
            datapath = fullfile(settings.path2project,'rawdata',subject,'meg',sprintf('%s_task-%s_meg.fif',subject,task));
        end

        if strcmp(task,'up')
            eventvalue = eventvalues.up;
        elseif strcmp(task,'click')
            eventvalue = eventvalues.click;
        elseif strcmp(task,'down')
            eventvalue = eventvalues.down;
        else
            error('Unexpected Task')
        end
            
        % Define trials
        %--------------
        % Load all events 
        cfg                     = [];
        cfg.dataset             = datapath;
        cfg.trialfun            = 'ft_trialfun_general'; 
        cfg.trialdef.eventtype  = 'STI101'; % use sum channel
        cfg.trialdef.eventvalue = eventvalue; 
        cfg.trialdef.prestim    = prestim; % in seconds        
        cfg.trialdef.poststim   = poststim; % in seconds            
        cfg                     = ft_definetrial(cfg);

        trl                     = cfg.trl;

        % Add latency correction 
        %-----------------------
        if apply_latency_correction
            trl(:,1:2) = trl(:,1:2) + round(audio_latency*1000); % in samples
        end
 
        % Check triggers
        %---------------
        if ~isequal(length(trl),1200)
            error('Unexpected number of triggers.')
        end
    
        % Filter continuous data to avoid edge artifacts
        %-----------------------------------------------
        cfg              = [];
        cfg.dataset      = datapath;
        cfg.channel      = 'meg'; 
        cfg.continuous   = 'yes';
        cfg.bpfilter     = 'yes';
        cfg.bpfreq       = bpfreq;
        cfg.dftfilter    = 'yes';      % enable notch filtering to eliminate power line noise
        cfg.dftfreq      = dftfreq;    % set up the frequencies for notch filtering
        cfg.dftreplace   = 'zero';     % 'zero' is default'
        cfg.coilaccuracy = 0;          % ensure that sensors are expressed in SI units
        data             = ft_preprocessing(cfg); 

        % Epoch data
        %-----------
        cfg     = [];
        cfg.trl = trl;  
        epochs  = ft_redefinetrial(cfg,data); 
    
        % Semi automatic artifact rejection
        %----------------------------------
        if apply_epoch_rejection
            % separately for magnetometers
            cfg             = [];
            cfg.metric      = 'maxzvalue';
            cfg.channel     = 'megmag';
            cfg.keepchannel = 'yes';  % This keeps those channels that are not displayed in the data
            epochs          = ft_rejectvisual(cfg,epochs);
            
            % separately for gradiometers
            cfg.channel     = 'megplanar';
            epochs          = ft_rejectvisual(cfg,epochs);

            % Demean trials
            %--------------
            cfg                = [];
            cfg.demean         = 'yes';
            cfg.baselinewindow = [-prestim 0];
            epochs             = ft_preprocessing(cfg,epochs);  
        end

        epochs_all{tsk_idx} = epochs;

        % Note down amount of preserved epochs
        %-------------------------------------
        n_trials(tsk_idx) = length(epochs.trial);

        % Compute average 
        %------------------------------------------------------------------
        % Timelockanalysis
        cfg           = [];
        avgs{tsk_idx} = ft_timelockanalysis(cfg, epochs_all{tsk_idx});
        
        clear epochs

    end % loop over tasks

    %% Add pooled data over click/downchirp
    %----------------------------------------------------------------------
    % combine click/downchrip
    if sum(contains(tasks,{'click','down'})) == 2 % both conditions should be selected

        idx                   = find(contains(tasks,{'click','down'}));
        cfg                   = [];
        epochs_pooled         = ft_appenddata(cfg, epochs_all{idx(1)}, epochs_all{idx(2)});
        epochs_pooled.grad    = epochs_all{idx(1)}.grad;  
        n_trials(n_tasks+1)   = length(epochs_pooled.trial);
        epochs_all{n_tasks+1} = epochs_pooled;
        
        cfg             = [];
        avgs{n_tasks+1} = ft_timelockanalysis(cfg, epochs_pooled);

        clear epochs_pooled
       
    end

    %% Save data
    %----------------------------------------------------------------------
    % make folder for data
    dir2save = fullfile(settings.path2project,'derivatives',subject,'sensorlevel');
    if ~exist(dir2save,'dir')
        mkdir(dir2save)
    end

    results            = struct();
    results.avgs       = avgs;
    % results.epochs     = epochs_all;
    results.n_trials   = n_trials;
    results.conditions = conditions;
    save(fullfile(dir2save,[subject,'_erfs.mat']),'-struct','results',"-v7.3"); 

    clear results avgs epochs_all n_trials 
 
end % loop subjects

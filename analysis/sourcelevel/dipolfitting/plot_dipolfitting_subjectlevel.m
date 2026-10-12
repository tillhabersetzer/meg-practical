%--------------------------------------------------------------------------
% Till Habersetzer, 29.04.2025
% Communication Acoustics, CvO University Oldenburg
% till.habersetzer@uol.de
%
% MEG Dipole Fit Visualization & Analysis
%
% FieldTrip-based MATLAB script to visually inspect and evaluate the 
% results of Equivalent Current Dipole (ECD) modeling for auditory tasks.
%
% Visualization & Analysis Steps:
% - Overlays estimated dipole locations (symmetric and non-symmetric fits) 
%   onto the subject's native orthogonal structural MRI slices.
% - Maps subject-specific dipole coordinates into standard MNI space and 
%   assigns anatomical region labels using the AAL atlas.
% - Rescales dipole moments to standard units (nAm) for visualization.
% - Extracts and plots bilateral source timecourses (waveforms) comparing 
%   multiple dipole orientation strategies:
%     1. Free orientation (full X, Y, Z components).
%     2. Z-component only.
%     3. Fixed orientation (constrained by the mean dipole moment).
%     4. Fixed orientation (constrained by maximum variance via SVD,
%     recommendstion)
%
% Outputs:
% - Diagnostic 3D spatial plots of dipole locations within the brain.
% - Time-series figures comparing task-specific source waveforms across 
%   the left and right auditory cortices.
%--------------------------------------------------------------------------

close all
clear
clc

%% Import main settings 
%--------------------------------------------------------------------------
current_dir = pwd;
cd(fullfile('..','..'))
settings_analysis
cd(current_dir)

%% Script settings
%--------------------------------------------------------------------------
% Choose subject for plotting
subject = 'sub-02'; % 'sub-01'

% Choose timewindow for plotting
% time2plot = [-10 90]; % -10, 90ms
timewin2plot = [-50 150];

%% Load data 
%--------------------------------------------------------------------------
data                 = importdata(fullfile(settings.path2project,'derivatives',subject,'sourcelevel',[subject,'_dipolefits.mat']));
tasks                = data.tasks;
n_tasks              = length(tasks);
% dipole moments
source_pooled_sym    = data.source_pooled_sym;
source_pooled_nosym  = data.source_pooled_nosym;
% vector dipol moments of conditions
source_vec           = data.source_vec;
% scalar dipol moments of conditions
source_sca_mean      = data.source_sca_mean;
source_sca_svd       = data.source_sca_svd;

chantype             = data.chantype;

sourcemodel   = importdata(fullfile(settings.path2project,'derivatives',subject,'forward_modelling',[subject,'_sourcemodel-volumetric.mat']));
sourcemodel   = ft_convert_units(sourcemodel,'m'); 
template_grid = importdata(fullfile(settings.path2fieldtrip,'template','sourcemodel','standard_sourcemodel3d10mm.mat'));
template_grid = ft_convert_units(template_grid,'mm'); 
   
clear data

%% Rescale units - optional for plotting (Am -> nAm)
%--------------------------------------------------------------------------
for tsk_idx = 1:n_tasks
    source_vec{tsk_idx}.dip.mom = 10^9*source_vec{tsk_idx}.dip.mom;
    source_sca_mean{tsk_idx}    = 10^9*source_sca_mean{tsk_idx};
    source_sca_svd{tsk_idx}     = 10^9*source_sca_svd{tsk_idx};
end

%% (1) Inspect dipole locations
%--------------------------------------------------------------------------

% load mri
%---------
mri = importdata(fullfile(settings.path2project,'derivatives',subject,'forward_modelling',[subject,'_T1w-segmented.mat']));
% Keep it in SI-units
mri = ft_convert_units(mri, 'm'); 

figure('Name', sprintf('%s: Fitted dipoles using pooled condition and %s', subject, chantype))
hold on

% symmetric dipole fit 
ft_plot_dipole(source_pooled_sym.dip.pos(1,:), mean(source_pooled_sym.dip.mom(1:3,:),2), 'color', 'r', 'unit','m')
ft_plot_dipole(source_pooled_sym.dip.pos(2,:), mean(source_pooled_sym.dip.mom(4:6,:),2), 'color', 'r', 'unit','m')

% refinement of symmetric dipole fit 
ft_plot_dipole(source_pooled_nosym.dip.pos(1,:), mean(source_pooled_nosym.dip.mom(1:3,:),2), 'color', 'g', 'unit','m')
ft_plot_dipole(source_pooled_nosym.dip.pos(2,:), mean(source_pooled_nosym.dip.mom(4:6,:),2), 'color', 'g', 'unit','m')

pos = mean(source_pooled_sym.dip.pos,1);
ft_plot_slice(mri.anatomy, 'transform', mri.transform, 'location', pos, 'orientation', [1 0 0], 'resolution', 0.001)
ft_plot_slice(mri.anatomy, 'transform', mri.transform, 'location', pos, 'orientation', [0 1 0], 'resolution', 0.001)
ft_plot_slice(mri.anatomy, 'transform', mri.transform, 'location', pos, 'orientation', [0 0 1], 'resolution', 0.001)

ft_plot_crosshair(pos, 'color', [1 1 1]/2);

axis tight
axis off

view(12, -10)
title(sprintf('%s: Fitted dipoles using pooled condition and %s', subject, chantype))

%% (2) Inspect dipole locations in mni space
%--------------------------------------------------------------------------
dippos_loc_sym   = cell(1,2); % left/right
dippos_loc_nosym = cell(1,2);

% Positons
%---------
% positions in mni space
dippos_sym     = source_pooled_sym.dip.pos;
idx            = dsearchn(sourcemodel.pos,dippos_sym);
dippos_sym_mni = template_grid.pos(idx,:);

% positions in mni space
dippos_nosym     = source_pooled_nosym.dip.pos;
idx              = dsearchn(sourcemodel.pos,dippos_nosym);
dippos_nosym_mni = template_grid.pos(idx,:);

% this path needs to point to your fieldtrip path
atlas = ft_read_atlas(fullfile(settings.path2fieldtrip,'template','atlas','aal','ROI_MNI_V4.nii')); % mm

cfg            = [];
cfg.atlas      = atlas;
cfg.inputcoord = 'mni';
cfg.output     = 'label';

positions = vertcat(dippos_sym_mni,dippos_nosym_mni);
for p=1:2 % left / right
    positions           = dippos_sym_mni;
    cfg.roi             = positions(p,:); 
    labels              = ft_volumelookup(cfg, atlas);
    [~, indx]           = max(labels.count);
    dippos_loc_sym{p}   = labels.name(indx);

    positions           = dippos_nosym_mni;
    cfg.roi             = positions(p,:); 
    labels              = ft_volumelookup(cfg, atlas);
    [~, indx]           = max(labels.count);
    dippos_loc_nosym{p} = labels.name(indx);
end  

%% (3) Inspect timecourses 
%--------------------------------------------------------------------------

%% All moments, xyz-directions and both hemispheres
%--------------------------------------------------------------------------
% Plot xyz-dipole moments all in single plots divided by left/right and
% task

% Mapping between dipole locations and hemispheres
%-------------------------------------------------
% [1,2] if first dipole belongs to left hemisphere, [2,1] if first dipole belongs to right hemisphere
% 1: left, 2: right
mapping = check_diploc(dippos_nosym); 

idxs      = [];
idxs(1,:) = 1:3; % left
idxs(2,:) = 4:6; % right

figidxs = [1,3,5;2,4,6];
name    = {'(left)','(right)'};

% Get overall min/max values
min_vals = cellfun(@(s) min(s.dip.mom, [], 'all'), source_vec);
mini     = min(min_vals);
max_vals = cellfun(@(s) max(s.dip.mom, [], 'all'), source_vec);
maxi     = max(max_vals);

figure('Name',sprintf('%s: Dipole moments xyz-components',subject))
for i=1:2
    idx    = idxs(mapping(i),:);
    figidx = figidxs(i,:);
    
    time2plot = source_vec{tsk_idx}.time*1000;
    axisvec   = horzcat(time2plot,[mini,maxi]);
    
    % Loop over tasks
    for tsk_idx = 1:n_tasks
        subplot(n_tasks,2,figidx(tsk_idx)); 
        plot(time2plot, source_vec{tsk_idx}.dip.mom(idx,:), '-')
        if tsk_idx==3
            xlabel('t / ms');
        end
        if i==1
            ylabel('dipole moment / nAm'); 
        end
        legend({'x', 'y', 'z'});
        axis(axisvec) 
        grid on
        grid minor
        title(sprintf('%s (%s)',tasks{tsk_idx},name{i}));
        xlim(timewin2plot)
    end
end
sgtitle(sprintf('%s: Dipole moments xyz-components',subject))

%% Visualize the z-component for both hemispheres
%--------------------------------------------------------------------------

% Mapping between dipole locations and hemispheres
%-------------------------------------------------
pos     = dippos_nosym;
mapping = check_diploc(pos); 

idxs = [3,6]; % z-component

name = {'left hemisphere','right hemisphere'};

% Get overall min/max values
min_vals = cellfun(@(s) min(s.dip.mom(idxs,:), [], 'all'), source_vec);
mini     = min(min_vals);
max_vals = cellfun(@(s) max(s.dip.mom(idxs,:), [], 'all'), source_vec);
maxi     = max(max_vals);

figure('Name',sprintf('%s: Dipole moments z-component',subject))
for i=1:2

    idx = idxs(mapping(i));

    time2plot = source_vec{1}.time*1000;
    axisvec   = horzcat(time2plot,[mini,maxi]);
    
    subplot(2,1,i); 
    hold on
    for tsk_idx = 1:n_tasks
        plot(source_vec{tsk_idx}.time*1000, source_vec{tsk_idx}.dip.mom(idx,:), '-')
    end
    legend(tasks);
    axis(axisvec)
    grid on
    grid minor
    title(name{i})
    if i==2
        xlabel('t / ms')
    end
    ylabel('dipole moment / nAm')
    xlim(timewin2plot)
end
sgtitle(sprintf('%s: Dipole moments z-component',subject))

%% Visualize fixed dipole (fixed orientation) - RECOMMENDATION
%--------------------------------------------------------------------------
% mean dipolmoment orientation has been used as orientation constraint

% Mapping between dipole locations and hemispheres
%-------------------------------------------------
pos     = dippos_nosym;
mapping = check_diploc(pos); 

name = {'left hemisphere','right hemisphere'};
time2plot = source_vec{1}.time*1000; 

% Get overall min/max values
min_vals = cellfun(@(s) min(s, [], 'all'), source_sca_mean);
mini     = min(min_vals);
max_vals = cellfun(@(s) max(s, [], 'all'), source_sca_mean);
maxi     = max(max_vals);

figure('Name',sprintf('%s: Fixed oriented dipole via mean orientation',subject))
for i=1:2

    idx     = mapping(i);
    axisvec = horzcat(time2plot,[mini,maxi]);
    
    subplot(2,1,i); 
    hold on
    for tsk_idx = 1:n_tasks
        plot(time2plot, source_sca_mean{tsk_idx}(idx,:), '-')
    end
    legend(tasks);
    axis(axisvec)
    grid on
    grid minor
    title(name{i})
    if i==2
        xlabel('t / ms')
    end
    ylabel('dipole moment / nAm')
    xlim(timewin2plot)
end
sgtitle(sprintf('%s: Fixed oriented dipole via mean orientation',subject))

%% Experimental plots - dont take too serious...
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Single timecourse: Projection of moments on direction which explains
%  maximum variance via SVD
%--------------------------------------------------------------------------

% Mapping between dipole locations and hemispheres
%-------------------------------------------------
pos     = dippos_nosym{ep_idx};
mapping = check_diploc(pos); 

idxs      = [];
idxs(1,:) = 1:3; % left
idxs(2,:) = 4:6; % right

name = {'left hemisphere','right hemisphere'};
time2plot = source_vec{1}.time*1000; 


% Calculate all projections first 
%--------------------------------
all_projections = cell(2, n_tasks); % Use a cell to store data for each subplot/task
for i = 1:2
    idx = idxs(mapping(i),:);
    for tsk_idx = 1:n_tasks
        moments           = source_vec{tsk_idx}.dip.mom(idx,:);
        [u, ~, ~]         = svd(moments, 'econ'); 
        moments_projected = u(:,1)'*moments; 
        
        all_projections{i, tsk_idx} = moments_projected;
    end
end

% Global axis limits
%-------------------
all_data_vector = [all_projections{:}];
min_y           = min(all_data_vector);
max_y           = max(all_data_vector);
y_lims          = [min_y, max_y];

% Set x-axis limits based on the time vector
x_lims = [min(time2plot), max(time2plot)];

figure('Name',sprintf('%s: Projection of moments onto maximum variance direction',subject))
for i=1:2

    idx = idxs(mapping(i),:);
    
    subplot(2,1,i)
    hold on;
    for tsk_idx = 1:n_tasks
        % Plot the pre-computed projection
        plot(time2plot, all_projections{i, tsk_idx}, '-');
    end
    grid on
    grid minor
    title(name{i})

    ylim(y_lims);
    % xlim(x_lims);
    xlim(timewin2plot)
    
    if i==2
        xlabel('t / ms')
    end
    ylabel('dipole moment / nAm')
    hold off;

end
sgtitle(sprintf('%s: Projection of moments onto maximum variance direction',subject))

%% Visualize fixed dipole (fixed orientation) - SVD Orientation
%--------------------------------------------------------------------------
% mean dipolmoment orientation has been used as orientation constraint

% Mapping between dipole locations and hemispheres
%-------------------------------------------------
pos     = dippos_nosym;
mapping = check_diploc(pos); 

name = {'left hemisphere','right hemisphere'};
time2plot = source_vec{1}.time*1000; 

% Get overall min/max values
min_vals = cellfun(@(s) min(s, [], 'all'), source_sca_svd);
mini     = min(min_vals);
max_vals = cellfun(@(s) max(s, [], 'all'), source_sca_svd);
maxi     = max(max_vals);

figure('Name',sprintf('%s: Fixed oriented dipole via svd orientation',subject))
for i=1:2

    idx     = mapping(i);
    axisvec = horzcat(time2plot,[mini,maxi]);
    
    subplot(2,1,i); 
    hold on
    for tsk_idx = 1:n_tasks
        plot(time2plot, source_sca_svd{tsk_idx}(idx,:), '-')
    end
    legend(tasks);
    axis(axisvec)
    grid on
    grid minor
    title(name{i})
    if i==2
        xlabel('t / ms')
    end
    ylabel('dipole moment / nAm')
    xlim(timewin2plot)
end
sgtitle(sprintf('%s: Fixed oriented dipole via svd orientation',subject))
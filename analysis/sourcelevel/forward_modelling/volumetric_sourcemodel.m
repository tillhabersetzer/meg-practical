%-----------------------------------------------------------------------
% Till Habersetzer, 14.01.2025
% Communication Acoustics, CvO University Oldenburg
% till.habersetzer@uol.de 
%
% MEG Volumetric Sourcemodel Generation
%
% FieldTrip-based MATLAB script to create subject-specific volumetric 
% source spaces for spatial filtering (beamforming) or dipole fitting.
%
% Processing Steps:
% - Loads a standard atlas-based MNI template grid (10mm resolution).
% - Applies non-linear spatial warping to project the MNI template grid 
%   into the subject's native anatomical space using their segmented MRI.
% - Ensures grid points are comparable across subjects for group-level statistics.
%
% Outputs:
% - Saved .mat files containing the subject-specific volumetric sourcemodel.
% - 3D quality control visualizations overlaying the warped source space 
%   grid inside the singleshell headmodel, along with the MEG sensors and headshape.
%
% Generate volumtric sourcemodels for beamforming / dipole fitting
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

% check whether maxfiltered data should be analyzed
use_maxfilter = settings.use_maxfilter;

%% Script settings

% choose subject number
%--------------------------------------------------------------------------
subjects = [1,2,3];
% Use task that has been used as a reference head position
task = 'click';

% option to plot sourcemodel
check = 1;
%--------------------------------------------------------------------------

%% Source model 
%--------------------------------------------------------------------------

% load template grid
%-------------------
template_grid = importdata(fullfile(settings.path2fieldtrip,'template','sourcemodel','standard_sourcemodel3d10mm.mat'));
template_grid = ft_convert_units(template_grid,'mm'); 

% plot the atlas based grid
if check
    figure
    ft_plot_mesh(template_grid.pos(template_grid.inside,:));
end

% Coregistration of subject specific grid to the atlas based template grid
%-------------------------------------------------------------------------
for sub_idx = subjects

    subject = sprintf('sub-%02d', sub_idx);

    % make individual subject's grid
    mri_segmented = importdata(fullfile(settings.path2derivatives,subject, ...
                    'forward_modelling',[subject,'_T1w-segmented.mat'])); % mm
    % mri_segmented = ft_convert_units(mri_segmented,'m'); % use SI units
    
    cfg           = [];
    cfg.warpmni   = 'yes';
    cfg.template  = template_grid;
    cfg.nonlinear = 'yes';
    cfg.mri       = mri_segmented;
    cfg.unit      = 'mm';
    sourcemodel   = ft_prepare_sourcemodel(cfg);
    
    % Plot the final source model together with the individual head model and the sensor array
    if check
        % check sourcemodel
        if use_maxfilter
            megfile = fullfile(settings.path2derivatives,subject,'maxfilter',sprintf('%s_task-%s_proc-tsss_meg.fif',subject,task));
        else
            megfile = fullfile(settings.path2project,'rawdata',subject,'meg',sprintf('%s_task-%s_meg.fif',subject,task));
        end

        shape     = ft_read_headshape(megfile,'unit','mm');
        grad      = ft_convert_units(ft_read_sens(megfile,'senstype','meg'),'mm'); 
        headmodel = importdata(fullfile(settings.path2derivatives,subject, ...
                    'forward_modelling',[subject,'_headmodel-singleshell.mat'])); % mm
        
        figure
        hold on   
        ft_plot_headmodel(headmodel,  'facecolor', 'cortex', 'edgecolor', 'none');
        alpha 0.5;  % camlight;
        alpha 0.4;  % make the surface transparent
        ft_plot_headshape(shape);
        ft_plot_mesh(sourcemodel.pos(sourcemodel.inside,:)); % plot only locations inside the volume
        ft_plot_sens(grad, 'style', '*b');
        view ([0 -90 0])
        title(subject)
    end
    
    % Save data
    %----------   
    % make folder for data
    dir2save = fullfile(settings.path2derivatives,subject,'forward_modelling');
    if ~exist(dir2save, 'dir')
       mkdir(dir2save)
    end
    save(fullfile(dir2save,[subject,'_sourcemodel-volumetric.mat']),'sourcemodel'); % in mm

end 

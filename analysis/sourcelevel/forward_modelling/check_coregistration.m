%--------------------------------------------------------------------------
% Till Habersetzer, 14.01.2025
% Communication Acoustics, CvO University Oldenburg
% till.habersetzer@uol.de 
%
% MEG/MRI Coregistration Quality Control
%
% FieldTrip-based MATLAB script for visual inspection and quality control 
% of the coregistration between the MEG sensor space, digitized headshape 
% and the structural MRI space.
%
% Visualization Steps:
% - Overlays MEG sensors, digitized headshape and the singleshell headmodel.
% - Plots MRI anatomy alongside brain and scalp segmentations.
% - Displays orthogonal slices and montages of the MRI intersecting the headmodel boundary.
% - Renders a 3D scalp isosurface overlaid with Polhemus headshape points and fiducials.
% - Validates coregistration consistency across multiple MEG recordings/tasks.
%
% Outputs:
% - Multiple 2D and 3D diagnostic figures to verify the accuracy of the 
%   forward model before proceeding to source reconstruction.
%
% https://www.fieldtriptoolbox.org/example/coregistration_quality_control/
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
%--------------------------------------------------------------------------

% choose subject number
%--------------------------------------------------------------------------
sub_idx = 1;
subject = sprintf('sub-%02d', sub_idx);

% choose dataset for headshape extraction
if use_maxfilter
    megfile1 = fullfile(settings.path2project,'derivatives',subject,'maxfilter',[subject,'_task-click_proc-tsss_meg.fif']);
    megfile2 = fullfile(settings.path2project,'derivatives',subject,'maxfilter',[subject,'_task-up_proc-tsss_meg.fif']);
    megfile3 = fullfile(settings.path2project,'derivatives',subject,'maxfilter',[subject,'_task-down_proc-tsss_meg.fif']);
else
    megfile1 = fullfile(settings.path2project,'rawdata',subject,'meg',[subject,'_task-click_meg.fif']);
    megfile2 = fullfile(settings.path2project,'rawdata',subject,'meg',[subject,'_task-up_meg.fif']);
    megfile3 = fullfile(settings.path2project,'rawdata',subject,'meg',[subject,'_task-down_meg.fif']);
end
%--------------------------------------------------------------------------

%% Load required data
%--------------------------------------------------------------------------
headmodel_meg   = importdata(fullfile(settings.path2project,'derivatives',subject,'forward_modelling',[subject,'_headmodel-singleshell.mat']));
mri             = importdata(fullfile(settings.path2project,'derivatives',subject,'forward_modelling',[subject,'_T1w-segmented.mat']));
sourcemodel_meg = importdata(fullfile(settings.path2project,'derivatives',subject,'forward_modelling',[subject,'_sourcemodel-volumetric.mat']));
headshape       = ft_read_headshape(megfile1,'unit','mm'); % has to be the file for reference head position

% Same Units for Plot (mm)
grad1 = ft_read_sens(megfile1,'senstype','meg');  % cm
grad2 = ft_read_sens(megfile2,'senstype','meg'); % cm
grad3 = ft_read_sens(megfile3,'senstype','meg'); % cm
grad1 = ft_convert_units(grad1,'mm');
grad2 = ft_convert_units(grad2,'mm');
grad3 = ft_convert_units(grad3,'mm');

%% figure 1, All together

figure
ft_plot_sens(grad1)
ft_plot_headshape(headshape)
ft_plot_headmodel(headmodel_meg)
ft_plot_axes([], 'unit', 'mm');

%% figure 2, MRI anatomy and brain segmentation

cfg              = [];
cfg.anaparameter = 'anatomy';
cfg.funparameter = 'brain';
% cfg.funparameter = 'scalp';
cfg.location     = [0 0 60];
ft_sourceplot(cfg, mri)

%% figure 3 and 4, MRI anatomy and headmodel

location = [0 0 60];
figure
ft_plot_ortho(mri.anatomy, 'transform', mri.transform, 'location', location, 'intersectmesh', headmodel_meg.bnd,'unit','mm')

figure
ft_plot_montage(mri.anatomy, 'transform', mri.transform, 'intersectmesh', headmodel_meg.bnd,'unit','mm')

%% figure 5, MRI scalp surface and polhemus headshape
% problems with surface extraction due to "worse" mri segmentation likely

% extract scalp if it is missing
cfg           = [];
cfg.output    = {'brain','skull','scalp'}; % you only need brain for meg
mri_2         = ft_volumesegment(cfg, mri);
mri_2.anatomy = mri.anatomy;
mri           = mri_2;

cfg             = [];
cfg.tissue      = {'scalp'};
cfg.method      = 'isosurface';
cfg.numvertices = 10000;
scalp           = ft_prepare_mesh(cfg, mri);

figure
ft_plot_mesh(scalp, 'facecolor', 'skin')
lighting phong
camlight left
camlight right
material dull
alpha 0.5
ft_plot_headshape(headshape, 'vertexcolor', 'k');

%% figure 6, MRI and anatomical landmarks
% seems not to work :/
figure
for i=1:3
  subplot(2,2,i)
  figure
  title(headshape.fid.label{i});
  location = headshape.fid.pos(i,:);
  ft_plot_ortho(mri.anatomy, 'transform', mri.transform, 'style', 'intersect', 'location', location, 'plotmarker', location, 'markersize', 5, 'markercolor', 'y')
end

%% figure 7, MRI scalp surface and anatomical landmarks

figure
ft_plot_mesh(scalp, 'facecolor', 'skin')
lighting phong
camlight left
camlight right
material dull
alpha 0.3
ft_plot_mesh(headshape.fid, 'vertexcolor', 'k', 'vertexsize', 10);

%% Optional code: Check coregistration across files

figure
ft_plot_headmodel(headmodel_meg);
hold on
ft_plot_sens(grad1, 'style', '*b');
ft_plot_headshape(headshape);

figure
ft_plot_headmodel(headmodel_meg);
hold on
ft_plot_sens(grad2, 'style', '*b');
ft_plot_headshape(headshape);

figure
ft_plot_headmodel(headmodel_meg);
hold on
ft_plot_sens(grad3, 'style', '*b');
ft_plot_headshape(headshape);

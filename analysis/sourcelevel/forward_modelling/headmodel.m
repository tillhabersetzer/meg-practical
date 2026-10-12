%--------------------------------------------------------------------------
% Till Habersetzer, 14.01.2025
% Communication Acoustics, CvO University Oldenburg
% till.habersetzer@uol.de 
%
% MEG Forward Modeling & MRI Preprocessing
%
% FieldTrip-based MATLAB script to create a singleshell headmodel for MEG 
% source localization and prepare structural MRI data for the FreeSurfer 
% surface-based pipeline.
%
% Processing Steps:
% - Imports structural T1w MRI and MEG headshape digitizations.
% - Multi-step Neuromag coregistration: interactive fiducial alignment 
%   followed by automatic ICP (Iterative Closest Point) headshape fitting.
% - Reslices the coregistered MRI to a standard 1mm isotropic resolution.
% - Segments the MRI volume to extract the brain surface.
% - Computes a 'singleshell' volume conduction headmodel.
%
% Outputs:
% - Saved .mat files containing the coregistered, resliced, and segmented 
%   MRI data, plus the finalized singleshell headmodel.
% - 3D quality control visualizations overlaying the MEG sensors, digitized 
%   headshape, and the computed volume conduction model.
%--------------------------------------------------------------------------

close all
clearvars
clc 

%% Import main settings 
%--------------------------------------------------------------------------
current_dir = pwd;
cd(fullfile('..','..'))
settings_analysis
cd(current_dir)

% Maxfilter
use_maxfilter = settings.use_maxfilter;

%% Script settings

% choose subject number
%--------------------------------------------------------------------------
sub_idx = 3;
subject = sprintf('sub-%02d', sub_idx);

% Use task that has been used as a reference head position
task = 'click';

% choose dataset for headshape extraction
if use_maxfilter
    megfile = fullfile(settings.path2derivatives,subject,'maxfilter',sprintf('%s_task-%s_proc-tsss_meg.fif',subject,task));
else
    megfile = fullfile(settings.path2project,'rawdata',subject,'meg',sprintf('%s_task-%s_meg.fif',subject,task));
end

% choose mri file
mrifile  = fullfile(settings.path2project,'rawdata',subject,'anat',[subject,'_T1w.nii']);

% initialize directory for data storing
dir2save = fullfile(settings.path2derivatives,subject,'forward_modelling');
%--------------------------------------------------------------------------

% make folder for data
%---------------------
if ~exist(dir2save, 'dir')
   mkdir(dir2save)
end

%% Preparation for Sourcemodel based on Surface Description
%--------------------------------------------------------------------------

% Extract Headshape
%------------------
headshape = ft_read_headshape(megfile,'unit','mm');

% Read in Mri
%------------
mri_orig = ft_read_mri(mrifile,'dataformat','nifti','readbids','no');

% 1. Coregistration to Neuromag Coordsystem based on Anatomical Landmarks
%------------------------------------------------------------------------
cfg            = [];
cfg.method     = 'interactive';
cfg.coordsys   = 'neuromag';
mri_realigned1 = ft_volumerealign(cfg, mri_orig);

% Incorporate Headshape Information (optional but recommended)
%-------------------------------------------------------------
cfg                       = [];
cfg.method                = 'headshape';
cfg.headshape.headshape   = headshape;
cfg.coordsys              = 'neuromag';
cfg.headshape.interactive = 'no';  % if manually: yes
cfg.headshape.icp         = 'yes'; % if manually: no / without automatic icp alignment - use only headshape
mri_realigned2            = ft_volumerealign(cfg, mri_realigned1);

% Check Results interactively in case of manual correction
%---------------------------------------------------------
cfg                       = [];
cfg.method                = 'headshape';
cfg.headshape.headshape   = headshape;
cfg.coordsys              = 'neuromag';
cfg.headshape.interactive = 'yes';
cfg.headshape.icp         = 'no'; 
mri_coreg                 = ft_volumerealign(cfg, mri_realigned2);

% 2. Reslice
%-----------
% Check if full head is still in mri after reslicing, might fail for big
% heads and is important in case you may need a bem headmodel which
% includes the scalp
cfg            = [];
cfg.resolution = 1;
cfg.dim        = [256 256 256];
cfg.yrange     = [-130,125]; % could be adjusted, see above remark, sum up to 255 -> 256 voxel
cfg.coordsys   = 'neuromag';
mri_resliced   = ft_volumereslice(cfg,mri_coreg); 

% Check 
%------
cfg = [];
ft_sourceplot(cfg, mri_coreg);
cfg = [];
ft_sourceplot(cfg, mri_resliced);

% 3. Segmentation (most time consuming)
%--------------------------------------
cfg           = [];
cfg.output    = {'brain'};
% cfg.output    = {'brain','skull','scalp'}; % you only need brain for meg
mri_segmented = ft_volumesegment(cfg, mri_resliced);

% Copy the Anatomy into the segmented Mri
mri_segmented.anatomy = mri_resliced.anatomy;

% Check
%------
cfg              = [];
cfg.funparameter = 'brain';
ft_sourceplot(cfg, mri_segmented);

% 4. Headmodel
%-------------
cfg        = [];
cfg.method = 'singleshell';
vol        = ft_prepare_headmodel(cfg, mri_segmented);

% Save data
%----------
save(fullfile(dir2save,[subject,'_T1w-coregistered.mat']),'mri_coreg'); % in mm
save(fullfile(dir2save,[subject,'_T1w-resliced.mat']),'mri_resliced'); % in mm
save(fullfile(dir2save,[subject,'_T1w-segmented.mat']),'mri_segmented'); % in mm
save(fullfile(dir2save,[subject,'_headmodel-singleshell.mat']),'vol'); % in mm

% Check
%------
% Same Units for Plot
grad   = ft_read_sens(megfile,'senstype','meg'); % cm
shape  = ft_read_headshape(megfile,'unit','cm');
vol_cm = ft_convert_units(vol,'cm');

figure
ft_plot_headmodel(vol_cm);
hold on
ft_plot_sens(grad, 'style', '*b');
ft_plot_headshape(shape);

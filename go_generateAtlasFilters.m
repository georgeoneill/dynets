function [filters, subgrid, subvol] = go_generateAtlasFilters(data,mripath)

% General housekeeping, good to know where the dataset and MRI are!
files.data  = data.cfg.dataset;
files.mri   = mripath;

tmp = which('ft_defaults');
if isempty(tmp)
    error('Fieldtrip path cannot be automatically found :(');
else
        slsh = strfind(tmp,'/');
        files.ftpath = tmp(1:slsh(end));
end

%% MRI import / head model preparation

% import 
mri             = ft_read_mri(files.mri);
% segment
cfg             = [];
cfg.write       = 'no';
[segmentedmri]  = ft_volumesegment(cfg,mri);
% headmodel
cfg             = [];
cfg.method      = 'singleshell';
subvol          = ft_prepare_headmodel(cfg,segmentedmri);

%% Prepare source space on MNI AAL atlas.


% create grid for MNI template
tmp = load([files.ftpath 'template/headmodel/standard_singleshell']);
mnivol          = tmp.vol;
cfg             = [];
cfg.vol         = mnivol;
cfg.grid.resolution     = 0.4;
cfg.grid.unit           = 'cm';
cfg.inwardshift = -1; 
mnigrid            = ft_prepare_sourcemodel(cfg);  

%% Atlas masking of source space
atlas = ft_read_atlas([files.ftpath 'template/atlas/aal/ROI_MNI_V4.nii'])
    
atlas           = ft_read_atlas([files.ftpath 'template/atlas/aal/ROI_MNI_V4.nii']);
atlas           = ft_convert_units(atlas,'cm');

% In the NIMG paper, we used an alternate version of the AAL atlas which
% removed all subcortical parcels and had them in a different order (Gong
% et ak, Cereb. Cortex 2009). The next function finds the sources in mni
% space which represent the center of mass of each of Gong's 78 parcels
% in the ordering. As the sources are ordered the same in individual space
% this should be fine to the extract at the subject level.

source_ids          = go_findGongAALCentres(atlas,mnigrid);

% Copy over relevant information to new source space
AALgrid             = [];
AALgrid.dim         = mnigrid.dim;
AALgrid.pos         = mnigrid.pos(source_ids,:);
AALgrid.unit        = 'cm';
AALgrid.inside      = ones(length(source_ids),1);
AALgrid.cfg         = mnigrid.cfg;

%% Warp masked MNI space back to individual space

cfg                 = [];
cfg.grid.warpmni    = 'yes';
cfg.grid.template   = AALgrid;
cfg.grid.nonlinear  = 'yes';
cfg.grid.unit       = 'mm';
cfg.mri             = mri;
subgrid             = ft_prepare_sourcemodel(cfg);

% uncomment below for visualisation purposes
% ft_plot_mesh(subgrid.pos(subgrid.inside,:))
% hold on
% ft_plot_vol(subvol,'facecolor','cortex','edgecolor','none'); alpha 0.5

%% Calculate forward model
% find gradiometer information
if ~exist('hdr')
    try 
        hdr = data.hdr;
    catch 
        hdr = ft_read_header(files.data);
    end
end

% lead fields
cfg             = [];
cfg.grad        = hdr.grad;
cfg.vol         = subvol;
cfg.grid        = subgrid;
cfg.channel     = {'MEG'};
cfg.normalise   = 'yes';
cfg.rankreduce  = 2; 
lf              = ft_prepare_leadfield(cfg);   % Leads


%% Generate Covariance for Beamforming

cfg                     = [];
cfg.covariance          = 'yes';
cfg.covariancewindow    = 'all';
cfg.keeptrials          = 'yes';
cfg.vartrllength        = 2;
timelock                = ft_timelockanalysis(cfg,data);

ntrials = length(data.trial);
sz = size(timelock.cov);
loc = find(sz==ntrials);


% We want to force the covariance matrix to be 100 for some heavy blurring,
% so lets work out what lambda needs to be if mu=0.01.
tmp = squeeze(mean(timelock.cov,loc)); % ensures its averaged across repeats
lambda = 0.01*max(svd(tmp)) - min(svd(tmp));

%% Generate Beamformer weights

cfg                 = [];
cfg.method          = 'lcmv';
cfg.grid            = lf;
cfg.vol             = subvol;
cfg.keepfilter      = 'yes';
cfg.keepfilter
cfg.lcmv.fixedori   = 'yes';
cfg.lcmv.lambda     = lambda;  % Heavy regularisation to blurr data a bit
src                 = ft_sourceanalysis(cfg,timelock);

% extract the beaforming filters (weights) for next part of the script;
filters = cell2mat(src.avg.filter);
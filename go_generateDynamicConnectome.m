function cmat = go_generateDynamicConnectome(opt,filters,data)

% Set some default parameters if they have been ommitted
if ~isfield(opt,'window')
    opt.window = [];
end

opt.window.size     = ft_getopt(opt.window, 'size', 6);
opt.window.step     = ft_getopt(opt.window, 'step', 1);
opt.bpfreq          = ft_getopt(opt, 'bpfreq', data.cfg.bpfreq);
opt.trial_legnth    = ft_getopt(opt, 'trial_legnth', ...
    data.cfg.trialdef.prestim + data.cfg.trialdef.poststim);

% % If refiltering of the data is required try this here
% if sum(opt.bpfreq == data.cfg.bpfreq)~=2
%     cfg             = [];
%     cfg.bpfilter    = 'yes';
%     cfg.bpfreq      = opt.bpfreq;
%     data            = ft_preprocessing(cfg,data);
% end

% Sanity check to ensure symemtric orthogonalisation will not entirely
% collapse under window choices due to n_parcels < n_dof in single signal
% Note: this code cannot tell if MAXFILTER has been applied, to which n_dof
% should be no higher than 64
n_dof = 2 * opt.window.size * diff(opt.bpfreq);
n_parcels = setdiff(size(filters),length(data.label));
if n_parcels > n_dof
    error(['Your windows are too short, or frequency range is too ' ...
        'narrow for the number of parcellations your have, consider ' ...
        'altering these parameters.'])
end

% determine the number of individual windows per trial, this will help with
% memory allocation amongst other things!
tmp = (0+opt.window.size/2):opt.window.step:(opt.trial_legnth-opt.window.size/2);
n_windows = length(tmp);
n_trials  = length(data.trial);
n_samples = opt.window.size * data.fsample;
n_shifts  = opt.window.step * data.fsample;

% work out which sample numbers are the start and end of each window
ti = 1+(0:(n_windows-1))*n_shifts;
tf = n_samples+(0:(n_windows-1))*n_shifts;

% start building the cmat structure
cmat                    = [];
cmat.connectivity       = cell(1,n_trials);



disp('Generating connectivity matrices:')
ft_progress('init', 'text', 'Please wait...')
% loop through all trials and all windows to generate connectomes
for ii = 1:n_trials
    ft_progress(ii/n_trials, 'Processing trial %d from %d', ii, n_trials);
    
    % preallocate memory for connectome
    cmat_trial = zeros(n_parcels,n_parcels,n_windows);
    
    % generate virtual electrodes
    VE = [];
    VE.raw = filters*data.trial{ii};
    
    for jj = 1:n_windows
        % cut a window
        VE.windowed = transpose(VE.raw(:,ti(jj):tf(jj))); 
        % summetric orthogonalisation
        VE.O        = symmetric_orthogonalise(VE.windowed,1);
        % envelope generation via. hilbert transformation
        VE.H        = abs(hilbert(VE.O));
        % Generate slice of connectome
        cmat_trial(:,:,jj) = corrcoef(VE.H) - eye(n_parcels);
    end
    
    % insert trial's conenctomes into structure;
    cmat.connectivity{ii} = cmat_trial;
    
end

ft_progress('close')
disp('DONE')
% work out at what point in the trial the windows are centered over.
tmp = data.time{1};
for ii = 1:n_windows
    time(ii) = mean(tmp(ti(ii):tf(ii)));
end

% add final information
cmat.n_trials            = n_trials;
cmat.window             = opt.window;
cmat.bpfreq             = opt.bpfreq;
cmat.time               = time;
cmat.n_parcels          = n_parcels;
cmat.conn_type          = 'amplitude envelope correlation';
cmat.orthogonalisation  = 'symmetric';

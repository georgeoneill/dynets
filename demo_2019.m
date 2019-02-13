clc
close
clear variables

tmp = which('ft_defaults');
if isempty(tmp)
    % change the below line to wherever your copy of fieldtrip resides
    addpath /net/geraint/data_local/george/toolboxes/fieldtrip/;
    ft_defaults
end

subject         = { '001'; '002' ; '003' ; '004' ; '005'};

for sub_ind = 1:5
    
    files.base      = ['/data_local/george/self_paced/' subject{sub_ind} '/'];
    files.data      = [files.base '/' subject{sub_ind} '_tap_600.ds'];
    files.mri       = [files.base '/' subject{sub_ind} '_crg.mri'];
    
    if exist([files.base '/demo.mat'])
        
        % Import data, recut trials to +/- 15 seconds, filter between 4-30 Hz
        % the above cutting times are for the self paced data used in the
        % related NIMG paper, choose your own trigger and epochs as you see
        % fit
        cfg             = [];
        cfg.dataset     = files.data;
        cfg.trialdef.eventtype  = 'ButtonPress';
        cfg.trialdef.prestim    = 15;
        cfg.trialdef.poststim   = 15;
        
        cfg             = ft_definetrial(cfg);
        
        cfg.continuous  = 'yes';
        cfg.channel     = {'MEG'};
        cfg.bpfilter    = 'yes';
        cfg.bpfreq      = [4 30];
        
        data            = ft_preprocessing(cfg);
        
        % Generate the beamforming weights based on COM of Gong's AAL.
        
        filters         = go_generateAtlasFilters(data,files.mri);
        
        % Generate the connectivity tensor
        
        cfg             = [];
        cfg.window.size = 3;
        cfg.window.step = 0.25;
        cfg.bpfreq      = [4 30];
        
        cmat            = go_generateDynamicConnectome(cfg,filters,data);
        save([files.base '/demo.mat'],'cmat');
        
    end
    cmat_list{sub_ind} = [files.base '/demo.mat'];
    
end

%% Decompose the tensor

cfg             = [];
cfg.NICs        = 10;
cfg.data        = cmat_list;

results         = go_decomposeConnectome(cfg);

%% View the results!

cfg             = [];
cfg.threshold   = 0.75;
go_viewNetworkComponents(cfg,results);

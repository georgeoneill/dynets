function perms = go_testNetworks(opt,results)

opt.p                   = ft_getopt(opt,'p',0.05);
opt.bonferroni_factor   = ft_getopt(opt,'bonferroni_factor',1);
opt.n_perms             = ft_getopt(opt,'nperms',[]);

if isempty(opt.n_perms)
    n_subs = length(results.sub_trials);
    half_subs = floor(n_subs/2);
    opt.n_perms = nchoosek(n_subs,half_subs);
end

sub_trial_end = cumsum(results.sub_trials);
sub_trial_start = [0 sub_trial_end(1:end-1)]+1;

ic_3d   = results.ICA.signals;
n_subs  = length(results.sub_trials);
ic_null = zeros(results.NICs,length(results.time),opt.n_perms);

disp('Testing ICA results');
ft_progress('init', 'text', 'Please wait...')

for ii = 1:opt.n_perms
    
    scram = randperm(n_subs);
    my_trials = [];

    for jj = 1:floor(n_subs/2);
        my_trials = [my_trials sub_trial_start(scram(jj)):sub_trial_end(scram(jj))];
    end
    
    ic_flip = ic_3d;
    ic_flip(:,:,my_trials) = -ic_flip(:,:,my_trials);
    ic_null(:,:,ii) = mean(ic_flip,3);
    ft_progress(ii/opt.n_perms, 'Permutation %d of %d', ii, opt.n_perms);
    
end

perms                   = struct;
perms.p                 = opt.p;
perms.bonferroni_factor = opt.bonferroni_factor;
perms.n_perms           = opt.n_perms;

p_corr     = perms.p/perms.bonferroni_factor;
p_lower    = round(p_corr*perms.n_perms); 
p_upper    = round((1-p_corr)*perms.n_perms);

thresholds.upper = zeros(results.NICs,length(results.time));
thresholds.lower = zeros(results.NICs,length(results.time));

for ii = 1:results.NICs
    ic_ind = squeeze(ic_null(ii,:,:));
    ic_sort = sort(ic_ind','ascend');
    thresholds.lower(ii,:) = ic_sort(p_lower,:);
    thresholds.upper(ii,:) = ic_sort(p_upper,:);
end

perms.thresholds = thresholds;
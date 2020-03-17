function perms = go_testNetworks(opt,results)

opt.p                   = ft_getopt(opt,'p',0.05);
opt.test                = ft_getopt(opt,'test',2);
opt.bonferroni_factor   = ft_getopt(opt,'bonferroni_factor',1);
opt.n_perms             = ft_getopt(opt,'nperms',[]);

if isempty(opt.n_perms)
    switch opt.test
        case {1,'time'}
            opt.n_perms = 10000;
        case {2,'flip','subs'}
            n_subs = length(results.sub_trials);
            half_subs = floor(n_subs/2);
            opt.n_perms = nchoosek(n_subs,half_subs);
        otherwise
            error('invalid test type, please select 1/time or 2/flip')
    end
end

if inv(opt.p/opt.bonferroni_factor) > opt.n_perms
    warning(['Your number of permutations is too low for your selected p value: '...
        'please considering increasing for test 1 (time) or increasing number of '...
        'subjects for test 2 (flip). Permutation testing may fail this at this point forwards.'])
end

sub_trial_end = cumsum(results.sub_trials);
sub_trial_start = [0 sub_trial_end(1:end-1)]+1;

ic_3d   = results.ICA.signals;
n_subs  = length(results.sub_trials);
ic_null = zeros(results.NICs,length(results.time),opt.n_perms);

disp('Testing ICA results');
ft_progress('init', 'text', 'Please wait...')

for ii = 1:opt.n_perms
    
    switch opt.test
        case {1,'time'}
            shifters = randi(numel(results.time),results.n_trials,1);
            fake_av_mytrials = zeros(results.NICs,numel(results.time));
            for jj = 1:results.n_trials
                tmp = results.ICA.signals(:,:,jj);
                fake_av_mytrials = fake_av_mytrials + circshift(tmp,shifters(jj),2);
            end
            ic_null(:,:,ii) = fake_av_mytrials./results.n_trials;
            
        case {2,'flip','subs'}
            scram = randperm(n_subs);
            my_trials = [];
            
            for jj = 1:floor(n_subs/2);
                my_trials = [my_trials sub_trial_start(scram(jj)):sub_trial_end(scram(jj))];
            end
            
            ic_flip = ic_3d;
            ic_flip(:,:,my_trials) = -ic_flip(:,:,my_trials);
            ic_null(:,:,ii) = mean(ic_flip,3);
        otherwise
            error('invalid test type, please select 1/time or 2/flip')
    end
    ft_progress(ii/opt.n_perms, 'Permutation %d of %d', ii, opt.n_perms);
    
end

perms                   = struct;
switch opt.test
    case {1,'time'}
        perms.test = 'time lock test';
    case {2,'flip','subs'}
        perms.test = 'signal flip test';
end
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
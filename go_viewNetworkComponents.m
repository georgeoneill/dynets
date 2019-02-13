function go_viewNetworkComponents(opt,results)

% set some defaults
opt.components = ft_getopt(opt,'components',1:results.NICs);
opt.threshold  = ft_getopt(opt,'threshold',0.9);

if opt.threshold > 1 || opt.threshold < 0
    error('threhsold can only be between 0 and 1');
end

for ii = opt.components
    
    mode = results.ICA.maps(:,:,ii);
    % if the key connections are all anticorrelated, do a sign flip of the
    % map and signal
    modescale = max(abs(mode(:)));
    threshmode = mode.*(abs(mode) >= opt.threshold*modescale);
    if mean(threshmode(:)) < 0;
        flip = -1;
    else
        flip = 1;
    end
    
    
    figure(ii*10+1)
    go_netviewer(flip*mode,opt.threshold);

    figure(ii*10+2)
    IC = squeeze(results.ICA.signals(ii,:,:));
    
    plot(results.time,flip*mean(IC,2),'linewidth',2,'color','k');
    grid on
    set(gcf,'color','w')
    xlabel('time / s')
    ylabel('trial averaged IC')
    
end
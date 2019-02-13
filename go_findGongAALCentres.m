function source_id = go_findGongAALCentres(atlas,grid)

gonglabels = go_getGongLabels;

for ii = 1:length(gonglabels)
    
    label = gonglabels{ii};
    
    % find which tissue number this corresponds to in the OG AAL atlas.
    hit = 0;
    for jj = 1:length(atlas.tissuelabel)
        tmp = atlas.tissuelabel(jj);
        if  strcmp(tmp,label)
           hit = 1;
           target = jj;
        end
    end
    
    % check there was a match otherwise error. 
    if ~hit
        error('Gong parcel not found in original AAL atlas :(')
    end
    
    % Assume we passed the above sanity check, mask the grid
    % according to the parcel mask!
    cfg             = [];
    cfg.atlas       = atlas;
    cfg.roi         = atlas.tissuelabel{target};
    cfg.inputcoord  = 'mni';
    cfg.feedback    = 'no';
    mask            = ft_volumelookup(cfg,grid);
    
    % Take all the locations within that parcel and find their center of
    % mass
    candidates = find(mask==1);
    center = mean(grid.pos(candidates,:));
    
    % Work out which of the candidate locations is the nearest to COM;
    tmp = knnsearch(grid.pos(candidates,:),center);
    source_id(ii) = candidates(tmp);

   
end

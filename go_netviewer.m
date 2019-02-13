function go_marsviewer(C,thresh)

C(eye(size(C))==1) = 0;
limit = max(abs(C(:)))*thresh;
mask = abs(C) >= limit;

cLims = [-max(abs(C(:))) max(abs(C(:)))];
C(~mask) = NaN;
edgeLims = sum(~isnan(C));
sphereCols = repmat([0 0 0]/255, 78, 1);
edgeLims = [1 10];
% Set the sphere widths to 1
% sphereWidths = repmat(1,78,1);
% Set them to only visible if a node survives thersholding
sphereWidths = sum(~isnan(C))*0.5;
sphereWidths = 5*sphereWidths./max(sphereWidths(:));

load aalviewer
mnipos = aalviewer.centroids;
% figure;clf
% Plot the cortical mesh
p = patch('faces',aalviewer.faces,'vertices',aalviewer.vertices,'edgecolor','none','facecolor','k','facealpha',0.1);
hold on


cmap      = colormap(RdBu);
if cLims(1) > 0
    cmap = cmap(129:end,:);
    isSingleColour = true;
elseif cLims(2) < 0
    cmap = cmap(1:128,:);
    isSingleColour = true;
else
    
    isSingleColour = false;
end

emap = (linspace(-3,3,length(cmap))).^2;

[i,j] = find(~isnan(C));
for p=length(i):-1:1,
    colorInd(p) = closest(C(i(p),j(p)),linspace(cLims(1),cLims(2),size(cmap,1)));
end

for p=1:length(i),
    edgecolour  = cmap(colorInd(p),:);
    edgeWeight = emap(colorInd(p));
    line(mnipos([i(p) j(p)],1),mnipos([i(p) j(p)],2),mnipos([i(p) j(p)],3),'color',edgecolour,'linewidth',edgeWeight)
end


set(gca,'clim',cLims);
colormap(RdBu);
hc = colorbar;
FONTSIZE = 14;
if isSingleColour,
    YTicks = [cLims(1) cLims(2)];
else
    YTicks = [cLims(1) 0 cLims(2)];
end%if

set(hc, ...
    'FontName', 'Helvetica', ...
    'FontSize', FONTSIZE, ...
    'Box', 'on', ...
    'TickDir', 'in', ...
    'XColor', [0.3 0.3 0.3], ...
    'YColor', [0.3 0.3 0.3], ...
    'LineWidth', 2);
% YTL = get(hc,'yticklabel');
% set(hc,'yticklabel',[repmat(' ',size(YTL,1),1), YTL]);



% Plot Spheres

for ii = 1:length(aalviewer.centroids);
    [x y z] = sphere(10);
    sw = sphereWidths(ii);
    surf(sw*x+aalviewer.centroids(ii,1),sw*y+aalviewer.centroids(ii,2),sw*z+aalviewer.centroids(ii,3),'edgecolor','none','facecolor','k','facealpha',1);
end


axis vis3d
axis equal
axis off
hold off
rotate3d('on')
set(gcf,'color','w')
set(gcf,'renderer','opengl')

end

function i = closest(a,k)
%CLOSEST finds index of vector a closest to k
assert(isscalar(k) | isscalar(a));

[~,i] = min(abs(a-k));
end


function [cmap] = RdBu(varargin)

switch nargin
    case 0
        ncols = 256;
        pn = 'div';
        deep = 0;
    case 1
        ncols = varargin{1};
        pn = 'div';
        deep = 0;
    otherwise
        ncols = varargin{1};
        if sum(strcmp('type',varargin));
            pn = varargin{find(strcmp('type',varargin))+1};
        else
            pn = 'div';
        end
        if sum(strcmp('deep',varargin));
            deep = 1;
        end
end


if rem(ncols,2)~=0;
    error('Can only accept even numbers');
end

ncols = ncols./2;


% colours
lo        = [5 48 97] / 255;
bottom    = [5 113 176] / 255;
botmiddle = [146 197 222] / 255;
middle    = [247 247 247] / 255;
topmiddle = [244 165 130] / 255;
top       = [202   0  32] / 255;
hi        = [103 0 31] / 255;

% Find ratio of negative to positive
if strncmp(pn,'div',3) || strncmp(pn,'neg',3)
    
    
    % Just negative
    if deep
        neg = [lo; bottom; botmiddle; middle];
    else
        neg = [bottom; botmiddle; middle];
    end
    len = length(neg);
    oldsteps = linspace(0, 1, len);
    newsteps = linspace(0, 1, ncols);
    neg128 = zeros(ncols, 3);
    
    for i=1:3
        % Interpolate over RGB spaces of colormap
        neg128(:,i) = min(max(interp1(oldsteps, neg(:,i), newsteps)', 0), 1);
    end
    
    cmap = neg128;
    
end

if strncmp(pn,'div',3) || strncmp(pn,'pos',3)
    % Just positive
    if deep
        pos = [middle; topmiddle; top; hi];
    else
        pos = [middle; topmiddle; top];
    end
    len = length(pos);
    oldsteps = linspace(0, 1, len);
    newsteps = linspace(0, 1, ncols);
    pos128 = zeros(ncols, 3);
    
    for i=1:3
        % Interpolate over RGB spaces of colormap
        pos128(:,i) = min(max(interp1(oldsteps, pos(:,i), newsteps)', 0), 1);
    end
    cmap = pos128;
end

if strmatch(pn,'div')
    % And put 'em together
    cmap = [neg128; pos128];
end
end

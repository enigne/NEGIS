clear
close all

addpath('../../');
projectsettings;
projPath = ['/Users/chenggong/Research/', glacier, '/'];
saveflag = 1;
% load data {{{
% Obs data, already projected to the mesh
disp('Loading the Obs velocity')
obsdata = load([projPath, 'PostProcessing/Results/velObs_onmesh.mat']);
% flowline data
load([projPath, 'PostProcessing/Results/flowlines_', glacier,'_10.mat']);
% load model mesh and ice mask
org=organizer('repository', [projPath, '/Models/', mdRefFrontsFolder], 'prefix', ['Model_' glacier '_'], 'steps', [0]);
disp(['Loading model from ', mdRefFrontsFolder]);
md = loadmodel(org, [stepName]);
%}}}
% data processing {{{
icemask = cell2mat({md.results.TransientSolution(:).MaskIceLevelset});
time = cell2mat({md.results.TransientSolution(:).time});
nFlowline = length(flowlineList);
nTime = length(time);
vel_onmesh = obsdata.vel_onmesh;
% find mid time points
obstime = (obsdata.TStart+obsdata.TEnd).*0.5;
[time_uni, ia, ic] = unique(obstime, 'stable');
% Take unique
vel_uni = vel_onmesh(:,ia);

% find the repeat time points
for i =1:length(ia)
	rid{i} = find(ic == (i));
	% overwrite with mean
	if length(rid{i}) > 1
		disp([' Take the mean of time points at ', num2str(rid{i}')])
		vel_uni(:, i) = mean(vel_onmesh(:, rid{i}), 2, 'omitnan');
	end
end
% sort
[obstime_sort, ind] = sort(time_uni);
vel_sort = vel_uni(:,ind);

%}}}
% Get front positions for each flowline {{{
positionx = zeros(nTime, nFlowline);
positiony = zeros(nTime, nFlowline);
for i = 1: nFlowline
	icemaskFL = InterpFromMeshToMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,icemask,flowlineList{i}.x,flowlineList{i}.y);
	% solve for the calving front coordinates
	cf = interpZeroPos([flowlineList{i}.Xmain(:), flowlineList{i}.x, flowlineList{i}.y], icemaskFL);
	positionx(:,i) = cf(:, 2);
	positiony(:,i) = cf(:, 3);
end
% try to interpolate according to the time of obs 
positionx_obsT = interp1(time, positionx,obstime_sort,'linear','extrap');
positiony_obsT = interp1(time, positiony,obstime_sort,'linear','extrap');
%}}}
% velocity{{{
vel = zeros(size(positionx_obsT));
for i = 1:length(obstime_sort)
	vel(i,:) = InterpFromMeshToMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,vel_sort(:,i), positionx_obsT(i,:), positiony_obsT(i,:));
end
meanvel = mean(vel', 'omitnan');

% clean up the data with more than 90% nan
width = 2;
flagNan = isnan(vel);
totalNan = sum(flagNan,2);
centralNan = sum(flagNan(:, width:nFlowline-width+1), 2);

% remove if max(vel)<4000
nanMask = ((max(vel')>4000) & (meanvel>4000));
% also remove data with no coverage in the central area
time_FObs = obstime_sort(nanMask);
meanvel_FObs = meanvel(nanMask);

plot(time_FObs, meanvel_FObs, 'o');
%}}}
% save{{{
if saveflag
	save([projPath, 'PostProcessing/Results/frontalObs_new.mat'], 'time_FObs', 'meanvel_FObs');
end
%}}}

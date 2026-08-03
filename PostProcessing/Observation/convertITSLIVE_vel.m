clear
close all

addpath('../../');
projectsettings;
projPath = ['/Users/chenggong/Research/', glacier, '/'];
saveflag = 1;
yearly = 0;
% load data {{{
% load model mesh and ice mask
org=organizer('repository', [projPath, '/Models/', mdRefFrontsFolder], 'prefix', ['Model_' glacier '_'], 'steps', [0]);
disp(['Loading model from ', mdRefFrontsFolder]);
md = loadmodel(org, [stepName]);
% flowline data
load([projPath, 'PostProcessing/Results/flowlines_', glacier,'_25.mat']);
% ITS_LIVE
if yearly
	disp('Loading the ITS_LIVE yearly velocity')
	[vx_obs, vy_obs, time] = interpFromITSLIVE(md.mesh.x, md.mesh.y, md.timestepping.start_time, md.timestepping.final_time, 'folder', '/Users/chenggong/ModelData/');
else
	disp('Loading the ITS_LIVE monthly averaged velocity Mosaic')
	obsData = interpFromMEaSUREsGeotiff(md.mesh.x,md.mesh.y, md.timestepping.start_time, md.timestepping.final_time, 'glacier', 'Greenland',  'folder','/Users/chenggong/ModelData/');
	vx_obs = [obsData.vx];
	vy_obs = [obsData.vy];
	time = 0.5*([obsData.Tstart] + [obsData.Tend]);
end
vel_obs = sqrt(vx_obs.^2 + vy_obs.^2);
nTime = numel(time);
%}}}
%% save the time series of the whole domain {{{
if saveflag
	if yearly
		save([projPath, 'PostProcessing/Results/timeSeries_Obs_ITSLIVE.mat'], 'time', 'vx_obs', 'vy_obs', 'vel_obs');
	else
		save([projPath, 'PostProcessing/Results/timeSeries_Obs_monthly.mat'], 'time', 'vx_obs', 'vy_obs', 'vel_obs');
	end
end %}}}
% data process {{{
md_time = cell2mat({md.results.TransientSolution(:).time});
icemask = double(cell2mat({md.results.TransientSolution(:).MaskIceLevelset})<0);
nFlowline = length(flowlineList);

md_mean_mask = zeros(size(vel_obs));
md_mean_ice_levelset = zeros(size(vel_obs));
for i = 1:nTime
	tId = find((md_time>=time(i)) & (md_time<time(i)+1));
	md_mean_mask(:, i) = mean(icemask(:,tId), 2);
	md_mean_ice_levelset(:,i) = reinitializelevelset(md, (0.8 - md_mean_mask(:,i)));
end
%}}}
% Get front positions for each flowline {{{
positionx = zeros(nTime, nFlowline);
positiony = zeros(nTime, nFlowline);
for i = 1: nFlowline
	icemaskFL = InterpFromMeshToMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,md_mean_ice_levelset,flowlineList{i}.x,flowlineList{i}.y);
	% solve for the calving front coordinates
	cf = interpZeroPos([flowlineList{i}.Xmain(:), flowlineList{i}.x, flowlineList{i}.y], icemaskFL);
	positionx(:,i) = cf(:, 2);
	positiony(:,i) = cf(:, 3);
end
%}}}
% yearly average frontal velocity{{{
vel = zeros(size(positionx));
for i = 1:nTime
	vel(i,:) = InterpFromMeshToMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y, vel_obs(:,i), positionx(i,:), positiony(i,:));
end
year = time;
meanvel = mean(vel', 'omitnan');
%}}}
% save frontal data{{{
if saveflag
	if yearly
		save([projPath, 'PostProcessing/Results/frontalObs_ITSLIVE.mat'], 'year', 'meanvel');
	else
		save([projPath, 'PostProcessing/Results/frontalObs_monthly.mat'], 'year', 'meanvel');
	end
end
%}}}

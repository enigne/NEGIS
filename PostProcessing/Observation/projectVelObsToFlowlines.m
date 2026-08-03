clear
close all

addpath('../../');
projectsettings;
projPath = ['/Users/chenggong/Research/', glacier, '/'];
saveflag = 1;
yearly = 1;
nFlowline = 25;
% load data {{{
% load model mesh and ice mask
org=organizer('repository', [projPath, '/Models/', mdRefFrontsFolder], 'prefix', ['Model_' glacier '_'], 'steps', [0]);
disp(['Loading model from ', mdRefFrontsFolder]);
md = loadmodel(org, [stepName]);
% flowline data
load([projPath, 'PostProcessing/Results/flowlines_', glacier,'_' num2str(nFlowline), '.mat']);
% ITS_LIVE
if yearly
   timestring = 'Yearly';
	disp('Loading the ITS_LIVE yearly velocity')
else
   timestring = 'Monthly';
	disp('Loading the ITS_LIVE monthly averaged velocity Mosaic')
end
datafile = [projPath,'PostProcessing/Results/velObs_MEaSUREs_', timestring, '_Mosaic_onmesh.mat'];
load(datafile);
time = 0.5*(TStart + TEnd);
nTime = numel(time);
%}}}
% Process data {{{
% take the Greene Front 
monthly_icemask = md.levelset.spclevelset(1:end-1,:);
mtime = md.levelset.spclevelset(end,:);
% average to monthly or yearly if there is more than one data
mean_ice_levelset = zeros(size(vel_onmesh));
for i = 1:nTime
   tId = find((mtime>=TStart(i)) & (mtime<=TEnd(i)));
   meanmask = mean(monthly_icemask(:,tId), 2);
   mean_ice_levelset(:,i) = reinitializelevelset(md, meanmask);
end
% project mask, ice velocity along the flowlines
%}}}
% Get front positions for each flowline {{{
% create a new grid from 100km upstream to -1km downstrem, relative to the ice front, dx=50m
Xdist = linspace(-100e3, 1e3, floor(101e3/50));
dataFL_all = projectSolutionsToFlowlines(md, flowlineList, mean_ice_levelset, time, Xdist, vel_onmesh);
%}}}
% save {{{
if saveflag
	vel_obs = dataFL_all;
	save([projPath, 'PostProcessing/Results/flowlines_Obs_', timestring, '.mat'], 'time', 'Xdist', 'vel_obs');
end
%}}}

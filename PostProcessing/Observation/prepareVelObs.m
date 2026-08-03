% To prepare velocity observations 
% project the velocity obs from netCDF data to the 2D mesh by ISSM
% Last modified: 2026-07-29

clear
close all
% Settings {{{
tstart = 2007;
tend = 2022;
saveflag = 1;
reloadGeotiff = 1;
addpath('../../')
projectsettings;
%}}}
% Load data {{{
projPath = ['/Users/chenggong/Research/', glacier, '/'];
% model
steps = 0;
folder = [projPath, 'Models/'];
stepName = 'Param_ISMIP'; % This will be used for the initial condition only
org = organizer('repository', folder, 'prefix', ['Model_' glacier '_'], 'steps', steps);
md = loadmodel(org, stepName);
% vel obs
if reloadGeotiff 
	obsData = interpFromMEaSUREsGeotiff(md.mesh.x,md.mesh.y, tstart, tend, 'glacier', 'Greenland',  'folder','/Users/chenggong/ModelData/');
	disp(['  Save obs to ', projPath, 'DATA/VelObs.mat']);
	save([projPath, 'DATA/VelObs.mat'], 'obsData');
else
	disp(['  Load obs from ', projPath, 'DATA/VelObs.mat']);
	load([projPath, 'DATA/VelObs.mat']);
end
% put data into places
vxdata = cell2mat({obsData.vx});
vydata = cell2mat({obsData.vy});
veldata = cell2mat({obsData.vel});
Tstartdata = cell2mat({obsData.Tstart});
Tenddata = cell2mat({obsData.Tend});
%}}}
% Clean up, sort {{{
% less than 10% coverage data points
cFlag = (sum(~isnan(veldata))>0.1*md.mesh.numberofvertices);
disp(['  remove data has less than 10% coverage']);
% apply the filter
Tstartdata = Tstartdata(cFlag);
Tenddata = Tenddata(cFlag);
veldata = veldata(:,cFlag);
vxdata = vxdata(:,cFlag);
vydata = vydata(:,cFlag);
%}}}
% find unique and sort by the mean time {{{
[C, ia, ic] = unique(Tstartdata+Tenddata, 'sorted');
TStart = Tstartdata(ia);
TEnd = Tenddata(ia);

vx_onmesh = zeros([size(vxdata,1),length(C)]);
vy_onmesh = zeros([size(vydata,1),length(C)]);
vel_onmesh = zeros([size(veldata,1),length(C)]);

% average 
disp(['  Before sorting: ', num2str(length(TStart)), ' sets']);
for i = 1: length(C)
	ids = find(ic == i); 
	vx_onmesh(:,i) = mean(double(vxdata(:,ids)), 2, 'omitnan');
	vy_onmesh(:,i) = mean(double(vydata(:,ids)), 2, 'omitnan');
	vel_onmesh(:,i) = mean(double(veldata(:,ids)), 2, 'omitnan');
end
disp(['  After sorting: ', num2str(length(C)), ' sets']);
%}}}
% add initialization {{{
if TStart(1) > tstart 
	disp('Add the initial condition of the model as the first time step of the obs');
	TStart = [tstart, TStart];
	TEnd = [tstart, TEnd];
	vx_onmesh = [md.initialization.vx, vx_onmesh];
	vy_onmesh = [md.initialization.vy, vy_onmesh];
	vel_onmesh = [md.initialization.vel, vel_onmesh];
end
%}}}
%% save the data {{{
if saveflag
	savefile = [projPath,'PostProcessing/Results/velObs_onmesh.mat'];
	disp(['Save to ', savefile]);
	save(savefile, 'TStart', 'TEnd', 'vel_onmesh', 'vx_onmesh',  'vy_onmesh');
end
%}}}

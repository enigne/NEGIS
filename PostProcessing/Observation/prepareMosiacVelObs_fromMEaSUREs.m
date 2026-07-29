% To prepare velocity observations: from MEaSUREs monthly/yearly averaged velocity Mosaic
% project the velocity obs from netCDF data to the 2D mesh by ISSM
% Last modified: 2026-07-29

clear
close all
% Settings {{{
tstart = 2007;
tend = 2022;
saveflag = 1;
reloadData = 1;
yearly = 1;
addpath('../../')
projectsettings;
%}}}
% Load data {{{
projPath = ['/Users/chenggong/Research/', glacier, '/'];
if yearly
	timestring = 'Yearly';
else
	timestring = 'Monthly';
end
% model
steps = 0;
folder = [projPath, 'Models/'];
stepName = 'Param_ISMIP'; % This will be used for the initial condition only
org = organizer('repository', folder, 'prefix', ['Model_' glacier '_'], 'steps', steps);
md = loadmodel(org, stepName);
% vel obs
if reloadData 
	if yearly
		[vx_obs, vy_obs, time] = interpFromITSLIVE(md.mesh.x, md.mesh.y, tstart, tend, 'folder','/Users/chenggong/ModelData/');
		obsData.vx = vx_obs;
		obsData.vy = vy_obs;
		obsData.vel = sqrt(vx_obs.^2+vy_obs.^2);
		obsData.Tstart = time;
		obsData.Tend = time+1;
	else
		obsData = interpFromMEaSUREsGeotiff(md.mesh.x,md.mesh.y, tstart, tend, 'glacier', 'Greenland');
	end
	disp(['  Save obs to ', projPath, 'DATA/VelObs_', timestring, 'Mosaic.mat']);
	save([projPath, 'DATA/VelObs_' timestring, 'Mosaic.mat'], 'obsData');
else
	disp(['  Load obs from ', projPath, 'DATA/VelObs_' timestring, 'Mosaic.mat']);
	load([projPath, 'DATA/VelObs_' timestring, 'Mosaic.mat'], 'obsData');
end

return
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
disp(['  remove ', num2str(sum(cFlag==0)), ' data from total ', num2str(numel(cFlag)), ', which has less than 10% coverage']);
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
%% save the data {{{
if saveflag
	savefile = [projPath,'PostProcessing/Results/velObs_MEaSUREs_', timestring, '_Mosaic_onmesh.mat'];
	disp(['Save to ', savefile]);
	save(savefile, 'TStart', 'TEnd', 'vel_onmesh', 'vx_onmesh',  'vy_onmesh');
end
%}}}

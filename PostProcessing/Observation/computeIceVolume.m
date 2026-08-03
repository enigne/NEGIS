% prepare ice volume changes, from ICESat2 and Abbas' dHdt map
% Last modified: 2026-08-03
clear
close all

addpath('../../');
projectsettings;
projPath = ['/Users/chenggong/Research/', glacier, '/'];
saveflag = 1;
% load model {{{
org=organizer('repository', [projPath, '/Models/', mdRefFrontsFolder], 'prefix', ['Model_' glacier '_'], 'steps', [0]);
disp(['Loading model from ', mdRefFrontsFolder]);
md = loadmodel(org, [stepName]);
time = cell2mat({md.results.TransientSolution(:).time});
icemask = cell2mat({md.results.TransientSolution(:).MaskIceLevelset});
H = cell2mat({md.results.TransientSolution(:).Thickness});
%}}}
% Load ICESat2 data{{{
%s_IS2 = interpICESat2ATL1415(md.mesh.x, md.mesh.y);
%H_IS2 = s_IS2(1:end-1,:) - md.geometry.bed;
%ICESat2Time =  s_IS2(end,:);
%% find the time steps for each of the H obs
%[~, solTid]= min(abs(ICESat2Time-time'));
%% find the minimal mask from ICESat data that all the data is fully covered with ice
%% compute the total ice volume according to that mask
%mask_model = sum(icemask(:,solTid)>0, 2)>0;
%mask_IS2 = sum(isnan(H_IS2),2)>0;
%ICESat2Mask = (mask_model + mask_IS2)>0;
%% compute ICESat2 ice volume
%ICESat2_Iv = integrateOverDomain(md, H_IS2, ICESat2Mask)/1e9;
%% compute model ice volume on the same mask
%ref_model_Iv = integrateOverDomain(md, H, ICESat2Mask)/1e9;
%}}}
% interp dHdt {{{
dH = interpdH(md.mesh.x, md.mesh.y, [md.timestepping.start_time, md.timestepping.final_time], '/Users/chenggong/ModelData/Greenland/DHKhan/Greenland_dhdt_icevol_1kmgrid_DB.nc');
dHTime = dH(end,:);
H_dH = cumsum(dH(1:end-1,:), 2);
% same as ICESat2 data, find the mask
[~, solTid] = min(abs(dHTime - time'));
mask_model = sum(icemask(:,solTid)>0, 2)>0;
mask_dH = sum(isnan(H_dH),2)>0;
dHMask = (mask_model + mask_dH)>0;
% compute ice volume changes from dH/dt map
dH_Iv = integrateOverDomain(md, H_dH, dHMask)/1e9;
%% compute model ice volume on the same mask
ref_model_Iv = integrateOverDomain(md, H, dHMask)/1e9;
% }}}
figure('Position', [0,800,800,800])
%subplot(2,1,1)
%plot(time, ref_model_Iv)
%hold on
%plot(ICESat2Time, ICESat2_Iv, 'o')
%xlim([2007,2024])
%ylabel('Total Ice volume (km^3)')
%xlabel('year')
%legend('model', 'ICESat2')

subplot(2,1,2)
plot(time, ref_model_Iv-ref_model_Iv(1))
hold on
%plot(ICESat2Time, ICESat2_Iv-ref_model_Iv(1),'o')
plot(dHTime, dH_Iv-dH_Iv(1))
xlim([2007,2022])
%ylim([-120,10])
legend({'model', 'Abbas dH/dt'}, 'Location','best')
ylabel('km^3')
xlabel('year')

if saveflag
%	save([projPath, '/PostProcessing/Results/ICESat2_IceVolume.mat'], 'time', 'ref_model_Iv', 'ICESat2Time', 'ICESat2_Iv',  'ICESat2Mask')
	save([projPath, '/PostProcessing/Results/dHdt_IceVolume.mat'], 'dHTime', 'dH_Iv')
end

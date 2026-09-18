clear
close all

addpath('../../')
projectsettings;
projPath = ['/Users/chenggong/Research/', glacier, '/'];
figNamePrefix = [projPath, 'PostProcessing/Figures/test_'];

Id = 0; % Latest experiments

% some detailed settings
addITS_LIVE = 1; % add ITS_LIVE yearly velocity
adddH_Abbas = 1; % add ITS_LIVE yearly velocity
addObsVel = 0 ; % add obs frontal velocity in the velocity plot, not implemented
startTime = 2011;
finalTime = 2022;
dt = 0.01;
output_frequency = 10;
yearNt = 1/dt/output_frequency;
%% Load data {{{
addpath([projPath, '/PostProcessing/']);
[folderList, nameList] = getFolderList(Id);

% Load simulations from transient.mat
transData = loadData(folderList, 'transient', [projPath, 'Models/']);
Ntrans = length(transData);
nsub = 3;
yearN = 1/dt/output_frequency;

colorList = {'#377eb8', '#ff7f00', '#4daf4a', '#f781bf', '#a65628', '#984ea3', '#999999', '#e41a1c', '#dede00'};
Ngroup = 3;
styleList = {'--','-', ':', '-.'};
gcolor = '#e41a1c';

% Load flowlines
load([projPath, 'PostProcessing/Results/flowlines_',glacier,'_25.mat']);

% yearly averaged velocity front ITS_LIVE
if addITS_LIVE
	yearly = load([projPath, 'PostProcessing/Results/frontalObs_ITSLIVE.mat']);
	monthly = load([projPath, 'PostProcessing/Results/flowlines_Obs_Monthly.mat']);
end

% compare with dHdt map from Khan 2025
if adddH_Abbas
	dHdt = load([projPath, 'PostProcessing/Results/dHdt_IceVolume.mat']);
end
%}}}
%% Average behaviors {{{
figure('position',[0,500,800,1000])

for i = 1: Ntrans
	% ice volume
	subplot(nsub,1,1)
	plot(transData{i}.time, (transData{i}.icevolume-transData{1}.icevolume(1))./1e9, 'LineWidth', 2, ...
		'color', colorList{mod(i, Ngroup)+1}, 'Linestyle', styleList{ceil(i/Ngroup)});
	hold on
	xlim([2007, finalTime])
	ylim([-200,50])
	title('Ice volume (km^3)')
end
subplot(nsub, 1, 1);
plot(dHdt.dHTime, dHdt.dH_Iv, 'color', [0.5,0.5,0.5], 'LineWidth',1.5)
legend([nameList, 'Khan2025'], 'Interpreter', 'latex', 'location','best')
%}}}
%% averaged along all flowlines {{{
Nf =  length(flowlineList);
for i = 1: Ntrans
   time = transData{i}.time;
   CF = zeros(size(transData{i}.flowlines{1}.calvingFront(:, 1)));
   vel = zeros(size(transData{i}.flowlines{1}.vel));

   for j = 1:Nf
      % calving front
      CF = CF + transData{i}.flowlines{j}.calvingFront(:, 1);
      % velocity
      vel = vel + transData{i}.flowlines{j}.vel;
   end

   subplot(nsub, 1, 2);
   mmv = movmean(vel./Nf, (yearNt/12)); % monthly moving average
   plot(time, mmv, 'LineWidth', 2, ...
		'color', colorList{mod(i, Ngroup)+1}, 'Linestyle', styleList{ceil(i/Ngroup)});
   hold on

   subplot(nsub, 1, 3);
   mmv = movmean(vel./Nf, (yearNt)); % yearly moving average
   plot(time, mmv, 'LineWidth', 2, ...
		'color', colorList{mod(i, Ngroup)+1}, 'Linestyle', styleList{ceil(i/Ngroup)});
   hold on
end

subplot(nsub, 1, 2);
if addITS_LIVE
	[~, mid] = min(abs(monthly.Xdist(:)));
	m_vel =  squeeze(mean(monthly.vel_obs(:,:,mid)));
   plot(monthly.time, m_vel, '.', 'MarkerSize', 15, 'color', gcolor);
end
title('Monthly averaged velocity')
xlim([startTime, finalTime])
ylim([0, 2000]);

subplot(nsub, 1, 3);
if addITS_LIVE
   plot(yearly.year, yearly.meanvel, '.', 'MarkerSize', 15, 'color', gcolor);
end
title('Yearly averaged velocity')
xlim([startTime, finalTime])
ylim([0, 2000]);

set(gcf,'color','w');
%}}}

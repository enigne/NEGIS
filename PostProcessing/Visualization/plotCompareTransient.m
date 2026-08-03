clear
close all

addpath('../../')
projectsettings;
projPath = ['/Users/chenggong/Research/', glacier, '/'];
figNamePrefix = [projPath, 'PostProcessing/Figures/test_'];

addObsVel = 1 ; % add obs frontal velocity in the velocity plot
addITS_LIVE = 1; % add ITS_LIVE yearly velocity
startTime = 2011;
finalTime = 2022;
dt = 0.01;
output_frequency = 10;

yearNt = 1/dt/output_frequency;

Id = 0; % Latest experiments
%% Load data {{{
addpath([projPath, '/PostProcessing/']);
[folderList, nameList] = getFolderList(Id);

% Load simulations from transient.mat
transData = loadData(folderList, 'transient', [projPath, 'Models/']);
Ntrans = length(transData);
nsub = 4;
yearN = 1/dt/output_frequency;

colorList = {'#377eb8', '#ff7f00', '#4daf4a', '#f781bf', '#a65628', '#984ea3', '#999999', '#e41a1c', '#dede00'};
Nsmb = 2;
styleList = {'-','--', ':', '-.'};
gcolor = '#e41a1c';

% Load flowlines
load([projPath, 'PostProcessing/Results/flowlines_',glacier,'_25.mat']);

% load frontal obs
if addObsVel
	%load([projPath, 'PostProcessing/Results/frontalObs.mat']);
	load([projPath, 'PostProcessing/Results/frontalObs_new.mat']);
end
% yearly averaged velocity front ITS_LIVE
if addITS_LIVE
	yearly = load([projPath, 'PostProcessing/Results/frontalObs_ITSLIVE.mat']);
	monthly = load([projPath, 'PostProcessing/Results/frontalObs_monthly.mat']);
end
%}}}
%% Average behaviors {{{
figure('position',[0,500,800,1000])

for i = 1: Ntrans
	% ice volume
	subplot(nsub,1,1)
	plot(transData{i}.time, (transData{i}.icevolume-transData{1}.icevolume(1))./1e9, 'LineWidth', 2);
	hold on
	xlim([2007, finalTime])
	ylim([-100,50])
	title('Ice volume (km^3)')
end
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
   plot(time, vel./Nf, 'LineWidth', 2, ...
      'color', colorList{ceil(i/Nsmb)}, 'Linestyle', styleList{mod(i,Nsmb)+1});
   hold on

   subplot(nsub, 1, 4);
   mmv = movmean(vel./Nf, (yearNt)); % yearly moving average
   plot(time, mmv, 'LineWidth', 2, ...
      'color', colorList{ceil(i/Nsmb)}, 'Linestyle', styleList{mod(i,Nsmb)+1});
   hold on

   subplot(nsub, 1, 3);
   mmv = movmean(vel./Nf, (yearNt/12)); % monthly moving average
   plot(time, mmv, 'LineWidth', 2, ...
      'color', colorList{ceil(i/Nsmb)}, 'Linestyle', styleList{mod(i,Nsmb)+1});
   hold on
end

subplot(nsub, 1, 2);
if addObsVel
   plot(time_FObs, meanvel_FObs, '.', 'MarkerSize', 15, 'color', gcolor);
end
title('Mean frontal velocity (m/a)')
xlim([startTime, finalTime])
ylim([0, 2000]);

subplot(nsub, 1, 4);
if addITS_LIVE
   plot(yearly.year, yearly.meanvel, '.', 'MarkerSize', 15, 'color', gcolor);
end
title('Yearly averaged velocity')
xlim([startTime, finalTime])
ylim([0, 2000]);
subplot(nsub, 1, 3);
if addITS_LIVE
   plot(monthly.year, monthly.meanvel, '.', 'MarkerSize', 15, 'color', gcolor);
end
title('Monthly averaged velocity')
xlim([startTime, finalTime])
ylim([0, 2000]);

set(gcf,'color','w');
%}}}

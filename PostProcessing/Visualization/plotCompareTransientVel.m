clear
close all

Id = 0; % Latest experiments
Xs = [-50e3 -10e3, -5000, 0];
%% Load data {{{
startTime = 2007;
finalTime = 2022;
dt = 0.01;
output_frequency = 10;
yearNt = 1/dt/output_frequency;
addpath('../../')
projectsettings;
projPath = ['/Users/chenggong/Research/', glacier, '/'];
addpath([projPath, '/PostProcessing/']);
[folderList, nameList] = getFolderList(Id);

% Load simulations from transient.mat
transData = loadData(folderList, 'transient', [projPath, 'Models/']);
NFigures = length(transData);

% Load flowlines
load([projPath, 'PostProcessing/Results/flowlines_',glacier,'_25.mat']);

% yearly averaged velocity front ITS_LIVE
yearly = load([projPath, 'PostProcessing/Results/flowlines_Obs_Yearly.mat']);
monthly = load([projPath, 'PostProcessing/Results/flowlines_Obs_Monthly.mat']);
[~, yid] = min(abs(yearly.Xdist(:) - Xs));
y_vel =  squeeze(mean(yearly.vel_obs(:,:,yid)));
[~, mid] = min(abs(monthly.Xdist(:) - Xs));
m_vel =  squeeze(mean(monthly.vel_obs(:,:,mid)));

% colormap
cmap = lines(numel(Xs));
%}}}
%% plot solutions {{{
nsub = 3;
for i = 1:NFigures
	disp(['==> Plotting for ', transData{i}.name])
	% get vel data
	time = transData{i}.time;
	[~,id] = min(abs(transData{i}.Xdist(:) - Xs));
	vel =  transData{i}.velFL(:,id);


	% plot
	figure('position',[0,500,800,1000], 'NumberTitle', 'off', 'Name', transData{i}.name)
	for j = 1:numel(Xs)
		% model velocity on model time
		subplot(nsub, 1, 1)
		plot(time, vel(:,j), 'LineWidth', 2, 'color', cmap(j,:));
		hold on

		% monthly average
		subplot(nsub, 1, 2)
		mmv = movmean(vel(:,j), (yearNt/12)); % monthly moving average
		plot(time, mmv, 'LineWidth', 2, 'color', cmap(j,:));
		hold on
		plot(monthly.time, m_vel(:,j), '*', 'MarkerSize', 8, 'color', cmap(j,:))

		% yearly average
		subplot(nsub, 1, 3)
		ymv = movmean(vel(:,j), (yearNt)); % yearly moving average
		plot(time, ymv, 'LineWidth', 2, 'color', cmap(j,:));
		hold on
		plot(yearly.time, y_vel(:,j), '*', 'MarkerSize', 8, 'color', cmap(j,:))
	end
	subplot(nsub, 1, 1);
	title('Ice velocity')
	xlim([startTime, finalTime])
	ylim([500, 1800]);
	nameList = arrayfun(@(x) sprintf('Distance to front: %d km',x/1e3), -Xs, 'UniformOutput', false);
	legend(nameList, 'Interpreter', 'latex', 'location','best')

	subplot(nsub, 1, 2);
	title('Monthly averaged velocity')
	xlim([startTime, finalTime])
	ylim([500, 1800]);

	subplot(nsub, 1, 3);
	title('Yearly averaged velocity')
	xlim([startTime, finalTime])
	ylim([500, 1800]);

	set(gcf,'color','w');
end
%}}}

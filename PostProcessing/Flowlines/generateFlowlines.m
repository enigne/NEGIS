clear
close all

% Settings {{{
addpath('../../')
projectsettings;
Nf = 25;
saveflag = 1;
plotflag = 1;
%}}}
%% Load model {{{
steps = 0;
projPath = ['/Users/chenggong/Research/', glacier, '/'];
org=organizer('repository', [projPath, '/Models/'], 'prefix', ['Model_' glacier '_'], 'steps', steps);
md = loadmodel(org, refmdName);
%}}}
%% create flowlines {{{
xmin = 385100; ymin = -1201500;
xmax = 507800; ymax = -990500;

if plotflag
	figure
	plotmodel(md, 'data', md.initialization.vel,...
		'mask', (md.mask.ice_levelset<1), ...
		'xlim', [xmin xmax], 'ylim', [ymin ymax], 'caxis', [0,2000])
	hold on
end
% northern and southern part of the glacier
x = md.mesh.x;
y = md.mesh.y;
u = md.initialization.vx;
v = md.initialization.vy;
index = md.mesh.elements;
% pick the seeds
x1 = linspace(435743.5206869633, 447273.5753317721, Nf);
y1 = linspace(-1069151.4441842311, -1076728.3372365339, Nf);

x2 = linspace(478240.0078064012, 488122.9117876659, Nf);
y2 = linspace(-1096164.7150663545, -1109341.9203747073, Nf);

x0 = [x1, x2];
y0 = [y1, y2];

fnameList = strcat('F', cellstr(num2str([1:length(x0)]')));
% fnameList(1:3) = {'N', 'C', 'S'};
flowlineList = cell(length(x0), 1);
ticks = 80;
% compute the flowline
for i = 1: length(x0)
	% get the flowline
	flowlineList{i} =flowlines(index,x,y,u,v,x0(i),y0(i));
	% remove duplicate points
	[~,ia,~] = unique([flowlineList{i}.x,flowlineList{i}.y],'rows', 'stable');
	flowlineList{i}.x = flowlineList{i}.x(ia);
	flowlineList{i}.y = flowlineList{i}.y(ia);
	% get the distance along the flowline
	flowlineList{i}.Xmain = cumsum([0;sqrt((flowlineList{i}.x(2:end)- flowlineList{i}.x(1:end-1)).^2 + (flowlineList{i}.y(2:end)- flowlineList{i}.y(1:end-1)).^2)]')/1000;
	% get the distance along the flowline from the calving front side
	flowlineList{i}.Xmain_calving = flowlineList{i}.Xmain + (100- flowlineList{i}.Xmain(end));
	% bedrock elevation along the flowline
	flowlineList{i}.bed = InterpFromMeshToMesh2d(md.mesh.elements,md.mesh.x,md.mesh.y,md.geometry.bed,flowlineList{i}.x,flowlineList{i}.y);
	% name
	flowlineList{i}.name = fnameList{i};
	% To visualize the flowlines
	[~,I] = min(abs(flowlineList{i}.Xmain-ticks));
	if plotflag
		plot(flowlineList{i}.x, flowlineList{i}.y, 'Linewidth', 1.5);
		plot(flowlineList{i}.x(I), flowlineList{i}.y(I), 'ko', 'Linewidth', 1.5);
	end
end

if plotflag
	hold on
	plot(x0, y0, '*')
end
%}}}
%% Save data{{{
if saveflag
	save([projPath, 'PostProcessing/Results/flowlines_', glacier, '_', num2str(Nf), '.mat'], 'x0', 'y0', 'flowlineList');
end
%}}}
%%
if plotflag
	figure
	for i = 1: length(x0)
		plot(flowlineList{i}.Xmain, flowlineList{i}.bed);
		hold on
	end
	xlim([72, 95])
end

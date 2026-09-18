clear
close all
addpath('../');
projectsettings;

glacier = 'NEGIS';
downloadData = 0;
extraPostProc = 1; % set 0 for AD exps
saveflag = 1;
stepName = 'Transient';
% Setting {{{ 
addpath('./');
projPath = ['/Users/chenggong/Research/', glacier, '/'];
steps = [1];
%}}}
% Loading models {{{
[folderList, dataNameList] = getFolderList();
Ndata = length(folderList);
for i = 1:Ndata
	org{i}=organizer('repository', [projPath, 'Models/', folderList{i}], 'prefix', ['Model_' glacier '_'], 'steps', steps);
end

if downloadData  
	% Discovery has limit on max number of connect, so download using serial for-loop
	for i = 1:Ndata
		disp(['---- Downloading the model to ', folderList{i}]);
		if perform(org{i}, ['Transient_Download'])
			mdList{i} = loadmodel(org{i}, [stepName]);

%			mdList{i}.cluster = discovery('numnodes',1,'cpuspernode',1);
			savePath = mdList{i}.miscellaneous.name;

			% download model
			disp(['Downloadng ', savePath, ' from ', mdList{1}.cluster.name])
			mdList{i} = loadresultsfromcluster(mdList{i},'runtimename', savePath);
		end
	end
	parfor i = 1:Ndata
		disp(['Save model to ', mdList{i}.miscellaneous.name])
		% save model
		savemodel(org{i}, mdList{i});
		if ~strcmp(mdList{i}.miscellaneous.name, './')
			system(['mv ', projPath,'/Models/', mdList{i}.miscellaneous.name, '/Model_',glacier,'_Transient_Download.mat ', projPath, '/Models/', mdList{i}.miscellaneous.name, '/Model_', glacier, '_', stepName, '.mat']);
		end
	end 
else
	parfor i = 1:Ndata
		disp(['---- Loading the model from ', folderList{i}]);
		mdList{i} = loadmodel(org{i}, [stepName]);
	end
end
%}}}
if extraPostProc %{{{
	% Load flowlines {{{
	load([projPath, 'PostProcessing/Results/flowlines_',glacier,'_25.mat']);
	%}}}
	% load obs data {{{
	load([projPath, 'PostProcessing/Results/velObs_onmesh.mat']);
	%}}}
	% postProcessing {{{
	parfor i = 1:Ndata
	extractTransientFromMd(mdList{i}, projPath, folderList{i}, dataNameList{i}, flowlineList, saveflag, vel_onmesh, TStart, TEnd);
end
%}}}
end %}}}

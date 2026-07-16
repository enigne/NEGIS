function varargout=runme(varargin)

	%Check inputs {{{
	if nargout>1
		help runme
		error('runme error message: bad usage');
	end
	%recover options
	options=pairoptions(varargin{:});
	% }}}
	%GET cluster name: totten{{{
	clustername = getfieldvalue(options,'cluster name','totten');
	% }}}
	%GET steps {{{
	steps = getfieldvalue(options,'steps',[1]);
	% }}}
	%GET Friction type: 'Schoof' {{{
	friction = getfieldvalue(options,'friction','Schoof');
	if ~ismember(friction,{'Schoof','Weertman','Budd'})
		disp('runme warning: friction law not supported, defaulting to use ''Schoof law''')
		friction = 'Schoof';
	end
	flagFriction = 0; % 0-by default,schoof, 1-Weertman, 2-Budd

	if strcmp(friction, 'Schoof')
		flagFriction = 0;
	elseif strcmp(friction, 'Weertman')
		flagFriction = 1;
	elseif strcmp(friction, 'Budd')
		flagFriction = 2;
	end
	% }}}
	%GET damageType: 0 {{{
	damageType = getfieldvalue(options,'damageType', 0); % 1-use shear stress as indicator
	% }}}
	%GET year of surface : 2007 {{{
	year_surface = getfieldvalue(options,'year of surface', 2007); % use which year's surface for the inversion
	% }}}
	%GET griddata range : [-0.2221, -0.1801, -2.2848, -2.2571]*1e6 {{{
	griddata_range = getfieldvalue(options,'griddata range', [-0.2221, -0.1801, -2.2848, -2.2571]*1e6); % use griddata to interpolate the surface 
	% }}}
	%GET calving law: Obs{{{
	calving = getfieldvalue(options,'calving','Obs');
	if ~ismember(calving,{'VM', 'Obs', 'Greene', 'CALFIN', 'TermPicks'})
		disp('runme warning: calving law not supported, defaulting to use ''Observed ice front positions''')
		calving = 'Obs';
	end

	% set default obs
	if strcmp(calving, 'Obs')
		calving = 'Greene';
	end

	flagObsCalving = 1;
	if strcmp(calving, 'VM')
		flagObsCalving = 0;
	end
	% }}}
	%GET rerun_inversion: 0{{{
	rerun_inversion = getfieldvalue(options,'rerun inversion', 0);
	% }}}
	%GET use Weertman: 0{{{
	use_weertman = getfieldvalue(options,'use Weertman', 0);
	% }}}
	%GET sigma: 1.0{{{
	sigma = getfieldvalue(options,'sigma', 1.0);
	% }}}
	%GET Cmax: 0.8 {{{
	Cmax = getfieldvalue(options,'Cmax',0.8);
	% }}}
	%GET savepath: '/'{{{
	savePath = getfieldvalue(options,'savePath', './testrun');
	% }}}
	%GET stabilization for levelset: 5 - SUPG {{{
	levelsetStabilization = getfieldvalue(options,'levelset stabilization', 5);
	% }}}
	%GET reinitialization for levelset: 50 {{{
	levelsetReinit = getfieldvalue(options,'levelset reinitialize', 50);
	% }}}
	%GET startTime: 2007 {{{
	startTime = getfieldvalue(options,'startTime', 2007);
	% }}}
	%GET finalTime: 2022 {{{
	finalTime = getfieldvalue(options,'finalTime', 2022);
	% }}}
	%GET C before 2007: 0 {{{
	C_before = getfieldvalue(options,'C before 2007', 0);
	% }}}
	%GET Cmax before 2007: 0 {{{
	Cmax_before = getfieldvalue(options,'Cmax before 2007', 0);
	% }}}
	%GET apply Weertman: 0 {{{
	applyWeertman = getfieldvalue(options,'apply Weertman', 0);
	% }}}
	%GET SMB model: MAR or RACMO{{{
	smb_model = getfieldvalue(options,'smb model','MAR');
	% }}}
	%GET jobTime: 5 (hours){{{
	jobTime = getfieldvalue(options,'jobTime', 5);
	% }}}
   %GET month of the front: 0 {{{
   monthfront = getfieldvalue(options,'month', 0);
   % }}}


	%GET residue threshold for linear solver: 1e-6{{{
	residue_threshold = getfieldvalue(options,'residue threshold', 1e-6);
	% }}}
	%GET cost coefficients: [1,1,1e-6] {{{
	costcoeffs = getfieldvalue(options,'cost coefficients', [1,1,1e-6]); 
	% }}}
	%GET relax time: 1 (year){{{
	relaxtime = getfieldvalue(options,'relax time', 1);
	% }}}
	%GET arate source: 'Obs' {{{
	arateSource = getfieldvalue(options,'Arate source', 'Obs');
	% }}}
	%GET mean window: 0 {{{
	meanwindow = getfieldvalue(options,'mean window', 0);
	% }}}
	%GET parameterization type: -1{{{
	use_param = getfieldvalue(options,'parameterization type', -1);
	% }}}
	%GET theta of calving param: 0{{{
	theta = getfieldvalue(options,'theta', 0);
	% }}}
	%GET alpha of calving param: 0 {{{
	alpha = getfieldvalue(options,'alpha', 0);
	% }}}
	%GET xoffset of caling param: 0{{{
	xoffset = getfieldvalue(options,'xoffset', 0);
	% }}}
	%GET yoffset of caling param: 0 {{{
	yoffset = getfieldvalue(options,'yoffset', 0);
	% }}}

	%Load some necessary codes {{{
	glacier = 'NEGIS'; hem='n';

	rootFolder = '/Users/chenggong/Research/';

	addpath(genpath([rootFolder, glacier, '/PostProcessing/']))
	addpath(genpath([rootFolder, glacier, '/src/']))
	projPath = [rootFolder, glacier, '/'];
	% }}}
	%Cluster parameters{{{
	if strcmpi(clustername, 'andes')
      cluster=andes('numnodes',1,'cpuspernode',64, 'memory', 32);
      cluster.time = jobTime;
      waitonlock = 0;
   elseif strcmpi(clustername, 'frontera')
      cluster=frontera('numnodes', 3,'cpuspernode', 56);
      cluster.time = jobTime;
      waitonlock = 0;
	else
		cluster=generic('name',oshostname(),'np', 14);
		waitonlock = Inf;
	end
	clear clustername
	org=organizer('repository',[projPath, '/Models'],'prefix',['Model_' glacier '_'],'steps',steps); clear steps;
	fprintf(['\n  ========  ' upper(glacier) '  ========\n\n']);
	%}}}
	%set suffix{{{
	switch flagFriction
		case 0 % Schoof
			friction_suffix = ['_Schoof']; %_Cmax0', num2str(Cmax*10)];
		case 1 % Weertman
			friction_suffix = ['_Weertman'];
		case 2 % Budd
			friction_suffix = ['_Budd'];
		case 3 % Budd p=q=5
			friction_suffix = ['_Budd_plastic'];
		otherwise
			error('The friction in the setting is not used.');
	end
	% with shear margin
	switch damageType
		case 1
			damage_suffix = '_SMW';
		case 2 
			damage_suffix = '_SMW2';
		case 3 
			damage_suffix = '_Rignot_SMW';
		otherwise
			damage_suffix = '';
	end

	% calving front forcing: calving laws or Obs
	if flagObsCalving
		calving_suffix = ['_', calving];
	else
		calving_suffix = '';
	end
	suffix = [damage_suffix, friction_suffix];
	% ratio for coeff in inversion
	ratio = [10, 2, 1];
	%}}}

	% Step 1--5
	if perform(org, 'Mesh')% {{{

		md=triangle(model,[projPath 'Exp/' glacier '.exp'],500);

		[velx, vely]=interpJoughinCompositeGreenland(md.mesh.x,md.mesh.y);
		vel  = sqrt(velx.^2+vely.^2);

		%h=NaN*ones(md.mesh.numberofvertices,1);
		%in=ContourToNodes(md.mesh.x,md.mesh.y,[projPath, '/Exp/refinement.exp'],1);
		%h(find(in)) = 200;

		%refine mesh using surface velocities as metric
		if strcmp(hem,'n')
			md=bamg(md,'hmin',100,'hmax',5000,'field',vel,'err',5, 'gradation', 2);%, 'hVertices', h);
			[md.mesh.lat,md.mesh.long]  = xy2ll(md.mesh.x,md.mesh.y,+1,45,70);
			md.mesh.epsg=3413;
		else
			md=bamg(md,'hmin',1000,'hmax',20000,'field',vel,'err',10);
			[md.mesh.lat,md.mesh.long]  = xy2ll(md.mesh.x,md.mesh.y,-1,0,71);
			md.mesh.epsg=3031;
		end

		savemodel(org,md);
	end %}}}
	if perform(org, ['Param_ISMIP', damage_suffix])% {{{

		md=loadmodel(org,'Mesh');
		md=setflowequation(md,'SSA','all');

		if strcmp(hem,'n')
			md=setmask(md,'','');
			md=parameterize(md,'Greenland.par');
		else
			md=setmask(md,'','');
			md=parameterize(md,'Antarctica.par');
		end

		% set ice temprature according to ISMIP6
		disp([' Assigning ice temperature according to ISMIP6 results'])
		org_ISMIP = organizer('repository', [projPath, '../ISMIP6Greenland/Models'], 'prefix', 'ISMIP6Greenland_', 'steps', [1]);
		md_ISMIP = loadmodel(org_ISMIP, 'save2d');
		% set Nan for no ice in ISMIP
		md_ISMIP.results.temperature(md_ISMIP.mask.ice_levelset>=0) = NaN;
		% Interpolate 
		vellimit = 1500;
		tGlacier = InterpFromMeshToMesh2d(md_ISMIP.mesh.elements, md_ISMIP.mesh.x, md_ISMIP.mesh.y, md_ISMIP.results.temperature, md.mesh.x, md.mesh.y);

		% compute the average temperature ove the fast flowing region of the given glacier
		masked = (md.initialization.vel< vellimit) | (md.mask.ice_levelset>=0);
		[intData, avgTGlacier, areas] = integrateOverDomain(md, tGlacier, masked);
		fprintf('    -- The average temperature of %s at fast flowing region (vel>%g) is %g ^oC\n', glacier, vellimit, avgTGlacier-273.15);
		% set no ice region in ISMIP to be the average temperature
		md_ISMIP.results.temperature(md_ISMIP.mask.ice_levelset>=0) = avgTGlacier;
		tGlacier = InterpFromMeshToMesh2d(md_ISMIP.mesh.elements, md_ISMIP.mesh.x, md_ISMIP.mesh.y, md_ISMIP.results.temperature, md.mesh.x, md.mesh.y);
		tnan = isnan(tGlacier);
		tGlacier(tnan) = avgTGlacier;

		disp([' Reassigning flow law parameters according to ISMIP6 results']);
		md.materials.rheology_B = cuffey(tGlacier); % tGlacier is already in K
		md.initialization.temperature = tGlacier;
		md.miscellaneous.name = glacier;

		% add damage on the shear margin {{{
		if (damageType == 0)
			disp([' No damage to shear margin']);
		elseif(damageType == 1),
			maxEffStrain = 2;
			md=mechanicalproperties(md,md.inversion.vx_obs,md.inversion.vy_obs);
			pos=md.mesh.elements(md.results.strainrate.effectivevalue>maxEffStrain);
			damage=ones(md.mesh.numberofvertices,1);
			damage(pos)=6;
			% set ice free element to no damage
			damage(md.mask.ice_levelset>=0) = 1;
			md.materials.rheology_B=1./((damage).^(1/3)).*md.materials.rheology_B;
			disp([' Add damage to shear margin']);
		elseif (damageType == 2)
			disp([' Add damage to shear margin, determined by strainrate and velocity threshold']);
			maxEffStrain = 1;
			md=mechanicalproperties(md,md.inversion.vx_obs,md.inversion.vy_obs);
			pos=md.mesh.elements(md.results.strainrate.effectivevalue>maxEffStrain);
			damage=ones(md.mesh.numberofvertices,1);
			damage(pos)=6;
			% set fast flow region (vel>10m/d) element to no damage
			damage(md.initialization.vel>3650) = 1;
			md.materials.rheology_B=1./((damage).^(1/3)).*md.materials.rheology_B;
		elseif (damageType == 3)
			disp([' Use Rignot 2012 velocity for determing the shear margin and inversion'])

			disp('      reading velocities ');
			[md.inversion.vx_obs md.inversion.vy_obs]=interpRignot2012(md.mesh.x,md.mesh.y);
			pos=find(isnan(md.inversion.vx_obs) | isnan(md.inversion.vy_obs));
			md.inversion.vx_obs(pos)=0;
			md.inversion.vy_obs(pos)=0;
			md.inversion.vel_obs  = sqrt(md.inversion.vx_obs.^2+md.inversion.vy_obs.^2);
			md.initialization.vx  = md.inversion.vx_obs;
			md.initialization.vy  = md.inversion.vy_obs;
			md.initialization.vel = md.inversion.vel_obs;

			disp([' Add damage to shear margin, determined by strainrate and velocity threshold']);
			maxEffStrain = 1;
			md=mechanicalproperties(md,md.inversion.vx_obs,md.inversion.vy_obs);
			pos=md.mesh.elements(md.results.strainrate.effectivevalue>maxEffStrain);
			damage=ones(md.mesh.numberofvertices,1);
			damage(pos)=6;
			% set fast flow region (vel>10m/d) element to no damage
			damage(md.initialization.vel>vellimit) = 1;
			% only has damage on ice region
			damage(md.mask.ice_levelset>=0) = 1;
			md.materials.rheology_B=1./((damage).^(1/3)).*md.materials.rheology_B;
		else
			error('Unknown damage type');
		end %}}}

		savemodel(org,md);
	end%}}}
	if perform(org, ['InversionB',damage_suffix]),% {{{

		md=loadmodel(org, ['Param_ISMIP', damage_suffix]);

		% set M1QN3 package
		md.inversion=m1qn3inversion(md.inversion);

		%No friction on PURELY ocean element
      pos_e = find(min(md.mask.ice_levelset(md.mesh.elements),[],2)<0);
      flags=ones(md.mesh.numberofvertices,1);
      flags(md.mesh.elements(pos_e,:))=0;
      md.friction.coefficient(find(flags))=0.0;

      % also set floating ice friction to 0.0
      pos=find(md.mask.ocean_levelset<0);
      md.friction.coefficient(pos) = 0.0;

		% Set inversion data
		md.inversion.vx_obs=md.initialization.vx; % initialization was defined in last step (raw data, with NaN)
		md.inversion.vy_obs=md.initialization.vy; % initialization was defined in last step (raw data, with NaN)

		pos=find(isnan(md.inversion.vx_obs) | isnan(md.inversion.vy_obs));
		md.inversion.vx_obs(pos)=0;
		md.inversion.vy_obs(pos)=0;
		md.inversion.vel_obs=sqrt(md.inversion.vx_obs.^2+md.inversion.vy_obs.^2);
		md.initialization.vx(pos)=0;
		md.initialization.vy(pos)=0;
		md.initialization.vel(pos)=0;

		% Control general
		md.inversion.iscontrol=1;
		md.inversion.maxsteps=40;
		md.inversion.maxiter=40;
		md.inversion.dxmin=0.1;
		md.inversion.gttol=1.0e-6;
		md.inversion.incomplete_adjoint=0; % 0: non linear viscosity, 1: linear viscosity 04/29/2019 changed to non linear

		% Cost functions
		md.inversion.cost_functions=[101 103 502];
		md.inversion.cost_functions_coefficients=ones(md.mesh.numberofvertices,length(md.inversion.cost_functions));
      md.inversion.cost_functions_coefficients(:,1)=costcoeffs(1);
      md.inversion.cost_functions_coefficients(:,2)=costcoeffs(2);
		md.inversion.cost_functions_coefficients(:,end)=costcoeffs(3);
		md.inversion.cost_functions_coefficients(pos,:)=0; % positions with NaN in the velocity data set

		% Controls
		% setting initial guess for rheology B
		md.inversion.control_parameters={'MaterialsRheologyBbar'};
		md.inversion.min_parameters=cuffey(273.15)*ones(size(md.materials.rheology_B)); % from Seroussi et al, 2014
		md.inversion.max_parameters=cuffey(273.15-30)*ones(size(md.materials.rheology_B)); % from Seroussi et al, 2014

		% Additional parameters
		mds.stressbalance.maxiter=50; % 10/24/2019
		mds.stressbalance.restol=0.0001; % 04/29/2019
		mds.stressbalance.reltol=0.01; % 11/05/2019
		mds.stressbalance.abstol=NaN; % 11/05/2019

		% Prepare to solve
		md.cluster=cluster;
		md.verbose=verbose('solution',false,'control',true);
		md.miscellaneous.name='inversion_B';
		mds=extract(md,md.mask.ocean_levelset<0);
		mds.friction.coefficient(:)=0; % make sure there is no basal friction
		% Solve
		mds.toolkits.DefaultAnalysis=bcgslbjacobioptions();% biconjugate gradient with block Jacobi preconditioner
		mds.settings.solver_residue_threshold=NaN; % 11/05/2019
		mds.stressbalance.maxiter=50; % 10/24/2019
		mds.stressbalance.reltol=NaN; % 11/05/2019
		mds.stressbalance.abstol=NaN; % 11/05/2019

		mds=solve(mds,'Stressbalance'); % only extracted model

		% Update model rheology_B accordingly
		md.results.rheology_B = md.materials.rheology_B;
		md.materials.rheology_B(mds.mesh.extractedvertices)=mds.results.StressbalanceSolution.MaterialsRheologyBbar;

		savemodel(org,md);
	end
	%}}}
	if perform(org, ['Inversion_drag_ISMIP', damage_suffix, '_Budd'])% {{{
		if (rerun_inversion)
			disp(['  Rerun inversion using previous results as initial guess'])
			md=loadmodel(org, ['Inversion_drag_ISMIP', damage_suffix, '_Budd']);
		else
			md=loadmodel(org, ['InversionB', damage_suffix]);
		end
		% fixed after add this option to effective pressure coupling
		md.friction.coupling = 2;

      %No friction on PURELY ocean element
      pos_e = find(min(md.mask.ice_levelset(md.mesh.elements),[],2)<0);
      flags=ones(md.mesh.numberofvertices,1);
      flags(md.mesh.elements(pos_e,:))=0;
      md.friction.coefficient(find(flags))=0.0;

      % also set floating ice friction to 0.0
      pos=find(md.mask.ocean_levelset<0);
      md.friction.coefficient(pos) = 0.0;

		%Control general
		md.inversion=m1qn3inversion(md.inversion);
		md.inversion.iscontrol=1;
		md.verbose=verbose('solution',false,'control',true);
		md.transient.amr_frequency = 0;

		%Cost functions
		md.inversion.cost_functions=[101 103 501];
		md.inversion.cost_functions_coefficients=zeros(md.mesh.numberofvertices,numel(md.inversion.cost_functions));
		md.inversion.cost_functions_coefficients(:,1)=costcoeffs(1);
		md.inversion.cost_functions_coefficients(:,2)=costcoeffs(2);
		md.inversion.cost_functions_coefficients(:,3)=costcoeffs(3);
		pos=find(md.mask.ice_levelset>0);
		md.inversion.cost_functions_coefficients(pos,1:2)=0;
		% skip inversion for H=minimal thickness nodes
%		pos=find(md.mask.ice_levelset<=0 & md.geometry.thickness<=1);
%		md.inversion.cost_functions_coefficients(pos,1:2)=0;
      %pos=find(md.mask.ocean_levelset<0);
		%md.inversion.cost_functions_coefficients(pos,:)=0;

		%Controls
		md.inversion.control_parameters={'FrictionCoefficient'};
		md.inversion.maxsteps=400;
		md.inversion.maxiter =400;
		md.inversion.min_parameters=1e-2*ones(md.mesh.numberofvertices,1);
		md.inversion.max_parameters=1e3*ones(md.mesh.numberofvertices,1);
		md.inversion.control_scaling_factors=1;
		md.inversion.dxmin = 1e-6;

		%Additional parameters
		md.stressbalance.restol=1e-4;
		md.stressbalance.reltol=1e-2;
		md.stressbalance.abstol=NaN;

		md.toolkits.DefaultAnalysis=bcgslbjacobioptions();
      md.settings.solver_residue_threshold = 1e-5;

		%Go solve
		md.cluster=cluster;
		md=solve(md,'sb');

		%Put results back into the model
		md.friction.coefficient=md.results.StressbalanceSolution.FrictionCoefficient;

		savemodel(org,md);
	end%}}}
	if perform(org, ['Inversion_drag_ISMIP', damage_suffix, '_Weertman'])% {{{

		if (rerun_inversion)
			disp(['  Rerun inversion using previous results as initial guess'])
			md=loadmodel(org, ['Inversion_drag_ISMIP', damage_suffix, '_Weertman']);
		else
			md=loadmodel(org, ['InversionB', damage_suffix]);

			% Set the friction law to Weertman
			md.friction=frictionweertman();
			md.friction.m = 3.0*ones(md.mesh.numberofelements,1);
			md.friction.C = 2000*ones(md.mesh.numberofvertices,1);
		end

		%No friction on PURELY ocean element
		pos_e = find(min(md.mask.ice_levelset(md.mesh.elements),[],2)<0);
		flags=ones(md.mesh.numberofvertices,1);
		flags(md.mesh.elements(pos_e,:))=0;
		md.friction.C(find(flags))=0.0;

		% also set floating ice friction to 0.0
		pos=find(md.mask.ocean_levelset<0);
		md.friction.C(pos) = 0.0;

		%Control general
		md.inversion=m1qn3inversion(md.inversion);
		md.inversion.iscontrol=1;
		md.verbose=verbose('solution',false,'control',true);
		md.transient.amr_frequency = 0;

		%Cost functions
		md.inversion.cost_functions=[101 103 501];
		md.inversion.cost_functions_coefficients=zeros(md.mesh.numberofvertices,numel(md.inversion.cost_functions));
		md.inversion.cost_functions_coefficients(:,1)=costcoeffs(1);
		md.inversion.cost_functions_coefficients(:,2)=costcoeffs(2);
		md.inversion.cost_functions_coefficients(:,3)=costcoeffs(3);
		pos=find(md.mask.ice_levelset>0);
		md.inversion.cost_functions_coefficients(pos,1:2)=0;

		%Controls
		md.inversion.control_parameters={'FrictionC'};
		md.inversion.maxsteps=400;
		md.inversion.maxiter =400;
		md.inversion.min_parameters=1e-4*ones(md.mesh.numberofvertices,1);
		md.inversion.max_parameters=5e4*ones(md.mesh.numberofvertices,1);
		md.inversion.control_scaling_factors=1;
		md.inversion.dxmin = 1e-6;
		%Additional parameters
		md.stressbalance.restol=1e-4;
		md.stressbalance.reltol=1e-2;
		md.stressbalance.abstol=NaN;

		md.toolkits.DefaultAnalysis=bcgslbjacobioptions();
		%Go solve
		md.cluster=cluster;
		md=solve(md,'sb');

		%Put results back into the model
		md.friction.C=md.results.StressbalanceSolution.FrictionC;

		savemodel(org,md);
	end%}}}

	% step 6--10
	if perform(org, ['Inversion_drag_ISMIP', damage_suffix, '_Schoof'])% {{{

		if (rerun_inversion)
			disp(['  Rerun inversion using previous results as initial guess'])
			md=loadmodel(org, ['Inversion_drag_ISMIP', damage_suffix, '_Schoof']);
		elseif (use_weertman)
			md=loadmodel(org, ['Inversion_drag_ISMIP', damage_suffix, '_Weertman']);
			C = md.friction.C;
         md.friction=frictionschoof();
         md.friction.m = 1.0/3.0*ones(md.mesh.numberofelements,1);
         md.friction.Cmax = Cmax*ones(md.mesh.numberofvertices,1);
         md.friction.C = C;
         md.friction.coupling = 2;

			%No friction on PURELY ocean element
         pos_e = find(min(md.mask.ice_levelset(md.mesh.elements),[],2)<0);
         flags=ones(md.mesh.numberofvertices,1);
         flags(md.mesh.elements(pos_e,:))=0;

         md.friction.C(find(flags))=0.0;
         %md.friction.C(md.friction.C==0)=0.01;
		else
			md=loadmodel(org, ['InversionB', damage_suffix]);

			% Set the friction law to schoof's
			md.friction=frictionschoof();
			md.friction.m = 1.0/3.0*ones(md.mesh.numberofelements,1);
			md.friction.Cmax = Cmax*ones(md.mesh.numberofvertices,1);
			md.friction.C = 1000*ones(md.mesh.numberofvertices,1);
			md.friction.coupling = 2;

			%No friction on PURELY ocean element
			pos_e = find(min(md.mask.ice_levelset(md.mesh.elements),[],2)<0);
			flags=ones(md.mesh.numberofvertices,1);
			flags(md.mesh.elements(pos_e,:))=0;
			md.friction.C(find(flags))=0.01;
		end

		pos=find(md.mask.ocean_levelset<0);
		md.friction.C(pos) = 0;

		%Control general
		md.inversion=m1qn3inversion(md.inversion);
		md.inversion.iscontrol=1;
		md.verbose=verbose('solution',false,'control',true);
		md.transient.amr_frequency = 0;

		%Cost functions
		md.inversion.cost_functions=[101 103 501];
		md.inversion.cost_functions_coefficients=zeros(md.mesh.numberofvertices,numel(md.inversion.cost_functions));
		md.inversion.cost_functions_coefficients(:,1)=costcoeffs(1);
		md.inversion.cost_functions_coefficients(:,2)=costcoeffs(2);
		md.inversion.cost_functions_coefficients(:,3)=costcoeffs(3);
		pos=find(md.mask.ice_levelset>0);
		md.inversion.cost_functions_coefficients(pos,1:2)=0;

		%Controls
		md.inversion.control_parameters={'FrictionC'};
		md.inversion.maxsteps=400;
		md.inversion.maxiter =400;
		md.inversion.min_parameters=1e-4*ones(md.mesh.numberofvertices,1);
		md.inversion.max_parameters=1e5*ones(md.mesh.numberofvertices,1);
		md.inversion.control_scaling_factors=1;
		md.inversion.dxmin = 1e-6;
		%Additional parameters
		md.stressbalance.restol=1e-4;
		md.stressbalance.reltol=1e-2;
		md.stressbalance.abstol=NaN;
		md.stressbalance.maxiter = 100;

		md.toolkits.DefaultAnalysis=bcgslbjacobioptions();
		md.settings.solver_residue_threshold = 1e-5;
		%Go solve
		md.cluster=cluster;
		md=solve(md,'sb');

		%Put results back into the model
		md.friction.C=md.results.StressbalanceSolution.FrictionC;

		savemodel(org,md);
	end%}}}
	if perform(org, ['Set_GreenFronts', suffix])% {{{
		md=loadmodel(org,['Inversion_drag_ISMIP', suffix]);

		% Step 1: set start_time to 2007 and final_time to 2022
		md.timestepping.final_time = finalTime;
		md.timestepping.start_time = startTime;

		% Step 2: get observed calving front from Greene's dataset, furthest possible, back to 1972
		mask = interpMonthlyIceMaskGreene(md.mesh.x, md.mesh.y, [md.timestepping.start_time, md.timestepping.final_time], 1, '/Users/chenggong/ModelData/Greenland/IceFrontsGreene/NSIDC-0793_19720915-20220215_V01.0.nc');

		% step 3: mask out 'forever ice' region
		% define forever ice region
	%	forever_ice_mask = (md.geometry.bed>=0);
	%	in=ContourToNodes(md.mesh.x,md.mesh.y,'./Exp/forever_ice.exp',1);
	%	forever_ice_mask(find(in)) = 1;
	%	md.results.forever_ice_mask = forever_ice_mask;

		% set premask area to -1
	%	mask(md.results.forever_ice_mask,:)=-1;

		% step 4: convert icemask to levelset distance
		distance = zeros(size(mask));
		for i = 1:size(mask,2)
			distance(1:end-1,i) = reinitializelevelset(md, mask(1:end-1,i));
		end
		distance(end,:) = mask(end,:);
		% transient spc
		md.levelset.spclevelset = distance;

		% update boundary conditions
		md.stressbalance.spcvx=NaN*ones(md.mesh.numberofvertices,1);
		md.stressbalance.spcvy=NaN*ones(md.mesh.numberofvertices,1);
		md.stressbalance.spcvz=NaN*ones(md.mesh.numberofvertices,1);
		md.stressbalance.referential=NaN*ones(md.mesh.numberofvertices,6);
		md.stressbalance.loadingforce=0*ones(md.mesh.numberofvertices,3);
		pos=find((md.mask.ice_levelset<0).*(md.mesh.vertexonboundary));
		md.stressbalance.spcvx(pos)=md.initialization.vx(pos);
		md.stressbalance.spcvy(pos)=md.initialization.vy(pos);
		md.stressbalance.spcvz(pos)=0;

		%Clean up
		savemodel(org,md);
	end%}}}
	if perform(org, ['Set_SMB_', smb_model, suffix])% {{{
		md=loadmodel(org,['Set_GreenFronts', suffix]);

		% Step 1: RACMO also goes to 2022, but not MAR(only to 2020), for MAR we will repeat the average of the last three years
		md.smb.mass_balance = [];

		if strcmp(smb_model, 'RACMO')
			% load RACMO
			for i= md.timestepping.start_time: md.timestepping.final_time
				if (i>=1990) & (i<=2021)
					filename = ['/Users/chenggong/ModelData/Greenland/RACMO23p2_2022_Greenland/smb/smb_rec.', num2str(i), '.BN_RACMO2.3p2_ERA5_3h_FGRN055.1km.MM.nc'];

					%Get time
					T  = double(ncread(filename,'time')); % in days
					if leapyear(i)
						time = i + (T)/366;
					else
						time = i + (T)/365;
					end

					%Coordinates
					x=double(ncread(filename,'x'));
					y=double(ncread(filename,'y'));

					%Load SMB for this year
					disp(['Loading ' filename]);
					SMB=double(ncread(filename,'smb_rec'))/1000.0*12.0*md.materials.rho_freshwater/md.materials.rho_ice; %from mmWE/month to mIE/yr
				elseif (i>= 1958) & (i<=1989)
					filename = ['/Users/chenggong/ModelData/Greenland/RACMO23p2_2022_Greenland/smb/smb_rec.', num2str(i), '.BN_RACMO2.3p2_ERA40_ERAIn_FGRN055.1km.MM.nc'];
					%Get time
					T  = double(ncread(filename,'time')); % in month
					time = i + (T+0.5)/12;

					%Coordinates
					x=double(ncread(filename,'lon'));
					y=double(ncread(filename,'lat'));

					%Load SMB for this year
					disp(['Loading ' filename]);
					SMB=double(ncread(filename,'SMB_rec'))/1000.0*12.0*md.materials.rho_freshwater/md.materials.rho_ice; %from mmWE/month to mIE/yr
				else
					disp(['Year ', num2str(i), ' is not coverd in RACMO data, skip for now!'])
					continue;
				end

				%Interpolate
				for m=1:numel(time)
					smb_mesh=InterpFromGridToMesh(x, y, SMB(:,:,m)', md.mesh.x, md.mesh.y, 0);
					md.smb.mass_balance = [md.smb.mass_balance, [smb_mesh;time(m)]];
				end
			end
		elseif strcmp(smb_model, 'MAR_6k')
			md.smb.mass_balance = [];
			for i= md.timestepping.start_time: md.timestepping.final_time
				if (i>=1950) & (i<=2021)
					filename = ['/totten_1/ModelData/Greenland/MAR_6km/MARv3.11.5-Greenland-6km-daily-ERA-', num2str(i), '.nc'];
					disp(['Loading ' filename]);
				else
					disp(['Year ', num2str(i), ' is not coverd in the MAR data, skip for now!'])
					continue;
				end

				%Get time
				T0 = ncreadatt(filename, 'TIME', 'time_origin');
				T  = ncread(filename,'TIME');
				time = date2decyear(double(datenum(T0)+T));
				if ( (min(time) <i ) || (max(time)>i+1) )
					error(['TIME in ', filename, 'exceeds the year ', num2str(i)])
				end

				%Coordinates
				LAT=ncread(filename,'LAT');
				LON=ncread(filename,'LON');

				%Load SMB for this year
				SMB=double(ncread(filename,'SMB'))/1000*365.25*md.materials.rho_freshwater/md.materials.rho_ice; %from mmWE/day to mIE/yr

				%Interpolate
				INDEX=BamgTriangulate(LON(:),LAT(:));
				SMB_reshaped = reshape(squeeze(SMB(:,:,1,:)),[numel(LAT) numel(time)]);
				smb_mar=InterpFromMeshToMesh2d(INDEX,LON(:),LAT(:),SMB_reshaped,md.mesh.long,md.mesh.lat);

				%Now use a monthly average
				smb_monthly = zeros(md.mesh.numberofvertices+1,1);
				for month=1:12
					pos = find(time>=time(1)+(month-1)/12  & time<time(1)+month/12);
					if ~isnan(mean(time(pos)))
						smb_monthly(1:end-1,month) = mean(smb_mar(:,pos),2);
						smb_monthly(end    ,month) = mean(time(pos));
					else
						disp(['Skipping year ' num2str(time(1)+month/12)]);
					end
				end

				md.smb.mass_balance = [md.smb.mass_balance smb_monthly];
			end
		elseif strcmp(smb_model, 'MAR')
			for i= md.timestepping.start_time: md.timestepping.final_time
				if (i>=1950) & (i<=2019)
					filename = ['/totten_1/ModelData/Greenland/MARv3.11-ERA5/MARv3.11-monthly-ERA5-', num2str(i), '.nc'];
					disp(['Loading ' filename]);
				else
					disp(['Year ', num2str(i), ' is not coverd in the MAR data, skip for now!'])
					continue;
				end

				%Get time
				T  = double(ncread(filename,'time'));
				time = i + (T+0.5)/12;

				%Coordinates
				x=double(ncread(filename,'x'));
				y=double(ncread(filename,'y'));

				%Load SMB for this year
				SMB=double(ncread(filename,'SMB'))/1000.0*12.0*md.materials.rho_freshwater/md.materials.rho_ice; %from mmWE/month to mIE/yr

				%Interpolate
				for m=1:numel(time)
					smb_mesh=InterpFromGridToMesh(x, y, SMB(:,:,m)', md.mesh.x, md.mesh.y, 0);
					md.smb.mass_balance = [md.smb.mass_balance, [smb_mesh;time(m)]];
				end
			end

			if (md.timestepping.final_time>2020)
				% Take average of the last three years from the MAR, repeat to the finalTime
				last3pos = find((md.smb.mass_balance(end,:)>=2017) & (md.smb.mass_balance(end,:)<2020));
				monthlypos = reshape(last3pos, 3, 12);

				averageSMB = zeros(md.mesh.numberofvertices, 12);
				for i = 1:12
					averageSMB(:,i) = mean(md.smb.mass_balance(1:end-1, monthlypos(:,i)),2);
				end
				Next = ceil(md.timestepping.final_time - 2020);
				repeatAverageSMB = repmat(averageSMB,1,Next);
				repeatTime = 2020+linspace(0.5, Next*12-0.5,Next*12)/12;

				% put this to md.smb.mass_balance for 2020-2022
				md.smb.mass_balance = [md.smb.mass_balance, [repeatAverageSMB;repeatTime]];
			end
		else
			error(['Unknown SMB model: ', smb_model])
		end

		savemodel(org,md);
	end%}}}



	if perform(org, ['Set_icemask_before1972', suffix])% {{{
		md=loadmodel(org,['Inversion_drag_ISMIP', suffix]);

		md.initialization.vx=md.results.StressbalanceSolution.Vx;
		md.initialization.vy=md.results.StressbalanceSolution.Vy;
		% step 0: save the mask for inversion
      md.results.icemask_inv = md.mask.ice_levelset;

		% Step 1: set start_time to 1958 and final_time to 2022
		md.timestepping.final_time = finalTime;
		md.timestepping.start_time = startTime;

		% Step 2: get observed calving front from Greene's dataset, back to 1972
		greene_mask = interpMonthlyIceMaskGreene(md.mesh.x, md.mesh.y, [md.timestepping.start_time, md.timestepping.final_time]);

		% step 3: for the ice mask before 1972, use yearly surface elevation data from Abbas
		% now project altimetry data to the mesh
		d = load([projPath, '/DATA/Jakobshavn_polar.mat']);
		X = d.data(:, 1);
		Y = d.data(:, 2);
		S = d.data(:, 3:end);
		time = d.tid;

		[t, tId] = intersect(time, [md.timestepping.start_time:1972],'stable');
		if isempty(tId)
			tId = 1;
			Nt = 1;
		else
			Nt = numel(tId);
		end

		% predefine some variables
		pre_mask = ones(md.mesh.numberofvertices+1, Nt);
		pre_mask(end,:) = t;

		% define forever ice region
		forever_ice_mask = (md.geometry.bed>=0);
		in=ContourToNodes(md.mesh.x,md.mesh.y,'./Exp/forever_ice.exp',1);
		forever_ice_mask(find(in)) = 1;
		md.results.forever_ice_mask = forever_ice_mask;
      % define manually fixed ice region for mask before Greene's 1972
      manual_ice_mask = (md.geometry.bed>=0);
      in=ContourToNodes(md.mesh.x,md.mesh.y,'./Exp/manual_fix_H_mask.exp',1);
      manual_ice_mask(find(in)) = 1;

		INDEX=BamgTriangulate(X,Y);
		griddata_flag = -ones(md.mesh.numberofvertices, 1);
		griddata_range = [-0.2221, -0.1801, -2.2848, -2.2571]*1e6;
		griddata_flag((md.mesh.x >= griddata_range(1)) & (md.mesh.x <= griddata_range(2)) & (md.mesh.y >= griddata_range(3)) & (md.mesh.y <= griddata_range(4))) = 1;

		for i = 1: Nt
			disp(['Project surface elevation of year ', num2str(t(i)), ' to the mesh']);
			% for the front part, use griddata [-0.2221, -0.1801, -2.2848, -2.2571]*1e6
			s_front = griddata(X,Y,S(:,tId(i)),md.mesh.x,md.mesh.y,'natural');
			% for the rest, use InterpFromMeshToMesh
			s_interior = InterpFromMeshToMesh2d(INDEX, X, Y, S(:,tId(i)), md.mesh.x, md.mesh.y);
			% merge
			s = s_interior;
			s(griddata_flag==1) = s_front(griddata_flag==1);
			% put to mask
			pre_mask(s>0, i) = -1;
		end

		% manually fix the pre mask
		pre_mask(manual_ice_mask,:) = -1;
		% manually fix Greene mask in 2005.2849
		setocean = ContourToNodes(md.mesh.x,md.mesh.y,'./Exp/manual_fix_mask2005_ocean.exp',1);
		setice = ContourToNodes(md.mesh.x,md.mesh.y,'./Exp/manual_fix_mask2005_ice.exp',1);
		% fix the holes and icebergs in 2005.2849 (April)
		[~, manid] = min(abs(greene_mask(end,:)-2005.2849));
		greene_mask(find(setocean),manid) = 1;
		greene_mask(find(setice),manid) = -1;
		% fix the holes in 2005.2 (March)
		[~, manid] = min(abs(greene_mask(end,:)-2005.2));
		greene_mask(find(setice),manid) = -1;

		% merge the two ice masks
		mask = [pre_mask, greene_mask];
		% set premask area to -1
		mask(md.results.forever_ice_mask,:)=-1;

		% step 4: convert icemask to levelset distance
		distance = zeros(size(mask));
		for i = 1:size(mask,2)
			distance(1:end-1,i) = reinitializelevelset(md, mask(1:end-1,i));
		end
		distance(end,:) = mask(end,:);
		% transient spc
		md.levelset.spclevelset = distance;

		% set mask
		% initial condition is from the geometry
		md.mask.ice_levelset = mask(1:end-1,1);

		% step 5: use Bedmachine to correct the initial surface
      [t, tId] = intersect(time, [md.timestepping.start_time, 2007],'stable');
		Nt = numel(tId);

      % load the two surface
      pre_surface = ones(md.mesh.numberofvertices, Nt);
      INDEX=BamgTriangulate(X,Y);
      griddata_flag = -ones(md.mesh.numberofvertices, 1);
      griddata_range = [-0.2221, -0.1801, -2.2848, -2.2571]*1e6;
      griddata_flag((md.mesh.x >= griddata_range(1)) & (md.mesh.x <= griddata_range(2)) & (md.mesh.y >= griddata_range(3)) & (md.mesh.y <= griddata_range(4))) = 1;
      for i = 1: Nt
         disp(['Project surface elevation of year ', num2str(t(i)), ' to the mesh']);
         % for the front part, use griddata [-0.2221, -0.1801, -2.2848, -2.2571]*1e6
         s_front = griddata(X,Y,S(:,tId(i)),md.mesh.x,md.mesh.y,'natural');
         % for the rest, use InterpFromMeshToMesh
         s_interior = InterpFromMeshToMesh2d(INDEX, X, Y, S(:,tId(i)), md.mesh.x, md.mesh.y);
         % merge
         s = s_interior;
         s(griddata_flag==1) = s_front(griddata_flag==1);
         % put to surface
         pre_surface(:,i) = s;
      end

		% get the diff between pre_surface at 2007 and BedMachine
		diff_surf = md.geometry.surface - pre_surface(:,2);
		diff_surf(isnan(diff_surf)) = 0;

		% step 6: set initial surface and thickness
		md.geometry.surface = pre_surface(:, 1)+diff_surf;
		nan_surf = isnan(md.geometry.surface);
		md.geometry.surface(nan_surf) = md.geometry.bed(nan_surf);
		pos = find(md.mask.ice_levelset>0);
		md.geometry.surface(pos) = md.geometry.base(pos)+10; %Minimum thickness

		md.geometry.thickness = md.geometry.surface - md.geometry.bed;
		pos=find(md.geometry.thickness<=10);
		md.geometry.surface(pos) = md.geometry.base(pos)+10; %Minimum thickness
		md.geometry.thickness = md.geometry.surface - md.geometry.bed;

		pos = find(max(md.mask.ice_levelset(md.mesh.elements),[],2)>0);
		md.mask.ice_levelset(md.mesh.elements(pos,:)) = 1;
		% For the region where surface is NaN, set thickness to small value (consistency requires >0)
		pos=find((md.mask.ice_levelset<0).*(md.geometry.surface<0));
		md.mask.ice_levelset(pos)=1;
		pos=find((md.mask.ice_levelset<0).*(isnan(md.geometry.surface)));
		md.mask.ice_levelset(pos)=1;

		md.geometry.thickness=md.geometry.surface-md.geometry.base;
		% update boundary conditions
		md.stressbalance.spcvx=NaN*ones(md.mesh.numberofvertices,1);
		md.stressbalance.spcvy=NaN*ones(md.mesh.numberofvertices,1);
		md.stressbalance.spcvz=NaN*ones(md.mesh.numberofvertices,1);
		md.stressbalance.referential=NaN*ones(md.mesh.numberofvertices,6);
		md.stressbalance.loadingforce=0*ones(md.mesh.numberofvertices,3);
		pos=find((md.mask.ice_levelset<0).*(md.mesh.vertexonboundary));
		md.stressbalance.spcvx(pos)=md.initialization.vx(pos);
		md.stressbalance.spcvy(pos)=md.initialization.vy(pos);
		md.stressbalance.spcvz(pos)=0;

		%Clean up
		savemodel(org,md);
	end%}}}
	if perform(org, ['Transient_', smb_model, suffix]),% {{{

		md=loadmodel(org, ['Set_SMB_', smb_model, suffix]);

		% step 0.1: for Schoof, to make Vmax higher, we need to lower Cmax in front of the terminus
		if Cmax_before > 0
			if flagFriction == 0 % Schoof
				md.friction.Cmax = Cmax_before+0*md.friction.Cmax;
				if applyWeertman > 0
					disp('use Weertman C for Schoof')
					md_w = loadmodel(org, ['Transient_', smb_model, damage_suffix, '_Weertman']);
					md.friction.C = md_w.friction.C;
				end
			end
		end

		% step 0: change friction coefficients for no ice region
		if C_before > 0
			disp([' change friction coefficient in front of the terminus to ', num2str(C_before)])
			%No friction on PURELY ocean element
			pos_e = find(min(md.results.icemask_inv(md.mesh.elements),[],2)<0);
			flags=ones(md.mesh.numberofvertices,1);
			flags(md.mesh.elements(pos_e,:))=0;

			if flagFriction < 2
				md.friction.C(find(flags))=C_before;
			else 
				md.friction.coefficient(find(flags))=C_before;
			end
		end

		md.initialization.pressure = zeros(md.mesh.numberofvertices,1); %FIXME
		md.masstransport.spcthickness = NaN(md.mesh.numberofvertices,1); %FIXME

		% Set parameters
		md.inversion.iscontrol=0;
		md.timestepping.start_time = startTime;
		md.timestepping.final_time = finalTime;
		md.timestepping.time_step  = 0.01;
		md.settings.output_frequency = 10;

		md.transient.ismovingfront=1;
		md.transient.isslc = 0;
		md.transient.isthermal=0;
		md.transient.isstressbalance=1;
		md.transient.ismasstransport=1;
		md.transient.isgroundingline=1;
		md.groundingline.migration = 'SubelementMigration';

		% calving parameters
		md.calving = calvingvonmises();
		md.calving.stress_threshold_floatingice = 200*10^3;
		md.calving.stress_threshold_groundedice = sigma*10^6; %1: a little much retreat, 0.9,0.95: too much retreat 1.2, 1.1, 1.05,1.02:less retreat:

		% meltingrate
		timestamps = [md.timestepping.start_time, md.timestepping.final_time];
		md.frontalforcings.meltingrate=zeros(md.mesh.numberofvertices+1,numel(timestamps));
		md.frontalforcings.meltingrate(end,:) = timestamps;

		% only set boundary conditions, so that levelset can solve for the calving front
		md.levelset.stabilization = levelsetStabilization;
		disp(['  Levelset function uses stabilization ', num2str(md.levelset.stabilization)]);
		md.levelset.reinit_frequency = levelsetReinit;
		disp(['  Levelset function reinitializes every ', num2str(md.levelset.reinit_frequency), ' time steps']);

		md.cluster = cluster;
		md.verbose.solution = 1;
		md.settings.waitonlock = waitonlock; % do not wait for complete
		md.miscellaneous.name = [savePath];
		md.toolkits.DefaultAnalysis=bcgslbjacobioptions();

		md.transient.requested_outputs={'default','IceVolume','IceVolumeAboveFloatation','MaskOceanLevelset','MaskIceLevelset'};

		nan_surf = isnan(md.geometry.surface);
		md.geometry.surface(nan_surf) = md.geometry.bed(nan_surf);
		pos = find(md.mask.ice_levelset>0);
		md.geometry.surface(pos) = md.geometry.base(pos)+10; %Minimum thickness

		md.geometry.thickness = md.geometry.surface - md.geometry.bed;
		pos=find(md.geometry.thickness<=10);
		md.geometry.surface(pos) = md.geometry.base(pos)+10; %Minimum thickness
		md.geometry.thickness = md.geometry.surface - md.geometry.bed;
		pos = find(max(md.mask.ice_levelset(md.mesh.elements),[],2)>0);
		md.mask.ice_levelset(md.mesh.elements(pos,:)) = 1;
		% For the region where surface is NaN, set thickness to small value (consistency requires >0)
		pos=find((md.mask.ice_levelset<0).*(md.geometry.surface<0));
		md.mask.ice_levelset(pos)=1;
		pos=find((md.mask.ice_levelset<0).*(isnan(md.geometry.surface)));
		md.mask.ice_levelset(pos)=1;

		md.geometry.thickness=md.geometry.surface-md.geometry.base;
		% update boundary conditions
		md.stressbalance.spcvx=NaN*ones(md.mesh.numberofvertices,1);
		md.stressbalance.spcvy=NaN*ones(md.mesh.numberofvertices,1);
		md.stressbalance.spcvz=NaN*ones(md.mesh.numberofvertices,1);
		md.stressbalance.referential=NaN*ones(md.mesh.numberofvertices,6);
		md.stressbalance.loadingforce=0*ones(md.mesh.numberofvertices,3);
		pos=find((md.mask.ice_levelset<0).*(md.mesh.vertexonboundary));
		md.stressbalance.spcvx(pos)=md.initialization.vx(pos);
		md.stressbalance.spcvy(pos)=md.initialization.vy(pos);
		md.stressbalance.spcvz(pos)=0;

		md=solve(md,'Transient','runtimename',false);
		savemodel(org,md);

		if ~strcmp(savePath, './')
			system(['mkdir -p ./Models/', savePath]);
			system(['cp ', projPath, '/Models/Model_', glacier, '_', org.steps(org.currentstep).string, '.mat ', projPath, '/Models/', savePath, '/Model_', glacier, '_Transient.mat']);
		end
	end%}}}
	if perform(org, ['Prepare_for_GNSS'])% {{{

		md=loadmodel(org,'Param_ISMIP_Rignot_SMW');

		% get the mesh
		elements=md.mesh.elements;
		x=md.mesh.x;
		y=md.mesh.y;

		%compute areas;
		eleAreas=GetAreas(elements,x,y);
		disp(['Minimum element size: ', num2str(min(eleAreas))])
		disp(['Maximum element size: ', num2str(max(eleAreas))])

		% get the center
		cx = 1/3*(x(elements(:,1)) + x(elements(:,2)) + x(elements(:,3)));
		cy = 1/3*(y(elements(:,1)) + y(elements(:,2)) + y(elements(:,3)));

		% convert to ll
		[lat, lon] = xy2ll(cx, cy, 1);

		% write to a txt file
		filename = [projPath, '/DATA/Jakobshavn.txt'];

		data = [lat, lon, eleAreas];
		% Write matrix to text file
		writematrix(data, filename, 'delimiter', '\t');

		disp(['Matrix has been written to ' filename]);

		% add damage for shear margin
		savemodel(org,md);
	end%}}}

	% step 11--15
	if perform(org, ['Transient_yearly', smb_model, suffix]),% {{{

		md=loadmodel(org, ['Set_SMB_', smb_model, suffix]);

		% step 0 
      % use only one month of the ice front position to drive the model
      if monthfront > 0
         fronttime = decyear2date(md.levelset.spclevelset(end,:));
         id = (mod(month(fronttime),12)+1 == monthfront);
         disp(['There are ' num2str(numel(fronttime)), ' front records in md.levelset.spclevelset, using month=', num2str(monthfront), ' gives ', num2str(sum(id)), ' records for the transient run']);
         temp_spclevelset = md.levelset.spclevelset(:,id);
         % append starting ice front geometry if not included
         if (temp_spclevelset(end,1) > md.levelset.spclevelset(end,1))
            md.levelset.spclevelset = [md.levelset.spclevelset(:,1), temp_spclevelset];
         else
            md.levelset.spclevelset = temp_spclevelset;
         end
      end

		md.initialization.pressure = zeros(md.mesh.numberofvertices,1); %FIXME
		md.masstransport.spcthickness = NaN(md.mesh.numberofvertices,1); %FIXME

		% Set parameters
		md.inversion.iscontrol=0;
		md.timestepping.start_time = startTime;
		md.timestepping.final_time = finalTime;
		md.timestepping.time_step  = 0.01;
		md.settings.output_frequency = 10;

		md.transient.ismovingfront=1;
		md.transient.isslc = 0;
		md.transient.isthermal=0;
		md.transient.isstressbalance=1;
		md.transient.ismasstransport=1;
		md.transient.isgroundingline=1;
		md.groundingline.migration = 'SubelementMigration';

		% calving parameters
		md.calving = calvingvonmises();
		md.calving.stress_threshold_floatingice = 200*10^3;
		md.calving.stress_threshold_groundedice = sigma*10^6; %1: a little much retreat, 0.9,0.95: too much retreat 1.2, 1.1, 1.05,1.02:less retreat:

		% meltingrate
		timestamps = [md.timestepping.start_time, md.timestepping.final_time];
		md.frontalforcings.meltingrate=zeros(md.mesh.numberofvertices+1,numel(timestamps));
		md.frontalforcings.meltingrate(end,:) = timestamps;

		% only set boundary conditions, so that levelset can solve for the calving front
		md.levelset.stabilization = levelsetStabilization;
		disp(['  Levelset function uses stabilization ', num2str(md.levelset.stabilization)]);
		md.levelset.reinit_frequency = levelsetReinit;
		disp(['  Levelset function reinitializes every ', num2str(md.levelset.reinit_frequency), ' time steps']);

		md.cluster = cluster;
		md.verbose.solution = 1;
		md.settings.waitonlock = waitonlock; % do not wait for complete
		md.miscellaneous.name = [savePath];
		md.toolkits.DefaultAnalysis=bcgslbjacobioptions();

		md.transient.requested_outputs={'default','IceVolume','IceVolumeAboveFloatation','MaskOceanLevelset','MaskIceLevelset'};

		nan_surf = isnan(md.geometry.surface);
		md.geometry.surface(nan_surf) = md.geometry.bed(nan_surf);
		pos = find(md.mask.ice_levelset>0);
		md.geometry.surface(pos) = md.geometry.base(pos)+10; %Minimum thickness

		md.geometry.thickness = md.geometry.surface - md.geometry.bed;
		pos=find(md.geometry.thickness<=10);
		md.geometry.surface(pos) = md.geometry.base(pos)+10; %Minimum thickness
		md.geometry.thickness = md.geometry.surface - md.geometry.bed;
		pos = find(max(md.mask.ice_levelset(md.mesh.elements),[],2)>0);
		md.mask.ice_levelset(md.mesh.elements(pos,:)) = 1;
		% For the region where surface is NaN, set thickness to small value (consistency requires >0)
		pos=find((md.mask.ice_levelset<0).*(md.geometry.surface<0));
		md.mask.ice_levelset(pos)=1;
		pos=find((md.mask.ice_levelset<0).*(isnan(md.geometry.surface)));
		md.mask.ice_levelset(pos)=1;

		md.geometry.thickness=md.geometry.surface-md.geometry.base;
		% update boundary conditions
		md.stressbalance.spcvx=NaN*ones(md.mesh.numberofvertices,1);
		md.stressbalance.spcvy=NaN*ones(md.mesh.numberofvertices,1);
		md.stressbalance.spcvz=NaN*ones(md.mesh.numberofvertices,1);
		md.stressbalance.referential=NaN*ones(md.mesh.numberofvertices,6);
		md.stressbalance.loadingforce=0*ones(md.mesh.numberofvertices,3);
		pos=find((md.mask.ice_levelset<0).*(md.mesh.vertexonboundary));
		md.stressbalance.spcvx(pos)=md.initialization.vx(pos);
		md.stressbalance.spcvy(pos)=md.initialization.vy(pos);
		md.stressbalance.spcvz(pos)=0;

		md=solve(md,'Transient','runtimename',false);
		savemodel(org,md);

		if ~strcmp(savePath, './')
			system(['mkdir -p ./Models/', savePath]);
			system(['cp ', projPath, '/Models/Model_', glacier, '_', org.steps(org.currentstep).string, '.mat ', projPath, '/Models/', savePath, '/Model_', glacier, '_Transient.mat']);
		end
	end%}}}
	varargout{1} = md;
	return;

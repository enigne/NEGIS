clear

% step 1: load time dependent vel obs from MEaSUREs, project to the mesh
prepareVelObs;

% step 2: compute averaged observed frontal velocity
computeFrontObs;

% step 3: prepare Monthly and yearly averaged obs
prepareMosiacVelObs_fromMEaSUREs;

% step 4: get annual average velocity from ITS_LIVE
convertITSLIVE_vel;

% step 5 project obs to flowlines
projectVelObsToFlowlines;

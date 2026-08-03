rootFolder = '/Users/chenggong/Research/';

addpath(genpath([rootFolder, '/GreenlandGlacier/']))

glacier = 'NEGIS';
stepName = 'Transient';
mdRefFrontsFolder = '20260729_NEGIS_RACMO_Budd';
refmdName = 'Param_ISMIP';

addpath(genpath([rootFolder, glacier]))
addpath(genpath([rootFolder, glacier, '/src/']))


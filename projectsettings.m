rootFolder = '/Users/chenggong/Research/';

addpath(genpath([rootFolder, '/GreenlandGlacier/']))

glacier = 'NEGIS';
stepName = 'Transient';
mdRefFrontsFolder = '20260803_NEGIS_MAR_Budd';
refmdName = 'Param_ISMIP';

addpath(genpath([rootFolder, glacier]))
addpath(genpath([rootFolder, glacier, '/src/']))


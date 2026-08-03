rootFolder = '/Users/chenggong/Research/';

addpath(genpath([rootFolder, '/GreenlandGlacier/']))

glacier = 'NEGIS';
stepName = 'Transient';
mdRefFrontsFolder = '20240911_Jakobshavn_RACMO_Budd/';
refmdName = 'Param_ISMIP';

addpath(genpath([rootFolder, glacier]))
addpath(genpath([rootFolder, glacier, '/src/']))


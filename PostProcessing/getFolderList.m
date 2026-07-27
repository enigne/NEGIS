function [folderList, nameList] = getFolderList(Id)
	%getFolderList - return the working folders
	%
	% Author: Cheng Gong
	% Last modified: 2026-07-24
	if nargin < 1
		Id = 0;
	end
	if Id == 0  % Latest test{{{
		folderList = {...
			'20260724_NEGIS_RACMO_Budd/',...
			};
		nameList = {...
			'RACMO, Budd',...
			}; %}}}
	elseif Id == -1 % -1: empty {{{
		folderList = {
		};
		nameList = {
		}; %}}}
	end
end

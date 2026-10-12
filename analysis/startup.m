% This script needs to be located in your userpath directory.
% userpath returns a user-specific folder that MATLAB® adds to the search 
% path at startup, specified as a character vector.
% Simply write userpath in your command window and the path will be shown.

% add fieldtrip toolbox (Change path to the location of the toolbox)
%--------------------------------------------------------------------------
restoredefaultpath
addpath('E:\practical_meg\fieldtrip-20250904')
ft_defaults

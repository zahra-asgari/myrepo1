% These are the global options variables. By convention, global options are
% upper case. Note that global options are NOT global variables, which are
% avoided to increase code reusability

% true if instance class output should be VERBOSE
VERBOSE = true;

% if set to true, planning site will be plotted as soon as it is generated
% note that if the instance is loaded from cache it will never be plotted
PLOT_SITE = false;

% if set to true the generator will employ instance caching
USE_CACHING = true;

% this is the export style name of figures. If left empty, a default style will be used
%FIGURE_EXPORT_STYLE = 'Polimi-ppt';
FIGURE_EXPORT_STYLE = '';

CACHE_FOLDER = 'cache/';

% consistency check: some global options combinations need to be avoided to
% avoid conflicts
if PLOT_SITE && USE_CACHING
    warning('PLOT_SITE is automatically set to false if using caches to avoid saving potentially large graphic handles')
    PLOT_SITE = false;
end

if ~isfolder(CACHE_FOLDER)
    mkdir(CACHE_FOLDER);
end

%%WARNING SILENCING SECTION

%silence warning about polyshape generation inconsistencies
warning_id = 'MATLAB:polyshape:repairedBySimplify';
warning('off',warning_id);
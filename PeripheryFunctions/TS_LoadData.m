function [TS_DataMat,TimeSeries,Operations,whatDataFile] = TS_LoadData(whatDataFile,getClustered)
% TS_LoadData   Load HCTSA data from file.
%
% Reorders a data matrix and TimeSeries and Operation structures according to the
% permutation information in the given data file (ts_clust or op_clust), or
% provided explicitly by the user.
%
%---INPUTS:
% whatDataFile: the name of the HCTSA data file to load in. Use 'norm' (default)
%               to load in HCTSA_N.mat
% getClustered: whether to reorder the structures according to a clustering
%---OUTPUTS:
% The key hctsa data objects obtained from the data source:
%       *) TS_DataMat (matrix)
%       *) TimeSeries (structure array)
%       *) Operations (structure array)
% whatDataFile, a string providing the file name of the data file used to load
%               the data

% ------------------------------------------------------------------------------
% Copyright (C) 2015, Ben D. Fulcher <ben.d.fulcher@gmail.com>,
% <http://www.benfulcher.com>
%
% If you use this code for your research, please cite:
% B. D. Fulcher, M. A. Little, N. S. Jones, "Highly comparative time-series
% analysis: the empirical structure of time series and their methods",
% J. Roy. Soc. Interface 10(83) 20130048 (2013). DOI: 10.1098/rsif.2013.0048
%
% This work is licensed under the Creative Commons
% Attribution-NonCommercial-ShareAlike 4.0 International License. To view a copy of
% this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/ or send
% a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View,
% California, 94041, USA.
% ------------------------------------------------------------------------------

%-------------------------------------------------------------------------------
% Check inputs, set defaults
%-------------------------------------------------------------------------------

if nargin < 1 || isempty(whatDataFile)
    whatDataFile = 'norm';
end
if nargin < 2 || isempty(getClustered)
    getClustered = 0;
end

%-------------------------------------------------------------------------------
% In some cases, you provide a structure with the pre-loaded data already in it
% e.g., as a whatDataFile = load('HCTSA.mat');
% In this case, no further loading is required -- just a restructuring
%-------------------------------------------------------------------------------
if isstruct(whatDataFile)
    if ~isfield(whatDataFile,{'TS_DataMat','TimeSeries','Operations'})
        error('Invalid input structure (requires TS_DataMat, TimeSeries, Operations as fields)');
    end
    TS_DataMat = whatDataFile.TS_DataMat;
    TimeSeries = whatDataFile.TimeSeries;
    Operations = whatDataFile.Operations;
    whatDataFile = '--INPUT_STRUCTURE--';
    return
end

%-------------------------------------------------------------------------------
% Use intuitive settings for HCTSA package defaults -- setting 'raw', 'norm', or 'cl'
switch whatDataFile
case {'raw','loc'} % the raw, un-normalized data:
    whatDataFile = 'HCTSA.mat';
    getClustered = 0;
case 'norm' % the normalized data:
    whatDataFile = 'HCTSA_N.mat';
    getClustered = 0;
case 'cl' % the clustered data:
    whatDataFile = 'HCTSA_N.mat';
    getClustered = 1;
end

%-------------------------------------------------------------------------------
% Check the file is a .mat file:
if ~strcmp(whatDataFile(end-3:end),'.mat')
    error('Specify a .mat filename');
end

% Load data from the file:
if ~exist(whatDataFile,'file')
    error('%s not found',whatDataFile);
end
fprintf(1,'Loading data from %s...',whatDataFile);
load(whatDataFile,'TS_DataMat','Operations','TimeSeries');
fprintf(1,' Done.\n');

%-------------------------------------------------------------------------------
% Change order according to stored clustering (if none has been run, by default
% returns the same ordering as the original dataset)
%-------------------------------------------------------------------------------
if getClustered
    % Load the clustering permutations and apply them to the data:
    load(whatDataFile,'ts_clust','op_clust')
    TS_DataMat = TS_DataMat(ts_clust.ord,op_clust.ord);
    TimeSeries = TimeSeries(ts_clust.ord);
    Operations = Operations(op_clust.ord);
end

end

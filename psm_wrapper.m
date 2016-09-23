function [ OMI_PSM ] = psm_wrapper( Data )
%PSM_WRAPPER Matlab routine that serves as an interface to the Python PSM code
%  	[ OMI_PSM ] = PSM_WRAPPER( DATA ) Takes a "Data" structure from BEHR
%  	and passes it to the PSM Python code, taking care to handle the
%  	necessary type conversions between Matlab and Python types.

E = JLLErrors;
% These are the fields required by the PSM algorithm. 
req_fields = {'TiledArea', 'TiledCornerLatitude', 'TiledCornerLongitude',...
              'FoV75Area', 'FoV75CornerLatitude', 'FoV75CornerLongitude',...
              'Latitude', 'Longitude', 'SpacecraftAltitude', 'SpacecraftLatitude',...
              'SpacecraftLongitude', 'CloudRadianceFraction', 'CloudPressure',...
              'BEHRColumnAmountNO2Trop', 'ColumnAmountNO2TropStd', 'RootMeanSquareErrorOfFit',...
              'vcdQualityFlags', 'XTrackQualityFlags', 'SolarZenithAngle',...
              'Time'};
xx = ~isfield(Data, req_fields);   
if any(xx)
    E.badinput('DATA is missing the required fields: %s', strjoin(req_fields(xx), ', '));
end

% We should remove the fields that are not required by the algorithm,
% becuase the PSM algorithm makes some assumptions about the fields
% present, which messes up the "clip_orbit" function (mainly the fields
% containing strings). We also may as well remove other unnecessary fields
% because that will reduce the time it takes to convert the Matlab types
% into Python types
fns = fieldnames(Data);
% Used to check for fill values
attributes = BEHR_publishing_attribute_table('struct');
for a=1:numel(fns)
    if ~any(strcmp(fns{a}, req_fields))
        Data = rmfield(Data, fns{a});
    else
        % Make sure that any fill values are converted to NaNs. There can
        % be some weird issues where fill values aren't caught, so
        % basically we check if the fill values are long or short (~ -32757
        % or ~ -1e30) and reject accordingly
        if attributes.(fns{a}).fillvalue < -1e29;
            filllim = -1e29;
        else
            filllim = -32767;
        end
        for b=1:numel(Data)
            Data(b).(fns{a})(Data(b).(fns{a}) <= filllim) = nan;
        end
    end
end

% Will convert Data structure to a dictionary (or list of dictionaries)
pydata = struct2pydict(Data);

% Next call the PSM gridding algorithm. Add the directory containing the
% PSM code to the Python search path if it isn't there.
psm_dir = BEHR_paths('psm');
if count(py.sys.path, psm_dir) == 0
    insert(py.sys.path, int32(0), psm_dir);
end
%mod = py.importlib.import_module('BEHRDaily_Map');
%py.reload(mod);
pgrid = py.BEHRDaily_Map.imatlab_gridding(pydata);

% Finally return the average array to a Matlab one. This provides one
% average grid for the day. We also convert the lat/lon vectors into full
% arrays to match how the OMI structure in existing BEHR files is
% organized.
OMI_PSM.BEHRColumnAmountNO2Trop = numpyarray2matarray(pgrid.values)';
OMI_PSM.Weights = numpyarray2matarray(pgrid.weights)';
OMI_PSM.Errors = numpyarray2matarray(pgrid.errors)';

lonvec = numpyarray2matarray(pgrid.lon);
latvec = numpyarray2matarray(pgrid.lat);
[longrid, latgrid] = meshgrid(lonvec, latvec);
OMI_PSM.Longitude = longrid;
OMI_PSM.Latitude = latgrid;


end


function [matpower_path, parameter_path, power_path, max_LVNs, LVN_fraction, ...
                                ramses, base, vmin, vmax, raw_data] = parameters
    % In this file, the user defines parameters concerning the load
    % disaggregation as a whole. The function should output the following
    % variables:
    %
    % matpower_path     a character vector indicating the (relative)
    %                   installation path of MATPOWER
    % parameter_path    directory that contains the injector parameters
    % power_path        directory that contains possible powers demanded by the
    %                   injectors at the time of the snapshot
    % max_LVNs          maximum number of LVNs into which any MV load can be
    %                   disaggregated
    % LVN_fraction      MVLoDis will take the original topology set T and work
    %                   with a random subset of size LVN_fraction*length(T)
    % ramses            boolean that indicates if the RAMSES output must be
    %                   generated
    % base              base in which the bus numbers will be expressed before
    %                   printing the bus names in RAMSES
    % vmin              minimum voltage allowed before changing the tap position
    %                   of the MV/LV transformers
    % vmax              same as above but maximum voltage
    % raw_data          boolean that indicates if the raw data should be
    %                   extracted

    % Fetch absolute path of this file
    this_file = which('parameters');
    this_path = [fileparts(this_file), '/'];

    % Paths
    matpower_path = [this_path, '../MATPOWER/matpower6.0'];
    parameter_path = [this_path, 'injector_pars'];
    power_path = [this_path, 'injector_power'];

    % Parameters for template set
    max_LVNs = 3;
    LVN_fraction = 0.75;

    % Boolean that chooses if results are printed in RAMSES
    ramses = true;

    % Base used for printing the bus numbers (default is 10, maximum is 36)
    base = 36;

    % Minimum and maximum voltages tolerated in LVNs before changing taps
    vmin = 0.925;
    vmax = 1.05;

    % Boolean that choses if raw data is extracted
    raw_data = true;
end

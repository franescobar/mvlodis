% This is the file that should be run by the user in order to create the
% topologies. For simplicity, the output folder has been hardcoded.

% Import external functions and MATPOWER
addpath(genpath('create_topologies'))
matpower_path = parameters;
addpath(genpath(matpower_path))

% Create set with the first n LVN topologies according to naming of DSS files
no_topologies = 14;
fprintf('Creating set with %d LVN topologies. Please wait...\n', no_topologies)
topology_set = create_topologies(14);

% Save LVN topologies to MAT-files
output_folder = '../disaggregation/created_topologies/';
for i = 1:length(topology_set)
    % Fetch topology
    mpc = topology_set{i};
    % Save with name 'topology_n' for n between 1 and N
    file_path = [output_folder, 'topology_', int2str(i), '.mat'];
    save(file_path, 'mpc');
end

fprintf('Done. Check output in %s\n', output_folder)

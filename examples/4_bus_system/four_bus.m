% This file carries out three major computations. First, it runs the power flow
% of the four-bus system as presented in Van Cutsem's textbook. Second, it
% replaces bus 3 and the transformer with a 75-bus MV network. Third, it
% disaggregates each MV load using LVNs. For illustration purposes, all loads
% are replaced simply by records of type "LOAD".
%
% A minimal interface is included, part of which can be disactivated by toggling
% the 'verbose' variable to be false.

% Ask for name of output files
name_mv = input('Name of output file for MV network: ');
name_lv = input('Name of output file for LV networks: ');
name_vol = input('Name of output file for LFRESV record of HV buses: ');;
verbose = true;

% Include MVLoDis
addpath(genpath('../..'));

% Load MATPOWER
matpower_path = parameters;
addpath(genpath(matpower_path));

% Define base quantities
transmission_kV = 230;
gen_kV = 13.8;
distribution_kV = 11;

base_MVA = 100;
stepup_MVA = 550;
stepdown_MVA = 2000;

% Model system in MATPOWER
define_constants;

X14 = 0.0277;   % combined reactance of two lines in p.u. on 100-MVA base
X24 = 0.0160;   % reactance of step-up transformer in  p.u. on 100-MVA base
X34 = 0.0040;   % reactance of step-down transformer in p.u. on 100-MVA base

n = 0.9924;

max_MVA = 2500;
mpc.baseMVA = 100;

mpc.bus(:, BUS_I) = [1; 2; 3; 4];
mpc.bus(:, BUS_TYPE) = [3; 2; 1; 1];
mpc.bus(:, PD) = [0; 0; 0; 0];
mpc.bus(:, QD) = [0; 0; 0; 0];
mpc.bus(:, GS) = [0; 0; 0; 0];
mpc.bus(:, BS) = [0; 0; 0; 0];
mpc.bus(:, BUS_AREA) = [1; 1; 1; 1];
mpc.bus(:, VM) = [1; 1; 1; 1];
mpc.bus(:, VA) = [0; 0; 0; 0];
mpc.bus(:, BASE_KV)=[transmission_kV; gen_kV; distribution_kV; transmission_kV];
mpc.bus(:, ZONE) = [1; 1; 1; 1];
mpc.bus(:, VMAX) = [1.5; 1.5; 1.5; 1.5];
mpc.bus(:, VMIN) = [0.5; 0.5; 0.5; 0.5];

mpc.branch(:, F_BUS) = [1; 1; 4; 4];
mpc.branch(:, T_BUS) = [4; 4; 2; 3];
mpc.branch(:, BR_R) = [0; 0; 0; 0];
mpc.branch(:, BR_X) = [2*X14; 2*X14; X24; X34];
mpc.branch(:, BR_B) = [0; 0; 0; 0];
mpc.branch(:, RATE_A) = [0; 0; 0; 2000];
mpc.branch(:, RATE_B) = [0; 0; 0; 2000];
mpc.branch(:, RATE_C) = [0; 0; 0; 2000];
mpc.branch(:, TAP) = [0; 0; 1.04; n];
mpc.branch(:, SHIFT) = [0; 0; 0; 0];
mpc.branch(:, BR_STATUS) = [1; 1; 1; 1];
mpc.branch(:, ANGMIN) = [-360; -360; -360; -360];
mpc.branch(:, ANGMAX) = [360; 360; 360; 360];
mpc.branch(:, PF) = [0; 0; 0; 0];
mpc.branch(:, QF) = [0; 0; 0; 0];
mpc.branch(:, PT) = [0; 0; 0; 0];
mpc.branch(:, QT) = [0; 0; 0; 0];

mpc.gen(:, GEN_BUS) = [1; 2];
mpc.gen(:, PG) = [0; 0];
mpc.gen(:, QG) = [0; 0];
mpc.gen(:, QMAX) = [max_MVA; max_MVA];
mpc.gen(:, QMIN) = [-max_MVA; -max_MVA];
mpc.gen(:, VG) = [1; 1];
mpc.gen(:, MBASE) = [max_MVA; stepup_MVA];
mpc.gen(:, GEN_STATUS) = [1; 1];
mpc.gen(:, PMAX) = [max_MVA; max_MVA];
mpc.gen(:, PMIN) = [0; 0];

% Run power flow for case A
mpc.bus(3, PD) = 1500;
mpc.bus(3, QD) =  750;
mpc.bus(1, VM) =    1.08;
mpc.bus(1, VA) =    0;
mpc.bus(2, VM) =    1.01;
mpc.gen(1, VG) =    1.08;
mpc.gen(2, PG) =  300;
mpc.gen(2, VG) =    1.01;
mpc.bus(:, BS) = [0; 0; 600; 0];

% Run power flow to initialize values
if verbose
    case_A = runpf(mpc);
    input('Press enter to continue...');
else
    evalc('case_A = runpf(mpc);');
end

% Bus names in RAMSES
RAMSES_names = ["ONE", "TWO", "THREE", "4"];

% Open output file
file = name_vol;
fid = fopen(file, 'w');
% Write headers
fprintf(fid, '# Load flow (power flow) results\n');
fprintf(fid, '# LFRESV bus_name v_magnitude (pu) v_phase (rad)\n');
fprintf(fid, '\n');
% For each bus (omit bus 3)
for j = [1, 2, 4]
    % Fetch values
    bus_name = RAMSES_names(j);
    magnitude = case_A.bus(j, VM);
    phase = case_A.bus(j, VA)*pi/180;
    % Write them to file
    fprintf(fid, 'LFRESV %s %1.8f %1.8f ;\n', bus_name, magnitude, phase);
end
% Close file
fclose(fid);

% Load MV topology (template with 75 load buses)
topology_paths = dir('*.mat');
% Extract the MATPOWER case (mpc) contained in the .mat file
variables = load(topology_paths(1).name, 'mpc');
new_topology = variables.mpc;

% Preprocess it
new_topology = remove_gens(new_topology);
new_topology = erase_loads(new_topology);
new_topology = relabel_buses(new_topology);
% Change step-down transformer
new_topology.branch(1, :) = case_A.branch(4, 1:13);
new_topology.branch(1, [F_BUS, T_BUS]) = [1, 2];
% Remove additional step-down transformer
new_topology.branch(2, :) = [];
% Change nominal voltages
new_topology.bus(1, BASE_KV) = transmission_kV;
new_topology.bus(2:end, BASE_KV) = distribution_kV;
% Adjust initial voltage to match the power flow
new_topology.bus(1, VM) = case_A.bus(4, VM);
new_topology.gen(1, VG) = case_A.bus(4, VM);
% Store it in cell
topology_set{1} = new_topology;

% Sort the branches according to F_BUS
topology_set{1}.branch(:, [F_BUS, T_BUS]);
[~, perm] = sort(topology_set{1}.branch(:, F_BUS), 1);
topology_set{1}.branch = topology_set{1}.branch(perm, :);
topology_set{1}.branch(:, [F_BUS, T_BUS]);

if verbose
    runpf(new_topology);
    input('Press enter to continue...');
else
    evalc('runpf(new_topology);');
end

% Disaggregate load at bus 3
P = case_A.branch(4, PF);
Q = case_A.branch(4, QF);
V = case_A.bus(4, VM);
A = case_A.bus(4, VA);

fprintf(['Disaggregating P = %.2f MW and Q = %.2f MW from the four-bus ', ...
         'system...\n'], P, Q);

% Specifications for consumption at MV buses
spec.inj = ["FOO"];
spec.abbr = ["F"];
spec.percentages = [50];
spec.probabilities = [1];
spec.power_accuracy = 0.1;

% Compute aggregate loads of first load bus
agg_P = -1*case_A.branch(4, PT) - 4;
agg_Q = -1*case_A.branch(4, QT) - 2;
% Force that load
[spec.inelastic_buses, spec.loads, topology_set{1}] = ...
                force_load(2, 'LOAD', 'L', spec, topology_set{1}, agg_P, agg_Q);

% Printing options
opts.print_loads = false;
opts.append = false;
opts.transformer = 'TRANSFO';

% Diversify and sort MV set (global so that it can be accessed by parallel
% calls)
global diverse_set
diverse_set = diversify_set(topology_set, 50);

% Name of disaggregated bus
load_no = '4';

% Disaggregate load into MV networks
if exist('output')
   evalc('status = rmdir(''output'', ''s'');');
end
mkdir('output')
chosen_templates = disaggregate_load(P, Q, V, A, load_no, 'output', ...
                                     name_mv, spec, opts);


% Manually remove very large loads
results = chosen_templates{1};
results.bus(2, PD) = results.bus(2, PD) - agg_P;
results.bus(2, QD) = results.bus(2, QD) - agg_Q;
chosen_templates{1} = results;

if verbose
    runpf(chosen_templates{1});
    input('Press enter to continue with MV load disaggregation...')
else
    evalc('runpf(chosen_templates{1});');
end

% Load LVNs
topology_paths = dir('../../disaggregation/created_topologies/*.mat');
topology_set = cell(length(topology_paths), 1);
for i = 1:length(topology_paths)
    % Extract the MATPOWER case (mpc) contained in each .mat file
    variables = load(topology_paths(i).name, 'mpc');
    new_topology = variables.mpc;
    topology_set{i} = new_topology;
end

% Diversify and sort set (global so that it can be accessed by parallel calls)
global diverse_set
diverse_set = diversify_set(topology_set, 1);

% Specify settings of LVNs
spec.inj = ["LOAD"];
spec.abbr = ["L"];
spec.percentages = [30];
spec.probabilities = [1];
spec.power_accuracy = 0.01;
spec.inelastic_buses = [];

opts.print_loads = true;
opts.append = true;

% For each MV network
for i = 1:length(chosen_templates)
    % For each bus
    for j = 1:size(chosen_templates{i}.bus, 1)
        % If this is a load bus
        if chosen_templates{i}.bus(j, PD) > 1e-3
            % Display some progress
            fprintf('Disaggregating load at bus %d of network %d...\n', j, i);
            % Read values
            P = chosen_templates{i}.bus(j, PD);
            Q = chosen_templates{i}.bus(j, QD);
            V = chosen_templates{i}.bus(j, VM);
            A = chosen_templates{i}.bus(j, VA);
            % Read load number
            new_load_no = name_lvbus(chosen_templates{i}.bus(j, BUS_I), i, ...
                                     load_no);
            % Disaggregate into LVNs
            disaggregate_load(P, Q, V, A, new_load_no, 'output', ...
                              name_lv, spec, opts);
        end
    end
end

fprintf('Finished disaggregation. Check RAMSES files in ''output''.\n');

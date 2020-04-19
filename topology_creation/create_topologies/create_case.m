function mpc = create_case(buses, loads, lines, z)
    % Takes the topology information and creates a MATPOWER case. For
    % simplicity, the MV and LV voltages are hardcoded. The function outputs the
    % following variable:
    %
    % mpc   a MATPOWER case (i.e. a struct) that contains the topology
    %       information. A placeholder power consumption of 1 kW is assigned to
    %       each load bus to distinguish it from non-load buses

    % Define MATPOWER constants
    define_constants;
    % Define base voltages
    LVN_kV = 0.4;
    feeder_kV = 11.0;
    % Initialize structs
    mpc.bus = zeros(length(buses)+1, VMIN);
    mpc.branch = zeros(size(lines, 1)+1, QT);
    % Define base power
    mpc.baseMVA = 100;
    % Define load buses (index is shifted to account for feeder)
    for i = 1:length(buses)
        mpc.bus(i+1, BUS_I) = i+1;
        mpc.bus(i+1, BUS_TYPE) = 1;
        % If the bus is a load bus
        if sum(loads == buses(i))
            % Naively assign 1 W to it
            dummy_power = 1e-6;
            mpc.bus(i+1, PD) = dummy_power;
            mpc.bus(i+1, QD) = dummy_power;
        % If the bus is not a load bus
        else
            % Assign to it a zero power
            mpc.bus(i+1, PD) = 0;
            mpc.bus(i+1, QD) = 0;
        end
        mpc.bus(i+1, GS) = 0;
        mpc.bus(i+1, BS) = 0;
        mpc.bus(i+1, BUS_AREA) = 1;
        mpc.bus(i+1, VM) = 1;
        mpc.bus(i+1, VA) = 0;
        mpc.bus(i+1, BASE_KV) = LVN_kV;
        mpc.bus(i+1, ZONE) = 1;
        % The voltage limits are set so as to guarantee the convergence of
        % Newton's method. This would be helpful in case a power flow needs to
        % be run at any point in the future (and indeed it will be so)
        mpc.bus(i+1, VMAX) = 1.5;
        mpc.bus(i+1, VMIN) = 0.5;
    end
    % Define lines (index is shifted to account for transformer)
    for i = 1:length(lines)
        mpc.branch(i+1, F_BUS) = lines(i, 1)+1;
        mpc.branch(i+1, T_BUS) = lines(i, 2)+1;
        % The impedances are expressed in pu with the LVN base
        mpc.branch(i+1, BR_R) = real(z(i))*mpc.baseMVA/LVN_kV^2;
        mpc.branch(i+1, BR_X) = imag(z(i))*mpc.baseMVA/LVN_kV^2;
        mpc.branch(i+1, BR_B) = 0;
        % The ratings are left as zero for unlimited
        mpc.branch(i+1, RATE_A) = 0;
        mpc.branch(i+1, RATE_B) = 0;
        mpc.branch(i+1, RATE_C) = 0;
        % For the moment, branches are lines, so that TAP = SHIFT = 0
        mpc.branch(i+1, TAP) = 0;
        mpc.branch(i+1, SHIFT) = 0;
        mpc.branch(i+1, BR_STATUS) = 1;
        % The remaining entries are left as zero, as runpf ignores them
    end
    % Include feeder bus (slack)
    mpc.bus(1, BUS_I) = 1;
    mpc.bus(1, BUS_TYPE) = 3;
    mpc.bus(1, PD) = 0;
    mpc.bus(1, QD) = 0;
    mpc.bus(1, GS) = 0;
    mpc.bus(1, BS) = 0;
    mpc.bus(1, BUS_AREA) = 1;
    mpc.bus(1, VM) = 1;
    mpc.bus(1, VA) = 0;
    mpc.bus(1, BASE_KV) = feeder_kV;
    mpc.bus(1, ZONE) = 1;
    mpc.bus(1, VMAX) = inf;
    mpc.bus(1, VMIN) = 0;
    % Load function with transformer data
    addpath('..')
    [~, possible_kVA, possible_R, possible_X] = parameters;
    % Randomize transformer data
    transformer_MVA = 0.001*possible_kVA(randi(length(possible_kVA)));
    R = possible_R(randi(length(possible_R)));
    X = possible_X(randi(length(possible_X)));
    % Include step-down transformer
    mpc.branch(1, F_BUS) = 1;
    mpc.branch(1, T_BUS) = 2;
    mpc.branch(1, BR_R) = R*mpc.baseMVA/transformer_MVA;
    mpc.branch(1, BR_X) = X*mpc.baseMVA/transformer_MVA;
    mpc.branch(1, BR_B) = 0;
    mpc.branch(1, RATE_A) = transformer_MVA;
    mpc.branch(1, RATE_B) = transformer_MVA;
    mpc.branch(1, RATE_C) = transformer_MVA;
    mpc.branch(1, TAP) = 1;
    mpc.branch(1, SHIFT) = 0;
    mpc.branch(1, BR_STATUS) = 1;
    % The remaining entries are left as zero, as runpf ignores them
    % Define generator at the feeder
    mpc.gen(1, GEN_BUS) = 1;
    mpc.gen(1, PG) = 0;
    mpc.gen(1, QG) = 0;
    mpc.gen(1, QMAX) = inf;
    mpc.gen(1, QMIN) = -inf;
    mpc.gen(1, VG) = 1;
    mpc.gen(1, MBASE) = transformer_MVA;
    mpc.gen(1, GEN_STATUS) = 1;
    mpc.gen(1, PMAX) = inf;
    mpc.gen(1, PMIN) = -inf;
end

function new_template = modify_template(old_template, new_P, new_Q, VM, VA, ...
                                        power_accuracy, inelastic_buses)
    % Modifies the loads of a template LVN so that it consumes exactly new_P
    % megawatts and new_Q megavars when connected to a bus with voltage
    % magnitude VM and voltage angle VA. The function outputs the following
    % variable:
    %
    % new_template  a MATPOWER case with the fine-grained load reallocation

    % Make desired powers and initial load accessible to other functions. This
    % apparent duplication of the arguments of the present function is
    % necessary to turn the arguments of this function into global variables,
    % to be used by secondary functions later on
    global desired_P desired_Q
    desired_P = new_P;
    desired_Q = new_Q;
    % Find initial load distribution
    global initial_load
    [initial_P, initial_Q, bus_integers] = fetch_loads(old_template);
    initial_load = [initial_P; initial_Q];
    % State initial condition and constraints for optimization problem. Notice
    % that the optimization variable x is the concatenation of the active
    % powers first and of the reactive powers second, so its size is actually
    % twice the number of loads
    x0 = initial_load;
    A = [];
    b = [];
    Aeq = [];
    beq = [];
    % To prevent any DER from not fitting in a given load bus in a subsequent
    % step, the lower bound of P and Q is set to their initial value, thus not
    % being allowed to decrease. Notice that setting the limit by multiplying
    % the initial powers also guarantees that not transit bus, which has P = 0
    % and Q = 0 initially, is allocated any power whatsoever
    lb = x0;
    % For simplicity, the optimization problem is assumed to be unbounded above
    ub = Inf + x0;
    % Tighten this bound for inelastic buses (1 would be the first load bus, but
    % not necessarily the bus with BUS_I equal to 1)
    % For each inelastic bus
    for i = 1:length(inelastic_buses)
        % We assume that the integer in inelastic_buses, which was passed by the
        % user, actually referes to the BUS_I field. Hence we only need to find
        % the index of x corresponding to the bus with BUS_I == bus.
        bus_int = inelastic_buses(i);
        bus_index_in_x = find(bus_integers == bus_int);
        % Stretch it slightly (admittedly, this multiplier was found
        % empirically)
        k = 1 + 0.5e-6;
        % Adjust lower bounds
        lb(bus_index_in_x) = x0(bus_index_in_x);
        lb(bus_index_in_x+0.5*size(lb, 1)) = x0(bus_index_in_x+0.5*size(lb, 1));
        % Adjust upper bounds
        ub(bus_index_in_x) = k*x0(bus_index_in_x);
        ub(bus_index_in_x+0.5*size(lb, 1)) = ...
                                           k*x0(bus_index_in_x+0.5*size(lb, 1));
    end
    % Make the old template available after modifying the voltage of its feeder
    global initial_template
    initial_template = modify_voltages(old_template, VM, VA);
    initial_template = modify_loads(initial_load, initial_template);
    % Set solver options
    opts = optimoptions('fmincon', ...
                        'Algorithm', 'sqp', ... % active-set
                        'Display', 'off', ...
                        'ConstraintTolerance', 1e-5, ...
                        'FunctionTolerance', 1e-2, ...
                        'OptimalityTolerance', 1e-2, ...
                        'TolConSQP', 1e-3);
    % Fetch minimum and maximum tolerated voltages
    [~, ~, ~, ~, ~, ~, ~, vmin, vmax] = parameters;
    % Find vector x with optimal load distribution
    tap = initial_template.branch(1, 9);
    attempts = 0;
    while vmin <= tap && tap <= vmax && attempts < 3
        % Run optimization
        [x, fval, exitflag] = fmincon(@f, x0, A, b, Aeq, beq, ...
                                      lb, ub, @mycon, opts);
        % Check worst voltages
        [min_voltage, max_voltage] = worst_voltages(x, initial_template);
        % If the exit flag is strictly positive (meaning, typically, that a
        % local minimum was found)
        if exitflag ~= 0 && exitflag ~= -1 && exitflag ~= -2
            % Break the loop
            break
        % Otherwise
        else
            % If voltages are both too high and too low
            if min_voltage < vmin && vmax < max_voltage
                % Give priority to correcting high voltages, which are more
                % dangerous
                tap = tap + 0.025;
                fprintf('Voltages are both too high and too low.\n')
                fprintf('Giving priority to correcting high voltages.\n')
            % Otherwise, if voltages are too low
            elseif min_voltage < vmin
                % Reduce the number of turns in the primary (high voltage)
                tap = tap - 0.025;
                fprintf('Voltages are too low. Decreasing tap position.\n')
            % Otherwise, if voltages are too high
            elseif vmax < max_voltage
                % Increase the number of turns in primary
                tap = tap + 0.025;
                fprintf('Voltages are too high. Increasing tap position.\n')
            % If voltages are neither too low nor too high
            else
                % Print message
                fprintf(['Voltages are correct but optimization probably ', ...
                         'failed.\n']);
                break
            end
            % Update the value of the tap in struct
            initial_template.branch(1, 9) = tap;
            % Count this as one attempt
            attempts = attempts + 1;
        end
    end
    if attempts > 3
        fprintf('Impossible to correct voltages. Exceeded maximum number of ')
        fprintf('attempts.\n')
    end
    % If the exitflag is still negative (no local minimum was found)
    if exitflag == 0 || exitflag == -1 || exitflag == -2
        % Display a warning
        fprintf(['Network optimization failed in spite of trying ', ...
                 'all tap positions of step-down ', ...
                 'transformer.\n'])
    end
    % Modify the template and run final power flow
    new_template = modify_loads(x, initial_template);
    evalc('new_template = runpf(new_template);');
    % Read the complex power injected by the first generator
    consumed_P = new_template.gen(1, 2);
    consumed_Q = new_template.gen(1, 3);
    % Display results
    fprintf(['Network had to demand P = %.3f MW and ', ...
             'Q = %.3f Mvar.\nIt demands P = %.3f MW and ', ...
             'Q = %.3f Mvar.\nLowest voltage is %.3f, while ', ...
             'highest voltage is %.3f.\n'], new_P, new_Q, ...
             consumed_P, consumed_Q, min_voltage, max_voltage);
end

function [load_P, load_Q, bus_integers] = fetch_loads(template)
    % Make MATPOWER's constants available
    define_constants;
    % Fetch P consumption at all buses
    all_P = template.bus(:, PD);
    % Find indices of buses with a nonzero P consumption i.e. load buses
    load_indices = find(all_P);
    % Return arrays with active and reactive power at load buses
    load_P = template.bus(load_indices, PD);
    load_Q = template.bus(load_indices, QD);
    % Fetch bus_integers of load buses
    bus_integers = template.bus(load_indices, BUS_I);
end

function new_template = modify_voltages(old_template, VM, VA)
    % Initialize new template
    new_template = old_template;
    % Change voltage of slack bus
    new_template.bus(1, 8) = VM;
    new_template.bus(1, 9) = VA;
    % Change generator voltage
    new_template.gen(1, 6) = VM;
end

function new_template = modify_loads(new_loads, old_template)
    % Make MATPOWER's constants available
    define_constants;
    % Separate the loads array, namely new_loads, into P and Q. Notice that
    % this array always has a length divisible by two, since it is formed by
    % concatenating two arrays, P and Q, of equal length
    load_P = new_loads(1:length(new_loads)/2);
    load_Q = new_loads(1+length(new_loads)/2:length(new_loads));
    % Find indices of buses with a nonzero consumption i.e. load buses
    indices = transpose(find(old_template.bus(:, PD)));
    % Initialize new template
    new_template = old_template;
    % Replace loads
    k = 0;
    for i = indices
        k = k + 1;
        new_template.bus(i, PD) = load_P(k);
        new_template.bus(i, QD) = load_Q(k);
    end
end

function sum = sum_squares(new_loads, old_loads)
    sum = 0;
    for i=1:length(new_loads)
        sum = sum + (new_loads(i) - old_loads(i))^2;
    end
end

function objective = f(x)
    global initial_load
    objective = sum_squares(x, initial_load);
end

function [c, ceq] = mycon(x)
    global initial_template desired_P desired_Q
    % Solve power flow with new loads
    evalc('solved_template = runpf(modify_loads(x, initial_template));');
    % Find power deviations between the power consumed by feeder (first entry
    % of gen field by convention) and the desired power. A factor of 100
    % multiplies the power deviations so that they be in the same order of
    % magnitude as the voltage deviations and, consequently, that the tolerance
    % given to the solver make sense for both constraints
    feeder_P = solved_template.gen(1, 2);
    feeder_Q = solved_template.gen(1, 3);
    P_deviations = 50*abs(feeder_P - desired_P);
    Q_deviations = 50*abs(feeder_Q - desired_Q);
    % Determine voltage setpoint and deadband
    [~, ~, ~, ~, ~, ~, ~, vmin, vmax] = parameters;
    v_setpoint = (vmin + vmax)/2;
    v_deadband = (vmax - vmin);
    % Find voltage deviations from setpoint at remaining buses
    number_of_buses = size(solved_template.bus, 1);
    voltage_deviations = ...
                    abs(solved_template.bus(2:number_of_buses, 8) - v_setpoint);
    % Return constrained functions
    ceq = 1e-2*[P_deviations, Q_deviations];
    c = 1e-2*5*(voltage_deviations - v_deadband/2);
end

function [min_voltage, max_voltage] = worst_voltages(x, template)
    % Make MATPOWER's constants available
    define_constants;
    % Run power flow on template
    solved_template = modify_loads(x, template);
    evalc('solved_template = runpf(solved_template);');
    % Read all voltages
    voltages = solved_template.bus(:, 8);
    % Find extrema
    min_voltage = min(voltages);
    max_voltage = max(voltages);
end

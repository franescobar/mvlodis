function diverse_set = diversify_set(topology_set, additional_topologies)
    % Diversifies the passed topology set (first argument) by adding a certain
    % number (second argument) of additional topologies. The function outputs
    % the following variable:
    %
    % diverse_set   a cell that contains MATPOWER cases.

    % Sort set according to number of loads in each topology
    topology_set = sort_set(topology_set);
    % Count number of loads in each topology and save those numbers in an array
    no_of_loads = count_loads(topology_set);
    % Determine how many subtopologies must be created from each topology and
    % how many loads should each subtopology contain (both stored in info)
    info = subtopology_info(no_of_loads, additional_topologies);
    % In order to count the total number of subtopologies, initialize counter
    set_size = 0;
    % For each topology
    for i = 1:length(info)
        % Count the number of subtopologies
        set_size = set_size + info{i}.no_of_subtopologies;
    end
    % Initialize diverse set
    diverse_set = cell(set_size, 1);
    % Initialize counter of subtopologies added to the diverse set
    included_subtopologies = 0;
    % For each topology
    for i = 1:length(info)
        % For each of the subtopologies that should be derived from the topology
        for j = 1:info{i}.no_of_subtopologies
            % Initialize subtopology as the topology itself
            subtopology = topology_set{i};
            % Remove the right number of loads
            for k = 1:info{i}.excess(j)
                subtopology = remove_load(subtopology);
            end
            % Count subtopology
            included_subtopologies = included_subtopologies + 1;
            % Add subtopology to cell
            diverse_set{included_subtopologies} = subtopology;
        end
    end
    % Sort set before returning it
    diverse_set = sort_set(diverse_set);
end

function no_of_loads = count_loads(topology_set)
    % Initialize array with no_of_loads
    no_of_loads = zeros(length(topology_set), 1);
    % For each topology
    for i = 1:length(topology_set)
        % Fetch vector of consumed power (PD = 3)
        demanded_powers = topology_set{i}.bus(:, 3);
        % Count nonzero demanded power and, thus, the number of load buses, and
        % store that number into the returned array
        no_of_loads(i) = sum(demanded_powers ~= 0);
    end
end

function sorted_set = sort_set(topology_set)
    % Initialize sorted set
    sorted_set = cell(length(topology_set), 1);
    % Count the number of loads
    no_of_loads = count_loads(topology_set);
    % Get the permutation of the indices 1...length(no_of_loads) that sorts the
    % array no_of_loads
    [A, perm] = sort(no_of_loads);
    % Use that same permutation to sort the set
    for i = 1:length(topology_set)
        sorted_set{i} = topology_set{perm(i)};
    end
end

function info = subtopology_info(no_of_loads, additional_topologies)
    % Compute maximum and minimum number of loads in any given subtopology
    min_no = min(no_of_loads);
    max_no = max(no_of_loads);
    % Generate number of loads of additional subtopologies
    required_loads = randi([min_no, max_no], additional_topologies, 1);
    required_loads = sort(required_loads);
    % Initialize info cell
    info = cell(length(no_of_loads), 1);
    % For each of the topologies
    for i = 1:length(no_of_loads)
        % Initialize array with the number of loads to be removed (excess)
        info{i}.excess = [];
        % Check all the required number of loads
        for j = 1:length(required_loads)
            % If the required number of loads is less than or equal to the
            % number of loads of this topology
            if required_loads(j) <= no_of_loads(i)
                loads_to_remove = no_of_loads(i) - required_loads(j);
                % Realize this number of loads by removing edges from the
                % current topology
                info{i}.excess = [info{i}.excess, loads_to_remove];
                % Prevent this required number of loads from being realized from
                % any subsequent topology
                required_loads(j) = max_no + 1;
            end
        end
        % In the end, add the subtopology with the same number of loads as the
        % topology itself
        info{i}.excess = [info{i}.excess, 0];
    end
    % Count the number of subtopologies for each topology
    for i = 1:length(no_of_loads)
        info{i}.no_of_subtopologies = length(info{i}.excess);
    end
end

function number = adjacent_buses(mpc, bus_index)
    % Read the bus integer (BUS_I = 1)
    bus_integer = mpc.bus(bus_index, 1);
    % Initialize counter
    number = 0;
    % For each line
    for i = 1:length(mpc.branch(:, 1))
        % Read the 'from' and 'to' buses (F_BUS = 1 and T_BUS = 2)
        from_bus = mpc.branch(i, 1);
        to_bus = mpc.branch(i, 2);
        % If either bus matches the given bus index
        if from_bus == bus_integer || to_bus == bus_integer
            % Increase the counter
            number = number + 1;
        end
    end
end

function reduced_mpc = remove_bus_and_line(mpc, bus_integer)
    % This function identifies a terminating bus (with BUS_I = bus_integer), the
    % feeder that touches that bus, and the preceding bus, which is the other
    % bus touched by the feeder. The function removes the terminating bus, the
    % feeder and, if the preceding bus was adjacent to exactly two nodes,
    % removes that bus and its feeder, and so on.
    %
    % Initialize return struct
    reduced_mpc = mpc;
    % Initialize variable that is true if there is a feeder that remains to be
    % removed
    feeder_remains = true;
    % While a feeder remains to be removed
    while feeder_remains
        % Identify terminating bus (bus to be removed)
        terminating_bus = bus_integer;
        % Search if that bus is the 'from' bus of any feeder (F_BUS = 1)
        from_buses = reduced_mpc.branch(:, 1);
        feeder_index = find(from_buses == terminating_bus);
        % If search was successful (feeder_index has nonzero length)
        if length(feeder_index) ~= 0
            % Store the 'to' bus as the preceding bus (T_BUS = 2)
            preceding_bus = reduced_mpc.branch(feeder_index, 2);
        % If the search was unsuccessful (feeder_index has zero length)
        else
            % Search if that bus is the 'to' bus of any feeder (T_BUS = 2).
            % Notice that if the index was not found in the 'from' ends, it must
            % necessarily be found in the 'to' ends, as this is guaranteed by
            % the fact that this bus is adjacent to exactly one bus
            to_buses = reduced_mpc.branch(:, 2);
            feeder_index = find(to_buses == terminating_bus);
            % Store the 'from' bus as the preceding bus (F_BUS = 1)
            preceding_bus = reduced_mpc.branch(feeder_index, 1);
        end
        % Remove the terminating bus (BUS_I = 1)
        terminating_bus_index = find(reduced_mpc.bus(:, 1) == terminating_bus);
        reduced_mpc.bus(terminating_bus_index, :) = [];
        % Remove the feeder
        reduced_mpc.branch(feeder_index, :) = [];
        % If the preceding bus is adjacent to more than one bus
        preceding_bus_index = find(reduced_mpc.bus(:, 1) == preceding_bus);
        if adjacent_buses(reduced_mpc, preceding_bus_index) > 1
            % Break the loop
            feeder_remains = false;
        % Otherwise, if the preceding bus is a load bus (PD = 3)
        elseif reduced_mpc.bus(preceding_bus_index, 3) ~= 0
            % Break the loop
            feeder_remains = false;
        % Otherwise, if the preceding bus is no load and can be removed
        else
            % Remove preceding bus during next iteration
            bus_integer = preceding_bus;
        end
    end
end

function reduced_mpc = remove_load(mpc)
    % Fetch vector of demanded powers (PD = 3)
    demanded_powers = mpc.bus(:, 3);
    % Find indices of load buses (those with a power demand other than zero)
    load_indices = find(demanded_powers ~= 0);
    % Initialize a boolean variable that controls the loop. This variable is
    % true as long as the selection of a bus has not been successul, either
    % because no attempt has been made (such as at this point) or because the
    % bus chosen at random was not a terminating bus (i.e., it is adjacent to
    % more than one bus, which is the case when the LVN template is not a tree).
    % This variable is false when the selection is succesful
    not_successful = true;
    % Initialize the returned struct
    reduced_mpc = mpc;
    % While the selection is not succesful (added iteration limit for warning)
    max_iterations = length(load_indices);
    iterations = 0;
    while not_successful
        % Count interation
        iterations = iterations + 1;
        if iterations > max_iterations
            fprintf('Warning: I tried several times to remove load buses ');
            fprintf('but failed.\n');
            fprintf('I''ll keep tring to choose load buses at random and ');
            fprintf('remove them,\n');
            fprintf('but you should consider checking your input LVNs.\n');
            fprintf('\n')
        end
        % Choose a load bus at random
        random_index = randi(length(load_indices));
        chosen_index = load_indices(random_index);
        % If the chosen bus is adjacent to exactly one bus
        if adjacent_buses(mpc, chosen_index) == 1
            % Declare the search as succesful
            not_successful = false;
            % Remove bus and line
            bus_integer = mpc.bus(chosen_index, 1);
            reduced_mpc = remove_bus_and_line(mpc, bus_integer);
            % Remove the entry from load_indices
            load_indices(random_index) = [];
        % If, instead, the chosen bus is adjacent to a number of buses other
        % than 1
        else
            % In order to check if at least one bus is a candidate to be
            % removed, initialize counter of buses that are adjacent to exactly
            % one bus
            candidates = 0;
            % For each bus
            for i = 1:length(mpc.bus(:, 1))
                % If it is adjacent to exactly one bus
                if adjacent_buses(mpc, i) == 1
                    % Count it as a candidate and break the loop
                    candidates = candidates + 1;
                    break
                end
            end
            % If there was no candidate to be removed
            if candidates == 0
                % Display a warning
                fprintf('No load can be removed from this template.\n');
                % And terminate the while loop
                not_successful = false;
            end
            % Notice that if the program did not enter the previous loop, it
            % will mean that a non candidate was chosen due to sheer luck but
            % candidates do exist indeed. Consequently, it is permitted that the
            % while loop keeps repeating until finding a candidate
        end
    end
end

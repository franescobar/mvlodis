function topology = relabel_buses(template, N)
    % Relabels the buses so that they are numbered as 1, 2..., N. The function
    % outputs the following variable:
    %
    % topology   a MATPOWER case containing the LVN topology with the new labels

    % Define MATPOWER's constants
    define_constants;
    % Initialize output variable
    topology = template;
    % Traverse the branch array
    for i = 1:size(topology.branch, 1)
        % Fetch current values
        from_bus = topology.branch(i, F_BUS);
        to_bus = topology.branch(i, T_BUS);
        % Change them by the indices
        topology.branch(i, F_BUS) = find(topology.bus(:, BUS_I) == from_bus);
        topology.branch(i, T_BUS) = find(topology.bus(:, BUS_I) == to_bus);
    end
    % Traverse the generators array
    for i = 1:size(topology.gen, 1)
        % Fetch current value
        genbus = topology.gen(i, GEN_BUS);
        % Change by the index
        topology.gen(i, GEN_BUS) = find(topology.bus(:, BUS_I) == genbus);
    end
    % Change bus array
    for i = 1:size(topology.bus, 1)
        % The int associated to each bus will be its indexs
        topology.bus(i, BUS_I) = i;
    end
end

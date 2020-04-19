function unloaded_LVN = read_LVN(line_path, linecode_path, load_path)
    % Creates the LVN topologies by calling the subordinate
    % functions find_graph, find_impedances, and create_case, located in this
    % same directory. The function outputs the following variable:
    %
    % unloaded_LVN  a MATPOWER case (i.e. a struct) that contains the LVN model.
    %               In a sense, this LVN is unloaded, since the only load
    %               allocation is a placeholder power of 1 kW at the load buses
    %               that serves the purpose of distinguishing them from
    %               non-load buses.

    % Find graph with distances as weights and remember linecodes
    [buses, loads, lines, dist, linecodes] = find_graph(line_path, load_path);
    % Scale weights so that they become complex impedances
    z = find_impedances(dist, linecodes, linecode_path);
    % Create MATPOWER case
    unloaded_LVN = create_case(buses, loads, lines, z);
end

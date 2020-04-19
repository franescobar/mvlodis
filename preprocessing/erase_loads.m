function topology = erase_loads(template)
    % Removes all loads from a given template (first argument), but leaves a
    % mark that makes it possible to identify load buses later on. The function
    % outputs the following variable:
    %
    % topology   a MATPOWER case containing the LVN topology without loads

    % Use MATPOWER's constants
    define_constants;
    % Initialize output variable
    topology = template;
    % For each bus in the topology
    for i = 1:size(topology.bus, 1)
        % If there is a non-zero consumption in this bus
        if topology.bus(i, PD) ~= 0 || topology.bus(i, PD) ~= 0
            % Overwrite those values by a mark (1 kW, selected arbitrarily)
            dummy_power = 1e-6;
            topology.bus(i, PD) = dummy_power;
            topology.bus(i, QD) = dummy_power;
        end
    end
end

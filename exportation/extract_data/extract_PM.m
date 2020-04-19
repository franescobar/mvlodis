function extract_PM(template, indices, p, specs, fid)
    % Use MATPOWER constants
    define_constants;
    % Identify load buses
    load_buses = template.bus(indices, :);
    % For each load bus
    for i = 1:size(load_buses, 1)
        % Initialize counter of demanded p
        total_p = 0;
        % For each load (injector)
        for j = 1:length(specs.inj)
            % Obtain corresponding P
            p_inj = p(i, j);
            % Update the total P
            total_p = total_p + p_inj;
        end
        % Compute mismatch
        m_p = load_buses(i, PD) - total_p;
        % Print mismatch to file
        fprintf(fid, '%.8f\n', ...
            m_p ...        % Active power (MW)
        );
    end
end

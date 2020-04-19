function extract_QM(template, indices, q, specs, fid)
    % Use MATPOWER constants
    define_constants;
    % Identify load buses
    load_buses = template.bus(indices, :);
    % For each load bus
    for i = 1:size(load_buses, 1)
        % Initialize counter of demanded p
        total_q = 0;
        % For each load (injector)
        for j = 1:length(specs.inj)
            % Obtain corresponding P
            q_inj = q(i, j);
            % Update the total P
            total_q = total_q + q_inj;
        end
        % Compute mismatch
        m_q = load_buses(i, QD) - total_q;
        % Print mismatch to file
        fprintf(fid, '%.8f\n', ...
            m_q ...        % Active power (MW)
        );
    end
end

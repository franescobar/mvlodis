function extract_Q(template, indices, q, fid, inj_column)
    % Identify load buses
    load_buses = template.bus(indices, :);
    % For each load bus
    for i = 1:size(load_buses, 1)
        % Fetch power consumed at inj_column
        q_inj = q(i, inj_column);
        % Print it
        fprintf(fid, '%.8f\n', ...
            q_inj ...        % Active power (MW)
        );
    end
end

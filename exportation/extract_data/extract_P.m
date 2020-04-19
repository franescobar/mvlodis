function extract_P(template, indices, p, fid, inj_column)
    % Identify load buses
    load_buses = template.bus(indices, :);
    % For each load bus
    for i = 1:size(load_buses, 1)
        % Fetch power consumed at inj_column
        p_inj = p(i, inj_column);
        % Print it
        fprintf(fid, '%.8f\n', ...
            p_inj ...        % Active power (MW)
        );
    end
end

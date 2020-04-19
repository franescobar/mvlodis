function extract_voltages(template, fid)
    % Define MATPOWER's constants
    define_constants;
    % For each bus (except feeder)
    for i = 2:size(template.bus, 1)
        % Print voltage magnitude
        fprintf(fid, '%.8f\n', ...
            template.bus(i, VM) ...     % Voltage magnitude (pu)
        );
    end
end

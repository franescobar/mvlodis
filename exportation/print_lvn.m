function print_lvn(template_set, indices, pnom, qnom, prob, p, q, specs, ...
                   load_no, folder, file_path, opts, total_p, total_q)
    % Prints all templates in template_set with the format required by RAMSES.
    % The function doesn't output anything.

    % Open output file
    fid = fopen([folder, '/', file_path, '.dat'], 'a');
    % Print general information regarding the load
    fprintf(fid, ['# Disaggregation of load at bus %s into %d networks. ', ...
                  'The total consumption\n# at this bus is P = %.3f MW ', ...
                  'and Q = %.3f Mvar. '], load_no, length(template_set), ...
            total_p, total_q ...
    );
    fprintf(fid, '\n');
    % For each LVN that is used to disaggregate this load
    % included_buses = 0;
    for i=1:length(template_set)
        % Identify LVN number
        lvn_no = i;
        % Compute number of loads (a useful number to have in the .dat file)
        no_of_loads = length(indices{i});
        % Print header
        fprintf(fid, ['#\n# Network no. %d of load at bus %s\n'], i, load_no);
        fprintf(fid, ['# Number of load buses: %d\n#'], no_of_loads);
        fprintf(fid, '\n');
        % Declare step-down transformer
        print_transformer(template_set{i}, fid, load_no, lvn_no, ...
                          opts.transformer);
        % Declare buses
        print_buses(template_set{i}, fid, lvn_no, load_no);
        % Declare lines
        print_lines(template_set{i}, fid, lvn_no, load_no);
        % Print voltages from load-flow calculations
        print_voltages(template_set{i}, fid, lvn_no, load_no);
        % Declare loads
        if opts.print_loads == true
            % Print loads to file
            print_loads(template_set{i}, indices{i}, pnom{i}, qnom{i}, ...
                        p{i}, q{i}, specs, fid, lvn_no, load_no);
        else
            % Do nothing
        end
        % Declare forced loads
        print_forced_loads(template_set{i}, fid, lvn_no, load_no, specs);
    end
    % Close output file
    fclose(fid);
    fclose('all');
    % Print raw data
    [~, ~, ~, ~, ~, ~, ~, ~, ~, raw_data] = parameters;
    if raw_data
        % Create folder to dump raw data in
        status = mkdir([folder, '/'], 'raw_data');
        folder_raw = [folder, '/', 'raw_data'];
        % Extract voltages
        fid = fopen([folder_raw, '/', file_path, '_volt.txt'], 'a');
        for i=1:length(template_set)
            % Print voltages from load-flow calculations
            extract_voltages(template_set{i}, fid);
        end
        % Close output file
        fclose(fid);
        % Extract P and Q for all injectors (except mismatch loads)
        for j=1:length(specs.inj)
            % Open output files
            fidp = fopen([folder_raw, '/', file_path, '_', char(specs.inj(j)), ...
                          '_P.txt'], 'a');
            fidq = fopen([folder_raw, '/', file_path, '_', char(specs.inj(j)), ...
                          '_Q.txt'], 'a');
            % Print values
            for i=1:length(template_set)
                % Print power from load-flow calculations
                inj_column = j;
                extract_P(template_set{i}, indices{i}, p{i}, fidp, inj_column);
                extract_Q(template_set{i}, indices{i}, q{i}, fidq, inj_column);
            end
            % Close output files
            fclose(fidp);
            fclose(fidq);
        end
        % Extract P and Q for mismatch impedances
        fidp = fopen([folder_raw, '/', file_path, '_MLOAD_P.txt'], 'a');
        fidq = fopen([folder_raw, '/', file_path, '_MLOAD_Q.txt'], 'a');
            for i=1:length(template_set)
                % Print power from load-flow calculations
                extract_PM(template_set{i}, indices{i}, p{i}, specs, fidp);
                extract_QM(template_set{i}, indices{i}, q{i}, specs, fidq);
            end
        % Close output files
        fclose(fidp);
        fclose(fidq);
        % Extract number of LVN
        fid = fopen([folder_raw, '/', file_path, '_LVN_NO.txt'], 'a');
        extract_LVN_no(size(template_set, 1), fid);
        fclose(fid);
        % Extract tap changes
        fid = fopen([folder_raw, '/', file_path, '_LVN_TAPCHG.txt'], 'a');
        extract_tap(template_set, fid);
        fclose(fid);
    end
end

function print_transformer(template, fid, load_no, lvn_no, transformer_type)
    % Define MATPOWER's constants
    define_constants;
    % Locate step-down transformer
    transformers = template.branch(find(template.branch(:, TAP) ~= 0), :);
    for i = 1:size(transformers, 1)
        % Take individual transformer
        transformer = transformers(i, :);
        % Parse transformer and buses names (append number to transformer)
        trfo_name = name_transformer(load_no, lvn_no);
        alphabet = 'abcdef';
        trfo_name = [trfo_name, alphabet(i)];
        from_name = name_lvbus(transformer(F_BUS), lvn_no, load_no);
        to_name = name_lvbus(transformer(T_BUS), lvn_no, load_no);
        % Define a variable that contains a single quote (this is done for
        % simplicity)
        quote = '''';
        % Extract system and step-down transformer data
        base_MVA = template.baseMVA;
        n = 1/transformer(TAP);
        S = transformer(RATE_A);
        % Print the transformer using the specified RAMSES record
        if strcmp(transformer_type, 'TRANSFO')
            % Write RAMSES record
            fprintf(fid, '%s %s %s %s %.7f %.7f %.7f %.7f %.6f %.2f %.4f %u;\n', ...
              'TRANSFO', ...    % Record name in RAMSES
              trfo_name, ....   % Transformer name
              from_name, ...    % Primary or 'from' bus
              to_name, ...      % Secondary or 'to' bus
              transformer(BR_R)*100*S/(base_MVA*n^2), ...% Resistance (%)
              transformer(BR_X)*100*S/(base_MVA*n^2), ...% Reactance (%)
              0.5*transformer(BR_B)*100*base_MVA*n^2/(S), ...% Susceptance, normally negative (%)
              0.5*transformer(BR_B)*100*base_MVA*n^2/(S), ...% Susceptance, normally negative (%)
              n*100, ...        % Present turns ratio (percentage)
              transformer(SHIFT), ...   % Phase displacement
              S, ...                    % Rated apparent power (MVA)
              transformer(BR_STATUS) ...% Breaker status (1 for closed, 0 for open)
            );
        elseif strcmp(transformer_type, 'TRFO')
          % Write RAMSES record
          fprintf(fid, '%s %s %s %s %s %s %.7f %.7f %.7f %.6f %.4f %u %u %u %u %u %u;\n', ...
              'TRFO', ...         % Record name in RAMSES
              trfo_name, ....     % Transformer name
              from_name, ...      % Primary or 'from' bus
              to_name, ...        % Secondary or 'to' bus
              quote, quote, ...   % Contolled bus (specified here as empty string)
              transformer(BR_R)*100*S/(base_MVA*n^2), ...% Resistance (%)
              transformer(BR_X)*100*S/(base_MVA*n^2), ...% Reactance (%)
              transformer(BR_B)*100*base_MVA*n^2/(S), ...% Susceptance, normally negative (%)
              n*100, ...          % Present turns ratio (percentage)
              S, ...              % Rated apparent power (MVA)
              0, ...              % Turns ratio of first LTC position (%)
              0, ...              % Turns ratio of last LTC position (%)
              0, ...              % Number of LTC positions
              0, ...              % Voltage tolerance: one half of deadband (pu)
              0, ...              % Desired voltage in the controlled bus (pu)
              transformer(BR_STATUS) ...% Breaker status (1 for closed, 0 for open)
          );
        end
    end
end

function print_buses(template, fid, lvn_no, load_no)
    % Define MATPOWER's constants
    define_constants;
    % For each bus (except feeder)
    for i = 2:size(template.bus, 1)
        % Parse bus information
        bus_name = name_lvbus(template.bus(i, BUS_I), lvn_no, load_no);
        % Write RAMSES record
        fprintf(fid, '%s %s %.1f %.6f %.6f %.6f %.6f;\n', ...
            'BUS', ...                      % Record name in RAMSES
            bus_name, ...                   % Bus name
            template.bus(i, BASE_KV), ...   % Base kV
            template.bus(i, PD), ...        % Demanded P (MW)
            template.bus(i, QD), ...        % Demanded Q (MVAr)
            template.bus(i, BS), ...        % Shunt susceptance (pu)
            template.bus(i, GS) ...         % Shunt conductance (pu)
        );
    end
end

% Add a very large number to the capacity in MVA
function print_lines(template, fid, lvn_no, load_no)
    % Define MATPOWER's constants
    define_constants;
    % Define auxiliary variables
    alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    repetitions = 0;
    past = [Inf, Inf];
    % For each branch
    for i = 1:size(template.branch, 1)
        % If this branch is a line (i.e. not a transformer)
        if template.branch(i, TAP) == 0
            % Find both ends of the line
            from_bus = template.branch(i, F_BUS);
            to_bus = template.branch(i, T_BUS);
            % Update present ends
            present = [from_bus, to_bus];
            % Determine if a suffix is required. For simplicity, this part of
            % the code assumes that if there are duplicates in the line, then
            % they are consecutive. This should be ensured by a previous
            % processing of the templates.
            if present(1) == past(1) && present(2) == past(2)
                repetitions = repetitions + 1;
            else
                repetitions = 0;
            end
            if repetitions == 0
                suffix = '';
            else
                suffix = alphabet(repetitions);
            end
            % Update past ends
            past = present;
            % Compute base impedance
            index = template.bus(:, BUS_I) == from_bus;
            z_base = template.bus(index, BASE_KV)^2/template.baseMVA;
            % Parse line information
            from_bus = name_lvbus(from_bus, lvn_no, load_no);
            to_bus = name_lvbus(to_bus, lvn_no, load_no);
            line_name = name_line(from_bus, to_bus);
            % Write RAMSES record
            fprintf(fid, '%s %s%s %s %s %.6f %.6f %.6f %.3f %.1f;\n', ...
                'LINE', ...                     % Record name in RAMSES
                line_name, ...                  % Line name
                suffix, ...                     % Suffix to avoid duplicates
                from_bus, ...                   % Name of 'from' bus
                to_bus, ...                     % Name of 'to' bus
                template.branch(i, BR_R)*z_base, ... % Total series R (ohm)
                template.branch(i, BR_X)*z_base, ... % Total series X (ohm)
                template.branch(i, BR_B)/(2*10^(-6)*z_base), ... % Half of total B (micro S)
                template.branch(i, RATE_A), ...     % Rated apparent power (MVA)
                template.branch(i, BR_STATUS) ...   % Breaker status (1 for closed, 0 for open)
            );
        end
        % If, instead, this branch is a transformer, do nothing, as the function
        % print_transformer takes care of that case
    end
end

function print_voltages(template, fid, lvn_no, load_no)
    % Define MATPOWER's constants
    define_constants;
    % For each bus (except feeder)
    for i = 2:size(template.bus, 1)
        % Parse bus information
        bus_name = name_lvbus(template.bus(i, BUS_I), lvn_no, load_no);
        % Write RAMSES record
        fprintf(fid, '%s %s %.8f %.8f;\n', ...
            'LFRESV', ...                   % Record name in RAMSES
            bus_name, ...                   % Bus name
            template.bus(i, VM), ...        % Voltage magnitude (pu)
            template.bus(i, VA)*pi/180 ...  % Voltage angle (rad)
        );
    end
end

function string = read_line(n, path)
    % Reads the n-th line of a file. Used to copy injector parameters. This one
    % is admittedly not the most efficient way in terms of time, as one could
    % store the parameters in an cell and then access them using indices
    fid = fopen(path, 'r');
    for i = 1:n
        header_line = fgetl(fid);
    end
    string = header_line;
    fclose(fid);
end

function print_loads(template, indices, pnom, qnom, p, q, specs, fid, ...
                     lvn_no, load_no)
    % Define MATPOWER's constants
    define_constants;
    % Specify directory with parameter files
    [~, par_directory, power_directory] = parameters;
    % Identify load buses
    load_buses = template.bus(indices, :);
    % For each load bus
    for i = 1:size(load_buses, 1)
        % Parse bus information
        bus_name = name_lvbus(load_buses(i, BUS_I), lvn_no, load_no);
        % Initialize counter of demanded p and q
        total_p = 0;
        total_q = 0;
        % For each load (injector)
        for j = 1:length(specs.inj)
            % Parse bus information
            injector_type = specs.inj(j);
            prefix = specs.abbr(j);
            injector_name = name_injector(prefix, bus_name);
            % Obtain corresponding P and Q
            p_inj = p(i, j);
            q_inj = q(i, j);
            % Obtain nominal powers
            pnom_inj = pnom(i, j);
            qnom_inj = qnom(i, j);
            % If the injector consumes non-zero P and Q when active
            if pnom_inj ~= 0 || qnom_inj ~= 0
                % Update the total P and Q
                total_p = total_p + p_inj;
                total_q = total_q + q_inj;
                % Find prefix
                if injector_type ~= "LOAD"
                    prefix = "INJEC ";
                else
                    prefix = "";
                end
                % Find linebreak
                if injector_type ~= "LOAD"
                    % Write initial parameters: INJEC type name bus FP FQ P Q
                    fprintf(fid, '%s%s %s %s 0. 0. %.6f %.6f\n', ...
                        prefix, ...         % Value can be 'INJEC' or ''
                        injector_type, ...  % Injector type in RAMSES
                        injector_name, ...  % Injector name
                        bus_name, ...       % Bus name
                        -p_inj, ...         % P
                        -q_inj ...          % Q
                    );
                else
                    % Write initial parameters: INJEC type name bus FP FQ P Q
                    fprintf(fid, '%s%s %s %s 0. 0. %.6f %.6f ', ...
                        prefix, ...         % Value can be 'INJEC' or ''
                        injector_type, ...  % Injector type in RAMSES
                        injector_name, ...  % Injector name
                        bus_name, ...       % Bus name
                        -p_inj, ...         % P
                        -q_inj ...          % Q
                    );
                end
                % Write remaining parameters (read from external file)
                par_file = [par_directory, '/', char(injector_type), '.txt'];
                pow_file = [power_directory, '/', char(injector_type), '.txt'];
                % Read numbers from file header
                [power_val, param_val, lines_val] = ...
                                            read_par_format(par_file, pow_file);
                % Read availabe powers
                available_powers = csvread(pow_file);
                [~, power_index] = ismember([pnom_inj, qnom_inj], ...
                                             available_powers, 'rows');
                % Choose at random a parameter set
                paramset_no = randi([1, param_val]);
                % Locate the power set (add 3 to account for header)
                starting_line = 3 + 1 + (power_index-1)*lines_val*param_val ...
                                      + (paramset_no-1)*lines_val;
                % Write the lines to the file (substract two to account for
                % empty lines)
                for k = 0:lines_val-2
                    line1 = read_line(starting_line+k, par_file);
                    % Strip spaces to the right and to the left
                    line1 = strip(line1);
                    if k == lines_val-2
                        fprintf(fid, ['    ', line1, ';\n']);
                    else
                        fprintf(fid, ['    ', line1, '\n']);
                    end
                end
            end
        end
        % Compute mismatch
        m_p = load_buses(i, PD) - total_p;
        m_q = load_buses(i, QD) - total_q;
        % If there is a mismatch
        if m_p ~= 0 || m_q ~= 0
            % Insert mismatch impedance
            mload_pars = "0. 1. 1.5 0. 0. 0. 0. 1. 2.5 0. 0. 0.";
            fprintf(fid, 'LOAD M-%s %s 0. 0. %.6f %.6f %s;\n', ...
                bus_name, ...   % Bus name (used for constructing the load name)
                bus_name, ...   % Bus name (in which the mismatch happens)
                -m_p, ...       % Mismatch P
                -m_q, ...       % Mismatch Q
                mload_pars ...  % Remaining parameters of mismatch load
            );
        end
    end
end

function print_forced_loads(template, fid, lvn_no, load_no, specs)
    % Define MATPOWER's constants
    define_constants;
    % For each bus in inelastic buses
    for i = 1:size(specs.inelastic_buses, 1)
        % Parse bus information
        bus_name = name_lvbus(specs.loads.bus, lvn_no, load_no);
        % Write RAMSES record
        fprintf(fid, '%s %s %s %s %s;\n', ...
            specs.loads.record, ...         % Record name in RAMSES
            specs.loads.name, ...           % Injector name
            bus_name, ...                   % Bus name previously obtained
            specs.loads.power, ...          % Power specifiers: FP FQ P Q
            specs.loads.pars ...            % Parameter set
        );
    end
end

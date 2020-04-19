function gen_parameteres
    % Generates missing parameter files from specification files with extension
    % '.par'

    % Fetch path of parameter and power files
    [~, parameter_path, power_path] = parameters;
    % Define extension of description files
    extension = 'par';
    % Search for description files recursively
    search_word = [parameter_path, '/**/*.', extension];
    listing = dir(search_word);
    % Build array with full path of description files
    desc_files = [];
    % For each description file found
    for i = 1:size(listing, 1)
        % If it is not a directory
        if ~listing(i).isdir
            % Build full name
            full_name = string([listing(i).folder, '/', listing(i).name]);
            % Store it in string array
            desc_files = [desc_files; full_name];
        end
    end
    % For each description file
    for i = 1:size(desc_files, 1)
        % Build path of parameter file
        desc_file = char(desc_files(i));
        par_file = [desc_file(1:end-4), '.txt'];
        % If file does not exist
        if ~isfile(par_file)
            % Create file
            fidwrite = fopen(par_file, 'w');
            % Read injector name
            [~, inj_name] = fileparts(par_file);
            % Construct power file
            power_file = [power_path, '/', inj_name, '.txt'];
            % Read initial parameters from file
            [power_val, param_val, lines_val] = read_par_format(desc_file, power_file);
            % Copy initial parameters to parameters file
            fid = fopen(desc_file);
            for j = 1:3
                tline = fgetl(fid);
                fprintf(fidwrite, [tline, '\n']);
            end
            % Read possible parameters in file
            pars = [];
            while ~feof(fid)
                tline = fgetl(fid);
                values = split(tline, '=');
                par_name = strip(values(1));
                % Include this parameter only if it is not a temporary variable
                if ~contains(par_name, 'temp')
                    pars = [pars; par_name];
                end
            end
            fclose(fid);
            % Read possible powers
            available_power = csvread(power_file);
            % For all possible powers
            for j = 1:size(available_power, 1)
                % Define variables P and Q, which were probably used in
                % description file as symbolic variables
                P = available_power(j, 1);
                Q = available_power(j, 2);
                % For each set of parameters
                for k = 1:param_val
                    % Open file
                    fid = fopen(desc_file);
                    % Advance three lines (where parameters are saved)
                    for l = 1:3
                        tline = fgetl(fid);
                    end
                    % Execute following lines
                    while ~feof(fid)
                        tline = fgetl(fid);
                        evalc(tline);
                    end
                    % Initialize maximum number of significant figures
                    max_decimals = 4;
                    % Initialize array with numeric value of parameters
                    num_pars = [];
                    % For each parameter
                    for l = 1:size(pars, 1)
                        % Fetch numeric value
                        instruction = ['temp_par = ', char(pars(l)), ';'];
                        evalc(instruction);
                        % Convert numeric value to string
                        value = strip(num2str(temp_par, '%.16f'), 'right', '0');
                        % Find position with decimal point
                        point_ind = find(value == '.');
                        % If the number has decimal part
                        if point_ind < length(value)
                            % Fetch it
                            decimal_part = value(point_ind+1:end);
                            % Find significant digits in decimal part
                            signif_digits = strip(decimal_part, 'left', '0');
                            % Determine number of digits to be removed
                            to_remove = length(signif_digits) - max_decimals;
                            % If there is at least one digit to be removed
                            if to_remove > 0
                                % Remove it
                                value = value(1:end-to_remove);
                            end
                        end
                        % Append value to array
                        num_pars = [num_pars; string(value)];
                    end
                    % Print parameters to file
                    indentation = 4;
                    max_characters = 80 - indentation;
                    printed_chars = 0;
                    used_lines = 0;
                    for l = 1:size(num_pars, 1)
                        % Count number of characters
                        char_no = length(char(num_pars(l)));
                        % If printing the following parameter will not cause
                        % the line to exceed the maximum number of characters
                        if char_no + printed_chars < max_characters
                            % Print parameter directly
                            fprintf(fidwrite, num_pars(l));
                            fprintf(fidwrite, ' ');
                        % Otherwise
                        else
                            % Jump to next line first
                            fprintf(fidwrite, '\n');
                            % Count line
                            used_lines = used_lines + 1;
                            % Reset printed characters
                            printed_chars = 0;
                            % Print parameter
                            fprintf(fidwrite, num_pars(l));
                            fprintf(fidwrite, ' ');
                        end
                        % In any case, count characters of printed parameter.
                        % The number one at the end accounts for spaces between
                        % parameters
                        printed_chars = printed_chars + char_no + 1;
                    end
                    % Insert blank lines
                    fprintf(fidwrite, '\n');
                    % Count another line
                    used_lines = used_lines + 1;
                    % Add remaining blank lines (to ensure consistency)
                    for i = 1:lines_val-used_lines
                        fprintf(fidwrite, '\n');
                    end
                    % Close file
                    fclose(fid);
                end
            end
            % Close output file
            fclose(fidwrite);
        end
    end
end

function nrmmatrix = nrmrnd(mu, sigma, sz1, sz2)
    nrmmatrix = mu + sigma*randn(sz1,sz2);
end

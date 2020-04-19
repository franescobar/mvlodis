function correct_DERD(folder)
    % This ad-hoc function corrects the files located in the given folder
    % (recursively) so that the injectors of type DER_D have a volt-var curve
    % that is centered in the initial voltage. It creates a duplicate of each
    % file and appends to them the suffix '-corrected'. The function outputs no
    % variables.

    % Define extension and suffix
    extension = 'dat';
    suffix = '-corrected';
    % Define indices of parameters that need to be changed
    indices = [3, 4];
    % Search for all files in the folder that match that extension
    search_word = [folder, '/**/*.', extension];
    listing = dir(search_word);
    % Build array with full paths
    files = [];
    % For each file found
    for i = 1:size(listing, 1)
        % If it's not a directory and doesn't contain the suffix
        if ~listing(i).isdir && ~contains(listing(i).name, suffix)
            % Build full name
            full_name = string([listing(i).folder, '/', listing(i).name]);
            % Store it in string array
            files = [files; full_name];
        end
    end
    % Build array with full paths of corrected files (including suffix)
    corrected_files = [];
    % For each file
    for i = 1:size(files, 1)
        % Initialize name as that of original file
        name = char(files(i));
        % Add suffix
        name = [name(1:length(name)-length(extension)-1), suffix, '.', ...
                extension];
        % Convert back to string
        name = string(name);
        % Store
        corrected_files = [corrected_files; name];
    end
    % Locate parameters and powers of DER_D
    listing = dir('**/DER_D.txt');
    % Create array with parameter files
    DERD_files = [];
    % For each found file with keyword
    for i = 1:size(listing, 1)
        % If it's not a directory
        if ~listing(i).isdir
            % Create full name
            full_name = string([listing(i).folder, '/', listing(i).name]);
            % Append it to string array
            DERD_files = [DERD_files; full_name];
        end
    end
    % Identify parameter and power file through their folder
    par_file = DERD_files(contains(DERD_files, 'injector_pars'));
    pow_file = DERD_files(contains(DERD_files, 'injector_power'));
    % Read numbers from header of parameter file
    [~, ~, lines_val] = read_par_format(par_file, pow_file);
    % For each original file
    for i = 1:size(files, 1)
        % Create temporal copy of original file
        temp_file = [char(files(i)), '.temp'];
        copyfile(files(i), temp_file);
        % Open original file and read all voltages
        fid = fopen(files(i), 'r');
        voltages = [];
        while ~feof(fid)
            line = fgetl(fid);
            % If line is not commented and a LFRESV was found
            if ~contains(string(line), '#') && contains(string(line), 'LFRESV')
                % Fetch bus voltage
                words = divide_string(line);
                v_magnitude = words{3};
                % Store voltage
                voltages = [voltages; str2double(v_magnitude)];
            end
        end
        % Close original file
        fclose(fid);
        % Determine maximum and minimum voltages
        min_v = min(voltages)
        max_v = max(voltages)
        % Open original and corresponding new file
        fid = fopen(files(i), 'r');
        fid2 = fopen(corrected_files(i), 'w+');
        % While end of original file has not been reached
        no_DERD = 0;
        while ~feof(fid)
            % Fetch line
            line = fgetl(fid);
            % If line is not commented and a DER_D was found
            if ~contains(string(line), '#') && contains(string(line), 'DER_D')
                % Count appearance
                no_DERD = no_DERD + 1;
                % Fetch bus name
                words = divide_string(line);
                bus_name = words{4};
                % Fetch voltage
                voltage = fetch_voltage(bus_name, temp_file);
                % Copy line to new file
                fprintf(fid2, [line, '\n']);
                % Find new parameters
                new_pars = correct_pars(voltage, min_v, max_v);
                % In order to correct parameters, initialize variables
                copied_parameters = 0;
                next_parameter = 1;
                % For each of the following lines
                for j = 1:lines_val-1
                    % Read pars in line
                    pars = divide_string(fgetl(fid));
                    % Store original line
                    original_line = join(pars);
                    original_line = original_line{1};
                    % For each parameter to be substituted
                    for k = 1:length(indices)
                        % If it's found  parameters being read
                        if copied_parameters < indices(k) && ...
                                  indices(k) <= copied_parameters + length(pars)
                            % Make the correct substitution
                            pars{indices(k)-copied_parameters} = ...
                                              num2str(new_pars(next_parameter));
                            % Count this parameter as corrected
                            next_parameter = next_parameter + 1;
                        end
                    end
                    % Join those parameters into a new line
                    new_line = join(pars);
                    new_line = new_line{1};
                    % Update number of copied parameters
                    copied_parameters = copied_parameters + length(pars);
                    % If a colon is missing
                    if original_line(length(original_line)) == ';' ...
                                            && new_line(length(new_line)) ~= ';'
                        % Add it
                        new_line = [new_line, ';'];
                    end
                    % Print line to corrected file
                    fprintf(fid2, ['    ', new_line, '\n']);
                end
            % Otherwise, if this line does not correspond to a DER_D
            else
                % Copy it immediately to new file and forget it
                fprintf(fid2, [line, '\n']);
            end
        end
        % Remember to close files
        fclose(fid);
        fclose(fid2);
        % Delete temporal file
        delete(temp_file);
        % If no DER_D were found in file, delete duplicate
        if no_DERD == 0
            delete(corrected_files(i));
        end
    end
end

function string = divide_string(string)
    % Split string using spaces as delimiters
    string = split(string);
    % Determine which positions contain empty strings
    indices = [];
    for i = 1:length(string)
        if length(string{i}) == 0
            indices = [indices; i];
        end
    end
    % Remove those positions
    string(indices, :) = [];
end

function voltage = fetch_voltage(bus_name, file)
    % Initialize voltage
    voltage = 0;
    % Open file
    fid = fopen(file, 'r');
    % For each line
    while ~feof(fid)
        % Fetch line
        line = fgetl(fid);
        % If line contains power flow result of the given bus
        if contains(line, 'LFRESV') && contains(line, bus_name)
            % Split line into words
            words = split(line);
            % Fetch third field and convert to double
            voltage = str2double(words{3});
        end
    end
    % Close file
    fclose(fid);
    % If voltage was not found
    if voltage == 0
        msg = sprintf(['\nMVLoDis error: I couldn''t find the voltage ', ...
                       'associated to bus %s in file\n', ...
                       '%s.\n'], bus_name, file);
        error(msg);
    end
end

function pars = correct_pars(terminal_voltage, min_v, max_v)
    % Define default limits of volt-var curve
    V0 = 0.98;
    V1 = 1.02;
    % Compute range width
    v_range = V1 - V0;
    % Compute relative position of voltage of this DER with respect to maximum
    % and minimum voltages in this file so that the voltage is also located in
    % that position with respect to volt-var curve
    pos = (terminal_voltage - min_v)/(max_v - min_v);
    V0 = terminal_voltage - pos*v_range;
    V1 = V0 + v_range;
    % Compute new limits so that curve is centered in terminal voltage
    % (deprecated)
    % V1 = round(terminal_voltage + v_range/2, 4);
    % V0 = round(terminal_voltage - v_range/2, 4);
    % Return parameters
    pars = [V0, V1];
end

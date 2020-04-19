function [buses, loads, lines, d, linecodes] = find_graph(line_path, load_path)
    % Reads the OpenDSS data stored in line_path and load_path and constructs
    % the topology without explicitly assigning an impedance to each branch. The
    % function outputs the following variables:
    %
    % buses     array with all bus identifiers (integers)
    % loads     array with bus identifiers that correspond to load buses
    % lines     array with 'from' buses in first column and 'to' buses in second
    %           column
    % d         array with distances associated to each line. It is indexed so
    %           that d(k) is the distance between buses lines(k)
    % linecodes array with linecodes (a DSS concept) associated to each line. It
    %           follows the same indexing convention as d

    % Read line data
    from_ends = read_values(line_path, 'bus1');
    to_ends = read_values(line_path, 'bus2');
    lines = [from_ends, to_ends];
    % Read distance and linecode data
    d = str2double(read_values(line_path, 'length'));
    linecodes = read_values(line_path, 'linecode');
    % Find bus array
    duplicate_buses = [from_ends; to_ends];
    buses = unique(duplicate_buses);
    % Read load data (without trailing .1.2.3 and without duplicates)
    duplicate_loads = read_values(load_path, 'bus1');
    loads = unique(duplicate_loads);
    for i = 1:length(loads)
        string_components = strsplit(loads(i), '.');
        loads(i) = string_components(1);
    end
    % Modify bus, line, and load arrays to use integers instead of strings
    [buses, loads, lines] = use_integers(buses, loads, lines);
end

function appearances = count_appearances(file_path, string)
    % Open file
    file = fopen(file_path);
    % Count number of file rows that begin with the given string
    appearances = 0;
    while ~feof(file)
        file_row = fgetl(file);
        % If the row being read is not empty (fgetl does not return -1)
        if file_row ~= -1
            % Search for the given string
            index = strfind(file_row, string);
            % If the string was found (i.e., if strfind returns something)
            if length(index) ~= 0
                % Count the appearance
                appearances = appearances + 1;
            end
        end
    end
    % Close file
    fclose(file);
end

function value = read_single_value(file_row, key)
    % Find starting position of key
    key_start_index = strfind(file_row, key);
    % Find starting position of value
    value_start_index = key_start_index + length(key) + length('=');
    % Find ending position of value: the index before the first space appears
    value_end_index = value_start_index;
    % While the next character is not a space
    while (file_row(value_end_index+1) ~= ' ')
        % Move one position to the right
        value_end_index = value_end_index + 1;
        % If this position is the last one in the row
        if value_end_index == length(file_row)
            % Stop reading
            break
        end
    end
    % Read value
    value = file_row(value_start_index:value_end_index);
end

function all_values = read_values(file_path, string)
    % Count appearances of given string
    appearances = count_appearances(file_path, string);
    % Initialize return array
    all_values = strings(appearances, 1);
    % Open file
    file = fopen(file_path);
    % Read values
    appearances = 0;
    while ~feof(file)
        file_row = fgetl(file);
        % If the row being read is not empty (fgetl does not return -1)
        if file_row ~= -1
            % Search for the string 'new line'
            index = strfind(file_row, string);
            % If the string was found (i.e., if strfind returns something)
            if length(index) ~= 0
                % Count appearance
                appearances = appearances + 1;
                % Store value
                all_values(appearances) = read_single_value(file_row, string);
            end
        end
    end
    % Close file
    fclose(file);
end

function [int_buses, int_loads, int_lines] = use_integers(buses, loads, lines)
    % Initialize load set
    int_loads = zeros(size(loads));
    % Traverse load set
    for i = 1:length(loads)
        % Map string of load bus to index of that string in 'buses'
        int_loads(i) = find(buses == loads(i));
    end
    % Initialize line set
    int_lines = zeros(size(lines));
    % Traverse line set
    for i = 1:size(lines, 1)
        % Identify 'from' and 'to' buses
        from_bus = lines(i, 1);
        to_bus = lines(i, 2);
        % Map string of each bus to index of that string in 'buses'
        int_lines(i, 1) = find(buses == from_bus);
        int_lines(i, 2) = find(buses == to_bus);
    end
    % Map each bus to its own index
    int_buses = transpose(1:length(buses));
end

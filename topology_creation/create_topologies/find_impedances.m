function z = find_impedances(d, linecodes, linecode_path)
    % Takes the distance d(k) associated to line k, its linecode linecodes(k),
    % and the linecode definition located in linecode_path to compute the total
    % series impedance of the line. The function outputs the following
    % variable:
    %
    % z     total series impedance. Its elements are arranged so that z(k) is
    %       the impedance of the line with distance d(k)

    % Initialize impedances
    z = zeros(length(d), 1);
    % For each length (or, equivalently, for each line)
    for i = 1:length(d)
        % Compute three-phase, abc impedance (3x3 matrix)
        z_matrix = find_impedance(linecodes(i), linecode_path);
        % Compute single-phase, positive sequence impedance (1x1)
        z_eq = find_equivalent_impedance(z_matrix);
        % Multiply distance in meters by impedance per meter to find new weight
        z(i) = z_eq*d(i);
    end
end

function z_matrix = find_impedance(linecode, linecode_path)
    % Open file
    file = fopen(linecode_path);
    % Read values
    while true
        file_row = fgetl(file);
        % If the row being read is empty
        if file_row == -1
            % Stop reading the file
            break
        % If the row is not empty
        else
            % Search for the string 'new linecode.'
            index = strfind(file_row, 'new linecode.');
            % If the string was found (i.e., strfind does not return anything)
            if length(index) ~= 0
                % See if linecode is the one specified by user
                if read_linecode(file_row, 'new linecode') == linecode
                    % Move to next row
                    file_row = fgetl(file);
                    % Read resistance matrix
                    r_matrix = read_matrix(file_row, 'rmatrix');
                    % Move to next row once again
                    file_row = fgetl(file);
                    % Read reactance matrix
                    x_matrix = read_matrix(file_row, 'xmatrix');
                    % Once the values were read, stop reading
                    break
                end
            end
        end
    end
    % Close file
    fclose(file);
    % Compute impedance matrix in ohm per km
    z_matrix = r_matrix + sqrt(-1)*x_matrix;
    % Convert impedance matrix to ohms per meter
    z_matrix = z_matrix/1000;
end

function linecode = read_linecode(line, string)
    % Find starting position of string 'linecode'
    string_start_index = strfind(line, string);
    % Find starting position of linecode name itself
    linecode_start_index = string_start_index + length(string) + length('.');
    % Find ending position of linecode: the index before the first space appears
    linecode_end_index = linecode_start_index;
    while (line(linecode_end_index+1) ~= ' ')
        linecode_end_index = linecode_end_index + 1;
        % If this position is the last one in the line
        if linecode_end_index == length(line)
            % Stop reading
            break
        end
    end
    % Read value
    linecode = line(linecode_start_index:linecode_end_index);
end

function matrix = read_matrix(file_row, name)
    % Find first square brace
    starting_index = 1;
    while true
        % If the current character is a square brace
        if file_row(starting_index) == '['
            break
        else
            starting_index = starting_index + 1;
        end
    end
    % Find last square brace
    ending_index = 1;
    while true
        % If the current character is a square brace
        if file_row(ending_index) == ']'
            break
        else
            ending_index = ending_index + 1;
        end
    end
    % Read string between the two delimiters
    string = file_row(starting_index+1:ending_index-1);
    % Split matrix into rows using '|' as delimiter
    rows = strsplit(string, '|');
    % Initialize matrix
    matrix = zeros(length(rows));
    % Traverse row data
    for i = 1:length(rows)
        % Split rows into columns using ' ' as delimiter
        data = strsplit(rows{i}, ' ');
        % Compute number of columns (a square matrix is assumed)
        number_of_columns = length(rows);
        % Traverse columns for this row
        j = 1;
        column_number = 1;
        while true
            % If this field is not empty
            if length(data{j}) ~= 0
                % Convert the value to double and store it in matrix
                matrix(i, column_number) = str2double(data{j});
                % If all columns have been filled out
                if column_number == number_of_columns
                    % Stop storing values
                    break
                % If not all columns have been filled out
                else
                    % Advance the index of the column to be filled next
                    column_number = column_number + 1;
                    % Advance the counter of field to be read
                    j = j + 1;
                end
            % If the field is empty
            else
                % Ignore it and simply advance the counter of field to be read
                j = j + 1;
            end
        end
    end
end

function z_eq = find_equivalent_impedance(z_matrix)
    % Transformation matrix from abc to 012 reference frame
    a = cosd(120) + sqrt(-1)*sind(120);
    A = [1 1 1; 1 a^2 a;1 a a^2];
    % Convert impedance matrix to 012 reference frame
    z_012 = inv(A)*z_matrix*A;
    % Fetch equivalent positive-sequence impedance
    z_eq = z_012(2, 2);
end

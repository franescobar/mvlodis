function name = name_lvbus(bus_int, lvn_no, load_no)
    % This function outputs the following variable:
    %
    % name      character array with a unique bus name

    % Define array with letters to allow alphabetic numbering
    alphabet = 'abcdefhijklmnopqrstuvwxyz';
    % If this is the first bus of the template
    if bus_int == 1
        % It should have the same name as the load being disaggregated, to make
        % the continuity possible
        name = load_no;
    % Otherwise
    else
        % Fetch base
        [~, ~, ~, ~, ~, ~, base] = parameters;
        % Convert load_no to number
        load_no = str2double(load_no);
        % Convert load_no and bus_int to that base
        load_no = base_n(load_no, base);
        bus_int = base_n(bus_int, base);
        % It should follow a naming convention. Most of the time, this is done
        % simply by concatenating indicators that make this bus unique. If the
        % number of buses is such that this name exceeds eight characters, then
        % this file should be modified
        name = [load_no, alphabet(lvn_no), bus_int];
    end
end

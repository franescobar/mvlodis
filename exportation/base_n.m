function number = base_n(x, n)
    % Changes the number x, assumed to be in base 10, to an arbitrary base n.
    % For simplicity, x can be either a double or a string. This function is
    % particularly useful to reduce the number of characters required to print a
    % given bus. The function outputs the following variable:
    %
    % number    x expressed in base n. Since n might be greater than 10, this
    %           this variable is necessarily a string.

    % Define positional characters. At the moment, there's a total of 36
    % characters. Small capitals are not used because they are reserved; they
    % are used to distinguish different LVNs connected to the same MV bus. In
    % any case, 36 characters seem to be enough
    chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    % Raise an error if there are less characters than required
    if n > length(chars)
        msg = sprintf(['MVLoDis error: I''m being told to print the bus ', ...
                       'numbers in base %d,\nbut only %d characters were ', ...
                       'defined.\n'], n, length(chars));
        error(msg);
    end
    % If the first argument is a string
    if isstring(x)
        % Convert it to double
        x = str2double(x);
    end
    % Find starting point
    j = log(x)/log(n);
    j = ceil(j);
    % Determine positional multipliers iteratively
    powers = flip(0:j);
    places = zeros(1, length(powers));
    for i = 1:size(places, 2)
        power = powers(i);
        places(i) = floor(x/(n^power));
        x = mod(x, n^power);
    end
    % Convert multipliers to characters
    number = chars(places+1);
    % If the first character is a zero, remove it
    if number(1) == '0'
        number = number(2:end);
    end
end

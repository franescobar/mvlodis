function [power_val, param_val, lines_val] = read_par_format(par_file, pow_file)
    % Reads header of file containing the parameters and returns three numbers
    % that make it possible to fetch the right parameters. After reading the
    % number of possible powers in the parameter file, the function compares
    % that number with the number of entries in the power file. If they are
    % different, an error is raised. The function outputs the following
    % variables:
    %
    % power_val     number of possible initial powers contemplated when creating
    %               the file
    % param_val     number of parameter sets for each possible initial power
    % lines_val     number of lines spanned by the parameters, including the
    %               (possible) white line

    % Read parameters from file header
    fid2 = fopen(par_file);
    while true
        line = fgetl(fid2);
        first_char = line(1);
        if first_char ~= '#'
            % Break if this line is not a hash
            break
        end
        % Fetch first five words of keyword
        key = line(3:7);
        % Fetch value
        index = strfind(line, '=');
        val = line(index+2:end);
        val = str2num(val);
        % Assign key
        switch key
            case 'power'
                power_val = val;
            case 'param'
                param_val = val;
            case 'lines'
                lines_val = val;
        end
    end
    fclose(fid2);
    % Check if any value could not be read
    if ~exist('power_val')
        msg = sprintf(['MVLoDis: It looks as if the file %s ', ...
                       'lacks a value\n', ...
                       'for the number of possible powers.\n'], ...
                        par_file);
        error(msg);
    end
    if ~exist('param_val')
        msg = sprintf(['MVLoDis: It looks as if the file %s ', ...
                       'lacks a value\n', ...
                       'for the number of parameter sets.\n'], ...
                       par_file);
        error(msg);
    end
    if ~exist('lines_val')
        msg = sprintf(['MVLoDis: It looks as if the file %s ', ...
                       'lacks a value\n', ...
                       'for the number of lines per ', ...
                       'parameter set.\n'], par_file);
        error(msg);
    end
    % Count entries in the power file
    fid2 = fopen(pow_file);
    n = 0;
    tline = fgetl(fid2);
    while ischar(tline)
        tline = fgetl(fid2);
        n = n+1;
    end
    fclose(fid2);
    if n ~= power_val
        [~, injector_type] = fileparts(par_file);
        msg = sprintf(['MVLoDis: The number of possible power ', ...
                       'values for injector %s\n', ...
                       'is ambiguous. The file %s\n', ...
                       'says it should be %d, but %d ', ...
                       'row(s) were found in\n%s\n'], ...
                       char(injector_type), par_file, power_val, ...
                       n, pow_file);
        error(msg);
    end
end

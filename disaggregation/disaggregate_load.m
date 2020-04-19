function chosen_templates = disaggregate_load(P, Q, VM, VA, load_no, ...
                                              folder, file_path, specs, opts)
    % Carries out the core functionality of the MVLoDis toolbox. Furthermore, it
    % prints the LVNs used in the disaggregation to the file specified in the
    % sixth and seventh arguments. The function outputs the following variable:
    %
    % chosen_templates  a cell containing the MATPOWER cases of the chosen
    %                   templates; this output variable might be used to couple
    %                   MVLoDis to any other MATLAB program that uses MATPOWER

    % Save current directory
    current_directory = pwd;
    % Change current directory to MVLoDis
    this_file = which('disaggregate_load');
    MVLoDis_path = [fileparts(this_file), '/../'];
    cd(MVLoDis_path);

    % Check if no options were given and use defaults
    if nargin < 9
        % No options were given
        opts.print_loads = true;
        opts.append = true;
        opts.transformer = 'TRANSFO';
    end
    % Before running, check if output folder exists
    if ~isfolder(folder)
        % Raise error
        msg = sprintf(['MVLoDis error: It looks as if the folder %s ', ...
                       'doesn''t exist.\n', ...
                       'I won''t be able to print anything.'], folder);
        error(msg);
    else
        % Delete file contents
        if opts.append == false
            delete([folder, '/', file_path, '*']);
        end
    end

    % If P to be disaggregated is negative
    if P < 0
        % Raise error
        msg = sprintf(['MVLoDis error: The MV load %s has negative P. ', ...
                       'I''m not\nready to handle that.'], load_no);
        error(msg);
    % Furthermore, if Q to be disaggregated is negative
    elseif Q < 0
        % Raise another error
        msg = sprintf(['MVLoDis error: The MV load %s has negative Q. ', ...
                       'I''m not\nready to handle that.'], load_no);
        error(msg);
    % Otherwise
    else
        % Load diverse LVN set
        global diverse_set
        % Allocate DERs
        [indices, pnom, qnom, prob, p, q, template_set] = ...
                                            allocate_loads(diverse_set, specs);

        % Take random subset based on parameter
        [~, ~, ~, ~, LVN_fraction] = parameters;
        n = floor(LVN_fraction*length(template_set));
        perm = randperm(length(template_set));
        perm = perm(1:n);
        template_set = template_set(sort(perm));
        % Apply same changes to remaining arrays
        indices = indices(sort(perm));
        pnom = pnom(sort(perm));
        qnom = qnom(sort(perm));
        prob = prob(sort(perm));
        p = p(sort(perm));
        q = q(sort(perm));

        % Identify templates with too high P or Q
        consumption = fetch_consumption(template_set);
        min_P = min(consumption(:, 1));
        power_ind = find(consumption(:, 1) == min_P);
        min_Q = min(consumption(power_ind, 2));
        too_many_LVNs = true;
        i = 1;
        while too_many_LVNs
            if consumption(i, 1) > P
                consumption(i, 1) = -1;
                i = 1;
            elseif consumption(i, 2) > Q
                consumption(i, 2) = -1;
                i = 1;
            else
                i = i + 1;
            end
            if i > size(consumption, 1)
                too_many_LVNs = false;
            end
        end

        % Remove templates with too high P or Q
        i = size(consumption, 1);
        while i > 0
            if consumption(i, 1) < 0 || consumption(i, 2) < 0
                template_set(i) = [];
                % Apply same changes to remaining arrays
                indices(i) = [];
                pnom(i) = [];
                qnom(i) = [];
                prob(i) = [];
                p(i) = [];
                q(i) = [];
            end
            i = i - 1;
        end

        % Fetch maximum number of LVNs a MV load can be disaggregated into
        [~, ~, ~, max_LVNs] = parameters;

        % Raise error if the template set is empty at this point
        if size(fetch_consumption(template_set), 1) == 0
            msg = sprintf(['MVLoDis error: The MV load %s is probably ', ...
                           'too small to\nbe disaggregated into existing ', ...
                           'LVNs. Try a different load\nand DER ', ...
                           'allocation.\nI was trying to disaggregate ', ...
                           'P = %.3f MW and Q = %.3f MVAr, but the ', ...
                           'smallest\ntemplate I have available demands ', ...
                           'P = %.3f MW and Q = %.3f MVAr.'], ...
                           load_no, P, Q, min_P, min_Q);
            error(msg);
        end

        % Remove small LVNs based on P
        too_many_LVNs = true;
        while too_many_LVNs
            [n, ind_min] = possible_lvn_no('P', P, template_set);
            if n > max_LVNs
                template_set(ind_min) = [];
                % Apply same changes to remaining arrays
                indices(ind_min) = [];
                pnom(ind_min) = [];
                qnom(ind_min) = [];
                prob(ind_min) = [];
                p(ind_min) = [];
                q(ind_min) = [];
            else
                too_many_LVNs = false;
            end
        end

        % Remove small LVNs based on Q
        too_many_LVNs = true;
        while too_many_LVNs
            [n, ind_min] = possible_lvn_no('Q', Q, template_set);
            if n > max_LVNs
                template_set(ind_min) = [];
                % Apply same changes to remaining arrays
                indices(ind_min) = [];
                pnom(ind_min) = [];
                qnom(ind_min) = [];
                prob(ind_min) = [];
                p(ind_min) = [];
                q(ind_min) = [];
            else
                too_many_LVNs = false;
            end
        end

        % Choose templates
        [chosen_templates, ind] = choose_templates(P, Q, VM, VA, ...
                                                   template_set, ...
                                                   specs.power_accuracy, ...
                                                   specs.inelastic_buses);

        % Raise error if no template can disaggregate the given load
        % (presumably because it's too small)
        if length(chosen_templates) == 0
            msg = sprintf(['MVLoDis error: The load at bus %s is either ', ...
                           'too small or too big to\nbe disaggregated into ',...
                           'existing networks as the posprocessed\nset is ', ...
                           'empty. Try a different load and DER ', ...
                           'allocation.\n'], load_no);
            error(msg);
        % Otherwise
        else
            % Print output to file
            [~, ~, ~, ~, ~, ramses] = parameters;
            if ramses
            print_lvn(chosen_templates, indices(ind), pnom(ind), qnom(ind), ...
                      prob(ind), p(ind), q(ind), specs, load_no, ...
                      folder, file_path, opts, P, Q);
            end
        end
    end

    % Return to original path
    cd(current_directory);
end

function consumption = fetch_consumption(template_set)
    % Fetch number of templates and initialize set with consumptions
    number_of_templates = length(template_set);
    consumption = zeros(number_of_templates, 2);
    % For each template
    for i = 1:number_of_templates
        % Read the complex power injected by the first generator
        consumed_P = template_set{i}.gen(1, 2);
        consumed_Q = template_set{i}.gen(1, 3);
        % Save both P and Q to the set
        consumption(i, :) = [consumed_P, consumed_Q];
    end
end

function [n, ind_min] = possible_lvn_no(power, value, template_set)
    % Fetch power consumptions of template set
    consumption = fetch_consumption(template_set);
    % If counting the LVNs with active power under a certain number
    if power == 'P'
        % Fetch original index with minimum P
        ind_min = find(consumption(:, 1) == min(consumption(:, 1)));
        % Sort consumption based on P
        [~, ind] = sort(consumption(:, 1));
        consumption = consumption(ind, 1);
    % If counting reactive power
    elseif power == 'Q'
        % Fetch original index with minimum Q
        ind_min = find(consumption(:, 2) == min(consumption(:, 2)));
        % Sort consumption based on Q
        [~, ind] = sort(consumption(:, 1));
        consumption = consumption(ind, 1);
    end
    % Find n such that the first n templates demand more than the given value
    n = 0;
    while true
        if n >= size(template_set, 1)
            % This case is added to prevent an infinite loop when the template
            % set is too small. In this case, the function returns n equal to
            % the size of the template set, which is indeed the number of
            % possible topologies that could be included in the optimal solution
            break
        elseif sum(consumption(1:n+1)) > value
            % Exit loop with current value of n
            break
        else
            % Increase counter
            n = n + 1;
        end
    end
end

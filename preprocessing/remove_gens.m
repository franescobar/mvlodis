function topology = remove_gens(template, N, kept_buses)
    % Removes N (second argument) generators from the given template (first
    % argument), thus leaving only a bare topology. If the second argument is
    % not passed, then all generators are removed. The third argument makes sure
    % that the generators connected to the specified buses are not disconnected.
    % By default, bus_indices will be taken to be [i], where [i] is the index of
    % the slack bus. The function outputs the following variable:
    %
    % topology   a MATPOWER case containing the LVN topology without generators

    % Use MATPOWER's constants
    define_constants;
    % Initialize output variable
    topology = template;
    % If the second argument was not passed
    if nargin < 2
        % Count all generators except for the slack bus
        N = length(template.gen) - 1;
        % Raise a message
        fprintf('Removing all generators from this template...\n');
    % Otherwise
    else
        % Raise a message anyway
        fprintf('Removing %d generators at random from this template...\n', ...
                N);
    end
    % If the third argument was not passed
    if nargin < 3
        % Initialize it as empty array
        kept_buses = [];
    end
    % Find integer associated to slack bus
    slack_index = find(template.bus(:, BUS_TYPE) == 3);
    slack_integer = template.bus(slack_index, BUS_I);
    % Add slack bus to specified buses and remove duplicates
    kept_buses = [slack_integer, kept_buses];
    kept_buses = unique(kept_buses);
    % Fetch buses of all available generators
    gen_buses = template.gen(:, GEN_BUS);
    % Ignore those generators in buses that must be kept
    [removable_buses, ind] = setdiff(gen_buses, kept_buses);
    % Compare the size of removable buses and the number to be removed
    if length(removable_buses) < N
        % And, if there are not enough buses, raise a warning
        msg = sprintf(['MVLoDis warning: I was asked to remove %d ', ...
                       'generators\nfrom a template, but the template ', ...
                       'only has %d generators\nand I was asked to keep ', ...
                       '%d of them (one of which is the slack bus).\n', ...
                       'I''ll simply remove as many generators as I can, ', ...
                       'which is %d.'], ...
                        N, length(gen_buses), length(kept_buses), ...
                        length(removable_buses));
        warning(msg);
        % And correct N
        N = length(removable_buses);
    end
    % Choose N generators (their indices) at random to be removed
    perm = randperm(length(ind));
    perm = perm(1:N);
    removed_indices = ind(perm);
    % Remove those generators from the template
    topology.gen(removed_indices, :) = [];
end

function [networks, indices] = choose_templates(P, Q, VM, VA, template_set, ...
                                                power_accuracy, ...
                                                inelastic_buses)
    % Returns a subset of the LVN set (last argument) such that the networks in
    % this subset, when connected in parallel to a bus with voltage magnitude VM
    % and voltage phase VA, consume exactly P megawatts and Q megavars. The
    % function outputs the following variables:
    %
    % networks      a cell containing the MATPOWER cases of the selected
    %               templates; these templates have already undergone the
    %               fine-grained reallocation
    % indices       an array that indicates which LVNs were chosen from the LVN
    %               set; this information is stored as indices and will be
    %               required later on in order to fetch the probability
    %               functions, the distribution functions, and so on

    % Find a suitable subset of templates and the desired power for each of them
    % so that, together, they consume exactly P + jQ
    fprintf('Choosing topologies from the template set...\n');
    [chosen_templates, new_P, new_Q, indices] = split_load(P, Q, ...
                                                           template_set, ...
                                                           power_accuracy);
    % Modify each one of the chosen templates
    number_of_templates = length(chosen_templates);
    networks = cell(number_of_templates, 1);
    for i = 1:number_of_templates
        % Display some progress
        fprintf('Processing template %d of %d...\n', i, number_of_templates);
        % Modify the template
        old_network = chosen_templates{i};
        networks{i} = modify_template(old_network, new_P(i), new_Q(i), VM, ...
                                      VA, power_accuracy, inelastic_buses);
    end
end

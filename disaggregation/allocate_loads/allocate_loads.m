function [indices, pnom, qnom, prob, p, q, templates] = ...
                                                allocate_loads(topologies, spec)
    % Allocates loads in a topology set (first argument) according to some
    % statistical specifications (second arugment).  The function outputs the
    % following variables:
    %
    % indices       a cell containing one vector per topology, which includes
    %               the indices of the load buses in that topology
    % pnom          a cell containing one matrix per topology, which represents
    %               the function pnom(k, d); basically, pnom(k, d) is the rated
    %               power of the DER (or load) of type d located at bus k
    % qnom          same as pnom but with reactive power
    % prob          same as pnom but with the probability that the DERs are on
    % p             same as pnom but with the power consumed at the time of the
    %               snapshot
    % q             same as p but with reactive power
    % templates     cell containing the MATPOWER cases of the topologies with
    %               realistic load allocation

    % Make MATPOWER's constants available
    define_constants;
    % Initialize cell to store indices of load buses in each template
    indices = cell(length(topologies), 1);
    % Initialize cell to store probability functions pi(k, d) for each template
    prob = cell(length(topologies), 1);
    % Initialize cell to store functions pnom(k, d) and qnom(k, d) for each
    % template. These functions will be stored later on in arrays, thus serving
    % as look-up tables
    pnom = cell(length(topologies), 1);
    qnom = cell(length(topologies), 1);
    % Initialize cell to store the p and q functions
    p = cell(length(topologies), 1);
    q = cell(length(topologies), 1);
    % Initialize cell for templates with allocated powers
    templates = cell(length(topologies), 1);
    % For each topology
    for i = 1:length(topologies)
        % Find the number of loads
        all_buses = topologies{i}.bus;
        dummy_power = 1e-6;
        load_indices = find(all_buses(:, PD) == dummy_power);
        no_of_loads = length(load_indices);
        % Append load indices to cell
        indices{i} = load_indices;
        % Initialize functions
        prob{i} = zeros(no_of_loads, length(spec.inj));
        pnom{i} = zeros(no_of_loads, length(spec.inj));
        qnom{i} = zeros(no_of_loads, length(spec.inj));
        p{i} = zeros(no_of_loads, length(spec.inj));
        q{i} = zeros(no_of_loads, length(spec.inj));
        % For each injector type
        for j = 1:length(spec.inj)
            % Fetch the injector name, assigned percentage, and probability
            inj_name = spec.inj(j);
            inj_per = spec.percentages(j);
            inj_prob = spec.probabilities(j);
            % Take enough random samples of P and Q (using a given distribution)
            % to allocate injectors of that type in the given percentage of
            % buses
            [samples_p, samples_q] = sample(inj_name, inj_per, no_of_loads);
            % Save those samples to the pnom(k, d) and qnom(k, d) functions
            pnom{i}(:, j) = samples_p;
            qnom{i}(:, j) = samples_q;
            % For each bus
            for k = 1:no_of_loads
                % Generate random number between 0 and 1
                r = rand;
                % If the random number is below the probability
                if rand < inj_prob
                    % Then this injector is active, as a fraction inj_prob of
                    % the DERs will satisfy this condition
                    prob{i}(k, j) = 1;
                % If the random number is, instead, above the probability
                else
                    % This injector is iddle
                    prob{i}(k, j) = 0;
                end
                % Generate the true power
                p{i}(k, j) = pnom{i}(k, j)*prob{i}(k, j);
                q{i}(k, j) = qnom{i}(k, j)*prob{i}(k, j);
            end
        end
        % Having allocated all the DER types, compute the total power consumed
        % at each load bus. Notice that at the household level it is not
        % required to run a power flow to find the total consumption of the
        % feeder; instead, powers can be added algebraically. Notice that the
        % sum is carried out over all possible DER types, namely, the second
        % coordinate
        load_p = sum(p{i}, 2);
        load_q = sum(q{i}, 2);
        % Assign these loads to the template
        new_template = modify_loads(topologies{i}, load_p, load_q);
        % Run a power flow and store the result in the templates cell
        evalc('templates{i} = runpf(new_template);');
    end
end

function new_template = modify_loads(old_template, p_load, q_load)
    % Make MATPOWER's constants available
    define_constants;
    % Initialize the template
    new_template = old_template;
    % Find indices of load buses
    dummy_power = 1e-6;
    all_buses = new_template.bus;
    indices = find(all_buses(:, PD) == dummy_power);
    % Assign the corresponding power to those buses
    new_template.bus(indices, PD) = new_template.bus(indices, PD) ...
                                  - dummy_power + p_load;
    new_template.bus(indices, QD) = new_template.bus(indices, QD) ...
                                  - dummy_power + q_load;
end

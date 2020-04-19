function [samples_p, samples_q] = sample(inj_name, inj_per, no_of_loads);
    % Reads the possible active and reactive powers from ../../injector_power
    % and generates enough pairs (p, q) so that the given percentage (second
    % argument) of load buses (which add up to a total equal to the third
    % argument) posses an given load type (third argument). The function
    % outputs the following variables:
    %
    % samples_p     a vector of length equal to the number of load buses, which
    %               contains the P consumed by the injector at each load bus
    % samples_q     same as samples_p but with Q

    % Compute the number of samples
    no_of_samples = floor(inj_per*no_of_loads/100);
    % Take that many samples
    [samples_p, samples_q] = generate_power(inj_name, no_of_samples);
    % Distribute them randomly among the loads
    [samples_p, samples_q] = distribute(samples_p, samples_q, no_of_loads);
end

function [samples_p, samples_q] = generate_power(inj_name, no_of_samples)
    % Initialize sample arrays
    samples_p = zeros(no_of_samples, 1);
    samples_q = zeros(no_of_samples, 1);
    % Construct path where available powers should be saved
    [~, ~, power_path0] = parameters;
    power_path = strcat(power_path0, '/', inj_name, '.txt');
    % If file exists
    if isfile(power_path)
        % Initialize available powers
        available_powers = csvread(power_path);
        % For each sample to be obtained
        for i = 1:no_of_samples
            % Select complex power at random
            random_index = randi(size(available_powers, 1));
            % Store it into the samples vectors
            samples_p(i) = available_powers(random_index, 1);
            samples_q(i) = available_powers(random_index, 2);
        end
    else
        % Raise warning
        msg = sprintf(['MVLoDis error: It looks as if the file %s does\n', ...
                       'not exist. Remember that MVLoDis will allocate ', ...
                       'loads of type %s\nonly if a file %s.txt exists in ', ...
                       'the folder %s.'], power_path, inj_name, ...
                                          inj_name, power_path0);
        error(msg);
    end
end

function [p, q] = distribute(samples_p, samples_q, no_of_loads)
    % Initialize vector of load powers (including all load nodes)
    p = zeros(no_of_loads, 1);
    q = zeros(no_of_loads, 1);
    % For each sampled power
    for i = 1:size(samples_p)
        % Store it in the samples vectors in order
        p(i) = samples_p(i);
        q(i) = samples_q(i);
    end
    % Finally, in order to introduce some randomness, create a random
    % permutation of the p and q vectors and apply the same permutation to both
    % p and q
    perm = randperm(length(p));
    p = p(perm);
    q = q(perm);
end

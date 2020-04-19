function [chosen_templates, new_P, new_Q, indices] = ...
                                split_load(P, Q, template_set, power_accuracy)
    % Takes P and Q (first and second arguments), converts them into integers
    % using the specified power accuracy (fourth argument), and chooses subset
    % of the template set which optimally disaggregates P and Q. The function
    % outputs the following variables
    %
    % chosen_templates      a cell containing the MATPOWER cases of the selected
    %                       templates
    % new_P                 the i-th template in chosen_template should reach
    %                       this power after the fine-grained load reallocation
    % new_Q                 same as new_P but with Q
    % indices               array containing the indices of the
    %                       chosen_templates; this is useful for fetching, among
    %                       other information, the probability function of each
    %                       template

    % Build set of pairs (P, Q) whose subset must be found
    power_set = fetch_consumption(template_set);
    % Define precision in MW to turn all involved quantities into integers
    precision = P*power_accuracy*0.5;
    % Convert power set to integers
    X = round(power_set/precision);
    % Convert desired active and reactive powers to integers as well
    int_P = round(P/precision);
    int_Q = round(Q/precision);
    % Form the target vector
    T = [int_P, int_Q];
    % Solve the subset-sum problem and return the indices (called 'ind')
    indices = subset_sum(X, T);
    % Return chosen templates
    chosen_templates = template_set(indices);
    % Return arrays with desired P and Q (new_P and new_Q, respectively) for
    % each template
    chosen_P = power_set(indices, 1);
    chosen_Q = power_set(indices, 2);
    new_P = chosen_P*P/sum(chosen_P);
    new_Q = chosen_Q*Q/sum(chosen_Q);
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

function d = distance(target, vec)
    % The following weights can, when different, distort the traditional
    % distance so as to penalize harder either mismatches in P or in Q. It is
    % recommended to simply change the weight for P (usually larger than 1) and
    % leave the weight for Q fixed at 1
    weight_p = 1;
    weight_q = 1;
    d = weight_p^2*(target(1) - vec(1))^2 + weight_q^2*(target(2) - vec(2))^2;
end

function sum = optimal_sum(target, vec_a, vec_b)
    % If the first vector exceeds at least one component of the target, return
    % the other
    if vec_a(1) > target(1) || vec_a(2) > target(2)
        sum = vec_b;
    % Since there should exist a symmetry between the vectors being compared
    % (not the target), test again for vec_b
    elseif vec_b(1) > target(1) || vec_b(2) > target(2)
        sum = vec_a;
    % If no vector exceeds the target
    else
        % Use the generalized distance as the metric to be minimized and,
        % therefore, as criterion to choose the optimal sum
        if distance(target, vec_a) < distance(target, vec_b)
            sum = vec_a;
        else
            sum = vec_b;
        end
    end
end

function indices = subset_sum(X, T)
    % Initialise the OPT and POINT functions
    OPT = -1*ones(size(X, 1)+1, T(1)+1, T(2)+1, 2);
    POINT = -1*ones(size(X, 1)+1, T(1)+1, T(2)+1, 3);
    % Carry out dynamic programming solution
    for j = 0:size(X, 1)
        for tx = 0:T(1)
            for ty = 0:T(2)
                % Form target vector for subproblem
                t = [tx, ty];
                % If the cases being analyzed are the base cases
                % if j == 0 || sum(t == 0) == length(t)
                if j == 0 || sum(t == 0) == length(t)
                    % Then the optimal sum is the zero vector. Note that the
                    % indices must be shifted by 1 to conform to MATLAB's
                    % indexing convention
                    OPT(j+1, tx+1, ty+1, :) = [0, 0];
                % Otherwise, apply recursive relations
                else
                    % Compute components of present Xj
                    X_jx = X(j, 1);
                    X_jy = X(j, 2);
                    % If either component is larger than the corresponding
                    % component of the target vector
                    if X_jx > tx || X_jy > ty
                        % Then the optimal sum is the one obtained without the
                        % present Xj
                        OPT(j+1, tx+1, ty+1, :) = OPT(j, tx+1, ty+1, :);
                    % If, instead, both components are smaller than the
                    % corresponding components of the target vector
                    else
                        % Then the solution is not straightforward and the
                        % optimal must be found by evaluating the two options.
                        % Notice that size mismatches make some reshaping
                        % necessary before adding the arrays
                        sum_1 = OPT(j, tx+1, ty+1, :);
                        sum_1 = reshape(sum_1, [1, 2]);
                        temp = OPT(j, tx-X_jx+1, ty-X_jy+1, :);
                        temp = reshape(temp, [1, 2]);
                        sum_2 = X(j, :) + temp;
                        OPT(j+1, tx+1, ty+1, :) = optimal_sum(t, sum_1, sum_2);
                        % If sum_1 was chosen
                        if reshape(OPT(j+1, tx+1, ty+1, :), [1, 2]) == sum_1
                            % Then X_j does not belong to the optimal subset;
                            % save pointer with relevant indices j, tx, and ty
                            % to the corresponding subproblem. These indices
                            % are stored without shifting by 1, as this will be
                            % done when they are used
                            POINT(j+1, tx+1, ty+1, :) = [j-1, tx, ty];
                        % Otherwise, if the second option, sum_2, was chosen
                        else
                            % Then X_j belongs to the optimal subset; save
                            % pointer with relevant indices j, tx, and ty to
                            % the corresponding subproblem
                            POINT(j+1, tx+1, ty+1, :) = [j-1, ...
                                                         tx-X_jx, ...
                                                         ty-X_jy];
                        end
                    end
                end
            end
        end
    end
    % Traverse POINT, starting from one corner, to find the optimal subset
    current_j = size(X, 1);
    current_tx = T(1);
    current_ty = T(2);
    solution = -1*ones(1, size(X, 1));
    chosen_elements = 0;
    % While not at the origin
    while sum([current_j, current_tx, current_ty] == 0) < 3
        % Read pointer saved at the current position
        next_j = POINT(current_j+1, current_tx+1, current_ty+1, 1);
        next_tx = POINT(current_j+1, current_tx+1, current_ty+1, 2);
        next_ty = POINT(current_j+1, current_tx+1, current_ty+1, 3);
        % If next position (indicated by the pointer) was unchanged
        if sum([next_tx, next_ty] == -1) == 2
            % Break the loop if current_j is zero
            if current_j == 0
                break
            % Otherwise, update it
            else
                current_j = current_j - 1;
            end
        % If, instead, next position was indeed changed
        else
            % And it points to a subproblem with a different target vector
            if next_tx ~= current_tx || next_ty ~= current_ty
                % Then X_j belongs to the solution
                chosen_elements = chosen_elements + 1;
                solution(chosen_elements) = current_j;
            end
            % In any case, update j, tx, and ty to move to the next position
            current_j = next_j;
            current_tx = next_tx;
            current_ty = next_ty;
        end
    end
    % Return indices of elements conforming the optimal subset
    indices = solution(find(solution ~= -1));
end

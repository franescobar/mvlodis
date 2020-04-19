function built_graph = build_graph(coordinates_path, substation_path)
    full_graph = build_full_graph(coordinates_path);
    contracted_graph = contract_graph(full_graph);
    graph_with_feeder = add_feeder(contracted_graph, substation_path);
    graph_with_feeder.intermediate_from
    graph_with_feeder.intermediate_to
    relabeled_graph = relabel_graph(graph_with_feeder);
    relabeled_graph.vertices
    relabeled_graph.intermediate_from
    relabeled_graph.intermediate_to
    % assign_fractions(relabeled_graph);
    % built_graph = assign_fractions(contracted_graph);
    return
    G = graph(relabeled_graph.from, relabeled_graph.to);
    P = plot(G);
    LVN = read_LVN('OpenDSS_data/LINES_LV_2.dss', ...
    'OpenDSS_data/linecode_declare.dss', ...
    'OpenDSS_data/OBJECT_LV_2.dss');
    define_constants;
    LVN_from = LVN.branch(:, F_BUS);
    LVN_to = LVN.branch(:, T_BUS);
    G1 = graph(relabeled_graph.from, relabeled_graph.to)
    % plot(G1)
    % figure
    G2 = graph(LVN_from, LVN_to)
    % plot(G2)
    % Find isomorphism
    P = isomorphism(G1, G2)
    % figure
    G = graph(relabeled_graph.from, relabeled_graph.to);
    P = plot(G);
    figure
    G2 = graph(contracted_graph.from, contracted_graph.to);
    P2 = plot(G2);

    % % [contracted_graph.from, contracted_graph.to]
    % ind = find(contracted_graph.to == 190)
    % get_intermediate_edges(ind(3), contracted_graph)
    % labelnode(P2, 1:size(full_graph.vertices), 1:size(full_graph.vertices))
    % sum(degree(G2) == 2)
    %
    % built_graph = 0;

    % With another function, sort the branches and assign fractions between
    % max_opacity and min_opacity according to distances (do some interpolation)
    % ... That is, separate the creation of the contracted graph from things
    % related to printing
end

function d = distance(P1, P2)
    % Compute euclidean distance
    dsquared = (P2(1)-P1(1))^2 + (P2(2)-P1(2))^2;
    d = sqrt(dsquared);
end

function [bool, first_pos] = exists(P, vertex_coord)
    % Initialize return values
    bool = false;
    first_pos = 0;
    ocurrences = 0;
    % Define tolerance
    tol = 1e-2;
    % For each vertex
    for i = 1:size(vertex_coord, 1)
        % If the given point is close enough to a vertex
        if distance(P, vertex_coord(i, :)) < tol
            % Store index of this ocurrence
            ocurrences = ocurrences + 1;
            % During the first ocurrence
            if ocurrences == 1
                % Toggle boolean and store position
                bool = true;
                first_pos = i;
            end
        end
    end
end

function graph = build_full_graph(coordinates_path)
    % Initialize fields containing non-duplicate coordinates
    graph.vertex_coord = [];
    graph.from_coord = [];
    graph.to_coord = [];
    % Open file that contains coordinates
    fid = fopen(coordinates_path, 'r');
    % Until the end has not been reached
    while ~feof(fid)
        % Fetch current line
        tline = fgetl(fid);
        % Split it using spaces as delimiters
        values = split(tline);
        % Read important values
        x1 = str2double(values(2));
        x2 = str2double(values(3));
        y1 = str2double(values(4));
        y2 = str2double(values(5));
        % Form 'from' and 'to' vertices
        from = [x1, y1];
        to = [x2, y2];
        % If 'from' vertex already exists in the array
        [bool, pos] = exists(from, graph.vertex_coord);
        if bool
            % Redefine 'from' vertex to match the one already in the list
            from = graph.vertex_coord(pos, :);
        % Otherwise
        else
            % Add to vertex set
            graph.vertex_coord = [graph.vertex_coord; from];
        end
        % In any case, add to edge set
        graph.from_coord = [graph.from_coord; from];
        % Do the same for 'to' vertex
        [bool, pos] = exists(to, graph.vertex_coord);
        if bool
            % Redefine 'to' vertex to match the one already in the list
            to = graph.vertex_coord(pos, :);
        % Otherwise
        else
            % Add to vertex set
            graph.vertex_coord = [graph.vertex_coord; to];
        end
        % In any case, add to edge set
        graph.to_coord = [graph.to_coord; to];
    end
    % Close file
    fclose(fid);
    % Associate each vertex to an integer
    graph.vertices = transpose(1:length(graph.vertex_coord));
    % Update values in 'from' set
    graph.from = [];
    for i = 1:size(graph.from_coord, 1)
        % Find position
        [~, pos] = exists(graph.from_coord(i, :), graph.vertex_coord);
        % Let that position be the integer
        graph.from = [graph.from; pos];
    end
    % Update values in 'to' set
    graph.to = [];
    for i = 1:size(graph.to_coord, 1)
        % Find position
        [~, pos] = exists(graph.to_coord(i, :), graph.vertex_coord);
        % Let that position be the integer
        graph.to = [graph.to; pos];
    end
    % Remove coordinate representation of edges
    graph = rmfield(graph, 'from_coord');
    graph = rmfield(graph, 'to_coord');
end

function [neighbor_no, edge_indices, neighbors] = ...
                                   count_neighbors(vertex, from_array, to_array)
    % Initialize edge indices
    edge_indices = [0; 0];
    % Find edges that either start or end at this vertex
    appearances_from = find(from_array == vertex);
    appearances_to = find(to_array == vertex);
    % Count them
    neighbor_no = size(appearances_from, 1) + size(appearances_to, 1);
    % Determine all apearances without repetitions (degenerate case)
    edge_indices = unique([appearances_from; appearances_to]);
    % If the number of neighbors is one or more
    if size(edge_indices, 1) > 0
        % Get neighbors
        edges = [from_array(edge_indices), to_array(edge_indices)];
        % Order them
        for i = 1:size(edge_indices, 1)-1
            if edges(i, 1) == edges(i+1, 2) || edges(i, 2) == edges(i+1, 1)
                edges(i+1, :) = flip(edges(i+1, :), 2);
            end
        end
        % Check which column contains the neighbors
        if sum(edges(:, 1) == vertex) == 0
            neighbor_column = 1;
        else
            neighbor_column = 2;
        end
        % Return neighbors
        neighbors = edges(:, neighbor_column);
    end
end

function intermediate_edges = get_intermediate_edges(edge_index, graph)
    % Initialize arrays with from and to integers
    from = [];
    to = [];
    % For each column of array with possible intermediate values
    for i = 1:size(graph.intermediate_from, 2)
        % If entry is nonempty (marked with -1)
        if graph.intermediate_from(edge_index, i) ~= -1
            % Append from
            from = [from; graph.intermediate_from(edge_index, i)];
            to = [to; graph.intermediate_to(edge_index, i)];
        end
    end
    % Save x and y coordinates in a single array and return (could be empty)
    intermediate_edges = [from, to];
end

function new_graph = add_intermediate_edges(edges, edge_index, graph)
    % It's assumed that 'edges' is of the form
    %
    %   [[from_int_1, to_int_1]; [from_int_2, to_int_2]; ...]

    % Initialize new graph as old graph
    new_graph = graph;
    % For each new edge
    for i = 1:size(edges, 1)
        % Initialize new columns
        new_col_from = -1*ones(size(graph.from, 1), 1);
        new_col_to = -1*ones(size(graph.from, 1), 1);
        % Modify them
        new_col_from(edge_index) = edges(i, 1);
        new_col_to(edge_index) = edges(i, 2);
        % Add them to return array
        new_graph.intermediate_from = [new_graph.intermediate_from, ...
                                       new_col_from];
        new_graph.intermediate_to = [new_graph.intermediate_to, new_col_to];
    end
end

function contracted_graph = contract_graph(full_graph)
    % Initialize return struct
    contracted_graph = full_graph;
    % Initialize two additional fields
    contracted_graph.intermediate_from = contracted_graph.from;
    contracted_graph.intermediate_to = contracted_graph.to;
    % Define temporary array with non-removed vertices
    temp_vertices = contracted_graph.vertices;
    % For each vertex
    i = 1;
    while i <= size(temp_vertices, 1)
        % Fetch information
        [neighbor_no, edge_indices, neighbors] = ...
                               count_neighbors(temp_vertices(i), ...
                                               contracted_graph.from, ...
                                               contracted_graph.to);
        % If the vertex has two neighbors
        if neighbor_no == 2
            % Add new edge to graph
            contracted_graph.from = [contracted_graph.from; neighbors(1)];
            contracted_graph.to = [contracted_graph.to; neighbors(2)];
            % Define dummy row
            dummy_row = -1*ones(1, size(contracted_graph.intermediate_from, 2));
            % Add dummy row to arrays with intermediate values
            contracted_graph.intermediate_from = ...
                                [contracted_graph.intermediate_from; dummy_row];
            contracted_graph.intermediate_to = ...
                                  [contracted_graph.intermediate_to; dummy_row];
            % For each previous edge
            for j = 1:size(edge_indices, 1)
                % Find intermediate edges it had
                previous_edges = get_intermediate_edges(edge_indices(j), ...
                                                        contracted_graph);
                % Add them to new edge in graph
                contracted_graph = ...
                    add_intermediate_edges(previous_edges, ...
                                           size(contracted_graph.from, 1), ...
                                           contracted_graph);
            end
            % Remove previous edges and previous intermediate edges
            contracted_graph.from(edge_indices, :) = [];
            contracted_graph.to(edge_indices, :) = [];
            contracted_graph.intermediate_from(edge_indices, :) = [];
            contracted_graph.intermediate_to(edge_indices, :) = [];
            % Remove bus from array being traversed
            temp_vertices(i) = [];
        % Otherwise
        else
            % Move on
            i = i + 1;
        end
    end
end

function relabeled_graph = relabel_graph(original_graph)
    % Initialize return array
    relabeled_graph = original_graph;
    % Count vertices after contraction
    G = graph(original_graph.from, original_graph.to);
    degrees = degree(G);
    vertices_no = sum(degrees ~= 0);
    % Relabel nodes so that 1:M are in new edges and M:N are in removed edges
    relabeled_vertices = [];
    vertices = 1;
    remaining_vertices = vertices_no + 1;
    for i = 1:size(degrees, 1)
        if degrees(i) ~= 0
            relabeled_vertices = [relabeled_vertices; vertices];
            vertices = vertices + 1;
        else
            relabeled_vertices = [relabeled_vertices; remaining_vertices];
            remaining_vertices = remaining_vertices + 1;
        end
    end
    % Map old indices to new ones
    relabeled_graph.vertices = relabeled_vertices;
    relabeled_graph.vertex_coord(relabeled_vertices, :) = ...
                                                   relabeled_graph.vertex_coord;
    for i = 1:size(relabeled_graph.vertices, 1)
        % Replace it in 'from' array
        ind = relabeled_graph.from == i;
        relabeled_graph.from(ind) = relabeled_vertices(i);
        % Replace it in 'to' array
        ind = relabeled_graph.to == i;
        relabeled_graph.to(ind) = relabeled_vertices(i);
        % Replace it in 'intermediate_from' array
        ind = relabeled_graph.intermediate_from == i;
        relabeled_graph.intermediate_from(ind) = relabeled_vertices(i);
        % Replace it in 'intermediate_to' array
        ind = relabeled_graph.intermediate_to == i;
        relabeled_graph.intermediate_to(ind) = relabeled_vertices(i);
    end
    % Sort new vertex array
    [relabeled_graph.vertices, perm] = sort(relabeled_graph.vertices);
end

function feeder = locate_feeder(graph, substation_path)
    % Initialize return struct
    feeder = 1;
    % Open file containing substation
    fid = fopen(substation_path);
    % While end of file not reached
    while ~feof(fid)
        % Fetch line
        tline = fgetl(fid);
        % Split it using spaces as delimiters
        values = split(tline);
        % Read important values
        x = str2double(values(2));
        y = str2double(values(3));
        % Look for this coordinate in graph
        [bool, first_pos] = exists([x, y], graph.vertex_coord);
        % If it was found
        if bool
            % Return it
            feeder = graph.vertices(first_pos);
        end
    end
end

function graph = add_feeder(original_graph, substation_path)
    % Initialize return array
    graph = original_graph;
    % Locate feeder
    feeder = locate_feeder(graph, substation_path);
    % Add dummy vertex connected to feeder
    dummy_vertex = size(graph.vertices, 1) + 1;
    graph.vertices = [graph.vertices; dummy_vertex];
    graph.from = [graph.from; dummy_vertex];
    graph.to = [graph.to; feeder];
    % Let the dummy vertex be located at the origin
    graph.vertex_coord = [graph.vertex_coord; [0, 0]];
    % Add dummy row to intermediate edges
    dummy_row = -1*ones(1, size(graph.intermediate_from, 2));
    graph.intermediate_from = [graph.intermediate_from; dummy_row];
    graph.intermediate_to = [graph.intermediate_to; dummy_row];
    % Add dummy elements
    graph.intermediate_from(end, 1) = dummy_vertex;
    graph.intermediate_to(end, 1) = feeder;
end

function graph = add_fractions(vertices, fractions, original_graph)

end

function next_vertex = find_next(vertex, edges)

end

function colored_graph = assign_fractions(original_graph)
    % Initialize return struct
    colored_graph = original_graph;
    % Add new field containing fractions
    colored_graph.fractions_from = colored_graph.intermediate_from;
    colored_graph.fractions_to = colored_graph.intermediate_to;
    % For all major edges
    for i = 1:size(colored_graph.from, 1)
        % Identify from
        from = colored_graph.to(i)
        % Get intermediate edges
        get_intermediate_edges(i, colored_graph)
        % Measure them
        % Assign constant to ends of all intermediate edges; the intermediate
        % edge that coincides with 'from' vertex should be zero; the one that
        % coincides with 'to' vertex should be one
    end
end

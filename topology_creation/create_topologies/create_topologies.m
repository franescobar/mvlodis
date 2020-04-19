function LVN_set = create_topologies(number_of_LVNs)
    % Creates the LVN topologies by calling the subordinate function read_LVN,
    % located in this same directory. The function outputs the following
    % variable:
    %
    % LVN_set   a cell that contains MATPOWER cases.

    % For simplicity, most of the directories have been hardcoded; after all,
    % the topology creation has to be carried out only once.

    % Specify format for files with LVN data
    folder = 'OpenDSS_data/';
    suffix = '.dss';
    % Store paths with LV lines data
    prefix = 'LINES_LV_';
    line_paths = strings(number_of_LVNs, 1);
    for i = 1:number_of_LVNs
        line_paths(i) = strcat(folder, prefix, int2str(i), suffix);
    end
    % Store path with linecode definitions
    linecode_path = strcat(folder, 'linecode_declare.dss');
    % Store paths with LV loads data
    prefix = 'OBJECT_LV_';
    load_paths = strings(number_of_LVNs, 1);
    for i = 1:number_of_LVNs
        load_paths(i) = strcat(folder, prefix, int2str(i), suffix);
    end
    % Initialize LVN set
    LVN_set = cell(number_of_LVNs, 1);
    % Read LVNs
    for i = 1:number_of_LVNs
        LVN_set{i} = read_LVN(line_paths(i), linecode_path, load_paths(i));
    end
end

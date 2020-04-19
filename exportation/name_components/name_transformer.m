function name = name_transformer(mv_load, lvn_no)
    % This function outputs the following variable:
    %
    % name      character array with a unique transformer name

    % The transformer name is obtained by simply concatenating the character T,
    % the load being disaggregated and the number (letter) of the network used
    % to disaggregate it (if several networks are used, then there might be
    % several step down transformers)
    alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    name = ['T', mv_load, '-', alphabet(lvn_no)];
end

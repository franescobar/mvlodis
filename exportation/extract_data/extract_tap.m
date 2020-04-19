function extract_tap(template_set, fid)
    % For each LVN
    for i = 1:length(template_set)
        % Determine final position
        tap = template_set{i}.branch(1, 9);
        % Determine number of tap changes
        tap_changes = (tap - 1)/0.025;
        % Print them
        fprintf(fid, '%.0f\n', tap_changes);
    end
end

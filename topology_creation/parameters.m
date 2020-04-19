function [matpower_path, kVA, R, X] = parameters
    % In this file, the user defines parameters concerning the low-voltage
    % networks. The function should output the following variables:
    %
    % matpower_path    a character vector indicating the (relative) installation
    % path of MATPOWER
    % kVA   a vector with possible transformer ratings (KVA)
    % R     a vector with possible winding resistances (pu)
    % X     a vector with possible leakage reactances (pu)

    kVA = 500;
    samples = 10;
    R = linspace(0.01, 0.02, samples);
    X = linspace(0.06, 0.08, samples);

    matpower_path = '../../MATPOWER/matpower6.0';
end

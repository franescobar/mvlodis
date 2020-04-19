function [inelastic_buses, load, template] = ...
                         force_load(bus, record, abbr, spec, old_template, P, Q)
    % Important: at the moment, this function works only when the template set
    % consists of the same template copied several times; this is the case as
    % otherwise it would be necessary to keep track of all the templates even
    % after moving them around, and that has not yet been implemented. (It
    % should.)

    % Forces the presence of the specified record in the specified bus. If this
    % record also happens to be a LOAD, then this load will be assigned the
    % given power and will be considered a constant impedance; otherwise,
    % MVLoDis will look at the folder injector_power and injector_pars folders
    % in order to know how to print that record. The function outputs the
    % following variables:
    %
    % inelastic_buses   equal to bus
    % load              a struct containing the power and the parameters of the
    %                   required record
    % template          a copy of old_template but with the allocated power at
    %                   the specified buss

    % If the last two arguments were not passed but the record is LOAD
    if nargin < 5 && strcmp(record, 'LOAD')
        msg = sprintf(['MVLoDis error: You asked me to force a LOAD at ', ...
                       'bus %d\nbut you didn''t specify its power.\n'], bus);
        error(msg);
    end
    % Return the inelastic bus
    inelastic_buses = bus;
    % Build output record
    load.record = record;
    % Load MATPOWER's constants
    define_constants;
    % Assume that the passed bus is the bus integer
    load.bus = bus;
    % Assign load name based on the assigned bus
    load.name = [abbr, num2str(load.bus)];
    % Get power and parameters. If the required record is LOAD
    if strcmp(record, 'LOAD')
        % Read power from arguments, as it will be ON
        FP = '0';
        FQ = '0';
        load.power = [FP, ' ', FQ, ' ', num2str(-P), ' ', num2str(-Q)];
        % Use the following parameters (constant current for P and constant
        % impedance for Q)
        load.pars = '0. 1. 1. 0. 0. 0. 0. 1. 2. 0. 0. 0.';
    else
        % Fetch power injector_power and injector_pars folders
        msg = sprintf(['MVLoDis error: The function force_load() is not  ', ...
                       'ready to install\nrecords other than LOAD.\n'])
        error(msg);
        % For future development: this function should read the probabilities
        % from spec and use them to assign injectors of type other than LOAD.
        % Assign P and Q in variables with that name, so that the following
        % lines do not have to be modified
    end
    % Assign output template
    template = old_template;
    % Assign load at specified bus
    template.bus(2, PD) = P;
    template.bus(2, QD) = Q;
end

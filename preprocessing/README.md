## Topology preprocessing

Although MVLoDis has the capability of importing topologies directly from
OpenDSS files, it can be the case that a given network has already been modeled
in MATPOWER. In order to use such model, however, it is required to preprocess
the template. It can be necessary, for instance, to remove the existing loads
and generators to prevent them from interfeering with the load and DER allocation
carried out by MVLoDis.

At the moment, this folder includes the following functions:
1. `erase_loads()`, which erases the loads from a given MATPOWER case but leaves
a mark of 1 kW in each load bus in order to differentiate it from a transit bus.
2. `remove_gens()`, which removes (possibly all) generators from a MATPOWER
case, except the one located at the slack bus.
3. `relabel_buses()`, which returns the same MATPOWER case but with the buses
numbered in this fashion: `1, 2, ..., N`.
4. `force-load()`, which forces the connection of a given load to a given bus.
This is particularly useful when big loads must be connected directly to high-
or medium-voltage buses.

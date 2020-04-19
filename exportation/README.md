## Exportation functions

The main function in this folder, `print_lvn()`, receives a MATPOWER case and
writes it to a file in RAMSES format, whereas the functions contained in the
folder `name_components` take care of assigning unique names to each network
component.

Recently, a function ``base_n()`` was added to handle larger systems. This
function changes a number from base 10 to base *n*, where *n* can be any
positive integer less than 65. Changing the base is sometimes useful to cope
with RAMSES limitation of eight characters for the name bus, since the same
(bus) number will require fewer characters when represented in base, say, 64
than when represented in base 10.

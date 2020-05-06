## Load disaggregation

This subfolder takes care of disaggregating a given (typically) MV load into
fully-modeled low-voltage networks (LVNs), and thus executes the core
functionality of the MVLoDis toolbox.

The disaggregation is carried out in three steps:

1. **Initial load or distributed energy resources (DERs) allocation**. Given
some statistical constraints that the resulting HV-MV-LV network should satisfy,
such as the percentage of load buses fed by a PV system, MVLoDis allocates the
loads and DERs specified in ``injector_power`` randomly throughout the LVN while
satisfying those constraints. This is done for each LVN in the given set.

2. **Template selection**. Given the initial allocation, MVLoDis looks at the
total active and reactive power demanded by each LVN. It then chooses the
optimal subset of LVNs that, when connected in parallel to a voltage of 1 pu,
have a total demand closest, but not equal, to the MV load being disaggregated.

3. **Connection to bulk power system**. Once the optimal subset has been found,
MVLoDis enlarges slightly (optimally) the power consumed at each load bus so
that the LVNs have a total demand that is *exactly* the MV load being
disaggregated.

### Steps for disaggregating a load

The disaggregation boils down to calling the function ``disaggregate_load()``.
Its arguments, which are specified in the function's ``.m`` file, are basically
information concerning the load, the statistical constraints, and the output
folder.

Here's the usual procedure for calling ``disaggregate_load()``:

1. **Fetch load information**. Fetch the active and reactive power, ``P`` and
``Q``, of the MV load to be disaggregated, as well as the voltage magnitude and
angle, ``VM`` and ``VA``, at which that MV bus operates.

2. **Specify names**. Use a bus number ``load_no`` to identify the load. This
identifier will be used for naming conventions of network components. Also,
specify the (relative) output folder ``folder`` and the path ``file_path`` of
the output file; this path is relative to ``folder``.

3. **Define loads and statistics**. Specify types of loads and DERs and their
statistical properties in a struct called ``specs``. For instance,
<pre><code>specs.inj = ["LOAD", "AIR_COND1"];
specs.percentages = [15, 20];
specs.probabilities = [1, 0.2];</code></pre>
will tell MVLoDis, on the one hand, that it must allocate loads of type ``LOAD``
in 15% of the load buses, and that the load will be consuming power at the time
of the snapshot t = 0 with a probability of 1. On the other hand, the preceding
instruction will also tell MVLoDis that it must allocate loads of type
``AIR_COND1`` in 20% of the load buses, and that they will be consuming power
at t = 0 with a probability of 0.2. (Additionally, it's required to specify
further information about the loads, but this is explained in the folders
``injector_pars`` and ``injector_power``.)

4. **Give further information**. Specify further information about loads and
DERs: the abbreviations used to print them in RAMSES and the accuracy of the
initial disaggregation. For instance,
<pre><code>specs.abbr = ["L", "AC"];
specs.power_accuracy = 0.1;</code></pre>
will tell MVLoDis to add an ``L`` to the name of each load of type ``LOAD`` and
``AC`` to the name of each ``AIR_COND1``, as well as to select the templates
using a power accuracy of 0.1 MW.

5. **Specify printing format**. Specify options about the printing process. For
instance,
<pre><code>opts.print_loads = false;
opts.append = false;
opts.transformer = 'TRANSFO';</code></pre>
will tell MVLoDis that it should not write the loads to the RAMSES file (which
is useful if ``disaggregate_load()`` is going to be used in cascade), that it
should not append content to the specified file but rather overwrite its
contents, and that all transformers should be printed using the ``TRANSFO``
record.

6. **Call the function**. Using the above variables, this means writing
<pre><code>disaggregate_load(P, Q, VM, VA, load_no, folder, file_path,
                     specs, opts)</code></pre>

7. **Check output and run**. Check the output in ``file_path`` and run it with
RAMSES.

Although the tool has been applied primarily to the HV-MV system produced by
TDNetGen, the above steps can be repeated for each MV load in any given system
with minor changes.

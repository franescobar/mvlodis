## Available load and DER parameters

In this folder, the user specifies possible parameters for a given load or DER.
These are the parameters passed to RAMSES to run the dynamic simulation, and
they are only taken into account by MVLoDis when the parameter ``ramses`` in
``parameters.m`` is set to ``true`` and the field ``opts.print_loads`` is passed
to ``disaggregate_load()`` as ``true`` as well.

In RAMSES, most loads and DERs are passed in the input as follows:
<pre><code>INJEC &lt;type&gt; &lt;name&gt; &lt;bus&gt; FP FQ P Q &lt;pars&gt;
</code></pre>
Here, ``<type>`` is the injector type, ``<name>`` is the name of each of its
individual ocurrences in the network, `FP`, `FQ`, `P` and `Q` are specifiers for
the power consumed by the injector at the time of the snapshot and `<pars>` are
the parameters contained in this folder. These parameters are passed as a
sequence of numeric fields and they specify details about the injector's dynamic
behaviour. For instance, for an induction motor, these parameters would be the
leakage impedances, the nominal power, the constants of the mechanical model,
and so on.

It's very important to note that each file in this folder should correspond to a
file in `../injector_power`.

### The format

Before including a file in this folder, make sure that it conforms to the
following format rules:
- The file begins with the line `# power_options = <val>`, where `<val>` is the
  number of possible pairs `(P, Q)` that an injector might be consuming at the
  time of the snapshot. This number should coincide with the number of lines in
  the corresponding file in `../injector_power`. If this is not the case,
  MVLoDis will notice and raise an error.
- The second line is `# parameter_sets = <val>`, where `<val>` specifies the
  number of feasible parameter sets for each pair `(P, Q)`.
- The third line is `# lines = <val>`, where `<val>` is the number of lines that
  each parameter set spans in the file. This number must include the empty line
  that separates one parameter set from the other.
- The remaining of the file contains the parameters.

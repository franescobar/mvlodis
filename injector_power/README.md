## Available load and DER powers

In this folder, the user specifies possible pairs (P, Q) that a given load
or DER might be *consuming* at the time of the snapshot. (Incidentally, the
name injector is used as an umbrella term for loads and DERs alike.) For
instance, if the file ``PV.txt`` contains the lines
<pre><code>-0.0018, 0
-0.0036, 0
-0.0054, 0
</code></pre>
then MVLoDis knows that all PV systems will be operating at unity power factor
(i.e. Q = 0) and will be *generating* one out of three possible values of active
power: 0.0018 MW, 0.0036 MW, or 0.0054 MW.

When MVLoDis allocates an injector, it chooses any power at random from the
associated file in this folder following an uniform probability distribution.
This in turn implies that if a given value of power is intended to be more
frequent than others, it must be copied several times into the ``.txt`` file.

This interface has been designed in this way so that the problem of power
definition &mdash;and the related problem of parameter generation&mdash;are
decoupled from the load disaggregation.

### The format

Before including a file in this folder, make sure that it conforms to the
following format rules:
- The file is called ``*.txt``, where ``*`` is the name of the injector as
  used in other places of MVLoDis.
- Each line contains only one pair P, Q.
- With the exception of commas, which serve as delimiters, only numeric
  characters are present.

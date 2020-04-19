## Posprocessing of topology set

Currently, this subfolder of the MVLoDis toolbox consists of a single function
called ``diversify_set``, which takes the topology set created with the
``topology_creation`` subfolder and generates ``N`` additional topologies using
criteria that preserve realism.

The diversification takes place as follows:

1. The topologies with the lowest (``Nmin``) and the largest (``Nmax``) number
of load buses are identified.

2. A random sequence of ``N`` integers between ``Nmin`` and ``Nmax`` is
generated.

3. For each integer ``ai`` in the sequence, one of the original topologies is
identified: the one with the lowest number of load buses so that this number is
still larger or equal than ``ai``.

4. Load buses (and the lines feeding them) are removed iteratively from this
topology until its number of load buses is exactly ``ai``.

5. The resulting template is included in the diversified set.

The above process yields a set with ``N`` additional topologies. Since the
removal of load buses is random, ``N`` can be as large as  a few hundreds
without any loss of realism.

Additionally, the resulting topologies are sorted according to the number of
load buses they contain. The topology with the lowest number of load buses will
correspond to index ``1`` in the output cell, whereas the one with the largest
number will correspond to the last index. This is useful in later steps of the
methodology used by MVLoDis, as having a sorted set will speed up the search for
an optimal subset of this template set.

"""

    This python script is used to simulate the disaggregated 4-bus system. It
    should be run from a terminal simply as

        python simulation.py

    Notice that the instructions on line 20 should be changed to match the
    (relative) path of the local RAMSES installation. If no local installation
    is present, then probably the simulation will not run as the free version
    of RAMSES is limited to about 100 buses.

    This simulation has been tested with version 0.0.16 of pyramses.

"""

import pyramses
import os, glob
from pyramses import simulator
simulator.__new__libdir__ = "C:\\Users\\Francisco\\Desktop\\URAMSES\\Release_intel_w64\\"

# Delete output files from previous simulations (comment if not required)
files = glob.glob('output/*')
for f in files:
    os.remove(f)

# Create cases
case = pyramses.cfg()

# Input files
case.addData('../output/lv.dat')
case.addData('../output/mv.dat')
case.addData('input/syst_A.dat')
case.addData('input/loads_A.dat')
case.addData('input/volt_A.dat')
case.addData('input/settings.dat')
case.addObs('input/obs.dat')
case.addDst('input/disturbance_A.dst')

# Output files
case.addTrj('output/obs.trj')
case.addInit('output/init.trace')
case.addCont('output/cont.trace')
case.addDisc('output/disc.trace')
case.addOut('output/output.trace')

# Runtime observables
case.addRunObs('BV 4A2')
case.addRunObs('BV 4')

# Create simulator instances
ram = pyramses.sim()
ram.execSim(case)

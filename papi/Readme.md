Virtual PAPI lights
====================

TOGFox

-- v0.01 - initial release

-- v0.02 - adjusted distance to airport by -500m to approximate the end of the runway

--		   - added an indicator(arrow) that shows if you're moving towards the 3 deg glide slope or away from it

--		   - recalibrated the lights as it was bringing the pilot in too low


Requires
========
FlyWithLUA NG

Installation
============
Place tf_papi.lua file into the FWL Scripts directory.
Place tf_common_functions.lua into the FWL Modules directory

How to use
==========
The script works silently and constantly in the background. There is no GUI and no interaction needed from the pilot. To disable the virutual PAPI lights simply delete the tf_papi.lua file (and optionally, the tf_common_functions.lua file).

To disable the script, you can:
- remove the tf_papi.lua file out of your scripts folder

How does it work?
=================
The script monitors the plane's movement during flight and will display virtual PAPI lights in the top left corner of the screen. The lights will appear when:

- the plane is not in replay mode and
- the plane is moving towards the closest airport and
- the plane is 10nm away or less from the closest airport and
- the plane appears to be on a descent angle (3 degree glide slope +/- an element of error)

The virtual PAPI lights will appear when these conditions are met.

Known issues
============
- Some airports are really close together and this might confuse the plug-in. The lights will still work - but will be "locked" on the wrong airport
- real PAPI lights are calibrated for the end of the runway. The virtual lights are calibrated for the centre of the airport. Excpet slightly inconsisten results.

Licence
=======
Feel free to change for personal use. If you re-use some code components then please give credit. No permission to re-host or republish without permission.





Persistent Parking
==================

TOGFox

--v0.01 - initial release
--v0.02 - now writes to file only if on the ground and not flying
--v0.03 - better way of determining if plane is parked
--v0.04 - fixed a defect that gave really bad experiences if you crashed
--v0.05 - added an extra safeguard to stop loading old positions when landing
--v0.06 - will now save location only if engine is off (stops saving location when holding short or lined up and waiting)
--v0.07 - refactored code so it is ready for a beta release
--v0.08 - simplified the database save/load functions to help reduce bugs
--v0.09 - fixed orientation just a little bit. Needs more work.

Installation
============
Place .lua file into the FWL scripts directory.

How to use
==========
The script works silently and constantly in the background. There is no GUI and no interaction needed from the pilot.

To disable the script, you can:
- remove the script out of your scripts folder or
- open the script file with a text editor and adjust these values found near the top of the script:

  -- bActivatePersistentParking  <-- activates/de-activates the script
  
  -- bLoadPersistentParking  <-- enables the plane to be repositioned when a session starts
  
  -- bSavePersistentParking  <-- enables the plane position to be remembered when parked.
  
  
  The default setting is 'true' (don't use quotes) for all three values. If you somehow corrupt the file during editing then refresh the script from this github.

How does it work?
=================
The script monitors the plane's movement and will remember where you parked your plane. When you start the next session, your plane will be returned to the previous position.

The script identifies a parked plane by:
- being on the ground (of course)
- having a ground speed < 10 knots and
- having the park brake engaged and
- having the engine off

When these conditions are met, the plane will be recognised as parked, and it's position will be remembered and restored next session.


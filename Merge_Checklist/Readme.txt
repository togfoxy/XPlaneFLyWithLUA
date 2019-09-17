Installation:

Copy tf_MergeClist.lua into \FlyWithLua\Scripts folder
Check for \Scripts\merge_clist folder
Check inside \Scripts\merge_clist folder for a common_checklist.txt file  (it's okay if it's missing)

Load up any plane with any checklist.

If you have a common checklist in the merge_clist folder then the script will ensure this checklist will appear BEFORE your regular aircraft specific checklist.

How to create a common checklist
================================

The common checklist is inside the following file:
\Scripts\merge_clist\common_checklist.txt

It needs to follow the normal clist structure and commands and is, in every sense, a valid checklist on it's own. Put your common pre-flight checklist items into this common checklist and it will appear every time you start a new flight session. You might want to put your regular flight planning items in this common checklist and make it available to every aircraft you fly.

How to create an aircraft specific checklist
============================================

Each aircraft can have it's own checklist. This appears in the aircraft folder just like a normal clist file but there is an important note:

If the aircraft folder has a 
merge_clist.txt
then you need to edit that file in the aircraft folder.

If the aircraft folder does not have a merge_clist.txt file then you need to edit the clist.txt file in the aircraft folder.

How it works
============

If a \scripts\merge_clist\common_checklist.txt file exists then that appears at the start of your final checklist.

If a [aircraft folder]\merge_clist.txt file exists then that becomes the second part of your final checklist and processing stops.

If there is no merge_clist.txt file but there is a clist.txt file (regular checklist) then that file becomes the second part of the final checklist. Processing then stops.

The sim will then present your final checklist for your enjoyment.

If the final checklist is not present then use the sim menu commands to reload the checklist as normal.

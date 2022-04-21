[h1]Summary[/h1]
Adds various configuration options to customize Return Fire. Options include shots per turn, chance to activate, whether to only return fire against misses or not and shooting preemptively.

By default makes all Return Fire unlimited with 100% chance to activate but only activate after misses. This keeps it balanced and is how the Chosen Revenge works already.

The affected return fire types are: secondary weapon return fire, primary weapon return fire, Dark Event return fire and Chosen Revenge return fire.

[h1]Bugfixes[/h1]
Makes Return Fire work with most vanilla weapons equippable by XCOM by adding PistolReturnFire to them. This doesn't do anything on its own but lets those weapons work with Return Fire. You can add more weapons in the configuration if a mod didn't include PistolReturnFire on its weapons.

Pistols, Bullpups and Autopistols already have PistolReturnFire, this mod doesn't touch those. Sniper Rifles don't get PistolReturnFire as Sharpshooters already have it on their Pistols.

Additionally fixes Return Fire, Pistol Overwatch and Counterattack Bayonet attacks being able to crit and Counterattack Bayonet not having reaction fire aim penalty.

Being suppressed or panicked will now prevent all types of passive reaction attacks like they should. This includes Return Fire and all melee reaction attacks.

[h1]Adding Return Fire to more classes[/h1]
Add SkirmisherReturnFire to a class to utilize PistolReturnFire added to their primary weapon. All classes use PistolReturnFire for the actual shot if it is on a weapon they have equipped. Templars should have ReturnFire instead of SkirmisherReturnFire.

A good option to add Return Fire to classes is [url=https://steamcommunity.com/sharedfiles/filedetails/?id=1129770962] I'm the Commander here[/url]. Alternatively you can do it via .inis, included examples in this mod.

Rangers and Templars with Bladestorm work fine as Return Fire activates after the attack and Bladestorm activates before it. Sparks with Intimidate basically work the same way as Skirmishers with Judgment, but they don't get over-the-shoulder camera for it.

[h1]Compatibility[/h1]
This mod only modifies existing templates and is therefore compatible with everything and can be added or removed at any time. If another mod modifies the same values it might overwrite them depending on the load order.

If you have a custom class mod with Return Fire that is only supposed to work with their secondary weapon you can modify the config to remove their primary weapons from it if they use them.

[h1]Notes[/h1]
Return Fire may fail to activate sometimes but that is caused by visibility checks and how all reaction fire works. Changing this is not in the scope of this mod as it would require adding new abilities to fix for all types of return fire.

Using Suppression doesn't prevent usage of reaction attacks while the unit is suppressing. This doesn't necessarily break anything but may look odd. It is a vanilla problem with Mutons anyway so it's not like I'm introducing a bug here.

This is my first polished and actually uploaded mod. Feel free to give suggestions or ask questions in the comments. I will most likely create more mods so stay tuned.

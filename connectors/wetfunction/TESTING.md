# Testing the Wet Function Redux connector in game

How to put an actor into each state the connector's conditions read, and how to check what its effects change. Names were read from Wet Function Redux SE 1.0 and the OSweat patch.

Wet Function keeps its values in StorageUtil, which Skyrim's console can't read or set, so everything here goes through Wet Function's own MCM (**WetFunction Redux**). MTF re-evaluates tiers every couple of seconds, so a change shows up shortly after closing the MCM.

The Papyrus log, with the connector's registration line and any script errors, is at `Documents/My Games/Skyrim Special Edition/Logs/Script/Papyrus.0.log`.

## Starting Wet Function on an actor

Every condition is false until Wet Function has run on the actor at least once.

1. Open the MCM, **Targets** page.
2. Select **Player**, or **Crosshair** / **Console** for an NPC (click the NPC with the console open first).
3. Press **Start Effect** and close the menu. The status shows `[Running]` when you come back.

**Wet Function running** should pass now. Press **Stop Effect** and it should fail within a few seconds.

## Wetness and Wetness stage

On the **Targets** page, with the actor selected and running, drag **Current values > Wetness**. With Wet Function's default points (dry 1, start 2, soaked 4, cap 10, all on the **Wetness** page):

| Wetness | Stage | Wetness % |
| --- | --- | --- |
| 1.0 | Dry | 10% |
| 3.0 | Sweaty | 30% |
| 6.0 | Soaked | 60% |
| 10.0 | Soaked | 100% |

Wet Function keeps updating the value, so for a steady test set **Force Values > Wetness** instead, and set it back to -1 afterwards.

- **Wetness:** a tier at 50% should show at 6.0 and not at 3.0.
- **Wetness stage:** try "Sweaty or wetter" at each row.

## Wetness trend

The rate is shown as **Current values > Wetness Rate** while the effect runs. Swim, or stand in the rain, and it goes positive (**Getting wetter**). Go indoors, or stand in clear weather, and it goes negative (**Drying off**). A forced wetness doesn't change the rate, so clear the force first.

## Effects

Put the effect on a tier, make the tier show, then check the value on the **Targets** page.

- **Wet the skin / Dry the skin:** **Current values > Wetness** jumps by the amount times the cap (25% of cap 10 is 2.5) and stays between 0 and the cap. On an actor Wet Function has never run on, nothing happens.
- **Wetness rate:** the **Wetness** page's **Global rate multiplier** shows 1.0 normally, 2.0 while a 200% tier shows, and goes back when the tier stops. **Wetness Rate** on the Targets page scales the same way. On an NPC tier, the multiplier doesn't change.

## Start and stop

Switch between a tier with Wetness rate and one without a few times, then confirm the Global rate multiplier is back to its old value, including with two tiers using it and only one of them stopping.

## Registration

The first session after the plugin is added, the Papyrus log shows `[MTF_Main] Registered 'proteux-mtf.wetfunction'` and `[MTF_Plugin_WetFunction] 0.1.0 registered` a few seconds after loading. The save remembers the registration, so later sessions log nothing; check the connector's state directly instead:

```
sqv MTF_Plugin_WetFunction
```

It should show the quest running, `::_registered_var = True`, and `WfrConfig` filled in. If MTF lists the plugin as "Catalog Only", the catalog loaded but the script didn't register; check that `MTF_Plugin_WetFunction.esp` is enabled in the load order.

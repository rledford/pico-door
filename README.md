# Pico Door

Pico Door is a family-made game that took about a month to build (learning Lua and Pico 8 at the same time). I would like to thank my team (my kids) for the awesome pixel art, sound effects, and excellent ideas (and tricky debugging) that they contributed to this project. Much of the dialog and other text are references to many different games we play, movies we watch, and music we listen to. See if you can pick up on these. There are some inside jokes for the family in there, but should be entertaining for anyone else that plays this game.

The object of the game is to explore the map, avoid death, destroy things, collect all the upgrades (in the chests), interact with things, and defeat the huge door you'll see in the starting area.

### Upgrades

- **Health++** - Increases max HP and heals
- **Damage++** - Increases shot damage
- **Hat** - Increases fire rate (it’s high noon)
- **Glasses** - Increases auto-target range
- **Cake** - Increases _The Distance_ of shots
- **Pogo** - Shots bounce
- **Earrings** - Shots pierce

### Movement

Since this is a roguelike, movement is done one tile at a time. you can rapidly press  the same or different directions and the moves will be queued up - the player moves pretty quick so it’s very responsive (unless you just hold all directional buttons down at the same time for an extended period of time). Holding a direction will queue up movements based on how your input repeats presses when held, so it may continuously move or it might move once and after a delay move continuously. This games requires thought-out and deliberate moves to get the player to safe places, but there are some straight-always that, once you know the map, you’ll be able to just hold a direction (knowing how your particular input works when held) and not be surprised by the outcome.

### Enemies

- **Eye** - A green goo thing with one eye that does light ranged and melee damage, and is easy to kill
- **Bug** - A slow-moving blob that does medium melee damage and is a bit harder to kill
- **Fang** - A fast-moving snake head that does high melee damage is a bit harder to kill
- **Skull** - A fast-moving, unreasonably aggressive skull that does high melee and ranged damage
- **Torch** - A stationary torch that fires fire ;) - these can not be damaged and their projectiles are the only ones that can go through walls. Torches are only aggressive once you're on the lower parts of the map (you'll know).

### Interactions

Anything that can be interacted with will  have a blue `X` over it when you're close enough (and not currently busy)

- **Mirror** - Will show your current stats and additional info like how many doors you've destroyed, chests looted, and the number of enemies killed
- **Vendor** - This vendor is useless (after needing to recoup some tokens to finish the actual game)
- **Moose** - Will do different things in different situations
- **Goblet of Grail** - Will do different things in different situations

### The Map

The rooms in the map can be traversed in any order and the enemies get harder the more upgrades you collect. So no matter what you decide to do first, by the end of your explorative loot fest, the enemies will be just as difficult.

Once you've collected **ALL** the upgrades you can _successfully_ interact with the Goblet of Grail (without being insulted). This will get you to the final boss fight.

### Achievements

Not spoiling how to get them

- **FBI, open up!**
- **Annoyer of moose**
- **Neck problems**
- **No thanks**

### Difficulties

- **Easy** - Enemies don't scale as much as you collect upgrades and the game is much easier to beat than normal mode.
- **Normal** - The intended way to play - enemy scaling is based on a horrific spreadsheet with questionable formulas.

## Contributors

- Lanik (pixel art, sound, and great ideas)
- Isaac (pixel art and great ideas)
- Ryan (grunt-work)
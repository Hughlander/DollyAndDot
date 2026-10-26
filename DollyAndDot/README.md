# Dolly and Dot

**Dolly and Dot are my best friends!**

A karaoke singalong for the **Meerah's Jukebox** toy. Whenever you or anyone
nearby plays the jukebox, the lyrics to *Dolly and Dot* appear on screen one
line at a time, each word lights up as it is sung, and an alpaca runs along the
line to show you where you are in the song. In dungeons, raids, battlegrounds
and arenas the addon /yells each line for you; in delves, scenarios and the open
world it sends the lyrics to your party, raid or instance chat instead, so the
whole group can sing along.

This is a faithful standalone recreation of the classic
[Dolly and Dot WeakAura](https://wago.io/ihJP5eZK2). Same word timings, same
positions, same alpaca. It does not need WeakAuras.

## Features

- Triggers automatically when Meerah's Jukebox is used by you or a nearby player
- Four lyric lines displayed above the centre of the screen
- Word-by-word highlighting in time with the music
- A running alpaca marks the current word
- /yells the lyrics in dungeons, raids, battlegrounds and arenas
- Falls back to party / raid / instance chat everywhere else (silent when solo)
- Lightweight: one Lua file, no saved variables, no configuration needed

## Requirements

- [SharedMedia](https://www.curseforge.com/wow/addons/sharedmedia) for the
  Expressway font used by the original WeakAura. If the font is unavailable the
  addon falls back to the default UI font.

## Slash commands

- `/dolly` – play the singalong immediately, handy for checking position
- `/dolly stop` – stop playback

## Notes

- World of Warcraft only lets addons /say or /yell on their own inside dungeons,
  raids, battlegrounds and arenas. Delves and scenarios count as the open world
  for this rule, so there the lyrics go to group chat instead. This is a client
  restriction, not something the addon can work around.
- Meerah's Jukebox is a toy from the Vol'dun storyline in Battle for Azeroth.
  The song is the one Meerah sings to her alpacas.

## Credits

Based on the "Dolly and Dot" WeakAura by its original author on wago.io.

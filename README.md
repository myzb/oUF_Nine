# oUF Nine

oUF Nine is a layout for the World of Warcraft unit frame addon [oUF](https://github.com/oUF-wow/oUF).
It aims to provide a clean and simplistic user interface while not cutting down on important information.

![oUF_Nine](https://i.imgur.com/HC11iDW.jpg)

_Image: oUF Nine in static (dark gray) color mode. Also shown is 'Dominos' action bar and 'Details!' damage meter addon_

## Features and Customization

The layout was mainly made for my own use, as such I currently don't plan to add an in-game customization menu.
All customization is done by editing the files in the ``config`` folder. Frames can be configured to show as class colored or static colored.
Most if not all features found in the default UI have been ported, including a few own additions. Key features are:

* Player Frame
  * _castbar_
  * _additional resource bar (certain boss encounters)_
  * _special class resources (totems, mana for non-healers, combo points, ...)_
  * _important player auras (i.e. defensive/offensive buffs)_
* Target Frame
  * _castbar_
  * _additional resource bar_
  * _target auras_
* Target of Target Frame
* Focus Frame
  * _castbar_
  * _raid style aura display_
* Focus Target Frame
* Pet Frame
  * _castbar_
* Boss Frame
  * _castbar_
  * _important debuffs (mirrors nameplate debuffs)_
* Party/Raid Frames
  * _inspired by blizzards default raid frames (i.e aura presentation)_
  * _blizzards dispel icon_
  * _option to define size and position_
  * _multiple profiles that activate based on specialization/group-size_
  * _frame coloring when special player buffs are applied (useful for healers to i.e. track hots)_
  * _debuff priority sorting (boss, pvp crowd control, ...)_
  * _defensive cooldown display_
  * _big debuffs for pve dispellables or pvp crowd-controls_
  * _frame right-clickthrough option (useful for healers)_
  * _party pets_
* Arena Frame
  * _castbar_
  * _important debuffs (mirrors nameplate debuffs)_
  * _includes arena preparation frame (class/spec detection)_
  * _pvp trinket display_
* Nameplates
  * _castbar_
  * _widget xp bar (i.e. nazjatar followers)_
  * _important debuffs and purgeable/stealable buffs_
  * _class and threat colored nameplates (useful for tanks)_
* Infobars
  * _experience, reputation, honor bar_
* Miscellaneous
  * _option to hide blizzard talking head frame_
  * _option to move tooltip frame_
  * _support for omniCD party cd tracking addon_

## Feedback and Feature Requests
To report a bug, please use the [issues](https://github.com/myzb/oUF_Nine/issues) section of Github. I want to keep
the layout minimalistic and clean. You are welcome to post suggestions, but I will only implement things that I find useful myself.

## Legal
Please see the [LICENSE](https://github.com/myzb/oUF_Nine/blob/master/LICENSE.txt) file.

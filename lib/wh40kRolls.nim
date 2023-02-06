import std/random
import std/re
import std/sugar
import std/enumerate
import terminal
import sequtils
import math
import strutils

randomize()

proc roll*(nb: int, sides: int): seq[int] =
    if sides == 0:
        result = @[nb]
    else:
        result = collect(newSeq):
            for i in 1..nb:
                rand(1..sides)

proc rolls_diff*(org: seq[int], `new`: seq[int]): seq[string] =
    for (o, n) in zip(org, `new`):
        if o != n:
            result.add($o & " => " & $n)

proc wound_target*(s: int, t: int, modifiers: int): int =
    if s == t:
        result = 4
    elif s * 2 < t:
        result = 6
    elif s < t:
        result = 5
    elif t * 2 < s:
        result = 2
    else:
        result = 3
    result = clamp(2, result - clamp(-1, modifiers, 1), 6)


proc check_above*(rolls: seq[int], target: int): seq[bool] = 
    result = collect(newSeq):
        for roll in rolls:
            roll >= target

proc check_below*(rolls: seq[int], target: int): seq[bool] = 
    result = collect(newSeq):
        for roll in rolls:
            roll <= target

proc rerolls*(rolls: seq[int], nb_rerolls: int, rerolls_on: int): seq[int] =
    var
        new_rolls: seq[int]
        tmp: int
        reroll_left: int = nb_rerolls
        always_reroll: bool = nb_rerolls == 0
    for idx, r in enumerate(rolls):
        if r <= rerolls_on and (reroll_left > 0 or always_reroll):
            reroll_left -= 1
            if always_reroll:
                tmp = rand((rerolls_on+1)..6)
            else:
                tmp = rand(1..6)
            new_rolls.add(tmp)
        else:
            new_rolls.add(r)
    return new_rolls

proc attack_roll*(a: string): (seq[int], int) =
    var
        attack_rolls: seq[int]
        attacks: int
        matches: array[2, string]
        nb: int
        sides: int

    discard match(a, re"^(\d+)?(?:[d,D]([3,6]))?$", matches=matches)

    nb = (if len(matches[0]) != 0: parseInt(matches[0]) else: 1)
    sides = (if len(matches[1]) != 0: parseInt(matches[1]) else: 0)
    
    attack_rolls = roll(nb, sides)
    attacks = sum(attack_rolls)
    
    return (attack_rolls, attacks)

proc hit_roll*(attacks: int, ws: int, autohits: bool = false, nb_rerolls: int = 0, rerolls_on: int = 0): (seq[int], seq[bool], int, seq[int], seq[bool]) =
    if autohits:
        return (@[], @[], attacks, @[], @[])
    var
        hit_rolls: seq[int]
        new_rolls: seq[int]
        success_old: seq[bool]
        success_new: seq[bool]
        hits: int
    
    hit_rolls = roll(attacks, 6)
    success_old = check_above(hit_rolls, ws)
    new_rolls = rerolls(hit_rolls, nb_rerolls, rerolls_on)
    success_new = check_above(new_rolls, ws)
    hits = count(success_new, true)
    
    return (new_rolls, success_new, hits, hit_rolls, success_old)

proc wound_roll*(hits: int, s: int, t: int, modifiers: int, autowound: bool = false, nb_rerolls: int = 0, rerolls_on: int = 0): (seq[int], seq[bool], int, seq[int], seq[bool]) =
    if autowound:
        return (@[], @[], hits, @[], @[])
    var
        org_rolls: seq[int]
        new_rolls: seq[int]
        success_old: seq[bool]
        success_new: seq[bool]
        target: int
        wounds: int
    
    target = wound_target(s, t, modifiers)
    org_rolls = roll(hits, 6)
    success_old = check_above(org_rolls, target)
    new_rolls = rerolls(org_rolls, nb_rerolls, rerolls_on)
    success_new = check_above(new_rolls, target)
    wounds = count(success_new, true)
    
    return (new_rolls, success_new, wounds, org_rolls, success_old)

proc save_roll*(wounds: int, sv: int, ap: int, d: int, nb_rerolls: int = 0, rerolls_on: int = 0): (seq[int], seq[bool], int, seq[int], seq[bool])  = 
    if sv + ap >= 7:
        return (@[], @[], wounds * d, @[], @[])
    var
        rolls: seq[int]
        new_rolls: seq[int]
        success_old: seq[bool]
        success_new: seq[bool]
        damage: int
    
    rolls = roll(wounds, 6)
    success_old = check_above(rolls, sv + ap)
    new_rolls = rerolls(rolls, nb_rerolls, rerolls_on)
    success_new = check_above(new_rolls, sv + ap)
    damage = count(success_new, false) * d
    
    return (new_rolls, success_new, damage, rolls, success_old)

proc print_attacks_roll*(a: string, attack_rolls: seq[int], attacks: int, file=stdout) =
    echo "Attacks rolls: ", a
    file.write "Rolls: "
    for roll in attack_rolls:
        file.write $roll & " "
    echo "Total: ", attacks

proc print_roll*(rolls: seq[int], success: seq[bool], nb: int, file=stdout) =
    file.write "Rolls: "
    for (s, r) in zip(success, rolls):
        if s:
            styledWrite file, fggreen, $r & " "
        else:
            styledWrite file, fgRed, $r & " "
    echo "Total: ", nb


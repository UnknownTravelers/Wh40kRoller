import wnim
import sequtils
import strutils

import lib/wh40kRolls

let app = App(wSystemDpiAware)
let frame = Frame(title="WarHammer 40k Rolls", style=wDefaultFrameStyle or wModalFrame)
frame.dpiAutoScale:
  frame.size = (640, 570)
  frame.minSize = (640, 530)

let panel = Panel(frame)
let staticbox1 = StaticBox(panel, label="Allie")
let staticbox2 = StaticBox(panel, label="Results")
let staticbox3 = StaticBox(panel, label="Foe")
let staticbox4 = StaticBox(panel, label="Autowin Roll")
let staticbox5 = StaticBox(panel, label="Rerolls")

# ---- Allie stats
let alabel = StaticText(panel, label="A", style=wAlignLeft)
let ainput = TextCtrl(panel, value="D6", style=wBorderSunken)

let wslabel = StaticText(panel, label="WS")
let wsinput = SpinCtrl(panel, value="3")
wsinput.setRange(0, 10)

let slabel = StaticText(panel, label="S")
let sinput = SpinCtrl(panel, value="3", style=wBorderSunken)
sinput.setRange(1, 100)

let aplabel = StaticText(panel, label="AP")
let apinput = SpinCtrl(panel, value="-1")
apinput.setRange(-100, 0)

let dlabel = StaticText(panel, label="D")
let dinput = SpinCtrl(panel, value="1")
dinput.setRange(1, 100)

# ---- Ennemy stats

let tlabel = StaticText(panel, label="T")
let tinput = SpinCtrl(panel, value="4")
tinput.setRange(1, 100)

let svlabel = StaticText(panel, label="Sv")
let svinput = SpinCtrl(panel, value="3")
svinput.setRange(0, 10)

# ---- Autowin

let autohitCheckBox = CheckBox(panel, label="Autohit")
let autowoundCheckBox = CheckBox(panel, label="Autowound")

# ---- Rerolls

let placeholder = StaticText(panel, label="")
let rerollOnTitle = StaticText(panel, label="Reroll On")
let nbRerollTitle = StaticText(panel, label="Nb Reroll")

let hitLabel = StaticText(panel, label="Hit")
let hitRerollOn = SpinCtrl(panel, value="0")
let hitNbReroll = SpinCtrl(panel, value="0")

let woundLabel = StaticText(panel, label="Wound")
let woundRerollOn = SpinCtrl(panel, value="0")
let woundNbReroll = SpinCtrl(panel, value="0")

let saveLabel = StaticText(panel, label="Save")
let saveRerollOn = SpinCtrl(panel, value="0")
let saveNbReroll = SpinCtrl(panel, value="0")

# ---- Result text
let resultsDisplay = TextCtrl(panel, style=wTeMultiline + wBorderSunken + wTeReadOnly + wTeRich)

# ---- Actions
let rollButton = Button(panel, label="Roll All")
let rollAttackButton = Button(panel, label="Roll Attack")
let rollHitButton = Button(panel, label="Roll Hit")
let rollWoundButton = Button(panel, label="Roll Wound")
let rollSaveButton = Button(panel, label="Roll Save")

proc printText(txt: string, newLine:bool=false, color=0x010101) =
    resultsDisplay.setFormat(fgColor=color)
    resultsDisplay.appendText(txt)
    resultsDisplay.setFormat(fgColor=0x010101)
    if newLine:
        resultsDisplay.appendText("\n")

proc displayRolls(old_rolls: seq[int], new_rolls: seq[int], success_old: seq[bool], success_new: seq[bool], hits: int) =
    printText("Rolls: ")
    for (s, r) in zip(success_old, old_rolls):
        if s:
            printText($r & " ", color=wGreen)
        else:
            printText($r & " ", color=wRed)
    let diffs = rolls_diff(old_rolls, new_rolls)
    if len(diffs) > 0:
        printText("\n Rerolls: ", true)
        for d in diffs:
            printText($d & " ")
        printText("", true)
        printText("Rolls: ")
        for (s, r) in zip(success_new, new_rolls):
            if s:
                printText($r & " ", color=wGreen)
            else:
                printText($r & " ", color=wRed)
    printText("Total: " & $hits, true)
    printText("", true)

# -- Actions
# TODO: clear display on roll, other button open dialog for number of dice to roll

rollButton.wEvent_Button do ():
    let
        a: string = ainput.getValue()
        ws: int = wsinput.getValue()
        autohit: bool = autohitCheckBox.getValue()
        hit_rerolls: int = hitNbReroll.getValue()
        hit_rerolls_on: int = hitRerollOn.getValue()
        s: int = sinput.getValue()
        t: int = tinput.getValue()
        wound_roll_mod: int = 0
        autowound: bool = autowoundCheckBox.getValue()
        wound_rerolls: int = woundNbReroll.getValue()
        wound_rerolls_on: int = woundRerollOn.getValue()
        sv: int = svinput.getValue()
        ap: int = abs(apinput.getValue())
        d: int = dinput.getValue()
        save_rerolls: int = saveNbReroll.getValue()
        save_rerolls_on: int = saveRerollOn.getValue()
    
    var
        attack_rolls: seq[int]
        attacks: int

        hit_rolls: seq[int]
        success_hit: seq[bool]
        hits: int
        org_hit_rolls: seq[int]
        success_hit_old: seq[bool]

        wound_rolls: seq[int]
        success_wound: seq[bool]
        wounds: int
        org_wound_rolls: seq[int]
        success_wound_old: seq[bool]

        save_rolls: seq[int]
        success_save: seq[bool]
        damage: int
        org_save_rolls: seq[int]
        success_save_old: seq[bool]

    
    resultsDisplay.clear()

    (attack_rolls, attacks) = attack_roll(a)
    
    printText("Attacks rolls: " & a, true)
    printText("Rolls: ")
    for roll in attack_rolls:
        printText($roll & " ")
    printText("Total: " & $attacks, true)
    printText("", true)

    if attacks <= 0:
        return

    (hit_rolls, success_hit, hits, org_hit_rolls, success_hit_old) = hit_roll(attacks, ws, autohit, hit_rerolls, hit_rerolls_on)
    
    if autohit:
        printText("Autohit", true)
    else:
        printText("Hit on " & $ws & "+", true)
        displayRolls(org_hit_rolls, hit_rolls, success_hit_old, success_hit, hits)

    if hits <= 0:
        return

    (wound_rolls, success_wound, wounds, org_wound_rolls, success_wound_old) = wound_roll(hits, s, t, wound_roll_mod, autowound, wound_rerolls, wound_rerolls_on)

    if autowound:
        printText("Autowound", true)
    else:
        printText("S: " & $s & ", T: " & $t & ", Mod: " & $wound_roll_mod, true)
        printText("Wound on " & $wound_target(s, t, wound_roll_mod) & "+", true)
        displayRolls(org_wound_rolls, wound_rolls, success_wound_old, success_wound, wounds)

    if wounds <= 0:
        return

    (save_rolls, success_save, damage, org_save_rolls, success_save_old) = save_roll(wounds, sv, ap, d, save_rerolls, save_rerolls_on)

    printText("Sv: " & $sv & "+, AP: -" & $ap & ", D: " & $d, true)
    printText("Saved on " & $(sv + ap) & "+", true)
    displayRolls(org_save_rolls, save_rolls, success_save_old, success_save, damage)

rollAttackButton.wEvent_Button do ():
    var
        a: string
        attack_rolls: seq[int]
        attacks: int
    
    resultsDisplay.clear()

    a = TextEntryDialog(message="What to roll", value="d6").display()
    (attack_rolls, attacks) = attack_roll(a)

    printText("Attacks rolls: " & a, true)
    printText("Rolls: ")
    for roll in attack_rolls:
        printText($roll & " ")
    printText("Total: " & $attacks, true)
    printText("", true)

rollHitButton.wEvent_Button do ():
    let
        ws: int = wsinput.getValue()
        hit_rerolls: int = hitNbReroll.getValue()
        hit_rerolls_on: int = hitRerollOn.getValue()
    var
        attacks: int
        hit_rolls: seq[int]
        success_hit: seq[bool]
        hits: int
        org_hit_rolls: seq[int]
        success_hit_old: seq[bool]

    resultsDisplay.clear()

    attacks = TextEntryDialog(message="How many roll").display().parseInt()
    (hit_rolls, success_hit, hits, org_hit_rolls, success_hit_old) = hit_roll(attacks, ws, false, hit_rerolls, hit_rerolls_on)
    
    printText("Hit on " & $ws & "+", true)
    displayRolls(org_hit_rolls, hit_rolls, success_hit_old, success_hit, hits)

rollWoundButton.wEvent_Button do ():
    let
        s: int = sinput.getValue()
        t: int = tinput.getValue()
        wound_roll_mod: int = 0
        wound_rerolls: int = woundNbReroll.getValue()
        wound_rerolls_on: int = woundRerollOn.getValue()
    var
        hits: int
        wound_rolls: seq[int]
        success_wound: seq[bool]
        wounds: int
        org_wound_rolls: seq[int]
        success_wound_old: seq[bool]

    resultsDisplay.clear()
    
    hits = TextEntryDialog(message="How many roll").display().parseInt()
    (wound_rolls, success_wound, wounds, org_wound_rolls, success_wound_old) = wound_roll(hits, s, t, wound_roll_mod, false, wound_rerolls, wound_rerolls_on)

    printText("S: " & $s & ", T: " & $t & ", Mod: " & $wound_roll_mod, true)
    printText("Wound on " & $wound_target(s, t, wound_roll_mod) & "+", true)
    displayRolls(org_wound_rolls, wound_rolls, success_wound_old, success_wound, wounds)

rollSaveButton.wEvent_Button do ():
    let
        sv: int = svinput.getValue()
        ap: int = abs(apinput.getValue())
        d: int = dinput.getValue()
        save_rerolls: int = saveNbReroll.getValue()
        save_rerolls_on: int = saveRerollOn.getValue()
    var
        wounds: int
        save_rolls: seq[int]
        success_save: seq[bool]
        damage: int
        org_save_rolls: seq[int]
        success_save_old: seq[bool]

    resultsDisplay.clear()
    
    wounds = TextEntryDialog(message="How many roll").display().parseInt()
    (save_rolls, success_save, damage, org_save_rolls, success_save_old) = save_roll(wounds, sv, ap, d, save_rerolls, save_rerolls_on)

    printText("Sv: " & $sv & "+, AP: -" & $ap & ", D: " & $d, true)
    printText("Saved on " & $(sv + ap) & "+", true)
    displayRolls(org_save_rolls, save_rolls, success_save_old, success_save, damage)


proc layout() =
    panel.autolayout """
        spacing: 10
        V: |-[staticbox1(>=200)]-[rollButton]-[rollAttackButton]-[rollHitButton]-[rollWoundButton]-[rollSaveButton]~[staticbox2]-|
        V: |-[staticbox3(==100)]-[staticbox4(==100)]-[staticbox5(==170)]-[staticbox2]-|
        H: |-[staticbox1, rollButton, rollAttackButton, rollHitButton, rollWoundButton, rollSaveButton]-[staticbox3..5(==48%)]-|
        H: |-[staticbox2]-|

        outer: staticbox1
        V: |-5-{stack2:[alabel]-[wslabel]-[slabel]-[aplabel]-[dlabel]}
        V: |-5-{stack3:[ainput]-[wsinput]-[sinput]-[apinput]-[dinput]}
        H: |-[stack2][stack3(==65%)]-15-|
        
        outer: staticbox2
        HV: |[resultsDisplay]|

        outer: staticbox3
        V: |-5-{stack4:[tlabel]-[svlabel]}
        V: |-5-{stack5:[tinput]-[svinput]}
        H: |-[stack4][stack5(==60%)]-|
        
        outer: staticbox4
        V: |-5-[autohitCheckBox]-[autowoundCheckBox]
        H :|-[autohitCheckBox,autowoundCheckBox]-|

        outer: staticbox5
        V: |-5-{stack7:[placeholder]-[hitLabel]-[woundLabel]-[saveLabel]}
        V: |-5-{stack8:[rerollOnTitle]-[hitRerollOn]-[woundRerollOn]-[saveRerollOn]}
        V: |-5-{stack9:[nbRerollTitle]-[hitNbReroll]-[woundNbReroll]-[saveNbReroll]}
        H: |-[stack7(>=20%)][stack8(>20%)][stack9(>=20%)]-|

    """


panel.wEvent_Size do ():
    layout()

layout()
frame.center() # Center frame window in screen
frame.show() # A frame is hidden on creation by default.
app.mainLoop() # or app.run()
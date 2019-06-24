Scriptname gpp_keyhandler extends ReferenceAlias

import Input

; Action Keys
int property GPP_KEYCODE_A1 = 268 auto hidden 		; Default: DPad Left
int property GPP_KEYCODE_A2 = 269 auto hidden 		; Default: DPad Right
int property GPP_KEYCODE_A3 = 266 auto hidden 		; Default: DPad Up
int property GPP_KEYCODE_A4 = 267 auto hidden 		; Default: DPad Down
int[] aiActionKeys

; Combo Keys
int property GPP_KEYCODE_C1 = 277 auto hidden 		; Default: B
int property GPP_KEYCODE_C2 = 274 auto hidden 		; Default: LB
int property GPP_KEYCODE_C3 = 275 auto hidden 		; Default: RB
int property GPP_KEYCODE_C4 = -1 auto hidden

; Globals containing same combo key values as above, only used by iEquip to update whenever a G++ combo key is changed in the G++ MCM (Fill through the CK)
GlobalVariable property GPP_COMBO1 auto 			; Default: 277, B
GlobalVariable property GPP_COMBO2 auto 			; Default: 274, LB
GlobalVariable property GPP_COMBO3 auto 			; Default: 275, RB
GlobalVariable property GPP_COMBO4 auto 			; Default: -1

; Input Mode Toggle Key
int property GPP_HOTKEY_TIM auto hidden 			; Default: CapsLock

; Arrays containing KeyCode values to be emulated with TapKey
int[] property aiNonComboActions auto hidden
int[] property aiC1Actions auto hidden
int[] property aiC2Actions auto hidden
int[] property aiC3Actions auto hidden
int[] property aiC4Actions auto hidden

bool bIsC1Held
bool bIsC2Held
bool bIsC3Held
bool bIsC4Held

; Delays
float property fMultiTapDelay = 0.3 auto hidden
float property fLongPressDelay = 0.6 auto hidden

; Bools
bool property bAllowKeyPress = true auto hidden
bool property bFourthComboEnabled auto hidden
bool property bExtControlsEnabled auto hidden
bool bNotInLootMenu = true

; Ints
int iWaitingKeyCode
int iMultiTap

; Strings
string sPreviousState

; iEquip Support
bool property biEquipLoaded auto hidden
int[] property aiiEquipKeys auto hidden

Event OnInit()

	aiNonComboActions = new int[16]
	aiC1Actions = new int[16]
	aiC2Actions = new int[16]
	aiC3Actions = new int[16]
	aiC4Actions = new int[16]

	int i
	while i < 16
		aiNonComboActions[i] = -1
		aiC1Actions[i] = -1
		aiC2Actions[i] = -1
		aiC3Actions[i] = -1
		aiC4Actions[i] = -1
		i += 1
	endWhile

	aiActionKeys = new int[4]

	aiiEquipKeys = new int[5]
	
	OnPlayerLoadGame()
EndEvent

event OnPlayerLoadGame()

	GotoState("")
    
    RegisterForMenu("InventoryMenu")
    RegisterForMenu("MagicMenu")
    RegisterForMenu("FavoritesMenu")
    RegisterForMenu("ContainerMenu")
    RegisterForMenu("BarterMenu")
    RegisterForMenu("Crafting Menu")
    RegisterForMenu("Dialogue Menu")
    RegisterForMenu("LootMenu")
    RegisterForMenu("CustomMenu")
    RegisterForMenu("Journal Menu")
    RegisterForMenu("Console")
    RegisterForMenu("GiftMenu")
    RegisterForMenu("Lockpicking Menu")
    RegisterForMenu("MapMenu")
    RegisterForMenu("RaceSex Menu")
    RegisterForMenu("Sleep/Wait Menu")
    RegisterForMenu("StatsMenu")
    RegisterForMenu("Training Menu")
    RegisterForMenu("TweenMenu")
    RegisterForMenu("Quantity Menu")

    ; Reset
    bNotInLootMenu = true
    bIsC1Held = false
    bIsC2Held = false
    bIsC3Held = false
    bIsC4Held = false
    UnregisterForUpdate()
    iWaitingKeyCode = 0
    iMultiTap = 0
    bAllowKeyPress = true

	biEquipLoaded = Game.GetModByName("iEquip.esp") != 255

	if biEquipLoaded
		updateiEquipKeysArray()
		Self.RegisterForModEvent("iEquip_KeysUpdated", "oniEquipKeysUpdated")
	else
		int i
		while i < 5
			aiiEquipKeys[i] = -1
			i += 1
		endWhile
		Self.UnregisterForModEvent("iEquip_KeysUpdated")
	endIf

	RegisterKeys()
endEvent

Function RegisterKeys()
	UnregisterForAllKeys()
	
	; Register for action keys
	RegisterForKey(GPP_KEYCODE_A1)
	RegisterForKey(GPP_KEYCODE_A2)
	RegisterForKey(GPP_KEYCODE_A3)
	RegisterForKey(GPP_KEYCODE_A4)

	aiActionKeys[0] = GPP_KEYCODE_A1
	aiActionKeys[1] = GPP_KEYCODE_A2
	aiActionKeys[2] = GPP_KEYCODE_A3
	aiActionKeys[3] = GPP_KEYCODE_A4
	
	; Register for combo keys
	RegisterForKey(GPP_KEYCODE_C1)
	RegisterForKey(GPP_KEYCODE_C2)
	RegisterForKey(GPP_KEYCODE_C3)
	
	if bFourthComboEnabled
		RegisterForKey(GPP_KEYCODE_C4)
	endif
EndFunction

event oniEquipKeysUpdated(string sEventName, string sStringArg, Float fNumArg, Form kSender)
	updateiEquipKeysArray()
endEvent

function updateiEquipKeysArray()
	aiiEquipKeys[0] = (Game.GetFormFromFile(0x00113B9F, "iEquip.esp") as globalvariable).GetValueInt()	; iEquipLeftKey
	aiiEquipKeys[1] = (Game.GetFormFromFile(0x00113BA0, "iEquip.esp") as globalvariable).GetValueInt()	; iEquipRightKey
	aiiEquipKeys[2] = (Game.GetFormFromFile(0x00113BA1, "iEquip.esp") as globalvariable).GetValueInt()	; iEquipShoutKey
	aiiEquipKeys[3] = (Game.GetFormFromFile(0x00113BA2, "iEquip.esp") as globalvariable).GetValueInt()	; iEquipConsumableKey
	aiiEquipKeys[4] = (Game.GetFormFromFile(0x00113BA3, "iEquip.esp") as globalvariable).GetValueInt()	; iEquipUtilityKey
endFunction

event OnMenuOpen(string MenuName)
    if MenuName == "LootMenu"
        bNotInLootMenu = false
    else
        sPreviousState = GetState()
        GoToState("DISABLED")
        UnregisterForUpdate()
        iWaitingKeyCode = 0
        iMultiTap = 0
    endIf
endEvent

event OnMenuClose(string MenuName)
    if MenuName == "LootMenu"
        bNotInLootMenu = true
    else 
        GotoState(sPreviousState)
    endIf
endEvent

event OnUpdate()
    bAllowKeyPress = false
    
    runUpdate()
    
    iMultiTap = 0
    iWaitingKeyCode = 0
    bAllowKeyPress = true
endEvent

; ---------------------
; - DEFAULT BEHAVIOUR -
; ---------------------

event OnKeyDown(int KeyCode)

	bool bIsComboKey

	if KeyCode == GPP_KEYCODE_C1
		bIsC1Held = true
		bIsComboKey = true
	elseIf KeyCode == GPP_KEYCODE_C2
		bIsC2Held = true
		bIsComboKey = true
	elseIf KeyCode == GPP_KEYCODE_C3
		bIsC3Held = true
		bIsComboKey = true
	elseIf KeyCode == GPP_KEYCODE_C4
		bIsC4Held = true
		bIsComboKey = true
	endif

    if bAllowKeyPress
        if KeyCode != iWaitingKeyCode && iWaitingKeyCode != 0
            if !bIsComboKey
                ; The player pressed a different key, so force the current one to process if there is one
                UnregisterForUpdate()
                OnUpdate()
            else
                iMultiTap = 0
            endIf
        endIf
        iWaitingKeyCode = KeyCode
   	
        if iMultiTap == 0       ; This is the first time the key has been pressed
            RegisterForSingleUpdate(fLongPressDelay)
        elseIf iMultiTap == 1   ; This is the second time the key has been pressed.
            iMultiTap = 2
            RegisterForSingleUpdate(fMultiTapDelay)
        elseIf iMultiTap == 2   ; This is the third time the key has been pressed
            iMultiTap = 3
            RegisterForSingleUpdate(0.0)
        endIf
    endif
endEvent

event OnKeyUp(int KeyCode, Float HoldTime)
    
    if KeyCode == GPP_KEYCODE_C1
		bIsC1Held = false
	elseIf KeyCode == GPP_KEYCODE_C2
		bIsC2Held = false
	elseIf KeyCode == GPP_KEYCODE_C3
		bIsC3Held = false
	elseIf KeyCode == GPP_KEYCODE_C4
		bIsC4Held = false
	endif

    if bAllowKeyPress && KeyCode == iWaitingKeyCode && iMultiTap == 0
        iMultiTap = 1
        RegisterForSingleUpdate(fMultiTapDelay)
    endIf
endEvent

function runUpdate()

	if iMultiTap == 1 || bExtControlsEnabled && (bNotInLootMenu || (iWaitingKeyCode != 266 || iWaitingKeyCode != 267))		; Ignore everything except single press is extended controls disabled, and ignore DPad Up/Down if QuickLoot LootMenu is open

		int keyToTap
	    
	    if bIsC1Held
	    	keyToTap = aiC1Actions[aiActionKeys.Find(iWaitingKeyCode)*4 + iMultiTap]
	            
	    elseIf bIsC1Held
	        keyToTap = aiC2Actions[aiActionKeys.Find(iWaitingKeyCode)*4 + iMultiTap]
	        
	    elseIf bIsC1Held
	        keyToTap = aiC3Actions[aiActionKeys.Find(iWaitingKeyCode)*4 + iMultiTap]
	        
	    elseIf bIsC1Held
	    	keyToTap = aiC4Actions[aiActionKeys.Find(iWaitingKeyCode)*4 + iMultiTap]

	    elseIf !biEquipLoaded || aiiEquipKeys.Find(iWaitingKeyCode) == -1													; Block all non-combo keypresses if it is an iEquip key
	    	keyToTap = aiNonComboActions[aiActionKeys.Find(iWaitingKeyCode)*4 + iMultiTap]

	    endIf

	    if keyToTap > 0
	    	TapKey(keyToTap)
	    endIf

	endIf

endFunction

; - Disabled
state DISABLED
    event OnBeginState()
        bAllowKeyPress = false
    endEvent
    
    event OnEndState()
        bAllowKeyPress = true
    endEvent
endState
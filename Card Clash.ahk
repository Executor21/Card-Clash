/*
Script: Card Clash
Συγγραφέας: Tasos
Έτος: 2025
MIT License
Copyright (c) 2025 Tasos
*/
#Requires AutoHotkey v2.0

; -------------------- GLOBAL SETTINGS --------------------
DECKS_FOLDER := "Decks\"
CARDS_FOLDER := "Cards\"
DATA_FOLDER := "Data\"

; -------------------- GLOBAL STATE --------------------
global mainGui := ""
global currentDeck := ""
global playerCards := []
global aiCards := []
global currentPlayerCard := ""
global currentAICard := ""
global allDecks := {}
global gameStarted := false
global statButtons := []
global imageCache := Map()
global gameHistory := []
global totalGamesPlayed := 0
global totalWins := 0
global totalLosses := 0
global soundsFolder := ""
global soundEnabled := true

global settings := Map(
    "soundEnabled", true,
    "animationsEnabled", true,
    "confirmExit", true,
    "autoSave", true
)

; -------------------- MAIN ENTRY POINT --------------------
Main()

Main() {
    global allDecks, mainGui, settings, soundsFolder, DATA_FOLDER
    
    ; Create data folder if it doesn't exist
    if !DirExist(DATA_FOLDER)
        DirCreate(DATA_FOLDER)
    
    ; Create sounds folder if it doesn't exist
    soundsFolder := DATA_FOLDER . "Sounds\"
    if !DirExist(soundsFolder)
        DirCreate(soundsFolder)
    
    ; Load settings
    LoadSettings()
    
    ; Load all decks from folder
    allDecks := LoadDecks()
    
    if (allDecks.Count = 0) {
        MsgBox "Δεν βρέθηκαν decks!`n`nΦτιάξε φάκελο 'decks\' και βάλε .ini αρχεία μέσα."
        ExitApp
    }
    
    ; Validate decks
    ValidateDecks()
    
    ; Create and show GUI
    TraySetIcon("Shell32.dll", 44)
    mainGui := CreateGUI()
    mainGui.Opt("-Resize +MaximizeBox +MinimizeBox")
    mainGui.OnEvent("Close", OnGuiClose)
    
    ; Populate deck dropdown
    deckNames := []
    for name in allDecks {
        deckNames.Push(name)
    }
    mainGui["DeckList"].Add(deckNames)
    if (deckNames.Length > 0)
        mainGui["DeckList"].Choose(1)
    
    ; Try to load saved game
    if (settings["autoSave"])
        TryLoadAutoSave()
    
    ; === REGISTER HOTKEYS AFTER GUI IS CREATED ===
    RegisterHotkeys()
    
    PlaySound("activate")
}

; -------------------- HOTKEY REGISTRATION --------------------
RegisterHotkeys() {
    global mainGui
    
    ; Make hotkeys active only when GUI window is active
    HotIfWinActive("ahk_id " . mainGui.Hwnd)
    
    ; Space - Next Round
    Hotkey("Space", NextRoundHotkey)
    
    ; Enter - Start/Restart Game
    Hotkey("Enter", StartGameHotkey)
    
    ; Numbers 1-9 - Select Stat
    Hotkey("1", StatButtonHotkey1)
    Hotkey("2", StatButtonHotkey2)
    Hotkey("3", StatButtonHotkey3)
    Hotkey("4", StatButtonHotkey4)
    Hotkey("5", StatButtonHotkey5)
    Hotkey("6", StatButtonHotkey6)
    Hotkey("7", StatButtonHotkey7)
    Hotkey("8", StatButtonHotkey8)
    Hotkey("9", StatButtonHotkey9)
    
    ; ESC - Exit with confirmation
    Hotkey("Escape", ExitHotkey)
    
    ; Ctrl+S - Quick Save
    Hotkey("^s", SaveGameHotkey)
    
    ; Ctrl+L - Load
    Hotkey("^l", LoadGameHotkey)
    
    HotIfWinActive()
}

; -------- HOTKEY FUNCTIONS --------
NextRoundHotkey(HotKeyObj) {
    global mainGui
    try {
        if (mainGui["NextBtn"].Enabled) {
            OnNextRound()
        }
    }
}

StartGameHotkey(HotKeyObj) {
    global mainGui
    try {
        if (mainGui["StartBtn"].Enabled) {
            OnStartGame()
        }
    }
}

StatButtonHotkey1(HotKeyObj) {
    TriggerStatButton(1)
}

StatButtonHotkey2(HotKeyObj) {
    TriggerStatButton(2)
}

StatButtonHotkey3(HotKeyObj) {
    TriggerStatButton(3)
}

StatButtonHotkey4(HotKeyObj) {
    TriggerStatButton(4)
}

StatButtonHotkey5(HotKeyObj) {
    TriggerStatButton(5)
}

StatButtonHotkey6(HotKeyObj) {
    TriggerStatButton(6)
}

StatButtonHotkey7(HotKeyObj) {
    TriggerStatButton(7)
}

StatButtonHotkey8(HotKeyObj) {
    TriggerStatButton(8)
}

StatButtonHotkey9(HotKeyObj) {
    TriggerStatButton(9)
}

ExitHotkey(HotKeyObj) {
    OnGuiClose()
}

SaveGameHotkey(HotKeyObj) {
    SaveGame()
}

LoadGameHotkey(HotKeyObj) {
    LoadGame()
}

TriggerStatButton(index) {
    global statButtons
    
    try {
        ; Check if button exists and is enabled
        if (statButtons.Length >= index && statButtons[index].Enabled) {
            ; Get the button text and extract the stat name
            buttonText := statButtons[index].Text
            ; Remove the emoji, spaces, and hotkey hint [1-9]
            stat := RegExReplace(buttonText, "^⚔️\s+|\s+\[\d+\]$", "")
            ; Trigger the stat button click
            OnStatButtonClick(stat)
        }
    } catch as err {
        ; Silently fail if button doesn't exist or isn't ready
    }
}

; -------------------- SOUND SYSTEM --------------------
PlaySound(soundType) {
    global soundsFolder, soundEnabled
    
    if !soundEnabled
        return
    
    soundFile := ""
    
    switch soundType {
        case "activate":
            soundFile := soundsFolder . "Activate.wav"
        case "save":
            soundFile := soundsFolder . "Save.wav"
        case "error":
            soundFile := soundsFolder . "Error.wav"
        case "win":
            soundFile := soundsFolder . "Win.wav"
        case "lose":
            soundFile := soundsFolder . "Lose.wav"
    }
    
    if FileExist(soundFile) {
        try {
            SoundPlay(soundFile)
        }
    }
}

; -------------------- GUI CREATION --------------------
CreateGUI() {
    global
    
    gameGui := Gui("-DPIScale", "🎴 Card Clash")
    gameGui.BackColor := "0x1a1a2e"
    
    ; === HEADER SECTION ===
    gameGui.SetFont("s14 Bold", "Segoe UI")
    gameGui.Add("Text", "x20 y15 w300 h35 cWhite", "🎴 Card Clash")
    
    ; Card count display (top right)
    gameGui.SetFont("s14 Bold", "Segoe UI")
    gameGui.Add("Text", "x900 y15 w380 h35 vCardCount Center c00FF00 Background0x16213e", "Επίλεξε Deck")
    
    ; === PLAYER CARD SECTION (TOP LEFT - HORIZONTAL) ===
    gameGui.SetFont("s12 Bold", "Segoe UI")
    gameGui.Add("GroupBox", "x20 y60 w400 h320 cWhite", "🂠 PLAYER")
    gameGui.Add("Text", "x30 y85 w160 h25 vPlayerCardCount Center cYellow Background0x0f3460", "Κάρτες: 0")
    
    ; Player card image (horizontal - wider than tall)
    gameGui.Add("Picture", "x30 y120 w370 h240 vPlayerImage Border")
    
    ; === AI CARD SECTION (TOP RIGHT - HORIZONTAL) ===
    gameGui.SetFont("s12 Bold", "Segoe UI")
    gameGui.Add("GroupBox", "x880 y60 w400 h320 cWhite", "🤖 AI")
    gameGui.Add("Text", "x890 y85 w160 h25 vAICardCount Center cYellow Background0x0f3460", "Κάρτες: 0")
    
    ; AI card image (horizontal - wider than tall)
    gameGui.Add("Picture", "x890 y120 w370 h240 vAIImage Border")
    
    ; === CENTER TOP SECTION - DECK SELECTION ===
    gameGui.SetFont("s11 Bold", "Segoe UI")
    gameGui.Add("Text", "x440 y70 cWhite Center w420", "📚 Επιλογή Deck:")
    gameGui.Add("DropDownList", "x440 y95 w420 h130 vDeckList")
    
    ; Start Game button
    gameGui.SetFont("s12 Bold", "Segoe UI")
    startBtn := gameGui.Add("Button", "x440 y135 w420 h50 vStartBtn", "🎲 ΞΕΚΙΝΑ ΠΑΙΧΝΙΔΙ")
    startBtn.OnEvent("Click", (*) => OnStartGame())
    
    ; === CENTER VS ===
    gameGui.SetFont("s20 Bold", "Segoe UI")
    gameGui.Add("Text", "x610 y200 w100 h50 Center cRed", "⚔️ VS")
    
    ; === PLAYER STATS (BOTTOM LEFT) ===
    gameGui.SetFont("s9", "Consolas")
    gameGui.Add("Text", "x20 y385 w400 h160 vPlayerStats cWhite Background0x0f3460", "")
    
    ; === AI STATS (BOTTOM RIGHT) ===
    gameGui.Add("Text", "x880 y385 w400 h160 vAIStats cWhite Background0x0f3460", "")
    
    ; === CENTER CONTROL SECTION ===
    
    ; STAT BUTTONS AREA
    gameGui.SetFont("s10 Bold", "Segoe UI")
    gameGui.Add("Text", "x440 y250 w420 cWhite Center", "⚡ Επίλεξε Στατιστικό (πάτα 1-9):")
    gameGui.Add("Text", "x440 y275 w420 h210 vStatButtonsArea Background0x0f3460", "")
    
    ; RESULT DISPLAY
    gameGui.SetFont("s11 Bold", "Segoe UI")
    gameGui.Add("Text", "x20 y550 w1260 h130 vResultText Center cYellow Background0x16213e", "Ξεκίνα το παιχνίδι!")
    
    ; Next Round button - Προσθήκη υπόδειξης για Space
    gameGui.SetFont("s12 Bold", "Segoe UI")
    nextBtn := gameGui.Add("Button", "x440 y495 w420 h50 vNextBtn Disabled", "➡️ Επόμενος Γύρος [SPACE]")
    nextBtn.OnEvent("Click", (*) => OnNextRound())
    
    ; === MENU BAR ===
    myMenuBar := MenuBar()
    
    gameMenu := Menu()
    gameMenu.Add("📊 Στατιστικά", (*) => ShowStats())
    gameMenu.Add("💾 Αποθήκευση", (*) => SaveGame())
    gameMenu.Add("📂 Φόρτωση", (*) => LoadGame())
    gameMenu.Add()
    gameMenu.Add("⚙️ Ρυθμίσεις", (*) => ShowSettings())
    gameMenu.Add()
    gameMenu.Add("🚪 Έξοδος", (*) => OnGuiClose())
    
    helpMenu := Menu()
    helpMenu.Add("📖 Οδηγίες", (*) => ShowHelp())
    helpMenu.Add("ℹ️ Σχετικά", (*) => ShowAbout())
    
    myMenuBar.Add("🎮 Παιχνίδι", gameMenu)
    myMenuBar.Add("❓ Βοήθεια", helpMenu)
    
    gameGui.MenuBar := myMenuBar
    
    ; === INFO FOOTER ===
    gameGui.SetFont("s9", "Segoe UI")
    gameGui.Add("Text", "x20 y690 w1260 Center c888888", "💡 Κανόνες: Επίλεξε deck → Ξεκίνα παιχνίδι → Πάτα ένα στατιστικό για μάχη! | ⌨️ SPACE: Επόμενος γύρος | ENTER: Start | ESC: Έξοδος")
    
    gameGui.Show("w1310 h730")
    return gameGui
}

; -------------------- EVENT HANDLERS --------------------

OnStartGame() {
    global currentDeck, allDecks, playerCards, aiCards, gameStarted, mainGui
    
    currentDeck := mainGui["DeckList"].Text
    
    if (currentDeck = "" || !allDecks.Has(currentDeck)) {
        MsgBox "Επίλεξε ένα Deck πρώτα!"
        PlaySound("error")
        return
    }
    
    ; Get all cards from deck
    allCards := []
    for name in allDecks[currentDeck] {
        allCards.Push(name)
    }
    
    if (allCards.Length < 2) {
        MsgBox "Χρειάζεσαι τουλάχιστον 2 κάρτες στο deck!"
        PlaySound("error")
        return
    }
    
    ; Shuffle cards (Fisher-Yates)
    Loop allCards.Length {
        i := allCards.Length - A_Index + 1
        j := Random(1, i)
        temp := allCards[i]
        allCards[i] := allCards[j]
        allCards[j] := temp
    }
    
    ; Deal cards - split between player and AI
    playerCards := []
    aiCards := []
    
    Loop allCards.Length {
        if (Mod(A_Index, 2) = 1)
            playerCards.Push(allCards[A_Index])
        else
            aiCards.Push(allCards[A_Index])
    }
    
    gameStarted := true
    
    ; Update GUI
    mainGui["CardCount"].Value := "Player: " . playerCards.Length . " | AI: " . aiCards.Length
    mainGui["PlayerCardCount"].Value := "Κάρτες: " . playerCards.Length
    mainGui["AICardCount"].Value := "Κάρτες: " . aiCards.Length
    mainGui["StartBtn"].Enabled := false
    mainGui["DeckList"].Enabled := false
    mainGui["ResultText"].Value := "Τράβα την επόμενη κάρτα!"
    
    PlaySound("activate")
    
    ; Draw first cards
    DrawCards()
}

DrawCards() {
    global playerCards, aiCards, currentPlayerCard, currentAICard, currentDeck, allDecks, CARDS_FOLDER, mainGui, statButtons, imageCache
    
    if (playerCards.Length = 0 || aiCards.Length = 0) {
        ShowGameOver()
        return
    }
    
    ; Draw top card from each deck
    currentPlayerCard := playerCards[1]
    currentAICard := aiCards[1]
    
    if (!allDecks[currentDeck].Has(currentPlayerCard) || 
        !allDecks[currentDeck].Has(currentAICard)) {
        MsgBox "Σφάλμα: Η κάρτα δεν υπάρχει στο deck!"
        PlaySound("error")
        return
    }

    ; Display Player Card
    playerData := allDecks[currentDeck][currentPlayerCard]
    playerImagePath := CARDS_FOLDER . currentDeck . "\" . currentPlayerCard . ".png"
    
    ; Use cached image or load new one
    if FileExist(playerImagePath) {
        if !imageCache.Has(playerImagePath) {
            imageCache[playerImagePath] := playerImagePath
        }
        mainGui["PlayerImage"].Value := "*w370 *h240 " . imageCache[playerImagePath]
    } else {
        mainGui["PlayerImage"].Value := ""
    }
    
    ; Show player stats
    playerStatsText := currentPlayerCard . "`n`n"
    excludedKeys := ["Image", "image", "NAME", "name", "Description", "description", "Type", "type"]
    for key, val in playerData {
        if !HasValue(excludedKeys, key)
            playerStatsText .= key . ": " . val . "`n"
    }
    mainGui["PlayerStats"].Value := playerStatsText
    
    ; Display AI Card
    aiData := allDecks[currentDeck][currentAICard]
    aiImagePath := CARDS_FOLDER . currentDeck . "\" . currentAICard . ".png"
    
    ; Use cached image or load new one
    if FileExist(aiImagePath) {
        if !imageCache.Has(aiImagePath) {
            imageCache[aiImagePath] := aiImagePath
        }
        mainGui["AIImage"].Value := "*w370 *h240 " . imageCache[aiImagePath]
    } else {
        mainGui["AIImage"].Value := ""
    }
    
    ; Εμφάνιση μόνο του ονόματος της κάρτας AI (όχι στατιστικά)
    mainGui["AIStats"].Value := currentAICard . "`n`n???"
    
    ; === ΔΗΜΙΟΥΡΓΙΑ STAT BUTTONS ===
    ; Proper cleanup with event handler removal
    for btn in statButtons {
        try {
            btn.Destroy()
        }
    }
    statButtons := []
    
    ; Συλλογή numeric stats
    statList := []
    excludedKeys := ["Image", "image", "NAME", "name", "Description", "description", "Type", "type"]
    
    for key in playerData {
        if HasValue(excludedKeys, key)
            continue
        
        val := playerData[key]
        if (ToNum(val) != 0 || val = "0")
            statList.Push(key)
    }
    
    ; Δημιουργία κουμπιών - 3 ανά σειρά στο κέντρο
    if (statList.Length > 0) {
        mainGui.SetFont("s8 Bold", "Segoe UI")
        
        buttonsPerRow := 3
        buttonWidth := 125
        buttonHeight := 55
        startX := 455
        startY := 290
        spacingX := 8
        spacingY := 8
        
        row := 0
        col := 0
        
for stat in statList {
    x := startX + (col * (buttonWidth + spacingX))
    y := startY + (row * (buttonHeight + spacingY))
    
    ; Check if this is a "lower wins" stat and display accordingly
    isLowerWins := SubStr(stat, 1, 1) = "!"
    displayName := isLowerWins ? "⬇️ " . SubStr(stat, 2) : "⚔️ " . stat
    
    ; Show number hotkey hint
    hotkey := (A_Index <= 9) ? " [" . A_Index . "]" : ""
    btn := mainGui.Add("Button", "x" . x . " y" . y . " w" . buttonWidth . " h" . buttonHeight, displayName . hotkey)
    btn.OnEvent("Click", OnStatButtonClick.Bind(stat))
    statButtons.Push(btn)
            
            col++
            if (col >= buttonsPerRow) {
                col := 0
                row++
            }
        }
    }
    
    mainGui["NextBtn"].Enabled := false
    mainGui["ResultText"].Value := "Πάτα ένα στατιστικό για μάχη!"
}

OnStatButtonClick(selectedStat, *) {
    global currentDeck, currentPlayerCard, currentAICard, allDecks, playerCards, aiCards, mainGui, statButtons, gameHistory
    
    ; Get card data
    playerData := allDecks[currentDeck][currentPlayerCard]
    aiData := allDecks[currentDeck][currentAICard]
    
    excludedKeys := ["Image", "image", "NAME", "name", "Description", "description", "Type", "type"]
    
    ; Show full stats
    playerStatsText := currentPlayerCard . "`n`n"
    for key, val in playerData {
        if !HasValue(excludedKeys, key)
            playerStatsText .= key . ": " . val . "`n"
    }
    mainGui["PlayerStats"].Value := playerStatsText
    
    aiStatsText := currentAICard . "`n`n"
    for key, val in aiData {
        if !HasValue(excludedKeys, key)
            aiStatsText .= key . ": " . val . "`n"
    }
    mainGui["AIStats"].Value := aiStatsText
    
    ; Compare values
playerVal := ToNum(playerData[selectedStat])
aiVal := ToNum(aiData[selectedStat])

; Check if this is a "lower wins" stat (starts with !)
isLowerWins := SubStr(selectedStat, 1, 1) = "!"
displayStat := isLowerWins ? SubStr(selectedStat, 2) : selectedStat

; Format numbers for display (remove unnecessary decimals)
playerDisplay := FormatNumber(playerVal)
aiDisplay := FormatNumber(aiVal)

; Determine winner - REVERSE logic if "lower wins"
roundResult := ""
playerWins := isLowerWins ? (playerVal < aiVal) : (playerVal > aiVal)
aiWins := isLowerWins ? (aiVal < playerVal) : (aiVal > playerVal)

comparisonSymbol := ""
if (playerWins) {
    comparisonSymbol := isLowerWins ? "<" : ">"
    roundResult := "win"
    playerCards.Push(playerCards.RemoveAt(1))
    playerCards.Push(aiCards.RemoveAt(1))
    result := "🎉 ΝΙΚΗΣΕΣ!`n`n" . displayStat . ":`n" 
    result .= currentPlayerCard . " (" . playerDisplay . ") " . comparisonSymbol . " "
    result .= currentAICard . " (" . aiDisplay . ")`n`n"
    result .= "Παίρνεις και τις 2 κάρτες!"
    PlaySound("win")
} else if (aiWins) {
    comparisonSymbol := isLowerWins ? ">" : "<"
    roundResult := "loss"
    aiCards.Push(aiCards.RemoveAt(1))
    aiCards.Push(playerCards.RemoveAt(1))
    result := "😞 ΕΧΑΣΕΣ!`n`n" . displayStat . ":`n" 
    result .= currentPlayerCard . " (" . playerDisplay . ") " . comparisonSymbol . " "
    result .= currentAICard . " (" . aiDisplay . ")`n`n"
    result .= "Το AI παίρνει και τις 2 κάρτες!"
    PlaySound("lose")
} else {
    roundResult := "draw"
    playerCards.Push(playerCards.RemoveAt(1))
    aiCards.Push(aiCards.RemoveAt(1))
    result := "🤝 ΙΣΟΠΑΛΙΑ!`n`n" . displayStat . ":`n" 
    result .= currentPlayerCard . " = " . currentAICard . " (" . playerDisplay . ")`n`n"
    result .= "Και οι δύο κρατάνε την κάρτα τους!"
    PlaySound("activate")
}
    
    ; Record to history
    gameHistory.Push(Map(
        "playerCard", currentPlayerCard,
        "aiCard", currentAICard,
        "stat", selectedStat,
        "playerVal", playerVal,
        "aiVal", aiVal,
        "result", roundResult
    ))
    
    mainGui["ResultText"].Value := result
    mainGui["CardCount"].Value := "Player: " . playerCards.Length . " | AI: " . aiCards.Length
    mainGui["PlayerCardCount"].Value := "Κάρτες: " . playerCards.Length
    mainGui["AICardCount"].Value := "Κάρτες: " . aiCards.Length
    
    ; Disable all stat buttons properly
    for btn in statButtons {
        try {
            btn.Enabled := false
        }
    }
    
    mainGui["NextBtn"].Enabled := true
    
    ; Auto-save if enabled
    if (settings["autoSave"])
        AutoSaveGame()
    
    if (playerCards.Length = 0 || aiCards.Length = 0) {
        ShowGameOver()
    }
}

OnNextRound() {
    global mainGui
    mainGui["ResultText"].Value := ""
    DrawCards()
}

ShowGameOver() {
    global playerCards, aiCards, mainGui, statButtons, totalGamesPlayed, totalWins, totalLosses, settings
    
    winner := ""
    gameResult := ""
    
    if (playerCards.Length > aiCards.Length) {
        winner := "🏆 ΝΙΚΗΣΕΣ! 🏆`n`nΜάζεψες όλες τις κάρτες!"
        gameResult := "win"
        totalWins++
        PlaySound("win")
    } else if (aiCards.Length > playerCards.Length) {
        winner := "💔 ΕΧΑΣΕΣ! 💔`n`nΤο AI μάζεψε όλες τις κάρτες!"
        gameResult := "loss"
        totalLosses++
        PlaySound("lose")
    } else {
        winner := "🤝 ΙΣΟΠΑΛΙΑ! 🤝"
        gameResult := "draw"
    }
    
    totalGamesPlayed++
    
    mainGui["ResultText"].Value := winner
    
    for btn in statButtons {
        try {
            btn.Enabled := false
        }
    }
    
    mainGui["NextBtn"].Enabled := false
    
    ; Calculate win rate
    winRate := totalGamesPlayed > 0 ? Round((totalWins / totalGamesPlayed) * 100, 1) : 0
    
    statsMsg := winner . "`n`n"
    statsMsg .= "Τελικό Σκορ:`nPlayer: " . playerCards.Length . " κάρτες`nAI: " . aiCards.Length . " κάρτες`n`n"
    statsMsg .= "═══════════════════`n"
    statsMsg .= "Συνολικά Παιχνίδια: " . totalGamesPlayed . "`n"
    statsMsg .= "Νίκες: " . totalWins . "`n"
    statsMsg .= "Ήττες: " . totalLosses . "`n"
    statsMsg .= "Win Rate: " . winRate . "%"
    
    MsgBox statsMsg
    
    ; Save statistics
    SaveSettings()
    
    ; Clear auto-save
    if (settings["autoSave"])
        ClearAutoSave()
    
    mainGui["StartBtn"].Enabled := true
    mainGui["StartBtn"].Text := "🔄 ΝΕΟ ΠΑΙΧΝΙΔΙ"
    mainGui["DeckList"].Enabled := true
}

; -------------------- UTILITY FUNCTIONS --------------------

HasValue(arr, val) {
    for item in arr {
        if (item = val)
            return true
    }
    return false
}

ToNum(val) {
    if (val = "")
        return 0
    v := StrReplace(val, ",", ".")
    v := RegExReplace(v, "[^0-9\.\-]", "")
    try
        return Float(v)
    catch
        return 0
}

; -------------------- INI LOADING --------------------

LoadDecks() {
    global DECKS_FOLDER
    decks := Map()
    
    if !DirExist(DECKS_FOLDER)
        return decks
    
    Loop Files, DECKS_FOLDER . "*.ini" {
        name := StrReplace(A_LoopFileName, ".ini")
        decks[name] := LoadSingleDeck(A_LoopFileFullPath)
    }
    
    return decks
}

LoadSingleDeck(path) {
    cards := Map()
    
    if !FileExist(path)
        return cards
    
    text := FileRead(path)
    current := ""
    
    for rawLine in StrSplit(text, "`n") {
        line := Trim(rawLine, " `r`t`n")
        
        if (line = "" || SubStr(line, 1, 1) = ";")
            continue
        
        if RegExMatch(line, "^\s*\[(.+)\]\s*$", &m) {
            current := m[1]
            cards[current] := Map()
            continue
        }
        
        if (current != "" && InStr(line, "=")) {
            p := InStr(line, "=")
            key := Trim(SubStr(line, 1, p-1))
            val := Trim(SubStr(line, p+1))
            cards[current][key] := val
        }
    }
    
    return cards
}

FormatNumber(num) {
    str := Format("{:g}", num)
    return str
}

; ====================================================================
; SETTINGS & SAVE/LOAD
; ====================================================================

OnGuiClose(*) {
    global settings, mainGui, gameStarted, DATA_FOLDER, imageCache 
    
    if (settings["confirmExit"] && gameStarted) {
        result := MsgBox("Θέλεις να τερματίσεις το παιχνίδι;`n`n(Το progress θα χαθεί αν δεν έχεις αποθηκεύσει)", "Έξοδος", "YesNo 32")
        if (result = "No")
            return
    }
    
    imageCache.Clear()
    SaveSettings()
    ExitApp
}

ValidateDecks() {
    global allDecks
    
    invalidDecks := []
    
    for deckName, cards in allDecks {
        if (cards.Count = 0) {
            invalidDecks.Push(deckName . " (άδειο deck)")
            continue
        }
        
        if (cards.Count < 2) {
            invalidDecks.Push(deckName . " (λιγότερες από 2 κάρτες)")
        }
        
        seen := Map()
        for cardName in cards {
            if (seen.Has(cardName)) {
                invalidDecks.Push(deckName . " (διπλότυπη κάρτα: " . cardName . ")")
                break
            }
            seen[cardName] := true
        }
    }
    
    if (invalidDecks.Length > 0) {
        msg := "⚠️ Προβλήματα με decks:`n`n"
        for issue in invalidDecks {
            msg .= "• " . issue . "`n"
        }
        MsgBox msg, "Προειδοποίηση", "48"
    }
}

LoadSettings() {
    global settings, totalGamesPlayed, totalWins, totalLosses, soundEnabled, DATA_FOLDER
    
    settingsFile := DATA_FOLDER . "Settings.ini"
    
    if !FileExist(settingsFile)
        return
    
    try {
        settings["soundEnabled"] := IniRead(settingsFile, "Settings", "SoundEnabled", "1") = "1"
        settings["animationsEnabled"] := IniRead(settingsFile, "Settings", "AnimationsEnabled", "1") = "1"
        settings["confirmExit"] := IniRead(settingsFile, "Settings", "ConfirmExit", "1") = "1"
        settings["autoSave"] := IniRead(settingsFile, "Settings", "AutoSave", "1") = "1"
        
        soundEnabled := settings["soundEnabled"]
        
        totalGamesPlayed := Integer(IniRead(settingsFile, "Stats", "TotalGames", "0"))
        totalWins := Integer(IniRead(settingsFile, "Stats", "Wins", "0"))
        totalLosses := Integer(IniRead(settingsFile, "Stats", "Losses", "0"))
    }
}

SaveSettings() {
    global settings, totalGamesPlayed, totalWins, totalLosses, DATA_FOLDER
    
    settingsFile := DATA_FOLDER . "Settings.ini"
    
    try {
        IniWrite(settings["soundEnabled"] ? "1" : "0", settingsFile, "Settings", "SoundEnabled")
        IniWrite(settings["animationsEnabled"] ? "1" : "0", settingsFile, "Settings", "AnimationsEnabled")
        IniWrite(settings["confirmExit"] ? "1" : "0", settingsFile, "Settings", "ConfirmExit")
        IniWrite(settings["autoSave"] ? "1" : "0", settingsFile, "Settings", "AutoSave")
        
        IniWrite(totalGamesPlayed, settingsFile, "Stats", "TotalGames")
        IniWrite(totalWins, settingsFile, "Stats", "Wins")
        IniWrite(totalLosses, settingsFile, "Stats", "Losses")
    }
}

ShowSettings() {
    global settings, mainGui, soundEnabled
    
    settingsGui := Gui("+Owner" . mainGui.Hwnd, "⚙️ Ρυθμίσεις")
    settingsGui.BackColor := "0x1a1a2e"
    
    settingsGui.SetFont("s11", "Segoe UI")
    
    settingsGui.Add("Text", "x20 y20 cWhite", "⚙️ Ρυθμίσεις Παιχνιδιού:")
    
    soundCheck := settingsGui.Add("Checkbox", "x40 y50 cWhite vSoundEnabled", "🔊 Ενεργοποίηση ήχων")
    soundCheck.Value := settings["soundEnabled"]
    
    animCheck := settingsGui.Add("Checkbox", "x40 y80 cWhite vAnimationsEnabled", "✨ Animations")
    animCheck.Value := settings["animationsEnabled"]
    
    confirmCheck := settingsGui.Add("Checkbox", "x40 y110 cWhite vConfirmExit", "⚠️ Επιβεβαίωση εξόδου")
    confirmCheck.Value := settings["confirmExit"]
    
    autoSaveCheck := settingsGui.Add("Checkbox", "x40 y140 cWhite vAutoSave", "💾 Auto-save παιχνιδιού")
    autoSaveCheck.Value := settings["autoSave"]
    
    settingsGui.SetFont("s10 Bold", "Segoe UI")
    saveBtn := settingsGui.Add("Button", "x40 y180 w120 h35", "💾 Αποθήκευση")
    saveBtn.OnEvent("Click", (*) => SaveSettingsFromGui(settingsGui))
    
    cancelBtn := settingsGui.Add("Button", "x170 y180 w120 h35", "❌ Ακύρωση")
    cancelBtn.OnEvent("Click", (*) => settingsGui.Destroy())
    
    settingsGui.Show("w330 h240")
}

SaveSettingsFromGui(gui) {
    global settings, soundEnabled
    
    settings["soundEnabled"] := gui["SoundEnabled"].Value
    settings["animationsEnabled"] := gui["AnimationsEnabled"].Value
    settings["confirmExit"] := gui["ConfirmExit"].Value
    settings["autoSave"] := gui["AutoSave"].Value
    
    soundEnabled := settings["soundEnabled"]
    
    SaveSettings()
    PlaySound("save")
    MsgBox "Οι ρυθμίσεις αποθηκεύτηκαν!", "Επιτυχία", "64"
    gui.Destroy()
}

ShowStats() {
    global totalGamesPlayed, totalWins, totalLosses, gameHistory, mainGui
    
    statsGui := Gui("+Owner" . mainGui.Hwnd, "📊 Στατιστικά")
    statsGui.BackColor := "0x1a1a2e"
    
    statsGui.SetFont("s11 Bold", "Segoe UI")
    statsGui.Add("Text", "x20 y20 cWhite", "📊 Στατιστικά Παιχνιδιού")
    
    statsGui.SetFont("s10", "Segoe UI")
    
    winRate := totalGamesPlayed > 0 ? Round((totalWins / totalGamesPlayed) * 100, 1) : 0
    lossRate := totalGamesPlayed > 0 ? Round((totalLosses / totalGamesPlayed) * 100, 1) : 0
    drawRate := totalGamesPlayed > 0 ? Round(((totalGamesPlayed - totalWins - totalLosses) / totalGamesPlayed) * 100, 1) : 0
    
    statsText := ""
    statsText .= "Συνολικά Παιχνίδια: " . totalGamesPlayed . "`n`n"
    statsText .= "═══════════════════`n"
    statsText .= "🏆 Νίκες: " . totalWins . " (" . winRate . "%)`n"
    statsText .= "😞 Ήττες: " . totalLosses . " (" . lossRate . "%)`n"
    statsText .= "🤝 Ισοπαλίες: " . (totalGamesPlayed - totalWins - totalLosses) . " (" . drawRate . "%)`n"
    statsText .= "═══════════════════`n`n"
    
    if (gameHistory.Length > 0) {
        statsText .= "Τρέχον Παιχνίδι - Γύροι: " . gameHistory.Length . "`n"
        
        wins := 0
        losses := 0
        draws := 0
        
        for round in gameHistory {
            if (round["result"] = "win")
                wins++
            else if (round["result"] = "loss")
                losses++
            else
                draws++
        }
        
        statsText .= "  Νίκες: " . wins . " | Ήττες: " . losses . " | Ισοπαλίες: " . draws
    }
    
    statsGui.Add("Text", "x20 y60 w400 h250 cWhite Background0x0f3460", statsText)
    
    statsGui.SetFont("s10 Bold", "Segoe UI")
    resetBtn := statsGui.Add("Button", "x20 y320 w190 h35", "🔄 Reset Στατιστικά")
    resetBtn.OnEvent("Click", (*) => ResetStats(statsGui))
    
    closeBtn := statsGui.Add("Button", "x220 y320 w200 h35", "✅ Κλείσιμο")
    closeBtn.OnEvent("Click", (*) => statsGui.Destroy())
    
    statsGui.Show("w440 h375")
}

ResetStats(gui) {
    global totalGamesPlayed, totalWins, totalLosses
    
    result := MsgBox("Θέλεις να διαγράψεις ΟΛΑ τα στατιστικά;", "Επιβεβαίωση", "YesNo 32")
    if (result = "Yes") {
        totalGamesPlayed := 0
        totalWins := 0
        totalLosses := 0
        SaveSettings()
        PlaySound("save")
        MsgBox "Τα στατιστικά διαγράφτηκαν!", "Επιτυχία", "64"
        gui.Destroy()
    }
}

SaveGame() {
    global currentDeck, playerCards, aiCards, gameHistory, gameStarted, DATA_FOLDER
    
    if (!gameStarted) {
        MsgBox "Δεν υπάρχει παιχνίδι σε εξέλιξη!", "Σφάλμα", "48"
        PlaySound("error")
        return
    }
    
    saveFile := DATA_FOLDER . "Saves.ini"
    
    try {
        if FileExist(saveFile)
            FileDelete(saveFile)
        
        IniWrite(currentDeck, saveFile, "Game", "CurrentDeck")
        IniWrite(playerCards.Length, saveFile, "Game", "PlayerCardCount")
        IniWrite(aiCards.Length, saveFile, "Game", "AICardCount")
        
        Loop playerCards.Length {
            IniWrite(playerCards[A_Index], saveFile, "PlayerCards", "Card" . A_Index)
        }
        
        Loop aiCards.Length {
            IniWrite(aiCards[A_Index], saveFile, "AICards", "Card" . A_Index)
        }
        
        IniWrite(gameHistory.Length, saveFile, "History", "Count")
        
        PlaySound("save")
        MsgBox "Το παιχνίδι αποθηκεύτηκε!", "Επιτυχία", "64"
    } catch as err {
        PlaySound("error")
        MsgBox "Σφάλμα κατά την αποθήκευση:`n" . err.Message, "Σφάλμα", "48"
    }
}

LoadGame() {
    global currentDeck, playerCards, aiCards, allDecks, mainGui, gameStarted, gameHistory, DATA_FOLDER
    
    saveFile := DATA_FOLDER . "Saves.ini"
    
    if !FileExist(saveFile) {
        MsgBox "Δεν βρέθηκε αποθηκευμένο παιχνίδι!", "Σφάλμα", "48"
        PlaySound("error")
        return
    }
    
    try {
        currentDeck := IniRead(saveFile, "Game", "CurrentDeck")
        
        if (!allDecks.Has(currentDeck)) {
            MsgBox "Το deck '" . currentDeck . "' δεν υπάρχει πια!", "Σφάλμα", "48"
            PlaySound("error")
            return
        }
        
        playerCount := Integer(IniRead(saveFile, "Game", "PlayerCardCount"))
        aiCount := Integer(IniRead(saveFile, "Game", "AICardCount"))
        
        playerCards := []
        Loop playerCount {
            card := IniRead(saveFile, "PlayerCards", "Card" . A_Index)
            playerCards.Push(card)
        }
        
        aiCards := []
        Loop aiCount {
            card := IniRead(saveFile, "AICards", "Card" . A_Index)
            aiCards.Push(card)
        }
        
        gameHistory := []
        gameStarted := true
        
        mainGui["DeckList"].Text := currentDeck
        mainGui["StartBtn"].Enabled := false
        mainGui["DeckList"].Enabled := false
        
        DrawCards()
        
        mainGui["CardCount"].Value := "Player: " . playerCards.Length . " | AI: " . aiCards.Length
        mainGui["PlayerCardCount"].Value := "Κάρτες: " . playerCards.Length
        mainGui["AICardCount"].Value := "Κάρτες: " . aiCards.Length
        
        PlaySound("activate")
        MsgBox "Το παιχνίδι φορτώθηκε!", "Επιτυχία", "64"
    } catch as err {
        PlaySound("error")
        MsgBox "Σφάλμα κατά τη φόρτωση:`n" . err.Message, "Σφάλμα", "48"
    }
}

AutoSaveGame() {
    global currentDeck, playerCards, aiCards, gameStarted, DATA_FOLDER
    
    if (!gameStarted)
        return
    
    saveFile := DATA_FOLDER . "Autosave.ini"
    
    try {
        if FileExist(saveFile)
            FileDelete(saveFile)
        
        IniWrite(currentDeck, saveFile, "Game", "CurrentDeck")
        IniWrite(playerCards.Length, saveFile, "Game", "PlayerCardCount")
        IniWrite(aiCards.Length, saveFile, "Game", "AICardCount")
        
        Loop playerCards.Length {
            IniWrite(playerCards[A_Index], saveFile, "PlayerCards", "Card" . A_Index)
        }
        
        Loop aiCards.Length {
            IniWrite(aiCards[A_Index], saveFile, "AICards", "Card" . A_Index)
        }
    }
}

TryLoadAutoSave() {
    global mainGui, DATA_FOLDER
    
    saveFile := DATA_FOLDER . "Autosave.ini"
    
    if !FileExist(saveFile)
        return
    
    result := MsgBox("Βρέθηκε autosave! Θέλεις να συνεχίσεις το παιχνίδι;", "Autosave", "YesNo 32")
    if (result = "Yes") {
        try {
            LoadGameFromFile(saveFile)
        } catch {
            PlaySound("error")
            MsgBox "Το autosave είναι κατεστραμμένο!", "Σφάλμα", "48"
        }
    } else {
        ClearAutoSave()
    }
}

LoadGameFromFile(saveFile) {
    global currentDeck, playerCards, aiCards, allDecks, mainGui, gameStarted, gameHistory
    
    currentDeck := IniRead(saveFile, "Game", "CurrentDeck")
    
    if (!allDecks.Has(currentDeck)) {
        throw Error("Deck not found")
    }
    
    playerCount := Integer(IniRead(saveFile, "Game", "PlayerCardCount"))
    aiCount := Integer(IniRead(saveFile, "Game", "AICardCount"))
    
    playerCards := []
    Loop playerCount {
        card := IniRead(saveFile, "PlayerCards", "Card" . A_Index)
        playerCards.Push(card)
    }
    
    aiCards := []
    Loop aiCount {
        card := IniRead(saveFile, "AICards", "Card" . A_Index)
        aiCards.Push(card)
    }
    
    gameHistory := []
    gameStarted := true
    
    mainGui["DeckList"].Text := currentDeck
    mainGui["StartBtn"].Enabled := false
    mainGui["DeckList"].Enabled := false
    
    DrawCards()
    
    mainGui["CardCount"].Value := "Player: " . playerCards.Length . " | AI: " . aiCards.Length
    mainGui["PlayerCardCount"].Value := "Κάρτες: " . playerCards.Length
    mainGui["AICardCount"].Value := "Κάρτες: " . aiCards.Length
}

ClearAutoSave() {
    global DATA_FOLDER
    saveFile := DATA_FOLDER . "Autosave.ini"
    if FileExist(saveFile)
        FileDelete(saveFile)
}

ShowHelp() {
    global mainGui
    
    helpGui := Gui("+Owner" . mainGui.Hwnd, "📖 Οδηγίες")
    helpGui.BackColor := "0x1a1a2e"
    
    helpGui.SetFont("s11 Bold", "Segoe UI")
    helpGui.Add("Text", "x20 y20 cWhite", "📖 Πώς να Παίξεις:")
    
    helpGui.SetFont("s10", "Segoe UI")
    helpText := ""
    helpText .= "1. Επίλεξε ένα Deck από τη λίστα`n"
    helpText .= "2. Πάτα 'ΞΕΚΙΝΑ ΠΑΙΧΝΙΔΙ'`n"
    helpText .= "3. Επίλεξε ένα στατιστικό για μάχη`n"
    helpText .= "4. Ο υψηλότερος αριθμός κερδίζει!`n"
    helpText .= "5. Ο νικητής παίρνει και τις 2 κάρτες`n"
    helpText .= "6. Συνέχισε μέχρι κάποιος να μείνει χωρίς κάρτες`n`n"
    helpText .= "⌨️ Συντομεύσεις Πληκτρολογίου:`n"
    helpText .= "━━━━━━━━━━━━━━━━━━━━━━━━━━`n"
    helpText .= "SPACE - Επόμενος γύρος`n"
    helpText .= "ENTER - Ξεκίνα παιχνίδι`n"
    helpText .= "1-9 - Επιλογή στατιστικού`n"
    helpText .= "Ctrl+S - Αποθήκευση`n"
    helpText .= "Ctrl+L - Φόρτωση`n"
    helpText .= "ESC - Έξοδος"
    
    helpGui.Add("Text", "x20 y60 w450 h320 cWhite Background0x0f3460", helpText)
    
    helpGui.SetFont("s10 Bold", "Segoe UI")
    closeBtn := helpGui.Add("Button", "x20 y390 w450 h35", "✅ Κλείσιμο")
    closeBtn.OnEvent("Click", (*) => helpGui.Destroy())
    
    helpGui.Show("w490 h445")
}

ShowAbout() {
    global mainGui
    
    aboutGui := Gui("+Owner" . mainGui.Hwnd, "ℹ️ Σχετικά")
    aboutGui.BackColor := "0x1a1a2e"
    
    aboutGui.SetFont("s14 Bold", "Segoe UI")
    aboutGui.Add("Text", "x20 y20 cWhite Center w360", "🎴 Card Clash")
    
    aboutGui.SetFont("s10", "Segoe UI")
    aboutText := ""
    aboutText .= "Έκδοση: 1.0`n"
    aboutText .= "━━━━━━━━━━━━━━━━━━━━━━━━`n`n"
    aboutText .= "Συγγραφέας: Tasos`n"
    aboutText .= "Έτος: 2025`n"
    aboutText .= "MIT License`n`n"
    aboutText .= "Copyright (c) 2025 Tasos`n`n"
    aboutText .= "━━━━━━━━━━━━━━━━━━━━━━━━`n"

    
    aboutGui.Add("Text", "x20 y60 w360 h280 cWhite Center Background0x0f3460", aboutText)
    
    aboutGui.SetFont("s10 Bold", "Segoe UI")
    closeBtn := aboutGui.Add("Button", "x20 y350 w360 h35", "✅ Κλείσιμο")
    closeBtn.OnEvent("Click", (*) => aboutGui.Destroy())
    
    aboutGui.Show("w400 h405")
}

; ====================================================================
; END OF SCRIPT
; ====================================================================
;Chord.ahk by Paul Pliska (ManaUser) - Version 2.0

#SingleInstance Force
#NoEnv
SendMode Input

; Chording can mean a few different things but what I mean by it here
; is pressing two buttons at the same time and getting a different
; result than when you press them alone. This isn't the same as just
; holding one button and pressing the other one, you have to press
; them down together.

; With that out of the way, let's take a look at MakeChord:

;       MakeChord(Note1, Note2, Result[, Delay, Context])

; Note1 and Note2 are the two keys or mouse buttons that combine
; to make the chord. Due to the delay, I don't recommend keys that
; are frequently used in typing, like letters or shift, unless you
; limit it to a specific application. (More on that in a moment.)

; Result can be one of three things:

;    1. A label. This will be executed when the chord is pressed.
;       When the chord is released, another label with the same
;       name followed by "_Up" will be executed, if it exists.
;    2. A single key or mouse button. This will be "pressed" for
;       as long as the chord is held.
;    3. A string for the Send command. This will be sent once
;       when the chord is pressed.

; The script will attempt to interpret Result as one of those three
; things in that order, so a string for Send is the default.

; Delay, if present, is how close together the key presses have to
; happen to count as a chord, in milliseconds. When you press one of the
; chord keys, its normal function will be delayed by that much to give
; you a chance to make the chord. A longer delay makes it easier to
; perform a chord, but if its too long, the delay will be noticeable,
; which is annoying.

; Context, if present, controls which applications the chord applies to.
; This works exactly the same as the Title parameter of #IfWinActive.
; If you omit the Context parameter, the chord applies everywhere. You
; can create a chord in multiple contexts, with different results. If
; more than one apply, the one that was created first will activate,
; except the "everywhere" context, which has the lowest priority.
; If you want to specify a context, but use the defelt delay, use zero
; for the delay.

; You can also change the delay using another function: SetKeyDelay()

;       SetKeyDelay(20, "LButton RButton MButton XButton1 XButton2")
;       SetKeyDelay(75)

; The first example sets the delay for all mouse buttons to 20 ms.
; The second sets the default delay to 75, it will be 50 otherwise.

; Some Examples:

MakeChord("LButton", "RButton", "MButton", 30)
MakeChord("RShift", "Enter", "NumpadEnter", 0, "ahk_class Photoshop")
MakeChord("F11", "F12", "UserName{tab}Password{enter}")
MakeChord("XButton1", "XButton2", "CtrlDrag")
MakeChord("#1", "#2", "You pressed the Windows Key plus 1 and 2.")

Return

CtrlDrag:
Send {Ctrl Down}{LButton Down}
Return

CtrlDrag_Up:
Send {LButton Up}{Ctrl Up}
Return

; You can delete everything above the line and either put in
; you one code here, or #Include this in your script and use
; MakeChord from there.

;-------------------------------------------------------------

;Chord.ahk by Paul Pliska (ManaUser) - Version 2.0
MakeChord(Note1, Note2, Result, Delay = 0, Context = "")
{
   Local NewChord
   If Context
      HotKey IfWinActive, %Context%
   If Note1 In Ctrl,Alt,Shift
   {
      MakeChord("L" Note1, Note2, Result)
      MakeChord("R" Note1, Note2, Result)
      If Context
         HotKey IfWinActive
      Return
   }
   If Note2 In Ctrl,Alt,Shift
   {
      MakeChord(Note1, "L" Note2, Result)
      MakeChord(Note1, "R" Note2, Result)
      If Context
         HotKey IfWinActive
      Return
   }
   KeyWait % StripMods(Note1)
   KeyWait % StripMods(Note2)
   HotKey *$%Note1%, NoteDown
   HotKey *$%Note2%, NoteDown
   HotKey *$%Note1% Up, NoteUp
   HotKey *$%Note2% Up, NoteUp
   If Context
      HotKey IfWinActive
   NewChord := GetChordName(EscapeNote(Note1), EscapeNote(Note2))
   If NOT InStr(ChordList, NewChord)
   {
      If (ChordList != "")
         ChordList .= "|"
      ChordList .= NewChord
   }
   If NOT RegExMatch(Result, "^[a-zA-Z]\|")
   {
      If IsLabel(Result)
         Result := "L|" Result
      Else If (GetKeyState(Result) != "")
         Result := "K|" Result
      Else
         Result := "S|" Result
   }
   If (ConText = "")
      %NewChord% := Result
   else
   {
      Loop
      {
         Existing := %NewChord%_%A_Index%_Context
         If (Existing = "" OR Existing = Context)
         {
            %NewChord%_%A_Index%_Context := Context
            %NewChord%_%A_Index% := Result
            Break
         }
      }
   }
   If (Delay > 0)
      SetKeyDelay(Delay, Note1 " " Note2)
   If (DefaultKeyDelay = "")
      DefaultKeyDelay := 50
}

SetKeyDelay(Delay, Keys = "")
{
   Global
   If (Keys = "")
      DefaultKeyDelay := Delay
   Loop Parse, Keys, %A_Space%
   {
      Escaped := EscapeNote(A_LoopField)
      %Escaped%_Delay := Delay
   }
}

NoteDown:
   Critical
   ThisKey := GetThisKey()
   If ChordUsingNote(ThisKey)
      Return
   If (LastNote != "")
   {
      ChordName := GetChordName(LastNote, ThisKey)
      If (NoCreate(ChordName) OR NoCreate(ChordName "_1"))
      {
         Loop
         {
            ThisContext := %ChordName%_%A_Index%_Context
            If (ThisContext = "")
            {
               ThisContextNum = x
               MatchingChord := %ChordName%
               Break
            }
            If WinActive(ThisContext)
            {
               ThisContextNum := A_Index
               MatchingChord := %ChordName%_%A_Index%
               Break
            }
         }
         RegExMatch(MatchingChord, "^([a-zA-Z])\|(.*)$", ChordPart)
         If (ChordPart1 = "L")
            SetTimer %ChordPart2%, -1
         If (ChordPart1 = "S")
            Send %ChordPart2%
         If (ChordPart1 = "K")
            Send % "{blind}{" Ctrl2AltFix(ChordName, ChordPart2) " DownTemp}"
         %ChordName%_Down := ThisContextNum
         SetTimer PressIt, Off
         LastNote =

         Return
      }
      GoSub PressIt
   }
   LastNote := ThisKey
   If (NoCreate(ThisKey "_Delay"))
      SetTimer PressIt, % %ThisKey%_Delay
   else
      SetTimer PressIt, % DefaultKeyDelay
Return

NoteUp:
   Critical
   ThisKey := GetThisKey()
   ChordName := ChordUsingNote(ThisKey)
   If ChordName
   {
      ThisContext := %ChordName%_Down
      If (ThisContext)
      {
         If (ThisContext = "x")
            MatchingChord := %ChordName%
         Else
            MatchingChord := %ChordName%_%ThisContext%

         If (ChordPart1 = "L" AND IsLabel(ChordPart2 "_Up"))
            SetTimer %ChordPart2%_Up, -1
         If (ChordPart1 = "K")
            Send % "{blind}{" ChordPart2 " Up}"
         %ChordName%_Down =
      }
   }
   If (LastNote != "")
      GoSub PressIt
   If GetKeyState(UnescapeNote(ThisKey, 1))
      Send % "{blind}{" UnescapeNote(ThisKey, 1) " Up}"
Return

PressIt:
   Critical
   Send % "{blind}{" UnescapeNote(LastNote, 1) " Down}"
   SetTimer PressIt, Off
   LastNote =
Return

GetThisKey()
{
   Return EscapeNote(RegExReplace(A_ThisHotkey, "i)[~*$]*(\S+)( Up)?", "$1"))
}

GetChordName(Note1, Note2)
{
   If (Note2 < Note1)
      Return Note2 "_" Note1
   Else
      Return Note1 "_" Note2
}

StripMods(Note)
{
   Return RegExReplace(Note, "^[+^!#]*")
}

EscapeNote(Note)
{
   Scaw = +^!#scaw
   Symbols = !EX@AT#NM$DS`%PC^CT&ND*AS(OP)CP``BT~TL_US+PL-MN=EQ|VB\BK/FW?QM[OS]CS{OC}CC:CN;SC"DQ'SQ,CM.PD<LT>GT
   ModKeys := RegExReplace(Note, "(([#^!+])(?=.)|.+$)", "$2")
   MainKey := SubStr(Note, StrLen(ModKeys) + 1)
   Loop 4
      If InStr(ModKeys, SubStr(Scaw, A_Index, 1))
         Escaped .= SubStr(Scaw, A_Index + 4, 1)
   Match := InStr(Symbols, MainKey, 1)
   If Mod(Match, 3) = 1
      MainKey := SubStr(Symbols, Match + 1, 2)
   Escaped .= "$" MainKey
   Return Escaped
}

UnescapeNote(Note, StripMods = 0)
{
   Scaw = +^!#scaw
   Symbols = !EX@AT#NM$DS`%PC^CT&ND*AS(OP)CP``BT~TL_US+PL-MN=EQ|VB\BK/FW?QM[OS]CS{OC}CC:CN;SC"DQ'SQ,CM.PD<LT>GT
   StringSplit Keys, Note, $
   Match := InStr(Symbols, Keys2, 1)
   If Mod(Match, 3) = 2
      Keys2 := SubStr(Symbols, Match - 1, 1)
   If NOT StripMods
   {
      Loop 4
         If InStr(Keys1, SubStr(Scaw, A_Index + 4, 1))
            Unescaped .= SubStr(Scaw, A_Index, 1)
   }
   Unescaped .= Keys2
   Return Unescaped
}

ChordUsingNote(Note)
{
   Global
   Loop Parse, ChordList, |
   {
      If SubStr("_" A_LoopField "_", "_" Note "_") AND %A_LoopField%_Down
         Return A_LoopField
   }
   Return ""
}

Ctrl2AltFix(Chord, Key)
{
   Local Fix
   Fix =
   If SubStr(Key, "Alt")
   {
      If InStr(Chord, "LCtrl")
         Fix .= "LCtrl Up}{"
      If InStr(Chord, "RCtrl")
         Fix .= "RCtrl Up}{"
   }
   Fix .= Key
   Return Fix
}

NoCreate(TestVar)
{
   Global
   If %TestVar% =
      Return ""
   Else
      Return (%TestVar%)
}
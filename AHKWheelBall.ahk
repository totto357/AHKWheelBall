;; AHKWheelBall.ahk
/*
AHKWheelBall
Created by totto357 (totto357 at gmail dot com)
v1.0
2018/06/18

# AHKWheelBall's Comments

This script is reproduction of WheelBall with AutoHotKey.
MouseWheelEmulator is used as a base script.

## Changes

The changes from MouseWheelEmulator are as follows.

- The amount of movement of the mouse cursor and the amount of movement of the scroll are linked.
- To decide which of vertical scrolling and horizontal scrolling is to be used, select the one with the larger amount of movement.
- If the mouse cursor does not move while holding down the right click, fire a normal right click.

Other movements are based on MouseWheelEmulator.

## 日本語の記事

Qiitaに解説記事を書きました。

https://qiita.com/totto357/items/87f448779a06eb449d12

# MouseWheelEmulator's Comments

The original comments of MouseWheelEmulator are below.

## Summary
This script combines the functionality of TheGood's AHKHID and ManaUser's MakeChord libraries to provide emulated middle-click and scroll wheel abilities to users of mice, trackpads and trackballs without a scroll wheel.

## Features
- Allows middle clicks and mouse wheel scrolling to be performed on hardware without a physical scroll wheel
- Freezes the mouse cursor in place during virtual mouse wheel scrolling
- Sends scroll wheel messages to window or control under cursor, not just the active window (in supported applications; see note about different scroll modes below)

## Installation
1. Download the AHKHID and MakeChord libraries and place the AHKHID.ahk and MakeChord.ahk files in the same folder as this script.

AHKHID: http://www.autohotkey.com/forum/topic41397.html
MakeChord (just the second half that starts with the MakeChord() function): http://www.autohotkey.com/forum/topic44399.html

2. Run this script.

## Usage

By default there are two ways to activate a middle click or scroll the virtual mouse wheel:

### To perform middle-click
Click the left and right mouse buttons simultaneously (often referred to as "chording").
-or-
Hold Alt and right click.

### To scroll the virtual mouse wheel
Click and hold the left and right mouse buttons simultaneously and move the mouse in the direction you wish to scroll.
-or-
Hold Alt, click and hold the right mouse button, and move the mouse in the direction you wish to scroll.

## Note
If you need to terminate the script you can use Ctrl-Alt-Break.

### About the different scroll modes

There are several different ways that any given program may implement mouse scrolling.
AHK has built-in WheelUp and WheelDown functions, but not all applications respond to them.
Some applications respond to WM_VSCROLL/WM_HSCROLL messages, while others respond to WM_MOUSEWHEEL/WM_HSCROLL messages.
If you find an application you use doesn't work with this script out of the box, you can probably fix it yourself by adding that application's process name to the conditional statements in the GetScrollMode() function.
The default scroll mode, 0, is AHK's built-in WheelUp and WheelDown commands.
This does not support horizontal scrolling or scrolling the window or control under the cursor, while the other two modes do.
Some applications respond to more than one scroll mode, so you can try them all and decide which works best for you.
Finally, to further muddy the waters, some applications have frames within them that respond to scroll messages differently to the rest of the application.
An example of this is the AHK help file, which uses the Internet Explorer_Server1 control to display HTML pages in one frame, and standard Windows controls to display the table of contents, index, etc. in another frame, and each responds to different scroll modes. I have tried to account for this in the GetScrollMode() function as well, but there may be other implementations I have not covered. You can use AHK's Window Spy to determine the name of the non-conforming control and write an exception for it, similar to the examples I have provided.

*/

;; Configuration

mouse_Threshold = 1 ; the number of pixels the mouse must move for a scroll tick to occur
MakeChord("LButton", "RButton", "scrollChord", 20) ; Chord to activate middle click or scrolling. See MakeChord.ahk for instructions
scroll_Hotkey = RButton ; Hotkey to activate middle click or scrolling

;; Added with AHKWheelBall

mouse_delta = 3 ; Weighting of scroll amount
sleep_interval = 30 ; Sleep time at InputMsg event

;; End Configuration

#SingleInstance Force
#NoEnv
#Persistent
SendMode Input
Process, Priority, , Realtime

#Include %A_ScriptDir%\AHKHID.ahk

;Create GUI to receive messages
Gui, +LastFound
hGui := WinExist()

;Intercept WM_INPUT messages
OnMessage(0x00FF, "InputMsg")

SetDefaultMouseSpeed, 0
CoordMode, Mouse, Screen

HotKey, %scroll_Hotkey%, scrollChord
HotKey, %scroll_Hotkey% Up, scrollChord_Up
return

scrollChord:
  mouse_Moved = f
  BlockInput, MouseMove
  MouseGetPos, m_x, m_y, winID, control
  WinGet, procName, ProcessName, ahk_id %winID%
  hw_m_target := DllCall( "WindowFromPoint", "int", m_x, "int", m_y )
  AHKHID_Register(1, 2, hGui, RIDEV_INPUTSINK)
return

scrollChord_Up:
  ToolTip
  BlockInput, MouseMoveOff
  AHKHID_Register(1, 2, 0, RIDEV_REMOVE)
  if mouse_Moved = f
    MouseClick, RIGHT
return

InputMsg(wParam, lParam) {
  local x, y
  Critical

  x := AHKHID_GetInputInfo(lParam, II_MSE_LASTX)
  y := AHKHID_GetInputInfo(lParam, II_MSE_LASTY)

  if ((Abs(x) > 0.0) or (Abs(y) > 0.0))
    mouse_Moved = t

  if Abs(x) > Abs(y)
  {
    if x > %mouse_Threshold%
      loop, % Abs(1 + x//mouse_delta)
        ScrollRight()
    else if x < -%mouse_Threshold%
      loop, % Abs(-1 + x//mouse_delta)
        ScrollLeft()
  }
  else
  {
    if y > %mouse_Threshold%
      loop, % Abs(1 + y//mouse_delta)
        ScrollDown()
    else if y < -%mouse_Threshold%
      loop, % Abs(-1 + y//mouse_delta)
        ScrollUp()
  }

  ; ToolTip, % "dX = " . x . " " . "dY = " . dy . a_tab . winID . a_tab . control . a_tab . procName . a_tab . hw_m_target . a_tab . scrollMode
  ;; Uncomment the above line for handy debug info shown while scrolling
  Sleep, % sleep_interval
}

ScrollDown() {
  global
  Click, WheelDown
}

ScrollUp() {
  global
  Click, WheelUp
}

ScrollRight() {
  global
  Send, +{ Click, WheelDown }
}

ScrollLeft() {
  global
  Send, +{ Click, WheelUp }
}

^!CtrlBreak::ExitApp

#Include %A_ScriptDir%\MakeChord.ahk

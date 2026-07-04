# Hotkeys EA (MetaTrader 5)

Numpad quick-execution EA. Attach to a chart, keep NumLock ON, and trade the
active symbol with one keypress.

## Install

1. In MT5: File > Open Data Folder.
2. Copy the repo `MQL5/` contents into the terminal `MQL5/` folder:
   - `Experts/HotkeysEA/HotkeysEA.mq5`
   - `Include/HotkeysEA/*.mqh`
   - `Scripts/HotkeysEA/HotkeysEA_Tests.mq5`
3. In MetaEditor, compile `HotkeysEA.mq5` (F7).
4. Enable AutoTrading, drag the EA onto a chart, allow algo trading.

## Hotkeys (NumLock ON)

| Key | Action |
|-----|--------|
| 1 | Buy market |
| 2 | Sell market |
| 3 | Close profit only |
| 4 | Close last position |
| 5 | Close half (last position) |
| 6 | Reverse |
| 7 | Move SL to breakeven |
| 8 | Toggle trailing stop |
| 9 | Toggle SL/TP on entry |
| 0 | Reset lot to default |
| + | Increase lot |
| - | Decrease lot |
| * | Buy pending |
| / | Sell pending |
| . (Del) | Delete pending orders |
| Enter | Close all (2x to confirm) |

## Inputs

See `MQL5/Include/HotkeysEA/Config.mqh` for all parameters (lot, SL/TP points,
trailing, pending type/distance, magic number, panel corner, confirm toggle).

## Tests

Run `Scripts/HotkeysEA/HotkeysEA_Tests` in MT5 to execute pure-logic unit tests
(keycode mapping, lot clamping, SL/TP/pending price math). Expected:
`31 passed, 0 failed`.

## Scope & Safety

All actions are limited to the active chart symbol and the configured magic
number, so manual trades and other EAs are never affected.

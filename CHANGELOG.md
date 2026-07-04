# Changelog

Semua perubahan penting proyek **Hotkeys EA** didokumentasikan di file ini.

Format mengikuti [Keep a Changelog](https://keepachangelog.com/id/1.1.0/),
dan proyek ini memakai [Semantic Versioning](https://semver.org/lang/id/).

## [1.01.0] - 2026-07-04

Release pertama — Hotkeys EA untuk MetaTrader 5.

### Ditambahkan

- **EA HotkeysEA v1.01** — eksekusi trading cepat via numpad (16 hotkey)
- **Entry:** Buy (`1`), Sell (`2`), Buy/Sell pending (`*` / `/`)
- **Lot:** tambah/kurangi (`+` / `-`), reset (`0`), cap maksimum
- **Manajemen posisi:** close profit (`3`), close last (`4`), close half (`5`), reverse (`6`), breakeven (`7`), close all (`Enter` dengan konfirmasi 2×)
- **Toggle:** trailing stop (`8`), SL/TP on entry (`9`)
- **Pending:** delete all (`Del/.`)
- **Panel on-chart** — lot, SL/TP, trailing, floating P/L, jumlah posisi, status trade
- **Filter magic number + symbol** — EA tidak sentuh posisi manual/EA lain
- **KeyPoller** — deteksi keyboard via WinAPI `GetAsyncKeyState` (NumLock ON/OFF)
- **Spread-aware SL/TP** — jarak stop minimum mengikuti spread broker
- **Unit test harness** — `HotkeysEA_Tests.mq5` (31 assertion logika murni)
- **Dokumentasi:**
  - `README.md` — overview & quick start
  - `docs/PENGGUNAAN.md` — panduan trader
  - `docs/COMPILE.md` — panduan compile developer

### Diperbaiki

- Input EA dipindah ke `HotkeysEA.mq5` (aturan MQL5, fix error compile)
- Include path diseragamkan (`#include <HotkeysEA/...>`)
- Keyboard polling: ganti `TERMINAL_KEYSTATE` (MQL4) → `GetAsyncKeyState` (WinAPI)
- Order `invalid stops` pada symbol spread lebar (mis. BTCUSD) — normalisasi + fallback buka tanpa SL/TP

### Persyaratan

- Windows, MetaTrader 5, keyboard numpad
- **Allow DLL imports** + **Allow Algo Trading** saat attach EA

### Modul

| File | Fungsi |
|------|--------|
| `Config.mqh` | Enum, keycode, konstanta |
| `KeyMap.mqh` | Mapping numpad → aksi |
| `KeyPoller.mqh` | Polling keyboard |
| `MathUtils.mqh` | Clamp lot, kalkulasi SL/TP/pending |
| `LotManager.mqh` | State lot + normalisasi broker |
| `PositionUtils.mqh` | Filter posisi symbol + magic |
| `TradeExecutor.mqh` | Eksekusi order via `CTrade` |
| `TrailingManager.mqh` | Trailing stop on tick |
| `Panel.mqh` | Label status on-chart |

---

## [Unreleased]

_Perubahan di branch `development` yang belum masuk release._

[1.01.0]: https://github.com/ardani17/hotkeys-ea/releases/tag/v1.01.0

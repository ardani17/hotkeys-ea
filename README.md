# Hotkeys EA — MetaTrader 5

Expert Advisor untuk **eksekusi trading cepat via numpad** pada chart MT5. Attach ke chart, tekan angka di keyboard numpad — buy, sell, atur lot, close posisi, tanpa klik mouse.

[![Platform](https://img.shields.io/badge/platform-MetaTrader%205-blue)](https://www.metatrader5.com/)
[![Language](https://img.shields.io/badge/language-MQL5-green)](https://www.mql5.com/)
[![OS](https://img.shields.io/badge/OS-Windows-lightgrey)](https://www.microsoft.com/windows)

---

## Fitur

- **16 hotkey numpad** — buy/sell, lot sizing, close variants, reverse, breakeven, trailing, pending orders
- **NumLock ON atau OFF** — mapping otomatis untuk kedua mode
- **Panel on-chart** — lot, SL/TP, trailing, P/L, status trading
- **Magic number filter** — tidak mengganggu trade manual / EA lain
- **Konfirmasi Close All** — Enter 2× dalam 3 detik (opsional)
- **Spread-aware SL/TP** — jarak stop disesuaikan spread broker

---

## Dokumentasi

| Dokumen | Untuk siapa | Isi |
|---------|-------------|-----|
| **[docs/PENGGUNAAN.md](docs/PENGGUNAAN.md)** | Trader / pengguna EA | Install `.ex5`, attach, hotkey, inputs, troubleshooting |
| **[docs/COMPILE.md](docs/COMPILE.md)** | Developer | Struktur source, compile MetaEditor, unit test, error compile |
| **[CHANGELOG.md](CHANGELOG.md)** | Semua | Riwayat versi & perubahan |

**Baru mulai?** → [PENGGUNAAN.md](docs/PENGGUNAAN.md)  
**Compile dari source?** → [COMPILE.md](docs/COMPILE.md)

---

## Quick start (pengguna)

1. Salin `HotkeysEA.ex5` ke `MQL5/Experts/HotkeysEA/` *(atau compile dari source — lihat COMPILE.md)*
2. Nyalakan **Algo Trading** di MT5
3. Drag **HotkeysEA** ke chart
4. Centang **Allow Algo Trading** + **Allow DLL imports**
5. Tekan numpad **`1`** = buy, **`2`** = sell, **`+`/`-`** = lot

Detail lengkap: **[docs/PENGGUNAAN.md](docs/PENGGUNAAN.md)**

---

## Hotkey ringkas

| Key | Aksi | Key | Aksi |
|-----|------|-----|------|
| 1 | Buy | 0 | Reset lot |
| 2 | Sell | + / - | Lot ± |
| 3 | Close profit | * / / | Pending buy/sell |
| 4 | Close last | . | Delete pending |
| 5 | Close half | Enter | Close all |
| 6 | Reverse | 8 | Toggle trailing |
| 7 | Breakeven | 9 | Toggle SL/TP |

---

## Struktur repository

```
hotkeys-ea/
├── README.md
├── docs/
│   ├── COMPILE.md           ← panduan compile (developer)
│   └── PENGGUNAAN.md        ← panduan pakai EA (user)
└── MQL5/
    ├── Experts/HotkeysEA/HotkeysEA.mq5
    ├── Include/HotkeysEA/*.mqh
    └── Scripts/HotkeysEA/HotkeysEA_Tests.mq5
```

---

## Branch

| Branch | Tujuan |
|--------|--------|
| `main` | Release stabil |
| `development` | Integrasi & testing |
| `feature/*` | Fitur / fix per branch |

---

## Persyaratan

- Windows + MetaTrader 5
- Keyboard numpad
- **Allow DLL imports** (keyboard polling via WinAPI)
- **Allow Algo Trading**

---

## Lisensi & disclaimer

Proyek open source untuk keperluan edukasi dan trading pribadi. **Trading forex/crypto berisiko.** Uji di akun demo sebelum live. Penulis tidak bertanggung jawab atas kerugian trading.

---

## Kontribusi & issue

- Issues: [github.com/ardani17/hotkeys-ea/issues](https://github.com/ardani17/hotkeys-ea/issues)
- Spec: [#1 Design Spec](https://github.com/ardani17/hotkeys-ea/issues/1)
- Plan: [#12 Implementation Plan](https://github.com/ardani17/hotkeys-ea/issues/12)

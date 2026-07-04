# Hotkeys EA — MetaTrader 5

Expert Advisor untuk **eksekusi trading cepat via numpad** pada chart MT5. Attach ke chart, tekan angka di keyboard numpad — buy, sell, atur lot, close posisi, tanpa klik mouse.

[![Release](https://img.shields.io/github/v/release/ardani17/hotkeys-ea?label=release)](https://github.com/ardani17/hotkeys-ea/releases/latest)
[![Platform](https://img.shields.io/badge/platform-MetaTrader%205-blue)](https://www.metatrader5.com/)
[![Language](https://img.shields.io/badge/language-MQL5-green)](https://www.mql5.com/)
[![OS](https://img.shields.io/badge/OS-Windows-lightgrey)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/license-MIT-yellow)](LICENSE)

> **Trade faster, click less.** 16 numpad hotkeys · on-chart panel · spread-aware stops · magic-number scope

---

## Mengapa Hotkeys EA?

Scalping dan manual trading di MT5 sering terhambat klik mouse dan dialog order. Hotkeys EA memberi kontrol penuh dari keyboard numpad — cocok untuk trader yang ingin **eksekusi instan** tanpa mengubah workflow chart.

| | Hotkeys EA | Trading manual MT5 |
|---|-----------|-------------------|
| Eksekusi order | 1 tombol numpad | Klik + konfirmasi |
| Atur lot | `+` / `-` langsung | Edit field order |
| Close / BE / trailing | Hotkey dedicated | Menu context / modify |
| Scope posisi | Magic number + symbol | Semua posisi chart |

---

## Download

**[⬇ Latest release (v1.01.0)](https://github.com/ardani17/hotkeys-ea/releases/latest)** — unduh `.ex5` atau compile dari source.

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
| `main` | Release stabil (default) |
| `development` | Integrasi fitur & testing |

---

## Persyaratan

- Windows + MetaTrader 5
- Keyboard numpad
- **Allow DLL imports** (keyboard polling via WinAPI)
- **Allow Algo Trading**

---

## Lisensi & disclaimer

Proyek ini dilisensikan di bawah [MIT License](LICENSE) — bebas dipakai, dimodifikasi, dan didistribusikan.

**Trading forex/crypto berisiko.** Uji di akun demo sebelum live. Penulis tidak bertanggung jawab atas kerugian trading.

---

## Kontribusi & issue

Punya ide fitur, bug report, atau ingin berkontribusi? Buka [Issues](https://github.com/ardani17/hotkeys-ea/issues) atau fork repo ini.

| | |
|---|---|
| 🐛 Bug / request | [Issues](https://github.com/ardani17/hotkeys-ea/issues/new) |
| 📋 Design spec | [#1](https://github.com/ardani17/hotkeys-ea/issues/1) |
| 🗺 Implementation plan | [#12](https://github.com/ardani17/hotkeys-ea/issues/12) |
| ⭐ Suka project ini? | [Star repo](https://github.com/ardani17/hotkeys-ea) |

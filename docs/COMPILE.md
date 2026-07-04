# Panduan Compile — Hotkeys EA (MT5)

Dokumen ini untuk **developer / maintainer** yang ingin membangun EA dari source code.
Untuk cara **menggunakan EA** setelah ter-compile, lihat [PENGGUNAAN.md](PENGGUNAAN.md).

---

## Prasyarat

| Item | Keterangan |
|------|------------|
| **MetaTrader 5** | Terminal MT5 terinstall (build 3000+) |
| **MetaEditor** | Biasanya terbundel dengan MT5 (F4 dari terminal) |
| **OS** | Windows (EA memakai WinAPI `GetAsyncKeyState` via `user32.dll`) |
| **Repo** | Clone atau copy folder proyek ini |

---

## Struktur file source

```
MQL5/
  Experts/HotkeysEA/
    HotkeysEA.mq5              ← entry point EA (compile file ini)
  Include/HotkeysEA/
    Config.mqh                 ← enum, keycode, konstanta
    KeyMap.mqh                 ← mapping numpad → aksi
    KeyPoller.mqh              ← polling keyboard (WinAPI)
    MathUtils.mqh              ← kalkulasi lot & harga (pure)
    LotManager.mqh             ← state lot + normalisasi broker
    PositionUtils.mqh          ← filter posisi symbol + magic
    TradeExecutor.mqh          ← eksekusi order via CTrade
    TrailingManager.mqh        ← trailing stop
    Panel.mqh                  ← panel status on-chart
  Scripts/HotkeysEA/
    HotkeysEA_Tests.mq5        ← unit test harness (opsional)
```

> **Penting:** Semua file `Include/HotkeysEA/*.mqh` **wajib** ada. Compile hanya `HotkeysEA.mq5`, tapi MetaEditor akan `#include` modul-modul di atas.

---

## Langkah 1 — Salin source ke data folder MT5

1. Buka MT5 → **File → Open Data Folder**
2. Salin isi folder `MQL5/` dari repo ke data folder terminal:

```
[Data Folder MT5]/MQL5/
  Experts/HotkeysEA/HotkeysEA.mq5
  Include/HotkeysEA/*.mqh
  Scripts/HotkeysEA/HotkeysEA_Tests.mq5   (opsional)
```

Contoh path data folder:

```
C:\Users\<user>\AppData\Roaming\MetaQuotes\Terminal\<ID>\MQL5\
```

3. Pastikan struktur folder **persis** seperti di atas (bukan hanya `.mq5` tanpa `Include`).

---

## Langkah 2 — Compile EA

1. Buka **MetaEditor** (F4 dari MT5, atau dari Start Menu)
2. **File → Open** → buka:
   ```
   MQL5/Experts/HotkeysEA/HotkeysEA.mq5
   ```
3. Tekan **F7** (Compile) atau klik tombol **Compile**
4. Tab **Errors** harus menampilkan:
   ```
   0 error(s), 0 warning(s)
   ```
5. Output binary:
   ```
   MQL5/Experts/HotkeysEA/HotkeysEA.ex5
   ```

Jika `.ex5` tidak muncul, compile **gagal** meskipun tidak ada error yang terlihat — cek tab Errors lagi.

---

## Langkah 3 — Compile test harness (opsional)

1. Buka `MQL5/Scripts/HotkeysEA/HotkeysEA_Tests.mq5`
2. Tekan **F7**
3. Di MT5, drag script **HotkeysEA_Tests** ke chart mana saja
4. Tab **Experts** harus menampilkan:
   ```
   ==== RESULT: 31 passed, 0 failed ====
   ```

Test ini memverifikasi logika murni (keycode mapping, clamp lot, SL/TP/pending math) **tanpa** order ke market.

---

## Compile via command line (opsional)

Jika MetaEditor terinstall, compile dari PowerShell:

```powershell
& "C:\Program Files\MetaTrader 5\metaeditor64.exe" /compile:"C:\path\to\MQL5\Experts\HotkeysEA\HotkeysEA.mq5" /log
```

Sesuaikan path MetaEditor dan file `.mq5` dengan instalasi Anda. Cek log compile di folder yang sama dengan `.mq5`.

---

## Aturan MQL5 yang relevan

### Input hanya di file utama EA

Parameter `input` **tidak boleh** di file `.mqh` yang di-include berkali-kali. Semua input ada di `HotkeysEA.mq5`. File `Config.mqh` hanya berisi enum dan `#define`.

### Include path

Gunakan format angle bracket agar konsisten:

```cpp
#include <HotkeysEA/Config.mqh>
```

### DLL import

`KeyPoller.mqh` mengimpor `user32.dll` untuk `GetAsyncKeyState`. Ini **bukan** error compile, tapi saat runtime user harus mengaktifkan **Allow DLL imports** (lihat [PENGGUNAAN.md](PENGGUNAAN.md)).

---

## Troubleshooting compile

| Error | Penyebab | Solusi |
|-------|----------|--------|
| `'HK_MapKey' - undeclared identifier` | `Include/HotkeysEA/` belum disalin | Salin seluruh folder Include |
| `'g_panel' - undeclared identifier` | Enum/input rusak karena `input` di `.mqh` | Pastikan pakai versi terbaru; input hanya di `.mq5` |
| `case value already used` | Enum tidak ter-load (include ganda/rusak) | Compile ulang setelah fix input; salin ulang semua `.mqh` |
| `'CTrade' - undeclared` | Standard library MT5 | Pastikan `#include <Trade/Trade.mqh>` ada; update MT5 |
| `'GetAsyncKeyState' - cannot load dll` | Normal saat compile | Izinkan DLL saat attach EA, bukan saat compile |

---

## Setelah compile berhasil

Lanjut ke **[PENGGUNAAN.md](PENGGUNAAN.md)** untuk attach EA, pengaturan, dan hotkey.

---

## Branch & release (developer)

| Branch | Tujuan |
|--------|--------|
| `development` | Integrasi fitur & fix |
| `main` | Release stabil |
| `feature/*` | Branch kerja per fitur |

Setelah merge ke `development`, salin ulang file ke data folder MT5 dan compile ulang agar `.ex5` ter-update.

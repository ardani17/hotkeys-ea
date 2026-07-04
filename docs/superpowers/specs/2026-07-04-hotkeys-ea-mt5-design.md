# Hotkeys EA — MT5 Numpad Quick Execution (Design Spec)

- **Tanggal:** 2026-07-04
- **Platform:** MetaTrader 5 (MQL5)
- **GitHub Issue:** [#1](https://github.com/ardani17/hotkeys-ea/issues/1)
- **Status:** Design disetujui, siap ke implementation plan

## 1. Tujuan

Expert Advisor (EA) untuk MetaTrader 5 yang memungkinkan eksekusi trading cepat
lewat keyboard numpad (kondisi NumLock ON), tanpa perlu klik mouse. Ditujukan untuk
scalping / eksekusi manual cepat pada symbol chart yang sedang di-attach EA.

## 2. Ruang Lingkup

- EA di-attach ke satu chart. Semua aksi berlaku untuk **symbol chart aktif** saja.
- Semua posisi difilter berdasarkan **magic number** + **symbol**, sehingga EA tidak
  mengganggu trade manual atau EA lain.
- Bukan sistem otomatis/algoritmik — murni alat bantu eksekusi manual via hotkey.

## 3. Hotkey Map

Aktif saat NumLock ON dan chart EA sedang fokus.

| Tombol | Fungsi | Scope |
|--------|--------|-------|
| `1` | Buy market | symbol aktif |
| `2` | Sell market | symbol aktif |
| `3` | Close profit only (tutup posisi yang profit) | symbol aktif |
| `4` | Close last position | symbol aktif |
| `5` | Close half (partial 50%) | posisi terakhir |
| `6` | Reverse (tutup posisi + buka arah berlawanan) | symbol aktif |
| `7` | Move SL to Breakeven | symbol aktif |
| `8` | Toggle Trailing Stop on/off | global EA |
| `9` | Toggle SL/TP on entry on/off | global EA |
| `0` | Reset lot ke default | — |
| `+` | Tambah lot (+step) | — |
| `-` | Kurangi lot (−step) | — |
| `*` | Buy pending order | symbol aktif |
| `/` | Sell pending order | symbol aktif |
| `.` (Del) | Delete semua pending order | symbol aktif |
| `Enter` | Close all posisi | symbol aktif |

## 4. Arsitektur

Single-file EA (`HotkeysEA.mq5`) dengan struktur modular internal.

- **`OnInit()`** — validasi input, init state (lot aktif, toggle SL/TP, trailing),
  gambar panel on-chart.
- **`OnDeinit()`** — hapus panel & seluruh objek chart yang dibuat EA.
- **`OnChartEvent()`** — menangkap `CHARTEVENT_KEYDOWN`, memetakan keycode numpad ke
  aksi. Ini komponen inti.
- **`OnTick()`** — menjalankan trailing stop (bila aktif) & refresh panel P/L.
- **Modul trading** — menggunakan class `CTrade` (library standar MQL5) untuk semua
  order: buy, sell, close, modify, pending.
- **Modul posisi** — helper filter posisi berdasarkan symbol + magic number
  (iterasi `PositionsTotal()`).
- **Modul panel** — objek `OBJ_LABEL` on-chart menampilkan: lot aktif, status SL/TP
  on/off, trailing on/off, floating P/L, jumlah posisi.

### Prinsip desain

- Setiap aksi difilter magic number + symbol chart aktif.
- Setiap unit (trading, posisi, panel, input handling) punya tanggung jawab tunggal
  dan bisa dipahami/diuji terpisah.
- Normalisasi lot & harga selalu mengikuti spesifikasi symbol broker.

## 5. Input Settings (Parameter EA)

| Parameter | Default | Keterangan |
|-----------|---------|------------|
| `InpDefaultLot` | `0.01` | Lot awal / hasil reset |
| `InpLotStep` | `0.01` | Step untuk tombol `+` / `-` |
| `InpMaxLot` | `1.00` | Batas lot maksimal (cap) |
| `InpMagicNumber` | `20260704` | Filter posisi milik EA |
| `InpUseSLTP` | `true` | SL/TP on entry (di-toggle via key `9`) |
| `InpStopLossPts` | `200` | Stop Loss dalam points |
| `InpTakeProfitPts` | `400` | Take Profit dalam points |
| `InpTrailingPts` | `150` | Jarak trailing stop (points) |
| `InpTrailingStep` | `50` | Step pergerakan trailing (points) |
| `InpPendingDistPts` | `100` | Jarak pending order dari harga (points) |
| `InpPendingType` | `STOP` | Tipe pending: `STOP` atau `LIMIT` |
| `InpConfirmCloseAll` | `true` | Minta konfirmasi sebelum Close All |
| `InpSlippagePts` | `30` | Max deviation (points) |
| `InpPanelCorner` | `LEFT_UPPER` | Posisi panel di chart |

## 6. Edge Cases & Error Handling

- **Trading tidak diizinkan** (AutoTrading off / market close): tampilkan warning di
  panel, jangan lempar error.
- **Margin tidak cukup**: tangkap retcode dari `CTrade`, tampilkan pesan singkat di
  panel/log.
- **Lot melebihi `InpMaxLot`**: clamp ke max, beri notifikasi.
- **Lot di bawah minimum broker**: clamp ke `SYMBOL_VOLUME_MIN`, normalisasi ke
  `SYMBOL_VOLUME_STEP`.
- **Close All dengan konfirmasi**: `Enter` pertama meminta konfirmasi (panel berubah
  warna), `Enter` kedua dalam 3 detik mengeksekusi. Dapat dimatikan via
  `InpConfirmCloseAll = false`.
- **Reverse tanpa posisi**: diperlakukan sebagai open biasa.
- **SL/TP invalid** (lebih dekat dari stops level): normalisasi ke
  `SYMBOL_TRADE_STOPS_LEVEL` minimum.
- **Pending order jarak invalid**: normalisasi mengikuti stops level broker.

## 7. Testing

- Manual test di akun demo MT5 untuk setiap hotkey.
- Test di Strategy Tester (visual mode) untuk verifikasi eksekusi & logika.
- Checklist fungsi:
  - [ ] Buy / Sell market
  - [ ] Lot: tambah / kurangi / reset / cap maksimal / clamp minimum
  - [ ] Close all / close profit only / close last / close half
  - [ ] Reverse
  - [ ] Move SL to breakeven
  - [ ] Toggle trailing stop (berjalan di OnTick)
  - [ ] Toggle SL/TP on entry
  - [ ] Buy / Sell pending order
  - [ ] Delete pending order
  - [ ] Panel menampilkan state akurat
  - [ ] Filter magic number + symbol bekerja (tidak sentuh trade lain)

## 8. Branch Strategy

- `main` — stable / release
- `development` — active development

## 9. Open Questions (terselesaikan)

- Fungsi `3` → Close profit only. **(selesai)**
- Close all scope → symbol chart aktif. **(selesai)**
- Lot default & step → 0.01 / 0.01. **(selesai)**
- SL/TP → dalam points via input. **(selesai)**

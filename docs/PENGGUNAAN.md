# Panduan Penggunaan — Hotkeys EA (MT5)

Dokumen ini untuk **trader / pengguna** yang ingin memakai EA di chart MT5.
Untuk **compile dari source code**, lihat [COMPILE.md](COMPILE.md).

---

## Apa itu Hotkeys EA?

Expert Advisor (EA) untuk eksekusi trading cepat lewat **keyboard numpad**. Attach EA ke satu chart, tekan tombol numpad, order dieksekusi pada **symbol chart tersebut** — tanpa klik mouse.

Semua order difilter **magic number** EA, sehingga tidak mengganggu posisi manual atau EA lain.

---

## Prasyarat

- MetaTrader 5 (Windows)
- File **`HotkeysEA.ex5`** sudah ter-compile (lihat [COMPILE.md](COMPILE.md) jika belum)
- Keyboard dengan **numpad** (tombol angka di kanan)
- Akun demo atau live dengan **Algo Trading** diizinkan broker

---

## Instalasi cepat (tanpa compile)

Jika Anda hanya menerima file `.ex5`:

1. MT5 → **File → Open Data Folder**
2. Salin `HotkeysEA.ex5` ke:
   ```
   MQL5/Experts/HotkeysEA/HotkeysEA.ex5
   ```
3. Restart MT5 atau refresh Navigator (klik kanan Expert Advisors → Refresh)

> Tanpa folder `Include`, EA tetap jalan jika sudah berupa `.ex5` (logic sudah ter-compile di dalam binary).

---

## Langkah attach EA

1. **Nyalakan Algo Trading** — tombol **Algo Trading** hijau di toolbar MT5
2. **Navigator** → **Expert Advisors** → **HotkeysEA**
3. Drag ke chart symbol yang ingin ditradingkan (mis. BTCUSD, EURUSD)
4. Di dialog properties, tab **Common**:
   - ✅ **Allow Algo Trading**
   - ✅ **Allow DLL imports** *(wajib — EA membaca keyboard via WinAPI)*
5. Klik **OK**
6. Di pojok kanan chart harus muncul **smiley** (EA aktif, bukan silang)

---

## Panel status (kiri atas chart)

```
== HOTKEYS EA ==
Lot     : 0.01
SL/TP   : ON
Trailing: OFF
Posisi  : 0
Float PL: 0.00
Trade   : OK
Key     : (tekan numpad)
```

| Baris | Arti |
|-------|------|
| **Lot** | Volume order berikutnya |
| **SL/TP** | ON = entry pakai Stop Loss / Take Profit |
| **Trailing** | ON = trailing stop aktif (key `8`) |
| **Posisi** | Jumlah posisi milik EA di symbol ini |
| **Float PL** | Floating profit/loss posisi EA |
| **Trade** | OK = trading diizinkan; BLOCKED = cek Algo Trading |
| **Key** | Aksi terakhir dari numpad |

Saat **Close All** menunggu konfirmasi, muncul baris kuning:
`>> ENTER lagi utk CLOSE ALL <<`

---

## Daftar hotkey (numpad)

EA mendukung **NumLock ON maupun OFF** (tombol angka 0–9 memetakan kode berbeda; operator `+`, `-`, `*`, `/`, Enter tetap sama).

### Entry & lot

| Tombol | Fungsi |
|--------|--------|
| **1** | Buy market |
| **2** | Sell market |
| **0** | Reset lot ke default |
| **+** | Tambah lot (step) |
| **-** | Kurangi lot (step) |

### Manajemen posisi

| Tombol | Fungsi |
|--------|--------|
| **3** | Tutup posisi yang profit saja |
| **4** | Tutup posisi terakhir |
| **5** | Tutup 50% posisi terakhir |
| **6** | Reverse (tutup semua + buka arah berlawanan) |
| **7** | Pindahkan SL ke breakeven |
| **Enter** | Close all (symbol chart ini) |

### Pending order

| Tombol | Fungsi |
|--------|--------|
| **\*** | Buy pending (STOP/LIMIT sesuai input) |
| **/** | Sell pending |
| **.** (Del) | Hapus semua pending order EA di symbol ini |

### Toggle

| Tombol | Fungsi |
|--------|--------|
| **8** | Toggle trailing stop ON/OFF |
| **9** | Toggle SL/TP saat entry ON/OFF |

---

## Close All — konfirmasi ganda

Default: **Enter** pertama = minta konfirmasi (panel kuning), **Enter** kedua dalam **3 detik** = tutup semua posisi EA di symbol chart.

- Tekan tombol lain → konfirmasi dibatalkan
- Set `InpConfirmCloseAll = false` di properties EA → Enter langsung close all

---

## Pengaturan (Inputs)

Buka properties EA (double-click nama EA di chart atau F7 → Inputs):

| Parameter | Default | Keterangan |
|-----------|---------|------------|
| **InpDefaultLot** | 0.01 | Lot awal / reset (key `0`) |
| **InpLotStep** | 0.01 | Step tombol `+` / `-` |
| **InpMaxLot** | 1.00 | Batas lot maksimum |
| **InpMagicNumber** | 20260704 | Magic number — hanya posisi EA ini yang disentuh |
| **InpUseSLTP** | true | SL/TP saat entry (toggle key `9`) |
| **InpStopLossPts** | 200 | Jarak SL dalam **points** |
| **InpTakeProfitPts** | 400 | Jarak TP dalam **points** |
| **InpTrailingPts** | 150 | Jarak trailing (points) |
| **InpTrailingStep** | 50 | Step pergerakan trailing |
| **InpPendingDistPts** | 100 | Jarak pending dari harga |
| **InpPendingType** | STOP | STOP atau LIMIT |
| **InpConfirmCloseAll** | true | Konfirmasi sebelum close all |
| **InpSlippagePts** | 30 | Max deviation (points) |
| **InpPanelCorner** | LEFT_UPPER | Posisi panel |
| **InpDebugKeys** | false | Log setiap aksi ke tab Experts |

### Tips SL/TP per symbol

**Points** bergantung symbol:

- **EURUSD** (5 digit): 200 points ≈ 20 pips
- **BTCUSD**: 200 points × point size — bisa hanya ~$2; spread crypto sering lebih besar

EA otomatis menyesuaikan jarak minimum SL/TP dengan **spread broker**. Jika SL/TP masih ditolak, EA membuka posisi **tanpa SL/TP** dan menulis peringatan di log.

Untuk crypto, pertimbangkan naikkan `InpStopLossPts` / `InpTakeProfitPts`, atau matikan SL/TP entry (key `9`) lalu set manual.

---

## Alur kerja disarankan

1. Attach EA ke chart symbol target
2. Cek panel: **Trade: OK**, lot sesuai risk
3. Atur lot dengan `+` / `-` atau `0` reset
4. Toggle SL/TP (`9`) dan trailing (`8`) sesuai strategi
5. Entry: `1` buy / `2` sell
6. Kelola posisi: `3`–`7`, `Enter` close all
7. Selesai session: lepas EA atau `Enter` close all

---

## Troubleshooting

| Gejala | Penyebab | Solusi |
|--------|----------|--------|
| Panel tidak muncul | EA tidak aktif | Cek smiley di chart; allow Algo Trading |
| **Trade: BLOCKED** | Algo Trading off | Nyalakan tombol hijau Algo Trading |
| Hotkey tidak bereaksi | DLL imports off | Properties EA → Allow DLL imports |
| Order `[auto trading disabled]` | Algo off saat tekan key | Nyalakan Algo Trading |
| Order `[invalid stops]` | SL/TP terlalu dekat spread | Naikkan InpStopLossPts; atau SL/TP off (key `9`) |
| Lot tidak berubah | EA tidak jalan / DLL off | Cek panel & log; enable DLL |
| Posisi manual ikut ke-close | Magic number sama | Gunakan magic unik; EA hanya close magic sendiri |
| Key terdeteksi di app lain | Polling keyboard global | Pastikan MT5 aktif saat trading; jangan ketik numpad di app lain |

### Mode debug

Set **InpDebugKeys = true**, attach ulang, tekan numpad. Tab **Experts** (Ctrl+T) harus menampilkan:

```
HotkeysEA: action=LOT + lot=0.02
```

Jika muncul → keyboard OK. Jika order gagal, baca pesan retcode di baris berikutnya.

### Cek log

Tab **Experts** atau file:

```
MQL5/Logs/YYYYMMDD.log
```

Cari baris `HotkeysEA` untuk status init, error order, dan peringatan SL/TP.

---

## Keamanan & scope

- ✅ Hanya symbol **chart tempat EA di-attach**
- ✅ Hanya posisi/order dengan **magic number** EA
- ✅ Close all hanya posisi EA di symbol tersebut
- ⚠️ Keyboard dipantau saat MT5 berjalan (WinAPI global) — hindari menekan numpad di aplikasi lain jika EA aktif
- ⚠️ Trading berisiko — uji di **akun demo** dulu

---

## Versi

- **v1.01** — polling keyboard WinAPI, NumLock ON/OFF, spread-aware SL/TP, panel status

Repository: [github.com/ardani17/hotkeys-ea](https://github.com/ardani17/hotkeys-ea)

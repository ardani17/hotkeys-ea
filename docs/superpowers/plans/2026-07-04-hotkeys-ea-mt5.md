# Hotkeys EA (MT5) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an MT5 Expert Advisor that executes trading actions (buy/sell, lot sizing, close variants, reverse, breakeven, trailing, pending orders) via the numpad on the active chart symbol.

**Architecture:** Single EA entry point (`HotkeysEA.mq5`) wires together focused include modules. Pure logic (keycode mapping, lot clamping, SL/TP/pending price math) lives in dependency-free functions that are unit-tested by a MT5 test-harness script. Market/`CTrade`-dependent modules (position filtering, trade execution, trailing, panel) are verified via compilation and manual Strategy Tester runs.

**Tech Stack:** MQL5, standard library `<Trade/Trade.mqh>` (`CTrade`), MetaEditor compiler, MetaTrader 5 Strategy Tester.

## Global Constraints

- Platform: MetaTrader 5 only (MQL5). Compile target: MetaEditor build 3000+.
- All trading actions are scoped to the **active chart symbol** (`_Symbol`) AND filtered by **magic number** (`InpMagicNumber`, default `20260704`). EA must never touch positions/orders it did not open.
- Hotkeys active only on `CHARTEVENT_KEYDOWN` while the EA's chart has focus; NumLock ON assumed (numpad virtual key codes).
- Lot handling: default `0.01`, step `0.01`, max cap `1.00`; always clamp to broker `SYMBOL_VOLUME_MIN`/`SYMBOL_VOLUME_MAX`/`SYMBOL_VOLUME_STEP`.
- SL/TP/pending distances are expressed in **points** via inputs; normalize against `SYMBOL_TRADE_STOPS_LEVEL`.
- Repo mirrors the MT5 `MQL5/` folder layout so sources map directly into a terminal data folder.
- No CLI test runner exists for MQL5: "run test" means compile in MetaEditor (F7) and run the harness script in MT5, reading the Experts/Journal tab.

## File Structure

```
MQL5/
  Experts/HotkeysEA/HotkeysEA.mq5        # entry point: OnInit/OnDeinit/OnChartEvent/OnTick wiring
  Include/HotkeysEA/Config.mqh           # inputs, enums, keycode constants
  Include/HotkeysEA/KeyMap.mqh           # HK_MapKey: keycode -> action (pure)
  Include/HotkeysEA/MathUtils.mqh        # HK_ClampLot / HK_CalcEntrySL / HK_CalcEntryTP / HK_CalcPendingPrice (pure)
  Include/HotkeysEA/LotManager.mqh       # CLotManager: stateful lot with broker normalization
  Include/HotkeysEA/PositionUtils.mqh    # CPositionFilter: iterate/count/profit/last ticket by symbol+magic
  Include/HotkeysEA/TradeExecutor.mqh    # CTradeExecutor: market/close/reverse/breakeven/pending via CTrade
  Include/HotkeysEA/TrailingManager.mqh  # CTrailingManager: OnTick trailing stop
  Include/HotkeysEA/Panel.mqh            # CPanel: on-chart status labels
  Scripts/HotkeysEA/HotkeysEA_Tests.mq5  # unit-test harness for pure functions
README.md                                # install & usage
```

Build order: Config -> KeyMap -> MathUtils -> (test harness for pure logic) -> LotManager -> PositionUtils -> TradeExecutor -> TrailingManager -> Panel -> main EA -> integration + README.

---

### Task 1: Config module (inputs, enums, keycodes)

**Files:**
- Create: `MQL5/Include/HotkeysEA/Config.mqh`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `enum ENUM_HK_PENDING { HK_PENDING_STOP, HK_PENDING_LIMIT }`
  - `enum ENUM_HK_ACTION { HK_NONE, HK_BUY, HK_SELL, HK_CLOSE_PROFIT, HK_CLOSE_LAST, HK_CLOSE_HALF, HK_REVERSE, HK_BREAKEVEN, HK_TOGGLE_TRAIL, HK_TOGGLE_SLTP, HK_RESET_LOT, HK_LOT_UP, HK_LOT_DOWN, HK_BUY_PENDING, HK_SELL_PENDING, HK_DELETE_PENDING, HK_CLOSE_ALL }`
  - Keycode `#define`s: `HK_VK_0..HK_VK_9`, `HK_VK_ADD`, `HK_VK_SUBTRACT`, `HK_VK_MULTIPLY`, `HK_VK_DIVIDE`, `HK_VK_DECIMAL`, `HK_VK_RETURN`.
  - `#define HK_CONFIRM_WINDOW_SEC 3`
  - `input` parameters listed below.

- [ ] **Step 1: Create the config include with enums, keycodes, and inputs**

```cpp
//+------------------------------------------------------------------+
//| Config.mqh - inputs, enums, and numpad keycodes                  |
//+------------------------------------------------------------------+
#ifndef HK_CONFIG_MQH
#define HK_CONFIG_MQH

// Numpad virtual key codes (NumLock ON)
#define HK_VK_0          96
#define HK_VK_1          97
#define HK_VK_2          98
#define HK_VK_3          99
#define HK_VK_4          100
#define HK_VK_5          101
#define HK_VK_6          102
#define HK_VK_7          103
#define HK_VK_8          104
#define HK_VK_9          105
#define HK_VK_MULTIPLY   106
#define HK_VK_ADD        107
#define HK_VK_SUBTRACT   109
#define HK_VK_DECIMAL    110
#define HK_VK_DIVIDE     111
#define HK_VK_RETURN     13

#define HK_CONFIRM_WINDOW_SEC 3

enum ENUM_HK_PENDING
{
   HK_PENDING_STOP = 0,
   HK_PENDING_LIMIT = 1
};

enum ENUM_HK_ACTION
{
   HK_NONE = 0,
   HK_BUY,
   HK_SELL,
   HK_CLOSE_PROFIT,
   HK_CLOSE_LAST,
   HK_CLOSE_HALF,
   HK_REVERSE,
   HK_BREAKEVEN,
   HK_TOGGLE_TRAIL,
   HK_TOGGLE_SLTP,
   HK_RESET_LOT,
   HK_LOT_UP,
   HK_LOT_DOWN,
   HK_BUY_PENDING,
   HK_SELL_PENDING,
   HK_DELETE_PENDING,
   HK_CLOSE_ALL
};

input double         InpDefaultLot      = 0.01;         // Default / reset lot
input double         InpLotStep         = 0.01;         // Lot step for +/-
input double         InpMaxLot          = 1.00;         // Max lot cap
input long           InpMagicNumber     = 20260704;     // Magic number filter
input bool           InpUseSLTP         = true;         // Use SL/TP on entry
input int            InpStopLossPts     = 200;          // Stop Loss (points)
input int            InpTakeProfitPts   = 400;          // Take Profit (points)
input int            InpTrailingPts     = 150;          // Trailing distance (points)
input int            InpTrailingStep    = 50;           // Trailing step (points)
input int            InpPendingDistPts  = 100;          // Pending distance (points)
input ENUM_HK_PENDING InpPendingType    = HK_PENDING_STOP; // Pending type
input bool           InpConfirmCloseAll = true;         // Confirm before Close All
input int            InpSlippagePts     = 30;           // Max deviation (points)
input ENUM_BASE_CORNER InpPanelCorner   = CORNER_LEFT_UPPER; // Panel corner

#endif // HK_CONFIG_MQH
```

- [ ] **Step 2: Verify it compiles**

Create a throwaway EA or open in MetaEditor and compile (F7). Optionally from CLI if MetaEditor is installed:

Run: `& "$env:APPDATA\..\..\<MT5>\metaeditor64.exe" /compile:"MQL5\Include\HotkeysEA\Config.mqh" /log`
Expected: 0 errors (includes generate no output binary but must parse without errors). If CLI path unknown, use MetaEditor F7 on a file that `#include`s it (done in Task 2).

- [ ] **Step 3: Commit**

```bash
git add MQL5/Include/HotkeysEA/Config.mqh
git commit -m "feat: add EA config (inputs, action enum, numpad keycodes)"
```

---

### Task 2: KeyMap module + test harness bootstrap

**Files:**
- Create: `MQL5/Include/HotkeysEA/KeyMap.mqh`
- Create: `MQL5/Scripts/HotkeysEA/HotkeysEA_Tests.mq5`

**Interfaces:**
- Consumes: `ENUM_HK_ACTION` and `HK_VK_*` from `Config.mqh`.
- Produces: `ENUM_HK_ACTION HK_MapKey(long key)` — pure function mapping a virtual keycode to an action; returns `HK_NONE` for unmapped keys.

- [ ] **Step 1: Write the failing test (harness + KeyMap assertions)**

```cpp
//+------------------------------------------------------------------+
//| HotkeysEA_Tests.mq5 - unit tests for pure logic                  |
//+------------------------------------------------------------------+
#property script_show_inputs
#include <HotkeysEA/Config.mqh>
#include <HotkeysEA/KeyMap.mqh>
#include <HotkeysEA/MathUtils.mqh>

int g_pass = 0;
int g_fail = 0;

void AssertTrue(const bool cond, const string name)
{
   if(cond) { g_pass++; PrintFormat("PASS: %s", name); }
   else     { g_fail++; PrintFormat("FAIL: %s", name); }
}
void AssertEqI(const long got, const long exp, const string name)
{
   AssertTrue(got == exp, StringFormat("%s (got %d exp %d)", name, got, exp));
}
void AssertEqD(const double got, const double exp, const double eps, const string name)
{
   AssertTrue(MathAbs(got - exp) <= eps, StringFormat("%s (got %.5f exp %.5f)", name, got, exp));
}

void TestKeyMap()
{
   AssertEqI(HK_MapKey(HK_VK_1), HK_BUY,            "key 1 -> BUY");
   AssertEqI(HK_MapKey(HK_VK_2), HK_SELL,           "key 2 -> SELL");
   AssertEqI(HK_MapKey(HK_VK_3), HK_CLOSE_PROFIT,   "key 3 -> CLOSE_PROFIT");
   AssertEqI(HK_MapKey(HK_VK_4), HK_CLOSE_LAST,     "key 4 -> CLOSE_LAST");
   AssertEqI(HK_MapKey(HK_VK_5), HK_CLOSE_HALF,     "key 5 -> CLOSE_HALF");
   AssertEqI(HK_MapKey(HK_VK_6), HK_REVERSE,        "key 6 -> REVERSE");
   AssertEqI(HK_MapKey(HK_VK_7), HK_BREAKEVEN,      "key 7 -> BREAKEVEN");
   AssertEqI(HK_MapKey(HK_VK_8), HK_TOGGLE_TRAIL,   "key 8 -> TOGGLE_TRAIL");
   AssertEqI(HK_MapKey(HK_VK_9), HK_TOGGLE_SLTP,    "key 9 -> TOGGLE_SLTP");
   AssertEqI(HK_MapKey(HK_VK_0), HK_RESET_LOT,      "key 0 -> RESET_LOT");
   AssertEqI(HK_MapKey(HK_VK_ADD), HK_LOT_UP,       "key + -> LOT_UP");
   AssertEqI(HK_MapKey(HK_VK_SUBTRACT), HK_LOT_DOWN,"key - -> LOT_DOWN");
   AssertEqI(HK_MapKey(HK_VK_MULTIPLY), HK_BUY_PENDING,  "key * -> BUY_PENDING");
   AssertEqI(HK_MapKey(HK_VK_DIVIDE), HK_SELL_PENDING,   "key / -> SELL_PENDING");
   AssertEqI(HK_MapKey(HK_VK_DECIMAL), HK_DELETE_PENDING,"key . -> DELETE_PENDING");
   AssertEqI(HK_MapKey(HK_VK_RETURN), HK_CLOSE_ALL, "key Enter -> CLOSE_ALL");
   AssertEqI(HK_MapKey(65), HK_NONE,                "key A -> NONE");
}

void OnStart()
{
   g_pass = 0; g_fail = 0;
   TestKeyMap();
   TestMathUtils(); // defined in Task 3
   PrintFormat("==== RESULT: %d passed, %d failed ====", g_pass, g_fail);
}
```

- [ ] **Step 2: Run test to verify it fails**

Compile `HotkeysEA_Tests.mq5` in MetaEditor (F7).
Expected: FAIL — compile errors `'HK_MapKey' - undeclared identifier` and `'TestMathUtils' - undeclared identifier`.

- [ ] **Step 3: Write minimal KeyMap implementation**

```cpp
//+------------------------------------------------------------------+
//| KeyMap.mqh - numpad keycode to action mapping (pure)             |
//+------------------------------------------------------------------+
#ifndef HK_KEYMAP_MQH
#define HK_KEYMAP_MQH
#include "Config.mqh"

ENUM_HK_ACTION HK_MapKey(const long key)
{
   switch((int)key)
   {
      case HK_VK_1:        return HK_BUY;
      case HK_VK_2:        return HK_SELL;
      case HK_VK_3:        return HK_CLOSE_PROFIT;
      case HK_VK_4:        return HK_CLOSE_LAST;
      case HK_VK_5:        return HK_CLOSE_HALF;
      case HK_VK_6:        return HK_REVERSE;
      case HK_VK_7:        return HK_BREAKEVEN;
      case HK_VK_8:        return HK_TOGGLE_TRAIL;
      case HK_VK_9:        return HK_TOGGLE_SLTP;
      case HK_VK_0:        return HK_RESET_LOT;
      case HK_VK_ADD:      return HK_LOT_UP;
      case HK_VK_SUBTRACT: return HK_LOT_DOWN;
      case HK_VK_MULTIPLY: return HK_BUY_PENDING;
      case HK_VK_DIVIDE:   return HK_SELL_PENDING;
      case HK_VK_DECIMAL:  return HK_DELETE_PENDING;
      case HK_VK_RETURN:   return HK_CLOSE_ALL;
      default:             return HK_NONE;
   }
}

#endif // HK_KEYMAP_MQH
```

- [ ] **Step 4: Run test to verify KeyMap passes**

After Task 3 provides `MathUtils.mqh` + `TestMathUtils`, compile and run the script in MT5 (drag onto any chart). Until then, temporarily comment out the `TestMathUtils();` line to compile and confirm the 17 KeyMap assertions print `PASS`.
Expected (KeyMap portion): 17 `PASS` lines, 0 `FAIL`.

- [ ] **Step 5: Commit**

```bash
git add MQL5/Include/HotkeysEA/KeyMap.mqh MQL5/Scripts/HotkeysEA/HotkeysEA_Tests.mq5
git commit -m "feat: add numpad keycode->action mapping with test harness"
```

---

### Task 3: MathUtils module (lot clamp + SL/TP/pending price math)

**Files:**
- Create: `MQL5/Include/HotkeysEA/MathUtils.mqh`
- Modify: `MQL5/Scripts/HotkeysEA/HotkeysEA_Tests.mq5` (add `TestMathUtils`)

**Interfaces:**
- Consumes: nothing (pure math; no symbol calls).
- Produces:
  - `double HK_ClampLot(double value, double minLot, double maxLot, double step)`
  - `double HK_CalcEntrySL(int dir, double entryPrice, int slPoints, double point)` — `dir`: +1 buy, -1 sell; returns `0.0` when `slPoints<=0`.
  - `double HK_CalcEntryTP(int dir, double entryPrice, int tpPoints, double point)` — returns `0.0` when `tpPoints<=0`.
  - `double HK_CalcPendingPrice(bool isBuy, bool isStop, double refPrice, int distPoints, double point)`

- [ ] **Step 1: Write the failing test (add TestMathUtils to harness)**

```cpp
void TestMathUtils()
{
   // Clamp: within range snaps to step
   AssertEqD(HK_ClampLot(0.03, 0.01, 1.00, 0.01), 0.03, 1e-8, "clamp 0.03 stays");
   AssertEqD(HK_ClampLot(0.005, 0.01, 1.00, 0.01), 0.01, 1e-8, "clamp below min -> min");
   AssertEqD(HK_ClampLot(5.0, 0.01, 1.00, 0.01), 1.00, 1e-8, "clamp above max -> max");
   AssertEqD(HK_ClampLot(0.024, 0.01, 1.00, 0.01), 0.02, 1e-8, "clamp rounds to step");
   AssertEqD(HK_ClampLot(0.13, 0.10, 1.00, 0.10), 0.10, 1e-8, "clamp step 0.10 rounds down");
   // Entry SL/TP
   AssertEqD(HK_CalcEntrySL(1, 1.10000, 200, 0.00001), 1.09800, 1e-8, "buy SL below");
   AssertEqD(HK_CalcEntrySL(-1, 1.10000, 200, 0.00001), 1.10200, 1e-8, "sell SL above");
   AssertEqD(HK_CalcEntryTP(1, 1.10000, 400, 0.00001), 1.10400, 1e-8, "buy TP above");
   AssertEqD(HK_CalcEntryTP(-1, 1.10000, 400, 0.00001), 1.09600, 1e-8, "sell TP below");
   AssertEqD(HK_CalcEntrySL(1, 1.10000, 0, 0.00001), 0.0, 1e-8, "SL disabled -> 0");
   // Pending prices
   AssertEqD(HK_CalcPendingPrice(true, true, 1.10000, 100, 0.00001), 1.10100, 1e-8, "buy stop above");
   AssertEqD(HK_CalcPendingPrice(true, false, 1.10000, 100, 0.00001), 1.09900, 1e-8, "buy limit below");
   AssertEqD(HK_CalcPendingPrice(false, true, 1.10000, 100, 0.00001), 1.09900, 1e-8, "sell stop below");
   AssertEqD(HK_CalcPendingPrice(false, false, 1.10000, 100, 0.00001), 1.10100, 1e-8, "sell limit above");
}
```

Also uncomment the `TestMathUtils();` call in `OnStart` (added in Task 2).

- [ ] **Step 2: Run test to verify it fails**

Compile the script (F7).
Expected: FAIL — `'HK_ClampLot' - undeclared identifier` (and the other three).

- [ ] **Step 3: Write minimal MathUtils implementation**

```cpp
//+------------------------------------------------------------------+
//| MathUtils.mqh - pure lot and price math (no symbol calls)        |
//+------------------------------------------------------------------+
#ifndef HK_MATHUTILS_MQH
#define HK_MATHUTILS_MQH

double HK_ClampLot(const double value, const double minLot, const double maxLot, double step)
{
   if(step <= 0.0) step = 0.01;
   double v = value;
   if(v < minLot) v = minLot;
   if(v > maxLot) v = maxLot;
   double steps = MathFloor((v - minLot) / step + 0.5);
   double result = minLot + steps * step;
   if(result > maxLot) result = maxLot;
   if(result < minLot) result = minLot;
   return result;
}

double HK_CalcEntrySL(const int dir, const double entryPrice, const int slPoints, const double point)
{
   if(slPoints <= 0) return 0.0;
   return (dir > 0) ? entryPrice - slPoints * point : entryPrice + slPoints * point;
}

double HK_CalcEntryTP(const int dir, const double entryPrice, const int tpPoints, const double point)
{
   if(tpPoints <= 0) return 0.0;
   return (dir > 0) ? entryPrice + tpPoints * point : entryPrice - tpPoints * point;
}

double HK_CalcPendingPrice(const bool isBuy, const bool isStop, const double refPrice,
                           const int distPoints, const double point)
{
   double dist = distPoints * point;
   if(isBuy) return isStop ? refPrice + dist : refPrice - dist;
   return isStop ? refPrice - dist : refPrice + dist;
}

#endif // HK_MATHUTILS_MQH
```

- [ ] **Step 4: Run test to verify all pure-logic tests pass**

Compile (F7) then run `HotkeysEA_Tests` in MT5 (drag script onto a chart). Read Experts tab.
Expected: `==== RESULT: 31 passed, 0 failed ====` (17 KeyMap + 14 MathUtils).

- [ ] **Step 5: Commit**

```bash
git add MQL5/Include/HotkeysEA/MathUtils.mqh MQL5/Scripts/HotkeysEA/HotkeysEA_Tests.mq5
git commit -m "feat: add pure lot/price math with unit tests"
```

---

### Task 4: LotManager module (stateful lot with broker normalization)

**Files:**
- Create: `MQL5/Include/HotkeysEA/LotManager.mqh`

**Interfaces:**
- Consumes: `HK_ClampLot` from `MathUtils.mqh`.
- Produces: class `CLotManager` with:
  - `void Init(string symbol, double defaultLot, double step, double maxLot)`
  - `double Current()` — current normalized lot
  - `void Increase()` / `void Decrease()` / `void Reset()`
  - `double Broker(double raw)` — clamps an arbitrary volume to broker min/max/step for the symbol

**Verification note:** `SYMBOL_VOLUME_*` requires a real symbol, so this is verified by compilation + manual Strategy Tester (the pure clamp math is already unit-tested in Task 3).

- [ ] **Step 1: Write the implementation**

```cpp
//+------------------------------------------------------------------+
//| LotManager.mqh - stateful lot sizing with broker normalization   |
//+------------------------------------------------------------------+
#ifndef HK_LOTMANAGER_MQH
#define HK_LOTMANAGER_MQH
#include "MathUtils.mqh"

class CLotManager
{
private:
   string m_symbol;
   double m_default;
   double m_step;
   double m_maxCap;
   double m_current;
public:
   void Init(const string symbol, const double defaultLot, const double step, const double maxLot)
   {
      m_symbol  = symbol;
      m_step    = (step > 0.0) ? step : 0.01;
      m_maxCap  = maxLot;
      m_default = Broker(defaultLot);
      m_current = m_default;
   }
   double Current() const { return m_current; }

   double Broker(const double raw)
   {
      double bmin  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      double bmax  = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
      double bstep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      double cap   = (m_maxCap > 0.0 && m_maxCap < bmax) ? m_maxCap : bmax;
      if(bstep <= 0.0) bstep = m_step;
      return HK_ClampLot(raw, bmin, cap, bstep);
   }
   void Increase() { m_current = Broker(m_current + m_step); }
   void Decrease() { m_current = Broker(m_current - m_step); }
   void Reset()    { m_current = m_default; }
};

#endif // HK_LOTMANAGER_MQH
```

- [ ] **Step 2: Verify it compiles**

Add `#include <HotkeysEA/LotManager.mqh>` to the test script temporarily and compile (F7).
Expected: 0 errors. Remove the temporary include afterward (LotManager is exercised by the EA/manual tests, not the pure harness).

- [ ] **Step 3: Commit**

```bash
git add MQL5/Include/HotkeysEA/LotManager.mqh
git commit -m "feat: add stateful lot manager with broker normalization"
```

---

### Task 5: PositionUtils module (filter by symbol + magic)

**Files:**
- Create: `MQL5/Include/HotkeysEA/PositionUtils.mqh`

**Interfaces:**
- Consumes: `_Symbol`, `InpMagicNumber` (passed in via Init).
- Produces: class `CPositionFilter` with:
  - `void Init(string symbol, long magic)`
  - `int Count()` — number of matching positions
  - `double TotalProfit()` — summed floating profit of matching positions
  - `ulong LastTicket()` — ticket of the most recently opened matching position (max `POSITION_TIME_MSC`), `0` if none
  - `bool SelectByIndex(int i, ulong &ticket)` — selects i-th matching position; returns false when out of range
  - `int NetDirection()` — `+1` if net matching volume is long-only, `-1` short-only, `0` if none/mixed

**Verification note:** requires open positions; verified via compilation + Strategy Tester in Task 10.

- [ ] **Step 1: Write the implementation**

```cpp
//+------------------------------------------------------------------+
//| PositionUtils.mqh - position filtering by symbol + magic         |
//+------------------------------------------------------------------+
#ifndef HK_POSITIONUTILS_MQH
#define HK_POSITIONUTILS_MQH

class CPositionFilter
{
private:
   string m_symbol;
   long   m_magic;
   bool   Match()
   {
      return (PositionGetString(POSITION_SYMBOL) == m_symbol &&
              PositionGetInteger(POSITION_MAGIC) == m_magic);
   }
public:
   void Init(const string symbol, const long magic) { m_symbol = symbol; m_magic = magic; }

   int Count()
   {
      int n = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0) continue;
         if(Match()) n++;
      }
      return n;
   }

   double TotalProfit()
   {
      double p = 0.0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0) continue;
         if(Match())
            p += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      }
      return p;
   }

   ulong LastTicket()
   {
      ulong  best = 0;
      long   bestTime = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0) continue;
         if(!Match()) continue;
         long tm = (long)PositionGetInteger(POSITION_TIME_MSC);
         if(best == 0 || tm > bestTime) { best = t; bestTime = tm; }
      }
      return best;
   }

   bool SelectByIndex(const int idx, ulong &ticket)
   {
      int n = -1;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0) continue;
         if(!Match()) continue;
         n++;
         if(n == idx) { ticket = t; return true; }
      }
      return false;
   }

   int NetDirection()
   {
      bool hasLong = false, hasShort = false;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0) continue;
         if(!Match()) continue;
         long type = PositionGetInteger(POSITION_TYPE);
         if(type == POSITION_TYPE_BUY)  hasLong = true;
         if(type == POSITION_TYPE_SELL) hasShort = true;
      }
      if(hasLong && !hasShort) return 1;
      if(hasShort && !hasLong) return -1;
      return 0;
   }
};

#endif // HK_POSITIONUTILS_MQH
```

- [ ] **Step 2: Verify it compiles**

Temporarily include it in the test script and compile (F7).
Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add MQL5/Include/HotkeysEA/PositionUtils.mqh
git commit -m "feat: add position filter by symbol and magic number"
```

---

### Task 6: TradeExecutor module (all trade actions via CTrade)

**Files:**
- Create: `MQL5/Include/HotkeysEA/TradeExecutor.mqh`

**Interfaces:**
- Consumes: `CLotManager`, `CPositionFilter`, `MathUtils` functions, `Config` inputs, `<Trade/Trade.mqh>`.
- Produces: class `CTradeExecutor` with:
  - `void Init(string symbol, long magic, int slippage, bool useSLTP, int slPts, int tpPts, int pendDistPts, ENUM_HK_PENDING pendType)`
  - `void SetUseSLTP(bool v)` / `bool UseSLTP()`
  - `bool OpenMarket(int dir, double lot)` — dir +1 buy / -1 sell; applies SL/TP if enabled
  - `bool CloseAll()` / `bool CloseProfit()` / `bool CloseLast(CPositionFilter &pf)` / `bool CloseHalf(CPositionFilter &pf)`
  - `bool Reverse(CPositionFilter &pf, double lot)`
  - `bool MoveToBreakeven()`
  - `bool PlacePending(int dir, double lot)` / `bool DeletePending()`

**Verification note:** all methods touch the market/`CTrade`; verified via Strategy Tester in Task 10. SL/TP normalized to `SYMBOL_TRADE_STOPS_LEVEL`.

- [ ] **Step 1: Write the implementation**

```cpp
//+------------------------------------------------------------------+
//| TradeExecutor.mqh - trade actions scoped to symbol + magic       |
//+------------------------------------------------------------------+
#ifndef HK_TRADEEXECUTOR_MQH
#define HK_TRADEEXECUTOR_MQH
#include <Trade/Trade.mqh>
#include "Config.mqh"
#include "MathUtils.mqh"
#include "PositionUtils.mqh"

class CTradeExecutor
{
private:
   CTrade          m_trade;
   string          m_symbol;
   long            m_magic;
   bool            m_useSLTP;
   int             m_slPts;
   int             m_tpPts;
   int             m_pendDist;
   ENUM_HK_PENDING m_pendType;

   double Point()  { return SymbolInfoDouble(m_symbol, SYMBOL_POINT); }
   int    Digits() { return (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS); }
   int    StopsLevel() { return (int)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL); }

   // Enforce broker minimum stop distance (points) for an SL/TP offset.
   int NormPts(const int pts)
   {
      int minLvl = StopsLevel();
      if(pts > 0 && pts < minLvl) return minLvl;
      return pts;
   }
   bool Match()
   {
      return (PositionGetString(POSITION_SYMBOL) == m_symbol &&
              PositionGetInteger(POSITION_MAGIC) == m_magic);
   }
public:
   void Init(const string symbol, const long magic, const int slippage, const bool useSLTP,
             const int slPts, const int tpPts, const int pendDistPts, const ENUM_HK_PENDING pendType)
   {
      m_symbol   = symbol;
      m_magic    = magic;
      m_useSLTP  = useSLTP;
      m_slPts    = slPts;
      m_tpPts    = tpPts;
      m_pendDist = pendDistPts;
      m_pendType = pendType;
      m_trade.SetExpertMagicNumber(magic);
      m_trade.SetDeviationInPoints(slippage);
      m_trade.SetTypeFillingBySymbol(symbol);
   }
   void SetUseSLTP(const bool v) { m_useSLTP = v; }
   bool UseSLTP() const { return m_useSLTP; }

   bool OpenMarket(const int dir, const double lot)
   {
      double ask = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double price = (dir > 0) ? ask : bid;
      double sl = 0.0, tp = 0.0;
      if(m_useSLTP)
      {
         sl = HK_CalcEntrySL(dir, price, NormPts(m_slPts), Point());
         tp = HK_CalcEntryTP(dir, price, NormPts(m_tpPts), Point());
         if(sl > 0.0) sl = NormalizeDouble(sl, Digits());
         if(tp > 0.0) tp = NormalizeDouble(tp, Digits());
      }
      if(dir > 0) return m_trade.Buy(lot, m_symbol, 0.0, sl, tp, "hk");
      return m_trade.Sell(lot, m_symbol, 0.0, sl, tp, "hk");
   }

   bool CloseAll()
   {
      bool ok = true;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0) continue;
         if(!Match()) continue;
         if(!m_trade.PositionClose(t)) ok = false;
      }
      return ok;
   }

   bool CloseProfit()
   {
      bool ok = true;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0) continue;
         if(!Match()) continue;
         double pl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
         if(pl > 0.0)
            if(!m_trade.PositionClose(t)) ok = false;
      }
      return ok;
   }

   bool CloseLast(CPositionFilter &pf)
   {
      ulong t = pf.LastTicket();
      if(t == 0) return false;
      return m_trade.PositionClose(t);
   }

   bool CloseHalf(CPositionFilter &pf)
   {
      ulong t = pf.LastTicket();
      if(t == 0) return false;
      if(!PositionSelectByTicket(t)) return false;
      double vol  = PositionGetDouble(POSITION_VOLUME);
      double step = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
      double vmin = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
      double half = HK_ClampLot(vol / 2.0, vmin, vol, step);
      if(half <= 0.0 || half >= vol) return false;
      return m_trade.PositionClosePartial(t, half);
   }

   bool Reverse(CPositionFilter &pf, const double lot)
   {
      int dir = pf.NetDirection();      // +1 long, -1 short, 0 none/mixed
      CloseAll();
      int newDir = (dir > 0) ? -1 : 1;  // long -> short; short/none -> long
      return OpenMarket(newDir, lot);
   }

   bool MoveToBreakeven()
   {
      bool ok = true;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0) continue;
         if(!Match()) continue;
         double open = PositionGetDouble(POSITION_PRICE_OPEN);
         double tp   = PositionGetDouble(POSITION_TP);
         double be   = NormalizeDouble(open, Digits());
         if(!m_trade.PositionModify(t, be, tp)) ok = false;
      }
      return ok;
   }

   bool PlacePending(const int dir, const double lot)
   {
      double ask  = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double bid  = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double ref  = (dir > 0) ? ask : bid;
      bool   isStop = (m_pendType == HK_PENDING_STOP);
      int    dist   = m_pendDist;
      int    minLvl = StopsLevel();
      if(dist < minLvl) dist = minLvl;
      double price = HK_CalcPendingPrice(dir > 0, isStop, ref, dist, Point());
      price = NormalizeDouble(price, Digits());
      double sl = 0.0, tp = 0.0;
      if(m_useSLTP)
      {
         sl = HK_CalcEntrySL(dir, price, NormPts(m_slPts), Point());
         tp = HK_CalcEntryTP(dir, price, NormPts(m_tpPts), Point());
         if(sl > 0.0) sl = NormalizeDouble(sl, Digits());
         if(tp > 0.0) tp = NormalizeDouble(tp, Digits());
      }
      if(dir > 0)
         return isStop ? m_trade.BuyStop(lot, price, m_symbol, sl, tp)
                       : m_trade.BuyLimit(lot, price, m_symbol, sl, tp);
      return isStop ? m_trade.SellStop(lot, price, m_symbol, sl, tp)
                    : m_trade.SellLimit(lot, price, m_symbol, sl, tp);
   }

   bool DeletePending()
   {
      bool ok = true;
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         ulong t = OrderGetTicket(i);
         if(t == 0) continue;
         if(OrderGetString(ORDER_SYMBOL) != m_symbol) continue;
         if(OrderGetInteger(ORDER_MAGIC) != m_magic) continue;
         if(!m_trade.OrderDelete(t)) ok = false;
      }
      return ok;
   }
};

#endif // HK_TRADEEXECUTOR_MQH
```

- [ ] **Step 2: Verify it compiles**

Temporarily include it in the test script and compile (F7).
Expected: 0 errors, 0 warnings on the executor.

- [ ] **Step 3: Commit**

```bash
git add MQL5/Include/HotkeysEA/TradeExecutor.mqh
git commit -m "feat: add trade executor (market, close variants, reverse, breakeven, pending)"
```

---

### Task 7: TrailingManager module

**Files:**
- Create: `MQL5/Include/HotkeysEA/TrailingManager.mqh`

**Interfaces:**
- Consumes: `_Symbol`, magic, trailing points/step from inputs.
- Produces: class `CTrailingManager` with:
  - `void Init(string symbol, long magic, int trailPts, int stepPts)`
  - `void Process(CTrade &trade)` — for each matching position, tighten SL toward price when in profit beyond trail distance

**Verification note:** requires running ticks + open positions; verified in Strategy Tester (Task 10).

- [ ] **Step 1: Write the implementation**

```cpp
//+------------------------------------------------------------------+
//| TrailingManager.mqh - trailing stop applied on each tick         |
//+------------------------------------------------------------------+
#ifndef HK_TRAILINGMANAGER_MQH
#define HK_TRAILINGMANAGER_MQH
#include <Trade/Trade.mqh>

class CTrailingManager
{
private:
   string m_symbol;
   long   m_magic;
   int    m_trailPts;
   int    m_stepPts;
public:
   void Init(const string symbol, const long magic, const int trailPts, const int stepPts)
   {
      m_symbol   = symbol;
      m_magic    = magic;
      m_trailPts = trailPts;
      m_stepPts  = (stepPts > 0) ? stepPts : 1;
   }

   void Process(CTrade &trade)
   {
      if(m_trailPts <= 0) return;
      double point  = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
      int    digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      double bid    = SymbolInfoDouble(m_symbol, SYMBOL_BID);
      double ask    = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
      double trail  = m_trailPts * point;
      double step   = m_stepPts * point;

      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong t = PositionGetTicket(i);
         if(t == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) != m_symbol) continue;
         if(PositionGetInteger(POSITION_MAGIC) != m_magic)  continue;

         long   type = PositionGetInteger(POSITION_TYPE);
         double open = PositionGetDouble(POSITION_PRICE_OPEN);
         double sl   = PositionGetDouble(POSITION_SL);
         double tp   = PositionGetDouble(POSITION_TP);

         if(type == POSITION_TYPE_BUY)
         {
            if(bid - open <= trail) continue;
            double newSL = NormalizeDouble(bid - trail, digits);
            if(sl == 0.0 || newSL - sl >= step)
               trade.PositionModify(t, newSL, tp);
         }
         else if(type == POSITION_TYPE_SELL)
         {
            if(open - ask <= trail) continue;
            double newSL = NormalizeDouble(ask + trail, digits);
            if(sl == 0.0 || sl - newSL >= step)
               trade.PositionModify(t, newSL, tp);
         }
      }
   }
};

#endif // HK_TRAILINGMANAGER_MQH
```

- [ ] **Step 2: Verify it compiles**

Temporarily include in the test script and compile (F7).
Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add MQL5/Include/HotkeysEA/TrailingManager.mqh
git commit -m "feat: add trailing stop manager"
```

---

### Task 8: Panel module (on-chart status)

**Files:**
- Create: `MQL5/Include/HotkeysEA/Panel.mqh`

**Interfaces:**
- Consumes: `ENUM_BASE_CORNER`.
- Produces: class `CPanel` with:
  - `void Create(long chartId, ENUM_BASE_CORNER corner)`
  - `void Update(double lot, bool useSLTP, bool trailingOn, bool confirmPending, double floatPL, int posCount)`
  - `void Destroy()`

**Verification note:** visual; verified by attaching the EA and reading the chart (Task 10).

- [ ] **Step 1: Write the implementation**

```cpp
//+------------------------------------------------------------------+
//| Panel.mqh - on-chart status labels                               |
//+------------------------------------------------------------------+
#ifndef HK_PANEL_MQH
#define HK_PANEL_MQH

class CPanel
{
private:
   long             m_chart;
   ENUM_BASE_CORNER m_corner;
   string           m_prefix;
   int              m_xoff;
   int              m_yoff;
   int              m_lineH;

   void SetLabel(const string key, const string text, const color clr, const int line)
   {
      string name = m_prefix + key;
      if(ObjectFind(m_chart, name) < 0)
      {
         ObjectCreate(m_chart, name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(m_chart, name, OBJPROP_CORNER, m_corner);
         ObjectSetInteger(m_chart, name, OBJPROP_XDISTANCE, m_xoff);
         ObjectSetInteger(m_chart, name, OBJPROP_YDISTANCE, m_yoff + line * m_lineH);
         ObjectSetInteger(m_chart, name, OBJPROP_FONTSIZE, 10);
         ObjectSetString(m_chart, name, OBJPROP_FONT, "Consolas");
         ObjectSetInteger(m_chart, name, OBJPROP_SELECTABLE, false);
      }
      ObjectSetString(m_chart, name, OBJPROP_TEXT, text);
      ObjectSetInteger(m_chart, name, OBJPROP_COLOR, clr);
   }
public:
   void Create(const long chartId, const ENUM_BASE_CORNER corner)
   {
      m_chart  = chartId;
      m_corner = corner;
      m_prefix = "HKPANEL_";
      m_xoff   = 12;
      m_yoff   = 20;
      m_lineH  = 18;
   }

   void Update(const double lot, const bool useSLTP, const bool trailingOn,
               const bool confirmPending, const double floatPL, const int posCount)
   {
      SetLabel("title", "== HOTKEYS EA ==", clrWhite, 0);
      SetLabel("lot",   StringFormat("Lot     : %.2f", lot), clrGold, 1);
      SetLabel("sltp",  StringFormat("SL/TP   : %s", useSLTP ? "ON" : "OFF"),
               useSLTP ? clrLime : clrTomato, 2);
      SetLabel("trail", StringFormat("Trailing: %s", trailingOn ? "ON" : "OFF"),
               trailingOn ? clrLime : clrTomato, 3);
      SetLabel("pos",   StringFormat("Posisi  : %d", posCount), clrSilver, 4);
      SetLabel("pl",    StringFormat("Float PL: %.2f", floatPL),
               floatPL >= 0 ? clrLime : clrTomato, 5);
      SetLabel("hint",  confirmPending ? ">> ENTER lagi utk CLOSE ALL <<" : "",
               clrYellow, 6);
      ChartRedraw(m_chart);
   }

   void Destroy()
   {
      ObjectsDeleteAll(m_chart, m_prefix);
      ChartRedraw(m_chart);
   }
};

#endif // HK_PANEL_MQH
```

- [ ] **Step 2: Verify it compiles**

Temporarily include in the test script and compile (F7).
Expected: 0 errors.

- [ ] **Step 3: Commit**

```bash
git add MQL5/Include/HotkeysEA/Panel.mqh
git commit -m "feat: add on-chart status panel"
```

---

### Task 9: Main EA (wiring, event handlers, close-all confirmation)

**Files:**
- Create: `MQL5/Experts/HotkeysEA/HotkeysEA.mq5`

**Interfaces:**
- Consumes: every include module + all `Config` inputs.
- Produces: the compiled EA `HotkeysEA.ex5` (the deliverable). No exported symbols for other tasks.

**Behavior:** `OnChartEvent` maps keydown -> action -> module call. Close All uses a two-press confirmation window (`HK_CONFIRM_WINDOW_SEC`) when `InpConfirmCloseAll` is true. `OnTick` runs trailing (if toggled on) and refreshes the panel.

- [ ] **Step 1: Write the EA**

```cpp
//+------------------------------------------------------------------+
//| HotkeysEA.mq5 - numpad quick-execution EA for MT5                |
//+------------------------------------------------------------------+
#property copyright "ardani17"
#property link      "https://github.com/ardani17/hotkeys-ea"
#property version   "1.00"
#property strict

#include <HotkeysEA/Config.mqh>
#include <HotkeysEA/KeyMap.mqh>
#include <HotkeysEA/MathUtils.mqh>
#include <HotkeysEA/LotManager.mqh>
#include <HotkeysEA/PositionUtils.mqh>
#include <HotkeysEA/TradeExecutor.mqh>
#include <HotkeysEA/TrailingManager.mqh>
#include <HotkeysEA/Panel.mqh>
#include <Trade/Trade.mqh>

CLotManager      g_lot;
CPositionFilter  g_pos;
CTradeExecutor   g_exec;
CTrailingManager g_trail;
CPanel           g_panel;
CTrade           g_trade;

bool     g_trailingOn   = false;
bool     g_confirmArmed = false;
datetime g_confirmTime  = 0;

int OnInit()
{
   g_lot.Init(_Symbol, InpDefaultLot, InpLotStep, InpMaxLot);
   g_pos.Init(_Symbol, InpMagicNumber);
   g_exec.Init(_Symbol, InpMagicNumber, InpSlippagePts, InpUseSLTP,
               InpStopLossPts, InpTakeProfitPts, InpPendingDistPts, InpPendingType);
   g_trail.Init(_Symbol, InpMagicNumber, InpTrailingPts, InpTrailingStep);
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippagePts);
   g_panel.Create(ChartID(), InpPanelCorner);
   RefreshPanel();
   ChartSetInteger(ChartID(), CHART_KEYBOARD_CONTROL, true);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   g_panel.Destroy();
}

void OnTick()
{
   if(g_trailingOn) g_trail.Process(g_trade);
   RefreshPanel();
}

void RefreshPanel()
{
   g_panel.Update(g_lot.Current(), g_exec.UseSLTP(), g_trailingOn,
                  g_confirmArmed, g_pos.TotalProfit(), g_pos.Count());
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id != CHARTEVENT_KEYDOWN) return;
   ENUM_HK_ACTION action = HK_MapKey(lparam);
   if(action == HK_NONE) return;

   // Close-All confirmation window handling
   if(action == HK_CLOSE_ALL)
   {
      if(InpConfirmCloseAll && !g_confirmArmed)
      {
         g_confirmArmed = true;
         g_confirmTime  = TimeCurrent();
         RefreshPanel();
         return;
      }
      g_confirmArmed = false;
      g_exec.CloseAll();
      RefreshPanel();
      return;
   }
   // Any other key cancels a pending confirmation
   g_confirmArmed = false;

   switch(action)
   {
      case HK_BUY:            g_exec.OpenMarket(1, g_lot.Current());  break;
      case HK_SELL:           g_exec.OpenMarket(-1, g_lot.Current()); break;
      case HK_CLOSE_PROFIT:   g_exec.CloseProfit();                   break;
      case HK_CLOSE_LAST:     g_exec.CloseLast(g_pos);                break;
      case HK_CLOSE_HALF:     g_exec.CloseHalf(g_pos);                break;
      case HK_REVERSE:        g_exec.Reverse(g_pos, g_lot.Current()); break;
      case HK_BREAKEVEN:      g_exec.MoveToBreakeven();               break;
      case HK_TOGGLE_TRAIL:   g_trailingOn = !g_trailingOn;           break;
      case HK_TOGGLE_SLTP:    g_exec.SetUseSLTP(!g_exec.UseSLTP());   break;
      case HK_RESET_LOT:      g_lot.Reset();                          break;
      case HK_LOT_UP:         g_lot.Increase();                       break;
      case HK_LOT_DOWN:       g_lot.Decrease();                       break;
      case HK_BUY_PENDING:    g_exec.PlacePending(1, g_lot.Current());  break;
      case HK_SELL_PENDING:   g_exec.PlacePending(-1, g_lot.Current()); break;
      case HK_DELETE_PENDING: g_exec.DeletePending();                 break;
      default: break;
   }
   RefreshPanel();
}

void OnTimer() {}
```

- [ ] **Step 2: Verify it compiles**

Open `HotkeysEA.mq5` in MetaEditor and compile (F7).
Expected: `0 errors, 0 warnings`, produces `HotkeysEA.ex5`.

- [ ] **Step 3: Confirm the confirmation-window expiry via OnTick**

Add expiry check so an armed confirmation auto-cancels after `HK_CONFIRM_WINDOW_SEC`. Modify `OnTick`:

```cpp
void OnTick()
{
   if(g_confirmArmed && TimeCurrent() - g_confirmTime > HK_CONFIRM_WINDOW_SEC)
      g_confirmArmed = false;
   if(g_trailingOn) g_trail.Process(g_trade);
   RefreshPanel();
}
```

Recompile (F7). Expected: 0 errors.

- [ ] **Step 4: Commit**

```bash
git add MQL5/Experts/HotkeysEA/HotkeysEA.mq5
git commit -m "feat: add main EA wiring, event handling, close-all confirmation"
```

---

### Task 10: Integration testing + README

**Files:**
- Create: `README.md`

**Interfaces:**
- Consumes: the compiled EA and test script.
- Produces: install/usage docs; a verified EA.

- [ ] **Step 1: Run the pure-logic test harness**

In MT5, drag `HotkeysEA_Tests` script onto any chart.
Expected in Experts tab: `==== RESULT: 31 passed, 0 failed ====`.

- [ ] **Step 2: Strategy Tester verification (visual mode)**

Open Strategy Tester, select `HotkeysEA`, a symbol (e.g. EURUSD), Visual mode ON. With the tester chart focused and NumLock ON, verify each hotkey against the checklist below. Record pass/fail.

- [ ] `1` opens a buy at current lot with SL/TP (when SL/TP ON)
- [ ] `2` opens a sell with SL/TP
- [ ] `+` / `-` change lot by 0.01; `0` resets to 0.01; cannot exceed 1.00; cannot go below broker min
- [ ] `9` toggles SL/TP (panel reflects ON/OFF); new entries respect it
- [ ] `3` closes only profitable positions
- [ ] `4` closes the most recent position
- [ ] `5` closes half of the most recent position
- [ ] `6` reverses net direction
- [ ] `7` moves SL of all matching positions to breakeven
- [ ] `8` toggles trailing; with it ON, SL tightens as price moves in profit
- [ ] `*` / `/` place pending buy/sell orders at the configured distance/type
- [ ] `.` deletes all pending orders for the symbol
- [ ] `Enter` arms confirmation (panel hint shows), second `Enter` within 3s closes all; confirmation auto-cancels after 3s; other keys cancel it
- [ ] With `InpConfirmCloseAll=false`, `Enter` closes all immediately
- [ ] Positions/orders from a different magic number are never touched

- [ ] **Step 2b: Fix any failures**

If a checklist item fails, fix the responsible module, recompile, commit with a `fix:` message, and re-run the affected check. Do not proceed to Step 3 until all items pass.

- [ ] **Step 3: Write the README**

```markdown
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
```

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: add install/usage README and verify integration"
```

- [ ] **Step 5: Merge to main (after all checks pass)**

```bash
git checkout main
git merge --no-ff development -m "release: Hotkeys EA v1.00"
git checkout development
```

---

## Self-Review

**1. Spec coverage:**
- Hotkey map (16 keys) — Tasks 2, 6, 9. Covered.
- Active-symbol + magic filtering — Tasks 5, 6, 7. Covered.
- Lot default/step/cap/min-clamp — Tasks 3, 4. Covered.
- SL/TP in points + toggle — Tasks 3, 6, 9. Covered.
- Trailing toggle in OnTick — Tasks 7, 9. Covered.
- Pending STOP/LIMIT via input + distance — Task 6. Covered.
- Close All confirmation (2x, 3s window, cancelable) — Task 9. Covered.
- Reverse with no position -> open — Task 6. Covered.
- SL/TP / pending normalized to stops level — Task 6. Covered.
- Panel showing lot/SL-TP/trailing/PL/count — Tasks 8, 9. Covered.
- Testing (harness + Strategy Tester) — Tasks 2, 3, 10. Covered.
- Branch strategy (merge to main) — Task 10. Covered.

**2. Placeholder scan:** No TBD/TODO; every code step has complete code; commands have expected output. Clear.

**3. Type consistency:** `HK_MapKey`, `HK_ClampLot`, `HK_CalcEntrySL/TP`, `HK_CalcPendingPrice`, `CLotManager.Current/Increase/Decrease/Reset/Broker`, `CPositionFilter.LastTicket/NetDirection/Count/TotalProfit`, `CTradeExecutor.OpenMarket/CloseAll/CloseProfit/CloseLast/CloseHalf/Reverse/MoveToBreakeven/PlacePending/DeletePending/UseSLTP/SetUseSLTP`, `CTrailingManager.Process`, `CPanel.Create/Update/Destroy` — names used consistently across Tasks 6/7/8/9. Consistent.

**Fix applied during review:** `CTradeExecutor::Reverse` had redundant/contradictory `newDir` assignments; simplified to `newDir = (dir > 0) ? -1 : 1` (long -> short; short/none -> long) in the Task 6 code.


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

void OnStart()
{
   g_pass = 0; g_fail = 0;
   TestKeyMap();
   TestMathUtils(); // defined in Task 3
   PrintFormat("==== RESULT: %d passed, %d failed ====", g_pass, g_fail);
}

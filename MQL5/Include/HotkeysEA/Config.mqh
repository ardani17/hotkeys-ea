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

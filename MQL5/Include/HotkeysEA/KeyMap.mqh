//+------------------------------------------------------------------+
//| KeyMap.mqh - numpad keycode to action mapping (pure)             |
//+------------------------------------------------------------------+
#ifndef HK_KEYMAP_MQH
#define HK_KEYMAP_MQH
#include <HotkeysEA/Config.mqh>

// Extract virtual key from CHARTEVENT_KEYDOWN lparam (low 16 bits)
int HK_ExtractKeyCode(const long lparam)
{
   return (int)(lparam & 0xFFFF);
}

ENUM_HK_ACTION HK_MapKey(const int key)
{
   switch(key)
   {
      // NumLock ON — numpad digits
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
      // NumLock OFF — same numpad keys send navigation codes
      case HK_VK_NL_END:   return HK_BUY;
      case HK_VK_NL_DOWN:  return HK_SELL;
      case HK_VK_NL_PGDN:  return HK_CLOSE_PROFIT;
      case HK_VK_NL_LEFT:  return HK_CLOSE_LAST;
      case HK_VK_NL_CLEAR: return HK_CLOSE_HALF;
      case HK_VK_NL_RIGHT: return HK_REVERSE;
      case HK_VK_NL_HOME:  return HK_BREAKEVEN;
      case HK_VK_NL_UP:    return HK_TOGGLE_TRAIL;
      case HK_VK_NL_PGUP:  return HK_TOGGLE_SLTP;
      case HK_VK_NL_INS:   return HK_RESET_LOT;
      // Operators (same in both NumLock states on Windows)
      case HK_VK_ADD:      return HK_LOT_UP;
      case HK_VK_SUBTRACT: return HK_LOT_DOWN;
      case HK_VK_MULTIPLY: return HK_BUY_PENDING;
      case HK_VK_DIVIDE:   return HK_SELL_PENDING;
      case HK_VK_DECIMAL:  return HK_DELETE_PENDING;
      case HK_VK_NL_DEL:   return HK_DELETE_PENDING;
      case HK_VK_RETURN:   return HK_CLOSE_ALL;
      default:             return HK_NONE;
   }
}

// All virtual keys we poll via TerminalInfoInteger(TERMINAL_KEYSTATE)
static const int HK_POLL_KEYS[] =
{
   HK_VK_0, HK_VK_1, HK_VK_2, HK_VK_3, HK_VK_4,
   HK_VK_5, HK_VK_6, HK_VK_7, HK_VK_8, HK_VK_9,
   HK_VK_NL_INS, HK_VK_NL_END, HK_VK_NL_DOWN, HK_VK_NL_PGDN,
   HK_VK_NL_LEFT, HK_VK_NL_CLEAR, HK_VK_NL_RIGHT,
   HK_VK_NL_HOME, HK_VK_NL_UP, HK_VK_NL_PGUP,
   HK_VK_ADD, HK_VK_SUBTRACT, HK_VK_MULTIPLY, HK_VK_DIVIDE,
   HK_VK_DECIMAL, HK_VK_NL_DEL, HK_VK_RETURN
};

#endif // HK_KEYMAP_MQH

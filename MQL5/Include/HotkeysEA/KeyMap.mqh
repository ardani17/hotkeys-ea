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

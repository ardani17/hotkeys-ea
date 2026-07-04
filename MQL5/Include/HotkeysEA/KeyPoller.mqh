//+------------------------------------------------------------------+
//| KeyPoller.mqh - poll TERMINAL_KEYSTATE for hotkey edge detection |
//+------------------------------------------------------------------+
#ifndef HK_KEYPOLLER_MQH
#define HK_KEYPOLLER_MQH
#include <HotkeysEA/KeyMap.mqh>

class CKeyPoller
{
private:
   bool m_wasDown[256];

   bool IsDown(const int vk)
   {
      if(vk < 0 || vk > 255) return false;
      return (TerminalInfoInteger(TERMINAL_KEYSTATE, vk) == 1);
   }
public:
   void Reset()
   {
      for(int i = 0; i < 256; i++)
         m_wasDown[i] = false;
   }

   // Returns action on new key press (rising edge), else HK_NONE
   ENUM_HK_ACTION Poll()
   {
      const int n = ArraySize(HK_POLL_KEYS);
      for(int i = 0; i < n; i++)
      {
         const int vk = HK_POLL_KEYS[i];
         if(vk < 0 || vk > 255) continue;

         const bool down = IsDown(vk);
         if(down && !m_wasDown[vk])
         {
            m_wasDown[vk] = true;
            ENUM_HK_ACTION action = HK_MapKey(vk);
            if(action != HK_NONE) return action;
         }
         if(!down)
            m_wasDown[vk] = false;
      }
      return HK_NONE;
   }
};

#endif // HK_KEYPOLLER_MQH

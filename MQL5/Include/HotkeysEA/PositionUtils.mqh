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

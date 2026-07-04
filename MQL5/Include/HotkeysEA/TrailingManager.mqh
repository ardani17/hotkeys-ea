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

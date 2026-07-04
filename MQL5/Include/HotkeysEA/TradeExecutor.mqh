//+------------------------------------------------------------------+
//| TradeExecutor.mqh - trade actions scoped to symbol + magic       |
//+------------------------------------------------------------------+
#ifndef HK_TRADEEXECUTOR_MQH
#define HK_TRADEEXECUTOR_MQH
#include <Trade/Trade.mqh>
#include <HotkeysEA/Config.mqh>
#include <HotkeysEA/MathUtils.mqh>
#include <HotkeysEA/PositionUtils.mqh>

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

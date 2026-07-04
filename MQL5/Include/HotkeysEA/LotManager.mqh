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

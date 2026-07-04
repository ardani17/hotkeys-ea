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

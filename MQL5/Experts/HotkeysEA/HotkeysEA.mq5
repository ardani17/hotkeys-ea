//+------------------------------------------------------------------+
//| HotkeysEA.mq5 - numpad quick-execution EA for MT5                |
//+------------------------------------------------------------------+
#property copyright "ardani17"
#property link      "https://github.com/ardani17/hotkeys-ea"
#property version   "1.00"
#property strict

#include <HotkeysEA/Config.mqh>
#include <HotkeysEA/KeyMap.mqh>
#include <HotkeysEA/MathUtils.mqh>
#include <HotkeysEA/LotManager.mqh>
#include <HotkeysEA/PositionUtils.mqh>
#include <HotkeysEA/TradeExecutor.mqh>
#include <HotkeysEA/TrailingManager.mqh>
#include <HotkeysEA/Panel.mqh>
#include <Trade/Trade.mqh>

CLotManager      g_lot;
CPositionFilter  g_pos;
CTradeExecutor   g_exec;
CTrailingManager g_trail;
CPanel           g_panel;
CTrade           g_trade;

bool     g_trailingOn   = false;
bool     g_confirmArmed = false;
datetime g_confirmTime  = 0;

void RefreshPanel();

int OnInit()
{
   g_lot.Init(_Symbol, InpDefaultLot, InpLotStep, InpMaxLot);
   g_pos.Init(_Symbol, InpMagicNumber);
   g_exec.Init(_Symbol, InpMagicNumber, InpSlippagePts, InpUseSLTP,
               InpStopLossPts, InpTakeProfitPts, InpPendingDistPts, InpPendingType);
   g_trail.Init(_Symbol, InpMagicNumber, InpTrailingPts, InpTrailingStep);
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippagePts);
   g_panel.Create(ChartID(), InpPanelCorner);
   RefreshPanel();
   ChartSetInteger(ChartID(), CHART_KEYBOARD_CONTROL, true);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   g_panel.Destroy();
}

void OnTick()
{
   if(g_confirmArmed && TimeCurrent() - g_confirmTime > HK_CONFIRM_WINDOW_SEC)
      g_confirmArmed = false;
   if(g_trailingOn) g_trail.Process(g_trade);
   RefreshPanel();
}

void RefreshPanel()
{
   g_panel.Update(g_lot.Current(), g_exec.UseSLTP(), g_trailingOn,
                  g_confirmArmed, g_pos.TotalProfit(), g_pos.Count());
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id != CHARTEVENT_KEYDOWN) return;
   ENUM_HK_ACTION action = HK_MapKey(lparam);
   if(action == HK_NONE) return;

   // Close-All confirmation window handling
   if(action == HK_CLOSE_ALL)
   {
      if(InpConfirmCloseAll && !g_confirmArmed)
      {
         g_confirmArmed = true;
         g_confirmTime  = TimeCurrent();
         RefreshPanel();
         return;
      }
      g_confirmArmed = false;
      g_exec.CloseAll();
      RefreshPanel();
      return;
   }
   // Any other key cancels a pending confirmation
   g_confirmArmed = false;

   switch(action)
   {
      case HK_BUY:            g_exec.OpenMarket(1, g_lot.Current());  break;
      case HK_SELL:           g_exec.OpenMarket(-1, g_lot.Current()); break;
      case HK_CLOSE_PROFIT:   g_exec.CloseProfit();                   break;
      case HK_CLOSE_LAST:     g_exec.CloseLast(g_pos);                break;
      case HK_CLOSE_HALF:     g_exec.CloseHalf(g_pos);                break;
      case HK_REVERSE:        g_exec.Reverse(g_pos, g_lot.Current()); break;
      case HK_BREAKEVEN:      g_exec.MoveToBreakeven();               break;
      case HK_TOGGLE_TRAIL:   g_trailingOn = !g_trailingOn;           break;
      case HK_TOGGLE_SLTP:    g_exec.SetUseSLTP(!g_exec.UseSLTP());   break;
      case HK_RESET_LOT:      g_lot.Reset();                          break;
      case HK_LOT_UP:         g_lot.Increase();                       break;
      case HK_LOT_DOWN:       g_lot.Decrease();                       break;
      case HK_BUY_PENDING:    g_exec.PlacePending(1, g_lot.Current());  break;
      case HK_SELL_PENDING:   g_exec.PlacePending(-1, g_lot.Current()); break;
      case HK_DELETE_PENDING: g_exec.DeletePending();                 break;
      default: break;
   }
   RefreshPanel();
}

void OnTimer() {}

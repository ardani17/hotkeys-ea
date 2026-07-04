//+------------------------------------------------------------------+
//| HotkeysEA.mq5 - numpad quick-execution EA for MT5                |
//+------------------------------------------------------------------+
#property copyright "ardani17"
#property link      "https://github.com/ardani17/hotkeys-ea"
#property version   "1.01"

#include <HotkeysEA/Config.mqh>

// Inputs must live in the main EA file (MQL5 does not allow input in shared includes)
input double           InpDefaultLot      = 0.01;            // Default / reset lot
input double           InpLotStep         = 0.01;            // Lot step for +/-
input double           InpMaxLot          = 1.00;            // Max lot cap
input long             InpMagicNumber     = 20260704;        // Magic number filter
input bool             InpUseSLTP         = true;            // Use SL/TP on entry
input int              InpStopLossPts     = 200;             // Stop Loss (points)
input int              InpTakeProfitPts   = 400;             // Take Profit (points)
input int              InpTrailingPts     = 150;             // Trailing distance (points)
input int              InpTrailingStep    = 50;              // Trailing step (points)
input int              InpPendingDistPts  = 100;             // Pending distance (points)
input ENUM_HK_PENDING  InpPendingType     = HK_PENDING_STOP; // Pending type
input bool             InpConfirmCloseAll = true;            // Confirm before Close All
input int              InpSlippagePts     = 30;              // Max deviation (points)
input ENUM_BASE_CORNER InpPanelCorner     = CORNER_LEFT_UPPER; // Panel corner
input bool             InpDebugKeys       = false;           // Log key presses to Experts tab

#include <HotkeysEA/KeyMap.mqh>
#include <HotkeysEA/KeyPoller.mqh>
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
CKeyPoller       g_keys;

bool     g_trailingOn   = false;
bool     g_confirmArmed = false;
datetime g_confirmTime  = 0;
string   g_lastKeyLabel = "";

string ActionLabel(const ENUM_HK_ACTION action)
{
   switch(action)
   {
      case HK_BUY:            return "BUY";
      case HK_SELL:           return "SELL";
      case HK_CLOSE_PROFIT:   return "CLOSE PROFIT";
      case HK_CLOSE_LAST:     return "CLOSE LAST";
      case HK_CLOSE_HALF:     return "CLOSE HALF";
      case HK_REVERSE:        return "REVERSE";
      case HK_BREAKEVEN:      return "BREAKEVEN";
      case HK_TOGGLE_TRAIL:   return "TOGGLE TRAIL";
      case HK_TOGGLE_SLTP:    return "TOGGLE SL/TP";
      case HK_RESET_LOT:      return "RESET LOT";
      case HK_LOT_UP:         return "LOT +";
      case HK_LOT_DOWN:       return "LOT -";
      case HK_BUY_PENDING:    return "BUY PENDING";
      case HK_SELL_PENDING:   return "SELL PENDING";
      case HK_DELETE_PENDING: return "DEL PENDING";
      case HK_CLOSE_ALL:      return "CLOSE ALL";
      default:                return "";
   }
}

bool TradeAllowed()
{
   return (TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) != 0 &&
           MQLInfoInteger(MQL_TRADE_ALLOWED) != 0);
}

void RefreshPanel()
{
   g_panel.Update(g_lot.Current(), g_exec.UseSLTP(), g_trailingOn,
                  g_confirmArmed, g_pos.TotalProfit(), g_pos.Count(),
                  g_lastKeyLabel, TradeAllowed());
}

void ExecuteAction(const ENUM_HK_ACTION action)
{
   if(action == HK_NONE) return;

   g_lastKeyLabel = ActionLabel(action);
   if(InpDebugKeys)
      PrintFormat("HotkeysEA: action=%s lot=%.2f", g_lastKeyLabel, g_lot.Current());

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

int OnInit()
{
   g_lot.Init(_Symbol, InpDefaultLot, InpLotStep, InpMaxLot);
   g_pos.Init(_Symbol, InpMagicNumber);
   g_exec.Init(_Symbol, InpMagicNumber, InpSlippagePts, InpUseSLTP,
               InpStopLossPts, InpTakeProfitPts, InpPendingDistPts, InpPendingType);
   g_trail.Init(_Symbol, InpMagicNumber, InpTrailingPts, InpTrailingStep);
   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpSlippagePts);
   g_keys.Reset();
   g_panel.Create(ChartID(), InpPanelCorner);
   ChartSetInteger(ChartID(), CHART_KEYBOARD_CONTROL, true);
   EventSetMillisecondTimer(50);
   RefreshPanel();
   Print("HotkeysEA v1.01 ready — numpad polling active (NumLock ON or OFF)");
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   g_panel.Destroy();
}

void OnTick()
{
   if(g_confirmArmed && TimeCurrent() - g_confirmTime > HK_CONFIRM_WINDOW_SEC)
      g_confirmArmed = false;
   if(g_trailingOn) g_trail.Process(g_trade);
   RefreshPanel();
}

void OnTimer()
{
   ENUM_HK_ACTION action = g_keys.Poll();
   if(action != HK_NONE)
      ExecuteAction(action);
}

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id != CHARTEVENT_KEYDOWN) return;

   const int vk = HK_ExtractKeyCode(lparam);
   if(InpDebugKeys)
      PrintFormat("HotkeysEA: CHARTEVENT_KEYDOWN vk=%d", vk);

   ENUM_HK_ACTION action = HK_MapKey(vk);
   if(action != HK_NONE)
      ExecuteAction(action);
}

//+------------------------------------------------------------------+
//| Panel.mqh - on-chart status labels                               |
//+------------------------------------------------------------------+
#ifndef HK_PANEL_MQH
#define HK_PANEL_MQH

class CPanel
{
private:
   long             m_chart;
   ENUM_BASE_CORNER m_corner;
   string           m_prefix;
   int              m_xoff;
   int              m_yoff;
   int              m_lineH;

   void SetLabel(const string key, const string text, const color clr, const int line)
   {
      string name = m_prefix + key;
      if(ObjectFind(m_chart, name) < 0)
      {
         ObjectCreate(m_chart, name, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(m_chart, name, OBJPROP_CORNER, m_corner);
         ObjectSetInteger(m_chart, name, OBJPROP_XDISTANCE, m_xoff);
         ObjectSetInteger(m_chart, name, OBJPROP_YDISTANCE, m_yoff + line * m_lineH);
         ObjectSetInteger(m_chart, name, OBJPROP_FONTSIZE, 10);
         ObjectSetString(m_chart, name, OBJPROP_FONT, "Consolas");
         ObjectSetInteger(m_chart, name, OBJPROP_SELECTABLE, false);
      }
      ObjectSetString(m_chart, name, OBJPROP_TEXT, text);
      ObjectSetInteger(m_chart, name, OBJPROP_COLOR, clr);
   }
public:
   void Create(const long chartId, const ENUM_BASE_CORNER corner)
   {
      m_chart  = chartId;
      m_corner = corner;
      m_prefix = "HKPANEL_";
      m_xoff   = 12;
      m_yoff   = 20;
      m_lineH  = 18;
   }

   void Update(const double lot, const bool useSLTP, const bool trailingOn,
               const bool confirmPending, const double floatPL, const int posCount)
   {
      SetLabel("title", "== HOTKEYS EA ==", clrWhite, 0);
      SetLabel("lot",   StringFormat("Lot     : %.2f", lot), clrGold, 1);
      SetLabel("sltp",  StringFormat("SL/TP   : %s", useSLTP ? "ON" : "OFF"),
               useSLTP ? clrLime : clrTomato, 2);
      SetLabel("trail", StringFormat("Trailing: %s", trailingOn ? "ON" : "OFF"),
               trailingOn ? clrLime : clrTomato, 3);
      SetLabel("pos",   StringFormat("Posisi  : %d", posCount), clrSilver, 4);
      SetLabel("pl",    StringFormat("Float PL: %.2f", floatPL),
               floatPL >= 0 ? clrLime : clrTomato, 5);
      SetLabel("hint",  confirmPending ? ">> ENTER lagi utk CLOSE ALL <<" : "",
               clrYellow, 6);
      ChartRedraw(m_chart);
   }

   void Destroy()
   {
      ObjectsDeleteAll(m_chart, m_prefix);
      ChartRedraw(m_chart);
   }
};

#endif // HK_PANEL_MQH

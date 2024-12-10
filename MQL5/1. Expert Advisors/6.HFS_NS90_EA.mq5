//+------------------------------------------------------------------+
//|                                                     RSI-EA01.mq5 |
//|                                      Santiago Cruz, AlgoNet Inc. |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz, AlgoNet Inc."
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

input group "=== Trading Inputs ==="

input string TradeComment     = "Scalping NS90 EA";

input int    InpMagic         = 902563; //EA Magic Number
input double RiskPercent      = 3;      //Risk as % of Trading Capital
input int    TPpoints         = 200;    //Take Profit (10 Points = 1 Pip)
input int    SLPoint          = 200;    //Stop Loss Points (10 Points = 1 Pip)
input int    TslTriggerPoints = 15;     //Points in Profits before Trailing SL is activated (10 Points = 1 Pip)
input int    TslPoints        = 10;     //Trailing Stop Loss (10 Points = 1 Pip)

input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;

enum StartHour
  {
   Inactive=0, _0100=1, _0200=2, _0300=3, _0400=4, _0500=5, _0600=6, _0700=7,_0800=8,_0900=9, _1000=10, _1100=11, _1200=12
  };

input StartHour SHInput=0;    //Start Hour

enum EndHour
  {
   Inactive=0, _1300=13, _1400=14, _1500=15, _1600=16, _1700=17, _1800=18,_1900=19, _2000=20, _2100=21, _2200=22, _2300=23
  };

input EndHour EHInput=0;      //End Hour

int SHChoice;
int EHChoice;

int BarsN = 5;
int ExpirationBars = 100;
int OrderDistPoints = 100;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

  }

//+------------------------------------------------------------------+
//|Finding High Points in Bars                                       |
//+------------------------------------------------------------------+
double findHigh()
  {
   double highestHigh = 0;
   for(int i=0; i<200; i++)
     {
      double high = iHigh(_Symbol,Timeframe,i);
      if(i > BarsN && iHighest(_Symbol,Timeframe,MODE_HIGH,BarsN*2+1,i-BarsN) == i)
        {
         if(high > highestHigh)
           {
            return high;
           }
        }
      highestHigh = MathMax(high,highestHigh);
     }
   return -1;
  }

//+------------------------------------------------------------------+
//|Finding Low Points in Bars                                       |
//+------------------------------------------------------------------+
double findLow()
  {
   double lowestLow = DBL_MAX;
   for(int i=0; i<200; i++)
     {
      double low = iLow(_Symbol,Timeframe,i);
      if(i > BarsN && iLowest(_Symbol,Timeframe,MODE_HIGH,BarsN*2+1,i-BarsN) == i)
        {
         if(low < lowestLow)
           {
            return low;
           }
        }
      lowestLow = MathMin(low,lowestLow);
     }
   return -1;
  }

//+------------------------------------------------------------------+
//|Checking for New Bars                                             |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   static datetime previousTime = 0;
   datetime currentTime = iTime(_Symbol,PERIOD_CURRENT,0);
   if(previousTime!=currentTime)
     {
      previousTime=currentTime;
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|Sending Buy Orders                                                |
//+------------------------------------------------------------------+
void SendBuyOrder(double entry){
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   
   if(ask > entry - OrderDistPoints * _Point)
     {
      return;
     }
   double tp = entry + TPpoints * _Point;
   double sl = entry - SLPoints * _Point;
}

//+------------------------------------------------------------------+
//|Calculation of Lot Size                                           |
//+------------------------------------------------------------------+
double calcLots(double slPoints){
   double risk = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercent /100;
   
   double ticksize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickvalue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double lotstep = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double minvolume = SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   double maxvolume = SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   double volumelimit = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_LIMIT);
   
   
   
   return lots;
}

//+------------------------------------------------------------------+

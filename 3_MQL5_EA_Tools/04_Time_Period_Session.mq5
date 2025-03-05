//+------------------------------------------------------------------+
//|                                        4.Time_Period_Session.mq5 |
//|                                      Santiago Cruz, AlgoNet Inc. |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz, AlgoNet Inc."
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

enum TradingHour
  {
   Inactive=0, _0100=1, _0200=2, _0300=3, _0400=4, _0500=5, _0600=6, _0700=7,_0800=8,_0900=9, _1000=10, _1100=11, _1200=12, _1300=13, _1400=14, _1500=15, _1600=16, _1700=17, _1800=18,_1900=19, _2000=20, _2100=21, _2200=22, _2300=23
  };

input group "=== Trading Period ==="
   input TradingHour StartHour = 0; //Start Hour
   input TradingHour EndHour  = 0;  //End Hour

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
   MqlDateTime time;
   TimeToStruct(TimeCurrent(),time);
   int HourNow = time.hour;
   
   if(HourNow < StartHour)
     {
      Comment("Trading Disabled");
      return;
     }
     
   if(HourNow>=EndHour && EndHour!=0)
     {
      Comment("Trading Disabled");
      return;
     }
   
   //This is the part of the code where we want the EA to run, between the time set period
   Comment("Trading Enabled");
  }
//+------------------------------------------------------------------+

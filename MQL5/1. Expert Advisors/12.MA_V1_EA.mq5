//+------------------------------------------------------------------+
//|                                                  12.MA_V1_EA.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

input group "=== Trading Inputs ==="
input string          TradeComment     = "MA EA";
static input long     EA_Magic         = 250116;
static input double   LotSize          = 0.01;
input  int            Stop_Loss        = 150;    //Stop Loss In Points
input  int            Take_Profit      = 250;    //Take Profit In Points
input int             MA_FastPeriod    = 14;     //MA Fast Period
input int             MA_SlowPeriod    = 21;     //MA Slow Period 

//---Global Variables
int MA_fastHandle;
int MA_slowHandle;
double MA_fastBuffer[];
double MA_slowBuffer[];
CTrade trade;
datetime openTimeBuy  = 0;
datetime openTimeSell  = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---Check if the User Enter Correct Inputs
   if(MA_FastPeriod <= 0 && MA_SlowPeriod <=0 && MA_FastPeriod >= MA_SlowPeriod)
     {
      Alert("Incorrect MA Parameters.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(Take_Profit <= 0 && Stop_Loss <= 0)
     {
      Alert("Incorrect TP and SL Parameters.");
      return INIT_PARAMETERS_INCORRECT;      
     }
     
//---MA Handles   
   MA_fastHandle = iMA(_Symbol,PERIOD_CURRENT,MA_FastPeriod,0,MODE_SMA,PRICE_CLOSE);
   if(MA_fastHandle == INVALID_HANDLE)
     {
      Alert("Failed to create MA Fast Handle.");
      return INIT_FAILED;
     }
   
   MA_slowHandle = iMA(_Symbol,PERIOD_CURRENT,MA_SlowPeriod,0,MODE_SMA,PRICE_CLOSE);
   if(MA_slowHandle == INVALID_HANDLE)
     {
      Alert("Failed to create MA Slow Handle.");
      return INIT_FAILED;
     }
   
   ArraySetAsSeries(MA_fastBuffer,true);
   ArraySetAsSeries(MA_slowBuffer,true);
   
   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(MA_fastHandle != INVALID_HANDLE)
     {
      IndicatorRelease(MA_fastHandle);
     }
   if(MA_slowHandle != INVALID_HANDLE)
     {
      IndicatorRelease(MA_slowHandle);
     }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   int value1 = CopyBuffer(MA_fastHandle,0,0,2,MA_fastBuffer);
   if(value1 != 2)
     {
      Print("Not Enough Data for Fast Moving Average.");
      return;
     }
   int value2 = CopyBuffer(MA_slowHandle,0,0,2,MA_slowBuffer);
   if(value2 != 2)
     {
      Print("Not Enough Data for Slow Moving Average.");
      return;
     }
     
   Comment("MA Fast[0]:",MA_fastBuffer[0],"\n",
           "MA Fast[1]:",MA_fastBuffer[1],"\n",
           "MA Slow[0]:",MA_slowBuffer[0],"\n",
           "MA Slow[1]:",MA_slowBuffer[1]);
 
//---Check for MA Cross Buy        
   if(MA_fastBuffer[1] <= MA_slowBuffer[1] && MA_fastBuffer[0] > MA_slowBuffer[0] && openTimeBuy != iTime(_Symbol,PERIOD_CURRENT,0))
     {
      openTimeBuy = iTime(_Symbol,PERIOD_CURRENT,0);
      double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      double SL = ask - Stop_Loss*SymbolInfoDouble(_Symbol,SYMBOL_POINT);      
      double TP = ask + Take_Profit*SymbolInfoDouble(_Symbol,SYMBOL_POINT);
      
      trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,LotSize,ask,SL,TP,TradeComment);
     }
//---Check for MA Cross Sell        
   if(MA_fastBuffer[1] >= MA_slowBuffer[1] && MA_fastBuffer[0] < MA_slowBuffer[0] && openTimeSell != iTime(_Symbol,PERIOD_CURRENT,0))
     {
      openTimeSell = iTime(_Symbol,PERIOD_CURRENT,0);
      double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double SL = bid + Stop_Loss*SymbolInfoDouble(_Symbol,SYMBOL_POINT);      
      double TP = bid - Take_Profit*SymbolInfoDouble(_Symbol,SYMBOL_POINT);
            
      trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,LotSize,bid,SL,TP,TradeComment);
     }
   
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                               17.Ichi_ATR_EA.mq5 |
//|                                      Santiago Cruz, AlgoNet Inc. |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz, AlgoNet Inc."
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

#include <Trade/Trade.mqh>

input group "=== Trading Inputs ==="

input  string            TradeComment   = "Ichi_ATR_EA";
static input long        EA_Magic       = 237925;       //Magic Number
input  double            LotSize        = 0.5;

input  int               ATR_Period     = 14;           //ATR Period for Dynamic SL and TP
input  double            ATR_SLFactor   = 1.0;
input  double            ATR_TPFactor   = 1.0;
input  ENUM_TIMEFRAMES   ATR_TimeFrame  = PERIOD_CURRENT;

input  ENUM_TIMEFRAMES   Ichi_Period    = PERIOD_CURRENT; 
input  int               Tenkan_Sen     = 9;            // period of Tenkan-sen 
input  int               Kijun_Sen      = 21;           // period of Kijun-sen 
input  int               Senkou_SpanB   = 52;           // period of Senkou Span B

input  int               Slippage       = 30;


//---Global Variables
int ATR_Handle, Ichimoku_Handle;

double ATR_Buffer[];

datetime timestamp;

CTrade   trade;

int OnInit()
  {
   ATR_Handle = iATR(Symbol(),ATR_TimeFrame,ATR_Period);
   if(ATR_Handle == INVALID_HANDLE)
     {
      Alert("Failed to create ATR Indicator Handle: ", GetLastError());
      return INIT_FAILED;
     }

   Ichimoku_Handle = iIchimoku(Symbol(),Ichi_Period,Tenkan_Sen,Kijun_Sen,Senkou_SpanB);
   if(Ichimoku_Handle == INVALID_HANDLE)
     {
      Alert("Failed to create Ichimoku Indicator Handle: ", GetLastError());
      return INIT_FAILED;
     }
     
   ArraySetAsSeries(ATR_Buffer,true);
   
   trade.SetDeviationInPoints(Slippage);
   trade.SetExpertMagicNumber(EA_Magic);
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   IndicatorRelease(ATR_Handle);
   IndicatorRelease(Ichimoku_Handle);
  }

void OnTick()
  {  
   if(!IsNewBar()){return;}

   double tenkanSen[], kijunSen[], SenkouSpanA[], SenkouSpanB[], ChikousSpan[];   
   CopyBuffer(Ichimoku_Handle,TENKANSEN_LINE,1,2,tenkanSen);
   CopyBuffer(Ichimoku_Handle,KIJUNSEN_LINE,1,2,kijunSen);
   CopyBuffer(Ichimoku_Handle,SENKOUSPANA_LINE,1,2,SenkouSpanA);
   CopyBuffer(Ichimoku_Handle,SENKOUSPANB_LINE,1,2,SenkouSpanB);
   CopyBuffer(Ichimoku_Handle,CHIKOUSPAN_LINE,1,2,ChikousSpan);
   
   CopyBuffer(ATR_Handle,MAIN_LINE,1,1,ATR_Buffer);
   
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   
   if(tenkanSen[1]>kijunSen[1] && tenkanSen[0]<=kijunSen[0])
     {
      double sl = ask - ATR_Buffer[0]*ATR_SLFactor;
      double tp = ask + ATR_Buffer[0]*ATR_TPFactor;
      trade.Buy(LotSize,_Symbol,ask,sl,tp,TradeComment);
     }
   else
     if(tenkanSen[1]<kijunSen[1] && tenkanSen[0]>=kijunSen[0])
       {
        double sl = bid + ATR_Buffer[0]*ATR_SLFactor;
        double tp = bid - ATR_Buffer[0]*ATR_TPFactor;
        trade.Sell(LotSize,_Symbol,ask,sl,tp,TradeComment);
       }
  }

bool IsNewBar()
  {
   static datetime previousTime = 0;
   datetime currentTime = iTime(Symbol(),Period(),0);
   if(previousTime == currentTime) return false;  
   previousTime = currentTime;
   return true;
  }

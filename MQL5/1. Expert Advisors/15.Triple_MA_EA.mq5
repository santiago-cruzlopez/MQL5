//+------------------------------------------------------------------+
//|                                               15.Three_MA_EA.mq5 |
//|                                      Santiago Cruz, AlgoNet Inc. |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz, AlgoNet Inc."
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

#include <Trade\Trade.mqh>

input group "=== Trading Inputs ==="

input string             TradeComment   = "Triple MA EA";
static input long        EA_Magic       = 250120;       //Magic Number
input double             TP_Ratio       = 1.0;          //Take Profit : Stop Loss
input double             Inp_Volume     = 0.01;         //Trade Volume

input int                MAVG1_FastB    = 10;           //Fast MA Bars
input ENUM_MA_METHOD     MAVG1_Method   = MODE_EMA;     //Fast MA Method
input ENUM_APPLIED_PRICE MAVG1_Price    = PRICE_CLOSE;  //Fast MA Applied Price   

input int                MAVG2_MainB    = 30;           //Main MA Bars
input ENUM_MA_METHOD     MAVG2_Method   = MODE_EMA;     //Main MA Method
input ENUM_APPLIED_PRICE MAVG2_Price    = PRICE_CLOSE;  //Main MA Applied Price 

input int                MAVG3_SlowB    = 60;           //Slow MA Bars
input ENUM_MA_METHOD     MAVG3_Method   = MODE_EMA;     //Slow MA Method
input ENUM_APPLIED_PRICE MAVG3_Price    = PRICE_CLOSE;  //Slow MA Applied Price 

//---Global Variables
int MAVG1_Handle;
int MAVG2_Handle;
int MAVG3_Handle;
CTrade trade;

int OnInit()
  {
   MAVG1_Handle = iMA(Symbol(), Period(), MAVG1_FastB, 0, MAVG1_Method, MAVG1_Price);
   MAVG2_Handle = iMA(Symbol(), Period(), MAVG2_MainB, 0, MAVG2_Method, MAVG2_Price);
   MAVG3_Handle = iMA(Symbol(), Period(), MAVG3_SlowB, 0, MAVG3_Method, MAVG3_Price);
   
   if(MAVG1_Handle == INVALID_HANDLE || MAVG2_Handle == INVALID_HANDLE || MAVG3_Handle == INVALID_HANDLE)
     {
      Alert("Failed to create MAVG Handle.");
      return INIT_FAILED;      
     }
   
   trade.SetExpertMagicNumber(EA_Magic);
   
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason)
  {
   IndicatorRelease(MAVG1_Handle);
   IndicatorRelease(MAVG2_Handle);
   IndicatorRelease(MAVG3_Handle);
  }

void OnTick()
  {
   datetime currentBarTime = iTime(Symbol(),Period(),0);
   static datetime previousBarTime = currentBarTime;
   if(previousBarTime == currentBarTime) return;
   previousBarTime = currentBarTime;
   
   double MAVG1_Values[]; //Fast MAVG1 Values
   double MAVG2_Values[]; //Main MAVG2 Values
   double MAVG3_Values[]; //Slow MAVG3 Values
   
   if(CopyBuffer(MAVG1_Handle,0,0,3,MAVG1_Values)<3) return;
   if(CopyBuffer(MAVG2_Handle,0,0,3,MAVG2_Values)<3) return;
   if(CopyBuffer(MAVG3_Handle,0,0,3,MAVG3_Values)<3) return;
   
   ArraySetAsSeries(MAVG1_Values,true);
   ArraySetAsSeries(MAVG2_Values,true);
   ArraySetAsSeries(MAVG3_Values,true);
   
   MqlTick tickValues;
   if(!SymbolInfoTick(Symbol(),tickValues))
     {
      return;
     }
   
   double openPrice;
   double StopLossPrice;
   double TakeProfitPrice;
   ENUM_ORDER_TYPE orderType;
   
   if(MAVG2_Values[1]>MAVG3_Values[1] && MAVG1_Values[2]<MAVG2_Values[2] && MAVG1_Values[1]>=MAVG2_Values[1])
     {
      orderType = ORDER_TYPE_BUY;
      openPrice = tickValues.ask;  
     } else       
     if(MAVG2_Values[1]<MAVG3_Values[1] && MAVG1_Values[2]>MAVG2_Values[2] && MAVG1_Values[1]<=MAVG2_Values[1])
     {
      orderType = ORDER_TYPE_SELL;
      openPrice = tickValues.bid;   
     } else return;
   
   StopLossPrice   = MAVG2_Values[1];
   TakeProfitPrice = openPrice + (TP_Ratio*(openPrice-StopLossPrice));
   
   trade.PositionOpen(Symbol(), orderType, Inp_Volume, openPrice, StopLossPrice, TakeProfitPrice, TradeComment);      
  }

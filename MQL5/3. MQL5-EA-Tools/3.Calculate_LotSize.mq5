//+------------------------------------------------------------------+
//|                                          3.Calculate_LotSize.mq5 |
//|                                      Santiago Cruz, AlgoNet Inc. |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz, AlgoNet Inc."
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

#include <Trade/Trade.mqh>
   CTrade         trade;

input double RiskPercent = 2;    //Risk on one tradfe as % of Capital

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
   double price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double sl = price - 400*_Point;
   double tp = price + 400*_Point;
   double lots = calcLots(price - sl);
   
   if(PositionsTotal()<1)
     {
      trade.Buy(lots,_Symbol,price,sl,tp,"Money Management");
     }
  }
  
//+------------------------------------------------------------------+
//| Calculate LoteSize                                               |
//+------------------------------------------------------------------+
double calcLots(double slPoints){

   double risk = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercent / 100;
   
   double ticksize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickvalue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double lotstep = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   
   double MoneyPerLotstep = slPoints / ticksize * tickvalue * lotstep;
   double lots = MathFloor(risk / MoneyPerLotstep) * lotstep;
   
   double MinVolume = SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   double MaxVolume = SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX); 
   
   if(MaxVolume!=0) lots = MathMin(lots,MaxVolume);
   if(MinVolume!=0) lots = MathMax(lots,MinVolume);
   
   lots = NormalizeDouble(lots,2);
   return lots;
   
   
}

//+------------------------------------------------------------------+

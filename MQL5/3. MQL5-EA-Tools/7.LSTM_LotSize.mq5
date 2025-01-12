//+------------------------------------------------------------------+
//|                                               7.LSTM_LotSize.mq5 |
//|                                      Santiago Cruz, AlgoNet Inc. |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+

//---NOTE: Once we download the BackTest Results on MT5, we have to Calculate the Kelly Criterion using Python, find the files here:
//--- Kelly Criterion Code: https://github.com/santiago-cruzlopez/Python-Codes/tree/main/Finance

//---Portfolio Risk Model using Kelly Criterion and Monte Carlo Simulation
//Source: https://www.mql5.com/en/articles/16500?utm_source=mql5.com.tg&utm_medium=message&utm_campaign=articles.codes.repost

/*
   The Leverage Space Trading Model (LSTM)

   L: leverage factor
   p:probability of success
   u:leveraged gain ratio
   l:leveraged loss ratio
   
   Given a backtest result, we can obtain the variable value by the following formulas.

   Let's say you're trading with 2:1 leverage. Assume the following:

   The probability of a successful trade (p) = 0.6 (60% chance of winning).
   The expected return (u) = 0.1 (10% gain without leverage, so leveraged 2:1 = 20% gain).
   The expected loss (l) = 0.05 (5% loss without leverage, so leveraged 2:1 = 10% loss).    
*/

#property copyright "Santiago Cruz, AlgoNet Inc."
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"
#include <Trade/Trade.mqh>


input int slp = 100;
input double risk = 2.0;

CTrade trade;

//+------------------------------------------------------------------+
//| Calculate the corresponding lot size given the risk              |
//+------------------------------------------------------------------+
double calclots(double slpoints)
{
   double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) * risk / 100;

   double ticksize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickvalue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   double moneyperlotstep = slpoints / ticksize * tickvalue * lotstep;
   double lots = MathFloor(riskAmount / moneyperlotstep) * lotstep;
   lots = MathMin(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));
   lots = MathMax(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
   return lots;
}

//+------------------------------------------------------------------+
//| Execute buy trade function                                       |
//+------------------------------------------------------------------+
void executeBuy(double price) {
       double sl = price- slp*_Point;
       sl = NormalizeDouble(sl, _Digits);
       double lots = lotpoint;
       if (risk > 0) lots = calclots(slp*_Point);
       trade.BuyStop(lots,price,_Symbol,sl,0,ORDER_TIME_DAY,1);
       buypos = trade.ResultOrder();
       }


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

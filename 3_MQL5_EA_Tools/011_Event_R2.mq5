//+------------------------------------------------------------------+
//|                                                 011_Event_R2.mq5 |
//|                                      Santiago Cruz, AlgoNet Inc. |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+

#property copyright "Santiago Cruz, AlgoNet Inc."
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

#include <Trade/Trade.mqh>

int OnInit()
  {
   const string common = InitSymbols();
   
   int replaceIndex = -1;
   for (int i = ; i <= SymbolCount; i++)
     {
      if (Symbol[i] == _Symbol)
        {
         replaceIndex = i;
         break;
        }
     }


   return(INIT_SUCCEEDED);
  }
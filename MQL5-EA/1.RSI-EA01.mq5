//+------------------------------------------------------------------+
//|                                                   1.RSI-EA01.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//declaring the variable
   int counter;
   counter = 23;
   Print(counter);
   
   int intName = 2;
   double doubleName = 23.32;
   Print(doubleName);
   
   string stringTypeVariable = "1.RS1-EA01";
   Print(stringTypeVariable);
   
   bool boolTypeVariable = true;
   Print(boolTypeVariable);
   
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
//Check Positions, Open/Close Positions, Modify Positions
   
  }
//+------------------------------------------------------------------+

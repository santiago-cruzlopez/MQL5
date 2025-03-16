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

  bool isNewTime() const
  {
     return lastRead != lastTime();
  }
  
  bool getOuterIndices(int &min, int &max)
  {
     if(isNewTime())
     {
        if(!read()) return false;
     }
     max = ArrayMaximum(data);
     min = ArrayMinimum(data);
     return true;
  }
  
  double operator[](const int buffer)
  {
     if(isNewTime())
     {
        if(!read())
        {
           return EMPTY_VALUE;
        }
     }
     return data[buffer];
  }
};
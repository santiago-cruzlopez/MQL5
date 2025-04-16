//+------------------------------------------------------------------+
//|                                                 011_Event_R2.mq5 |
//|                                            Author: Santiago Cruz |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz"
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

#include <Trade/Trade.mqh>

int OnInit()
{
   currenciesCount = 0;
   ArrayResize(currencies, 0);
   
   if(!StartUp(true)) return INIT_PARAMETERS_INCORRECT;
   
   const bool barwise = UnityPriceType == PRICE_CLOSE && UnityPricePeriod == 1;
   controller = new UnityController(UnitySymbols, barwise,
      UnityBarLimit, UnityPriceType, UnityPriceMethod, UnityPricePeriod);
   // waiting for messages from the indicator on currencies in buffers
   return INIT_SUCCEEDED;
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


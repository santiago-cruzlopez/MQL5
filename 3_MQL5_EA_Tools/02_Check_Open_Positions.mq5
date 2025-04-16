//+------------------------------------------------------------------+
//|                                       2.Check_Open_Positions.mq5 |
//|                                            Author: Santiago Cruz |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz"
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

#include <Trade/Trade.mqh>
   CTrade         trade;
   CPositionInfo  pos_info;
   COrderInfo     ord_info;
   
   int OpenBuy, OpenSell, OpenBuyOrder, OpenSellOrder;
   
   input ulong       InpMagic = 1234;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(InpMagic);
   ChartSetInteger(0,CHART_SHOW_GRID,false);

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
   if(!IsNewBar()) return;
   
   CheckOpenPositions();
   
   double Closex1 = iClose(_Symbol,PERIOD_CURRENT,1);
   double Openx1  = iOpen(_Symbol,PERIOD_CURRENT,1);
   
   //If we want to have only one Buy Position Open at the time, we add OpenBuy<1
   if(Closex1 > Openx1)
     {
      trade.Buy(0.01,_Symbol,0,0,0,NULL);
     }
   //If we want to have only one Sell Position Open at the time, we add OpenSell<1
   if(Closex1 < Openx1)
     {
      
     }trade.Sell(0.01,_Symbol,0,0,0,NULL);
     
   Comment("\n OpenBuys = "+OpenBuy+
           "\n OpenSells = "+OpenSell);
  }

//+------------------------------------------------------------------+
//| Check for New Bar/Candle                                         |
//+------------------------------------------------------------------+ 
bool IsNewBar(){

   static datetime previousTime = 0;
   
   datetime currentTime = iTime(_Symbol,PERIOD_CURRENT,0);
   
   if(previousTime!=currentTime){
      previousTime = currentTime;
      return true;
   }
   return false;
}
  
//+------------------------------------------------------------------+
//| Check Open Positions                                             |
//+------------------------------------------------------------------+  
void CheckOpenPositions(){

   OpenBuy=0;
   OpenSell=0;
   
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      pos_info.SelectByIndex(i);
      
      if(pos_info.Symbol()==_Symbol && pos_info.Magic()==InpMagic)
        {
         if(pos_info.PositionType()==POSITION_TYPE_BUY)
           {
            OpenBuy++;
           }
           else if(pos_info.PositionType()==POSITION_TYPE_SELL)
                  {
                   OpenSell++;
                  }
        }
     }
}

//+------------------------------------------------------------------+

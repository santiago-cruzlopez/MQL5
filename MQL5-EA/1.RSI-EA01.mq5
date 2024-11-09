//+------------------------------------------------------------------+
//|                                                   1.RSI-EA01.mq5 |
//|                               Author: Santiago Cruz, AlgoNet Inc.|
//|                       https://www.mql5.com/en/users/algo-trader/ |                               
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>

CTrade trade;
int rsiHandle;
ulong posTicket;

int OnInit()
  {
   //declaring the variable
   int rsiHandle = iRSI(_Symbol,PERIOD_CURRENT,14,PRICE_CLOSE);
   
   return 0;
  }

// Expert deinitialization function                                 
void OnDeinit(const int reason)
  {
//---
   
  }

// Expert tick function                                             
void OnTick()
  {
//Check Positions, Open/Close Positions, Modify Positions
//store multiple data [], empty since we don't how many values the RSI indicator is going to take
   double rsi[];
   CopyBuffer(rsiHandle,0,1,1,rsi);
   
   if(rsi[0] > 70){  
     if(posTicket > 0 && PositionSelectByTicket(posTicket)){
        int posType = (int)PositionGetInteger(POSITION_TYPE);
        if(posType == POSITION_TYPE_BUY){        
           trade.PositionClose(posTicket);
           posTicket = 0;
        }
     }
    
     if(posTicket <= 0){
        trade.Sell(0.01,_Symbol);
        posTicket = trade.ResultOrder();
     }
     
   }else if(rsi[0] < 30){
      if(posTicket > 0 && PositionSelectByTicket(posTicket)){
        int posType = (int)PositionGetInteger(POSITION_TYPE);
        if(posType == POSITION_TYPE_SELL){        
           trade.PositionClose(posTicket);
           posTicket = 0;
        }
     }
   
     if(posTicket <= 0){
        trade.Buy(0.01,_Symbol);
        posTicket = trade.ResultOrder();
     }
   }
   
   if(PositionSelectByTicket(posTicket)){
      double posPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double posSl = PositionGetDouble(POSITION_SL);
      double posTp = PositionGetDouble(POSITION_TP);
      int posType = (int)PositionGetInteger(POSITION_TYPE);
      
      
      if(posType == POSITION_TYPE_BUY){
         if(posSl == 0){
            double sl = posPrice - 0.00300;
            double tp = posPrice + 0.00500;
            trade.PositionModify(posTicket,sl,tp);
         }
      }else if(posType == POSITION_TYPE_SELL){
         if(posSl == 0){
            double sl = posPrice + 0.00500;
            double tp = posPrice - 0.00300;
            trade.PositionModify(posTicket,sl,tp);      
         }    
      }else{
       
      }
    }
   
   Comment(rsi[0], "\n", posTicket);
  }

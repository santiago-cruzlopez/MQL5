//+------------------------------------------------------------------+
//|                                           5.Trailing_Stop_01.mq5 |
//|                                            Author: Santiago Cruz |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
//Source: https://www.youtube.com/watch?v=3l8RyeQNmNo&t=1290s
#property copyright "Santiago Cruz"
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"
#include <Trade/Trade.mqh>

input int TSL_TriggerPoints = 50;
input int TSL_Points = 100;
input ENUM_TIMEFRAMES MATime_Frame = PERIOD_CURRENT;
input int MAPeriod = 20;
input ENUM_MA_METHOD MA_Method = MODE_SMA;
input ENUM_APPLIED_PRICE MA_AppPrice = PRICE_CLOSE;

int Handle_MA;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Handle_MA = iMA(_Symbol,MATime_Frame,MAPeriod,0,MA_Method,MA_AppPrice);
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

   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      ulong Pos_Ticket = PositionGetTicket(i);

      if(PositionSelectByTicket(Pos_Ticket))
        {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol)
           {
            CTrade trade;

            double Pos_OpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double Pos_SL        = PositionGetDouble(POSITION_SL);
            double Pos_TP        = PositionGetDouble(POSITION_TP);

            double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
            double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);

            double MA[];
            CopyBuffer(Handle_MA,MAIN_LINE,1,1,MA);

            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
              {
               if(bid > Pos_OpenPrice + TSL_TriggerPoints*_Point)
                 {

                  double sl = bid - TSL_Points*_Point;

                  if(sl > Pos_SL && sl < bid)
                    {

                     if(trade.PositionModify(Pos_Ticket,sl,Pos_TP))
                       {
                        Print(__FUNCTION__," > Pos #",Pos_Ticket," was modified by normal TSL.");
                       }
                    }
                 }
               if(ArraySize(MA) > 0)
                 {
                  double sl = MA[0];

                  if(sl > Pos_SL)
                    {
                     if(trade.PositionModify(Pos_Ticket,sl,Pos_TP))
                       {
                        Print(__FUNCTION__," > Pos #",Pos_Ticket," was modified by MA TSL.");
                       }
                    }
                 }
              }
            else
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                 {
                  if(ask < Pos_OpenPrice - TSL_TriggerPoints*_Point)
                    {
                     double sl = ask + TSL_Points*_Point;

                     if((sl < Pos_SL || Pos_SL==0) && sl > ask)
                       {
                        if(trade.PositionModify(Pos_Ticket,sl,Pos_TP))
                          {
                           Print(__FUNCTION__," > Pos #",Pos_Ticket," was modified.");
                          }
                       }
                    }
                  if(ArraySize(MA) > 0)
                    {
                     double sl = MA[0];

                     if(sl < Pos_SL || Pos_SL==0)
                       {
                        if(trade.PositionModify(Pos_Ticket,sl,Pos_TP))
                          {
                           Print(__FUNCTION__," > Pos #",Pos_Ticket," was modified by MA TSL.");
                          }
                       }
                    }
                 }
           }
        }
     }

  }
//+------------------------------------------------------------------+

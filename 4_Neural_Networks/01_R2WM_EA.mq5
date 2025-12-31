//+------------------------------------------------------------------+
//|                                                   01_R2WM_EA.mq5 |
//|                                                    Santiago Cruz |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+

#property copyright "Santiago Cruz, AlgoNet Inc."
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

#include <Trade\PositionInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\Trade.mqh>
#include <WNN.mqh>

CTrade trade;
CAccountInfo  AccInfo;
CPositionInfo m_position;

input group "=== Trading Inputs ==="

input string          TradeComment      = "WNN Neural Network EA";
static input long     EA_Magic_Buy      = 250201;  
static input long     EA_Magic_Sell     = 250202;
input double          LotSize           = 1.05;
double                pip               = _Point*10;
input int             TPinPips          = 5;
input int             SLinPips          = 5;
input ENUM_TIMEFRAMES TimeFrame         = PERIOD_H1;
input int             min               = 50;
input int             number_of_neurons = 15;
input int             history_depth     = 15;     

WNN WNN_2(_Symbol,TimeFrame,history_depth,number_of_neurons,.00000001);

int OnInit()
  { 
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   
  }

void OnTick()
  {
   datetime    tm = TimeCurrent();
   MqlDateTime stm;
   TimeToStruct(tm,stm);
   
   int TimeCheck = 0;
   
   if(stm.day_of_week==2 || stm.day_of_week==3 || stm.day_of_week==4 && stm.hour>7 && stm.hour<15)
     {
      TimeCheck = 1;
     }
   
   if(m_position.SelectByMagic(_Symbol,EA_Magic_Buy))
     {
      if((long)m_position.Time() + 60*min < (long)TimeCurrent())
        {
         trade.PositionClose(m_position.Ticket(),-1);
        }
     }
     
   if(m_position.SelectByMagic(_Symbol,EA_Magic_Sell))
     {
      if((long)m_position.Time() + 60*min < (long)TimeCurrent())
        {
         trade.PositionClose(m_position.Ticket(),-1);
        }
     }
   
   bool TradeTracker = (m_position.SelectByMagic(_Symbol,EA_Magic_Buy) == false) && (m_position.SelectByMagic(_Symbol, EA_Magic_Sell) == false);
   
   if(stm.min == 1)
     {
      WNN_2.Train(0);
      
      double Pred = WNN_2.Prediction();
      Print(Pred);
      
      if(Pred<.5 && TradeTracker && TimeCheck==1)
        {
         double TakeProfit = pip*TPinPips;
         double StopLoss = pip*SLinPips;
         
         MqlTradeRequest myrequest;
         MqlTradeResult myresult;
         ZeroMemory(myrequest);
         ZeroMemory(myresult);
         
         myrequest.type = ORDER_TYPE_BUY;
         myrequest.action = TRADE_ACTION_DEAL;
         myrequest.sl = SymbolInfoDouble(_Symbol,SYMBOL_BID) - StopLoss;
         myrequest.symbol = _Symbol;
         myrequest.volume = LotSize;
         myrequest.type_filling = ORDER_FILLING_FOK;
         myrequest.price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         myrequest.magic = EA_Magic_Buy;
         OrderSend(myrequest,myresult);
        }

      if(Pred>.5 && TradeTracker && TimeCheck==1)
        {
         double TakeProfit = pip*TPinPips;
         double StopLoss = pip*SLinPips;
         
         MqlTradeRequest myrequest;
         MqlTradeResult myresult;
         ZeroMemory(myrequest);
         ZeroMemory(myresult);
         
         myrequest.type = ORDER_TYPE_SELL;
         myrequest.action = TRADE_ACTION_DEAL;
         myrequest.sl = SymbolInfoDouble(_Symbol,SYMBOL_BID) + StopLoss;
         myrequest.symbol = _Symbol;
         myrequest.volume = LotSize;
         myrequest.type_filling = ORDER_FILLING_FOK;
         myrequest.price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
         myrequest.magic = EA_Magic_Sell;
         OrderSend(myrequest,myresult);
        }
  
     }
   
  }
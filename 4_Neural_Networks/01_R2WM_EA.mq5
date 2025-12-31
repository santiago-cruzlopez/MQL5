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
#include <NeuralNetwork.mqh>
#include <OrderBook.mqh>

CTrade trade;
CAccountInfo  AccInfo;
CPositionInfo m_position;
OrderBook OB_ASK;
OrderBook OB_Bid;

input group "=== Trading Inputs ==="

input string          TradeComment      = "WNN Neural Network EA";
static input long     EA_Magic_Buy      = 250206;  
static input long     EA_Magic_Sell     = 250207;
input double          LotSize           = 1.05;
double                pip               = _Point*10;
input int             TPinPips          = 5;
input int             SLinPips          = 5;    
input ENUM_TIMEFRAMES TimeFrame         = PERIOD_H1;
input int             number_of_neurons = 15;
input int             SlowMA            = 100;
input int             FastMA            = 20;
input int             RSIPeriod         = 14; 

NeuralNetwork NNTrade_Buy(10,28,number_of_neurons,10,.0001,1);
NeuralNetwork NNTrade_Sell(10,28,number_of_neurons,10,.0001,1);

matrix tempMatrix(10,28);
matrix tempMatrixb(10,28);

bool Tracker = true;
ulong TimeCheck = ulong(TimeCurrent());
double tempAsk = SymbolInfoDouble(_Symbol,SYMBOL_ASK);

int deltaTick = 0;
bool deltaTracker = false;
double delta_prev = 0;
double deltaDerivative = 0;

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
   
   if( (stm.hour == 16 && stm.min >=0) || (stm.hour == 17 && stm.min <= 40) )
     {
   
   for(int i=PositionGetTicket()-1;i>=0;i--)
     {
      int ticket = PositionGetTicket(i);
      m_position.SelectByTicket(ticket);
      ulong posTime = ulong(m_position.Time());
      
      if(1*60 < ulong(TimeCurrent()) - posTime)
        {
         int ticket = PositionGetTicket(i);
         trade.PositionClose(ticket);
        }
     }
   
   double current_Ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double current_Bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   
   ulong current_Volume = iTickVolume(_Symbol,PERIOD_M1,0);
   
   OB_Ask.Insert(current_Ask,current_Volume);
   OB_Bid.Insert(current_Bid,current_Volume);
   
   double UniqueAsk[];
   double UniqueNumsAsk[];
   
   double UniqueBid[];
   double UniqueNumsBid[];
   
   double UniqueAskSize = OB_Ask.SetArraysWithValues(UniqueNumsAsk,UniqueAsk);
   double UniqueBidSize = OB_Bid.SetArraysWithValues(UniqueNumsBid,UniqueBid);
   
   double deltaAsk = 0;
   double deltaBid = 0;
   double delta = 0;
   
   if(stm.sec < deltaTick)
     {
      for(int i=0;i<UniqueAskSize;i++)
        {
         deltaAsk += UniqueNumsAsk[i]*UniqueAsk[i];
        }
        
      for(int i=0;i<UniqueBidSize;i++)
        {
         deltaBid += UniqueNumsBid[i]*UniqueBid[i];
        }
      
      delta = deltaAsk - deltaBid;
      deltaDerivative = (current_Ask - delta) / current_Ask - delta_prev;
      delta_prev = (current_Ask - delta)/current_Ask;
      
      OB_Ask.ClearBook();
      OB_Bid.ClearBook();
     }
   
   deltaTick = stm.sec;
   
  }
//+------------------------------------------------------------------+
//|                                                    RSI_MA_EA.mq5 |
//|                                            Author: Santiago Cruz |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz"
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

#include <Trade/Trade.mqh>

//---User Inputs
static input long      InpMagicnumber  = 546812;    //Magic Number
static input double    InpLotSize      = 0.01;     //Lot Size
input int              InpRSIPeriod    = 21;       //RSI Period
input int              InpRSILevel     = 70;       //RSI Level Upper
input int              InpMAPeriod     = 21;       //MA Period
input ENUM_TIMEFRAMES  InpMATimerframe = PERIOD_H1; //MA Timeframes
input int              InpStopLoss     = 200;      //StopLoss in Points (0=off)
input int              InpTakeProfit   = 100;      //TakeProfit in Points (0=off)
input bool             InpCLoseSignal  = false;    //Close Trades by Opposite Signal

//---Global Variables
int handleRSI;
int handleMA;
double bufferRSI[];
double bufferMA[];
MqlTick currentTick;
CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---Check the User Inputs
   if(InpMagicnumber<=0)
     {
      Alert("Magic Number <= 0");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(InpLotSize<=0 || InpLotSize>10)
     {
      Alert("Lot Size <= 0 or >10");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpRSIPeriod<=1)
     {
      Alert("RSI Period <= 1");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpRSILevel>=100 || InpRSILevel<=50)
     {
      Alert("RSI Levels >= 100 or <=50");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpMAPeriod<=1)
     {
      Alert("MA Period <= 1");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpStopLoss<0)
     {
      Alert("SL < 0");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpTakeProfit<0)
     {
      Alert("TP < 0");
      return INIT_PARAMETERS_INCORRECT;
     }

//---Set Magic Number to Trade Object
   trade.SetExpertMagicNumber(InpMagicnumber);

//---Getting the Indicator Handles
   handleRSI = iRSI(_Symbol,PERIOD_CURRENT,InpRSIPeriod,PRICE_OPEN);
   if(handleRSI == INVALID_HANDLE)
     {
      Alert("Failed to create Indicator handleRSI");
      return INIT_FAILED;
     }

   handleMA = iMA(_Symbol,InpMATimerframe,InpMAPeriod,0,MODE_SMA,PRICE_OPEN);
   if(handleMA == INVALID_HANDLE)
     {
      Alert("Failed to create Indicator handleMA");
      return INIT_FAILED;
     }

//---Set the Indicators Buffer
   ArraySetAsSeries(bufferRSI,true);
   ArraySetAsSeries(bufferMA,true);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---Release handleRSI Indicator
   if(handleRSI != INVALID_HANDLE)
     {
      IndicatorRelease(handleRSI);
     }

//---Release handleMA Indicator
   if(handleMA != INVALID_HANDLE)
     {
      IndicatorRelease(handleMA);
     }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---Check if Current Tick is a New Bar Open Tick
   if(!IsNewBar())
     {
      return;
     }

//---Get Current Tick
   if(!SymbolInfoTick(_Symbol,currentTick))
     {
      Print("Failed to get current tick");
      return;
     }

//---Get RSI Values
   int values = CopyBuffer(handleRSI,0,0,2,bufferRSI);
   if(values!=2)
     {
      Print("Failed to get RSI Indicator values");
      return;
     }

//---Get MA Values
   values = CopyBuffer(handleMA,MAIN_LINE,0,1,bufferMA);
   if(values!=1)
     {
      Print("Failed to get MA Indicator values");
      return;
     }

   Comment("bufferRSI[0]:",bufferRSI[0],
           "\nbufferRSI[1]:",bufferRSI[1],
           "\nbufferMA[0]:",bufferMA[0]);

//---Count Open Positions
   int cntBuy, cntSell;
   if(!CountOpenPositions(cntBuy,cntSell))
     {
      return;
     }

//---Check for Buy Positions
   if(cntBuy==0 && bufferRSI[1]>=(100-InpRSILevel) && bufferRSI[0]<(100-InpRSILevel) && currentTick.ask>bufferMA[0])
     {
      if(InpCLoseSignal)
        {
         if(!ClosePositions(2))
           {
            return;
           }
        }

      double sl = InpStopLoss==0 ? 0 : currentTick.bid - InpStopLoss * _Point;
      double tp = InpTakeProfit==0 ? 0 : currentTick.bid + InpTakeProfit * _Point;
      if(!NormalizePrice(sl))
        {
         return;
        }
      if(!NormalizePrice(tp))
        {
         return;
        }

      trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,InpLotSize,currentTick.ask,sl,tp,"RSI MA Filter EA");
     }

//---Check for Sell Positions
   if(cntSell==0 && bufferRSI[1]<=InpRSILevel && bufferRSI[0]>InpRSILevel && currentTick.bid<bufferMA[0])
     {
      if(InpCLoseSignal)
        {
         if(!ClosePositions(1))
           {
            return;
           }
        }

      double sl = InpStopLoss==0 ? 0 : currentTick.ask + InpStopLoss * _Point;
      double tp = InpTakeProfit==0 ? 0 : currentTick.ask - InpTakeProfit * _Point;
      if(!NormalizePrice(sl))
        {
         return;
        }
      if(!NormalizePrice(tp))
        {
         return;
        }

      trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,InpLotSize,currentTick.bid,sl,tp,"RSI MA Filter EA");
     }

  }

//+------------------------------------------------------------------+
//|Check if we have a Bar Open Tick                                  |
//+------------------------------------------------------------------+
bool IsNewBar()
  {

   static datetime previousTime = 0;
   datetime currentTime = iTime(_Symbol,PERIOD_CURRENT,0);
   if(previousTime!=currentTime)
     {
      previousTime=currentTime;
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|Count Open Positions                                              |
//+------------------------------------------------------------------+
bool CountOpenPositions(int &cntBuy, int &cntSell)
  {

   cntBuy = 0;
   cntSell = 0;
   int total = PositionsTotal();
   for(int i=total-1;i>=0;i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0)
        {
         Print("Failed to get position Ticket");
         return false;
        }
      if(!PositionSelectByTicket(ticket))
        {
         Print("Print to select position");
         return false;
        }
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic))
        {
         Print("Failed to get position Magic Number");
         return false;
        }
      if(magic==InpMagicnumber)
        {
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type))
           {
            Print("Failed to get position type");
            return false;
           }
         if(type==POSITION_TYPE_BUY)
           {
            cntBuy++;
           }
         if(type==POSITION_TYPE_SELL)
           {
            cntSell++;
           }
        }
     }
   return true;
  }

//+------------------------------------------------------------------+
//|Normalize Price                                                   |
//+------------------------------------------------------------------+
bool NormalizePrice(double &price)
  {
   double tickSize=0;
   if(!SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE,tickSize))
     {
      Print("Failed to get tick size");
      return false;
     }
   price = NormalizeDouble(MathRound(price/tickSize)*tickSize,_Digits);

   return true;
  }

//+------------------------------------------------------------------+
//|Close Positions                                                   |
//+------------------------------------------------------------------+
bool ClosePositions(int all_buy_sell){
   int total = PositionsTotal();
   for(int i=total-1;i>=0;i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0)
        {
         Print("Failed to get position ticket");
         return false;
        }
      if(!PositionSelectByTicket(ticket))
        {
         Print("Failed to select position");
         return false;
        } 
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic))
        {
         Print("Failed to get position magicnumber");
         return false;
        }
      if(magic==InpMagicnumber)
        {
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type))
           {
            Print("Failed to get position type");
            return false;
           }
         if(all_buy_sell==1 && type==POSITION_TYPE_SELL)
           {
            continue;
           }
         if(all_buy_sell==2 && type==POSITION_TYPE_BUY)
           {
            continue;
           }
         trade.PositionClose(ticket);
         if(trade.ResultRetcode()!=TRADE_RETCODE_DONE)
           {
            Print("Failed to close position. Ticket: ",
                   (string)ticket, " result: ",(string)trade.ResultRetcode(),":",trade.CheckResultRetcodeDescription());
           }
        }
     }
     
     return true;
}

//+------------------------------------------------------------------+

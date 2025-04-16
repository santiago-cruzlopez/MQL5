//+------------------------------------------------------------------+
//|                                               14.RSI_MA_V2_EA.mq |
//|                                            Author: Santiago Cruz |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz"
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

#include <Trade\Trade.mqh>

input group "=== Trading Inputs ==="
input string            TradeComment     = "RSI MA V2 EA";
static input long       EA_Magic      = 250115;    //Magic Number
static input double     LotSize       = 0.01;      
input  int              RSI_Period    = 21;        //RSI Period
input  int              RSI_Level     = 70;        //RSI Level Upper
input  int              MA_Period     = 21;        //MA Period   
input  ENUM_TIMEFRAMES  MA_Timeframe  = PERIOD_D1; //MA Timeframe
input  int              Stop_Loss     = 200;       //Stop Loss In Points
input  int              Take_Profit   = 100;       //Take Profit In Points
input  bool             Close_Signal  = false;     //Close Trades By Opposite Signal

//---Global Variables
int      MA_Handle;
int      RSI_Handle;
double   MA_Buffer[];
double   RSI_Buffer[];
MqlTick  currentTick;
CTrade   trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(EA_Magic<= 0 && LotSize<=0 && Stop_Loss<0 && Take_Profit<0)
     {
      Alert("Incorrect Input Parameters!");
      return INIT_PARAMETERS_INCORRECT;
     }
   
   if(RSI_Period<=1 && (RSI_Level>=0 || RSI_Level<=50))
     {
      Alert("Incorrect RSI Input Parameters!");
      return INIT_PARAMETERS_INCORRECT;      
     }  

   if(MA_Period <= 1)
     {
      Alert("Incorrect MA Input Parameters!");
      return INIT_PARAMETERS_INCORRECT;      
     }  

   trade.SetExpertMagicNumber(EA_Magic);

//---Create Indicators Handles
   RSI_Handle = iRSI(_Symbol,PERIOD_CURRENT,RSI_Period,PRICE_OPEN);
   if(RSI_Handle == INVALID_HANDLE)
     {
      Alert("Failed to Create RSI Indicator Handle!");
      return INIT_FAILED;
     }
   
   MA_Handle = iMA(_Symbol,MA_Timeframe,MA_Period,0,MODE_SMA,PRICE_OPEN);
   if(MA_Handle == INVALID_HANDLE)
     {
      Alert("Failed to Create MA Indicator Handle!");
      return INIT_FAILED;
     }
     
//---Set Buffer as Series   
   ArraySetAsSeries(RSI_Buffer,true);
   ArraySetAsSeries(MA_Buffer,true);

   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---Realease RSI Indicator Handle
   if(RSI_Handle != INVALID_HANDLE)
     {
      IndicatorRelease(RSI_Handle);
     }
   if(MA_Handle != INVALID_HANDLE)
     {
      IndicatorRelease(MA_Handle);
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
      Print("Failed to get current Tick.");
      return;
     }

//---Get RSI Value
   int value1 = CopyBuffer(RSI_Handle,0,0,2,RSI_Buffer);
   if(value1 != 2)
     {
      Print("Failed to get the RSI Indicator Values.");
      return;
     }

//---Get MA Value
   int value2 = CopyBuffer(MA_Handle,0,0,1,MA_Buffer);
   if(value2 != 1)
     {
      Print("Failed to get the MA Indicator Values.");
      return;
     }

   Comment("RSI Buffer[0]: ",RSI_Buffer[0],"\n",
           "RSI Buffer[1]: ",RSI_Buffer[1],"\n",
           "MA  Buffer[0]: ",MA_Buffer[0]);

//---Count Open Positions
   int cntBuy,cntSell;
   if(!CountOpenPositions(cntBuy,cntSell))
     {
      return;
     }
     
//---Check for Buy Positions
   if(cntBuy==0 && RSI_Buffer[1]>=(100-RSI_Level) && RSI_Buffer[0]<(100-RSI_Level) && currentTick.ask > MA_Buffer[0])
     {
      if(Close_Signal){if(!ClosePositions(2)){ClosePositions(2);}}
      double sl = Stop_Loss == 0 ? 0 : currentTick.bid - Stop_Loss*_Point;
      double tp = Take_Profit == 0 ? 0 : currentTick.bid + Take_Profit*_Point;
      if(!NormalizePrice(sl)){return;}
      if(!NormalizePrice(sl)){return;}      
      trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,LotSize,currentTick.ask,sl,tp,TradeComment);      
     }
 
//---Check for Sell Positions
   if(cntSell==0 && RSI_Buffer[1]<=RSI_Level && RSI_Buffer[0]>RSI_Level && currentTick.bid < MA_Buffer[0])
     {
      if(Close_Signal){if(!ClosePositions(1)){ClosePositions(1);}}
      double sl = Stop_Loss == 0 ? 0 : currentTick.ask + Stop_Loss*_Point;
      double tp = Take_Profit == 0 ? 0 : currentTick.ask - Take_Profit*_Point;
      if(!NormalizePrice(sl)){return;}
      if(!NormalizePrice(sl)){return;}      
      trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,LotSize,currentTick.bid,sl,tp,TradeComment);     
     }
     
  }

//+------------------------------------------------------------------+
//| Check For New Bars                                               |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   static datetime previousTime = 0;
   datetime currentTime = iTime(_Symbol,PERIOD_CURRENT,0);
   if(previousTime != currentTime)
     {
      previousTime = currentTime;
      return true;
     }   
   return false;
  }

//+------------------------------------------------------------------+
//| Count Open Positions                                             |
//+------------------------------------------------------------------+
bool CountOpenPositions(int &cntBuy, int &cntSell)
  {
   cntBuy = 0;
   cntSell = 0;
   int total = PositionsTotal();
   for(int i=total-1;i>=0;i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0){Print("Failed to get position ticket."); return false;}
      if(!PositionSelectByTicket(ticket)){Print("Failed to select position ticket."); return false;}
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic)){Print("Failed to get position Magic Number."); return false;}
      if(magic == EA_Magic)
        {
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type)){Print("Failed to get position type."); return false;}
         if(type == POSITION_TYPE_BUY){cntBuy++;}
         if(type == POSITION_TYPE_SELL){cntSell++;}
        }
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Normalize Price                                                  |
//+------------------------------------------------------------------+
bool NormalizePrice(double &price){
   double tickSize = 0;
   if(!SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE,tickSize))
     {
      Print("Failed to get tick");
      return false;
     }
   price = NormalizeDouble(MathRound(price/tickSize)*tickSize,_Digits);
   return true;
}

//+------------------------------------------------------------------+
//| Close All Positions                                              |
//+------------------------------------------------------------------+
bool ClosePositions(int all_buy_sell)
  {
   int total = PositionsTotal();
   for(int i=total-1;i>=0;i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0){Print("Failed to get position ticket."); return false;}
      if(!PositionSelectByTicket(ticket)){Print("Failed to select position ticket."); return false;}
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic)){Print("Failed to get position Magic Number."); return false;}
      if(magic == EA_Magic)
        {
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type)){Print("Failed to get position type."); return false;}
         if(all_buy_sell == 1 && type == POSITION_TYPE_SELL){continue;}
         if(all_buy_sell == 2 && type == POSITION_TYPE_BUY){continue;}
         trade.PositionClose(ticket);
         if(trade.ResultRetcode() != TRADE_RETCODE_DONE)
           {
            Print("Failed to close Position Ticket: ",(string)ticket," result" ,(string)trade.ResultRetcode(),":",trade.CheckResultRetcodeDescription());
            return false;
           }
        }
     }
   return true;
  }

//+------------------------------------------------------------------+

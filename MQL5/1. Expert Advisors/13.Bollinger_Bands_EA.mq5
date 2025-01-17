//+------------------------------------------------------------------+
//|                                        13.Bollinger_Bands_EA.mq5 |
//|                                      Santiago Cruz, AlgoNet Inc. |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade\Trade.mqh>

input  group "=== Trading Inputs ==="
input  string         TradeComment     = "Bollinger Bands EA";
static input long     EA_Magic         = 250117;
static input double   LotSize          = 0.01;   //Lot Size
input  int            Stop_Loss        = 100;    //Stop Loss In Points
input  int            Take_Profit      = 200;    //Take Profit In Points
input  int            BB_Period        = 21;     //BB Period
input  double         BB_Deviation     = 2.0;    //Deviation

//---Global Variables
int      BB_Handle;
double   BB_UpperBuffer[];
double   BB_BaseBuffer[];
double   BB_LowerBuffer[];
datetime openTimeBuy  = 0;
datetime openTimeSell = 0;
MqlTick  currentTick;
CTrade   trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---Check User Input Parameters
   if(EA_Magic<=0 && LotSize<=0 && Stop_Loss<0 && Take_Profit<0)
     {
      Alert("Incorrect Input Parameters.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(BB_Period<=1 && BB_Deviation<=0)
     {
      Alert("Incorrect Bollinger Bands Parameters");
      return INIT_PARAMETERS_INCORRECT;
     }

   trade.SetExpertMagicNumber(EA_Magic);

//---Create Bollinger Bands Handle
   BB_Handle = iBands(_Symbol,PERIOD_CURRENT,BB_Period,1,BB_Deviation,PRICE_CLOSE);
   if(BB_Handle == INVALID_HANDLE)
     {
      Alert("Failed to create Bollinger Band Indicator Handle.");
      return INIT_FAILED;
     }

//---Bollinger Bands Buffers
   ArraySetAsSeries(BB_UpperBuffer,true);
   ArraySetAsSeries(BB_BaseBuffer,true);
   ArraySetAsSeries(BB_LowerBuffer,true);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---Release Bollinger Bands Indicator Handle
   if(BB_Handle != INVALID_HANDLE)
     {
      IndicatorRelease(BB_Handle);
     }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---Check Current Tick
   if(!IsNewBar())
     {
      return;
     }

//---Get Current Tick
   if(!SymbolInfoTick(_Symbol,currentTick))
     {
      Print("Failed to get Current Tick!");
      return;
     }

//---Get Bollinger Bands Indicator Values
   int BB_Value = CopyBuffer(BB_Handle,0,0,1,BB_BaseBuffer) 
                + CopyBuffer(BB_Handle,1,0,1,BB_UpperBuffer) 
                + CopyBuffer(BB_Handle,2,0,1,BB_LowerBuffer);
                
   if(BB_Value != 3)
     {
      Print("Failed to get Bollinger Bands Indicator Values!");
      return;
     }
   
   Comment("BB Up[0]: ",BB_UpperBuffer[0],"\n",
           "BB Base[0]: ",BB_BaseBuffer[0],"\n", 
           "BB Low[0]: ",BB_LowerBuffer[0]);
   
//---Count Open Positions
   int cntBuy,cntSell;
   if(!CountOpenPositions(cntBuy,cntSell))
     {
      return;
     }

//---Check For Lower Band Cross to Open a Buy Position
   if(cntBuy==0 && currentTick.ask<=BB_LowerBuffer[0] && openTimeBuy!=iTime(_Symbol,PERIOD_CURRENT,0))
     {
      openTimeBuy = iTime(_Symbol,PERIOD_CURRENT,0);
      double SL = currentTick.bid - Stop_Loss*_Point;
      double TP = Take_Profit == 0 ? 0 : currentTick.bid + Take_Profit*_Point;
      if(!NormalizePrice(SL,SL)){return;}
      if(!NormalizePrice(TP,TP)){return;}      
      trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,LotSize,currentTick.ask,SL,TP,TradeComment);      
     }      

//---Check For Upper Band Cross to Open a Sell Position
   if(cntSell==0 && currentTick.bid>=BB_UpperBuffer[0] && openTimeSell!=iTime(_Symbol,PERIOD_CURRENT,0))
     {
      openTimeSell = iTime(_Symbol,PERIOD_CURRENT,0);
      double SL = currentTick.ask + Stop_Loss*_Point;
      double TP = Take_Profit == 0 ? 0 : currentTick.ask - Take_Profit*_Point;
      if(!NormalizePrice(SL,SL)){return;}
      if(!NormalizePrice(TP,TP)){return;}      
      trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,LotSize,currentTick.bid,SL,TP,TradeComment);      
     }  
   
//---Check For Close Position Buy/Sell with Base Band   
   if(!CountOpenPositions(cntBuy,cntSell)){return;}   
   if(cntBuy>0 && currentTick.bid>=BB_BaseBuffer[0]){ClosePositions(1);}
   if(cntSell>0 && currentTick.ask<=BB_BaseBuffer[0]){ClosePositions(2);}   
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
bool CountOpenPositions(int &countBuy, int &countSell)
  {
   countBuy = 0;
   countSell = 0;
   int total = PositionsTotal();
   for(int i=total-1;i>=0;i--)
     {
      ulong positionTicket = PositionGetTicket(i);
      if(positionTicket<=0){Print("Failed to get position ticket."); return false;}
      if(!PositionSelectByTicket(positionTicket)){Print("Failed to select position Ticket."); return false;}
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic)){Print("Failed to get position Magic Number."); return false;}
      if(magic == EA_Magic)
        {
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type)){Print("Failed to get position Type Buy/Sell."); return false;}
         if(type == POSITION_TYPE_BUY){countBuy++;}
         if(type == POSITION_TYPE_SELL){countSell++;}
        }
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Normalize Price                                                  |
//+------------------------------------------------------------------+
bool NormalizePrice(double &price, double &normalizedPrize){
   double tickSize = 0;
   if(!SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE,tickSize))
     {
      Print("Failed to get Trade Tick Size!");
      return false;
     }
   normalizedPrize = NormalizeDouble(MathRound(price/tickSize)*tickSize,_Digits);
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
      ulong positionTicket = PositionGetTicket(i);
      if(positionTicket<=0){Print("Failed to get position ticket."); return false;}
      if(!PositionSelectByTicket(positionTicket)){Print("Failed to select position ticket."); return false;}
      long magic;
      if(!PositionGetInteger(POSITION_MAGIC,magic)){Print("Failed to get position Magic Number."); return false;}
      if(magic == EA_Magic)
        {
         long type;
         if(!PositionGetInteger(POSITION_TYPE,type)){Print("Failed to get position Type Buy/Sell."); return false;}
         if(all_buy_sell == 1 && type == POSITION_TYPE_SELL){continue;}
         if(all_buy_sell == 2 && type == POSITION_TYPE_BUY){continue;}
         trade.PositionClose(positionTicket);
         if(trade.ResultRetcode() != TRADE_RETCODE_DONE)
           {
            Print("Failed to close Position Ticket: ",(string)positionTicket," result" ,(string)trade.ResultRetcode(),":",trade.CheckResultRetcodeDescription());
            return false;
           }
        }
     }
   return true;
  }

//+------------------------------------------------------------------+

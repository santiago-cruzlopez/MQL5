//+------------------------------------------------------------------+
//|                                              10.CCI_2MAVG_EA.mq5 |
//|                                      Santiago Cruz, AlgoNet Inc. |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+

/*
 Enter Buy When:
   - CCI crosses above zero
   - Fast MAVG crosses above Slow MAVG 
   - These do NOT have to happen at the same time (OR)
   - Trade Exit when Fast MAVG crosses below Slow MAVG
 Enter Sell When:
   - CCI crosses below zero
   - Fast MAVG crosses below Slow MA
   - These do NOT have to happen at the same time (OR)
   - Trade Exit when MAVG crosses above Slow MAVG
*/

#property copyright "Santiago Cruz, AlgoNet Inc."
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

#include <Trade\Trade.mqh>

input group "=== Trading Inputs ==="

input string             TradeComment   = "CCI 2MAVG EA";
static input long        EA_Magic       = 250122;       //Magic Number
input double             Inp_Volume     = 0.01;         //Trade Volume

input int                CCI_Period     = 14;           //CCI Period
input ENUM_APPLIED_PRICE CCI_Price      = PRICE_CLOSE;  //CCI Applied Price

input int                MAVG1_FastB    = 10;           //Fast MA Bars
input ENUM_MA_METHOD     MAVG1_Method   = MODE_EMA;     //Fast MA Method
input ENUM_APPLIED_PRICE MAVG1_Price    = PRICE_CLOSE;  //Fast MA Applied Price   

input int                MAVG2_SlowB    = 60;           //Slow MA Bars
input ENUM_MA_METHOD     MAVG2_Method   = MODE_EMA;     //Slow MA Method
input ENUM_APPLIED_PRICE MAVG2_Price    = PRICE_CLOSE;  //Slow MA Applied Price 

//---Global Variables
int MAVG1_Handle;
int MAVG2_Handle;
int CCI_Handle;

double MAVG1_Buffer[];
double MAVG2_Buffer[];
double CCI_Buffer[];

CTrade trade;
CPositionInfo Pos_Info;

int OnInit()
  {
   MAVG1_Handle = iMA(Symbol(), Period(), MAVG1_FastB, 0, MAVG1_Method, MAVG1_Price);
   MAVG2_Handle = iMA(Symbol(), Period(), MAVG2_SlowB, 0, MAVG2_Method, MAVG2_Price);
   CCI_Handle  = iCCI(Symbol(), Period(), CCI_Period, CCI_Price);

   if(MAVG1_Handle == INVALID_HANDLE || MAVG2_Handle == INVALID_HANDLE)
     {
      Alert("Failed to create MAVG1 and MAVG2 Handle.");
      return INIT_FAILED;      
     }
   
   if(CCI_Handle == INVALID_HANDLE)
     {
      Alert("Failed to create CCI Indicator Handle.");
      return INIT_FAILED;
     }
   
   ArraySetAsSeries(MAVG1_Buffer,true);
   ArraySetAsSeries(MAVG2_Buffer,true);
   ArraySetAsSeries(CCI_Buffer,true);   
   
   trade.SetExpertMagicNumber(EA_Magic);
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   IndicatorRelease(MAVG1_Handle);
   IndicatorRelease(MAVG2_Handle);
   IndicatorRelease(CCI_Handle);   
  }

void OnTick()
  {
   if(!(bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return;
   
   static int MACross  = 0;
   static int CCICross = 0;
   
   bool newBar = NewBar();
   
   if(newBar)
     {
      CopyBuffer(CCI_Handle,0,0,3,CCI_Buffer);
      double CCI1 = CCI_Buffer[1];
      double CCI2 = CCI_Buffer[2];
           
      if(CCI1>0 && CCI2<=0) CCICross =  1;
      if(CCI1<0 && CCI2>=0) CCICross = -1;
      
      CopyBuffer(MAVG1_Handle,0,0,3,MAVG1_Buffer);
      CopyBuffer(MAVG2_Handle,0,0,3,MAVG2_Buffer);
      
      double fastMA1 = MAVG1_Buffer[1];
      double fastMA2 = MAVG2_Buffer[2];
      
      double slowMA1 = MAVG2_Buffer[1];
      double slowMA2 = MAVG2_Buffer[2];
      
      if(fastMA1>slowMA1 && fastMA2<=slowMA2)
        {
         MACross = 1;
         CloseTrades(POSITION_TYPE_SELL);
        }
        
      if(fastMA1<slowMA1 && fastMA2>=slowMA2)
        {
         MACross = -1;
         CloseTrades(POSITION_TYPE_BUY);
        }
 
      if(MACross!=0 && MACross==CCICross)
        {
         if(OpenTrade(MACross)>0)
           {
            MACross  = 0;
            CCICross = 0;
           }
        }
     } 
  }

bool CloseTrades(ENUM_POSITION_TYPE type)
  {   
   bool result = true;
   
   int cnt = PositionsTotal();
   for(int i=cnt-1; i>=0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket<=0)
        {
         result = false;
         continue;
        }
      if(Pos_Info.Symbol()!=Symbol() || Pos_Info.Magic()!=EA_Magic) continue;
      
      if(Pos_Info.PositionType()==type)
        {
         result &= trade.PositionClose(ticket);
        }
     }
    return(result);
  }

bool OpenTrade(int MACross)
  {
   if(MACross<0)
     {
      return(trade.PositionOpen(Symbol(),ORDER_TYPE_SELL,Inp_Volume,SymbolBid(),0,0,TradeComment));
     }
   if(MACross>0)
     {
      return(trade.PositionOpen(Symbol(),ORDER_TYPE_BUY,Inp_Volume,SymbolAsk(),0,0,TradeComment));
     }
   return(true);   
  }

bool NewBar()
  {
   static datetime current = 0;
   datetime        now     = iTime(Symbol(), Period(), 0);
   if(now == current) return(false);
   current = now;
   return(true);
  }

double SymbolAsk(){return(SymbolInfoDouble(Symbol(),SYMBOL_ASK));}
double SymbolBid(){return(SymbolInfoDouble(Symbol(),SYMBOL_BID));}
//+------------------------------------------------------------------+
//|                                                    18_HMA_EA.mq5 |
//|                                            Author: Santiago Cruz |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+

#property copyright "Santiago Cruz"
#property link      "https://www.mql5.com/en/users/algo-trader"
#property version   "1.00"

#include <Trade/Trade.mqh>

input group "=== Trading Inputs ==="

input string             TradeComment    = "HMA EA";
static input long        EA_Magic        = 250522;          // Magic Number
static input double      LotSize         = 0.05;            // Lot Size
input  int               Stop_Loss       = 530;             // Stop Loss In Points
input  int               Take_Profit     = 1290;            // Take Profit In Points

input int                MAVG1_FastP     = 28;              // HMA MA Period
input ENUM_MA_METHOD     MAVG1_Method    = MODE_SMA;        // HMA MA Method
input ENUM_APPLIED_PRICE MAVG1_Price     = PRICE_WEIGHTED;  // HMA MA Applied Price 
input ENUM_TIMEFRAMES    MAVG1_TimeFrame = PERIOD_D1;       // HMA Timeframe  

int MAVG1_Handle;

double MAVG1_Buffer[];

CTrade         trade;
CTrade         obj_Trade;

int OnInit()
  {
    MAVG1_Handle = iCustom(_Symbol,MAVG1_TimeFrame,"Market\\HMA Color with Alerts MT5.ex5","",MAVG1_FastP,MAVG1_Method,MAVG1_Price);
    if (MAVG1_Handle == INVALID_HANDLE)
      {
        Print("Error creating 2 MA Handles: ", GetLastError());
        return(INIT_FAILED);
      }
    
    ArraySetAsSeries(MAVG1_Buffer,true);

    trade.SetExpertMagicNumber(EA_Magic); 

    return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
    IndicatorRelease(MAVG1_Handle);
  }

void OnTick()
  {
    double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
    double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);

    int currBars = iBars(_Symbol,_Period);
    static int prevBars = 0;
    if (prevBars == currBars) return;
    prevBars = currBars;

    CopyBuffer(MAVG1_Handle,1,0,3,MAVG1_Buffer);
    Print("MAVG1_Buffer[0][1][2]: ");
    ArrayPrint(MAVG1_Buffer);

    Comment("MA Fast[0]:",MAVG1_Buffer[0],"\n",
            "MA Fast[1]:",MAVG1_Buffer[1],"\n",
            "MA Fast[2]:",MAVG1_Buffer[2]);    
    
    if(MAVG1_Buffer[1]==0 && MAVG1_Buffer[2]==1){
      Print("BUY SIGNAL GENERATED");
      obj_Trade.Buy(LotSize,_Symbol,Ask,Bid-Stop_Loss*_Point,Bid+Take_Profit*_Point);
    } 
    else if (MAVG1_Buffer[1]==1 && MAVG1_Buffer[2]==0){
      Print("SELL SIGNAL GENERATED");
      obj_Trade.Sell(LotSize,_Symbol,Bid,Ask+Stop_Loss*_Point,Ask-Take_Profit*_Point);
    }
  } 
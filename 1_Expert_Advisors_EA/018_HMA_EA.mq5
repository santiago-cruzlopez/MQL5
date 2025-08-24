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
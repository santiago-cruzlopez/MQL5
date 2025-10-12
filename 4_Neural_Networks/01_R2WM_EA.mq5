//+------------------------------------------------------------------+
//|                                                   01_R2WM_EA.mq5 |
//|                                      Santiago Cruz, AlgoNet Inc. |
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
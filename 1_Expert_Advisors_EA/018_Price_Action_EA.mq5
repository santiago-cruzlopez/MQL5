//+------------------------------------------------------------------+
//|                                           18.Price_Action_EA.mq5 |
//|                                      Santiago Cruz, AlgoNet Inc. |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+

/*
   Timeframe Daily
   2 Bar pattern on close of the bar
   Direction of the Firtst Bar doesn't matter.
   Second Bar:
               - Downbar if bearish and close is below of first bar
               - Upbar if bullish and close is above the gih of first bar
               
   On Downbar enter BUY during next bar if price crosses second bar high.
   On Upbar enter  SELL during next bar if price crosses second bar low.
   Close on firtst close of a bar in profit.
   Close after 10 bars of not before.
*/


#property copyright "Santiago Cruz, AlgoNet Inc."
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

input group "=== Trading Inputs ==="

input string             TradeComment   = "Scalping Price Action EA";
static input long        EA_Magic       = 250128;       //Magic Number
input double             Inp_LotSize    = 0.01;         //Trade Volume

//---Global Variables
CTrade trade;
CPositionInfo PositionInfo;
double BuyEntryPrice = 0;
double SellEntryPrice = 0;

const int OldBarIndex = 10;


int OnInit()
  {
   
   
   trade.SetExpertMagicNumber(EA_Magic);
   
   IsNewBar();
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
  
  }

void OnTick()
  {
   if(!IsMarketOpen()) return;
   
   if(IsNewBar())
     {
      CloseTrades();
      ResetEntryPrices();
     }
   
   MqlTick tick;
   SymbolInfoTick(Symbol(), tick);
   
   if(BuyEntryPrice>0 && tick.ask>=BuyEntryPrice) OpenTrade(ORDER_TYPE_BUY,tick.ask);
   if(SellEntryPrice>0 && tick.bid<=SellEntryPrice) OpenTrade(ORDER_TYPE_SELL, tick.bid);      
  }
  
void CloseTrades()
  {
   datetime oldBarTime = iTime(Symbol(), Period(), OldBarIndex);
   
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(!PositionInfo.SelectByIndex(i))  continue;
      if(PositionInfo.Symbol()!=Symbol()) continue;
      if(PositionInfo.Magic()!= EA_Magic) continue;
      
      double profit = PositionInfo.Profit();
      datetime time = PositionInfo.Time();
      if(profit>0 || time<oldBarTime)
        {
         trade.PositionClose(PositionInfo.Ticket());
        }
     }  
  }  

void ResetEntryPrices()
  {
   MqlRates rates[];
   CopyRates(Symbol(),Period(),0,3,rates);
   ArraySetAsSeries(rates,true);
   
   BuyEntryPrice = 0;
   SellEntryPrice = 0;
   
   if(rates[1].close>rates[1].open && rates[1].close>rates[2].high) SellEntryPrice = rates[1].low;
   if(rates[1].close<rates[1].open && rates[1].close<rates[2].low) BuyEntryPrice = rates[1].high;       
  }
  
void OpenTrade(ENUM_ORDER_TYPE type, double price)
  {   
   price = NormalizeDouble(price, Digits());
   
   if(!trade.PositionOpen(Symbol(), type, Inp_LotSize, price, 0, 0, TradeComment))
     {
      PrintFormat("Open Failed for %s, %s, price = %f", Symbol(), EnumToString(type), price);
     }
   
   BuyEntryPrice = 0;
   SellEntryPrice = 0;
        
  }  

bool IsMarketOpen()
  {
   MqlDateTime time;
   TimeTradeServer(time);
   
   ENUM_DAY_OF_WEEK dow = (ENUM_DAY_OF_WEEK)time.day_of_week;
   datetime seconds = time.hour * 3600 + time.min*60 + time.sec;
   
   datetime fromTime;
   datetime toTime;
   
   for(int session=0;session<20;session++)
     {
      if(!SymbolInfoSessionTrade(Symbol(), dow, session, fromTime, toTime))
        {
         return false;
        }
      if(seconds>=fromTime && seconds<=toTime) return true; 
     }
     
   return false;     
  }
  
bool IsNewBar()
  {
   static datetime previousTime = 0;
   datetime currentTime = iTime(Symbol(),Period(),0);
   if(previousTime == currentTime) return false;
   
   previousTime = currentTime;
   return true;
  }
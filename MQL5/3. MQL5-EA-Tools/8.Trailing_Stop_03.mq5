#property copyright "Santiago Cruz, AlgoNet Inc."
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"
#property strict

#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/PositionInfo.mqh>

input group "=== Trading Inputs ==="

input  int               WhenToBreak    = 20;           //When to Breakeven in pips
input  int               BreakBy        = 5;            //Break even in pips
input  int               WhenToTrail    = 50;           //When to Start Trailing in pips
input  int               TrailBy        = 20;           //TrailingStop in pips
input  int               Slippage       = 10;

double   m_whentobreak;
double   m_breakby;
double   m_whentotrail;
double   m_trailby;

CTrade   trade;
CSymbolInfo m_symbol;
CPositionInfo PositionInfo;

int OnInit()
  {
   trade.SetDeviationInPoints(Slippage);   
   trade.SetExpertMagicNumber(EA_Magic);
   
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  { 
  
  }

void OnTick()
  {
   if(PositionsTotal()>0)
     {
      BreakEven();
      TrailingStopLoss();
     }
  }

void BreakEven()
  {
   m_whentobreak = WhenToBreak*_Point;
   m_breakby= BreakBy*_Point;
   if(_Digits==5 || _Digits==3){m_whentobreak=m_whentobreak*10;}
   
   for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if(!PositionInfo.SelectByIndex(i))
        {
         continue;
        }
      if(PositionInfo.Magic() != EA_Magic)
        {
         continue;
        }
      if(PositionInfo.Symbol() != m_symbol.Name())
        {
         continue;
        }

      double current_sl = PositionInfo.StopLoss();
      double openingPrice = PositionInfo.PriceOpen();
      if(PositionInfo.PositionType()==POSITION_TYPE_BUY)
        {
         if(current_sl>=openingPrice)
           {
            continue;
           }
        }
      if(PositionInfo.PositionType()==POSITION_TYPE_SELL)
        {
         if(current_sl!=0 && current_sl<=openingPrice)
           {
            continue;
           }
        }
      //---Checking if price has arrived at BE point
      double breakevenprice = PositionInfo.PositionType()==POSITION_TYPE_BUY ? openingPrice+m_whentobreak : openingPrice-m_whentobreak;
      double current_price = PositionInfo.PriceCurrent();

      if(PositionInfo.PositionType()==POSITION_TYPE_BUY)
        {
         if(current_price<breakevenprice)
           {
            continue;
           }
        }
      else
        {
         if(current_price>breakevenprice)
           {
            continue;
           }
        }
      //---Breaking even
      double new_sl=PositionInfo.PositionType() == POSITION_TYPE_BUY ? openingPrice + m_breakby : openingPrice - m_breakby;

      //---Modify position
      if(!trade.PositionModify(PositionInfo.Ticket(),new_sl,PositionInfo.TakeProfit()))
        {
         Alert("Error Modifying position [%d]",GetLastError());
        }
     }
  }
  
void TrailingStopLoss()
  {
   m_trailby = TrailBy*_Point;
   m_whentotrail = WhenToTrail*_Point;
   if(_Digits==5 || _Digits==3){
      m_trailby=m_trailby*10;
      m_whentotrail=m_whentotrail*10;}

   for(int i = PositionsTotal()-1; i>=0; i--)
     {
      if(!PositionInfo.SelectByIndex(i))
        {
         continue;
        }
      if(PositionInfo.Magic() != EA_Magic)
        {
         continue;
        }
      if(PositionInfo.Symbol() != m_symbol.Name())
        {
         continue;
        }
      //---Getting the Stoploss and OpenPrice
      double current_sl = PositionInfo.StopLoss();
      double opening_price = PositionInfo.PriceOpen();
      double current_price = PositionInfo.PriceCurrent();

      //---Checking if Price Has reached the trailmark
      double trailprice = PositionInfo.PositionType()==POSITION_TYPE_BUY ? opening_price + m_whentotrail : opening_price - m_whentotrail;

      if(PositionInfo.PositionType()==POSITION_TYPE_BUY)
        {
         if(current_price < trailprice)
           {
            continue;
           }
        }
      else
        {
         if(current_price > trailprice)
           {
            continue;
           }
        }

      //---Getting the new sl and checking if position sl has moved
      double new_sl = PositionInfo.PositionType()==POSITION_TYPE_BUY ? current_price - m_trailby : current_price + m_trailby;

      //---Checking if new SL is valid
      if(PositionInfo.PositionType()==POSITION_TYPE_BUY && new_sl < current_sl)
        {
         continue;
        }
      if(PositionInfo.PositionType()==POSITION_TYPE_SELL && new_sl > current_sl)
        {
         continue;
        }

      ulong m_ticket = PositionInfo.Ticket();
      double TP = PositionInfo.TakeProfit();

      if(!trade.PositionModify(m_ticket,new_sl,TP))
        {
         Alert("Error Modifying position [%d]",GetLastError());
        }
     }
}

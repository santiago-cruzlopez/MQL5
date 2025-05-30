//+------------------------------------------------------------------+
//|                                                   TSI_ATR_EA.mq5 |
//|                                            Author: Santiago Cruz |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz"
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/SymbolInfo.mqh>


//---Martingale
enum ENUM_MARTINGALE
  {
   Martingale_sys,
   AntiMartingale_sys
  };

//---Input parameters for EA
input int Stoploss =46;          //Stoploss in pips
input int TakeProfit = 140;      //Takeprofit in pips
input int EA_Magic = 12345;      //EA magic number
input double Lotsize = 0.01;     //Lotsize
input int Slippage = 10;
input bool Buy = true;          //Allow Buying
input bool Sell = true;          //Allow Selling
input string BuyOrderComment = "A buy has been Successfully executed";
input string SellOrderComment = "A sell has been Successfully executed";

//---Martingale Input Variable
input bool UseMartingale = true;
input ENUM_MARTINGALE Martingale_type = Martingale_sys;
input double Martingale_multiplier = 2;
input int Martingale_limit = 4;

//---Money Management Input Variable
input bool UseATR_MM = false;          //ATR-Based position sizing
input int ATR_Period = 20;
input double ATR_Multiplier = 1.0;
input double Risk = 2;              //Percentage Risk total Account
input double Fixed_balance = 0;
input double MoneyRisk = 0;
input bool UseMoneynotpercentage = false; //Use Money Risk Not Percentage
input bool UseEquitynotbalance = false;   //Use Equity Not Money Risk Calc
input int LotDigits = 2;            //Decimal places in the lotsize

//---Breakeven input variables
input bool UseBreakEven = true;     //Use breakeven
input int WhenToBreak = 20;         //When to Breakeven in pips
input int BreakBy = 5;              //Break even in pips

//---Trailing stop input variables
input bool UseTrailing = true;     //Use trailing stop
input int WhenToTrail = 50;         //When to Start Trailing in pips
input int TrailBy = 20;              //TrailingStop in pips

//---Input parameters for Indicator
//--- input parameters for the mainline
input int      ema1=25;                //First smoothing period
input int      ema2=13;                //Second smoothing period

//--- input parameters for the signal line
input int sMAp = 10;                    //Signal line period
input ENUM_MA_METHOD MAmode = MODE_EMA; //Mode of MA for the signal line

//---Other global parameters
int TSICDHandle, ATRHandle;
double TSI_mline[],TSI_sline[];
double STP,TKP;
ulong LastBars = 0;
double Ask,Bid,m_volume;

//----
double m_whentobreak;
double m_breakby;
double m_whentotrail;
double m_trailby;

//---Creating some Objects
CTrade *Trade;
CPositionInfo PositionInfo;
CSymbolInfo m_symbol;
CDealInfo m_deal;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---Getting the indicator handles
   TSICDHandle = iCustom(_Symbol,_Period,"TSI_CD",ema1,ema2,sMAp,MAmode);
   ATRHandle   = iATR(_Symbol,PERIOD_CURRENT,ATR_Period);

//---Initializing the Trade Objects
   Trade = new CTrade;
   Trade.SetDeviationInPoints(Slippage);
   Trade.SetExpertMagicNumber(EA_Magic);
   m_symbol.Name(Symbol());

//---Check if valid handles are returned
   if(TSICDHandle<0)
     {
      Alert("Error creating Handles for indicators -Error: ",GetLastError());
      return(0);
     }

//---Standardise the currency digits for different pairs
   STP = Stoploss*_Point;
   TKP = TakeProfit*_Point;
   m_whentobreak = WhenToBreak*_Point;
   m_breakby= BreakBy*_Point;
   m_trailby = TrailBy*_Point;
   m_whentotrail = WhenToTrail*_Point;

   if(_Digits==5||_Digits==3)
     {
      STP=STP*10;
      TKP=TKP*10;
      m_whentobreak=m_whentobreak*10;
      m_trailby=m_trailby*10;
      m_whentotrail=m_whentotrail*10;
     }

//---Checking the adequecy of the number of bars in history
   if(Bars(_Symbol,_Period)<500)
     {
      Alert("We have less than enough bars, EA will now exit");
      return(0);
     }
//---Setting our array to the as series flag
   ArraySetAsSeries(TSI_mline,true);
   ArraySetAsSeries(TSI_sline,true);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---Releasing indicator handles
   IndicatorRelease(TSICDHandle);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---Checking if we are able to trade
   if((!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))||(!TerminalInfoInteger(TERMINAL_CONNECTED))||(SymbolInfoInteger(_Symbol,SYMBOL_TRADE_MODE)!=SYMBOL_TRADE_MODE_FULL))
     {
      return;
     }

//--- Check if we have a newbar
   ulong bars = Bars(_Symbol,PERIOD_CURRENT);
   if(LastBars!=bars)
     {
      LastBars=bars;
     }
   else
     {
      return;
     }

//---Defining MQL structures to be used for trading
   MqlTick latest_price;                  //To be used to get the latest information about prices

//---Checking if we have the latest price quote
   if(!SymbolInfoTick(_Symbol,latest_price))
     {
      Alert("Error getting the latest price quote - Error: ",GetLastError(),"!!");
      return;
     }

//---Copying and checking indicator values
   if(CopyBuffer(TSICDHandle,2,0,3,TSI_mline)<0||CopyBuffer(TSICDHandle,3,0,3,TSI_sline)<0)
     {
      Alert("Error copying the indicator buffers. Error: ",GetLastError());
      return;
     }

//---Getting the potential loss value based on the current ATR
   if(UseATR_MM)
     {
      double ATR[1];
      if(CopyBuffer(ATRHandle,0,1,1,ATR)!=1)
        {
         return;
        }
      STP = ATR[0]*ATR_Multiplier;
     }

//---Checking for the presence of an open position
   bool Tradeopened = false;

   if(PositionsTotal()>0)
     {
      Tradeopened = true;
      if(UseBreakEven)
        {
         BreakEven();
        }
      if(UseTrailing)
        {
         TrailingStopLoss();
        }
     }
//Checking for market entry signals
   bool Buycondition = false;
   bool Sellcondition = false;

//Buy order conditions
   if(Tradeopened==false)
     {
      if(Buy==true)
        {
         if((TSI_mline[1]>TSI_sline[1])&&(TSI_mline[2]<TSI_sline[2]))
           {
            Buycondition=true;
           }
        }
     }
//Sell order conditions
   if(Tradeopened==false)
     {
      if(Sell==true)
        {
         if((TSI_mline[1]<TSI_sline[1])&&(TSI_mline[2]>TSI_sline[2]))
           {
            Sellcondition=true;
           }
        }
     }
//---Executing a buy trade
   if(Buycondition==true)
     {
      fBuy();
     }

//---Executing a sell trade
   if(Sellcondition==true)
     {
      fSell();
     }
  }

//+------------------------------------------------------------------+
//|Entering a Buy Order                                              |
//+------------------------------------------------------------------+
void fBuy()
  {
   m_volume = GetLotSize();
   Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   Trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,m_volume,Ask,Ask-STP,Ask+TKP,BuyOrderComment);
  }

//+------------------------------------------------------------------+
//|Entering a Sell Order                                              |
//+------------------------------------------------------------------+
void fSell()
  {
   m_volume = GetLotSize();
   Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   Trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,m_volume,Bid,Bid+STP,Bid-TKP,BuyOrderComment);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|Breaking Even                                                     |
//+------------------------------------------------------------------+
void BreakEven()
  {
//---Loop through all open positions
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

      //---Checking if SL is in profit

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
      if(!Trade.PositionModify(PositionInfo.Ticket(),new_sl,PositionInfo.TakeProfit()))
        {
         Alert("Error Modifying position [%d]",GetLastError());
        }

     }
  }
//+------------------------------------------------------------------+
//|Trailing Stop Function                                            |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingStopLoss()
  {
//---Loop through all open positions
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

      if(!Trade.PositionModify(m_ticket,new_sl,TP))
        {
         Alert("Error Modifying position [%d]",GetLastError());
        }
     }
  }

//+------------------------------------------------------------------+
//| Getting the LotSize Function                                     |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetLotSize()
  {
//Check for the LotSize to Use
   double d_lot = 0.0;
   if(UseMartingale)
     {
      d_lot = Martingale();
     }
   else
      if(UseATR_MM)
        {
         d_lot = ATR_MM();
        }
      else
        {
         d_lot = Lotsize;
        }
//Check if d_lot is bigger than the Maximum volume allowed
   if(d_lot > SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX))
     {
      d_lot = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
     }

//Check if d_lot is less than the Maximum volume allowed
   if(d_lot < SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN))
     {
      d_lot = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
     }

   return d_lot;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Martingale()
  {
///---Checking past trades to count won and lost positions
   int WinCount = 0, LossCount = 0;

   if(HistorySelect(0,TimeCurrent()))
     {
      int total = HistoryDealsTotal();
      for(int i= total-1;i>=0;i--)
        {
         if(!m_deal.SelectByIndex(i))
           {
            continue;
           }
         if(m_deal.Magic() != EA_Magic)
           {
            continue;
           }
         if(m_deal.Symbol() != _Symbol)
           {
            continue;
           }
         //---Check that the position is a Closed Deal
         if(m_deal.Entry() != DEAL_ENTRY_OUT)
           {
            continue;
           }
         //---Checking if it was a profit or losed trade
         //---Count the Losses if won trades are not 0
         if(WinCount==0 && m_deal.Profit()<0)
           {
            LossCount=LossCount+1;  //++
           }
         else
            if(LossCount == 0 && m_deal.Profit() > 0)
              {
               WinCount=WinCount+1;
              }
            else
              {
               break;
              }
        }
     }

//---Determining the count based on type of Martingale
   int ConsecutiveCount = 0;
   if(Martingale_type == Martingale_sys)
     {
      ConsecutiveCount=LossCount;
     }
   else
     {
      ConsecutiveCount=WinCount;
     }
//---Check if Consecutive count doesn't exceed the Martingale Limit
   if(ConsecutiveCount>Martingale_limit)
     {
      ConsecutiveCount = Martingale_limit;
     }

//---Calculating the Martingale Lotsize
   double d_lot;
   d_lot = Lotsize * MathPow(Martingale_multiplier,ConsecutiveCount);

   return d_lot;
  }

//+------------------------------------------------------------------+
//| ATR-Money Management                                             |
//+------------------------------------------------------------------+
double ATR_MM()
  {
   double Size, RiskMoney, d_lot = 0.0;

   if(AccountInfoString(ACCOUNT_CURRENCY)=="")
     {
      return(-1);
     }
   if(Fixed_balance>0)
     {
      Size = Fixed_balance;
     }
   else
      if(UseEquitynotbalance)
        {
         Size = AccountInfoDouble(ACCOUNT_EQUITY);
        }
      else
        {
         Size = AccountInfoDouble(ACCOUNT_BALANCE);
        }

   if(!UseMoneynotpercentage)
     {
      RiskMoney = Size * Risk/100;
     }
   else
     {
      RiskMoney=MoneyRisk;
     }

   double Tickvalue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double Ticksize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if((STP!=0)&&(Tickvalue!=0)&&(Ticksize!=0))
     {
      d_lot = NormalizeDouble(RiskMoney/(STP*Tickvalue/Ticksize),LotDigits);
     }

//---Check if d_lot is bigger than the Maximum volume allowed
   if(d_lot > SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX))
     {
      d_lot = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
     }

//---Check if d_lot is less than the Maximum volume allowed
   if(d_lot < SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN))
     {
      d_lot = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
     }

   return d_lot;

  }


//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

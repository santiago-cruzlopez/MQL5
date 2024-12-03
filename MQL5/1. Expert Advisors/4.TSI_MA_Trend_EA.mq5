//+------------------------------------------------------------------+
//|                                            9.TSI_MA_Trend_EA.mq5 |
//|                                      Santiago Cruz, AlgoNet Inc. |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz, AlgoNet Inc."
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| Enumeration for Martingale                                       |
//+------------------------------------------------------------------+
enum ENUM_MARTINGALE
  {
   Martingale_sys,     //Martingale
   AntiMartingale_sys //AntiMartingale (reverse MArtingale)
  };

//---Input parameters for EA
input int Stoploss =46;           //Stoploss in pips
input int TakeProfit = 140;      //Takeprofit in pips
input int EA_Magic = 12345;     //EA magic number
input double Lotsize = 0.05;   //Lotsize
input int Slippage = 10;
input bool Buy = true;        //Allow Buying
input bool Sell = true;      //Allow Selling
input string BuyOrderComment = "A buy has been Successfully executed";
input string SellOrderComment = "A sell has been Successfully executed";

//---Breakeven input variables
input bool UseBreakEven = true;     //Use breakeven
input int WhenToBreak = 20;         //When to Breakeven in pips
input int BreakBy = 5;             //Break even in pips

//---Close at opposite signal
input bool Close_opposite = false;    //Close at opposite signal

//---Martingale input variables
input bool     UseMrtingale   = false;                       //Use Martingale Systems
input ENUM_MARTINGALE InpMartingaleType = Martingale_sys;   //Martingale Type
input double InpMaringaleMultiplier = 2;                   //Martingale Multiplier
input int      InpMartingaleLimit  = 4;                   //Martingale Limit

//---Money management input variables
input bool UseATR_MM = false;                   //ATR-based position sizing
input int ATR_Period = 20;                     //ATR Period
input double ATR_Multiplier = 1.0;            //ATR Multipliplier
input double Risk = 2.0;                     //Percentage risk
input double Fixed_balance = 0;             //Fixed balance used if greater than 0
input double MoneyRisk     =0;             //Money risked used if greater than 0
input bool UseMoneynotpercentage = false; //Use Money risk not Percentage
input bool UseEquitynotbalance = false;  //Use Equity not Money for risk calc
input int LotDigits = 2;                //Decimal places in the lotsize

//---Trailing stop input variables
input bool UseTrailing = true;     //Use trailing stop
input int WhenToTrail = 50;        //When to Start Trailing in pips
input int TrailBy = 20;           //TrailingStop in pips

//---Input parameters for Indicator
//--- input parameters for the mainline
input int      ema1=25;                //First smoothing period
input int      ema2=13;               //Second smoothing period

//--- input parameters for the signal line
input int sMAp = 10;                     //Signal line period
input ENUM_MA_METHOD MAmode = MODE_EMA; //Mode of MA for the signal line

//--- input parameters for Moving Average
input int            MAPeriod1=100;           // Longterm MA Period
input int            MAShift1=0;             // Longterm MA Shift
input ENUM_MA_METHOD MAMethod1=MODE_EMA;    // Longterm MA Method
input int            MAPeriod2=50;         // Shortterm MA Period
input int            MAShift2=0;          // Shortterm MA Shift
input ENUM_MA_METHOD MAMethod2=MODE_EMA; // Shortterm MA Method


//---Other global parameters
int TSICDHandle,ATRHandle, MAHandle1, MAHandle2;          //Handle for the TSICD indicator
double TSI_mline[],TSI_sline[],MAval1[],MAval2[];        //Arrays for storing indicator values
double STP,TKP;                                         //Stoploss & TakeProfit intermediates
ulong LastBars = 0;                                    //Previously counted Bars on the chart
double Ask,Bid,m_volume;                              //Ask, Bid and Lotsize
bool HaveLongPosition, HaveShortPosition;            //Information about trade status

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
   ATRHandle = iATR(_Symbol,PERIOD_CURRENT,ATR_Period);
   MAHandle1 = iMA(_Symbol,PERIOD_CURRENT,MAPeriod1,MAShift1,MAMethod1,PRICE_CLOSE);
   MAHandle2 = iMA(_Symbol,PERIOD_CURRENT,MAPeriod2,MAShift2,MAMethod2,PRICE_CLOSE);

//---Initializing the Trade Objects
   Trade = new CTrade;
   Trade.SetDeviationInPoints(Slippage);
   Trade.SetExpertMagicNumber(EA_Magic);
   m_symbol.Name(Symbol());

//---Check if valid handles are returned
   if((TSICDHandle<0)&&(MAHandle1<0)&&(MAHandle2<2))
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
   ArraySetAsSeries(MAval1,true);
   ArraySetAsSeries(MAval2,true);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---Releasing indicator handles
//IndicatorRelease(TSICDHandle);
//IndicatorRelease(MAHandle1);
//IndicatorRelease(MAHandle2);
   delete Trade;
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
   if(CopyBuffer(TSICDHandle,2,0,3,TSI_mline)<0||CopyBuffer(TSICDHandle,3,0,3,TSI_sline)<0||CopyBuffer(MAHandle1,0,0,3,MAval1)<0||CopyBuffer(MAHandle2,0,0,3,MAval2)<0)
     {
      Alert("Error copying the indicator buffers. Error: ",GetLastError());
      return;
     }

//---Getting the potential loss value based on the current ATR.
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
   GetPositionStates();

   if(PositionsTotal()>0)
     {
      if(UseBreakEven)
        {
         BreakEven();
        }
      if(UseTrailing)
        {
         TrailingStopLoss();
        }
     }

//Close conditions
   bool SellClose = false;
   bool BuyClose = false;

//Checking for market entry signals
   bool Buycondition = false;
   bool Sellcondition = false;

//---Buy Close signals
   if((TSI_mline[1]<TSI_sline[1])&&(TSI_mline[2]>TSI_sline[2]))
     {
      BuyClose=true;
     }

//---Sell Close signals
   if((TSI_mline[1]>TSI_sline[1])&&(TSI_mline[2]<TSI_sline[2]))
     {
      SellClose=true;
     }

//Closing trades using an indicator
   if(Close_opposite)
     {
      GetPositionStates();
      if(HaveLongPosition&&BuyClose)
        {
         ClosePrevious();
        }
      if(HaveShortPosition&&SellClose)
        {
         ClosePrevious();
        }
     }

//Buy order conditions
   if(MAval2[1]>MAval1[1])
     {
      if((TSI_mline[1]>TSI_sline[1])&&(TSI_mline[2]<TSI_sline[2]))
        {
         Buycondition=true;
        }
     }

//Sell order conditions
   if(MAval2[1]<MAval1[1])
     {
      if((TSI_mline[1]<TSI_sline[1])&&(TSI_mline[2]>TSI_sline[2]))
        {
         Sellcondition=true;
        }
     }


//---Executing a buy trade
   if(!HaveLongPosition)
     {
      if(Buy)
        {
         if(Buycondition==true)
           {
            fBuy();
           }
        }
     }

//---Executing a sell trade
   if(!HaveShortPosition)
     {
      if(Sell)
        {
         if(Sellcondition==true)
           {
            fSell();
           }
        }
     }

//Closing trades using an indicator
   if(Close_opposite)
     {
      GetPositionStates();
      if(HaveLongPosition&&BuyClose)
        {
         ClosePrevious();
        }
      if(HaveShortPosition&&SellClose)
        {
         ClosePrevious();
        }
     }
  }

//+------------------------------------------------------------------+
//| Check what position is open                                      |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetPositionStates()
  {
//Checking if there are open positions and their type
   if(PositionInfo.Select(_Symbol))
     {
      if(PositionInfo.PositionType()==POSITION_TYPE_BUY)
        {
         HaveLongPosition=true;
         HaveShortPosition=false;
        }
      else
         if(PositionInfo.PositionType()==POSITION_TYPE_SELL)
           {
            HaveLongPosition=false;
            HaveShortPosition=true;
           }
         else
           {
            HaveLongPosition=false;
            HaveShortPosition=false;
           }
     }
  }

//+------------------------------------------------------------------+
//|Close Open Positions                                              |
//+------------------------------------------------------------------+
void ClosePrevious()
  {
   Trade.PositionClose(_Symbol,Slippage);
   if((Trade.ResultRetcode() != 10008)&&(Trade.ResultRetcode() != 10009)&&(Trade.ResultRetcode() != 10010))
     {
      Alert("Failed to close open position - Return code: ",Trade.ResultRetcodeDescription());
     }
   else
     {
      return;
     }
  }


//+------------------------------------------------------------------+
//|Entering a Buy Order                                              |
//+------------------------------------------------------------------+
void fBuy()
  {
   m_volume = GetLotSize();
   Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   if(Close_opposite)
     {
      Trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,m_volume,Ask,0,0,BuyOrderComment);
     }
   else
     {
      if(PositionsTotal()==0)
        {
         Trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,m_volume,Ask,Ask-STP,Ask+TKP,BuyOrderComment);
        }
     }
  }

//+------------------------------------------------------------------+
//|Entering a Sell Order                                              |
//+------------------------------------------------------------------+
void fSell()
  {
   m_volume = GetLotSize();
   Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   if(Close_opposite)
     {
      Trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,m_volume,Bid,0,0,BuyOrderComment);
     }
   else
     {
      if(PositionsTotal()==0)
        {
         Trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,m_volume,Bid,Bid+STP,Bid-TKP,BuyOrderComment);
        }
     }

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
//| Trailing Stop Function                                           |
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
//|Getting the Lotsize                                               |
//+------------------------------------------------------------------+
double GetLotSize()
  {
//Check which lotsize to use
   double d_lot = 0.0;
   if(UseMrtingale)
      d_lot = Martingale();

   else
      if(UseATR_MM)
         d_lot = ATR_MM();
      else
         d_lot = Lotsize;

//---Check if d_lot is bigger than Maximum volume allowed
   if(d_lot > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX))
     {
      d_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
     }
//---Check if d_lot is smaller that the Minimum volume allowed
   if(d_lot < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN))
     {
      d_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
     }
   return d_lot;
  }

//+------------------------------------------------------------------+
//|Martingale function                                               |
//+------------------------------------------------------------------+
double Martingale()
  {

//--Checking past trades to Count Won and Lost Positions
   int WinCount = 0, LossCount = 0;

   if(HistorySelect(0, TimeCurrent()))
     {
      int total = HistoryDealsTotal();
      for(int i = total - 1; i >= 0; i--) //Always Start Counting from Highest Index to lowest Index
        {
         //Exclude some past deals we are not interested in:
         if(!m_deal.SelectByIndex(i))
           {
            continue;
           }
         if(m_deal.Magic() != EA_Magic)
           {
            continue;
           }
         if(m_deal.Symbol() != Symbol())
           {
            continue;
           }


         //--Check that the Deal is a Close Deal not an open deal
         if(m_deal.Entry() != DEAL_ENTRY_OUT)
           {
            continue;
           }


         //---Check if it is Profit or loss.
         //---Count Loss only if Won trades is 0
         if(WinCount == 0 && m_deal.Profit() < 0)
           {
            LossCount++;
           }
         else //Count Won only if Loss trade is 0
            if(LossCount == 0 && m_deal.Profit() > 0)
              {
               WinCount++;
              }
            else //We end our Counting if conditions change
              {
               break;
              }
        }
     }

//---Determining the consecutive trade count
   int ConsecutiveCount = 0;
   if(InpMartingaleType == Martingale_sys)
     {
      ConsecutiveCount = LossCount;
     }
   else
     {
      ConsecutiveCount = WinCount;
     }

//---Check if Consecutive Count does not exceeded Martingale Limit
   if(ConsecutiveCount > InpMartingaleLimit)
     {
      ConsecutiveCount = InpMartingaleLimit;
     }

//---Determining the lot size to use
   double d_lot;
   d_lot = Lotsize * MathPow(InpMaringaleMultiplier, ConsecutiveCount);
//---
   return d_lot;
  }

//+------------------------------------------------------------------+
//|ATR-Money management                                                                  |
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
   double Ticksize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);

   if((STP!=0)&&(Tickvalue!=0)&&(Ticksize!=0))
     {
      d_lot = NormalizeDouble(RiskMoney/(STP*Tickvalue/Ticksize),LotDigits);
     }
//---Check if d_lot is bigger than Maximum volume allowed
   if(d_lot > SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX))
     {
      d_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
     }
//---Check if d_lot is smaller that the Minimum volume allowed
   if(d_lot < SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN))
     {
      d_lot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
     }
   return d_lot;
  }



//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

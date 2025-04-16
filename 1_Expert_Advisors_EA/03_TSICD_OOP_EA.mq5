//+------------------------------------------------------------------+
//|                                                 TSICD_OOP_EA.mq5 |
//|                                            Author: Santiago Cruz |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz"
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

//---Input parameters for EA
input int Stoploss =46;          //Stoploss in pips
input int TakeProfit = 140;      //Takeprofit in pips
input int EA_Magic = 12345;      //EA magic number
input double Lotsize = 0.05;     //Lotsize
input int Slippage = 100;
input bool Buy = true;          //Allow Buying
input bool Sell = true;          //Allow Selling
input string BuyOrderComment = "A Buy Order has been Successfully Executed";
input string SellOrderComment = "A Sell Order has been Successfully Executed";

//---Input parameters for Indicator
//--- input parameters for the mainline
input int      ema1=25;                //First smoothing period
input int      ema2=13;                //Second smoothing period

//--- input parameters for the signal line
input int sMAp = 10;                    //Signal line period
input ENUM_MA_METHOD MAmode = MODE_EMA; //Mode of MA for the signal line

//---Other global parameters
int TSICDHandle;
double TSI_mline[],TSI_sline[];
double STP,TKP;
ulong LastBars = 0;

//---Creating Trade Objects OOP
   CTrade *Trade;
   CPositionInfo PositionInfo;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---Getting the indicator handles
   TSICDHandle = iCustom(_Symbol,_Period,"TSI_CD",ema1,ema2,sMAp,MAmode);
   
//---Initializing the Trade Objects
   Trade = new CTrade;
   Trade.SetDeviationInPoints(Slippage);
   Trade.SetExpertMagicNumber(EA_Magic);
   

//---Check if valid handles are returned
   if(TSICDHandle<0)
     {
      Alert("Error creating Handles for indicators -Error: ",GetLastError());
      return(0);
     }

//---Standardise the currency digits for different pairs
   STP = Stoploss*_Point;
   TKP = TakeProfit*_Point;

   if(_Digits==5||_Digits==3)
     {
      STP=STP*10;
      TKP=TKP*10;
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
//---Checking for the presence of an open position
   bool Tradeopened = false;

   if(PositionsTotal()>0)
     {
      Tradeopened = true;
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
//---Executing a Buy trade
   if(Buycondition==true)
     {
      fBuy();
     }

//---Executing a Sell trade
   if(Sellcondition==true)
     {
      fSell();
     }
  }

//+------------------------------------------------------------------+
//| Enter a Buy Order Function                                       |
//+------------------------------------------------------------------+
void fBuy()
{
   double Ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   Trade.PositionOpen(_Symbol,ORDER_TYPE_BUY,Lotsize,Ask,Ask-STP,Ask+TKP,BuyOrderComment);
}

//+------------------------------------------------------------------+
//| Enter a Sell Order Function                                      |
//+------------------------------------------------------------------+
void fSell()
{
   double Bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   Trade.PositionOpen(_Symbol,ORDER_TYPE_SELL,Lotsize,Bid,Bid+STP,Bid-TKP,SellOrderComment);
}

//+------------------------------------------------------------------+

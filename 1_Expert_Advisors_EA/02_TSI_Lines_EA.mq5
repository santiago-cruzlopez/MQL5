//+------------------------------------------------------------------+
//|                                                 TSI_Lines_EA.mq5 |
//|                                      Santiago Cruz, AlgoNet Inc. |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz, AlgoNet Inc."
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

//---Input Parameters for EA
   input int Stoploss = 46;      //SL in pips
   input int TakeProfit = 140;   //TP in pips
   input int EA_Magic = 12345;   //EA Metric Number
   input double Lotsize = 0.05;  //Lotsize
   input int Slippage = 100;     
   
//---Input Parameters for Indicator
//---Input Parameters for the Mainline
   input int      ema1=25;       //First Smoothing Period
   input int      ema2=13;       //Second Smoothing Period
   
//---Input Parameters for the Signal Line
   input int sMAp = 10;          //Signal Line Period
   input ENUM_MA_METHOD MAmode = MODE_EMA;

//---Other Global Parameters
   int TSICDHandle;
   double TSI_mline[],TSI_sline[];
   double STP, TKP;
   ulong LastBars = 0;   

int OnInit()
  {
//---Getting the Indicator Handles
   TSICDHandle = iCustom(_Symbol,_Period,"TSI_CD",ema1,ema2,sMAp,MAmode);
   
//---Check if Valid Handles are Returned
   if(TSICDHandle < 0)
     {
      Alert("Error creating Handles for Indicators -Error: ",GetLastError());
      return(0);
     }
     
//---Standardise the Current Digits
   STP = Stoploss*_Point;
   TKP = TakeProfit*_Point;
   
   if(_Digits==5 || _Digits==3)
     {
      STP=STP*10;
      TKP=TKP*10;
     }
     
//---Check the Number of Bars in History
   if(Bars(_Symbol,_Period) < 500)
     {
      Alert("We have less than enough bars, EA will now exit");
      return(0);
     }
//---Set Arrays to the AsSeries Flag
   ArraySetAsSeries(TSI_mline,true);
   ArraySetAsSeries(TSI_sline,true);
   return(INIT_SUCCEEDED);
  }
  

//---Expert deinitialization function                                 
void OnDeinit(const int reason)
  {
//---Release the Indicator Handles
   IndicatorRelease(TSICDHandle);
  }

                                             
void OnTick()
  {
//---Check if we are able to Trade
   if((!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) || (!TerminalInfoInteger(TERMINAL_CONNECTED)) || (SymbolInfoInteger(_Symbol,SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_FULL))
     {
      return;
     }
     
//---Check if we have a New Candlestick/Bar
   ulong bars = Bars(_Symbol, PERIOD_CURRENT);
   if(LastBars != bars)
     {
      LastBars=bars;
     }
   else
     {
      return;
     }

//---Define MQL5 Trading Structures
   MqlTick latest_price;            //To be used to get the latest information about prices
   MqlTradeRequest mrequest;        //To be used to send trade requests
   MqlTradeResult mresult;          //To be used to access trade results
   ZeroMemory(mrequest);

//---Check if we have the latest Price Quote
   if(SymbolInfoTick(_Symbol,latest_price))
     {
      Alert("Error getting the latest price quote -Error: ",GetLastError(),"!!");
      return;
     }
   
//---Copy and Check the Indicator Values
   if(CopyBuffer(TSICDHandle,2,0,3,TSI_mline) < 0 || CopyBuffer(TSICDHandle,3,0,3,TSI_sline))
     {
      Alert("Error copying the Indicator Buffer. Error: ",GetLastError());
      return;
     }

//---Check if we have Open Positions
   bool Tradeopened = false;
   
   if(PositionsTotal() > 0)
     {
      Tradeopened = true;
     }

//---Set the Marktet Entry Signals Conditions
   bool Buycondition = false;
   bool Sellcondition = false;
   
//---Buy Order Conditions
   if(Tradeopened == false)
     {
      if((TSI_mline[1] > TSI_sline[1])&&(TSI_mline[2] < TSI_sline[2]))
        {
         Buycondition = true;
        }
     }

//---Sell Order Conditions
   if(Tradeopened == false)
     {
      if((TSI_mline[1] > TSI_sline[1])&&(TSI_mline[2] > TSI_sline[2]))
        {
         Sellcondition = true;
        }
     }

//Withoud OOP, use #include <Trade\Trade.mqh> to avoid the following part of the code.
//---Set Instructions for Opening and Closing Trades
//---Executing a Buy Trade
   if(Buycondition == true)
     {
      mrequest.action = TRADE_ACTION_DEAL;
      mrequest.price  = NormalizeDouble(latest_price.ask,_Digits);
      mrequest.sl     = NormalizeDouble(latest_price.ask - STP,_Digits);
      mrequest.tp     = NormalizeDouble(latest_price.ask + TKP,_Digits);
      mrequest.symbol = _Symbol;
      mrequest.volume = Lotsize;
      mrequest.magic  = EA_Magic;
      mrequest.type   = ORDER_TYPE_BUY;
      mrequest.type_filling = ORDER_FILLING_FOK;
      mrequest.deviation    = Slippage;
      
      bool buyorder = OrderSend(mrequest,mresult);
      
//---Getting the Trade Results
      if(mresult.retcode == 10009|| mresult.retcode == 10008)
        {
         Alert("A Buy Order has been successfully placed with Ticket# : ",mresult.order,"!!");
        }
        else
          {
           Alert("A buy trade could not be placed. Error: ",GetLastError());
          }
     }

//---Executing a Sell Trade
   if(Sellcondition == true)
     {
      mrequest.action = TRADE_ACTION_DEAL;
      mrequest.price  = NormalizeDouble(latest_price.bid,_Digits);
      mrequest.sl     = NormalizeDouble(latest_price.ask + STP,_Digits);
      mrequest.tp     = NormalizeDouble(latest_price.ask - TKP,_Digits);
      mrequest.symbol = _Symbol;
      mrequest.volume = Lotsize;
      mrequest.magic  = EA_Magic;
      mrequest.type   = ORDER_TYPE_SELL;
      mrequest.type_filling = ORDER_FILLING_FOK;
      mrequest.deviation    = Slippage;
      
      bool sellorder = OrderSend(mrequest,mresult);
      
//---Getting the Trade Results
      if(mresult.retcode == 10009|| mresult.retcode == 10008)
        {
         Alert("A Sell Order has been successfully placed with Ticket# : ",mresult.order,"!!");
        }
     }
     else
       {
        Alert("A Sell trade could not be placed. Error: ",GetLastError());
       }     
  }
//+------------------------------------------------------------------+

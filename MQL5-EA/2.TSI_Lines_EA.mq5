//+------------------------------------------------------------------+
//|                                               2.TSI_Lines_EA.mq5 |
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

   return(INIT_SUCCEEDED);
  }
  

//---Expert deinitialization function                                 
void OnDeinit(const int reason)
  {
//---Release the Indicator Handles
   IndicatorRelease(TSICDHandle);
  }

//---Expert tick function                                             
void OnTick()
  {
//---

  }
//+------------------------------------------------------------------+
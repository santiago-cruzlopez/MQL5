//+------------------------------------------------------------------+
//|                                                      019_ADX.mq5 |
//|                                                    Santiago Cruz |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz"
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"
#property description "Simple EA based on MA-8 and ADX-8 with SL/TP"

#include <Trade\Trade.mqh>
CTrade trade;

//--- input parameters
input int    StopLoss   = 30;          // Stop Loss (pips)
input int    TakeProfit = 100;         // Take Profit (pips)
input int    ADX_Period = 8;           // ADX Period
input int    MA_Period  = 8;           // Moving Average Period
input int    EA_Magic   = 12345;       // EA Magic Number
input double Adx_Min    = 22.0;        // Minimum ADX Value
input double Lot        = 0.1;         // Lots to Trade

//--- other global variables
int    adxHandle;                     
int    maHandle;         
double plsDI[], minDI[], adxVal[];     // +DI, -DI, ADX buffers
double maVal[];                        // MA buffer
double p_close;                        // previous bar close price
int    STP, TKP;                       // Stop-Loss / Take-Profit in points

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   adxHandle=iADX(NULL,0,ADX_Period);
   maHandle=iMA(_Symbol,_Period,MA_Period,0,MODE_EMA,PRICE_CLOSE);

   if(adxHandle<0 || maHandle<0)
     {
      Alert("Error creating indicator handles - error: ",GetLastError());
      return(INIT_FAILED);
     }

   //--- adjust SL/TP for 5-digit / 3-digit brokers
   STP=StopLoss;
   TKP=TakeProfit;
   if(_Digits==5 || _Digits==3)
     {
      STP*=10;
      TKP*=10;
     }

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(adxHandle);
   IndicatorRelease(maHandle);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //--- enough bars?
   if(Bars(_Symbol,_Period)<60)
     {
      Alert("Less than 60 bars - EA stopped");
      return;
     }

   //--- detect new bar
   static datetime Old_Time=0;
   datetime New_Time[1];
   bool    IsNewBar=false;

   if(CopyTime(_Symbol,_Period,0,1,New_Time)>0)
     {
      if(Old_Time!=New_Time[0])
        {
         IsNewBar=true;
         Old_Time=New_Time[0];
        }
     }
   else
     {
      Alert("Error copying time data - error ",GetLastError());
      return;
     }

   if(!IsNewBar) return;   // only work on new bar

   //--- structures for trade
   MqlTick      latest_price;
   MqlTradeRequest  mrequest;
   MqlTradeResult   mresult;
   MqlRates      mrate[];
   ZeroMemory(mrequest);

   //--- get latest price
   if(!SymbolInfoTick(_Symbol,latest_price))
     {
      Alert("Error getting tick - error ",GetLastError());
      return;
     }

   //--- copy last 3 bars rates
   if(CopyRates(_Symbol,_Period,0,3,mrate)<0)
     {
      Alert("Error copying rates - error ",GetLastError());
      return;
     }

   //--- set arrays as series
   ArraySetAsSeries(mrate,true);
   ArraySetAsSeries(plsDI,true);
   ArraySetAsSeries(minDI,true);
   ArraySetAsSeries(adxVal,true);
   ArraySetAsSeries(maVal,true);

   //--- copy indicator buffers (last 3 bars)
   if(CopyBuffer(adxHandle,0,0,3,adxVal)<0 ||
      CopyBuffer(adxHandle,1,0,3,plsDI)<0 ||
      CopyBuffer(adxHandle,2,0,3,minDI)<0)
     {
      Alert("Error copying ADX buffers - error ",GetLastError());
      return;
     }
   if(CopyBuffer(maHandle,0,0,3,maVal)<0)
     {
      Alert("Error copying MA buffer - error ",GetLastError());
      return;
     }

   //--- previous bar close
   p_close=mrate[1].close;

   //--- check existing position (only one allowed)
   bool Buy_opened=false, Sell_opened=false;
   if(PositionSelect(_Symbol))
     {
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)  Buy_opened=true;
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL) Sell_opened=true;
     }

   //=================================================================
   // BUY CONDITIONS
   //=================================================================
   bool BuyCond1=(maVal[0]>maVal[1]) && (maVal[1]>maVal[2]);          // MA rising
   bool BuyCond2=(p_close>maVal[1]);                                 // price above MA
   bool BuyCond3=(adxVal[0]>Adx_Min);                                // ADX > 22
   bool BuyCond4=(plsDI[0]>minDI[0]);                                // +DI > -DI

   if(BuyCond1 && BuyCond2 && BuyCond3 && BuyCond4)
     {
      if(Buy_opened)
        {
         Alert("Buy position already open");
         return;
        }

      //--- prepare request
      mrequest.action   = TRADE_ACTION_DEAL;
      mrequest.symbol   = _Symbol;
      mrequest.volume   = Lot;
      mrequest.type     = ORDER_TYPE_BUY;
      mrequest.price    = NormalizeDouble(latest_price.ask,_Digits);
      mrequest.sl       = NormalizeDouble(latest_price.ask - STP*_Point,_Digits);
      mrequest.tp       = NormalizeDouble(latest_price.ask + TKP*_Point,_Digits);
      mrequest.deviation=100;
      mrequest.magic    = EA_Magic;
      mrequest.type_filling=ORDER_FILLING_FOK;

      OrderSend(mrequest,mresult);

      if(mresult.retcode==10009 || mresult.retcode==10008)
         Alert("Buy order placed, ticket #",mresult.order);
      else
        {
         Alert("Buy order failed - error ",GetLastError());
         ResetLastError();
        }
     }

   //=================================================================
   // SELL CONDITIONS
   //=================================================================
   bool SellCond1=(maVal[0]<maVal[1]) && (maVal[1]<maVal[2]);        // MA falling
   bool SellCond2=(p_close<maVal[1]);                                // price below MA
   bool SellCond3=(adxVal[0]>Adx_Min);                               // ADX > 22
   bool SellCond4=(plsDI[0]<minDI[0]);                               // -DI > +DI

   if(SellCond1 && SellCond2 && SellCond3 && SellCond4)
     {
      if(Sell_opened)
        {
         Alert("Sell position already open");
         return;
        }

      //--- prepare request
      mrequest.action   = TRADE_ACTION_DEAL;
      mrequest.symbol   = _Symbol;
      mrequest.volume   = Lot;
      mrequest.type     = ORDER_TYPE_SELL;
      mrequest.price    = NormalizeDouble(latest_price.bid,_Digits);
      mrequest.sl       = NormalizeDouble(latest_price.bid + STP*_Point,_Digits);
      mrequest.tp       = NormalizeDouble(latest_price.bid - TKP*_Point,_Digits);
      mrequest.deviation=100;
      mrequest.magic    = EA_Magic;
      mrequest.type_filling=ORDER_FILLING_FOK;

      OrderSend(mrequest,mresult);

      if(mresult.retcode==10009 || mresult.retcode==10008)
         Alert("Sell order placed, ticket #",mresult.order);
      else
        {
         Alert("Sell order failed - error ",GetLastError());
         ResetLastError();
        }
     }
  }
//+------------------------------------------------------------------+
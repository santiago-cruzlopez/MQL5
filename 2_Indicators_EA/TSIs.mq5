//+------------------------------------------------------------------+
//|                                             Second Indicator.mq5 |
//|                                            Author: Santiago Cruz |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz, AlgoNet Inc."
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots   2
//--- plot TSI_line
#property indicator_label1  "TSI main line"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3
#property indicator_applied_price PRICE_CLOSE

//--- plot TSI_signal line
#property indicator_label2  "TSI signal line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrBlue
#property indicator_style2  STYLE_DASH
#property indicator_width2  1

#include <MovingAverages.mqh>

//--- input parameters
input int      ema1=25;
input int      ema2=13;

//--- input parameters for the signal line
input int sMAp = 10;
input ENUM_MA_METHOD MAmode = MODE_EMA;


//--- indicator buffers
double         TSI_mlineBuffer[],
               TSI_slineBuffer[],
               MomBuffer[],
               AbsMomBuffer[],
               EMA_MomBuffer[],
               EMA_EMAMomBuffer[],
               EMA_AbsMomBuffer[],
               EMA_EMAAbsMomBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,TSI_mlineBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,TSI_slineBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,MomBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,AbsMomBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,EMA_MomBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,EMA_EMAMomBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,EMA_AbsMomBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,EMA_EMAAbsMomBuffer,INDICATOR_CALCULATIONS);
   
   //Bar starting point
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ema1+ema2-1);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ema1+ema2+sMAp);
   //Set the accuracy of displaying indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,2);
   string shortname;
   StringConcatenate(shortname,"TSI(",ema1,",",ema2,")");
   //Set a name to show in the seperate window
   PlotIndexSetString(0,PLOT_LABEL,shortname);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//If the size of the rates total is too small ...stop the program
   if(rates_total<ema1+ema2)
     {
      return (0);
     }
     
//---Calculating the values of momentum
//if it is the first call
   if(prev_calculated==0)
     {
      //Set zero values to zero indexes.
      MomBuffer[0]=0.0;
      AbsMomBuffer[0]=0.0;
     }
  int first;
  if(prev_calculated ==0)  
   {
      first =MathMax(ema1,ema2);
   }
   else
     {
      first = prev_calculated-1;
     }
   for(int i=first;i<rates_total;i++)
     {
      MomBuffer[i] = price[i] - price[i-1];
      AbsMomBuffer[i]=fabs(MomBuffer[i]);
     }

//Calculating the values of the first Smoothing
   ExponentialMAOnBuffer(rates_total,prev_calculated,1,ema1,MomBuffer,EMA_MomBuffer);
   ExponentialMAOnBuffer(rates_total,prev_calculated,1,ema1,AbsMomBuffer,EMA_AbsMomBuffer);
   
//Calculations for the second smoothing
   ExponentialMAOnBuffer(rates_total,prev_calculated,ema1,ema2,EMA_MomBuffer,EMA_EMAMomBuffer);
   ExponentialMAOnBuffer(rates_total,prev_calculated,ema1,ema2,EMA_AbsMomBuffer,EMA_EMAAbsMomBuffer);
   
//Calculating the value of our indicator
   if(prev_calculated==0)
     {
      first = ema1+ema2-1;
     }
   for(int i=first;i<rates_total;i++)
     {
      TSI_mlineBuffer[i] = 100*EMA_EMAMomBuffer[i]/EMA_EMAAbsMomBuffer[i];
     }

//Calculating the value of the signal line
   int begin2 = begin+ema1+ema2-1;
   int lwmaws = 2;
   
   switch(MAmode)
     {
      case MODE_EMA :
           ExponentialMAOnBuffer(rates_total,prev_calculated,begin2,sMAp,TSI_mlineBuffer,TSI_slineBuffer);
           break;
      case MODE_LWMA:
           LinearWeightedMAOnBuffer(rates_total,prev_calculated,begin2,sMAp,TSI_mlineBuffer,TSI_slineBuffer,lwmaws);
           break;
      case MODE_SMA:
           SimpleMAOnBuffer(rates_total,prev_calculated,begin2,sMAp,TSI_mlineBuffer,TSI_slineBuffer);
           break;
      case MODE_SMMA:
           SmoothedMAOnBuffer(rates_total,prev_calculated,begin2,sMAp,TSI_mlineBuffer,TSI_slineBuffer);
           break;

     }
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

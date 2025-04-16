//+------------------------------------------------------------------+
//|                                                       TSI_CD.mq5 |
//|                                            Author: Santiago Cruz |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz"
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   3
//--- plot TSI_CD
#property indicator_label1  "TSI_CD"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrOrangeRed,clrWhite
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
//--- plot TSI_line
#property indicator_label2  "TSI_line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
//--- plot TSI_sline
#property indicator_label3  "TSI_sline"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRosyBrown
#property indicator_style3  STYLE_DOT
#property indicator_width3  1

//--- indicator buffers
double         TSI_CDBuffer[];
double         TSI_mlineBuffer[];
double         TSI_slineBuffer[];
double         TSI_CDColors[];


//--- input parameters for the mainline
input int      ema1=25;
input int      ema2=13;

//--- input parameters for the signal line
input int sMAp = 10;
input ENUM_MA_METHOD MAmode = MODE_EMA;

int Handle;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(2,TSI_mlineBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,TSI_slineBuffer,INDICATOR_DATA);
   SetIndexBuffer(0,TSI_CDBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,TSI_CDColors,INDICATOR_COLOR_INDEX);

   
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ema1+ema2+sMAp);
   IndicatorSetInteger(INDICATOR_DIGITS,2);
   
  Handle = iCustom(_Symbol,PERIOD_CURRENT,"TSIs",ema1,ema2,sMAp,MAmode);
   
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
//----------------------------------------------------------
//Preliminary checks

//---Checking the start of the indicator
int first;
if(prev_calculated==0)
  {
   first = begin+1;
  }
else
  {
   first = prev_calculated-1;
  }
//---Checking if copying of the buffers was successful
if(CopyBuffer(Handle,0,0,rates_total-first,TSI_mlineBuffer)==-1)
  {
   return(0);
  }
if(CopyBuffer(Handle,1,0,rates_total-first,TSI_slineBuffer)==-1)
  {
   return(0);
  } 
  
//--------------------------------------------------
//indicator calculations
for(int i=first;i<rates_total;i++)
  {
   TSI_CDBuffer[i] = TSI_mlineBuffer[i] - TSI_slineBuffer[i];
   
   //adding colours
   if(TSI_CDBuffer[i]>TSI_CDBuffer[i-1])
     {
      TSI_CDColors[i]=0;
     }
   if(TSI_CDBuffer[i]<TSI_CDBuffer[i-1])
     {
      TSI_CDColors[i]=1;
     }
     string display = StringFormat("cdbuffer = %d, mlinebuffer = %d, slinebuffer = %d",TSI_CDBuffer[i],TSI_mlineBuffer[i],TSI_slineBuffer[i]);
     Comment (display);
  }
  
 

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

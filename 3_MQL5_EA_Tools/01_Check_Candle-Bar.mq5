//+------------------------------------------------------------------+
//|                                           1.Check_Candle-Bar.mq5 |
//|                                            Author: Santiago Cruz |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz"
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//For New Bar/Candle
   if(!IsNewBar()){return;}
    Print("New Bar Detected");

//For New Day
   if(!IsNewDay()){return;}
   Print("New Day For Making Money!");
  }
  
//+------------------------------------------------------------------+
//| Check for New Bar/Candle                                         |
//+------------------------------------------------------------------+ 
bool IsNewBar(){

   static datetime previousTime = 0;
   
   datetime currentTime = iTime(_Symbol,PERIOD_CURRENT,0);
   
   if(previousTime!=currentTime){
      previousTime = currentTime;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Check for a New Day                                              |
//+------------------------------------------------------------------+
bool IsNewDay(){
   
   MqlDateTime time;
   TimeToStruct(TimeCurrent(),time);
   
   static int Dateprev=0;
   int Datenow = time.day;
   
   if(Dateprev!=Datenow){ //If Dateprev is not equal, we now it is a new Day
      Dateprev = Datenow;
      return true;
   }
   return false;

}
 

//+------------------------------------------------------------------+

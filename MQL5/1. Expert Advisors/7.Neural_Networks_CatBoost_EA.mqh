#include <Trade/Trade.mqh>
//XAU - 1h.
CTrade trade;

input ENUM_TIMEFRAMES TF = PERIOD_CURRENT;
input ENUM_MA_METHOD MaMethod = MODE_SMA;
input ENUM_APPLIED_PRICE MaAppPrice = PRICE_CLOSE;
input int MaPeriodsFast = 15;
input int MaPeriodsSlow = 25;
input int MaPeriods = 200;
input double lott = 0.01;
ulong buypos = 0, sellpos = 0;
input int Magic = 0;
int barsTotal = 0;
int handleMaFast;
int handleMaSlow;
int handleMa;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(Magic);
   handleMaFast =iMA(_Symbol,TF,MaPeriodsFast,0,MaMethod,MaAppPrice);
   handleMaSlow =iMA(_Symbol,TF,MaPeriodsSlow,0,MaMethod,MaAppPrice);  
   handleMa = iMA(_Symbol,TF,MaPeriods,0,MaMethod,MaAppPrice); 
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }  

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  int bars = iBars(_Symbol,PERIOD_CURRENT);
  //Beware, the last element of the buffer list is the most recent data, not [0]
  if (barsTotal!= bars){
     barsTotal = bars;
     double maFast[];
     double maSlow[];
     double ma[];
     CopyBuffer(handleMaFast,BASE_LINE,1,2,maFast);
     CopyBuffer(handleMaSlow,BASE_LINE,1,2,maSlow);
     CopyBuffer(handleMa,0,1,1,ma);
     double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
     double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
     double lastClose = iClose(_Symbol, PERIOD_CURRENT, 1);
     //The order below matters
     if(buypos>0&& lastClose<maSlow[1]) trade.PositionClose(buypos);
     if(sellpos>0 &&lastClose>maSlow[1])trade.PositionClose(sellpos);   
     if (maFast[1]>maSlow[1]&&maFast[0]<maSlow[0]&&buypos ==sellpos)executeBuy(); 
     if(maFast[1]<maSlow[1]&&maFast[0]>maSlow[0]&&sellpos ==buypos) executeSell();
     if(buypos>0&&(!PositionSelectByTicket(buypos)|| PositionGetInteger(POSITION_MAGIC) != Magic)){
      buypos = 0;
      }
     if(sellpos>0&&(!PositionSelectByTicket(sellpos)|| PositionGetInteger(POSITION_MAGIC) != Magic)){
      sellpos = 0;
      }
    }
 }

//+------------------------------------------------------------------+
//| Expert trade transaction handling function                       |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result) {
    if (trans.type == TRADE_TRANSACTION_ORDER_ADD) {
        COrderInfo order;
        if (order.Select(trans.order)) {
            if (order.Magic() == Magic) {
                if (order.OrderType() == ORDER_TYPE_BUY) {
                    buypos = order.Ticket();
                } else if (order.OrderType() == ORDER_TYPE_SELL) {
                    sellpos = order.Ticket();
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Execute sell trade function                                      |
//+------------------------------------------------------------------+
void executeSell() {      
       double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
       bid = NormalizeDouble(bid,_Digits);
       trade.Sell(lott,_Symbol,bid);  
       sellpos = trade.ResultOrder();  
       }   

//+------------------------------------------------------------------+
//| Execute buy trade function                                       |
//+------------------------------------------------------------------+
void executeBuy() {
       double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
       ask = NormalizeDouble(ask,_Digits);
       trade.Buy(lott,_Symbol,ask);
       buypos = trade.ResultOrder();
}

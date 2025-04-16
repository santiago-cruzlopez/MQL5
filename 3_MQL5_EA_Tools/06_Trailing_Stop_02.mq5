//+------------------------------------------------------------------+
//|                                           6.Trailing_Stop_02.mq5 |
//|                                            Author: Santiago Cruz | 
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+

//Source: "https://github.com/nkanven/MT4-MT5-Trading-EA-Collections/blob/master/MQL5/Experts/Nkanven/TrendlinesEA.mq5"

#property copyright "Santiago Cruz"
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"


int Trail()
  {
   for(int i=0;i<PositionsTotal();i++)
     {
      if(PositionGetSymbol(i)==_Symbol && PositionGetInteger(POSITION_MAGIC)==Magic)
        {
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
           {
            ulong  ticket=PositionGetTicket(i);
            double pp=SymbolInfoDouble(_Symbol,SYMBOL_BID);
            double sl=PositionGetDouble(POSITION_SL);
            double op=PositionGetDouble(POSITION_PRICE_OPEN);
            double tp=PositionGetDouble(POSITION_TP);

            if(pp-op>=TrailingStart*_Point)
              {
               if(sl<pp-(TrailingStop+TrailingStep)*_Point || sl==0)
                 {
                  Modify(ticket,pp-TrailingStop*_Point,tp);
                 }
              }
           }
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
           {
            ulong  ticket=PositionGetTicket(i);
            double pp=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
            double sl=PositionGetDouble(POSITION_SL);
            double op=PositionGetDouble(POSITION_PRICE_OPEN);
            double tp=PositionGetDouble(POSITION_TP);

            if(op-pp>=TrailingStart*_Point)
              {
               if(sl>pp+(TrailingStop+TrailingStep)*_Point || sl==0)
                 {
                  Modify(ticket,pp+TrailingStop*_Point,tp);
                 }
              }
           }
        }
     }

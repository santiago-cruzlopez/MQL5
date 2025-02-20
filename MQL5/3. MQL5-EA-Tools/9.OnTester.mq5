#property copyright "Your Name"
#property link      "https://www.example.com"
#property version   "1.00"

// Input parameters for optimization
input double StopLoss = 50.0;     // Stop Loss in points
input double TakeProfit = 100.0;  // Take Profit in points
input int MATimePeriod = 14;      // Moving Average Period

// Global variables
double balance;

//+------------------------------------------------------------------+
//| Expert initialization function                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   balance = AccountBalance();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                               |
//+------------------------------------------------------------------+
void OnTick()
{
   // Simple trading logic based on Moving Average
   double ma[];
   ArraySetAsSeries(ma, true);
   int maHandle = iMA(_Symbol, _Period, MATimePeriod, 0, MODE_SMA, PRICE_CLOSE);
   CopyBuffer(maHandle, 0, 0, 3, ma);

   if(!PositionSelect(_Symbol)) // If no position is open
   {
      if(ma[1] > ma[2] && ma[0] > ma[1]) // Buy signal
      {
         double sl = Ask() - StopLoss * _Point;
         double tp = Ask() + TakeProfit * _Point;
         trade.Buy(0.1, _Symbol, Ask(), sl, tp, "Buy Order");
      }
      else if(ma[1] < ma[2] && ma[0] < ma[1]) // Sell signal
      {
         double sl = Bid() + StopLoss * _Point;
         double tp = Bid() - TakeProfit * _Point;
         trade.Sell(0.1, _Symbol, Bid(), sl, tp, "Sell Order");
      }
   }
}

//+------------------------------------------------------------------+
//| Tester function                                                    |
//+------------------------------------------------------------------+
double OnTester()
{
   // Calculate metrics after testing
   double profit = TesterStatistics(STAT_PROFIT);         // Total profit
   double trades = TesterStatistics(STAT_TRADES);         // Number of trades
   double maxDrawdown = TesterStatistics(STAT_EQUITY_DD); // Maximum drawdown
   
   // Avoid division by zero
   if(trades == 0) return 0.0;

   // Custom criterion: Profit per trade adjusted by drawdown
   double customCriterion = (profit / trades) - maxDrawdown;

   // Ensure non-negative result for optimization
   if(customCriterion < 0) customCriterion = 0.0;

   Print("OnTester: Profit = ", profit, ", Trades = ", trades, ", Custom Criterion = ", customCriterion);
   return customCriterion;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Cleanup code if needed
}

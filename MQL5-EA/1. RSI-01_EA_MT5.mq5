//+------------------------------------------------------------------+
//|                                                    RSI_EA_03.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

// Input parameters
input double RiskPercentage = 1.0; // Risk per trade in percentage
input double MaxDrawdown = 10.0; // Maximum drawdown percentage
input int RSIPeriod = 14; // RSI period
input double OverboughtLevel = 70.0; // Overbought level
input double OversoldLevel = 30.0; // Oversold level
input double StopLossDistance = 50; // Stop loss in points
input double TakeProfitDistance = 100; // Take profit in points

// Global variables
double AccountRisk;
double AccountLossThreshold;
double AccountStartBalance;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    AccountStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    AccountLossThreshold = AccountStartBalance * (1 - MaxDrawdown / 100);
    Print("RSI EA Initialized. Starting Balance: ", AccountStartBalance);
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("RSI EA Deinitialized.");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Check for account drawdown
    if (AccountInfoDouble(ACCOUNT_BALANCE) < AccountLossThreshold)
    {
        Print("Account loss exceeds 10%. No more trades will be opened.");
        return;
    }

    // Calculate RSI
    double rsiValue = iRSI(NULL, 0, RSIPeriod, PRICE_CLOSE, 0);
    
    // Trading logic
    if (rsiValue > OverboughtLevel)
    {
        // Overbought: Consider selling
        OpenTrade(ORDER_SELL);
    }
    else if (rsiValue < OversoldLevel)
    {
        // Oversold: Consider buying
        OpenTrade(ORDER_BUY);
    }
}

//+------------------------------------------------------------------+
//| Function to open trades                                          |
//+------------------------------------------------------------------+
void OpenTrade(int orderType)
{
    // Calculate risk amount
    AccountRisk = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercentage / 100;
    
    // Calculate lot size based on risk
    double lotSize = CalculateLotSize(AccountRisk, StopLossDistance);
    
    if (lotSize > 0)
    {
        double price = (orderType == ORDER_BUY) ? Ask : Bid;
        double stopLoss = (orderType == ORDER_BUY) ? price - StopLossDistance * Point : price + StopLossDistance * Point;
        double takeProfit = (orderType == ORDER_BUY) ? price + TakeProfitDistance * Point : price - TakeProfitDistance * Point;

        // Send order
        int ticket = OrderSend(Symbol(), orderType, lotSize, price, 3, stopLoss, takeProfit, "RSI Strategy", 0, 0, clrBlue);
        if (ticket < 0)
        {
            Print("Error opening order: ", GetLastError());
        }
    }
}

//+------------------------------------------------------------------+
//| Function to calculate lot size based on risk                    |
//+------------------------------------------------------------------+
double CalculateLotSize(double riskAmount, double stopLossDistance)
{
    double lotSize = riskAmount / (stopLossDistance * Point);
    return NormalizeDouble(lotSize, 2); // Adjust to the broker's lot size requirements
}

//+------------------------------------------------------------------+

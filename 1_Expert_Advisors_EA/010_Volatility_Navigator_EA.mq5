//+------------------------------------------------------------------+
//|                                   10.Volatility_Navigator_EA.mq5 |
//|                                            Author: Santiago Cruz |
//|                       https://www.mql5.com/en/users/algo-trader/ |
//+------------------------------------------------------------------+
#property copyright "Santiago Cruz"
#property link      "https://www.mql5.com/en/users/algo-trader/"
#property version   "1.00"

// Input parameters for trading strategy
input int rsiPeriod = 14;                  // Period for RSI calculation
input double overboughtLevel = 70.0;       // RSI level for overbought condition
input double oversoldLevel = 30.0;         // RSI level for oversold condition
input int bbPeriod = 20;                    // Period for Bollinger Bands
input double bbDeviation = 2.0;             // Deviation for Bollinger Bands
input int atrPeriod = 14;                   // ATR period for stop loss and take profit calculations
input double atrMultiplier = 1.5;           // Multiplier for ATR in calculating stop loss and take profit
input string signalSound = "alert.wav";     // Sound file for alert notifications

// Indicator handles for Bollinger Bands and ATR
int bbHandle = 0;
int atrHandle = 0;

// Function to clear previous drawings from the chart
void ClearPreviousDrawings()
{
    // Delete any previously created trade lines and signal text
    if (ObjectFind(0, "EntryPoint") != -1)
        ObjectDelete(0, "EntryPoint");
    if (ObjectFind(0, "StopLoss") != -1)
        ObjectDelete(0, "StopLoss");
    if (ObjectFind(0, "TakeProfit") != -1)
        ObjectDelete(0, "TakeProfit");
    if (ObjectFind(0, "SignalText") != -1)
        ObjectDelete(0, "SignalText");
    if (ObjectFind(0, "BuyArrow") != -1)
        ObjectDelete(0, "BuyArrow");
    if (ObjectFind(0, "SellArrow") != -1)
        ObjectDelete(0, "SellArrow");
}

// Function to draw entry points, stop loss, and take profit on the chart
void DrawTradeLines(double entryPoint, double stopLoss, double takeProfit, string signalText)
{
    // Clear previous drawings before drawing new ones
    ClearPreviousDrawings();

    // Draw the entry point line
    if (!ObjectCreate(0, "EntryPoint", OBJ_HLINE, 0, TimeCurrent(), entryPoint))
        Print("Failed to create EntryPoint line. Error: ", GetLastError());
    ObjectSetInteger(0, "EntryPoint", OBJPROP_COLOR, clrGreen);
    ObjectSetInteger(0, "EntryPoint", OBJPROP_WIDTH, 2);

    // Draw the stop loss line
    if (!ObjectCreate(0, "StopLoss", OBJ_HLINE, 0, TimeCurrent(), stopLoss))
        Print("Failed to create StopLoss line. Error: ", GetLastError());
    ObjectSetInteger(0, "StopLoss", OBJPROP_COLOR, clrRed);
    ObjectSetInteger(0, "StopLoss", OBJPROP_WIDTH, 2);

    // Draw the take profit line
    if (!ObjectCreate(0, "TakeProfit", OBJ_HLINE, 0, TimeCurrent(), takeProfit))
        Print("Failed to create TakeProfit line. Error: ", GetLastError());
    ObjectSetInteger(0, "TakeProfit", OBJPROP_COLOR, clrBlue);
    ObjectSetInteger(0, "TakeProfit", OBJPROP_WIDTH, 2);

    // Draw a label with the signal text to provide information at a glance
    if (!ObjectCreate(0, "SignalText", OBJ_LABEL, 0, TimeCurrent(), entryPoint + 10))
        Print("Failed to create SignalText label. Error: ", GetLastError());
    ObjectSetInteger(0, "SignalText", OBJPROP_XDISTANCE, 10);
    ObjectSetInteger(0, "SignalText", OBJPROP_YDISTANCE, 30);
    ObjectSetInteger(0, "SignalText", OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, "SignalText", OBJPROP_FONTSIZE, 12);
    ObjectSetString(0, "SignalText", OBJPROP_TEXT, signalText);
}

// Function to draw arrows on the chart at entry points
void DrawEntryArrow(double price, string label, color arrowColor)
{
    if (!ObjectCreate(0, label, OBJ_ARROW, 0, TimeCurrent(), price))
    {
        Print("Failed to create arrow object. Error: ", GetLastError());
        return;
    }
    ObjectSetInteger(0, label, OBJPROP_ARROWCODE, 233); // Arrow code for upward direction
    ObjectSetInteger(0, label, OBJPROP_COLOR, arrowColor);
    ObjectSetInteger(0, label, OBJPROP_WIDTH, 2);       // Set the width of the arrow
}

// Function to manage open positions for efficient trade execution
void ManageOpenPositions(string symbol)
{
    // Loop through all open positions
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket))
        {
            // Check if the position is for the current symbol
            if (PositionGetString(POSITION_SYMBOL) == symbol)
            {
                double currentProfit = PositionGetDouble(POSITION_PROFIT);
                Print("Current Profit for position: ", currentProfit);
                // Additional management logic can be added here (e.g., close position, update SL/TP)
            }
        }
    }
}

// Function to calculate trade parameters such as entry point, stop loss, and take profit
void CalculateTradeParameters()
{
    // Get the current RSI value
    double rsiValue = iRSI(Symbol(), PERIOD_CURRENT, rsiPeriod, PRICE_CLOSE);
    Print("RSI Value: ", rsiValue);

    double bbUpper = 0.0;
    double bbLower = 0.0;
    double atrValue = 0.0;

    // Get the latest closing prices
    double closePrices[];
    if (CopyClose(NULL, 0, 0, 1, closePrices) <= 0)
    {
        Print("Error copying close prices: ", GetLastError());
        return; // Exit if there's an error
    }

    // Initialize and get values for Bollinger Bands
    if (bbHandle == 0)
    {
        bbHandle = iBands(NULL, 0, bbPeriod, 0, bbDeviation, PRICE_CLOSE);
    }

    if (bbHandle != INVALID_HANDLE)
    {
        double bbBuffer[];
        // Get the upper and lower Bollinger Bands
        if (CopyBuffer(bbHandle, 1, 0, 1, bbBuffer) > 0)
        {
            bbUpper = bbBuffer[0]; // Upper band value
            Print("Bollinger Band Upper: ", bbUpper);
        }

        if (CopyBuffer(bbHandle, 2, 0, 1, bbBuffer) > 0)
        {
            bbLower = bbBuffer[0]; // Lower band value
            Print("Bollinger Band Lower: ", bbLower);
        }

        // Initialize and get the ATR value
        if (atrHandle == 0)
        {
            atrHandle = iATR(NULL, 0, atrPeriod);
        }

        if (atrHandle != INVALID_HANDLE)
        {
            double atrBuffer[];
            if (CopyBuffer(atrHandle, 0, 0, 1, atrBuffer) > 0)
            {
                atrValue = atrBuffer[0]; // Current ATR value
                Print("ATR Value: ", atrValue);
            }
        }

        double entryPoint, stopLoss, takeProfit;

        // Generate buy or sell signals based on Bollinger Bands and RSI values
        if (closePrices[0] < bbLower && rsiValue < oversoldLevel)  // Buy Condition
        {
            entryPoint = closePrices[0];
            stopLoss = entryPoint - (atrValue * atrMultiplier);
            takeProfit = entryPoint + (atrValue * atrMultiplier * 2);
            DrawTradeLines(entryPoint, stopLoss, takeProfit, "Buy Signal");
            DrawEntryArrow(entryPoint, "BuyArrow", clrGreen); // Draw Buy Arrow
            PlaySound(signalSound); // Notify with sound for new entry
        }
        else if (closePrices[0] > bbUpper && rsiValue > overboughtLevel)  // Sell Condition
        {
            entryPoint = closePrices[0];
            stopLoss = entryPoint + (atrValue * atrMultiplier); // Above entry for short position
            takeProfit = entryPoint - (atrValue * atrMultiplier * 2); // Below entry for short position
            DrawTradeLines(entryPoint, stopLoss, takeProfit, "Sell Signal");
            DrawEntryArrow(entryPoint, "SellArrow", clrRed); // Draw Sell Arrow
            PlaySound(signalSound); // Notify with sound for new entry
        }
    }
}

// Expert initialization function
int OnInit()
{
    // Initialization tasks can be done here
    return INIT_SUCCEEDED;
}

// Expert deinitialization function
void OnDeinit(const int reason)
{
    // Release the indicator handles when the EA is removed
    if (bbHandle != 0)
        IndicatorRelease(bbHandle);
    if (atrHandle != 0)
        IndicatorRelease(atrHandle);
    ClearPreviousDrawings(); // Clear drawings on removal
}

// Expert tick function
void OnTick()
{
    ManageOpenPositions(Symbol()); // Manage open positions before calculating new parameters
    CalculateTradeParameters(); // Calculate trade parameters based on market data
}

//+------------------------------------------------------------------+

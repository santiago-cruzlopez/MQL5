//+------------------------------------------------------------------+
//|                                                  Discord_001.mq5 |
//|         Copyright 2024, Javier Santiago Gaston de Iriarte Cabrera|
//|                       https://medium.com/@jsgastoniriartecabrera |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://medium.com/@jsgastoniriartecabrera"
#property version   "1.00"

#include <Trade/Trade.mqh>

CTrade trade;
// Discord webhook URL - Replace with your webhook URL
string discord_webhook = "https://discord.com/api/webhooks/XXXXXXXXXXXXXXXXXXXXXXx";

// Strategy Parameters
input group "Discord Settings"
input string DiscordBotName = "MT5 Trading Bot";    // Name of the bot in Discord
input color MessageColor = clrBlue;                 // Color for Discord messages
input bool SendPriceUpdates = true;               // Send regular price updates

input group "Trading Parameters"
input int RandomSeed = 42;        // Random seed for reproducibility
input double LotSize = 0.01;      // Trading lot size
input int MaxOpenTrades = 5;      // Maximum number of open trades
input int MinutesBeforeNext = 1;  // Minutes to wait before next trade

// Global Variables
datetime lastTradeTime = 0;
datetime lastMessageTime = 0;
int magicNumber = 12345;
bool isWebRequestEnabled = false;

// Structure to hold trade information
struct TradeInfo {
    string symbol;
    string type;
    double price;
    double lots;
    double sl;
    double tp;
};


int OnInit() {
    Print("Initialization step 1: Checking WebRequest permissions...");
    
    // Initialize random number generator
    MathSrand(RandomSeed);
    
    if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) {
        Print("Error: WebRequest is not allowed. Please allow in Tool -> Options -> Expert Advisors");
        return INIT_FAILED;
    }
    
    Print("Initialization step 2: Testing Discord connection...");
    
    // Simple test message
    ResetLastError();
    string test_message = "{\"content\":\"Test message from MT5\"}";
    string headers = "Content-Type: application/json\r\n";
    char data[], result[];
    ArrayResize(data, StringToCharArray(test_message, data, 0, WHOLE_ARRAY, CP_UTF8) - 1);
    
    int res = WebRequest(
        "POST",
        discord_webhook,
        headers,
        5000,
        data,
        result,
        headers
    );
    
    if(res == -1) {
        int error = GetLastError();
        Print("WebRequest failed. Error code: ", error);
        Print("Make sure these URLs are allowed:");
        Print("https://discord.com/*");
        Print("https://discordapp.com/*");
        return INIT_FAILED;
    }
    
    isWebRequestEnabled = true;
    Print("Initialization step 3: All checks passed!");
    Print("Successfully connected to Discord!");
    
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    SendDiscordMessage("```\nEA stopped. Reason code: " + 
                      IntegerToString(reason) + "```");
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick() {
    // Random trade decision (1% chance per tick)
    if(MathRand() % 100 == 0 && CanTrade()) {
        PlaceRandomTrade();
    }
}

//+------------------------------------------------------------------+
//| Check if we can trade                                             |
//+------------------------------------------------------------------+
bool CanTrade() {
    if(OrdersTotal() >= MaxOpenTrades) return false;
    
    datetime currentTime = TimeCurrent();
    if(currentTime - lastTradeTime < MinutesBeforeNext * 60) return false;
    
    return true;
}


//+------------------------------------------------------------------+
//| Function to escape JSON string                                     |
//+------------------------------------------------------------------+
string EscapeJSON(string text) {
    string escaped = text;
    StringReplace(escaped, "\\", "\\\\");
    StringReplace(escaped, "\"", "\\\"");
    StringReplace(escaped, "\n", "\\n");
    StringReplace(escaped, "\r", "\\r");
    StringReplace(escaped, "\t", "\\t");
    return escaped;
}




void SendPriceUpdate() {
    if(!SendPriceUpdates) return;
    if(TimeCurrent() - lastMessageTime < 300) return; // Every 5 minutes
    
    Sleep(100);  // Add small delay before price update
    
    string message = "```\n";
    message += "Price Update for " + _Symbol + "\n";
    message += "Bid: " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits) + "\n";
    message += "Ask: " + DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits) + "\n";
    message += "Spread: " + DoubleToString(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), 0) + " points\n";
    message += "```";
    
    SendDiscordMessage(message);
}


string FormatTradeMessage(TradeInfo& tradeInfo) {
    string message = "**New " + tradeInfo.type + " Signal Alert!**\n";
    message += "Symbol: " + tradeInfo.symbol + "\n";
    message += "Type: " + tradeInfo.type + "\n";
    message += "Price: " + DoubleToString(tradeInfo.price, _Digits) + "\n";
    message += "Lots: " + DoubleToString(tradeInfo.lots, 2) + "\n";
    message += "Stop Loss: " + DoubleToString(tradeInfo.sl, _Digits) + "\n";
    message += "Take Profit: " + DoubleToString(tradeInfo.tp, _Digits) + "\n";
    message += "Spread: " + DoubleToString(SymbolInfoInteger(tradeInfo.symbol, SYMBOL_SPREAD), 0) + " points\n";
    message += "Time: " + TimeToString(TimeCurrent());
    return message;
}

void PlaceRandomTrade() {
    // Generate random decision (0 = Sell, 1 = Buy)
    bool isBuy = (MathRand() % 2) == 1;
    
    double price = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) 
                        : SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Random SL and TP (50-150 points)
    int slPoints = 50 + (MathRand() % 100);
    int tpPoints = 50 + (MathRand() % 100);
    
    double sl = isBuy ? price - slPoints * _Point : price + slPoints * _Point;
    double tp = isBuy ? price + tpPoints * _Point : price - tpPoints * _Point;
    
    // Prepare trade structure for Discord notification
    TradeInfo tradeInfo;
    tradeInfo.symbol = _Symbol;
    tradeInfo.type = isBuy ? "BUY" : "SELL";
    tradeInfo.price = price;
    tradeInfo.lots = LotSize;
    tradeInfo.sl = sl;
    tradeInfo.tp = tp;
    
    // Send notification before placing trade
    string message = FormatTradeMessage(tradeInfo);
    if(SendDiscordMessage(message)) {
        Sleep(500);  // Add delay between messages
        
        // Set up the trade parameters
        trade.SetExpertMagicNumber(magicNumber);
        trade.SetDeviationInPoints(10);
        trade.SetTypeFilling(ORDER_FILLING_FOK);
        
        // Place the trade using market orders
        bool success = false;
        if(isBuy) {
            success = trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, LotSize, price, sl, tp, "Random Strategy Trade");
        } else {
            success = trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, LotSize, price, sl, tp, "Random Strategy Trade");
        }
        
        // Check trade result and send notification
        if(success) {
            lastTradeTime = TimeCurrent();
            Sleep(500);
            SendDiscordMessage("✅ Trade executed successfully! Ticket: " + IntegerToString(trade.ResultOrder()));
        } else {
            Sleep(500);
            string errorDesc = "Unknown error";
            int errorCode = trade.ResultRetcode();
            switch(errorCode) {
                case TRADE_RETCODE_INVALID_PRICE:
                    errorDesc = "Invalid price level";
                    break;
                case TRADE_RETCODE_INVALID_STOPS:
                    errorDesc = "Invalid SL/TP levels";
                    break;
                case TRADE_RETCODE_INVALID_VOLUME:
                    errorDesc = "Invalid volume";
                    break;
                case TRADE_RETCODE_NO_MONEY:
                    errorDesc = "Insufficient funds";
                    break;
                case TRADE_RETCODE_MARKET_CLOSED:
                    errorDesc = "Market is closed";
                    break;
            }
            SendDiscordMessage("❌ Error placing trade: " + errorDesc + " (Code: " + IntegerToString(errorCode) + ")", true);
        }
    }
}

bool SendDiscordMessage(string message, bool isError = false) {
    if(!isWebRequestEnabled) return false;
    
    Sleep(100);
    
    // Add emoji prefix for visual status
    message = (isError ? "❌ " : "✅ ") + message;
    
    // Prepare webhook data
    string payload = "{\"content\":\"" + EscapeJSON(message) + "\"}";
    string headers = "Content-Type: application/json\r\n";
    
    char post[], result[];
    ArrayResize(post, StringToCharArray(payload, post, 0, WHOLE_ARRAY, CP_UTF8) - 1);
    
    ResetLastError();
    int res = WebRequest(
        "POST",
        discord_webhook,
        headers,
        5000,
        post,
        result,
        headers
    );
    
    // Both 200 and 204 are success codes for Discord webhooks
    if(res == 200 || res == 204) {
        lastMessageTime = TimeCurrent();
        return true;
    }
    
    // If we get here, there was an error
    string error = "";
    switch(res) {
        case 400: error = "Bad Request"; break;
        case 401: error = "Unauthorized"; break;
        case 403: error = "Forbidden"; break;
        case 404: error = "Not Found"; break;
        case 429: error = "Rate Limited"; break;
        default: error = "Unknown Error";
    }
    
    Print("Discord Error: ", error, " (", res, ")");
    Print("Message: ", message);
    Print("Last MT5 Error: ", GetLastError());
    
    return false;
}
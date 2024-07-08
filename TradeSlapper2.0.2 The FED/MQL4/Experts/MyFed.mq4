//+------------------------------------------------------------------+
//|                                                        MyFed.mq4 |
//|                                       Cloned current EA strategy |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property strict

input string Receipt = "Enter Your Receipt Here";
input bool Use_Amplitude = true;
input int Amplitude = 2;
input int RsiTP = 100;
input int RsiPer = 13;
input bool Use_Breakeven_Level = true;
input int Breakeven_Level = 20;
input double Breakeven_Point = 1.0;
input int LotVariant = 3;
input double FixLot = 0.01;
input int MoneyForOneLot = 300;
enum MoneyType {
    Balance,
    Equity,
    FreeMargin
};
input MoneyType MoneyForOneLot_Type = Balance;
input int lotdecimal = 2;
input int MagicNumber = 12345; // Define MagicNumber
input double MaxLotSize = 10.0; // Maximum allowable lot size

bool isTradingAllowed = true; // Flag to control trading

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    //--- initialization code
    return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    //--- cleanup code
}
//+------------------------------------------------------------------+
//| Calculate lot size based on account balance/equity/free margin   |
//+------------------------------------------------------------------+
double CalculateLotSize() {
    double lotSize = FixLot;

    if (MoneyForOneLot_Type == Balance) // Balance
        lotSize = AccountBalance() / MoneyForOneLot;
    else
    if (MoneyForOneLot_Type == Equity) // Equity
        lotSize = AccountEquity() / MoneyForOneLot;
    else
    if (MoneyForOneLot_Type == FreeMargin) // Free Margin
        lotSize = AccountFreeMargin() / MoneyForOneLot;

    // Adjust lot size to the nearest allowed value
    lotSize = MathFloor(lotSize * MathPow(10, lotdecimal)) / MathPow(10, lotdecimal);

    // Ensure lot size is within allowable bounds
    lotSize = MathMax(lotSize, FixLot); // Ensure minimum lot size is FixLot
    lotSize = MathMin(lotSize, MaxLotSize); // Ensure lot size does not exceed MaxLotSize

    return lotSize;
}

//+------------------------------------------------------------------+
//| Set breakeven level                                              |
//+------------------------------------------------------------------+
void SetBreakeven(int ticket) {
    if (OrderSelect(ticket, SELECT_BY_TICKET)) {
        double breakevenPrice;
        if (OrderType() == OP_BUY) {
            breakevenPrice = OrderOpenPrice() + (Breakeven_Point * Point);
            if (Bid - OrderOpenPrice() >= Breakeven_Level * Point || Bid < breakevenPrice) {
                if (OrderStopLoss() < OrderOpenPrice() || Bid < breakevenPrice) {
                    if (!OrderModify(ticket, OrderOpenPrice(), breakevenPrice, OrderTakeProfit(), 0, clrGreen)) {
                        Print("Error in OrderModify for Buy: ", GetLastError());
                    }
                }
            }
        } else
        if (OrderType() == OP_SELL) {
            breakevenPrice = OrderOpenPrice() - (Breakeven_Point * Point);
            if (OrderOpenPrice() - Ask >= Breakeven_Level * Point || Ask > breakevenPrice) {
                if (OrderStopLoss() > OrderOpenPrice() || Ask > breakevenPrice) {
                    if (!OrderModify(ticket, OrderOpenPrice(), breakevenPrice, OrderTakeProfit(), 0, clrRed)) {
                        Print("Error in OrderModify for Sell: ", GetLastError());
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check if sufficient margin is available                          |
//+------------------------------------------------------------------+
bool CheckMargin(double & lotSize, int orderType) {
    while (lotSize >= FixLot) {
        if (AccountFreeMarginCheck(Symbol(), orderType, lotSize) > 0) {
            return true;
        }
        lotSize = MathFloor((lotSize - FixLot) * MathPow(10, lotdecimal)) / MathPow(10, lotdecimal);
    }
    return false;
}

//+------------------------------------------------------------------+
//| Calculate and ensure valid stop loss and take profit levels      |
//+------------------------------------------------------------------+
bool EnsureValidLevels(double & stopLoss, double & takeProfit, double price, bool isBuy) {
    double minStopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;

    if (isBuy) {
        if ((price - stopLoss) < minStopLevel) {
            stopLoss = price - minStopLevel;
        }
        if ((takeProfit - price) < minStopLevel) {
            takeProfit = price + minStopLevel;
        }
    } else {
        if ((stopLoss - price) < minStopLevel) {
            stopLoss = price + minStopLevel;
        }
        if ((price - takeProfit) < minStopLevel) {
            takeProfit = price - minStopLevel;
        }
    }

    return (stopLoss != price && takeProfit != price);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    /*
    double a = NormalizeDouble(Ask, Digits);
    Print("Current Ask Price: ", Ask);
    if (isTradingAllowed && true) {
        isTradingAllowed = false;
        Print("Trading stopped due to condition being met.");
        return;
    }

    
    */

    double rsiValue = iRSI(NULL, 0, RsiPer, PRICE_CLOSE, 0);
    
    if(isTradingAllowed) {Print(rsiValue); isTradingAllowed = True; return;} else return;

    if (Use_Amplitude) {
        rsiValue *= Amplitude;
    }

    double slippage = 3; // Adjust slippage as needed
    double ask = NormalizeDouble(Ask, Digits);
    double bid = NormalizeDouble(Bid, Digits);
    double stopLoss = 0;
    double takeProfit = 0;

    if (rsiValue < 30) {
        stopLoss = ask - (Breakeven_Level * Point);
        takeProfit = ask + (RsiTP * Point);

        if (!EnsureValidLevels(stopLoss, takeProfit, ask, true)) {
            Print("Invalid stop loss/take profit levels for Buy order");
            return;
        }

        if (OrdersTotal() < LotVariant) {
            double lotSize = CalculateLotSize();

            if (!CheckMargin(lotSize, OP_BUY)) {
                Print("Not enough margin to open Buy order with lot size: ", lotSize);
                return;
            }

            int ticket = OrderSend(Symbol(), OP_BUY, lotSize, ask, slippage, stopLoss, takeProfit, "Buy order", MagicNumber, 0, clrGreen);

            if (ticket < 0) {
                Print("Error in OrderSend for Buy: ", GetLastError());
                return;
            }

            if (Use_Breakeven_Level && ticket > 0) {
                SetBreakeven(ticket);
            }
        }
    } else
    if (rsiValue > 70) {
        stopLoss = bid + (Breakeven_Level * Point);
        takeProfit = bid - (RsiTP * Point);

        if (!EnsureValidLevels(stopLoss, takeProfit, bid, false)) {
            Print("Invalid stop loss/take profit levels for Sell order");
            return;
        }

        if (OrdersTotal() < LotVariant) {
            double lotSize = CalculateLotSize();

            if (!CheckMargin(lotSize, OP_SELL)) {
                Print("Not enough margin to open Sell order with lot size: ", lotSize);
                return;
            }

            int ticket = OrderSend(Symbol(), OP_SELL, lotSize, bid, slippage, stopLoss, takeProfit, "Sell order", MagicNumber, 0, clrRed);

            if (ticket < 0) {
                Print("Error in OrderSend for Sell: ", GetLastError());
                return;
            }

            if (Use_Breakeven_Level && ticket > 0) {
                SetBreakeven(ticket);
            }
        }
    }

    if (Use_Breakeven_Level) {
        for (int i = OrdersTotal() - 1; i >= 0; i--) {
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
                if (OrderMagicNumber() == MagicNumber) {
                    SetBreakeven(OrderTicket());
                }
            }
        }
    }
}
//+------------------------------------------------------------------+
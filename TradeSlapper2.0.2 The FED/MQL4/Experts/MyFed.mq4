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
enum MoneyType { Balance, Equity, FreeMargin };
input MoneyType MoneyForOneLot_Type = Balance;
input int lotdecimal = 2;
input int MagicNumber = 12345; // Define MagicNumber

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //--- initialization code
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //--- cleanup code
  }
//+------------------------------------------------------------------+
//| Calculate lot size based on account balance/equity/free margin   |
//+------------------------------------------------------------------+
double CalculateLotSize()
{
   double lotSize = FixLot;

   if (MoneyForOneLot_Type == Balance) // Balance
      lotSize = MathFloor((AccountBalance() / MoneyForOneLot) * MathPow(10, lotdecimal)) / MathPow(10, lotdecimal);
   else if (MoneyForOneLot_Type == Equity) // Equity
      lotSize = MathFloor((AccountEquity() / MoneyForOneLot) * MathPow(10, lotdecimal)) / MathPow(10, lotdecimal);
   else if (MoneyForOneLot_Type == FreeMargin) // Free Margin
      lotSize = MathFloor((AccountFreeMargin() / MoneyForOneLot) * MathPow(10, lotdecimal)) / MathPow(10, lotdecimal);

   return MathMax(lotSize, FixLot); // Ensure minimum lot size is FixLot
}

//+------------------------------------------------------------------+
//| Set breakeven level                                              |
//+------------------------------------------------------------------+
void SetBreakeven(int ticket)
{
   if (OrderSelect(ticket, SELECT_BY_TICKET))
   {
      double breakevenPrice;
      
      if (OrderType() == OP_BUY)
      {
         breakevenPrice = OrderOpenPrice() + (Breakeven_Point * Point);
         if (Bid - OrderOpenPrice() >= Breakeven_Level * Point || Bid < breakevenPrice)
         {
            if (OrderStopLoss() < OrderOpenPrice() || Bid < breakevenPrice)
            {
               if(!OrderModify(ticket, OrderOpenPrice(), breakevenPrice, OrderTakeProfit(), 0, clrGreen))
               {
                  Print("Error in OrderModify for Buy: ", GetLastError());
               }
            }
         }
      }
      else if (OrderType() == OP_SELL)
      {
         breakevenPrice = OrderOpenPrice() - (Breakeven_Point * Point);
         if (OrderOpenPrice() - Ask >= Breakeven_Level * Point || Ask > breakevenPrice)
         {
            if (OrderStopLoss() > OrderOpenPrice() || Ask > breakevenPrice)
            {
               if(!OrderModify(ticket, OrderOpenPrice(), breakevenPrice, OrderTakeProfit(), 0, clrRed))
               {
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
bool CheckMargin()
{
   return (AccountFreeMarginCheck(Symbol(), OP_BUY, FixLot) > 0);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   double rsiValue = iRSI(NULL, 0, RsiPer, PRICE_CLOSE, 0);

   if (Use_Amplitude)
   {
      rsiValue *= Amplitude;
   }

   double slippage = 3; // Adjust slippage as needed
   double ask = NormalizeDouble(Ask, Digits);
   double bid = NormalizeDouble(Bid, Digits);
   double stopLoss = 0;
   double takeProfit = 0;
   double minStopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;

   // Determine stop loss and take profit levels ensuring they are valid
   if (rsiValue < 30)
   {
      stopLoss = ask - (Breakeven_Level * Point);
      takeProfit = ask + (RsiTP * Point);

      // Ensure stop loss and take profit are beyond the minimum stop level
      if ((ask - stopLoss) < minStopLevel)
         stopLoss = ask - minStopLevel;
      if ((takeProfit - ask) < minStopLevel)
         takeProfit = ask + minStopLevel;
   }
   else if (rsiValue > 70)
   {
      stopLoss = bid + (Breakeven_Level * Point);
      takeProfit = bid - (RsiTP * Point);

      // Ensure stop loss and take profit are beyond the minimum stop level
      if ((stopLoss - bid) < minStopLevel)
         stopLoss = bid + minStopLevel;
      if ((bid - takeProfit) < minStopLevel)
         takeProfit = bid - minStopLevel;
   }

   if (rsiValue < 30)
   {
      if (OrdersTotal() < LotVariant)
      {
         double lotSize = CalculateLotSize();
         
         int ticket = OrderSend(Symbol(), OP_BUY, lotSize, ask, slippage, stopLoss, takeProfit, "Buy order", MagicNumber, 0, clrGreen);

         if (ticket < 0)
         {
            Print("Error in OrderSend for Buy: ", GetLastError());
            return;
         }

         if (Use_Breakeven_Level && ticket > 0)
         {
            SetBreakeven(ticket);
         }
      }
   }
   else if (rsiValue > 70)
   {
      if (OrdersTotal() < LotVariant)
      {
         double lotSize = CalculateLotSize();
         
         // Send a sell order
         int ticket = OrderSend(Symbol(), OP_SELL, lotSize, bid, slippage, stopLoss, takeProfit, "Sell order", MagicNumber, 0, clrRed);

         if (ticket < 0)
         {
            Print("Error in OrderSend for Sell: ", GetLastError());
            return;
         }

         if (Use_Breakeven_Level && ticket > 0)
         {
            SetBreakeven(ticket);
         }
      }
   }

   if (Use_Breakeven_Level)
   {
      for (int i = OrdersTotal() - 1; i >= 0; i--)
      {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if (OrderMagicNumber() == MagicNumber)
            {
               SetBreakeven(OrderTicket());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+

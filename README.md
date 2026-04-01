# MT4 EA Dual Backtesting Assets

Repository of **MetaTrader 4** expert advisor (EA) resources, chart templates, and **optimizer set files** used for dual or parallel backtesting workflows. The tree includes **TradeSlapper**-related MQL4 templates under `TradeSlapper2.0.2 The FED/` and preset **`.set`** files under `Fed Zip/Set Files/` for major FX pairs.

## Contents (high level)

- **`TradeSlapper2.0.2 The FED/MQL4/Experts/`** — EA source (e.g. `MyFed.mq4`)  
- **`.../MQL4/Files/TradeSlapperTemplates/`** — Per-symbol chart templates (`.tpl`)  
- **`Fed Zip/Set Files/`** — Strategy tester `.set` inputs for pairs such as EURUSD, GBPUSD, USDJPY, etc.

## Usage

1. Copy EA (`.mq4`) files into your MT4 `Experts` directory and compile in MetaEditor.  
2. Install templates into `Templates` or the path your EA expects.  
3. Load the appropriate `.set` file in the MT4 Strategy Tester when optimizing or backtesting.

Paths and build numbers refer to a specific TradeSlapper distribution—verify compatibility with your MT4 build and broker environment.

## Disclaimer

Automated trading carries financial risk. Past backtest results do not guarantee future performance. Use only in demo or with capital you can afford to lose.

## License

See the repository license file if present.

//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_SAR_EURUSD_H1_Params : Stg_SAR_Params {
  Stg_SAR_EURUSD_H1_Params() {
    symbol = "EURUSD";
    tf = PERIOD_H1;
    SAR_Step = 0.05;
    SAR_Maximum_Stop = 0.4;
    SAR_Shift = 0;
    SAR_SignalOpenMethod = 0;
    SAR_SignalOpenLevel = 36;
    SAR_SignalCloseMethod = 1;
    SAR_SignalCloseLevel = 36;
    SAR_PriceLimitMethod = 0;
    SAR_PriceLimitLevel = 0;
    SAR_MaxSpread = 6;
  }
};

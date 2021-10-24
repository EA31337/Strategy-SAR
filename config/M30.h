/**
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_SAR_Params_M30 : IndiSARParams {
  Indi_SAR_Params_M30() : IndiSARParams(indi_sar_defaults, PERIOD_M30) {
    step = (float)0.04;
    max = (float)0.5;
    shift = 0;
  }
} indi_sar_m30;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_SAR_Params_M30 : StgParams {
  // Struct constructor.
  Stg_SAR_Params_M30() : StgParams(stg_sar_defaults) {
    lot_size = 0;
    signal_open_method = 2;
    signal_open_level = (float)0.0;
    signal_open_boost = 0;
    signal_close_method = 2;
    signal_close_level = (float)0;
    price_profit_method = 60;
    price_profit_level = (float)6;
    price_stop_method = 60;
    price_stop_level = (float)6;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_sar_m30;

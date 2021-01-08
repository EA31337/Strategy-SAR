/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_SAR_Params_H1 : Indi_SAR_Params {
  Indi_SAR_Params_H1() : Indi_SAR_Params(indi_sar_defaults, PERIOD_H1) { shift = 0; }
} indi_sar_h1;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_SAR_Params_H1 : StgParams {
  // Struct constructor.
  Stg_SAR_Params_H1() : StgParams(stg_sar_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = (float)0;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = (float)0;
    price_stop_method = 0;
    price_stop_level = (float)2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_sar_h1;

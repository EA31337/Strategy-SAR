//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                                     Copyright 2016-2022, EA31337 |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines EA parameter values.
struct Stg_SAR_EA_Params : EAParams {
  Stg_SAR_EA_Params() {
    name = ea_name;
    log_level = Log_Level;
    chart_info_freq = Info_On_Chart ? 2 : 0;
  }
};

//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements SAR strategy based on the Parabolic Stop and Reverse system indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_SAR.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT string __SAR_Parameters__ = "-- SAR strategy params --";  // >>> SAR <<<
INPUT int SAR_Active_Tf = 8;          // Activate timeframes (1-255, e.g. M1=1,M5=2,M15=4,M30=8,H1=16,H2=32...)
INPUT double SAR_Step = 0.05;         // Step
INPUT double SAR_Maximum_Stop = 0.4;  // Maximum stop
INPUT int SAR_Shift = 0;              // Shift
INPUT ENUM_TRAIL_TYPE SAR_TrailingStopMethod = 7;     // Trail stop method
INPUT ENUM_TRAIL_TYPE SAR_TrailingProfitMethod = 11;  // Trail profit method
INPUT double SAR_SignalOpenLevel = 0;                 // Signal open level
INPUT int SAR1_SignalBaseMethod = 91;                 // Signal base method (-127-127)
INPUT int SAR1_OpenCondition1 = 680;
INPUT int SAR1_OpenCondition2 = 0;
INPUT ENUM_MARKET_EVENT SAR1_CloseCondition = 1;  // Close condition for M1
INPUT int SAR5_OpenCondition1 = 680;              // Open condition 1 (0-1023)
INPUT double SAR_MaxSpread = 6.0;                 // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_SAR_Params : Stg_Params {
  unsigned int SAR_Period;
  ENUM_APPLIED_PRICE SAR_Applied_Price;
  int SAR_Shift;
  ENUM_TRAIL_TYPE SAR_TrailingStopMethod;
  ENUM_TRAIL_TYPE SAR_TrailingProfitMethod;
  double SAR_SignalOpenLevel;
  long SAR_SignalBaseMethod;
  long SAR_SignalOpenMethod1;
  long SAR_SignalOpenMethod2;
  double SAR_SignalCloseLevel;
  ENUM_MARKET_EVENT SAR_SignalCloseMethod1;
  ENUM_MARKET_EVENT SAR_SignalCloseMethod2;
  double SAR_MaxSpread;

  // Constructor: Set default param values.
  Stg_SAR_Params()
      : SAR_Period(::SAR_Period),
        SAR_Applied_Price(::SAR_Applied_Price),
        SAR_Shift(::SAR_Shift),
        SAR_TrailingStopMethod(::SAR_TrailingStopMethod),
        SAR_TrailingProfitMethod(::SAR_TrailingProfitMethod),
        SAR_SignalOpenLevel(::SAR_SignalOpenLevel),
        SAR_SignalBaseMethod(::SAR_SignalBaseMethod),
        SAR_SignalOpenMethod1(::SAR_SignalOpenMethod1),
        SAR_SignalOpenMethod2(::SAR_SignalOpenMethod2),
        SAR_SignalCloseLevel(::SAR_SignalCloseLevel),
        SAR_SignalCloseMethod1(::SAR_SignalCloseMethod1),
        SAR_SignalCloseMethod2(::SAR_SignalCloseMethod2),
        SAR_MaxSpread(::SAR_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_SAR : public Strategy {
 public:
  Stg_SAR(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_SAR *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_SAR_Params _params;
    switch (_tf) {
      case PERIOD_M1: {
        Stg_SAR_EURUSD_M1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M5: {
        Stg_SAR_EURUSD_M5_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M15: {
        Stg_SAR_EURUSD_M15_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M30: {
        Stg_SAR_EURUSD_M30_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H1: {
        Stg_SAR_EURUSD_H1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H4: {
        Stg_SAR_EURUSD_H4_Params _new_params;
        _params = _new_params;
      }
    }
    // Initialize strategy parameters.
    ChartParams cparams(_tf);
    SAR_Params adx_params(_params.SAR_Period, _params.SAR_Applied_Price);
    IndicatorParams adx_iparams(10, INDI_SAR);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_SAR(adx_params, adx_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.SAR_SignalBaseMethod, _params.SAR_SignalOpenMethod1, _params.SAR_SignalOpenMethod2,
                       _params.SAR_SignalCloseMethod1, _params.SAR_SignalCloseMethod2, _params.SAR_SignalOpenLevel,
                       _params.SAR_SignalCloseLevel);
    sparams.SetStops(_params.SAR_TrailingProfitMethod, _params.SAR_TrailingStopMethod);
    sparams.SetMaxSpread(_params.SAR_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_SAR(sparams, "SAR");
    return _strat;
  }

  /**
   * Check if SAR indicator is on buy or sell.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   _signal_method (int) - signal method to use by using bitwise AND operation
   *   _signal_level1 (double) - signal level to consider the signal (in pips)
   *   _signal_level1 (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    bool _result = false;
    double sar_0 = ((Indi_SAR *)this.Data()).GetValue(0);
    double sar_1 = ((Indi_SAR *)this.Data()).GetValue(1);
    double sar_2 = ((Indi_SAR *)this.Data()).GetValue(2);
    if (_signal_method == EMPTY) _signal_method = GetSignalBaseMethod();
    if (_signal_level1 == EMPTY) _signal_level1 = GetSignalLevel1();
    if (_signal_level2 == EMPTY) _signal_level2 = GetSignalLevel2();
    double gap = _signal_level1 * pip_size;
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result = sar_0 + gap < Open[CURR] || sar_1 + gap < Open[PREV];
        if (_signal_method != 0) {
          if (METHOD(_signal_method, 0)) _result &= sar_1 - gap > this.Chart().GetAsk();
          if (METHOD(_signal_method, 1)) _result &= sar_0 < sar_1;
          if (METHOD(_signal_method, 2)) _result &= sar_0 - sar_1 <= sar_1 - sar_2;
          if (METHOD(_signal_method, 3)) _result &= sar_2 > this.Chart().GetAsk();
          if (METHOD(_signal_method, 4)) _result &= sar_0 <= Close[CURR];
          if (METHOD(_signal_method, 5)) _result &= sar_1 > Close[PREV];
          if (METHOD(_signal_method, 6)) _result &= sar_1 > Open[PREV];
        }
        break;
      case ORDER_TYPE_SELL:
        _result = sar_0 - gap > Open[CURR] || sar_1 - gap > Open[PREV];
        if (_signal_method != 0) {
          if (METHOD(_signal_method, 0)) _result &= sar_1 + gap < this.Chart().GetAsk();
          if (METHOD(_signal_method, 1)) _result &= sar_0 > sar_1;
          if (METHOD(_signal_method, 2)) _result &= sar_1 - sar_0 <= sar_2 - sar_1;
          if (METHOD(_signal_method, 3)) _result &= sar_2 < this.Chart().GetAsk();
          if (METHOD(_signal_method, 4)) _result &= sar_0 >= Close[CURR];
          if (METHOD(_signal_method, 5)) _result &= sar_1 < Close[PREV];
          if (METHOD(_signal_method, 6)) _result &= sar_1 < Open[PREV];
        }
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    if (_signal_level == EMPTY) _signal_level = GetSignalCloseLevel();
    return SignalOpen(Order::NegateOrderType(_cmd), _signal_method, _signal_level);
  }
};

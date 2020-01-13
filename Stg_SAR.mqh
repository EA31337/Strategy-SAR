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
INPUT double SAR_Step = 0.05;                                   // Step
INPUT double SAR_Maximum_Stop = 0.4;                            // Maximum stop
INPUT int SAR_Shift = 0;                                        // Shift
INPUT int SAR_SignalOpenMethod = 91;                            // Signal open method (-127-127)
INPUT double SAR_SignalOpenLevel = 0;                           // Signal open level
INPUT int SAR_SignalCloseMethod = 91;                           // Signal close method (-127-127)
INPUT double SAR_SignalCloseLevel = 0;                          // Signal close level
INPUT int SAR_PriceLimitMethod = 0;                             // Price limit method
INPUT double SAR_PriceLimitLevel = 0;                           // Price limit level
INPUT double SAR_MaxSpread = 6.0;                               // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_SAR_Params : Stg_Params {
  double SAR_Step;
  double SAR_Maximum_Stop;
  int SAR_Shift;
  int SAR_SignalOpenMethod;
  double SAR_SignalOpenLevel;
  int SAR_SignalCloseMethod;
  double SAR_SignalCloseLevel;
  int SAR_PriceLimitMethod;
  double SAR_PriceLimitLevel;
  double SAR_MaxSpread;

  // Constructor: Set default param values.
  Stg_SAR_Params()
      : SAR_Step(::SAR_Step),
        SAR_Maximum_Stop(::SAR_Maximum_Stop),
        SAR_Shift(::SAR_Shift),
        SAR_SignalOpenMethod(::SAR_SignalOpenMethod),
        SAR_SignalOpenLevel(::SAR_SignalOpenLevel),
        SAR_SignalCloseMethod(::SAR_SignalCloseMethod),
        SAR_SignalCloseLevel(::SAR_SignalCloseLevel),
        SAR_PriceLimitMethod(::SAR_PriceLimitMethod),
        SAR_PriceLimitLevel(::SAR_PriceLimitLevel),
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
    SAR_Params sar_params(_params.SAR_Step, _params.SAR_Maximum_Stop);
    IndicatorParams sar_iparams(10, INDI_SAR);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_SAR(sar_params, sar_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.SAR_SignalOpenMethod, _params.SAR_SignalOpenLevel, _params.SAR_SignalCloseMethod,
                       _params.SAR_SignalCloseLevel);
    sparams.SetMaxSpread(_params.SAR_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_SAR(sparams, "SAR");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, double _level = 0.0) {
    bool _result = false;
    double sar_0 = ((Indi_SAR *)this.Data()).GetValue(0);
    double sar_1 = ((Indi_SAR *)this.Data()).GetValue(1);
    double sar_2 = ((Indi_SAR *)this.Data()).GetValue(2);
    double gap = _level * Market().GetPipSize();
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result = sar_0 + gap < Open[CURR] || sar_1 + gap < Open[PREV];
        if (_method != 0) {
          if (METHOD(_method, 0)) _result &= sar_1 - gap > this.Chart().GetAsk();
          if (METHOD(_method, 1)) _result &= sar_0 < sar_1;
          if (METHOD(_method, 2)) _result &= sar_0 - sar_1 <= sar_1 - sar_2;
          if (METHOD(_method, 3)) _result &= sar_2 > this.Chart().GetAsk();
          if (METHOD(_method, 4)) _result &= sar_0 <= Close[CURR];
          if (METHOD(_method, 5)) _result &= sar_1 > Close[PREV];
          if (METHOD(_method, 6)) _result &= sar_1 > Open[PREV];
        }
        break;
      case ORDER_TYPE_SELL:
        _result = sar_0 - gap > Open[CURR] || sar_1 - gap > Open[PREV];
        if (_method != 0) {
          if (METHOD(_method, 0)) _result &= sar_1 + gap < this.Chart().GetAsk();
          if (METHOD(_method, 1)) _result &= sar_0 > sar_1;
          if (METHOD(_method, 2)) _result &= sar_1 - sar_0 <= sar_2 - sar_1;
          if (METHOD(_method, 3)) _result &= sar_2 < this.Chart().GetAsk();
          if (METHOD(_method, 4)) _result &= sar_0 >= Close[CURR];
          if (METHOD(_method, 5)) _result &= sar_1 < Close[PREV];
          if (METHOD(_method, 6)) _result &= sar_1 < Open[PREV];
        }
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, int _method = 0, double _level = 0.0) {
    return SignalOpen(Order::NegateOrderType(_cmd), _method, _level);
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  double PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_STG_PRICE_LIMIT_MODE _mode, int _method = 0, double _level = 0.0) {
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd) * (_mode == LIMIT_VALUE_STOP ? -1 : 1);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    switch (_method) {
      case 0: {
        // @todo
      }
    }
    return _result;
  }
};

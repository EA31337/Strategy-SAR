/**
 * @file
 * Implements SAR strategy based on the Parabolic Stop and Reverse system indicator.
 */

// User input params.
INPUT float SAR_Step = 0.05f;              // Step
INPUT float SAR_Maximum_Stop = 0.4f;       // Maximum stop
INPUT int SAR_Shift = 0;                   // Shift
INPUT int SAR_SignalOpenMethod = 91;       // Signal open method (-127-127)
INPUT float SAR_SignalOpenLevel = 0;       // Signal open level
INPUT int SAR_SignalOpenFilterMethod = 0;  // Signal open filter method
INPUT int SAR_SignalOpenBoostMethod = 0;   // Signal open boost method
INPUT int SAR_SignalCloseMethod = 91;      // Signal close method (-127-127)
INPUT float SAR_SignalCloseLevel = 0;      // Signal close level
INPUT int SAR_PriceLimitMethod = 0;        // Price limit method
INPUT float SAR_PriceLimitLevel = 0;       // Price limit level
INPUT float SAR_MaxSpread = 6.0;           // Max spread to trade (pips)

// Includes.
#include <EA31337-classes/Indicators/Indi_SAR.mqh>
#include <EA31337-classes/Strategy.mqh>

// Struct to define strategy parameters to override.
struct Stg_SAR_Params : StgParams {
  float SAR_Step;
  float SAR_Maximum_Stop;
  int SAR_Shift;
  int SAR_SignalOpenMethod;
  float SAR_SignalOpenLevel;
  int SAR_SignalOpenFilterMethod;
  int SAR_SignalOpenBoostMethod;
  int SAR_SignalCloseMethod;
  float SAR_SignalCloseLevel;
  int SAR_PriceLimitMethod;
  float SAR_PriceLimitLevel;
  float SAR_MaxSpread;

  // Constructor: Set default param values.
  Stg_SAR_Params()
      : SAR_Step(::SAR_Step),
        SAR_Maximum_Stop(::SAR_Maximum_Stop),
        SAR_Shift(::SAR_Shift),
        SAR_SignalOpenMethod(::SAR_SignalOpenMethod),
        SAR_SignalOpenLevel(::SAR_SignalOpenLevel),
        SAR_SignalOpenFilterMethod(::SAR_SignalOpenFilterMethod),
        SAR_SignalOpenBoostMethod(::SAR_SignalOpenBoostMethod),
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
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Stg_SAR_Params>(_params, _tf, stg_sar_m1, stg_sar_m5, stg_sar_m15, stg_sar_m30, stg_sar_h1,
                                    stg_sar_h4, stg_sar_h4);
    }
    // Initialize strategy parameters.
    SARParams sar_params(_params.SAR_Step, _params.SAR_Maximum_Stop);
    sar_params.SetTf(_tf);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_SAR(sar_params), NULL, NULL);
    sparams.logger.Ptr().SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.SAR_SignalOpenMethod, _params.SAR_SignalOpenLevel, _params.SAR_SignalOpenFilterMethod,
                       _params.SAR_SignalOpenBoostMethod, _params.SAR_SignalCloseMethod, _params.SAR_SignalCloseLevel);
    sparams.SetPriceLimits(_params.SAR_PriceLimitMethod, _params.SAR_PriceLimitLevel);
    sparams.SetMaxSpread(_params.SAR_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_SAR(sparams, "SAR");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0) {
    Indi_SAR *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    if (_is_valid) {
      double level = _level * Chart().GetPipSize();
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          _result = _indi[CURR].value[0] + level < Chart().GetOpen(0);
          _result |= _indi[PREV].value[0] + level < Chart().GetOpen(1);
          if (_method != 0) {
            if (METHOD(_method, 0)) _result &= _indi[PREV].value[0] - level > Market().GetAsk();
            if (METHOD(_method, 1)) _result &= _indi[CURR].value[0] < _indi[PREV].value[0];
            if (METHOD(_method, 2))
              _result &= _indi[CURR].value[0] - _indi[PREV].value[0] <= _indi[PREV].value[0] - _indi[PPREV].value[0];
            if (METHOD(_method, 3)) _result &= _indi[PPREV].value[0] > Market().GetAsk();
            if (METHOD(_method, 4)) _result &= _indi[CURR].value[0] <= Chart().GetClose(0);
            if (METHOD(_method, 5)) _result &= _indi[PREV].value[0] > Chart().GetClose(1);
            if (METHOD(_method, 6)) _result &= _indi[PREV].value[0] > Chart().GetOpen(1);
          }
          break;
        case ORDER_TYPE_SELL:
          _result = _indi[CURR].value[0] - level > Chart().GetOpen(0);
          _result |= _indi[PREV].value[0] - level > Chart().GetOpen(1);
          if (_method != 0) {
            if (METHOD(_method, 0)) _result &= _indi[PREV].value[0] + level < Market().GetAsk();
            if (METHOD(_method, 1)) _result &= _indi[CURR].value[0] > _indi[PREV].value[0];
            if (METHOD(_method, 2))
              _result &= _indi[PREV].value[0] - _indi[CURR].value[0] <= _indi[PPREV].value[0] - _indi[PREV].value[0];
            if (METHOD(_method, 3)) _result &= _indi[PPREV].value[0] < Market().GetAsk();
            if (METHOD(_method, 4)) _result &= _indi[CURR].value[0] >= Chart().GetClose(0);
            if (METHOD(_method, 5)) _result &= _indi[PREV].value[0] < Chart().GetClose(1);
            if (METHOD(_method, 6)) _result &= _indi[PREV].value[0] < Chart().GetOpen(1);
          }
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  float PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_SAR *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    double open_0 = Chart().GetOpen(0);
    double gap = _level * Market().GetPipSize();
    double _diff = 0;
    if (_is_valid) {
      switch (_method) {
        case 0:
          _diff = fabs(open_0 - _indi[CURR].value[0]);
          _result = open_0 + (_diff + _trail) * _direction;
          break;
        case 1:
          _diff = fmax(fabs(open_0 - fmax(_indi[CURR].value[0], _indi[PREV].value[0])),
                       fabs(open_0 - fmin(_indi[CURR].value[0], _indi[PREV].value[0])));
          _result = open_0 + (_diff + _trail) * _direction;
          break;
        case 2: {
          int _bar_count = (int)_level * 10;
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
      }
    }
    return (float)_result;
  }
};

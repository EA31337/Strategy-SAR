/**
 * @file
 * Implements SAR strategy based on the Parabolic Stop and Reverse system indicator.
 */

// User input params.
INPUT float SAR_LotSize = 0;               // Lot size
INPUT int SAR_SignalOpenMethod = 0;        // Signal open method (-127-127)
INPUT float SAR_SignalOpenLevel = 0.0f;    // Signal open level
INPUT int SAR_SignalOpenFilterMethod = 1;  // Signal open filter method
INPUT int SAR_SignalOpenBoostMethod = 0;   // Signal open boost method
INPUT int SAR_SignalCloseMethod = 91;      // Signal close method (-127-127)
INPUT float SAR_SignalCloseLevel = 0.0f;   // Signal close level
INPUT int SAR_PriceStopMethod = 0;         // Price stop method
INPUT float SAR_PriceStopLevel = 0;        // Price stop level
INPUT int SAR_TickFilterMethod = 1;        // Tick filter method
INPUT float SAR_MaxSpread = 4.0;           // Max spread to trade (pips)
INPUT int SAR_Shift = 0;                   // Shift
INPUT int SAR_OrderCloseTime = -20;        // Order close time in mins (>0) or bars (<0)
INPUT string __SAR_Indi_SAR_Parameters__ =
    "-- SAR strategy: SAR indicator params --";  // >>> SAR strategy: SAR indicator <<<
INPUT float SAR_Indi_SAR_Step = 0.05f;           // Step
INPUT float SAR_Indi_SAR_Maximum_Stop = 0.4f;    // Maximum stop
INPUT float SAR_Indi_SAR_Shift = 0;              // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_SAR_Params_Defaults : SARParams {
  Indi_SAR_Params_Defaults() : SARParams(::Indi_SAR_Step, ::Indi_SAR_Maximum_Stop, ::SAR_Indi_SAR_Shift) {}
} indi_sar_defaults;

// Defines struct with default user strategy values.
struct Stg_SAR_Params_Defaults : StgParams {
  Stg_SAR_Params_Defaults()
      : StgParams(::SAR_SignalOpenMethod, ::SAR_SignalOpenFilterMethod, ::SAR_SignalOpenLevel,
                  ::SAR_SignalOpenBoostMethod, ::SAR_SignalCloseMethod, ::SAR_SignalCloseLevel, ::SAR_PriceStopMethod,
                  ::SAR_PriceStopLevel, ::SAR_TickFilterMethod, ::SAR_MaxSpread, ::SAR_Shift, ::SAR_OrderCloseTime) {}
} stg_sar_defaults;

// Struct to define strategy parameters to override.
struct Stg_SAR_Params : StgParams {
  SARParams iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_SAR_Params(SARParams &_iparams, StgParams &_sparams)
      : iparams(indi_sar_defaults, _iparams.tf), sparams(stg_sar_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_SAR : public Strategy {
 public:
  Stg_SAR(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_SAR *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    SARParams _indi_params(indi_sar_defaults, _tf);
    StgParams _stg_params(stg_sar_defaults);
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<SARParams>(_indi_params, _tf, indi_sar_m1, indi_sar_m5, indi_sar_m15, indi_sar_m30, indi_sar_h1,
                               indi_sar_h4, indi_sar_h8);
      SetParamsByTf<StgParams>(_stg_params, _tf, stg_sar_m1, stg_sar_m5, stg_sar_m15, stg_sar_m30, stg_sar_h1,
                               stg_sar_h4, stg_sar_h8);
    }
    // Initialize indicator.
    SARParams sar_params(_indi_params);
    _stg_params.SetIndicator(new Indi_SAR(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_SAR(_stg_params, "SAR");
    _stg_params.SetStops(_strat, _strat);
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_SAR *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    if (_is_valid) {
      double level = _level * Chart().GetPipSize();
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          _result = _indi[CURR][0] + level < Chart().GetOpen(0);
          _result |= _indi[PREV][0] + level < Chart().GetOpen(1);
          if (_method != 0) {
            if (METHOD(_method, 0)) _result &= _indi[PREV][0] - level > Market().GetAsk();
            if (METHOD(_method, 1)) _result &= _indi[CURR][0] < _indi[PREV][0];
            if (METHOD(_method, 2)) _result &= _indi[CURR][0] - _indi[PREV][0] <= _indi[PREV][0] - _indi[PPREV][0];
            if (METHOD(_method, 3)) _result &= _indi[PPREV][0] > Market().GetAsk();
            if (METHOD(_method, 4)) _result &= _indi[CURR][0] <= Chart().GetClose(0);
            if (METHOD(_method, 5)) _result &= _indi[PREV][0] > Chart().GetClose(1);
            if (METHOD(_method, 6)) _result &= _indi[PREV][0] > Chart().GetOpen(1);
          }
          break;
        case ORDER_TYPE_SELL:
          _result = _indi[CURR][0] - level > Chart().GetOpen(0);
          _result |= _indi[PREV][0] - level > Chart().GetOpen(1);
          if (_method != 0) {
            if (METHOD(_method, 0)) _result &= _indi[PREV][0] + level < Market().GetAsk();
            if (METHOD(_method, 1)) _result &= _indi[CURR][0] > _indi[PREV][0];
            if (METHOD(_method, 2)) _result &= _indi[PREV][0] - _indi[CURR][0] <= _indi[PPREV][0] - _indi[PREV][0];
            if (METHOD(_method, 3)) _result &= _indi[PPREV][0] < Market().GetAsk();
            if (METHOD(_method, 4)) _result &= _indi[CURR][0] >= Chart().GetClose(0);
            if (METHOD(_method, 5)) _result &= _indi[PREV][0] < Chart().GetClose(1);
            if (METHOD(_method, 6)) _result &= _indi[PREV][0] < Chart().GetOpen(1);
          }
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
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
        case 1:
          _diff = fabs(open_0 - _indi[CURR][0]);
          _result = open_0 + (_diff + _trail) * _direction;
          break;
        case 2:
          _diff = fmax(fabs(open_0 - fmax(_indi[CURR][0], _indi[PREV][0])),
                       fabs(open_0 - fmin(_indi[CURR][0], _indi[PREV][0])));
          _result = open_0 + (_diff + _trail) * _direction;
          break;
        case 3: {
          int _bar_count = (int)_level * 10;
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count));
          break;
        }
      }
    }
    return (float)_result;
  }
};

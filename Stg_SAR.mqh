/**
 * @file
 * Implements SAR strategy based on the Parabolic Stop and Reverse system indicator.
 */

// User input params.
INPUT_GROUP("SAR strategy: strategy params");
INPUT float SAR_LotSize = 0;                // Lot size
INPUT int SAR_SignalOpenMethod = 0;         // Signal open method (-127-127)
INPUT float SAR_SignalOpenLevel = 0.11f;    // Signal open level
INPUT int SAR_SignalOpenFilterMethod = 32;  // Signal open filter method
INPUT int SAR_SignalOpenFilterTime = 6;     // Signal open filter time
INPUT int SAR_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT int SAR_SignalCloseMethod = 0;        // Signal close method (-127-127)
INPUT int SAR_SignalCloseFilter = 32;       // Signal close filter (-127-127)
INPUT float SAR_SignalCloseLevel = 0.11f;   // Signal close level
INPUT int SAR_PriceStopMethod = 1;          // Price stop method (0-127)
INPUT float SAR_PriceStopLevel = 0;         // Price stop level
INPUT int SAR_TickFilterMethod = -48;       // Tick filter method
INPUT float SAR_MaxSpread = 4.0;            // Max spread to trade (pips)
INPUT short SAR_Shift = 0;                  // Shift
INPUT float SAR_OrderCloseLoss = 0;         // Order close loss
INPUT float SAR_OrderCloseProfit = 0;       // Order close profit
INPUT int SAR_OrderCloseTime = -30;         // Order close time in mins (>0) or bars (<0)
INPUT_GROUP("SAR strategy: SAR indicator params");
INPUT float SAR_Indi_SAR_Step = 0.011f;        // Step
INPUT float SAR_Indi_SAR_Maximum_Stop = 0.1f;  // Maximum stop
INPUT int SAR_Indi_SAR_Shift = 0;              // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_SAR_Params_Defaults : SARParams {
  Indi_SAR_Params_Defaults() : SARParams(::SAR_Indi_SAR_Step, ::SAR_Indi_SAR_Maximum_Stop, ::SAR_Indi_SAR_Shift) {}
} indi_sar_defaults;

// Defines struct with default user strategy values.
struct Stg_SAR_Params_Defaults : StgParams {
  Stg_SAR_Params_Defaults()
      : StgParams(::SAR_SignalOpenMethod, ::SAR_SignalOpenFilterMethod, ::SAR_SignalOpenLevel,
                  ::SAR_SignalOpenBoostMethod, ::SAR_SignalCloseMethod, ::SAR_SignalCloseFilter, ::SAR_SignalCloseLevel,
                  ::SAR_PriceStopMethod, ::SAR_PriceStopLevel, ::SAR_TickFilterMethod, ::SAR_MaxSpread, ::SAR_Shift) {
    Set(STRAT_PARAM_OCL, SAR_OrderCloseLoss);
    Set(STRAT_PARAM_OCP, SAR_OrderCloseProfit);
    Set(STRAT_PARAM_OCT, SAR_OrderCloseTime);
    Set(STRAT_PARAM_SOFT, SAR_SignalOpenFilterTime);
  }
} stg_sar_defaults;

// Struct to define strategy parameters to override.
struct Stg_SAR_Params : StgParams {
  SARParams iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_SAR_Params(SARParams &_iparams, StgParams &_sparams)
      : iparams(indi_sar_defaults, _iparams.tf.GetTf()), sparams(stg_sar_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

#ifdef __config__
// Loads pair specific param values.
#include "config/H1.h"
#include "config/H4.h"
#include "config/H8.h"
#include "config/M1.h"
#include "config/M15.h"
#include "config/M30.h"
#include "config/M5.h"
#endif

class Stg_SAR : public Strategy {
 public:
  Stg_SAR(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_SAR *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    SARParams _indi_params(indi_sar_defaults, _tf);
    StgParams _stg_params(stg_sar_defaults);
#ifdef __config__
    SetParamsByTf<SARParams>(_indi_params, _tf, indi_sar_m1, indi_sar_m5, indi_sar_m15, indi_sar_m30, indi_sar_h1,
                             indi_sar_h4, indi_sar_h8);
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_sar_m1, stg_sar_m5, stg_sar_m15, stg_sar_m30, stg_sar_h1, stg_sar_h4,
                             stg_sar_h8);
#endif
    // Initialize indicator.
    SARParams sar_params(_indi_params);
    _stg_params.SetIndicator(new Indi_SAR(_indi_params));
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams(_magic_no, _log_level);
    Strategy *_strat = new Stg_SAR(_stg_params, _tparams, _cparams, "SAR");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_SAR *_indi = GetIndicator();
    bool _result =
        _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift) && _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift + 2);
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    IndicatorSignal _signals = _indi.GetSignals(4, _shift);
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result &= _indi[_shift + 2][0] > _indi[_shift][0];
        _result &= _indi.IsIncreasing(1, 0, _shift);
        _result &= _indi.IsDecByPct(-_level, 0, _shift, 2);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
      case ORDER_TYPE_SELL:
        _result &= _indi[_shift + 2][0] < _indi[_shift][0];
        _result &= _indi.IsDecreasing(1, 0, _shift);
        _result &= _indi.IsIncByPct(_level, 0, _shift, 2);
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
    }
    return _result;
  }
};

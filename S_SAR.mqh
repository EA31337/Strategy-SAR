//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2017, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Properties.
#property strict

/**
 * @file
 * Implementation of SAR strategy based on the Parabolic Stop and Reverse system indicator.
 *
 * @docs
 * - https://docs.mql4.com/indicators/iSAR
 * - https://www.mql5.com/en/docs/indicators/iSAR
 */

// Includes.
#include <EA31337-classes\Strategy.mqh>
#include <EA31337-classes\Strategies.mqh>

// User inputs.
#ifdef __input__ input #endif string __SAR_Parameters__ = "-- Settings for the Parabolic Stop and Reverse system indicator --"; // >>> SAR <<<
#ifdef __input__ input #endif double SAR_Step = 0.15; // Step
#ifdef __input__ input #endif double SAR_Step_Ratio = 0.3; // Step ratio between timeframes (0.5-1.5)
#ifdef __input__ input #endif double SAR_Maximum_Stop = 0.40000000; // Maximum stop
#ifdef __input__ input #endif int SAR_Shift = 0; // Shift
#ifdef __input__ input #endif double SAR_SignalLevel = 0.00000000; // Signal level
#ifdef __input__ input #endif int SAR_SignalMethod = 0; // Signal method for M1 (-127-127)

class SAR: public Strategy {
protected:

  double sar[H1][3]; int sar_week[H1][7][2];
  int       open_method = EMPTY;    // Open method.
  double    open_level  = 0.0;     // Open level.

    public:

  /**
   * Update indicator values.
   */
  bool Update(int tf = EMPTY) {
    // Calculates the Parabolic Stop and Reverse system indicator.
    ratio = tf == 30 ? 1.0 : fmax(SAR_Step_Ratio, NEAR_ZERO) / tf * 30;
    for (i = 0; i < FINAL_ENUM_INDICATOR_INDEX; i++) {
      sar[index][i] = iSAR(symbol, tf, SAR_Step * ratio, SAR_Maximum_Stop, i + SAR_Shift);
    }
    if (VerboseDebug) PrintFormat("SAR M%d: %s", tf, Arrays::ArrToString2D(sar, ",", Digits));
    success = (bool) sar[index][CURR] + sar[index][PREV] + sar[index][FAR];
  }

  /**
   * Check if SAR indicator is on buy or sell.
   *
   * @param
   *   cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   signal_method (int) - signal method to use by using bitwise AND operation
   *   signal_level (double) - signal level to consider the signal (in pips)
   *   signal_level (double) - signal level to consider the signal
   */
  bool Signal(int cmd, ENUM_TIMEFRAMES tf = PERIOD_M1, int signal_method = EMPTY, double signal_level = EMPTY) {
    bool result = FALSE; int period = Timeframe::TfToIndex(tf);
    UpdateIndicator(S_SAR, tf);
    if (signal_method == EMPTY) signal_method = GetStrategySignalMethod(S_SAR, tf, 0);
    if (signal_level  == EMPTY) signal_level  = GetStrategySignalLevel(S_SAR, tf, 0);
    double gap = signal_level * pip_size;
    switch (cmd) {
      case OP_BUY:
        result = sar[period][CURR] + gap < Open[CURR] || sar[period][PREV] + gap < Open[PREV];
        if ((signal_method &   1) != 0) result &= sar[period][PREV] - gap > Ask;
        if ((signal_method &   2) != 0) result &= sar[period][CURR] < sar[period][PREV];
        if ((signal_method &   4) != 0) result &= sar[period][CURR] - sar[period][PREV] <= sar[period][PREV] - sar[period][FAR];
        if ((signal_method &   8) != 0) result &= sar[period][FAR] > Ask;
        if ((signal_method &  16) != 0) result &= sar[period][CURR] <= Close[CURR];
        if ((signal_method &  32) != 0) result &= sar[period][PREV] > Close[PREV];
        if ((signal_method &  64) != 0) result &= sar[period][PREV] > Open[PREV];
        if (result) {
          // FIXME: Convert into more flexible way.
          signals[DAILY][SAR1][period][OP_BUY]++; signals[WEEKLY][SAR1][period][OP_BUY]++;
          signals[MONTHLY][SAR1][period][OP_BUY]++; signals[YEARLY][SAR1][period][OP_BUY]++;
        }
        break;
      case OP_SELL:
        result = sar[period][CURR] - gap > Open[CURR] || sar[period][PREV] - gap > Open[PREV];
        if ((signal_method &   1) != 0) result &= sar[period][PREV] + gap < Ask;
        if ((signal_method &   2) != 0) result &= sar[period][CURR] > sar[period][PREV];
        if ((signal_method &   4) != 0) result &= sar[period][PREV] - sar[period][CURR] <= sar[period][FAR] - sar[period][PREV];
        if ((signal_method &   8) != 0) result &= sar[period][FAR] < Ask;
        if ((signal_method &  16) != 0) result &= sar[period][CURR] >= Close[CURR];
        if ((signal_method &  32) != 0) result &= sar[period][PREV] < Close[PREV];
        if ((signal_method &  64) != 0) result &= sar[period][PREV] < Open[PREV];
        if (result) {
          // FIXME: Convert into more flexible way.
          signals[DAILY][SAR1][period][OP_SELL]++; signals[WEEKLY][SAR1][period][OP_SELL]++;
          signals[MONTHLY][SAR1][period][OP_SELL]++; signals[YEARLY][SAR1][period][OP_SELL]++;
        }
        break;
    }
    result &= signal_method <= 0 || Convert::ValueToOp(curr_trend) == cmd;
    if (VerboseTrace && result) {
      PrintFormat("%s:%d: Signal: %d/%d/%d/%g", __FUNCTION__, __LINE__, cmd, tf, signal_method, signal_level);
    }
    return result;
  }
};

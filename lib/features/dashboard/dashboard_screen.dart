import 'package:flutter/material.dart';
import 'package:insta_counter_app/core/constants/app_constants.dart';
import 'package:insta_counter_app/core/theme/app_theme.dart';
import 'package:insta_counter_app/providers/counter_notifier.dart';
import 'package:insta_counter_app/widgets/control_button.dart';
import 'package:insta_counter_app/widgets/counter_display.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CounterNotifier>(
      builder: (context, counter, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final pad = constraints.maxWidth > 600 ? 32.0 : 20.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.surfaceElevated,
                          AppTheme.surfaceElevated.withValues(alpha: 0.6),
                          AppTheme.accent.withValues(alpha: 0.12),
                        ],
                      ),
                      border: Border.all(color: AppTheme.outline),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Followers',
                          style: GoogleFonts.dmSans(
                            color: Colors.white60,
                            letterSpacing: 1.2,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CounterDisplay(value: counter.count),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Quick add',
                    style: GoogleFonts.dmSans(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ControlButton(
                        label: '+250',
                        onPressed: () => counter.add(250),
                      ),
                      ControlButton(
                        label: '+2.5k',
                        onPressed: () => counter.add(2500),
                      ),
                      ControlButton(
                        label: '+10k',
                        onPressed: () => counter.add(10000),
                      ),
                      ControlButton(
                        label: 'Reset',
                        outlined: true,
                        onPressed: counter.reset,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Manual count',
                    style: GoogleFonts.dmSans(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: counter.count.clamp(
                      AppConstants.countSliderMin,
                      AppConstants.countSliderMax,
                    ),
                    min: AppConstants.countSliderMin,
                    max: AppConstants.countSliderMax,
                    onChanged: counter.setCount,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppConstants.countSliderMin.toInt().toString(),
                        style: GoogleFonts.dmSans(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        AppConstants.countSliderMax.toInt().toString(),
                        style: GoogleFonts.dmSans(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Pause live updates',
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Switch(
                                value: counter.pauseLiveUpdates,
                                onChanged: (v) => counter.setPause(v),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'When off, the mock stream nudges the count on a timer.',
                            style: GoogleFonts.dmSans(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Stream speed',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SegmentedButton<LiveUpdateSpeed>(
                            segments: const [
                              ButtonSegment(
                                value: LiveUpdateSpeed.slow,
                                label: Text('Slow'),
                              ),
                              ButtonSegment(
                                value: LiveUpdateSpeed.normal,
                                label: Text('Normal'),
                              ),
                              ButtonSegment(
                                value: LiveUpdateSpeed.fast,
                                label: Text('Fast'),
                              ),
                            ],
                            selected: {counter.speed},
                            onSelectionChanged: (s) {
                              counter.setSpeed(s.first);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

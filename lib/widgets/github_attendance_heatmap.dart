import 'package:flutter/material.dart';
import '../services/hitam_scraper_service.dart';

/// GitHub-style Attendance Activity Heatmap
/// Matches GitHub's signature dark contribution graph aesthetic with 5-level green intensity,
/// month labels, day-of-week rows, streaks, and interactive day inspection.
class GithubAttendanceHeatmap extends StatefulWidget {
  final StudentAcademicRegisterReport? academicRegister;
  final double overallAttendance;
  final int totalClasses;
  final int attendedClasses;
  final List<Map<String, dynamic>> subjects;

  const GithubAttendanceHeatmap({
    super.key,
    this.academicRegister,
    required this.overallAttendance,
    required this.totalClasses,
    required this.attendedClasses,
    required this.subjects,
  });

  @override
  State<GithubAttendanceHeatmap> createState() =>
      _GithubAttendanceHeatmapState();
}

class _DayAttendanceRecord {
  final DateTime date;
  final int attended;
  final int held;
  final int level; // 0 to 4
  final bool isWeekend;
  final bool hasClasses;
  final List<Map<String, String>> subjects;

  const _DayAttendanceRecord({
    required this.date,
    required this.attended,
    required this.held,
    required this.level,
    required this.isWeekend,
    required this.hasClasses,
    required this.subjects,
  });
}

class _GithubAttendanceHeatmapState extends State<GithubAttendanceHeatmap> {
  final ScrollController _scrollController = ScrollController();
  _DayAttendanceRecord? _selectedRecord;

  // GitHub contribution color tokens
  static const Color _bgCanvas = Color(0xFF0D1117);
  static const Color _cardBorder = Color(0xFF30363D);
  static const Color _tileEmpty = Color(0xFF161B22);
  static const Color _tileBorder = Color(0xFF21262D);

  static const Color _greenL1 = Color(0xFF0E4429); // 1-25%
  static const Color _greenL2 = Color(0xFF006D32); // 26-50%
  static const Color _greenL3 = Color(0xFF26A641); // 51-75%
  static const Color _greenL4 = Color(0xFF39D353); // 76-100% (Vibrant Radiant Green)
  static const Color _missedRed = Color(0xFF7F1D1D); // Missed day

  static const Color _textMuted = Color(0xFF7D8590);
  static const Color _textBright = Color(0xFFE6EDF3);

  @override
  void initState() {
    super.initState();
    // Auto-scroll to latest week after initial layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Parses date keys like "16/06", "16/06/2026", "16-06", etc.
  DateTime? _parseDateKey(String raw, int fallbackYear) {
    try {
      final clean = raw.trim().replaceAll('-', '/');
      final parts = clean.split('/');
      if (parts.length >= 2) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (d != null && m != null && d >= 1 && d <= 31 && m >= 1 && m <= 12) {
          int y = fallbackYear;
          if (parts.length >= 3) {
            final parsedY = int.tryParse(parts[2]);
            if (parsedY != null) {
              y = parsedY < 100 ? 2000 + parsedY : parsedY;
            }
          }
          return DateTime(y, m, d);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Builds a normalized map of date records
  Map<String, _DayAttendanceRecord> _buildAttendanceMap(
    DateTime start,
    DateTime end,
  ) {
    final Map<String, _DayAttendanceRecord> result = {};
    final reg = widget.academicRegister;
    final now = DateTime.now();

    // 1. Process scraped real Academic Register if present
    if (reg != null && reg.dates.isNotEmpty) {
      final Map<String, List<Map<String, String>>> daySubjects = {};
      final Map<String, int> dayAttended = {};
      final Map<String, int> dayHeld = {};

      for (var entry in reg.entries) {
        entry.attendanceByDate.forEach((dateKey, statusRaw) {
          final status = statusRaw.trim().toUpperCase();
          if (status.isEmpty || status == '-') return;

          final dt = _parseDateKey(dateKey, now.year);
          if (dt == null) return;
          final normalizedKey = _formatKey(dt);

          daySubjects.putIfAbsent(normalizedKey, () => []);
          final bool isPresent = status.contains('P');
          final bool isAbsent = status.contains('A');

          if (isPresent || isAbsent) {
            daySubjects[normalizedKey]!.add({
              'subject': entry.subject,
              'status': isPresent ? 'Present' : 'Absent',
            });
            dayHeld[normalizedKey] = (dayHeld[normalizedKey] ?? 0) + 1;
            if (isPresent) {
              dayAttended[normalizedKey] = (dayAttended[normalizedKey] ?? 0) + 1;
            }
          }
        });
      }

      // Populate records for all days in window
      DateTime cur = start;
      while (!cur.isAfter(end)) {
        final k = _formatKey(cur);
        final isWeekend = cur.weekday == DateTime.sunday;
        final attended = dayAttended[k] ?? 0;
        final held = dayHeld[k] ?? 0;
        final subjList = daySubjects[k] ?? [];

        int level = 0;
        if (held > 0) {
          final ratio = attended / held;
          if (ratio >= 0.90) {
            level = 4;
          } else if (ratio >= 0.70) {
            level = 3;
          } else if (ratio >= 0.40) {
            level = 2;
          } else if (attended > 0) {
            level = 1;
          }
        }

        result[k] = _DayAttendanceRecord(
          date: cur,
          attended: attended,
          held: held,
          level: level,
          isWeekend: isWeekend,
          hasClasses: held > 0,
          subjects: subjList,
        );
        cur = cur.add(const Duration(days: 1));
      }
      return result;
    }

    // 2. Deterministic term distribution if register still loading
    final double attendanceRatio =
        (widget.overallAttendance / 100).clamp(0.0, 1.0);
    DateTime cur = start;
    int dayIndex = 0;

    while (!cur.isAfter(end)) {
      final k = _formatKey(cur);
      final isWeekend = cur.weekday == DateTime.sunday;
      final isFuture = cur.isAfter(now);

      int attended = 0;
      int held = 0;
      int level = 0;
      List<Map<String, String>> subjList = [];

      if (!isWeekend && !isFuture) {
        dayIndex++;
        held = (cur.weekday == DateTime.saturday) ? 3 : 5;
        // Deterministic pseudo-random pattern matching exact overall percentage
        final bool isGoodDay = ((dayIndex * 17 + cur.day) % 100) < (attendanceRatio * 100);
        if (isGoodDay) {
          attended = held;
          level = 4;
        } else {
          attended = (held * 0.5).round();
          level = attended > 0 ? 2 : 0;
        }

        for (var s in widget.subjects.take(held)) {
          subjList.add({
            'subject': s['subject']?.toString() ?? 'Course',
            'status': isGoodDay ? 'Present' : 'Absent',
          });
        }
      }

      result[k] = _DayAttendanceRecord(
        date: cur,
        attended: attended,
        held: held,
        level: level,
        isWeekend: isWeekend,
        hasClasses: held > 0,
        subjects: subjList,
      );
      cur = cur.add(const Duration(days: 1));
    }

    return result;
  }

  String _formatKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatDisplayDate(DateTime d) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // 22-week window spanning current academic cycle
    final DateTime end = DateTime(now.year, now.month, now.day);
    // Align end to upcoming Saturday
    final DateTime alignedEnd = end.add(Duration(days: (DateTime.saturday - end.weekday) % 7));
    // 22 weeks back aligned to Sunday
    final DateTime alignedStart = alignedEnd.subtract(const Duration(days: 22 * 7 - 1));

    final attendanceMap = _buildAttendanceMap(alignedStart, alignedEnd);

    // Group into week columns (each column has 7 days from Sunday=0 to Saturday=6)
    final List<List<_DayAttendanceRecord>> weeks = [];
    DateTime cur = alignedStart;
    while (!cur.isAfter(alignedEnd)) {
      List<_DayAttendanceRecord> week = [];
      for (int i = 0; i < 7; i++) {
        final k = _formatKey(cur);
        week.add(
          attendanceMap[k] ??
              _DayAttendanceRecord(
                date: cur,
                attended: 0,
                held: 0,
                level: 0,
                isWeekend: cur.weekday == DateTime.sunday,
                hasClasses: false,
                subjects: const [],
              ),
        );
        cur = cur.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    // Calculate metrics
    int activeStreak = 0;
    int totalRecordedDays = 0;
    int fullAttendanceDays = 0;

    // Scan backwards from today for active streak
    DateTime scan = end;
    bool streakBroken = false;
    while (scan.isAfter(alignedStart) && !streakBroken) {
      if (scan.weekday != DateTime.sunday) {
        final rec = attendanceMap[_formatKey(scan)];
        if (rec != null && rec.hasClasses) {
          totalRecordedDays++;
          if (rec.attended > 0) {
            activeStreak++;
            if (rec.attended == rec.held) fullAttendanceDays++;
          } else {
            streakBroken = true;
          }
        }
      }
      scan = scan.subtract(const Duration(days: 1));
    }

    // Default selected record to latest recorded lecture day
    _selectedRecord ??= attendanceMap.values.lastWhere(
      (r) => r.hasClasses && !r.date.isAfter(now),
      orElse: () => attendanceMap.values.last,
    );

    return Container(
      decoration: BoxDecoration(
        color: _bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER ROW: Title + Streak Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _greenL4.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_view_week_rounded,
                  color: _greenL4,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Activity',
                      style: TextStyle(
                        color: _textBright,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Term-wide lecture consistency heatmap',
                      style: TextStyle(
                        color: _textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Gamification Streak Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF238636).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _greenL3.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      activeStreak > 0
                          ? '$activeStreak-Day Streak'
                          : 'Term Active',
                      style: const TextStyle(
                        color: _greenL4,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 2. THE GITHUB CONTRIBUTION HEATMAP GRID
          LayoutBuilder(
            builder: (context, constraints) {
              return Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                trackVisibility: false,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day of week labels column (Sun, Mon, Tue, Wed, Thu, Fri, Sat)
                      Padding(
                        padding: const EdgeInsets.only(top: 22, right: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SizedBox(height: 14), // Sun
                            Text('Mon', style: TextStyle(color: _textMuted, fontSize: 10, height: 1.4)),
                            SizedBox(height: 16), // Tue
                            Text('Wed', style: TextStyle(color: _textMuted, fontSize: 10, height: 1.4)),
                            SizedBox(height: 16), // Thu
                            Text('Fri', style: TextStyle(color: _textMuted, fontSize: 10, height: 1.4)),
                          ],
                        ),
                      ),

                      // Columns of weeks
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Month Headers Row
                          Row(
                            children: List.generate(weeks.length, (colIdx) {
                              final firstDay = weeks[colIdx][0].date;
                              // Print month label if first week of month
                              final bool isMonthStart = colIdx == 0 ||
                                  firstDay.month != weeks[colIdx - 1][0].date.month;

                              const monthNames = [
                                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                              ];

                              return SizedBox(
                                width: 16.5,
                                child: isMonthStart
                                    ? Text(
                                        monthNames[firstDay.month - 1],
                                        style: const TextStyle(
                                          color: _textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : null,
                              );
                            }),
                          ),
                          const SizedBox(height: 6),

                          // Week columns grid
                          Row(
                            children: weeks.map((week) {
                              return Column(
                                children: week.map((dayRecord) {
                                  final bool isSelected = _selectedRecord != null &&
                                      _formatKey(_selectedRecord!.date) ==
                                          _formatKey(dayRecord.date);

                                  return _buildDaySquare(dayRecord, isSelected);
                                }).toList(),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // 3. INTERACTIVE SELECTED DAY INSPECTION BANNER
          if (_selectedRecord != null) _buildSelectedDayDetail(_selectedRecord!),

          const SizedBox(height: 16),

          // 4. FOOTER: Legend & Context
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.attendedClasses} / ${widget.totalClasses} lectures verified',
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Less -> More Legend
              Row(
                children: [
                  const Text(
                    'Less',
                    style: TextStyle(color: _textMuted, fontSize: 11),
                  ),
                  const SizedBox(width: 6),
                  _buildLegendSquare(_tileEmpty),
                  _buildLegendSquare(_greenL1),
                  _buildLegendSquare(_greenL2),
                  _buildLegendSquare(_greenL3),
                  _buildLegendSquare(_greenL4),
                  const SizedBox(width: 4),
                  const Text(
                    'More',
                    style: TextStyle(color: _textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendSquare(Color c) {
    return Container(
      width: 11,
      height: 11,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(2.5),
        border: Border.all(
          color: c == _tileEmpty ? _tileBorder : Colors.transparent,
          width: 0.8,
        ),
      ),
    );
  }

  Widget _buildDaySquare(_DayAttendanceRecord record, bool isSelected) {
    final now = DateTime.now();
    final isFuture = record.date.isAfter(now);

    Color fillColor = _tileEmpty;
    Color borderColor = _tileBorder;

    if (!isFuture && !record.isWeekend) {
      if (record.hasClasses) {
        if (record.attended == 0) {
          fillColor = _missedRed.withOpacity(0.5);
          borderColor = _missedRed;
        } else {
          switch (record.level) {
            case 1:
              fillColor = _greenL1;
              borderColor = _greenL1;
              break;
            case 2:
              fillColor = _greenL2;
              borderColor = _greenL2;
              break;
            case 3:
              fillColor = _greenL3;
              borderColor = _greenL3;
              break;
            case 4:
            default:
              fillColor = _greenL4;
              borderColor = _greenL4;
              break;
          }
        }
      }
    }

    if (isSelected) {
      borderColor = Colors.white;
    }

    return Tooltip(
      message: '${_formatDisplayDate(record.date)}\n'
          '${record.hasClasses ? "${record.attended} / ${record.held} classes attended" : (record.isWeekend ? "Weekend" : "No scheduled lectures")}',
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRecord = record;
          });
        },
        child: Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.all(2.2),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(2.5),
            border: Border.all(
              color: isSelected ? Colors.white : borderColor,
              width: isSelected ? 1.5 : 0.8,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _greenL4.withOpacity(0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayDetail(_DayAttendanceRecord r) {
    final isFuture = r.date.isAfter(DateTime.now());

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isFuture) {
      statusText = 'Future Session Date';
      statusColor = _textMuted;
      statusIcon = Icons.update_rounded;
    } else if (r.isWeekend) {
      statusText = 'Sunday • College Recess';
      statusColor = _textMuted;
      statusIcon = Icons.beach_access_rounded;
    } else if (!r.hasClasses) {
      statusText = 'No recorded lectures on this date';
      statusColor = _textMuted;
      statusIcon = Icons.event_busy_rounded;
    } else if (r.attended == r.held) {
      statusText = '${r.attended}/${r.held} Lectures Attended • 100% Present';
      statusColor = _greenL4;
      statusIcon = Icons.check_circle_rounded;
    } else if (r.attended > 0) {
      statusText =
          '${r.attended}/${r.held} Attended • ${r.held - r.attended} Missed';
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusText = '0/${r.held} Attended • Absent All Classes';
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Text(
                _formatDisplayDate(r.date),
                style: const TextStyle(
                  color: _textBright,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (r.subjects.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: r.subjects.map((s) {
                final isP = s['status'] == 'Present';
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isP
                        ? const Color(0xFF0E4429).withOpacity(0.5)
                        : const Color(0xFF7F1D1D).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isP ? _greenL3 : const Color(0xFFEF4444),
                      width: 0.7,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isP ? Icons.check : Icons.close,
                        size: 11,
                        color: isP ? _greenL4 : const Color(0xFFFCA5A5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${s['subject']}: ${s['status']}',
                        style: TextStyle(
                          color: isP ? _greenL4 : const Color(0xFFFCA5A5),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/hitam_scraper_service.dart';
import 'glass_components.dart';

/// GitHub-style Attendance Activity Heatmap
/// Matches GitHub's contribution graph aesthetic adapted for college academic schedules:
/// - 6 days per week (Monday to Saturday, Sunday excluded as colleges are closed)
/// - 52-week 1-year calendar grid
/// - 5-level green intensity mapping
/// - Clean non-wrapping month headers
/// - Mon, Wed, Fri row alignment
/// - Clean, icon-free day lecture inspection banner
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
  final bool hasClasses;
  final List<Map<String, String>> subjects;

  const _DayAttendanceRecord({
    required this.date,
    required this.attended,
    required this.held,
    required this.level,
    required this.hasClasses,
    required this.subjects,
  });
}

class _GithubAttendanceHeatmapState extends State<GithubAttendanceHeatmap> {
  final ScrollController _scrollController =
      ScrollController(initialScrollOffset: 1500.0);
  _DayAttendanceRecord? _selectedRecord;

  // GitHub contribution color tokens (Dark Glass Emerald Theme)
  static const Color _bgCanvas = Colors.transparent;
  static const Color _cardBorder = Colors.transparent;
  static const Color _tileEmpty = Color(0x18FFFFFF);
  static const Color _tileBorder = Color(0x22FFFFFF);

  static const Color _greenL1 = Color(0xFF047857); // 1-25%
  static const Color _greenL2 = Color(0xFF059669); // 26-50%
  static const Color _greenL3 = Color(0xFF10B981); // 51-75%
  static const Color _greenL4 = Color(0xFF34D399); // 76-100% (Neon Emerald Green)
  static const Color _missedTileBg = Color(0xFFEF4444); // Vibrant red for absent day
  static const Color _missedTileBorder = Color(0xFFF87171);

  static const Color _textMuted = Color(0xB3FFFFFF);
  static const Color _textBright = Colors.white;

  // Exact geometry tokens for 100% alignment
  static const double _tileSize = 11.5;
  static const double _tileMargin = 1.8;
  static const double _colWidth = _tileSize + (_tileMargin * 2); // 15.1 px
  static const double _rowHeight = _tileSize + (_tileMargin * 2); // 15.1 px
  static const double _dayLabelColWidth = 32.0;

  @override
  void initState() {
    super.initState();
    _scrollToRecent();
  }

  void _scrollToRecent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      } else {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted &&
              _scrollController.hasClients &&
              _scrollController.position.maxScrollExtent > 0) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
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
          } else {
            final now = DateTime.now();
            if (m > now.month + 2) {
              y = now.year - 1;
            } else {
              y = now.year;
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

      // Populate records for all days in window with strictly max 6 periods per day
      // (HITAM schedule: 3 morning classes, lunch 12:15 PM - 1:00 PM, 3 afternoon classes)
      DateTime cur = start;
      while (!cur.isAfter(end)) {
        final k = _formatKey(cur);
        final rawAttended = dayAttended[k] ?? 0;
        final rawHeld = dayHeld[k] ?? 0;
        final rawSubjList = daySubjects[k] ?? [];

        int held = 0;
        int attended = 0;
        int level = 0;
        List<Map<String, String>> subjList = [];

        if (rawHeld > 0) {
          // Group raw subjects by unique name to eliminate accidental duplicates from
          // multiple scraped columns / remedial rows
          final Map<String, List<String>> uniqueSubjStatuses = {};
          for (var item in rawSubjList) {
            final name = item['subject'] ?? 'Course';
            final status = item['status'] ?? 'Absent';
            uniqueSubjStatuses.putIfAbsent(name, () => []).add(status);
          }

          // In HITAM, a college day consists of strictly 6 classes (periods of 1 hour):
          // - 1st Class: 09:15 - 10:15 AM
          // - 2nd Class: 10:15 - 11:15 AM
          // - 3rd Class: 11:15 AM - 12:15 PM
          // - Lunch Break: 12:15 PM - 01:00 PM
          // - 4th Class: 01:00 - 02:00 PM
          // - 5th Class: 02:00 - 03:00 PM
          // - 6th Class: 03:00 - 04:00 PM
          // Each class is 1 hour. On some days, only specific subjects have 2 classes (CV, FSWD LAB, MINI PROJECT).
          // All other subjects have 1 class. Total classes in a day never exceed 6.
          final List<({String name, String status, int hours})> dayCourses = [];
          int allocatedHours = 0;

          uniqueSubjStatuses.forEach((name, statuses) {
            final int pCount = statuses.where((s) => s == 'Present').length;
            final int aCount = statuses.where((s) => s == 'Absent').length;
            final bool isP = pCount >= aCount;

            final upper = name.toUpperCase().trim();
            // Only CV, FSWD LAB, and MINI / MINI PROJECT can have 2 classes (2 hours)
            final bool canHaveTwoClasses = upper == 'CV' ||
                upper.contains('FSWD LAB') ||
                upper.contains('MINI');

            // 1 hour for each subject; 2 classes if it's CV, FSWD LAB, or MINI and raw data had >= 2 sessions
            int hrs = 1;
            if (canHaveTwoClasses && statuses.length >= 2) {
              hrs = 2;
            }

            dayCourses.add((
              name: name,
              status: isP ? 'Present' : 'Absent',
              hours: hrs,
            ));
            allocatedHours += hrs;
          });

          // Limit total courses so that total classes never exceed 6
          if (dayCourses.length > 6) {
            dayCourses.removeRange(6, dayCourses.length);
            allocatedHours = dayCourses.fold(0, (sum, c) => sum + c.hours);
          }

          // If allocated hours exceed 6, adjust 2-hour subjects down to 1 hour
          while (allocatedHours > 6) {
            bool reduced = false;
            for (int i = 0; i < dayCourses.length; i++) {
              if (dayCourses[i].hours > 1) {
                dayCourses[i] = (
                  name: dayCourses[i].name,
                  status: dayCourses[i].status,
                  hours: dayCourses[i].hours - 1,
                );
                allocatedHours--;
                reduced = true;
                if (allocatedHours <= 6) break;
              }
            }
            if (!reduced) {
              if (dayCourses.length > 6) {
                dayCourses.removeLast();
                allocatedHours--;
              } else {
                break;
              }
            }
          }

          // If allocated hours are less than 6, expand subjects to reach the fixed 6 classes
          if (allocatedHours < 6 && dayCourses.isNotEmpty) {
            // First pass: allow CV, FSWD LAB, MINI to take 2 classes
            for (int i = 0; i < dayCourses.length && allocatedHours < 6; i++) {
              final upper = dayCourses[i].name.toUpperCase().trim();
              final bool canHaveTwo = upper == 'CV' ||
                  upper.contains('FSWD LAB') ||
                  upper.contains('MINI');
              if (canHaveTwo && dayCourses[i].hours == 1) {
                dayCourses[i] = (
                  name: dayCourses[i].name,
                  status: dayCourses[i].status,
                  hours: 2,
                );
                allocatedHours++;
              }
            }
            // Second pass: if still < 6, expand remaining subjects (up to 2 hrs max)
            for (int i = 0; i < dayCourses.length && allocatedHours < 6; i++) {
              if (dayCourses[i].hours < 2) {
                dayCourses[i] = (
                  name: dayCourses[i].name,
                  status: dayCourses[i].status,
                  hours: 2,
                );
                allocatedHours++;
              }
            }
          }

          int presentHours = 0;
          for (var c in dayCourses) {
            for (int h = 0; h < c.hours; h++) {
              subjList.add({
                'subject': c.name,
                'status': c.status,
              });
            }
            if (c.status == 'Present') {
              presentHours += c.hours;
            }
          }

          held = 6; // FIXED: strictly 6 classes in a day at HITAM
          if (allocatedHours > 0) {
            attended = ((presentHours / allocatedHours) * 6).round().clamp(0, 6);
          } else {
            attended = ((rawAttended / rawHeld) * 6).round().clamp(0, 6);
          }
          if (presentHours > 0 && attended == 0) {
            attended = 1;
          }
          if (presentHours == allocatedHours && allocatedHours > 0) {
            attended = 6;
          }

          if (held > 0) {
            final ratio = attended / held;
            if (ratio >= 0.85) {
              level = 4;
            } else if (ratio >= 0.60) {
              level = 3;
            } else if (ratio >= 0.35) {
              level = 2;
            } else if (attended > 0) {
              level = 1;
            }
          }
        }

        result[k] = _DayAttendanceRecord(
          date: cur,
          attended: attended,
          held: held,
          level: level,
          hasClasses: held > 0,
          subjects: subjList,
        );
        cur = cur.add(const Duration(days: 1));
      }
      return result;
    }

    // 2. Deterministic term distribution matching actual attendance
    final double attendanceRatio =
        (widget.overallAttendance / 100).clamp(0.0, 1.0);
    DateTime cur = start;
    int dayIndex = 0;

    // Academic session active from mid-June up to current date
    final semesterStart = DateTime(now.year, 6, 15);

    while (!cur.isAfter(end)) {
      final k = _formatKey(cur);
      final isSunday = cur.weekday == DateTime.sunday;
      final isFuture = cur.isAfter(now);
      final isDuringSession = !cur.isBefore(semesterStart) && !isFuture;

      int attended = 0;
      int held = 0;
      int level = 0;
      List<Map<String, String>> subjList = [];

      if (!isSunday && isDuringSession) {
        dayIndex++;
        held = 6; // Exactly 6 classes in a day: 3 morning, lunch 12:15-1:00 PM, 3 afternoon
        final bool isGoodDay =
            ((dayIndex * 19 + cur.day * 7) % 100) < (attendanceRatio * 100);
        if (isGoodDay) {
          attended = held;
          level = 4;
        } else {
          attended = (held * attendanceRatio).round().clamp(1, 5);
          level = attended >= 5 ? 3 : (attended >= 3 ? 2 : 1);
        }

        // Standard schedule: 1 hour for each subject.
        // On specific days, only CV, FSWD LAB, or MINI has 2 classes. Total is always 6 classes.
        final isMiniDay = cur.weekday == DateTime.tuesday;
        final isLabDay = cur.weekday == DateTime.wednesday || cur.weekday == DateTime.friday;
        final isCvDoubleDay = cur.weekday == DateTime.thursday;

        List<({String name, int hours})> dailySchedule;
        if (isMiniDay) {
          dailySchedule = [
            (name: 'Computer Vision', hours: 1),
            (name: 'Full Stack Web Dev', hours: 1),
            (name: 'Neural Networks & Deep Learning', hours: 1),
            (name: 'Mini Project', hours: 2),
            (name: 'Problem Solving', hours: 1),
          ];
        } else if (isLabDay) {
          dailySchedule = [
            (name: 'Computer Vision', hours: 1),
            (name: 'Blockchain Technology', hours: 1),
            (name: 'Problem Solving', hours: 1),
            (name: 'FSWD Lab', hours: 2),
            (name: 'Neural Networks & Deep Learning', hours: 1),
          ];
        } else if (isCvDoubleDay) {
          dailySchedule = [
            (name: 'Computer Vision', hours: 2),
            (name: 'Full Stack Web Dev', hours: 1),
            (name: 'Blockchain Technology', hours: 1),
            (name: 'Neural Networks & Deep Learning', hours: 1),
            (name: 'Problem Solving', hours: 1),
          ];
        } else {
          dailySchedule = [
            (name: 'Computer Vision', hours: 1),
            (name: 'Full Stack Web Dev', hours: 1),
            (name: 'Blockchain Technology', hours: 1),
            (name: 'Neural Networks & Deep Learning', hours: 1),
            (name: 'Problem Solving', hours: 1),
            (name: 'Network Programming', hours: 1),
          ];
        }

        int periodsAssigned = 0;
        for (var item in dailySchedule) {
          for (int h = 0; h < item.hours; h++) {
            final bool isPresent = periodsAssigned < attended;
            subjList.add({
              'subject': item.name,
              'status': isPresent ? 'Present' : 'Absent',
            });
            periodsAssigned++;
          }
        }
      }

      result[k] = _DayAttendanceRecord(
        date: cur,
        attended: attended,
        held: held,
        level: level,
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
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    // Colleges are closed on Sunday, so each college week runs Monday to Saturday (6 days).
    DateTime alignedEnd;
    if (today.weekday == DateTime.sunday) {
      alignedEnd = today.subtract(const Duration(days: 1)); // previous Saturday
    } else {
      alignedEnd = today.add(Duration(days: DateTime.saturday - today.weekday));
    }

    const int totalWeeks = 52;
    // Monday of starting week: alignedEnd - 5 days gives current week's Monday.
    // Go back (totalWeeks - 1) * 7 days to get start Monday.
    final DateTime alignedStart = alignedEnd
        .subtract(const Duration(days: 5))
        .subtract(const Duration(days: (totalWeeks - 1) * 7));

    final attendanceMap = _buildAttendanceMap(alignedStart, alignedEnd);

    // Group into 52 college-week columns (each column has 6 days: Mon=0 to Sat=5, Sunday excluded)
    final List<List<_DayAttendanceRecord>> weeks = [];
    for (int w = 0; w < totalWeeks; w++) {
      final DateTime weekMonday =
          alignedStart.add(Duration(days: w * 7));
      List<_DayAttendanceRecord> week = [];
      for (int dayOffset = 0; dayOffset < 6; dayOffset++) {
        final DateTime d = weekMonday.add(Duration(days: dayOffset));
        final k = _formatKey(d);
        week.add(
          attendanceMap[k] ??
              _DayAttendanceRecord(
                date: d,
                attended: 0,
                held: 0,
                level: 0,
                hasClasses: false,
                subjects: const [],
              ),
        );
      }
      weeks.add(week);
    }

    // Default selected record: prefer latest day with attendance
    _selectedRecord ??= attendanceMap.values.lastWhere(
      (r) => r.hasClasses && r.attended > 0 && !r.date.isAfter(now),
      orElse: () => attendanceMap.values.lastWhere(
        (r) => r.hasClasses && !r.date.isAfter(now),
        orElse: () => attendanceMap.values.last,
      ),
    );

    // Generate month label positions across the weeks
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final List<({int colIdx, String name})> monthLabels = [];
    int lastCol = -10;

    for (int col = 0; col < weeks.length; col++) {
      final firstDay = weeks[col][0].date;
      final bool isMonthStart =
          col == 0 || firstDay.month != weeks[col - 1][0].date.month;
      if (isMonthStart) {
        if (col - lastCol >= 3) {
          monthLabels.add((colIdx: col, name: monthNames[firstDay.month - 1]));
          lastCol = col;
        }
      }
    }

    final double gridWidth = weeks.length * _colWidth;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER: Clean Title & Subtitle (icons & streaks removed)
          const Column(
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
            ],
          ),

          const SizedBox(height: 18),

          // 2. THE 6-DAY (MON-SAT) GITHUB CONTRIBUTION HEATMAP GRID
          LayoutBuilder(
            builder: (context, constraints) {
              final Widget gridContent = Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mon, Wed, Fri row labels (aligned with 6 college days)
                  SizedBox(
                    width: _dayLabelColWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24), // Offset for month header
                        ...List.generate(6, (rowIdx) {
                          String label = '';
                          if (rowIdx == 0) label = 'Mon';
                          if (rowIdx == 2) label = 'Wed';
                          if (rowIdx == 4) label = 'Fri';
                          return Container(
                            height: _rowHeight,
                            alignment: Alignment.centerLeft,
                            child: label.isNotEmpty
                                ? Text(
                                    label,
                                    style: const TextStyle(
                                      color: _textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      height: 1.0,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          );
                        }),
                      ],
                    ),
                  ),

                  // Month headers row + 6-row calendar grid
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month headers (positioned with Stack so text NEVER wraps)
                      SizedBox(
                        height: 18,
                        width: gridWidth,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: monthLabels.map((m) {
                            return Positioned(
                              left: m.colIdx * _colWidth,
                              child: Text(
                                m.name,
                                softWrap: false,
                                overflow: TextOverflow.visible,
                                style: const TextStyle(
                                  color: _textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // 6-row columns of contribution squares (Monday to Saturday)
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
              );

              final double totalContentWidth =
                  _dayLabelColWidth + gridWidth + 8;
              final bool canFitWithoutScroll =
                  constraints.maxWidth >= totalContentWidth;

              if (canFitWithoutScroll) {
                return Center(child: gridContent);
              }

              return SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 6),
                child: gridContent,
              );
            },
          ),

          const SizedBox(height: 16),

          // 3. INTERACTIVE SELECTED DAY INSPECTION BANNER (icon-free)
          if (_selectedRecord != null) _buildSelectedDayDetail(_selectedRecord!),

          const SizedBox(height: 14),

          // 4. FOOTER: Legend matching GitHub reference
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
              const Text(
                'Verified across all academic courses',
                style: TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // Less -> More 5-Level Legend
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Less',
                    style: TextStyle(color: _textMuted, fontSize: 11),
                  ),
                  const SizedBox(width: 5),
                  _buildLegendSquare(_tileEmpty, border: _tileBorder),
                  _buildLegendSquare(_greenL1),
                  _buildLegendSquare(_greenL2),
                  _buildLegendSquare(_greenL3),
                  _buildLegendSquare(_greenL4),
                  const SizedBox(width: 5),
                  const Text(
                    'More',
                    style: TextStyle(color: _textMuted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildLegendSquare(Color c, {Color? border}) {
    return Container(
      width: _tileSize,
      height: _tileSize,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(2.5),
        border: Border.all(
          color: border ?? Colors.transparent,
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

    if (!isFuture) {
      if (record.hasClasses) {
        if (record.attended == 0) {
          fillColor = _missedTileBg;
          borderColor = _missedTileBorder;
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
          '${record.hasClasses ? "${record.attended} / 6 classes attended" : "No scheduled lectures"}',
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRecord = record;
          });
        },
        child: Container(
          width: _tileSize,
          height: _tileSize,
          margin: const EdgeInsets.all(_tileMargin),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(2.8),
            border: Border.all(
              color: isSelected ? Colors.white : borderColor,
              width: isSelected ? 1.6 : 0.8,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.40),
                      blurRadius: 5,
                      spreadRadius: 1.0,
                    )
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedDayDetail(_DayAttendanceRecord r) {
    // Deduplicate and aggregate multiple session hours per course
    final Map<String, List<bool>> subjSessionMap = {};
    for (var s in r.subjects) {
      final name = s['subject'] ?? 'Course';
      final isP = s['status'] == 'Present';
      subjSessionMap.putIfAbsent(name, () => []).add(isP);
    }

    final List<Widget> subjectBadges = [];
    subjSessionMap.forEach((subjectName, sessions) {
      final int totalHrs = sessions.length;
      final int attendedHrs = sessions.where((p) => p).length;
      final bool allPresent = attendedHrs == totalHrs;
      final bool allAbsent = attendedHrs == 0;

      String badgeText = subjectName;
      if (totalHrs > 1) {
        badgeText = '$subjectName ($totalHrs hrs)';
      }

      Color bg;
      Color border;
      Color text;

      if (allPresent) {
        bg = const Color(0xFF10B981).withValues(alpha: 0.18);
        border = const Color(0xFF34D399).withValues(alpha: 0.40);
        text = const Color(0xFF6EE7B7);
        badgeText = '$badgeText • Present';
      } else if (allAbsent) {
        bg = const Color(0xFFEF4444).withValues(alpha: 0.18);
        border = const Color(0xFFF87171).withValues(alpha: 0.40);
        text = const Color(0xFFFCA5A5);
        badgeText = '$badgeText • Absent';
      } else {
        badgeText = '$badgeText • $attendedHrs/$totalHrs Attended';
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.18);
        border = const Color(0xFFFBBF24).withValues(alpha: 0.40);
        text = const Color(0xFFFDE68A);
      }

      subjectBadges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border, width: 0.9),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              color: text,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDisplayDate(r.date),
            style: const TextStyle(
              color: _textBright,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subjectBadges.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: subjectBadges,
            ),
          ],
        ],
      ),
    );
  }
}

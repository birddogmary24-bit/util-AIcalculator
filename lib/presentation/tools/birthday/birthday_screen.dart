import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/region.dart';
import '../../../providers/region_provider.dart';
import 'birthday_provider.dart';

class BirthdayScreen extends ConsumerStatefulWidget {
  const BirthdayScreen({super.key});

  @override
  ConsumerState<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends ConsumerState<BirthdayScreen> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(birthdayProvider);
    final region = ref.watch(regionProvider);
    final isKr = region == RegionMode.kr;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          isKr ? '생일 기억' : 'Birthday Reminder',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            onPressed: () => _showInfoDialog(isKr),
            icon: Icon(Icons.info_outline, color: cs.primary, size: 26),
            tooltip: isKr ? '알림 안내' : 'Notification Info',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.entries.isEmpty
              ? _buildEmptyState(isKr)
              : _buildList(state, isKr),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(isKr),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: const Icon(Icons.add, size: 24),
        label: Text(
          isKr ? '추가' : 'Add',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isKr) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cake_outlined,
            size: 80,
            color: cs.onSurfaceVariant.withAlpha(100),
          ),
          const SizedBox(height: 20),
          Text(
            isKr ? '등록된 생일이 없습니다' : 'No birthdays registered',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isKr
                ? '아래 추가 버튼을 눌러\n소중한 사람의 생일을 등록하세요'
                : 'Tap the Add button below\nto register a birthday',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(isKr),
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add),
            label: Text(
              isKr ? '생일 추가하기' : 'Add Birthday',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BirthdayState state, bool isKr) {
    final sorted = state.sortedEntries;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final entry = sorted[index];
        return _buildBirthdayCard(entry, isKr);
      },
    );
  }

  Widget _buildBirthdayCard(BirthdayEntry entry, bool isKr) {
    final cs = Theme.of(context).colorScheme;
    final daysUntil = entry.daysUntilNext();
    final isToday = entry.isBirthdayToday;

    // D-day display
    String ddayText;
    Color ddayColor;
    if (isToday) {
      ddayText = isKr ? '오늘!' : 'Today!';
      ddayColor = cs.error;
    } else {
      ddayText = 'D-$daysUntil';
      ddayColor = daysUntil <= 7 ? cs.error : cs.primary;
    }

    // Date display
    String dateText;
    if (isKr) {
      dateText = entry.year != null
          ? '${entry.year}년 ${entry.month}월 ${entry.day}일'
          : '${entry.month}월 ${entry.day}일';
    } else {
      final monthName = DateFormat('MMM').format(DateTime(2000, entry.month));
      dateText = entry.year != null
          ? '$monthName ${entry.day}, ${entry.year}'
          : '$monthName ${entry.day}';
    }

    // Age display
    final age = entry.currentAge;

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        ref.read(birthdayProvider.notifier).removeEntry(entry.id);
      },
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isKr ? '삭제 확인' : 'Confirm Delete'),
            content: Text(
              isKr
                  ? '${entry.name}님의 생일을 삭제하시겠습니까?'
                  : 'Delete ${entry.name}\'s birthday?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(isKr ? '취소' : 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: cs.error),
                child: Text(isKr ? '삭제' : 'Delete'),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isToday ? cs.errorContainer : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isToday
                    ? cs.error.withAlpha(25)
                    : cs.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isToday ? Icons.celebration : Icons.cake,
                color: isToday ? cs.error : cs.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Name, date, age
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateText,
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  if (age != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      isKr ? '만 $age세' : 'Age $age',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // D-day badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: ddayColor.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                ddayText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ddayColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(bool isKr) {
    final cs = Theme.of(context).colorScheme;
    final isWeb = kIsWeb;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.notifications_active, color: cs.primary, size: 28),
            const SizedBox(width: 10),
            Text(
              isKr ? '생일 알림 안내' : 'Birthday Notifications',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isKr
                    ? '생일을 등록하면 자동으로 알림이 설정됩니다.'
                    : 'Notifications are set automatically when you add a birthday.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                icon: Icons.alarm,
                color: cs.primary,
                title: isKr ? '3일 전  오후 6시' : '3 days before  6:00 PM',
                subtitle: isKr
                    ? '"OO님 생일이 3일 남았어요!"'
                    : '"Birthday is in 3 days!"',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.alarm,
                color: cs.tertiary,
                title: isKr ? '1일 전  오후 6시' : '1 day before  6:00 PM',
                subtitle: isKr
                    ? '"내일은 OO님 생일이에요!"'
                    : '"Tomorrow is their birthday!"',
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                icon: Icons.celebration,
                color: cs.error,
                title: isKr ? '당일  오전 8시' : 'On the day  8:00 AM',
                subtitle: isKr
                    ? '"오늘은 OO님 생일입니다!"'
                    : '"Today is their birthday!"',
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withAlpha(80),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.touch_app, size: 20, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isKr
                            ? '알림을 탭하면 이 페이지로 바로 이동합니다.'
                            : 'Tap a notification to jump to this page.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isWeb) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.web, size: 20, color: cs.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isKr
                              ? '웹 버전에서는 알림이 지원되지 않습니다.\n모바일 앱에서 이용해 주세요.'
                              : 'Notifications are not supported on web.\nPlease use the mobile app.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.security, size: 20, color: cs.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isKr
                              ? '알림을 받으려면 기기의 알림 권한을 허용해 주세요.'
                              : 'Please allow notification permission on your device.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isKr ? '확인' : 'OK',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAddDialog(bool isKr) async {
    final nameController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    bool includeYear = true;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final dialogCs = Theme.of(context).colorScheme;
            String dateText;
            if (isKr) {
              dateText = includeYear
                  ? DateFormat('yyyy년 M월 d일').format(selectedDate)
                  : DateFormat('M월 d일').format(selectedDate);
            } else {
              dateText = includeYear
                  ? DateFormat('MMM d, yyyy').format(selectedDate)
                  : DateFormat('MMM d').format(selectedDate);
            }

            return AlertDialog(
              title: Text(
                isKr ? '생일 추가' : 'Add Birthday',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name input
                    Text(
                      isKr ? '이름' : 'Name',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: dialogCs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        hintText: isKr ? '이름을 입력하세요' : 'Enter name',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: dialogCs.onSurfaceVariant.withAlpha(120),
                        ),
                        filled: true,
                        fillColor: dialogCs.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: dialogCs.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date picker
                    Text(
                      isKr ? '생일' : 'Birthday',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: dialogCs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(1920),
                          lastDate: DateTime.now(),
                          locale: isKr ? const Locale('ko') : const Locale('en'),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: dialogCs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month,
                              color: dialogCs.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              dateText,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: dialogCs.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Include year toggle
                    Row(
                      children: [
                        Checkbox(
                          value: includeYear,
                          onChanged: (v) {
                            setDialogState(() => includeYear = v ?? true);
                          },
                          activeColor: dialogCs.primary,
                        ),
                        Text(
                          isKr
                              ? '출생연도 포함 (나이 계산)'
                              : 'Include birth year (age calc)',
                          style: TextStyle(
                            fontSize: 14,
                            color: dialogCs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    isKr ? '취소' : 'Cancel',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    ref.read(birthdayProvider.notifier).addEntry(
                          name: name,
                          month: selectedDate.month,
                          day: selectedDate.day,
                          year: includeYear ? selectedDate.year : null,
                        );
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dialogCs.primary,
                    foregroundColor: dialogCs.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isKr ? '추가' : 'Add',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/format.dart';
import '../utils/storage.dart';

class StatisticsScreen extends StatefulWidget {
  final int currentUserId;
  const StatisticsScreen({super.key, required this.currentUserId});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  bool _isLoading = false;
  String? _selectedDate;

  List<Map<String, dynamic>> _days = [];
  String? _treasurerName;

  // 정산
  Map<String, int> _toReceive = {};
  Map<String, int> _toPay = {};
  bool _settlementLoading = false;
  int _myMonthlyTotal = 0;

  // 내 계좌
  String _currentUserName = '';
  String _accountBank = '';
  String _accountNumber = '';

  // 팀원 계좌 목록 [{name, bank, number}]
  List<Map<String, String>> _teamAccounts = [];

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadAccount();
    _loadTeamAccounts();
  }

  Future<void> _loadAccount() async {
    // 서버에서 내 dept 필드 읽어서 계좌 파싱 (로컬스토리지 fallback)
    try {
      final userData = await ApiService.getUser(widget.currentUserId);
      final dept = userData['dept'] as String? ?? '';
      final name = userData['name'] as String? ?? '';
      if (dept.contains('|')) {
        final parts = dept.split('|');
        if (mounted) {
          setState(() {
            _currentUserName = name;
            _accountBank = parts[0];
            _accountNumber = parts.length > 1 ? parts[1] : '';
          });
        }
        return;
      }
      if (mounted) setState(() => _currentUserName = name);
    } catch (_) {}
    // 서버 실패 시 localStorage fallback
    if (mounted) {
      setState(() {
        _accountBank = getLocalStorage('account_bank');
        _accountNumber = getLocalStorage('account_number');
      });
    }
  }

  Future<void> _loadTeamAccounts() async {
    try {
      final allUsers = await ApiService.listAllUsers();
      final accounts = <Map<String, String>>[];
      for (final u in allUsers) {
        final dept = u['dept'] as String? ?? '';
        final name = u['name'] as String? ?? '';
        if ((u['id'] as int) == widget.currentUserId && _currentUserName.isEmpty && name.isNotEmpty) {
          if (mounted) setState(() => _currentUserName = name);
        }
        if (dept.contains('|')) {
          final parts = dept.split('|');
          accounts.add({
            'name': name,
            'bank': parts[0],
            'number': parts.length > 1 ? parts[1] : '',
          });
        }
      }
      if (mounted) setState(() => _teamAccounts = accounts);
    } catch (_) {}
  }

  void _copySettlementMessage() {
    final lastDay = DateTime(_year, _month + 1, 0).day;
    final buf = StringBuffer();
    buf.writeln('[점심 정산 안내] $_month월');
    if (_accountBank.isNotEmpty || _accountNumber.isNotEmpty) {
      buf.writeln('계좌: $_accountBank $_accountNumber');
    }
    buf.writeln('정산일: $_month월 $lastDay일');
    buf.writeln();
    for (final e in _toReceive.entries) {
      buf.writeln('${e.key}  ${formatPrice(e.value)}원');
    }
    Clipboard.setData(ClipboardData(text: buf.toString().trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('정산 메시지가 복사되었습니다'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _editAccount() async {
    final bankCtrl = TextEditingController(text: _accountBank);
    final numCtrl = TextEditingController(text: _accountNumber);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('내 계좌번호'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bankCtrl,
              decoration: const InputDecoration(hintText: '은행명 (예: 국민은행)'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: numCtrl,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(hintText: '계좌번호 (예: 123-456-789012)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('저장', style: TextStyle(color: Color(0xFFFF6B35))),
          ),
        ],
      ),
    );
    if (result != true || !mounted) return;
    final bank = bankCtrl.text.trim();
    final number = numCtrl.text.trim();
    // 로컬 저장 (fallback)
    setLocalStorage('account_bank', bank);
    setLocalStorage('account_number', number);
    // 서버 저장 (dept 필드에 "은행|계좌번호" 형식)
    bool serverSaveOk = false;
    try {
      await ApiService.updateUserDept(widget.currentUserId, '$bank|$number');
      serverSaveOk = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('서버 저장 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
    if (!mounted) return;
    if (serverSaveOk) {
      setState(() {
        _accountBank = bank;
        _accountNumber = number;
        _teamAccounts.removeWhere((a) => a['name'] == _currentUserName);
        if (_currentUserName.isNotEmpty && (bank.isNotEmpty || number.isNotEmpty)) {
          _teamAccounts.add({'name': _currentUserName, 'bank': bank, 'number': number});
        }
      });
      _loadTeamAccounts();
    } else {
      setState(() {
        _accountBank = bank;
        _accountNumber = number;
      });
    }
  }

  Future<void> _loadSettlement() async {
    if (mounted) setState(() => _settlementLoading = true);
    try {
      // 전체 사용자 이름 맵 (user_id → name)
      final allUsers = await ApiService.listAllUsers();
      final userMap = { for (final u in allUsers) u['id'] as int: u['name'] as String };
      final myName = userMap[widget.currentUserId] ?? '';

      // _days에서 내가 참여한 날짜 추출 + 월 총 지출 계산
      int monthlyTotal = 0;
      final myDates = <String>[];
      for (final day in _days) {
        final users = (day['users'] as List).cast<Map<String, dynamic>>();
        for (final u in users) {
          if (u['user_name'] == myName) {
            myDates.add(day['date'] as String);
            monthlyTotal += u['amount'] as int;
            break;
          }
        }
      }
      if (mounted) setState(() => _myMonthlyTotal = monthlyTotal);

      final Map<String, int> toReceive = {};
      final Map<String, int> toPay = {};

      // 참여한 날짜별로만 selections 조회 → memo로 총무 판별
      for (final dateStr in myDates) {
        final selections = await ApiService.listSelectionsByDate(dateStr);

        Map<String, dynamic>? treasurerSel;
        try {
          treasurerSel = selections.firstWhere((s) => s['memo'] == 'treasurer');
        } catch (_) {}
        if (treasurerSel == null) continue;

        final treasurerId = treasurerSel['user_id'] as int;
        final treasurerName = userMap[treasurerId] ?? '알수없음';

        if (treasurerId == widget.currentUserId) {
          // 내가 총무 → 다른 멤버들에게 받아야 할 금액
          for (final sel in selections) {
            if (sel['user_id'] == widget.currentUserId) continue;
            final memberName = userMap[sel['user_id'] as int] ?? '알수없음';
            toReceive[memberName] = (toReceive[memberName] ?? 0) + (sel['price'] as int);
          }
        } else {
          // 다른 사람이 총무 → 내 금액만큼 줘야 함
          try {
            final mySel = selections.firstWhere((s) => s['user_id'] == widget.currentUserId);
            toPay[treasurerName] = (toPay[treasurerName] ?? 0) + (mySel['price'] as int);
          } catch (_) {}
        }
      }

      if (mounted) setState(() {
        _toReceive = toReceive;
        _toPay = toPay;
        _settlementLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _settlementLoading = false);
    }
  }

  Future<void> _loadDayDetail(String dateKey) async {
    if (mounted) setState(() => _treasurerName = null);
    try {
      final selections = await ApiService.listSelectionsByDate(dateKey);
      final treasurerSel = selections.cast<Map<String, dynamic>?>().firstWhere(
        (s) => s?['memo'] == 'treasurer',
        orElse: () => null,
      );
      if (treasurerSel != null && mounted) {
        final userId = treasurerSel['user_id'] as int;
        final userData = await ApiService.getUser(userId);
        if (mounted) setState(() => _treasurerName = userData['name'] as String);
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    if (mounted) setState(() {
      _isLoading = true;
      _selectedDate = null;
      _treasurerName = null;
      _toReceive = {};
      _toPay = {};
    });
    try {
      final stats = await ApiService.getMonthlyStats(_year, _month);
      if (mounted) {
        setState(() {
          _days = (stats['days'] as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      }
      _loadSettlement(); // 백그라운드에서 정산 계산
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _prevMonth() {
    setState(() {
      _month == 1 ? (_month = 12, _year--) : _month--;
    });
    _loadData();
  }

  void _nextMonth() {
    final now = DateTime.now();
    if (_year == now.year && _month == now.month) return;
    setState(() {
      _month == 12 ? (_month = 1, _year++) : _month++;
    });
    _loadData();
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _year == now.year && _month == now.month;
  }

  Map<String, Map<String, dynamic>> get _byDateMap {
    return { for (final day in _days) day['date'] as String: day };
  }

  String _dateKey(int day) {
    final m = _month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$_year-$m-$d';
  }

  String _formatDateLabel(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    return '${parts[1]}/${parts[2]} (${_weekdayLabels[dt.weekday - 1]})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '이용 내역',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
      ),
      body: Column(
        children: [
          _buildMonthPicker(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
                : _buildCalendarTab(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _editAccount,
        backgroundColor: const Color(0xFFFF6B35),
        icon: const Icon(Icons.account_balance_outlined, color: Colors.white, size: 18),
        label: Text(
          _accountNumber.isEmpty ? '계좌 등록' : '계좌 수정',
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildMonthPicker() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF1A1A1A)),
            onPressed: _prevMonth,
          ),
          SizedBox(
            width: 130,
            child: Text(
              '$_year년 ${_month.toString().padLeft(2, '0')}월',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: _isCurrentMonth ? Colors.grey[300] : const Color(0xFF1A1A1A),
            ),
            onPressed: _isCurrentMonth ? null : _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettlementCard(),
        const SizedBox(height: 12),
        _buildTeamAccountsCard(),
        const SizedBox(height: 12),
        _buildCalendarGrid(),
        if (_selectedDate != null) ...[
          const SizedBox(height: 12),
          _buildDayDetail(_selectedDate!),
        ],
      ],
    );
  }

  Widget _buildTeamAccountsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_outlined, size: 16, color: Color(0xFFFF6B35)),
                SizedBox(width: 6),
                Text('팀원 계좌',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            if (_teamAccounts.isEmpty)
              Text(
                '아직 등록된 계좌가 없어요.\n아래 "계좌 등록" 버튼을 눌러 내 계좌를 등록하면 팀원들에게 공개됩니다.',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              )
            else
              ..._teamAccounts.map((acc) {
                final display = '${acc['bank']} ${acc['number']}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(acc['name']!,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            Text(display,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: display));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${acc['name']} 계좌가 복사되었습니다'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDE5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy, size: 12, color: Color(0xFFFF6B35)),
                              SizedBox(width: 4),
                              Text('복사',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFFF6B35),
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSettlementCard() {
    final lastDay = DateTime(_year, _month + 1, 0).day;
    final hasData = _toReceive.isNotEmpty || _toPay.isNotEmpty;

    if (_settlementLoading) {
      return const Card(
        elevation: 0,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35), strokeWidth: 2)),
        ),
      );
    }

    if (!hasData) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 16, color: Color(0xFFFF6B35)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('이번달 정산',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              Text('정산일: $_month월 $lastDay일',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 16, color: Color(0xFFFF6B35)),
                const SizedBox(width: 6),
                const Text('이번달 정산',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_myMonthlyTotal > 0) ...[
                  Text('내 지출 ',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  Text('${formatPrice(_myMonthlyTotal)}원',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                  const SizedBox(width: 8),
                ],
                if (_toReceive.isNotEmpty)
                  GestureDetector(
                    onTap: _copySettlementMessage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDE5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy, size: 12, color: Color(0xFFFF6B35)),
                          SizedBox(width: 4),
                          Text('메시지 복사', style: TextStyle(fontSize: 12, color: Color(0xFFFF6B35), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text('정산일: $_month월 $lastDay일',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            if (_toReceive.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('받을 금액', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                  if (_accountNumber.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: '$_accountBank $_accountNumber'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('계좌번호가 복사되었습니다'), duration: Duration(seconds: 1)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDE5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy, size: 11, color: Color(0xFFFF6B35)),
                            const SizedBox(width: 4),
                            Text('$_accountBank $_accountNumber',
                                style: const TextStyle(fontSize: 11, color: Color(0xFFFF6B35), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              ..._toReceive.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_downward, size: 13, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13))),
                    Text('${formatPrice(e.value)}원',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              )),
            ],
            if (_toPay.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('줄 금액', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ..._toPay.entries.map((e) {
                final acc = _teamAccounts.cast<Map<String, String>?>().firstWhere(
                  (a) => a?['name'] == e.key,
                  orElse: () => null,
                );
                final accDisplay = acc != null ? '${acc['bank']} ${acc['number']}' : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward, size: 13, color: Colors.red),
                          const SizedBox(width: 6),
                          Expanded(child: Text('${e.key} (총무)', style: const TextStyle(fontSize: 13))),
                          Text('${formatPrice(e.value)}원',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                      if (accDisplay != null) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: accDisplay));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${e.key} 계좌가 복사되었습니다'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 19),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy, size: 11, color: Colors.red[300]),
                                const SizedBox(width: 4),
                                Text(accDisplay,
                                    style: TextStyle(fontSize: 11, color: Colors.red[400], fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.only(left: 19),
                          child: Text('계좌 미등록', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final byDate = _byDateMap;
    final firstDay = DateTime(_year, _month, 1);
    final daysInMonth = DateTime(_year, _month + 1, 0).day;
    final startOffset = firstDay.weekday - 1;
    final today = DateTime.now();
    final isThisMonth = today.year == _year && today.month == _month;
    const cellHeight = 66.0;
    final totalRows = ((startOffset + daysInMonth) / 7).ceil();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: _weekdayLabels.map((d) {
                final isSat = d == '토';
                final isSun = d == '일';
                return Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSun ? Colors.red[300] : isSat ? Colors.blue[300] : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            ...List.generate(totalRows, (row) {
              return Row(
                children: List.generate(7, (col) {
                  final day = row * 7 + col - startOffset + 1;
                  if (day < 1 || day > daysInMonth) {
                    return const Expanded(child: SizedBox(height: cellHeight));
                  }

                  final dateKey = _dateKey(day);
                  final dayData = byDate[dateKey];
                  final hasData = dayData != null;
                  final isSelected = _selectedDate == dateKey;
                  final isToday = isThisMonth && today.day == day;
                  final isSun = col == 6;
                  final isSat = col == 5;

                  return Expanded(
                    child: GestureDetector(
                      onTap: hasData
                          ? () {
                              final next = isSelected ? null : dateKey;
                              setState(() { _selectedDate = next; _treasurerName = null; });
                              if (next != null) _loadDayDetail(next);
                            }
                          : null,
                      child: SizedBox(
                        height: cellHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFF6B35)
                                    : isToday
                                        ? const Color(0xFFFFEDE5)
                                        : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: hasData || isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : isSun
                                            ? Colors.red[300]
                                            : isSat
                                                ? Colors.blue[300]
                                                : hasData
                                                    ? const Color(0xFF1A1A1A)
                                                    : Colors.grey[400],
                                  ),
                                ),
                              ),
                            ),
                            if (hasData) ...[
                              const SizedBox(height: 3),
                              Text(
                                formatPrice(dayData['total_amount'] as int),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isSelected
                                      ? const Color(0xFFFF6B35)
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${(dayData['users'] as List).length}명',
                                style: TextStyle(fontSize: 9, color: Colors.grey[400]),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetail(String dateKey) {
    final dayData = _byDateMap[dateKey];
    if (dayData == null) return const SizedBox.shrink();
    final label = _formatDateLabel(dateKey);
    final users = (dayData['users'] as List).cast<Map<String, dynamic>>();

    final Map<String, List<Map<String, dynamic>>> byRestaurant = {};
    for (final user in users) {
      byRestaurant.putIfAbsent(user['restaurant_name'] as String, () => []).add(user);
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                if (_treasurerName != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          size: 14, color: Color(0xFFFF6B35)),
                      const SizedBox(width: 4),
                      Text(
                        '총무: $_treasurerName',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...byRestaurant.entries.map((entry) {
              final restaurantName = entry.key;
              final members = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.restaurant, size: 14, color: Color(0xFFFF6B35)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            restaurantName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...members.map((user) {
                      final name = user['user_name'] as String;
                      final menuName = user['menu_name'] as String;
                      final amount = user['amount'] as int;
                      return Padding(
                        padding: const EdgeInsets.only(left: 20, bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 13, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                  Text(menuName,
                                      style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                                ],
                              ),
                            ),
                            Text('${formatPrice(amount)}원',
                                style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 16),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

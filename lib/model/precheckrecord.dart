import 'package:farmflow/model/precheck_item.dart';
import 'package:uuid/uuid.dart';

class PreCheckRecord {
  final String id;
  final String machineId;
  final DateTime checkDate;
  final Map<String, CheckStatus> result;
  final int? totalHoursAtCheck;

  final String? operatorName;

  PreCheckRecord({
    String? id,
    required this.machineId,
    required this.checkDate,
    required this.result,
    this.totalHoursAtCheck,
    this.operatorName,
  }) : id = id ?? Uuid().v4();

  factory PreCheckRecord.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final machineId = (json['machine_id'] ?? json['machineId']) as String;
    final checkDateRaw = (json['check_date'] ?? json['checkDate']);
    final checkDate =
        checkDateRaw is String
            ? DateTime.parse(checkDateRaw)
            : checkDateRaw as DateTime;

    final resultRaw = json['result'] as Map<String, dynamic>;
    final result = resultRaw.map((key, value) {
      final statusStr = value as String;
      final status = CheckStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => CheckStatus.notChecked,
      );
      return MapEntry(key, status);
    });

    final totalHoursAtCheck =
        (json['total_hours_at_check'] ?? json['totalHoursAtCheck']) as int?;
    final operatorName =
        (json['operator_name'] ?? json['operatorName']) as String?;

    return PreCheckRecord(
      id: id,
      machineId: machineId,
      checkDate: checkDate,
      result: result,
      totalHoursAtCheck: totalHoursAtCheck,
      operatorName: operatorName,
    );
  }
}

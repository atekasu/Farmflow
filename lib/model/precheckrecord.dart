import 'package:farmflow/model/precheck_item.dart';
import 'package:uuid/uuid.dart';

class PreCheckRecord {
  final String id;
  final String machineId;
  final DateTime checkDate;
  final Map<String, CheckStatus> result;
  final int? totalHoursAtCheck;

  //将来の拡張用
  final String? operatorName;

  PreCheckRecord({
    String? id,
    required this.machineId,
    required this.checkDate,
    required this.result,
    this.totalHoursAtCheck,
    this.operatorName,
  }) : id = id ?? Uuid().v4();
}

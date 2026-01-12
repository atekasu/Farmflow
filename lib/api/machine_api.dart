import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:farmflow/model/machine.dart';

class MachineApi {
  MachineApi({this.baseUrl = 'http://127.0.0.1:8000'});

  final String baseUrl;

  Future<List<Machine>> fetchMachines() async {
    final url = Uri.parse('$baseUrl/machines');

    try {
      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('機械一覧の取得がタイムアウトしました。');
            },
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map((e) => Machine.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to fetch machines: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  Future<Machine> fetchMachineById(String id) async {
    final url = Uri.parse('$baseUrl/machines/$id');

    try {
      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('機械情報の取得がタイムアウトしました。');
            },
          );

      if (response.statusCode != 200) {
        throw Exception('Failed:${response.statusCode}');
      }

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return Machine.fromJson(data);
    } catch (e) {
      throw Exception('API Error:$e');
    }
  }

  Future<Map<String, dynamic>> recordMaintenance({
    required String machineId,
    required String itemId,
    required int currentHour,
  }) async {
    final url = Uri.parse('$baseUrl/machines/$machineId/maintenance');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'item_id': itemId, 'current_hour': currentHour}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('メンテナンス記録の送信がタイムアウトしました。');
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      throw Exception(
        'Failed to record maintenance: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }
}

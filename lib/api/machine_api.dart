import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:farmflow/model/machine.dart';

///FastAPI バックエンドと通信するAPIクライアント
class MachineApi {
  MachineApi({this.baseUrl = 'http://127.0.0.1:8000'});

  final String baseUrl;

  ///機会一覧を取得
  Future<List<Machine>> fetchMachines() async {
    final url = Uri.parse('$baseUrl/machines');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Machine.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch machines:${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Error:$e');
    }
  }

  ///特定の機械の取得
  Future<Machine> fetchMachineById(String id) async {
    final url = Uri.parse('$baseUrl/machines/$id');

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed:${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      return Machine.fromJson(data);
    } catch (e) {
      throw Exception('API Error:$e');
    }
  }
}

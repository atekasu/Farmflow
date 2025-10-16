import 'package:farmflow/application/precheck_reset_notifire.dart';
import 'package:flutter/material.dart';
import 'screen/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FarmFlow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomeScreen(),
    );
  }
}

///起動直後に一度だけ resetIfNewDate() を実行する薄いブートスラップ
class _Bootstrap extends ConsumerStatefulWidget {
  const _Bootstrap({Key? key, required this.child}) : super(key: key);
  final Widget child;

  @override
  ConsumerState<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends ConsumerState<_Bootstrap> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    //初回のフレーム後に実行（Buildをブロックしない）
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(precheckResetterProvider).resetIfNewDate();
        debugPrint('☑︎ PreCheck 日跨ぎクリア完了');
      } catch (e) {
        debugPrint('⚠️ PreCheck 日跨ぎクリア失敗: $e');
      } finally {
        if (mounted) setState(() => _done = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ここでローディング表示を挟みたければ挟める
    return widget.child;
  }
}

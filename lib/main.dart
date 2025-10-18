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
      home: const _Bootstrap(child: HomeScreen()),
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

class _BootstrapState extends ConsumerState<_Bootstrap> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    // ライフサイクル監視を登録
    WidgetsBinding.instance.addObserver(this);
    // 初回フレーム後に一度だけチェック（描画をブロックしない）
    WidgetsBinding.instance.addPostFrameCallback((_) => _resetIfNeeded());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetIfNeeded();
    }
  }

  Future<void> _resetIfNeeded() async {
    try {
      await ref.read(precheckResetterProvider).resetIfNewDate();
      debugPrint('✓ PreCheck 日跨ぎクリア完了（resume/boot）');
    } catch (e) {
      debugPrint('⚠ PreCheck 日跨ぎクリア失敗: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ここでローディングを挟みたければ挟める
    return widget.child;
  }
}

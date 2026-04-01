import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/bill_provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(const FairSplitterApp());
}

class FairSplitterApp extends StatelessWidget {
  const FairSplitterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BillProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Fair Splitter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const RegisterScreen(),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/bill_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/debt_provider.dart';
import 'providers/group_provider.dart';
import 'providers/notification_provider.dart';
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
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (ctx) => ChatProvider(ctx.read<AuthProvider>().api),
          update: (ctx, auth, prev) => prev ?? ChatProvider(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, DebtProvider>(
          create: (ctx) => DebtProvider(ctx.read<AuthProvider>().api),
          update: (ctx, auth, prev) => prev ?? DebtProvider(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, GroupProvider>(
          create: (ctx) => GroupProvider(ctx.read<AuthProvider>().api),
          update: (ctx, auth, prev) => prev ?? GroupProvider(auth.api),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (ctx) => NotificationProvider(ctx.read<AuthProvider>().api),
          update: (ctx, auth, prev) => prev ?? NotificationProvider(auth.api),
        ),
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

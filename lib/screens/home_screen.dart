import 'package:flutter/material.dart';
import '../widgets/otp_card.dart';
import '../models/otp_account.dart';
import '../services/otp_service.dart';
import '../services/storage_service.dart';
import 'add_account_screen.dart';
import 'dart:math';
import 'edit_account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<OTPAccount> _accounts = [];
  List<String> _pinnedAccountNames = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await StorageService.loadAccounts();
    final pinnedAccountNames = await StorageService.loadPinnedAccounts();
    setState(() {
      _accounts = accounts;
      _pinnedAccountNames = pinnedAccountNames;
      _sortAccounts();
    });
  }

  void _sortAccounts() {
    _accounts.sort((a, b) {
      final isPinnedA = _pinnedAccountNames.contains(a.name);
      final isPinnedB = _pinnedAccountNames.contains(b.name);
      if (isPinnedA && !isPinnedB) return -1;
      if (!isPinnedA && isPinnedB) return 1;
      return a.name.compareTo(b.name);
    });
  }

  Future<void> _saveAccounts() async {
    await StorageService.saveAccounts(_accounts);
    await StorageService.savePinnedAccounts(_pinnedAccountNames);
  }

  void _addRandomAccount() {
    final random = Random();
    final randomIssuers = [
      'Google',
      'GitHub',
      'Facebook',
      'Twitter',
      'Amazon',
      'Microsoft',
      'Apple'
    ];
    final randomIssuer = randomIssuers[random.nextInt(randomIssuers.length)];

    setState(() {
      _accounts.add(OTPAccount(
        name: "Account ${_accounts.length + 1}",
        secret: OTPService.generateRandomSecret(),
        issuer: randomIssuer,
      ));
    });
    _saveAccounts();
  }

  void _deleteAccount(OTPAccount account) {
    setState(() {
      _accounts.removeWhere((a) => a.name == account.name);
      _pinnedAccountNames.remove(account.name);
    });
    _saveAccounts();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${account.name} has been deleted')),
    );
  }

  void _editAccount(OTPAccount account) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAccountScreen(account: account),
      ),
    );

    if (result != null && result is OTPAccount) {
      setState(() {
        final index = _accounts.indexWhere(
            (a) => a.name == account.name && a.secret == account.secret);
        if (index != -1) {
          _accounts[index] = result;
          _sortAccounts();
        }
      });
      _saveAccounts();
    }
  }

  void _pinAccount(OTPAccount account) {
    setState(() {
      if (_pinnedAccountNames.contains(account.name)) {
        _pinnedAccountNames.remove(account.name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${account.name} has been unpinned')),
        );
      } else {
        _pinnedAccountNames.add(account.name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${account.name} has been pinned')),
        );
      }
      _sortAccounts();
    });
    _saveAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2FA Authenticator'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton.filled(
              icon: const Icon(Icons.shuffle, size: 28),
              onPressed: _addRandomAccount,
              tooltip: 'Add Random Account',
              style: IconButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton.filled(
              icon: const Icon(Icons.add, size: 28),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddAccountScreen()),
                );
                if (result != null && result is OTPAccount) {
                  setState(() {
                    _accounts.add(result);
                  });
                  _saveAccounts();
                }
              },
              tooltip: 'Add Account Manually',
              style: IconButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _accounts.length,
        itemBuilder: (context, index) {
          return OTPCard(
            account: _accounts[index],
            onDelete: _deleteAccount,
            onEdit: _editAccount,
            onPin: _pinAccount,
            isPinned: _pinnedAccountNames.contains(_accounts[index].name),
          );
        },
      ),
    );
  }
}

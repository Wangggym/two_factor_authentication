import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/otp_account.dart';

class EditAccountScreen extends StatefulWidget {
  final OTPAccount account;

  const EditAccountScreen({super.key, required this.account});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  late TextEditingController _nameController;
  late TextEditingController _issuerController;
  late String _keyUri;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account.name);
    _issuerController = TextEditingController(text: widget.account.issuer);
    _keyUri = _generateKeyUri();
  }

  String _generateKeyUri() {
    return 'otpauth://totp/${widget.account.issuer}:${widget.account.name}?secret=${widget.account.secret}&issuer=${widget.account.issuer}&period=30&digits=6&algorithm=SHA1';
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Account'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final updatedAccount = OTPAccount(
                  name: _nameController.text,
                  secret: widget.account.secret,
                  issuer: _issuerController.text,
                );
                Navigator.pop(context, updatedAccount);
              }
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          children: [
            // First Card - Editable Fields
            Card(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabelText('Issuer'),
                    TextField(
                      controller: _issuerController,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(),
                    _buildLabelText('Account Name'),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(),
                    _buildLabelText('Secret Key'),
                    _buildReadOnlyField(widget.account.secret),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(5),
              child: Text(
                'NOTE: Changes would not apply to the Key URI',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            // Second Card - Key URI
            Card(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabelText('Key URI'),
                    _buildReadOnlyField(_keyUri),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Third Card - QR Code
            Card(
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Center(
                  child: QrImageView(
                    data: _keyUri,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelText(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildReadOnlyField(String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              height: 2,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20),
          onPressed: () => _copyToClipboard(
            value,
            'Copied to clipboard',
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

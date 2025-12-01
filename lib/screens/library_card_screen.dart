import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import 'dart:convert';

class LibraryCardScreen extends StatefulWidget {
  const LibraryCardScreen({super.key});

  @override
  State<LibraryCardScreen> createState() => _LibraryCardScreenState();
}

class _LibraryCardScreenState extends State<LibraryCardScreen> {
  final UserService _userService = UserService();
  LibraryCard? _card;
  bool _isLoading = true;
  bool _showQR = true; // Toggle between QR and barcode

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  Future<void> _loadCard() async {
    setState(() => _isLoading = true);
    _card = await _userService.getLibraryCard();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Card'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _card == null
              ? const Center(child: Text('Failed to load card'))
              : _buildCard(),
    );
  }

  Widget _buildCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Card Display
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primaryContainer,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AL-BURHAAN',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                            ),
                            Text(
                              'LIBRARY',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white70,
                                    letterSpacing: 4,
                                  ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _card!.isExpired ? Colors.red : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _card!.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Name
                    Text(
                      _card!.fullName.toUpperCase(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),

                    // Card Number
                    Text(
                      _card!.cardNumber,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            letterSpacing: 2,
                            fontFamily: 'monospace',
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Expiry
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXPIRES',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              _card!.dateExpiry ?? 'N/A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (_card!.daysUntilExpiry != null)
                          Text(
                            _card!.daysUntilExpiry! > 0
                                ? '${_card!.daysUntilExpiry} days left'
                                : 'Expired',
                            style: TextStyle(
                              color: _card!.daysUntilExpiry! < 30
                                  ? Colors.yellow
                                  : Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // QR/Barcode Toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('QR Code'),
                icon: Icon(Icons.qr_code),
              ),
              ButtonSegment(
                value: false,
                label: Text('Barcode'),
                icon: Icon(Icons.view_week),
              ),
            ],
            selected: {_showQR},
            onSelectionChanged: (selection) {
              setState(() => _showQR = selection.first);
            },
          ),
          const SizedBox(height: 24),

          // QR Code or Barcode
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_showQR && _card!.qrCode != null)
                    _buildImage(_card!.qrCode!, 200)
                  else if (!_showQR && _card!.barcode != null)
                    _buildImage(_card!.barcode!, 100)
                  else
                    Container(
                      width: 200,
                      height: _showQR ? 200 : 100,
                      color: Colors.grey[200],
                      child: const Center(
                        child: Text('Code not available'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Scan this code at the library',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Instructions
          Card(
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 8),
                      Text(
                        'How to use',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Show this screen to the librarian\n'
                    '2. They will scan the code to identify you\n'
                    '3. You can borrow or return books',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String base64Data, double height) {
    try {
      // Remove data URI prefix if present
      String data = base64Data;
      if (data.contains(',')) {
        data = data.split(',').last;
      }

      return Image.memory(
        base64Decode(data),
        height: height,
        fit: BoxFit.contain,
      );
    } catch (e) {
      return Container(
        height: height,
        color: Colors.grey[200],
        child: const Center(child: Text('Failed to load code')),
      );
    }
  }
}

import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as scanner;

import '../app_controller.dart';
import '../cloud/cloud_controller.dart';
import '../cloud/cloud_models.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';
import 'home_screen.dart';

class DepositVouchersTab extends StatelessWidget {
  const DepositVouchersTab({
    super.key,
    required this.controller,
    required this.cloudController,
  });

  final AppController controller;
  final CloudController cloudController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vouchers = [
      ...controller.depositVouchers.map(_DepositVoucherEntry.local),
      ...cloudController.sharedVouchers.map(_DepositVoucherEntry.shared),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.depositTab,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openDepositEditor(context),
                icon: const Icon(Icons.add),
                label: Text(l10n.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: vouchers.isEmpty
                ? Center(child: Text(l10n.emptyDepositVouchers))
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 170),
                    itemCount: vouchers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = vouchers[index];
                      final voucher = entry.voucher;

                      return Card(
                        child: ListTile(
                          leading: entry.sharedVoucher == null
                              ? null
                              : const Icon(Icons.groups_2_outlined),
                          title: Text(
                            voucher.code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              _formatAmount(voucher.amount),
                              voucher.storeName,
                              if (entry.sharedVoucher != null)
                                entry.sharedVoucher!.groupName,
                              if (voucher.validUntil != null)
                                '${l10n.validUntilLabel}: ${_formatDate(voucher.validUntil!)}',
                            ].join(' • '),
                          ),
                          onTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (_) => _DepositPreviewDialog(
                                voucher: voucher,
                                onUsed: () => _useVoucher(context, entry),
                              ),
                            );
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              switch (value) {
                                case 'used':
                                  await _useVoucher(context, entry);
                                  break;
                                case 'delete':
                                  await _deleteVoucher(context, entry);
                                  break;
                              }
                            },
                            itemBuilder: (menuContext) => [
                              PopupMenuItem<String>(
                                value: 'used',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(l10n.used),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Theme.of(
                                        menuContext,
                                      ).colorScheme.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.delete,
                                      style: TextStyle(
                                        color: Theme.of(
                                          menuContext,
                                        ).colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVoucher(
    BuildContext context,
    _DepositVoucherEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context);
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.deleteDepositVoucher),
            content: Text(entry.voucher.code),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.delete),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    if (entry.sharedVoucher != null) {
      await cloudController.hideSharedVoucher(entry.voucher.id);
    } else {
      await controller.deleteDepositVoucher(entry.voucher.id);
    }
  }

  Future<bool> _useVoucher(
    BuildContext context,
    _DepositVoucherEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context);
    final shouldUse =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.used),
            content: Text(
              entry.sharedVoucher == null
                  ? entry.voucher.code
                  : l10n.useSharedDepositVoucherDescription,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(l10n.used),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldUse) {
      return false;
    }

    if (entry.sharedVoucher != null) {
      return cloudController.useSharedVoucher(entry.voucher.id);
    }
    await controller.deleteDepositVoucher(entry.voucher.id);
    return true;
  }

  Future<void> _openDepositEditor(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DepositVoucherEditorScreen(controller: controller),
      ),
    );

    if (saved == true && context.mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.depositVoucherSaved)));
    }
  }
}

class _DepositVoucherEntry {
  const _DepositVoucherEntry._({
    required this.voucher,
    required this.sharedVoucher,
  });

  factory _DepositVoucherEntry.local(DepositVoucher voucher) {
    return _DepositVoucherEntry._(voucher: voucher, sharedVoucher: null);
  }

  factory _DepositVoucherEntry.shared(SharedDepositVoucher voucher) {
    return _DepositVoucherEntry._(
      voucher: voucher.toDepositVoucher(),
      sharedVoucher: voucher,
    );
  }

  final DepositVoucher voucher;
  final SharedDepositVoucher? sharedVoucher;
}

class DepositVoucherEditorScreen extends StatefulWidget {
  const DepositVoucherEditorScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<DepositVoucherEditorScreen> createState() =>
      _DepositVoucherEditorScreenState();
}

class _DepositVoucherEditorScreenState
    extends State<DepositVoucherEditorScreen> {
  final TextEditingController _amountController = TextEditingController();
  ScannedDepositCode? _scannedCode;
  DateTime? _scannedAt;
  String? _selectedStoreName;
  DateTime? _validUntil;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scannedCode = _scannedCode;
    final canSave =
        scannedCode != null &&
        _parseAmount() != null &&
        (_selectedStoreName?.trim().isNotEmpty ?? false) &&
        _validUntil != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addDepositVoucher)),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissKeyboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: _scanCode,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: Text(l10n.scanCode),
                    ),
                    const SizedBox(height: 16),
                    if (scannedCode == null)
                      Text(
                        l10n.scanDepositCodeHint,
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    else ...[
                      _VirtualCodePreview(
                        code: scannedCode.code,
                        format: scannedCode.format,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.scannedCodeLabel,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      SelectableText(scannedCode.code),
                      if (_scannedAt != null)
                        Text(
                          '${l10n.scannedAtLabel}: ${_formatDateTime(_scannedAt!)}',
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.depositAmountLabel,
                        prefixIcon: const Icon(Icons.payments_outlined),
                      ),
                      onTapOutside: (_) => _dismissKeyboard(),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickStore,
                      icon: const Icon(Icons.storefront_outlined),
                      label: Text(
                        _selectedStoreName == null
                            ? l10n.storeLabel
                            : '${l10n.storeLabel}: $_selectedStoreName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _pickValidUntil,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        _validUntil == null
                            ? l10n.validUntilLabel
                            : '${l10n.validUntilLabel}: ${_formatDate(_validUntil!)}',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: canSave ? _save : null,
            icon: const Icon(Icons.save_outlined),
            label: Text(l10n.save),
          ),
        ),
      ),
    );
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _scanCode() async {
    final result = await Navigator.of(context).push<ScannedDepositCode>(
      MaterialPageRoute(builder: (_) => const DepositCodeScannerScreen()),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _scannedCode = result;
      _scannedAt = DateTime.now();
    });
  }

  Future<void> _pickStore() async {
    final l10n = AppLocalizations.of(context);

    final selection = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final stores = [...widget.controller.marketLayouts]
              ..sort(
                (left, right) => normalizeLatinText(
                  left.name,
                ).compareTo(normalizeLatinText(right.name)),
              );

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: Text(l10n.addStoreName),
                    onTap: () => Navigator.pop(sheetContext, _addStoreSentinel),
                  ),
                  if (stores.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.emptyMarketLayouts),
                    ),
                  if (stores.isNotEmpty)
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: stores.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final store = stores[index];

                          return ListTile(
                            leading: const Icon(Icons.storefront_outlined),
                            title: Text(store.name),
                            onTap: () =>
                                Navigator.pop(sheetContext, store.name),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || selection == null) {
      return;
    }

    if (selection == _addStoreSentinel) {
      final storeName = await _promptAndCreateStore();
      if (!mounted || storeName == null) {
        return;
      }

      setState(() {
        _selectedStoreName = storeName;
      });
      return;
    }

    setState(() {
      _selectedStoreName = selection;
    });
  }

  Future<String?> _promptAndCreateStore() async {
    final l10n = AppLocalizations.of(context);
    final name = await showNamePrompt(
      context: context,
      title: l10n.addStoreName,
      label: l10n.storeNameLabel,
    );
    if (name == null) {
      return null;
    }

    final cleanedName = name.trim();
    if (cleanedName.isEmpty) {
      return null;
    }

    for (final store in widget.controller.marketLayouts) {
      if (sameNormalizedText(store.name, cleanedName)) {
        return store.name;
      }
    }

    await widget.controller.upsertMarketLayout(
      MarketLayout(id: createId(), name: cleanedName, categoryOrder: const []),
    );

    return cleanedName;
  }

  Future<void> _save() async {
    final scannedCode = _scannedCode;
    final amount = _parseAmount();
    final storeName = _selectedStoreName?.trim();
    if (scannedCode == null ||
        amount == null ||
        storeName == null ||
        storeName.isEmpty ||
        _validUntil == null) {
      return;
    }

    await widget.controller.addDepositVoucher(
      code: scannedCode.code,
      format: scannedCode.format,
      amount: amount,
      storeName: storeName,
      validUntil: _validUntil,
      scannedAt: _scannedAt,
    );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  double? _parseAmount() {
    final normalized = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(normalized);
    if (amount == null || amount < 0) {
      return null;
    }
    return amount;
  }

  Future<void> _pickValidUntil() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _validUntil = selectedDate;
    });
  }
}

class DepositCodeScannerScreen extends StatefulWidget {
  const DepositCodeScannerScreen({super.key});

  @override
  State<DepositCodeScannerScreen> createState() =>
      _DepositCodeScannerScreenState();
}

class _DepositCodeScannerScreenState extends State<DepositCodeScannerScreen> {
  bool _didScan = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scanCode)),
      body: Stack(
        children: [
          scanner.MobileScanner(
            onDetect: _handleDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.cameraPermissionRequired,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  l10n.scanDepositCodeInstruction,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDetect(scanner.BarcodeCapture capture) {
    if (_didScan) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue?.trim();
      if (rawValue == null || rawValue.isEmpty) {
        continue;
      }

      _didScan = true;
      Navigator.of(
        context,
      ).pop(ScannedDepositCode(code: rawValue, format: barcode.format.name));
      return;
    }
  }
}

class ScannedDepositCode {
  const ScannedDepositCode({required this.code, required this.format});

  final String code;
  final String format;
}

class _DepositPreviewDialog extends StatelessWidget {
  const _DepositPreviewDialog({required this.voucher, required this.onUsed});

  final DepositVoucher voucher;
  final Future<bool> Function() onUsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.depositCodePreview),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VirtualCodePreview(code: voucher.code, format: voucher.format),
            const SizedBox(height: 16),
            SelectableText(voucher.code),
            const SizedBox(height: 8),
            Text(
              '${l10n.depositAmountLabel}: ${_formatAmount(voucher.amount)}',
            ),
            Text('${l10n.storeLabel}: ${voucher.storeName}'),
            if (voucher.validUntil != null)
              Text(
                '${l10n.validUntilLabel}: ${_formatDate(voucher.validUntil!)}',
              ),
            Text(
              '${l10n.scannedAtLabel}: ${_formatDateTime(voucher.scannedAt)}',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: () async {
            final used = await onUsed();
            if (used && context.mounted) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.check_circle_outline_rounded),
          label: Text(l10n.used),
        ),
      ],
    );
  }
}

class _VirtualCodePreview extends StatelessWidget {
  const _VirtualCodePreview({required this.code, required this.format});

  final String code;
  final String format;

  @override
  Widget build(BuildContext context) {
    final isQrCode = format.toLowerCase().contains('qr');
    final barcode = isQrCode ? bw.Barcode.qrCode() : bw.Barcode.code128();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1F000000)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: bw.BarcodeWidget(
          barcode: barcode,
          data: code,
          drawText: false,
          width: double.infinity,
          height: isQrCode ? 220 : 96,
          errorBuilder: (context, error) {
            return bw.BarcodeWidget(
              barcode: bw.Barcode.qrCode(),
              data: code,
              drawText: false,
              width: 220,
              height: 220,
            );
          },
        ),
      ),
    );
  }
}

const String _addStoreSentinel = '__add_store__';

String _formatAmount(double amount) {
  return '${amount.toStringAsFixed(2)} zł';
}

String _formatDate(DateTime source) {
  final date = source.toLocal();
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();

  return '$day.$month.$year';
}

String _formatDateTime(DateTime source) {
  final date = source.toLocal();
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$day.$month.$year $hour:$minute';
}

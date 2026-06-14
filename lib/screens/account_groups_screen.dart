import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../cloud/cloud_controller.dart';
import '../cloud/cloud_localizations.dart';
import '../cloud/cloud_models.dart';
import '../l10n/app_localizations.dart';
import '../models.dart';

class AccountGroupsScreen extends StatefulWidget {
  const AccountGroupsScreen({
    super.key,
    required this.cloudController,
    required this.appController,
  });

  final CloudController cloudController;
  final AppController appController;

  @override
  State<AccountGroupsScreen> createState() => _AccountGroupsScreenState();
}

class _AccountGroupsScreenState extends State<AccountGroupsScreen> {
  final _displayNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.cloudController.refresh());
      }
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _claimHandle() async {
    final name = _displayNameController.text.trim();
    if (name.length < 2) {
      return;
    }
    await widget.cloudController.claimHandle(name);
  }

  Future<void> _createGroup() async {
    final l10n = AppLocalizations.of(context);
    final cloudL10n = CloudLocalizations.of(context);
    final name = await _showTextPrompt(
      context: context,
      title: cloudL10n.text('createGroup'),
      label: cloudL10n.text('groupName'),
      confirmLabel: l10n.add,
    );
    if (name != null) {
      await widget.cloudController.createGroup(name);
    }
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final cloudL10n = CloudLocalizations.of(context);
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(cloudL10n.text('deleteAccount')),
            content: Text(cloudL10n.text('deleteAccountDescription')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancel),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(cloudL10n.text('deleteAccount')),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldDelete) {
      return;
    }

    final deleted = await widget.cloudController.deleteAccount();
    if (deleted && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(cloudL10n.text('accountDeleted'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cloudL10n = CloudLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: widget.cloudController,
          builder: (context, _) => Text(
            cloudL10n.text(
              widget.cloudController.isSignedIn ? 'groups' : 'signIn',
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.cloudController,
        builder: (context, _) {
          final controller = widget.cloudController;
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!controller.isConfigured)
                    _InfoCard(
                      icon: Icons.cloud_off_outlined,
                      title: cloudL10n.text('localMode'),
                      description: cloudL10n.text('notConfigured'),
                    )
                  else if (!controller.isSignedIn)
                    _SignedOutContent(controller: controller)
                  else if (controller.isProfileLoading)
                    const SizedBox(
                      height: 320,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (controller.needsProfile)
                    _ProfileSetupCard(
                      displayNameController: _displayNameController,
                      onSubmit: _claimHandle,
                    )
                  else ...[
                    _ProfileCard(controller: controller),
                    const SizedBox(height: 16),
                    if (controller.invites.isNotEmpty) ...[
                      Text(
                        cloudL10n.text('invitations'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      for (final invite in controller.invites)
                        _InviteCard(invite: invite, controller: controller),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cloudL10n.text('groups'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: controller.isBusy ? null : _createGroup,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(cloudL10n.text('createGroup')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (controller.groups.isEmpty)
                      _InfoCard(
                        icon: Icons.group_outlined,
                        title: cloudL10n.text('groups'),
                        description: cloudL10n.text('emptyGroups'),
                      )
                    else
                      for (final group in controller.groups)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.group_outlined),
                            title: Text(group.name),
                            subtitle: Text(group.role),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => GroupDetailsScreen(
                                    group: group,
                                    cloudController: controller,
                                    appController: widget.appController,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  ],
                  if (controller.isSignedIn &&
                      !controller.isProfileLoading) ...[
                    const SizedBox(height: 24),
                    _DeleteAccountCard(
                      isBusy: controller.isBusy,
                      onDelete: _deleteAccount,
                    ),
                  ],
                  if (controller.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      controller.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              if (controller.isBusy && !controller.isProfileLoading)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Color(0x16000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DeleteAccountCard extends StatelessWidget {
  const _DeleteAccountCard({required this.isBusy, required this.onDelete});

  final bool isBusy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = CloudLocalizations.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.text('deleteAccount'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: errorColor),
            ),
            const SizedBox(height: 8),
            Text(l10n.text('deleteAccountDescription')),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: errorColor),
              onPressed: isBusy ? null : onDelete,
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(l10n.text('deleteAccount')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedOutContent extends StatelessWidget {
  const _SignedOutContent({required this.controller});

  final CloudController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = CloudLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoCard(
          icon: Icons.lock_outline_rounded,
          title: l10n.text('localMode'),
          description: l10n.text('localModeDescription'),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: controller.isBusy ? null : controller.signInWithApple,
          icon: const Icon(Icons.apple),
          label: Text(l10n.text('signInApple')),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: controller.isBusy ? null : controller.signInWithGoogle,
          icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
          label: Text(l10n.text('signInGoogle')),
        ),
      ],
    );
  }
}

class _ProfileSetupCard extends StatelessWidget {
  const _ProfileSetupCard({
    required this.displayNameController,
    required this.onSubmit,
  });

  final TextEditingController displayNameController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = CloudLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.text('completeProfile'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(l10n.text('completeProfileDescription')),
            const SizedBox(height: 16),
            TextField(
              controller: displayNameController,
              autofocus: true,
              maxLength: 24,
              inputFormatters: [
                FilteringTextInputFormatter.deny('#'),
                LengthLimitingTextInputFormatter(24),
              ],
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: l10n.text('displayName')),
              onSubmitted: (_) => onSubmit(),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onSubmit,
              child: Text(l10n.text('createProfile')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.controller});

  final CloudController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = CloudLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.text('signedInAs'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              controller.profile!.handle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        trailing: TextButton(
          onPressed: controller.isBusy ? null : controller.signOut,
          child: Text(l10n.text('signOut')),
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.invite, required this.controller});

  final CloudGroupInvite invite;
  final CloudController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = CloudLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              invite.groupName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('${l10n.text('invitedBy')}: ${invite.inviterHandle}'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: controller.isBusy
                      ? null
                      : () => controller.respondToInvite(
                          inviteId: invite.id,
                          accept: false,
                        ),
                  child: Text(l10n.text('decline')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: controller.isBusy
                      ? null
                      : () => controller.respondToInvite(
                          inviteId: invite.id,
                          accept: true,
                        ),
                  child: Text(l10n.text('accept')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class GroupDetailsScreen extends StatefulWidget {
  const GroupDetailsScreen({
    super.key,
    required this.group,
    required this.cloudController,
    required this.appController,
  });

  final CloudGroup group;
  final CloudController cloudController;
  final AppController appController;

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  List<CloudGroupMember> _members = const [];
  List<SharedGroceryList> _lists = const [];
  List<SharedDepositVoucher> _vouchers = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.cloudController.addListener(_syncSharedData);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _reload();
      }
    });
  }

  @override
  void dispose() {
    widget.cloudController.removeListener(_syncSharedData);
    super.dispose();
  }

  void _syncSharedData() {
    if (!mounted) {
      return;
    }
    setState(() {
      _lists = widget.cloudController.sharedListsForGroup(widget.group.id);
      _vouchers = widget.cloudController.sharedVouchersForGroup(
        widget.group.id,
      );
    });
  }

  Future<void> _reload() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }
    final members = await widget.cloudController.loadGroupMembers(
      widget.group.id,
    );
    await widget.cloudController.refreshSharedData();
    if (!mounted) {
      return;
    }
    setState(() {
      _members = members;
      _lists = widget.cloudController.sharedListsForGroup(widget.group.id);
      _vouchers = widget.cloudController.sharedVouchersForGroup(
        widget.group.id,
      );
      _isLoading = false;
    });
  }

  Future<void> _inviteMember() async {
    final cloudL10n = CloudLocalizations.of(context);
    final handle = await _showTextPrompt(
      context: context,
      title: cloudL10n.text('inviteMember'),
      label: cloudL10n.text('memberHandle'),
      confirmLabel: cloudL10n.text('sendInvite'),
      maxLength: 100,
    );
    if (handle == null) {
      return;
    }
    final sent = await widget.cloudController.inviteUser(
      groupId: widget.group.id,
      handle: handle,
    );
    if (sent && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(cloudL10n.text('invitationSent'))));
    } else if (mounted && widget.cloudController.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.cloudController.errorMessage!)),
      );
    }
    widget.cloudController.clearError();
    if (!mounted) {
      return;
    }
    FocusScope.of(context).unfocus();
  }

  Future<void> _shareList() async {
    final cloudL10n = CloudLocalizations.of(context);
    final sharedSourceLocalIds = widget.cloudController.sharedSourceLocalIds;
    final selected = await _showSelection<GroceryListModel>(
      context: context,
      title: cloudL10n.text('shareLocalList'),
      explanation: cloudL10n.text('shareListExplanation'),
      values: widget.appController.groceryLists
          .where((list) => !sharedSourceLocalIds.contains(list.id))
          .toList(),
      label: (list) => '${list.name} (${list.items.length})',
    );
    if (selected == null) {
      return;
    }
    final shared = await widget.cloudController.shareListWithGroup(
      groupId: widget.group.id,
      list: selected,
    );
    if (!shared) {
      _showCloudError();
      return;
    }
    await widget.appController.deleteGroceryList(selected.id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(cloudL10n.text('sharedToGroup'))));
      await _reload();
    }
  }

  Future<void> _stopSharingList(SharedGroceryList list) async {
    final cloudL10n = CloudLocalizations.of(context);
    final shouldStop =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(cloudL10n.text('stopSharing')),
            content: Text(cloudL10n.text('stopSharingExplanation')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(cloudL10n.text('stopSharing')),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldStop || !mounted) {
      return;
    }

    final latest = await widget.cloudController.fetchSharedList(list.id);
    if (latest == null) {
      _showCloudError();
      return;
    }

    final privateList = latest.toPrivateGroceryListModel();
    final previousLocal = widget.appController.getGroceryListById(
      privateList.id,
    );
    await widget.appController.upsertGroceryList(privateList);

    final deleted = await widget.cloudController.deleteSharedList(list.id);
    if (!deleted) {
      if (previousLocal == null) {
        await widget.appController.deleteGroceryList(privateList.id);
      } else {
        await widget.appController.upsertGroceryList(previousLocal);
      }
      _showCloudError();
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(cloudL10n.text('stoppedSharing'))));
      await _reload();
    }
  }

  Future<void> _moveVoucher() async {
    final cloudL10n = CloudLocalizations.of(context);
    final selected = await _showSelection<DepositVoucher>(
      context: context,
      title: cloudL10n.text('moveLocalDeposit'),
      explanation: cloudL10n.text('moveDepositExplanation'),
      values: widget.appController.depositVouchers,
      label: (voucher) =>
          '${voucher.storeName} · ${voucher.amount.toStringAsFixed(2)}',
    );
    if (selected == null) {
      return;
    }
    final moved = await widget.cloudController.moveVoucherToGroup(
      groupId: widget.group.id,
      voucher: selected,
    );
    if (!moved) {
      _showCloudError();
      return;
    }
    await widget.appController.deleteDepositVoucher(selected.id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(cloudL10n.text('movedToGroup'))));
      await _reload();
    }
  }

  Future<void> _leaveGroup() async {
    final cloudL10n = CloudLocalizations.of(context);
    final shouldLeave =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(cloudL10n.text('leaveGroup')),
            content: Text(cloudL10n.text('leaveGroupDescription')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(cloudL10n.text('leaveGroup')),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldLeave || !mounted) {
      return;
    }

    final left = await widget.cloudController.leaveGroup(widget.group.id);
    if (!mounted) {
      return;
    }
    if (left) {
      Navigator.pop(context);
      return;
    }
    _showCloudError();
  }

  void _showCloudError() {
    final message = widget.cloudController.errorMessage;
    if (mounted && message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    widget.cloudController.clearError();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CloudLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        actions: [
          if (widget.group.canInvite)
            IconButton(
              onPressed: _inviteMember,
              tooltip: l10n.text('inviteMember'),
              icon: const Icon(Icons.person_add_alt_1_outlined),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator.adaptive(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _InfoCard(
                    icon: Icons.group_outlined,
                    title: widget.group.name,
                    description: l10n.text('membersCanEdit'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.text('members'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (_members.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(l10n.text('emptyMembers')),
                    )
                  else
                    Card(
                      child: Column(
                        children: [
                          for (var index = 0; index < _members.length; index++)
                            ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  _members[index].displayName
                                      .substring(0, 1)
                                      .toUpperCase(),
                                ),
                              ),
                              title: Text(_members[index].displayName),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: l10n.text('sharedLists'),
                    actionLabel: l10n.text('shareLocalList'),
                    onAction: _shareList,
                  ),
                  if (_lists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(l10n.text('emptySharedLists')),
                    )
                  else
                    for (final list in _lists)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.playlist_add_check_rounded),
                          title: Text(list.name),
                          subtitle: Text('${list.items.length}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'stop_sharing') {
                                await _stopSharingList(list);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'stop_sharing',
                                child: Text(l10n.text('stopSharing')),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: l10n.text('sharedDeposits'),
                    actionLabel: l10n.text('moveLocalDeposit'),
                    onAction: _moveVoucher,
                  ),
                  if (_vouchers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(l10n.text('emptySharedDeposits')),
                    )
                  else
                    for (final voucher in _vouchers)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.qr_code_2_rounded),
                          title: Text(
                            '${voucher.storeName} · ${voucher.amount.toStringAsFixed(2)}',
                          ),
                          subtitle: Text(voucher.code),
                          trailing: voucher.redeemedAt == null
                              ? null
                              : const Icon(Icons.check_circle_outline_rounded),
                        ),
                      ),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: widget.cloudController.isBusy
                        ? null
                        : _leaveGroup,
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(l10n.text('leaveGroup')),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add_rounded),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _showTextPrompt({
  required BuildContext context,
  required String title,
  required String label,
  required String confirmLabel,
  int maxLength = 100,
}) async {
  final l10n = AppLocalizations.of(context);
  var value = '';
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        autofocus: true,
        maxLength: maxLength,
        inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
        decoration: InputDecoration(labelText: label),
        onChanged: (nextValue) {
          value = nextValue;
        },
        onSubmitted: (submittedValue) {
          if (submittedValue.trim().isNotEmpty) {
            Navigator.pop(dialogContext, submittedValue.trim());
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final trimmedValue = value.trim();
            if (trimmedValue.isNotEmpty) {
              Navigator.pop(dialogContext, trimmedValue);
            }
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result;
}

Future<T?> _showSelection<T>({
  required BuildContext context,
  required String title,
  required String explanation,
  required List<T> values,
  required String Function(T value) label,
}) async {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(explanation),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: values.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(l10n.nothingToShow),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: values.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(label(values[index])),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.pop(sheetContext, values[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

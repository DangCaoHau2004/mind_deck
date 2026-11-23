import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/data/models/class/class_invitation_model.dart';
import 'package:mind_deck/ui/screens/classroom/class_members/bloc/class_members_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_members/bloc/class_members_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_members/bloc/class_members_state.dart';

/// Mời thành viên bằng email chính xác: dán nhiều email -> kiểm tra -> gửi lời mời.
/// Người được mời luôn là học viên và phải tự chấp nhận.
Future<void> showInviteMembersSheet(BuildContext context, {required String classId}) {
  final bloc = context.read<ClassMembersBloc>();
  bloc.add(InviteRowsCleared());
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: _InviteSheet(classId: classId),
    ),
  );
}

/// Tách email theo khoảng trắng / dấu phẩy / chấm phẩy, chuẩn hóa chữ thường, bỏ trùng.
List<String> parseInviteEmails(String raw) {
  final seen = <String>{};
  final result = <String>[];
  for (final part in raw.split(RegExp(r'[\s,;]+'))) {
    final email = part.trim().toLowerCase();
    if (email.isNotEmpty && seen.add(email)) result.add(email);
  }
  return result;
}

class _InviteSheet extends StatefulWidget {
  final String classId;

  const _InviteSheet({required this.classId});

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> get _emails => parseInviteEmails(_controller.text);

  ({String label, Color color, IconData icon}) _describe(InviteLookupRow row, ColorScheme cs) {
    if (row.newlyInvited) {
      return (
        label: 'Đã gửi lời mời',
        color: Colors.green.shade600,
        icon: Icons.mark_email_read_rounded,
      );
    }
    return switch (row.status) {
      InviteLookupRow.ok => (
        label: 'Có thể mời',
        color: Colors.green.shade600,
        icon: Icons.check_circle_rounded,
      ),
      InviteLookupRow.alreadyMember => (
        label: 'Đã là thành viên',
        color: cs.outline,
        icon: Icons.people_alt_rounded,
      ),
      InviteLookupRow.pending => (
        label: 'Đang chờ duyệt vào lớp',
        color: Colors.orange.shade600,
        icon: Icons.hourglass_top_rounded,
      ),
      InviteLookupRow.invited => (
        label: 'Đã được mời, chưa trả lời',
        color: Colors.blue.shade600,
        icon: Icons.schedule_send_rounded,
      ),
      InviteLookupRow.locked => (
        label: 'Không thể mời tài khoản này',
        color: cs.outline,
        icon: Icons.block_rounded,
      ),
      _ => (label: 'Không tìm thấy tài khoản', color: cs.error, icon: Icons.person_off_rounded),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: BlocBuilder<ClassMembersBloc, ClassMembersState>(
            builder: (context, state) {
              final rows = state.inviteRows;
              final canSend = rows.any((r) => r.canInvite) && !state.isInviteBusy;
              final okEmails = [
                for (final r in rows)
                  if (r.canInvite) r.email,
              ];
              final busy = state.isInviteBusy || state.isProcessing;

              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 6,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Mời thành viên',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nhập chính xác email tài khoản Mind Deck. Người được mời cần chấp nhận lời mời.',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    minLines: 3,
                    maxLines: 6,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) {
                      if (rows.isNotEmpty)
                        context.read<ClassMembersBloc>().add(InviteRowsCleared());
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText:
                          'a@example.com, b@example.com\n(mỗi email một dòng hoặc cách nhau bằng dấu phẩy)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${_emails.length} email',
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: _emails.isEmpty || busy
                            ? null
                            : () => context.read<ClassMembersBloc>().add(
                                InviteLookupRequested(widget.classId, _emails),
                              ),
                        icon: state.isInviteBusy && rows.isEmpty
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search_rounded),
                        label: const Text('Kiểm tra'),
                      ),
                    ],
                  ),
                  if (rows.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    for (final row in rows) _buildRow(context, row, cs, busy),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: canSend
                          ? () => context.read<ClassMembersBloc>().add(
                              InvitesSent(widget.classId, okEmails),
                            )
                          : null,
                      style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                      child: state.isInviteBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              okEmails.isEmpty
                                  ? 'Không có email nào mời được'
                                  : 'Gửi lời mời (${okEmails.length})',
                            ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRow(BuildContext context, InviteLookupRow row, ColorScheme cs, bool busy) {
    final d = _describe(row, cs);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: d.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: d.color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(d.icon, color: d.color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.fullName != null && row.fullName!.isNotEmpty ? row.fullName! : row.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    row.fullName != null && row.fullName!.isNotEmpty
                        ? '${row.email} · ${d.label}'
                        : d.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: d.color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (row.status == InviteLookupRow.invited && row.canRevoke && row.userId != null)
              TextButton(
                onPressed: busy
                    ? null
                    : () => context.read<ClassMembersBloc>().add(
                        InviteRevoked(widget.classId, row.userId!),
                      ),
                child: const Text('Thu hồi'),
              ),
          ],
        ),
      ),
    );
  }
}

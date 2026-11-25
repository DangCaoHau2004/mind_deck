import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/models/class/class_member_model.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/ui/commons/custom_toast.dart';
import 'package:mind_deck/ui/screens/classroom/class_members/bloc/class_members_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_members/bloc/class_members_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_members/bloc/class_members_state.dart';
import 'package:mind_deck/ui/screens/classroom/class_members/widgets/invite_members_sheet.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';

/// Thứ bậc: owner > admin > tutor > student. Chỉ người CAO bậc hơn mới đuổi được.
int _rank(ClassRole role) => switch (role) {
  ClassRole.owner => 4,
  ClassRole.admin => 3,
  ClassRole.tutor => 2,
  _ => 1,
};

class ClassMembersScreen extends StatelessWidget {
  final ClassModel classData;

  const ClassMembersScreen({Key? key, required this.classData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DI().sl<ClassMembersBloc>()
            ..add(ClassMembersLoaded(classData.id, canManage: classData.isAdminOrOwner)),
      child: _ClassMembersView(classData: classData),
    );
  }
}

class _ClassMembersView extends StatelessWidget {
  final ClassModel classData;

  const _ClassMembersView({required this.classData});

  /// Hạng của tôi trong lớp (dùng để quyết định ai đuổi được ai).
  int get _myRank => classData.isOwner
      ? 4
      : switch (classData.myRole) {
          'admin' => 3,
          'tutor' => 2,
          _ => 1,
        };

  Future<void> _confirmKick(BuildContext context, ClassMemberModel member) async {
    final name = member.fullName.isNotEmpty ? member.fullName : 'thành viên này';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đuổi khỏi lớp?'),
        content: Text(
          '$name sẽ mất quyền xem học liệu và không còn trong thống kê của lớp. '
          'Tiến trình học cá nhân của họ vẫn được giữ lại.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Đuổi', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<ClassMembersBloc>().add(MemberKicked(classData.id, member.userId));
    }
  }

  Future<void> _confirmTransferOwner(BuildContext context, ClassMemberModel member) async {
    final name = member.fullName.isNotEmpty ? member.fullName : 'thành viên này';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chuyển quyền chủ lớp?'),
        content: Text(
          '$name sẽ trở thành chủ lớp. Bạn sẽ xuống làm admin của lớp và không thể tự lấy lại '
          'quyền chủ lớp.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Chuyển quyền', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<ClassMembersBloc>().add(OwnerTransferred(classData.id, member.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool canManage = classData.isAdminOrOwner;

    return BlocConsumer<ClassMembersBloc, ClassMembersState>(
      listenWhen: (prev, current) => prev.noticeId != current.noticeId,
      listener: (context, state) {
        final notice = state.notice;
        if (notice == null) return;
        CustomToast.show(
          context,
          state.noticeIsError
              ? CustomToast.danger(message: notice)
              : CustomToast.success(message: notice),
        );
        // Vừa chuyển quyền chủ lớp: quay về màn lớp để tải lại vai trò của tôi.
        if (state.ownerTransferred) Navigator.of(context).pop(true);
      },
      builder: (context, state) {
        return DefaultTabController(
          length: canManage ? 3 : 1,
          child: Scaffold(
            backgroundColor: colorScheme.background,
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(CupertinoIcons.back, color: colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                "Thành viên",
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900, // Chữ đậm, phá cách
                  letterSpacing: 0.5,
                ),
              ),
              backgroundColor: Colors.transparent, // Trong suốt để hiện nền
              scrolledUnderElevation: 0,
              elevation: 0,
              centerTitle: true,
              actions: [
                // Giảng viên luôn mời được; học viên chỉ khi lớp bật `allowMemberAdd`.
                if (classData.canInviteMembers)
                  IconButton(
                    tooltip: 'Mời thành viên',
                    icon: Icon(CupertinoIcons.person_add, color: colorScheme.primary),
                    onPressed: () => showInviteMembersSheet(context, classId: classData.id),
                  ),
              ],
              // Phá cách: Biến TabBar mặc định thành Segmented Control hiện đại
              bottom: canManage
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(66),
                      child: Container(
                        height: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          labelColor: colorScheme.onPrimary,
                          unselectedLabelColor: colorScheme.onSurfaceVariant,
                          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          tabs: [
                            const Tab(text: "Đã tham gia"),
                            Tab(
                              text: state.pendingMembers.isEmpty
                                  ? "Chờ duyệt"
                                  : "Chờ duyệt (${state.pendingMembers.length}${state.pendingPage.hasMore ? '+' : ''})",
                            ),
                            Tab(
                              text: state.invitedMembers.isEmpty
                                  ? "Đã mời"
                                  : "Đã mời (${state.invitedMembers.length}${state.invitedPage.hasMore ? '+' : ''})",
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
            body: Builder(
              builder: (context) {
                if (state.status == ClassMembersStatus.loading) {
                  return Center(
                    child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 4),
                  );
                }
                if (state.status == ClassMembersStatus.failure) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.errorMessage ?? 'Có lỗi xảy ra',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => context.read<ClassMembersBloc>().add(
                              ClassMembersLoaded(classData.id, canManage: canManage),
                            ),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // Tab 1: Đã tham gia
                    _buildMemberList(context, state.members, MemberListKind.joined),

                    // Tab 2, 3: Chờ duyệt / Đã mời (chỉ owner/admin)
                    if (canManage) ...[
                      _buildMemberList(context, state.pendingMembers, MemberListKind.pending),
                      _buildMemberList(context, state.invitedMembers, MemberListKind.invited),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMemberList(
    BuildContext context,
    List<ClassMemberModel> members,
    MemberListKind mode,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool canManage = classData.isAdminOrOwner;
    final bool isPending = mode == MemberListKind.pending;
    final bool isInvited = mode == MemberListKind.invited;

    Future<void> onRefresh() async {
      final bloc = context.read<ClassMembersBloc>();
      bloc.add(ClassMembersRefreshed(classData.id));
      await bloc.stream.firstWhere((ClassMembersState s) => !s.isRefreshing);
    }

    if (members.isEmpty) {
      return CommonRefresh(
        onRefresh: onRefresh,
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPending || isInvited
                          ? CupertinoIcons.person_crop_circle_badge_exclam
                          : CupertinoIcons.person_3_fill,
                      size: 80,
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isPending
                        ? "Không có yêu cầu chờ duyệt."
                        : isInvited
                        ? "Chưa có lời mời nào đang chờ."
                        : "Lớp học chưa có ai.",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final pageInfo = switch (mode) {
      MemberListKind.joined => context.read<ClassMembersBloc>().state.membersPage,
      MemberListKind.pending => context.read<ClassMembersBloc>().state.pendingPage,
      MemberListKind.invited => context.read<ClassMembersBloc>().state.invitedPage,
    };

    // Gần cuối danh sách thì tải trang kế tiếp (bloc tự bỏ qua khi hết trang hoặc đang tải).
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.depth == 0 && n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) {
          context.read<ClassMembersBloc>().add(ClassMembersMoreLoaded(classData.id, mode));
        }
        return false;
      },
      child: CommonRefresh(
        onRefresh: onRefresh,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList.builder(
              itemCount: members.length + (pageInfo.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= members.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                  );
                }
                final member = members[index];

                // Custom design elements dựa trên role
                final isOwner = member.role == ClassRole.owner;
                final isAdmin = member.role == ClassRole.admin;
                final isTutor = member.role == ClassRole.tutor;

                final roleColor = isOwner || isAdmin
                    ? Colors.purple.shade600
                    : (isTutor ? Colors.orange.shade600 : colorScheme.primary);

                final roleIcon = isOwner || isAdmin
                    ? Icons.shield_rounded
                    : (isTutor ? Icons.school_rounded : Icons.person_rounded);

                // Email là null với học viên (trừ khi lớp bật `showMemberEmails`); giảng viên luôn thấy.
                final email = member.email ?? member.user?.email;
                final canKick =
                    canManage &&
                    mode == MemberListKind.joined &&
                    member.userId != classData.ownerId &&
                    _rank(member.role) < _myRank;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  clipBehavior: Clip.antiAlias, // Để watermark không tràn viền
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Dải màu bên trái báo hiệu quyền
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 6, color: roleColor),
                      ),

                      // Watermark icon cực lớn chìm dưới nền
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Transform.rotate(
                          angle: -0.2,
                          child: Icon(
                            roleIcon,
                            size: 100,
                            color: roleColor.withValues(alpha: 0.04),
                          ),
                        ),
                      ),

                      // Nội dung thẻ
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                        child: Row(
                          children: [
                            // Squircle Avatar (Vuông bo góc)
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : '?',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: roleColor,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.fullName.isNotEmpty ? member.fullName : 'Unknown User',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (email != null && email.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (mode == MemberListKind.joined) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(roleIcon, size: 12, color: roleColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          member.role.name.toUpperCase(),
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: roleColor,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (isInvited && member.invitedAt != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Đã mời ${_formatDate(member.invitedAt!)}',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.outline,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Khối Actions
                            if (canManage && isPending) ...[
                              Column(
                                children: [
                                  InkWell(
                                    onTap: () => context.read<ClassMembersBloc>().add(
                                      MemberApproved(classData.id, member.userId),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.green,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => context.read<ClassMembersBloc>().add(
                                      MemberKicked(classData.id, member.userId),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.red,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (canManage && isInvited) ...[
                              TextButton(
                                onPressed: () => context.read<ClassMembersBloc>().add(
                                  InviteRevoked(classData.id, member.userId),
                                ),
                                child: Text(
                                  'Thu hồi',
                                  style: TextStyle(
                                    color: colorScheme.error,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ] else if (canKick) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceVariant.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_horiz_rounded,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  offset: const Offset(0, 40),
                                  onSelected: (value) {
                                    if (value == 'kick') {
                                      _confirmKick(context, member);
                                    } else if (value == 'role' && classData.isOwner) {
                                      _showRoleDialog(context, member);
                                    } else if (value == 'transfer' && classData.isOwner) {
                                      _confirmTransferOwner(context, member);
                                    }
                                  },
                                  itemBuilder: (BuildContext context) {
                                    return [
                                      if (classData.isOwner)
                                        const PopupMenuItem(
                                          value: 'role',
                                          child: Row(
                                            children: [
                                              Icon(Icons.swap_calls_rounded, size: 22),
                                              SizedBox(width: 12),
                                              Text(
                                                'Đổi quyền',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (classData.isOwner)
                                        const PopupMenuItem(
                                          value: 'transfer',
                                          child: Row(
                                            children: [
                                              Icon(Icons.workspace_premium_rounded, size: 22),
                                              SizedBox(width: 12),
                                              Text(
                                                'Chuyển quyền chủ lớp',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      PopupMenuItem(
                                        value: 'kick',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.person_remove_rounded,
                                              size: 22,
                                              color: colorScheme.error,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Đuổi khỏi lớp',
                                              style: TextStyle(
                                                color: colorScheme.error,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ];
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(l.day)}/${two(l.month)}/${l.year}';
  }

  void _showRoleDialog(BuildContext context, ClassMemberModel member) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: colorScheme.surface,
          title: Text(
            'Chỉ định quyền',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
              fontSize: 22,
            ),
          ),
          contentPadding: const EdgeInsets.only(top: 20, bottom: 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRoleOption(
                context: dialogContext,
                blocContext: context,
                member: member,
                roleValue: 'admin',
                title: 'Admin',
                icon: Icons.shield_rounded,
                color: Colors.purple.shade600,
              ),
              _buildRoleOption(
                context: dialogContext,
                blocContext: context,
                member: member,
                roleValue: 'tutor',
                title: 'Tutor',
                icon: Icons.school_rounded,
                color: Colors.orange.shade600,
              ),
              _buildRoleOption(
                context: dialogContext,
                blocContext: context,
                member: member,
                roleValue: 'student',
                title: 'Student',
                icon: Icons.person_rounded,
                color: colorScheme.primary,
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget hỗ trợ vẽ Option trong Dialog để code sạch hơn
  Widget _buildRoleOption({
    required BuildContext context,
    required BuildContext blocContext,
    required ClassMemberModel member,
    required String roleValue,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        blocContext.read<ClassMembersBloc>().add(
          MemberRoleUpdated(classData.id, member.userId, roleValue),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

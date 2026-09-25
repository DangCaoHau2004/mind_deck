import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/data/models/class/class_member_model.dart';
import 'package:mind_deck/data/models/enums.dart';
import 'package:mind_deck/ui/screens/classroom/class_members/bloc/class_members_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_members/bloc/class_members_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_members/bloc/class_members_state.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';

class ClassMembersScreen extends StatelessWidget {
  final ClassModel classData;

  const ClassMembersScreen({Key? key, required this.classData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DI().sl<ClassMembersBloc>()..add(ClassMembersLoaded(classData.id)),
      child: _ClassMembersView(classData: classData),
    );
  }
}

class _ClassMembersView extends StatelessWidget {
  final ClassModel classData;

  const _ClassMembersView({required this.classData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isAdminOrOwner = classData.isOwner || classData.myRole == 'admin';

    return DefaultTabController(
      length: isAdminOrOwner ? 2 : 1,
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
          // Phá cách: Biến TabBar mặc định thành Segmented Control hiện đại
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(66),
            child: Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.6),
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
                      color: colorScheme.primary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: [
                  const Tab(text: "Đã tham gia"),
                  if (isAdminOrOwner) const Tab(text: "Chờ duyệt"),
                ],
              ),
            ),
          ),
        ),
        body: BlocConsumer<ClassMembersBloc, ClassMembersState>(
          listenWhen: (prev, current) => prev.isProcessing != current.isProcessing,
          listener: (context, state) {
            if (!state.isProcessing && state.processErrorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.processErrorMessage!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  margin: const EdgeInsets.all(20),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == ClassMembersStatus.loading) {
              return Center(
                child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 4),
              );
            }
            if (state.status == ClassMembersStatus.failure) {
              return Center(
                child: Text(
                  state.errorMessage ?? 'Có lỗi xảy ra',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }

            return TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Tab 1: Đã tham gia
                _buildMemberList(context, state.members, isAdminOrOwner, false),

                // Tab 2: Chờ duyệt (nếu có quyền)
                if (isAdminOrOwner)
                  _buildMemberList(context, state.pendingMembers, isAdminOrOwner, true),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMemberList(
    BuildContext context,
    List<ClassMemberModel> members,
    bool isAdminOrOwner,
    bool isPending,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool canViewEmail =
        classData.isOwner || classData.myRole == 'admin' || classData.myRole == 'tutor';

    if (members.isEmpty) {
      return CommonRefresh(
        onRefresh: () async {
          final bloc = context.read<ClassMembersBloc>();
          bloc.add(ClassMembersRefreshed(classData.id));
          await bloc.stream.firstWhere((ClassMembersState s) => !s.isRefreshing);
        },
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPending
                          ? CupertinoIcons.person_crop_circle_badge_exclam
                          : CupertinoIcons.person_3_fill,
                      size: 80,
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isPending ? "Không có yêu cầu chờ duyệt." : "Lớp học chưa có ai.",
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

    return CommonRefresh(
      onRefresh: () async {
        final bloc = context.read<ClassMembersBloc>();
        bloc.add(ClassMembersRefreshed(classData.id));
        await bloc.stream.firstWhere((ClassMembersState s) => !s.isRefreshing);
      },
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          sliver: SliverList.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
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

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                clipBehavior: Clip.antiAlias, // Để watermark không tràn viền
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: roleColor.withOpacity(0.05),
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
                        child: Icon(roleIcon, size: 100, color: roleColor.withOpacity(0.04)),
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
                              color: roleColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              member.user?.fullName.isNotEmpty == true
                                  ? member.user!.fullName[0].toUpperCase()
                                  : '?',
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
                                  member.user?.fullName ?? 'Unknown User',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (canViewEmail &&
                                    member.user?.email != null &&
                                    member.user!.email.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    member.user!.email,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (!isPending) ...[
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
                              ],
                            ),
                          ),

                          // Khối Actions
                          if (isAdminOrOwner && isPending) ...[
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
                                      color: Colors.green.withOpacity(0.15),
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
                                      color: Colors.red.withOpacity(0.15),
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
                          ] else if (isAdminOrOwner &&
                              !isPending &&
                              member.userId != classData.ownerId &&
                              member.role != ClassRole.owner) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant.withOpacity(0.4),
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
                                    context.read<ClassMembersBloc>().add(
                                      MemberKicked(classData.id, member.userId),
                                    );
                                  } else if (value == 'role' && classData.isOwner) {
                                    _showRoleDialog(context, member);
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
    );
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
                color: color.withOpacity(0.15),
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

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mind_deck/configs/di.dart';
import 'package:mind_deck/data/models/class/class_model.dart';
import 'package:mind_deck/navigation/app_routes.dart';
import 'package:mind_deck/ui/screens/classroom/class_materials/bloc/class_materials_bloc.dart';
import 'package:mind_deck/ui/screens/classroom/class_materials/bloc/class_materials_event.dart';
import 'package:mind_deck/ui/screens/classroom/class_materials/bloc/class_materials_state.dart';
import 'package:mind_deck/ui/screens/deck/widgets/deck_item_widget.dart';
import 'package:mind_deck/ui/screens/folder/widgets/folder_item_widget.dart';
import 'package:mind_deck/ui/commons/common_refresh.dart';
import 'package:mind_deck/data/models/deck_model.dart';
import 'package:mind_deck/data/models/folder_model.dart';
import 'package:mind_deck/ui/screens/classroom/class_materials/add_material_screen.dart';
import 'package:go_router/go_router.dart';

class ClassMaterialsScreen extends StatelessWidget {
  final ClassModel classData;

  const ClassMaterialsScreen({super.key, required this.classData});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DI().sl<ClassMaterialsBloc>()..add(ClassMaterialsLoaded(classData.id)),
      child: _ClassMaterialsView(classData: classData),
    );
  }
}

class _ClassMaterialsView extends StatefulWidget {
  final ClassModel classData;

  const _ClassMaterialsView({required this.classData});

  @override
  State<_ClassMaterialsView> createState() => _ClassMaterialsViewState();
}

class _ClassMaterialsViewState extends State<_ClassMaterialsView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ClassMaterialsBloc>().add(ClassMaterialsLoadMore(widget.classData.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdminOrTutor =
        widget.classData.isOwner ||
        widget.classData.myRole == 'admin' ||
        widget.classData.myRole == 'tutor';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: BlocBuilder<ClassMaterialsBloc, ClassMaterialsState>(
          builder: (context, state) {
            if (state.isSelectionMode) {
              final selectedCount = state.selectedDecks.length + state.selectedFolders.length;
              return AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () =>
                      context.read<ClassMaterialsBloc>().add(ClassMaterialsSelectionCleared()),
                ),
                title: Text("$selectedCount đã chọn", style: const TextStyle(color: Colors.black)),
                backgroundColor: Colors.white,
                elevation: 1,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: selectedCount > 0
                        ? () {
                            context.read<ClassMaterialsBloc>().add(
                              ClassMaterialsDeleted(widget.classData.id),
                            );
                          }
                        : null,
                  ),
                ],
              );
            }

            return AppBar(
              leading: IconButton(
                icon: const Icon(CupertinoIcons.back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text("Học liệu", style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.white,
              elevation: 1,
              actions: [
                if (isAdminOrTutor)
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddMaterialScreen(
                            initialSelectedDecks: state.decks,
                            initialSelectedFolders: state.folders,
                          ),
                        ),
                      );

                      if (result != null && result is Map<String, dynamic>) {
                        final decks = result['decks'] as List<DeckModel>;
                        final folders = result['folders'] as List<FolderModel>;

                        if (decks.isNotEmpty || folders.isNotEmpty) {
                          if (context.mounted) {
                            context.read<ClassMaterialsBloc>().add(
                              ClassMaterialAdded(
                                classId: widget.classData.id,
                                deckIds: decks.map((e) => e.id).toList(),
                                folderIds: folders.map((e) => e.id).toList(),
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
              ],
            );
          },
        ),
      ),
      body: BlocConsumer<ClassMaterialsBloc, ClassMaterialsState>(
        listener: (context, state) {
          if (!state.isProcessing && state.processErrorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.processErrorMessage!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          final isInitialLoading =
              (state.status == ClassMaterialsStatus.initial ||
                  state.status == ClassMaterialsStatus.loading) &&
              state.decks.isEmpty &&
              state.folders.isEmpty;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm học liệu...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (value) {
                    context.read<ClassMaterialsBloc>().add(
                      ClassMaterialsSearchChanged(widget.classData.id, value),
                    );
                  },
                ),
              ),
              Expanded(
                child: CommonRefresh(
                  onRefresh: () async {
                    final bloc = context.read<ClassMaterialsBloc>();
                    bloc.add(ClassMaterialsRefreshed(widget.classData.id));
                    await bloc.stream.firstWhere((ClassMaterialsState s) => !s.isRefreshing);
                  },
                  slivers: [
                    if (isInitialLoading)
                      const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                    else if (state.status == ClassMaterialsStatus.failure &&
                        state.decks.isEmpty &&
                        state.folders.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Text(
                            state.errorMessage ?? 'Có lỗi xảy ra',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      )
                    else if (state.decks.isEmpty && state.folders.isEmpty)
                      const SliverFillRemaining(
                        child: Center(child: Text("Lớp chưa có học liệu nào.")),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList.builder(
                          itemCount:
                              state.folders.length +
                              state.decks.length +
                              ((state.status == ClassMaterialsStatus.loading &&
                                      (state.decks.isNotEmpty || state.folders.isNotEmpty))
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index < state.folders.length) {
                              final folder = state.folders[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: FolderItemWidget(
                                  folder: folder,
                                  onTap: () {
                                    if (state.isSelectionMode) {
                                      context.read<ClassMaterialsBloc>().add(
                                        ClassMaterialFolderSelectionToggled(folder.id),
                                      );
                                    } else {
                                      context.pushNamed(
                                        AppRoute.folderDetail.name,
                                        pathParameters: {'id': folder.id},
                                        extra: folder.toJson(),
                                      );
                                    }
                                  },
                                  onLongPress: isAdminOrTutor
                                      ? () {
                                          if (!state.isSelectionMode) {
                                            context.read<ClassMaterialsBloc>().add(
                                              const ClassMaterialsSelectionModeToggled(true),
                                            );
                                            context.read<ClassMaterialsBloc>().add(
                                              ClassMaterialFolderSelectionToggled(folder.id),
                                            );
                                          }
                                        }
                                      : null,
                                  isSelected: state.selectedFolders.contains(folder.id),
                                  isSelectionMode: state.isSelectionMode,
                                ),
                              );
                            }

                            final deckIndex = index - state.folders.length;
                            if (deckIndex < state.decks.length) {
                              final deck = state.decks[deckIndex];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: DeckItemWidget(
                                  deck: deck,
                                  onTap: () {
                                    if (state.isSelectionMode) {
                                      context.read<ClassMaterialsBloc>().add(
                                        ClassMaterialDeckSelectionToggled(deck.id),
                                      );
                                    } else {
                                      context.pushNamed(
                                        AppRoute.deckDetail.name,
                                        pathParameters: {'id': deck.id},
                                        extra: deck.toJson(),
                                      );
                                    }
                                  },
                                  onLongPress: isAdminOrTutor
                                      ? () {
                                          if (!state.isSelectionMode) {
                                            context.read<ClassMaterialsBloc>().add(
                                              const ClassMaterialsSelectionModeToggled(true),
                                            );
                                            context.read<ClassMaterialsBloc>().add(
                                              ClassMaterialDeckSelectionToggled(deck.id),
                                            );
                                          }
                                        }
                                      : null,
                                  isSelected: state.selectedDecks.contains(deck.id),
                                  isSelectionMode: state.isSelectionMode,
                                ),
                              );
                            }

                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class TasksScreen extends StatefulWidget {
  static const String routeName = '/tasks';

  const TasksScreen({Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late final Box<Task> _taskBox;

  final Set<Task> _selectedTasks = {};

  bool get _isSelectionMode => _selectedTasks.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _taskBox = Hive.box<Task>('tasks');
  }

  void _toggleSelection(Task task) {
    setState(() {
      if (_selectedTasks.contains(task)) {
        _selectedTasks.remove(task);
      } else {
        _selectedTasks.add(task);
      }
    });
  }

  Future<void> _deleteSelectedTasks() async {
    final tasks = List<Task>.from(_selectedTasks);

    for (final task in tasks) {
      await task.delete();
    }

    setState(() {
      _selectedTasks.clear();
    });
  }


  void _openEditor({Task? task}) {
    final titleCtrl = TextEditingController(text: task?.name ?? '');
    final descCtrl = TextEditingController(text: task?.description ?? '');

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'TaskEditor',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final slide = Curves.easeOut.transform(anim.value);

        return Opacity(
          opacity: anim.value,
          child: Transform.translate(
            offset: Offset(0, (1 - slide) * 90),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
                child: SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.9,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom,
                    ),
                    child: Column(
                      children: [
                        _EditorHeader(
                          isEditing: task != null,
                          onClose: () => Navigator.pop(ctx),
                          onSave: () {
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Task title is required'),
                                ),
                              );
                              return;
                            }

                            if (task == null) {
                              _taskBox.add(
                                Task(
                                  name: title,
                                  description: descCtrl.text.trim(),
                                ),
                              );
                            } else {
                              task
                                ..name = title
                                ..description = descCtrl.text.trim()
                                ..save();
                            }

                            Navigator.pop(ctx);
                          },
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _InputField(
                                  controller: titleCtrl,
                                  label: 'Task title',
                                  hint: 'e.g. Finish assignment',
                                  icon: Icons.task_alt,
                                ),
                                const SizedBox(height: 16),
                                _InputField(
                                  controller: descCtrl,
                                  label: 'Description',
                                  hint: 'Optional notes',
                                  icon: Icons.notes,
                                  maxLines: 5,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  Future<void> _toggleTask(Task task) async {
    task.completed = !task.completed;
    await task.save();
  }

  Future<void> _removeTask(Task task) async {
    await task.delete();
  }


  Widget _taskTile(Task task) {
    final id = task.key ?? task.createdOn.millisecondsSinceEpoch;
    final isSelected = _selectedTasks.contains(task);

    return Dismissible(
      key: ValueKey(id),
      direction:
      _isSelectionMode ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: const Color.fromARGB(255, 62, 89, 87),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _removeTask(task),
      child: ListTile(
        onLongPress: () => _toggleSelection(task),
        onTap:
        _isSelectionMode ? () => _toggleSelection(task) : null,
        leading: _isSelectionMode
            ? Checkbox(
          value: isSelected,
          onChanged: (_) => _toggleSelection(task),
        )
            : Checkbox(
          value: task.completed,
          onChanged: (_) => _toggleTask(task),
        ),
        title: Text(
          task.name,
          style: TextStyle(
            decoration: task.completed
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        subtitle:
        task.description.isNotEmpty ? Text(task.description) : null,
        trailing: !_isSelectionMode
            ? IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _openOptions(task),
        )
            : null,
        tileColor:
        isSelected ? Colors.grey.withOpacity(0.2) : null,
      ),
    );
  }

  void _openOptions(Task task) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!task.completed)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  _openEditor(task: task);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(ctx);
                _removeTask(task);
              },
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 62, 89, 87),
          title: Text(
            _isSelectionMode
                ? '${_selectedTasks.length} selected'
                : 'Tasks',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            if (_isSelectionMode)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: _deleteSelectedTasks,
              ),
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                    (_) => false,
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.more_horiz, color: Colors.white,),
                child: Text(
                  'Pending',
                  style: TextStyle(color: Colors.white),
                ),
              ),

              Tab(
                icon: Icon(Icons.check_circle_outline,color: Colors.white,),
                  child: Text(
                    'Completed',
                    style: TextStyle(color: Colors.white),
                  ),
              ),
            ],
          ),
        ),
        body: ValueListenableBuilder<Box<Task>>(
          valueListenable: _taskBox.listenable(),
          builder: (_, box, __) {
            final tasks = box.values.toList();
            final pending = tasks.where((t) => !t.completed).toList();
            final done = tasks.where((t) => t.completed).toList();

            return TabBarView(
              children: [
                _buildList(pending, 'No pending tasks'),
                _buildList(done, 'No completed tasks'),
              ],
            );
          },
        ),
        floatingActionButton: _isSelectionMode
            ? null
            : FloatingActionButton(
          backgroundColor:
          const Color.fromARGB(255, 62, 89, 87),
          onPressed: () => _openEditor(),
          child:
          const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildList(List<Task> list, String emptyText) {
    if (list.isEmpty) {
      return Center(child: Text(emptyText));
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 12, bottom: 90),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _taskTile(list[i]),
    );
  }
}


class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon:
        Icon(icon, color: const Color.fromARGB(255, 62, 89, 87)),
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _EditorHeader extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onClose;
  final VoidCallback onSave;

  const _EditorHeader({
    required this.isEditing,
    required this.onClose,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFEAEAEA)),
        ),
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.close), onPressed: onClose),
          Text(
            isEditing ? 'Edit Task' : 'New Task',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onSave,
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }
}

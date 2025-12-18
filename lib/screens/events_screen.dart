import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/event.dart';

class EventsScreen extends StatefulWidget {
  static const String routeName = '/events';

  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late final Box<Event> _eventBox;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _eventBox = Hive.box<Event>('events');
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  List<Event> _upcoming(List<Event> all) {
    final now = DateTime.now();
    final list = all.where((e) => e.scheduledAt.isAfter(now)).toList();
    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  List<Event> _history(List<Event> all) {
    final now = DateTime.now();
    final list = all.where((e) => e.scheduledAt.isBefore(now)).toList();
    list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return list;
  }

  void _openEditor({Event? event}) {
    final titleCtrl = TextEditingController(text: event?.title ?? '');
    final venueCtrl = TextEditingController(text: event?.venue ?? '');
    DateTime selected =
        event?.scheduledAt ?? DateTime.now().add(const Duration(minutes: 2));

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'EventEditor',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        return Transform.scale(
          scale: 0.9 + (0.1 * anim.value),
          child: Opacity(
            opacity: anim.value,
            child: _EventEditorDialog(
              titleController: titleCtrl,
              venueController: venueCtrl,
              initialDate: selected,
              onSave: (title, venue, date) {
                if (title.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event title required')),
                  );
                  return;
                }
                if (date.isBefore(DateTime.now())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Event must be in the future'),
                    ),
                  );
                  return;
                }

                if (event == null) {
                  _eventBox.add(
                    Event(
                      title: title.trim(),
                      venue: venue.trim(),
                      scheduledAt: date,
                    ),
                  );
                } else {
                  event
                    ..title = title.trim()
                    ..venue = venue.trim()
                    ..scheduledAt = date
                    ..save();
                }

                Navigator.pop(ctx);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _eventTile(Event e) {
    final id = e.key ?? e.scheduledAt.millisecondsSinceEpoch;

    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Color.fromARGB(255, 59, 163, 155),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => e.delete(),
      child: ListTile(
        title: Text(
          e.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${e.venue}\n${_formatDate(e.scheduledAt)}'),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showOptions(e),
        ),
      ),
    );
  }

  void _showOptions(Event e) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                _openEditor(event: e);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(ctx);
                e.delete();
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
          backgroundColor: Color.fromARGB(255, 59, 163, 155),
          title: const Text('Events', style: TextStyle(color: Colors.white)),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white,
            tabs: [
              Tab(
                icon: Icon(Icons.event, color: Colors.white),
                text: 'Upcoming',
              ),
              Tab(
                icon: Icon(Icons.history, color: Colors.white),
                text: 'Past',
              ),
            ],
          ),
        ),
        body: ValueListenableBuilder<Box<Event>>(
          valueListenable: _eventBox.listenable(),
          builder: (_, box, __) {
            final all = box.values.toList();
            return TabBarView(
              children: [
                _buildList(_upcoming(all), 'No upcoming events'),
                _buildList(_history(all), 'No past events'),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Color.fromARGB(255, 59, 163, 155),
          onPressed: () => _openEditor(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildList(List<Event> list, String emptyText) {
    if (list.isEmpty) {
      return Center(child: Text(emptyText));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) => _eventTile(list[i]),
    );
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $hh:$mm';
  }
}

class _EventEditorDialog extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController venueController;
  final DateTime initialDate;
  final void Function(String, String, DateTime) onSave;

  const _EventEditorDialog({
    required this.titleController,
    required this.venueController,
    required this.initialDate,
    required this.onSave,
  });

  @override
  State<_EventEditorDialog> createState() => _EventEditorDialogState();
}

class _EventEditorDialogState extends State<_EventEditorDialog>
    with SingleTickerProviderStateMixin {
  late DateTime _selected;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (d == null) return;

    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selected),
    );
    if (t == null) return;

    setState(() {
      _selected = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.35),
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ScaleTransition(
              scale: CurvedAnimation(parent: _anim, curve: Curves.easeOutBack),
              child: Container(
                width: 360,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'New Event',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _EditorField(
                      controller: widget.titleController,
                      label: 'Event title',
                      icon: Icons.event,
                    ),
                    const SizedBox(height: 12),

                    _EditorField(
                      controller: widget.venueController,
                      label: 'Venue',
                      icon: Icons.place,
                    ),
                    const SizedBox(height: 16),

                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Color.fromARGB(
                                255,
                                59,
                                163,
                                155,
                              ).withOpacity(0.18),
                              Color.fromARGB(
                                255,
                                59,
                                163,
                                155,
                              ).withOpacity(0.06),
                            ],
                          ),
                          border: Border.all(
                            color: Color.fromARGB(
                              255,
                              59,
                              163,
                              155,
                            ).withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            _DateTimeChip(
                              icon: Icons.calendar_today,
                              label:
                                  '${_selected.year}-${_selected.month.toString().padLeft(2, '0')}-${_selected.day.toString().padLeft(2, '0')}',
                            ),
                            const SizedBox(width: 10),
                            _DateTimeChip(
                              icon: Icons.access_time,
                              label:
                                  '${_selected.hour.toString().padLeft(2, '0')}:${_selected.minute.toString().padLeft(2, '0')}',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => widget.onSave(
                              widget.titleController.text,
                              widget.venueController.text,
                              _selected,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(
                                255,
                                59,
                                163,
                                155,
                              ),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _EditorField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Color.fromARGB(255, 59, 163, 155)),
        labelText: label,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _DateTimeChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DateTimeChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color.fromARGB(255, 59, 163, 155)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

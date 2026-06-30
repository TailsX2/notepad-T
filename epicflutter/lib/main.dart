import 'package:flutter/material.dart';

void main() {
  runApp(const NotepadApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotepadApp();
  }
}

class NotepadApp extends StatelessWidget {
  const NotepadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notepad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const NotepadHome(),
    );
  }
}

class Note {
  Note({required this.title, required this.content, DateTime? updatedAt})
      : updatedAt = updatedAt ?? DateTime.now();

  String title;
  String content;
  DateTime updatedAt;
}

class NotepadHome extends StatefulWidget {
  const NotepadHome({super.key});

  @override
  State<NotepadHome> createState() => _NotepadHomeState();
}

class _NotepadHomeState extends State<NotepadHome> {
  final List<Note> _notes = [
    Note(
      title: 'Welcome',
      content: 'Tap any note to edit it.\n\nUse the + button to add more notes.',
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  int? _selectedIndex;
  bool _isSelectionMode = false;
  final Set<int> _selectedForDeletion = {};

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
  }

  void _openNoteEditor(int index) {
    final selectedNote = _notes[index];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditor(
          note: selectedNote,
          onSave: (title, content) {
            setState(() {
              selectedNote.title = title.trim().isEmpty ? 'Untitled note' : title.trim();
              selectedNote.content = content;
              selectedNote.updatedAt = DateTime.now();
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }

  void _selectNote(int index) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedForDeletion.contains(index)) {
          _selectedForDeletion.remove(index);
        } else {
          _selectedForDeletion.add(index);
        }
      });
      return;
    }

    _openNoteEditor(index);
  }

  void _addNote() {
    setState(() {
      final newNote = Note(title: 'Untitled note', content: '');
      _notes.insert(0, newNote);
      _selectedIndex = 0;
      _isSelectionMode = false;
      _selectedForDeletion.clear();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedForDeletion.clear();
      }
    });
  }

  void _deleteSelectedNotes() {
    if (_selectedForDeletion.isEmpty) {
      return;
    }

    setState(() {
      final indexes = _selectedForDeletion.toList()..sort();
      for (final index in indexes.reversed) {
        _notes.removeAt(index);
      }

      _selectedForDeletion.clear();
      _isSelectionMode = false;

      if (_notes.isEmpty) {
        _selectedIndex = null;
      } else {
        if (_selectedIndex == null || _selectedIndex! >= _notes.length) {
          _selectedIndex = 0;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedForDeletion.isNotEmpty;

    return Scaffold( // Scaffold provides the app structure including app bar and body.
      appBar: AppBar(
        title: Text(_isSelectionMode ? 'Select notes' : 'Notepad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNote,
            tooltip: 'Add note',
          ),
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.remove_circle_outline),
            onPressed: _toggleSelectionMode,
            tooltip: _isSelectionMode ? 'Cancel selection' : 'Delete notes',
          ),
          if (_isSelectionMode && hasSelection)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteSelectedNotes,
              tooltip: 'Delete selected',
            ),
        ],
      ),
      body: _notes.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final note = _notes[index];
                      final isSelected = index == _selectedIndex;
                      final isMarkedForDeletion = _selectedForDeletion.contains(index);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => _isSelectionMode ? _selectNote(index) : _openNoteEditor(index),
                          borderRadius: BorderRadius.circular(16),
                          child: Container( // Container adds padding, decoration, and layout around the note tile.
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMarkedForDeletion
                                  ? Colors.red.shade50
                                  : isSelected
                                      ? Theme.of(context).colorScheme.primaryContainer
                                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              border: isMarkedForDeletion
                                  ? Border.all(color: Colors.red.shade300)
                                  : null,
                            ),
                            child: Row( // Row arranges its children horizontally.
                              children: [
                                if (_isSelectionMode)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Icon(
                                      isMarkedForDeletion
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: isMarkedForDeletion
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        note.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        note.content.isEmpty
                                            ? 'Tap to write something...'
                                            : note.content.replaceAll('\n', ' '),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatDate(note.updatedAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.note_alt_outlined, size: 64),
            const SizedBox(height: 16),
            const Text(
              'No notes yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('Create your first note to get started.'),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _addNote,
              icon: const Icon(Icons.add),
              label: const Text('Create note'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    }
    if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    }
    return 'just now';
  }
}

class NoteEditor extends StatefulWidget {
  const NoteEditor({super.key, required this.note, required this.onSave});

  final Note note;
  final void Function(String title, String content) onSave;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    widget.onSave(
      _titleController.text,
      _contentController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Scaffold provides the app structure including app bar and body.
        appBar: AppBar(
          title: const Text('Edit note'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                _saveNote();
                Navigator.of(context).pop();
              },
              tooltip: 'Save',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'Contents',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}

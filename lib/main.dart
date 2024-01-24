import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'screens/onboarding_screen.dart';

void main() => runApp(const MyApp());

class Note {
  int? id;
  String? title;
  String? content;

  Note({this.id, this.title, this.content});

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'content': content};
  }
}

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._();

  DatabaseHelper._();

  ///
  Future<void> updateNote(int id, String title, String content) async {
  final Database db = await database;

  await db.update(
    'notes',
    {'title': title, 'content': content},
    where: 'id = ?',
    whereArgs: [id],
  );
}

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'notes_database.db');

    return await openDatabase(path, version: 1, onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT)',
      );
    });
  }

  Future<void> insert(Note note) async {
    final Database db = await database;

    await db.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(int id) async {
    final Database db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> getNotes() async {
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.query('notes');

    return List.generate(maps.length, (i) {
      return Note(
        id: maps[i]['id'],
        title: maps[i]['title'],
        content: maps[i]['content'],
      );
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Keep Note Clone',
      home: OnBoardingScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();
  FocusNode titleFocusNode = FocusNode();
  FocusNode contentFocusNode = FocusNode();

  List<Note> notes = [];

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  void loadNotes() async {
    List<Note> loadedNotes = await DatabaseHelper.instance.getNotes();
    setState(() {
      notes = loadedNotes;
    });
  }

  void addNote() async {
    String title = titleController.text;
    String content = contentController.text;

    if (title.isNotEmpty || content.isNotEmpty) {
      Note newNote = Note(
        title: title,
        content: content,
      );

      await DatabaseHelper.instance.insert(newNote);
      titleController.clear();
      contentController.clear();
      loadNotes();
    }
  }

  void deleteNote(int index) async {
    await DatabaseHelper.instance.delete(notes[index].id!);
    loadNotes();
  }


   void editNote(int index, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNoteScreen(note: notes[index]),
      ),
    ).then((result) {
      // Refresh the notes list when returning from the edit screen
      if (result != null && result) {
        loadNotes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HAMRO DIARY'),
        centerTitle: true,
        backgroundColor: Colors.black,

      ),
      
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Content'),
            ),
          ),
          ElevatedButton(
            onPressed: addNote,
            child: const Text('Add Note'),
          ),
          ////////
               Expanded(
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(notes[index].title!),
                  subtitle: Text(notes[index].content!),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => editNote(index, context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => deleteNote(index),
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
}

class EditNoteScreen extends StatefulWidget {
  final Note note;

  const EditNoteScreen({Key? key, required this.note}) : super(key: key);

  @override
  EditNoteScreenState createState() => EditNoteScreenState();
}

class EditNoteScreenState extends State<EditNoteScreen> {
  late TextEditingController titleController;
  late TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title);
    contentController = TextEditingController(text: widget.note.content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Note'),
      ),
      body: Column(
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: contentController,
            decoration: const InputDecoration(labelText: 'Content'),
          ),
          ElevatedButton(
            onPressed: () {
              
              // Update the note in the database
              DatabaseHelper.instance.updateNote(
                widget.note.id!,
                titleController.text,
                contentController.text,
              );

              // Return to the previous screen and refresh the list
              Navigator.pop(context, true);
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}

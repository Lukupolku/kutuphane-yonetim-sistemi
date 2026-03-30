import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'rafta.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE rooms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bookshelves (
        id TEXT PRIMARY KEY,
        room_id TEXT NOT NULL,
        name TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE shelves (
        id TEXT PRIMARY KEY,
        bookshelf_id TEXT NOT NULL,
        name TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (bookshelf_id) REFERENCES bookshelves(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        isbn TEXT,
        title TEXT NOT NULL,
        authors TEXT,
        publisher TEXT,
        published_date TEXT,
        page_count INTEGER,
        cover_image_url TEXT,
        description TEXT,
        categories TEXT,
        language TEXT DEFAULT 'tr',
        source TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_books (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        shelf_id TEXT,
        status TEXT DEFAULT 'toRead',
        rating REAL,
        is_favorite INTEGER DEFAULT 0,
        start_date TEXT,
        finish_date TEXT,
        personal_notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
        FOREIGN KEY (shelf_id) REFERENCES shelves(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE book_notes (
        id TEXT PRIMARY KEY,
        user_book_id TEXT NOT NULL,
        page_number INTEGER,
        content TEXT NOT NULL,
        image_path TEXT,
        type TEXT DEFAULT 'note',
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_book_id) REFERENCES user_books(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE lendings (
        id TEXT PRIMARY KEY,
        user_book_id TEXT NOT NULL,
        borrower_name TEXT NOT NULL,
        borrower_contact TEXT,
        lent_date TEXT NOT NULL,
        due_date TEXT,
        returned_date TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_book_id) REFERENCES user_books(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE reading_lists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        source TEXT DEFAULT 'user',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE reading_list_items (
        id TEXT PRIMARY KEY,
        reading_list_id TEXT NOT NULL,
        book_id TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        added_at TEXT NOT NULL,
        FOREIGN KEY (reading_list_id) REFERENCES reading_lists(id) ON DELETE CASCADE,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
      )
    ''');

    // Indexes for common queries
    await db.execute(
        'CREATE INDEX idx_bookshelves_room ON bookshelves(room_id)');
    await db.execute(
        'CREATE INDEX idx_shelves_bookshelf ON shelves(bookshelf_id)');
    await db.execute(
        'CREATE INDEX idx_user_books_book ON user_books(book_id)');
    await db.execute(
        'CREATE INDEX idx_user_books_shelf ON user_books(shelf_id)');
    await db.execute(
        'CREATE INDEX idx_book_notes_user_book ON book_notes(user_book_id)');
    await db.execute(
        'CREATE INDEX idx_lendings_user_book ON lendings(user_book_id)');
    await db.execute('CREATE INDEX idx_books_isbn ON books(isbn)');
  }
}

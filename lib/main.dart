import 'package:flutter/material.dart';
import 'db_helper.dart';

// Ali Butt
// Ayoub

void main() {
  runApp(CardOrganizerApp());
}

class CardOrganizerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FoldersScreen(),
    );
  }
}

class FoldersScreen extends StatefulWidget {
  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  DBHelper dbHelper = DBHelper();
  List<Map<String, dynamic>> folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final data = await dbHelper.fetchFolders();
    setState(() {
      folders = data;
    });
  }

  // Add folder functionality
  Future<void> _showAddFolderDialog() async {
    TextEditingController folderController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Folder'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: folderController,
                  decoration: InputDecoration(
                    labelText: "Folder Name",
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () async {
                if (folderController.text.isNotEmpty) {
                  await dbHelper.insertFolder(folderController.text);
                  Navigator.of(context).pop();
                  _loadFolders(); // Refresh the UI after folder creation
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Method to show the confirmation dialog before deleting a folder
  Future<void> _showDeleteConfirmationDialog(int folderId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Folder'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    'Are you sure you want to delete this folder and all its cards?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                await dbHelper.deleteFolder(folderId);
                Navigator.of(context).pop();
                _loadFolders(); // Refresh the UI after deletion
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Card Organizer'),
      ),
      body: folders.isEmpty
          ? Center(child: Text('No Folders Found.'))
          : ListView.builder(
              itemCount: folders.length,
              itemBuilder: (context, index) {
                final folder = folders[index];
                return ListTile(
                  title: Text(folder['folder_name']),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () =>
                        _showDeleteConfirmationDialog(folder['id']),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CardsScreen(folderId: folder['id']),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFolderDialog, // Add folder functionality
        child: Icon(Icons.add),
      ),
    );
  }
}

class CardsScreen extends StatefulWidget {
  final int folderId;

  CardsScreen({required this.folderId});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  DBHelper dbHelper = DBHelper();
  List<Map<String, dynamic>> cards = [];
  Map<String, dynamic>? lastDeletedCard; // Store the last deleted card details

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final data = await dbHelper.fetchCards(widget.folderId);
    setState(() {
      cards = data;
    });
  }

  Future<void> _addCard() async {
    if (lastDeletedCard != null) {
      // Restore the deleted card
      int result = await dbHelper.insertCard(
        lastDeletedCard!['name'],
        lastDeletedCard!['suit'],
        lastDeletedCard!['image_url'],
        widget.folderId,
      );
      lastDeletedCard = null; // Clear the deleted card
    } else {
      // Add a new card (example data)
      int result = await dbHelper.insertCard(
        'New Card',
        'Hearts', // Example suit
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/Playing_card_heart_A.svg/640px-Playing_card_heart_A.svg.png',
        widget.folderId,
      );

      if (result == -1) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('This folder can only hold 6 cards.'),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
    _loadCards(); // Reload the cards after adding
  }

  Future<void> _deleteCard(int cardId, Map<String, dynamic> cardDetails) async {
    // Store the last deleted card's details
    lastDeletedCard = cardDetails;
    await dbHelper.deleteCard(cardId);
    _loadCards(); // Reload the cards after deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cards in Folder'),
      ),
      body: GridView.builder(
        itemCount: cards.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemBuilder: (context, index) {
          final card = cards[index];
          return Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(card['image_url'], height: 100),
                Text(card['name']),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    await _deleteCard(card['id'], card);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        child: Icon(Icons.add),
      ),
    );
  }
}

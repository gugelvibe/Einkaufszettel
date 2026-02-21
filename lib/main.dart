import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/shopping_provider.dart';
import 'models/shopping_models.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ShoppingProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Einkaufszettel',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFE3F2FD), // Sky blue background
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final FocusNode _productFocus = FocusNode();
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _productController.addListener(_onProductChanged);
  }

  void _onProductChanged() {
    final text = _productController.text.toLowerCase();
    final provider = context.read<ShoppingProvider>();
    if (text.isEmpty) {
      setState(() {
        _suggestions = [];
      });
    } else {
      final currentItemNames =
          provider.currentList?.items
              .map((item) => item.name.toLowerCase().trim())
              .toList() ??
          [];
      setState(() {
        _suggestions = provider.currentHistory
            .where(
              (item) =>
                  item.toLowerCase().contains(text) &&
                  !currentItemNames.contains(item.toLowerCase().trim()),
            )
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _productController.dispose();
    _quantityController.dispose();
    _productFocus.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _productController.text.trim();
    final quantity = _quantityController.text.trim();
    final provider = context.read<ShoppingProvider>();

    if (name.isNotEmpty) {
      if (provider.currentList?.isInputDisabled ?? false) {
        final history = provider.currentHistory;
        final inHistory = history.any(
          (h) => h.trim().toLowerCase() == name.toLowerCase(),
        );
        if (!inHistory) {
          // Show feedback if needed, but for now just clear and return
          _productController.clear();
          return;
        }
      }
      provider.addItem(name, quantity);
      _productController.clear();
      _quantityController.clear();
      _productFocus.requestFocus(); // Keep focus
    }
  }

  void _showNewListDialog() {
    final TextEditingController nameController = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Neue Einkaufsliste'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: 'Name der Liste',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                context.read<ShoppingProvider>().addNewList(name);
              }
              Navigator.pop(context);
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  void _showRenameListDialog() {
    final provider = context.read<ShoppingProvider>();
    final currentList = provider.currentList;
    if (currentList == null) return;

    final TextEditingController nameController = TextEditingController(
      text: currentList.name,
    );
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Einkaufsliste umbenennen'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: 'Name der Liste',
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                provider.updateListName(name);
              }
              Navigator.pop(context);
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog() {
    final provider = context.read<ShoppingProvider>();
    final colors = [
      {'name': 'Himmelblau', 'hex': 'E3F2FD'},
      {'name': 'Zartrosa', 'hex': 'FCE4EC'},
      {'name': 'Mintgrün', 'hex': 'E8F5E9'},
      {'name': 'Zitronengelb', 'hex': 'FFF9C4'},
      {'name': 'Lavendel', 'hex': 'F3E5F5'},
      {'name': 'Papayanet', 'hex': 'FBE9E7'},
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Hintergrundfarbe wählen'),
        actions: colors.map((c) {
          return CupertinoActionSheetAction(
            onPressed: () {
              provider.updateListColor(c['hex']);
              Navigator.pop(context);
            },
            child: Text(c['name']!),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
      ),
    );
  }

  void _showActionSheet(BuildContext context) {
    final provider = context.read<ShoppingProvider>();
    final currentList = provider.currentList;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Einstellungen'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              context.read<ShoppingProvider>().clearList();
              Navigator.pop(context);
            },
            child: const Text('Einkaufsliste leeren'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showRenameListDialog();
            },
            child: const Text('Liste umbenennen'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showColorPickerDialog();
            },
            child: const Text('Farbe ändern'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              provider.toggleInputMode();
              Navigator.pop(context);
            },
            child: Text(
              currentList?.isInputDisabled ?? false
                  ? 'Eingabemodus aktivieren'
                  : 'Auswahlmodus aktivieren',
            ),
          ),
          if (currentList?.isInputDisabled ?? false)
            CupertinoActionSheetAction(
              onPressed: () {
                provider.toggleHistoryScope();
                Navigator.pop(context);
              },
              child: Text(
                currentList?.useGlobalHistory ?? true
                    ? 'Nur Begriffe dieser Liste'
                    : 'Alle Begriffe (global)',
              ),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Teilen'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showNewListDialog();
            },
            child: const Text('Zusätzliche Einkaufsliste'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Abbrechen'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingProvider>();
    final currentList = provider.currentList;

    Color backgroundColor = const Color(0xFFE3F2FD);
    if (currentList?.colorHex != null) {
      try {
        backgroundColor = Color(
          int.parse('FF${currentList!.colorHex}', radix: 16),
        );
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withOpacity(0.1),
              elevation: 0,
              leading: IconButton(
                icon: Image.asset('assets/app_icon.png', height: 28),
                onPressed: () => _showActionSheet(context),
              ),
              title: GestureDetector(
                onTap: Theme.of(context).platform == TargetPlatform.macOS
                    ? () => _showActionSheet(context)
                    : null,
                child: Text(
                  currentList?.name ?? 'Einkaufszettel',
                  style: TextStyle(
                    color: Theme.of(context).platform == TargetPlatform.macOS
                        ? CupertinoColors.activeBlue
                        : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(provider.canUndo ? Icons.undo : Icons.check),
                  onPressed: () {
                    if (provider.canUndo) {
                      provider.undoDeletion();
                    } else {
                      provider.removeCompletedItems();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Liquid Background Blobs
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.blue.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.pink.withOpacity(0.2),
                    Colors.pink.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: 50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.yellow.withOpacity(0.2),
                    Colors.yellow.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          // Main Content
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < 0) {
                  provider.nextList();
                } else if (details.primaryVelocity! > 0) {
                  provider.previousList();
                }
              }
            },
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: currentList == null || currentList.items.isEmpty
                        ? const Center(child: Text('Liste ist leer'))
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.only(top: 8),
                            itemCount: currentList.items.length,
                            onReorder: provider.reorderItems,
                            proxyDecorator: (child, index, animation) {
                              return Material(
                                color: Colors.transparent,
                                child: child,
                              );
                            },
                            itemBuilder: (context, index) {
                              final item = currentList.items[index];
                              return _buildListTile(item, index);
                            },
                          ),
                  ),
                  _buildInputBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(ShoppingItem item, int index) {
    return Container(
      key: ValueKey(item.id),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12, width: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        dense: true,
        title: GestureDetector(
          onTap: () => context.read<ShoppingProvider>().toggleItemDone(item.id),
          child: Text.rich(
            TextSpan(
              children: [
                if (item.quantity.isNotEmpty)
                  TextSpan(text: '${item.quantity} '),
                TextSpan(text: item.name),
              ],
              style: TextStyle(
                fontSize: 18,
                decoration: item.isDone ? TextDecoration.lineThrough : null,
                decorationColor: Colors.red,
                color: Colors.black,
                fontWeight: item.isDone ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsArea() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      color: Colors.white,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            dense: true,
            title: Text(suggestion),
            onTap: () {
              _productController.text = suggestion;
              _addItem();
              _productFocus.requestFocus();
            },
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            top: 8,
            left: 8,
            right: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_suggestions.isNotEmpty) _buildSuggestionsArea(),
              Row(
                children: [
                  // Quantity field (e.g., "2" or "1kg")
                  Container(
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        hintText: 'Anzahl',
                        hintStyle: TextStyle(color: Colors.black26),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      keyboardType: TextInputType.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _productController,
                        focusNode: _productFocus,
                        onSubmitted: (_) => _addItem(),
                        decoration: const InputDecoration(
                          hintText: 'Artikel...',
                          hintStyle: TextStyle(color: Colors.black26),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Add button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _addItem,
                    child: const Icon(
                      CupertinoIcons.add_circled_solid,
                      size: 32,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/shopping_provider.dart';
// import 'models/shopping_models.dart';

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
      setState(() {
        _suggestions = provider.itemHistory
            .where((item) => item.toLowerCase().contains(text))
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
    if (name.isNotEmpty) {
      context.read<ShoppingProvider>().addItem(name, quantity);
      _productController.clear();
      _quantityController.clear();
      _productFocus.requestFocus(); // Keep focus
    }
  }

  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
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
              // Add new list functionality could go here
              Navigator.pop(context);
            },
            child: const Text('Zusätzliche Einkaufsliste'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              context.read<ShoppingProvider>().toggleInputMode();
              Navigator.pop(context);
            },
            child: Text(
              context.read<ShoppingProvider>().isInputDisabled
                  ? 'Eingabemodus aktivieren'
                  : 'Nur Anzeige-Modus',
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Teilen'),
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: () => _showActionSheet(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/app_icon.png', height: 28),
            const SizedBox(width: 8),
            Text(currentList?.name ?? 'Einkaufszettel'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Finish shopping or similar action
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (!provider.isInputDisabled) _buildInputBar(),
              Expanded(
                child: currentList == null || currentList.items.isEmpty
                    ? const Center(child: Text('Liste ist leer'))
                    : ReorderableListView.builder(
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
                          return Container(
                            key: ValueKey(item.id),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.black12,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              dense: true,
                              title: GestureDetector(
                                onTap: () => provider.toggleItemDone(item.id),
                                child: Row(
                                  children: [
                                    if (item.quantity.isNotEmpty)
                                      Text(
                                        '${item.quantity} ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: item.isDone
                                              ? Colors.red
                                              : Colors.black,
                                          decoration: item.isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                          fontWeight: item.isDone
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          decoration: item.isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: item.isDone
                                              ? Colors.red
                                              : Colors.black,
                                          fontWeight: item.isDone
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: ReorderableDragStartListener(
                                index: index,
                                child: const Icon(
                                  Icons.menu,
                                  color: Colors.black26,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_suggestions.isNotEmpty && !provider.isInputDisabled)
            _buildSuggestionsOverlay(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    return Positioned(
      top: 60, // Positioned below the input bar (which is at the top)
      left: 8,
      right: 8,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              return ListTile(
                title: Text(suggestion),
                onTap: () {
                  _productController.text = suggestion;
                  _addItem();
                  _productFocus.requestFocus(); // Ensure focus remains
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
        top: 8,
        left: 8,
        right: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Colors.black12, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              onTap: _addItem,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.add, size: 20, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 70,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(4),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'x',
              style: TextStyle(color: Colors.black26, fontSize: 18),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: _productController,
                focusNode: _productFocus,
                decoration: const InputDecoration(
                  hintText: 'Produkt',
                  hintStyle: TextStyle(color: Colors.black26),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 16),
                onSubmitted: (_) => _addItem(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

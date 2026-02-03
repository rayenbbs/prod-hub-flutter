import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'models/quote.dart';
import 'services/quote_service.dart';

class QuoteGeneratorScreen extends StatefulWidget {
  const QuoteGeneratorScreen({super.key});

  @override
  State<QuoteGeneratorScreen> createState() => _QuoteGeneratorScreenState();
}

class _QuoteGeneratorScreenState extends State<QuoteGeneratorScreen> {
  final QuoteService _quoteService = QuoteService();
  final FlutterTts _flutterTts = FlutterTts();

  List<Quote> _allQuotes = [];
  List<Quote> _filteredQuotes = [];
  List<String> _categories = [];

  Quote? _currentQuote;
  String _selectedCategory = 'All';
  int _clickCount = 0;
  bool _isAutoPlay = false;
  bool _showAddQuoteForm = false;
  bool _canAddQuote = false;
  Timer? _autoPlayTimer;

  // Form controllers
  final TextEditingController _quoteTextController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _loadQuotes();

    // Add listener to update button state
    _quoteTextController.addListener(() {
      setState(() {
        _canAddQuote = _quoteTextController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _quoteTextController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _initializeTts() async {
    if (!kIsWeb) {
      try {
        await _flutterTts.setLanguage("en-US");
        await _flutterTts.setSpeechRate(0.85);
        await _flutterTts.setPitch(1.05);
      } catch (e) {
        print('TTS initialization failed: $e');
      }
    }
  }

  Future<void> _loadQuotes() async {
    await _quoteService.initializeDefaultQuotes();
    final quotes = await _quoteService.getAllQuotes();
    final categories = await _quoteService.getCategories();

    setState(() {
      _allQuotes = quotes;
      _filteredQuotes = quotes;
      _categories = categories;
      if (quotes.isNotEmpty) {
        _currentQuote = quotes.first;
      }
    });
  }

  Future<void> _refreshQuotes() async {
    final quotes = await _quoteService.getAllQuotes();
    final categories = await _quoteService.getCategories();

    setState(() {
      _allQuotes = quotes;
      _filterQuotes();
      _categories = categories;
    });
  }

  void _filterQuotes() {
    if (_selectedCategory == 'All') {
      _filteredQuotes = List.from(_allQuotes);
    } else {
      _filteredQuotes = _allQuotes.where((q) => q.category == _selectedCategory).toList();
    }
  }

  void _generateNewQuote() {
    if (_allQuotes.isEmpty) return;

    setState(() {
      _clickCount++;
      Quote newQuote;
      do {
        final randomIndex = (_allQuotes.length * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000).floor();
        newQuote = _allQuotes[randomIndex % _allQuotes.length];
      } while (newQuote.id == _currentQuote?.id && _allQuotes.length > 1);

      _currentQuote = newQuote;
      _selectedCategory = newQuote.category;
      _filterQuotes();
    });
  }

  void _nextQuote() {
    if (_filteredQuotes.isEmpty) return;

    final currentIndex = _filteredQuotes.indexWhere((q) => q.id == _currentQuote?.id);
    final nextIndex = (currentIndex + 1) % _filteredQuotes.length;

    setState(() {
      _currentQuote = _filteredQuotes[nextIndex];
      _clickCount++;
    });
  }

  void _previousQuote() {
    if (_filteredQuotes.isEmpty) return;

    final currentIndex = _filteredQuotes.indexWhere((q) => q.id == _currentQuote?.id);
    final previousIndex = (currentIndex - 1 + _filteredQuotes.length) % _filteredQuotes.length;

    setState(() {
      _currentQuote = _filteredQuotes[previousIndex];
      _clickCount++;
    });
  }

  void _toggleAutoPlay() {
    setState(() {
      _isAutoPlay = !_isAutoPlay;
    });

    if (_isAutoPlay) {
      _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _generateNewQuote();
      });
    } else {
      _autoPlayTimer?.cancel();
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentQuote?.id == null) return;
    await _quoteService.toggleFavorite(_currentQuote!.id!);
    await _refreshQuotes();

    // Update current quote
    final updatedQuote = _allQuotes.firstWhere((q) => q.id == _currentQuote!.id);
    setState(() {
      _currentQuote = updatedQuote;
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filterQuotes();
      if (_filteredQuotes.isNotEmpty) {
        _currentQuote = _filteredQuotes.first;
      }
    });
  }

  Future<void> _copyToClipboard() async {
    if (_currentQuote == null) return;
    final text = '"${_currentQuote!.text}" - ${_currentQuote!.author}';
    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('📋 Copied to clipboard!')),
      );
    }
  }

  Future<void> _readQuote() async {
    if (_currentQuote == null) return;

    if (kIsWeb) {
      // TTS is not supported on web
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔊 Text-to-Speech is only available on mobile devices. Please test on Android/iOS!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      final text = '${_currentQuote!.text}. By ${_currentQuote!.author}';
      await _flutterTts.speak(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read quote: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareOnFacebook() async {
    if (_currentQuote == null) return;
    final text = Uri.encodeComponent('"${_currentQuote!.text}" - ${_currentQuote!.author}');
    final url = Uri.parse('https://www.facebook.com/sharer/sharer.php?u=&quote=$text');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareOnTwitter() async {
    if (_currentQuote == null) return;
    final text = Uri.encodeComponent('"${_currentQuote!.text}" - ${_currentQuote!.author}');
    final url = Uri.parse('https://twitter.com/intent/tweet?text=$text');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }


  void _toggleAddQuoteForm() {
    setState(() {
      _showAddQuoteForm = !_showAddQuoteForm;
      if (!_showAddQuoteForm) {
        _quoteTextController.clear();
        _authorController.clear();
        _categoryController.clear();
        _canAddQuote = false;
      }
    });
  }

  Future<void> _addCustomQuote() async {
    final text = _quoteTextController.text.trim();
    if (text.isEmpty) return;

    final newQuote = Quote(
      text: text,
      author: _authorController.text.trim().isEmpty ? 'Anonymous' : _authorController.text.trim(),
      category: _categoryController.text.trim().isEmpty ? 'Custom' : _categoryController.text.trim(),
    );

    await _quoteService.addQuote(newQuote);
    await _refreshQuotes();

    // Set current quote to the newly added quote
    final addedQuote = _allQuotes.last;
    setState(() {
      _currentQuote = addedQuote;
    });

    _toggleAddQuoteForm();
  }

  Future<void> _deleteQuote() async {
    if (_currentQuote?.id == null || _allQuotes.length <= 1) return;

    await _quoteService.deleteQuote(_currentQuote!.id!);
    await _refreshQuotes();

    // Find next quote
    if (_filteredQuotes.isNotEmpty) {
      setState(() {
        _currentQuote = _filteredQuotes.first;
      });
    } else if (_allQuotes.isNotEmpty) {
      setState(() {
        _currentQuote = _allQuotes.first;
        _selectedCategory = 'All';
        _filterQuotes();
      });
    }
  }

  int get _currentQuoteNumber {
    if (_currentQuote == null || _filteredQuotes.isEmpty) return 0;
    return _filteredQuotes.indexWhere((q) => q.id == _currentQuote!.id) + 1;
  }

  int get _favoriteCount => _allQuotes.where((q) => q.isFavorite).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Generator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8b9dc3), // #8b9dc3
              Color(0xFF9a8ab4), // #9a8ab4
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stats Bar
              _buildStatsBar(),
              const SizedBox(height: 16),

              // Header
              _buildHeader(),
              const SizedBox(height: 16),

              // Category Filter
              _buildCategoryFilter(),
              const SizedBox(height: 16),

              // Quote Container
              _buildQuoteContainer(),
              const SizedBox(height: 16),

              // Navigation Controls
              _buildNavigationControls(),
              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(),
              const SizedBox(height: 16),

              // Add Quote Form
              if (_showAddQuoteForm) _buildAddQuoteForm(),

              // Favorites Count
              if (_favoriteCount > 0) _buildFavoritesCount(),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                'CLICKS:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
              Text(
                '$_clickCount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier New',
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                'QUOTE:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
              Text(
                '$_currentQuoteNumber/${_allQuotes.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier New',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '💡 Daily Motivation',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            IconButton(
              onPressed: _toggleAutoPlay,
              icon: Text(_isAutoPlay ? '⏸️' : '▶️', style: const TextStyle(fontSize: 20)),
              tooltip: 'Toggle Auto-play',
            ),
            IconButton(
              onPressed: _toggleFavorite,
              icon: Text(
                _currentQuote?.isFavorite ?? false ? '❤️' : '🤍',
                style: const TextStyle(fontSize: 20),
              ),
              tooltip: 'Toggle Favorite',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category;
          return ElevatedButton(
            onPressed: () => _selectCategory(category),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              foregroundColor: Colors.black87,
              side: BorderSide(
                color: isSelected
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white.withOpacity(0.2),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: isSelected ? 4 : 0,
            ),
            child: Text(
              category,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuoteContainer() {
    if (_currentQuote == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        ),
        child: const Center(
          child: Text(
            'No quotes available',
            style: TextStyle(color: Colors.black87),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
      ),
      child: Column(
        children: [
          Opacity(
            opacity: 0.2,
            child: Text(
              '❝',
              style: TextStyle(fontSize: 64, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentQuote!.text,
            style: const TextStyle(
              fontSize: 24,
              fontStyle: FontStyle.italic,
              height: 1.6,
              color: Colors.black87,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              Text(
                '— ${_currentQuote!.author}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '#${_currentQuote!.category}',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_selectedCategory == 'All')
          IconButton(
            onPressed: _previousQuote,
            icon: const Text('◀️', style: TextStyle(fontSize: 24)),
            tooltip: 'Previous Quote',
          ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _generateNewQuote,
          icon: const Text('🔄'),
          label: const Text('Random Quote'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        const SizedBox(width: 8),
        if (_selectedCategory == 'All')
          IconButton(
            onPressed: _nextQuote,
            icon: const Text('▶️', style: TextStyle(fontSize: 24)),
            tooltip: 'Next Quote',
          ),
        IconButton(
          onPressed: _deleteQuote,
          icon: const Text('🗑️', style: TextStyle(fontSize: 24)),
          tooltip: 'Delete This Quote',
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Text('📋'),
                label: const Text('Copy'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _readQuote,
                icon: const Text('🔊'),
                label: const Text('Read'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareOnFacebook,
                icon: const Text('📘'),
                label: const Text('Facebook'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareOnTwitter,
                icon: const Text('🐦'),
                label: const Text('Twitter'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[400]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _toggleAddQuoteForm,
          icon: const Text('➕'),
          label: const Text('Add Quote'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  Widget _buildAddQuoteForm() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '✨ Add Your Own Quote',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quoteTextController,
              decoration: const InputDecoration(
                labelText: 'Quote Text *',
                hintText: 'Enter your inspiring quote...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author',
                hintText: 'Author name (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g., Motivation, Success (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _toggleAddQuoteForm,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canAddQuote ? _addCustomQuote : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Quote'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesCount() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: Text(
          '⭐ $_favoriteCount favorite${_favoriteCount != 1 ? 's' : ''}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

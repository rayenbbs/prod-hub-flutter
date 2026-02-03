import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quote.dart';

class QuoteService {
  static const String _quotesKey = 'quotes';

  // Default quotes matching the Angular version
  static final List<Quote> _defaultQuotes = [
    Quote(id: '1', text: "The only way to do great work is to love what you do.", author: "Steve Jobs", category: "Work"),
    Quote(id: '2', text: "Believe you can and you're halfway there.", author: "Theodore Roosevelt", category: "Belief"),
    Quote(id: '3', text: "Success is not final, failure is not fatal: it is the courage to continue that counts.", author: "Winston Churchill", category: "Success"),
    Quote(id: '4', text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt", category: "Dreams"),
    Quote(id: '5', text: "It does not matter how slowly you go as long as you do not stop.", author: "Confucius", category: "Persistence"),
    Quote(id: '6', text: "Everything you've ever wanted is on the other side of fear.", author: "George Addair", category: "Fear"),
    Quote(id: '7', text: "Believe in yourself. You are braver than you think, more talented than you know, and capable of more than you imagine.", author: "Roy T. Bennett", category: "Self-belief"),
    Quote(id: '8', text: "I learned that courage was not the absence of fear, but the triumph over it.", author: "Nelson Mandela", category: "Courage"),
    Quote(id: '9', text: "The only impossible journey is the one you never begin.", author: "Tony Robbins", category: "Beginning"),
    Quote(id: '10', text: "Your limitation—it's only your imagination.", author: "Unknown", category: "Imagination"),
    Quote(id: '11', text: "Push yourself, because no one else is going to do it for you.", author: "Unknown", category: "Motivation"),
    Quote(id: '12', text: "Great things never come from comfort zones.", author: "Unknown", category: "Growth"),
    Quote(id: '13', text: "Dream it. Wish it. Do it.", author: "Unknown", category: "Action"),
    Quote(id: '14', text: "Success doesn't just find you. You have to go out and get it.", author: "Unknown", category: "Success"),
    Quote(id: '15', text: "The harder you work for something, the greater you'll feel when you achieve it.", author: "Unknown", category: "Achievement"),
    Quote(id: '16', text: "Dream bigger. Do bigger.", author: "Unknown", category: "Dreams"),
    Quote(id: '17', text: "Don't stop when you're tired. Stop when you're done.", author: "Unknown", category: "Persistence"),
    Quote(id: '18', text: "Wake up with determination. Go to bed with satisfaction.", author: "Unknown", category: "Dedication"),
    Quote(id: '19', text: "Do something today that your future self will thank you for.", author: "Unknown", category: "Action"),
    Quote(id: '20', text: "Little things make big days.", author: "Unknown", category: "Gratitude"),
  ];

  // Get all quotes
  Future<List<Quote>> getAllQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? quotesJson = prefs.getString(_quotesKey);

    if (quotesJson == null || quotesJson.isEmpty) {
      return [];
    }

    final List<dynamic> decoded = json.decode(quotesJson);
    return decoded.map((json) => Quote.fromJson(json)).toList();
  }

  // Save quotes
  Future<void> _saveQuotes(List<Quote> quotes) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(quotes.map((q) => q.toJson()).toList());
    await prefs.setString(_quotesKey, encoded);
  }

  // Initialize default quotes if empty
  Future<void> initializeDefaultQuotes() async {
    final quotes = await getAllQuotes();
    if (quotes.isEmpty) {
      await _saveQuotes(_defaultQuotes);
    }
  }

  // Add a quote
  Future<void> addQuote(Quote quote) async {
    final quotes = await getAllQuotes();
    final newQuote = quote.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    quotes.add(newQuote);
    await _saveQuotes(quotes);
  }

  // Update a quote
  Future<void> updateQuote(String id, Quote updatedQuote) async {
    final quotes = await getAllQuotes();
    final index = quotes.indexWhere((q) => q.id == id);
    if (index != -1) {
      quotes[index] = updatedQuote;
      await _saveQuotes(quotes);
    }
  }

  // Delete a quote
  Future<void> deleteQuote(String id) async {
    final quotes = await getAllQuotes();
    quotes.removeWhere((q) => q.id == id);
    await _saveQuotes(quotes);
  }

  // Toggle favorite
  Future<void> toggleFavorite(String id) async {
    final quotes = await getAllQuotes();
    final index = quotes.indexWhere((q) => q.id == id);
    if (index != -1) {
      quotes[index] = quotes[index].copyWith(isFavorite: !quotes[index].isFavorite);
      await _saveQuotes(quotes);
    }
  }

  // Get quotes by category
  Future<List<Quote>> getQuotesByCategory(String category) async {
    final quotes = await getAllQuotes();
    if (category == 'All') {
      return quotes;
    }
    return quotes.where((q) => q.category == category).toList();
  }

  // Get all categories
  Future<List<String>> getCategories() async {
    final quotes = await getAllQuotes();
    final categories = quotes.map((q) => q.category).toSet().toList();
    categories.sort();
    return ['All', ...categories];
  }

  // Get favorite quotes
  Future<List<Quote>> getFavoriteQuotes() async {
    final quotes = await getAllQuotes();
    return quotes.where((q) => q.isFavorite).toList();
  }

  // Reset to default quotes
  Future<void> resetToDefaultQuotes() async {
    await _saveQuotes(_defaultQuotes);
  }
}

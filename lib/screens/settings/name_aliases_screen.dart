import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/financial_repository.dart';

class NameAliasesScreen extends StatefulWidget {
  const NameAliasesScreen({super.key});

  @override
  State<NameAliasesScreen> createState() => _NameAliasesScreenState();
}

class _NameAliasesScreenState extends State<NameAliasesScreen> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _addAlias() async {
    final text = _controller.text.trim().toUpperCase();
    if (text.isNotEmpty) {
      await context.read<FinancialRepository>().addAlias(text);
      _controller.clear();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch repository for changes
    final repo = context.watch<FinancialRepository>();
    final aliases = repo.userAliases;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Names'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add names that appear in your bank SMS when you receive money (e.g., your full name, business name, or abbreviations).\n\nThis helps the app detect "Income" transactions correctly.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Add Name (e.g. SHADIVA)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addAlias(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addAlias,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: const Text('ADD'),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Text('Your Active Name Matches:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            // List
            Expanded(
              child: aliases.isEmpty 
              ? const Center(child: Text('No custom names added yet.\nWe strictly use your App Login name by default.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                itemCount: aliases.length,
                itemBuilder: (context, index) {
                  final name = aliases[index];
                  return Card(
                    child: ListTile(
                      title: Text(name),
                      leading: const Icon(Icons.person_pin),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                           context.read<FinancialRepository>().removeAlias(name);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

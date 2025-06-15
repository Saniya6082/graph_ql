import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:ql/add_item.dart' show AddItemScreen;

class ItemListScreen extends StatelessWidget {
  final String getAllItemsQuery = """
    query GetAllItems {
      allItems{
        id
        name
        description
        createdAt
        updatedAt
      }
    }
  """;

  final String deleteItemMutation = """
    mutation DeleteItem(\$id: ID!) {
      deleteItem(id: \$id) {
        id
      }
    }
  """;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(
          'GraphQL Learning',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade400,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: Query(
        options: QueryOptions(
          document: gql(getAllItemsQuery),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
        builder: (QueryResult result, {refetch, fetchMore}) {
          print("Loading: ${result.isLoading}");
          print("HasException: ${result.hasException}");
          print("Exception: ${result.exception}");
          print("Data: ${result.data}");

          if (result.hasException) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                    const SizedBox(height: 16),
                    Text(
                      'Error Connecting to Server',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.exception.toString(),
                      style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'monospace'),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => refetch?.call(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (result.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
                  SizedBox(height: 16),
                  Text(
                    'Loading Items...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final items = result.data?['allItems'] ?? [];

          if (items.isEmpty) {
            return Stack(
              children: [
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No Items Found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the + button to add a new item',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () async {
                      final added = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddItemScreen()),
                      );
                      if (added == true && refetch != null) {
                        refetch();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Item added successfully'),
                            backgroundColor: Colors.green.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      }
                    },
                    backgroundColor: Colors.blue.shade400,
                    foregroundColor: Colors.white,
                    tooltip: 'Add New Item',
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            );
          }

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  if (refetch != null) {
                    await refetch();
                  }
                },
                color: Colors.blue.shade400,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return Mutation(
                      options: MutationOptions(
                        document: gql(deleteItemMutation),
                        onCompleted: (data) {
                          print('Delete mutation completed: $data');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Item deleted successfully'),
                              backgroundColor: Colors.green.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                          refetch?.call();
                        },
                        onError: (error) {
                          print('Delete mutation error: $error');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Delete failed: $error'),
                              backgroundColor: Colors.red.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        },
                      ),
                      builder: (runMutation, mutationResult) {
                        return AnimatedOpacity(
                          opacity: mutationResult!.isLoading ? 0.5 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                item['name'],
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              subtitle: item['description'] != null
                                  ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  item['description'],
                                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                                ),
                              )
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red.shade600),
                                    tooltip: 'Delete Item',
                                    onPressed: mutationResult.isLoading
                                        ? null
                                        : () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          title: const Text(
                                            'Confirm Delete',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          content: Text(
                                            'Are you sure you want to delete "${item['name']}"?',
                                            style: TextStyle(color: Colors.grey.shade800),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                runMutation({'id': item['id']});
                                              },
                                              child: Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red.shade600,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue.shade400),
                                    tooltip: 'Edit Item',
                                    onPressed: mutationResult.isLoading
                                        ? null
                                        : () async {
                                      final updated = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddItemScreen(
                                            id: item['id'],
                                            initialName: item['name'],
                                            initialDescription: item['description'],
                                          ),
                                        ),
                                      );
                                      if (updated == true) {
                                        refetch?.call();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text('Item updated successfully'),
                                            backgroundColor: Colors.green.shade600,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: () async {
                    final added = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddItemScreen()),
                    );
                    if (added == true && refetch != null) {
                      refetch();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Item added successfully'),
                          backgroundColor: Colors.green.shade600,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    }
                  },
                  backgroundColor: Colors.blue.shade400,
                  foregroundColor: Colors.white,
                  tooltip: 'Add New Item',
                  child: const Icon(Icons.add),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

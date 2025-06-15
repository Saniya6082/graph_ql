import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:ql/add_item.dart' show AddItemScreen;
import 'package:ql/list_screen.dart' show ItemListScreen;

void main() async {
  await initHiveForFlutter();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static const String GRAPHQL_URL = 'your url here';

  @overridex
  Widget build(BuildContext context) {
    final HttpLink httpLink = HttpLink(GRAPHQL_URL);

    ValueNotifier<GraphQLClient> client = ValueNotifier(
      GraphQLClient(
        link: httpLink,
        cache: GraphQLCache(store: HiveStore()),
      ),
    );

    return GraphQLProvider(
      client: client,
      child: MaterialApp(
        title: 'GraphQL Flutter Demo',
        home: ItemListScreen(),
      ),
    );
  }
}



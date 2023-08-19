import 'package:flutter/material.dart';
import 'package:map_module/view/MapPage.dart';
import 'package:map_module/blocs/map_bloc.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MapBloc(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Map Module',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: MapPage(),
      ),
    );
  }
}
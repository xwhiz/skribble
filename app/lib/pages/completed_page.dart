import 'package:app/models/player_model.dart';
import 'package:app/pages/home_page.dart';
import 'package:app/viewmodels/main_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CompletedPage extends StatefulWidget {
  const CompletedPage({super.key});

  @override
  State<CompletedPage> createState() => _CompletedPageState();
}

class _CompletedPageState extends State<CompletedPage> {
  @override
  void initState() {
    super.initState();

    Provider.of<MainViewModel>(context, listen: false).removeRoom();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<MainViewModel>(context);
    var players = vm.room?.players ?? [];
    players.sort((a, b) => b.score!.compareTo(a.score!));

    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Players Ranking',
              style: TextStyle(
                fontFamily: 'ComicNeue',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(179, 32, 42, 53),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final player = players[index];

                  //  A card like list style
                  return Card(
                    child: ListTile(
                      title: Text(player.username ?? ''),
                      trailing: Text(player.score.toString(),
                          style: Theme.of(context).textTheme.bodyLarge),
                      leading: index == 0
                          ? Image.asset("assets/images/crown.png")
                          : null,
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: 400,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomePage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  // ignore: deprecated_member_use
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Go to home screen",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ComicNeue', // Applying Comic Neue font
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

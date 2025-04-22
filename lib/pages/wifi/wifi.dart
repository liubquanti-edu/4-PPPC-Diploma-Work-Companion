import 'package:flutter/material.dart';
import '../../models/wifi.dart';
import '../../services/firebase_wifi.dart';
import '../../services/wifi.dart';
import 'package:card_loading/card_loading.dart';

class WiFiPage extends StatefulWidget {
  const WiFiPage({Key? key}) : super(key: key);

  @override
  _WiFiPageState createState() => _WiFiPageState();
}

class _WiFiPageState extends State<WiFiPage> {
  final WiFiFirestoreService _firestoreService = WiFiFirestoreService();
  final WiFiService _wifiService = WiFiService();
  String? _currentWiFi;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentWiFi();
  }

  Future<void> _getCurrentWiFi() async {
    setState(() => _isLoading = true);
    _currentWiFi = await _wifiService.getCurrentWiFiSSID();
    setState(() => _isLoading = false);
  }

  Future<void> _connectToWiFi(WiFiNetwork network) async {
    setState(() => _isLoading = true);
    
    final result = await _wifiService.connectToWiFi(
      network.ssid,
      network.password,
    );
    
    if (result) {
      await _getCurrentWiFi();
    } else {
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi мережі'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentWiFi,
          ),
        ],
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.wifi, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _isLoading
                        ? CardLoading(
                            height: 25,
                            width: double.infinity,
                            borderRadius: BorderRadius.circular(5),
                            cardLoadingTheme: CardLoadingTheme(
                              colorOne: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              colorTwo: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            ),
                          )
                        : Text(
                          _currentWiFi != null
                            ? 'Підключено до: $_currentWiFi'
                            : 'Немає підключення до WiFi',
                          style: const TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ),
                  ],
                ),
              ),
              const Divider(),
                Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<WiFiNetwork>>(
                    stream: _firestoreService.getWiFiNetworks(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                      return Center(
                        child: Text('Помилка: ${snapshot.error}'),
                      );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('Немає доступних WiFi мереж'),
                      );
                      }

                      return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final network = snapshot.data![index];
                        final isCurrentNetwork = _currentWiFi == network.ssid;

                        return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: Icon(
                          Icons.wifi,
                          color: isCurrentNetwork
                            ? Colors.green
                            : Colors.grey,
                          ),
                          title: Text(network.ssid),
                          trailing: isCurrentNetwork
                            ? IconButton(
                              onPressed: null,
                              icon: const Icon(Icons.check_circle),
                              style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                .colorScheme
                                .onSecondary,
                              foregroundColor: Theme.of(context)
                                .colorScheme
                                .primary,
                              ),
                            )
                            : IconButton(
                              onPressed: _isLoading
                                ? null
                                : () => _connectToWiFi(network),
                              icon: const Icon(Icons.link_rounded),
                              style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                .colorScheme
                                .onSecondary,
                              foregroundColor: Theme.of(context)
                                .colorScheme
                                .primary,
                              ),
                            ),
                        ),
                        );
                      },
                      );
                    },
                    ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
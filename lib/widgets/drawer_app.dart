import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../screens/add_cuenta_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/styles_app.dart';

class DrawerApp extends StatefulWidget {
  const DrawerApp({super.key});

  @override
  State<DrawerApp> createState() => _DrawerAppState();
}

class _DrawerAppState extends State<DrawerApp> {
  PackageInfo packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  @override
  void initState() {
    initPackageInfo();
    super.initState();
  }

  Future<void> initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => packageInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: StylesApp.backgroundScreen(context),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                primary: true,
                scrollDirection: Axis.vertical,
                children: [
                  Container(
                    padding: .symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary,
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        opacity: 0.15,
                        image: AssetImage('assets/images/logo.png'),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Nextcloud Open Client',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const Text(
                          'OPENFLOW',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w100,
                          ),
                        ),
                        const Text(
                          'Cloud workflow: Up Down Share',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                            fontWeight: FontWeight.w200,
                            color: Colors.white,
                          ),
                        ),
                        const Row(
                          mainAxisAlignment: .spaceAround,
                          children: [
                            Icon(
                              Icons.file_copy_outlined,
                              color: Colors.blueGrey,
                            ),
                            Icon(
                              Icons.folder_shared_outlined,
                              color: Colors.blueGrey,
                            ),
                            Icon(
                              Icons.article_outlined,
                              color: Colors.blueGrey,
                            ),
                            Icon(
                              Icons.photo_library_outlined,
                              color: Colors.blueGrey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.account_circle_rounded),
                    title: const Text('Add Count'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const AddCuentaScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(
                    color: Colors.white30,
                    indent: 20,
                    endIndent: 20,
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline_rounded),
                    title: const Text('Info'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.code),
                    title: const Text('About'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: .symmetric(vertical: 6),
              color: Theme.of(context).colorScheme.onPrimary,
              child: Center(
                child: Text(
                  'v.${packageInfo.version}+${packageInfo.buildNumber}',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

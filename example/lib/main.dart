import 'dart:io';
import 'dart:math';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geiger_api_connector/geiger_api_connector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  if (Platform.isWindows) {
    doWhenWindowReady(() {
      final win = appWindow;
      const initialSize = Size(417, 732);
      win.minSize = initialSize;
      win.size = initialSize;
      win.alignment = Alignment.center;
      win.title = "Custom window with Flutter";
      win.show();
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

const String montimagePluginId = 'my-plugin-id-00';
const String montimagePluginName = "Testing Plugin";

class MyHomePageState extends State<MyHomePage> {
  List<Message> events = [];
  String userData = '';
  String deviceData = '';
  bool isInProcessing = false;
  bool isMasterStarted = false;
  bool isExternalPluginStarted = false;
  String? masterOutput;
  String? pluginOutput;

  GeigerApiConnector masterApiConnector = GeigerApiConnector(
      pluginId: GeigerApi.masterId, pluginName: montimagePluginName);
  GeigerApiConnector pluginApiConnector = GeigerApiConnector(
      pluginId: montimagePluginId, pluginName: montimagePluginName);
  SensorDataModel userNodeDataModel = SensorDataModel(
    sensorId: 'mi-cyberrange-score-sensor-id',
    name: 'MI Cyberrange Score',
    description: 'This is MI Cyberrange score',
    minValue: '0',
    maxValue: '100',
    valueType: 'double',
    flag: '1',
    threatsImpact:
        '80efffaf-98a1-4e0a-8f5e-gr89388352ph,High;80efffaf-98a1-4e0a-8f5e-gr89388354sp,Hight;80efffaf-98a1-4e0a-8f5e-th89388365it,Hight;80efffaf-98a1-4e0a-8f5e-gr89388350ma,Medium;80efffaf-98a1-4e0a-8f5e-gr89388356db,Medium',
  );
  SensorDataModel deviceNodeDataModel = SensorDataModel(
    sensorId: 'mi-ksp-scanner-is-rooted-device',
    name: 'Is device rooted',
    description: 'This is device check',
    minValue: 'false',
    maxValue: 'true',
    valueType: 'boolean',
    flag: '0',
    threatsImpact:
        '80efffaf-98a1-4e0a-8f5e-gr89388352ph,High;80efffaf-98a1-4e0a-8f5e-gr89388354sp,Hight;80efffaf-98a1-4e0a-8f5e-th89388365it,Hight;80efffaf-98a1-4e0a-8f5e-gr89388350ma,Medium;80efffaf-98a1-4e0a-8f5e-gr89388356db,Medium',
  );
  RecommendationNodeModel deviceRecommendation01 = RecommendationNodeModel(
    recommendationId: 'my-recommendation-01',
    short: 'This is a short description of my recommendation 01',
    long: 'This is a long description of my description 01',
    action: 'geiger://my-recommendation/01',
    relatedThreatsWeights:
        '80efffaf-98a1-4e0a-8f5e-gr89388352ph,High;80efffaf-98a1-4e0a-8f5e-gr89388354sp,Hight;80efffaf-98a1-4e0a-8f5e-th89388365it,Hight;80efffaf-98a1-4e0a-8f5e-gr89388350ma,Medium;80efffaf-98a1-4e0a-8f5e-gr89388356db,Medium',
    costs: 'False',
    recommendationType: 'device',
  );

  RecommendationNodeModel deviceRecommendation02 = RecommendationNodeModel(
    recommendationId: 'my-recommendation-02',
    short: 'This is a short description of my recommendation 02',
    long: 'This is a long description of my description 02',
    action: 'geiger://my-recommendation/02',
    relatedThreatsWeights:
        '80efffaf-98a1-4e0a-8f5e-gr89388352ph,High;80efffaf-98a1-4e0a-8f5e-gr89388354sp,Hight;80efffaf-98a1-4e0a-8f5e-th89388365it,Hight;80efffaf-98a1-4e0a-8f5e-gr89388350ma,Medium;80efffaf-98a1-4e0a-8f5e-gr89388356db,Medium',
    costs: 'False',
    recommendationType: 'device',
  );

  // String masterExecutor = 'cybergeigertoolbox.geiger_toolbox;'
  //     'cybergeigertoolbox.geiger_toolbox.MainActivity;'
  //     'TODO';

  String masterExecutor = 'com.montimage.master;'
      'com.montimage.master.MainActivity;'
      'TODO';

  String pluginExecutor = 'com.montimage.master;'
      'com.montimage.master.MainActivity;'
      'TODO';

  Future<bool> initMasterPlugin() async {
    final bool initGeigerAPI = await masterApiConnector.connectToGeigerAPI(
        masterExecutor: masterExecutor);
    if (initGeigerAPI == false) return false;
    final bool ret = await masterApiConnector.connectToLocalStorage();
    if (ret == false) return false;
    final bool regPluginListener =
        await masterApiConnector.registerPluginListener();
    final bool regStorageListener =
        await masterApiConnector.registerStorageListener();
    isMasterStarted = true;
    return regPluginListener && regStorageListener;
  }

  Future<bool> initExternalPlugin() async {
    final bool initGeigerAPI = await pluginApiConnector.connectToGeigerAPI(
        masterExecutor: masterExecutor, pluginExecutor: pluginExecutor);
    if (initGeigerAPI == false) return false;
    bool ret = await pluginApiConnector.connectToLocalStorage();
    if (ret == false) return false;

    // Prepare some data roots
    // Prepare Devices data metrics node
    ret = await pluginApiConnector.prepareRoot([
      'Devices',
      pluginApiConnector.currentDeviceId!,
      montimagePluginId,
      'data',
      'metrics'
    ], '');
    if (ret == false) return false;
    // Prepare a recommendation node
    ret = await pluginApiConnector.prepareRoot([
      'Devices',
      pluginApiConnector.currentDeviceId!,
      montimagePluginId,
      'data',
      'recommendations'
    ], '');
    // Prepare Users data metrics node
    ret = await pluginApiConnector.prepareRoot([
      'Users',
      pluginApiConnector.currentUserId!,
      montimagePluginId,
      'data',
      'metrics'
    ], '');
    if (ret == false) return false;
    ret = await pluginApiConnector.prepareRoot([
      'Chatbot',
      'sensors',
      montimagePluginId,
    ], '');
    if (ret == false) return false;
    // write the plugin information
    ret = await pluginApiConnector.updatePluginInfo(
        montimagePluginId, 'Montimage', 'An awesome plugin');
    // Prepare some data nodes
    ret = await pluginApiConnector.addDeviceSensorNode(deviceNodeDataModel);
    if (ret == false) return false;
    ret = await pluginApiConnector.addUserSensorNode(userNodeDataModel);
    if (ret == false) return false;

    // Prepare for plugin event handler
    pluginApiConnector.addPluginEventhandler(MessageType.scanPressed,
        (Message msg) async {
      await pluginApiConnector.sendDeviceSensorData(
        deviceNodeDataModel.sensorId,
        Random().nextBool().toString(),
      );
      await pluginApiConnector.sendUserSensorData(
        userNodeDataModel.sensorId,
        Random().nextInt(100).toString(),
      );
    });
    final bool regPluginListener =
        await pluginApiConnector.registerPluginListener();

    // Prepare for storage event handler
    final bool regStorageListener = await pluginApiConnector
        .registerStorageListener(searchPath: ':Chatbot:sensors');
    isExternalPluginStarted = true;
    return regPluginListener && regStorageListener;
  }

  _showSnackBar(String message) {
    SnackBar snackBar = SnackBar(
      content: Text(message),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const TabBar(
            tabs: [
              Tab(
                icon: Icon(
                  Icons.center_focus_strong_outlined,
                ),
                text: 'GeigerToolbox',
              ),
              Tab(
                icon: Icon(Icons.extension_rounded),
                text: 'External Plugin',
              ),
            ],
          ),
        ),
        body: isInProcessing == true
            ? const Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.orange,
                ),
              )
            : TabBarView(
                children: [
                  _viewBackendView(),
                  _viewExternalPluginView(),
                ],
              ),
      ),
    );
  }

  _viewBackendView() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 5),
            const Text(
              'GeigerToolbox',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.orange),
            ),
            Text(
              '(geiger_api_connector: ${GeigerApiConnector.version})',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            !isMasterStarted
                ? Column(children: [
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          isInProcessing = true;
                        });
                        final bool masterPlugin = await initMasterPlugin();
                        if (masterPlugin == false) {
                          _showSnackBar('Failed to start Master Plugin');
                        } else {
                          _showSnackBar('The Master Plugin has been started');
                        }
                        setState(() {
                          isInProcessing = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.orange,
                        minimumSize: const Size.fromHeight(40),
                      ),
                      child: const Text('Start Master Plugin'),
                    ),
                    const Text('The Master Plugin is not intialized yet!'),
                  ])
                : Column(
                    children: [
                      const Text(
                        'Backend is running...',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.green),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool sentScanPressed = await masterApiConnector
                              .sendPluginEventType(MessageType.scanPressed);
                          if (sentScanPressed == false) {
                            _showSnackBar('Failed to send SCAN_PRESSED event');
                          } else {
                            _showSnackBar('A SCAN_PRESSED event has been sent');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Send SCAN_PRESSED'),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          final String storageStr =
                              await masterApiConnector.dumpLocalStorage(':');
                          setState(() {
                            masterOutput = storageStr;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Dump Storage'),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final String allEventStr =
                              masterApiConnector.showAllPluginEvents();
                          setState(() {
                            masterOutput = allEventStr;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Show all plugin events'),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final String allStorageStr =
                              masterApiConnector.showAllStorageEvents();
                          setState(() {
                            masterOutput = allStorageStr;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Show all storage events'),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final String? sensorData = await masterApiConnector
                              .readGeigerValueOfDeviceSensor(montimagePluginId,
                                  deviceNodeDataModel.sensorId);
                          setState(() {
                            deviceData = sensorData ?? 'null';
                            masterOutput = 'Device sensors data: $deviceData';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: Text(
                            'Show the received device sensor data ($deviceData)'),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final String? sensorData = await masterApiConnector
                              .readGeigerValueOfUserSensor(montimagePluginId,
                                  userNodeDataModel.sensorId);
                          setState(() {
                            userData = sensorData ?? 'null';
                            masterOutput = 'User sensors data: $userData';
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orange,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: Text(
                            'Show the received users sensor data ($userData)'),
                      ),
                      const Divider(),
                      const SizedBox(height: 5),
                      Text(masterOutput != null ? masterOutput! : '<output>'),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  _viewExternalPluginView() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 5),
            const Text(
              'External Plugin',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.blue),
            ),
            !isExternalPluginStarted
                ? Column(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool externalPlugin =
                              await initExternalPlugin();
                          if (externalPlugin == false) {
                            _showSnackBar('Failed to start External Plugin');
                          } else {
                            _showSnackBar(
                                'The External Plugin has been started');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Start an External Plugin'),
                      ),
                      const Text('The external plugin is not initialzed yet!'),
                    ],
                  )
                : Column(
                    children: [
                      const Text(
                        'Plugin $montimagePluginId is running...',
                        style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.green),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool dataSent =
                              await pluginApiConnector.sendDeviceSensorData(
                                  deviceNodeDataModel.sensorId, "true");
                          if (dataSent == false) {
                            _showSnackBar(
                                'Failed to send a device sensor data');
                          } else {
                            _showSnackBar('A device sensor data has been sent');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Send a device data'),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool dataSent =
                              await pluginApiConnector.sendUserSensorData(
                                  userNodeDataModel.sensorId, "50");
                          if (dataSent == false) {
                            _showSnackBar('Failed to send a user sensor data');
                          } else {
                            _showSnackBar('A user sensor data has been sent');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Send a user data'),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          // trigger/send a SCAN_COMPLETED event
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool sentData = await pluginApiConnector
                              .sendPluginEventType(MessageType.scanCompleted);
                          if (sentData == false) {
                            _showSnackBar(
                                'Failed to send SCAN_COMPLETED event');
                          } else {
                            _showSnackBar(
                                'The SCAN_COMPLETED event has been sent');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Send SCAN_COMPLETED event'),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          // trigger/send a SCAN_COMPLETED event
                          setState(() {
                            isInProcessing = true;
                          });
                          final String payload = '''{
                            "title":"A message from MI Cyberrange",
                            "message":"You should do more anti-phishing email testing",
                            "timestamp": ${DateTime.now().millisecondsSinceEpoch}
                          }''';
                          final bool sentData = await pluginApiConnector
                              .sendPluginEventWithPayload(
                                  MessageType.customEvent, payload);
                          if (sentData == false) {
                            _showSnackBar(
                                'Failed to send a message with payload');
                          } else {
                            _showSnackBar(
                                'A message with payload has been sent');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text(
                            'Send a custom event with payload (json encoded string)'),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          // trigger/send a STORAGE_EVENT event
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool sentData =
                              await pluginApiConnector.sendDataNode(
                                  'my-sensor-data',
                                  ':Chatbot:sensors:$montimagePluginId',
                                  [
                                    'category',
                                    'description',
                                    'fileFullPath',
                                    'isApplication',
                                    'isDeviceAdminThreat',
                                    'objectName',
                                    'virusName'
                                  ],
                                  [
                                    'Malware',
                                    'critical threat detected',
                                    'fileFullPath/applications/glume.apk',
                                    'true',
                                    'true',
                                    'hijack.org',
                                    'hijack'
                                  ],
                                  null);
                          if (sentData == false) {
                            _showSnackBar('Failed to send data to Chatbot');
                          } else {
                            _showSnackBar('Data has been sent to Chatbot');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Send a threat info to Chatbot'),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // trigger/send a STORAGE_EVENT event
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool sentData = await pluginApiConnector
                              .sendDeviceRecommendation(deviceRecommendation01);
                          if (sentData == false) {
                            _showSnackBar(
                                'Failed to send a device recommendation');
                          } else {
                            _showSnackBar(
                                'A Device recommendation has been sent');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Send the device recommendation 01'),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // trigger/send a STORAGE_EVENT event
                          setState(() {
                            isInProcessing = true;
                          });
                          final bool sentData = await pluginApiConnector
                              .sendDeviceRecommendation(deviceRecommendation02);
                          if (sentData == false) {
                            _showSnackBar(
                                'Failed to send a device recommendation');
                          } else {
                            _showSnackBar(
                                'A Device recommendation has been sent');
                          }
                          setState(() {
                            isInProcessing = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Send the device recommendation 02'),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          pluginApiConnector.sendDataNode(
                              'cffb567a-3d64-4204-a637-1da234ed25b0',
                              ':Global:Recommendations',
                              ['RecommendationType'],
                              ['device'],
                              null);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Change a global recommendation'),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final String allEventStr =
                              pluginApiConnector.showAllPluginEvents();
                          setState(() {
                            pluginOutput = allEventStr;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Show all plugin events'),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final String allStorageStr =
                              pluginApiConnector.showAllStorageEvents();
                          setState(() {
                            pluginOutput = allStorageStr;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Show all storage events'),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () {
                          pluginApiConnector.sendPluginEventType(
                              MessageType.returningControl);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Back to the GeigerToolbox'),
                      ),
                      const SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () async {
                          await pluginApiConnector.close();
                          setState(() {
                            isExternalPluginStarted = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: const Text('Disconnect'),
                      ),
                      const Divider(),
                      const SizedBox(height: 5),
                      Text(pluginOutput != null ? pluginOutput! : '<output>'),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

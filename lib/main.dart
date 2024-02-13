import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:connectivity/connectivity.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart' as gp;
import 'package:get/get.dart';
import 'package:location00/location00.dart';
import 'package:order_booking_shop/Tracker/trac.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'API/Globals.dart';
import 'Databases/DBHelper.dart';
import 'Views/splash_screen.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';


Future<void> main()  async {
  WidgetsFlutterBinding.ensureInitialized();
  // AndroidAlarmManager.initialize();
  // FlutterBackground.initialize(androidConfig: androidConfig);
  // FlutterBackground.enableBackgroundExecution();
  //await initializeService();
  await initializeServiceLocation();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Firebase.initializeApp();
  runApp(
      const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const SplashScreen())

  );
}

void callbackDispatcher(){
  Workmanager().executeTask((task, inputData) async {
    print("WorkManager MMM ");
    return Future.value(true);
  });
}

Future<void> initializeServiceLocation() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'MY FOREGROUND SERVICE',
    description: 'This channel is used for important notifications.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  if (Platform.isIOS || Platform.isAndroid) {
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        iOS: DarwinInitializationSettings(),
        android: AndroidInitializationSettings('ic_bg_service_small'),
      ),
    );
  }

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.setString("hello", "world");

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  LocationService locationService = LocationService();
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
      //ls.listenLocation();
    });
  }

  service.on('stopService').listen((event) async {
    locationService.stopListening();
    locationService.deleteDocument();
    Workmanager().cancelAll();
    service.stopSelf();
    //stopListeningLocation();
    FlutterLocalNotificationsPlugin().cancelAll();
  });

  Workmanager().registerPeriodicTask("1", "simpleTask", frequency: Duration(minutes: 15));

  if(isClockedIn == false){
    startTimer();
    locationService.listenLocation();
  }

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        flutterLocalNotificationsPlugin.show(
          888,
          'COOL SERVICE',
          'Awesome',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'my_foreground',
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: true,
              priority: Priority.high,
            ),
          ),
        );

        flutterLocalNotificationsPlugin.show(
          889,
          'Location',
          'Longitude ${locationService.longi} , Latitute ${locationService.lat}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'my_foreground',
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );

        service.setForegroundNotificationInfo(
          title: "My App Service",
          content: "Timer ${_formatDuration(secondsPassed.toString())}",
        );
      }
    }



    final deviceInfo = DeviceInfoPlugin();
    String? device;

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      device = androidInfo.model;
    }

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      device = iosInfo.model;
    }

    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
        "device": device,
      },
    );
  });
}

//Flutter Background

// final androidConfig = FlutterBackgroundAndroidConfig(
//   notificationTitle: "Background Tracking",
//   notificationText: "Background Notification",
//   notificationImportance: AndroidNotificationImportance.Default,
//   notificationIcon: AndroidResource(
//       name: 'background_icon',
//       defType: 'drawable'), // Default is ic_launcher from folder mipmap
// );
//

// to ensure this is executed
// run app from xcode, then from xcode menu, select Simulate Background Fetch

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final log = preferences.getStringList('log') ?? <String>[];
  log.add(DateTime.now().toIso8601String());
  await preferences.setStringList('log', log);




  return true;
}


//         // if you don't using custom notification, uncomment this
//         service.setForegroundNotificationInfo(
//           title: "My App Service",
//           content: "Updated at backgroundTask()",
//         );
//       }
//     }
//
//     /// you can see this log in logcat
//     print('FLUTTER BACKGROUND SERVICE: backgroundTask()');
//
//
String _formatDuration(String secondsString) {
  int seconds = int.parse(secondsString);
  Duration duration = Duration(seconds: seconds);
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String hours = twoDigits(duration.inHours);
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String secondsFormatted = twoDigits(duration.inSeconds.remainder(60));
  return '$hours:$minutes:$secondsFormatted';
}


Future<bool> isInternetConnected() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  bool isConnected = connectivityResult == ConnectivityResult.mobile ||
      connectivityResult == ConnectivityResult.wifi;

  print('Internet Connected: $isConnected');

  return isConnected;
}


Future<void> backgroundTask() async {
  try {
    bool isConnected = await isInternetConnected();

    if (isConnected) {
      print('Internet connection is available. Initiating background data synchronization.');
      await synchronizeData();
      print('Background data synchronization completed.');
    } else {
      print('No internet connection available. Skipping background data synchronization.');
    }
  } catch (e) {
    print('Error in backgroundTask: $e');
  }
}

Future<void> synchronizeData() async {
  print('Synchronizing data in the background.');

  await postAttendanceTable();
  await postAttendanceOutTable();
  await postShopTable();
  await postShopVisitData();
  await postStockCheckItems();
  await postMasterTable();
  await postOrderDetails();
  await postReturnFormTable();
  await postReturnFormDetails();
  await postRecoveryFormTable();
  //await databaseoutputs();
}

// Future<void> databaseoutputs() async {
//   DatabaseOutputs dbHelper = DatabaseOutputs();
//   await dbHelper.checkFirstRun();
// }
Future<void> postShopVisitData() async {
  DBHelper dbHelper = DBHelper();
  await dbHelper.postShopVisitData();
}
// Future<void> _startTimer() async {
//   HomePage dbHelper = HomePage();
//   await dbHelper._startTimer();
// }


Future<void> postStockCheckItems() async {
  DBHelper dbHelper = DBHelper();
  await dbHelper.postStockCheckItems();
}

Future<void> postAttendanceOutTable() async {
  DBHelper dbHelper = DBHelper();
  await dbHelper.postAttendanceOutTable();
}

Future<void> postAttendanceTable() async {
  DBHelper dbHelper = DBHelper();
  await dbHelper.postAttendanceTable();
}

Future<void> postMasterTable() async {
  DBHelper dbHelper = DBHelper();
  await dbHelper.postMasterTable();
}

Future<void> postOrderDetails() async {
  DBHelper dbHelper = DBHelper();
  await dbHelper.postOrderDetails();
}

Future<void> postShopTable() async {
  DBHelper dbHelper = DBHelper();
  await dbHelper.postShopTable();
}

Future<void> postReturnFormTable() async {
  print('Attempting to post Return data');
  DBHelper dbHelper = DBHelper();
  await dbHelper.postReturnFormTable();
  print('Return data posted successfully');
}

Future<void> postReturnFormDetails() async {
  DBHelper dbHelper = DBHelper();
  await dbHelper.postReturnFormDetails();
}

Future<void> postRecoveryFormTable() async {
  DBHelper dbHelper = DBHelper();
  await dbHelper.postRecoveryFormTable();
}
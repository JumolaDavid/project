import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info/package_info.dart';
import 'package:new_app/assembly/bloc/authentication.dart';
import 'package:new_app/assembly/bloc/location_permission.dart';
import 'package:new_app/assembly/bloc/location_tracking/bloc.dart';
import 'package:new_app/assembly/infrastructure/authentication/metadata.dart';
import 'package:new_app/assembly/infrastructure/storage/factory.dart';
import 'package:new_app/backbone/exception.dart';
import 'package:new_app/network/http/client.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  connectionStatus.initialize();
  LocalNotificationService localNotificationService = LocalNotificationService.getInstance();
  await localNotificationService.initialize();
  
  
  runZoned(
    () async {
      await SystemChrome.setPreferredOrientations(
          <DeviceOrientation>[DeviceOrientation.portraitUp]);
      final PublishSubject<String> tokenSubject = PublishSubject<String>();
      final PublishSubject<DocumentedException> globalExceptionSubject =
          PublishSubject<DocumentedException>();
      final KeyValueStorage storage = await KeyValueStorageFactory().create();
      final AuthMetadata authMetadata =
          AuthMetadataFactory().create(tokenSubject.sink, storage);
      HttpClient httpClient;
      AuthBloc authBloc;
      final String token = await authMetadata.getToken();
      final bool isProduction = await authMetadata.isProduction();
      if (token == null) {
        httpClient = HttpClientFactory(isProduction)
            .unauthenticated(globalExceptionSubject.sink);
        authBloc = AuthBlocFactory().create(
          httpClient,
          authMetadata,
          isAuthenticated: false,
          storage: storage,
        );
      } else {
        httpClient = HttpClientFactory(isProduction)
            .authenticated(token, globalExceptionSubject.sink);
        authBloc = AuthBlocFactory().create(
          httpClient,
          authMetadata,
          isAuthenticated: true,
          storage: storage,
        );
      }

      final ConnectivityBloc connectivityBloc = ConnectivityBloc();
      final LocationPermissionBloc locationPermissionBloc =
          LocationPermissionBlocFactory().create();
      final EmergencyPageDisplayingController emergencyPageState =
          EmergencyPageDisplayingController(false);
      final FlutterLocalNotificationsPlugin notificationsPlugin =
          FlutterLocalNotificationsPlugin();
      PackageInfo packageInfo;
      try {
        packageInfo = await PackageInfo.fromPlatform();
      } on Object catch (e, st) {
        FirebaseCrashlytics.instance.recordError(e, st);
      }
      runApp(
        new_appNavigatorApp(
          locationPermissionBloc: locationPermissionBloc,
          emergencyPageState: emergencyPageState,
          storage: storage,
          notificationsPlugin: notificationsPlugin,
          packageInfo: packageInfo,
        ),
      );
    },
    onError: FirebaseCrashlytics.instance.recordError,
  );
}

class new_appNavigatorApp extends StatefulWidget {
  final HttpClient httpClient;
  final AuthMetadata authMetadata;
  final AuthBloc authBloc;
  final LocationTrackingBloc locationTrackingBloc;
  final FirebaseMessaging firebaseMessaging;
  final Subject<String> tokenSubject;
  final PublishSubject<DocumentedException> globalExceptionSubject;
  final PushNotificationsStreamController pushNotificationsSC;
  final FcmTokenSendingService fcmTokenService;
  final ConnectivityBloc connectivityBloc;
  final LocationPermissionBloc locationPermissionBloc;
  final EmergencyPageDisplayingController emergencyPageState;
  final KeyValueStorage storage;
  final FlutterLocalNotificationsPlugin notificationsPlugin;
  final PackageInfo packageInfo;

  const new_appNavigatorApp({
    @required this.httpCli ent,
    @required this.authMetadata,
    @required this.authBloc,
    @required this.locationTrackingBloc,
    @required this.firebaseMessaging,
    @required this.tokenSubject,
    @required this.globalExceptionSubject,
    @required this.pushNotificationsSC,
    @required this.fcmTokenService,
    @required this.connectivityBloc,
    @required this.locationPermissionBloc,
    @required this.emergencyPageState,
    @required this.storage,
    @required this.notificationsPlugin,
    @required this.packageInfo,
    Key key,
  }) : super(key: key);

  @override
  _new_appNavigatorAppState createState() => _new_appNavigatorAppState(
      httpClient, authBloc, locationTrackingBloc, fcmTokenService);
}

class _new_appNavigatorAppState extends State<new_appNavigatorApp> {
  Widget _firstPage = SplashPage();
  HttpClient _httpClient;
  AuthBloc _authBloc;
  LocationTrackingBloc _locationTrackingBloc;
  FcmTokenSendingService _fcmTokenService;

  _new_appNavigatorAppState(
    this._httpClient,
    this._authBloc,
    this._locationTrackingBloc,
    this._fcmTokenService,
  );

  @override
  void initState() {
    super.initState();
    _subscribeOnTokenSubject();
  
  }

  void _subscribeOnTokenSubject() {
    widget.tokenSubject.listen((String token) async {
      final bool isProduction = await widget.authMetadata.isProduction();
      setState(() {
        _httpClient = HttpClientFactory(isProduction)
            .authenticated(token, widget.globalExceptionSubject.sink);
        _authBloc = AuthBlocFactory().create(_httpClient, widget.authMetadata,
            isAuthenticated: true, storage: widget.storage);
        _locationTrackingBloc = LocationTrackingBlocFactory()
            .create(_httpClient, _authBloc, widget.storage);
        _fcmTokenService = HttpFcmTokenSendingService(_httpClient);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <Provider<dynamic>>[
        Provider<HttpClient>.value(value: _httpClient),
        Provider<AuthMetadata>.value(value: widget.authMetadata),
        Provider<AuthBloc>.value(value: _authBloc),
        Provider<InvalidTokenExceptionStream>.value(
          value: InvalidTokenExceptionStream(widget.globalExceptionSubject),
        ),
        Provider<LocationTrackingBloc>.value(value: _locationTrackingBloc),
        Provider<FirebaseMessaging>.value(value: widget.firebaseMessaging),
        Provider<PushNotificationsStreamController>.value(
            value: widget.pushNotificationsSC),
        Provider<FcmTokenSendingService>.value(value: _fcmTokenService),
        Provider<ConnectivityBloc>.value(value: widget.connectivityBloc),
        Provider<LocationPermissionBloc>.value(
          value: widget.locationPermissionBloc,
        ),
        Provider<EmergencyPageDisplayingController>.value(
            value: widget.emergencyPageState),
        Provider<KeyValueStorage>.value(value: widget.storage),
        Provider<InternetConnectionExceptionStream>.value(
          value: InternetConnectionExceptionStream(
            widget.globalExceptionSubject,
          ),
        ),
        Provider<FlutterLocalNotificationsPlugin>.value(
          value: widget.notificationsPlugin,
        ),
        Provider<PackageInfo>.value(value: widget.packageInfo),
      ],
      child: _buildMaterialApp(),
    );
  }

  Widget _buildMaterialApp() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'New_app',
      theme: ThemeData(
        primaryColor: new_appColorPalette.blue,
      ),
      home: _firstPage,
      routes: <String, WidgetBuilder>{
        '/emergency': (BuildContext context) => EmergencyPage(),
      },
    );
  }
}

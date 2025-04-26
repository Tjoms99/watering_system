import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

// Base UUID for our custom service
const String wateringServiceUuid = 'DEAD0000-C634-45D2-A209-C636967B81B2';

// Characteristic UUIDs
const String modeCharUuid = 'DEAD0001-C634-45D2-A209-C636967B81B2';
const String intervalCharUuid = 'DEAD0002-C634-45D2-A209-C636967B81B2';
const String amountCharUuid = 'DEAD0003-C634-45D2-A209-C636967B81B2';
const String waterNowCharUuid = 'DEAD0004-C634-45D2-A209-C636967B81B2';
const String statusCharUuid = 'DEAD0005-C634-45D2-A209-C636967B81B2';
const String lastWateredCharUuid = 'DEAD0006-C634-45D2-A209-C636967B81B2';
const String nextWateringCharUuid = 'DEAD0007-C634-45D2-A209-C636967B81B2';

// Device name prefix for scanning
const String DEVICE_NAME_PREFIX = 'Watering Service';

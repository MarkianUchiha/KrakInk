// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/error_handlers.dart';

void main() {
  // Todo (binding + runApp) dentro de la misma zona para evitar el aviso
  // "Zone mismatch" de Flutter.
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    installErrorHandlers();
    runApp(const InklusApp());
  }, recordZoneError);
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/core/config/feature_flags.dart';
import 'package:equipment_form_app/core/equipment_model/label.dart';
import 'package:equipment_form_app/data/models/session.dart';
import 'package:equipment_form_app/features/session/domain/session_models.dart';
import 'package:equipment_form_app/features/session/view/widgets/equipment_header_title.dart';
import 'package:equipment_form_app/features/session/view/widgets/equipment_row_simulator.dart';

void main() {
  testWidgets('EquipmentRowSimulator renders legacy label when flag OFF',
      (tester) async {
    await FeatureFlagsOverride.runWith(
      normalizedEquipmentModel: false,
      run: () async {
        final device = PrimaryDeviceState(
          id: 'd1',
          type: PrimaryDeviceType.laptop,
          makeModel: '7420',
          accessories: const [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EquipmentRowSimulator(
                devices: [device],
                formType: FormType.received,
                workflow: WorkflowSessionState(
                  formType: FormType.received,
                  location: LocationCode.acc,
                ),
              ),
            ),
          ),
        );

        expect(find.textContaining('DELL LATITUDE 7420'), findsOneWidget);
      },
    );
  });

  testWidgets('EquipmentRowSimulator renders structured label when flag ON',
      (tester) async {
    await FeatureFlagsOverride.runWith(
      normalizedEquipmentModel: true,
      run: () async {
        final device = PrimaryDeviceState(
          id: 'd1',
          type: PrimaryDeviceType.laptop,
          makeModel: '7420',
          accessories: const [],
        );

        final label = EquipmentLabel(
          make: 'HP',
          family: 'EliteBook',
          modelNumber: '840 G5',
          rawMakeModel: '840 G5',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EquipmentRowSimulator(
                devices: [device],
                formType: FormType.received,
                workflow: WorkflowSessionState(
                  formType: FormType.received,
                  location: LocationCode.acc,
                ),
                labelResolver: (_) => label,
              ),
            ),
          ),
        );

        expect(find.text('HP ELITEBOOK 840 G5'), findsOneWidget);
      },
    );
  });

  testWidgets('EquipmentHeaderTitle shows legacy label when flag OFF',
      (tester) async {
    await FeatureFlagsOverride.runWith(
      normalizedEquipmentModel: false,
      run: () async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EquipmentHeaderTitle(
                type: PrimaryDeviceType.laptop,
                fallbackLabel: 'DELL LATITUDE 7420',
                structuredLabel: EquipmentLabel(
                  make: 'HP',
                  family: 'EliteBook',
                  modelNumber: '840 G5',
                  rawMakeModel: '840 G5',
                ),
              ),
            ),
          ),
        );

        expect(find.text('Laptop DELL LATITUDE 7420'), findsOneWidget);
      },
    );
  });

  testWidgets('EquipmentHeaderTitle uses structured label when flag ON',
      (tester) async {
    await FeatureFlagsOverride.runWith(
      normalizedEquipmentModel: true,
      run: () async {
        final structured = EquipmentLabel(
          make: 'Lenovo',
          family: 'ThinkPad',
          modelNumber: 'T480',
          rawMakeModel: '7420',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EquipmentHeaderTitle(
                type: PrimaryDeviceType.laptop,
                fallbackLabel: 'DELL LATITUDE 7420',
                structuredLabel: structured,
              ),
            ),
          ),
        );

        expect(find.text('Laptop LENOVO THINKPAD T480'), findsOneWidget);
      },
    );
  });
}

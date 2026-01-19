import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ddns_updater/services/ddns_service.dart';
import 'package:ddns_updater/services/ip_service.dart';
import 'package:ddns_updater/services/ddns_providers/ddns_provider.dart';
import 'package:ddns_updater/models/ddns_config.dart';
import 'package:flutter/services.dart';

@GenerateMocks([IpService, DDNSProvider])
import 'ddns_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockIpService mockIpService;
  late MockDDNSProvider mockProvider;

  // Ideally we would test DDNSService instance methods, but most logic is in the static _smartUpdateLogic.
  // Since _smartUpdateLogic is private, we can test it via performUpdate OR backgroundUpdate.
  // However, performUpdate updates WidgetService which might fail in test env (home_widget dependency).
  // backgroundUpdate also updates WidgetService.
  // We might need to mock WidgetService too or test the public methods and hope WidgetService handle errors gracefully or is mockable.
  // WidgetService has static methods. This is hard to mock with Mockito.
  // Let's rely on backgroundUpdate returning a result we can inspect, and hope WidgetService calls don't crash.
  // WidgetService.updateWidget uses HomeWidget.saveWidgetData which uses MethodChannel.
  // We can setMethodCallHandler for channel? Or just skip if possible.

  // A better approach: expose _smartUpdateLogic as package-private or visibleForTesting?
  // Or just run it and see. MethodChannels usually return null in tests unless mocked.

  setUp(() {
    mockIpService = MockIpService();
    mockProvider = MockDDNSProvider();

    const MethodChannel('home_widget').setMockMethodCallHandler((
      MethodCall methodCall,
    ) async {
      return null;
    });
  });

  group('DDNSService Tests', () {
    final config = DDNSConfig(
      id: '1',
      domain: 'test.duckdns.org',
      token: 'token',
      provider: 'DuckDNS',
      logs: [],
    );

    test('backgroundUpdate performs update when IP changes', () async {
      // 1. Get Public IP -> '1.1.1.1'
      when(mockIpService.getPublicIp()).thenAnswer((_) async => '1.1.1.1');

      // 2. Resolve Domain IP -> '2.2.2.2' (Different)
      when(
        mockIpService.resolveDomainIp(any),
      ).thenAnswer((_) async => '2.2.2.2');
      // Provider update expected
      when(mockProvider.updateIP(any, any)).thenAnswer((_) async => 'OK');

      final result = await DDNSService.backgroundUpdate(
        config,
        ipService: mockIpService,
        provider: mockProvider,
      );

      expect(result.success, true);
      expect(result.publicIp, '1.1.1.1');
      verify(mockProvider.updateIP(config.domain, config.token)).called(1);
    });

    test('backgroundUpdate skips update if IP matches', () async {
      // 1. Public IP
      when(mockIpService.getPublicIp()).thenAnswer((_) async => '1.1.1.1');

      // 2. Domain IP (SAME)
      when(
        mockIpService.resolveDomainIp(any),
      ).thenAnswer((_) async => '1.1.1.1');

      final result = await DDNSService.backgroundUpdate(
        config.copyWith(lastSuccessUpdate: DateTime.now()),
        ipService: mockIpService,
        provider: mockProvider,
      );

      expect(result.success, true);
      expect(result.status, contains('Skipped'));
      verifyNever(mockProvider.updateIP(any, any));
    });

    test(
      'backgroundUpdate verifies verification step on IP mismatch',
      () async {
        // 1. Initial IP check
        when(mockIpService.getPublicIp()).thenAnswer((_) async => '2.2.2.2');

        // 2. Domain IP (Different)
        when(
          mockIpService.resolveDomainIp(any),
        ).thenAnswer((_) async => '1.1.1.1');

        // 3. Verification check (Stable, so returns 2.2.2.2 again)
        // Note: getPublicIp is called twice.
        // We can mock consecutive calls.
        when(mockIpService.getPublicIp()).thenAnswer(
          (_) async => '2.2.2.2',
        ); // First call & Second call returning same

        when(mockProvider.updateIP(any, any)).thenAnswer((_) async => 'OK');

        final result = await DDNSService.backgroundUpdate(
          config,
          ipService: mockIpService,
          provider: mockProvider,
        );

        expect(result.success, true);
        expect(result.publicIp, '2.2.2.2');
        verify(mockProvider.updateIP(any, any)).called(1);
      },
    );
  });
}

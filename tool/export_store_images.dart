import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangoliving_agent/core/theme/app_theme.dart';
import 'package:mangoliving_agent/core/widgets/dashboard_app_bar_actions.dart';
import 'package:mangoliving_agent/core/widgets/mango_living_logo.dart';
import 'package:mangoliving_agent/features/auth/domain/models/agent_user.dart';
import 'package:mangoliving_agent/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mangoliving_agent/features/clients/domain/models/managed_client.dart';
import 'package:mangoliving_agent/features/clients/domain/models/roster_client.dart';
import 'package:mangoliving_agent/features/clients/domain/roster_merge.dart';
import 'package:mangoliving_agent/features/clients/presentation/controllers/clients_controller.dart';
import 'package:mangoliving_agent/features/clients/presentation/pages/clients_page.dart';
import 'package:mangoliving_agent/features/messages/domain/models/chat_thread.dart';
import 'package:mangoliving_agent/features/messages/presentation/controllers/chat_threads_controller.dart';
import 'package:mangoliving_agent/features/messages/presentation/pages/messages_page.dart';
import 'package:mangoliving_agent/features/offers/domain/models/property_action.dart';
import 'package:mangoliving_agent/features/offers/presentation/controllers/offers_controller.dart';
import 'package:mangoliving_agent/features/offers/presentation/pages/offers_page.dart';
import 'package:mangoliving_agent/features/overview/domain/models/overview_snapshot.dart';
import 'package:mangoliving_agent/features/overview/presentation/controllers/overview_controller.dart';
import 'package:mangoliving_agent/features/overview/presentation/pages/overview_page.dart';
import 'package:mangoliving_agent/features/showings/domain/models/showing_request.dart';
import 'package:mangoliving_agent/features/showings/presentation/controllers/showings_controller.dart';
import 'package:mangoliving_agent/features/showings/presentation/pages/showings_page.dart';

const String _outDir = '/Users/sjigoa/Desktop/App-Store-images';

final AgentUser _agent = AgentUser(
  id: 'agent-1',
  email: 'agent@mango.com',
  firstName: 'Alex',
  lastName: 'Rivera',
  roleName: 'agent',
  isEmailVerified: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('export App Store images', timeout: const Timeout(Duration(minutes: 3)), (WidgetTester tester) async {
    await _loadFonts();
    final Directory dir = Directory(_outDir)..createSync(recursive: true);
    final OverviewSnapshot home = _homeSnapshot();

    await _shoot(
      tester,
      file: File('${dir.path}/01-home-1206x2622.png'),
      size: const Size(402, 874),
      pixelRatio: 3,
      child: _phone(
        index: 0,
        overrides: <Override>[
          authControllerProvider.overrideWith(_ShotAuth.new),
          overviewControllerProvider.overrideWith(_ShotOverview.new),
          dashboardUserProvider.overrideWith((Ref ref) => _agent),
          dashboardUnreadProvider.overrideWith((Ref ref) => 2),
        ],
        page: const OverviewPage(),
      ),
    );

    expect(home.actionItems, greaterThan(0));
  });

  testWidgets('clients', timeout: const Timeout(Duration(seconds: 60)), (WidgetTester tester) async {
    await _loadFonts();
    Directory(_outDir).createSync(recursive: true);
    await _shoot(
      tester,
      file: File('$_outDir/02-clients-1206x2622.png'),
      size: const Size(402, 874),
      pixelRatio: 3,
      child: _phone(
        index: 1,
        overrides: <Override>[
          clientsControllerProvider.overrideWith(_ShotClients.new),
          dashboardUserProvider.overrideWith((Ref ref) => _agent),
        ],
        page: const ClientsPage(),
      ),
    );
  });

  testWidgets('messages', timeout: const Timeout(Duration(seconds: 60)), (WidgetTester tester) async {
    await _loadFonts();
    await _shoot(
      tester,
      file: File('$_outDir/03-messages-1206x2622.png'),
      size: const Size(402, 874),
      pixelRatio: 3,
      child: _phone(
        index: 2,
        overrides: <Override>[
          chatThreadsControllerProvider.overrideWith(_ShotThreads.new),
          dashboardUserProvider.overrideWith((Ref ref) => _agent),
        ],
        page: const MessagesPage(),
      ),
    );
  });

  testWidgets('showings', timeout: const Timeout(Duration(seconds: 60)), (WidgetTester tester) async {
    await _loadFonts();
    await _shoot(
      tester,
      file: File('$_outDir/04-showings-1206x2622.png'),
      size: const Size(402, 874),
      pixelRatio: 3,
      child: _phone(
        index: 3,
        overrides: <Override>[
          showingsControllerProvider.overrideWith(_ShotShowings.new),
          dashboardUserProvider.overrideWith((Ref ref) => _agent),
        ],
        page: const ShowingsPage(),
      ),
    );
  });

  testWidgets('offers', timeout: const Timeout(Duration(seconds: 60)), (WidgetTester tester) async {
    await _loadFonts();
    await _shoot(
      tester,
      file: File('$_outDir/05-offers-1206x2622.png'),
      size: const Size(402, 874),
      pixelRatio: 3,
      child: _phone(
        index: 4,
        showNav: false,
        overrides: <Override>[
          offersControllerProvider.overrideWith(_ShotOffers.new),
          dashboardUserProvider.overrideWith((Ref ref) => _agent),
        ],
        page: const OffersPage(),
      ),
    );
  });

  testWidgets('header wide', timeout: const Timeout(Duration(seconds: 90)), (WidgetTester tester) async {
    await _loadFonts();
    final ui.Image phone = await _decodePhone(tester);
    await _shoot(
      tester,
      file: File('$_outDir/header-5244x2950.png'),
      size: const Size(2622, 1475),
      pixelRatio: 2,
      child: _Header(phone: phone, wide: true),
    );
  });

  testWidgets('header banner', timeout: const Timeout(Duration(seconds: 90)), (WidgetTester tester) async {
    await _loadFonts();
    final ui.Image phone = await _decodePhone(tester);
    await _shoot(
      tester,
      file: File('$_outDir/header-3840x1646.png'),
      size: const Size(1920, 823),
      pixelRatio: 2,
      child: _Header(phone: phone, wide: false),
    );
  });
}

class _ShotAuth extends AuthController {
  @override
  Future<AgentSession?> build() async {
    return AgentSession(token: 'shot', user: _agent);
  }
}

class _ShotOverview extends OverviewController {
  @override
  Future<OverviewSnapshot> build() async => _homeSnapshot();
}

class _ShotClients extends ClientsController {
  @override
  Future<ClientsViewData> build() async {
    return ClientsViewData(
      roster: ClientRoster(
        clients: <RosterClient>[
          _client(
            'Maya Chen',
            'maya@example.com',
            ClientUiStatus.active,
            4,
            12,
            buyerMode: BuyerMode.sharing,
            actions: <ClientAction>[_action('a1', ClientActionType.needsFollowup)],
          ),
          _client(
            'Jordan Ellis',
            'jordan@example.com',
            ClientUiStatus.active,
            2,
            6,
            buyerMode: BuyerMode.sharing,
            actions: <ClientAction>[
              _action('a2', ClientActionType.showingRequested),
            ],
          ),
          _client(
            'Priya Shah',
            'priya@example.com',
            ClientUiStatus.invited,
            0,
            0,
            buyerMode: BuyerMode.privacy,
          ),
        ],
        pendingRequests: <ManagedClient>[
          const ManagedClient(
            id: 'p1',
            name: 'Luis Ortega',
            email: 'luis@example.com',
            status: 'pending',
          ),
        ],
      ),
    );
  }
}

class _ShotThreads extends ChatThreadsController {
  @override
  Future<ChatThreadsState> build() async {
    final DateTime now = DateTime.now();
    return ChatThreadsState(
      threads: <ChatThread>[
        ChatThread(
          agentClientId: 'c1',
          buyerName: 'Maya Chen',
          unreadCount: 2,
          updatedAt: now.toIso8601String(),
          lastMessageText: 'Can we see the Hyde Park house tomorrow?',
          lastMessageAt: now.toIso8601String(),
          lastSenderRole: 'buyer',
        ),
        ChatThread(
          agentClientId: 'c2',
          buyerName: 'Jordan Ellis',
          unreadCount: 0,
          updatedAt: now.subtract(const Duration(hours: 3)).toIso8601String(),
          lastMessageText: 'I sent the offer summary.',
          lastMessageAt: now.subtract(const Duration(hours: 3)).toIso8601String(),
          lastSenderRole: 'agent',
        ),
        ChatThread(
          agentClientId: 'c3',
          buyerName: 'Priya Shah',
          unreadCount: 1,
          updatedAt: now.subtract(const Duration(hours: 5)).toIso8601String(),
          lastMessageText: 'Thanks, I will keep my search private for now.',
          lastMessageAt: now.subtract(const Duration(hours: 5)).toIso8601String(),
          lastSenderRole: 'buyer',
        ),
      ],
    );
  }
}

class _ShotShowings extends ShowingsController {
  @override
  Future<ShowingsViewData> build() async {
    final DateTime soon = DateTime.now().add(const Duration(days: 1, hours: 2));
    return ShowingsViewData(
      requests: <ShowingRequest>[
        ShowingRequest(
          id: 's1',
          buyerName: 'Maya Chen',
          status: 'scheduled',
          propertyAddress: '1842 Avenue G',
          propertyCity: 'Austin, TX',
          scheduledAt: soon.toIso8601String(),
        ),
        ShowingRequest(
          id: 's2',
          buyerName: 'Jordan Ellis',
          status: 'pending',
          propertyAddress: '910 West Lynn',
          propertyCity: 'Austin, TX',
          message: 'Saturday morning works best.',
        ),
      ],
    );
  }
}

class _ShotOffers extends OffersController {
  @override
  Future<OffersViewData> build() async {
    return OffersViewData(
      rows: <PropertyAction>[
        PropertyAction(
          id: 'o1',
          buyerId: 'b1',
          propertyId: 'p1',
          currentState: 'offer_placed',
          property: const OfferProperty(
            streetAddress: '1842 Avenue G',
            city: 'Austin',
            listPrice: 725000,
          ),
          buyer: const OfferBuyer(firstName: 'Maya', lastName: 'Chen'),
          offer: const OfferDetails(offerAmount: 710000, offerStatus: OfferStatus.sent),
        ),
        PropertyAction(
          id: 'o2',
          buyerId: 'b2',
          propertyId: 'p2',
          currentState: 'visited',
          property: const OfferProperty(
            streetAddress: '910 West Lynn',
            city: 'Austin',
            listPrice: 640000,
          ),
          buyer: const OfferBuyer(firstName: 'Jordan', lastName: 'Ellis'),
        ),
        PropertyAction(
          id: 'o3',
          buyerId: 'b3',
          propertyId: 'p3',
          currentState: 'offer_accepted',
          property: const OfferProperty(
            streetAddress: '55 Rainey Street',
            city: 'Austin',
            listPrice: 890000,
          ),
          buyer: const OfferBuyer(firstName: 'Priya', lastName: 'Shah'),
          offer: const OfferDetails(
            offerAmount: 875000,
            offerStatus: OfferStatus.accepted,
          ),
        ),
      ],
    );
  }
}

RosterClient _client(
  String name,
  String email,
  ClientUiStatus status,
  int searches,
  int messages, {
  BuyerMode? buyerMode,
  List<ClientAction> actions = const <ClientAction>[],
}) {
  return RosterClient(
    id: email,
    name: name,
    email: email,
    phone: '5125550100',
    status: status,
    buyerMode: buyerMode,
    lastActiveTimestamp: DateTime.now().millisecondsSinceEpoch,
    createdAt: DateTime.now().subtract(const Duration(days: 12)),
    searches: searches,
    messages: messages,
    activities: const <ClientActivity>[],
    actions: actions,
    location: 'Austin, TX',
  );
}

ClientAction _action(String id, ClientActionType type) {
  return ClientAction(
    id: id,
    type: type,
    description: type.name,
    priority: ActionPriority.high,
    status: ActionItemStatus.pending,
    createdAt: DateTime.now(),
  );
}

OverviewSnapshot _homeSnapshot() {
  final DateTime soon = DateTime.now().add(const Duration(days: 1, hours: 2));
  final DateTime now = DateTime.now();
  return OverviewSnapshot(
    profile: _agent,
    clients: const <ManagedClient>[
      ManagedClient(
        id: 'p1',
        name: 'Luis Ortega',
        email: 'luis@example.com',
        status: 'pending',
      ),
      ManagedClient(
        id: 'a1',
        name: 'Maya Chen',
        email: 'maya@example.com',
        status: 'active',
      ),
    ],
    interestCount: 3,
    showings: <ShowingRequest>[
      ShowingRequest(
        id: 's1',
        buyerName: 'Maya Chen',
        status: 'scheduled',
        propertyAddress: '1842 Avenue G',
        propertyCity: 'Austin, TX',
        scheduledAt: soon.toIso8601String(),
      ),
      ShowingRequest(
        id: 's2',
        buyerName: 'Jordan Ellis',
        status: 'pending',
        propertyAddress: '910 West Lynn',
        propertyCity: 'Austin, TX',
      ),
    ],
    threads: <ChatThread>[
      ChatThread(
        agentClientId: 'c1',
        buyerName: 'Maya Chen',
        unreadCount: 2,
        updatedAt: now.toIso8601String(),
        lastMessageText: 'Can we see the Hyde Park house tomorrow?',
        lastMessageAt: now.toIso8601String(),
        lastSenderRole: 'buyer',
      ),
    ],
    notifications: const [],
    lastReadAt: now,
    newestNotificationAt: now.toIso8601String(),
  );
}

Widget _phone({
  required int index,
  required List<Override> overrides,
  required Widget page,
  bool showNav = true,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _storeTheme(),
      home: Scaffold(
        body: page,
        bottomNavigationBar: showNav ? NavigationBar(
          selectedIndex: index,
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Clients',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today),
              label: 'Showings',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
        )
            : null,
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.phone, required this.wide});

  final ui.Image phone;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
      color: const Color(0xFFFFF8F4),
      textStyle: const TextStyle(fontFamily: 'StoreArial', color: Color(0xFF171717)),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: wide ? 140 : 96),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MangoLivingLogo(fontSize: wide ? 92 : 64),
                  SizedBox(height: wide ? 36 : 20),
                  Text(
                    'See who needs\nyou today',
                    style: TextStyle(
                      fontSize: wide ? 92 : 58,
                      height: 0.98,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.5,
                      color: const Color(0xFF171717),
                    ),
                  ),
                  SizedBox(height: wide ? 28 : 16),
                  Text(
                    'Clients, messages, showings, and offers.',
                    style: TextStyle(
                      fontSize: wide ? 36 : 26,
                      color: const Color(0xFF717182),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: wide ? 200 : 20),
                child: AspectRatio(
                  aspectRatio: 402 / 874,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 40,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: RawImage(image: phone, fit: BoxFit.fill),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 80),
        ],
      ),
      ),
    );
  }
}

Future<ui.Image> _decodePhone(WidgetTester tester) async {
  final Uint8List bytes = File('$_outDir/01-home-1206x2622.png').readAsBytesSync();
  late ui.Image image;
  await tester.runAsync(() async {
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    image = frame.image;
  });
  return image;
}

Future<void> _loadFonts() async {
  final Uint8List regular = File(
    '/System/Library/Fonts/Supplemental/Arial.ttf',
  ).readAsBytesSync();
  final Uint8List bold = File(
    '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
  ).readAsBytesSync();
  final Uint8List icons = File(
    '/Users/sjigoa/development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytesSync();
  final FontLoader text = FontLoader('StoreArial')
    ..addFont(Future<ByteData>.value(ByteData.sublistView(regular)))
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bold)));
  final FontLoader material = FontLoader('MaterialIcons')
    ..addFont(Future<ByteData>.value(ByteData.sublistView(icons)));
  await text.load();
  await material.load();
}

ThemeData _storeTheme() {
  final ThemeData base = AppTheme.light;
  final TextTheme text = base.textTheme.apply(fontFamily: 'StoreArial');
  return base.copyWith(
    textTheme: text,
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: 'StoreArial'),
    appBarTheme: base.appBarTheme.copyWith(
      titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
        fontFamily: 'StoreArial',
      ),
    ),
  );
}

Future<void> _shoot(
  WidgetTester tester, {
  required File file,
  required Size size,
  required double pixelRatio,
  required Widget child,
}) async {
  await tester.binding.setSurfaceSize(size);
  tester.view.devicePixelRatio = pixelRatio;
  tester.view.physicalSize = Size(size.width * pixelRatio, size.height * pixelRatio);

  debugPrint('shoot ${file.path}');
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('shot'),
      child: MediaQuery(
        data: MediaQueryData(size: size, devicePixelRatio: pixelRatio),
        child: child,
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
  await tester.pump();

  final RenderRepaintBoundary boundary =
      tester.renderObject(find.byKey(const Key('shot'))) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

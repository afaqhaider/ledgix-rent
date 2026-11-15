import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledgix_rent/core/data/in_memory_repository.dart';
import 'package:ledgix_rent/core/providers.dart';
import 'package:ledgix_rent/core/routing/app_router.dart';
import 'package:ledgix_rent/features/expenses/data/expense_sync.dart';
import 'package:ledgix_rent/features/expenses/domain/expense.dart';
import 'package:ledgix_rent/features/expenses/domain/profitability.dart';
import 'package:ledgix_rent/features/expenses/domain/service_charge_plan.dart';
import 'package:ledgix_rent/features/landlord/domain/landlord.dart';
import 'package:ledgix_rent/features/leases/domain/lease.dart';
import 'package:ledgix_rent/features/maintenance/domain/maintenance_ticket.dart';
import 'package:ledgix_rent/features/payments/domain/payment.dart';
import 'package:ledgix_rent/features/properties/domain/property.dart';
import 'package:ledgix_rent/main.dart';
import 'package:material_ui/material_ui.dart';

// All data here is made up.

Expense _sc(String id, DateTime due, {bool paid = false, ExpenseSource source = ExpenseSource.schedule, String property = 'p1'}) =>
    Expense(
      id: id,
      propertyId: property,
      type: ExpenseType.serviceCharge,
      amount: 3000,
      dueDate: due,
      status: paid ? ExpenseStatus.paid : ExpenseStatus.due,
      paidDate: paid ? due : null,
      source: source,
    );

Property _villa({double? sc = 12000, DateTime? next, double? price}) => Property(
      id: 'p1',
      landlordId: 'demo',
      name: 'Palm Villa',
      type: PropertyType.villa,
      address: 'Test address',
      hoaName: 'Test HOA',
      serviceChargeAnnual: sc,
      serviceChargeFrequency: ServiceChargeFrequency.quarterly,
      serviceChargeNextDue: next ?? DateTime(2026, 12, 1),
      purchasePrice: price,
    );

void main() {
  group('service-charge plan', () {
    test('instalments per frequency split the annual amount', () {
      ServiceChargePlan plan(ServiceChargeFrequency f) =>
          ServiceChargePlan(annualAmount: 12000, frequency: f, nextDue: DateTime(2026, 12, 1));
      final q = plan(ServiceChargeFrequency.quarterly).instalments('p1');
      expect(q.map((e) => e.dueDate), [DateTime(2026, 12, 1), DateTime(2027, 3, 1), DateTime(2027, 6, 1), DateTime(2027, 9, 1)]);
      expect(q.every((e) => e.amount == 3000 && e.type == ExpenseType.serviceCharge && e.source == ExpenseSource.schedule), isTrue);
      expect(q.map((e) => e.period), ['Q4 2026', 'Q1 2027', 'Q2 2027', 'Q3 2027']);
      expect(plan(ServiceChargeFrequency.semiAnnual).instalments('p1').map((e) => (e.amount, e.dueDate)),
          [(6000.0, DateTime(2026, 12, 1)), (6000.0, DateTime(2027, 6, 1))]);
      expect(plan(ServiceChargeFrequency.annual).instalments('p1').single.amount, 12000);
      expect(plan(ServiceChargeFrequency.monthly).instalments('p1').length, 12);
      expect(plan(ServiceChargeFrequency.custom).instalments('p1'), isEmpty);
    });

    test('ids are stable so saving again updates instead of duplicating', () {
      final a = _villa().serviceChargePlan!.instalments('p1').map((e) => e.id).toList();
      final b = _villa().serviceChargePlan!.instalments('p1').map((e) => e.id).toList();
      expect(a, b);
    });

    test('reconcile keeps paid and hand-entered rows, replaces unpaid generated ones', () {
      final plan = ServiceChargePlan(annualAmount: 16000, frequency: ServiceChargeFrequency.quarterly, nextDue: DateTime(2026, 12, 1));
      final paidFirst = _sc(ServiceChargePlan.instalmentId('p1', DateTime(2026, 12, 1)), DateTime(2026, 12, 1), paid: true);
      final staleLater = _sc('sc_p1_2027-02-15', DateTime(2027, 2, 15));
      final manual = _sc('m1', DateTime(2027, 1, 1), source: ExpenseSource.manual);
      final r = plan.reconcile('p1', [paidFirst, staleLater, manual]);
      expect(r.save.map((e) => e.id), isNot(contains(paidFirst.id)));
      expect(r.save.length, 3);
      expect(r.save.first.amount, 4000);
      expect(r.delete, ['sc_p1_2027-02-15']);
    });

    test('once every instalment is paid, the next year is generated', () {
      final plan = _villa().serviceChargePlan!;
      final year = [for (final e in plan.instalments('p1')) e.markPaid(e.dueDate)];
      final next = plan.rollForward('p1', year);
      expect(next.map((e) => e.dueDate).first, DateTime(2027, 12, 1));
      expect(next.length, 4);
      expect(plan.rollForward('p1', [...year.take(3), plan.instalments('p1').last]), isEmpty);
    });

    test('overdue is derived from the due date; paid stays paid', () {
      final today = DateTime(2027, 1, 10);
      expect(_sc('a', DateTime(2027, 1, 1)).statusOn(today), ExpenseStatus.overdue);
      expect(_sc('b', DateTime(2027, 2, 1)).statusOn(today), ExpenseStatus.due);
      expect(_sc('c', DateTime(2026, 12, 1), paid: true).statusOn(today), ExpenseStatus.paid);
    });

    test('agency fee 5% quick-fill', () {
      expect(agencyFeeFivePercent(60000), 3000);
      expect(agencyFeeFivePercent(85500), 4275);
    });

    test('expense map round-trip, and old records load', () {
      final e = _sc('x', DateTime(2027, 3, 1), paid: true).copyWith(payee: 'HOA', receiptUrl: 'https://example.com/r.pdf');
      final back = Expense.fromMap(e.toMap());
      expect((back.amount, back.isPaid, back.payee, back.receiptUrl, back.dueDate), (3000.0, true, 'HOA', 'https://example.com/r.pdf', DateTime(2027, 3, 1)));
      final old = Property.fromMap({'id': 'p', 'name': 'Old'});
      expect((old.serviceChargeAnnual, old.serviceChargePlan, old.purchasePrice), (null, null, null));
      final round = Property.fromMap(_villa(price: 2000000).toMap());
      expect((round.serviceChargeAnnual, round.serviceChargeFrequency, round.serviceChargeNextDue, round.purchasePrice),
          (12000.0, ServiceChargeFrequency.quarterly, DateTime(2026, 12, 1), 2000000.0));
    });
  });

  group('profitability', () {
    final lease = Lease(
      id: 'l1', propertyId: 'p1', tenantId: 't1', startDate: DateTime(2027, 1, 1), endDate: DateTime(2027, 12, 31), annualRent: 120000,
    );
    Payment pay(String id, DateTime due, PaymentStatus s) =>
        Payment(id: id, leaseId: 'l1', type: PaymentMethod.cheque, amount: 30000, dueDate: due, status: s);

    test('rent collected vs expenses by type, per unit and in total', () {
      final other = Property(id: 'p2', landlordId: 'demo', name: 'Studio');
      final r = Profitability.compute(
        range: DateRange.thisYear(DateTime(2027, 6, 1)),
        today: DateTime(2027, 6, 1),
        properties: [_villa(price: 1500000), other],
        leases: [lease],
        payments: [
          pay('a', DateTime(2027, 1, 1), PaymentStatus.cleared),
          pay('b', DateTime(2027, 4, 1), PaymentStatus.cleared),
          pay('c', DateTime(2027, 7, 1), PaymentStatus.pending),
          pay('d', DateTime(2026, 10, 1), PaymentStatus.cleared), // last year: ignored
        ],
        expenses: [
          _sc('s1', DateTime(2027, 3, 1), paid: true),
          _sc('s2', DateTime(2027, 6, 1)),
          _sc('s0', DateTime(2026, 12, 1), paid: true), // last year: ignored
          Expense(id: 'ag', propertyId: 'p1', type: ExpenseType.agencyFee, amount: 6000, dueDate: DateTime(2027, 1, 1), status: ExpenseStatus.paid),
          Expense(id: 'mx', propertyId: 'p1', type: ExpenseType.maintenance, amount: 1500, dueDate: DateTime(2027, 2, 1), ticketId: 'tk1'),
          Expense(id: 'o', propertyId: 'p2', type: ExpenseType.other, amount: 500, dueDate: DateTime(2027, 5, 1)),
        ],
        tickets: [
          // Has an expense already: not counted twice.
          MaintenanceTicket(id: 'tk1', propertyId: 'p1', title: 'AC', status: TicketStatus.completed, cost: 1500, confirmedVisit: DateTime(2027, 2, 1)),
          // Costed before expenses existed: counted by its visit date.
          MaintenanceTicket(id: 'tk2', propertyId: 'p1', title: 'Leak', status: TicketStatus.closed, cost: 800, confirmedVisit: DateTime(2027, 3, 5)),
        ],
      );
      final villa = r.units.firstWhere((u) => u.property.id == 'p1');
      expect(villa.pnl.rentCollected, 60000);
      expect(villa.pnl.rentOutstanding, 30000);
      expect(villa.pnl.serviceCharges, 6000);
      expect(villa.pnl.agencyFees, 6000);
      expect(villa.pnl.maintenance, 2300);
      expect(villa.pnl.totalExpenses, 14300);
      expect(villa.pnl.net, 45700);
      expect(villa.pnl.unpaidExpenses, 4500);
      expect(villa.yieldPercent, closeTo(45700 / 1500000 * 100, 0.01));
      final studio = r.units.firstWhere((u) => u.property.id == 'p2');
      expect(studio.pnl.net, -500);
      expect(studio.yieldPercent, isNull);
      expect(r.units.first.property.id, 'p1'); // best net first
      expect(r.total.net, 45200);
      final csv = r.toCsv(header: List.filled(11, 'h'), totalLabel: 'Total').split('\n');
      expect(csv.length, 4);
      expect(csv.last, startsWith('"Total",60000.00,30000.00'));
    });

    test('last 12 months range', () {
      final r = DateRange.last12Months(DateTime(2027, 6, 15));
      expect(r.contains(DateTime(2026, 6, 16)), isTrue);
      expect(r.contains(DateTime(2026, 6, 15)), isFalse);
      expect(r.contains(DateTime(2027, 6, 15)), isTrue);
    });
  });

  group('expense sync (demo repository)', () {
    test('property plan, agency fee and approved maintenance create expenses', () async {
      final repo = InMemoryRepository<Expense>();
      final sync = ExpenseSync(repo);
      await sync.serviceCharges(_villa());
      expect(repo.items.where((e) => e.type == ExpenseType.serviceCharge).length, 4);
      // Saving again does not duplicate; clearing the plan removes unpaid rows.
      await sync.serviceCharges(_villa());
      expect(repo.items.length, 4);
      await sync.serviceCharges(_villa(sc: null));
      expect(repo.items, isEmpty);

      final lease = Lease(id: 'l1', propertyId: 'p1', tenantId: 't', startDate: DateTime(2027, 1, 1), endDate: DateTime(2027, 12, 31), annualRent: 60000);
      await sync.agencyFee(Lease.fromMap({...lease.toMap(), 'agencyFee': 3000, 'agencyName': 'Test Realty', 'agencyFeePaidDate': '2027-01-02'}));
      final ag = await repo.get(ExpenseSync.agencyId('l1'));
      expect((ag!.type, ag.amount, ag.isPaid, ag.payee), (ExpenseType.agencyFee, 3000.0, true, 'Test Realty'));
      await sync.agencyFee(lease);
      expect(await repo.get(ExpenseSync.agencyId('l1')), isNull);

      const t = MaintenanceTicket(id: 'tk', propertyId: 'p1', title: 'AC', status: TicketStatus.quoted);
      await sync.maintenance(t);
      expect(await repo.get(ExpenseSync.ticketId('tk')), isNull);
      await sync.maintenance(t.copyWith(status: TicketStatus.approved, cost: 1200), payee: 'Cool Co');
      final mx = await repo.get(ExpenseSync.ticketId('tk'));
      expect((mx!.type, mx.amount, mx.payee), (ExpenseType.maintenance, 1200.0, 'Cool Co'));
    });

    test('paying the last instalment rolls the plan into next year', () async {
      final repo = InMemoryRepository<Expense>();
      final sync = ExpenseSync(repo);
      final villa = _villa();
      await sync.serviceCharges(villa);
      for (final e in [...repo.items]) {
        await sync.markPaid(e, e.dueDate, property: villa);
      }
      expect(repo.items.length, 8);
      expect(repo.items.where((e) => !e.isPaid).map((e) => e.dueDate).reduce((a, b) => a.isBefore(b) ? a : b), DateTime(2027, 12, 1));
    });
  });

  group('screens', () {
    Future<ProviderContainer> app(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.listen(userIdProvider, (_, _) {});
      final today = DateTime.now();
      await tester.runAsync(() async {
        await c.read(authRepositoryProvider).signInWithEmail('expenses@test.local', 'x');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await c.read(landlordRepositoryProvider).save(const Landlord(id: 'demo', name: 'Me Landlord'));
        // Demo repositories are shared between tests: start each one clean.
        final repo = c.read(expenseRepositoryProvider);
        for (final e in await repo.watchAll().first) {
          await repo.delete(e.id);
        }
        await c.read(propertyRepositoryProvider).save(_villa(next: DateTime(today.year, today.month, today.day).add(const Duration(days: 10))));
        await ExpenseSync(c.read(expenseRepositoryProvider)).serviceCharges(
            _villa(next: DateTime(today.year, today.month, today.day).add(const Duration(days: 10))));
      });
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const LedgixApp()));
      await tester.pumpAndSettle();
      return c;
    }

    Future<void> go(WidgetTester tester, ProviderContainer c, String path) async {
      c.read(routerProvider).go(path);
      await tester.pumpAndSettle();
    }

    for (final (label, size) in [('desktop', const Size(1440, 900)), ('phone', const Size(390, 844))]) {
      testWidgets('$label: dashboard shows service charges due and profit; mark paid', (tester) async {
        final c = await app(tester, size);
        await go(tester, c, '/');
        final card = find.byKey(const Key('service-charges-due'));
        await tester.scrollUntilVisible(card, 200, scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        expect(card.hitTestable(), findsOneWidget);
        // Demo data is shared between tests, so take the first unpaid one.
        final first = (c.read(expensesProvider).value!.where((e) => !e.isPaid).toList()
              ..sort((a, b) => a.dueDate.compareTo(b.dueDate)))
            .first;
        expect(find.descendant(of: card, matching: find.text('Palm Villa · ${first.period}')), findsOneWidget);
        await tester.tap(find.byKey(Key('mark-paid-${first.id}')).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('mark-paid-confirm')));
        await tester.pumpAndSettle();
        expect((await tester.runAsync(() => c.read(expenseRepositoryProvider).get(first.id)))!.isPaid, isTrue);
        final profit = find.byKey(const Key('profitability-card'));
        await tester.scrollUntilVisible(profit, 200, scrollable: find.byType(Scrollable).first);
        expect(profit.hitTestable(), findsOneWidget);
      });
    }

    testWidgets('desktop: property form service charges section and agreement 5% fee are visible', (tester) async {
      final c = await app(tester, const Size(1440, 900));
      await go(tester, c, '/property/p1/edit');
      final section = find.byKey(const Key('section-service-charges'));
      await tester.scrollUntilVisible(section, 200, scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('field-scAnnual')).hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('sc-preview')), findsOneWidget);
      expect(find.textContaining('4 instalments of AED 3,000.00'), findsOneWidget);

      await go(tester, c, '/leases/new');
      await tester.enterText(find.byKey(const ValueKey('field-annualRent')), '60000');
      final five = find.byKey(const Key('agency-five-percent'));
      await tester.scrollUntilVisible(five, 200, scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
      await tester.tap(five.hitTestable());
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, '3000'), findsOneWidget);
    });

    testWidgets('desktop: profitability report, expenses and service charges pages render', (tester) async {
      final c = await app(tester, const Size(1440, 900));
      await go(tester, c, '/reports');
      expect(find.byKey(const Key('profitability-table')).hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('pnl-total')).hitTestable(), findsOneWidget);
      await go(tester, c, '/expenses');
      expect(find.byKey(const Key('expenses-total')).hitTestable(), findsOneWidget);
      await go(tester, c, '/service-charges');
      expect(find.byKey(const Key('service-charge-plans')).hitTestable(), findsOneWidget);
      await go(tester, c, '/expenses/new');
      expect(find.byKey(const ValueKey('field-expense-amount')).hitTestable(), findsOneWidget);
    });
  });
}

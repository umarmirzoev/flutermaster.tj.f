import '../../../core/models/platform_models.dart';
import '../models/admin_models.dart';

SaOrderStatus _mapOrderStatus(AdminOrderStatus status) => switch (status) {
      AdminOrderStatus.newOrder => SaOrderStatus.newOrder,
      AdminOrderStatus.inProgress => SaOrderStatus.inProgress,
      AdminOrderStatus.completed => SaOrderStatus.completed,
      AdminOrderStatus.cancelled => SaOrderStatus.cancelled,
    };

SaOrder adminOrderToSa(AdminOrder order) => SaOrder(
      id: order.id,
      client: order.client,
      master: order.master,
      service: order.service,
      date: order.date,
      status: _mapOrderStatus(order.status),
      amount: order.amount,
    );

SaClient adminClientToSa(AdminClient client) => SaClient(
      id: client.id,
      name: client.name,
      phone: client.phone,
      avatar: 'assets/images/master_1.png',
      date: client.joined,
      isNew: client.orders <= 1,
      orders: client.orders,
      spent: client.spent,
      isVip: client.isVip,
    );

SaMaster adminMasterToSa(AdminMaster master) {
  final avatar = master.avatar.startsWith('assets/')
      ? master.avatar
      : 'assets/images/master_1.png';
  return SaMaster(
    id: master.id,
    name: master.name,
    avatar: avatar,
    rating: master.rating,
    orders: master.orders,
    phone: master.phone,
    specialization: master.specialization,
  );
}

List<SaOrder> adminOrdersToSa(List<AdminOrder> orders) =>
    orders.map(adminOrderToSa).toList();

List<SaClient> adminClientsToSa(List<AdminClient> clients) =>
    clients.map(adminClientToSa).toList();

List<SaMaster> adminMastersToSa(List<AdminMaster> masters) =>
    masters.map(adminMasterToSa).toList();

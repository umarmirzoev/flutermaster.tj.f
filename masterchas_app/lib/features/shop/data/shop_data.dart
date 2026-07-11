import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/l10n/app_locale.dart';

/// Formats an integer with thin spaces as thousands separators (e.g. 5 990).
String shopMoney(int v) {
  final str = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
    buf.write(str[i]);
  }
  return buf.toString();
}

enum ProductBadge { none, hit, isNew }

class ShopProduct {
  const ShopProduct({
    required this.ru,
    required this.en,
    required this.image,
    required this.price,
    required this.oldPrice,
    required this.rating,
    required this.ratingsCount,
    required this.orders,
    required this.badge,
    required this.categoryIndex,
    required this.descRu,
    required this.descEn,
    this.imageBytes,
  });

  final String ru;
  final String en;
  final String image;
  final int price;
  final int oldPrice; // 0 == no discount
  final double rating;
  final int ratingsCount;
  final int orders;
  final ProductBadge badge;
  final int categoryIndex; // 1..7 (0 == "All")
  final String descRu;
  final String descEn;
  final Uint8List? imageBytes;

  int get discountPercent => oldPrice > price ? (((oldPrice - price) / oldPrice) * 100).round() : 0;

  String name(AppLocale locale) => switch (locale) {
        AppLocale.ru || AppLocale.tg => ru,
        AppLocale.en || AppLocale.zh => en,
      };

  String desc(AppLocale locale) => switch (locale) {
        AppLocale.ru || AppLocale.tg => descRu,
        AppLocale.en || AppLocale.zh => descEn,
      };
}

Widget buildShopProductImage(ShopProduct product, {double? width, double? height, BoxFit fit = BoxFit.contain}) {
  if (product.imageBytes != null) {
    return Image.memory(product.imageBytes!, width: width, height: height, fit: fit);
  }
  return Image.asset(product.image, width: width, height: height, fit: fit);
}

const shopProducts = <ShopProduct>[
  ShopProduct(
    ru: 'BERALI шуруповёрт 48В', en: 'BERALI drill driver 48V',
    image: 'assets/images/tool_drill.png', price: 520, oldPrice: 650, rating: 4.8,
    ratingsCount: 142, orders: 1240, badge: ProductBadge.hit, categoryIndex: 1,
    descRu: 'Аккумуляторный шуруповёрт с двумя АКБ 48В, кейсом и набором бит. Реверс, регулировка крутящего момента, светодиодная подсветка.',
    descEn: 'Cordless drill driver with two 48V batteries, a case and a set of bits. Reverse, torque control and LED light.',
  ),
  ShopProduct(
    ru: 'Шлифмашина угловая 125мм', en: 'Angle grinder 125mm',
    image: 'assets/images/shop_grinder.png', price: 380, oldPrice: 450, rating: 4.7,
    ratingsCount: 98, orders: 860, badge: ProductBadge.hit, categoryIndex: 1,
    descRu: 'Угловая шлифмашина (болгарка) 125мм, мощный двигатель, защита от перегрузки, удобная рукоятка.',
    descEn: '125mm angle grinder with a powerful motor, overload protection and a comfortable grip.',
  ),
  ShopProduct(
    ru: 'Дисковая пила 190мм', en: 'Circular saw 190mm',
    image: 'assets/images/shop_saw.png', price: 580, oldPrice: 0, rating: 4.9,
    ratingsCount: 76, orders: 540, badge: ProductBadge.hit, categoryIndex: 1,
    descRu: 'Дисковая пила 190мм для точного и быстрого реза дерева. Регулировка глубины и угла, лазерный указатель.',
    descEn: '190mm circular saw for fast, precise wood cutting. Depth and angle adjustment, laser guide.',
  ),
  ShopProduct(
    ru: 'Набор инструментов 108 предметов', en: 'Tool set 108 pcs',
    image: 'assets/images/tool_set.png', price: 290, oldPrice: 370, rating: 4.8,
    ratingsCount: 320, orders: 2100, badge: ProductBadge.hit, categoryIndex: 2,
    descRu: 'Универсальный набор из 108 предметов: головки, биты, ключи и трещотка в прочном кейсе.',
    descEn: 'Universal 108-piece set: sockets, bits, wrenches and a ratchet in a durable case.',
  ),
  ShopProduct(
    ru: 'Перфоратор 26мм 800Вт', en: 'Rotary hammer 26mm 800W',
    image: 'assets/images/shop_perforator.png', price: 620, oldPrice: 780, rating: 4.9,
    ratingsCount: 64, orders: 430, badge: ProductBadge.hit, categoryIndex: 1,
    descRu: 'Перфоратор SDS-Plus 800Вт, 3 режима работы, антивибрационная система. Для бетона, кирпича и камня.',
    descEn: 'SDS-Plus 800W rotary hammer, 3 modes, anti-vibration system. For concrete, brick and stone.',
  ),
  ShopProduct(
    ru: 'BERALI гайковёрт аккумуляторный', en: 'BERALI cordless impact wrench',
    image: 'assets/images/tool_drill.png', price: 490, oldPrice: 0, rating: 4.8,
    ratingsCount: 41, orders: 210, badge: ProductBadge.isNew, categoryIndex: 1,
    descRu: 'Аккумуляторный ударный гайковёрт с высоким крутящим моментом. Бесщёточный двигатель, быстрая зарядка.',
    descEn: 'Cordless impact wrench with high torque. Brushless motor and fast charging.',
  ),
  ShopProduct(
    ru: 'BERALI мойка высокого давления', en: 'BERALI pressure washer',
    image: 'assets/images/shop_washer.png', price: 720, oldPrice: 880, rating: 4.6,
    ratingsCount: 53, orders: 320, badge: ProductBadge.isNew, categoryIndex: 4,
    descRu: 'Мойка высокого давления 150 бар. Для авто, фасадов и дорожек. В комплекте насадки и шланг.',
    descEn: 'High-pressure washer 150 bar. For cars, facades and pathways. Nozzles and hose included.',
  ),
  ShopProduct(
    ru: 'Набор инструментов 216 предметов', en: 'Tool set 216 pcs',
    image: 'assets/images/tool_set.png', price: 850, oldPrice: 1050, rating: 4.9,
    ratingsCount: 38, orders: 180, badge: ProductBadge.isNew, categoryIndex: 2,
    descRu: 'Профессиональный набор из 216 предметов для дома и автосервиса в металлическом кейсе.',
    descEn: 'Professional 216-piece set for home and auto service in a metal case.',
  ),
  ShopProduct(
    ru: 'BERALI лобзик 850Вт', en: 'BERALI jigsaw 850W',
    image: 'assets/images/shop_jigsaw.png', price: 340, oldPrice: 0, rating: 4.7,
    ratingsCount: 47, orders: 290, badge: ProductBadge.isNew, categoryIndex: 1,
    descRu: 'Электролобзик 850Вт с маятниковым ходом и подсветкой. Точный рез дерева, металла и пластика.',
    descEn: '850W jigsaw with pendulum action and light. Precise cutting of wood, metal and plastic.',
  ),
  ShopProduct(
    ru: 'BERALI фонарь аккумуляторный', en: 'BERALI rechargeable flashlight',
    image: 'assets/images/shop_flashlight.png', price: 75, oldPrice: 95, rating: 4.6,
    ratingsCount: 130, orders: 980, badge: ProductBadge.isNew, categoryIndex: 5,
    descRu: 'Аккумуляторный рабочий фонарь COB с магнитом и крючком. Несколько режимов яркости.',
    descEn: 'Rechargeable COB work light with a magnet and a hook. Several brightness modes.',
  ),
];

/// Инструменты только для вкладки «Аренда» (цена за сутки).
const rentalProducts = <ShopProduct>[
  ShopProduct(
    ru: 'Дрель-шуруповёрт', en: 'Drill driver',
    image: 'assets/images/tool_drill.png', price: 45, oldPrice: 0, rating: 4.9,
    ratingsCount: 86, orders: 320, badge: ProductBadge.hit, categoryIndex: 1,
    descRu: 'Аккумуляторная дрель на сутки. Залог 150 с., доставка по Душанбе.',
    descEn: 'Cordless drill for daily rent. Deposit 150 s., delivery in Dushanbe.',
  ),
  ShopProduct(
    ru: 'Дисковая пила', en: 'Circular saw',
    image: 'assets/images/shop_saw.png', price: 55, oldPrice: 65, rating: 4.8,
    ratingsCount: 64, orders: 210, badge: ProductBadge.hit, categoryIndex: 1,
    descRu: 'Дисковая пила 190 мм. Аренда на 1–7 суток, залог 200 с.',
    descEn: '190mm circular saw. Rent for 1–7 days, deposit 200 s.',
  ),
  ShopProduct(
    ru: 'Перфоратор', en: 'Rotary hammer',
    image: 'assets/images/shop_perforator.png', price: 70, oldPrice: 0, rating: 4.9,
    ratingsCount: 52, orders: 180, badge: ProductBadge.hit, categoryIndex: 1,
    descRu: 'Перфоратор SDS-Plus для бетона и кирпича. Залог 250 с.',
    descEn: 'SDS-Plus rotary hammer for concrete and brick. Deposit 250 s.',
  ),
  ShopProduct(
    ru: 'Угловая шлифмашина', en: 'Angle grinder',
    image: 'assets/images/shop_grinder.png', price: 40, oldPrice: 50, rating: 4.7,
    ratingsCount: 41, orders: 150, badge: ProductBadge.hit, categoryIndex: 1,
    descRu: 'Болгарка 125 мм. Комплект дисков включён.',
    descEn: '125mm angle grinder. Disc set included.',
  ),
  ShopProduct(
    ru: 'Электролобзик', en: 'Jigsaw',
    image: 'assets/images/shop_jigsaw.png', price: 35, oldPrice: 0, rating: 4.8,
    ratingsCount: 38, orders: 120, badge: ProductBadge.isNew, categoryIndex: 1,
    descRu: 'Лобзик для реза дерева, пластика и металла.',
    descEn: 'Jigsaw for wood, plastic and metal.',
  ),
  ShopProduct(
    ru: 'Набор инструментов', en: 'Tool set',
    image: 'assets/images/tool_set.png', price: 30, oldPrice: 0, rating: 4.6,
    ratingsCount: 95, orders: 410, badge: ProductBadge.hit, categoryIndex: 2,
    descRu: 'Набор из 108 предметов для бытового ремонта.',
    descEn: '108-piece set for household repairs.',
  ),
];

class ShopBrand {
  const ShopBrand(this.name, this.color);
  final String name;
  final Color color;
}

const shopBrands = <ShopBrand>[
  ShopBrand('BERALI', Color(0xFF57B55E)),
  ShopBrand('Makita', Color(0xFF00A6A6)),
  ShopBrand('DeWALT', Color(0xFFEFA700)),
  ShopBrand('Bosch', Color(0xFFE3001B)),
  ShopBrand('Metabo', Color(0xFFD0021B)),
  ShopBrand('HILTI', Color(0xFFD2051E)),
];

/// Self-contained localization for the shop screen.
class ShopL10n {
  const ShopL10n({
    required this.title,
    required this.searchHint,
    required this.categories,
    required this.promosTitle,
    required this.seeAll,
    required this.bestSellers,
    required this.brandsTitle,
    required this.recommended,
    required this.advantagesTitle,
    required this.inStock,
    required this.badgeHit,
    required this.badgeNew,
    required this.priceUnit,
    required this.promoTitles,
    required this.promoSubs,
    required this.promoBtns,
    required this.advTitles,
    required this.advSubs,
    required this.newsletterTitle,
    required this.newsletterSub,
    required this.emailHint,
    required this.subscribeBtn,
    required this.subscribed,
    required this.notFound,
    required this.ordersWord,
    required this.ratingsWord,
    required this.buyNow,
    required this.addToCartBtn,
    required this.aboutProduct,
    required this.similarTitle,
    required this.warranty,
    required this.original,
    required this.fastDelivery,
    required this.dealsTitle,
    required this.profileSoon,
    required this.cartTitle,
    required this.cartEmpty,
    required this.addedToCart,
    required this.total,
    required this.checkout,
    required this.orderPlaced,
    required this.deliveryAddress,
    required this.deliveryAddressSub,
    required this.addressHint,
    required this.rentPriceUnit,
    required this.rentBuyNow,
    required this.rentOrderPlaced,
    required this.navShop,
    required this.navCats,
    required this.navDeals,
    required this.navProfile,
    required this.navRent,
    required this.navMore,
    required this.favoritesTitle,
    required this.favoritesEmpty,
    required this.storeAddress,
    required this.checkoutKindShop,
    required this.checkoutKindRent,
  });

  final String title;
  final String searchHint;
  final List<String> categories; // 8 items, index 0 == "All"
  final String promosTitle;
  final String seeAll;
  final String bestSellers;
  final String brandsTitle;
  final String recommended;
  final String advantagesTitle;
  final String inStock;
  final String badgeHit;
  final String badgeNew;
  final String priceUnit;
  final List<String> promoTitles; // 3
  final List<String> promoSubs; // 3
  final List<String> promoBtns; // 3
  final List<String> advTitles; // 4
  final List<String> advSubs; // 4
  final String newsletterTitle;
  final String newsletterSub;
  final String emailHint;
  final String subscribeBtn;
  final String subscribed;
  final String notFound;
  final String ordersWord;
  final String ratingsWord;
  final String buyNow;
  final String addToCartBtn;
  final String aboutProduct;
  final String similarTitle;
  final String warranty;
  final String original;
  final String fastDelivery;
  final String dealsTitle;
  final String profileSoon;
  final String cartTitle;
  final String cartEmpty;
  final String addedToCart;
  final String total;
  final String checkout;
  final String orderPlaced;
  final String deliveryAddress;
  final String deliveryAddressSub;
  final String addressHint;
  final String rentPriceUnit;
  final String rentBuyNow;
  final String rentOrderPlaced;
  final String navShop;
  final String navCats;
  final String navDeals;
  final String navProfile;
  final String navRent;
  final String navMore;
  final String favoritesTitle;
  final String favoritesEmpty;
  final String storeAddress;
  final String checkoutKindShop;
  final String checkoutKindRent;

  static ShopL10n of(AppLocale locale) => _map[locale]!;

  static const _map = {
    AppLocale.ru: ShopL10n(
      title: 'Магазин',
      searchHint: 'Поиск товара',
      categories: ['Все', 'Электроинструмент', 'Ручной инструмент', 'Расходники',
        'Садовая техника', 'Освещение', 'Измерительные приборы', 'Хранение и сумки'],
      promosTitle: 'Акции и спецпредложения',
      seeAll: 'Смотреть все',
      bestSellers: 'Хиты продаж',
      brandsTitle: 'Бренды',
      recommended: 'Рекомендуем для вас',
      advantagesTitle: 'Преимущества нашего магазина',
      inStock: 'в наличии',
      badgeHit: 'ХИТ',
      badgeNew: 'НОВИНКА',
      priceUnit: 'с.',
      promoTitles: ['Скидка до 30%', 'Бесплатная доставка', 'Сезонная распродажа до -40%'],
      promoSubs: ['на электроинструмент BERALI', 'от 300 с.', 'на садовую технику'],
      promoBtns: ['К покупкам', 'Подробнее', 'Смотреть'],
      advTitles: ['Бесплатная доставка', 'Гарантия качества', 'Возврат товара', 'Поддержка 24/7'],
      advSubs: ['от 300 с.', 'до 2 лет', 'в течение 14 дней', 'мы всегда на связи'],
      newsletterTitle: 'Будьте в курсе новинок и акций',
      newsletterSub: 'Подпишитесь на рассылку и получайте лучшие предложения первыми',
      emailHint: 'Ваш e-mail',
      subscribeBtn: 'Подписаться',
      subscribed: 'Вы подписались на рассылку!',
      notFound: 'Ничего не найдено',
      ordersWord: 'заказов',
      ratingsWord: 'оценки',
      buyNow: 'Купить сейчас',
      addToCartBtn: 'В корзину',
      aboutProduct: 'О товаре',
      similarTitle: 'Похожие товары',
      warranty: 'Гарантия 1 год',
      original: 'Оригинал',
      fastDelivery: 'Быстрая доставка',
      dealsTitle: 'Товары по акции',
      profileSoon: 'Профиль скоро появится',
      cartTitle: 'Корзина',
      cartEmpty: 'Корзина пуста',
      addedToCart: 'Добавлено в корзину',
      total: 'Итого',
      checkout: 'Оформить заказ',
      orderPlaced: 'Заказ оформлен! Мы свяжемся с вами.',
      deliveryAddress: 'Адрес доставки',
      deliveryAddressSub: 'Укажите адрес, куда привезти товар',
      addressHint: 'ул. Рудаки 45, Душанбе',
      rentPriceUnit: 'с./сут',
      rentBuyNow: 'Арендовать',
      rentOrderPlaced: 'Заявка на аренду отправлена! Мы свяжемся с вами.',
      navShop: 'Магазин',
      navCats: 'Категории',
      navDeals: 'Акции',
      navProfile: 'Профиль',
      navRent: 'Аренда',
      navMore: 'Ещё',
      favoritesTitle: 'Избранное',
      favoritesEmpty: 'Добавьте инструменты в избранное',
      storeAddress: 'г. Душанбе, ул. Бохтар, 123',
      checkoutKindShop: 'Магазин',
      checkoutKindRent: 'Аренда',
    ),
    AppLocale.en: ShopL10n(
      title: 'Shop',
      searchHint: 'Search products',
      categories: ['All', 'Power tools', 'Hand tools', 'Consumables',
        'Garden equipment', 'Lighting', 'Measuring tools', 'Storage & bags'],
      promosTitle: 'Deals & offers',
      seeAll: 'See all',
      bestSellers: 'Best sellers',
      brandsTitle: 'Brands',
      recommended: 'Recommended for you',
      advantagesTitle: 'Why shop with us',
      inStock: 'in stock',
      badgeHit: 'HOT',
      badgeNew: 'NEW',
      priceUnit: 's.',
      promoTitles: ['Up to 30% off', 'Free delivery', 'Seasonal sale up to -40%'],
      promoSubs: ['on BERALI power tools', 'from 300 s.', 'on garden equipment'],
      promoBtns: ['Shop now', 'Learn more', 'View'],
      advTitles: ['Free delivery', 'Quality warranty', 'Returns', '24/7 support'],
      advSubs: ['from 300 s.', 'up to 2 years', 'within 14 days', 'always in touch'],
      newsletterTitle: 'Stay up to date with deals',
      newsletterSub: 'Subscribe to the newsletter and get the best offers first',
      emailHint: 'Your e-mail',
      subscribeBtn: 'Subscribe',
      subscribed: 'You have subscribed!',
      notFound: 'Nothing found',
      ordersWord: 'orders',
      ratingsWord: 'ratings',
      buyNow: 'Buy now',
      addToCartBtn: 'Add to cart',
      aboutProduct: 'About product',
      similarTitle: 'Similar products',
      warranty: '1 year warranty',
      original: 'Original',
      fastDelivery: 'Fast delivery',
      dealsTitle: 'Products on sale',
      profileSoon: 'Profile coming soon',
      cartTitle: 'Cart',
      cartEmpty: 'Your cart is empty',
      addedToCart: 'Added to cart',
      total: 'Total',
      checkout: 'Checkout',
      orderPlaced: 'Order placed! We will contact you.',
      deliveryAddress: 'Delivery address',
      deliveryAddressSub: 'Enter where to deliver the order',
      addressHint: 'Rudaki St 45, Dushanbe',
      rentPriceUnit: 's./day',
      rentBuyNow: 'Rent now',
      rentOrderPlaced: 'Rental request sent! We will contact you.',
      navShop: 'Shop',
      navCats: 'Categories',
      navDeals: 'Deals',
      navProfile: 'Profile',
      navRent: 'Rent',
      navMore: 'More',
      favoritesTitle: 'Favorites',
      favoritesEmpty: 'Add tools to your favorites',
      storeAddress: '123 Bokhtar St., Dushanbe',
      checkoutKindShop: 'Shop',
      checkoutKindRent: 'Rent',
    ),
    AppLocale.tg: ShopL10n(
      title: 'Мағоза',
      searchHint: 'Ҷустуҷӯи мол',
      categories: ['Ҳама', 'Асбоби барқӣ', 'Асбоби дастӣ', 'Маводи сарфшаванда',
        'Техникаи боғ', 'Равшанӣ', 'Асбобҳои ченкунӣ', 'Нигоҳдорӣ ва сумкаҳо'],
      promosTitle: 'Аксияҳо ва пешниҳодҳо',
      seeAll: 'Ҳама',
      bestSellers: 'Серфурӯштарин',
      brandsTitle: 'Брендҳо',
      recommended: 'Барои шумо тавсия',
      advantagesTitle: 'Бартариятҳои мағозаи мо',
      inStock: 'дар анбор',
      badgeHit: 'ХИТ',
      badgeNew: 'НАВ',
      priceUnit: 'с.',
      promoTitles: ['Тахфиф то 30%', 'Расонидани ройгон', 'Фурӯши мавсимӣ то -40%'],
      promoSubs: ['ба асбоби барқии BERALI', 'аз 300 с.', 'ба техникаи боғ'],
      promoBtns: ['Ба харид', 'Муфассал', 'Дидан'],
      advTitles: ['Расонидани ройгон', 'Кафолати сифат', 'Бозгашти мол', 'Дастгирии 24/7'],
      advSubs: ['аз 300 с.', 'то 2 сол', 'дар 14 рӯз', 'ҳамеша дар тамос'],
      newsletterTitle: 'Аз навигариҳо ва аксияҳо огоҳ бошед',
      newsletterSub: 'Обуна шавед ва беҳтарин пешниҳодҳоро аввал гиред',
      emailHint: 'E-mail-и шумо',
      subscribeBtn: 'Обуна шудан',
      subscribed: 'Шумо обуна шудед!',
      notFound: 'Чизе ёфт нашуд',
      ordersWord: 'фармоиш',
      ratingsWord: 'баҳо',
      buyNow: 'Ҳозир харидан',
      addToCartBtn: 'Ба сабад',
      aboutProduct: 'Дар бораи мол',
      similarTitle: 'Молҳои монанд',
      warranty: 'Кафолат 1 сол',
      original: 'Аслӣ',
      fastDelivery: 'Расонидани зуд',
      dealsTitle: 'Молҳои аксиявӣ',
      profileSoon: 'Профил ба зудӣ меояд',
      cartTitle: 'Сабад',
      cartEmpty: 'Сабад холӣ аст',
      addedToCart: 'Ба сабад илова шуд',
      total: 'Ҳамагӣ',
      checkout: 'Ба расмият даровардан',
      orderPlaced: 'Фармоиш қабул шуд! Мо бо шумо тамос мегирем.',
      deliveryAddress: 'Суроғаи расонидан',
      deliveryAddressSub: 'Суроғаи расонидани молро нависед',
      addressHint: 'кучаи Рӯдакӣ 45, Душанбе',
      rentPriceUnit: 'с./рӯз',
      rentBuyNow: 'Иҷора кардан',
      rentOrderPlaced: 'Дархости иҷора фиристода шуд!',
      navShop: 'Мағоза',
      navCats: 'Категорияҳо',
      navDeals: 'Аксияҳо',
      navProfile: 'Профил',
      navRent: 'Иҷора',
      navMore: 'Бештар',
      favoritesTitle: 'Дӯстдошта',
      favoritesEmpty: 'Асбобҳоро ба дӯстдошта илова кунед',
      storeAddress: 'ш. Душанбе, кӯчаи Бохтар, 123',
      checkoutKindShop: 'Мағоза',
      checkoutKindRent: 'Иҷора',
    ),
    AppLocale.zh: ShopL10n(
      title: '商店',
      searchHint: '搜索商品',
      categories: ['全部', '电动工具', '手动工具', '耗材',
        '园艺设备', '照明', '测量仪器', '收纳与包'],
      promosTitle: '优惠与特惠',
      seeAll: '查看全部',
      bestSellers: '热销',
      brandsTitle: '品牌',
      recommended: '为您推荐',
      advantagesTitle: '本店优势',
      inStock: '有货',
      badgeHit: '热销',
      badgeNew: '新品',
      priceUnit: '索',
      promoTitles: ['最高3折优惠', '免费配送', '季节促销最高6折'],
      promoSubs: ['BERALI电动工具', '满300索莫尼', '园艺设备'],
      promoBtns: ['去购买', '了解更多', '查看'],
      advTitles: ['免费配送', '质量保证', '退货', '24/7支持'],
      advSubs: ['满300索莫尼', '长达2年', '14天内', '随时联系'],
      newsletterTitle: '及时了解新品与优惠',
      newsletterSub: '订阅邮件，第一时间获取最优惠的信息',
      emailHint: '您的邮箱',
      subscribeBtn: '订阅',
      subscribed: '您已成功订阅！',
      notFound: '未找到商品',
      ordersWord: '订单',
      ratingsWord: '评价',
      buyNow: '立即购买',
      addToCartBtn: '加入购物车',
      aboutProduct: '商品详情',
      similarTitle: '相似商品',
      warranty: '保修1年',
      original: '正品',
      fastDelivery: '快速配送',
      dealsTitle: '促销商品',
      profileSoon: '个人中心即将上线',
      cartTitle: '购物车',
      cartEmpty: '购物车为空',
      addedToCart: '已加入购物车',
      total: '合计',
      checkout: '去结算',
      orderPlaced: '下单成功！我们会与您联系。',
      deliveryAddress: '配送地址',
      deliveryAddressSub: '请输入商品配送地址',
      addressHint: '鲁达基街45号，杜尚别',
      rentPriceUnit: '索莫尼/天',
      rentBuyNow: '租赁',
      rentOrderPlaced: '租赁申请已发送！',
      navShop: '商店',
      navCats: '分类',
      navDeals: '优惠',
      navProfile: '个人',
      navRent: '租赁',
      navMore: '更多',
      favoritesTitle: '收藏',
      favoritesEmpty: '将工具添加到收藏',
      storeAddress: '杜尚别市博赫塔尔街123号',
      checkoutKindShop: '商城',
      checkoutKindRent: '租赁',
    ),
  };
}

/// Icon for a shop category (index into ShopL10n.categories).
const shopCategoryIcons = <IconData>[
  LucideIcons.layout_grid, // All
  LucideIcons.drill, // Power tools
  LucideIcons.wrench, // Hand tools
  LucideIcons.package_2, // Consumables
  LucideIcons.trees, // Garden
  LucideIcons.lightbulb, // Lighting
  LucideIcons.ruler, // Measuring
  LucideIcons.box, // Storage
];

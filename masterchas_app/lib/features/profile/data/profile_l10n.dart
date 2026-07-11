import '../../../core/l10n/app_locale.dart';
import 'account_level.dart';

class ProfileL10n {
  const ProfileL10n({
    required this.title,
    required this.online,
    required this.orders,
    required this.favorites,
    required this.spent,
    required this.unit,
    required this.accountLevel,
    required this.toGoldTpl,
    required this.bonusesTitle,
    required this.bonusRate,
    required this.orderHistory,
    required this.paymentMethods,
    required this.addCard,
    required this.myAddresses,
    required this.security,
    required this.notifications,
    required this.support,
    required this.darkTheme,
    required this.darkThemeSub,
    required this.chooseLanguage,
    required this.soon,
    required this.cardNumber,
    required this.expiry,
    required this.cvv,
    required this.holder,
    required this.save,
    required this.delete,
    required this.emptyCards,
    required this.emptyAddresses,
    required this.emptyOrders,
    required this.emptyFavorites,
    required this.addressTitle,
    required this.city,
    required this.street,
    required this.details,
    required this.comment,
    required this.addAddress,
    required this.biometric,
    required this.pinLock,
    required this.twofa,
    required this.changePin,
    required this.pushNotif,
    required this.emailNotif,
    required this.smsNotif,
    required this.promoNotif,
    required this.orderNotif,
    required this.callSupport,
    required this.writeSupport,
    required this.send,
    required this.messageHint,
    required this.messageSent,
    required this.faqTitle,
    required this.faq1q,
    required this.faq1a,
    required this.faq2q,
    required this.faq2a,
    required this.spentTitle,
    required this.totalSpent,
    required this.totalDiscount,
    required this.totalBonus,
    required this.chartTitle,
    required this.perDay,
    required this.itemsWord,
    required this.discountWord,
    required this.bonusWord,
    required this.invalidCard,
    required this.cardSaved,
    required this.addressSaved,
    required this.addToCart,
    required this.levelLabelTpl,
    required this.pointsToNextTpl,
    required this.maxLevel,
    required this.tierBronze,
    required this.tierSilver,
    required this.tierGold,
    required this.tierPlatinum,
    required this.referFriend,
    required this.referBonus,
    required this.promoCopiedTpl,
    required this.dailyQuests,
    required this.bonusesRewardTpl,
    required this.questReview,
    required this.questShare,
    required this.questOrderToday,
    required this.achievementsTitle,
    required this.achFirstOrder,
    required this.ach5Orders,
    required this.ach10Orders,
    required this.achReview,
    required this.achRefer,
    required this.signOut,
    required this.signOutTitle,
    required this.signOutMsg,
    required this.cancel,
    required this.defaultUser,
    required this.langRussian,
    required this.langEnglish,
    required this.langTajik,
    required this.langChinese,
  });

  final String title;
  final String online;
  final String orders;
  final String favorites;
  final String spent;
  final String unit;
  final String accountLevel;
  final String toGoldTpl;
  final String bonusesTitle;
  final String bonusRate;
  final String orderHistory;
  final String paymentMethods;
  final String addCard;
  final String myAddresses;
  final String security;
  final String notifications;
  final String support;
  final String darkTheme;
  final String darkThemeSub;
  final String chooseLanguage;
  final String soon;
  final String cardNumber;
  final String expiry;
  final String cvv;
  final String holder;
  final String save;
  final String delete;
  final String emptyCards;
  final String emptyAddresses;
  final String emptyOrders;
  final String emptyFavorites;
  final String addressTitle;
  final String city;
  final String street;
  final String details;
  final String comment;
  final String addAddress;
  final String biometric;
  final String pinLock;
  final String twofa;
  final String changePin;
  final String pushNotif;
  final String emailNotif;
  final String smsNotif;
  final String promoNotif;
  final String orderNotif;
  final String callSupport;
  final String writeSupport;
  final String send;
  final String messageHint;
  final String messageSent;
  final String faqTitle;
  final String faq1q;
  final String faq1a;
  final String faq2q;
  final String faq2a;
  final String spentTitle;
  final String totalSpent;
  final String totalDiscount;
  final String totalBonus;
  final String chartTitle;
  final String perDay;
  final String itemsWord;
  final String discountWord;
  final String bonusWord;
  final String invalidCard;
  final String cardSaved;
  final String addressSaved;
  final String addToCart;
  final String levelLabelTpl;
  final String pointsToNextTpl;
  final String maxLevel;
  final String tierBronze;
  final String tierSilver;
  final String tierGold;
  final String tierPlatinum;
  final String referFriend;
  final String referBonus;
  final String promoCopiedTpl;
  final String dailyQuests;
  final String bonusesRewardTpl;
  final String questReview;
  final String questShare;
  final String questOrderToday;
  final String achievementsTitle;
  final String achFirstOrder;
  final String ach5Orders;
  final String ach10Orders;
  final String achReview;
  final String achRefer;
  final String signOut;
  final String signOutTitle;
  final String signOutMsg;
  final String cancel;
  final String defaultUser;
  final String langRussian;
  final String langEnglish;
  final String langTajik;
  final String langChinese;

  String toGold(int n) => toGoldTpl.replaceFirst('{n}', '$n');

  String tierName(AccountTier tier) => switch (tier) {
        AccountTier.bronze => tierBronze,
        AccountTier.silver => tierSilver,
        AccountTier.gold => tierGold,
        AccountTier.platinum => tierPlatinum,
      };

  String levelLine(AccountTier tier) =>
      levelLabelTpl.replaceFirst('{tier}', tierName(tier));

  String pointsToNextLine(AccountTier nextTier, int points) =>
      pointsToNextTpl
          .replaceFirst('{tier}', tierName(nextTier))
          .replaceFirst('{n}', '$points');

  String promoCopied(String code) =>
      promoCopiedTpl.replaceFirst('{code}', code);

  String bonusesReward(int points) =>
      bonusesRewardTpl.replaceFirst('{n}', '$points');

  static ProfileL10n of(AppLocale locale) => _map[locale]!;

  static const _ru = ProfileL10n(
    title: 'Профиль',
    online: 'Онлайн',
    orders: 'Заказы',
    favorites: 'Избранное',
    spent: 'Потрачено',
    unit: 'с.',
    accountLevel: 'Уровень аккаунта',
    toGoldTpl: 'До Gold осталось {n} баллов',
    bonusesTitle: 'Бонусы и баллы',
    bonusRate: '1 балл = 1 сомони',
    orderHistory: 'История заказов',
    paymentMethods: 'Методы оплаты',
    addCard: 'Добавить',
    myAddresses: 'Мои адреса',
    security: 'Безопасность',
    notifications: 'Уведомления',
    support: 'Поддержка',
    darkTheme: 'Тёмная тема',
    darkThemeSub: 'Включить тёмный интерфейс',
    chooseLanguage: 'Выберите язык',
    soon: 'Скоро будет доступно',
    cardNumber: 'Номер карты (16 цифр)',
    expiry: 'Срок (ММ/ГГ)',
    cvv: 'CVV',
    holder: 'Имя на карте',
    save: 'Сохранить',
    delete: 'Удалить',
    emptyCards: 'Карт пока нет. Добавьте первую карту.',
    emptyAddresses: 'Адресов пока нет. Добавьте адрес доставки.',
    emptyOrders: 'Заказов пока нет.',
    emptyFavorites: 'В избранном пока пусто.',
    addressTitle: 'Название (Дом, Работа)',
    city: 'Город',
    street: 'Улица',
    details: 'Дом, квартира, подъезд',
    comment: 'Комментарий для курьера',
    addAddress: 'Добавить адрес',
    biometric: 'Вход по отпечатку',
    pinLock: 'PIN-код приложения',
    twofa: 'Двухфакторная защита',
    changePin: 'Сменить PIN',
    pushNotif: 'Push-уведомления',
    emailNotif: 'E-mail уведомления',
    smsNotif: 'SMS уведомления',
    promoNotif: 'Акции и скидки',
    orderNotif: 'Статус заказов',
    callSupport: 'Позвонить',
    writeSupport: 'Написать в поддержку',
    send: 'Отправить',
    messageHint: 'Опишите ваш вопрос...',
    messageSent: 'Сообщение отправлено!',
    faqTitle: 'Частые вопросы',
    faq1q: 'Как оформить заказ?',
    faq1a: 'Добавьте товары в корзину и нажмите «Оформить заказ».',
    faq2q: 'Как вернуть товар?',
    faq2a: 'В течение 14 дней через раздел «Поддержка».',
    spentTitle: 'Расходы',
    totalSpent: 'Всего потрачено',
    totalDiscount: 'Скидки',
    totalBonus: 'Бонусы',
    chartTitle: 'Расходы за 7 дней',
    perDay: 'за день',
    itemsWord: 'тов.',
    discountWord: 'скидка',
    bonusWord: 'бонус',
    invalidCard: 'Проверьте данные карты',
    cardSaved: 'Карта добавлена',
    addressSaved: 'Адрес сохранён',
    addToCart: 'В корзину',
    levelLabelTpl: 'Уровень: {tier}',
    pointsToNextTpl: 'До «{tier}» осталось {n} с.',
    maxLevel: 'Максимальный уровень!',
    tierBronze: 'Бронза',
    tierSilver: 'Серебро',
    tierGold: 'Золото',
    tierPlatinum: 'Платина',
    referFriend: 'Приведи друга',
    referBonus: 'Вы и друг получите по 50 сомони',
    promoCopiedTpl: 'Промокод {code} скопирован',
    dailyQuests: 'Задания дня',
    bonusesRewardTpl: '+{n} бонусов',
    questReview: 'Оставь отзыв о мастере',
    questShare: 'Поделись приложением',
    questOrderToday: 'Закажи услугу сегодня',
    achievementsTitle: 'Достижения',
    achFirstOrder: 'Первый\nзаказ',
    ach5Orders: '5\nзаказов',
    ach10Orders: '10\nзаказов',
    achReview: 'Отзыв\nоставлен',
    achRefer: 'Пригласил\nдруга',
    signOut: 'Выйти из аккаунта',
    signOutTitle: 'Выйти?',
    signOutMsg: 'Вы выйдете из аккаунта',
    cancel: 'Отмена',
    defaultUser: 'Пользователь',
    langRussian: 'Русский',
    langEnglish: 'English',
    langTajik: 'Тоҷикӣ',
    langChinese: '中文',
  );

  static const _en = ProfileL10n(
    title: 'Profile',
    online: 'Online',
    orders: 'Orders',
    favorites: 'Favorites',
    spent: 'Spent',
    unit: 's.',
    accountLevel: 'Account level',
    toGoldTpl: '{n} points left to Gold',
    bonusesTitle: 'Bonuses & points',
    bonusRate: '1 point = 1 somoni',
    orderHistory: 'Order history',
    paymentMethods: 'Payment methods',
    addCard: 'Add',
    myAddresses: 'My addresses',
    security: 'Security',
    notifications: 'Notifications',
    support: 'Support',
    darkTheme: 'Dark theme',
    darkThemeSub: 'Enable dark interface',
    chooseLanguage: 'Choose language',
    soon: 'Coming soon',
    cardNumber: 'Card number (16 digits)',
    expiry: 'Expiry (MM/YY)',
    cvv: 'CVV',
    holder: 'Name on card',
    save: 'Save',
    delete: 'Delete',
    emptyCards: 'No cards yet. Add your first card.',
    emptyAddresses: 'No addresses yet. Add a delivery address.',
    emptyOrders: 'No orders yet.',
    emptyFavorites: 'Favorites is empty.',
    addressTitle: 'Label (Home, Work)',
    city: 'City',
    street: 'Street',
    details: 'Building, apartment',
    comment: 'Comment for courier',
    addAddress: 'Add address',
    biometric: 'Biometric login',
    pinLock: 'App PIN',
    twofa: 'Two-factor auth',
    changePin: 'Change PIN',
    pushNotif: 'Push notifications',
    emailNotif: 'Email notifications',
    smsNotif: 'SMS notifications',
    promoNotif: 'Deals & discounts',
    orderNotif: 'Order status',
    callSupport: 'Call',
    writeSupport: 'Contact support',
    send: 'Send',
    messageHint: 'Describe your question...',
    messageSent: 'Message sent!',
    faqTitle: 'FAQ',
    faq1q: 'How to place an order?',
    faq1a: 'Add items to cart and tap Checkout.',
    faq2q: 'How to return an item?',
    faq2a: 'Within 14 days via Support.',
    spentTitle: 'Spending',
    totalSpent: 'Total spent',
    totalDiscount: 'Discounts',
    totalBonus: 'Bonuses',
    chartTitle: 'Last 7 days',
    perDay: 'per day',
    itemsWord: 'items',
    discountWord: 'discount',
    bonusWord: 'bonus',
    invalidCard: 'Check card details',
    cardSaved: 'Card added',
    addressSaved: 'Address saved',
    addToCart: 'Add to cart',
    levelLabelTpl: 'Level: {tier}',
    pointsToNextTpl: '{n} s. left until «{tier}»',
    maxLevel: 'Maximum level!',
    tierBronze: 'Bronze',
    tierSilver: 'Silver',
    tierGold: 'Gold',
    tierPlatinum: 'Platinum',
    referFriend: 'Refer a friend',
    referBonus: 'You and your friend get 50 somoni each',
    promoCopiedTpl: 'Promo code {code} copied',
    dailyQuests: 'Daily quests',
    bonusesRewardTpl: '+{n} bonuses',
    questReview: 'Leave a review about a master',
    questShare: 'Share the app',
    questOrderToday: 'Order a service today',
    achievementsTitle: 'Achievements',
    achFirstOrder: 'First\norder',
    ach5Orders: '5\norders',
    ach10Orders: '10\norders',
    achReview: 'Review\nleft',
    achRefer: 'Invited\na friend',
    signOut: 'Sign out',
    signOutTitle: 'Sign out?',
    signOutMsg: 'You will be signed out of your account',
    cancel: 'Cancel',
    defaultUser: 'User',
    langRussian: 'Русский',
    langEnglish: 'English',
    langTajik: 'Тоҷикӣ',
    langChinese: '中文',
  );

  static const _tg = ProfileL10n(
    title: 'Профил',
    online: 'Онлайн',
    orders: 'Фармоишҳо',
    favorites: 'Дӯстдошта',
    spent: 'Сарф шуд',
    unit: 'с.',
    accountLevel: 'Сатҳи ҳисоб',
    toGoldTpl: 'То Gold {n} хол мондааст',
    bonusesTitle: 'Бонусҳо ва холҳо',
    bonusRate: '1 хол = 1 сомонӣ',
    orderHistory: 'Таърихи фармоишҳо',
    paymentMethods: 'Усулҳои пардохт',
    addCard: 'Илова',
    myAddresses: 'Суроғаҳои ман',
    security: 'Амният',
    notifications: 'Огоҳиномаҳо',
    support: 'Дастгирӣ',
    darkTheme: 'Мавзӯи торик',
    darkThemeSub: 'Фаъол кардани интерфейси торик',
    chooseLanguage: 'Забонро интихоб кунед',
    soon: 'Ба зудӣ дастрас мешавад',
    cardNumber: 'Рақами корт (16 рақам)',
    expiry: 'Мӯҳлат (ММ/СС)',
    cvv: 'CVV',
    holder: 'Ном дар корт',
    save: 'Захира',
    delete: 'Нест кардан',
    emptyCards: 'Корт нест. Аввалин кортро илова кунед.',
    emptyAddresses: 'Суроға нест. Суроғаи расониданро илова кунед.',
    emptyOrders: 'Фармоиш нест.',
    emptyFavorites: 'Дӯстдошта холӣ аст.',
    addressTitle: 'Ном (Хона, Кор)',
    city: 'Шаҳр',
    street: 'Кӯча',
    details: 'Хона, хонаи хоб, дар',
    comment: 'Шарҳ барои курер',
    addAddress: 'Иловаи суроға',
    biometric: 'Воридшавӣ бо из',
    pinLock: 'PIN-и барнома',
    twofa: 'Аутентификатсияи дукарата',
    changePin: 'Ивази PIN',
    pushNotif: 'Push-огоҳинома',
    emailNotif: 'E-mail огоҳинома',
    smsNotif: 'SMS огоҳинома',
    promoNotif: 'Аксияҳо',
    orderNotif: 'Ҳолати фармоиш',
    callSupport: 'Занг',
    writeSupport: 'Ба дастгирӣ навиштан',
    send: 'Ирсол',
    messageHint: 'Саволи худро нависед...',
    messageSent: 'Паём фиристода шуд!',
    faqTitle: 'Саволҳои зуд-зуд',
    faq1q: 'Чӣ тавр фармоиш диҳам?',
    faq1a: 'Молҳоро ба сабад илова кунед ва «Ба расмият даровардан»-ро пахш кунед.',
    faq2q: 'Чӣ тавр молро баргардонам?',
    faq2a: 'Дар 14 рӯз тавассути «Дастгирӣ».',
    spentTitle: 'Хароҷот',
    totalSpent: 'Ҳамагӣ сарф шуд',
    totalDiscount: 'Тахфифҳо',
    totalBonus: 'Бонусҳо',
    chartTitle: '7 рӯзи охир',
    perDay: 'дар рӯз',
    itemsWord: 'мол',
    discountWord: 'тахфиф',
    bonusWord: 'бонус',
    invalidCard: 'Маълумоти кортро санҷед',
    cardSaved: 'Корт илова шуд',
    addressSaved: 'Суроға захира шуд',
    addToCart: 'Ба сабад',
    levelLabelTpl: 'Сатҳ: {tier}',
    pointsToNextTpl: 'То «{tier}» {n} с. мондааст',
    maxLevel: 'Сатҳи максималӣ!',
    tierBronze: 'Бронза',
    tierSilver: 'Нуқра',
    tierGold: 'Тилло',
    tierPlatinum: 'Платина',
    referFriend: 'Дӯстро биёред',
    referBonus: 'Шумо ва дӯстатон ҳар як 50 сомонӣ мегиред',
    promoCopiedTpl: 'Рамзи промо {code} нусха бардошта шуд',
    dailyQuests: 'Вазифаҳои рӯз',
    bonusesRewardTpl: '+{n} бонус',
    questReview: 'Ба маъмур баҳо гузоред',
    questShare: 'Барномаро мубодила кунед',
    questOrderToday: 'Имрӯз хизмат фармоиш диҳед',
    achievementsTitle: 'Дастовардҳо',
    achFirstOrder: 'Фармоиши\nаввал',
    ach5Orders: '5\nфармоиш',
    ach10Orders: '10\nфармоиш',
    achReview: 'Баҳо\nгузошта шуд',
    achRefer: 'Дӯстро\nдаъват кард',
    signOut: 'Баромадан',
    signOutTitle: 'Баромадан?',
    signOutMsg: 'Шумо аз ҳисоб баромада мешавед',
    cancel: 'Бекор',
    defaultUser: 'Корбар',
    langRussian: 'Русский',
    langEnglish: 'English',
    langTajik: 'Тоҷикӣ',
    langChinese: '中文',
  );

  static const _zh = ProfileL10n(
    title: '个人中心',
    online: '在线',
    orders: '订单',
    favorites: '收藏',
    spent: '已花费',
    unit: '索',
    accountLevel: '账户等级',
    toGoldTpl: '距离 Gold 还差 {n} 积分',
    bonusesTitle: '奖励与积分',
    bonusRate: '1 积分 = 1 索莫尼',
    orderHistory: '订单历史',
    paymentMethods: '支付方式',
    addCard: '添加',
    myAddresses: '我的地址',
    security: '安全',
    notifications: '通知',
    support: '客服支持',
    darkTheme: '深色主题',
    darkThemeSub: '启用深色界面',
    chooseLanguage: '选择语言',
    soon: '即将推出',
    cardNumber: '卡号（16位）',
    expiry: '有效期（月/年）',
    cvv: 'CVV',
    holder: '持卡人姓名',
    save: '保存',
    delete: '删除',
    emptyCards: '暂无银行卡，请添加。',
    emptyAddresses: '暂无地址，请添加配送地址。',
    emptyOrders: '暂无订单。',
    emptyFavorites: '收藏为空。',
    addressTitle: '标签（家、公司）',
    city: '城市',
    street: '街道',
    details: '楼栋、门牌',
    comment: '给快递员的备注',
    addAddress: '添加地址',
    biometric: '指纹登录',
    pinLock: '应用 PIN',
    twofa: '双重验证',
    changePin: '更改 PIN',
    pushNotif: '推送通知',
    emailNotif: '邮件通知',
    smsNotif: '短信通知',
    promoNotif: '优惠促销',
    orderNotif: '订单状态',
    callSupport: '拨打电话',
    writeSupport: '联系客服',
    send: '发送',
    messageHint: '描述您的问题...',
    messageSent: '消息已发送！',
    faqTitle: '常见问题',
    faq1q: '如何下单？',
    faq1a: '将商品加入购物车并点击结算。',
    faq2q: '如何退货？',
    faq2a: '14天内通过客服申请。',
    spentTitle: '消费',
    totalSpent: '总消费',
    totalDiscount: '优惠',
    totalBonus: '积分',
    chartTitle: '近7天',
    perDay: '每天',
    itemsWord: '件',
    discountWord: '优惠',
    bonusWord: '积分',
    invalidCard: '请检查卡信息',
    cardSaved: '卡已添加',
    addressSaved: '地址已保存',
    addToCart: '加入购物车',
    levelLabelTpl: '等级：{tier}',
    pointsToNextTpl: '距离「{tier}」还差 {n} 索',
    maxLevel: '已达最高等级！',
    tierBronze: '青铜',
    tierSilver: '白银',
    tierGold: '黄金',
    tierPlatinum: '铂金',
    referFriend: '邀请好友',
    referBonus: '您和好友各得 50 索莫尼',
    promoCopiedTpl: '优惠码 {code} 已复制',
    dailyQuests: '每日任务',
    bonusesRewardTpl: '+{n} 积分',
    questReview: '给师傅留下评价',
    questShare: '分享应用',
    questOrderToday: '今天下单服务',
    achievementsTitle: '成就',
    achFirstOrder: '首单',
    ach5Orders: '5单',
    ach10Orders: '10单',
    achReview: '已评价',
    achRefer: '邀请好友',
    signOut: '退出登录',
    signOutTitle: '退出？',
    signOutMsg: '您将退出当前账户',
    cancel: '取消',
    defaultUser: '用户',
    langRussian: 'Русский',
    langEnglish: 'English',
    langTajik: 'Тоҷикӣ',
    langChinese: '中文',
  );

  static const _map = {
    AppLocale.ru: _ru,
    AppLocale.en: _en,
    AppLocale.tg: _tg,
    AppLocale.zh: _zh,
  };
}

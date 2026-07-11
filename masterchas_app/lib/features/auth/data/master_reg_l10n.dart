import '../../../core/l10n/app_locale.dart';

class MasterRegL10n {
  const MasterRegL10n({
    required this.becomeMaster,
    required this.stepData,
    required this.stepSkills,
    required this.stepPhoto,
    required this.applicationTitle,
    required this.nameTitle,
    required this.applicationSub,
    required this.nameSub,
    required this.phoneLabel,
    required this.passwordLabel,
    required this.lastName,
    required this.firstName,
    required this.patronymic,
    required this.selfEmployed,
    required this.companyHint,
    required this.continueBtn,
    required this.termsPrefix,
    required this.termsOfUse,
    required this.termsAnd,
    required this.privacyPolicy,
    required this.loginTitle,
    required this.loginSub,
    required this.codeLabel,
    required this.loggingIn,
    required this.loginBtn,
    required this.codeHint,
    required this.orDivider,
    required this.applySub,
    required this.skillsTitle,
    required this.skillsSub,
    required this.selectedServicesTpl,
    required this.saving,
    required this.skillsContinue,
  });

  final String becomeMaster;
  final String stepData;
  final String stepSkills;
  final String stepPhoto;
  final String applicationTitle;
  final String nameTitle;
  final String applicationSub;
  final String nameSub;
  final String phoneLabel;
  final String passwordLabel;
  final String lastName;
  final String firstName;
  final String patronymic;
  final String selfEmployed;
  final String companyHint;
  final String continueBtn;
  final String termsPrefix;
  final String termsOfUse;
  final String termsAnd;
  final String privacyPolicy;
  final String loginTitle;
  final String loginSub;
  final String codeLabel;
  final String loggingIn;
  final String loginBtn;
  final String codeHint;
  final String orDivider;
  final String applySub;
  final String skillsTitle;
  final String skillsSub;
  final String selectedServicesTpl;
  final String saving;
  final String skillsContinue;

  String selectedServices(int n) => selectedServicesTpl.replaceFirst('{n}', '$n');

  static MasterRegL10n of(AppLocale locale) => _map[locale]!;

  static const _ru = MasterRegL10n(
    becomeMaster: 'Стать мастером',
    stepData: 'Данные',
    stepSkills: 'Навыки',
    stepPhoto: 'Фото',
    applicationTitle: 'Заявка мастера',
    nameTitle: 'Как вас зовут?',
    applicationSub:
        'Заполните данные для подачи заявки. После проверки вы получите код для входа в кабинет.',
    nameSub:
        'Пожалуйста, укажите ваши фамилию, имя и отчество точно так, как указано в паспорте. Это необходимо для проверки.',
    phoneLabel: 'Номер телефона',
    passwordLabel: 'Пароль (мин. 8 символов)',
    lastName: 'Фамилия',
    firstName: 'Имя',
    patronymic: 'Отчество',
    selfEmployed: 'Я частный или самозанятый специалист',
    companyHint: 'Введите название компании *',
    continueBtn: 'Продолжить',
    termsPrefix: 'Я принимаю ',
    termsOfUse: 'Условия использования',
    termsAnd: ' и ',
    privacyPolicy: 'Политику конфиденциальности',
    loginTitle: 'Вход для мастера',
    loginSub: 'Введите номер телефона и код входа из личного кабинета',
    codeLabel: 'Код входа',
    loggingIn: 'Вход...',
    loginBtn: 'Войти в кабинет',
    codeHint:
        'Код выдаётся при регистрации мастера. Если забыли код — обратитесь в поддержку.',
    orDivider: 'или',
    applySub:
        'Станьте мастером на Master.tj — укажите ФИО, услуги и дождитесь одобрения',
    skillsTitle: 'Чем вы занимаетесь?',
    skillsSub:
        'Укажите все ваши навыки и специальности, чтобы вам поступало больше подходящих заказов.',
    selectedServicesTpl: 'Выбрано услуг: {n}',
    saving: 'Сохранение...',
    skillsContinue: 'Продолжить',
  );

  static const _en = MasterRegL10n(
    becomeMaster: 'Become a master',
    stepData: 'Details',
    stepSkills: 'Skills',
    stepPhoto: 'Photo',
    applicationTitle: 'Master application',
    nameTitle: 'What is your name?',
    applicationSub:
        'Fill in your details to apply. After review you will receive a login code.',
    nameSub:
        'Please enter your last, first and patronymic names exactly as in your passport.',
    phoneLabel: 'Phone number',
    passwordLabel: 'Password (min. 8 characters)',
    lastName: 'Last name',
    firstName: 'First name',
    patronymic: 'Patronymic',
    selfEmployed: 'I am a private or self-employed specialist',
    companyHint: 'Enter company name *',
    continueBtn: 'Continue',
    termsPrefix: 'I accept the ',
    termsOfUse: 'Terms of use',
    termsAnd: ' and ',
    privacyPolicy: 'Privacy policy',
    loginTitle: 'Master login',
    loginSub: 'Enter your phone number and login code from your account',
    codeLabel: 'Login code',
    loggingIn: 'Signing in...',
    loginBtn: 'Sign in',
    codeHint:
        'The code is issued when you register as a master. If you forgot it — contact support.',
    orDivider: 'or',
    applySub:
        'Become a master on Master.tj — enter your name, services and wait for approval',
    skillsTitle: 'What do you do?',
    skillsSub:
        'Select all your skills and specialties to receive more matching orders.',
    selectedServicesTpl: 'Services selected: {n}',
    saving: 'Saving...',
    skillsContinue: 'Continue',
  );

  static const _tg = MasterRegL10n(
    becomeMaster: 'Маъмур шудан',
    stepData: 'Маълумот',
    stepSkills: 'Малакаҳо',
    stepPhoto: 'Акс',
    applicationTitle: 'Дархости маъмур',
    nameTitle: 'Номи шумо чист?',
    applicationSub:
        'Маълумотро барои дархост пур кунед. Пас аз санҷиш код барои воридшавӣ дода мешавад.',
    nameSub:
        'Лутфан насаб, ном ва номи падарро мисли дар шиноснома нависед.',
    phoneLabel: 'Рақами телефон',
    passwordLabel: 'Парол (ҳадди ақал 8 аломат)',
    lastName: 'Насаб',
    firstName: 'Ном',
    patronymic: 'Номи падар',
    selfEmployed: 'Ман мутахассиси хусусӣ ё худкор ҳастам',
    companyHint: 'Номи ширкатро ворид кунед *',
    continueBtn: 'Идома додан',
    termsPrefix: 'Ман қабул мекунам ',
    termsOfUse: 'Шартҳои истифода',
    termsAnd: ' ва ',
    privacyPolicy: 'Сиёсати махфият',
    loginTitle: 'Воридшавии маъмур',
    loginSub: 'Рақами телефон ва коди воридшавиро аз кабинет ворид кунед',
    codeLabel: 'Коди воридшавӣ',
    loggingIn: 'Воридшавӣ...',
    loginBtn: 'Ворид шудан',
    codeHint:
        'Код ҳангоми бақайдгирии маъмур дода мешавад. Агар фаромӯш карда бошед — ба дастгирӣ муроҷиат кунед.',
    orDivider: 'ё',
    applySub:
        'Маъмур шавед дар Master.tj — ФИО, хизматҳо ва интизори тасдиқ бошед',
    skillsTitle: 'Шумо чӣ кор мекунед?',
    skillsSub:
        'Ҳамаи малакаҳо ва ихтисосҳои худро интихоб кунед, то фармоишҳои мувофиқ бештар гиред.',
    selectedServicesTpl: 'Хизматҳои интихобшуда: {n}',
    saving: 'Захира...',
    skillsContinue: 'Идома додан',
  );

  static const _zh = MasterRegL10n(
    becomeMaster: '成为师傅',
    stepData: '资料',
    stepSkills: '技能',
    stepPhoto: '照片',
    applicationTitle: '师傅申请',
    nameTitle: '您的姓名？',
    applicationSub: '填写资料提交申请。审核通过后将获得登录码。',
    nameSub: '请按护照上的信息准确填写姓、名和父名。',
    phoneLabel: '手机号码',
    passwordLabel: '密码（至少8位）',
    lastName: '姓',
    firstName: '名',
    patronymic: '父名',
    selfEmployed: '我是个人或自雇师傅',
    companyHint: '请输入公司名称 *',
    continueBtn: '继续',
    termsPrefix: '我接受',
    termsOfUse: '使用条款',
    termsAnd: '和',
    privacyPolicy: '隐私政策',
    loginTitle: '师傅登录',
    loginSub: '请输入手机号和账户登录码',
    codeLabel: '登录码',
    loggingIn: '登录中...',
    loginBtn: '进入账户',
    codeHint: '注册师傅时发放登录码。如忘记请联系客服。',
    orDivider: '或',
    applySub: '在 Master.tj 成为师傅 — 填写姓名和服务，等待审核',
    skillsTitle: '您从事什么工作？',
    skillsSub: '选择所有技能和专长，以获得更多匹配的订单。',
    selectedServicesTpl: '已选服务：{n}',
    saving: '保存中...',
    skillsContinue: '继续',
  );

  static const _map = {
    AppLocale.ru: _ru,
    AppLocale.en: _en,
    AppLocale.tg: _tg,
    AppLocale.zh: _zh,
  };
}

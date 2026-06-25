import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/l10n/app_locale.dart';

/// Single service with multilingual name, unit and price range (in somoni).
class ServiceItem {
  const ServiceItem(
    this.ru,
    this.tj,
    this.en,
    this.unit,
    this.priceMin,
    this.priceAvg,
    this.priceMax,
  );

  final String ru;
  final String tj;
  final String en;
  final String unit; // 'шт' | 'м' | 'м2'
  final int priceMin;
  final int priceAvg;
  final int priceMax;

  String name(AppLocale locale) => switch (locale) {
        AppLocale.ru => ru,
        AppLocale.tg => tj,
        AppLocale.en => en,
        AppLocale.zh => en,
      };

  String unitLabel(AppLocale locale) {
    switch (unit) {
      case 'м':
        return switch (locale) {
          AppLocale.ru || AppLocale.tg => 'м',
          AppLocale.en => 'm',
          AppLocale.zh => '米',
        };
      case 'м2':
        return switch (locale) {
          AppLocale.zh => '㎡',
          _ => 'м²',
        };
      default: // шт
        return switch (locale) {
          AppLocale.ru => 'шт',
          AppLocale.tg => 'дона',
          AppLocale.en => 'pc',
          AppLocale.zh => '件',
        };
    }
  }
}

/// Service category with icon, accent color and its services.
class ServiceCategory {
  const ServiceCategory(
    this.ru,
    this.tj,
    this.en,
    this.icon,
    this.color,
    this.services,
  );

  final String ru;
  final String tj;
  final String en;
  final IconData icon;
  final Color color;
  final List<ServiceItem> services;

  String name(AppLocale locale) => switch (locale) {
        AppLocale.ru => ru,
        AppLocale.tg => tj,
        AppLocale.en => en,
        AppLocale.zh => en,
      };
}

const _amber = Color(0xFFF59E0B);
const _sky = Color(0xFF3B82F6);
const _green = Color(0xFF57B55E);
const _orange = Color(0xFFF97316);
const _violet = Color(0xFF8B5CF6);
const _indigo = Color(0xFF6366F1);
const _teal = Color(0xFF14B8A6);
const _cyan = Color(0xFF06B6D4);
const _orangeRed = Color(0xFFEF4444);
const _fuchsia = Color(0xFFEC4899);
const _stone = Color(0xFFB45309);
const _slate = Color(0xFF64748B);

const List<ServiceCategory> serviceCatalog = [
  ServiceCategory('Электрика', 'Барқкорӣ', 'Electrical', LucideIcons.zap, _amber, [
    ServiceItem('Установка розетки', 'Насб кардани розетка', 'Socket Installation', 'шт', 30, 55, 80),
    ServiceItem('Замена выключателя', 'Иваз кардани выключатель', 'Switch Replacement', 'шт', 25, 43, 60),
    ServiceItem('Установка люстры', 'Насб кардани люстра', 'Chandelier Installation', 'шт', 50, 125, 200),
    ServiceItem('Прокладка проводки', 'Кашидани сим', 'Wiring', 'м', 20, 40, 60),
    ServiceItem('Монтаж электрощита', 'Насби щити барқ', 'Electrical Panel', 'шт', 200, 500, 800),
    ServiceItem('Установка автомата', 'Насби автомат', 'Circuit Breaker', 'шт', 40, 80, 120),
    ServiceItem('Диагностика электрики', 'Ташхиси барқ', 'Electrical Diagnostics', 'шт', 50, 100, 150),
    ServiceItem('Установка счетчика', 'Насби ҳисобкунак', 'Meter Installation', 'шт', 100, 200, 300),
  ]),
  ServiceCategory('Сантехника', 'Сантехника', 'Plumbing', LucideIcons.droplets, _sky, [
    ServiceItem('Замена смесителя', 'Иваз кардани смеситель', 'Faucet Replacement', 'шт', 80, 140, 200),
    ServiceItem('Установка унитаза', 'Насб кардани унитоз', 'Toilet Installation', 'шт', 150, 275, 400),
    ServiceItem('Прочистка канализации', 'Тоза кардани канализатсия', 'Drain Cleaning', 'шт', 100, 200, 300),
    ServiceItem('Установка раковины', 'Насб кардани дастшӯяк', 'Sink Installation', 'шт', 100, 175, 250),
    ServiceItem('Замена труб', 'Иваз кардани қубур', 'Pipe Replacement', 'м', 50, 100, 150),
    ServiceItem('Установка бойлера', 'Насб кардани бойлер', 'Boiler Installation', 'шт', 200, 350, 500),
    ServiceItem('Ремонт душевой кабины', 'Таъмири душ', 'Shower Repair', 'шт', 100, 225, 350),
    ServiceItem('Установка счетчика воды', 'Насби ҳисобкунаки об', 'Water Meter', 'шт', 80, 140, 200),
  ]),
  ServiceCategory('Отделка', 'Ороиш', 'Finishing', LucideIcons.paintbrush, _green, [
    ServiceItem('Шпаклевка стен', 'Шпаклёвкаи девор', 'Wall Putty', 'м2', 20, 40, 60),
    ServiceItem('Штукатурка стен', 'Гачкории девор', 'Wall Plaster', 'м2', 25, 48, 70),
    ServiceItem('Поклейка обоев', 'Часпонидани обой', 'Wallpaper Installation', 'м2', 20, 40, 60),
    ServiceItem('Укладка плитки', 'Гузоштани плитка', 'Tile Laying', 'м2', 50, 90, 130),
    ServiceItem('Установка гипсокартона', 'Насби гипсокартон', 'Drywall Installation', 'м2', 40, 75, 110),
    ServiceItem('Откосы и проемы', 'Откос ва даромадгоҳ', 'Slopes and Openings', 'м', 30, 55, 80),
  ]),
  ServiceCategory('Мебель и двери', 'Мебел ва дарҳо', 'Furniture & Doors', LucideIcons.sofa, _orange, [
    ServiceItem('Сборка шкафа', 'Ҷамъ кардани шкаф', 'Wardrobe Assembly', 'шт', 120, 210, 300),
    ServiceItem('Сборка кухни', 'Ҷамъ кардани ошхона', 'Kitchen Assembly', 'шт', 300, 650, 1000),
    ServiceItem('Установка межкомнатной двери', 'Насби дари дохилӣ', 'Interior Door Installation', 'шт', 150, 275, 400),
    ServiceItem('Установка замка', 'Насби қулф', 'Lock Installation', 'шт', 80, 140, 200),
    ServiceItem('Регулировка дверей', 'Танзими дарҳо', 'Door Adjustment', 'шт', 50, 90, 130),
    ServiceItem('Навеска полок', 'Овехтани рафҳо', 'Shelf Mounting', 'шт', 30, 65, 100),
  ]),
  ServiceCategory('Умный дом', 'Хонаи зиракона', 'Smart Home', LucideIcons.cpu, _violet, [
    ServiceItem('Установка видеодомофона', 'Насби видеодомофон', 'Video Intercom Installation', 'шт', 200, 400, 600),
    ServiceItem('Установка умного замка', 'Насби қулфи интеллектуалӣ', 'Smart Lock Installation', 'шт', 150, 325, 500),
    ServiceItem('Установка датчиков движения', 'Насби сенсори ҳаракат', 'Motion Sensor Installation', 'шт', 50, 90, 130),
    ServiceItem('Установка умного освещения', 'Насби равшании интеллектуалӣ', 'Smart Lighting Installation', 'шт', 80, 165, 250),
    ServiceItem('Настройка умного дома', 'Танзими хонаи зирак', 'Smart Home Setup', 'шт', 200, 500, 800),
  ]),
  ServiceCategory('Видеонаблюдение', 'Видеоназорат', 'CCTV', LucideIcons.camera, _indigo, [
    ServiceItem('Установка камеры', 'Насби камера', 'Camera Installation', 'шт', 120, 210, 300),
    ServiceItem('Монтаж видеорегистратора', 'Насби видеорегистратор', 'DVR Installation', 'шт', 200, 350, 500),
    ServiceItem('Прокладка кабеля для камер', 'Кашидани кабел барои камера', 'Camera Cabling', 'м', 10, 20, 30),
    ServiceItem('Настройка удаленного доступа', 'Танзими дастрасии фосилавӣ', 'Remote Access Setup', 'шт', 80, 140, 200),
    ServiceItem('Обслуживание CCTV', 'Хизматрасонии CCTV', 'CCTV Maintenance', 'шт', 100, 200, 300),
  ]),
  ServiceCategory('Уборка', 'Тозакунӣ', 'Cleaning', LucideIcons.sparkles, _teal, [
    ServiceItem('Генеральная уборка', 'Тозакунии умумӣ', 'Deep Cleaning', 'м2', 15, 23, 30),
    ServiceItem('Уборка после ремонта', 'Тозакунӣ пас аз таъмир', 'Post-Renovation Cleaning', 'м2', 20, 30, 40),
    ServiceItem('Мытье окон', 'Шустани тирезаҳо', 'Window Cleaning', 'шт', 30, 55, 80),
    ServiceItem('Химчистка мебели', 'Химчисткаи мебел', 'Furniture Dry Cleaning', 'шт', 80, 140, 200),
    ServiceItem('Уборка офиса', 'Тозакунии офис', 'Office Cleaning', 'м2', 10, 18, 25),
    ServiceItem('Уборка кухни', 'Тозакунии ошхона', 'Kitchen Cleaning', 'шт', 80, 140, 200),
  ]),
  ServiceCategory('Кондиционеры', 'Кондиционерҳо', 'Air Conditioning', LucideIcons.wind, _cyan, [
    ServiceItem('Установка кондиционера', 'Насби кондиционер', 'Air Conditioner Installation', 'шт', 300, 550, 800),
    ServiceItem('Чистка кондиционера', 'Тозакунии кондиционер', 'Air Conditioner Cleaning', 'шт', 100, 175, 250),
    ServiceItem('Заправка фреоном', 'Пур кардани фреон', 'Freon Refill', 'шт', 150, 250, 350),
    ServiceItem('Ремонт кондиционера', 'Таъмири кондиционер', 'Air Conditioner Repair', 'шт', 150, 350, 550),
    ServiceItem('Демонтаж кондиционера', 'Кушодани кондиционер', 'Air Conditioner Removal', 'шт', 120, 210, 300),
  ]),
  ServiceCategory('Отопление', 'Гармкунӣ', 'Heating', LucideIcons.flame, _orangeRed, [
    ServiceItem('Установка радиатора', 'Насби радиатор', 'Radiator Installation', 'шт', 150, 275, 400),
    ServiceItem('Замена радиатора', 'Иваз кардани радиатор', 'Radiator Replacement', 'шт', 200, 350, 500),
    ServiceItem('Промывка системы отопления', 'Шустани системаи гармкунӣ', 'Heating Flush', 'шт', 300, 550, 800),
    ServiceItem('Установка котла', 'Насб кардани дег', 'Boiler Installation', 'шт', 500, 1250, 2000),
    ServiceItem('Ремонт котла', 'Таъмири дег', 'Boiler Repair', 'шт', 200, 500, 800),
    ServiceItem('Монтаж теплого пола', 'Насби фарши гарм', 'Underfloor Heating', 'м2', 300, 650, 1000),
  ]),
  ServiceCategory('Малярные работы', 'Корҳои рангубор', 'Painting', LucideIcons.paint_bucket, _fuchsia, [
    ServiceItem('Покраска стен', 'Ранг задани деворҳо', 'Wall Painting', 'м2', 25, 43, 60),
    ServiceItem('Покраска потолка', 'Ранг задани шифт', 'Ceiling Painting', 'м2', 30, 50, 70),
    ServiceItem('Покраска фасада', 'Ранг задани фасад', 'Facade Painting', 'м2', 35, 58, 80),
    ServiceItem('Покраска труб и батарей', 'Ранг задани қубур ва батарея', 'Pipe Painting', 'м', 20, 35, 50),
    ServiceItem('Декоративная покраска', 'Ранги декоративӣ', 'Decorative Painting', 'м2', 50, 100, 150),
  ]),
  ServiceCategory('Полы и ламинат', 'Фарш ва ламинат', 'Floors & Laminate', LucideIcons.layers, _stone, [
    ServiceItem('Укладка ламината', 'Гузоштани ламинат', 'Laminate Laying', 'м2', 45, 73, 100),
    ServiceItem('Укладка линолеума', 'Гузоштани линолеум', 'Linoleum Laying', 'м2', 25, 43, 60),
    ServiceItem('Стяжка пола', 'Стяжкаи фарш', 'Floor Screed', 'м2', 30, 55, 80),
    ServiceItem('Укладка паркета', 'Гузоштани паркет', 'Parquet Laying', 'м2', 60, 105, 150),
    ServiceItem('Ремонт пола', 'Таъмири фарш', 'Floor Repair', 'м2', 30, 60, 90),
    ServiceItem('Наливной пол', 'Фарши наливной', 'Self-Leveling Floor', 'м2', 40, 70, 100),
  ]),
  ServiceCategory('Другие услуги', 'Хидматҳои дигар', 'Other Services', LucideIcons.ellipsis, _slate, [
    ServiceItem('Мелкий ремонт', 'Таъмири хурд', 'Minor Repairs', 'шт', 50, 125, 200),
    ServiceItem('Навеска карниза', 'Овехтани карниз', 'Cornice Mounting', 'шт', 40, 80, 120),
    ServiceItem('Установка зеркала', 'Насб кардани оина', 'Mirror Installation', 'шт', 30, 65, 100),
    ServiceItem('Навеска телевизора', 'Овехтани телевизор', 'TV Mounting', 'шт', 50, 100, 150),
    ServiceItem('Сборка и установка аксессуаров', 'Ҷамъ ва насби аксессуарҳо', 'Accessory Installation', 'шт', 40, 95, 150),
  ]),
];

import '../providers/theme_provider.dart';

class S {
  final AppLanguage _lang;
  S(this._lang);

  bool get _cyr => _lang == AppLanguage.uzCyrillic;

  // ─── Auth ─────────────────────────────────────────────────────────────────
  String get appTitle        => _cyr ? 'Гилам Ювиш'          : 'Gilam Yuvish';
  String get login           => _cyr ? 'Кириш'                : 'Kirish';
  String get loginLabel      => _cyr ? 'Логин'                : 'Login';
  String get passwordLabel   => _cyr ? 'Парол'                : 'Parol';
  String get loginButton     => _cyr ? 'Тизимга кириш'        : 'Tizimga kirish';
  String get logoutButton    => _cyr ? 'Чиқиш'                : 'Chiqish';
  String get logoutConfirm   => _cyr ? 'Чиқмоқчимисиз?'      : 'Chiqmoqchimisiz?';
  String get yes             => _cyr ? 'Ҳа, чиқиш'           : 'Ha, chiqish';
  String get no              => _cyr ? 'Йўқ'                  : "Yo'q";
  String get managementSystem => _cyr ? 'Бошқарув тизими'    : 'Boshqaruv tizimi';

  // ─── Nav ──────────────────────────────────────────────────────────────────
  String get home     => _cyr ? 'Бош саҳифа'  : 'Bosh sahifa';
  String get orders   => _cyr ? 'Буюртмалар'  : 'Buyurtmalar';
  String get staff    => _cyr ? 'Ходимлар'    : 'Xodimlar';
  String get finance  => _cyr ? 'Молия'       : 'Moliya';
  String get settings => _cyr ? 'Созламалар'  : 'Sozlamalar';

  // ─── Dashboard ────────────────────────────────────────────────────────────
  String get hello            => _cyr ? 'Салом,'                    : 'Salom,';
  String get todayOrders      => _cyr ? 'Бугунги буюртмалар'        : 'Bugungi buyurtmalar';
  String get monthOrders      => _cyr ? 'Ойлик буюртмалар'          : 'Oylik buyurtmalar';
  String get newOrders        => _cyr ? 'Янги буюртмалар'           : 'Yangi buyurtmalar';
  String get readyOrders      => _cyr ? 'Тайёр (яетказиш кутмоқда)' : 'Tayyor (yetkazish kutmoqda)';
  String get todayIncome      => _cyr ? 'Бугунги тушум'             : 'Bugungi tushum';
  String get debt             => _cyr ? 'Қарздорлик'                : 'Qarzdorlik';
  String get workersActivity       => _cyr ? 'Ходимлар фаолияти'         : 'Xodimlar faoliyati';
  String get upakovchilarActivity  => _cyr ? 'Упаковчилар фаолияти'      : 'Upakovchilar faoliyati';
  String get activeOrders          => _cyr ? 'фаол'                      : 'faol';
  String get totalOrders           => _cyr ? 'та жами буюртма'           : 'ta jami buyurtma';
  String get orderCountSuffix      => _cyr ? 'та заказ'                  : 'ta zakaz';
  String get todayClean            => _cyr ? 'Бугун'                     : 'Bugun';
  String get yesterday             => _cyr ? 'Кеча'                      : 'Kecha';
  String get byDays                => _cyr ? 'Кунлар бўйича'             : "Kunlar bo'yicha";
  String get noOrdersYet           => _cyr ? 'Ҳали заказ йўқ'            : "Hali zakaz yo'q";
  String get todayNoOrders         => _cyr ? 'Бугун ҳали заказ йўқ'      : "Bugun hali zakaz yo'q";
  String get workerStatsTitle      => _cyr ? 'Кунлик статистика'         : 'Kunlik statistika';
  String get whoPackages           => _cyr ? 'Ким упаковка қилади?'      : 'Kim upakovka qiladi?';
  String get noActivePackers       => _cyr ? 'Фаол упаковчилар йўқ. Админ упаковчик қўшиши керак.' : "Faol upakovchilar yo'q. Admin upakovchik qo'shishi kerak.";
  String get assignedPacker        => _cyr ? 'Упаковка — упаковчик тайинланди'  : 'Upakovka — upakovchik tayinlandi';
  String get packerAssignLater     => _cyr ? 'Упаковка — кейинроқ тайинланади' : 'Upakovka — keyinroq tayinlanadi';
  List<String> get monthsShort => _cyr
      ? ['', 'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек']
      : ['', 'Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyn', 'Iyl', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek'];
  List<String> get monthsFull => _cyr
      ? ['', 'Январ', 'Феврал', 'Март', 'Апрел', 'Май', 'Июн', 'Июл', 'Август', 'Сентябр', 'Октябр', 'Ноябр', 'Декабр']
      : ['', 'Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun', 'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr'];
  String get salaryPercent         => _cyr ? 'Maosh foizi'                     : 'Maosh foizi';
  String get totalRevenue          => _cyr ? 'Жами тушум'                      : 'Jami tushum';
  String get workerSalary          => _cyr ? 'Маош'                            : 'Maosh';
  String get expense               => _cyr ? 'Чиқим (маош)'                    : 'Chiqim (maosh)';

  // ─── Orders ───────────────────────────────────────────────────────────────
  String get newOrder          => _cyr ? 'Янги буюртма'               : 'Yangi buyurtma';
  String get active            => _cyr ? 'Фаол'                       : 'Faol';
  String get delivered         => _cyr ? 'Етказилган'                 : 'Yetkazilgan';
  String get noActiveOrders    => _cyr ? 'Фаол буюртмалар йўқ'        : "Faol buyurtmalar yo'q";
  String get noDeliveredOrders => _cyr ? 'Етказилган буюртмалар йўқ'  : "Yetkazilgan buyurtmalar yo'q";
  String get search            => _cyr ? 'Қидириш (исм, телефон, #рақам...)' : 'Qidirish (ism, telefon, #raqam...)';
  String get all               => _cyr ? 'Ҳаммаси'                   : 'Hammasi';
  String get filterBy          => _cyr ? 'Фильтр'                    : 'Filter';
  String get orderNumber       => _cyr ? 'Буюртма рақами'             : 'Buyurtma raqami';

  // ─── Order statuses ───────────────────────────────────────────────────────
  String get statusYangi      => _cyr ? 'Янги'            : 'Yangi';
  String get statusQabul      => _cyr ? 'Навбат'          : 'Navbat';
  String get statusYuvilyapti => _cyr ? 'Ювиляпти'        : 'Yuvilyapti';
  String get statusUpakovka   => _cyr ? 'Упаковка'        : 'Upakovka';
  String get statusTayyor     => _cyr ? 'Тайёр'           : 'Tayyor';
  String get statusYetkazildi => _cyr ? 'Етказилди'       : 'Yetkazildi';

  // ─── Order form ───────────────────────────────────────────────────────────
  String get customerInfo     => _cyr ? 'Мижоз маълумотлари'          : "Mijoz ma'lumotlari";
  String get customerName     => _cyr ? 'Мижоз исми ва фамилияси'     : 'Mijoz ismi va familiyasi';
  String get phone            => _cyr ? 'Телефон рақами'               : 'Telefon raqami';
  String get address          => _cyr ? 'Манзил'                       : 'Manzil';
  String get carpetInfo       => _cyr ? 'Гилам маълумотлари'           : "Gilam ma'lumotlari";
  String get carpetType       => _cyr ? 'Гилам тури (ип, жун, тафтинг...)' : 'Gilam turi (ip, jun, tafting...)';
  String get carpetCount      => _cyr ? 'Гиламлар сони'                : 'Gilamlar soni';
  String get width            => _cyr ? 'Эни'                          : 'Eni';
  String get height           => _cyr ? 'Бўйи'                         : "Bo'yi";
  String get totalArea        => _cyr ? 'Жами майдон'                  : 'Jami maydon';
  String get totalPrice       => _cyr ? 'Жами нарх'                    : 'Jami narx';
  String get pricePerSqm      => _cyr ? '1 кв.м нарxи'                 : '1 kv.m narxi';
  String get dateInfo         => _cyr ? 'Сана'                         : 'Sana';
  String get pickupDate       => _cyr ? 'Олиб кетиш санаси'            : 'Olib ketish sanasi';
  String get deliveryDate     => _cyr ? 'Етказиш санаси'               : 'Yetkazish sanasi';
  String get assignInfo       => _cyr ? 'Тайинлаш'                     : 'Tayinlash';
  String get worker           => _cyr ? 'Ишчи'                         : 'Ishchi';
  String get driver           => _cyr ? 'Ҳайдовчи'                     : 'Haydovchi';
  String get notAssigned      => _cyr ? 'Тайинланмаган'                : 'Tayinlanmagan';
  String get notes            => _cyr ? 'Изоҳ'                         : 'Izoh';
  String get notesHint        => _cyr ? 'Қўшимча изоҳ (ихтиёрий)'      : "Qo'shimcha izoh (ixtiyoriy)";
  String get save             => _cyr ? 'Сақлаш'                       : 'Saqlash';
  String get cancel           => _cyr ? 'Бекор қилиш'                  : 'Bekor qilish';
  String get addOrder         => _cyr ? 'Буюртма қўшиш'                : "Buyurtma qo'shish";
  String get editOrder        => _cyr ? 'Буюртмани таҳрирлаш'          : 'Buyurtmani tahrirlash';
  String get deleteOrder      => _cyr ? 'Ўчириш'                       : "O'chirish";
  String get deleteConfirm    => _cyr ? 'Ўчиришни тасдиқланг'          : "O'chirishni tasdiqlang";
  String deleteRecordMsg(String amount) => _cyr ? '$amount сўм ёзувини ўчирасизми?' : "$amount so'm yozuvini o'chirasizmi?";
  String get markPaid         => _cyr ? "Тўланган деб белгилаш"        : "To'langan deb belgilash";
  String get paid             => _cyr ? "Тўланган"                     : "To'langan";
  String get unpaid           => _cyr ? "Тўланмаган"                   : "To'lanmagan";
  String get overdue          => _cyr ? 'Кечикди'                      : 'Kechikdi';
  String get orderDetail      => _cyr ? 'Буюртма тафсилоти'            : 'Buyurtma tafsiloti';
  String get moveTo           => _cyr ? 'га ўтказиш'                   : "ga o'tkazish";
  String get customer         => _cyr ? 'Мижоз'                        : 'Mijoz';
  String get orderSource      => _cyr ? 'Манба'                        : 'Manba';
  String get fromBotLabel     => _cyr ? '🤖 Telegram bot орқали'       : '🤖 Telegram bot orqali';
  String get botOrders        => _cyr ? 'Бот орқали зак.'              : 'Bot orqali zak.';
  String get carpet           => _cyr ? 'Гилам'                        : 'Gilam';
  String get pieces           => _cyr ? 'та'                           : 'ta';
  String get dateAndPayment   => _cyr ? 'Сана ва тўлов'                : "Sana va to'lov";
  String get enterMeasurements => _cyr ? 'Ўлчамларни киритинг'         : "O'lchamlarni kiriting";
  String get editMeasurements => _cyr ? 'Ўлчамларни таҳрирлаш'        : "O'lchamlarni tahrirlash";
  String get assignmentInfo   => _cyr ? 'Тайинлаш'                    : 'Tayinlash';
  String get copyDone         => _cyr ? 'Нусхаланди'                   : 'Nusxalandi';
  String get confirm          => _cyr ? 'Тасдиқлаш'                    : 'Tasdiqlash';
  String get close            => _cyr ? 'Ёпиш'                         : 'Yopish';
  String get edit             => _cyr ? 'Таҳрирлаш'                    : 'Tahrirlash';
  String get delete           => _cyr ? 'Ўчириш'                       : "O'chirish";
  String get add              => _cyr ? 'Қўшиш'                        : "Qo'shish";
  String get back             => _cyr ? 'Орқага'                       : 'Orqaga';
  String get next             => _cyr ? 'Кейинги'                      : 'Keyingi';

  // ─── Worker ───────────────────────────────────────────────────────────────
  String get workerRole        => _cyr ? 'Ишчи'                         : 'Ishchi';
  String get noTaskAssigned    => _cyr ? 'Сизга ҳозирча буюртма\nтайинланмаган' : "Sizga hozircha buyurtma\ntayinlanmagan";
  String get noDoneOrders      => _cyr ? 'Бажарилган буюртмалар йўқ'    : "Bajarilgan buyurtmalar yo'q";
  String get washingDone       => _cyr ? 'Ювиш тугалланди'              : 'Yuvish tugallandi';
  String get faolTab           => _cyr ? 'Фаол'                         : 'Faol';
  String get doneTab           => _cyr ? 'Бажарилди'                    : 'Bajarildi';
  String get moveToNext        => _cyr ? 'Кейинги босқичга ўтказиш'     : 'Keyingi bosqichga o\'tkazish';
  String get statusUpdated     => _cyr ? 'Ҳолат янгиланди'              : 'Holat yangilandi';
  String get orderReady        => _cyr ? 'Тайёр! Мижозга SMS юборилди 📱' : 'Tayyor! Mijozga SMS yuborildi 📱';
  String get selectDeliveryDriver => _cyr ? 'Етказиб берувчи ҳайдовчи'  : 'Yetkazib beruvchi haydovchi';
  String get whoDelivers       => _cyr ? 'Ким етказиб беради?'           : 'Kim yetkazib beradi?';
  String get assignLater       => _cyr ? 'Кейинроқ тайинланади'          : 'Keyinroq tayinlanadi';

  // ─── Driver ───────────────────────────────────────────────────────────────
  String get driverRole         => _cyr ? 'Ҳайдовчи'                   : 'Haydovchi';
  String get pickup             => _cyr ? 'Олиб келиш'                  : 'Olib kelish';
  String get delivery           => _cyr ? 'Етказиш'                     : 'Yetkazish';
  String get noPickupTasks      => _cyr ? 'Олиб келиш топшириқлари йўқ' : "Olib kelish topshiriqlari yo'q";
  String get noDeliveryTasks    => _cyr ? 'Етказиш топшириқлари йўқ'    : "Yetkazish topshiriqlari yo'q";
  String get pickedUp           => _cyr ? 'Олиб келинди'                : 'Olib kelindi';
  String get deliveredBtn       => _cyr ? 'Етказиб берилди'             : 'Yetkazib berildi';
  String get pickupDateLabel    => _cyr ? 'Олиб кетиш'                  : 'Olib ketish';
  String get deliveryDateLabel  => _cyr ? 'Етказиш'                     : 'Yetkazish';
  String get today              => _cyr ? 'Бугун!'                      : 'Bugun!';
  String get late               => _cyr ? 'кечикди!'                    : 'kechikdi!';
  String get enterItems         => _cyr ? 'Нарсаларни киритинг ва олиб келинди' : 'Narsalarni kiriting va olib kelindi';
  String get saveAndPickup      => _cyr ? 'Сақлаш ва олиб келинди'      : 'Saqlash va olib kelindi';
  String get locationDetected   => _cyr ? 'Манзил аниқланди'            : 'Manzil aniqlandi';
  String get locationSaved      => _cyr ? 'Манзил сақланган'            : 'Manzil saqlangan';
  String get locating           => _cyr ? 'Аниқланмоқда...'             : 'Aniqlanmoqda...';
  String get gpsOff             => _cyr ? 'GPS ўчирилган'               : "GPS o'chirilgan";
  String get locationDenied     => _cyr ? 'Жойлашув рухсати берилмаган' : 'Joylashuv ruxsati berilmagan';
  String get viewOnMap          => _cyr ? 'Хаританда кўриш'             : 'Xaritada ko\'rish';
  String get pickupLocation     => _cyr ? 'Олиб кетиш манзилини кўриш'  : "Olib ketish manzilini ko'rish";
  String get howManyItems       => _cyr ? 'Нечта нарса бор?'            : 'Nechta narsa bor?';
  String get enterDimensions    => _cyr ? 'Ўлчамларни киритиш'          : "O'lchamlarni kiritish";

  // ─── Payment ──────────────────────────────────────────────────────────────
  String get collectPayment     => _cyr ? "Тўловни олдим"               : "To'lovni oldim";
  String get paymentReceived    => _cyr ? "Тўлов қабул қилинди"         : "To'lov qabul qilindi";
  String get paymentRequired    => _cyr ? "Аввал тўловни олинг!"        : "Avval to'lovni oling!";
  String get paymentRequiredMsg => _cyr
      ? "мижоздан тўловни олинг, сўнг етказилди деб белгиланг"
      : "mijozdan to'lovni oling, so'ng yetkazildi deb belgilang";
  String get didYouCollect      => _cyr ? "Тўловни олдингизми?"         : "To'lovni oldingizmi?";
  String get yesCollected       => _cyr ? "Ҳа, олдим"                   : "Ha, oldim";
  String get notPaid            => _cyr ? "ТЎЛАНМАГАН"                : "TO'LANMAGAN";
  String get totalSum           => _cyr ? 'Жами сумма'                  : 'Jami summa';

  // ─── Staff ────────────────────────────────────────────────────────────────
  String get workers             => _cyr ? 'Ишчилар'          : 'Ishchilar';
  String get drivers             => _cyr ? 'Ҳайдовчилар'      : 'Haydovchilar';
  String get addWorker           => _cyr ? 'Ишчи қўшиш'       : "Ishchi qo'shish";
  String get addDriver           => _cyr ? 'Ҳайдовчи қўшиш'   : "Haydovchi qo'shish";
  String get addUser             => _cyr ? 'Фойдаланувчи қўшиш' : "Foydalanuvchi qo'shish";
  String get newUser             => _cyr ? 'Янги фойдаланувчи' : 'Yangi foydalanuvchi';
  String get userCreated         => _cyr ? 'Фойдаланувчи яратилди' : 'Foydalanuvchi yaratildi';
  String get fullName            => _cyr ? 'Исм-шарифи'        : 'Ism-sharifi';
  String get name                => _cyr ? 'Исм'               : 'Ism';
  String get generatedCredentials => _cyr ? 'Кириш маълумотлари' : "Kirish ma'lumotlari";
  String get credentialsSaveNote  => _cyr ? 'Кириш маълумотларини сақланг!\nБу парол қайтариб кўрсатилмайди.' : "Kirish ma'lumotlarini saqlang!\nBu parol qaytarib ko'rsatilmaydi.";
  String get copyCredentials     => _cyr ? 'Нусха олиш'        : 'Nusxa olish';
  String get copyLogin           => _cyr ? 'Логинни нусхалаш'  : "Loginni nusxalash";
  String get copyPassword        => _cyr ? 'Паролни нусхалаш'  : "Parolni nusxalash";
  String get deactivate          => _cyr ? 'Ўчириш'            : "O'chirish";
  String get activate            => _cyr ? 'Фаоллаштириш'      : 'Faollashtirish';
  String get block               => _cyr ? 'Блоклаш'           : 'Bloklash';
  String get activeStatus        => _cyr ? 'Фаол'              : 'Faol';
  String get inactiveStatus      => _cyr ? 'Фаол эмас'         : "Faol emas";
  String get noWorkers           => _cyr ? 'Ишчилар йўқ'       : "Ishchilar yo'q";
  String get noDrivers           => _cyr ? 'Ҳайдовчилар йўқ'   : "Haydovchilar yo'q";
  String get copied              => _cyr ? 'Нусхаланди'         : 'Nusxalandi';
  String get viewPassword        => _cyr ? 'Логин/Паролни кўриш' : "Login/Parolni ko'rish";
  String get manageUsers         => _cyr ? 'Фойдаланувчиларни бошқариш' : 'Foydalanuvchilarni boshqarish';
  String get role                => _cyr ? 'Вазифа'             : 'Vazifa';
  String get workerRole2         => _cyr ? 'Ишчи'               : 'Ishchi';
  String get driverRole2         => _cyr ? 'Ҳайдовчи'           : 'Haydovchi';

  // ─── Finance ──────────────────────────────────────────────────────────────
  String get financeTitle    => _cyr ? 'Молия'            : 'Moliya';
  String get totalIncome     => _cyr ? 'Жами тушум'       : 'Jami tushum';
  String get paidIncome      => _cyr ? 'Тўланган'         : "To'langan";
  String get pendingIncome   => _cyr ? 'Қарздорлик'       : 'Qarzdorlik';
  String get monthly         => _cyr ? 'Ойлик'            : 'Oylik';
  String get daily           => _cyr ? 'Кунлик'           : 'Kunlik';
  String get currency        => _cyr ? 'сўм'              : "so'm";
  String get income          => _cyr ? 'Тушум'            : 'Tushum';
  String get orderCount      => _cyr ? 'Буюртмалар сони'  : 'Buyurtmalar soni';
  String get netProfit       => _cyr ? 'Соф фойда'        : 'Sof foyda';
  String get noData2         => _cyr ? 'Маълумот йўқ'     : "Ma'lumot yo'q";

  // ─── Driver settlements ───────────────────────────────────────────────────
  String get driverSettlements  => _cyr ? 'Ҳайдовчилар ҳисоби'     : 'Haydovchilar hisobi';
  String get dailyCollection    => _cyr ? 'Кунлик жамланган'        : 'Kunlik jamlangan';
  String get totalCollected     => _cyr ? 'Жами йиғилган'           : "Jami yig'ilgan";
  String get totalSettled       => _cyr ? 'Топширилган'              : 'Topshirilgan';
  String get outstanding        => _cyr ? 'Ҳайдовчида қолган'       : 'Haydovchida qolgan';
  String get debtor             => _cyr ? 'Қарздор'                 : 'Qarzdor';
  String get settled            => _cyr ? 'Ҳисоб-китоб қилинган ✓'  : "Hisob-kitob qilingan ✓";
  String get iReceived          => _cyr ? 'Пулни олдим'              : 'Pulni oldim';
  String get claimOrder         => _cyr ? 'Қабул қилдим'             : 'Qabul qildim';
  String get claimOrderConfirm  => _cyr ? 'Бу буюртмани қабул қиласизми? Кейин у бошқа ҳайдовчиларга кўринмайди.' : "Bu buyurtmani qabul qilasizmi? Keyin u boshqa haydovchilarga ko'rinmaydi.";
  String get claimedOk          => _cyr ? '✓ Буюртма сизга тайинланди' : '✓ Buyurtma sizga tayinlandi';
  String get claimedTaken       => _cyr ? 'Бу буюртмани бошқа ҳайдовчи қабул қилиб бўлган' : 'Bu buyurtmani boshqa haydovchi qabul qilib bo\'lgan';
  String get confirmReceived    => _cyr ? 'Тасдиқлаш — Пулни олдим' : 'Tasdiqlash — Pulni oldim';
  String get collectionHistory  => _cyr ? 'Йиғилган (кунлик)'       : "Yig'ilgan (kunlik)";
  String get settlementHistory  => _cyr ? 'Топширилган'             : 'Topshirilgan';
  String get deleteSettlement   => _cyr ? 'Ёзувни ўчириш'           : "Yozuvni o'chirish";
  String get noDebt             => _cyr ? 'да қарз йўқ'             : 'da qarz yo\'q';
  String get hasMoney           => _cyr ? 'та ҳайдовчида пул бор'   : 'ta haydovchida pul bor';

  // ─── Services ─────────────────────────────────────────────────────────────
  String get servicesTitle      => _cyr ? 'Хизматлар нархлари'       : 'Xizmatlar narxlari';
  String get addService         => _cyr ? 'Хизмат қўшиш'             : "Xizmat qo'shish";
  String get serviceName        => _cyr ? 'Хизмат номи'              : 'Xizmat nomi';
  String get serviceNameHint    => _cyr ? 'Гилам, Ёстиқ, Парда...'  : 'Gilam, Yostiq, Parda...';
  String get unitType           => _cyr ? 'Ўлчов тури'               : "O'lchov turi";
  String get sqmUnit            => _cyr ? 'м²'                       : 'm²';
  String get meterUnit          => _cyr ? 'Метр'                     : 'Metr';
  String get pieceUnit          => _cyr ? 'Дона'                     : 'Dona';
  String get pricePerSqmUnit    => _cyr ? "Нарх (сўм/м²)"            : "Narx (so'm/m²)";
  String get pricePerMeter      => _cyr ? "Нарх (сўм/м)"             : "Narx (so'm/m)";
  String get pricePerPiece      => _cyr ? "Нарх (сўм/дона)"          : "Narx (so'm/dona)";
  String get serviceActive      => _cyr ? 'Фаол'                     : 'Faol';
  String get serviceInactive    => _cyr ? 'Ўчирилган'                : "O'chirilgan";
  String get editService        => _cyr ? 'Хизматни таҳрирлаш'       : 'Xizmatni tahrirlash';
  String get servicesManagement => _cyr ? 'Хизматлар ва нархлар'     : 'Xizmatlar va narxlar';
  String get servicesDesc       => _cyr ? 'Гилам, ёстиқ, корпа... нархларини бошқариш' : 'Gilam, yostiq, korpa... narxlarini boshqarish';
  String get washingItems       => _cyr ? 'Ювилган нарсалар'         : 'Yuvilgan narsalar';
  String get selectItems        => _cyr ? 'Нарсаларни белгиланг'     : 'Narsalarni belgilang';
  String get itemsInfo          => _cyr ? 'Хизмат қўшиб нархини белгиланг. Ҳайдовчи олиб келганда ҳар бир нарса учун ўлчам/сон киритади.' : "Xizmat qo'shib narxini belgilang. Haydovchi olib kelganda har bir narsa uchun o'lcham/son kiritadi.";

  // ─── Profile ──────────────────────────────────────────────────────────────
  String get profileTitle       => _cyr ? 'Профил'                   : 'Profil';
  String get myOrders           => _cyr ? 'Менинг буюртмаларим'      : 'Mening buyurtmalarim';
  String get viewAllOrders      => _cyr ? 'Ҳаммасини кўриш →'        : "Hammasini ko'rish →";
  String get statistics         => _cyr ? 'Статистика'               : 'Statistika';
  String get activeCount        => _cyr ? 'Фаол буюртмалар'          : 'Faol buyurtmalar';
  String get doneCount          => _cyr ? 'Бажарилган'               : 'Bajarilgan';
  String get totalCount         => _cyr ? 'Жами'                     : 'Jami';
  String get fontSizeLabel      => _cyr ? "Шрифт ўлчами"             : "Shrift o'lchami";
  String get fontSmall          => _cyr ? 'Кичик'                    : 'Kichik';
  String get fontNormal         => _cyr ? 'Оддий'                    : 'Oddiy';
  String get fontLarge          => _cyr ? 'Катта'                    : 'Katta';
  String get fontXLarge         => _cyr ? 'Жуда катта'               : 'Juda katta';

  // ─── Settings ─────────────────────────────────────────────────────────────
  String get settingsTitle      => _cyr ? 'Созламалар'               : 'Sozlamalar';
  String get priceSettings      => _cyr ? 'Гилам ювиш нархи'         : 'Gilam yuvish narxi';
  String get currentPrice       => _cyr ? 'Ҳозирги нарх'             : 'Hozirgi narx';
  String get savePrice          => _cyr ? 'Нархни сақлаш'            : 'Narxni saqlash';
  String get priceSaved         => _cyr ? 'Нарх сақланди'            : 'Narx saqlandi';
  String get smsSettings        => _cyr ? 'Автоматик SMS'             : 'Avtomatik SMS';
  String get smsInfo            => _cyr ? '"Тайёр" ҳолатига ўтганда мижозга SMS юборилади' : '"Tayyor" holatiga o\'tganda mijozga SMS yuboriladi';
  String get smsSampleTitle     => _cyr ? 'SMS намунаси:'             : 'SMS namunasi:';
  String get smsSampleText      => _cyr
      ? '"Гиламингиз ювиб тайёр бўлди! Етказиб бериш учун боғланамиз."'
      : '"Gilamingiz yuvib tayyor bo\'ldi! Yetkazib berish uchun bog\'lanamiz."';
  String get smsPermissionNote  => _cyr
      ? 'Биринчи SMS да Android рухсат сўрайди — "Рухсат бериш" ни босинг'
      : 'Birinchi SMS da Android ruxsat so\'raydi — "Ruxsat berish" ni bosing';
  String get appearance         => _cyr ? 'Кўриниш'                  : "Ko'rinish";
  String get themeMode          => _cyr ? 'Тема'                     : 'Tema';
  String get lightMode          => _cyr ? 'Оч'                       : 'Och';
  String get darkMode           => _cyr ? 'Тўқ'                      : "To'q";
  String get languageLabel      => _cyr ? 'Тил'                      : 'Til';
  String get uzLatin            => "O'zbek (Lotin)";
  String get uzCyrillic         => 'Ўзбек (Кирилл)';
  String get calcExample        => _cyr ? 'Ҳисоблаш намунаси'        : 'Hisoblash namunasi';

  // ─── Common ───────────────────────────────────────────────────────────────
  String get errorOccurred  => _cyr ? 'Хатолик юз берди'            : 'Xatolik yuz berdi';
  String get loading        => _cyr ? 'Юкланмоқда...'               : 'Yuklanmoqda...';
  String get retry          => _cyr ? 'Қайта уриниш'                : "Qayta urinish";
  String get sum            => _cyr ? 'сўм'                         : "so'm";
  String get meter          => _cyr ? 'м'                           : 'm';
  String get sqMeter        => _cyr ? 'м²'                          : 'm²';
  String get enterValue     => _cyr ? 'Тўғри қиймат киритинг'       : "To'g'ri qiymat kiriting";
  String get noData         => _cyr ? 'Маълумот йўқ'                : "Ma'lumot yo'q";
  String get refresh        => _cyr ? 'Янгилаш'                     : 'Yangilash';
  String get refreshing     => _cyr ? 'Янгиланмоқда...'             : 'Yangilanmoqda...';
  String get serverError    => _cyr ? 'Сервер билан уланишда хатолик' : 'Server bilan ulanishda xatolik';
  String get backendCheck   => _cyr ? 'Backend ишлаяптими?'         : 'Backend ishlayadimi?';
  String get emptyList      => _cyr ? 'Рўйхат бўш'                  : "Ro'yxat bo'sh";
  String get pieces2        => _cyr ? 'дона'                        : 'dona';
  String get sqm            => _cyr ? 'м²'                          : 'm²';
  String get atLeastOne     => _cyr ? 'Камида 1 та киритинг'        : 'Kamida 1 ta kiriting';
  String get savedSuccess   => _cyr ? 'Муваффақиятли сақланди'      : 'Muvaffaqiyatli saqlandi';
  String get error          => _cyr ? 'Хатолик'                     : 'Xatolik';
  String get optional       => _cyr ? 'ихтиёрий'                    : 'ixtiyoriy';
  String get required2      => _cyr ? 'мажбурий'                    : 'majburiy';
  String get enterName      => _cyr ? 'Исм киритинг'                : 'Ism kiriting';
  String get enterPhone     => _cyr ? 'Телефон киритинг'            : 'Telefon kiriting';
  String get enterAddress   => _cyr ? 'Манзил киритинг'             : 'Manzil kiriting';
  String get correctNumber  => _cyr ? 'Тўғри рақам киритинг'       : "To'g'ri raqam kiriting";
  String get fullPhoneNumber => _cyr ? 'Тўлиқ рақам киритинг'      : "To'liq raqam kiriting";

  // ─── Extra Orders ─────────────────────────────────────────────────────────
  String get filterHint          => _cyr ? 'Қидириш (исм, телефон, #рақам...)' : 'Qidirish (ism, telefon, #raqam...)';
  String get carpetTypeOrNote    => _cyr ? 'Гилам тури / Изоҳ'               : 'Gilam turi / Izoh';
  String get carpetSizeInfo      => _cyr ? 'Гилам сони ва ўлчамлари даставчи етиб боргач киритади' : "Gilam soni va o'lchamlari dastavchi yetib borgach kiritadi";
  String get carpetTypeHint      => _cyr ? 'Гилам тури ёки қўшимча изоҳ (ихтиёрий)' : "Gilam turi yoki qo'shimcha izoh (ixtiyoriy)";
  String get selectWorker        => _cyr ? 'Ишчи танланг'                    : 'Ishchi tanlang';
  String get selectDriver        => _cyr ? 'Ҳайдовчи танланг'                : 'Haydovchi tanlang';
  String get notAssignedDash     => _cyr ? '— Тайинланмаган —'               : '— Tayinlanmagan —';
  String get deleteOrderConfirm  => _cyr ? 'буюртмасини ўчирасизми?'         : "buyurtmasini o'chirasizmi?";
  String get unknownName         => _cyr ? "Номаълум"                        : "Noma'lum";

  // ─── Finance extra ────────────────────────────────────────────────────────
  String get financeReport       => _cyr ? 'Молиявий ҳисобот'                : 'Moliyaviy hisobot';
  String get orderList           => _cyr ? 'Буюртмалар рўйхати'              : "Buyurtmalar ro'yxati";
  String get noDataForMonth      => _cyr ? 'Бу ой учун маълумот йўқ'         : "Bu oy uchun ma'lumot yo'q";
  String get noDataForDay        => _cyr ? 'Бу кун учун маълумот йўқ'        : "Bu kun uchun ma'lumot yo'q";
  String get todayOrders2        => _cyr ? 'Бугунги буюртмалар'              : 'Bugungi buyurtmalar';
  String get noDataForYear       => _cyr ? 'Бу йил учун маълумот йўқ'        : "Bu yil uchun ma'lumot yo'q";
  String get yearlyTab           => _cyr ? 'Йиллик'                          : 'Yillik';
  String get monthlyTab          => _cyr ? 'Ойлик'                           : 'Oylik';
  String get dailyTab            => _cyr ? 'Кунлик'                          : 'Kunlik';
  String get monthBreakdown      => _cyr ? 'Ойлар бўйича'                    : "Oylar bo'yicha";

  // ─── Driver settlements extra ─────────────────────────────────────────────
  String get totalCollectedLabel => _cyr ? 'Жами йиғилди'                    : "Jami yig'ildi";
  String get leftAtDriver        => _cyr ? 'Ҳайдовчиларда қолган'            : 'Haydovchilarda qolgan';
  String get receivedAmount      => _cyr ? "Олинган сумма (сўм)"             : "Olingan summa (so'm)";
  String get notSettledYet       => _cyr ? 'Ҳали топширилмаган:'             : 'Hali topshirilmagan:';
  String get alreadySettled      => _cyr ? 'Ҳисоб-китоб қилинган'           : 'Hisob-kitob qilingan';
  String get noMoneyYet          => _cyr ? 'Ҳали буюртмалардан пул олинмаган' : 'Hali buyurtmalardan pul olinmagan';
  String get noSettlementsYet    => _cyr ? "Ҳали топшириш йўқ"               : "Hali topshirish yo'q";
  String get history             => _cyr ? 'Тарих'                           : 'Tarix';
  String get lastSettlement      => _cyr ? 'Охирги топшириш:'                : 'Oxirgi topshirish:';
  String get leftDebt            => _cyr ? 'Қолди (қарз)'                   : 'Qoldi (qarz)';
  String get topshirildi         => _cyr ? 'Топширилди'                      : 'Topshirildi';

  // ─── Driver collections extra ─────────────────────────────────────────────
  String get dailyTotalIncome    => _cyr ? 'Кунлик жами тушум'               : 'Kunlik jami tushum';
  String get driverCollection    => _cyr ? "Ҳайдовчилар йиғими"              : "Haydovchilar yig'imi";
  String get paymentCollected    => _cyr ? 'Тўловлар олинди'                 : "To'lovlar olindi";
  String get noPaymentToday      => _cyr ? 'Бугун тўлов олмаган'             : "Bugun to'lov olmagan";
  String get collectedMark       => _cyr ? 'Олиб келди ✓'                    : 'Olib keldi ✓';
  String get unpaidOrders        => _cyr ? "Тўланмаган буюртмалар"           : "To'lanmagan buyurtmalar";
  String get allOrdersPaid       => _cyr ? "Барча буюртмалар тўланган"       : "Barcha buyurtmalar to'langan";
  String get packagingDone       => _cyr ? "Упаковка тугалланди"             : "Upakovka tugallandi";
  String get servicesNotEntered  => _cyr ? "Хизматлар киритилмаган"          : "Xizmatlar kiritilmagan";
  String get todayPrefix         => _cyr ? 'Бугун — '                        : 'Bugun — ';
  String get ordersFrom          => _cyr ? 'та буюртмадан тўлов олинди'      : "ta buyurtmadan to'lov olindi";

  // ─── Driver home extra ────────────────────────────────────────────────────
  String get driverLabel         => _cyr ? 'Ҳайдовчи'                       : 'Haydovchi';
  String get pickupTab           => _cyr ? 'Олиб келиш'                      : 'Olib kelish';
  String get deliveryTab         => _cyr ? 'Етказиш'                         : 'Yetkazish';
  String get pickupDatePrefix    => _cyr ? 'Олиб кетиш: '                    : 'Olib ketish: ';
  String get deliveryDatePrefix  => _cyr ? 'Етказиш: '                       : 'Yetkazish: ';
  String get lateLabel           => _cyr ? ' — кечикди!'                     : ' — kechikdi!';
  String get todayLabel          => _cyr ? ' — бугун!'                       : ' — bugun!';
  String get measureOrChange     => _cyr ? "Ўлчамларни кўриш / Ўзгартириш"  : "O'lchamlarni ko'rish / O'zgartirish";
  String get enterCarpetsPickup  => _cyr ? 'Гиламларни киритинг ва Олиб келинди' : 'Gilamlarni kiriting va Olib kelindi';
  String get confirmDeliveryBtn  => _cyr ? 'Ҳа, етказиб берилди'             : 'Ha, yetkazib berildi';
  String get paidLabel           => _cyr ? "Тўланди"                         : "To'landi";
  String get unpaidBig           => _cyr ? "ТЎЛАНМАГАН"                    : "TO'LANMAGAN";
  String get remindPayment       => _cyr ? 'Мижоз ҳали ҳақ тўламаган — олиб келишдан олдин эслатиб қўйинг' : "Mijoz hali haq to'lamagan — olib kelishdan oldin eslatib qo'ying";
  String get dontForgetMoney     => _cyr ? 'Пул олишни унутманг!'            : "Pul olishni unutmang!";
  String get deliveredSms        => _cyr ? '✓ Етказилди — Мижозга SMS юборилди 📱' : '✓ Yetkazildi — Mijozga SMS yuborildi 📱';
  String get deliveredOk         => _cyr ? '✓ Етказиб берилди'               : '✓ Yetkazib berildi';

  // ─── Pickup items extra ───────────────────────────────────────────────────
  String get receiveItems        => _cyr ? 'Нарсаларни қабул қилиш'          : 'Narsalarni qabul qilish';
  String get countLabel          => _cyr ? 'Сони'                            : 'Soni';
  String get lengthLabel         => _cyr ? 'Узунлик'                         : 'Uzunlik';
  String get widthLabel          => _cyr ? 'Эни'                             : 'Eni';
  String get heightLabel         => _cyr ? "Бўйи"                            : "Bo'yi";
  String get totalAreaLabel      => _cyr ? 'Жами: '                          : 'Jami: ';
  String get serviceCountSuffix  => _cyr ? 'та хизмат'                       : 'ta xizmat';
  String get saveAndPickedUp     => _cyr ? 'Сақлаш ва Олиб келинди'          : 'Saqlash va Olib kelindi';
  String get pickedUpSuccess     => _cyr ? '✓ Олиб келинди!'                 : '✓ Olib kelindi!';
  String get measureAtHome       => _cyr ? 'Ўлчамни кейин киритаман'         : 'O\'lchamni keyin kiritaman';
  String get measureAtHomeInfo   => _cyr ? 'Манзил сақланади. Ўлчамларни йўлда ёки заводда киритасиз.' : 'Manzil saqlanadi. O\'lchamlarni yo\'lda yoki zavodda kiritasiz.';
  String get measurePending      => _cyr ? 'Ўлчам киритилмаган'              : 'O\'lcham kiritilmagan';

  // ─── Worker home extra ────────────────────────────────────────────────────
  String get workerLabel         => _cyr ? 'Ишчи'                            : 'Ishchi';
  String get upakovchikLabel     => _cyr ? 'Упаковчик'                       : 'Upakovchik';
  String get selectUpakovchik    => _cyr ? 'Упаковчик танланг'               : 'Upakovchik tanlang';
  String get noUpakovchikTasks   => _cyr ? 'Упаковка вазифалари йўқ'         : "Upakovka vazifalari yo'q";
  String get doneWithCount       => _cyr ? 'Бажарилди'                       : 'Bajarildi';
  String get itemCount           => _cyr ? 'та буюм'                         : 'ta buyum';
  String get driverNotPickedYet  => _cyr ? 'Даставчи ҳали олмаган'           : 'Dastavchi hali olmagan';
  String get washingDoneLabel    => _cyr ? 'Ювиш тугалланди'                 : 'Yuvish tugallandi';
  String get statusUpdatedMsg    => _cyr ? '✓ Ҳолат янгиланди: '             : '✓ Holat yangilandi: ';
  String get readySmsSent        => _cyr ? '✓ Тайёр! Мижозга SMS юборилди 📱' : '✓ Tayyor! Mijozga SMS yuborildi 📱';
  String get readySmsNoPermit    => _cyr ? '✓ Тайёр! (SMS рухсати берилмаган)' : '✓ Tayyor! (SMS ruxsati berilmagan)';
  String get readyOk             => _cyr ? '✓ Тайёр!'                        : '✓ Tayyor!';

  // ─── Users extra ──────────────────────────────────────────────────────────
  String get createUser          => _cyr ? 'Яратиш'                          : 'Yaratish';
  String get noUsers             => _cyr ? 'Фойдаланувчилар мавжуд эмас'     : 'Foydalanuvchilar mavjud emas';
  String get blockUser           => _cyr ? 'Фойдаланувчини блоклаш'          : 'Foydalanuvchini bloklash';
  String get activateUser        => _cyr ? 'Фойдаланувчини фаоллаштириш'     : 'Foydalanuvchini faollashtirish';
  String get blockConfirm        => _cyr ? 'ни блоклашни тасдиқлайсизми?'    : 'ni bloklashni tasdiqlaysizmi?';
  String get activateConfirm     => _cyr ? 'ни фаоллашти\nришни тасдиқлайсизми?' : 'ni faollashtirishni tasdiqlaysizmi?';
  String get inactiveLabel       => _cyr ? 'Нофаол'                          : 'Nofarol';
  String get copyAction          => _cyr ? 'Нусха олиш'                      : 'Nusxa olish';
  String get copiedMsg           => _cyr ? 'Нусха олинди'                    : 'Nusxa olindi';
  String get loginLabel2         => _cyr ? 'Логин'                           : 'Login';
  String get passwordCopy        => _cyr ? 'Парол'                           : 'Parol';

  // ─── Services extra ───────────────────────────────────────────────────────
  String get newService          => _cyr ? 'Янги хизмат'                     : 'Yangi xizmat';
  String get serviceAdded        => _cyr ? "Хизмат қўшилди"                  : "Xizmat qo'shildi";
  String get serviceUpdated      => _cyr ? 'Янгиланди'                       : 'Yangilandi';
  String get enterValidData      => _cyr ? "Илтимос, тўғри маълумот киритинг" : "Iltimos, to'g'ri ma'lumot kiriting";
  String get sqmSuffix           => _cyr ? "сўм/м²"                          : "so'm/m²";
  String get meterSuffix         => _cyr ? "сўм/м"                           : "so'm/m";
  String get pieceSuffix         => _cyr ? "сўм/дона"                        : "so'm/dona";

  // ─── Password change ──────────────────────────────────────────────────────
  String get changePassword      => _cyr ? "Паролни ўзгартириш"              : "Parolni o'zgartirish";
  String get currentPassword     => _cyr ? "Жорий парол"                     : "Joriy parol";
  String get newPassword         => _cyr ? "Янги парол"                      : "Yangi parol";
  String get confirmPassword     => _cyr ? "Янги паролни тасдиқланг"         : "Yangi parolni tasdiqlang";
  String get passwordMinLength   => _cyr ? "Парол камида 4 та белгидан иборат бўлсин" : "Parol kamida 4 ta belgidan iborat bo'lsin";
  String get passwordMismatch    => _cyr ? "Янги паролlar мос келмайди"      : "Yangi parollar mos kelmaydi";
  String get fillAllFields       => _cyr ? "Барча майдонларни тўлдиринг"     : "Barcha maydonlarni to'ldiring";
  String get passwordChanged     => _cyr ? "✓ Парол муваффақиятли ўзгартирилди" : "✓ Parol muvaffaqiyatli o'zgartirildi";

  // ─── SMS settings ─────────────────────────────────────────────────────────
  String get smsTemplateLabel    => _cyr ? "SMS матни:"                      : "SMS matni:";
  String get saveSmsTemplate     => _cyr ? "SMS матнини сақлаш"              : "SMS matnini saqlash";
  String get smsSample           => _cyr ? "Намуна:"                         : "Namuna:";
  String get smsTemplateSaved    => _cyr ? "SMS матни сақланди ✓"            : "SMS matni saqlandi ✓";
  String get smsEnabledStatus    => _cyr ? 'SMS юбориляпти ✓'                : 'SMS yuborilyapti ✓';
  String get smsDisabledStatus   => _cyr ? "SMS ўчирилган"                   : "SMS o'chirilgan";

  // ─── GPS / Location ───────────────────────────────────────────────────────
  String get gpsDetecting        => _cyr ? "GPS орқали манзил аниқланмоқда..." : "GPS orqali manzil aniqlanmoqda...";
  String get gpsDetected         => _cyr ? "Манзил аниқланди ✓"              : "Manzil aniqlandi ✓";
  String get gpsNotDetected      => _cyr ? "Манзил аниқланмади — босинг"     : "Manzil aniqlanmadi — bosing";
  String get gpsOffTap           => _cyr ? "GPS ўчирилган — ёқиш учун босинг" : "GPS o'chirilgan — yoqish uchun bosing";
  String get gpsPermDenied       => _cyr ? "Рухсат берилмаган — созламалар учун босинг" : "Ruxsat berilmagan — sozlamalar uchun bosing";
  String get gpsEnable           => _cyr ? "GPS ёқиш"                        : "GPS yoqish";
  String get gpsDetectBtn        => _cyr ? "Аниқлаш"                         : "Aniqlash";
  String get permDeniedTitle     => _cyr ? "Рухсат берилмаган"               : "Ruxsat berilmagan";
  String get permDeniedMsg       => _cyr ? "Илова созламаларидан жойлашув рухсатини беринг." : "Ilova sozlamalaridan joylashuv ruxsatini bering.";
  String get openSettings        => _cyr ? "Созламалар"                       : "Sozlamalar";

  // ─── Discount ─────────────────────────────────────────────────────────────
  String get discountSettings    => _cyr ? 'Скидка созламалари'                  : 'Skidka sozlamalari';
  String get discountEnabled     => _cyr ? 'Скидкани ёқиш'                       : 'Skidkani yoqish';
  String get discountMinSqm      => _cyr ? 'Минимал майдон (м²)'                 : 'Minimal maydon (m²)';
  String get discountAmount      => _cyr ? 'Скидка миқдори (сўм)'                : 'Skidka miqdori (so\'m)';
  String get discountInfo        => _cyr ? 'Белгиланган майдондан ошса скидка берилади' : 'Belgilangan maydondan oshsa skidka beriladi';
  String get discountSaved       => _cyr ? 'Скидка созламалари сақланди ✓'       : 'Skidka sozlamalari saqlandi ✓';
  String get discountApplied     => _cyr ? 'Скидка'                              : 'Skidka';
  String get subtotal            => _cyr ? 'Нарх'                                : 'Narx';
  String get totalWithDiscount   => _cyr ? 'Жами (скидка билан)'                 : 'Jami (skidka bilan)';
  String get discountHint        => _cyr ? 'Масалан: 50 м² дан ошса 30 000 сўм скидка' : 'Masalan: 50 m² dan oshsa 30 000 so\'m skidka';
  String get discountHintSqm     => _cyr ? 'Белгиланган м² дан ошса скидка берилади'    : 'Belgilangan m² dan oshsa skidka beriladi';
  String get discountHintMeter   => _cyr ? 'Белгиланган метрдан ошса скидка берилади'   : 'Belgilangan metrdan oshsa skidka beriladi';
  String get discountHintPiece   => _cyr ? 'Белгиланган донадан ошса скидка берилади'   : 'Belgilangan donadan oshsa skidka beriladi';

  // ─── Update dialog ────────────────────────────────────────────────────────
  String get updateRequired      => _cyr ? 'Янгиланиш керак'                  : 'Yangilanish kerak';

  // ─── Driver pickup ────────────────────────────────────────────────────────
  String get receiveCarpets      => _cyr ? 'Гиламларни қабул қилиш'           : 'Gilamlarni qabul qilish';
  String get howManyCarpets      => _cyr ? 'Нечта гилам?'                     : 'Nechta gilam?';
  String get minOneCarpetSize    => _cyr ? "Камида 1 та гилам ўлчамини киритинг" : "Kamida 1 ta gilam o'lchamini kiriting";
  String get carpetCountTitle    => _cyr ? 'Гилам сони'                       : 'Gilam soni';
  String get enterCountLabel     => _cyr ? 'Сонини киритинг'                  : 'Sonini kiriting';
  String get pieceCounter        => _cyr ? 'та'                               : 'ta';
  String get enterSizeLabel      => _cyr ? "Ўлчам киритинг"                   : "O'lcham kiriting";
  String get mapBtn              => _cyr ? 'Харита'                           : 'Xarita';
  String get botBadge            => _cyr ? 'Бот'                              : 'Bot';
  String get deliverAsDebtBtn    => _cyr ? "Қарзга етказиб бериш"             : "Qarzga yetkazib berish";
  String get paymentAcceptedMsg  => _cyr ? "✓ Тўлов қабул қилинди"            : "✓ To'lov qabul qilindi";
  String get deliveredAsDebtMsg  => _cyr ? "✓ Қарзга етказиб берилди"         : "✓ Qarzga yetkazib berildi";
  String get deliveredAsDebtLabel => _cyr ? "Қарзга етказиб берилди"          : "Qarzga yetkazib berildi";
  String get noDebtors           => _cyr ? "Қарздорлар йўқ"                   : "Qarzdorlar yo'q";
  String get driversReportTitle  => _cyr ? "Ҳайдовчилар ҳисоби"               : "Haydovchilar hisobi";
  String get advanceColon        => _cyr ? "Аванс: "                          : "Avans: ";
  String get savedWithSum        => _cyr ? "Сақланди — "                      : "Saqlandi — ";

  // ─── Admin settings ───────────────────────────────────────────────────────
  String get carpetWashing       => _cyr ? 'Гилам ювиш'                       : 'Gilam yuvish';

  // ─── Common extra ─────────────────────────────────────────────────────────
  String get ok                  => _cyr ? "OK"                               : "OK";
  String get bekor               => _cyr ? "Бекор"                            : "Bekor";
  String get sample              => _cyr ? "Намуна"                           : "Namuna";
  String get allFieldsRequired   => _cyr ? "Барча майдонларни тўлдиринг"     : "Barcha maydonlarni to'ldiring";

  // ─── Notification dialog ──────────────────────────────────────────────────
  String get notificationsTitle  => _cyr ? 'Билдиришномалар'                  : 'Bildirishnomalar';
  String get notificationsBody   => _cyr
      ? 'Янги буюртмалар, ҳолат ўзгаришлари ва муҳим хабарларни дарҳол олиш учун билдиришномаларга рухсат беринг.'
      : "Yangi buyurtmalar, holat o'zgarishlari va muhim xabarlarni darhol olish uchun bildirishnomalarga ruxsat bering.";
  String get later               => _cyr ? 'Кейинроқ'                        : 'Keyinroq';
  String get allowPermission     => _cyr ? 'Рухсат бериш'                    : 'Ruxsat berish';

  // ─── Order detail extra ───────────────────────────────────────────────────
  String get revertStatus        => _cyr ? 'Орқага қайтариш'                 : 'Orqaga qaytarish';
  String get revertBody          => _cyr
      ? 'Бу буюртма "Олиб келинмаган" ҳолатига қайтарилади. Курьер рўйхатида яна кўринади.'
      : "Bu buyurtma \"Olib kelinmagan\" holatiga qaytariladi. Kuryer ro'yxatida yana ko'rinadi.";
  String get markNotPickedUp     => _cyr ? 'Олиб келинмаган деб белгилаш'    : 'Olib kelinmagan deb belgilash';
  String get yesReturn           => _cyr ? 'Ҳа, қайтариш'                   : 'Ha, qaytarish';
  String get calculatedPrice     => _cyr ? 'Ҳисобланган нарх'               : 'Hisoblangan narx';
  String get agreedPrice         => _cyr ? 'Келишилган нарх'                 : 'Kelishilgan narx';
  String get cancelAgreedPrice   => _cyr ? 'Келишилган нархни бекор қилиш'   : 'Kelishilgan narxni bekor qilish';
  String get setPriceTitle       => _cyr ? 'Нархни белгилаш'                 : 'Narxni belgilash';
  String get advancePayment      => _cyr ? 'Олдиндан тўлов'                  : "Oldindan to'lov";
  String get advancePaymentHint  => _cyr ? 'Олдиндан олинган суммa (ихтиёрий)' : 'Oldindan olingan summa (ixtiyoriy)';
  String get remainingAmount     => _cyr ? 'Қолди'                           : 'Qoldi';
  String get prevEntered         => _cyr ? 'Аввал киритилган'                : 'Avval kiritilgan';
  String get addressSaved        => _cyr ? 'Манзил сақланган'                : 'Manzil saqlangan';
  String get totalLabel          => _cyr ? 'Жами:'                           : 'Jami:';
  String get remainingLabel      => _cyr ? 'Қолди:'                          : 'Qoldi:';

  // ─── Driver order detail extra ────────────────────────────────────────────
  String get paymentInfo         => _cyr ? "Тўлов маълумотлари"              : "To'lov ma'lumotlari";
  String get totalPriceLabel     => _cyr ? 'Жами нарх'                       : 'Jami narx';
  String get advanceTaken        => _cyr ? 'Олдиндан олинган'                : 'Oldindan olingan';
  String get paidInAdvance       => _cyr ? 'Олдиндан'                        : 'Oldindan';
  String get paidEarlierSuffix   => _cyr ? "тўланган эди"                    : "to'langan edi";
  String get remainingSum        => _cyr ? 'Қолган сумма'                    : 'Qolgan summa';
  String get remainingColon      => _cyr ? 'Қолган:'                         : 'Qolgan:';
  String get fullyPaid           => _cyr ? "Тўлиқ тўланди"                  : "To'liq to'landi";
  String get enterAdvance        => _cyr ? "Олдиндан тўлов киритиш"          : "Oldindan to'lov kiritish";
  String get editAdvance         => _cyr ? "Олдиндан тўловни таҳрирлаш"     : "Oldindan to'lovni tahrirlash";
  String get pickupLabel         => _cyr ? 'Олиб кетиш'                      : 'Olib ketish';
  String get deliveryTypeLabel   => _cyr ? 'Яетказиш'                        : 'Yetkazish';
  String get xizmatlar           => _cyr ? 'Хизматлар'                       : 'Xizmatlar';
  String get mijoz               => _cyr ? 'Мижоз'                           : 'Mijoz';
  String get ismLabel            => _cyr ? 'Исм'                             : 'Ism';

  // ─── Pickup items extra ───────────────────────────────────────────────────
  String get howMany             => _cyr ? 'Нечта'                           : 'Nechta';

  // ─── Manage users extra ───────────────────────────────────────────────────
  String get workerLabel2        => _cyr ? 'Ишчи'                            : 'Ishchi';
  String get driverLabel2        => _cyr ? 'Ҳайдовчи'                        : 'Haydovchi';
  String get cancelAction        => _cyr ? 'Бекор қилиш'                     : 'Bekor qilish';
  String get nameLabel           => _cyr ? 'Исм'                             : 'Ism';
}

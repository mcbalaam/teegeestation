#define EMAG_LOCKED_SHUTTLE_COST (CARGO_CRATE_VALUE * 50)

/datum/map_template/shuttle/emergency
	port_id = "emergency"
	name = "базовый шаблон шаттла (аварийный)"
	///assoc list of shuttle events to add to this shuttle on spawn (typepath = weight)
	var/list/events
	///pick all events instead of random
	var/use_all_events = FALSE
	///how many do we pick
	var/event_amount = 1
	///do we empty the event list before adding our events
	var/events_override = FALSE

/datum/map_template/shuttle/emergency/New()
	. = ..()
	if(!occupancy_limit && who_can_purchase)
		CRASH("The [name] needs an occupancy limit!")
	if(HAS_TRAIT(SSstation, STATION_TRAIT_SHUTTLE_SALE) && credit_cost > 0 && prob(15))
		var/discount_amount = round(rand(25, 80), 5)
		name += " (скидка [discount_amount]%!)"
		var/discount_multiplier = 100 - discount_amount
		credit_cost = ((credit_cost * discount_multiplier) / 100)

///on post_load use our variables to change shuttle events
/datum/map_template/shuttle/emergency/post_load(obj/docking_port/mobile/mobile)
	. = ..()
	if(!events)
		return
	if(events_override)
		mobile.event_list.Cut()
	if(use_all_events)
		for(var/path in events)
			mobile.add_shuttle_event(path)
			events -= path
	else
		for(var/i in 1 to event_amount)
			var/path = pick_weight(events)
			events -= path
			mobile.add_shuttle_event(path)

/datum/map_template/shuttle/emergency/backup
	suffix = "backup"
	name = "резервный эвакуационный шаттл"
	who_can_purchase = null

/datum/map_template/shuttle/emergency/construction
	suffix = "construction"
	name = "набор «Собери Свой Шаттл»"
	description = "Для предприимчивого шаттло-инженера! Шасси пристыкуется после покупки, но запуск должен быть авторизован как обычно через вызов шаттла. В комплекте идут строительные материалы."
	admin_notes = "Без брига, без медицинских помещений."
	credit_cost = CARGO_CRATE_VALUE * 5
	who_can_purchase = list(ACCESS_CAPTAIN, ACCESS_CE)
	occupancy_limit = "Flexible"

/datum/map_template/shuttle/emergency/constructionbig
	suffix = "constructionbig"
	name = "набор «Собери Свой Межзвёздный Крейсер»"
	description = "Старший брат строительного набора, с бóльшим пространством для ваших шаттлостроительных идей! Шасси пристыкуется после покупки, но запуск должен быть авторизован как обычно через вызов шаттла. В комплекте идут строительные материалы."
	admin_notes = "Без брига, без медицинских помещений."
	credit_cost = CARGO_CRATE_VALUE * 30
	who_can_purchase = list(ACCESS_CAPTAIN, ACCESS_CE)
	occupancy_limit = "Flexible and more"

/datum/map_template/shuttle/emergency/asteroid
	suffix = "asteroid"
	name = "эвакуационный шаттл Asteroid Station"
	description = "Добротный среднеразмерный шаттл, впервые использовавшийся для перевозки экипажа Нанотрейзен на объекты, расположенные в поясе астероидов, и обратно."
	credit_cost = CARGO_CRATE_VALUE * 6
	occupancy_limit = "50"

/datum/map_template/shuttle/emergency/venture
	suffix = "venture"
	name = "эвакуационный шаттл «Venture»"
	description = "Среднеразмерный шаттл для тех, кто любит много пространства для ног."
	credit_cost = CARGO_CRATE_VALUE * 10
	occupancy_limit = "45"

/datum/map_template/shuttle/emergency/humpback
	suffix = "humpback"
	name = "эвакуационный шаттл «Humpback»"
	description = "Переоборудованное грузовое и спасательное судно для осмотра достопримечательностей и туризма. Имеется бар. Включает двухминутный отпускной тур на территорию карпов."
	credit_cost = CARGO_CRATE_VALUE * 12
	occupancy_limit = "30"
	events = list(
		/datum/shuttle_event/simple_spawner/carp/friendly = 10,
		/datum/shuttle_event/simple_spawner/carp/friendly_but_no_personal_space = 2,
		/datum/shuttle_event/simple_spawner/carp = 2,
		/datum/shuttle_event/simple_spawner/carp/magic = 1,
	)

/datum/map_template/shuttle/emergency/bar
	suffix = "bar"
	name = "аварийный бар для эвакуации"
	description = "Разумный персонал бара (Бардрон и Барледи), санузел, качественный зал для глав и большой обеденный стол."
	admin_notes = "Бардрон и Барледи имеют TRAIT_GODMODE (практически неуязвимость), будут автоматически одушевлены весёлым шариком за 60 секунд до прибытия. \
	Имеются медицинские помещения."
	credit_cost = CARGO_CRATE_VALUE * 10
	occupancy_limit = "30"

/datum/map_template/shuttle/emergency/pod
	suffix = "pod"
	name = "аварийные капсулы"
	description = "Мы не ожидали эвакуации так скоро. Всё, что у нас есть — две спасательные капсулы."
	admin_notes = "Для наказания игроков."
	who_can_purchase = null
	occupancy_limit = "10"

/datum/map_template/shuttle/emergency/russiafightpit
	suffix = "russiafightpit"
	name = "шаттл «Mother Russia Bleeds»"
	description = "Это высококачественный шаттл, да, товарищ! Много сидений, куча места, всё оборудование! Даже развлечения включены! Куча бухла и бойцовская арена для пьяного экипажа! Если арена недостаточно весела, просто нажми кнопку выпуска медведей. Не волнуйтесь, медведи обучены не вырываться из ямы, так что полностью безопасно, пока никто не настолько глуп или пьян, чтобы оставить дверь открытой. Постарайтесь не дать азимовским ботан-консолям всё испортить!"
	admin_notes = "Включает небольшой набор оружия (и медведей). Только доступ капитана позволяет выпустить медведей. Медведи сами не разобьют окна, но могут сбежать, если кто-то их выпустит."
	credit_cost = CARGO_CRATE_VALUE * 10
	occupancy_limit = "40"

/datum/map_template/shuttle/emergency/meteor
	suffix = "meteor"
	name = "астероид с парочкой двигателей"
	description = "Полый астероид с прикрученными двигателями; процедура выдалбливания делает его очень трудным для захвата, но чрезвычайно дорогим. Из-за размера и сложности управления этот шаттл может повредить зону стыковки."
	admin_notes = "Этот шаттл, скорее всего, раздавит зал эвакуации, убив всех, кто там находится."
	credit_cost = CARGO_CRATE_VALUE * 30
	movement_force = list("KNOCKDOWN" = 3, "THROW" = 2)
	occupancy_limit = "CONDEMNED"

/datum/map_template/shuttle/emergency/monastery
	suffix = "monastery"
	name = "Большой Корпоративный Монастырь"
	description = "Изначально построенный для публичной станции, этот грандиозный религиозный храм, из-за сокращения бюджета, теперь доступен в качестве эвакуационного шаттла за соответствующее... пожертвование. Из-за большого размера и бессердечных владельцев этот шаттл может нанести побочный ущерб."
	admin_notes = "ПРЕДУПРЕЖДЕНИЕ: Этот шаттл УНИЧТОЖИТ четверть станции, вероятно, захватив с собой множество объектов."
	emag_only = TRUE
	credit_cost = EMAG_LOCKED_SHUTTLE_COST * 1.8
	movement_force = list("KNOCKDOWN" = 3, "THROW" = 5)
	occupancy_limit = "70"

/datum/map_template/shuttle/emergency/luxury
	suffix = "luxury"
	name = "роскошный эвакуационный шаттл"
	description = "Роскошный золотой шаттл с крытым бассейном. Каждый член экипажа, желающий попасть на борт, должен внести 500 кредитов наличными или минеральной монетой за билет на одного."
	extra_desc = "Посадка на этот шаттл стоит 500 кредитов."
	admin_notes = "Из-за ограниченного места для неплатящего экипажа этот шаттл может вызвать бунт."
	emag_only = TRUE
	credit_cost = EMAG_LOCKED_SHUTTLE_COST
	occupancy_limit = "75"

/datum/map_template/shuttle/emergency/medisim
	suffix = "medisim"
	name = "Средневековый Симуляционный Купол"
	description = "Современный симуляционный купол, установленный на вашем шаттле! Смотрите и смейтесь над тем, каким мелочным было человечество до выхода к звёздам. Историческая достоверность — не менее 40%."
	prerequisites = "Перед покупкой этого шаттла необходимо загрузить специальную голопалубную симуляцию."
	admin_notes = "Призраки могут заходить и сражаться как рыцари или лучники. CTF перезапускается автоматически, вмешательство администраторов не требуется."
	credit_cost = 20000
	occupancy_limit = "30"

/datum/map_template/shuttle/emergency/medisim/prerequisites_met()
	return SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_MEDISIM]

/datum/map_template/shuttle/emergency/discoinferno
	suffix = "discoinferno"
	name = "шаттл «Disco Inferno»"
	description = "Славные результаты столетий исследования плазмы сотрудниками Нанотрейзен. Вот ради чего вы здесь. Заходите и танцуйте, как будто вы в огне, гори-гори ясно!"
	admin_notes = "Обжигающе жарко. В главной зоне есть танцевальный автомат, а также плазменные плитки пола, которые игроки будут поджигать каждый раз."
	emag_only = TRUE
	credit_cost = EMAG_LOCKED_SHUTTLE_COST
	occupancy_limit = "10"

/datum/map_template/shuttle/emergency/arena
	suffix = "arena"
	name = "шаттл «Арена»"
	description = "Чтобы попасть на этот шаттл, экипаж должен пройти через потустороннюю арену. Ожидаются массовые жертвы."
	prerequisites = "Чтобы разблокировать этот шаттл, необходимо выследить и уничтожить источник Кровавого Сигнала."
	admin_notes = "РВИ И ТЕРЗАЙ."
	credit_cost = CARGO_CRATE_VALUE * 20
	occupancy_limit = "1/2"
	/// Whether the arena z-level has been created
	var/arena_loaded = FALSE

/datum/map_template/shuttle/emergency/arena/prerequisites_met()
	return SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_BUBBLEGUM]

/datum/map_template/shuttle/emergency/arena/post_load(obj/docking_port/mobile/M)
	. = ..()
	if(!arena_loaded)
		arena_loaded = TRUE
		var/datum/map_template/arena/arena_template = new()
		arena_template.load_new_z()

/datum/map_template/arena
	name = "The Arena"
	mappath = "_maps/templates/the_arena.dmm"

/datum/map_template/shuttle/emergency/birdboat
	suffix = "birdboat"
	name = "эвакуационный шаттл Birdboat Station"
	description = "Хотя и маловат, этот шаттл полностью укомплектован — чего не скажешь о типе станции, для которой он был заказан."
	credit_cost = CARGO_CRATE_VALUE * 2
	occupancy_limit = "25"

/datum/map_template/shuttle/emergency/box
	suffix = "box"
	name = "эвакуационный шаттл Box Station"
	credit_cost = CARGO_CRATE_VALUE * 4
	description = "Золотой стандарт аварийной эвакуации — эта проверенная временем конструкция оснащена всем необходимым для безопасного полёта экипажа домой."
	occupancy_limit = "45"

/datum/map_template/shuttle/emergency/donut
	suffix = "donut"
	name = "эвакуационный шаттл Donutstation"
	description = "Идеальный остриё для любой пошлой шутки о форме станции; этот шаттл оборудован отдельной камерой содержания для заключённых и компактным медицинским крылом."
	admin_notes = "Имеет шлюзы с обеих сторон шаттла и, вероятно, пересечётся спереди на некоторых станциях, где построили за пределами зоны отправления."
	credit_cost = CARGO_CRATE_VALUE * 5
	occupancy_limit = "60"

/datum/map_template/shuttle/emergency/clown
	suffix = "clown"
	name = "шаттл «Snappop(tm)»"
	description = "Эй, дети и взрослые! \
	Вам надоели СКУЧНЫЕ и НУДНЫЕ путешествия на шаттле после эвакуации по СКУЧНЫМ причинам? Тогда закажите Snappop(tm) сегодня! \
	У нас есть весёлые занятия для всех, кокпит со свободным доступом и никакого скучного брига охраны! Фу! Играйте в переодевания с друзьями! \
	Соберите все простыни раньше соседа! Проверьте, следит ли за вами ИИ, с помощью нашего патентованного «Детектора Подсматривающего ИИ-Мультитула» или сокращённо ПИИИИИП. \
	Приятной поездки!"
	admin_notes = "Бриг заменён на прикрученную книгу гринтекста, окружённую лавалендовыми безднами; дверь со стороны станции убрана во избежание случайного падения. Без брига."
	credit_cost = CARGO_CRATE_VALUE * 16
	occupancy_limit = "HONK"

/datum/map_template/shuttle/emergency/cramped
	suffix = "cramped"
	name = "безопасное транспортное судно 5 (STV5)"
	description = "Ну, похоже у ЦентКома был только этот корабль поблизости; вероятно, они не ожидали, что вам понадобится эвакуация так рано. \
	Наверное, лучше не рыться в том оборудовании, которое они перевозили. Надеюсь, вы дружны с коллегами, потому что места здесь очень мало.\n\
	\n\
	Содержит контрабандное оружие из оружейной, добычу из техтоннелей и брошенные ящики!"
	admin_notes = "Из-за происхождения как одноместного безопасного судна, имеет активный GPS с меткой STV5. Примерно столько же места, как в Hi Daniel, но со взрывоопасными ящиками."
	occupancy_limit = "5"

/datum/map_template/shuttle/emergency/meta
	suffix = "meta"
	name = "эвакуационный шаттл Meta Station"
	credit_cost = CARGO_CRATE_VALUE * 8
	description = "Довольно стандартный шаттл, хотя крупнее и немного лучше оснащён, чем вариант Box Station."
	occupancy_limit = "45"

/datum/map_template/shuttle/emergency/kilo
	suffix = "kilo"
	name = "эвакуационный шаттл Kilo Station"
	credit_cost = CARGO_CRATE_VALUE * 10
	description = "Полностью функциональный шаттл с лазаретом, складскими помещениями и обычными удобствами."
	occupancy_limit = "55"

/datum/map_template/shuttle/emergency/mini
	suffix = "mini"
	name = "эвакуационный шаттл Ministation"
	credit_cost = CARGO_CRATE_VALUE * 2
	description = "Несмотря на название, этот шаттл лишь немного меньше стандартного и всё ещё укомплектован бригом и медотсеком."
	occupancy_limit = "35"

/datum/map_template/shuttle/emergency/tram
	suffix = "tram"
	name = "эвакуационный шаттл Tram Station"
	credit_cost = CARGO_CRATE_VALUE * 4
	description = "Поезд, но в космосе, чух-чух!"
	occupancy_limit = "35"

/datum/map_template/shuttle/emergency/birdshot
	suffix = "birdshot"
	name = "эвакуационный шаттл Birdshot Station"
	credit_cost = CARGO_CRATE_VALUE * 2
	description = "Мы вытащили этот из Мотбола специально для вас!"
	occupancy_limit = "40"


/datum/map_template/shuttle/emergency/emergency_catwalk
	suffix = "catwalk"
	name = "эвакуационный шаттл Catwalk Station"
	credit_cost = CARGO_CRATE_VALUE * 5
	description = "Шаттл стандартного размера с медотсеком и бригом, а также приподнятым мостиком."
	occupancy_limit = "40"

/datum/map_template/shuttle/emergency/wawa
	suffix = "wawa"
	name = "эвакуационный шаттл Wawa"
	description = "Из-за недавней канцелярской ошибки в отделе финансирования значительная часть средств ушла на плюшевых ящериц. В связи с затратами Нанотрейзен предоставила близлежащий мусоровоз в качестве замены. Учитесь делиться местами."
	credit_cost = CARGO_CRATE_VALUE * 6
	occupancy_limit = "25"

/datum/map_template/shuttle/emergency/scrapheap
	suffix = "scrapheap"
	name = "резервное эвакуационное судно «Scrapheap Challenge»"
	credit_cost = CARGO_CRATE_VALUE * -18
	description = "Товарищ! Мы видим, у вас проблемы с деньгами, да? Если у вас денег мало, очень мало, мы ищем хороший шаттл, аварийный шаттл. Вы берёте лучший в секторе шаттл, мы забираем ваш, вы получаете деньги, да? Пожалуйста, не облокачивайтесь на окна, хрупкий как тонкий фарфор. —Иван"
	admin_notes = "Случайно собранная модульная мерзость. Может не иметь рабочего медотсека, отсутствующих секций и очень хрупких окон. На удивление герметичен. При покупке даёт хороший приток денег, но может быть куплен только если бюджет буквально 0 кредитов."
	movement_force = list("KNOCKDOWN" = 3, "THROW" = 2)
	occupancy_limit = "30"
	prerequisites = "Этот шаттл предлагается к покупке только при низком бюджете станции."

/datum/map_template/shuttle/emergency/scrapheap/prerequisites_met()
	return SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_SCRAPHEAP]

/obj/modular_map_root/scrapheapchallenge
	config_file = "strings/modular_maps/emergency_scrapheap.toml"

/datum/map_template/shuttle/emergency/narnar
	suffix = "narnar"
	name = "шаттл номер 667"
	description = "Похоже, этот шаттл мог забрести во тьму между звёзд по пути на станцию. Давайте не будем слишком задумываться о том, откуда взялись все тела."
	admin_notes = "Содержит настоящие культистские руины, глаза-мобов и неактивные конструкции. Мобы культа будут автоматически одушевлены весёлым шариком. \
	Капсулы клонирования в зоне 'медотсека' являются выставочными и нерабочими."
	prerequisites = "Таинственную культистскую руну необходимо изгнать, прежде чем этот шаттл можно будет призвать."
	credit_cost = 6667
	occupancy_limit = "666"

/datum/map_template/shuttle/emergency/narnar/prerequisites_met()
	return SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_NARNAR]

/datum/map_template/shuttle/emergency/pubby
	suffix = "pubby"
	name = "эвакуационный шаттл Pubby Station"
	description = "Поезд, но в космосе! Укомплектован первым и вторым классом, бригом и складской зоной."
	admin_notes = "Чух-чух, мазафакер!"
	credit_cost = CARGO_CRATE_VALUE * 2
	occupancy_limit = "50"

/datum/map_template/shuttle/emergency/cere
	suffix = "cere"
	name = "эвакуационный шаттл Cere Station"
	description = "Крупная, усиленная версия стандартного шаттла Box. Включает расширенный бриг, полностью укомплектованный медотсек, расширенное грузовое хранилище с зарядниками для мехов, \
	машинное отделение с различными припасами и вместимость экипажа 80+. Живите по-крупному, живите Cere."
	admin_notes = "Серьёзно большой, даже крупнее шаттла Delta."
	credit_cost = CARGO_CRATE_VALUE * 20
	occupancy_limit = "110"

/datum/map_template/shuttle/emergency/supermatter
	suffix = "supermatter"
	name = "гиперфрактальный гигашаттл"
	description = "\"Не знаю, это кажется излишне сложным.\"\n\
	\"У этого шаттла очень высокий уровень безопасности, по словам Кадета ЦентКома Йинса.\"\n\
	\"Ты уверен?\"\n\
	\"Да, у него рейтинг безопасности N-A-N, что, видимо, больше 100%.\""
	admin_notes = "Суперматерия на шаттле — это специальная закреплённая 'безопасная' суперматерия, которая не получает урона и не поглощает и не выделяет газ. \
	Без вмешательства администрации она не может взорваться. \
	Однако она всё ещё превращает в пыль всё при контакте, излучает высокий уровень радиации и вызывает галлюцинации у всех, кто смотрит на неё без защитных очков. \
	Эмиттеры появляются включёнными; ожидайте административных уведомлений, они безвредны."
	emag_only = TRUE
	credit_cost = EMAG_LOCKED_SHUTTLE_COST
	movement_force = list("KNOCKDOWN" = 3, "THROW" = 2)
	occupancy_limit = "15"

/datum/map_template/shuttle/emergency/imfedupwiththisworld
	suffix = "imfedupwiththisworld"
	name = "Oh, Hi Daniel"
	description = "Как прошёл день в космосе? О, довольно неплохо. Мы получили новую космическую станцию, и компания заработает много денег. Какую космическую станцию? Не могу сказать; это космическая тайна. \
	Ну, космически колись. Почему нет? Нет, не могу. Кстати, как твоя космическая ролевая игра?"
	admin_notes = "Крошечный, с одним шлюзом и деревянными стенами. Что может пойти не так?"
	emag_only = TRUE
	credit_cost = EMAG_LOCKED_SHUTTLE_COST
	movement_force = list("KNOCKDOWN" = 3, "THROW" = 2)
	occupancy_limit = "5"

/datum/map_template/shuttle/emergency/goon
	suffix = "goon"
	name = "NES Port"
	description = "Аварийный шаттл Нанотрейзен Port (сокр. NES Port) — шаттл, используемый на других, менее известных объектах Нанотрейзен; имеет более открытый интерьер для больших толп, но меньше бортовых удобств."
	credit_cost = CARGO_CRATE_VALUE
	occupancy_limit = "40"

/datum/map_template/shuttle/emergency/rollerdome
	suffix = "rollerdome"
	name = "роллердром дяди Пита"
	description = "Разработан членом команды R&D Нанотрейзен, утверждающим, что он прибыл из 2028 года. \
	Он говорит, что этот шаттл основан на старом развлекательном комплексе 1990-х, хотя в нашей базе данных нет записей о чём-либо, относящемся к тому десятилетию."
	admin_notes = "ТОЛЬКО ДЕТИ ДЕВЯНОСТЫХ ПОМНЯТ. Использует весёлый шарик и дрона из Аварийного Бара."
	credit_cost = CARGO_CRATE_VALUE * 30
	occupancy_limit = "5"

/datum/map_template/shuttle/emergency/basketball
	suffix = "bballhooper"
	name = "баскетбольный стадион с парой двигателей"
	description = "Кидай, мужик, кидай! Прокачай свою игру с этим новым стильным баскетбольным стадионом! Имейте в виду, что некоторые другие функции, \
	которые вы привыкли ожидать на других шаттлах, отсутствуют, чтобы дать вам этот стильный стадион по доступной цене. \
	Он также не был рассчитан на форм-фактор некоторых ваших станций... удачи с этим."
	admin_notes = "Большой шаттл, построенный вокруг баскетбольного стадиона: совершенно непрактично, но невероятно весело!"
	credit_cost = CARGO_CRATE_VALUE * 10
	occupancy_limit = "30"

/datum/map_template/shuttle/emergency/wabbajack
	suffix = "wabbajack"
	name = "крейсер «NT Lepton Violet»"
	description = "Исследовательская команда на этом судне однажды пропала без вести, и никакое расследование не смогло выяснить, что с ними случилось. \
	Единственными обитателями были мёртвые грызуны, которые, по-видимому, загрызли друг друга до смерти. \
	Излишне говорить, что ни одна инженерная команда не хотела приближаться к этой штуке, и она используется как аварийный эвакуационный шаттл только потому, что больше ничего нет."
	admin_notes = "Если экипаж разгадает головоломку, он пробудит статую Ваббаджек. Скорее всего, это плохо кончится. Не зря её заколотили досками. Может, стоило просто оставить её в покое."
	credit_cost = CARGO_CRATE_VALUE * 30
	occupancy_limit = "30"
	prerequisites = "Для покупки этого шаттла необходимо, чтобы произошёл акт магического полиморфизма."

/datum/map_template/shuttle/emergency/wabbajack/prerequisites_met()
	return SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_WABBAJACK]

/datum/map_template/shuttle/emergency/omega
	suffix = "omega"
	name = "эвакуационный шаттл Omegastation"
	description = "Меньшего размера с современным дизайном, этот шаттл для экипажа, предпочитающего уют, но при этом имеющего возможность размять ноги."
	credit_cost = CARGO_CRATE_VALUE * 2
	occupancy_limit = "30"

/datum/map_template/shuttle/emergency/cruise
	suffix = "cruise"
	name = "крейсер «NTSS Independence»"
	description = "Обычно зарезервированный для особых мероприятий и событий, круизный шаттл Independence может привнести летнее настроение в вашу следующую эвакуацию станции за 'скромную' плату!"
	admin_notes = "Этот мазафакер БОЛЬШОЙ. Возможно, придётся принудительно стыковать его."
	credit_cost = CARGO_CRATE_VALUE * 100
	occupancy_limit = "80"

/datum/map_template/shuttle/emergency/monkey
	suffix = "nature"
	name = "шаттл динамического взаимодействия с окружающей средой"
	description = "Большой шаттл с центральным биокуполом, процветающим жизнью. Резвитесь с обезьянками! (Дополнительные обезьянки хранятся на мостике.)"
	admin_notes = "Довольно большой, почти как Raven или Cere. Будьте осторожны с ним."
	credit_cost = CARGO_CRATE_VALUE * 16
	occupancy_limit = "45"

/datum/map_template/shuttle/emergency/casino
	suffix = "casino"
	name = "шаттл «Счастливый Джекпот»"
	description = "Роскошное казино, битком набитое всем необходимым для зарождения новых игровых зависимостей!"
	admin_notes = "Корабль немного громоздкий, так что следите, где паркуете."
	credit_cost = 7777
	occupancy_limit = "85"

/datum/map_template/shuttle/emergency/shadow
	suffix = "shadow"
	name = "шаттл «NTSS Shadow»"
	description = "Гарантированно доставит вас куда-нибудь БЫСТРО. С изготовленным на заказ плазменным двигателем этот красавец унесёт вас дальше от опасности, чем любой другой!"
	admin_notes = "В кормовой части корабля есть плазменный бак, который начинает гореть. Может быть выпущен экипажем. Плазменные окна рядом с нагревателями двигателя также воспламенятся и тоже могут быть выпущены экипажем."
	credit_cost = CARGO_CRATE_VALUE * 50
	occupancy_limit = "40"

/datum/map_template/shuttle/emergency/fish
	suffix = "fish"
	name = "эвакуационный шаттл «Выбор Рыбака»"
	description = "Обменивает такие удобства, как 'складское пространство' и 'достаточное количество сидений', на искусственную среду, идеальную для рыбалки, плюс обильные припасы (тоже для рыбалки)."
	admin_notes = "Внутри есть бездна, есть перила, но это не остановит решительных игроков."
	credit_cost = CARGO_CRATE_VALUE * 10
	occupancy_limit = "35"

/datum/map_template/shuttle/emergency/lance
	suffix = "lance"
	name = "эвакуационный шаттл «Копьё»"
	description = "Совершенно новый шаттл от лучших инженеров Нанотрейзен, разработанный для тактического врезания в разрушенную станцию, устраняя угрозы и одновременно спасая экипаж! Будьте осторожны, не стойте на его пути."
	admin_notes = "ПРЕДУПРЕЖДЕНИЕ: Этот шаттл спроектирован для врезания в станцию. У него есть турели, как у Raven."
	credit_cost = CARGO_CRATE_VALUE * 70
	occupancy_limit = "50"

/datum/map_template/shuttle/emergency/tranquility
	suffix = "tranquility"
	name = "шаттл «Tranquility»"
	description = "Большой шаттл, покрытый флорой и комфортными зонами отдыха. Идеальный способ закончить мирную смену."
	admin_notes = "Он довольно большой и уютный. Будьте осторожны при его размещении!"
	credit_cost = CARGO_CRATE_VALUE * 25
	occupancy_limit = "40"

/datum/map_template/shuttle/emergency/hugcage
	suffix = "hugcage"
	name = "шаттл обнимации"
	description = "Маленький уютный шаттл с множеством кроватей для уставших или чувствительных космонавтов и коробкой для боев подушками."
	admin_notes = "Имеет весёлый шарик одушевления для питомцев."
	credit_cost = CARGO_CRATE_VALUE * 16
	occupancy_limit = "20"

/datum/map_template/shuttle/emergency/fame
	suffix = "fame"
	name = "шаттл Зала Славы"
	description = "Грандиозный шаттл с красной ковровой дорожкой, ведущей в Зал Славы. Достойны ли вы стоять среди лучших космонавтов в истории?"
	admin_notes = "Построен вокруг сохранения воспоминаний, трофеев, фотографий и статуй."
	credit_cost = CARGO_CRATE_VALUE * 25
	occupancy_limit = "55"

/datum/map_template/shuttle/emergency/delta
	suffix = "delta"
	name = "эвакуационный шаттл Delta Station"
	description = "Большой шаттл для большой станции; этот шаттл может комфортно удовлетворить все ваши потребности в перенаселении и скученности. Укомплектован всеми удобствами плюс дополнительным оборудованием."
	admin_notes = "Иди по-крупному или иди домой."
	credit_cost = CARGO_CRATE_VALUE * 15
	occupancy_limit = "75"

/datum/map_template/shuttle/emergency/northstar
	suffix = "northstar"
	name = "эвакуационный шаттл North Star"
	description = "Прочный шаттл, предназначенный для дальних перелётов от окраин фронтира до Центрального Командования и обратно. \
	Умеренно комфортный и большой, но тесноватый."
	credit_cost = CARGO_CRATE_VALUE * 14
	occupancy_limit = "55"

/datum/map_template/shuttle/emergency/nebula
	suffix = "nebula"
	name = "эвакуационный шаттл Nebula Station"
	description = "Превосходный роскошный шаттл для перевозки большого количества пассажиров. \
	Богато оснащён кустами и бесплатным кислородом."
	credit_cost = CARGO_CRATE_VALUE * 18
	occupancy_limit = "80"

/datum/map_template/shuttle/emergency/raven
	suffix = "raven"
	name = "крейсер «Raven»"
	description = "Крейсер ЦентКома Raven — бывшее высокорисковое спасательное судно, ныне переоборудованное в аварийный эвакуационный шаттл. \
	Некогда первым прибывавшее на место для сбора ценных останков в зонах боевых действий, теперь оно служит отличным вариантом эвакуации для станций под плотным огнём внешних сил. \
	Этот эвакуационный шаттл оснащён щитами и многочисленными противопехотными турелями по периметру для отражения метеоров и попыток вражеского абордажа."
	admin_notes = "Укомплектован турелями, которые будут целиться во всё без нейтральной фракции (ядерные оперативники, ксеносы и т.д., но не питомцы)."
	credit_cost = CARGO_CRATE_VALUE * 60
	occupancy_limit = "CLASSIFIED"

/datum/map_template/shuttle/emergency/zeta
	suffix = "zeta"
	name = "Tr%nPo2r& Z3TA"
	description = "На вашем мониторе появляется глитч, мерцающий среди представленных перед вами вариантов. \
	Он выглядит странно и чуждо..."
	prerequisites = "Для доступа к сигналу потребуется исследовать особую инопланетную технологию."
	admin_notes = "Имеет инопланетные хирургические инструменты и ядро пустоты, обеспечивающее неограниченную энергию."
	credit_cost = CARGO_CRATE_VALUE * 16
	occupancy_limit = "xxx"

/datum/map_template/shuttle/emergency/zeta/prerequisites_met()
	return SSshuttle.shuttle_purchase_requirements_met[SHUTTLE_UNLOCK_ALIENTECH]

#undef EMAG_LOCKED_SHUTTLE_COST

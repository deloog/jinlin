/// 数据库模式定义
///
/// 定义数据库的表结构和升级脚本
class DatabaseSchema {
  // 数据库版本
  static const int databaseVersion = 4;

  // 表名
  static const String holidaysTable = 'holidays';
  static const String userSettingsTable = 'user_settings';
  static const String contactsTable = 'contacts';
  static const String reminderEventsTable = 'reminder_events';
  static const String syncStatusTable = 'sync_status';
  static const String appSettingsTable = 'app_settings';

  // 创建节日表
  static const String createHolidaysTable = '''
    CREATE TABLE IF NOT EXISTS $holidaysTable (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      type_id INTEGER NOT NULL,
      date_type INTEGER NOT NULL,
      month INTEGER,
      day INTEGER,
      lunar_month INTEGER,
      lunar_day INTEGER,
      calculation_rule TEXT,
      regions TEXT NOT NULL,
      importance INTEGER NOT NULL DEFAULT 0,
      user_importance INTEGER DEFAULT 0,
      icon_url TEXT,
      image_url TEXT,
      color TEXT,
      names TEXT,
      descriptions TEXT,
      created_at TEXT NOT NULL,
      last_modified TEXT NOT NULL,
      is_sync_conflict INTEGER DEFAULT 0,
      is_deleted INTEGER DEFAULT 0,
      deleted_at TEXT,
      deletion_reason TEXT
    )
  ''';

  // 创建用户设置表
  static const String createUserSettingsTable = '''
    CREATE TABLE IF NOT EXISTS $userSettingsTable (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      nickname TEXT NOT NULL,
      avatar_url TEXT,
      language_code TEXT NOT NULL,
      country_code TEXT,
      show_lunar_calendar INTEGER DEFAULT 0,
      theme_mode INTEGER DEFAULT 0,
      primary_color TEXT,
      background_image_url TEXT,
      enable_notifications INTEGER DEFAULT 1,
      default_reminder_times TEXT,
      enable_sound INTEGER DEFAULT 1,
      enable_vibration INTEGER DEFAULT 1,
      enable_cloud_sync INTEGER DEFAULT 0,
      sync_frequency_hours INTEGER DEFAULT 24,
      last_sync_time TEXT,
      auto_backup INTEGER DEFAULT 0,
      backup_frequency_days INTEGER DEFAULT 7,
      last_backup_time TEXT,
      show_expired_events INTEGER DEFAULT 0,
      expired_event_retention_days INTEGER DEFAULT 30,
      enable_ai_features INTEGER DEFAULT 1,
      enabled_ai_features TEXT,
      created_at TEXT NOT NULL,
      last_modified TEXT NOT NULL
    )
  ''';

  // 创建联系人表
  static const String createContactsTable = '''
    CREATE TABLE IF NOT EXISTS $contactsTable (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      relation_type INTEGER NOT NULL,
      specific_relation TEXT,
      phone_number TEXT,
      email TEXT,
      avatar_url TEXT,
      birthday TEXT,
      is_birthday_lunar INTEGER DEFAULT 0,
      additional_info TEXT,
      associated_holiday_ids TEXT,
      names TEXT,
      specific_relations TEXT,
      created_at TEXT NOT NULL,
      last_modified TEXT NOT NULL,
      is_sync_conflict INTEGER DEFAULT 0,
      is_deleted INTEGER DEFAULT 0,
      deleted_at TEXT,
      deletion_reason TEXT
    )
  ''';

  // 创建提醒事件表
  static const String createReminderEventsTable = '''
    CREATE TABLE IF NOT EXISTS $reminderEventsTable (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      description TEXT,
      type INTEGER NOT NULL,
      due_date TEXT,
      is_all_day INTEGER DEFAULT 1,
      is_lunar_date INTEGER DEFAULT 0,
      status INTEGER DEFAULT 0,
      is_completed INTEGER DEFAULT 0,
      completed_at TEXT,
      is_repeating INTEGER DEFAULT 0,
      repeat_rule TEXT,
      repeat_until TEXT,
      reminder_times TEXT,
      contact_id TEXT,
      holiday_id TEXT,
      location TEXT,
      latitude REAL,
      longitude REAL,
      tags TEXT,
      category TEXT,
      titles TEXT,
      descriptions TEXT,
      ai_generated_description TEXT,
      ai_generated_greetings TEXT,
      ai_generated_gift_suggestions TEXT,
      importance INTEGER DEFAULT 0,
      custom_color TEXT,
      custom_icon TEXT,
      is_shared INTEGER DEFAULT 0,
      shared_with TEXT,
      last_synced TEXT,
      is_sync_conflict INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      last_modified TEXT NOT NULL,
      is_deleted INTEGER DEFAULT 0,
      deleted_at TEXT,
      deletion_reason TEXT,
      FOREIGN KEY (contact_id) REFERENCES $contactsTable (id) ON DELETE SET NULL,
      FOREIGN KEY (holiday_id) REFERENCES $holidaysTable (id) ON DELETE SET NULL
    )
  ''';

  // 创建同步状态表
  static const String createSyncStatusTable = '''
    CREATE TABLE IF NOT EXISTS $syncStatusTable (
      id TEXT PRIMARY KEY,
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      sync_status INTEGER NOT NULL,
      is_conflict INTEGER DEFAULT 0,
      server_version TEXT,
      local_version TEXT,
      last_sync_time TEXT NOT NULL,
      created_at TEXT NOT NULL,
      last_modified TEXT NOT NULL,
      is_deleted INTEGER DEFAULT 0,
      deleted_at TEXT
    )
  ''';

  // 创建应用设置表
  static const String createAppSettingsTable = '''
    CREATE TABLE IF NOT EXISTS $appSettingsTable (
      id TEXT PRIMARY KEY,
      key TEXT NOT NULL,
      value TEXT,
      created_at TEXT NOT NULL,
      last_modified TEXT NOT NULL
    )
  ''';

  // 创建索引
  static const List<String> createIndexes = [
    // 节日表索引
    'CREATE INDEX IF NOT EXISTS idx_holidays_regions ON $holidaysTable (regions)',
    'CREATE INDEX IF NOT EXISTS idx_holidays_type_id ON $holidaysTable (type_id)',
    'CREATE INDEX IF NOT EXISTS idx_holidays_date_type ON $holidaysTable (date_type)',
    'CREATE INDEX IF NOT EXISTS idx_holidays_month_day ON $holidaysTable (month, day)',
    'CREATE INDEX IF NOT EXISTS idx_holidays_lunar_month_day ON $holidaysTable (lunar_month, lunar_day)',
    'CREATE INDEX IF NOT EXISTS idx_holidays_last_modified ON $holidaysTable (last_modified)',
    'CREATE INDEX IF NOT EXISTS idx_holidays_name ON $holidaysTable (name)',
    'CREATE INDEX IF NOT EXISTS idx_holidays_importance ON $holidaysTable (importance)',
    'CREATE INDEX IF NOT EXISTS idx_holidays_user_importance ON $holidaysTable (user_importance)',
    'CREATE INDEX IF NOT EXISTS idx_holidays_type_regions ON $holidaysTable (type_id, regions)',

    // 联系人表索引
    'CREATE INDEX IF NOT EXISTS idx_contacts_relation_type ON $contactsTable (relation_type)',
    'CREATE INDEX IF NOT EXISTS idx_contacts_birthday ON $contactsTable (birthday)',
    'CREATE INDEX IF NOT EXISTS idx_contacts_last_modified ON $contactsTable (last_modified)',
    'CREATE INDEX IF NOT EXISTS idx_contacts_name ON $contactsTable (name)',
    'CREATE INDEX IF NOT EXISTS idx_contacts_is_birthday_lunar ON $contactsTable (is_birthday_lunar)',
    'CREATE INDEX IF NOT EXISTS idx_contacts_birthday_is_lunar ON $contactsTable (birthday, is_birthday_lunar)',

    // 提醒事件表索引
    'CREATE INDEX IF NOT EXISTS idx_reminder_events_due_date ON $reminderEventsTable (due_date)',
    'CREATE INDEX IF NOT EXISTS idx_reminder_events_type ON $reminderEventsTable (type)',
    'CREATE INDEX IF NOT EXISTS idx_reminder_events_status ON $reminderEventsTable (status)',
    'CREATE INDEX IF NOT EXISTS idx_reminder_events_contact_id ON $reminderEventsTable (contact_id)',
    'CREATE INDEX IF NOT EXISTS idx_reminder_events_holiday_id ON $reminderEventsTable (holiday_id)',
    'CREATE INDEX IF NOT EXISTS idx_reminder_events_last_modified ON $reminderEventsTable (last_modified)',
    'CREATE INDEX IF NOT EXISTS idx_reminder_events_is_completed ON $reminderEventsTable (is_completed)',
    'CREATE INDEX IF NOT EXISTS idx_reminder_events_title ON $reminderEventsTable (title)',
    'CREATE INDEX IF NOT EXISTS idx_reminder_events_category ON $reminderEventsTable (category)',
    'CREATE INDEX IF NOT EXISTS idx_reminder_events_is_lunar_date ON $reminderEventsTable (is_lunar_date)',
    'CREATE INDEX IF NOT EXISTS idx_reminder_events_due_completed ON $reminderEventsTable (due_date, is_completed)',
    'CREATE INDEX IF NOT EXISTS idx_reminder_events_type_status ON $reminderEventsTable (type, status)',
    'CREATE INDEX IF NOT EXISTS idx_reminder_events_importance ON $reminderEventsTable (importance)',

    // 同步状态表索引
    'CREATE INDEX IF NOT EXISTS idx_sync_status_entity ON $syncStatusTable (entity_type, entity_id)',
    'CREATE INDEX IF NOT EXISTS idx_sync_status_conflict ON $syncStatusTable (is_conflict)',
    'CREATE INDEX IF NOT EXISTS idx_sync_status_entity_conflict ON $syncStatusTable (entity_type, entity_id, is_conflict)',

    // 应用设置表索引
    'CREATE INDEX IF NOT EXISTS idx_app_settings_key ON $appSettingsTable (key)',
    'CREATE INDEX IF NOT EXISTS idx_app_settings_last_modified ON $appSettingsTable (last_modified)',
  ];

  /// 获取数据库升级脚本
  static List<String> getUpgradeScripts(int oldVersion, int newVersion) {
    final List<String> scripts = [];

    // 从版本1升级到版本2
    if (oldVersion < 2 && newVersion >= 2) {
      // 删除旧表
      scripts.add('DROP TABLE IF EXISTS $holidaysTable');
      scripts.add('DROP TABLE IF EXISTS $userSettingsTable');
      scripts.add('DROP TABLE IF EXISTS $contactsTable');
      scripts.add('DROP TABLE IF EXISTS $reminderEventsTable');
      scripts.add('DROP TABLE IF EXISTS $syncStatusTable');

      // 创建新表
      scripts.add(createHolidaysTable);
      scripts.add(createUserSettingsTable);
      scripts.add(createContactsTable);
      scripts.add(createReminderEventsTable);
      scripts.add(createSyncStatusTable);

      // 创建索引
      for (final indexSql in createIndexes) {
        scripts.add(indexSql);
      }
    }

    // 从版本2升级到版本3（添加软删除支持）
    if (oldVersion == 2 && newVersion >= 3) {
      // 节日表添加软删除字段
      scripts.add('ALTER TABLE $holidaysTable ADD COLUMN is_deleted INTEGER DEFAULT 0');
      scripts.add('ALTER TABLE $holidaysTable ADD COLUMN deleted_at TEXT');
      scripts.add('ALTER TABLE $holidaysTable ADD COLUMN deletion_reason TEXT');

      // 联系人表添加软删除字段
      scripts.add('ALTER TABLE $contactsTable ADD COLUMN is_deleted INTEGER DEFAULT 0');
      scripts.add('ALTER TABLE $contactsTable ADD COLUMN deleted_at TEXT');
      scripts.add('ALTER TABLE $contactsTable ADD COLUMN deletion_reason TEXT');

      // 提醒事件表添加软删除字段
      scripts.add('ALTER TABLE $reminderEventsTable ADD COLUMN is_deleted INTEGER DEFAULT 0');
      scripts.add('ALTER TABLE $reminderEventsTable ADD COLUMN deleted_at TEXT');
      scripts.add('ALTER TABLE $reminderEventsTable ADD COLUMN deletion_reason TEXT');

      // 同步状态表添加软删除字段
      scripts.add('ALTER TABLE $syncStatusTable ADD COLUMN is_deleted INTEGER DEFAULT 0');
      scripts.add('ALTER TABLE $syncStatusTable ADD COLUMN deleted_at TEXT');

      // 创建软删除索引
      scripts.add('CREATE INDEX IF NOT EXISTS idx_holidays_is_deleted ON $holidaysTable (is_deleted)');
      scripts.add('CREATE INDEX IF NOT EXISTS idx_contacts_is_deleted ON $contactsTable (is_deleted)');
      scripts.add('CREATE INDEX IF NOT EXISTS idx_reminder_events_is_deleted ON $reminderEventsTable (is_deleted)');
      scripts.add('CREATE INDEX IF NOT EXISTS idx_sync_status_is_deleted ON $syncStatusTable (is_deleted)');
    }

    // 从版本3升级到版本4（添加性能优化索引）
    if (oldVersion < 4 && newVersion >= 4) {
      // 节日表添加索引
      scripts.add('CREATE INDEX IF NOT EXISTS idx_holidays_name ON $holidaysTable (name)');
      scripts.add('CREATE INDEX IF NOT EXISTS idx_holidays_importance ON $holidaysTable (importance)');
      scripts.add('CREATE INDEX IF NOT EXISTS idx_holidays_user_importance ON $holidaysTable (user_importance)');
      scripts.add('CREATE INDEX IF NOT EXISTS idx_holidays_type_regions ON $holidaysTable (type_id, regions)');

      // 联系人表添加索引
      scripts.add('CREATE INDEX IF NOT EXISTS idx_contacts_name ON $contactsTable (name)');
      scripts.add('CREATE INDEX IF NOT EXISTS idx_contacts_is_birthday_lunar ON $contactsTable (is_birthday_lunar)');
      scripts.add('CREATE INDEX IF NOT EXISTS idx_contacts_birthday_is_lunar ON $contactsTable (birthday, is_birthday_lunar)');

      // 提醒事件表添加索引
      scripts.add('CREATE INDEX IF NOT EXISTS idx_reminder_events_is_completed ON $reminderEventsTable (is_completed)');
      scripts.add('CREATE INDEX IF NOT EXISTS idx_reminder_events_title ON $reminderEventsTable (title)');
      scripts.add('CREATE INDEX IF NOT EXISTS idx_reminder_events_category ON $reminderEventsTable (category)');
      scripts.add('CREATE INDEX IF NOT EXISTS idx_reminder_events_is_lunar_date ON $reminderEventsTable (is_lunar_date)');
      scripts.add('CREATE INDEX IF NOT EXISTS idx_reminder_events_due_completed ON $reminderEventsTable (due_date, is_completed)');
      scripts.add('CREATE INDEX IF NOT EXISTS idx_reminder_events_type_status ON $reminderEventsTable (type, status)');
      scripts.add('CREATE INDEX IF NOT EXISTS idx_reminder_events_importance ON $reminderEventsTable (importance)');

      // 同步状态表添加索引
      scripts.add('CREATE INDEX IF NOT EXISTS idx_sync_status_entity_conflict ON $syncStatusTable (entity_type, entity_id, is_conflict)');

      // 应用设置表添加索引
      scripts.add('CREATE INDEX IF NOT EXISTS idx_app_settings_key ON $appSettingsTable (key)');
      scripts.add('CREATE INDEX IF NOT EXISTS idx_app_settings_last_modified ON $appSettingsTable (last_modified)');
    }

    return scripts;
  }
}

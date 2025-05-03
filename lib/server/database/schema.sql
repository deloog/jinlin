-- 数据库表结构

-- 节日表
CREATE TABLE IF NOT EXISTS holidays (
    id VARCHAR(50) PRIMARY KEY,
    type VARCHAR(20) NOT NULL,
    calculation_type VARCHAR(20) NOT NULL,
    calculation_rule VARCHAR(50) NOT NULL,
    importance_level INT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 节日翻译表
CREATE TABLE IF NOT EXISTS holiday_translations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    holiday_id VARCHAR(50) NOT NULL,
    language_code VARCHAR(10) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    customs TEXT,
    foods TEXT,
    greetings TEXT,
    FOREIGN KEY (holiday_id) REFERENCES holidays(id) ON DELETE CASCADE,
    UNIQUE KEY (holiday_id, language_code)
);

-- 地区表
CREATE TABLE IF NOT EXISTS regions (
    code VARCHAR(10) PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

-- 节日地区关联表
CREATE TABLE IF NOT EXISTS holiday_regions (
    holiday_id VARCHAR(50) NOT NULL,
    region_code VARCHAR(10) NOT NULL,
    PRIMARY KEY (holiday_id, region_code),
    FOREIGN KEY (holiday_id) REFERENCES holidays(id) ON DELETE CASCADE,
    FOREIGN KEY (region_code) REFERENCES regions(code) ON DELETE CASCADE
);

-- 语言表
CREATE TABLE IF NOT EXISTS languages (
    code VARCHAR(10) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 数据版本表
CREATE TABLE IF NOT EXISTS data_versions (
    region_code VARCHAR(10) NOT NULL,
    version INT NOT NULL DEFAULT 1,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (region_code)
);

-- 初始化语言数据
INSERT IGNORE INTO languages (code, name) VALUES
('zh', '中文'),
('en', 'English'),
('ja', '日本語'),
('ko', '한국어'),
('fr', 'Français'),
('de', 'Deutsch');

-- 初始化地区数据
INSERT IGNORE INTO regions (code, name) VALUES
('GLOBAL', 'Global'),
('CN', 'China'),
('US', 'United States'),
('JP', 'Japan'),
('KR', 'Korea'),
('FR', 'France'),
('DE', 'Germany');

-- 初始化数据版本
INSERT IGNORE INTO data_versions (region_code, version) VALUES
('GLOBAL', 1),
('CN', 1),
('US', 1),
('JP', 1),
('KR', 1),
('FR', 1),
('DE', 1);

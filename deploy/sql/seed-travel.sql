-- Active: 1785918095841@@127.0.0.1@33069@looklook_travel
-- Active: 1785918095841@@127.0.0.1@33069@looklook_travell
-- =====================================================
-- seed-travel.sql
-- 给 looklook_travel 库造 3 间民宿的测试数据
-- 关联步骤：Step 5 M1.5 (2026-08-05)
-- 数据关系：homestay_activity.data_id → homestay.id
--         homestay.homestay_business_id → homestay_business.id
-- =====================================================
USE looklook_travel;

-- 设置外键检查关闭 (虽然本表无外键, 但保持一致)
SET FOREIGN_KEY_CHECKS = 0;

-- 清空旧数据 (避免重复 key 冲突)
TRUNCATE TABLE homestay_comment;
TRUNCATE TABLE homestay_activity;
TRUNCATE TABLE homestay;
TRUNCATE TABLE homestay_business;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================
-- 1. 民宿店铺 (homestay_business) - 1 个
-- =====================================================
INSERT INTO homestay_business
  (id, create_time, update_time, delete_time, del_state,
   title, user_id, info, boss_info, license_fron, license_back,
   row_state, star, tags, cover, header_img, version)
VALUES
  (1, NOW(), NOW(), NOW(), 0,
   '云栖民宿', 10001, '面朝大海 春暖花开', '老板阿强 10年民宿经验',
   'license_front_1.jpg', 'license_back_1.jpg',
   1, 4.8, '海景/亲子',
   'https://img.example.com/business1_cover.jpg',
   'https://img.example.com/business1_header.jpg',
   0);

-- =====================================================
-- 2. 民宿 (homestay) - 3 个, 都属于 id=1 店铺
-- =====================================================
INSERT INTO homestay
  (id, create_time, update_time, delete_time, del_state,
   title, sub_title, banner, info, people_num,
   homestay_business_id, user_id, row_state, row_type,
   food_info, food_price, homestay_price, market_homestay_price, version)
VALUES
  -- 民宿 1: 海景大床房
  (1, NOW(), NOW(), NOW(), 0,
   '海景大床房', '180° 全海景',
   'https://img.example.com/h1_banner.jpg,https://img.example.com/h1_banner2.jpg',
   '落地窗、独立卫浴、超大海景阳台，看日出绝佳位置',
   2, 1, 10001, 1, 0,
   '含双早', 8800, 58800, 98800, 0),

  -- 民宿 2: 亲子双床房
  (2, NOW(), NOW(), NOW(), 0,
   '亲子双床房', '带滑梯的儿童房',
   'https://img.example.com/h2_banner.jpg',
   '主卧 + 儿童房 + 滑梯，孩子玩到不肯走',
   4, 1, 10001, 1, 0,
   '含四早', 15800, 98800, 158800, 0),

  -- 民宿 3: 复式家庭套房
  (3, NOW(), NOW(), NOW(), 0,
   '复式家庭套房', 'loft 顶层 + 露台',
   'https://img.example.com/h3_banner.jpg',
   '上下两层共 80 平，顶层私享露台可烧烤',
   6, 1, 10001, 1, 1,
   '含六早 + 烧烤架', 28800, 188800, 268800, 0);

-- =====================================================
-- 3. 活动映射 (homestay_activity) - 关键表!
-- homestayList 接口查的就是这张表
--   row_type = 'preferredHomestay' → 优选民宿
--   row_status = 1                 → 上架
--   data_id = homestay.id
-- =====================================================
INSERT INTO homestay_activity
  (id, create_time, update_time, delete_time, del_state,
   row_type, data_id, row_status, version)
VALUES
  (1, NOW(), NOW(), NOW(), 0, 'preferredHomestay', 1, 1, 0),
  (2, NOW(), NOW(), NOW(), 0, 'preferredHomestay', 2, 1, 0),
  (3, NOW(), NOW(), NOW(), 0, 'preferredHomestay', 3, 1, 0);

-- =====================================================
-- 4. 评论 (homestay_comment) - 3 条, 演示 commentList 接口
-- =====================================================
INSERT INTO homestay_comment
  (id, create_time, update_time, delete_time, del_state,
   homestay_id, user_id, content, star, version)
VALUES
  (1, NOW(), NOW(), NOW(), 0, 1, 20001,
   '房间非常干净，海景绝了，下次还来！',
   '{"overall": 5, "clean": 5, "service": 5, "facility": 5}', 0),
  (2, NOW(), NOW(), NOW(), 0, 2, 20002,
   '孩子玩疯了，老板热情，早餐丰富',
   '{"overall": 5, "clean": 4, "service": 5, "facility": 5}', 0),
  (3, NOW(), NOW(), NOW(), 0, 3, 20003,
   '复式很大，露台烧烤很棒，就是上下楼要小心',
   '{"overall": 4, "clean": 5, "service": 4, "facility": 5}', 0);

-- =====================================================
-- 校验 (导入完跑一下, 应该看到 3 行 activity)
-- =====================================================
SELECT 'travel seed 完成' AS message,
       (SELECT COUNT(*) FROM homestay_business) AS business_count,
       (SELECT COUNT(*) FROM homestay) AS homestay_count,
       (SELECT COUNT(*) FROM homestay_activity WHERE row_type='preferredHomestay' AND row_status=1) AS up_preferred_count,
       (SELECT COUNT(*) FROM homestay_comment) AS comment_count;

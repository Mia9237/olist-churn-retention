# Data Source & Data Dictionary

## 1. 数据集信息

数据集：Olist Brazilian E-Commerce Public Dataset
来源：Kaggle
下载地址：https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

> 说明：原始 CSV 文件不存入代码仓库（文件较大，已加入 .gitignore），需要使用者自行下载放入 `data/` 目录。
> 数据时间范围：2016-09 ~ 2018-09，共 9 张业务表，覆盖订单、客户、支付、商品、评价、物流等电商全链路数据。

## 2. 表清单 & 表业务说明

| 表名 | 中文名称 | 核心用途 |
|---|---|---|
| olist_customers_dataset | 用户表 | 用户唯一 ID、用户所在地区 |
| olist_orders_dataset | 订单主表 | 订单 ID、用户 ID、订单状态、各阶段时间戳（下单/发货/签收），本项目时序窗口切分核心表 |
| olist_order_items_dataset | 订单商品明细表 | 订单内商品、商品 ID、单价、数量 |
| olist_products_dataset | 商品表 | 商品类目、商品基础属性 |
| olist_order_payments_dataset | 支付表 | 订单支付方式、支付金额、支付分期数 |
| olist_order_reviews_dataset | 评价表 | 用户评价分数、评价时间、评价文本 |
| olist_geolocation_dataset | 地理信息表 | 邮编对应城市、经纬度，用于地域特征 |
| product_category_name_translation | 商品类目翻译表 | 葡萄牙语类目翻译成英文 |
| olist_sellers_dataset | 卖家表 | 卖家 ID 与所在地，本项目未重点使用 |

## 3. 核心关联主键

- `customer_id`：用户唯一标识，customers 表主键，关联 orders 表
- `order_id`：订单唯一标识，orders 表主键，关联 order_items / payments / reviews
- `product_id`：商品唯一标识，关联 order_items 与 products 表

## 4. 关键字段说明（建模用到的重点字段）

> 只写项目里实际用到的字段，不用全量罗列，精简为主

1. customers
    - `customer_id`：用户 ID
    - `customer_zip_code_prefix`：邮编前缀
2. orders
    - `order_id`：订单 ID
    - `customer_id`：用户 ID
    - `order_purchase_timestamp`：**下单时间（时序切分核心字段）**
    - `order_status`：订单状态（delivered/shipped/canceled）
    - `order_delivered_customer_date`：签收时间
3. order_payments
    - `payment_value`：支付金额（RFM 的 M，总消费金额）
    - `payment_type`：支付类型
4. order_reviews
    - `review_score`：用户评价分（作为用户满意度特征）

## 5. 数据质量说明

1. 时间范围：订单时间 2016-09-04 ~ 2018-09-03，和项目观测/预测窗口对齐。
2. 异常说明：存在部分取消订单、缺失签收时间，SQL 阶段做过滤（仅保留已交付完成订单用于 RFM 与流失标签构建）。
3. 注意：数据集是静态历史快照，没有实时更新数据。
4. 数据粒度：一条订单可以包含多个商品，一个用户可有多条订单。

## 6. 使用提示

下载后将所有 CSV 文件放入 `data/` 目录，`sql/` 下的取数脚本与 `notebooks/` 下的 Notebook 读取该目录下原始数据。

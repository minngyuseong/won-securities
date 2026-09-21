CREATE DATABASE stock_service
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;
    
    
SHOW DATABASES;


USE stock_service;


-- =========================================================
-- 1. 고객
-- =========================================================
CREATE TABLE CUSTOMER (
    customer_id BIGINT NOT NULL AUTO_INCREMENT COMMENT '고객ID',
    login_id VARCHAR(50) NOT NULL COMMENT '로그인ID',
    password_hash VARCHAR(255) NOT NULL COMMENT '비밀번호해시',
    customer_name VARCHAR(50) NOT NULL COMMENT '고객명',
    birth_date DATE NOT NULL COMMENT '생년월일',
    mobile_no VARCHAR(20) NOT NULL COMMENT '휴대전화번호',
    email VARCHAR(100) NULL COMMENT '이메일',
    address VARCHAR(255) NULL COMMENT '주소',
    customer_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        COMMENT '고객상태: ACTIVE, DEACTIVE',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT '등록일시',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
        COMMENT '수정일시',
    withdrawn_at DATETIME NULL COMMENT '탈퇴일시',

    PRIMARY KEY (customer_id),
    UNIQUE KEY uk_customer_login_id (login_id)
) COMMENT = '고객';


-- =========================================================
-- 2. 계좌
-- =========================================================
CREATE TABLE ACCOUNT (
    account_id BIGINT NOT NULL AUTO_INCREMENT COMMENT '계좌ID',
    customer_id BIGINT NOT NULL COMMENT '고객ID',
    account_no VARCHAR(20) NOT NULL COMMENT '계좌번호',
    account_type VARCHAR(20) NOT NULL
        COMMENT '계좌유형: CMA, ISA',
    account_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        COMMENT '계좌상태: ACTIVE, DEACTIVE',
    deposit_balance DECIMAL(18, 2) NOT NULL DEFAULT 0
        COMMENT '예수금',
    opened_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT '계좌개설일시',
    closed_at DATETIME NULL COMMENT '계좌해지일시',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
        COMMENT '수정일시',

    PRIMARY KEY (account_id),
    UNIQUE KEY uk_account_account_no (account_no),

    CONSTRAINT fk_account_customer
        FOREIGN KEY (customer_id)
        REFERENCES CUSTOMER (customer_id)
) COMMENT = '증권계좌';


-- =========================================================
-- 3. 종목
-- =========================================================
CREATE TABLE STOCK_ITEM (
    stock_id BIGINT NOT NULL AUTO_INCREMENT COMMENT '종목ID',
    stock_code VARCHAR(12) NOT NULL COMMENT '종목코드',
    stock_name VARCHAR(100) NOT NULL COMMENT '종목명',
    stock_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        COMMENT '종목상태: ACTIVE, SUSPENDED, DELISTED',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT '등록일시',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
        COMMENT '수정일시',

    PRIMARY KEY (stock_id),
    UNIQUE KEY uk_stock_item_stock_code (stock_code)
) COMMENT = '주식종목';


-- =========================================================
-- 4. 보유잔고
-- =========================================================
CREATE TABLE HOLDING_BALANCE (
    account_id BIGINT NOT NULL COMMENT '계좌ID',
    stock_id BIGINT NOT NULL COMMENT '종목ID',
    holding_quantity BIGINT NOT NULL DEFAULT 0
        COMMENT '보유수량',
    average_purchase_price DECIMAL(18, 2) NOT NULL DEFAULT 0
        COMMENT '평균매입단가',

    PRIMARY KEY (account_id, stock_id),

    CONSTRAINT fk_holding_balance_account
        FOREIGN KEY (account_id)
        REFERENCES ACCOUNT (account_id),

    CONSTRAINT fk_holding_balance_stock
        FOREIGN KEY (stock_id)
        REFERENCES STOCK_ITEM (stock_id)
) COMMENT = '종목보유잔고';


-- =========================================================
-- 5. 주식주문
-- =========================================================
CREATE TABLE STOCK_ORDER (
    order_id BIGINT NOT NULL AUTO_INCREMENT COMMENT '주문ID',
    account_id BIGINT NOT NULL COMMENT '계좌ID',
    stock_id BIGINT NOT NULL COMMENT '종목ID',
    buy_sell_type VARCHAR(10) NOT NULL
        COMMENT '매매구분: BUY, SELL',
    order_type VARCHAR(10) NOT NULL
        COMMENT '주문유형: MARKET, LIMIT',
    order_price DECIMAL(18, 2) NULL
        COMMENT '주문가격: 시장가 주문 시 NULL',
    order_quantity BIGINT NOT NULL COMMENT '주문수량',
    order_status VARCHAR(20) NOT NULL COMMENT '주문상태',
    ordered_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT '주문일시',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
        COMMENT '수정일시',
    cancelled_at DATETIME NULL COMMENT '취소일시',

    PRIMARY KEY (order_id),

    CONSTRAINT fk_stock_order_account
        FOREIGN KEY (account_id)
        REFERENCES ACCOUNT (account_id),

    CONSTRAINT fk_stock_order_stock
        FOREIGN KEY (stock_id)
        REFERENCES STOCK_ITEM (stock_id)
) COMMENT = '주식주문';


-- =========================================================
-- 6. 체결
-- =========================================================
CREATE TABLE TRADE_EXECUTION (
    execution_id BIGINT NOT NULL AUTO_INCREMENT COMMENT '체결ID',
    order_id BIGINT NOT NULL COMMENT '주문ID',
    execution_price DECIMAL(18, 2) NOT NULL COMMENT '체결가격',
    execution_quantity BIGINT NOT NULL COMMENT '체결수량',
    executed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        COMMENT '체결일시',

    PRIMARY KEY (execution_id),

    CONSTRAINT fk_trade_execution_order
        FOREIGN KEY (order_id)
        REFERENCES STOCK_ORDER (order_id)
) COMMENT = '주문체결';
USE stock_service;


-- ============================================================
-- 1. 회원
-- ============================================================

-- 1-1. 회원가입
-- [파라미터]
-- loginId      : 사용자가 입력한 로그인 ID
-- passwordHash : 애플리케이션에서 BCrypt 처리한 비밀번호 해시
-- customerName : 사용자가 입력한 고객명
-- birthDate    : 사용자가 입력한 생년월일
-- mobileNo     : 사용자가 입력한 휴대전화번호
-- email        : 사용자가 입력한 이메일
-- address      : 사용자가 입력한 주소
--
-- [Workbench 테스트값]
-- loginId      = 'ruby98'
-- passwordHash = '$2a$10$exampleHashValue'
-- customerName = '성루비'
-- birthDate    = '1998-01-01'
-- mobileNo     = '010-1234-5678'
-- email        = 'ruby@example.com'
-- address      = '서울특별시'
INSERT INTO CUSTOMER (
    login_id,
    password_hash,
    customer_name,
    birth_date,
    mobile_no,
    email,
    address
)
VALUES (
    'ruby98',
    '$2a$10$exampleHashValue',
    '성루비',
    '1998-01-01',
    '010-1234-5678',
    'ruby@example.com',
    '서울특별시'
);


-- 1-2. 로그인용 고객 조회
-- 비밀번호 해시는 조회 후 애플리케이션에서 BCrypt로 검증
--
-- [파라미터]
-- loginId : 로그인 화면에서 사용자가 입력한 로그인 ID
--
-- [Workbench 테스트값]
-- loginId = 'ruby98'
SELECT
    customer_id,
    login_id,
    password_hash,
    customer_name,
    customer_status
FROM CUSTOMER
WHERE login_id = 'ruby98';


-- 1-3. 내 정보 조회
-- [파라미터]
-- customerId : 로그인 인증 후 서버가 식별한 고객 ID
--              실제 구현에서는 SecurityContext/JWT 등에서 가져옴
--
-- [Workbench 테스트값]
-- customerId = 1
SELECT
    login_id,
    customer_name,
    birth_date,
    mobile_no,
    email,
    address
FROM CUSTOMER
WHERE customer_id = 1;


-- ============================================================
-- 2. 계좌
-- ============================================================

-- 계좌 개설 기능은 현재 프로젝트 범위에서 제외
-- 계좌는 이미 개설되어 있다고 가정


-- 2-1. 내 활성 계좌 목록 조회
-- [파라미터]
-- customerId : 로그인 인증 후 서버가 식별한 고객 ID
--
-- [Workbench 테스트값]
-- customerId = 1
SELECT
    account_id,
    account_no,
    account_type,
    deposit_balance
FROM ACCOUNT
WHERE customer_id = 1
  AND account_status = 'ACTIVE'
ORDER BY opened_at DESC;


-- ============================================================
-- 3. 종목
-- ============================================================

-- 3-1. 거래 가능한 종목 전체 조회
-- [파라미터]
-- 없음
--
-- ACTIVE 종목만 주문 가능한 종목 목록에 표시
SELECT
    stock_id,
    stock_code,
    stock_name,
    stock_status
FROM STOCK_ITEM
WHERE stock_status = 'ACTIVE'
ORDER BY stock_name;


-- 3-2. 종목명 / 종목코드 검색
-- [파라미터]
-- keyword : 사용자가 종목 검색창에 입력한 검색어
--
-- 실제 구현 시:
-- 종목명   → keyword를 포함하는 종목 검색
-- 종목코드 → keyword로 시작하는 종목 검색
--
-- [Workbench 테스트값]
-- keyword = '삼성'
SELECT
    stock_id,
    stock_code,
    stock_name,
    stock_status
FROM STOCK_ITEM
WHERE stock_status = 'ACTIVE'
  AND (
        stock_name LIKE '%삼성%'
        OR stock_code LIKE '삼성%'
      )
ORDER BY stock_name;


-- 3-3. 종목 상세 조회
-- [파라미터]
-- stockId : 사용자가 선택한 종목의 ID
--
-- [Workbench 테스트값]
-- stockId = 1
SELECT
    stock_id,
    stock_code,
    stock_name,
    stock_status
FROM STOCK_ITEM
WHERE stock_id = 1;


-- ============================================================
-- 4. 보유종목 / 잔고
-- ============================================================

-- 4-1. 계좌의 전체 보유종목 조회
-- [파라미터]
-- accountId : 사용자가 선택한 계좌 ID
--
-- [Workbench 테스트값]
-- accountId = 1
--
-- 현재 설계에서는 holding_quantity가 0이 되면
-- HOLDING_BALANCE 행을 삭제하는 방향
SELECT
    h.stock_id,
    s.stock_code,
    s.stock_name,
    h.holding_quantity,
    h.average_purchase_price
FROM HOLDING_BALANCE h
JOIN STOCK_ITEM s
    ON h.stock_id = s.stock_id
WHERE h.account_id = 1
ORDER BY s.stock_name;


-- 4-2. 특정 종목 보유잔고 조회
-- [파라미터]
-- accountId : 사용자가 선택한 계좌 ID
-- stockId   : 조회할 종목 ID
--
-- [Workbench 테스트값]
-- accountId = 1
-- stockId   = 1
SELECT
    h.account_id,
    h.stock_id,
    s.stock_code,
    s.stock_name,
    h.holding_quantity,
    h.average_purchase_price
FROM HOLDING_BALANCE h
JOIN STOCK_ITEM s
    ON h.stock_id = s.stock_id
WHERE h.account_id = 1
  AND h.stock_id = 1;


-- ============================================================
-- 5. 주문 가능 여부
-- ============================================================

-- 5-1. 계좌 예수금 조회
-- [파라미터]
-- accountId : 주문에 사용할 계좌 ID
--
-- [Workbench 테스트값]
-- accountId = 1
SELECT
    deposit_balance
FROM ACCOUNT
WHERE account_id = 1
  AND account_status = 'ACTIVE';


-- 5-2. 지정가 매수 주문 가능금액 계산
-- 예수금 - 현재 미체결 지정가 매수 주문에 묶여 있는 금액
--
-- [파라미터]
-- accountId : 주문 가능금액을 계산할 계좌 ID
--
-- [Workbench 테스트값]
-- accountId = 1
SELECT
    a.deposit_balance
    -
    COALESCE(
        SUM(
            o.order_price *
            (
                o.order_quantity
                - COALESCE(e.executed_quantity, 0)
            )
        ),
        0
    ) AS available_amount
FROM ACCOUNT a
LEFT JOIN STOCK_ORDER o
    ON a.account_id = o.account_id
    AND o.buy_sell_type = 'BUY'
    AND o.order_type = 'LIMIT'
    AND o.order_status IN ('RECEIVED', 'PARTIAL_FILLED')
LEFT JOIN (
    SELECT
        order_id,
        SUM(execution_quantity) AS executed_quantity
    FROM TRADE_EXECUTION
    GROUP BY order_id
) e
    ON o.order_id = e.order_id
WHERE a.account_id = 1
GROUP BY
    a.account_id,
    a.deposit_balance;


-- 5-3. 특정 종목 매도 가능수량 계산
-- 현재 보유수량 - 이미 매도 주문 중인 미체결수량
--
-- [파라미터]
-- accountId : 주문에 사용할 계좌 ID
-- stockId   : 매도하려는 종목 ID
--
-- [Workbench 테스트값]
-- accountId = 1
-- stockId   = 1
SELECT
    h.holding_quantity
    -
    COALESCE(
        SUM(
            o.order_quantity
            - COALESCE(e.executed_quantity, 0)
        ),
        0
    ) AS available_quantity
FROM HOLDING_BALANCE h
LEFT JOIN STOCK_ORDER o
    ON h.account_id = o.account_id
    AND h.stock_id = o.stock_id
    AND o.buy_sell_type = 'SELL'
    AND o.order_status IN ('RECEIVED', 'PARTIAL_FILLED')
LEFT JOIN (
    SELECT
        order_id,
        SUM(execution_quantity) AS executed_quantity
    FROM TRADE_EXECUTION
    GROUP BY order_id
) e
    ON o.order_id = e.order_id
WHERE h.account_id = 1
  AND h.stock_id = 1
GROUP BY
    h.account_id,
    h.stock_id,
    h.holding_quantity;


-- ============================================================
-- 6. 주문 등록
-- ============================================================

-- 6-1. 지정가 주문 등록
-- [파라미터]
-- accountId     : 주문할 계좌 ID
-- stockId       : 주문할 종목 ID
-- buySellType   : 매매구분 (BUY / SELL)
-- orderPrice    : 사용자가 지정한 주문가격
-- orderQuantity : 사용자가 입력한 주문수량
--
-- [Workbench 테스트값]
-- accountId     = 1
-- stockId       = 1
-- buySellType   = 'BUY'
-- orderPrice    = 70000
-- orderQuantity = 10
INSERT INTO STOCK_ORDER (
    account_id,
    stock_id,
    buy_sell_type,
    order_type,
    order_price,
    order_quantity,
    order_status
)
VALUES (
    1,
    1,
    'BUY',
    'LIMIT',
    70000,
    10,
    'RECEIVED'
);


-- 6-2. 시장가 주문 등록
-- 시장가는 주문가격을 지정하지 않으므로 order_price = NULL
--
-- [파라미터]
-- accountId     : 주문할 계좌 ID
-- stockId       : 주문할 종목 ID
-- buySellType   : 매매구분 (BUY / SELL)
-- orderQuantity : 사용자가 입력한 주문수량
--
-- [Workbench 테스트값]
-- accountId     = 1
-- stockId       = 1
-- buySellType   = 'BUY'
-- orderQuantity = 10
INSERT INTO STOCK_ORDER (
    account_id,
    stock_id,
    buy_sell_type,
    order_type,
    order_price,
    order_quantity,
    order_status
)
VALUES (
    1,
    1,
    'BUY',
    'MARKET',
    NULL,
    10,
    'RECEIVED'
);


-- ============================================================
-- 7. 주문 조회
-- ============================================================

-- 7-1. 계좌별 전체 주문내역
-- 주문수량 / 누적체결수량 / 미체결수량까지 계산
--
-- [파라미터]
-- accountId : 조회할 계좌 ID
--
-- [Workbench 테스트값]
-- accountId = 1
SELECT
    o.order_id,
    o.account_id,
    s.stock_code,
    s.stock_name,
    o.buy_sell_type,
    o.order_type,
    o.order_price,
    o.order_quantity,

    COALESCE(
        SUM(e.execution_quantity),
        0
    ) AS executed_quantity,

    o.order_quantity
    -
    COALESCE(
        SUM(e.execution_quantity),
        0
    ) AS remaining_quantity,

    o.order_status,
    o.ordered_at,
    o.cancelled_at

FROM STOCK_ORDER o

JOIN STOCK_ITEM s
    ON o.stock_id = s.stock_id

LEFT JOIN TRADE_EXECUTION e
    ON o.order_id = e.order_id

WHERE o.account_id = 1

GROUP BY
    o.order_id,
    o.account_id,
    s.stock_code,
    s.stock_name,
    o.buy_sell_type,
    o.order_type,
    o.order_price,
    o.order_quantity,
    o.order_status,
    o.ordered_at,
    o.cancelled_at

ORDER BY o.ordered_at DESC;


-- 7-2. 특정 주문 상세 조회
-- [파라미터]
-- orderId   : 조회할 주문 ID
-- accountId : 해당 주문이 로그인 사용자의 계좌 주문인지 확인하기 위한 계좌 ID
--
-- [Workbench 테스트값]
-- orderId   = 1
-- accountId = 1
SELECT
    o.order_id,
    o.account_id,
    o.stock_id,
    s.stock_code,
    s.stock_name,
    o.buy_sell_type,
    o.order_type,
    o.order_price,
    o.order_quantity,

    COALESCE(
        SUM(e.execution_quantity),
        0
    ) AS executed_quantity,

    o.order_quantity
    -
    COALESCE(
        SUM(e.execution_quantity),
        0
    ) AS remaining_quantity,

    o.order_status,
    o.ordered_at,
    o.updated_at,
    o.cancelled_at

FROM STOCK_ORDER o

JOIN STOCK_ITEM s
    ON o.stock_id = s.stock_id

LEFT JOIN TRADE_EXECUTION e
    ON o.order_id = e.order_id

WHERE o.order_id = 1
  AND o.account_id = 1

GROUP BY
    o.order_id;


-- ============================================================
-- 8. 체결
-- ============================================================

-- 8-1. 체결 등록
-- [파라미터]
-- orderId          : 체결된 주문 ID
-- executionPrice   : 실제 체결가격
-- executionQuantity: 실제 체결수량
--
-- [Workbench 테스트값]
-- orderId           = 1
-- executionPrice    = 69900
-- executionQuantity = 3
INSERT INTO TRADE_EXECUTION (
    order_id,
    execution_price,
    execution_quantity,
    executed_at
)
VALUES (
    1,
    69900,
    3,
    CURRENT_TIMESTAMP
);


-- 8-2. 특정 주문의 체결 상세내역
-- [파라미터]
-- orderId : 조회할 주문 ID
--
-- [Workbench 테스트값]
-- orderId = 1
SELECT
    execution_id,
    order_id,
    execution_price,
    execution_quantity,
    executed_at
FROM TRADE_EXECUTION
WHERE order_id = 1
ORDER BY executed_at ASC;


-- 8-3. 특정 주문의 누적 체결수량
-- [파라미터]
-- orderId : 조회할 주문 ID
--
-- [Workbench 테스트값]
-- orderId = 1
SELECT
    COALESCE(
        SUM(execution_quantity),
        0
    ) AS executed_quantity
FROM TRADE_EXECUTION
WHERE order_id = 1;


-- 8-4. 특정 주문의 평균 체결가격
-- 단순 AVG(execution_price)가 아니라 체결수량을 반영한 가중평균
--
-- [파라미터]
-- orderId : 조회할 주문 ID
--
-- [Workbench 테스트값]
-- orderId = 1
SELECT
    CASE
        WHEN SUM(execution_quantity) > 0
        THEN
            SUM(execution_price * execution_quantity)
            / SUM(execution_quantity)
        ELSE NULL
    END AS average_execution_price
FROM TRADE_EXECUTION
WHERE order_id = 1;


-- ============================================================
-- 9. 주문 상태 변경
-- ============================================================

-- 9-1. 부분체결 상태로 변경
-- [파라미터]
-- orderId : 부분체결된 주문 ID
--
-- [Workbench 테스트값]
-- orderId = 1
UPDATE STOCK_ORDER
SET order_status = 'PARTIAL_FILLED'
WHERE order_id = 1;


-- 9-2. 전체체결 상태로 변경
-- [파라미터]
-- orderId : 전체체결된 주문 ID
--
-- [Workbench 테스트값]
-- orderId = 1
UPDATE STOCK_ORDER
SET order_status = 'FILLED'
WHERE order_id = 1;


-- 9-3. 주문 취소
-- 접수 또는 부분체결 상태에서만 취소 가능
--
-- [파라미터]
-- orderId   : 취소할 주문 ID
-- accountId : 해당 주문이 사용자의 계좌 주문인지 확인하기 위한 계좌 ID
--
-- [Workbench 테스트값]
-- orderId   = 1
-- accountId = 1
UPDATE STOCK_ORDER
SET
    order_status = 'CANCELLED',
    cancelled_at = CURRENT_TIMESTAMP
WHERE order_id = 1
  AND account_id = 1
  AND order_status IN ('RECEIVED', 'PARTIAL_FILLED');


-- 9-4. 주문 거부
-- [파라미터]
-- orderId : 거부 처리할 주문 ID
--
-- [Workbench 테스트값]
-- orderId = 1
UPDATE STOCK_ORDER
SET order_status = 'REJECTED'
WHERE order_id = 1
  AND order_status = 'RECEIVED';


-- ============================================================
-- 10. 체결 후 계좌 예수금 반영
-- ============================================================

-- 10-1. 매수 체결
-- 체결가격 × 체결수량만큼 예수금 감소
--
-- [파라미터]
-- accountId         : 체결된 주문의 계좌 ID
-- executionPrice    : 실제 체결가격
-- executionQuantity : 실제 체결수량
--
-- [Workbench 테스트값]
-- accountId         = 1
-- executionPrice    = 69900
-- executionQuantity = 3
UPDATE ACCOUNT
SET deposit_balance =
    deposit_balance - (69900 * 3)
WHERE account_id = 1;


-- 10-2. 매도 체결
-- 체결가격 × 체결수량만큼 예수금 증가
--
-- [파라미터]
-- accountId         : 체결된 주문의 계좌 ID
-- executionPrice    : 실제 체결가격
-- executionQuantity : 실제 체결수량
--
-- [Workbench 테스트값]
-- accountId         = 1
-- executionPrice    = 69900
-- executionQuantity = 3
UPDATE ACCOUNT
SET deposit_balance =
    deposit_balance + (69900 * 3)
WHERE account_id = 1;


-- ============================================================
-- 11. 체결 후 보유잔고 반영
-- ============================================================

-- 11-1. 매수 체결 후 보유잔고 반영
--
-- 기존 보유분이 있다면:
-- 새로운 평균매입단가
-- = (기존평단 × 기존수량 + 체결가격 × 체결수량)
--   / (기존수량 + 체결수량)
--
-- 기존 보유분이 없다면 INSERT
--
-- [파라미터]
-- accountId         : 매수 체결된 계좌 ID
-- stockId           : 매수 체결된 종목 ID
-- executionPrice    : 실제 체결가격
-- executionQuantity : 실제 체결수량
--
-- [Workbench 테스트값]
-- accountId         = 1
-- stockId           = 1
-- executionPrice    = 69900
-- executionQuantity = 3
INSERT INTO HOLDING_BALANCE (
    account_id,
    stock_id,
    holding_quantity,
    average_purchase_price
)
VALUES (
    1,
    1,
    3,
    69900
)
ON DUPLICATE KEY UPDATE
    average_purchase_price =
        (
            average_purchase_price * holding_quantity
            + 69900 * 3
        )
        /
        (
            holding_quantity + 3
        ),

    holding_quantity =
        holding_quantity + 3;


-- 11-2. 매도 체결 후 보유수량 감소
-- 매도 시 기존 평균매입단가는 그대로 유지
--
-- [파라미터]
-- accountId         : 매도 체결된 계좌 ID
-- stockId           : 매도 체결된 종목 ID
-- executionQuantity : 실제 체결수량
--
-- [Workbench 테스트값]
-- accountId         = 1
-- stockId           = 1
-- executionQuantity = 3
UPDATE HOLDING_BALANCE
SET holding_quantity =
    holding_quantity - 3
WHERE account_id = 1
  AND stock_id = 1;


-- 11-3. 전량 매도된 보유종목 삭제
-- 보유수량이 0이 된 경우 현재 보유잔고에서 제거
--
-- [파라미터]
-- accountId : 매도 체결된 계좌 ID
-- stockId   : 매도 체결된 종목 ID
--
-- [Workbench 테스트값]
-- accountId = 1
-- stockId   = 1
DELETE FROM HOLDING_BALANCE
WHERE account_id = 1
  AND stock_id = 1
  AND holding_quantity = 0;


-- ============================================================
-- 12. 체결내역 조회
-- ============================================================

-- 12-1. 계좌 전체 체결내역
-- [파라미터]
-- accountId : 체결내역을 조회할 계좌 ID
--
-- [Workbench 테스트값]
-- accountId = 1
SELECT
    e.execution_id,
    o.order_id,
    s.stock_code,
    s.stock_name,
    o.buy_sell_type,
    o.order_type,
    e.execution_price,
    e.execution_quantity,
    e.executed_at
FROM TRADE_EXECUTION e
JOIN STOCK_ORDER o
    ON e.order_id = o.order_id
JOIN STOCK_ITEM s
    ON o.stock_id = s.stock_id
WHERE o.account_id = 1
ORDER BY e.executed_at DESC;


-- ============================================================
-- 13. 주문 + 체결 종합 조회
-- ============================================================

-- 13-1. 주문별 주문/체결 종합 조회
-- 주문수량 / 체결수량 / 미체결수량 / 평균체결가를 함께 조회
--
-- [파라미터]
-- accountId : 주문내역을 조회할 계좌 ID
--
-- [Workbench 테스트값]
-- accountId = 1
SELECT
    o.order_id,
    s.stock_code,
    s.stock_name,
    o.buy_sell_type,
    o.order_type,
    o.order_price,
    o.order_quantity,

    COALESCE(
        SUM(e.execution_quantity),
        0
    ) AS executed_quantity,

    o.order_quantity
    -
    COALESCE(
        SUM(e.execution_quantity),
        0
    ) AS remaining_quantity,

    CASE
        WHEN SUM(e.execution_quantity) > 0
        THEN
            SUM(e.execution_price * e.execution_quantity)
            / SUM(e.execution_quantity)
        ELSE NULL
    END AS average_execution_price,

    o.order_status,
    o.ordered_at

FROM STOCK_ORDER o

JOIN STOCK_ITEM s
    ON o.stock_id = s.stock_id

LEFT JOIN TRADE_EXECUTION e
    ON o.order_id = e.order_id

WHERE o.account_id = 1

GROUP BY
    o.order_id,
    s.stock_code,
    s.stock_name,
    o.buy_sell_type,
    o.order_type,
    o.order_price,
    o.order_quantity,
    o.order_status,
    o.ordered_at

ORDER BY o.ordered_at DESC;
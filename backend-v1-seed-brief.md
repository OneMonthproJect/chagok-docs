# chagok-backend 작업 지시서 (V1 담당 정비사 반영 + 시연 시드)

> `C:\OneMonthProj\chagok-backend` 폴더에서 Claude Code 세션을 열고 아래를 그대로 붙여 넣는다.
> 원본 명세: `../chagok-docs/docs/07_data_ERD_DB설계서.md`(5.1, 6.1, 6.3, 7장). 이 명세는 `chagok-docs`의 PR 브랜치 `docs/#22-roles-required-fields` → `docs/#20-reservation-decisions` → `docs/#21-records-retention` → `docs/#23-assign-owners`에 나뉘어 있고, **`docs/#23-assign-owners`(또는 `docs/#21-records-retention`) 체크아웃에 전체 내용이 들어 있다.** 세션이 `../chagok-docs`를 읽을 때 그 브랜치가 체크아웃된 상태여야 한다(현재 `docs/#23-assign-owners`).
> 문서 PR이 develop에 머지되기 전에 시작해도 된다. 다만 V1 PR의 「문서 PR」 칸에는 위 문서 PR 링크가 들어가야 하고, 문서 PR이 먼저 머지되어야 한다(CONTRIBUTING 7장).

---

먼저 이 레포의 `CLAUDE.md`와 `.claude/rules/ai-rules.md`를 읽고 그 절차(분석 → 계획 → 구현 → 검증 → 보고)를 따른다. 아래 변경은 07이 이미 확정한 것이라 계획 보고는 짧게 해도 된다. push는 하지 않고, 커밋은 로컬에만 한다. 커밋 메시지에 AI 공동 작성자 표기(`Co-authored-by: Claude`, `noreply@anthropic.com` 등)를 넣지 않는다(CONTRIBUTING 4장). `main`·`develop`에는 커밋하지 않는다. 다른 레포(`chagok-docs`, `chagok-frontend`) 파일은 고치지 않는다.

## 1. V1 마이그레이션 수정 (브랜치 `feature/#4-flyway-v1-init`)

`git fetch` 후 `origin/feature/#4-flyway-v1-init` 기준으로 로컬 브랜치를 만든다. V1은 develop에 아직 머지되지 않았으므로 직접 고칠 수 있다(머지 뒤에는 이미 있는 마이그레이션을 고치지 않는다).

`src/main/resources/db/migration/V1__init.sql`:

1. `staff`: `CONSTRAINT uk_staff_shop_id_id UNIQUE (shop_id, id)` 추가.
2. `reservation`: `assignee_staff_id BIGINT NOT NULL` 추가, `CONSTRAINT fk_reservation_assignee FOREIGN KEY (shop_id, assignee_staff_id) REFERENCES staff (shop_id, id)`, 인덱스 `(shop_id, assignee_staff_id, reserved_at)`. 식별자가 64자를 넘으면 단축하고 머리 주석에 기록한다(`idx_maintenance_record_shop_vehicle_item_date`와 같은 방식). `created_by_staff_id` 단일 FK는 그대로 둔다.
3. `maintenance_record`: 단일 FK `fk_maintenance_record_staff (staff_id) → staff(id)`를 복합 FK `(shop_id, staff_id) → staff(shop_id, id)`로 교체하고, `idx_maintenance_record_staff_id`를 `shop_id`로 시작하는 `(shop_id, staff_id)` 인덱스로 교체한다.
4. 머리 주석 갱신: 복합 FK 6 → 8개, UNIQUE(shop_id, id) 부모 4 → 5개(staff 추가), 단일 FK 10 → 9개(`shop_id` 7, `created_by_staff_id` 1, `platform_admin` 1). 옛 이름 "관문 1 결정 C"는 "M1 결정 C"로 고친다.
5. 넣지 않는 것: `IN_PROGRESS`·`updated_at`·`version`·revision 표(V2), `customer.status`·`anonymized_at`·`vehicle.active`·`staff.active`·`contact_log`(V3). `vehicle.model`은 NULL 허용으로 둔다(차종 필수는 서버 검증). V1에 P0-나머지·P1 칼럼·값을 넣지 않는다.

`src/test/java/com/wanted/chagok/migration/V1InitMigrationTest.java` (07 6.3 V1 검증 기준):

- V1-2: 복합 FK 8개 + 단일 FK 9개, UNIQUE 부모 5개(`fk_reservation_assignee`와 복합화된 `fk_maintenance_record_staff` 추가).
- V1-3~V1-5 쪽에 추가: A 정비소 `reservation`의 `assignee_staff_id`에 B 정비소 정비사를 넣으면 1452, A 정비소 `maintenance_record`의 `staff_id`에 B 정비소 정비사를 넣으면 1452.
- V1-12: `reservation` 칼럼에 `assignee_staff_id`가 있어야 하고, V1에 없어야 할 목록(`inspect_result`, `NO_SHOW`, `IN_PROGRESS`, `customer.version`, `vehicle.version`, `maintenance_record.updated_at`·`version`, revision 표 2개, `customer.status`, `vehicle.active`, `staff.active`, `contact_log`)이 없음을 확인한다.
- 테스트의 INSERT 보조 SQL에 `assignee_staff_id`를 추가하고, 기존 양성 대조 INSERT를 보정한다.

검증: DB 없이 가능한 것(컴파일, `ArchitectureTest` 등 `./gradlew build`)은 실제로 돌려 결과를 적는다. MySQL이 필요한 dbTest는 환경이 없으면 "미검증"으로 보고한다(통과로 세지 않는다). 변경 전후 SQL 차이를 보고에 포함한다.

## 2. 시연 시드 (`db/seed/demo_seed.sql`, V1 반영 뒤)

현재 비어 있다. `.claude/skills/chagok-seed-data/SKILL.md`(또는 `chagok-seed-builder` 에이전트)와 `db/seed/README.md` 규칙대로 `../chagok-docs/docs/07_data_ERD_DB설계서.md` 7장(7.1~7.5)을 그대로 만든다.

- 계정 이름: `owner_a` 박사장, `mech_a` 김정비, `owner_b` 최사장, `admin` 운영관리자 (비밀번호 `1234`의 BCrypt 해시, `password_change_required = false`).
- 차량 11대의 차종·연식·주행거리는 7.2 표 그대로(90마0005는 주행거리 비움, 66카0011은 연식·주행거리 비움).
- 예약 담당: 78라0004 `mech_a`, 22사0007 `owner_a`, 34나0002 `mech_a`, 55차0010 `owner_a`.
- 날짜는 `CURDATE()` 기준 상대값, `created_at`·`updated_at`은 직접 입력(DB 기본값 없음), `DELETE`·`TRUNCATE`·`DROP`·`ALTER`·`CREATE`·`UPDATE` 금지.
- 기대값(7.5)을 보고에 포함: 홈 오늘 예약 2건, 오늘 연락할 고객 5명, 재점검 대상 6대, A 정비소 고객 10명·차량 11대. MySQL이 없어 실행하지 못하면 "실행 미확인"으로 적는다.
- 07과 맞지 않아 만들 수 없는 것이 있으면 지어내지 말고 ❓로 보고한다.

## 끝났을 때 보고할 것

변경 파일, 실제 실행한 명령과 결과(성공·실패·미실행 구분), 로컬 커밋 해시, push하지 않았다는 점, 07과 어긋난 곳(❓), AI 사용 기록 한 줄 초안(`| 날짜 | chagok-backend#4 | 스킬·에이전트 | 한 일 | 사람이 바꾼 것 |`).

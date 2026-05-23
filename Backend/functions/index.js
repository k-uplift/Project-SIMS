/**
 * 냉장고를 부탁해 - Cloud Functions
 *
 * 1) notifyExpiringIngredients: 매일 KST 09:00에 모든 냉장고를 순회하며
 *    유통기한 D-3 이내 식재료가 있는 멤버들에게 FCM 알림 발송.
 * 2) testNotifyMe: 본인에게 즉시 테스트 알림을 보내는 HTTPS 함수 (개발용).
 */

const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onRequest} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, Timestamp} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const logger = require("firebase-functions/logger");

initializeApp();

// D-3 이내를 "임박"으로 간주
const EXPIRING_WITHIN_DAYS = 3;

// 공통 옵션
const REGION = "asia-northeast3"; // 서울

/**
 * KST 기준 오늘 자정 (시각 비교 단순화).
 * JS Date는 UTC 기반이지만 비교에만 쓰면 충분.
 */
function todayKstMidnight() {
  const now = new Date();
  // KST = UTC+9
  const kstOffsetMs = 9 * 60 * 60 * 1000;
  const kstNow = new Date(now.getTime() + kstOffsetMs);
  // KST 기준 자정으로 (UTC로 다시 변환)
  const kstMidnight = new Date(Date.UTC(
      kstNow.getUTCFullYear(),
      kstNow.getUTCMonth(),
      kstNow.getUTCDate(),
      0, 0, 0,
  ));
  return new Date(kstMidnight.getTime() - kstOffsetMs);
}

async function fetchTokensForUser(db, uid) {
  const snap = await db
      .collection("fcmTokens")
      .doc(uid)
      .collection("devices")
      .get();
  const tokens = [];
  snap.forEach((doc) => {
    const token = doc.data()?.token;
    if (token) tokens.push(token);
  });
  return tokens;
}

async function expiringIngredientsInFridge(db, fridgeId) {
  const today = todayKstMidnight();
  const cutoff = new Date(
      today.getTime() + EXPIRING_WITHIN_DAYS * 24 * 60 * 60 * 1000,
  );

  const snap = await db
      .collection("fridges")
      .doc(fridgeId)
      .collection("ingredients")
      .where("expireDate", "<=", Timestamp.fromDate(cutoff))
      .get();

  const items = [];
  snap.forEach((doc) => {
    const data = doc.data() || {};
    const name = data.name || "식재료";
    const expire = data.expireDate;
    if (!expire) return;
    const expireDate = expire.toDate();
    const expireMidnight = new Date(Date.UTC(
        expireDate.getUTCFullYear(),
        expireDate.getUTCMonth(),
        expireDate.getUTCDate(),
    ));
    const todayUtc = new Date(Date.UTC(
        today.getUTCFullYear(),
        today.getUTCMonth(),
        today.getUTCDate(),
    ));
    const dday = Math.round(
        (expireMidnight - todayUtc) / (24 * 60 * 60 * 1000),
    );
    if (dday < 0) return; // 이미 지난 건 제외
    items.push({name, dday});
  });

  items.sort((a, b) => a.dday - b.dday);
  return items;
}

async function sendToTokens(tokens, title, body) {
  if (!tokens || tokens.length === 0) return 0;

  let success = 0;
  const chunkSize = 100; // FCM은 multicast 한 번에 최대 500개. 안전하게 100.

  for (let i = 0; i < tokens.length; i += chunkSize) {
    const chunk = tokens.slice(i, i + chunkSize);
    const message = {
      notification: {title, body},
      data: {type: "expiring"},
      tokens: chunk,
      android: {
        priority: "high",
        notification: {
          channelId: "fridge_expiring_channel",
        },
      },
    };
    try {
      const response = await getMessaging().sendEachForMulticast(message);
      success += response.successCount;
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            logger.warn(
                `[FCM] 발송 실패 token=${chunk[idx].substring(0, 16)}...`,
                resp.error,
            );
          }
        });
      }
    } catch (e) {
      logger.error("[FCM] multicast 전체 실패", e);
    }
  }
  return success;
}

function buildNotificationBody(items, fridgeName) {
  const title = `[${fridgeName}] 유통기한 임박`;
  const head = items.slice(0, 3);
  const rest = items.length - 3;
  const lines = head.map((it) => {
    const ddayStr = it.dday === 0 ? "오늘 만료" : `D-${it.dday}`;
    return `${it.name} (${ddayStr})`;
  });
  let body = lines.join(", ");
  if (rest > 0) body += ` 외 ${rest}개`;
  return {title, body};
}

// ─────────────────────────────────────────────────────────
// 1) 스케줄러: 매일 KST 09:00
// ─────────────────────────────────────────────────────────
exports.notifyExpiringIngredients = onSchedule(
    {
      schedule: "0 9 * * *",
      timeZone: "Asia/Seoul",
      region: REGION,
      memory: "256MiB",
    },
    async () => {
      const db = getFirestore();
      const fridgesSnap = await db.collection("fridges").get();

      let totalFridges = 0;
      let totalSent = 0;

      for (const fridgeDoc of fridgesSnap.docs) {
        totalFridges += 1;
        const fridge = fridgeDoc.data() || {};
        const fridgeId = fridgeDoc.id;
        const fridgeName = fridge.name || "내 냉장고";
        const members = fridge.memberUids || [];
        if (members.length === 0) continue;

        const items = await expiringIngredientsInFridge(db, fridgeId);
        if (items.length === 0) continue;

        const {title, body} = buildNotificationBody(items, fridgeName);

        const allTokens = [];
        for (const uid of members) {
          const tokens = await fetchTokensForUser(db, uid);
          allTokens.push(...tokens);
        }
        if (allTokens.length === 0) continue;

        const sent = await sendToTokens(allTokens, title, body);
        totalSent += sent;
        logger.info(
            `[notify] fridge=${fridgeId} name=${fridgeName} ` +
            `items=${items.length} tokens=${allTokens.length} sent=${sent}`,
        );
      }

      logger.info(
          `[notify] 완료. 냉장고 ${totalFridges}개, 발송 ${totalSent}건`,
      );
    },
);

// ─────────────────────────────────────────────────────────
// 2) HTTPS: 본인에게 즉시 테스트 알림
//    https://<region>-<project>.cloudfunctions.net/testNotifyMe?uid=<uid>
// ─────────────────────────────────────────────────────────
exports.testNotifyMe = onRequest(
    {region: REGION,
      invoker: "public",
    },
    async (req, res) => {
      const uid = req.query.uid;
      if (!uid) {
        res.status(400).send("uid 쿼리 파라미터가 필요합니다");
        return;
      }

      const db = getFirestore();
      const tokens = await fetchTokensForUser(db, uid);
      if (tokens.length === 0) {
        res.status(404).send(`uid=${uid}에 등록된 FCM 토큰이 없습니다`);
        return;
      }

      const sent = await sendToTokens(
          tokens,
          "테스트 알림",
          "Cloud Functions에서 보낸 테스트 메시지입니다.",
      );
      res.status(200).send(`tokens=${tokens.length}, sent=${sent}`);
    },
);
import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { verifyAppleJws, checkEntitlement, checkAppPurchase, isEarlyAdopterVersion, VerifyError } from '../src/apple.js';
import { opensslAvailable, makeChain, makeJws, goodPayload } from './chain.js';

const skip = opensslAvailable() ? false : 'openssl не найден';
let good;
let devCert;
let other;

before(() => {
  if (skip) return;
  good = makeChain('good-');
  devCert = makeChain('dev-', { leafOid: false });
  other = makeChain('other-');
});

async function rejects(promise, code) {
  await assert.rejects(promise, (error) => error instanceof VerifyError && error.code === code, `ожидалась ошибка ${code}`);
}

test('настоящая цепочка и подпись проходят, данные возвращаются', { skip }, async () => {
  const payload = goodPayload();
  const result = await verifyAppleJws(makeJws(good, payload), { rootSha256: good.rootSha });
  assert.equal(result.originalTransactionId, payload.originalTransactionId);
  assert.equal(result.productId, payload.productId);
});

test('чужой корень не принимается (отпечаток закреплён)', { skip }, async () => {
  await rejects(verifyAppleJws(makeJws(good, goodPayload()), { rootSha256: other.rootSha }), 'bad_root');
});

test('сертификат без расширения Apple (как у обычного разработчика) отвергается', { skip }, async () => {
  await rejects(verifyAppleJws(makeJws(devCert, goodPayload()), { rootSha256: devCert.rootSha }), 'bad_leaf');
});

test('промежуточный и корень из разных цепочек не сходятся', { skip }, async () => {
  const jws = makeJws(good, goodPayload(), { x5c: [good.leaf, good.int, other.root] });
  await rejects(verifyAppleJws(jws, { rootSha256: other.rootSha }), 'bad_chain');
});

test('подмена содержимого ломает подпись', { skip }, async () => {
  const genuine = makeJws(good, goodPayload({ expiresDate: 1 }));
  const forged = makeJws(good, goodPayload());
  const [h, , s] = genuine.split('.');
  const swapped = `${h}.${forged.split('.')[1]}.${s}`;
  await rejects(verifyAppleJws(swapped, { rootSha256: good.rootSha }), 'bad_signature');
});

test('мусор вместо JWS', { skip }, async () => {
  await rejects(verifyAppleJws('abc', { rootSha256: good.rootSha }), 'bad_format');
  await rejects(verifyAppleJws(42, { rootSha256: good.rootSha }), 'bad_format');
  await rejects(verifyAppleJws('a.b.c', { rootSha256: good.rootSha }), 'bad_format');
});

const env = {
  BUNDLE_ID: 'com.samvel.armenianbible',
  PRODUCT_IDS: 'com.samvel.armenianbible.subscription.monthly,com.samvel.armenianbible.subscription.yearly',
  LIFETIME_PRODUCT_IDS: 'com.samvel.armenianbible.lifetime',
  ALLOW_SANDBOX: 'true'
};

test('правила доступа: подходящая подписка', () => {
  assert.equal(checkEntitlement(goodPayload(), env), null);
});

test('правила доступа: отказы', () => {
  assert.equal(checkEntitlement(goodPayload({ bundleId: 'x.y' }), env), 'bundle');
  assert.equal(checkEntitlement(goodPayload({ productId: 'other' }), env), 'product');
  assert.equal(checkEntitlement(goodPayload({ revocationDate: Date.now() }), env), 'revoked');
  assert.equal(checkEntitlement(goodPayload({ expiresDate: Date.now() - 1000 }), env), 'expired');
  assert.equal(checkEntitlement(goodPayload({ expiresDate: undefined }), env), 'expired');
  assert.equal(checkEntitlement(goodPayload({ environment: 'Xcode' }), env), 'environment');
  assert.equal(checkEntitlement(goodPayload({ environment: 'Sandbox' }), { ...env, ALLOW_SANDBOX: 'false' }), 'sandbox');
  assert.equal(checkEntitlement(goodPayload({ environment: 'Production' }), { ...env, ALLOW_SANDBOX: 'false' }), null);
  assert.equal(checkEntitlement(goodPayload({ originalTransactionId: '' }), env), 'no_id');
});

// --- Пожизненная покупка и ранние покупатели платной версии

const lifetimePayload = (overrides = {}) =>
  goodPayload({ productId: 'com.samvel.armenianbible.lifetime', type: 'Non-Consumable', expiresDate: undefined, ...overrides });

test('пожизненная покупка: годится без срока, пока её не вернули', () => {
  assert.equal(checkEntitlement(lifetimePayload(), env), null);
  assert.equal(checkEntitlement(lifetimePayload({ environment: 'Production' }), env), null);
  assert.equal(checkEntitlement(lifetimePayload({ revocationDate: Date.now() }), env), 'revoked');
  assert.equal(checkEntitlement(lifetimePayload({ bundleId: 'x.y' }), env), 'bundle');
});

test('пожизненная покупка: чужой тип товара и неизвестный товар не проходят', () => {
  // товар из списка пожизненных, но не «Non-Consumable»: не принимаем
  assert.equal(checkEntitlement(lifetimePayload({ type: 'Auto-Renewable Subscription' }), env), 'product');
  // без списка пожизненных товаров покупка не принимается
  assert.equal(checkEntitlement(lifetimePayload(), { ...env, LIFETIME_PRODUCT_IDS: '' }), 'product');
  // у обычной подписки срок по-прежнему обязателен
  assert.equal(checkEntitlement(goodPayload({ expiresDate: undefined }), env), 'expired');
});

test('ранний покупатель: номер сборки до 100 включительно и версия ниже 2.0', () => {
  // целое число без точки это номер сборки (так отдаёт App Store для iOS), с точкой это версия
  for (const v of ['1', '2', '57', '100', '1.0', '1.9', ' 1.5 ']) assert.equal(isEarlyAdopterVersion(v), true, v);
  for (const v of ['101', '2.0', '4.3.1', '', '   ', 'abc', undefined, null, 57]) assert.equal(isEarlyAdopterVersion(v), false, String(v));
});

const appPurchase = (overrides = {}) => ({
  bundleId: 'com.samvel.armenianbible',
  originalAppVersion: '57',
  environment: 'Production',
  appTransactionId: '704000000000001',
  ...overrides
});

test('покупка приложения: ранний покупатель из App Store проходит', () => {
  assert.equal(checkAppPurchase(appPurchase(), env), null);
  // без appTransactionId номером служит дата первой покупки
  assert.equal(checkAppPurchase(appPurchase({ appTransactionId: undefined, originalPurchaseDate: 1500000000000 }), env), null);
});

test('покупка приложения: отказы', () => {
  assert.equal(checkAppPurchase(appPurchase({ bundleId: 'x.y' }), env), 'bundle');
  // TestFlight и песочница: originalAppVersion там у всех «1.0», поэтому не годятся
  assert.equal(checkAppPurchase(appPurchase({ environment: 'Sandbox' }), env), 'environment');
  assert.equal(checkAppPurchase(appPurchase({ originalAppVersion: '4.3.1' }), env), 'not_early');
  assert.equal(checkAppPurchase(appPurchase({ originalAppVersion: '250' }), env), 'not_early');
  assert.equal(checkAppPurchase(appPurchase({ appTransactionId: undefined }), env), 'no_id');
});

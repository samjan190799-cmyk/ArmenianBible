import { test, before } from 'node:test';
import assert from 'node:assert/strict';
import { verifyAppleJws, checkEntitlement, VerifyError } from '../src/apple.js';
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

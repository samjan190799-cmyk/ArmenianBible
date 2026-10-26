// Проверка подписанного Apple подтверждения покупки (StoreKit 2 JWS).
// Цепочка сертификатов в заголовке x5c должна: заканчиваться корнем Apple Root CA G3 (сверяем отпечаток), иметь верные подписи
// между звеньями и содержать расширения Apple для чеков App Store. Последняя проверка обязательна: промежуточный сертификат
// Apple выдаёт сертификаты и обычным разработчикам, без неё любой разработчик мог бы подписать «покупку» сам.

import { children, readTLV, parseCertificate, hashForSignatureOid, ecdsaDerToRaw } from './der.js';

/** SHA-256 корневого сертификата Apple Root CA - G3 (https://www.apple.com/certificateauthority/AppleRootCA-G3.cer) */
export const APPLE_ROOT_G3_SHA256 = '63343abfb89a6a03ebb57e9b3f5fa7be7c4f5c756f3017b3a8c488c3653e9179';

// Расширения в DER: 1.2.840.113635.100.6.11.1 (лист, подпись чеков Mac App Store) и 1.2.840.113635.100.6.2.1 (промежуточный WWDR)
const OID_RECEIPT_LEAF = Uint8Array.from([0x06, 0x0a, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x63, 0x64, 0x06, 0x0b, 0x01]);
const OID_WWDR_INTERMEDIATE = Uint8Array.from([0x06, 0x0a, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x63, 0x64, 0x06, 0x02, 0x01]);

export class VerifyError extends Error {
  constructor(code) {
    super(code);
    this.code = code;
  }
}

function b64ToBytes(b64) {
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

function b64urlToBytes(s) {
  return b64ToBytes(s.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(s.length / 4) * 4, '='));
}

const decoder = new TextDecoder();
const encoder = new TextEncoder();

function containsBytes(hay, needle) {
  outer: for (let i = 0; i + needle.length <= hay.length; i++) {
    for (let j = 0; j < needle.length; j++) if (hay[i + j] !== needle[j]) continue outer;
    return true;
  }
  return false;
}

async function sha256Hex(bytes) {
  const digest = new Uint8Array(await crypto.subtle.digest('SHA-256', bytes));
  return Array.from(digest, (b) => b.toString(16).padStart(2, '0')).join('');
}

function importCertKey(cert) {
  if (cert.curve === 'unknown') throw new VerifyError('bad_key');
  return crypto.subtle.importKey('spki', cert.spkiBytes, { name: 'ECDSA', namedCurve: cert.curve }, false, ['verify']);
}

async function certSignedBy(cert, issuer) {
  const key = await importCertKey(issuer);
  const size = issuer.curve === 'P-256' ? 32 : 48;
  let hash;
  let raw;
  try {
    hash = hashForSignatureOid(cert.sigAlg);
    raw = ecdsaDerToRaw(cert.signature, size);
  } catch {
    return false;
  }
  return crypto.subtle.verify({ name: 'ECDSA', hash }, key, raw, cert.tbsBytes);
}

/**
 * Проверяет JWS и возвращает его содержимое (данные транзакции).
 * Бросает VerifyError с кодом: bad_format, bad_header, bad_chain, bad_root, bad_leaf, bad_signature, bad_payload.
 */
export async function verifyAppleJws(jws, { rootSha256 = APPLE_ROOT_G3_SHA256 } = {}) {
  if (typeof jws !== 'string') throw new VerifyError('bad_format');
  const parts = jws.split('.');
  if (parts.length !== 3) throw new VerifyError('bad_format');

  let header;
  try {
    header = JSON.parse(decoder.decode(b64urlToBytes(parts[0])));
  } catch {
    throw new VerifyError('bad_format');
  }
  if (header.alg !== 'ES256' || !Array.isArray(header.x5c) || header.x5c.length !== 3) throw new VerifyError('bad_header');

  let ders;
  let certs;
  try {
    ders = header.x5c.map(b64ToBytes);
    certs = ders.map(parseCertificate);
  } catch {
    throw new VerifyError('bad_chain');
  }

  if ((await sha256Hex(ders[2])) !== rootSha256.toLowerCase()) throw new VerifyError('bad_root');
  if (!(await certSignedBy(certs[0], certs[1]))) throw new VerifyError('bad_chain');
  if (!(await certSignedBy(certs[1], certs[2]))) throw new VerifyError('bad_chain');
  if (!containsBytes(ders[0], OID_RECEIPT_LEAF) || !containsBytes(ders[1], OID_WWDR_INTERMEDIATE)) throw new VerifyError('bad_leaf');
  if (certs[0].curve !== 'P-256') throw new VerifyError('bad_leaf');

  const leafKey = await importCertKey(certs[0]);
  const signature = b64urlToBytes(parts[2]);
  const signedData = encoder.encode(`${parts[0]}.${parts[1]}`);
  const ok = signature.length === 64 && (await crypto.subtle.verify({ name: 'ECDSA', hash: 'SHA-256' }, leafKey, signature, signedData));
  if (!ok) throw new VerifyError('bad_signature');

  try {
    return JSON.parse(decoder.decode(b64urlToBytes(parts[1])));
  } catch {
    throw new VerifyError('bad_payload');
  }
}

/** Годится ли транзакция для доступа к ИИ. Возвращает null, если да, или короткую причину отказа */
export function checkEntitlement(payload, env, now = Date.now()) {
  const bundleId = env.BUNDLE_ID || 'com.samvel.armenianbible';
  const products = (env.PRODUCT_IDS || '').split(',').map((s) => s.trim()).filter(Boolean);
  if (payload.bundleId !== bundleId) return 'bundle';
  if (!products.includes(payload.productId)) return 'product';
  if (payload.revocationDate) return 'revoked';
  if (typeof payload.expiresDate !== 'number' || payload.expiresDate < now) return 'expired';
  if (payload.environment !== 'Production' && payload.environment !== 'Sandbox') return 'environment';
  if (payload.environment === 'Sandbox' && env.ALLOW_SANDBOX === 'false') return 'sandbox';
  if (!payload.originalTransactionId) return 'no_id';
  return null;
}

export { children, readTLV };

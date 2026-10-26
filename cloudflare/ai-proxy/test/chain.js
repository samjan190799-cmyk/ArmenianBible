// Пробная цепочка сертификатов «как у Apple» (корень P-384 → промежуточный P-384 → лист P-256 с расширениями Apple),
// собранная через openssl, и подписание ею JWS. Настоящий корень Apple тут не нужен: тест подставляет отпечаток своего корня.

import { mkdtempSync, writeFileSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';
import { createHash, sign } from 'node:crypto';

const dir = mkdtempSync(join(tmpdir(), 'luys-chain-'));

function openssl(...args) {
  return execFileSync('openssl', args, { cwd: dir, stdio: 'pipe', maxBuffer: 1 << 20 });
}

export function opensslAvailable() {
  try {
    execFileSync('openssl', ['version'], { stdio: 'pipe' });
    return true;
  } catch {
    return false;
  }
}

/** leafOid=false — лист без расширения Apple: так выглядит сертификат обычного разработчика, выданный тем же промежуточным */
export function makeChain(prefix, { leafOid = true } = {}) {
  const n = (name) => `${prefix}${name}`;
  openssl('ecparam', '-name', 'secp384r1', '-genkey', '-noout', '-out', n('root.key'));
  openssl('req', '-x509', '-new', '-key', n('root.key'), '-sha384', '-days', '3650', '-subj', '/CN=Test Root', '-out', n('root.pem'));

  writeFileSync(join(dir, n('int.ext')), 'basicConstraints=critical,CA:TRUE\n1.2.840.113635.100.6.2.1=ASN1:NULL\n');
  openssl('ecparam', '-name', 'secp384r1', '-genkey', '-noout', '-out', n('int.key'));
  openssl('req', '-new', '-key', n('int.key'), '-subj', '/CN=Test Intermediate', '-out', n('int.csr'));
  openssl('x509', '-req', '-in', n('int.csr'), '-CA', n('root.pem'), '-CAkey', n('root.key'), '-CAcreateserial', '-sha384', '-days', '3650', '-extfile', n('int.ext'), '-out', n('int.pem'));

  writeFileSync(join(dir, n('leaf.ext')), leafOid ? '1.2.840.113635.100.6.11.1=ASN1:NULL\n' : 'basicConstraints=CA:FALSE\n');
  openssl('ecparam', '-name', 'prime256v1', '-genkey', '-noout', '-out', n('leaf.key'));
  openssl('req', '-new', '-key', n('leaf.key'), '-subj', '/CN=Test Leaf', '-out', n('leaf.csr'));
  openssl('x509', '-req', '-in', n('leaf.csr'), '-CA', n('int.pem'), '-CAkey', n('int.key'), '-CAcreateserial', '-sha256', '-days', '3650', '-extfile', n('leaf.ext'), '-out', n('leaf.pem'));

  const der = (name) => openssl('x509', '-in', n(`${name}.pem`), '-outform', 'DER');
  const rootDer = der('root');
  return {
    leaf: der('leaf').toString('base64'),
    int: der('int').toString('base64'),
    root: rootDer.toString('base64'),
    rootSha: createHash('sha256').update(rootDer).digest('hex'),
    leafKeyPem: readFileSync(join(dir, n('leaf.key')))
  };
}

const b64u = (value) => Buffer.from(value).toString('base64url');

export function makeJws(chain, payload, { x5c } = {}) {
  const header = { alg: 'ES256', x5c: x5c ?? [chain.leaf, chain.int, chain.root] };
  const input = `${b64u(JSON.stringify(header))}.${b64u(JSON.stringify(payload))}`;
  const signature = sign('sha256', Buffer.from(input), { key: chain.leafKeyPem, dsaEncoding: 'ieee-p1363' });
  return `${input}.${b64u(signature)}`;
}

export function goodPayload(overrides = {}) {
  return {
    bundleId: 'com.samvel.armenianbible',
    productId: 'com.samvel.armenianbible.subscription.yearly',
    originalTransactionId: '2000000123456789',
    expiresDate: Date.now() + 7 * 24 * 3600 * 1000,
    environment: 'Sandbox',
    ...overrides
  };
}

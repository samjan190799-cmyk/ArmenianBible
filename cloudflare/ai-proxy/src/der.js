// Минимальный разбор DER: ровно столько, сколько нужно, чтобы проверить цепочку сертификатов Apple
// без внешних библиотек (работает и в Cloudflare Workers, и в Node).

const OIDS = {
  ecdsaSha256: '2a8648ce3d040302',
  ecdsaSha384: '2a8648ce3d040303',
  curveP256: '2a8648ce3d030107',
  curveP384: '2b81040022'
};

export function readTLV(buf, offset = 0) {
  if (offset + 2 > buf.length) throw new Error('der: truncated');
  const tag = buf[offset];
  let len = buf[offset + 1];
  let headerLen = 2;
  if (len & 0x80) {
    const n = len & 0x7f;
    if (n === 0 || n > 3) throw new Error('der: bad length');
    len = 0;
    for (let i = 0; i < n; i++) len = (len << 8) | buf[offset + 2 + i];
    headerLen = 2 + n;
  }
  const start = offset + headerLen;
  const end = start + len;
  if (end > buf.length) throw new Error('der: truncated');
  return { tag, offset, start, end };
}

export function children(buf, node) {
  const out = [];
  let p = node.start;
  while (p < node.end) {
    const child = readTLV(buf, p);
    out.push(child);
    p = child.end;
  }
  return out;
}

function hex(bytes) {
  return Array.from(bytes, (b) => b.toString(16).padStart(2, '0')).join('');
}

function oidHex(buf, node) {
  if (node.tag !== 0x06) throw new Error('der: oid expected');
  return hex(buf.subarray(node.start, node.end));
}

/** Разбирает сертификат X.509: что подписано, чем подписано и открытый ключ */
export function parseCertificate(der) {
  const cert = readTLV(der, 0);
  const [tbs, sigAlg, sigBits] = children(der, cert);
  const tbsKids = children(der, tbs);
  // [0] версия может отсутствовать; дальше: serial, signature, issuer, validity, subject, subjectPublicKeyInfo
  const first = tbsKids[0].tag === 0xa0 ? 1 : 0;
  const spki = tbsKids[first + 5];
  const spkiKids = children(der, spki);
  const algKids = children(der, spkiKids[0]);
  const curve = oidHex(der, algKids[1]);
  return {
    tbsBytes: der.subarray(tbs.offset, tbs.end),
    sigAlg: oidHex(der, children(der, sigAlg)[0]),
    signature: der.subarray(sigBits.start + 1, sigBits.end),
    spkiBytes: der.subarray(spki.offset, spki.end),
    curve: curve === OIDS.curveP256 ? 'P-256' : curve === OIDS.curveP384 ? 'P-384' : 'unknown'
  };
}

export function hashForSignatureOid(oid) {
  if (oid === OIDS.ecdsaSha256) return 'SHA-256';
  if (oid === OIDS.ecdsaSha384) return 'SHA-384';
  throw new Error('der: unsupported signature algorithm');
}

/** Подпись ECDSA из сертификата (SEQUENCE из двух INTEGER) → «сырые» r и s, как их ждёт WebCrypto */
export function ecdsaDerToRaw(sig, size) {
  const seq = readTLV(sig, 0);
  const [r, s] = children(sig, seq);
  const pad = (node) => {
    let v = sig.subarray(node.start, node.end);
    while (v.length > size && v[0] === 0) v = v.subarray(1);
    if (v.length > size) throw new Error('der: bad signature integer');
    const out = new Uint8Array(size);
    out.set(v, size - v.length);
    return out;
  };
  const raw = new Uint8Array(size * 2);
  raw.set(pad(r), 0);
  raw.set(pad(s), size);
  return raw;
}

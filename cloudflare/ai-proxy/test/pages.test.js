import { test } from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import worker from '../src/index.js';
import { giftPageHtml, duelPageHtml, PAGE_HEADERS } from '../src/pages.js';

function toBase64Url(value) {
  return Buffer.from(JSON.stringify(value), 'utf8').toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/** Запускает скрипт страницы на крошечной подделке DOM: что он построил, видно в card.children */
function run(html, hash, language = 'ru-RU') {
  const code = /<script>([\s\S]*)<\/script>/.exec(html)[1];
  const card = { children: [], appendChild(node) { this.children.push(node); } };
  const document = {
    getElementById: () => card,
    createElement: (tag) => ({ tag, className: '', textContent: '', href: '' })
  };
  const sandbox = {
    document,
    location: { hash },
    navigator: { language },
    atob: globalThis.atob,
    TextDecoder: globalThis.TextDecoder,
    Uint8Array
  };
  vm.runInNewContext(code, sandbox);
  return card.children;
}

test('страницы отдаются Worker с жёсткими заголовками и без кеширования данных', async () => {
  for (const path of ['/g', '/d']) {
    const res = await worker.fetch(new Request(`https://luys.example${path}`), {}, {});
    assert.equal(res.status, 200);
    assert.match(res.headers.get('content-type'), /^text\/html/);
    assert.match(res.headers.get('content-security-policy'), /default-src 'none'/);
    assert.equal(res.headers.get('referrer-policy'), 'no-referrer');
    assert.equal(res.headers.get('x-content-type-options'), 'nosniff');
    const html = await res.text();
    assert.ok(html.includes('armenianbible://'));
    assert.ok(html.includes('https://apps.apple.com/app/id6790569890'));
  }
  assert.equal(PAGE_HEADERS['content-type'], 'text/html; charset=utf-8');
});

test('подарок: текст, подпись и имя показываются, кнопка ведёт в приложение с теми же данными', () => {
  const payload = toBase64Url({ t: 'Благословение на каждый день', c: 'Пасха', l: 'russian', n: 'Самвел' });
  const nodes = run(giftPageHtml(), '#' + payload);
  const texts = nodes.map((n) => n.textContent);
  assert.ok(texts.includes('Благословение на каждый день'));
  assert.ok(texts.includes('От Самвел'));
  assert.ok(texts.includes('Пасха'));
  const open = nodes.find((n) => n.href.startsWith('armenianbible://gift?d='));
  assert.ok(open, 'нет кнопки «Открыть в приложении»');
  assert.equal(open.href, 'armenianbible://gift?d=' + payload);
  assert.ok(nodes.some((n) => n.href === 'https://apps.apple.com/app/id6790569890'));
});

test('подарок: язык страницы по языку браузера, армянский текст не ломается', () => {
  const payload = toBase64Url({ t: 'Սերը երկայնամիտ է', c: 'Սրտանց', n: 'Անի' });
  const hy = run(giftPageHtml(), '#' + payload, 'hy-AM').map((n) => n.textContent);
  assert.ok(hy.includes('Սերը երկայնամիտ է'));
  assert.ok(hy.includes('Անի-ից'));
  const en = run(giftPageHtml(), '#' + payload, 'en-US').map((n) => n.textContent);
  assert.ok(en.includes('From Անի'));
});

test('HTML в тексте подарка остаётся текстом: страница кладёт его только через textContent', () => {
  const evil = '<img src=x onerror=alert(1)>';
  const nodes = run(giftPageHtml(), '#' + toBase64Url({ t: evil, c: '<b>x</b>', n: '<script>' }));
  const textNode = nodes.find((n) => n.className === 'text');
  assert.equal(textNode.textContent, evil);
  assert.ok(nodes.every((n) => n.tag !== 'img' && n.tag !== 'script'));
});

test('чужие знаки в части ссылки не попадают в адреса кнопок', () => {
  // мусор после данных: страница либо считает ссылку повреждённой, либо берёт только безопасные знаки
  const nodes = run(giftPageHtml(), '#' + toBase64Url({ t: 'ok' }) + '"><script>alert(1)</script>', 'en-US');
  for (const node of nodes) {
    assert.ok(!/[<>"' ]/.test(node.href), 'в адресе кнопки опасный знак: ' + node.href);
  }
  assert.ok(nodes.some((n) => n.textContent === 'This link is damaged'));
});

test('битая или пустая ссылка: сообщение «ссылка повреждена» и App Store, без падения', () => {
  for (const hash of ['', '#', '#!!!', '#abc']) {
    const nodes = run(giftPageHtml(), hash, 'en-US');
    assert.ok(nodes.some((n) => n.textContent === 'This link is damaged'), `hash=${hash}`);
    assert.ok(nodes.some((n) => n.href === 'https://apps.apple.com/app/id6790569890'));
  }
});

test('дуэль: вызов показывает счёт соперника, ответ показывает итог', () => {
  const challenge = toBase64Url({ c: 'all', s: 5, n: 10, m: 90, a: 'Самвел', r: 8 });
  const nodes = run(duelPageHtml(), '#' + challenge, 'ru-RU');
  const texts = nodes.map((n) => n.textContent);
  assert.ok(texts.includes('Самвел вызывает вас'));
  assert.ok(texts.includes('8 / 10'));
  assert.ok(nodes.some((n) => n.href === 'armenianbible://duel?d=' + challenge));

  const reply = toBase64Url({ c: 'all', s: 5, n: 10, m: 90, a: 'Самвел', r: 8, b: 'Ани', q: 7 });
  const result = run(duelPageHtml(), '#' + reply, 'ru-RU').map((n) => n.textContent);
  assert.ok(result.includes('Итог дуэли'));
  assert.ok(result.includes('8 : 7'));
  assert.ok(result.includes('Самвел — Ани'));
});

test('дуэль: без счёта автора вызова страница считает ссылку повреждённой', () => {
  const nodes = run(duelPageHtml(), '#' + toBase64Url({ c: 'all', s: 1, n: 10 }), 'en-US');
  assert.ok(nodes.some((n) => n.textContent === 'This link is damaged'));
});

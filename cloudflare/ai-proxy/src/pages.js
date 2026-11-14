// Страницы-приземления для ссылок «для двоих»: /g (лист в подарок) и /d (вызов на дуэль).
// Данные лежат в части ссылки после «#» (JSON в base64url): браузер не отправляет её на сервер, так что Worker
// не видит ни текста подарка, ни имён и ничего не хранит. Страница расшифровывает данные у человека в браузере и
// показывает их через textContent (без разметки), а затем предлагает «Открыть в приложении» или App Store.

const APP_STORE = 'https://apps.apple.com/app/id6790569890';

const STYLE = `
  :root { color-scheme: light dark; }
  * { box-sizing: border-box; }
  body { margin: 0; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 24px;
         background: #f4eee3; color: #2b241d; font-family: Georgia, 'Noto Serif Armenian', serif; }
  @media (prefers-color-scheme: dark) { body { background: #17120e; color: #ece3d2; } .card { background: #292019; } }
  .card { width: 100%; max-width: 420px; background: #fcf9f3; border: 1px solid rgba(143,107,42,.45); border-radius: 18px;
          padding: 28px 24px; text-align: center; box-shadow: 0 8px 30px rgba(0,0,0,.12); }
  h1 { font-size: 20px; margin: 0 0 6px; }
  .from { font-size: 14px; opacity: .7; margin-bottom: 18px; }
  .text { font-size: 20px; line-height: 1.5; margin: 18px 0; white-space: pre-wrap; word-break: break-word; }
  .caption { font-size: 13px; color: #a8291f; font-weight: 600; margin-bottom: 20px; }
  .score { font-size: 38px; font-weight: 600; color: #8f6b2a; margin: 10px 0 4px; }
  .hint { font-size: 13px; opacity: .7; margin: 14px 0 18px; }
  a.btn { display: block; padding: 14px; border-radius: 14px; text-decoration: none; font-weight: 600; margin-top: 10px; }
  a.primary { background: #9e3226; color: #fcf9f3; }
  a.secondary { border: 1.5px solid #8f6b2a; color: #8f6b2a; }
`;

const SHARED_SCRIPT = `
  var LANG = (navigator.language || 'en').slice(0, 2);
  if (LANG !== 'hy' && LANG !== 'ru') LANG = 'en';
  function t(map) { return map[LANG] || map.en; }
  function decode(s) {
    s = s.replace(/-/g, '+').replace(/_/g, '/');
    while (s.length % 4) s += '=';
    var bin = atob(s);
    var bytes = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return JSON.parse(new TextDecoder().decode(bytes));
  }
  var raw = (location.hash || '').slice(1).replace(/[^A-Za-z0-9_-]/g, '');
  var data = null;
  try { data = raw ? decode(raw) : null; } catch (e) { data = null; }
  function el(tag, cls, text) {
    var node = document.createElement(tag);
    if (cls) node.className = cls;
    if (text !== undefined) node.textContent = text;
    return node;
  }
  function button(cls, label, href) {
    var a = el('a', 'btn ' + cls, label);
    a.href = href;
    return a;
  }
  var card = document.getElementById('card');
  function finish(openHost, key) {
    card.appendChild(el('div', 'hint', t({
      hy: 'Հավելվածում ամեն ինչ կենդանանում է:',
      ru: 'В приложении всё оживает.',
      en: 'It all comes alive in the app.'
    })));
    if (raw) card.appendChild(button('primary', t({ hy: 'Բացել հավելվածում', ru: 'Открыть в приложении', en: 'Open in the app' }), 'armenianbible://' + openHost + '?' + (key || 'd') + '=' + raw));
    card.appendChild(button('secondary', t({ hy: 'Ներբեռնել App Store-ից', ru: 'Скачать в App Store', en: 'Get it on the App Store' }), '${APP_STORE}'));
  }
  function broken() {
    card.appendChild(el('h1', '', t({ hy: 'Հղումը վնասված է', ru: 'Ссылка повреждена', en: 'This link is damaged' })));
    card.appendChild(button('secondary', t({ hy: 'Ներբեռնել App Store-ից', ru: 'Скачать в App Store', en: 'Get it on the App Store' }), '${APP_STORE}'));
  }
`;

const GIFT_SCRIPT = `
  if (!data || typeof data.t !== 'string' || !data.t) { broken(); } else {
    card.appendChild(el('h1', '', t({ hy: 'Էջ Ձեզ համար', ru: 'Лист для вас', en: 'A page for you' })));
    if (typeof data.n === 'string' && data.n) {
      card.appendChild(el('div', 'from', t({ hy: data.n + '-ից', ru: 'От ' + data.n, en: 'From ' + data.n })));
    }
    card.appendChild(el('div', 'text', data.t.slice(0, 400)));
    if (typeof data.c === 'string' && data.c) card.appendChild(el('div', 'caption', data.c.slice(0, 80)));
    finish('gift');
  }
`;

const DUEL_SCRIPT = `
  if (!data || typeof data.n !== 'number' || typeof data.r !== 'number') { broken(); } else {
    var a = (typeof data.a === 'string' && data.a) ? data.a.slice(0, 40) : t({ hy: 'Մրցակից', ru: 'Соперник', en: 'Your friend' });
    if (typeof data.q === 'number') {
      var b = (typeof data.b === 'string' && data.b) ? data.b.slice(0, 40) : t({ hy: 'Մրցակից', ru: 'Соперник', en: 'Your friend' });
      card.appendChild(el('h1', '', t({ hy: 'Մենամարտի արդյունքը', ru: 'Итог дуэли', en: 'Duel result' })));
      card.appendChild(el('div', 'score', data.r + ' : ' + data.q));
      card.appendChild(el('div', 'from', a + ' — ' + b));
    } else {
      card.appendChild(el('h1', '', t({ hy: 'Աստվածաշնչի վիկտորինայի մարտահրավեր', ru: 'Вызов на библейскую викторину', en: 'A Bible quiz challenge' })));
      card.appendChild(el('div', 'from', t({ hy: a + '-ը Ձեզ հրավիրում է', ru: a + ' вызывает вас', en: a + ' challenges you' })));
      card.appendChild(el('div', 'score', data.r + ' / ' + data.n));
      card.appendChild(el('div', 'caption', t({ hy: 'Մրցակցի արդյունքը', ru: 'Счёт соперника', en: 'Their score' })));
    }
    finish('duel');
  }
`;

const ROOM_SCRIPT = `
  if (!/^[A-HJ-NP-Z2-9]{5}$/.test(raw)) { broken(); } else {
    card.appendChild(el('h1', '', t({ hy: 'Ձեզ կանչում են ուղիղ մենամարտի', ru: 'Вас зовут на дуэль онлайн', en: 'You are invited to a live duel' })));
    card.appendChild(el('div', 'from', t({ hy: 'Աստվածաշնչի վիկտորինա երկուսի համար', ru: 'Библейская викторина на двоих', en: 'A Bible quiz for two' })));
    card.appendChild(el('div', 'score', raw));
    card.appendChild(el('div', 'caption', t({ hy: 'Սենյակի կոդ', ru: 'Код комнаты', en: 'Room code' })));
    finish('room', 'c');
  }
`;

function page(title, script) {
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="referrer" content="no-referrer">
<title>${title}</title>
<style>${STYLE}</style></head>
<body><div class="card" id="card"></div>
<script>${SHARED_SCRIPT}${script}</script>
</body></html>`;
}

export function giftPageHtml() {
  return page('Luys', GIFT_SCRIPT);
}

export function duelPageHtml() {
  return page('Luys', DUEL_SCRIPT);
}

export function roomPageHtml() {
  return page('Luys', ROOM_SCRIPT);
}

/** Заголовки страниц: скрипт и стили только свои, ничего чужого страница не грузит и не отправляет */
export const PAGE_HEADERS = {
  'content-type': 'text/html; charset=utf-8',
  'cache-control': 'public, max-age=300',
  'content-security-policy': "default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
  'x-content-type-options': 'nosniff',
  'referrer-policy': 'no-referrer'
};

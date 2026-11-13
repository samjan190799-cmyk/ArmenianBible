// Страница с цифрами воронки: открывается с телефона по адресу /dashboard. Токен вводится один раз и хранится только в браузере
// (в самой странице секретов нет), данные берутся запросом GET /v1/stats с этим токеном.

export const DASHBOARD_SCRIPT = String.raw`
const FUNNEL = [
  ['Открыли приложение', 'app_open', ''],
  ['Увидели экран подписки', 'paywall_shown', ''],
  ['Выбрали тариф', 'paywall_plan', ''],
  ['Нажали «Купить»', 'purchase_started', ''],
  ['Купили', 'purchase_result', 'result=success']
];
const LABELS = {
  ai: 'ИИ-помощник', ai_limit: 'Лимит вопросов', narek_audio: 'Аудио Нарека', consolation: 'Нарек утешает', candle: 'Свеча',
  map: 'Карта святынь', quiz: 'Викторина', wallpaper: 'Обои', wallpaper_auto: 'Автообои', settings: 'Настройки', home: 'Главный экран',
  manuscript_pen: 'Перо рукописи', manuscript_surface: 'Основа рукописи', widget: 'Виджеты', unknown: 'Не указано'
};
const app = document.getElementById('app');
let days = Number(localStorage.getItem('luys_stats_days')) || 14;

function h(tag, text, cls) {
  const node = document.createElement(tag);
  if (text !== undefined && text !== null) node.textContent = String(text);
  if (cls) node.className = cls;
  return node;
}
function cell(events, name, dim) {
  return (events[name] && events[name][dim]) || { events: 0, people: 0 };
}
function percent(part, whole) {
  return whole > 0 ? Math.round((part / whole) * 1000) / 10 + '%' : '—';
}
function table(headers, rows) {
  const t = h('table');
  const head = h('tr');
  headers.forEach((x) => head.appendChild(h('th', x)));
  t.appendChild(head);
  rows.forEach((row) => {
    const tr = h('tr');
    row.forEach((x) => tr.appendChild(h('td', x)));
    t.appendChild(tr);
  });
  return t;
}
function dimRows(events, name, key, labels) {
  const prefix = key + '=';
  return Object.entries(events[name] || {})
    .filter(([dim]) => dim.startsWith(prefix))
    .map(([dim, v]) => [labels && labels[dim.slice(prefix.length)] || dim.slice(prefix.length), v.people, v.events])
    .sort((a, b) => b[1] - a[1]);
}
function section(title) {
  app.appendChild(h('h2', title));
}

function render(data) {
  app.textContent = '';
  const ev = data.events;
  const active = cell(ev, '_active', '');
  const total = data.daily.reduce((s, d) => s + d.newInstalls, 0);
  const premiumYes = cell(ev, '_active', 'premium=yes').events;

  const picker = h('div', null, 'picker');
  [7, 14, 30].forEach((n) => {
    const b = h('button', n + ' дн.', n === days ? 'on' : '');
    b.onclick = () => { days = n; localStorage.setItem('luys_stats_days', n); load(); };
    picker.appendChild(b);
  });
  app.appendChild(picker);

  section('Сводка за ' + days + ' дн.');
  app.appendChild(table(['', ''], [
    ['Разных людей открывали приложение', active.people],
    ['Новых установок', total],
    ['Дней с подпиской (активных людей-дней)', premiumYes]
  ]));

  section('Воронка (люди)');
  const first = cell(ev, FUNNEL[0][1], FUNNEL[0][2]).people;
  let prev = first;
  const rows = FUNNEL.map(([label, name, dim]) => {
    const people = cell(ev, name, dim).people;
    const row = [label, people, percent(people, prev), percent(people, first)];
    prev = people;
    return row;
  });
  app.appendChild(table(['Шаг', 'Людей', 'От прошлого', 'От открывших'], rows));

  section('Откуда открывали подписку');
  app.appendChild(table(['Откуда', 'Людей', 'Раз'], dimRows(ev, 'paywall_shown', 'source', LABELS)));

  section('Итог покупок');
  app.appendChild(table(['Итог', 'Людей', 'Раз'], dimRows(ev, 'purchase_result', 'result')));
  const restore = dimRows(ev, 'restore_result', 'result');
  if (restore.length) {
    section('Восстановление покупок');
    app.appendChild(table(['Итог', 'Людей', 'Раз'], restore));
  }
  const products = dimRows(ev, 'products_loaded', 'result');
  if (products.length) {
    section('Загрузка тарифов из App Store');
    app.appendChild(table(['Итог', 'Людей', 'Раз'], products));
  }

  section('Чем пользуются');
  app.appendChild(table(['Функция', 'Людей', 'Раз'], dimRows(ev, 'feature_used', 'feature')));

  section('ИИ');
  const aiRows = Object.entries(ev.ai_result || {})
    .filter(([dim]) => dim !== '')
    .map(([dim, v]) => [dim.replace('result=', 'итог: ').replace('via=', 'через: '), v.people, v.events])
    .sort((a, b) => b[1] - a[1]);
  app.appendChild(table(['Что', 'Людей', 'Раз'], aiRows));

  section('Языки активных людей');
  app.appendChild(table(['Язык', 'Людей-дней'], Object.entries(ev._active || {}).filter(([d]) => d.startsWith('lang=')).map(([d, v]) => [d.slice(5), v.events])));

  section('По дням');
  app.appendChild(table(['День', 'Активных', 'Новых', 'Видели подписку', 'Покупок'],
    data.daily.slice().reverse().map((d) => [d.day, d.active, d.newInstalls, d.paywallShown, d.purchases])));

  section('Служебное');
  const reset = h('button', 'Сбросить все цифры', 'danger');
  reset.onclick = async () => {
    if (!confirm('Стереть все накопленные цифры воронки? Это нельзя отменить.')) return;
    try {
      const res = await fetch('/v1/stats/reset', { method: 'POST', headers: { authorization: 'Bearer ' + localStorage.getItem('luys_stats_token') } });
      if (!res.ok) { alert('Не удалось сбросить: ' + res.status); return; }
      load();
    } catch (e) {
      alert('Нет связи с сервером.');
    }
  };
  app.appendChild(reset);
}

async function load() {
  let token = localStorage.getItem('luys_stats_token');
  if (!token) {
    token = prompt('Токен статистики (его вы задавали командой wrangler secret put STATS_TOKEN)') || '';
    if (!token) { app.textContent = 'Без токена цифры не показать. Обновите страницу.'; return; }
  }
  app.textContent = 'Загрузка…';
  try {
    const res = await fetch('/v1/stats?days=' + days, { headers: { authorization: 'Bearer ' + token } });
    if (res.status === 401) { localStorage.removeItem('luys_stats_token'); app.textContent = 'Токен не подошёл. Обновите страницу и введите заново.'; return; }
    if (res.status === 503) { app.textContent = 'Токен статистики на сервере не задан (STATS_TOKEN).'; return; }
    if (!res.ok) { app.textContent = 'Ошибка сервера: ' + res.status; return; }
    localStorage.setItem('luys_stats_token', token);
    render(await res.json());
  } catch (e) {
    app.textContent = 'Нет связи с сервером.';
  }
}
load();
`;

export function dashboardHtml() {
  return `<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>Luys: воронка</title>
<style>
:root { color-scheme: light dark; --bg: #f6f1e7; --ink: #2b241d; --muted: #6e6152; --line: rgba(43,36,29,.14); --accent: #9e3226; }
@media (prefers-color-scheme: dark) { :root { --bg: #17130f; --ink: #ece3d2; --muted: #a99c89; --line: rgba(236,227,210,.16); --accent: #db7b6d; } }
body { margin: 0; padding: 16px; background: var(--bg); color: var(--ink); font: 15px/1.4 -apple-system, system-ui, "Segoe UI", sans-serif; }
h1 { font-size: 22px; margin: 4px 0 12px; }
h2 { font-size: 15px; margin: 22px 0 6px; color: var(--accent); text-transform: uppercase; letter-spacing: .04em; }
table { width: 100%; border-collapse: collapse; }
th, td { padding: 6px 4px; text-align: left; border-bottom: 1px solid var(--line); vertical-align: top; }
th { color: var(--muted); font-weight: 600; font-size: 13px; }
td:not(:first-child), th:not(:first-child) { text-align: right; white-space: nowrap; }
.picker button { margin-right: 8px; padding: 6px 12px; border: 1px solid var(--line); border-radius: 14px; background: transparent; color: var(--ink); font: inherit; }
.picker button.on { background: var(--accent); border-color: var(--accent); color: var(--bg); }
button.danger { margin: 22px 0 8px; padding: 8px 14px; border: 1px solid var(--accent); border-radius: 14px; background: transparent; color: var(--accent); font: inherit; }
</style>
</head>
<body>
<h1>Воронка Luys</h1>
<div id="app">Загрузка…</div>
<script>${DASHBOARD_SCRIPT}</script>
</body>
</html>`;
}

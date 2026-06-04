const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

app.use('/public', express.static(path.join(__dirname, 'public')));
const session = require('express-session');
app.use(session({ secret: 'wolfy-secret', resave: false, saveUninitialized: true }));
app.use(express.json());
// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

// simple in-memory store for hole cards per dealt hand
const holeStore = new Map();

function buildDeck() {
  const suits = ['♠', '♥', '♦', '♣'];
  const ranks = ['A','2','3','4','5','6','7','8','9','10','J','Q','K'];
  const deck = [];
  for (const s of suits) {
    for (const r of ranks) {
      deck.push({rank: r, suit: s, code: `${r}${s}`});
    }
  }
  return deck;
}

function shuffle(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

function getRandomHand(count = 5) {
  const deck = buildDeck();
  shuffle(deck);
  return deck.slice(0, count);
}

function dealFromDeck() {
  const deck = buildDeck();
  shuffle(deck);
  return deck;
}

app.get('/api/hand', (req, res) => {
  const hand = getRandomHand(5);
  res.json({hand});
});

// Return hole cards for a given hand id. The hole cards are deleted after the first successful fetch
app.get('/api/hole', (req, res) => {
  const id = req.query.id || req.session.handId;
  const idxRaw = req.query.index;
  if (!id) return res.status(400).json({error: 'missing id'});
  const entry = holeStore.get(id);
  if (!entry) return res.status(404).json({error: 'not found or already revealed'});
  if (typeof idxRaw === 'undefined') return res.status(400).json({error: 'missing index'});
  const i = parseInt(idxRaw, 10);
  if (Number.isNaN(i) || i < 0 || i >= entry.hole.length) return res.status(400).json({error: 'invalid index'});
  const card = entry.hole[i];
  if (!card) return res.status(410).json({error: 'card not available'});
  return res.json({card});
});

// Advance community cards: returns next batch (flop/turn/river)
app.get('/api/advance', (req, res) => {
  const id = req.query.id || req.session.handId;
  if (!id) return res.status(400).json({error: 'missing id'});
  const entry = holeStore.get(id);
  if (!entry) return res.status(404).json({error: 'not found'});
  if (entry.commRevealed >= 5) return res.status(400).json({ error: 'all revealed' });
  // reveal next step with burn card: if 0 -> flop (burn1 then flop 3), if 3 -> turn (burn2 then turn), if 4 -> river (burn3 then river)
  let stage = 'unknown';
  let cards = [];
  let burn = null;
  if (entry.commRevealed === 0) {
    stage = 'flop';
    burn = entry.burns[0] || null;
    cards = entry.community.slice(0,3);
    entry.commRevealed += 3;
  } else if (entry.commRevealed === 3) {
    stage = 'turn';
    burn = entry.burns[1] || null;
    cards = [entry.community[3]];
    entry.commRevealed += 1;
  } else if (entry.commRevealed === 4) {
    stage = 'river';
    burn = entry.burns[2] || null;
    cards = [entry.community[4]];
    entry.commRevealed += 1;
  }
  holeStore.set(id, entry);
  // do not send burn card details to client — only reveal community cards and stage
  res.json({ stage, cards, revealed: entry.commRevealed });
});

// get store info (three secret cards) - do not reveal actual card values here
app.get('/api/store', (req, res) => {
  const id = req.query.id || req.session.handId;
  if (!id) return res.status(400).json({error: 'missing id'});
  const entry = holeStore.get(id);
  if (!entry) return res.status(404).json({error:'not found'});
  // return number of cards and whether trade is allowed
  // allow one trade pre-flop (commRevealed === 0) and one trade for each post-flop stage (commRevealed >= 3)
  const allowed = ((entry.commRevealed === 0) || (entry.commRevealed >= 3)) && (entry.lastTradeReveal !== entry.commRevealed);
  res.json({ count: entry.shop.length, allowed });
});

// execute a trade: body { shopIndex, holeIndex }
app.post('/api/trade', (req, res) => {
  const id = req.query.id || req.session.handId;
  if (!id) return res.status(400).json({error: 'missing id'});
  const entry = holeStore.get(id);
  if (!entry) return res.status(404).json({error:'not found'});
  const { shopIndex, holeIndex } = req.body || {};
  if (typeof shopIndex === 'undefined' || typeof holeIndex === 'undefined') return res.status(400).json({error:'missing indices'});
  if (!Number.isInteger(shopIndex) || shopIndex < 0 || shopIndex >= entry.shop.length) return res.status(400).json({error:'invalid shopIndex'});
  if (!Number.isInteger(holeIndex) || holeIndex < 0 || holeIndex >= entry.hole.length) return res.status(400).json({error:'invalid holeIndex'});
  // allow trades pre-flop (commRevealed === 0) or post-flop (commRevealed >= 3); one trade per stage
  if (!((entry.commRevealed === 0) || (entry.commRevealed >= 3))) return res.status(400).json({ error: 'trade not allowed at this stage' });
  if (entry.lastTradeReveal === entry.commRevealed) return res.status(400).json({error:'trade already used for this stage'});
  // perform trade: shop card -> hole, traded-in hole card -> burns, then replenish shop slot from deck
  const shopCard = entry.shop[shopIndex];
  const holeCard = entry.hole[holeIndex];
  // put shop card into player's hole
  entry.hole[holeIndex] = shopCard;
  // burn the traded-in hole card
  entry.burns = entry.burns || [];
  entry.burns.push(holeCard);
  // replenish shop slot from deck (if any remain)
  const replacement = (entry.deck && entry.deck.length) ? entry.deck.splice(0,1)[0] : null;
  entry.shop[shopIndex] = replacement;
  entry.lastTradeReveal = entry.commRevealed;
  holeStore.set(id, entry);
  // only reveal the new hole value to the requester (single card response)
  // also return the new replacement that was put into the shop slot (may be null)
  res.json({ card: entry.hole[holeIndex], replacement });
});

// Helper: map rank string to numeric value
const RANK_VALUE = {
  '2': 2,'3':3,'4':4,'5':5,'6':6,'7':7,'8':8,'9':9,'10':10,'J':11,'Q':12,'K':13,'A':14
};

function cardValue(card) {
  return RANK_VALUE[card.rank] || parseInt(card.rank, 10) || 0;
}

// evaluate a 5-card hand and return a comparable score array and name
function evaluateFive(cards) {
  // cards: array of 5 {rank,suit,code}
  const vals = cards.map(c => cardValue(c)).sort((a,b) => b-a);
  const suits = cards.map(c => c.suit);
  const counts = {};
  for (const v of vals) counts[v] = (counts[v]||0)+1;
  const uniq = Object.keys(counts).map(x=>parseInt(x,10)).sort((a,b)=>b-a);
  const isFlush = suits.every(s => s === suits[0]);
  // straight detection (handle wheel A-2-3-4-5)
  let isStraight = false;
  let highStraight = 0;
  const uniqDesc = Array.from(new Set(vals));
  // check normal straight
  for (let i=0;i<=uniqDesc.length-5;i++){}
  // build unique sorted ascending for easier straight check
  const uniqAsc = Array.from(new Set(vals)).sort((a,b)=>a-b);
  // attempt highest straight
  for (let i = uniqAsc.length-1; i>=4; i--) {
    const slice = uniqAsc.slice(i-4, i+1);
    if (slice.length === 5 && slice[4]-slice[0] === 4) {
      isStraight = true;
      highStraight = slice[4];
      break;
    }
  }
  // check wheel A-2-3-4-5
  if (!isStraight) {
    const wheel = [14,5,4,3,2];
    if (wheel.every(v => uniqAsc.indexOf(v) !== -1)) {
      isStraight = true;
      highStraight = 5;
    }
  }

  // counts sorted
  const countPairs = Object.entries(counts).map(([k,v])=>({v:+k,count:v})).sort((a,b)=>{ if (a.count!==b.count) return b.count-a.count; return b.v - a.v; });

  // determine category
  // categories: 8 StraightFlush,7 FourKind,6 FullHouse,5 Flush,4 Straight,3 Trips,2 TwoPair,1 Pair,0 HighCard
  // produce score tuple for comparison
  if (isStraight && isFlush) return {score:[8, highStraight], name:'Straight Flush'};
  if (countPairs[0].count === 4) return {score:[7, countPairs[0].v, countPairs[1].v], name:'Four of a Kind'};
  if (countPairs[0].count === 3 && countPairs[1] && countPairs[1].count === 2) return {score:[6, countPairs[0].v, countPairs[1].v], name:'Full House'};
  if (isFlush) return {score:[5].concat(vals), name:'Flush'};
  if (isStraight) return {score:[4, highStraight], name:'Straight'};
  if (countPairs[0].count === 3) {
    const kickers = uniq.filter(v=>v!==countPairs[0].v).sort((a,b)=>b-a);
    return {score:[3, countPairs[0].v].concat(kickers), name:'Three of a Kind'};
  }
  if (countPairs[0].count === 2 && countPairs[1] && countPairs[1].count === 2) {
    const pairHigh = Math.max(countPairs[0].v, countPairs[1].v);
    const pairLow = Math.min(countPairs[0].v, countPairs[1].v);
    const kicker = uniq.filter(v=>v!==pairHigh && v!==pairLow)[0];
    return {score:[2, pairHigh, pairLow, kicker], name:'Two Pair'};
  }
  if (countPairs[0].count === 2) {
    const pair = countPairs[0].v;
    const kickers = uniq.filter(v=>v!==pair).sort((a,b)=>b-a);
    return {score:[1, pair].concat(kickers), name:'Pair'};
  }
  return {score:[0].concat(vals), name:'High Card'};
}

// compare two score arrays lexicographically
function compareScore(a,b) {
  for (let i=0;i<Math.max(a.length,b.length);i++){
    const va = a[i]||0; const vb = b[i]||0;
    if (va>vb) return 1;
    if (va<vb) return -1;
  }
  return 0;
}

// Given the hand entry, compute best 5-card hand from 7 cards
app.get('/api/best', (req, res) => {
  const id = req.query.id || req.session.handId;
  if (!id) return res.status(400).json({error:'missing id'});
  const entry = holeStore.get(id);
  if (!entry) return res.status(404).json({error:'not found'});
  if (entry.commRevealed < 5) return res.status(400).json({error:'community not fully revealed'});
  // build full 7-card array with origin mapping
  const all = [];
  for (let i=0;i<5;i++) all.push({card: entry.community[i], origin:'community', index:i});
  for (let i=0;i<2;i++) all.push({card: entry.hole[i], origin:'hole', index:i});
  // iterate all combinations of 5 indices from 0..6
  const n = all.length;
  let best = null;
  let bestInfo = null;
  function choose(indices) {
    const cards = indices.map(i=>all[i].card);
    const evald = evaluateFive(cards);
    if (!best || compareScore(evald.score, best.score) === 1) {
      best = evald;
      bestInfo = indices.map(i => all[i]);
    }
  }
  // generate combinations
  for (let a=0;a<n-4;a++) for (let b=a+1;b<n-3;b++) for (let c=b+1;c<n-2;c++) for (let d=c+1; d<n-1; d++) for (let e=d+1;e<n;e++) {
    choose([a,b,c,d,e]);
  }
  if (!best) return res.status(500).json({error:'could not evaluate hand'});
  // determine primary (core) cards within the best 5 (pairs/trips/quads/etc.)
  const rankCounts = {};
  for (const item of bestInfo) {
    const r = cardValue(item.card);
    rankCounts[r] = (rankCounts[r] || 0) + 1;
  }
  const category = best.score[0];
  // for high card, primary is the highest single card; for others, determine by counts/category rules
  let primaryRanks = new Set();
  if (category === 8 || category === 5 || category === 4 || category === 6) {
    // straight flush, flush, straight, full house -> all five primary
    bestInfo.forEach(i => primaryRanks.add(cardValue(i.card)));
  } else if (category === 7) {
    // four of a kind -> rank with count 4
    for (const [r,c] of Object.entries(rankCounts)) if (c == 4) primaryRanks.add(+r);
  } else if (category === 3) {
    // trips
    for (const [r,c] of Object.entries(rankCounts)) if (c == 3) primaryRanks.add(+r);
  } else if (category === 2) {
    // two pair -> ranks with count 2
    for (const [r,c] of Object.entries(rankCounts)) if (c == 2) primaryRanks.add(+r);
  } else if (category === 1) {
    // one pair
    for (const [r,c] of Object.entries(rankCounts)) if (c == 2) primaryRanks.add(+r);
  } else if (category === 0) {
    // high card -> highest single card
    const vals = bestInfo.map(i=>cardValue(i.card)).sort((a,b)=>b-a);
    if (vals.length) primaryRanks.add(vals[0]);
  }

  const out = bestInfo.map(i => {
    const rv = cardValue(i.card);
    return { origin: i.origin, index: i.index, card: i.card, primary: primaryRanks.has(rv) };
  });

  // return best hand info and mapping to origins with primary flag
  res.json({ name: best.name, score: best.score, cards: out });
});

app.get('/', (req, res) => {
  // draw 7 cards server-side: first 5 visible, last 2 are hole (face-down)
  // draw 7 cards server-side: first 5 visible are community placeholders (we'll treat as deck ordering)
  const full = getRandomHand(7);
  // Proper dealing from a shuffled deck: hole (2), burn1, flop(3), burn2, turn(1), burn3, river(1)
  const deck = dealFromDeck();
  const hole = deck.splice(0,2);
  // three secret shop cards
  const shop = deck.splice(0,3);
  const burn1 = deck.splice(0,1)[0];
  const flop = deck.splice(0,3);
  const burn2 = deck.splice(0,1)[0];
  const turn = deck.splice(0,1)[0];
  const burn3 = deck.splice(0,1)[0];
  const river = deck.splice(0,1)[0];
  const community = [].concat(flop, turn, river);
  // generate a simple hand id and store hole cards + community server-side until revealed
  const handId = Date.now().toString(36) + '-' + Math.random().toString(36).slice(2,8);
  // store remaining deck so we can draw replacement shop cards later
  holeStore.set(handId, { hole, shop, community, burns: [burn1, burn2, burn3], commRevealed: 0, createdAt: Date.now(), lastTradeReveal: -1, deck });
  // store hand id in session so subsequent API calls without id will use it
  req.session.handId = handId;
  // render EJS template with data (cards array and handId)
  const cards = []; // no visible community initially on the river area
  // hand will remain empty (no community shown until advance)
  res.render('index', { cards, handId });
});

app.listen(PORT, () => {
  console.log(`Server listening on http://localhost:${PORT}`);
});

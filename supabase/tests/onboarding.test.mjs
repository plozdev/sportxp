import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { PGlite } from '../../build/onboarding-sql-check/node_modules/@electric-sql/pglite/dist/index.js';
const db = new PGlite();
let checks = 0;
const id = '00000000-0000-0000-0000-000000000001';
await db.exec(`
  CREATE ROLE anon; CREATE ROLE authenticated; CREATE ROLE authenticator;
  CREATE SCHEMA auth;
  CREATE TABLE auth.users(id uuid PRIMARY KEY);
  CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS
    $$ SELECT nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
  CREATE FUNCTION auth.jwt() RETURNS jsonb LANGUAGE sql STABLE AS
    $$ SELECT '{"user_metadata":{"display_name":"Hoàng Nguyễn"}}'::jsonb $$;
  GRANT USAGE ON SCHEMA public,auth TO anon,authenticated;
  GRANT EXECUTE ON FUNCTION auth.uid(),auth.jwt() TO anon,authenticated;
  CREATE TABLE public.profiles (
    id uuid PRIMARY KEY REFERENCES auth.users(id), display_name text NOT NULL,
    elo_rating integer, tier_name text, trust_score integer NOT NULL DEFAULT 100,
    win_streak integer NOT NULL DEFAULT 0, onboarding_step integer NOT NULL DEFAULT 0);
`);
await db.exec(await readFile(new URL('../migrations/20261018_onboarding.sql', import.meta.url), 'utf8'));
// A migration may be reapplied without changing existing answers or ratings.
await db.exec(await readFile(new URL('../migrations/20261018_onboarding.sql', import.meta.url), 'utf8'));
const state = async () => (await db.query('select public.get_onboarding_state() as state')).rows[0].state;
const save = async (q,a) => (await db.query('select public.save_onboarding_answer($1,$2) as state',[q,a])).rows[0].state;
await db.exec(`SET ROLE anon`);
await assert.rejects(() => state()); checks++;
await db.exec(`RESET ROLE; INSERT INTO auth.users VALUES ('${id}'); SET request.jwt.claim.sub = '${id}'; SET ROLE authenticated`);
assert.equal((await state()).onboarding_step,0); checks++;
await assert.rejects(() => save(1,0)); checks++;
await assert.rejects(() => save(0,4)); checks++;
assert.equal((await save(0,3)).onboarding_step,1); checks++;
assert.deepEqual((await state()).answers,[3]); checks++;
assert.equal((await save(1,3)).onboarding_step,2); checks++;
// Revising Q1 clears Q2; a following session resumes with the right answer count.
assert.deepEqual((await save(0,2)).answers,[2]); checks++;
await save(0,3); await save(1,3);
await assert.rejects(() => save(2,3)); checks++;
await save(2,2); await save(3,3);
const done = await save(4,3);
assert.equal(done.onboarding_step,5); assert.equal(done.elo_rating,850); checks++;
assert.equal(done.tier_name,'Phong trào Khá'); checks++;
// Replaying the final save cannot reset Elo gained in real matches.
await db.exec('RESET ROLE');
await db.exec(`UPDATE public.profiles SET elo_rating = 1050 WHERE id = '${id}'`);
await db.exec('SET ROLE authenticated');
assert.equal((await save(4,3)).elo_rating,1050); checks++;
assert.equal((await state()).tier_name,'Bán chuyên / Thi đấu'); checks++;
await assert.rejects(() => save(0,0)); checks++;
// Even permissive legacy profile grants cannot bypass server-managed Elo.
await db.exec('RESET ROLE; GRANT SELECT,INSERT,UPDATE ON public.profiles TO authenticated; SET ROLE authenticated');
await assert.rejects(() => db.exec(`UPDATE public.profiles SET elo_rating=3000 WHERE id='${id}'`)); checks++;
await assert.rejects(() => db.exec(`UPDATE public.profiles SET onboarding_step=0 WHERE id='${id}'`)); checks++;
await assert.rejects(() => db.exec('SELECT * FROM public.onboarding_responses')); checks++;
await db.exec(`UPDATE public.profiles SET display_name='Minh' WHERE id='${id}'`);
assert.equal((await state()).display_name,'Minh'); checks++;
// Exhaustively compare SQL and Dart-spec scoring for every valid combination.
await db.exec('RESET ROLE');
const combinations = (await db.query(`select a,b,c,d,e from generate_series(0,3) a
  cross join generate_series(0,3) b cross join generate_series(0,2) c
  cross join generate_series(0,3) d cross join generate_series(0,3) e`)).rows;
for (let n = 0; n < combinations.length; n++) {
  const answers = Object.values(combinations[n]);
  const user = `00000000-0000-0000-0001-${String(n).padStart(12,'0')}`;
  await db.exec(`INSERT INTO auth.users VALUES('${user}'); SET request.jwt.claim.sub='${user}'; SET ROLE authenticated`);
  await state();
  let result;
  for(let q = 0; q < 5; q++) result = await save(q,answers[q]);
  const points = 300 + [0,50,120,200][answers[0]] + [0,60,100,150][answers[1]] +
    [0,100,150][answers[2]] + [0,50,100,130][answers[3]] + [0,50,100,150][answers[4]];
  assert.equal(result.elo_rating,Math.min(850,points));
  const expectedTier = points < 450 ? 'Nhập môn' : points < 600 ? 'Phong trào cơ bản' : points < 750 ? 'Phong trào Trung bình' : 'Phong trào Khá';
  assert.equal(result.tier_name,expectedTier);
  await db.exec('RESET ROLE');
}
console.log(`PASS: ${checks} authorization/progress checks and ${combinations.length} complete SQL scoring paths`);
await db.close();

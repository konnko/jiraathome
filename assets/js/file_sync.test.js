import {test} from "node:test"
import assert from "node:assert/strict"
import * as Y from "yjs"
import {FileSync} from "./file_sync.js"

function client(t, storage = new Map()) {
  const doc = new Y.Doc()
  const calls = []
  const sync = new FileSync({
    doc,
    request: (event, payload, reply) => calls.push({event, payload, reply}),
    storage: {
      getItem: key => storage.get(key),
      setItem: (key, value) => storage.set(key, value),
      removeItem: key => storage.delete(key)
    },
    status: () => {}, saved: () => {}
  })
  t.after(() => {sync.destroy(); doc.destroy()})
  sync.connect()
  calls.shift().reply({updates: []})
  return {doc, sync, calls, storage}
}

const saved = (call, sequence) => ({sequence, data: call.payload.data, author: "Анна", saved_at: "МСК"})
const apply = (doc, update) => Y.applyUpdate(doc, Buffer.from(update.data, "base64"))

test("one-second trailing debounce and only one batch in flight", t => {
  t.mock.timers.enable({apis: ["setTimeout", "Date"]})
  const {doc, calls} = client(t)
  doc.getText("test").insert(0, "А")
  t.mock.timers.tick(800)
  doc.getText("test").insert(1, "Б")
  t.mock.timers.tick(999)
  assert.equal(calls.length, 0)
  t.mock.timers.tick(1)
  assert.equal(calls.length, 1)
  const first = calls.shift()
  doc.getText("test").insert(2, "В")
  t.mock.timers.tick(1000)
  assert.equal(calls.length, 0)
  first.reply({ok: true, update: saved(first, 1)})
  t.mock.timers.tick(0)
  assert.equal(calls.length, 1)
  const replica = new Y.Doc()
  apply(replica, saved(first, 1))
  apply(replica, saved(calls[0], 2))
  assert.equal(replica.getText("test").toString(), "АБВ")
  replica.destroy()
})

test("simultaneous edits converge without replacing the other person's text", t => {
  t.mock.timers.enable({apis: ["setTimeout", "Date"]})
  const a = client(t)
  const b = client(t)
  a.doc.getText("test").insert(0, "Анна")
  b.doc.getText("test").insert(0, "Борис")
  t.mock.timers.tick(1000)
  const first = saved(a.calls[0], 1)
  const second = saved(b.calls[0], 2)
  for (const c of [a, b]) {
    c.sync.receive(first)
    c.sync.receive(second)
    c.calls[0].reply({ok: true, update: c === a ? first : second})
  }
  assert.equal(a.doc.getText("test").toString(), b.doc.getText("test").toString())
  assert.match(a.doc.getText("test").toString(), /Анна/)
  assert.match(a.doc.getText("test").toString(), /Борис/)
  t.mock.timers.tick(1000)
  assert.equal(a.calls.length, 1, "remote changes must not echo back")
})

test("reconnection resends the same unacknowledged batch and keeps offline edits", t => {
  t.mock.timers.enable({apis: ["setTimeout", "Date"]})
  const c = client(t)
  c.doc.getText("test").insert(0, "А")
  t.mock.timers.tick(1000)
  const unacknowledged = c.calls.shift()
  c.sync.disconnect()
  c.doc.getText("test").insert(1, "Б")
  t.mock.timers.tick(1500)
  assert.equal(c.calls.length, 0)
  c.sync.connect()
  c.calls.shift().reply({updates: [saved(unacknowledged, 1)]})
  const retry = c.calls.shift()
  assert.deepEqual(retry.payload, unacknowledged.payload)
  retry.reply({ok: true, update: saved(retry, 1)})
  t.mock.timers.tick(0)
  assert.equal(c.calls.length, 1)
  assert.equal(c.doc.getText("test").toString(), "АБ")
})

test("unsent changes survive a reload of the same tab", t => {
  t.mock.timers.enable({apis: ["setTimeout", "Date"]})
  const storage = new Map()
  const before = client(t, storage)
  before.doc.getText("test").insert(0, "Черновик")
  before.sync.destroy()
  const after = client(t, storage)
  assert.equal(after.doc.getText("test").toString(), "Черновик")
  t.mock.timers.tick(0)
  assert.equal(after.calls.length, 1)
  const call = after.calls[0]
  call.reply({ok: true, update: saved(call, 1)})
  assert.equal(storage.size, 0)
})

test("unsent drafts migrate from the old application name", t => {
  const doc = new Y.Doc()
  doc.getText("test").insert(0, "Старый черновик")
  const encoded = Buffer.from(Y.encodeStateAsUpdate(doc)).toString("base64")
  doc.destroy()
  const storage = new Map([["pochetasks:shared-file:pending", encoded]])
  const c = client(t, storage)
  assert.equal(c.doc.getText("test").toString(), "Старый черновик")
  assert.equal(storage.has("pochetasks:shared-file:pending"), false)
  assert.equal(storage.has("jiraathome:shared-file:pending"), true)
})

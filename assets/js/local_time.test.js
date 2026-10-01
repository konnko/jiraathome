import {test} from "node:test"
import assert from "node:assert/strict"
import {formatLocalTime} from "./local_time.js"

test("local dates cross midnight and follow daylight saving time", () => {
  assert.equal(formatLocalTime("2026-10-01T22:15:00Z", "Asia/Tbilisi"), "02.10.26, 02:15")
  assert.equal(formatLocalTime("2026-01-01T12:00:00Z", "America/New_York"), "01.01.26, 07:00")
  assert.equal(formatLocalTime("2026-07-01T12:00:00Z", "America/New_York"), "01.07.26, 08:00")
})

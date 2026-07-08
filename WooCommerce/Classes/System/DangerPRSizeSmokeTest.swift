/*
 * Smoke test for the Danger PR size `line_selector`.
 *
 * This file exists only to exercise the `line_selector:` passed to
 * `pr_size_checker.check_diff_size` in the Dangerfile. It adds well over the
 * 300-line threshold, yet almost every added line is a comment or blank line,
 * so the size the checker computes stays in the single digits and no warning
 * is reported.
 *
 * Delete this file before merging anything real.
 */

/*
 * How the checker counts lines
 * ----------------------------
 *
 * With no `line_selector`, dangermattic reads git numstats and every added or
 * removed line counts the same, whether it carries logic or not.
 *
 * With a `line_selector`, it walks the diff patches instead and calls the
 * selector with each changed line, stripped of its `+`/`-` marker. Only the
 * lines for which the selector returns true are counted.
 *
 * The Swift selector in the Dangerfile drops:
 *
 *   - blank lines
 *   - lines starting with the // line-comment marker
 *   - lines opening, continuing or closing a block comment
 *
 * Everything below is filler to push the raw diff far past 300 lines.
 */

// Filler line 001: not code, so the size checker skips it.
// Filler line 002: not code, so the size checker skips it.
// Filler line 003: not code, so the size checker skips it.
// Filler line 004: not code, so the size checker skips it.
// Filler line 005: not code, so the size checker skips it.
// Filler line 006: not code, so the size checker skips it.
// Filler line 007: not code, so the size checker skips it.
// Filler line 008: not code, so the size checker skips it.
// Filler line 009: not code, so the size checker skips it.
// Filler line 010: not code, so the size checker skips it.
// Filler line 011: not code, so the size checker skips it.
// Filler line 012: not code, so the size checker skips it.
// Filler line 013: not code, so the size checker skips it.
// Filler line 014: not code, so the size checker skips it.
// Filler line 015: not code, so the size checker skips it.
// Filler line 016: not code, so the size checker skips it.
// Filler line 017: not code, so the size checker skips it.
// Filler line 018: not code, so the size checker skips it.
// Filler line 019: not code, so the size checker skips it.

// --- Filler block 1 ---
// Filler line 021: not code, so the size checker skips it.
// Filler line 022: not code, so the size checker skips it.
// Filler line 023: not code, so the size checker skips it.
// Filler line 024: not code, so the size checker skips it.
// Filler line 025: not code, so the size checker skips it.
// Filler line 026: not code, so the size checker skips it.
// Filler line 027: not code, so the size checker skips it.
// Filler line 028: not code, so the size checker skips it.
// Filler line 029: not code, so the size checker skips it.
// Filler line 030: not code, so the size checker skips it.
// Filler line 031: not code, so the size checker skips it.
// Filler line 032: not code, so the size checker skips it.
// Filler line 033: not code, so the size checker skips it.
// Filler line 034: not code, so the size checker skips it.
// Filler line 035: not code, so the size checker skips it.
// Filler line 036: not code, so the size checker skips it.
// Filler line 037: not code, so the size checker skips it.
// Filler line 038: not code, so the size checker skips it.
// Filler line 039: not code, so the size checker skips it.

// --- Filler block 2 ---
// Filler line 041: not code, so the size checker skips it.
// Filler line 042: not code, so the size checker skips it.
// Filler line 043: not code, so the size checker skips it.
// Filler line 044: not code, so the size checker skips it.
// Filler line 045: not code, so the size checker skips it.
// Filler line 046: not code, so the size checker skips it.
// Filler line 047: not code, so the size checker skips it.
// Filler line 048: not code, so the size checker skips it.
// Filler line 049: not code, so the size checker skips it.
// Filler line 050: not code, so the size checker skips it.
// Filler line 051: not code, so the size checker skips it.
// Filler line 052: not code, so the size checker skips it.
// Filler line 053: not code, so the size checker skips it.
// Filler line 054: not code, so the size checker skips it.
// Filler line 055: not code, so the size checker skips it.
// Filler line 056: not code, so the size checker skips it.
// Filler line 057: not code, so the size checker skips it.
// Filler line 058: not code, so the size checker skips it.
// Filler line 059: not code, so the size checker skips it.

// --- Filler block 3 ---
// Filler line 061: not code, so the size checker skips it.
// Filler line 062: not code, so the size checker skips it.
// Filler line 063: not code, so the size checker skips it.
// Filler line 064: not code, so the size checker skips it.
// Filler line 065: not code, so the size checker skips it.
// Filler line 066: not code, so the size checker skips it.
// Filler line 067: not code, so the size checker skips it.
// Filler line 068: not code, so the size checker skips it.
// Filler line 069: not code, so the size checker skips it.
// Filler line 070: not code, so the size checker skips it.
// Filler line 071: not code, so the size checker skips it.
// Filler line 072: not code, so the size checker skips it.
// Filler line 073: not code, so the size checker skips it.
// Filler line 074: not code, so the size checker skips it.
// Filler line 075: not code, so the size checker skips it.
// Filler line 076: not code, so the size checker skips it.
// Filler line 077: not code, so the size checker skips it.
// Filler line 078: not code, so the size checker skips it.
// Filler line 079: not code, so the size checker skips it.

// --- Filler block 4 ---
// Filler line 081: not code, so the size checker skips it.
// Filler line 082: not code, so the size checker skips it.
// Filler line 083: not code, so the size checker skips it.
// Filler line 084: not code, so the size checker skips it.
// Filler line 085: not code, so the size checker skips it.
// Filler line 086: not code, so the size checker skips it.
// Filler line 087: not code, so the size checker skips it.
// Filler line 088: not code, so the size checker skips it.
// Filler line 089: not code, so the size checker skips it.
// Filler line 090: not code, so the size checker skips it.
// Filler line 091: not code, so the size checker skips it.
// Filler line 092: not code, so the size checker skips it.
// Filler line 093: not code, so the size checker skips it.
// Filler line 094: not code, so the size checker skips it.
// Filler line 095: not code, so the size checker skips it.
// Filler line 096: not code, so the size checker skips it.
// Filler line 097: not code, so the size checker skips it.
// Filler line 098: not code, so the size checker skips it.
// Filler line 099: not code, so the size checker skips it.

// --- Filler block 5 ---
// Filler line 101: not code, so the size checker skips it.
// Filler line 102: not code, so the size checker skips it.
// Filler line 103: not code, so the size checker skips it.
// Filler line 104: not code, so the size checker skips it.
// Filler line 105: not code, so the size checker skips it.
// Filler line 106: not code, so the size checker skips it.
// Filler line 107: not code, so the size checker skips it.
// Filler line 108: not code, so the size checker skips it.
// Filler line 109: not code, so the size checker skips it.
// Filler line 110: not code, so the size checker skips it.
// Filler line 111: not code, so the size checker skips it.
// Filler line 112: not code, so the size checker skips it.
// Filler line 113: not code, so the size checker skips it.
// Filler line 114: not code, so the size checker skips it.
// Filler line 115: not code, so the size checker skips it.
// Filler line 116: not code, so the size checker skips it.
// Filler line 117: not code, so the size checker skips it.
// Filler line 118: not code, so the size checker skips it.
// Filler line 119: not code, so the size checker skips it.

// --- Filler block 6 ---
// Filler line 121: not code, so the size checker skips it.
// Filler line 122: not code, so the size checker skips it.
// Filler line 123: not code, so the size checker skips it.
// Filler line 124: not code, so the size checker skips it.
// Filler line 125: not code, so the size checker skips it.
// Filler line 126: not code, so the size checker skips it.
// Filler line 127: not code, so the size checker skips it.
// Filler line 128: not code, so the size checker skips it.
// Filler line 129: not code, so the size checker skips it.
// Filler line 130: not code, so the size checker skips it.
// Filler line 131: not code, so the size checker skips it.
// Filler line 132: not code, so the size checker skips it.
// Filler line 133: not code, so the size checker skips it.
// Filler line 134: not code, so the size checker skips it.
// Filler line 135: not code, so the size checker skips it.
// Filler line 136: not code, so the size checker skips it.
// Filler line 137: not code, so the size checker skips it.
// Filler line 138: not code, so the size checker skips it.
// Filler line 139: not code, so the size checker skips it.

// --- Filler block 7 ---
// Filler line 141: not code, so the size checker skips it.
// Filler line 142: not code, so the size checker skips it.
// Filler line 143: not code, so the size checker skips it.
// Filler line 144: not code, so the size checker skips it.
// Filler line 145: not code, so the size checker skips it.
// Filler line 146: not code, so the size checker skips it.
// Filler line 147: not code, so the size checker skips it.
// Filler line 148: not code, so the size checker skips it.
// Filler line 149: not code, so the size checker skips it.
// Filler line 150: not code, so the size checker skips it.
// Filler line 151: not code, so the size checker skips it.
// Filler line 152: not code, so the size checker skips it.
// Filler line 153: not code, so the size checker skips it.
// Filler line 154: not code, so the size checker skips it.
// Filler line 155: not code, so the size checker skips it.
// Filler line 156: not code, so the size checker skips it.
// Filler line 157: not code, so the size checker skips it.
// Filler line 158: not code, so the size checker skips it.
// Filler line 159: not code, so the size checker skips it.

// --- Filler block 8 ---
// Filler line 161: not code, so the size checker skips it.
// Filler line 162: not code, so the size checker skips it.
// Filler line 163: not code, so the size checker skips it.
// Filler line 164: not code, so the size checker skips it.
// Filler line 165: not code, so the size checker skips it.
// Filler line 166: not code, so the size checker skips it.
// Filler line 167: not code, so the size checker skips it.
// Filler line 168: not code, so the size checker skips it.
// Filler line 169: not code, so the size checker skips it.
// Filler line 170: not code, so the size checker skips it.
// Filler line 171: not code, so the size checker skips it.
// Filler line 172: not code, so the size checker skips it.
// Filler line 173: not code, so the size checker skips it.
// Filler line 174: not code, so the size checker skips it.
// Filler line 175: not code, so the size checker skips it.
// Filler line 176: not code, so the size checker skips it.
// Filler line 177: not code, so the size checker skips it.
// Filler line 178: not code, so the size checker skips it.
// Filler line 179: not code, so the size checker skips it.

// --- Filler block 9 ---
// Filler line 181: not code, so the size checker skips it.
// Filler line 182: not code, so the size checker skips it.
// Filler line 183: not code, so the size checker skips it.
// Filler line 184: not code, so the size checker skips it.
// Filler line 185: not code, so the size checker skips it.
// Filler line 186: not code, so the size checker skips it.
// Filler line 187: not code, so the size checker skips it.
// Filler line 188: not code, so the size checker skips it.
// Filler line 189: not code, so the size checker skips it.
// Filler line 190: not code, so the size checker skips it.
// Filler line 191: not code, so the size checker skips it.
// Filler line 192: not code, so the size checker skips it.
// Filler line 193: not code, so the size checker skips it.
// Filler line 194: not code, so the size checker skips it.
// Filler line 195: not code, so the size checker skips it.
// Filler line 196: not code, so the size checker skips it.
// Filler line 197: not code, so the size checker skips it.
// Filler line 198: not code, so the size checker skips it.
// Filler line 199: not code, so the size checker skips it.

// --- Filler block 10 ---
// Filler line 201: not code, so the size checker skips it.
// Filler line 202: not code, so the size checker skips it.
// Filler line 203: not code, so the size checker skips it.
// Filler line 204: not code, so the size checker skips it.
// Filler line 205: not code, so the size checker skips it.
// Filler line 206: not code, so the size checker skips it.
// Filler line 207: not code, so the size checker skips it.
// Filler line 208: not code, so the size checker skips it.
// Filler line 209: not code, so the size checker skips it.
// Filler line 210: not code, so the size checker skips it.
// Filler line 211: not code, so the size checker skips it.
// Filler line 212: not code, so the size checker skips it.
// Filler line 213: not code, so the size checker skips it.
// Filler line 214: not code, so the size checker skips it.
// Filler line 215: not code, so the size checker skips it.
// Filler line 216: not code, so the size checker skips it.
// Filler line 217: not code, so the size checker skips it.
// Filler line 218: not code, so the size checker skips it.
// Filler line 219: not code, so the size checker skips it.

// --- Filler block 11 ---
// Filler line 221: not code, so the size checker skips it.
// Filler line 222: not code, so the size checker skips it.
// Filler line 223: not code, so the size checker skips it.
// Filler line 224: not code, so the size checker skips it.
// Filler line 225: not code, so the size checker skips it.
// Filler line 226: not code, so the size checker skips it.
// Filler line 227: not code, so the size checker skips it.
// Filler line 228: not code, so the size checker skips it.
// Filler line 229: not code, so the size checker skips it.
// Filler line 230: not code, so the size checker skips it.
// Filler line 231: not code, so the size checker skips it.
// Filler line 232: not code, so the size checker skips it.
// Filler line 233: not code, so the size checker skips it.
// Filler line 234: not code, so the size checker skips it.
// Filler line 235: not code, so the size checker skips it.
// Filler line 236: not code, so the size checker skips it.
// Filler line 237: not code, so the size checker skips it.
// Filler line 238: not code, so the size checker skips it.
// Filler line 239: not code, so the size checker skips it.

// --- Filler block 12 ---
// Filler line 241: not code, so the size checker skips it.
// Filler line 242: not code, so the size checker skips it.
// Filler line 243: not code, so the size checker skips it.
// Filler line 244: not code, so the size checker skips it.
// Filler line 245: not code, so the size checker skips it.
// Filler line 246: not code, so the size checker skips it.
// Filler line 247: not code, so the size checker skips it.
// Filler line 248: not code, so the size checker skips it.
// Filler line 249: not code, so the size checker skips it.
// Filler line 250: not code, so the size checker skips it.
// Filler line 251: not code, so the size checker skips it.
// Filler line 252: not code, so the size checker skips it.
// Filler line 253: not code, so the size checker skips it.
// Filler line 254: not code, so the size checker skips it.
// Filler line 255: not code, so the size checker skips it.
// Filler line 256: not code, so the size checker skips it.
// Filler line 257: not code, so the size checker skips it.
// Filler line 258: not code, so the size checker skips it.
// Filler line 259: not code, so the size checker skips it.

// --- Filler block 13 ---
// Filler line 261: not code, so the size checker skips it.
// Filler line 262: not code, so the size checker skips it.
// Filler line 263: not code, so the size checker skips it.
// Filler line 264: not code, so the size checker skips it.
// Filler line 265: not code, so the size checker skips it.
// Filler line 266: not code, so the size checker skips it.
// Filler line 267: not code, so the size checker skips it.
// Filler line 268: not code, so the size checker skips it.
// Filler line 269: not code, so the size checker skips it.
// Filler line 270: not code, so the size checker skips it.
// Filler line 271: not code, so the size checker skips it.
// Filler line 272: not code, so the size checker skips it.
// Filler line 273: not code, so the size checker skips it.
// Filler line 274: not code, so the size checker skips it.
// Filler line 275: not code, so the size checker skips it.
// Filler line 276: not code, so the size checker skips it.
// Filler line 277: not code, so the size checker skips it.
// Filler line 278: not code, so the size checker skips it.
// Filler line 279: not code, so the size checker skips it.

// --- Filler block 14 ---
// Filler line 281: not code, so the size checker skips it.
// Filler line 282: not code, so the size checker skips it.
// Filler line 283: not code, so the size checker skips it.
// Filler line 284: not code, so the size checker skips it.
// Filler line 285: not code, so the size checker skips it.
// Filler line 286: not code, so the size checker skips it.
// Filler line 287: not code, so the size checker skips it.
// Filler line 288: not code, so the size checker skips it.
// Filler line 289: not code, so the size checker skips it.
// Filler line 290: not code, so the size checker skips it.
// Filler line 291: not code, so the size checker skips it.
// Filler line 292: not code, so the size checker skips it.
// Filler line 293: not code, so the size checker skips it.
// Filler line 294: not code, so the size checker skips it.
// Filler line 295: not code, so the size checker skips it.
// Filler line 296: not code, so the size checker skips it.
// Filler line 297: not code, so the size checker skips it.
// Filler line 298: not code, so the size checker skips it.
// Filler line 299: not code, so the size checker skips it.

// --- Filler block 15 ---
// Filler line 301: not code, so the size checker skips it.
// Filler line 302: not code, so the size checker skips it.
// Filler line 303: not code, so the size checker skips it.
// Filler line 304: not code, so the size checker skips it.
// Filler line 305: not code, so the size checker skips it.
// Filler line 306: not code, so the size checker skips it.
// Filler line 307: not code, so the size checker skips it.
// Filler line 308: not code, so the size checker skips it.
// Filler line 309: not code, so the size checker skips it.
// Filler line 310: not code, so the size checker skips it.
// Filler line 311: not code, so the size checker skips it.
// Filler line 312: not code, so the size checker skips it.
// Filler line 313: not code, so the size checker skips it.
// Filler line 314: not code, so the size checker skips it.
// Filler line 315: not code, so the size checker skips it.
// Filler line 316: not code, so the size checker skips it.
// Filler line 317: not code, so the size checker skips it.
// Filler line 318: not code, so the size checker skips it.
// Filler line 319: not code, so the size checker skips it.

// --- Filler block 16 ---
// Filler line 321: not code, so the size checker skips it.
// Filler line 322: not code, so the size checker skips it.
// Filler line 323: not code, so the size checker skips it.
// Filler line 324: not code, so the size checker skips it.
// Filler line 325: not code, so the size checker skips it.
// Filler line 326: not code, so the size checker skips it.
// Filler line 327: not code, so the size checker skips it.
// Filler line 328: not code, so the size checker skips it.
// Filler line 329: not code, so the size checker skips it.
// Filler line 330: not code, so the size checker skips it.
// Filler line 331: not code, so the size checker skips it.
// Filler line 332: not code, so the size checker skips it.
// Filler line 333: not code, so the size checker skips it.
// Filler line 334: not code, so the size checker skips it.
// Filler line 335: not code, so the size checker skips it.
// Filler line 336: not code, so the size checker skips it.
// Filler line 337: not code, so the size checker skips it.
// Filler line 338: not code, so the size checker skips it.
// Filler line 339: not code, so the size checker skips it.

// --- Filler block 17 ---
// Filler line 341: not code, so the size checker skips it.
// Filler line 342: not code, so the size checker skips it.
// Filler line 343: not code, so the size checker skips it.
// Filler line 344: not code, so the size checker skips it.
// Filler line 345: not code, so the size checker skips it.
// Filler line 346: not code, so the size checker skips it.
// Filler line 347: not code, so the size checker skips it.
// Filler line 348: not code, so the size checker skips it.
// Filler line 349: not code, so the size checker skips it.
// Filler line 350: not code, so the size checker skips it.
// Filler line 351: not code, so the size checker skips it.
// Filler line 352: not code, so the size checker skips it.
// Filler line 353: not code, so the size checker skips it.
// Filler line 354: not code, so the size checker skips it.
// Filler line 355: not code, so the size checker skips it.
// Filler line 356: not code, so the size checker skips it.
// Filler line 357: not code, so the size checker skips it.
// Filler line 358: not code, so the size checker skips it.
// Filler line 359: not code, so the size checker skips it.

// --- Filler block 18 ---
// Filler line 361: not code, so the size checker skips it.
// Filler line 362: not code, so the size checker skips it.
// Filler line 363: not code, so the size checker skips it.
// Filler line 364: not code, so the size checker skips it.
// Filler line 365: not code, so the size checker skips it.
// Filler line 366: not code, so the size checker skips it.
// Filler line 367: not code, so the size checker skips it.
// Filler line 368: not code, so the size checker skips it.
// Filler line 369: not code, so the size checker skips it.
// Filler line 370: not code, so the size checker skips it.
// Filler line 371: not code, so the size checker skips it.
// Filler line 372: not code, so the size checker skips it.
// Filler line 373: not code, so the size checker skips it.
// Filler line 374: not code, so the size checker skips it.
// Filler line 375: not code, so the size checker skips it.
// Filler line 376: not code, so the size checker skips it.
// Filler line 377: not code, so the size checker skips it.
// Filler line 378: not code, so the size checker skips it.
// Filler line 379: not code, so the size checker skips it.

// --- Filler block 19 ---
// Filler line 381: not code, so the size checker skips it.
// Filler line 382: not code, so the size checker skips it.
// Filler line 383: not code, so the size checker skips it.
// Filler line 384: not code, so the size checker skips it.
// Filler line 385: not code, so the size checker skips it.
// Filler line 386: not code, so the size checker skips it.
// Filler line 387: not code, so the size checker skips it.
// Filler line 388: not code, so the size checker skips it.
// Filler line 389: not code, so the size checker skips it.
// Filler line 390: not code, so the size checker skips it.
// Filler line 391: not code, so the size checker skips it.
// Filler line 392: not code, so the size checker skips it.
// Filler line 393: not code, so the size checker skips it.
// Filler line 394: not code, so the size checker skips it.
// Filler line 395: not code, so the size checker skips it.
// Filler line 396: not code, so the size checker skips it.
// Filler line 397: not code, so the size checker skips it.
// Filler line 398: not code, so the size checker skips it.
// Filler line 399: not code, so the size checker skips it.

// --- Filler block 20 ---

enum DangerPRSizeSmokeTest {
    static let countedLines = 3
}


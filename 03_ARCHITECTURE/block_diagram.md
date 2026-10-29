# G03 · Sơ đồ khối bên trong (Block Diagram)

Vẽ theo **đúng 60 dòng** của `04_IMPLEMENTATION/rtl/g03_median3.sv`; mọi số cell lấy từ
`06_GDSII/synthesis/synth_stat.txt` và `netlist.v`.

---

## 1. Sơ đồ khối

```
  sample_in[7:0] ──────────────────────────────────────────────┬──────────┐
       │                                                        │          │
       │                                                        │ c        │
       ▼                                                        │          │
  ╔═══════════════════════════════════════╗                     │          │
  ║  THANH GHI DICH 2 TANG (cua so)       ║                     │          │
  ║                                        ║                     │          │
  ║   ╔═══════════╗      ╔═══════════╗    ║                     │          │
  ║   ║ hist0_q   ║◀─────║ hist1_q   ║◀───╫─────────────────────┘          │
  ║   ║  8 FF     ║      ║  8 FF     ║    ║   (nap sample_in moi chu ky     │
  ║   ╚═════╤═════╝      ╚═════╤═════╝    ║    co valid_in = 1)             │
  ╚═════════╪══════════════════╪══════════╝                                 │
            │ a = s(k-2)       │ b = s(k-1)                                 │ c = s(k)
            │                  │                                            │
            ▼                  ▼                                            │
  ┌─────────────────────────────────────────────────────────────────────────┴──────┐
  │  MANG SAP XEP 3 PHAN TU  (to hop thuan tuy — 0 flip-flop)                       │
  │                                                                                 │
  │   a ──┬────────────────┐                                                        │
  │       │   ┌────────┐   │                                                        │
  │       ├──▶│  CMP1  │   │  lt1 = (a <= b)                                        │
  │   b ──┼──▶│ a <= b │───┼──┬─────────────┐                                       │
  │       │   └────────┘   │  │             │                                       │
  │       │                ▼  ▼             ▼                                       │
  │       │           ┌────────┐       ┌────────┐                                   │
  │       └──────────▶│ MUX lo1│       │ MUX hi1│◀──────── b                        │
  │   b ─────────────▶│ min(a,b)       │ max(a,b)                                   │
  │                   └───┬────┘       └───┬────┘                                   │
  │                       │ lo1            │ hi1                                    │
  │                       │                ├──────────────┐                         │
  │                       │                │   ┌────────┐ │                         │
  │                       │                ├──▶│  CMP2  │ │  lt2 = (hi1 <= c)       │
  │                       │            c ──┼──▶│hi1 <= c│─┼──┬──────┐               │
  │                       │                │   └────────┘ │  │      │               │
  │                       │                ▼              ▼  ▼      ▼               │
  │                       │           ┌────────┐      ┌─────────┐   │               │
  │                       │           │ MUX lo2│      │ MUX hi2 │   │ (MA CHET —    │
  │                       │      c ──▶│min(hi1,c)     │max(hi1,c)   │  bi Yosys bo) │
  │                       │           └───┬────┘      └─────────┘   │               │
  │                       │               │ lo2                                     │
  │                       │               │                                         │
  │                       ├───────────────┼──┐                                      │
  │                       │   ┌────────┐  │  │                                      │
  │                       ├──▶│  CMP3  │  │  │  lt3 = (lo1 <= lo2)                  │
  │                       │   │lo1<=lo2│──┼──┼──┬──────────┐                        │
  │                       │   └────────┘  │  │  │          │                        │
  │                       ▼               ▼  ▼  ▼          ▼                        │
  │                  ┌─────────┐       ┌──────────┐   ┌─────────┐                   │
  │                  │ MUX lo3 │       │ MUX med3 │   │         │ (MA CHET —        │
  │                  │min(...) │       │ max(...) │   │         │  bi Yosys bo)     │
  │                  └─────────┘       └────┬─────┘                                 │
  └─────────────────────────────────────────┼───────────────────────────────────────┘
                                             │ med3[7:0]
   ╔═══════════════╗   count_q >= 1 ?        │
   ║ count_q  2 FF ║───────────┬─────────────┤
   ║ +1 bao hoa 2  ║           │             ▼
   ╚═══════════════╝           │      ╔═════════════╗
                               │      ║ median_out  ║──▶ median_out[7:0]
                               │      ║    8 FF     ║
                               │      ╚═════════════╝
                               ▼
                        ╔═════════════╗
                        ║ valid_out   ║──▶ valid_out
                        ║    1 FF     ║
                        ╚═════════════╝
                  🔴 dieu kien dung phai la count_q >= 2 (xem known_issues.md)
```

## 2. Bảng ánh xạ cấu trúc RTL → phần cứng sinh ra

| Dòng RTL | Cấu trúc RTL | Phần cứng sinh ra | Bằng chứng trong netlist |
|---|---|---|---|
| 12 | `logic [W-1:0] hist0_q` | **8 `dfxtp_1`** | `Q(\a[0..7])` — Yosys đổi tên vì `assign a = hist0_q` là bí danh thuần |
| 13 | `logic [W-1:0] hist1_q` | **8 `dfxtp_1`** | `Q(\b[0..7])` — tương tự |
| 14 | `logic [1:0] count_q` | **2 `dfxtp_1`** | `Q(\count_q[0..1])` |
| 20–21 | `CE1`: `lo1`/`hi1` | 1 bộ so sánh 8 bit + 2 mux 8 bit | chuỗi `maj3_1` (mượn) + `mux2i_1` |
| 24–25 | `CE2`: `lo2`/**`hi2`** | 1 bộ so sánh + **1** mux (`hi2` bị loại) | như trên |
| 28–29 | `CE3`: **`lo3`**/`med3` | 1 bộ so sánh + **1** mux (`lo3` bị loại) | như trên |
| 31–33 | `assign a/b/c` | **0 cell** — bí danh thuần | tên `hist0_q`/`hist1_q` biến mất khỏi netlist |
| 35 | `always_ff @(posedge clk)` | Cả 27 FF là `dfxtp_1` ⟹ reset **đồng bộ** | không có `dfrtp_1` nào |
| 46–47 | `hist0_q <= hist1_q; hist1_q <= sample_in;` | **Thanh ghi dịch 2 tầng**, mỗi FF có mux giữ/nạp | `mux2i_1`, `nand2_1`, `lpflow_*` |
| 49–50 | `count_q <= count_q + 1` (bão hoà 2) | Bộ tăng 2 bit + chặn | `and2_0`, `o21a_1`, `nor2_1` |
| 52 | `if (count_q >= 2'd1)` | So sánh hằng — **1 cổng** (chỉ cần `count_q[1] | count_q[0]`) | 🔴 đúng phải là `count_q[1]` (1 dây, **0 cổng**) |
| 53–54 | Nạp `valid_out`, `median_out` | Enable của 9 FF đầu ra | `lpflow_inputiso1p_1`, `a21o_1` |

### Kiểm chứng số flip-flop

```
   8 (hist0_q -> 'a')  +  8 (hist1_q -> 'b')  +  2 (count_q)
+  8 (median_out)      +  1 (valid_out)                        = 27 FF
```

`synth_stat.txt` ghi `sky130_fd_sc_hd__dfxtp_1  27`. **Khớp chính xác — không dư, không thiếu.**

> Đối chiếu Charter mục 10: *"Dấu hiệu làm đúng: **16 ô nhớ** (2 mẫu trước) + mạng sắp xếp
> tổ hợp."* Thực tế: **16 FF đúng cho hai mẫu trước** ✅, cộng thêm 8 FF cho thanh ghi đầu ra,
> 2 cho bộ đếm, 1 cho `valid_out`. Charter chỉ đếm phần lưu cửa sổ. Và phần *"mạng sắp xếp
> **tổ hợp**"* cũng đúng: mạng có **0 flip-flop** — `median_out` là thanh ghi **đầu ra**,
> nằm **sau** mạng, không nằm trong nó.

## 3. Đếm bộ so sánh và bộ ghép kênh — trả lời Charter mục 2 câu 1

> *"Mạng sắp xếp ba phần tử gồm mấy bộ so sánh và mấy bộ ghép kênh?"*

Câu này có **hai đáp án đúng**, và biết cả hai mới là hiểu vấn đề:

| Cách đếm | Bộ so sánh | Bộ ghép kênh (8 bit) | Ghi chú |
|---|---:|---:|---|
| **Theo mã RTL viết ra** | **3** | **6** | Mỗi CE sinh cả `min` lẫn `max` |
| **Theo logic thật sự sống** | **3** | **4** | `hi2` và `lo3` **không bao giờ được đọc** ⟹ Yosys loại bỏ |

```
   CE1: lt1 = (a <= b)        -> MUX lo1  ✅ song  |  MUX hi1  ✅ song
   CE2: lt2 = (hi1 <= c)      -> MUX lo2  ✅ song  |  MUX hi2  ❌ CHET
   CE3: lt3 = (lo1 <= lo2)    -> MUX lo3  ❌ CHET  |  MUX med3 ✅ song
   ─────────────────────────────────────────────────────────────────
   TONG: 3 bo so sanh  ·  6 mux viet ra  ·  4 mux song
```

**Bằng chứng từ netlist:** `mux2i_1 × 18`. Bốn mux 8 bit "đầy đủ" cần 32 cell mux; chỉ có 18
vì ABC đã **gộp** phần lớn logic mux vào các cell phức hợp (`a21oi_1` ×18, `a21o_1` ×7,
`o21a_1` ×7, `a21boi_0` ×7, `nand2_1` ×21…). Đây là lý do **không đếm mux bằng cách đếm cell
`mux*`** — phải đếm từ RTL rồi đối chiếu tổng diện tích.

Charter mục 10 ghi: *"Mạng 3 phần tử = 3 bộ so sánh."* ✅ **Khớp.**

## 4. Bộ so sánh 8 bit được hiện thực như thế nào — nguồn gốc của `maj3_1`

`(a <= b)` trên 8 bit **không** phải một cổng. Nó là một **phép trừ có mượn**: `b − a` và lấy
bit mượn cuối. Chuỗi mượn giống hệt chuỗi carry của bộ cộng:

```
   borrow[0] = 0
   borrow[i+1] = maj( ~a[i], b[i], borrow[i] )     <- chinh la cell maj3_1
   (a <= b)  <=>  borrow[8] = 0
                   ^^^^^^^^^ phai doi HET 8 tang moi biet
```

`synth_stat.txt`: `maj3_1 × 15`. Ba bộ so sánh 8 bit về lý thuyết cần ~21 tầng; ABC rút xuống
15 bằng cách chia sẻ và gộp logic. **Toàn bộ 15 cell này là tim của G03** — chúng chiếm
15/189 = 7,9 % số cell nhưng **100 % đường tới hạn** (§6).

> 💡 Đây là mấu chốt để hiểu vì sao G03 chậm: mỗi compare-exchange **không** rẻ như trực giác
> ("chỉ là một phép so sánh") — nó là một **chuỗi nối tiếp 8 tầng**, và mạng có **ba** chuỗi
> như vậy **mắc nối tiếp nhau**.

## 5. Thanh ghi dịch, không phải bộ đệm vòng

Khác hẳn G01/G02 (bộ đệm vòng + con trỏ + cây mux đọc), G03 dùng **thanh ghi dịch**:

```systemverilog
46                hist0_q <= hist1_q;
47                hist1_q <= sample_in;
```

| Tiêu chí | Thanh ghi dịch (G03) | Bộ đệm vòng (G02) |
|---|---|---|
| Cần con trỏ? | ❌ **không** | ✅ `wr_ptr` 3 FF |
| Cần cây mux đọc? | ❌ **không** | ✅ 24 cell |
| Cần mux giữ/nạp mỗi FF? | ✅ (do `valid_in` gating) | ✅ |
| Hoạt động chuyển mạch | **Cao** — mọi mẫu dịch mỗi chu kỳ | Thấp — chỉ 1 từ bị ghi |
| Điểm hoà vốn | Tốt khi `N` **nhỏ** (2–4) | Tốt khi `N` **lớn** |

Với `N = 3` (chỉ cần nhớ 2 mẫu), thanh ghi dịch là lựa chọn **rõ ràng đúng**: nó tiết kiệm
toàn bộ hạ tầng địa chỉ. Đó là lý do G03 chỉ có **27 FF** so với 94 của G02.

## 6. Khối con nào nằm trên đường tới hạn

Đường tới hạn thật (`06_GDSII/sta/timing_report_max.txt`, arrival **7,82 ns**, slack **2,10 ns**):

```
  b[0] (= hist1_q[0], BIT THAP NHAT)
    ▶ _179_ lpflow_isobufsrc_1
    ▶ _180_ _181_ _182_ _183_ _184_ _185_   maj3_1  x6     <- CHUOI MUON cua CMP1
    ▶ _186_ o21a_1   (fanout 27!)                          <- ket qua lt1 = (a<=b)
    ▶ _205_ mux2i_1                                        <- MUX hi1
    ▶ _209_ _210_   maj3_1  x2                             <- CHUOI MUON cua CMP2
    ▶ _212_ o21ai_0 ▶ _213_ a21oi_1 ▶ _214_ o22ai_1
    ▶ _216_ a21o_1   (fanout 13)                           <- ket qua lt2 = (hi1<=c)
    ▶ _243_ a211oi_1
    ▶ _244_ … _250_  maj3_1  x7                            <- CHUOI MUON cua CMP3
    ▶ _256_ lpflow_inputiso1p_1 ▶ _257_ a21o_1 ▶ _258_ a21boi_0
    ▶ _326_/D  =  median_out[1]

  TONG: 28 cell, trong do 6+2+7 = 15 cell maj3_1
```

| Khối con | Trên đường tới hạn? | Bằng chứng |
|---|:-:|---|
| **CMP1** (`a <= b`) | ✅ **toàn bộ chuỗi mượn** | 6 `maj3` + `o21a` (`_186_`, fanout 27) |
| **MUX hi1** | ✅ | `_205_ mux2i_1` |
| **CMP2** (`hi1 <= c`) | ✅ | 2 `maj3` + 4 cổng kết (`_216_`, fanout 13) |
| **CMP3** (`lo1 <= lo2`) | ✅ **toàn bộ chuỗi mượn** | 7 `maj3` |
| **MUX med3** | ✅ | `_257_ a21o_1`, `_258_ a21boi_0` |
| Thanh ghi `hist1_q` (`b`) | ✅ là **startpoint** | `_341_` có `.Q(\b[0])` |
| `median_out[1]` | ✅ là **endpoint** | `_326_` |
| `count_q`, `valid_out` | ❌ | Đường phụ, arrival chỉ **1,22 ns** (đường thứ hai trong báo cáo: `valid_in → _324_`) |
| `hist0_q` (`a`) | ❌ ở startpoint này | Đường từ `a` ngắn hơn vì `a` chỉ vào CMP1 và CE3 |

> ⭐ **Phát hiện có thể kiểm chứng ngay: cả 15 cell `maj3_1` của thiết kế đều nằm trên MỘT
> đường.** Đếm `maj3_1` trong `synth_stat.txt` = **15**; đếm `maj3_1` trong danh sách cell
> của đường tới hạn = **6 + 2 + 7 = 15**. Không một `maj3` nào nằm ngoài. Điều đó nói lên:
> **G03 không có đường phụ nào đáng kể — toàn bộ độ trễ tập trung vào một chuỗi so sánh
> duy nhất.** Đây là chân dung kinh điển của một mạng sắp xếp: sâu và hẹp.

### Dự đoán từ RTL vs STA

| Điểm | Dự đoán khi đọc RTL | STA thật | Lệch? |
|---|---|---|---|
| Đường tới hạn đi qua **cả 3 CE nối tiếp** | ✅ có | ✅ đúng | Không |
| Startpoint là một trong hai thanh ghi cửa sổ | ✅ | `b[0]` = `hist1_q[0]` | Không |
| Vì sao là **bit 0** chứ không phải bit 7? | — | Bit thấp nhất ⟹ **chuỗi mượn dài nhất** | Hợp lý |
| Độ sâu ≈ 3 × 8 = 24 tầng mượn | — | **15** `maj3` | ABC rút gọn ~37 % |
| Endpoint là `median_out[?]` | ✅ | `median_out[1]` | Không |

Ở G03, dự đoán từ RTL **khớp về cấu trúc** — khác hẳn G02, nơi ABC đổi hẳn thuật toán cộng.
Lý do: mạng sắp xếp **không có** biến thể thuật toán nào rẻ hơn cho công cụ khai thác;
so sánh 8 bit buộc phải đợi hết chuỗi mượn.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-G03-003, Charter mục 2 câu 1.*

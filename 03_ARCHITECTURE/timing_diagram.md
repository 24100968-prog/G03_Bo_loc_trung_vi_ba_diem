# G03 · Giản đồ thời gian (Timing Diagram)

---

## 0. Giản đồ này lấy ở đâu ra

G03 là mạch **tuần tự**, nên đây là **giản đồ dạng sóng theo chu kỳ clock**.

Giản đồ được **suy từng chu kỳ từ RTL thật** (`g03_median3.sv`, dòng 20–58) theo **đúng chuỗi
kích thích** của `05_VERIFICATION/testbench/g03_tb.sv` (dòng 32–64). Mô phỏng thật **dừng ở
chu kỳ C4** (`simulation.log`: `Time: 36`), nên từ C5 trở đi là **dự đoán từ mã** — và dự
đoán đó chỉ ra rằng **toàn bộ phần còn lại của testbench sẽ PASS** nếu sửa một ký tự.

> ❗ Mọi dạng sóng ở đây là mô phỏng **hành vi (zero-delay)**: tín hiệu đổi **ngay** tại cạnh
> clock, độ trễ cổng = 0. Nó **không** minh hoạ độ trễ thật. Độ trễ thật của đường xấu nhất
> sau tổng hợp là **7,82 ns** (`sta/timing_report_max.txt`) — tức chiếm **78 %** chu kỳ giả
> định 10 ns — và còn tăng sau routing.

**Quy ước thời gian.** `always #5 clk = ~clk`, `clk = 0` tại `t = 0` ⟹ chu kỳ **10 ns**, cạnh
lên tại `t = 5, 15, 25, …`. Testbench kiểm kết quả tại `#1` **sau** mỗi cạnh.

---

## 1. Giao dịch điển hình — đúng chuỗi của testbench

```
 chu ky      C1   C2 │ C3   C4 │ C5   C6   C7   C8 │ C9   C10  C11 │C12 │C13  C14  C15
 t (ns)       5   15 │ 25   35 │ 45   55   65   75 │ 85   95   105 │115 │125  135  145
           ┌─┐  ┌─┐  │┌─┐  ┌─┐ │┌─┐  ┌─┐  ┌─┐  ┌─┐ │┌─┐  ┌─┐  ┌─┐  │┌─┐ │┌─┐  ┌─┐  ┌─┐
 clk    ───┘ └──┘ └──┘│ └──┘ └─┘│ └──┘ └──┘ └──┘ └─┘│ └──┘ └──┘ └──┘│ └──┘│ └──┘ └──┘ └──
                      │         │                   │               │    │
 ────────────── GIA TRI CO TAI CANH LEN (dau vao) ─────────────────────────────────────
 rst_n       0    0   │  1    1 │  1    1    1    1 │  1    1    1  │ 1  │  1    1    1
 valid_in    0    0   │  1    1 │  1    1    1    1 │  1    1    1  │ 0  │  1    1    1
 sample_in  00   00   │ 10   11 │250    3    1    2 │  2    9    2  │ 2  │  0  255  128
                      │         │                   │               │    │
 ═════════ GIA TRI SAU CANH LEN (doc tu RTL dong 42-56) ══════════════════════════════
 count_q     0    0   │  1    2 │  2    2    2    2 │  2    2    2  │ 2  │  2    2    2
 hist0_q (a) 0    0   │  0   10 │ 11  250    3    1 │  2    2    9  │ 9  │  2    0  255
 hist1_q (b) 0    0   │ 10   11 │250    3    1    2 │  2    9    2  │ 2  │  0  255  128
 valid_out   0    0   │  0    1 │  1    1    1    1 │  1    1    1  │ 0  │  1    1    1
 median_out  0    0   │  0   10 │ 11   11    3    2 │  2    2    2  │ 2  │  2    2  128
 ──────────────────────────────────────────────────────────────────────────────────────
 cua so (a,b,c)       │ -    -  │(0,10,11)->KHONG dung; tu C5: (10,11,250)…
 TB ky vong   -    -  │ v=0  v=0│ v=1  v=1  v=1  v=1│ v=1  v=1  v=1 │v=0 │ v=1  v=1  v=1
             -    -   │      y=- │ y=11 y=11 y=3  y=2│ y=2  y=2  y=2 │ -  │ y=2  y=2 y=128
 Ket qua      -    -  │ ✅   🔴 │ (chua chay toi — du doan: TAT CA PASS sau khi va)
                            │
                            └── DUT cho valid_out = 1 tai mau thu HAI
                                TB ky vong 0  =>  $fatal @ t = 36
```

> **Lưu ý cách đọc cột C4/C5:** `hist0_q` và `hist1_q` trong bảng là giá trị **sau** cạnh.
> Cửa sổ `(a,b,c)` dùng để tính `median_out` tại cạnh nào là giá trị **trước** cạnh đó của
> `hist0_q`, `hist1_q` cộng với `sample_in` tại cạnh đó.

### Giải thích từng đoạn

| Chu kỳ | Điều gì xảy ra | Nhánh RTL | Vì sao đoạn này quan trọng |
|---|---|---|---|
| **C1** | `rst_n = 0` ⟹ xoá 27 flip-flop | 36–41 | Reset **đồng bộ**: trạng thái chỉ về 0 **sau** cạnh |
| **C2** | Vẫn reset; TB nhả `rst_n` ngay sau cạnh | 36–41 | Race **vô hại** vì C1 đã reset xong |
| **C3** | Mẫu 1 (`10`). `count_q` 0 ⟹ `0 >= 1` sai ⟹ `valid_out = 0` | 52 | ✅ **PASS** |
| **C4** | Mẫu 2 (`11`). `count_q` **trước cạnh = 1** ⟹ `1 >= 1` **đúng** ⟹ `valid_out ← 1` | 52 | 🔴 **FATAL.** Cửa sổ là `(a,b,c) = (0, 10, 11)` — số `0` là **giá trị reset**, không phải dữ liệu. `med3 = max(min(0,10), min(max(0,10),11)) = max(0,10) = 10` |
| **C5** | Mẫu 3 (`250`). Cửa sổ `(10, 11, 250)` ⟹ `med3 = 11` | 20–29 | ⭐ **Ca loại xung** của Charter mục 8. Mẫu `250` **không ảnh hưởng gì** tới kết quả |
| **C6–C8** | Hoán vị `3, 1, 2` | 20–29 | Ba hình dạng thứ tự khác nhau — ca CC-5 |
| **C9–C11** | Trùng lặp `2, 9, 2` | 20–29 | Ép `x <= x` — ca CC-6 |
| **C12** | `valid_in = 0` ⟹ mọi flip-flop đứng yên, `valid_out` về 0 | 43, 45 | Ca CC-8 (gating) |
| **C13–C15** | Ca biên `0, 255, 128` | 20–29 | ⭐ Ép cả hai cực trị 8 bit; nếu khai `signed` thì `255 = −1` và C15 cho `0` thay vì `128` |

## 2. Soi kỹ C4 — cạnh mà mô phỏng chết

```
                    C3 (t=25)            C4 (t=35)
                 ──────────────┬──────────────────────────
  clk        ────┐  ┌──────────┐  ┌──────────────────────
                 └──┘          └──┘
                    ▲              ▲
                    │              │
  count_q (truoc) 0 ┼──▶ 1 ────────┼──▶ 2
  count_q >= 1    0 ┼──▶ 0 ────────┼──▶ 1   🔴 bat SOM mot mau
  count_q >= 2    0 ┼──▶ 0 ────────┼──▶ 0   ✅ dung phai la nhu the nay
                    │              │
  a = hist0_q     0 ┼──▶ 0 ────────┼──▶ 10
  b = hist1_q     0 ┼──▶ 10 ───────┼──▶ 11
  c = sample_in  10 ┼──▶ 11 ───────┼──▶ 250
                    │              │
  cua so           (0,0,10)    (0,10,11)  <-- so 0 la GIA TRI RESET, khong phai du lieu
  med3 to hop        0            10
                    │              │
  valid_out       0 ┼──▶ 0 ────────┼──▶ 1  🔴  TB ky vong 0
  median_out      0 ┼──▶ 0 ────────┼──▶ 10
                                   │
                            $fatal "valid mismatch x=11" @ t = 36
```

**Vì sao số `0` lọt vào cửa sổ:** `hist0_q` được reset về `'0` (dòng 37). Tại C4, `hist0_q`
vẫn là `0` vì nó mới chỉ nhận được một lần dịch (từ `hist1_q = 0` tại C3). Cửa sổ mới có
**hai** mẫu thật (`10`, `11`) và **một** giá trị reset (`0`).

**Giá trị mạch thật sự tính:** `med3 = min(s1, s2) = min(10, 11) = 10`.
Tổng quát, tại mẫu thứ hai sau mỗi lần reset, RTL luôn cho `median_out = min(s(1), s(2))`,
vì `max(min(0,b), min(max(0,b), c)) = max(0, min(b,c)) = min(b,c)` với `b, c` không dấu.

**Hậu quả trong ứng dụng thật** (cảm biến áp suất): sau mỗi lần khởi động hoặc reset, tầng
ngoài nhận **một mẫu hợp lệ giả** mang giá trị `min` của hai mẫu đầu — nhỏ hơn giá trị thật.
Với tầng so sánh ngưỡng, đó là một lần đọc áp suất thấp giả.

## 3. Nếu vá `2'd1 → 2'd2` thì phần còn lại có PASS không?

Mô phỏng bằng tay toàn bộ testbench theo RTL đã vá:

| Chu kỳ | `sample_in` | Cửa sổ `(a, b, c)` | `med3` | TB kỳ vọng | Kết quả |
|---|---:|---|---:|---|:-:|
| C3 | 10 | — | — | `valid = 0` | ✅ |
| C4 | 11 | — | — | `valid = 0` | ✅ (sau vá) |
| C5 | 250 | `(10, 11, 250)` | **11** | `valid=1, y=11` | ✅ |
| C6 | 3 | `(11, 250, 3)` | **11** | `y = 11` | ✅ |
| C7 | 1 | `(250, 3, 1)` | **3** | `y = 3` | ✅ |
| C8 | 2 | `(3, 1, 2)` | **2** | `y = 2` | ✅ |
| C9 | 2 | `(1, 2, 2)` | **2** | `y = 2` | ✅ |
| C10 | 9 | `(2, 2, 9)` | **2** | `y = 2` | ✅ |
| C11 | 2 | `(2, 9, 2)` | **2** | `y = 2` | ✅ |
| C12 | — | `valid_in = 0` | — | `valid = 0` | ✅ |
| C13 | 0 | `(9, 2, 0)` | **2** | `y = 2` | ✅ |
| C14 | 255 | `(2, 0, 255)` | **2** | `y = 2` | ✅ |
| C15 | 128 | `(0, 255, 128)` | **128** | `y = 128` | ✅ |

> ⟹ **Đổi đúng MỘT ký tự (`1` thành `2`) là toàn bộ mô phỏng G03 PASS.** Không dòng nào khác
> phải sửa, không testbench nào phải sửa. Đây là bằng chứng mạnh nhất cho phán xử
> "lỗi nằm trong DUT" — xem `05_VERIFICATION/known_issues.md`.

## 4. Vì sao đây là giản đồ **hành vi**, không minh hoạ độ trễ thật

Ở giản đồ trên, `median_out` đổi giá trị **ngay** tại cạnh clock. Ở silicon thì không:

```
   Mo phong hanh vi (zero-delay):

     clk        ──┐  ┌────────────────
                  └──┘
     b[0]        ──X──────────────────         doi ngay tai canh
     median_out  ──X──────────────────         doi ngay tai canh


   Thuc te sau tong hop (so tu STA):

     clk        ──┐  ┌────────────────────────────────────────┐  ┌───
                  └──┘                                        └──┘
     b[0]        ──┬──X───────────────────────────────────────────
                   │◀─▶│ 0,36 ns  (clk->Q cua _341_)
     lt1          ─────┴────X───────────────────────────────────── ~2,94 ns
     lt2          ──────────────────X──────────────────────────── ~4,54 ns
     med3         ──────────────────────────────X─────────────── ~7,69 ns
     median_out/D ───────────────────────────────┴X───────────── 7,82 ns
                   │◀──────────── 7,82 ns ────────▶│
                                                   │◀─ 2,10 ─▶│
                                                   setup 0,08 ─┘
```

Các mốc `2,94 / 4,54 / 7,69 / 7,82 ns` lấy đúng từ cột `Time` của
`06_GDSII/sta/timing_report_max.txt` tại các cell `_186_`, `_216_`, `_257_`, `_258_`.

**Điểm phải nhớ:** mô phỏng RTL **không thể** phát hiện vi phạm setup. Chỉ STA (hoặc mô
phỏng gate-level có SDF) mới làm được, và cả hai đều nói `7,82 ns` trên chu kỳ `10 ns`.

## 5. Đường tới hạn trên trục thời gian (số liệu thật)

```
  canh clk k                                                 canh clk k+1
      │                                                           │
      │◀──────────────── chu ky 10,00 ns (GIA DINH) ─────────────▶│
      │                                                           │
      │ clk->Q                                                    │
      │◀0,36▶│                                                    │
      │      │ b[0] ▶ CMP1 (6 maj3) ▶ lt1 ▶ MUX hi1               │
      │      │      ▶ CMP2 (2 maj3) ▶ lt2                         │
      │      │      ▶ CMP3 (7 maj3) ▶ MUX med3 ▶ median_out[1]/D  │
      │      │◀────────── 7,46 ns logic (28 cell) ───────────────▶│
      │                                                           │
      │◀───────────── arrival 7,82 ns ──────────────▶│            │
      │                                              │◀─ 2,10 ──▶│
      │                                                        │◀▶│ setup 0,08
      │                                          required 9,92 ns
```

| Đại lượng | G03 | So với nhóm G |
|---|---:|---|
| Arrival | **7,82 ns** | **dài nhất** (G01 4,56 · G02 4,38 · G04 6,71) |
| Slack | **2,10 ns** | **mỏng nhất** (G01 5,36 · G02 5,48 · G04 3,16) |
| Tỉ lệ chiếm chu kỳ | **78,2 %** | G01 45,6 % · G02 43,8 % · G04 67,1 % |
| Số cell trên đường | **28** | G01 14 · G02 14 · G04 19 |

> ⚠️ Con số 7,82 ns **chưa có ký sinh dây**, **một góc PVT** (`tt_025C_1v80`), **skew = 0**.
> Với ba điểm fanout cao trên đường (27, 13, 13 — `datapath.md` §5), độ trễ sau routing sẽ
> **tăng đáng kể**. G03 là đề có **nguy cơ vi phạm timing cao nhất nhóm G**. Không được
> diễn dịch thành tần số hoạt động.

Đường **hold** ngắn nhất: `_325_ → _325_` (`median_out[0]` hồi tiếp), slack `0,43 ns` (MET).

## 6. Waveform thật đã thu được

| Hạng mục | Trạng thái |
|---|---|
| File VCD | ⬜ **Không có** — `g03_tb.sv` không có `$dumpfile`/`$dumpvars`, và mô phỏng dừng bằng `$fatal` tại `t = 36` |
| Log mô phỏng | ✅ `05_VERIFICATION/simulation.log` (2 dòng) |
| Log biên dịch | ✅ `05_VERIFICATION/iverilog_compile.log` — **rỗng, không một cảnh báo** |

Muốn có waveform, cần thêm (**chưa áp dụng**):

```systemverilog
    initial begin
        $dumpfile("g03_waves.vcd");
        $dumpvars(0, g03_tb);
    end
```

và áp bản vá một ký tự ở `known_issues.md` §6 để mô phỏng chạy hết 15 chu kỳ.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-G03-010, REQ-G03-012.*

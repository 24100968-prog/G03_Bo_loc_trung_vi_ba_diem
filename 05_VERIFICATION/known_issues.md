# G03 · Phán xử lỗi mô phỏng (Known Issues)

> ## ✅ Trạng thái: **ĐÃ ÁP DỤNG** — 2026-09-24
>
> Giảng viên đã duyệt. **Vá 1** (§6) đã được áp dụng vào
> `04_IMPLEMENTATION/rtl/g03_median3.sv` dòng 52: ngưỡng phát hành đầu ra đổi từ
> `count_q >= 2'd1` thành `count_q >= 2'd2`.
> Nhật ký đầy đủ: [`08_ORIGINAL_SOURCE/PATCHLOG.md`](../08_ORIGINAL_SOURCE/PATCHLOG.md).
>
> ⚠️ **Đây là bản vá chạm vào RTL** — khác hẳn F10/G01/G02 trong cùng đợt. Netlist đã đổi,
> nên tổng hợp **đã được chạy lại** và mọi số liệu ở tầng `06_GDSII/` phải được sinh lại
> (xem §7 và `PATCHLOG.md` §5.1).
>
> **Kết quả xác minh bằng công cụ thật sau khi vá:**
>
> | Bước | Trước khi vá | Sau khi vá |
> |---|---|---|
> | Mô hình chuẩn Python | PASS — `G03 golden reference PASS` (5/5) | ✅ PASS, mã thoát 0 |
> | Biên dịch `iverilog -g2012` | PASS | ✅ PASS, không cảnh báo |
> | Mô phỏng `vvp` | ❌ `FATAL g03_tb.sv:23 valid mismatch x=11`, `Time: 36` (dừng ở **mẫu thứ hai**) | ✅ **`G03 TB completed`**, `$finish` tại `t = 146` — **12/12** mốc kiểm PASS |
> | Tổng hợp `yosys` | 189 cell · 27 FF · 1 576,512 µm² | ✅ **188 cell · 27 FF · 1 562,7488 µm²** |
>
> **Dự đoán ở §6 rằng bản vá LÀM GIẢM một cổng đã được xác nhận bằng đo đạc:** `−1 cell`,
> `−13,7632 µm²`, số flip-flop **không đổi (27)**. Số "trước khi vá" được đo lại từ chính
> bản gốc đóng băng trong `08_ORIGINAL_SOURCE/rtl/` để hai con số so sánh được với nhau.
>
> **Testbench KHÔNG bị sửa** — phán xử §4 đã chứng minh testbench đúng, và 12/12 mốc kiểm
> PASS mà không phải đổi một giá trị kỳ vọng nào.
>
> **Chưa áp dụng** (xem `PATCHLOG.md` §5.2): **Vá 2** (tham số hoá ngưỡng theo `N` — loại bỏ
> cả lớp lỗi); **Vá 3** (assertion — hiện `properties.sv` **vẫn không bắt được** lớp lỗi này,
> và nằm trong `ifdef G03_SVA` chưa từng chạy); **Vá 4** (ca CC-9/CC-2/CC-10); **Vá 5** (VCD).
>
> Phần phán xử bên dưới được **giữ nguyên** làm tài liệu dạy học. Mọi câu "chưa áp dụng"
> trong đó phản ánh trạng thái **tại thời điểm phán xử**, không phải trạng thái hiện nay.

---

> Tài liệu này chỉ tồn tại vì BRIEF G03 ghi **Mô phỏng RTL: RAN_WITH_ISSUES**.
> Mục tiêu: **phán xử** lỗi nằm ở đâu, chứng minh bằng mã, và đề xuất bản vá tối thiểu.
> **Bản vá CHƯA được áp dụng** — xem §8. *(Nguyên văn lúc phán xử; nay Vá 1 đã áp dụng.)*

---

## 1. Trích nguyên văn thông báo lỗi

Nguồn: `05_VERIFICATION/simulation.log` (trùng với BRIEF G03).

```
FATAL: .../runs/G03/work/g03_tb.sv:23: valid mismatch x=11
       Time: 36  Scope: g03_tb.send
```

| Log khác | Nội dung |
|---|---|
| `iverilog_compile.log` | **RỖNG** — không một lỗi, không một cảnh báo |
| `python_reference_run.log` | `G03 golden reference PASS` (5/5 test) |
| `yosys.log` | Tổng hợp **PASS** — 189 cell, 27 FF, 1576,512 µm² |
| `sta.log` | **PASS**, `wns max 0.00`, `tns max 0.00` |

Ba dữ kiện đọc ngay từ dòng lỗi:
1. Lỗi ở **dòng 23** — assertion `valid_out == exp_valid`, **không** phải assertion so giá trị
   trung vị (dòng 25–27). Nghĩa là **thời điểm** sai, chưa chắc **giá trị** sai.
2. `x = 11` ⟹ đang ở lệnh `send(11,0,0)` — lệnh **thứ hai** của phần warm-up.
3. `Time: 36` ⟹ cạnh clock tại `t = 35` = chu kỳ **C4** = **mẫu thứ hai**. Lỗi xảy ra ở
   **ngay mẫu thứ hai sau reset**.

## 2. Định vị: lỗi nằm ở file nào

| File | Bị nhắc trong log? | Kết luận sơ bộ |
|---|:-:|---|
| `04_IMPLEMENTATION/rtl/g03_median3.sv` (**DUT**) | ❌ | Nhưng đây là bên **bị kiện** |
| `05_VERIFICATION/golden_model/reference_model.py` | ❌ | PASS 5/5 |
| `05_VERIFICATION/testbench/g03_tb.sv` | ✅ **dòng 23** | Là bên **phát hiện**, chưa chắc là bên sai |
| `05_VERIFICATION/testbench/properties.sv` | ❌ | Bị `ifdef G03_SVA` tắt |
| Icarus Verilog 12.0 | ❌ | Không cảnh báo nào |

## 3. Đoạn mã gây tranh chấp

### Bên A — DUT, `g03_median3.sv` dòng 45–56:

```systemverilog
45            if (valid_in) begin
46                hist0_q <= hist1_q;
47                hist1_q <= sample_in;
48
49                if (count_q < 2'd2)
50                    count_q <= count_q + 2'd1;
51
52                if (count_q >= 2'd1) begin      // <<<<<< NGHI PHAM
53                    valid_out <= 1'b1;
54                    median_out <= med3;
55                end
56            end
```

### Bên B — Testbench, `g03_tb.sv` dòng 37–40:

```systemverilog
37        // Warm-up.
38        send(10,0,0);      // mau 1 -> valid phai = 0
39        send(11,0,0);      // mau 2 -> valid phai = 0
40        send(250,1,11);    // mau 3 -> valid = 1, median = 11
```

### Bên C — Mô hình chuẩn, `reference_model.py` dòng 4–15:

```python
def median_stream(samples):
    out=[]; hist=[]
    for x in samples:
        hist.append(x)
        if len(hist)<3:                     # <<<<<< NGUONG = 3
            out.append((False,None))
        else:
            if len(hist)>3: hist.pop(0)
            out.append((True,median3(*hist)))
    return out
```

## 4. 🔨 PHÁN XỬ

### Kết luận một dòng

> **Lỗi nằm trong DUT (`g03_median3.sv`, dòng 52), không nằm trong testbench, không nằm trong
> mô hình chuẩn.** Đây là **lỗi off-by-one** ở ngưỡng phát hành đầu ra: RTL viết
> `count_q >= 2'd1` trong khi cửa sổ dài 3 đòi hỏi `count_q >= 2'd2`. Hậu quả: mạch phát ra
> **một kết quả hợp lệ giả** ở mẫu thứ hai sau mỗi lần reset, tính từ một cửa sổ chỉ có **hai**
> mẫu thật cộng **một giá trị reset `0`**.

### Tầng thứ nhất — lập luận tổng quát về ngưỡng

`count_q` đếm số mẫu **đã nhận trước đó**. Mẫu đang được xử lý là mẫu thứ `count_q + 1`.
Muốn xuất kết quả ở mẫu thứ `N`:

```
        count_q + 1 >= N     <=>     count_q >= N - 1
```

| Đề | `N` | Ngưỡng đúng | RTL viết | |
|---|---:|---:|---|:-:|
| G02 (trung bình 8 điểm) | 8 | `>= 7` | `count_q >= 4'd7` | ✅ |
| **G03 (trung vị 3 điểm)** | **3** | **`>= 2`** | `count_q >= 2'd1` | 🔴 |

Hai đề dùng **cùng một khung mã** (cùng cấu trúc `always_ff`, cùng `count_q` bão hoà, cùng
cách gating bằng `valid_in`), nhưng chỉ G02 điền đúng hằng số. Đây là dấu hiệu rất mạnh của
một **lỗi sao chép-sửa** (copy-adapt), không phải một lựa chọn thiết kế có chủ đích.

### Tầng thứ hai — ba nguồn độc lập cùng chống lại DUT

| Nguồn | Nói gì | Độc lập với DUT? |
|---|---|:-:|
| Mô hình chuẩn Python (`median_stream`) | `(False, None)` cho **hai** mẫu đầu ⟹ hợp lệ từ mẫu **thứ ba** | ✅ Ngôn ngữ khác, tác giả cùng nhưng logic viết độc lập |
| Testbench (`send(11,0,0)`) | Mẫu thứ hai phải có `valid = 0` | ✅ |
| Bản chất bài toán | Trung vị **3 điểm** cần **3 điểm**. Với 2 điểm, "trung vị" không được định nghĩa | ✅ Toán học |
| Chính RTL, dòng 49 | `count_q < 2'd2` — tác giả **biết** ngưỡng đầy là 2 và dùng đúng nó cho bộ đếm | ✅ Mâu thuẫn nội bộ ngay trong 3 dòng liền kề |

Dòng 49 và dòng 52 nằm cách nhau **ba dòng** và dùng **hai hằng số khác nhau** cho cùng một
khái niệm "cửa sổ đã đầy". Đó là bằng chứng nội tại mạnh nhất.

### Tầng thứ ba — mạch tính ra cái gì ở mẫu thứ hai

Tại C4 (`t = 35`), trạng thái là `hist0_q = 0` (giá trị **reset**), `hist1_q = 10`,
`sample_in = 11`. Mạng sắp xếp tính:

```
   a = 0, b = 10, c = 11
   lo1 = min(0,10)  = 0        hi1 = max(0,10) = 10
   lo2 = min(10,11) = 10       hi2 = 11            (ma chet)
   med3 = max(lo1, lo2) = max(0, 10) = 10
```

Tổng quát, với `b, c` **không dấu** và `a = 0`:

```
   med3 = max( min(0,b), min(max(0,b), c) ) = max( 0, min(b,c) ) = min(b, c)
```

> ⟹ **Ở mẫu thứ hai sau mỗi lần reset, G03 luôn xuất `min(s(1), s(2))` kèm `valid_out = 1`.**
> Không phải giá trị rác ngẫu nhiên — mà là một giá trị **trông có vẻ hợp lý** nhưng **thấp
> hơn** giá trị đúng. Trong ứng dụng cảm biến áp suất của Charter mục 1 (đầu ra đi thẳng vào
> so sánh ngưỡng → van an toàn), đây là một lần đọc **áp suất thấp giả** sau mỗi lần khởi động.
> Loại lỗi "gần đúng" này nguy hiểm hơn hẳn lỗi cho ra giá trị rõ ràng sai.

### Tầng thứ tư — chứng minh bản vá là **đủ**

Mô phỏng bằng tay toàn bộ testbench với RTL đã vá (`>= 2'd2`):

| Chu kỳ | `sample_in` | Cửa sổ `(a,b,c)` | `med3` | TB kỳ vọng | |
|---|---:|---|---:|---|:-:|
| C3 | 10 | — | — | `valid=0` | ✅ |
| C4 | 11 | — | — | `valid=0` | ✅ |
| C5 | 250 | `(10,11,250)` | 11 | `valid=1, y=11` | ✅ |
| C6 | 3 | `(11,250,3)` | 11 | `y=11` | ✅ |
| C7 | 1 | `(250,3,1)` | 3 | `y=3` | ✅ |
| C8 | 2 | `(3,1,2)` | 2 | `y=2` | ✅ |
| C9 | 2 | `(1,2,2)` | 2 | `y=2` | ✅ |
| C10 | 9 | `(2,2,9)` | 2 | `y=2` | ✅ |
| C11 | 2 | `(2,9,2)` | 2 | `y=2` | ✅ |
| C12 | (gap) | — | — | `valid=0` | ✅ |
| C13 | 0 | `(9,2,0)` | 2 | `y=2` | ✅ |
| C14 | 255 | `(2,0,255)` | 2 | `y=2` | ✅ |
| C15 | 128 | `(0,255,128)` | 128 | `y=128` | ✅ |

> ⟹ **Đổi đúng MỘT ký tự làm toàn bộ mô phỏng G03 PASS.** Không dòng RTL nào khác, không
> dòng testbench nào phải sửa.

### Bảng phán xử

| Khả năng | Có phải không? | Lập luận |
|---|:-:|---|
| Lỗi trong **DUT** (`g03_median3.sv` dòng 52) | ✅ **CHÍNH LÀ ĐÂY** | Ngưỡng phải là `N−1 = 2`, RTL viết 1. Ba nguồn độc lập (mô hình chuẩn, testbench, toán học) đều chống lại DUT; và chính dòng 49 của DUT dùng đúng hằng 2 cho cùng khái niệm |
| Lỗi trong **testbench** | ❌ **KHÔNG** | `send(11,0,0)` khớp hoàn toàn với `median_stream` và với định nghĩa trung vị 3 điểm. Testbench **làm đúng việc của nó** và bắt được lỗi ngay ca thứ hai |
| Lỗi trong **mô hình chuẩn** | ❌ **KHÔNG** | PASS 5/5; ngưỡng `len(hist) < 3` là định nghĩa chuẩn |
| **Giới hạn công cụ** (Icarus) | ❌ **KHÔNG** | Không cảnh báo nào; `$fatal` là do assertion của người viết, không phải do công cụ |
| Lỗi trong **mạng sắp xếp** | ❌ **KHÔNG** | Ba compare-exchange ở dòng 20–29 đúng hoàn toàn. Đã kiểm 6/6 hoán vị + 4 ca trùng lặp ở mức Python, và mô phỏng bằng tay C5–C15 ở bảng trên đều khớp |

## 5. Lỗi thứ hai, tiềm ẩn: độ phủ hình thức bằng 0

`properties.sv` chỉ có **một** assertion, và nó **không** kiểm được lỗi ở §4:

```systemverilog
assert_valid_requires_input:
    assert property (@(posedge clk) valid_out |-> $past(valid_in));
```

Tính chất này **vẫn đúng** với RTL lỗi (mẫu thứ hai cũng có `valid_in = 1` ở cạnh trước).
Nghĩa là: **nếu chỉ dựa vào assertion, lỗi này lọt hoàn toàn.** Nó chỉ bị bắt vì testbench
kiểm **đúng cái mẫu thứ hai** — một lựa chọn thiết kế testbench rất tốt.

Ghi chú trong chính file: *"Enable only after freezing exact cycle alignment from the official
specification."* — tức tác giả **tự biết** chưa chốt được căn chỉnh chu kỳ. Lỗi ở §4 chính là
hậu quả của việc chưa chốt đó.

## 6. 🔧 Bản vá tối thiểu (đề xuất — **chưa áp dụng**)

### Vá 1 — sửa ngưỡng phát hành (bắt buộc, sửa được lỗi ở §1) — ✅ **ĐÃ ÁP DỤNG 2026-09-24**

`04_IMPLEMENTATION/rtl/g03_median3.sv`

```diff
                 if (count_q < 2'd2)
                     count_q <= count_q + 2'd1;
 
-                if (count_q >= 2'd1) begin
+                if (count_q >= 2'd2) begin   // N-1 = 3-1 = 2: cua so du BA mau THAT
                     valid_out <= 1'b1;
                     median_out <= med3;
                 end
```

**Vì sao vá như vậy:**
1. Cửa sổ dài `N = 3` ⟹ ngưỡng đúng là `N − 1 = 2` (§4 tầng 1).
2. Hằng `2` đã xuất hiện ngay dòng trên (`count_q < 2'd2`) ⟹ sau vá, hai dòng **nhất quán**.
3. `count_q` rộng 2 bit và bão hoà tại 2 ⟹ `count_q >= 2'd2` tương đương `count_q[1]` — thực
   tế **rẻ hơn** `>= 2'd1` (vốn cần `count_q[1] | count_q[0]`). Vá này **giảm** một cổng.
4. Đường tới hạn **không** đi qua `count_q` (`datapath.md` §3) ⟹ dự kiến `7,82 ns` không đổi.
   **Phải chạy lại để xác nhận, không được ghi số dự đoán vào báo cáo.**

### Vá 2 — làm ngưỡng tự suy ra từ `N` (nên có, phòng lỗi tái diễn)

```diff
 module g03_median3 #(
-    parameter int W = 8
+    parameter int W = 8
 ) (
 ...
+    localparam int N = 3;                 // chieu dai cua so, CO DINH (Charter muc 3)
+    localparam int CNT_MAX = N - 1;       // nguong phat hanh = so mau da nhan truoc do
 ...
-                if (count_q < 2'd2)
+                if (count_q < CNT_MAX[1:0])
                     count_q <= count_q + 2'd1;
 
-                if (count_q >= 2'd1) begin
+                if (count_q >= CNT_MAX[1:0]) begin
```

Sau vá này, **một** hằng `N` điều khiển cả hai chỗ ⟹ không thể lệch nhau nữa. Đây là bản vá
có giá trị dạy học cao nhất: nó **loại bỏ cả lớp lỗi**, không chỉ một trường hợp.

### Vá 3 — bổ sung assertion bắt được đúng lỗi này (nên có)

```diff
 `ifdef G03_SVA
+// Dem so mau THAT da nhan, thay cho viec tin vao count_q cua DUT.
+int unsigned accepted_q;
+always_ff @(posedge clk)
+    if (!rst_n)        accepted_q <= 0;
+    else if (valid_in) accepted_q <= (accepted_q < 3) ? accepted_q + 1 : 3;
+
+assert_no_early_valid:
+    assert property (@(posedge clk) valid_out |-> (accepted_q >= 3));
+
+// Ket qua PHAI la ban sao cua mot trong ba mau (INV-3) — bat loi noi nham day trong mang.
+assert_output_is_an_input:
+    assert property (@(posedge clk)
+        valid_out |-> (median_out == $past(sample_in)   ||
+                       median_out == $past(sample_in,2) ||
+                       median_out == $past(sample_in,3)));
+
 assert_valid_requires_input:
     assert property (@(posedge clk) valid_out |-> $past(valid_in));
 `endif
```

*(Lưu ý: `assert_output_is_an_input` chỉ đúng khi `valid_in` giữ mức cao liên tục; với dòng
dữ liệu thưa phải dùng biến phụ lưu ba mẫu gần nhất thay cho `$past`.)*

### Vá 4 — bổ sung ca kiểm thử còn thiếu của Charter mục 8 (nên có)

```systemverilog
    // CC-9: HAI xung lien tiep -> trung vi KHONG loai duoc (neu GIOI HAN)
    // cua so (10,250,250) -> 250 ;  (250,250,10) -> 250
    // CC-2: chuoi tang dan thuan -> tre dung MOT mau, khong meo
    // CC-10: ba mau bang nhau -> ket qua = chinh gia tri do
```

Chi tiết vector: `02_SPECIFICATION/corner_cases.md` §4.

### Vá 5 — sinh waveform (Charter mục 3 yêu cầu artifact số)

```systemverilog
    initial begin
        $dumpfile("g03_waves.vcd");
        $dumpvars(0, g03_tb);
    end
```

## 7. Việc phải làm lại sau khi áp Vá 1

Vá 1 đụng vào **RTL**, nên **mọi số liệu ở tầng 06_GDSII đều phải chạy lại**:

| File | Vì sao phải chạy lại |
|---|---|
| `06_GDSII/synthesis/*` | Logic `>= 2` khác `>= 1` ⟹ netlist đổi, số cell có thể đổi |
| `06_GDSII/sta/*` | Netlist đổi ⟹ tên instance đổi; đường tới hạn **dự kiến** không đổi nhưng phải xác nhận |
| `06_GDSII/power/*` | Netlist đổi |
| `02_SPECIFICATION/parameters.md` §3, `06_GDSII/physical_report.md` | Chứa số cell/diện tích/timing |
| `03_ARCHITECTURE/*` | Mọi tên instance (`_341_`, `_326_`, …) sẽ đổi |
| `07_TRACEABILITY/RTM.csv`, `limitations.md` | Trạng thái REQ-G03-001 |

> ⚠️ Đây là điểm khác quan trọng so với G02: ở G02 bản vá chỉ đụng **testbench** nên tầng
> vật lý giữ nguyên. Ở G03, bản vá đụng **RTL** nên **toàn bộ hồ sơ số liệu phải làm lại**.

## 8. ⚠️ Trạng thái bản vá

> **CẬP NHẬT 2026-09-24 — Vá 1 ĐÃ ÁP DỤNG.** Mục này giữ nguyên văn bản lúc phán xử; trạng
> thái hiện hành nằm ở khối đầu file và ở `08_ORIGINAL_SOURCE/PATCHLOG.md`. Vá 2–5 vẫn chưa
> áp dụng. Bản gốc của `g03_median3.sv` vẫn được đóng băng nguyên vẹn trong
> `08_ORIGINAL_SOURCE/rtl/`.

- **Chưa áp dụng.** Cả năm vá ở §6 **không** được ghi vào file nào.
  `04_IMPLEMENTATION/rtl/g03_median3.sv` **giữ nguyên bản gốc của thầy**.
- Lý do: quy trình của hồ sơ này là **phán xử, không sửa**. Vá 1 đụng vào **thiết kế**, nên
  bắt buộc phải có thầy duyệt.
- Thứ tự đề nghị sau khi duyệt: **Vá 1** → chạy lại `01_run_sim.sh` (kỳ vọng PASS) →
  chạy lại `02_run_synth.sh` + `03_run_sta.tcl` → cập nhật toàn bộ số liệu (§7) →
  **Vá 5** → **Vá 4** → **Vá 3** → cuối cùng **Vá 2**.
- **Tuyệt đối không sửa testbench** để "làm cho mô phỏng xanh". Phán xử §4 đã chứng minh
  testbench đúng.

## 9. Giá trị dạy học

| # | Bài học | Vì sao đáng dạy |
|---|---|---|
| 1 | **Ngưỡng phát hành của bộ lọc cửa sổ `N` là `count >= N−1`, không phải `>= 1`.** Bộ đếm đếm *mẫu đã nhận trước đó*, mẫu hiện tại là thứ `count+1` | Đây là lỗi off-by-one kinh điển nhất của mọi mạch xử lý dòng dữ liệu. Đối chiếu G02 (`>= 7` cho `N = 8`) là cách nhớ tốt nhất |
| 2 | **Mâu thuẫn nội tại trong ba dòng liền kề.** Dòng 49 dùng hằng `2`, dòng 52 dùng hằng `1`, cho **cùng một khái niệm** "cửa sổ đã đầy" | Kỹ năng đọc mã: khi thấy hai hằng số khác nhau mô tả cùng một khái niệm, một trong hai **chắc chắn** sai. Đây là chỗ phải dừng lại và hỏi |
| 3 | **Lỗi "gần đúng" nguy hiểm hơn lỗi "sai hẳn".** Mạch không cho giá trị rác — nó cho `min(s1,s2)`, một số trông hợp lý nhưng thấp hơn sự thật | Giá trị rác bị phát hiện ngay; giá trị gần đúng đi thẳng vào tầng so sánh ngưỡng và gây hậu quả vật lý |
| 4 | **Giá trị reset lọt vào cửa sổ dữ liệu.** `hist0_q = 0` không phải "mẫu áp suất bằng 0", nó là "chưa có dữ liệu" | Phân biệt *không có dữ liệu* với *dữ liệu bằng 0* là một trong những nguồn lỗi lớn nhất của xử lý tín hiệu nhúng. `valid_out` tồn tại chính để nói điều đó — và ở đây nó nói **sai** |
| 5 | **Assertion hiện có KHÔNG bắt được lỗi này.** `valid_out |-> $past(valid_in)` vẫn đúng với RTL lỗi | Có assertion **không có nghĩa là** có độ phủ. Assertion phải truy vết về **đặc tả**, không phải viết cho có |
| 6 | **Testbench viết tốt là testbench kiểm cả những chu kỳ "không có gì xảy ra".** Nếu TB chỉ bắt đầu kiểm từ mẫu thứ ba, lỗi này **lọt hoàn toàn** | Đây là ví dụ hoàn hảo cho nguyên tắc: phải khẳng định cả *"chưa được phép xảy ra"*, không chỉ *"kết quả đúng chưa"* |
| 7 | **Cùng một triệu chứng, hai thủ phạm khác nhau.** G02 cũng `$fatal` ở assertion `valid`, nhưng ở đó lỗi nằm ở **testbench**; ở G03 lỗi nằm ở **DUT** | Dạy rằng không được phán xử theo triệu chứng. Phải **đọc mã** và tìm **nguồn độc lập** để đối chứng |
| 8 | **Bản vá đụng RTL kéo theo toàn bộ tầng vật lý phải chạy lại.** Bản vá đụng testbench thì không | Nhận thức về chi phí của một thay đổi — thứ phân biệt kỹ sư với người viết mã |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*

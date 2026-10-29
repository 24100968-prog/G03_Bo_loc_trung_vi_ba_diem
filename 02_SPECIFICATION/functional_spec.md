# G03 · Đặc tả chức năng (Functional Specification)

> ## ⚠️ CẢNH BÁO 1 — ĐỐI CHIẾU CHARTER MỤC 4: **CHƯA THOẢ**
>
> Charter mục 4 yêu cầu ánh xạ chân Tiny Tapeout:
> `ui_in[7:0]` = mẫu vào · `uio_in[0]` = mẫu hợp lệ · `uo_out[7:0]` = trung vị ·
> `uio_out[0]` = kết quả hợp lệ.
>
> RTL thật (`04_IMPLEMENTATION/rtl/g03_median3.sv`) khai báo cổng:
> `clk`, `rst_n`, `valid_in`, `sample_in[7:0]`, `valid_out`, `median_out[7:0]`.
>
> | Chân Charter mục 4 | Cổng RTL | Trạng thái |
> |---|---|---|
> | `ui_in[7:0]` | `sample_in[7:0]` | ⚠️ khớp **chức năng**, khác **tên và lớp vỏ** |
> | `uio_in[0]` | `valid_in` | ⚠️ như trên |
> | `uo_out[7:0]` | `median_out[7:0]` | ⚠️ như trên |
> | `uio_out[0]` | `valid_out` | ⚠️ như trên |
> | — | `clk`, `rst_n` | Tiny Tapeout cấp từ harness |
>
> **Phán xử:** RTL là **module lõi trần**, **không có** module vỏ `tt_um_*` với bộ chân
> `ui_in / uo_out / uio_in / uio_out / uio_oe` ⟹ **ánh xạ chân Charter mục 4 CHƯA ĐƯỢC HIỆN
> THỰC**. Thiếu sót ở **tầng vỏ**, không phải lỗi chức năng. Ngoài ra **xung đột `uio[0]`
> vừa vào vừa ra** mà chính Charter mục 4 đã nêu vẫn **chưa được đánh số lại**.
> ⟹ **REQ-G03-002 phải đánh dấu CHƯA THOẢ.** **Không tự sửa RTL** — cần giảng viên duyệt.

> ## 🔴 CẢNH BÁO 2 — RTL **KHÔNG KHỚP** ĐẶC TẢ VỀ THỜI ĐIỂM XUẤT KẾT QUẢ
>
> Đặc tả (§3, §5 dưới đây), mô hình chuẩn Python và testbench đều quy định: **kết quả hợp lệ
> lần đầu tại mẫu thứ BA**. RTL dòng 52 viết `if (count_q >= 2'd1)` ⟹ xuất **tại mẫu thứ HAI**,
> khi cửa sổ mới có **hai** mẫu thật và phần tử thứ ba vẫn là giá trị reset `0`.
>
> Đây là nguyên nhân trực tiếp làm mô phỏng dừng (`simulation.log`, `Time: 36`).
> **Lỗi nằm trong DUT.** Phán xử đầy đủ và bản vá một ký tự:
> `05_VERIFICATION/known_issues.md`. **Bản vá chưa được áp dụng.**
> ⟹ **REQ-G03-001 đánh dấu CHƯA THOẢ** cho tới khi thầy duyệt bản vá.

---

## 1. Chức năng trong một câu

G03 nhận một **dòng mẫu 8-bit không dấu** kèm tín hiệu hợp lệ, và với mỗi mẫu kể từ mẫu thứ
ba trở đi, xuất ra **giá trị trung vị (phần tử đứng giữa khi sắp xếp) của ba mẫu gần nhất**.

## 2. Ký hiệu

| Ký hiệu | Nghĩa |
|---|---|
| `W` | Độ rộng mẫu, tham số RTL, mặc định **8** |
| `s(k)` | Mẫu thứ `k` **được chấp nhận** (`valid_in = 1` tại cạnh lên) |
| `N` | Chiều dài cửa sổ = **3** (Charter mục 3: cửa sổ ≥ 5 điểm nằm ngoài phạm vi) |
| `a`, `b`, `c` | Ba phần tử của cửa sổ: `a = s(k−2)`, `b = s(k−1)`, `c = s(k)` |
| `CE(x,y)` | **Compare-exchange**: trả về cặp `(min(x,y), max(x,y))` |

## 3. Phương trình hành vi

### 3.1 Hàm trung vị ba phần tử

```
    median3(a,b,c) = max( min(a,b) , min( max(a,b) , c ) )
```

Chứng minh tính đúng bằng vét cạn — chỉ có **6 thứ tự** có thể của ba phần tử phân biệt:

| Thứ tự | `min(a,b)` | `max(a,b)` | `min(max(a,b),c)` | `max(...)` = kết quả | Trung vị đúng |
|---|---|---|---|---|---|
| `a<b<c` | a | b | b | **b** | b ✅ |
| `a<c<b` | a | b | c | **c** | c ✅ |
| `b<a<c` | b | a | a | **a** | a ✅ |
| `b<c<a` | b | a | c | **c** | c ✅ |
| `c<a<b` | a | b | c | **a** | a ✅ |
| `c<b<a` | b | a | c | **b** | b ✅ |

Trường hợp có phần tử bằng nhau được bao phủ vì `min`/`max` đều dùng so sánh không nghiêm
ngặt (`<=`) nhất quán ⟹ không có "khe hở" nào. `reference_model.test_all_permutations` và
`test_ties` đã chạy và **PASS**.

### 3.2 Mạng sắp xếp ba tầng (đây là cách RTL hiện thực)

```
      a ──┬──────────────▶ CE1 ──▶ lo1 ──────────────────▶ CE3 ──▶ lo3  (BO DI)
          │                 │                               │
      b ──┴──────────────▶ CE1 ──▶ hi1 ──┬──▶ CE2 ──▶ lo2 ──┴──▶ med3 ──▶ KET QUA
                                          │       │
      c ─────────────────────────────────┴──▶ CE2 ──▶ hi2  (BO DI)

      CE1 = CE(a, b)         -> lo1 = min(a,b),   hi1 = max(a,b)
      CE2 = CE(hi1, c)       -> lo2 = min(hi1,c), hi2 = max(hi1,c)  <- hi2 KHONG DUNG
      CE3 = CE(lo1, lo2)     -> lo3 = min(...)    <- KHONG DUNG ,  med3 = max(...)
```

**Độ sâu = 3 tầng compare-exchange nối tiếp.** Đây là số tầng **tối thiểu** cho mạng sắp xếp
3 phần tử — không thể rút xuống 2 vì mỗi tầng chỉ so được một cặp.

### 3.3 Hành vi theo chu kỳ

```
  Dieu kien chap nhan: valid_in = 1 tai canh len cua clk va rst_n = 1

  (1) Cua so
        a = hist0_q  (= s(k-2)),   b = hist1_q (= s(k-1)),   c = sample_in (= s(k))

  (2) Dau ra — DAC TA
        valid_out(k) = 1   <=>   k >= 3
        median_out(k) = median3( s(k-2), s(k-1), s(k) )

  (2') Dau ra — RTL HIEN TAI (SAI, xem CANH BAO 2)
        valid_out(k) = 1   <=>   count_q >= 1   <=>   k >= 2

  (3) Cap nhat trang thai
        hist0_q <- hist1_q
        hist1_q <- s(k)
        count_q <- min(count_q + 1, 2)
```

## 4. Bảng hành vi theo pha

| Pha | `k` | `count_q` trước | `valid_out` **đặc tả** | `valid_out` **RTL** | `median_out` |
|---|---:|---:|:-:|:-:|---|
| Reset | — | — | 0 | 0 | `0` |
| Mẫu 1 | 1 | 0 | 0 | 0 ✅ | giữ nguyên |
| **Mẫu 2** | 2 | 1 | **0** | **1** 🔴 | 🔴 `median3(0, s(1), s(2))` — dùng số 0 của reset làm "mẫu" |
| Mẫu 3 | 3 | 2 | 1 | 1 ✅ | `median3(s1,s2,s3)` |
| Mẫu ≥ 4 | ≥4 | 2 | 1 | 1 ✅ | `median3(s(k−2),s(k−1),s(k))` |
| Nghỉ | — | bất kỳ | 0 | 0 ✅ | giữ nguyên |

> 🔴 Chỉ **một** ô trong bảng sai, và nó chỉ ảnh hưởng **một mẫu duy nhất** sau mỗi lần reset.
> Đây là loại lỗi cực kỳ dễ lọt: từ mẫu thứ ba trở đi mạch chạy đúng hoàn toàn.

## 5. Độ trễ và giao thức

| Đại lượng | Giá trị | Bằng chứng |
|---|---|---|
| Trạng thái sau reset | `hist0_q=0`, `hist1_q=0`, `count_q=0`, `valid_out=0`, `median_out=0` | RTL dòng 36–41 |
| Kiểu reset | **Đồng bộ**, tích cực thấp | `always_ff @(posedge clk) if (!rst_n)`; netlist dùng **27 × `dfxtp_1`** (không có chân reset) |
| Độ trễ vào → ra | **1 chu kỳ clock** | `median_out` là đầu ra flip-flop |
| Thời gian khởi động **đặc tả** | **3 mẫu** | `median_stream` trả `(False,None)` cho 2 mẫu đầu |
| Thời gian khởi động **RTL** | **2 mẫu** 🔴 | `count_q >= 2'd1` |
| Thông lượng | 1 mẫu / 1 chu kỳ | không có trạng thái chờ |
| Back-pressure | **không có** | không có cổng `ready` |

## 6. Tính chất bất biến (Invariants)

| ID | Phát biểu | Kiểm bằng |
|---|---|---|
| **INV-1** | `valid_out` chỉ lên 1 nếu `valid_in` bằng 1 tại cạnh trước đó. | `properties.sv` `assert_valid_requires_input` |
| **INV-2** | Sau reset, `valid_out` lên 1 lần đầu **đúng tại mẫu thứ 3**. | 🔴 **RTL VI PHẠM** — xem Cảnh báo 2 |
| **INV-3** | `median_out ∈ {a, b, c}` — kết quả **luôn là một trong ba mẫu đầu vào**, không bao giờ là giá trị mới. | Tính chất của mạng sắp xếp: mọi đầu ra đều đi qua `min`/`max` |
| **INV-4** | `min(a,b,c) ≤ median_out ≤ max(a,b,c)`. | Hệ quả của INV-3 |
| **INV-5** | ⭐ **Loại xung**: nếu `c` là giá trị cực đại hoặc cực tiểu của bộ ba, thì `median_out` **không phụ thuộc giá trị của `c`**. | Bằng chứng số: `median_stream([10,11,250])[-1] = (True,11)` — mẫu 250 **hoàn toàn không ảnh hưởng**, trong khi `mean_stream` cho **90** |
| **INV-6** | **Không có sai số làm tròn**: `median_out` là bản sao bit-chính-xác của một mẫu vào. | Khác hẳn trung bình (`>>` là `floor`) |
| **INV-7** | Nếu `a = b = c` thì `median_out = a`. | `reference_model.test_ties`: `median3(5,5,5) = 5` |
| **INV-8** | `count_q ∈ [0,2]`, đơn điệu không giảm giữa hai lần reset, bão hoà tại 2. | RTL dòng 49–50 |
| **INV-9** | Khi `valid_in = 0`: `hist0_q`, `hist1_q`, `count_q`, `median_out` **không đổi**; chỉ `valid_out` về 0. | RTL dòng 43–45 |
| **INV-10** | Với chuỗi đơn điệu (tăng hoặc giảm) thì `median_out(k) = s(k−1)` — tức **trễ đúng một mẫu, không méo**. | Với `s(k−2) < s(k−1) < s(k)` thì trung vị là `s(k−1)` |
| **INV-11** | `median_out` và `valid_out` là **đầu ra flip-flop** ⟹ không glitch tổ hợp lọt ra chân. | Netlist: `Q(median_out[0..7])`, `Q(valid_out)` |

## 7. Điều kiện biên và hành vi không xác định

| # | Tình huống | Hành vi | Ghi chú |
|---|---|---|---|
| B-1 | `rst_n = 0` nhưng không có cạnh lên | **Reset không xảy ra** | Reset đồng bộ |
| B-2 | Nhả `rst_n` đúng tại cạnh lên | **Không xác định** (race) | TB của G03 nhả reset tại cạnh nhưng **vô hại** vì có 2 cạnh reset (t = 5 và 15) |
| B-3 | Mẫu thứ 2 sau reset | 🔴 RTL xuất `median3(0, s1, s2)` | Số `0` đến từ giá trị reset của `hist0_q`, **không phải dữ liệu thật** |
| B-4 | Ba mẫu bằng nhau | `median_out` = giá trị đó | INV-7 |
| B-5 | Hai trong ba mẫu bằng nhau | `median_out` = giá trị trùng lặp | `median3(2,2,9)=2`, `median3(2,9,2)=2`, `median3(9,2,2)=2` — TB có ca này |
| B-6 | Ca biên `0, 255, 128` | `median_out = 128` | `test_boundary`, và TB dòng 58–60 |
| B-7 | `valid_in` nghỉ giữa dòng | Cửa sổ đứng yên | INV-9, TB dòng 53–55 |
| B-8 | Đọc `median_out` khi `valid_out = 0` | **Không được phép** | Tàn dư hoặc `0` |
| B-9 | **Hai xung liên tiếp** | ⚠️ Trung vị **KHÔNG** loại được | Với `10, 250, 250`, trung vị = 250. Cửa sổ 3 chỉ loại được xung **cô lập** — giới hạn quan trọng nhất của đề |
| B-10 | `W ≠ 8` | Vẫn đúng | Mạng sắp xếp không phụ thuộc độ rộng |

## 8. Ràng buộc cấu trúc bắt buộc

Charter mục 2 câu 3 hỏi thẳng: *"Vì sao đề cấm dùng vòng lặp sắp xếp ở mức hành vi?"*
Charter mục 10 nói rõ chỗ hay tắc: *"Viết `sort()` kiểu phần mềm — không tổng hợp ra được
phần cứng đọc hiểu nổi."*

| Ràng buộc | Nội dung | RTL có thoả? |
|---|---|:-:|
| **C-1** | Phải là **mạng sắp xếp tổ hợp tường minh**, mỗi compare-exchange viết thành một cặp `assign` | ✅ dòng 20–29 |
| **C-2** | **Cấm** vòng lặp sắp xếp ở mức hành vi (`for` + hoán đổi, `sort()`) | ✅ không có `for`/`while` nào |
| **C-3** | Đúng **3** bộ so sánh — không nhiều hơn, không ít hơn | ✅ ba biểu thức so sánh `(a<=b)`, `(hi1<=c)`, `(lo1<=lo2)` |
| **C-4** | Cửa sổ **cố định 3** | ✅ Charter mục 3 liệt cửa sổ ≥ 5, lọc 2 chiều, lọc thích nghi vào **ngoài phạm vi** |
| **C-5** | Hai mẫu trước phải nằm trong **thanh ghi** (mạch tuần tự) | ✅ `hist0_q`, `hist1_q` — 16 flip-flop |

### Vì sao cấm vòng lặp sắp xếp — lý do kỹ thuật, không phải sở thích

| Cách viết | Vấn đề |
|---|---|
| `sort()` / hàm thư viện | Không tồn tại trong tập con tổng hợp được của SystemVerilog |
| `for (i…) if (arr[i] > arr[j]) swap(…)` với biến vòng lặp **cố định** | Công cụ **bung vòng lặp** (unroll) ra thành đúng mạng compare-exchange — chạy được, nhưng **số tầng và số bộ so sánh trở nên không nhìn thấy được trong mã**; không trả lời được Charter mục 2 câu 1 |
| Vòng lặp có **số lần chạy phụ thuộc dữ liệu** | **Không tổng hợp được** — phần cứng không có khái niệm "lặp đến khi xong" trong một chu kỳ |
| Mạng compare-exchange tường minh (cách RTL dùng) | ✅ Đếm được ngay: **3 bộ so sánh, 3 tầng**, và ánh xạ 1-1 sang netlist |

> 💡 Điểm cốt lõi: yêu cầu không phải "vòng lặp không tổng hợp được" (vòng lặp cố định thì
> được), mà là **"vòng lặp che giấu cấu trúc phần cứng"**. Mục tiêu học tập của đề là *nhìn
> thấy* mạng sắp xếp, chứ không phải *có được* kết quả đúng.

## 9. Mã chết đã phát hiện trong RTL

```systemverilog
17    logic [W-1:0] lo1,hi1,lo2,hi2,lo3,med3;
...
25    assign hi2  = (hi1 <= c)   ? c   : hi1;    // hi2  KHONG BAO GIO duoc doc
28    assign lo3  = (lo1 <= lo2) ? lo1 : lo2;    // lo3  KHONG BAO GIO duoc doc
```

Tra toàn bộ 60 dòng RTL: `hi2` và `lo3` chỉ xuất hiện đúng **một lần** — ở chính dòng gán
của chúng. Chúng là **mã chết**.

| Câu hỏi | Trả lời |
|---|---|
| Có phải lỗi không? | ❌ **Không.** Đây là cách viết **đầy đủ** một mạng sắp xếp: mỗi compare-exchange sinh ra cả `min` lẫn `max`, dù bài toán chỉ cần một đầu ra |
| Có tốn diện tích không? | ❌ **Không.** Yosys loại bỏ logic không tới được đầu ra. Netlist **không** chứa mux nào cho `hi2`/`lo3` |
| Có giá trị gì? | ✅ Giữ mã **đối xứng và dễ đọc**: đổi `med3` thành `lo3` là có ngay bộ lọc **min**; giữ `hi2` là có ngay bộ lọc **max**. Đó chính là đề **G05** |
| Hệ quả cho việc đếm | ⚠️ Câu hỏi "mấy bộ ghép kênh?" có **hai đáp án đúng**: **6 viết trong RTL**, nhưng chỉ **4 sống** trong netlist. Xem `03_ARCHITECTURE/block_diagram.md` §3 |

## 10. Chênh lệch đã phát hiện giữa đặc tả và mã nguồn

| # | Vấn đề | Nơi | Mức |
|---|---|---|---|
| 1 | Ngưỡng `count_q >= 2'd1` phải là `>= 2'd2` | RTL dòng 52 | 🔴 **LỖI DUT** — `known_issues.md` |
| 2 | Ánh xạ chân Charter mục 4 chưa hiện thực | RTL | ⚠️ **CHƯA THOẢ** |
| 3 | Xung đột `uio[0]` vào/ra chưa được quyết | Charter mục 4 | ⚠️ chờ giảng viên |
| 4 | `hi2`, `lo3` là mã chết | RTL dòng 25, 28 | ℹ️ cố ý, không phải lỗi |
| 5 | `properties.sv` chỉ có **một** assertion và đang bị `ifdef` tắt | `testbench/properties.sv` | ⚠️ độ phủ hình thức = 0 |
| 6 | Mô hình chuẩn Python **đúng hoàn toàn** | `reference_model.py` | ✅ PASS |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*

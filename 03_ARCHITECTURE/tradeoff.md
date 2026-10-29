# G03 · Đánh đổi kiến trúc (Trade-off Analysis)

---

## 1. Câu hỏi trung tâm của đề

> Charter mục 9: *"Lọc trung vị loại nhiễu xung tốt hơn lọc trung bình. **Chứng minh điều đó
> bằng mô phỏng của chính mình** (một mẫu nhiễu đột biến), và **so sánh diện tích với đề G01**
> để nêu cái giá phải trả."*
>
> Charter mục 10 — *chỗ hay tắc:* *"Viết `sort()` kiểu phần mềm — không tổng hợp ra được phần
> cứng đọc hiểu nổi."*

## 2. Nửa thứ nhất: trung vị loại nhiễu xung tốt hơn — **ĐÃ CHỨNG MINH BẰNG SỐ**

`05_VERIFICATION/golden_model/reference_model.py` chạy **cả hai** bộ lọc trên **cùng một
chuỗi có một xung đột biến**, và đã chạy **PASS** (`python_reference_run.log`):

```python
def test_impulse():          assert median_stream([10,11,250])[-1] == (True,11)
def test_mean_difference():  assert mean_stream  ([10,11,250])[-1] == (True,90)
```

| Chuỗi `10, 11, 250` | Nền tín hiệu ≈ 10,5 | Đầu ra | Sai lệch tuyệt đối |
|---|---:|---:|---:|
| **Trung vị 3 điểm** | 10,5 | **11** | **0,5** |
| **Trung bình 3 điểm** | 10,5 | **90** | **79,5** |

**Trung bình lệch gấp 159 lần trung vị** trên cùng một xung.

### Vì sao — cơ chế, không chỉ con số

| | Trung bình | Trung vị |
|---|---|---|
| Hàm | **Tuyến tính** | **Phi tuyến, hạng-thứ tự (rank-order)** |
| Ảnh hưởng của một mẫu | Đầu ra dịch `Δ/N` với **mọi** `Δ` — **không bị chặn** | Đầu ra chỉ đổi khi mẫu **đổi thứ hạng**; biên độ mẫu **không** vào công thức |
| Điểm gãy (breakdown point) | **0 %** — một mẫu hỏng làm hỏng đầu ra | **~33 %** — chịu được 1/3 số mẫu hỏng |
| Đầu ra có thể là giá trị **mới** không? | ✅ có (`90` không có trong chuỗi vào) | ❌ **không** — luôn là bản sao của một mẫu vào (INV-3) |
| Sai số làm tròn | ✅ có (`>>` là `floor`) | ❌ **không** (INV-6) |

> 💡 **Câu chốt:** với trung bình, giá trị `250` **đi vào phép tính**; với trung vị, `250` chỉ
> đi vào **so sánh** rồi bị loại. Đó là toàn bộ khác biệt.

### Giới hạn phải nêu kèm — **không được bỏ**

| Giới hạn | Bằng chứng / lập luận |
|---|---|
| Cửa sổ 3 chỉ loại được xung **cô lập** | Với `10, 250, 250` trung vị cho **250**: xung lọt qua. Cần cửa sổ `≥ 2m+1` để chịu `m` xung liên tiếp |
| Cửa sổ ≥ 5 nằm **ngoài phạm vi** | Charter mục 3 |
| Ca hai xung liên tiếp (**CC-9**) **chưa được kiểm** | Thiếu ở cả testbench lẫn mô hình Python — `corner_cases.md` §3 |
| Trung vị **kém hơn** trung bình với nhiễu trắng | Với nhiễu Gauss, trung bình là ước lượng tối ưu; trung vị có phương sai lớn hơn ~57 %. Đây là lý do G01/G02 tồn tại song song với G03 |

## 3. So bốn kiến trúc tính trung vị 3 điểm

| # | Kiến trúc | Bộ so sánh | Độ sâu | Bộ nhớ | Chu kỳ/mẫu | Dùng khi |
|---|---|---:|---|---|---:|---|
| **A** | **Mạng compare-exchange 3 tầng** (G03 chọn) | 3 | **3 CE nối tiếp** | 16 FF | 1 | Mặc định; `N` nhỏ |
| **B** | **Biểu thức bool trực tiếp** `med = a^b^c` kiểu min/max lồng | 3 (ẩn) | Tương đương A | 16 FF | 1 | Không lợi gì — công cụ sinh ra cùng logic |
| **C** | **Dùng lại MỘT bộ CE ba lần** (tuần tự hoá) | 1 | 1 CE | 16 FF + thanh ghi tạm + **FSM** | **3** | Cần diện tích rất nhỏ, thông lượng thấp |
| **D** | **Mạng A + pipeline 2 tầng** | 3 | **1 CE mỗi tầng** | 16 + 16 FF | 1 (độ trễ 3) | Cần tần số cao |
| ⬛ | Vòng lặp sắp xếp ở mức hành vi (`sort()`, `for`+swap) | — | — | — | — | **BỊ CẤM** — Charter mục 10 |

### 3.1 Vì sao phương án B không có lợi

Mọi cách viết trung vị ba phần tử đều quy về **ba phép so sánh độ lớn 8 bit**, và ba phép đó
**buộc phải nối tiếp** (phải biết `max(a,b)` mới so được với `c`). Không có tự do đại số nào
để công cụ khai thác — khác hẳn G02, nơi `a+b−c` có biến thể carry-save
(`datapath.md` §4). Bằng chứng: dự đoán từ RTL của G03 **khớp** với STA về cấu trúc.

### 3.2 Vì sao phương án D là hướng tối ưu **đúng** về thời gian

G03 **không có vòng hồi tiếp dữ liệu** (`datapath.md` §6) ⟹ pipeline tự do:

```
   Hien tai (1 tang):
     b[0] ─▶[ CE1 ]─▶[ CE2 ]─▶[ CE3 ]─▶ median_out      7,82 ns
            ◀────────── 28 cell, 15 maj3 ──────────▶

   Pipeline 2 tang:
     b[0] ─▶[ CE1 ]─▶ ▣ ─▶[ CE2 ]─▶[ CE3 ]─▶ median_out  ~3 ns + ~5 ns
                     +16 FF, +1 chu ky do tre
```

Giá: **+16 flip-flop** (≈ +59 % ô nhớ) và **+1 chu kỳ độ trễ**; phải sửa cả đặc tả,
testbench và mô hình chuẩn theo. Charter mục 3 **không cấm** pipeline, nhưng xem §4.

### 3.3 Phương án C và câu chuyện FSM

Dùng lại một bộ CE ba lần giảm phần logic xuống ~1/3 nhưng cần 3 chu kỳ/mẫu **và một FSM
thật** (`fsm.md` §5). Với cảm biến áp suất chạy vài kHz, đánh đổi này khả thi. Nó cũng là
cách duy nhất để G03 nhỏ hơn nữa — nhưng khi đó **không còn là "mạng sắp xếp tổ hợp"** mà
Charter mục 10 yêu cầu.

## 4. Nửa thứ hai: **cái giá phải trả** — so diện tích với G01

Cùng bộ công cụ, cùng `design.sdc`, cùng thư viện ⟹ so chéo hợp lệ.

| Chỉ số | **G03** (trung vị 3) | **G01** (trung bình 4) | Chênh |
|---|---:|---:|---|
| Số cell | **189** | 260 | **−27,3 %** |
| Flip-flop | **27** | 58 | **−53,4 %** |
| Diện tích (µm²) | **1576,512** | 2623,7664 | **−39,9 %** |
| Data arrival (ns) | **7,82** | 4,56 | **+71,5 %** |
| Slack (ns) | **2,10** | 5,36 | **−60,8 %** |
| Tỉ lệ chiếm chu kỳ | **78,2 %** | 45,6 % | +32,6 điểm |
| Công suất (W) | **1,76e-04** | 3,28e-04 | **−46,3 %** |
| Công suất tổ hợp | **32,0 %** | 22,7 % | +9,3 điểm |
| Số cell trên đường tới hạn | **28** | 14 | **×2** |

### 🔎 Kết luận — và nó **ngược với giả định của Charter**

Charter mục 9 viết *"so sánh diện tích với đề G01 để nêu **cái giá phải trả**"*, hàm ý trung
vị đắt hơn về diện tích. **Số liệu thật nói ngược lại:**

> **Trung vị 3 điểm NHỎ HƠN trung bình 4 điểm gần 40 % về diện tích và tốn ít hơn 46 % công
> suất — nhưng CHẬM HƠN 71,5 %. Cái giá phải trả của trung vị là THỜI GIAN, không phải
> DIỆN TÍCH.**

Lý do cơ chế:

| | Trung bình (G01) | Trung vị (G03) |
|---|---|---|
| Cần bộ tích luỹ? | ✅ `sum_q` 10 FF | ❌ **không** |
| Cần bộ đệm vòng + con trỏ + cây mux đọc? | ✅ 32 FF + mux | ❌ **không** — thanh ghi dịch 16 FF |
| Cần thanh ghi ra? | ✅ 8 FF | ✅ 8 FF |
| Logic chính | Bộ cộng — **song song theo bit**, chuỗi carry **một** lần | Ba bộ so sánh — chuỗi mượn **ba** lần **nối tiếp** |
| Độ sâu | `O(W)` một lần | `O(3·W)` ba lần nối tiếp |
| Diện tích | `O(N·W)` bộ nhớ + `O(W)` số học | `O(N·W)` bộ nhớ + `O(N·W)` so sánh |

**Bằng chứng cứng cho "chậm vì ba chuỗi nối tiếp":** cả **15/15** cell `maj3_1` của G03 nằm
trên **một** đường tới hạn (`block_diagram.md` §6). Không đề nào khác trong nhóm G có đặc
điểm này.

### ⚠️ Lưu ý trung thực về phép so sánh này

| Vấn đề | Trạng thái |
|---|---|
| G01 có cửa sổ **4**, G03 có cửa sổ **3** | Không hoàn toàn cùng điều kiện. Charter yêu cầu so G03↔G01 nên bảng trên là câu trả lời trực tiếp, nhưng nó **trộn hai biến** (kiểu lọc **và** chiều dài cửa sổ) |
| Phép so công bằng hơn: **trung vị 3 so với trung bình 3** | ⬜ **CHƯA CHẠY** — cần biến thể RTL trung bình 3 điểm |
| Cả hai số đều ở mức **sau tổng hợp**, chưa P&R | Kết luận chỉ đúng ở mức này |
| G03 hiện **chưa đúng chức năng** (lỗi off-by-one) | Sau khi vá `2'd1 → 2'd2`, phải **chạy lại** tổng hợp và STA; số liệu có thể đổi nhẹ (logic so sánh `>= 2` = 1 dây `count_q[1]`, **rẻ hơn** `>= 1` = 1 cổng OR) |

> Dự đoán sau khi vá: số cell **giảm nhẹ** (bớt ~1 cổng OR), diện tích giảm không đáng kể,
> đường tới hạn **không đổi** (vì nó không đi qua `count_q`). **Phải chạy lại để xác nhận,
> không được ghi số dự đoán vào báo cáo.**

## 5. Nếu phải tối ưu G03 thì tấn công vào đâu

Phân tích 189 cell theo chức năng:

| Khối chức năng | Cell ước tính | Ghi chú |
|---|---:|---|
| 16 FF `hist0_q` + `hist1_q` | 16 | Bộ nhớ cửa sổ |
| 9 FF `median_out` + `valid_out` | 9 | Thanh ghi ra |
| 2 FF `count_q` | 2 | Điều khiển |
| **Ba bộ so sánh** (`maj3_1` 15 + logic kết) | ≈ **40** | ⭐ **Tim của mạch — 100 % đường tới hạn** |
| **Bốn mux 8 bit** (`mux2i_1` 18 + `a21oi_1` 18 + `a21o_1` 7 + …) | ≈ 60 | Compare-exchange |
| Mux giữ/nạp + enable + reset | ≈ 45 | |

| Hướng tối ưu | Cải thiện | Giá | Đánh giá |
|---|---|---|---|
| **Pipeline 2 tầng** (phương án D) | Đường tới hạn ~chia đôi | +16 FF, +1 chu kỳ độ trễ | ✅ Hướng **đúng** nếu cần tốc độ |
| **Chốt `sample_in` bằng thanh ghi vào có enable** | Mạng sắp xếp ngừng chuyển mạch khi `valid_in = 0` ⟹ giảm phần công suất tổ hợp (hiện **32,0 %**) | +8 FF, +1 chu kỳ | ⚠️ Đáng cân nhắc cho ứng dụng pin |
| **Nhân bản bộ so sánh CMP1** để giảm fanout 27 | Giảm delay tại `_186_` (0,40 ns — cell đắt nhất đường) | +logic | ⚠️ Nên để **P&R** tự làm, không sửa tay |
| Tối ưu mux | Rất ít dư địa — ABC đã gộp mạnh | — | ❌ Không đáng |

## 6. Việc Charter yêu cầu mà **chưa làm** được

| Yêu cầu | Trạng thái | Cần gì |
|---|:-:|---|
| Chứng minh trung vị loại xung tốt hơn, **bằng mô phỏng của chính mình** | ⚠️ **Một nửa** | Đã có ở mức **Python** (PASS). Ở mức **Verilog** ca này bị chặn bởi lỗi off-by-one ⟹ phải vá rồi chạy lại |
| So diện tích với G01 | ✅ **ĐÃ LÀM** (§4) | — |
| Ca **hai xung liên tiếp** (nêu giới hạn) | ⬜ chưa chạy | Thêm CC-9 vào TB và Python |
| So **trung vị 3 với trung bình 3** (công bằng) | ⬜ chưa chạy | Viết biến thể RTL, chạy lại flow |
| Chạy lại flow **sau khi vá** lỗi off-by-one | ⬜ chưa chạy | Cần thầy duyệt bản vá trước |

## 7. Những đánh đổi **KHÔNG** được phép trong đề này

| Cám dỗ | Vì sao không được |
|---|---|
| Viết `sort()` hoặc `for`+swap cho gọn | Charter mục 10 cấm thẳng; và nó **che giấu** số bộ so sánh / số tầng ⟹ không trả lời được Charter mục 2 câu 1 |
| Dùng cửa sổ **5 điểm** để loại được xung kép | Charter mục 3: **ngoài phạm vi** |
| Lọc trung vị **hai chiều** hoặc **thích nghi** | Charter mục 3: ngoài phạm vi |
| Đổi sang trung bình vì "nhỏ hơn / nhanh hơn" | Phá huỷ toàn bộ mục đích của đề (loại nhiễu xung) |
| Xoá `hi2`/`lo3` vì "mã chết" | Chúng **không tốn cell nào** (Yosys loại bỏ) và giữ mã đối xứng, dễ chuyển thành bộ lọc min/max (đề G05). Xoá đi là mất giá trị dạy học |
| **Sửa testbench để mô phỏng PASS** | Phán xử ở `known_issues.md` kết luận lỗi nằm ở **DUT**. Sửa TB ở đây là **che lỗi thật** |
| Kết luận "G03 chạy được ở X MHz" từ 7,82 ns | Chưa ký sinh dây, một góc PVT, skew = 0, và ba điểm fanout cao chưa được đệm |
| Sửa netlist bằng tay | Charter mục 3: ngoài phạm vi |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-G03-020, REQ-G03-021, Charter mục 2, mục 9, mục 10.*

# G03 · Nhật ký vá (PATCHLOG)

**Ngày vá:** 2026-09-24 · **Người duyệt:** giảng viên đã duyệt áp dụng toàn bộ bản vá

## 1. Tóm tắt

| # | File | Loại lỗi | Mô tả một dòng | Ảnh hưởng số liệu |
|---|---|---|---|---|
| P-1 | `04_IMPLEMENTATION/rtl/g03_median3.sv` | **Lỗi thiết kế (DUT)** | Ngưỡng phát hành đầu ra `count_q >= 2'd1` sai off-by-one, cửa sổ dài 3 đòi hỏi `count_q >= 2'd2` | **Có — đã chạy lại tổng hợp** |

⚠️ **Đây là đề duy nhất trong đợt này có bản vá chạm vào RTL.** Netlist đã đổi ⇒ mọi số liệu
ở tầng `06_GDSII/` và mọi tên instance trong `03_ARCHITECTURE/` phải được sinh lại. Số liệu
tổng hợp mới đo được ghi ở §3.

## 2. Chi tiết từng bản vá

### P-1 — Sửa ngưỡng phát hành đầu ra (off-by-one trong DUT)

**File:** `04_IMPLEMENTATION/rtl/g03_median3.sv` · **Dòng:** 52 ·
**Phán xử:** lỗi ở **DUT**

**Trước:**
```systemverilog
                if (count_q < 2'd2)
                    count_q <= count_q + 2'd1;

                if (count_q >= 2'd1) begin
                    valid_out <= 1'b1;
                    median_out <= med3;
                end
```

**Sau:**
```systemverilog
                if (count_q < 2'd2)
                    count_q <= count_q + 2'd1;

                if (count_q >= 2'd2) begin   // N-1 = 3-1 = 2: cua so du BA mau THAT
                    valid_out <= 1'b1;
                    median_out <= med3;
                end
```

**Vì sao:** `count_q` đếm số mẫu **đã nhận trước đó**, nên mẫu đang xử lý là mẫu thứ
`count_q + 1`. Muốn xuất kết quả từ mẫu thứ `N` thì ngưỡng đúng là `count_q >= N − 1`. Với
`N = 3` ngưỡng phải là **2**, RTL viết **1**.

Bốn nguồn độc lập cùng chống lại DUT:

| Nguồn | Nói gì |
|---|---|
| Mô hình chuẩn Python `median_stream()` | `len(hist) < 3` ⇒ hai mẫu đầu là `(False, None)`, hợp lệ từ mẫu **thứ ba** |
| Testbench `send(11,0,0)` | Mẫu thứ hai phải có `valid = 0` |
| Bản chất bài toán | Trung vị **3 điểm** cần **3 điểm**; với 2 điểm "trung vị" không được định nghĩa |
| **Chính RTL, dòng 49** | `count_q < 2'd2` — tác giả **biết** ngưỡng đầy là 2 và dùng đúng nó cho bộ đếm |

Dòng 49 và dòng 52 cách nhau **ba dòng** mà dùng **hai hằng số khác nhau** cho cùng một khái
niệm "cửa sổ đã đầy" — đó là bằng chứng nội tại mạnh nhất. So sánh với G02 (cùng khung mã,
`N = 8`, ngưỡng `count_q >= 4'd7` — **đúng**) cho thấy đây là lỗi **sao chép-sửa**, không
phải lựa chọn thiết kế.

**Hệ quả chức năng của lỗi (đã tồn tại trong silicon nếu không vá):** ở mẫu thứ hai sau **mỗi
lần reset**, cửa sổ chứa `hist0_q = 0` — giá trị **reset**, không phải một mẫu áp suất thật —
cộng hai mẫu thật. Mạng sắp xếp cho `med3 = max(min(0,b), min(max(0,b),c)) = min(b,c)`. Tức
mạch phát ra **một kết quả hợp lệ giả** bằng `min(s(1), s(2))` kèm `valid_out = 1`: không
phải giá trị rác dễ phát hiện, mà một số **trông hợp lý nhưng thấp hơn sự thật**. Trong ứng
dụng cảm biến áp suất của Charter mục 1 (đầu ra đi thẳng vào so sánh ngưỡng → van an toàn),
đây là một lần đọc **áp suất thấp giả sau mỗi lần khởi động**.

**Hệ quả vật lý:** `count_q` rộng 2 bit và bão hoà ở 2, nên `count_q >= 2'd2` tương đương
`count_q[1]` — **rẻ hơn** `>= 2'd1` (vốn cần `count_q[1] | count_q[0]`). Dự đoán ở §6 của
`known_issues.md` rằng bản vá **giảm** một cổng đã được xác nhận bằng đo đạc: **189 → 188
cell**, diện tích **1 576,512 → 1 562,7488 µm²** (giảm 13,7632 µm²). Số flip-flop **không
đổi (27)**, đúng như dự kiến vì độ rộng `count_q` không thay đổi.

Chênh lệch cell theo loại (trước → sau):
`and2_0` 5→4 · `and3_1` 0→1 · `nand2b_1` 2→1 · `nor2_1` 16→17 · `o21a_1` 7→6 ·
`o21ai_0` 4→5 · `xnor2_1` 1→0. Tổng: **−1 cell**.

**Không sửa testbench.** Phán xử §4 của `known_issues.md` đã chứng minh testbench đúng, và
mô phỏng sau vá xác nhận: cả **12/12** mốc kiểm của testbench PASS mà không phải đổi một giá
trị kỳ vọng nào.

### Chênh lệch so với bản vá đã soạn trong `known_issues.md`

**Không có.** Bản vá được áp dụng **đúng nguyên văn** khối diff "Vá 1" ở §6 của
`05_VERIFICATION/known_issues.md` — đổi đúng **một ký tự** (`1` → `2`), cộng một comment
giải thích. Bốn bản vá còn lại ở §6 (Vá 2 — tham số hoá ngưỡng theo `N`; Vá 3 — thêm
assertion; Vá 4 — thêm ca kiểm thử; Vá 5 — sinh VCD) **chưa áp dụng**: cả bốn đều được chính
`known_issues.md` xếp loại *"nên có"* chứ không phải *"bắt buộc"*, và không cần thiết để mô
phỏng PASS. Chúng được giữ lại ở §5 theo nguyên tắc sửa tối thiểu.
Comment được viết **không dấu (ASCII)** theo quy ước mã nguồn. Giao diện module (tên cổng,
độ rộng) **không đổi**.

## 3. Kết quả xác minh sau khi vá

| Bước | Trước khi vá | Sau khi vá |
|---|---|---|
| Mô hình chuẩn Python | PASS — `G03 golden reference PASS`, mã thoát 0 | PASS — `G03 golden reference PASS`, mã thoát 0 (không đổi) |
| Biên dịch | PASS, không cảnh báo | PASS, không cảnh báo |
| Mô phỏng | ❌ `FATAL g03_tb.sv:23 valid mismatch x=11`, `Time: 36` (dừng ở **mẫu thứ hai**) | ✅ **`G03 TB completed`**, `$finish` tại `t = 146`, mã thoát 0 — **12/12** mốc kiểm PASS |
| Tổng hợp | 189 cell / 27 FF / **1 576,512 µm²** | ✅ **188 cell / 27 FF / 1 562,7488 µm²** |

Số "trước khi vá" ở dòng tổng hợp được đo lại **từ chính bản gốc đóng băng**
(`08_ORIGINAL_SOURCE/rtl/g03_median3.sv`) bằng đúng lệnh yosys ở dưới, để bảo đảm hai con số
so sánh được với nhau. Yosys **không báo `ERROR` nào** ở cả hai lần chạy.

Lệnh đã chạy để xác minh:

```bash
D=<…>/out/G03_Bo_loc_trung_vi_ba_diem
T=$(mktemp -d)
LIB=<…>/sky130hd.lib

python3 $D/05_VERIFICATION/golden_model/reference_model.py

iverilog -g2012 -o $T/sim.vvp \
   $D/04_IMPLEMENTATION/rtl/*.sv \
   $D/05_VERIFICATION/testbench/*.sv
cd $T && vvp sim.vvp

yosys -Q -p "read_verilog -sv $D/04_IMPLEMENTATION/rtl/*.sv; \
   hierarchy -check -top g03_median3; proc; opt; fsm; opt; memory; opt; techmap; opt; \
   dfflibmap -liberty $LIB; abc -liberty $LIB; setundef -zero; splitnets; opt_clean -purge; \
   stat -liberty $LIB"

# so sanh: cung lenh tren nhung doc tu ban goc dong bang
#   read_verilog -sv $D/08_ORIGINAL_SOURCE/rtl/*.sv
```

> Ghi chú: `05_VERIFICATION/golden_model/` của G03 chỉ có `reference_model.py`, không có file
> `.sv` nào, nên dòng `$D/05_VERIFICATION/golden_model/*.sv` trong mẫu lệnh của SPEC được bỏ
> khỏi lệnh `iverilog`.

## 4. Cách quay lui

```bash
cp 08_ORIGINAL_SOURCE/rtl/*            04_IMPLEMENTATION/rtl/
cp 08_ORIGINAL_SOURCE/golden_model/*   05_VERIFICATION/golden_model/
cp 08_ORIGINAL_SOURCE/testbench/*      05_VERIFICATION/testbench/
```

## 5. Việc còn lại

### 5.1 Bắt buộc — hệ quả của việc vá RTL

Vá P-1 đụng vào **thiết kế**, nên mọi số liệu dẫn xuất từ netlist đều **đã lỗi thời**:

| File / tầng | Vì sao phải làm lại |
|---|---|
| `06_GDSII/synthesis/*` | Netlist đổi: 189 → 188 cell, 1 576,512 → 1 562,7488 µm² |
| `06_GDSII/sta/*` | Netlist đổi ⇒ tên instance đổi. Đường tới hạn **dự kiến** không đổi (không đi qua `count_q`) nhưng **phải chạy lại để xác nhận — không được ghi số dự đoán** |
| `06_GDSII/power/*` | Netlist đổi |
| `02_SPECIFICATION/parameters.md` §3, `06_GDSII/physical_report.md` | Chứa số cell / diện tích / timing cũ |
| `03_ARCHITECTURE/*` | Mọi tên instance (`_341_`, `_326_`, …) sẽ đổi |
| `07_TRACEABILITY/RTM.csv`, `limitations.md` | Trạng thái REQ-G03-001 chuyển từ "chưa chứng minh" sang "đã chứng minh" |

Toàn bộ các file này nằm ngoài ranh giới file được sửa của đợt vá (SPEC §0) và **sẽ được sinh
lại tự động** sau đợt này. Số liệu tổng hợp mới ở §3 là số liệu để đối chiếu khi sinh lại.

### 5.2 Tuỳ chọn — không chặn tiêu chí đạt ở §3

1. **Vá 2 — làm ngưỡng tự suy ra từ `N`.** Thay hai hằng `2'd2` rời rạc bằng
   `localparam int N = 3; localparam int CNT_MAX = N - 1;`. Sau vá này **một** hằng `N` điều
   khiển cả hai chỗ ⇒ hai dòng không thể lệch nhau nữa. Đây là bản vá có giá trị dạy học cao
   nhất vì nó **loại bỏ cả lớp lỗi**, không chỉ trường hợp này. Chưa áp dụng vì nó viết lại
   cấu trúc tham số của module chứ không sửa một lỗi đang biểu hiện.
2. **Vá 3 — thêm assertion bắt được đúng lớp lỗi này.** Đây là điểm yếu nghiêm trọng nhất còn
   lại: `properties.sv` chỉ có **một** assertion (`valid_out |-> $past(valid_in)`) và nó
   **vẫn đúng với RTL lỗi** — nếu chỉ dựa vào assertion thì lỗi P-1 **lọt hoàn toàn**. Nó chỉ
   bị bắt vì testbench kiểm đúng cái mẫu thứ hai. **Không vá trong đợt này**: assertion nằm
   trong `ifdef G03_SVA` và `01_run_sim.sh` không truyền cờ `-DG03_SVA` ⇒ chưa từng chạy,
   không ảnh hưởng kết quả ở §3; vá trọn vẹn cần sửa **cả** script chạy mô phỏng, mà
   `04_IMPLEMENTATION/scripts/` nằm ngoài ranh giới file được sửa (SPEC §0).
3. **Vá 4 — bổ sung ca kiểm thử còn thiếu của Charter mục 8**: CC-9 (hai xung liên tiếp ⇒
   trung vị **không** loại được — giới hạn đã biết của cửa sổ 3 điểm), CC-2 (chuỗi tăng dần
   thuần ⇒ trễ đúng một mẫu, không méo), CC-10 (ba mẫu bằng nhau). Vector chi tiết ở
   `02_SPECIFICATION/corner_cases.md` §4.
4. **Vá 5 — sinh waveform VCD.** Chưa thêm `$dumpfile`/`$dumpvars`; `05_VERIFICATION/waveforms/`
   vẫn trống, trong khi Charter mục 3 yêu cầu artifact số.

## 6. Áp dụng lại (2026-09-24)

**Vì sao phải làm lại:** một bước sinh tài liệu tự động (`generate2.py`) đã chép mã nguồn cũ từ
`runs/<mã>/work/` **đè lên** `04_IMPLEMENTATION/rtl/`, `05_VERIFICATION/golden_model/` và
`05_VERIFICATION/testbench/`. Với G03 đây là mất mát nặng nhất trong đợt: bản vá P-1 chạm vào
**RTL**, nên việc ghi đè đã **đưa lỗi off-by-one quay lại thiết kế**. Lỗi của bộ sinh đã được
sửa. Trước khi áp dụng lại, ba thư mục này đã được đối chiếu với `08_ORIGINAL_SOURCE/` và
**trùng khít** — xác nhận `g03_median3.sv` đã quay về ngưỡng sai `count_q >= 2'd1`.

**Đã áp dụng lại:** **1/1** bản vá — P-1 (`04_IMPLEMENTATION/rtl/g03_median3.sv` dòng 52):
`count_q >= 2'd1` → `count_q >= 2'd2`, kèm comment giải thích `N-1 = 3-1 = 2`. Testbench và mô
hình chuẩn **không** bị chạm, đúng như §2. Không phát hiện chênh lệch nào giữa mô tả trong
PATCHLOG và bản vá thực tế.

**Kết quả xác minh lần này** (chạy bằng đúng lệnh ở §3):

| Bước | Kết quả đo lần này | Khớp §3? |
|---|---|---|
| Mô hình chuẩn Python | `G03 golden reference PASS`, mã thoát 0 | ✅ |
| Biên dịch iverilog 12.0 | thành công, mã thoát 0, không cảnh báo | ✅ |
| Mô phỏng | `G03 TB completed`, `$finish` tại `t = 146`, mã thoát 0 — 12/12 mốc kiểm PASS, không `ERROR`/`FATAL`/`mismatch` | ✅ |
| Tổng hợp yosys 0.33 + sky130hd | **188 cell / 27 FF (`dfxtp_1`) / 1 562,7488 µm²** | ✅ khớp chính xác |

Đây là đề duy nhất mà số liệu tổng hợp là **bằng chứng bản vá RTL đã vào đúng chỗ**: nếu bản vá
thiếu thì yosys sẽ cho lại 189 cell / 1 576,512 µm² của bản gốc. Con số đo được là **188 cell /
27 FF / 1 562,7488 µm²**, trùng khớp tuyệt đối với §3. Mục §5.1 (phải sinh lại tầng `06_GDSII/`,
`03_ARCHITECTURE/`, `07_TRACEABILITY/`) **vẫn còn nguyên hiệu lực** và §5.2 giữ nguyên — lần áp
dụng lại này không thêm bản vá nào ngoài P-1.

# G03 — Bộ lọc trung vị ba điểm · Ghi chú thực hiện

## 1. Bài toán này thực chất là gì

Bề ngoài G03 là "tìm số ở giữa của ba số". Thực chất nó là bài toán **lọc hạng-thứ tự
(rank-order filtering) trên một dòng dữ liệu**, và nó tồn tại để giải quyết đúng một thứ mà
bộ lọc tuyến tính **không thể** giải quyết: **nhiễu xung**.

Bối cảnh của Charter mục 1 nói rõ vì sao: cảm biến áp suất công nghiệp bị nhiễu xung do relay
đóng ngắt, động cơ khởi động, phóng tĩnh điện. Đầu ra của khối đi thẳng vào tầng so sánh
ngưỡng → van an toàn. Một xung giả làm trung bình vọt lên có thể **kích van sai** — đó là hậu
quả vật lý, không chỉ là một số xấu trên màn hình.

Điểm mấu chốt về bản chất: **trung bình là hàm tuyến tính, trung vị là hàm phi tuyến**. Với
trung bình, mọi mẫu đều **đi vào phép tính** và ảnh hưởng của một mẫu hỏng biên độ `Δ` là
`Δ/N` — **không bị chặn**. Với trung vị, mẫu chỉ đi vào **so sánh** rồi bị loại nếu nó nằm ở
rìa; biên độ của nó **không hề xuất hiện** trong kết quả. Thuật ngữ thống kê gọi đây là
*breakdown point*: trung bình có 0 %, trung vị ba điểm có ~33 %.

Nhưng bài toán cũng mang theo một ràng buộc cứng: **cấm sắp xếp bằng vòng lặp phần mềm**.
Đó không phải sở thích của giảng viên — đó là vì mục tiêu học tập là **nhìn thấy** mạng sắp
xếp, đếm được số bộ so sánh và số tầng. Một vòng `for` + `swap` sẽ được công cụ bung ra thành
đúng mạng đó, chạy được, nhưng cấu trúc trở nên **vô hình trong mã**.

## 2. Bản chất kỹ thuật — cơ chế hoạt động

Cơ chế cốt lõi là **mạng compare-exchange**. Một compare-exchange `CE(x,y)` trả về cặp đã sắp
`(min(x,y), max(x,y))`. Mạng trung vị ba phần tử cần đúng **ba** CE:

```
   CE1 = CE(a, b)         -> lo1 = min(a,b),    hi1 = max(a,b)
   CE2 = CE(hi1, c)       -> lo2 = min(hi1,c)
   CE3 = CE(lo1, lo2)     -> med3 = max(lo1,lo2)      <- KET QUA

   median3(a,b,c) = max( min(a,b), min(max(a,b), c) )
```

Đây mới là nút thắt cần chỉ ra, và nó **không** nằm ở chỗ người ta tưởng:

> **Ba CE này BẮT BUỘC nối tiếp nhau.** Phải biết `max(a,b)` mới so được với `c`; phải có
> `lo2` mới so được với `lo1`. Và mỗi CE chứa một **bộ so sánh độ lớn 8 bit**, mà so sánh
> 8 bit **không phải một cổng** — nó là một phép trừ có mượn, tức một **chuỗi mượn 8 tầng
> nối tiếp**. Vậy đường dữ liệu dài nhất là **ba chuỗi mượn mắc nối tiếp**, chứ không phải
> "ba phép so sánh".

Số liệu thật xác nhận rất đẹp: netlist có **15 cell `maj3_1`** (`maj3` là cell "đa số ba
ngõ" — chính là hàm sinh mượn `borrow[i+1] = maj(~a[i], b[i], borrow[i])`). Và **cả 15 cell
đó đều nằm trên MỘT đường tới hạn**: 6 của CMP1, 2 của CMP2, 7 của CMP3. Đếm từ
`synth_stat.txt` = 15; đếm từ danh sách cell của đường tới hạn = 15. Không một `maj3` nào
nằm ngoài.

Hệ quả là chân dung điện của G03 hoàn toàn khác họ hàng trung bình của nó: **sâu và hẹp**.
Đường tới hạn **7,82 ns** — chiếm **78,2 %** chu kỳ giả định 10 ns — trong khi đường phụ
(`valid_in → valid_out`) chỉ **1,22 ns**. Chênh nhau **6,4 lần**.

## 3. Đọc mã nguồn: RTL làm gì, từng dòng quan trọng

**(a) Mạng sắp xếp, dòng 19–29:**

```systemverilog
    // Compare-exchange stage 1: a,b
    assign lo1 = (a <= b) ? a : b;
    assign hi1 = (a <= b) ? b : a;
    // Compare-exchange stage 2: hi1,c
    assign lo2 = (hi1 <= c) ? hi1 : c;
    assign hi2 = (hi1 <= c) ? c : hi1;
    // Compare-exchange stage 3: lo1,lo2
    assign lo3 = (lo1 <= lo2) ? lo1 : lo2;
    assign med3 = (lo1 <= lo2) ? lo2 : lo1;
```

Sáu `assign`, **ba** biểu thức so sánh. Dùng `<=` (không nghiêm ngặt) **nhất quán ở cả ba**
là điều kiện để các ca trùng lặp (`median3(2,9,2)`) ra đúng. Nếu một trong ba đổi thành `<`,
mạng vẫn "gần đúng" nhưng sai ở biên.

Chú ý `hi2` và `lo3` **không bao giờ được đọc** — đó là **mã chết có chủ đích**: viết đầy đủ
một CE giữ mã đối xứng và dễ đọc, và Yosys loại bỏ chúng nên **không tốn cell nào**. Hệ quả
cho câu hỏi Charter mục 2 câu 1: có **hai đáp án đúng** — 6 mux **viết ra**, 4 mux **sống**.

**(b) Thanh ghi dịch, dòng 46–47:**

```systemverilog
                hist0_q <= hist1_q;
                hist1_q <= sample_in;
```

Hai dòng này thay thế toàn bộ hạ tầng của G01/G02 (bộ đệm vòng + con trỏ + cây mux đọc).
Với `N = 3` (chỉ cần nhớ **hai** mẫu), thanh ghi dịch là lựa chọn rõ ràng đúng — và nó giải
thích vì sao G03 chỉ có **27 flip-flop** so với 94 của G02.

**(c) Ngưỡng phát hành — dòng 49–55, chỗ có LỖI:**

```systemverilog
                if (count_q < 2'd2)
                    count_q <= count_q + 2'd1;

                if (count_q >= 2'd1) begin      // <<<< SAI: phai la 2'd2
                    valid_out <= 1'b1;
                    median_out <= med3;
                end
```

Hai dòng cách nhau **ba dòng** dùng **hai hằng số khác nhau** cho cùng khái niệm "cửa sổ đã
đầy". Ngưỡng đúng là `N − 1 = 2`. Phán xử đầy đủ: `05_VERIFICATION/known_issues.md`.

**(d) Bí danh, dòng 31–33:** `assign a = hist0_q; assign b = hist1_q; assign c = sample_in;`
— **0 cell**. Thú vị: Yosys coi `a`/`b` là tên chính và **đặt tên flip-flop trong netlist là
`a[0..7]`, `b[0..7]`** chứ không phải `hist0_q`/`hist1_q`. Biết điều này mới đọc được STA.

## 4. Vì sao chọn kiến trúc này

| Tiêu chí | Mạng CE 3 tầng (đã chọn) | Dùng lại 1 CE ba lần | Vòng lặp hành vi |
|---|---|---|---|
| Bộ so sánh | 3 | 1 | ẩn (công cụ bung ra) |
| Chu kỳ/mẫu | 1 | 3 | 1 |
| Cần FSM? | ❌ | ✅ | ❌ |
| Đếm được cấu trúc từ mã? | ✅ | ✅ | ❌ **không** |
| Charter cho phép? | ✅ | ⚠️ mất tính "tổ hợp" (mục 10) | ❌ **cấm** (mục 10) |

Với `N = 3`, mạng song song là lựa chọn hiển nhiên đúng: chỉ 3 CE, không đáng tuần tự hoá,
và nó giữ được **tính đọc được** mà Charter đòi hỏi.

## 5. Cách thực hiện — lộ trình 8 bước từ đặc tả tới GDSII

| Bước | Việc | Trạng thái thật của G03 |
|---|---|---|
| 1 | Suy phương trình `median3` + chứng minh vét cạn 6 hoán vị | ✅ `functional_spec.md` §3.1 |
| 2 | Viết mô hình chuẩn Python **cùng với** mô hình trung bình để so | ✅ `reference_model.py` — **PASS 5/5** |
| 3 | Viết RTL: mạng CE tường minh + thanh ghi dịch | ⚠️ viết rồi, **có lỗi ngưỡng** |
| 4 | Viết testbench phủ Charter mục 8 | ✅ tốt — **bắt được lỗi ngay ca thứ hai** |
| 5 | Mô phỏng RTL | 🔴 **RAN_WITH_ISSUES** — dừng tại `t = 36` |
| 6 | Tổng hợp | ✅ 189 cell · 27 FF · 1576,512 µm² |
| 7 | STA + công suất | ✅ arrival 7,82 ns · slack 2,10 ns · 1,76e-04 W |
| 8 | P&R → DRC/LVS → GDSII | ⬜ **CHƯA CHẠY** |

> ⚠️ Với G03, bước 6–7 đang mô tả một mạch **chưa đúng chức năng**. Sau khi vá, **phải chạy
> lại toàn bộ bước 6–7** — khác với G02, nơi bản vá chỉ đụng testbench.

## 6. Số liệu thật đã đo được và cách đọc chúng

| Chỉ số | Giá trị | Nguồn |
|---|---:|---|
| Số cell | 189 | `synth_stat.txt` |
| Flip-flop | 27 | như trên |
| Diện tích | 1576,512 µm² | như trên |
| Startpoint → Endpoint | `_341_` (= `b[0]` = `hist1_q[0]`) → `_326_` (= `median_out[1]`) | `timing_report_max.txt` |
| Data arrival | **7,82 ns** | như trên |
| Slack | **2,10 ns** (MET) | như trên |
| Số cell trên đường tới hạn | **28**, trong đó **15 `maj3_1`** | như trên |
| WNS / TNS | 0,00 / 0,00 | `wns.txt`, `tns.txt` |
| Hold slack nhỏ nhất | 0,43 ns (MET) | `timing_report_min.txt` |
| Công suất | 1,76e-04 W (tổ hợp **32,0 %** · tuần tự 68,0 %) | `power_report.txt` |

**Những con số này CHỨNG MINH:**
- Mạng sắp xếp tổng hợp được ra standard cell sky130 thật; **27 flip-flop khớp chính xác**
  tính tay (8 + 8 + 2 + 8 + 1), không dư không thiếu.
- Charter mục 10 nói *"16 ô nhớ (2 mẫu trước) + mạng sắp xếp **tổ hợp**"* — cả hai đều đúng:
  16 FF cho cửa sổ, và mạng có **0 flip-flop**.
- Charter mục 10 nói *"Mạng 3 phần tử = 3 bộ so sánh"* — đúng, và 15 cell `maj3_1` là chứng
  cứ vật lý cho ba chuỗi mượn.

**Những con số này KHÔNG chứng minh:**
- **Không** chứng minh mạch làm đúng chức năng — mô phỏng dừng ở chu kỳ thứ tư, **và** đã
  phán xử rằng thiết kế sai.
- **Không** chứng minh "G03 chạy được ở 100 MHz". `7,82 ns` **chưa có ký sinh dây**, chỉ
  **một** góc PVT `tt_025C_1v80`, **skew = 0**.
- **Không** chứng minh công suất thật của ứng dụng.

**Ba con số đáng bàn nhất:**

*(a) Slack 2,10 ns — mỏng nhất nhóm G* (G01 5,36 · G02 5,48 · G04 3,16). Đường tới hạn chiếm
**78,2 %** chu kỳ. Cộng thêm ba điểm fanout cao trên đường (27, 13, 13) chưa tính ký sinh
dây, **G03 là đề có nguy cơ vi phạm timing cao nhất nhóm sau khi P&R**.

*(b) Công suất tổ hợp 32,0 % — cao nhất trong ba đề lọc* (G01 22,7 %, G02 18,1 %). Đúng với
chân dung "logic nặng, nhớ nhẹ". Một phần là do mạng sắp xếp **không bị gating**: nó chạy
liên tục kể cả khi `valid_in = 0` (`control.md` §3).

*(c) 15/15 cell `maj3_1` nằm trên một đường.* Đây là số liệu có thể kiểm lại trong ba mươi
giây và nó tóm tắt toàn bộ bản chất của đề.

## 7. Trả lời các câu hỏi kỹ thuật của Charter (mục 2)

**Câu 1 — Mạng sắp xếp ba phần tử gồm mấy bộ so sánh và mấy bộ ghép kênh?**
✅ **Trả lời được, và có hai đáp án đúng:**
- **3 bộ so sánh** (`a<=b`, `hi1<=c`, `lo1<=lo2`) — khớp Charter mục 10.
- **6 bộ ghép kênh 8 bit viết trong RTL**, nhưng chỉ **4 sống** trong phần cứng (`hi2` và
  `lo3` là mã chết, bị Yosys loại). Netlist có `mux2i_1 × 18` vì ABC đã gộp phần lớn logic
  mux vào cell phức hợp — **không đếm mux bằng cách đếm cell `mux*`**.

**Câu 2 — So kết quả trung vị với trung bình trên chuỗi có một xung đột biến?**
✅ **Trả lời được bằng số đã chạy PASS.** Chuỗi `10, 11, 250`:
trung vị → **11**; trung bình → **90**. Nền tín hiệu ≈ 10,5 ⟹ trung vị lệch **0,5**, trung
bình lệch **79,5** — **gấp 159 lần**. Nguồn: `reference_model.test_impulse` và
`test_mean_difference`, `python_reference_run.log` = PASS.
⚠️ Ở mức **Verilog** ca này bị chặn bởi lỗi off-by-one (nó nằm đúng ở `send(250,1,11)`).

**Câu 3 — Vì sao đề cấm dùng vòng lặp sắp xếp ở mức hành vi?**
✅ **Trả lời được.** Lý do **không** phải "không tổng hợp được" — vòng lặp có số lần chạy cố
định thì tổng hợp được. Lý do thật là: vòng lặp **che giấu cấu trúc phần cứng**. Số bộ so
sánh, số tầng, độ sâu tổ hợp trở nên vô hình trong mã ⟹ không trả lời được câu 1, không dự
đoán được đường tới hạn, không đối chiếu được với STA. Còn vòng lặp có số lần chạy **phụ
thuộc dữ liệu** thì thật sự không tổng hợp được.

## 8. Trả lời câu phân tích riêng (Charter mục 9)

Câu hỏi có hai nửa.

**Nửa 1 — chứng minh trung vị loại nhiễu xung tốt hơn:** ✅ đã chứng minh bằng số ở §7 câu 2.
Kèm theo **giới hạn bắt buộc phải nêu**: cửa sổ 3 chỉ loại được xung **cô lập**. Với hai xung
liên tiếp (`10, 250, 250`) trung vị cho **250** — xung lọt qua. Ca này (**CC-9**) **chưa được
kiểm** ở cả testbench lẫn mô hình Python.

**Nửa 2 — so diện tích với G01 để nêu cái giá phải trả:** ✅ đã làm, và kết quả **ngược với
giả định ngầm của Charter**:

| Chỉ số | G03 (trung vị 3) | G01 (trung bình 4) | Chênh |
|---|---:|---:|---|
| Diện tích | **1576,512 µm²** | 2623,7664 µm² | **−39,9 %** |
| Flip-flop | 27 | 58 | −53,4 % |
| Công suất | 1,76e-04 W | 3,28e-04 W | −46,3 % |
| **Arrival** | **7,82 ns** | **4,56 ns** | **+71,5 %** |
| Slack | 2,10 ns | 5,36 ns | −60,8 % |

> **Cái giá phải trả của trung vị là THỜI GIAN, không phải DIỆN TÍCH.** Trung vị bỏ được bộ
> tích luỹ, bộ đệm vòng, con trỏ và cây mux đọc — nên nhỏ hơn. Nhưng nó phải mắc **ba chuỗi
> mượn nối tiếp**, nên chậm hơn.

⚠️ **Trung thực về phép so này:** G01 có cửa sổ **4**, G03 có cửa sổ **3** — phép so trộn hai
biến. Phép so công bằng hơn (trung vị 3 với **trung bình 3**) **chưa chạy**.

## 9. Những chỗ sinh viên hay sai và cách phát hiện

| # | Sai lầm | Hậu quả | Phát hiện bằng bằng chứng nào |
|---|---|---|---|
| 1 | **Ngưỡng `count_q >= 1` thay vì `>= 2`** | Xuất một kết quả hợp lệ **giả** ở mẫu thứ hai, tính từ cửa sổ có giá trị reset `0` | 🔴 **Đây là lỗi thật của đề.** Ca `send(11,0,0)` bắt ngay. Quy tắc nhớ: ngưỡng = `N − 1`; đối chiếu G02 dùng `>= 7` cho `N = 8` |
| 2 | Viết `sort()` hoặc `for`+swap | Cấu trúc phần cứng **vô hình** trong mã | Thử trả lời "mấy bộ so sánh, mấy tầng?" — không trả lời được từ mã |
| 3 | Dùng `<` ở một CE và `<=` ở CE khác | Sai ở ca **trùng lặp** (`median3(2,9,2)`) | Ca CC-6 trong TB: `send(2,1,2); send(9,1,2); send(2,1,2);` |
| 4 | Khai `logic signed [7:0]` | `255` thành `−1` ⟹ `median3(0,255,128)` ra `0` thay vì `128` | Ca biên CC-7 trong TB: `send(0,…); send(255,…); send(128,1,128);` |
| 5 | Nối nhầm CE3 thành `CE(hi1, lo2)` thay vì `CE(lo1, lo2)` | Ra **max** thay vì trung vị ở một số hoán vị | Ca CC-5 (ba hoán vị liên tiếp `3,1,2`). Một chuỗi hằng sẽ **không** bắt được |
| 6 | Tưởng `median_out` thuộc mạng sắp xếp | Kết luận sai rằng "mạng có flip-flop" | Netlist: mạng là `assign` thuần, 0 FF. `median_out` là thanh ghi **sau** mạng |
| 7 | Đếm mux bằng cách đếm cell `mux2i_1` | Ra 18, không khớp lý thuyết 32 | ABC gộp mux vào `a21oi_1`/`a21o_1`/`o21a_1`. Phải đếm từ **RTL** rồi đối chiếu diện tích |
| 8 | Xoá `hi2`/`lo3` vì "mã chết, tốn diện tích" | Không tốn gì cả, và mất tính đối xứng | Netlist **không** chứa mux nào cho chúng |
| 9 | Phát biểu "trung vị loại được mọi nhiễu xung" | Sai — **hai xung liên tiếp lọt qua** | Tính tay: `median3(250,250,10) = 250`. Ca CC-9 **chưa có**, phải bổ sung |
| 10 | Kết luận "trung vị đắt hơn trung bình" theo cảm tính | Số liệu nói ngược: G03 nhỏ hơn G01 **39,9 %** | So bảng §8 |
| 11 | Tin rằng assertion hiện có đủ để bắt lỗi | `valid_out \|-> $past(valid_in)` **vẫn đúng** với RTL lỗi | `known_issues.md` §5 |

## 10. Câu hỏi mentor nên đặt khi bảo vệ

| # | Câu hỏi | Đáp án mong đợi |
|---|---|---|
| 1 | Cửa sổ dài 3 thì ngưỡng phát hành phải là bao nhiêu, và vì sao? | `count_q >= N − 1 = 2`. `count_q` đếm mẫu **đã nhận trước đó**; mẫu hiện tại là thứ `count_q+1` |
| 2 | RTL viết `>= 1`. Đó là lỗi hay lựa chọn thiết kế? Chứng minh. | **Lỗi.** Ba nguồn độc lập chống lại: mô hình chuẩn (`len<3`), testbench (`send(11,0,0)`), toán học (trung vị 3 điểm cần 3 điểm). Và chính dòng 49 của RTL dùng đúng hằng `2` |
| 3 | Mạch thật sự xuất ra giá trị gì ở mẫu thứ hai? | `min(s(1), s(2))`. Vì `max(min(0,b), min(max(0,b),c)) = max(0, min(b,c)) = min(b,c)` với `b,c` không dấu |
| 4 | Mạng sắp xếp 3 phần tử gồm mấy bộ so sánh, mấy mux? | 3 bộ so sánh; **6 mux viết ra, 4 mux sống** (`hi2`, `lo3` là mã chết) |
| 5 | Vì sao G03 nhỏ hơn G01 mà lại chậm hơn? | Nhỏ vì bỏ được bộ tích luỹ + bộ đệm vòng + con trỏ + mux đọc. Chậm vì **ba chuỗi mượn 8 bit mắc nối tiếp** |
| 6 | Chứng minh "cả 15 cell `maj3_1` nằm trên đường tới hạn". | Đếm `maj3_1` ở `synth_stat.txt` = 15; đếm trong danh sách cell đường tới hạn = 6 + 2 + 7 = 15 |
| 7 | Vì sao startpoint là `b[0]` chứ không phải `b[7]`? | Bit **thấp nhất** là đầu chuỗi mượn ⟹ đường dài nhất |
| 8 | Vì sao dự đoán đường tới hạn ở G03 khớp với STA, còn ở G02 thì sai hẳn? | G03 **không có tự do đại số** — ba CE phụ thuộc nhau bắt buộc. G02 có `a+b−c` mà ABC dựng được nén carry-save 3:2 |
| 9 | Vì sao đề cấm `sort()`? | Vì nó **che giấu cấu trúc**, không phải vì không tổng hợp được |
| 10 | Trung vị có loại được **mọi** nhiễu xung không? | **Không.** Cửa sổ 3 chỉ loại được xung **cô lập**; hai xung liên tiếp lọt qua. Cần `N ≥ 2m+1` cho `m` xung — nhưng `N ≥ 5` nằm ngoài phạm vi |
| 11 | `median_out` có nằm trong mạng sắp xếp không? | **Không** — nó là thanh ghi đầu ra **sau** mạng. Mạng có 0 flip-flop |
| 12 | Nếu áp bản vá thì phải chạy lại những gì? | **Toàn bộ tầng 06_GDSII** (synthesis, STA, power) vì vá đụng RTL, cộng mọi tài liệu chứa số |
| 13 | Số `7,82 ns` cho phép kết luận gì về tần số? | **Không gì cả.** Chưa ký sinh dây, một góc PVT, skew = 0, và có ba điểm fanout cao (27/13/13) sẽ tệ hơn sau routing |

## 11. Giới hạn: đã chứng minh được gì, chưa chứng minh được gì

**Đã chứng minh:**
- Hàm `median3` đúng trên **cả 6 hoán vị** và các ca trùng lặp — chứng minh vét cạn, không
  phải mô phỏng mẫu (`reference_model`, PASS).
- Trung vị loại nhiễu xung tốt hơn trung bình, **bằng số của chính hồ sơ**: `11` so với `90`
  trên cùng chuỗi `10, 11, 250`.
- RTL tổng hợp được ra 189 standard cell sky130, **27 flip-flop khớp chính xác** tính tay.
- Mạng sắp xếp là **tổ hợp thuần** (0 flip-flop) — đúng Charter mục 10.
- Đường tới hạn ở mức sau tổng hợp: `b[0] → median_out[1]`, 28 cell, 7,82 ns, và **15/15
  cell `maj3_1` nằm trên đó**.
- So sánh diện tích với G01 đã hoàn thành, với kết luận ngược với giả định ban đầu.
- 🔴 Lỗi mô phỏng đã được **định vị và phán xử**: **lỗi nằm trong DUT**, bản vá là một ký tự.

**Chưa chứng minh:**
- **Chức năng của RTL — và đã biết là SAI** ở mẫu thứ hai sau reset. REQ-G03-001 **CHƯA THOẢ**.
- Ca **hai xung liên tiếp** (CC-9) — giới hạn quan trọng nhất của đề, **chưa kiểm ở đâu cả**.
- Ca chuỗi tăng dần thuần và ca ba mẫu bằng nhau ở mức Verilog.
- Phép so **công bằng** trung vị 3 với trung bình 3 — chưa chạy.
- Số liệu **sau khi vá** — toàn bộ tầng 06_GDSII phải chạy lại.
- Netlist tương đương RTL — chưa mô phỏng gate-level.
- Biên an toàn qua các góc PVT — ⚠️ **đặc biệt đáng lo với slack chỉ 2,10 ns**.
- Độ trễ thật sau routing — ba điểm fanout cao chưa được tính ký sinh dây.
- Ánh xạ chân Charter mục 4 — **chưa có vỏ `tt_um_*`**; xung đột `uio[0]` chưa được quyết.
- Layout, DRC, LVS, GDSII — chưa chạy flow vật lý.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*

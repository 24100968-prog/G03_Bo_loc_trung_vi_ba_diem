# G03 · Ca biên và ca góc (Corner Cases)

> Mỗi ca phải trả lời được: *"ca này bắt được lỗi gì mà ca khác không bắt được?"*

Nguồn đối chiếu: testbench thật `05_VERIFICATION/testbench/g03_tb.sv` (65 dòng) và
mô hình chuẩn `05_VERIFICATION/golden_model/reference_model.py`.

---

## 1. Tiêu chí phân loại riêng của G03

Trung vị là hàm **phi tuyến, bất biến với đơn điệu**. Nó không có "chuỗi carry" hay "tràn số"
để ép. Thứ duy nhất đáng ép là **thứ tự tương đối** của ba phần tử và **đường đi qua mạng
sắp xếp**. Vì vậy cách phân loại có ý nghĩa nhất là:

| Lớp | Ép vào đâu | Loại lỗi bắt được |
|---|---|---|
| **L-P** (Permutation) | 6 hoán vị thứ tự của `(a,b,c)` | Nối nhầm dây giữa ba tầng CE, đảo `min`/`max` |
| **L-T** (Tie) | Các phần tử **bằng nhau** | Dùng `<` thay cho `<=` không nhất quán ⟹ mất một nhánh |
| **L-W** (Warm-up) | Bộ đếm `count_q` và ngưỡng xuất | **Off-by-one** — 🔴 chính là lỗi của đề này |
| **L-I** (Impulse) | Xung đột biến cô lập | Chứng minh giá trị của trung vị so với trung bình |
| **L-G** (Gating) | `if (valid_in)` | Cửa sổ tự trượt khi không có mẫu |
| **L-B** (Bounds) | `0` và `255` | Lỗi so sánh có dấu/không dấu, tràn ở bộ trừ so sánh |

> Chú ý: lớp **L-B** ở G03 **không** kiểm tràn số học (trung vị không cộng gì cả) mà kiểm
> **bộ so sánh 8 bit không dấu**. Nếu ai đó khai `logic signed [7:0]`, thì `255` thành `−1`
> và `median3(0,255,128)` cho `0` thay vì `128`.

---

## 2. Ca bắt buộc của Charter mục 8

Charter mục 8: *"Chuỗi phẳng có một mẫu nhiễu đột biến · chuỗi tăng dần · ba mẫu bằng nhau ·
so sánh với kết quả lọc trung bình"*.

| ID | Ca Charter | Lớp | Vì sao ca này tồn tại — lý do kỹ thuật | Đã có trong TB? |
|---|---|:-:|---|---|
| **CC-1** | Chuỗi phẳng có **một mẫu nhiễu đột biến** | L-I | ⭐ **Ca định nghĩa lý do tồn tại của đề.** Với `10, 11, 250`, trung vị cho **11** — giá trị 250 **hoàn toàn không ảnh hưởng** (INV-5). Đây là bằng chứng trực tiếp cho Charter mục 9 | ✅ TB dòng 38–40 (`send(250,1,11)`) — nhưng đang bị chặn bởi lỗi off-by-one |
| **CC-2** | **Chuỗi tăng dần** | L-P | Với chuỗi đơn điệu, trung vị = mẫu **giữa** ⟹ bộ lọc chỉ **trễ một mẫu, không méo** (INV-10). Ca này bắt lỗi đảo `min`/`max`: nếu đảo, đầu ra sẽ là mẫu mới nhất hoặc cũ nhất thay vì mẫu giữa | ⚠️ **gián tiếp** — TB có `3,1,2` và `0,255,128` nhưng **không có chuỗi tăng dần thuần** |
| **CC-3** | **Ba mẫu bằng nhau** | L-T | Ép mọi so sánh vào biên `x <= x`. Nếu một trong ba CE dùng `<` thay `<=`, nhánh chọn đổi và kết quả có thể ra sai ở ca trùng lặp | ⚠️ TB có `2,2` và `2,9,2` (**hai** bằng nhau) nhưng **thiếu ca ba bằng nhau** |
| **CC-4** | **So sánh với kết quả lọc trung bình** | L-I | Đây là ca **so sánh hai kiến trúc**, không phải ca kiểm DUT. Nó định lượng giá trị của trung vị | ❌ **không thể có trong TB Verilog** (không có DUT trung bình). ✅ Có ở Python: `test_impulse` vs `test_mean_difference` |

### Bằng chứng số cho CC-1 + CC-4 — đã chạy và PASS

`reference_model.py` chứa **cả hai** bộ lọc trên **cùng một chuỗi**:

```python
def test_impulse():
    assert median_stream([10,11,250])[-1] == (True,11)

def test_mean_difference():
    assert mean_stream([10,11,250])[-1] == (True,90)
```

Kết quả chạy thật (`python_reference_run.log`): `G03 golden reference PASS`.

| Chuỗi vào | Nền tín hiệu | Trung vị 3 điểm | Trung bình 3 điểm | Sai lệch so với nền |
|---|---:|---:|---:|---|
| `10, 11, 250` | ≈ 10,5 | **11** | **90** | trung vị: **+0,5** · trung bình: **+79,5** |

> ⭐ **Đây là con số trả lời Charter mục 9.** Một xung đơn biên độ 250 trên nền ~10 làm
> đầu ra trung bình lệch **+79,5 đơn vị**, trong khi trung vị lệch **+0,5** — nhỏ hơn
> **159 lần**. Và đây là số từ một lần chạy **PASS**, không phải ước lượng.

---

## 3. Ca tự xây dựng bổ sung (REQ-G03-011 yêu cầu ≥ 2, có ca biên)

| ID | Ca | Lớp | Lý do kỹ thuật | Trạng thái |
|---|---|:-:|---|---|
| **CC-5** | **Hoán vị đầy đủ** `3 → 1 → 2` cho cửa sổ `(11,250,3)`, `(250,3,1)`, `(3,1,2)` | L-P | Ba cửa sổ liên tiếp phủ ba **hình dạng thứ tự khác nhau**: mẫu mới là nhỏ nhất, là nhỏ nhất, rồi là ở giữa. Bắt lỗi nối dây giữa CE2 và CE3 | ✅ TB dòng 43–45 |
| **CC-6** | **Ca trùng lặp** `2,2` rồi `2,9,2` | L-T | Ép `x <= x` ở nhiều vị trí khác nhau trong mạng. `median3(2,9,2)` là ca hiểm nhất: hai phần tử bằng nhau **không kề nhau** | ✅ TB dòng 48–50 |
| **CC-7** | **Ca biên** `0 → 255 → 128` | L-B | ⭐ Ép **cả hai** cực trị của dải 8 bit **cùng lúc**, và đặt trung vị ở giữa. Bắt lỗi khai báo `signed`: nếu `signed`, `255 = −1` ⟹ trung vị thành `0` thay vì `128` | ✅ TB dòng 58–60 |
| **CC-8** | **Khoảng nghỉ của `valid_in`** | L-G | Phân biệt *bộ lọc theo mẫu* với *bộ lọc theo chu kỳ*. Nếu quên bọc `if (valid_in)`, `hist0_q`/`hist1_q` sẽ tự dịch mỗi chu kỳ ⟹ cửa sổ đầy 0 sau vài chu kỳ nghỉ | ✅ TB dòng 53–55 |
| **CC-9** | **Hai xung liên tiếp** `10, 250, 250` | L-I | ⭐ Ca chứng minh **GIỚI HẠN** của cửa sổ 3: trung vị = **250**, tức xung **lọt qua**. Ca này quan trọng ngang ca chứng minh ưu điểm — nó ngăn phát biểu vượt mức "trung vị loại được mọi nhiễu xung" | ❌ **THIẾU** ở cả TB lẫn Python |
| **CC-10** | **Ba mẫu bằng nhau** `5,5,5` | L-T | Ca đơn giản nhất nhưng kiểm được tính nhất quán của cả ba `<=` | ⚠️ chỉ có ở Python (`test_ties`) |

---

## 4. Đối chiếu độ phủ: testbench thật đã có gì, thiếu gì

Đọc từ `g03_tb.sv` dòng 32–64:

```
 dong 38-40  send(10,0,0); send(11,0,0); send(250,1,11);   -> CC-1  (L-W + L-I)  ** FAIL o dong 39 **
 dong 43-45  send(3,1,11); send(1,1,3); send(2,1,2);       -> CC-5  (L-P)
 dong 48-50  send(2,1,2); send(9,1,2); send(2,1,2);        -> CC-6  (L-T)
 dong 53-55  valid_in=0; @(posedge clk); assert(!valid_out)-> CC-8  (L-G)
 dong 58-60  send(0,1,2); send(255,1,2); send(128,1,128);  -> CC-7  (L-B)
```

| Lớp | Ca | TB Verilog | Python | Ghi chú |
|---|---|:-:|:-:|---|
| L-P | CC-2, CC-5 | ⚠️ 1/2 | ✅ (`test_all_permutations`: 6/6) | TB thiếu chuỗi tăng dần thuần |
| L-T | CC-3, CC-6, CC-10 | ⚠️ 1/3 | ✅ 3/3 | TB thiếu ca ba bằng nhau |
| L-W | — | ✅ có | ✅ có | 🔴 **và nó đang bắt được lỗi thật** |
| L-I | CC-1, CC-4, CC-9 | ⚠️ 1/3 | ⚠️ 2/3 | CC-9 thiếu ở **cả hai** |
| L-G | CC-8 | ✅ | ❌ | Python không có khái niệm `valid_in` |
| L-B | CC-7 | ✅ | ✅ | |

> 🔎 **Kết luận độ phủ:** testbench G03 **được thiết kế tốt** — nó phủ đủ năm lớp và đã
> **bắt được lỗi thật ngay ở ca thứ hai**. Điểm mạnh nhất là ca `send(11,0,0)` ở dòng 39:
> nó kiểm **đúng cái điều kiện mà RTL viết sai**. Nếu testbench chỉ bắt đầu kiểm từ mẫu thứ
> ba trở đi (một cách viết rất tự nhiên), lỗi này sẽ **lọt hoàn toàn** và chỉ lộ ra ở
> silicon dưới dạng "một mẫu rác sau mỗi lần khởi động".
>
> Thiếu sót đáng kể duy nhất là **CC-9** — ca chứng minh giới hạn.

### Ca đề nghị bổ sung (chưa áp dụng)

```systemverilog
    // CC-9: HAI xung lien tiep -> trung vi KHONG loai duoc
    // cua so (10,250,250) -> trung vi = 250  (xung LOT QUA)
    send(10, 1, /*tuy trang thai truoc*/ 8'hXX);
    send(250,1, /*...*/  8'hXX);
    send(250,1, 250);        // <-- khang dinh quan trong: ket qua = 250
    send(10, 1, 250);        // cua so (250,250,10) -> van la 250

    // CC-2: chuoi tang dan thuan -> tre dung MOT mau, khong meo
    send(10,1,/*…*/ 8'hXX); send(20,1,/*…*/ 8'hXX);
    send(30,1,20);   // cua so (10,20,30) -> 20
    send(40,1,30);   // cua so (20,30,40) -> 30
    send(50,1,40);   // cua so (30,40,50) -> 40

    // CC-10: ba mau bang nhau
    send(5,1,/*…*/ 8'hXX); send(5,1,/*…*/ 8'hXX);
    send(5,1,5);
```

*(Giá trị `8'hXX` là chỗ phải tính theo trạng thái ngay trước đó khi viết vào TB thật;
ở đây chỉ nêu khẳng định cần kiểm.)*

---

## 5. Ca có trong TB và **đã bắt được lỗi thật**

```systemverilog
38        send(10,0,0);      // mau 1 -> valid phai = 0   ✅ PASS
39        send(11,0,0);      // mau 2 -> valid phai = 0   🔴 FAIL: DUT cho valid = 1
40        send(250,1,11);    // mau 3 -> valid = 1, median = 11   (chua chay toi)
```

`simulation.log`: `FATAL: g03_tb.sv:23: valid mismatch x=11 · Time: 36`

Đây là testbench **làm đúng việc của nó**. Phán xử đầy đủ: `05_VERIFICATION/known_issues.md`
— kết luận: **lỗi nằm trong DUT**, bản vá là **một ký tự** (`2'd1` → `2'd2`).

> 💡 Đối lập đáng dạy: ở đề **G02** cũng có `$fatal` tương tự, nhưng phán xử cho kết quả
> **ngược lại** — ở đó lỗi nằm ở **testbench**. Cùng một triệu chứng, hai thủ phạm khác nhau.
> Đó là lý do phải **đọc mã** chứ không đoán theo triệu chứng.

---

## 6. Ca **KHÔNG** áp dụng cho G03 — và vì sao

| Ca | Vì sao không áp dụng |
|---|---|
| **Tràn số / cờ overflow** | Trung vị **không thực hiện phép cộng nào**. INV-3: đầu ra luôn là bản sao bit-chính-xác của một mẫu vào ⟹ không tồn tại tràn |
| **Sai số làm tròn** | INV-6: không có phép chia, không có `>>`. Khác hẳn G01/G02 |
| **Ca kiểm bộ tích luỹ** | G03 **không có** bộ tích luỹ — đó là G01/G02/G04 |
| **Ca theo nhánh FSM** | G03 **không có FSM** — xem `03_ARCHITECTURE/fsm.md` |
| **Cửa sổ 5 điểm trở lên** | Charter mục 3: **ngoài phạm vi** |
| **Lọc trung vị hai chiều** | Charter mục 3: ngoài phạm vi |
| **Lọc thích nghi** | Charter mục 3: ngoài phạm vi |
| **Ca có dấu (signed)** | Giao diện là **không dấu**. Nhưng ca CC-7 (`0,255,128`) chính là ca **phát hiện** nếu ai đó vô tình khai `signed` |
| **Metastability / CDC** | Một domain clock duy nhất |
| **Glitch trên đầu ra** | `median_out`, `valid_out` đều là đầu ra flip-flop (INV-11) |

---

## 7. Ca phải bổ sung khi chuyển sang gate-level / post-layout

`test_matrix.csv` ghi `L4-GATE` và `L5-SDF` là **CHƯA CHẠY**.

| ID | Ca | Mục đích | Cần gì |
|---|---|---|---|
| **G-1** | Chạy lại CC-1…CC-10 trên `netlist.v` | Chứng minh netlist tương đương RTL | Thư viện mô phỏng `sky130_fd_sc_hd` |
| **G-2** | ⭐ Ca kích hoạt đường tới hạn: đổi **`hist1_q[0]`** (bit **thấp nhất**) và ép cả ba bộ so sánh phải lật | Đường tới hạn thật là `b[0] → median_out[1]`, **7,82 ns**, và nó đi qua **cả 15 cell `maj3_1`** của thiết kế. Phải kiểm đây có phải đường khả thi không | Netlist + SDF |
| **G-3** | Kiểm **hold** trên `_325_ → _325_` (`median_out[0]`), slack min `0,43 ns` | Hold vi phạm không sửa được bằng hạ tần số | SDF sau CTS |
| **G-4** | SDF ở góc `ss` và `ff` | ⚠️ **Đặc biệt quan trọng với G03**: slack chỉ còn **2,10 ns** trên chu kỳ 10 ns — **mỏng nhất trong nhóm G**. Góc `ss` rất có thể làm âm | Liberty + SDF nhiều góc |
| **G-5** | VCD từ G-1 nạp lại OpenSTA để tính công suất thật | `1,76e-04 W` hiện dùng hoạt động mặc định | VCD gate-level |
| **G-6** | Kiểm `hi2`/`lo3` **thật sự** bị loại khỏi netlist | Xác nhận mã chết không tốn cell nào | Đếm `mux2i_1` trong netlist so với dự đoán |

> ⚠️ **G-4 là ca quan trọng nhất của G03.** Với slack 2,10 ns (so với G01 5,36 · G02 5,48 ·
> G04 3,16), G03 là đề **sát biên nhất** của nhóm. Mọi khẳng định về tần số phải chờ ca này.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*

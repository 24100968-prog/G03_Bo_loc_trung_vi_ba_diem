# G03 · Sơ đồ hệ thống (System Diagram)

---

## 1. Bối cảnh ứng dụng — cảm biến áp suất có nhiễu xung

Charter mục 1: *"Khối loại nhiễu xung đột biến trong tín hiệu cảm biến áp suất — trung bình
không loại được xung nhọn, trung vị thì loại được."*

```
  ┌─────────────────── HE THONG DO AP SUAT CONG NGHIEP ───────────────────────┐
  │                                                                            │
  │  ┌──────────┐  mV   ┌────────┐  8 bit  ╔═══════════════╗                  │
  │  │ Cam bien │──────▶│  ADC   │────────▶║               ║   8 bit          │
  │  │  ap suat │       │ 8 bit  │ sample  ║     G03       ║─────────────────▶│
  │  │ (piezo)  │       │        │         ║  Trung vi 3   ║  median_out      │
  │  └────┬─────┘       └───┬────┘         ║    diem       ║─────────────────▶│
  │       ▲                 │ data_ready   ║               ║  valid_out       │
  │       │                 └─────────────▶║ valid_in      ║                  │
  │       │                                ╚═══════╤═══════╝                  │
  │  ┌────┴──────────────┐                     ▲   │                          │
  │  │ NGUON NHIEU XUNG: │       clk, rst_n ───┘   ▼                          │
  │  │ · dong co khoi dong│                      ┌──────────────┐             │
  │  │ · relay dong/ngat  │                      │ Canh bao qua │             │
  │  │ · phong tinh dien  │                      │   nguong     │             │
  │  │ · tia lua han      │                      └──────┬───────┘             │
  │  └───────────────────┘                              ▼                     │
  │                                              ┌─────────────┐              │
  │  ┌────────────┐   ┌──────────────┐           │ Van an toan │              │
  │  │ Dao dong ky│──▶│ Chia tan+POR │──▶clk/rst │  / bao dong │              │
  │  └────────────┘   └──────────────┘           └─────────────┘              │
  └────────────────────────────────────────────────────────────────────────────┘

        ╔═══╗ = pham vi de G03      ┌───┐ = tang ngoai, KHONG thuoc de nay
```

### Vì sao ứng dụng này bắt buộc phải dùng trung vị, không được dùng trung bình

| Đặc điểm | Hệ quả |
|---|---|
| Nhiễu là **xung đơn, biên độ rất lớn, hiếm** (relay đóng, động cơ khởi động) | Trung bình **trải** xung ra `N` mẫu thay vì loại bỏ; trung vị **loại sạch** nếu xung cô lập |
| Đầu ra đi thẳng vào **so sánh ngưỡng → van an toàn** | Một xung giả làm trung bình vọt lên có thể **kích van sai** ⟹ hậu quả vật lý, không chỉ là số xấu trên màn hình |
| Cần **giữ nguyên biên độ** của tín hiệu thật | INV-6: trung vị là **bản sao bit-chính-xác** của một mẫu vào, không có sai số làm tròn |
| Cần đáp ứng nhanh với thay đổi **thật** của áp suất | INV-10: với chuỗi đơn điệu, trung vị chỉ trễ **một mẫu**, không làm mượt sườn |

### Bằng chứng số (đã chạy, PASS)

`reference_model.py` chứa **cả hai** bộ lọc trên cùng một chuỗi có một xung:

| Chuỗi `10, 11, 250` | Kết quả | Lệch so với nền ≈ 10,5 |
|---|---:|---:|
| **Trung vị 3 điểm** (`median_stream`) | **11** | **+0,5** |
| **Trung bình 3 điểm** (`mean_stream`) | **90** | **+79,5** |

Nguồn: `python_reference_run.log` → `G03 golden reference PASS`.
Trung bình lệch **gấp 159 lần** trung vị. Đây là con số trả lời Charter mục 9.

> ⚠️ **Giới hạn phải nêu kèm:** cửa sổ 3 chỉ loại được xung **cô lập**. Với **hai** xung liên
> tiếp (`10, 250, 250`), trung vị cho **250** — xung **lọt qua**. Muốn chịu được `m` xung
> liên tiếp cần cửa sổ `≥ 2m+1`, mà cửa sổ ≥ 5 điểm nằm **ngoài phạm vi** (Charter mục 3).

## 2. Ranh giới khối

| Hạng mục | Thuộc G03? | Ghi chú |
|---|:-:|---|
| Hai thanh ghi mẫu trước (`hist0_q`, `hist1_q`) | ✅ | 16 flip-flop |
| Mạng sắp xếp 3 phần tử (3 CE tổ hợp) | ✅ | Toàn bộ phần logic |
| Bộ đếm khởi động `count_q` | ✅ | 2 flip-flop |
| Thanh ghi đầu ra `median_out`, `valid_out` | ✅ | 9 flip-flop |
| **Tạo `clk`, `rst_n`** | ❌ | Harness / khối chia tần |
| **Tạo `valid_in`** | ❌ | `data_ready` của ADC |
| **So sánh ngưỡng, cảnh báo** | ❌ | Tầng sau |
| **Đồng bộ hoá đầu vào** | ❌ | Nghĩa vụ tầng ngoài |
| **Lớp vỏ 24 chân `tt_um_*`** | ⚠️ **CHƯA CÓ** | Xem cảnh báo `functional_spec.md` |

### Hợp đồng với tầng ngoài

1. `valid_in` chỉ lên 1 khi `sample_in` ổn định và là mẫu mới.
2. Giữ `rst_n = 0` qua **≥ 1 cạnh lên** của `clk` (reset **đồng bộ**).
3. Chỉ đọc `median_out` khi `valid_out = 1`.
4. Chấp nhận **2 mẫu đầu không có đầu ra** (theo đặc tả; RTL hiện tại chỉ bỏ **1** — đó là lỗi).
5. Không có `ready`: phải luôn sẵn sàng nhận.

## 3. Vòng đời RTL → GDSII — trạng thái thật

```
  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │ 1. Dac ta    │    │ 2. RTL       │    │ 3. Mo phong  │    │ 4. Tong hop  │
  │    + Charter │───▶│ SystemVerilog│───▶│  RTL         │───▶│  Yosys 0.33  │
  │      ✅      │    │      ✅      │    │ 🔴 DUNG SOM  │    │      ✅      │
  └──────────────┘    └──────────────┘    └──────┬───────┘    └──────┬───────┘
                                                  │                   │
                          simulation.log ─────────┘                   │
                          "valid mismatch x=11" @36                   │
                          -> known_issues.md: LOI O DUT (off-by-one)  │
                                                                      ▼
  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │ 8. GDSII     │    │ 7. DRC / LVS │    │ 6. P&R       │    │ 5. STA + Pwr │
  │      ⬜      │◀───│      ⬜      │◀───│  LibreLane   │◀───│  OpenSTA 3.1 │
  └──────────────┘    └──────────────┘    │      ⬜      │    │      ✅      │
                                          └──────────────┘    └──────────────┘

  ⬛ KHONG AP DUNG (Charter muc 3 — ngoai pham vi):
     cua so >= 5 diem · loc trung vi hai chieu · loc thich nghi ·
     thiet ke analog muc transistor · physical design thu cong · sign-off · tape-out
```

| Bước | Trạng thái | Công cụ | Bằng chứng | Kết quả then chốt |
|---|:-:|---|---|---|
| 1 · Đặc tả | ✅ | — | `01_`, `02_` | REQ-G03-002 **chưa thoả** (vỏ chân) |
| 2 · RTL | ✅ | — | `g03_median3.sv` (60 dòng) | Biên dịch sạch, **0 cảnh báo** |
| 2b · Mô hình chuẩn | ✅ | Python 3 | `python_reference_run.log` | `PASS` — 5/5 test |
| 3 · Mô phỏng RTL | 🔴 | Icarus 12.0 | `simulation.log` | Dừng `t = 36` — **lỗi ở DUT** |
| 4 · Tổng hợp | ✅ | Yosys 0.33 | `synth_stat.txt` | **189 cell · 27 FF · 1576,512 µm²** |
| 5 · STA | ✅ | OpenSTA 3.1.0 | `timing_report_max.txt` | arrival **7,82 ns**, slack **2,10 ns** |
| 5b · Công suất | ✅ | OpenSTA 3.1.0 | `power_report.txt` | **1,76e-04 W** (tuần tự 68,0 %) |
| 6 · P&R | ⬜ | LibreLane | — | Cần PDK sky130A |
| 7 · DRC / LVS | ⬜ | Magic / Netgen | — | — |
| 8 · GDSII | ⬜ | KLayout | — | — |

> ❗ Đặc biệt với G03: **bước 3 đỏ vì thiết kế sai**, không phải vì công cụ hay testbench.
> Nghĩa là mọi con số ở bước 4–5 đang mô tả một mạch **chưa đúng chức năng**. Sau khi áp bản
> vá (một ký tự), **phải chạy lại toàn bộ bước 4–5** vì logic `count_q >= 2` khác
> `count_q >= 1` về mặt cell.

## 4. G03 trong họ đề nhóm G

Cùng bộ công cụ, cùng `design.sdc`, cùng thư viện ⟹ **so chéo hợp lệ**.

| Đề | Chức năng | Cell | FF | Diện tích (µm²) | Arrival (ns) | Slack (ns) |
|---|---|---:|---:|---:|---:|---:|
| G01 | Trung bình trượt 4 điểm | 260 | 58 | 2623,7664 | 4,56 | 5,36 |
| G02 | Trung bình trượt 8 điểm | 380 | 94 | 4078,912 | 4,38 | 5,48 |
| **G03** | **Trung vị 3 điểm** | **189** | **27** | **1576,512** | **7,82** | **2,10** |
| G04 | Tích luỹ bão hoà 16 bit | 119 | 18 | 1083,5392 | 6,71 | 3,16 |

> 🔎 **Phát hiện trung tâm của đề G03, đọc thẳng từ bảng:**
> G03 là đề có **diện tích nhỏ thứ hai** nhưng **đường tới hạn DÀI NHẤT** của cả nhóm.
> So với G01 (Charter mục 9 yêu cầu so): diện tích **−39,9 %**, flip-flop **−53,4 %**,
> nhưng arrival **+71,5 %** và slack chỉ còn **39 %**.
>
> **"Cái giá phải trả" của trung vị không nằm ở diện tích — nó nằm ở THỜI GIAN.**
> Lý do: ba bộ so sánh độ lớn 8 bit mắc **nối tiếp**, mỗi bộ là một chuỗi mượn (borrow chain)
> 8 tầng. Bằng chứng cứng: **cả 15 cell `maj3_1`** của thiết kế đều nằm trên **một** đường
> tới hạn (`datapath.md` §4). Không một đề nào khác trong nhóm có đặc điểm này.
>
> ⚠️ **Lưu ý trung thực:** G01 có cửa sổ **4**, G03 có cửa sổ **3** — so sánh này **không
> hoàn toàn cùng điều kiện**. Charter mục 9 yêu cầu so G03 với G01 nên bảng trên là câu trả
> lời trực tiếp, nhưng phép so công bằng hơn (trung vị 3 so với **trung bình 3**) **chưa
> chạy**. Xem `tradeoff.md` §6.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-G03-001, Charter mục 9.*

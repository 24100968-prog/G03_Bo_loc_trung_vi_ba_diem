# G03 · Máy trạng thái (FSM)

---

## 1. Kết luận: G03 **không có FSM**

G03 có 27 flip-flop, nhưng **24 trong số đó là dữ liệu** (`hist0_q` 8 + `hist1_q` 8 +
`median_out` 8). Chỉ còn `count_q` (2 bit) và `valid_out` (1 bit) mang tính điều khiển.

| Tiêu chí của một FSM | G03 có? | Bằng chứng trong RTL (60 dòng) |
|---|:-:|---|
| Có `typedef enum` / hằng trạng thái | ❌ | Không có |
| Có biến `state` / `next_state` | ❌ | Chỉ có `hist0_q`, `hist1_q`, `count_q` |
| Có `case (state)` | ❌ | **Không có một `case` nào** trong toàn bộ file |
| Trạng thái kế tiếp rẽ nhánh theo **giá trị dữ liệu** | ❌ | `count_q <= count_q + 1` — không phụ thuộc `sample_in` |
| Đầu ra phụ thuộc trạng thái | ⚠️ **có, nhưng đơn điệu** | `valid_out` bật khi `count_q >= 1` và không bao giờ tắt lại (trừ khi `valid_in = 0` hoặc reset) |

## 2. `count_q` là **bộ đếm bão hoà 3 trạng thái**, không phải FSM

```
        valid_in          valid_in
   ┌───┐ ────────▶  ┌───┐ ────────▶  ┌───┐ ⟲ valid_in  (bao hoa)
   │ 0 │            │ 1 │            │ 2 │
   └───┘            └───┘            └───┘
     │ ▲              │ ▲              │ ▲
     └─┘ !valid_in    └─┘ !valid_in    └─┘ !valid_in

   rst_n = 0 :  MOI trang thai ─────────────▶ 0

   valid_out = 1 tu trang thai  ──▶  1   (RTL hien tai)   🔴 SAI
   valid_out = 1 tu trang thai  ──▶  2   (DAC TA dung)    ✅
```

| Vì sao đây **không** phải FSM | Giải thích |
|---|---|
| Không có **rẽ nhánh** | Mỗi trạng thái chỉ có 2 cung: đứng yên hoặc tiến một bước. Không cung nào phụ thuộc giá trị `sample_in` |
| Không có **chu trình** | Đồ thị là đường thẳng kết thúc ở nút hút `2` |
| Mã hoá là **nhị phân đếm** | Công cụ sinh ra bộ tăng 2 bit + chặn (`and2_0`, `o21a_1`), không phải bảng chuyển trạng thái |
| Số "trạng thái" phụ thuộc **`N`** | Với `N = 5` sẽ có 6 trạng thái. FSM thật không nở ra theo tham số |

> 🔴 **Điểm quan trọng của đề này:** dù `count_q` không phải FSM, **ngưỡng phát hành đầu ra
> vẫn là một quyết định trạng thái**, và nó **bị viết sai**. Đồ thị trên cho thấy rất rõ:
> `valid_out` phải bật từ trạng thái **2**, không phải từ **1**. Vẽ đồ thị này ra là cách
> nhanh nhất để nhìn thấy lỗi — nhanh hơn đọc dòng `if (count_q >= 2'd1)`.

## 3. Mạng sắp xếp **hoàn toàn tổ hợp** — bằng chứng

Charter mục 10 ghi: *"16 ô nhớ (2 mẫu trước) + **mạng sắp xếp tổ hợp**."* Kiểm chứng:

| Bằng chứng | Giá trị | Diễn giải |
|---|---|---|
| Vị trí mã của mạng | Dòng 20–29, dùng `assign` | **Ngoài** `always_ff` ⟹ tổ hợp thuần |
| Flip-flop trong mạng | **0** | 27 FF đều truy được về `hist0_q`/`hist1_q`/`count_q`/`median_out`/`valid_out` |
| `median_out` có thuộc mạng không? | ❌ **Không** | Nó là thanh ghi **đầu ra**, nằm **sau** mạng |
| Công suất nhóm Combinational | **32,0 %** (`5,63e-05 W` / `1,76e-04 W`) | Cao nhất trong ba đề lọc nhóm G (G01 22,7 %, G02 18,1 %) — phù hợp với việc phần logic ở đây **nặng** so với phần nhớ |

## 4. Bằng chứng từ netlist: không có dấu vết của bộ giải mã trạng thái

| Cell đặc trưng | G03 có? | Ý nghĩa |
|---|---|---|
| `maj3_1` ×15 | ✅ | Vân tay của **chuỗi mượn so sánh** — logic **số học**, không phải logic trạng thái |
| `mux2i_1` ×18, `a21oi_1` ×18 | ✅ | Vân tay của **mux compare-exchange** |
| `nor4`/`and4` nhiều ngõ, one-hot decode | ❌ | Vân tay điển hình của bộ giải mã trạng thái — **không có** |
| Flip-flop có tên `state*` | ❌ | Netlist chỉ có `a`, `b`, `count_q`, `median_out`, `valid_out` |

## 5. Trường hợp nào FSM **sẽ** xuất hiện

| Nếu thêm yêu cầu… | FSM xuất hiện vì… | Trạng thái ước tính |
|---|---|---|
| **Cửa sổ ≥ 5 điểm** (Charter mục 3: *ngoài phạm vi*) | Mạng sắp xếp 5 phần tử cần 9 CE; nếu **tuần tự hoá** để tiết kiệm diện tích thì phải đếm bước | `IDLE / CE(0..8) / DONE` |
| **Dùng lại MỘT bộ compare-exchange 3 lần** thay vì 3 bộ song song | Phải nhớ đang ở tầng nào và đường dữ liệu phải định tuyến lại mỗi nhịp | `S0 / S1 / S2 / OUT` — 4 |
| **Back-pressure** (`ready` từ tầng sau) | Phải nhớ "đang giữ kết quả" | `RUN / HOLD` — 2 |
| **Lọc thích nghi** (Charter mục 3: ngoài phạm vi) | Phải chuyển giữa chế độ trung vị và trung bình theo mức nhiễu | ≥ 3 |
| **Nạp mẫu qua 24 chân hẹp** nhiều nhịp | Phải nhớ nhịp | 2–3 |

> 🔎 Trường hợp thứ hai đáng bàn: **dùng lại một bộ CE ba lần** biến G03 từ 189 cell xuống
> còn ~1/3 phần logic, nhưng cần 3 chu kỳ mỗi mẫu **và** một FSM thật. Với ứng dụng cảm biến
> áp suất (kHz), đánh đổi này hoàn toàn khả thi. Xem `tradeoff.md` §3 phương án C.
> **Kiến trúc quyết định có FSM hay không** — không phải "mạch tuần tự thì phải có FSM".

## 6. Sai lầm hay gặp

| Sai lầm | Vì sao sai | Cách phát hiện |
|---|---|---|
| "Mạch tuần tự ⟹ phải vẽ FSM" | Thanh ghi dịch + mạng tổ hợp là mạch tuần tự không FSM | Tìm `case (state)` — không có thì đừng bịa |
| "Vẽ FSM `RESET / WARMUP / RUN`" | `RESET` không phải trạng thái (reset **đồng bộ**, không có flip-flop riêng); `WARMUP → RUN` là **ngưỡng bộ đếm** | Netlist không có flip-flop nào ngoài 27 đã liệt kê |
| "Mạng sắp xếp là một FSM 3 bước" | Ba tầng CE chạy **đồng thời trong một chu kỳ**, không phải ba bước theo thời gian | STA: cả ba tầng nằm trên **một** đường tổ hợp 7,82 ns, giữa chúng **không có flip-flop nào** |
| "Không có FSM ⟹ bỏ trống mục này" | SPEC §0.7: phải giải thích vì sao | Chính là tài liệu này |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-G03-003.*

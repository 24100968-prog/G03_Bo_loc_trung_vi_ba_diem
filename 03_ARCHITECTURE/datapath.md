# G03 · Đường dữ liệu (Datapath)

---

## 1. G03 gần như **toàn bộ là datapath**

```
  ┌──── DATAPATH ─────────────────────────────────┐   ┌─ DIEU KHIEN ────────────┐
  │                                                │   │                          │
  │  sample_in ─▶ hist1_q ─▶ hist0_q               │◀──┤  count_q (2 bit, bao hoa)│
  │  (a,b,c) ─▶ MANG SAP XEP 3 CE ─▶ med3          │   │  valid_in (gating)       │
  │  med3 ─▶ median_out                            │   │  count_q >= 1 ? (enable) │
  └────────────────────────────────────────────────┘   └──────────────────────────┘
        8 + 8 + 8 = 24 flip-flop du lieu                 2 + 1 = 3 flip-flop dieu khien
```

Tỉ lệ **24 : 3**. Nhưng điều đáng nói hơn: **toàn bộ logic tổ hợp** của G03 nằm trong mạng
sắp xếp, và mạng đó **không có flip-flop nào** — đúng như Charter mục 10 mô tả
(*"mạng sắp xếp tổ hợp"*).

## 2. Bảng các đường dữ liệu

| Đường | Độ rộng | Từ | Đến | Bản chất |
|---|---:|---|---|---|
| `sample_in[7:0]` | 8 | cổng vào | `hist1_q` và `c` | Mẫu mới — **rẽ hai nhánh** |
| `c[7:0]` | 8 | bí danh của `sample_in` | CE2 | **0 cell** — `assign` thuần |
| `hist1_q[7:0]` | 8 | thanh ghi | `hist0_q`, `b` | Mẫu `s(k−1)` |
| `b[7:0]` | 8 | bí danh của `hist1_q` | CE1 | **0 cell**; trong netlist thanh ghi **mang luôn tên `b`** |
| `hist0_q[7:0]` | 8 | thanh ghi | `a` | Mẫu `s(k−2)` |
| `a[7:0]` | 8 | bí danh của `hist0_q` | CE1 | **0 cell**; netlist mang tên `a` |
| `lt1` | 1 | CMP1 `(a<=b)` | MUX `lo1`, MUX `hi1` | ⭐ Fanout **27** — tín hiệu điều khiển nội bộ nặng nhất |
| `lo1[7:0]` | 8 | MUX | CE3 | `min(a,b)` |
| `hi1[7:0]` | 8 | MUX | CE2 | `max(a,b)` — **nằm trên đường tới hạn** |
| `lt2` | 1 | CMP2 `(hi1<=c)` | MUX `lo2` | Fanout **13** |
| `lo2[7:0]` | 8 | MUX | CE3 | `min(max(a,b), c)` |
| `hi2[7:0]` | 8 | MUX | **không ai đọc** | ⬛ **MÃ CHẾT** — bị Yosys loại |
| `lt3` | 1 | CMP3 `(lo1<=lo2)` | MUX `med3` | |
| `lo3[7:0]` | 8 | MUX | **không ai đọc** | ⬛ **MÃ CHẾT** |
| `med3[7:0]` | 8 | MUX | `median_out` | **Kết quả** = `max(lo1, lo2)` |
| `median_out[7:0]` | 8 | thanh ghi ra | cổng ra | |
| `count_q[1:0]` | 2 | bộ đếm | enable đầu ra | Trạng thái khởi động |

## 3. Đồ thị phụ thuộc

`▣` = ranh giới flip-flop.

```
  ================== TRONG MOT CHU KY CLOCK ==================

   ▣ hist0_q = a ──────────────────┐
                                   │
   ▣ hist1_q = b ──────┬───────────┤
                       │           │
     sample_in = c ────┼───┐       │
                       │   │       │
                       ▼   │       ▼
         (muc 0..8)  ┌─────┴───────────────┐
                     │ CMP1: chuoi muon    │   <- 8 tang noi tiep
                     │ (a <= b)  -> lt1    │      (netlist: 6 x maj3 + o21a)
                     └──────────┬──────────┘
                                │ lt1  (fanout 27)
              ┌─────────────────┼─────────────────┐
              ▼                 │                 ▼
    (muc 9)  ┌──────────┐       │        ┌──────────────┐
             │ MUX lo1  │       │        │  MUX hi1     │
             │ min(a,b) │       │        │  max(a,b)    │
             └────┬─────┘       │        └──────┬───────┘
                  │ lo1         │               │ hi1
                  │             │               │
                  │             │               ▼        c
                  │             │      (muc 10..18) ┌────┴─────────────┐
                  │             │                   │ CMP2: chuoi muon │
                  │             │                   │ (hi1 <= c)-> lt2 │
                  │             │                   └────────┬─────────┘
                  │             │                            │ lt2 (fanout 13)
                  │             │                            ▼
                  │             │                   (muc 19) ┌──────────┐
                  │             │                            │ MUX lo2  │
                  │             │                            │min(hi1,c)│
                  │             │                            └────┬─────┘
                  │             │                                 │ lo2
                  ▼             │                                 ▼
      (muc 20..28) ┌────────────┴─────────────────────────────────┴──┐
                   │ CMP3: chuoi muon  (lo1 <= lo2) -> lt3           │
                   └──────────────────────┬─────────────────────────-┘
                                          │ lt3
                                          ▼
                             (muc 29)  ┌──────────┐
                                       │ MUX med3 │
                                       │max(lo1,lo2)
                                       └────┬─────┘
                                            ▼
                                    ▣ median_out   (muc 30)
```

### Độ sâu logic

| Đích | Đường dài nhất | Số cell | Arrival (ns) | Nguồn |
|---|---|---:|---:|---|
| `median_out[1]` | `b[0]` → CMP1 → MUX hi1 → CMP2 → CMP3 → MUX med3 | **28** | **7,82** | **đường tới hạn** |
| `valid_out` | `valid_in` → `o21a_1` → `and2_0` | **2** | **1,22** | đường thứ hai trong báo cáo |
| `a[i]` (= `hist0_q`) | `b[i]` → mux giữ/nạp | ≈ 2 | — | rất ngắn |
| `count_q[1]` | `count_q` → +1 bão hoà | ≈ 3 | — | — |

**Chênh lệch 7,82 ns so với 1,22 ns — gấp 6,4 lần.** G03 là mạch **cực kỳ mất cân đối**:
một đường rất dài và mọi đường khác rất ngắn.

**Đường ngắn nhất (báo cáo min):** `_325_ → _325_` (`median_out[0]` hồi tiếp), hold slack
**`0,43 ns` (MET)**.

## 4. Dự đoán đường tới hạn từ RTL — và kết quả STA

### Dự đoán (đọc RTL, chưa xem STA)

Mạng có **3 tầng compare-exchange nối tiếp**, mỗi tầng chứa một bộ so sánh độ lớn 8 bit.
So sánh 8 bit là **chuỗi mượn 8 tầng** (không có cách nào nhanh hơn nếu không dùng
carry-lookahead). Vậy dự đoán:

```
   b[0]  -> CMP1 (8 tang muon)
         -> MUX hi1 (1 tang)
         -> CMP2 (8 tang muon)
         -> MUX lo2 (1 tang)
         -> CMP3 (8 tang muon)
         -> MUX med3 (1 tang)
         -> median_out
   ≈ 24 tang muon + 3 tang mux  ≈ 27 muc logic
```

Và dự đoán startpoint là **bit thấp nhất** của một trong hai thanh ghi cửa sổ, vì bit thấp
nhất là đầu chuỗi mượn.

### Kết quả STA thật

```
  Startpoint: _341_  =  b[0]   (= hist1_q[0])
  Endpoint:   _326_  =  median_out[1]
  arrival 7,82 ns · slack 2,10 ns (MET) · 28 cell · 15 cell maj3_1

  b[0] ▶ isobuf ▶ 6×maj3 ▶ o21a(fo 27) ▶ mux2i ▶ 2×maj3
       ▶ o21ai ▶ a21oi ▶ o22ai ▶ a21o(fo 13) ▶ a211oi
       ▶ 7×maj3 ▶ inputiso ▶ a21o ▶ a21boi ▶ median_out[1]/D
```

| Điểm dự đoán | Thực tế | Lệch |
|---|---|---|
| Đi qua **cả 3 CE nối tiếp** | ✅ đúng (6 + 2 + 7 `maj3`) | Không |
| Startpoint là bit **thấp nhất** của thanh ghi cửa sổ | ✅ `b[0]` | Không |
| ≈ 24 tầng mượn | **15** `maj3` | ABC rút gọn ≈ 37 % |
| Endpoint là một bit của `median_out` | ✅ `median_out[1]` | Không |

**Vì sao ABC rút được từ ~24 xuống 15:** nó **chia sẻ** logic giữa ba bộ so sánh. Chú ý
CMP2 chỉ đóng góp **2** `maj3` trên đường: vì khi tín hiệu tới CMP2 nó đã đi vào ở một vị
trí bit cao (qua `mux2i` của `hi1`), nên chỉ còn vài tầng mượn phải đi nốt. Đây là hiệu ứng
**"đường vào muộn thì đi được ít tầng"** — công cụ đã sắp xếp lại để tín hiệu đến muộn nhất
đi qua ít logic nhất.

### Vì sao dự đoán ở G03 **khớp** còn ở G02 thì **sai hẳn**

| | G02 | G03 |
|---|---|---|
| Phép toán | `a + b − c` (tổng **ba** toán hạng) | Ba phép so sánh **nối tiếp phụ thuộc nhau** |
| Công cụ có biến thể thuật toán rẻ hơn không? | ✅ có — **nén carry-save 3:2** | ❌ **không** — phải biết `lt1` mới chọn được `hi1`, phải có `hi1` mới so được CMP2 |
| Dự đoán từ RTL | Sai ~3,7 lần | Khớp về cấu trúc, lệch ~37 % về số tầng |

> 💡 **Bài học phương pháp:** dự đoán từ RTL đáng tin khi **phụ thuộc dữ liệu là bắt buộc**
> (như chuỗi CE của G03), và không đáng tin khi **có tự do đại số** để công cụ khai thác
> (như tổng nhiều toán hạng của G02). Biết phân biệt hai trường hợp này là kỹ năng thật.

## 5. Vì sao `lt1` có fanout 27 — và vì sao điều đó quan trọng

`lt1 = (a <= b)` là **một bit** nhưng phải lái:
- 8 mux cho `lo1` + 8 mux cho `hi1` = 16 tải (nếu mỗi mux 1 tải), cộng logic gộp ⟹ netlist
  báo **fanout 27** tại `_186_/X`.

Hệ quả đo được trên đường tới hạn: cell `_186_ o21a_1` với fanout 27 có `Cap 0.06`,
`Slew 0.30`, `Delay 0.40 ns` — **cell đắt nhất trên toàn đường** (so với ~0,35 ns của các
`maj3`). Tương tự `_216_` (fanout 13) và `_250_` (fanout 13) đều đắt hơn hàng xóm.

| Ý nghĩa | Giải thích |
|---|---|
| Đây là **đặc trưng cấu trúc**, không phải lỗi | Một bit so sánh **phải** lái cả một mux 8 bit |
| Tối ưu được không? | Có — chèn đệm hoặc nhân bản bộ so sánh. Nhưng đó là việc của **P&R** (**chưa chạy**), không nên làm bằng tay |
| Sau routing sẽ **tệ hơn** | Fanout 27 kéo theo dây dài; ký sinh RC hiện **chưa được tính** vào 7,82 ns |

> ⚠️ Với slack chỉ **2,10 ns**, và ba điểm fanout cao chưa tính ký sinh dây, **G03 là đề có
> nguy cơ vi phạm timing cao nhất nhóm G** sau khi P&R. Phải nêu rõ điều này trong kết luận.

## 6. Không có vòng hồi tiếp nào

Khác hẳn G02 (`sum_q → bộ cộng → sum_q`) và G04 (`acc_q → bộ cộng → acc_q`), G03 **không có
vòng hồi tiếp dữ liệu**:

```
   sample_in ──▶ hist1_q ──▶ hist0_q ──▶ (chi doc)
                     │            │
                     └────────────┴──▶ MANG SAP XEP ──▶ median_out ──▶ (chi ra)
```

Mọi đường đều đi **một chiều**. Hệ quả:

| Hệ quả | Giải thích |
|---|---|
| **Pipeline được tự do** | Có thể chèn thanh ghi giữa CE1 và CE2, hoặc giữa CE2 và CE3, mà **không đổi phương trình** — chỉ thêm độ trễ |
| Đây là hướng tối ưu **đúng** cho G03 | Cắt đường 7,82 ns thành 2–3 đoạn ⟹ slack tăng mạnh. Giá: +8 hoặc +16 FF và +1…2 chu kỳ độ trễ |
| Nhưng **có được phép không?** | Charter mục 3 **không cấm** pipeline. Tuy nhiên nó làm đổi số chu kỳ khởi động ⟹ phải sửa cả đặc tả, testbench và mô hình chuẩn. Xem `tradeoff.md` §5 |
| Ứng dụng có cần không? | Cảm biến áp suất công nghiệp chạy ở hàng kHz; **không cần**. Xem `tradeoff.md` §4 |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-G03-020, Charter mục 2 câu 1.*

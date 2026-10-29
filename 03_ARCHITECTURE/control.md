# G03 · Phần điều khiển (Control)

G03 là mạch **tuần tự**, nên mục này có nội dung thật. Nhưng phần điều khiển của G03 là
**nhỏ nhất trong nhóm G**: đúng **hai flip-flop** và **hai** tín hiệu.

---

## 1. Toàn bộ phần điều khiển

```
  ┌────────────────────── KHOI DIEU KHIEN ──────────────────────────┐
  │                                                                  │
  │   valid_in ──▶ ┌──────────────┐                                  │
  │                │   GATING     │──▶ cho phep MOI cap nhat trang   │
  │                │  (dong 45)   │    thai: hist0_q, hist1_q,       │
  │                └──────────────┘    count_q, median_out, valid_out│
  │                                                                  │
  │   ╔═══════════════════╗   +1 bao hoa 2    ┌────────────────────┐ │
  │   ║  count_q [1:0]    ║─────────────────▶ │ count_q >= 1 ?     │ │
  │   ║   2 flip-flop     ║                   │ (RTL — 🔴 SAI)      │ │
  │   ╚═══════════════════╝                   │ dung phai la >= 2  │ │
  │                                           └─────────┬──────────┘ │
  │                                                      │            │
  │                                    enable nap median_out + valid  │
  └──────────────────────────────────────────────────────┼────────────┘
                                                         ▼
```

**2 flip-flop điều khiển trên 27** = **7,4 %**. Không có con trỏ, không có địa chỉ, không có
bộ giải mã — vì G03 dùng **thanh ghi dịch** chứ không phải bộ đệm vòng (`block_diagram.md` §5).

## 2. Bảng tín hiệu điều khiển và tác dụng

| Tín hiệu | Nguồn | Rộng | Tác dụng lên datapath | Dòng RTL |
|---|---|---:|---|---|
| `rst_n` | cổng vào | 1 | Xoá toàn bộ 27 flip-flop về 0 tại cạnh lên kế tiếp. **Đồng bộ** | 36–41 |
| `valid_in` | cổng vào | 1 | **Cổng chủ**: khi bằng 0, không flip-flop trạng thái nào đổi | 45 |
| `count_q` | nội bộ | 2 | Mở cổng đầu ra khi cửa sổ đã đủ mẫu | 49, 52 |
| `count_q >= 1` | tổ hợp | 1 | 🔴 Enable nạp `median_out` **và** đặt `valid_out = 1` — **sai ngưỡng** | 52 |

### Ngưỡng đúng phải là bao nhiêu — lập luận tổng quát

Với cửa sổ dài `N`, `count_q` đếm **số mẫu đã nhận trước đó**. Mẫu đang xử lý là mẫu thứ
`count_q + 1`. Muốn xuất ở mẫu thứ `N` thì:

```
       count_q + 1 >= N     <=>     count_q >= N - 1
```

| Đề | `N` | Ngưỡng đúng | RTL viết | Đánh giá |
|---|---:|---:|---|:-:|
| G02 | 8 | `>= 7` | `count_q >= 4'd7` | ✅ **đúng** |
| **G03** | **3** | **`>= 2`** | `count_q >= 2'd1` | 🔴 **SAI — thiếu 1** |

Hai đề dùng **cùng một khung mã**, nhưng chỉ một đề viết đúng hằng số. Bằng chứng rõ nhất
cho phán xử "đây là lỗi off-by-one của DUT, không phải lựa chọn thiết kế": nếu tác giả cố ý
cho phép cửa sổ chưa đầy thì mô hình chuẩn Python (`median_stream`) đã phải làm giống vậy —
nhưng nó trả `(False, None)` cho **hai** mẫu đầu.

Xem phán xử đầy đủ: `05_VERIFICATION/known_issues.md`.

## 3. Quan hệ điều khiển ↔ datapath

```
                  ┌───────────────────────────────────────────────┐
  valid_in ──────▶│ AND voi moi enable ben duoi                    │
                  └──┬──────────┬──────────┬──────────┬───────────┘
                     │          │          │          │
                     ▼          ▼          ▼          ▼
                 hist0_q    hist1_q    count_q    median_out + valid_out
                  (8 FF)     (8 FF)     (2 FF)         (8 + 1 FF)
                                           │                ▲
                                           │                │
                                           └── count_q>=1 ──┘  🔴 nen la >=2

   MANG SAP XEP (3 CE)  ──── KHONG co tin hieu dieu khien nao ────
   Mang chay LIEN TUC moi chu ky, ke ca khi valid_in = 0.
   Chi co viec NAP KET QUA moi bi gating.
```

| Quan hệ | Chi tiết |
|---|---|
| **Mạng sắp xếp không bị gating** | `assign lo1/hi1/lo2/hi2/lo3/med3` nằm **ngoài** `always_ff` ⟹ chúng tính liên tục. Chỉ thanh ghi đầu ra mới có enable |
| Hệ quả về **công suất** | Mạng vẫn chuyển mạch khi `valid_in = 0` nếu `sample_in` đổi ⟹ **công suất động lãng phí**. Công suất tổ hợp của G03 chiếm **32,0 %** — cao nhất trong ba đề lọc của nhóm (G01: 22,7 %, G02: 18,1 %) |
| Có thể tối ưu không? | Có — chốt `sample_in` bằng một thanh ghi vào có enable. Giá: +8 FF, +1 chu kỳ. Xem `tradeoff.md` §5 |
| **Không có trạng thái chờ** | Mọi mẫu xử lý trong đúng 1 chu kỳ |
| **Không có back-pressure** | Không có `ready`; tầng sau phải luôn nhận kịp |

## 4. Ba khẳng định về điều khiển, có bằng chứng từ netlist

| Khẳng định | Bằng chứng |
|---|---|
| Reset là **đồng bộ** | Cả **27** flip-flop đều là `sky130_fd_sc_hd__dfxtp_1` — loại **không có chân reset**. Nếu bất đồng bộ, Yosys phải dùng `dfrtp_1` |
| `valid_in` là cổng chủ và là **tín hiệu nhanh nhất** | Đường `valid_in → _170_ o21a_1 → _172_ and2_0 → _324_/D (valid_out)` chỉ **2 cell**, arrival **1,22 ns**, slack **8,66 ns**. Nó có fanout **20** tại cổng vào — lái enable của toàn bộ 27 FF |
| Điều khiển **không** nằm trên đường tới hạn | Đường tới hạn (7,82 ns) đi từ `b[0]` qua mạng sắp xếp; không có cell nào của `count_q` trên đó |

## 5. Vì sao điều khiển **không** phải một FSM

Xem `fsm.md`. Tóm tắt: `count_q` là **bộ đếm bão hoà** ba trạng thái (`0 → 1 → 2 → 2`),
chuỗi thẳng một chiều, không rẽ nhánh theo dữ liệu, không có `case (state)`.

## 6. Nghĩa vụ hợp đồng của tầng ngoài

| # | Nghĩa vụ | Nếu vi phạm |
|---|---|---|
| 1 | Giữ `rst_n = 0` qua **≥ 1 cạnh lên** của `clk` | Trạng thái không được xoá |
| 2 | `valid_in` chỉ lên 1 khi `sample_in` đã ổn định | Dịch và so nhầm giá trị |
| 3 | Chỉ đọc `median_out` khi `valid_out = 1` | Đọc phải tàn dư |
| 4 | Chấp nhận **2 mẫu đầu** không có kết quả (theo đặc tả) | 🔴 RTL hiện chỉ bỏ **1** — tầng ngoài sẽ nhận **một mẫu rác** sau mỗi lần khởi động |
| 5 | Luôn sẵn sàng nhận kết quả (không có `ready`) | Mất mẫu |
| 6 | Giữ `sample_in` ổn định khi `valid_in = 0` (nếu muốn tiết kiệm công suất) | Mạng sắp xếp chuyển mạch vô ích |
| 7 | Đồng bộ hoá `sample_in`/`valid_in` nếu đến từ domain khác | Metastability |

> ⚠️ **Nghĩa vụ số 4 là chỗ nguy hiểm nhất hiện nay.** Với RTL chưa vá, tầng ngoài nhận
> `valid_out = 1` kèm một giá trị tính từ `median3(0, s1, s2)` — trong ứng dụng cảm biến áp
> suất, giá trị này có thể là **0** (nếu `s1`, `s2` đều lớn hơn 0 thì `median3(0,s1,s2)` =
> `min(s1,s2)`, còn nếu một trong hai bằng 0 thì ra 0). Một số đọc áp suất sai ngay sau khởi
> động có thể kích van an toàn. Đây là lý do lỗi off-by-one này **không** phải lỗi nhỏ.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-G03-003.*

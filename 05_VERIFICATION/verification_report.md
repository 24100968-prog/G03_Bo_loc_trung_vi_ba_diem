# G03 · Báo cáo kiểm chứng (Verification Report)

> 🔧 **ĐỀ NÀY ĐÃ ĐƯỢC VÁ LỖI**
>
> Mô phỏng ban đầu không đạt. Lỗi đã được chẩn đoán, vá và **xác minh lại bằng
> công cụ thật**. Mọi số liệu trong hồ sơ là số liệu **sau khi vá**.
>
> * Mã nguồn gốc: [`08_ORIGINAL_SOURCE/`](08_ORIGINAL_SOURCE/) — giữ nguyên, quay lui được
> * Nhật ký vá: [`08_ORIGINAL_SOURCE/PATCHLOG.md`](08_ORIGINAL_SOURCE/PATCHLOG.md)
> * Chẩn đoán đầy đủ: [`05_VERIFICATION/known_issues.md`](05_VERIFICATION/known_issues.md)



**Ngày chạy:** 2026-09-24 · **Phiên bản:** v1.0

---

## 1. Điều kiện tạo ra bằng chứng

> Charter mục 6: *"Mỗi khẳng định đi kèm bằng chứng **và điều kiện tạo ra bằng chứng đó**."*

| Hạng mục | Giá trị |
|---|---|
| Hệ điều hành | Ubuntu 22.04 LTS (x86-64) |
| Công cụ mô phỏng | **Icarus Verilog 12.0 (stable)** (cờ `-g2012`) |
| Top module | `g03_median3` |
| RTL | `04_IMPLEMENTATION/rtl/` |
| Mô hình chuẩn | `05_VERIFICATION/golden_model/` |
| Testbench | `05_VERIFICATION/testbench/` |
| Lệnh chạy | `bash 04_IMPLEMENTATION/scripts/01_run_sim.sh` |
| Nguồn gốc gói | `G03_FINAL_MENTOR_PACKAGE_v1_0` |

## 2. Kết quả tổng hợp

| Lớp | Nội dung | Kết quả |
|---|---|---|
| L0 | Mô hình chuẩn Python | ✅ **PASS** |
| L2 | Mô phỏng RTL | ✅ PASS — testbench chạy hết, không có assertion nào vi phạm |
| L3 | Kiểm cấu trúc — số flip-flop | ✅ đo được **27** FF, phân loại Charter là **Tuần tự** |
| L4 | Mô phỏng gate-level | ⬜ chưa chạy |
| L5 | Mô phỏng post-layout (SDF) | ⬜ chưa chạy |

## 3. Trích log mô phỏng

```
G03 TB completed
05_VERIFICATION/testbench/g03_tb.sv:63: $finish called at 146 (1s)
```

Log đầy đủ: [`simulation.log`](simulation.log)

## 4. Kiểm cấu trúc — số flip-flop

Trích `../06_GDSII/synthesis/synth_stat.txt` (Yosys 0.33 (git sha1 2584903a060) + `sky130_fd_sc_hd`):

| Chỉ số | Giá trị |
|---|---:|
| Tổng số cell | **188** |
| Cell tuần tự (flip-flop / latch) | **27** |
| Diện tích | 1562,7488 µm² |


✅ Đúng phân loại **Tuần tự** của Charter — có ô nhớ đồng bộ theo clock.


## 5. Trả lời câu hỏi kỹ thuật của Charter (mục 2)

> 1. Mạng sắp xếp ba phần tử gồm mấy bộ so sánh và mấy bộ ghép kênh?
> 2. So kết quả lọc trung vị với lọc trung bình trên cùng chuỗi có một xung đột biến — khác nhau thế nào?
> 3. Vì sao đề cấm dùng vòng lặp sắp xếp ở mức hành vi?
> Sinh viên được phép thay bằng câu hỏi của mình, miễn là cụ thể và trả lời được bằng bằng chứng — không viết “tìm hiểu về…”.

Phần trả lời dựa trên số liệu đo được nằm ở:

- Câu về **giao diện / tín hiệu**: `02_SPECIFICATION/interface.md`
- Câu về **thời gian / tần số**: `06_GDSII/sta/` và `06_GDSII/physical_report.md`
- Câu về **diện tích / tài nguyên**: `06_GDSII/physical_report.md` §2
- Phân tích bản chất và cơ chế: `implementation-notes_G03.md`

## 6. Những gì báo cáo này **chưa** chứng minh

| Chưa chứng minh | Vì sao |
|---|---|
| Kiến trúc bên trong đúng như mô tả | Kiểm chứng chức năng mù về cấu trúc — phải đọc RTL và netlist |
| Độ trễ lan truyền đạt yêu cầu | Mô phỏng hành vi là zero-delay |
| Mạch đúng sau place & route | Chưa chạy P&R |
| Không có glitch gây hại | Mô phỏng zero-delay không sinh glitch |

Danh sách đầy đủ: `07_TRACEABILITY/limitations.md`.

---

*Truy vết: REQ-G03-001, REQ-G03-003, REQ-G03-010…013.*

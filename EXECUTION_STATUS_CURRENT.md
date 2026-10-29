# G03 — Trạng thái thực hiện trong phiên hiện tại

## Những gì đã chỉnh sửa
- RTL `04_IMPLEMENTATION/rtl/g03_median3.sv`: giữ ngưỡng phát hành đúng `N-1 = 2`, dùng chung hằng `WINDOW_PREV` cho cả bộ đếm và điều kiện phát hành để tránh lệch hằng số.
- Testbench `05_VERIFICATION/testbench/g03_tb.sv`: thay bằng testbench có scoreboard tham chiếu độc lập, tránh race khi reset bằng cách điều khiển tín hiệu ở cạnh xuống, kiểm tra warm-up, trung vị, giá trị trùng, khoảng trống `valid_in`, reset giữa luồng và 300 chu kỳ stress có valid gap.

## Trạng thái kiểm chứng trong phiên này
Không thể chạy mô phỏng/tổng hợp/STA/P&R trong môi trường hiện tại: các executable `iverilog`, `yosys`, `openroad`, `klayout`, `magic`, `netgen` không có sẵn. Lệnh mô phỏng đã được thử và dừng ngay với thông báo thiếu `iverilog`. Vì vậy, testbench mới là **chưa được chạy tại phiên này**; không được diễn giải như một kết quả PASS mới.

Gói ZIP gốc có các báo cáo và log ghi nhận một lần chạy trước đó sau bản vá tối thiểu (mô phỏng PASS, tổng hợp 188 cell/27 FF/1562.7488 µm², STA 7.82 ns, công suất 1.70e-04 W), nhưng các kết quả đó không phải do phiên hiện tại tái tạo. Gói không chứa thư mục `06_GDSII` với netlist/report thực tế và ghi rõ P&R, routing, DRC, LVS, GDS chưa chạy.

## Cách chạy trên WSL Ubuntu có bộ công cụ
Từ thư mục gốc `G03_Bo_loc_trung_vi_ba_diem`:

```bash
bash 04_IMPLEMENTATION/scripts/01_run_sim.sh
python3 05_VERIFICATION/golden_model/reference_model.py
bash 04_IMPLEMENTATION/scripts/02_run_synth.sh /path/to/sky130_fd_sc_hd__tt_025C_1v80.lib
sta -no_splash -exit 04_IMPLEMENTATION/scripts/03_run_sta.tcl
bash 04_IMPLEMENTATION/scripts/04_run_librelane.sh
```

Để chạy bước tổng hợp, cần Liberty sky130 phù hợp. Để chạy LibreLane cần `PDK_ROOT` trỏ tới PDK `sky130A`, cùng LibreLane/OpenROAD/KLayout/Magic/Netgen và các phụ thuộc tương thích. Chỉ sau khi flow hoàn tất mới báo cáo được kết quả vật lý và tình trạng DRC/LVS/GDS.

## Diễn giải các kết quả đã có trong hồ sơ gốc
- `27 FF`: 16 bit lịch sử (`hist0_q`, `hist1_q`) + 2 bit bộ đếm + 8 bit thanh ghi đầu ra + 1 bit `valid_out`.
- `7.82 ns`: số timing trước/sau bản vá tối thiểu được ghi trong hồ sơ; phải tái chạy STA với netlist và constraint mới để xác nhận. Chưa tính ký sinh dây nếu đây là STA trước P&R.
- `slack 2.10 ns`: chỉ có ý nghĩa theo chu kỳ 10 ns, input/output delay, thư viện và corner đã dùng. Không tự nó chứng minh timing sau routing đạt.
- GDS tồn tại, DRC sạch, LVS khớp và chức năng đúng sau layout là bốn khẳng định riêng; cần report tương ứng cho từng khẳng định.

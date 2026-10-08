# LidarMap

Ứng dụng iPhone nhỏ để quét lưới 3D căn phòng bằng cảm biến LiDAR (ARKit) và xuất tệp **PLY** (mét, trục Y hướng lên). Tệp này nạp thẳng vào công cụ "Bản đồ nền từ LiDAR iPhone" để dựng mặt bằng và lưới chiếm chỗ cho lưới WiFi. Không có bước xử lý đám mây: bấm dừng là xuất được ngay.

Không cần máy Mac: GitHub biên dịch ứng dụng trên máy macOS ảo (miễn phí với repo công khai), anh cài file `.ipa` bằng SideStore từ Windows và tài khoản Apple miễn phí.

> Lưu ý trung thực: bộ mã này chưa được biên dịch thử trên Xcode thật. Lần chạy đầu có thể báo lỗi biên dịch; nếu vậy, mở mục **Summary** của lần chạy (có khối "Lỗi biên dịch"), chép nội dung gửi cho Claude để sửa, rồi tải lại bản mới.

## Phần A. Cho GitHub biên dịch

1. Tạo tài khoản miễn phí tại github.com (nếu chưa có).
2. Bấm **New repository**, đặt tên `lidarmap`, chọn **Public**, bấm **Create repository**. Phải để Public thì phút biên dịch macOS mới miễn phí. Mã nguồn này không chứa thông tin riêng tư.
3. Giải nén gói mã nguồn trên Windows. Trong trang repo bấm **Add file, Upload files**, rồi kéo **toàn bộ nội dung** của thư mục giải nén (các thư mục `Sources`, `Config`, `.github` và các tệp `project.yml`, `README.md`, `.gitignore`) vào trang. Bấm **Commit changes**.
   - Nếu thư mục `.github` không lên (một số trình duyệt bỏ qua thư mục tên bắt đầu bằng dấu chấm), bấm **Add file, Create new file**, gõ tên `.github/workflows/build.yml`, mở tệp cùng tên trên máy bằng Notepad, chép toàn bộ nội dung dán vào, rồi Commit.
4. Mở tab **Actions**. Nếu GitHub hỏi bật workflow, bấm nút đồng ý. Quy trình **Build LidarMap IPA** tự chạy sau mỗi lần commit (hoặc bấm **Run workflow**). Dự kiến khoảng 5 đến 10 phút (ước lượng, chưa đo).
5. Chạy xong dấu xanh: ở cột phải trang repo, mục **Releases**, mở bản **LidarMap bản dựng mới nhất** và tải `LidarMap.ipa`. Cách khác: Actions, chọn lần chạy, mục Artifacts, tải `LidarMap-ipa`.
6. Nếu dấu đỏ: mở lần chạy đó, xem **Summary**, chép khối "Lỗi biên dịch" gửi cho Claude.

## Phần B. Cài SideStore lên iPhone (làm một lần, từ Windows)

Theo tài liệu docs.sidestore.io (hỗ trợ iOS 15.0 đến 15.8.6, 16.0 đến 17.7.7 và 18.0 trở lên):

1. Nên dùng một Apple ID phụ (tạo miễn phí) thay vì Apple ID chính.
2. Trên Windows cài: **iTunes** (bản tải trực tiếp từ Apple, tốt hơn bản Microsoft Store) và **iloader** (iloader.app). Trên iPhone cài **LocalDevVPN** từ App Store.
3. Cắm iPhone bằng cáp USB, mở khoá, bấm **Tin cậy** và nhập mật mã.
4. Mở iloader, đăng nhập Apple ID, chọn iPhone, bấm **Install SideStore (Stable)**.
5. Trên iPhone: **Cài đặt, Cài đặt chung, VPN và quản lý thiết bị**, mục Developer App, chọn Apple ID của anh, bấm **Tin cậy**, **Cho phép và khởi động lại**.
6. **Cài đặt, Quyền riêng tư và bảo mật**, kéo xuống cuối, bật **Chế độ nhà phát triển** (máy khởi động lại).
7. Mở **LocalDevVPN**, bấm **Connect**. Mở **SideStore**, đăng nhập cùng Apple ID. Vào **My Apps**, bấm bộ đếm **7 DAYS** cạnh SideStore để làm mới lần đầu.

## Phần C. Cài và dùng LidarMap

1. Trên iPhone, mở trang Releases của repo bằng Safari, tải `LidarMap.ipa` và lưu vào ứng dụng Tệp.
2. Bật LocalDevVPN, mở SideStore, vào **My Apps**, bấm dấu **+**, chọn `LidarMap.ipa`. (Tên nút trong SideStore có thể khác chút tuỳ phiên bản.)
3. Mở LidarMap, cho phép Camera.
4. Tài khoản Apple miễn phí cho phép tối đa **3 ứng dụng** và mỗi ứng dụng hết hạn sau **7 ngày**. SideStore (cũng chiếm một suất) tự làm mới khi LocalDevVPN bật và iPhone ở trong Wi-Fi. Trước khi hết hạn có thể mở SideStore bấm làm mới thủ công.
5. Muốn cập nhật bản mới: tải `LidarMap.ipa` mới và cài đè trong SideStore (dữ liệu quét trong ứng dụng được giữ).

## Cách quét cho kết quả tốt

1. Bật hết đèn (khoảng 50 lux trở lên), che hoặc tránh gương, kính và vật đen bóng. Dọn sàn. Giữ cửa ở trạng thái cố định.
2. Mở LidarMap, bấm **Bắt đầu quét**. Đi chậm một vòng khép kín về điểm xuất phát, xoay cả người, giữ máy cách tường 1 đến 3 m. Quét từ sàn lên trần, cả góc phòng và sau đồ vật. Hãy làm lưới phủ kín mặt sàn.
3. Chấm trạng thái xanh nghĩa là theo dõi tốt. Cam kèm dòng chữ nghĩa là đi chậm lại hoặc hướng máy vào vùng có nhiều chi tiết.
4. Mỗi lần chỉ một phòng, dưới 5 phút. Quét lâu hơn dễ bị trôi.
5. Bấm **Dừng quét**, rồi **Xuất PLY**. Bảng chia sẻ hiện ra: chọn **Lưu vào Tệp**, AirDrop, Zalo hoặc email. Tệp cũng tự nằm trong ứng dụng Tệp, mục **Trên iPhone của tôi, LidarMap**.
6. Mở công cụ Bản đồ nền từ LiDAR iPhone (trên Safari hoặc máy tính), bấm **Chọn tệp** và chọn tệp `quet_...ply`.

## Cấu trúc mã nguồn

| Tệp | Việc |
|---|---|
| `Sources/ScanController.swift` | Điều khiển phiên ARKit (bắt đầu, dừng, quét lại), thông số hiển thị, gọi xuất tệp |
| `Sources/MeshExporter.swift` | Gộp các mảnh lưới ARKit thành một lưới trong toạ độ thế giới và ghi PLY nhị phân |
| `Sources/ContentView.swift` | Giao diện SwiftUI, khung nhìn AR, bảng chia sẻ |
| `project.yml` | Cấu hình XcodeGen (sinh project Xcode khi biên dịch) |
| `.github/workflows/build.yml` | Quy trình GitHub Actions biên dịch IPA không ký |

## Kế hoạch tiếp theo

1. Chế độ RoomPlan (tường, cửa, vật dạng tham số, ghép nhiều phòng) xuất JSON và USDZ.
2. Gắn công cụ bản đồ nền vào trong ứng dụng để quét xong ra mặt bằng ngay.

# 1. Phân tích Yêu cầu (Requirements Analysis)

## Mô tả hệ thống
Hệ thống Quản lý Thư viện cần quản lý thông tin về sách, thành viên, và các giao dịch mượn trả sách.

## Các yêu cầu chức năng

### 1. Quản lý Sách
- **Thông tin sách**: Tên sách, mã ISBN, nhà xuất bản, năm xuất bản, số lượng hiện có
- **Tác giả**: Một cuốn sách có thể có nhiều tác giả
- **Thể loại**: Mỗi sách thuộc về một hoặc nhiều thể loại

### 2. Quản lý Thành viên
- **Thông tin cá nhân**: Họ tên, mã thẻ thư viên, địa chỉ, số điện thoại
- **Thông tin thành viên**: Ngày tham gia, loại thành viên (sinh viên/giảng viên)
- **Đặc quyền**: Số sách được mượn tối đa, thời gian mượn

### 3. Quản lý Mượn trả
- **Phiếu mượn**: Thành viên nào mượn cuốn sách nào
- **Thời gian**: Ngày mượn, ngày hẹn trả, ngày thực tế trả
- **Trạng thái**: Đang mượn, đã trả, quá hạn

### 4. Quản lý Tác giả
- **Thông tin tác giả**: Họ tên, năm sinh, quốc tịch
- **Mối quan hệ**: Một tác giả có thể viết nhiều sách

### 5. Quản lý Nhà xuất bản
- **Thông tin NXB**: Tên, địa chỉ, số điện thoại
- **Mối quan hệ**: Một NXB có thể xuất bản nhiều sách

## Các yêu cầu phi chức năng
- Đảm bảo tính toàn vẹn dữ liệu
- Hiệu suất truy vấn tốt
- Bảo mật thông tin thành viên
- Dễ dàng bảo trì và mở rộng

## Các quy tắc nghiệp vụ
1. Mỗi sách phải có ít nhất một tác giả
2. Thành viên chỉ được mượn tối đa số sách theo quy định của loại thành viên
3. Không được mượn sách mới nếu có sách quá hạn chưa trả
4. Số lượng sách trong kho phải >= 0
5. Ngày trả phải >= ngày mượn
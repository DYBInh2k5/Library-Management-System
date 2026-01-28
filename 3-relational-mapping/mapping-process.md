# 3. Chuyển đổi sang Lược đồ Quan hệ (Relational Mapping)

## Áp dụng thuật toán 7 bước chuyển đổi ERD sang lược đồ quan hệ

### Bước 1: Tạo bảng cho các thực thể mạnh (Strong Entities)

#### 1.1. Bảng SACH
```sql
SACH(ISBN, TenSach, NamXuatBan, SoLuong, GiaTien, MaNXB)
- Primary Key: ISBN
- Foreign Key: MaNXB references NHA_XUAT_BAN(MaNXB)
```

#### 1.2. Bảng THANH_VIEN  
```sql
THANH_VIEN(MaThe, HoTen, DiaChi, SoDienThoai, NgayThamGia, LoaiThanhVien)
- Primary Key: MaThe
```

#### 1.3. Bảng TAC_GIA
```sql
TAC_GIA(MaTacGia, HoTen, NamSinh, QuocTich)
- Primary Key: MaTacGia
```

#### 1.4. Bảng NHA_XUAT_BAN
```sql
NHA_XUAT_BAN(MaNXB, TenNXB, DiaChi, SoDienThoai)
- Primary Key: MaNXB
```

#### 1.5. Bảng THE_LOAI
```sql
THE_LOAI(MaTheLoai, TenTheLoai, MoTa)
- Primary Key: MaTheLoai
```

### Bước 2: Xử lý thực thể yếu (Weak Entities)
- Không có thực thể yếu trong hệ thống này

### Bước 3: Xử lý mối quan hệ 1:1
- Không có mối quan hệ 1:1 trong hệ thống này

### Bước 4: Xử lý mối quan hệ 1:N
#### 4.1. Mối quan hệ XUAT_BAN (NHA_XUAT_BAN 1:N SACH)
- Đã xử lý bằng cách thêm MaNXB vào bảng SACH như Foreign Key

### Bước 5: Tạo bảng cho mối quan hệ M:N

#### 5.1. Bảng MUON_TRA (THANH_VIEN M:N SACH)
```sql
MUON_TRA(MaThe, ISBN, NgayMuon, NgayHenTra, NgayThucTeTra, TrangThai)
- Primary Key: (MaThe, ISBN, NgayMuon)
- Foreign Key: MaThe references THANH_VIEN(MaThe)
- Foreign Key: ISBN references SACH(ISBN)
```

#### 5.2. Bảng VIET_SACH (TAC_GIA M:N SACH)
```sql
VIET_SACH(MaTacGia, ISBN, VaiTro)
- Primary Key: (MaTacGia, ISBN)
- Foreign Key: MaTacGia references TAC_GIA(MaTacGia)
- Foreign Key: ISBN references SACH(ISBN)
```

#### 5.3. Bảng THUOC_THE_LOAI (SACH M:N THE_LOAI)
```sql
THUOC_THE_LOAI(ISBN, MaTheLoai)
- Primary Key: (ISBN, MaTheLoai)
- Foreign Key: ISBN references SACH(ISBN)
- Foreign Key: MaTheLoai references THE_LOAI(MaTheLoai)
```

### Bước 6: Xử lý thuộc tính đa trị
- Không có thuộc tính đa trị riêng lẻ (đã xử lý thông qua mối quan hệ M:N)

### Bước 7: Xử lý thuộc tính phức hợp
- Không có thuộc tính phức hợp trong hệ thống này

## Kết quả cuối cùng - Lược đồ quan hệ hoàn chỉnh:

1. **SACH**(ISBN, TenSach, NamXuatBan, SoLuong, GiaTien, MaNXB)
2. **THANH_VIEN**(MaThe, HoTen, DiaChi, SoDienThoai, NgayThamGia, LoaiThanhVien)
3. **TAC_GIA**(MaTacGia, HoTen, NamSinh, QuocTich)
4. **NHA_XUAT_BAN**(MaNXB, TenNXB, DiaChi, SoDienThoai)
5. **THE_LOAI**(MaTheLoai, TenTheLoai, MoTa)
6. **MUON_TRA**(MaThe, ISBN, NgayMuon, NgayHenTra, NgayThucTeTra, TrangThai)
7. **VIET_SACH**(MaTacGia, ISBN, VaiTro)
8. **THUOC_THE_LOAI**(ISBN, MaTheLoai)
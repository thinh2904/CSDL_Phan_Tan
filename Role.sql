create Role QuanLyCuaHang;
create Role NhanVien;

Go
--
create login QuanLy01 with password='123'
create user QuanLy01 for login QuanLy01 
execute sp_addrolemember 'QuanLyCuaHang','QuanLy01 '
exec sp_addsrvrolemember 'QuanLy01 ', 'sysadmin'
Go
--
create login QuanLy02 with password='123'
create user QuanLy02 for login QuanLy02 
execute sp_addrolemember 'QuanLyCuaHang','QuanLy02'
exec sp_addsrvrolemember 'QuanLy02', 'sysadmin'



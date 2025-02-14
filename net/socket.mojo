
from sys import external_call
from memory import Pointer, DTypePointer
from libc import errno
from utils import StaticTuple
from bit import byte_swap

alias AF_INET = 2
alias SOCK_STREAM = 1
alias SOCKET_ERROR = -1
alias BACKLOG = 32

trait Read:
	fn read(
		self, inout buf: Pointer[UInt8], count: Int32
	) raises -> Int32:
		pass

trait Write:
	fn write(
		self, buf: DTypePointer[DType.uint8, 0], count: Int32
	) raises -> Int32:
		pass

struct TcpListener(Stringable):
	var fd: Int32

	fn __init__(inout self, sock_addr: SockAddr) raises:
		self.fd = socket(AF_INET, SOCK_STREAM, 0)
		var sock_addr_in = sock_addr_in(sock_addr)
		bind(self.fd, sock_addr_in, len(sock_addr_in))
		listen(self.fd, BACKLOG)

	fn accept(self) raises -> TcpConnection:
		var addr = sock_addr_in()
		var length = addr.__len__()
		var addr_ptr = UnsafePointer.address_of(addr)
		var addr_len = Pointer.address_of(length)

		var client_fd = accept(self.fd, addr_ptr, addr_len)
		var client_addr = Pointer
			.address_of(addr.sin_addr.s_addr)
			.bitcast[SIMD[DType.uint8, 4]]()[]

		return TcpConnection(
			SockAddr(
				client_addr,
				addr.sin_port
			),
			client_fd
		)

	fn __str__(self) -> String:
		return str(self.fd)

@value
struct TcpConnection(Read):
	var client: SockAddr
	var fd: Int32

	fn read(self, inout buf: Pointer[UInt8], count: Int32) raises -> Int32:
		return read(
			self.fd,
			buf,
			count,
		)

	fn write(self, buf: DTypePointer[DType.uint8, 0], count: Int32) raises -> Int32:
		return write(
			self.fd,
			buf,
			count
		)


@value
struct SockAddr:
	var addr: SIMD[DType.uint8, 4]
	var port: UInt16

	fn __init__(inout self, addr: SIMD[DType.uint8, 4], port: UInt16):
		self.addr = addr
		self.port = byte_swap(port)

fn debug_print(ptr: sock_addr_in):
	var ptr_u8 = UnsafePointer.address_of(ptr).bitcast[UInt8]()
	for i in range(16):
		print(hex(ptr_u8.offset(i)[]), end=" ")
	print()


@value
struct sock_addr_in:
	var sin_family: Int16
	var sin_port: UInt16
	var sin_addr: in_addr
	var char: StaticTuple[UInt8, 8]

	fn __len__(self) -> Int:
		return 22

	fn __init__(inout self):
		self.sin_family = 0
		self.sin_port =	0
		self.sin_addr = in_addr(0)
		self.char = StaticTuple[UInt8, 8](0)

	fn __init__(inout self, sock_addr: SockAddr):
		var addr = Pointer.address_of(sock_addr.addr).bitcast[UInt32]().load()
		self.sin_family = AF_INET
		self.sin_port =	sock_addr.port
		self.sin_addr = in_addr(addr)
		self.char = StaticTuple[UInt8, 8](0)

@value
struct in_addr:
	var s_addr: UInt32

fn socket(domain: Int32, typ: Int32, protocol: Int32) raises -> Int32:
	var ret = external_call["socket", Int32](domain, typ, protocol)
	if ret == SOCKET_ERROR:
		raise Error(str("Socket Error: ") + str(errno()))
	return ret

fn bind(socket: Int32, sock_addr: sock_addr_in, sock_addr_len: Int32) raises:
	var sock_addr_ptr = UnsafePointer.address_of(sock_addr)
	var ret = external_call["bind", Int32](socket, sock_addr_ptr, sock_addr_len)
	if ret == SOCKET_ERROR:
		raise Error(str("Bind Error: ") + str(errno()))

fn listen(socket: Int32, backlog: Int32) raises:
	var ret = external_call["listen", Int32](socket, backlog)
	if ret == SOCKET_ERROR:
		raise Error(str("Listen Error: ") + str(errno()))

fn accept(socket: Int32, inout sock_addr: UnsafePointer[sock_addr_in], sock_addr_len: Pointer[Int]) raises -> Int:
	var ret = external_call["accept", Int](socket, sock_addr, sock_addr_len)
	if ret == SOCKET_ERROR:
		raise Error(str("Accept Error: ") + str(errno()))
	return ret

fn read(socket: Int32, inout buf: Pointer[UInt8], count: Int32) raises -> Int32:
	var ret = external_call["read", Int](socket, buf, count)
	if ret == SOCKET_ERROR:
		raise Error(str("Read Error: ") + str(errno()))
	return ret

fn write(socket: Int32, buf: DTypePointer[DType.uint8, 0], count: Int32) raises -> Int32:
	var ret = external_call["write", Int](socket, buf, count)
	if ret == SOCKET_ERROR:
		raise Error(str("Write Error: ") + str(errno()))
	return ret

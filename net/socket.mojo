
from sys import external_call
from memory import Pointer, DTypePointer
from libc import errno
from utils import StaticTuple

var AF_INET = 2
var SOCK_STREAM = 1
var SOCKET_ERROR = -1

trait Read:
	fn read[size: Int](self, buffer: Pointer[SIMD[DType.uint8, size]]) raises
		-> Int32:
		pass

struct TcpListener(Stringable):
	var fd: Int32

	fn __init__(inout self, sock_addr: SockAddr) raises:
		self.fd = socket(AF_INET, SOCK_STREAM, 0)
		var sock_addr_in = sock_addr_in(sock_addr)
		bind(self.fd, sock_addr_in, len(sock_addr_in))
		listen(self.fd, 32)

	fn accept(self) raises -> TcpConnection:
		var addr = sock_addr_in()
		var l = 16
		var addr_ptr = UnsafePointer.address_of(addr)
		var addr_len = Pointer.address_of(l)
		var conn_fd = accept(self.fd, addr_ptr, addr_len)
		return TcpConnection(
			SockAddr(
				Pointer
					.address_of(addr.sin_port)
					.bitcast[SIMD[DType.uint8, 4]]()[],
				addr.sin_port
			),
			conn_fd
		)

	fn __str__(self) -> String:
		return str(self.fd)

@value
struct TcpConnection(Read):
	var client: SockAddr
	var fd: Int32

	fn read[size: Int](self, buffer: Pointer[SIMD[DType.uint8, size]]) raises -> Int32:
		return read(
			self.fd,
			buffer.bitcast[UInt8](),
			size
		)


@value
struct SockAddr:
	var addr: SIMD[DType.uint8, 4]
	var port: UInt16

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

fn accept(socket: Int32, sock_addr: UnsafePointer[sock_addr_in], sock_addr_len: Pointer[Int]) raises -> Int:
	var ret = external_call["accept", Int](socket, sock_addr, sock_addr_len)
	if ret == SOCKET_ERROR:
		raise Error(str("Accept Error: ") + str(errno()))
	return ret

fn read(socket: Int32, buffer: Pointer[UInt8], buffer_len: Int32) raises -> Int32:
	var ret = external_call["read", Int](socket, buffer, buffer_len)
	if ret == SOCKET_ERROR:
		raise Error(str("Read Error: ") + str(errno()))
	return ret

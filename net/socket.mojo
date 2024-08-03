
from sys import external_call
from memory import Pointer
from libc import errno
from utils import StaticTuple

var AF_INET = 2
var SOCK_STREAM = 1
var SOCKET_ERROR = -1

trait HexDump:
	pass

struct Socket(Stringable):
	var fd: Int32

	fn __init__(inout self, fd: Int32):
		self.fd = fd

	fn __str__(self) -> String:
		return str(self.fd)

	fn bind(self, sock_addr: SockAddr) raises:
		var sock_addr_in = sock_addr.to_sock_addr_in()
		debug_print(sock_addr_in)
		bind(self.fd, sock_addr_in, len(sock_addr_in))

@value
struct SockAddr:
	var addr: StaticTuple[UInt8, 4]
	var port: UInt16

	fn to_sock_addr_in(self) -> sock_addr_in:
		var addr = Pointer.address_of(self.addr).bitcast[UInt32]().load()
		return sock_addr_in(
			AF_INET, 
			self.port, 
			in_addr(addr), 
			StaticTuple[UInt8, 8](0)
		)


fn debug_print(ptr: sock_addr_in):
	var ptr_u8 = UnsafePointer.address_of(ptr).bitcast[UInt8]()
	for i in range(20):
		print(ptr_u8.offset(i)[], end=" ")
	print()


@value
struct sock_addr_in:
	var sin_family: Int16
	var sin_port: UInt16
	var sin_addr: in_addr
	var char: StaticTuple[UInt8, 8]

	fn __len__(self) -> Int:
		return 16

@value
struct in_addr:
	var s_addr: UInt32

fn socket(domain: Int32, typ: Int32, protocol: Int32) raises -> Socket: 
	var ret = external_call["socket", Int32](domain, typ, protocol)
	if ret == SOCKET_ERROR:
		raise Error(str("Socket Error: ") + str(errno()))
	return Socket(ret)

fn bind(socket: Int32, sock_addr: sock_addr_in, sock_addr_len: UInt64) raises:
	var sock_addr_ptr = UnsafePointer.address_of(sock_addr)
	var ret = external_call["bind", Int32](socket, sock_addr_ptr, sock_addr_len)
	if ret == SOCKET_ERROR:
		raise Error(str("Bind Error: ") + str(errno()))



#!/usr/bin/env mojo

import net
import libc
from utils import StaticTuple
from memory import Pointer

fn main():
	print("Hello world")

	var res = "HTTP/1.1 204 No Content\r\n\r\n"

	try:
		var ip_addr = SIMD[DType.uint8, 4](0)
		var addr = net.SockAddr(ip_addr, 36895)
		var listener = net.TcpListener(addr)

		var size: Int32
		var read_buf = SIMD[DType.uint8, 2048](0);
		var read_buf_ptr = Pointer
			.address_of(read_buf)
			.bitcast[UInt8]();
		while(True):
			var conn = listener.accept()
			size = conn.read(read_buf_ptr, len(read_buf))
			for i in range(size):
				print(chr(int(read_buf[i])), end='')
			print()

			size = conn.write(res.as_uint8_ptr(), len(res))
	except e:
		print(e)
		libc.exit(-1)
	

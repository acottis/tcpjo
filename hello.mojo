#!/usr/bin/env mojo

import net
import libc
from utils import StaticTuple
from memory import Pointer

fn main() raises:
	var res = "HTTP/1.1 200\r\nContent-Length: 0\r\n\r\n"

	var addr = net.SockAddr(0, 8080)
	var listener = net.TcpListener(addr)
	print("[INFO] Listening on 0.0.0.0:8080")

	var size: Int32
	var read_buf = SIMD[DType.uint8, 2048](0);
	var read_buf_ptr = Pointer
		.address_of(read_buf)
		.bitcast[UInt8]();
	while(True):
		var conn = listener.accept()
		print(conn.client.addr, conn.client.port)
		size = conn.read(read_buf_ptr, len(read_buf))
		for i in range(size):
			print(chr(int(read_buf_ptr.offset(i)[])), end='')
		print()

		size = conn.write(res.as_uint8_ptr(), len(res))
	

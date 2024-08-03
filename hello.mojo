#!/usr/bin/env mojo

import net
import libc
from utils import StaticTuple
from memory import Pointer

fn main():
	print("Hello world")

	try:
		var ip_addr = SIMD[DType.uint8, 4](0)
		var addr = net.SockAddr(ip_addr, 36895)
		var listener = net.TcpListener(addr)

		while(True):
			var buffer = SIMD[DType.uint8, 1024](0);
			var buffer_ptr = Pointer.address_of(buffer)
			var conn = listener.accept()
			var size = conn.read[1024](buffer_ptr)
			for i in range(size):
				print(chr(int(buffer[i])), end='')
			print()
	except e:
		print(e)
		libc.exit(-1)
	
